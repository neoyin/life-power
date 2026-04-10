import 'package:flutter/material.dart';

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
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: const Color(0xFFd9e5e6),
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
            ? BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(
                  colors: [Color(0xFF535f6f), Color(0xFFd7e3f7)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              )
            : null,
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: const Color(0xFFf0f4f5),
          ),
          child: ClipOval(
            child: imageUrl != null && imageUrl!.isNotEmpty
                ? Image.network(
                    imageUrl!,
                    width: size,
                    height: size,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return _buildInitials();
                    },
                  )
                : _buildInitials(),
          ),
        ),
      ),
    );
  }

  Widget _buildInitials() {
    final initials = name.isNotEmpty
        ? name.split(' ').map((e) => e.isNotEmpty ? e[0] : '').take(2).join().toUpperCase()
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
    final displayCount = watchers.length > maxDisplay ? maxDisplay : watchers.length;
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

  WatcherAvatarData({
    required this.name,
    this.imageUrl,
  });
}
