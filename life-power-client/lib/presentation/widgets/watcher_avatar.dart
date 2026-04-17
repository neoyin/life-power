import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:crypto/crypto.dart';

class AvatarImageCache {
  static final AvatarImageCache _instance = AvatarImageCache._internal();
  factory AvatarImageCache() => _instance;
  AvatarImageCache._internal();

  final Map<String, Uint8List> _memoryCache = {};
  Directory? _cacheDir;

  Future<Directory> get cacheDirectory async {
    if (_cacheDir == null) {
      _cacheDir = await getTemporaryDirectory();
      final avatarCacheDir = Directory('${_cacheDir!.path}/avatar_cache');
      if (!avatarCacheDir.existsSync()) {
        avatarCacheDir.createSync(recursive: true);
      }
      _cacheDir = avatarCacheDir;
    }
    return _cacheDir!;
  }

  String _hashUrl(String url) {
    final bytes = utf8.encode(url);
    return md5.convert(bytes).toString();
  }

  Future<Uint8List?> getFromMemory(String url) async {
    return _memoryCache[url];
  }

  Uint8List? getFromMemorySync(String url) {
    return _memoryCache[url];
  }

  Future<Uint8List?> getFromDisk(String url) async {
    try {
      final cacheDir = await cacheDirectory;
      final file = File('${cacheDir.path}/${_hashUrl(url)}');
      if (file.existsSync()) {
        final bytes = await file.readAsBytes();
        _memoryCache[url] = bytes;
        return bytes;
      }
    } catch (_) {}
    return null;
  }

  Future<void> saveToMemory(String url, Uint8List bytes) async {
    _memoryCache[url] = bytes;
  }

  Future<void> saveToDisk(String url, Uint8List bytes) async {
    try {
      final cacheDir = await cacheDirectory;
      final file = File('${cacheDir.path}/${_hashUrl(url)}');
      await file.writeAsBytes(bytes);
    } catch (_) {}
  }

  Future<Uint8List?> get(String url) async {
    var cached = await getFromMemory(url);
    if (cached != null) return cached;

    cached = await getFromDisk(url);
    if (cached != null) return cached;

    return null;
  }

  Future<Uint8List?> fetchAndCache(String url) async {
    try {
      final response = await Dio().get<List<int>>(
        url,
        options: Options(
          responseType: ResponseType.bytes,
          followRedirects: true,
          validateStatus: (status) => status != null && status < 400,
        ),
      );

      if (response.statusCode == 200 && response.data != null) {
        final bytes = Uint8List.fromList(response.data!);
        await saveToMemory(url, bytes);
        await saveToDisk(url, bytes);
        return bytes;
      }
    } catch (_) {}
    return null;
  }
}

class WatcherAvatar extends StatelessWidget {
  final String name;
  final String? imageUrl;
  final double size;
  final bool showGradientBorder;
  final bool isAddButton;
  final VoidCallback? onTap;

  const WatcherAvatar({
    super.key,
    required this.name,
    this.imageUrl,
    this.size = 64,
    this.showGradientBorder = false,
    this.isAddButton = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    if (isAddButton) {
      return GestureDetector(
        onTap: onTap,
        child: Container(
          width: size,
          height: size,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            color: Color(0xFFd9e5e6),
          ),
          child: Icon(
            Icons.add,
            color: const Color(0xFF727d7e),
            size: size * 0.4,
          ),
        ),
      );
    }

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: showGradientBorder ? size + 4 : size,
        height: showGradientBorder ? size + 4 : size,
        padding: const EdgeInsets.all(2),
        decoration: showGradientBorder
            ? const BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [Color(0xFF535f6f), Color(0xFFd7e3f7)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              )
            : null,
        child: Container(
          width: size,
          height: size,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            color: Color(0xFFf0f4f5),
          ),
          child: ClipOval(
            child: imageUrl != null && imageUrl!.isNotEmpty
                ? CachedAvatarImage(
                    imageUrl: imageUrl!,
                    size: size,
                    fallback: _buildInitials(),
                  )
                : _buildInitials(),
          ),
        ),
      ),
    );
  }

  Widget _buildInitials() {
    final initials = name.isNotEmpty
        ? name
            .split(' ')
            .map((e) => e.isNotEmpty ? e[0] : '')
            .take(2)
            .join()
            .toUpperCase()
        : '?';
    return Container(
      width: size,
      height: size,
      color: const Color(0xFFf0f4f5),
      child: Center(
        child: Text(
          initials,
          style: TextStyle(
            fontSize: size * 0.35,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF535f6f),
          ),
        ),
      ),
    );
  }
}

class CachedAvatarImage extends StatefulWidget {
  final String imageUrl;
  final double size;
  final Widget fallback;

  const CachedAvatarImage({
    super.key,
    required this.imageUrl,
    required this.size,
    required this.fallback,
  });

  @override
  State<CachedAvatarImage> createState() => _CachedAvatarImageState();
}

class _CachedAvatarImageState extends State<CachedAvatarImage> {
  static final AvatarImageCache _cache = AvatarImageCache();
  Uint8List? _imageData;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _imageData = _cache.getFromMemorySync(widget.imageUrl);
    if (_imageData == null) {
      _isLoading = true;
      _loadImage();
    }
  }

  Future<void> _loadImage() async {
    final cached = await _cache.get(widget.imageUrl);
    if (cached != null && mounted) {
      setState(() {
        _imageData = cached;
        _isLoading = false;
      });
      return;
    }

    final fetched = await _cache.fetchAndCache(widget.imageUrl);
    if (mounted) {
      setState(() {
        _imageData = fetched;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return SizedBox(
        width: widget.size,
        height: widget.size,
        child: Center(
          child: _ImagePlaceholder(size: widget.size),
        ),
      );
    }

    if (_imageData != null) {
      return Image.memory(
        _imageData!,
        width: widget.size,
        height: widget.size,
        fit: BoxFit.cover,
        gaplessPlayback: true,
      );
    }

    return widget.fallback;
  }
}

class _ImagePlaceholder extends StatelessWidget {
  final double size;

  const _ImagePlaceholder({required this.size});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      color: const Color(0xFFf0f4f5),
      child: const Center(
        child: CircularProgressIndicator(
          strokeWidth: 2,
          color: Color(0xFF535f6f),
        ),
      ),
    );
  }
}

class WatcherAvatarList extends StatelessWidget {
  final List<WatcherAvatarData> watchers;
  final int maxDisplay;
  final double avatarSize;
  final bool showGradientBorder;
  final VoidCallback? onAddTap;
  final Function(int index)? onAvatarTap;

  const WatcherAvatarList({
    super.key,
    required this.watchers,
    this.maxDisplay = 4,
    this.avatarSize = 40,
    this.showGradientBorder = true,
    this.onAddTap,
    this.onAvatarTap,
  });

  @override
  Widget build(BuildContext context) {
    final displayCount =
        watchers.length > maxDisplay ? maxDisplay : watchers.length;
    final remainingCount = watchers.length - maxDisplay;

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (int i = 0; i < displayCount; i++)
          Transform.translate(
            offset: Offset(i * -12.0, 0),
            child: Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: const Color(0xFFf8fafa),
                  width: 4,
                ),
              ),
              child: GestureDetector(
                onTap: () => onAvatarTap?.call(i),
                child: WatcherAvatar(
                  name: watchers[i].name,
                  imageUrl: watchers[i].imageUrl,
                  size: avatarSize,
                  showGradientBorder: showGradientBorder,
                ),
              ),
            ),
          ),
        if (remainingCount > 0)
          Transform.translate(
            offset: Offset(displayCount * -12.0, 0),
            child: Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: const Color(0xFFf8fafa),
                  width: 4,
                ),
              ),
              child: Container(
                width: avatarSize,
                height: avatarSize,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Color(0xFFd7e3f7),
                ),
                child: Center(
                  child: Text(
                    '+$remainingCount',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF535f6f),
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class WatcherAvatarData {
  final String name;
  final String? imageUrl;
  final int? energyScore;
  final String? energyLevel;
  final int? energyTrend;

  WatcherAvatarData({
    required this.name,
    this.imageUrl,
    this.energyScore,
    this.energyLevel,
    this.energyTrend,
  });
}

class WatcherAvatarWithEnergy extends StatelessWidget {
  final WatcherAvatarData data;
  final double avatarSize;
  final VoidCallback? onTap;

  const WatcherAvatarWithEnergy({
    super.key,
    required this.data,
    this.avatarSize = 64,
    this.onTap,
  });

  Color _getEnergyColor() {
    switch (data.energyLevel?.toLowerCase()) {
      case 'high':
      case 'energetic':
        return const Color(0xFF006f1d);
      case 'medium':
      case 'balanced':
        return const Color(0xFFfec330);
      case 'low':
      case 'low battery':
        return const Color(0xFF9c4343);
      default:
        return const Color(0xFF727d7e);
    }
  }

  @override
  Widget build(BuildContext context) {
    final energyColor = _getEnergyColor();

    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Stack(
            children: [
              WatcherAvatar(
                name: data.name,
                imageUrl: data.imageUrl,
                size: avatarSize,
                showGradientBorder: true,
              ),
              if (data.energyScore != null)
                Positioned(
                  right: 0,
                  bottom: 0,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                    decoration: BoxDecoration(
                      color: energyColor,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                    child: Text(
                      '${data.energyScore}%',
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            data.name,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: Color(0xFF2a3435),
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          if (data.energyTrend != null)
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  data.energyTrend! >= 0 ? Icons.trending_up : Icons.trending_down,
                  size: 12,
                  color: data.energyTrend! >= 0
                      ? const Color(0xFF006f1d)
                      : const Color(0xFF9c4343),
                ),
                const SizedBox(width: 2),
                Text(
                  '${data.energyTrend! >= 0 ? '+' : ''}${data.energyTrend!}%',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: data.energyTrend! >= 0
                        ? const Color(0xFF006f1d)
                        : const Color(0xFF9c4343),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}
