import 'package:flutter/material.dart';
import 'package:life_power_client/core/i18n.dart';

enum SyncStatus { idle, syncing, success, error }

class SyncStatusIndicator extends StatefulWidget {
  final SyncStatus status;
  final VoidCallback? onRetry;
  final VoidCallback? onRefresh;

  const SyncStatusIndicator({
    super.key,
    required this.status,
    this.onRetry,
    this.onRefresh,
  });

  @override
  State<SyncStatusIndicator> createState() => _SyncStatusIndicatorState();
}

class _SyncStatusIndicatorState extends State<SyncStatusIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _rotationController;
  late Animation<double> _rotationAnimation;

  @override
  void initState() {
    super.initState();
    _rotationController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    _rotationAnimation = Tween<double>(begin: 0, end: 1).animate(_rotationController);

    if (widget.status == SyncStatus.syncing) {
      _rotationController.repeat();
    }
  }

  @override
  void didUpdateWidget(SyncStatusIndicator oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.status == SyncStatus.syncing) {
      _rotationController.repeat();
    } else {
      _rotationController.stop();
      _rotationController.reset();
    }
  }

  @override
  void dispose() {
    _rotationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.status == SyncStatus.error ? widget.onRetry : widget.onRefresh,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: _getBackgroundColor(),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildIcon(),
            const SizedBox(width: 6),
            Text(
              _getStatusText(),
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: _getTextColor(),
              ),
            ),
            if (widget.status == SyncStatus.error) ...[
              const SizedBox(width: 4),
              Icon(
                Icons.refresh,
                size: 14,
                color: _getTextColor(),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildIcon() {
    switch (widget.status) {
      case SyncStatus.idle:
        return Icon(
          Icons.cloud_outlined,
          size: 16,
          color: _getTextColor(),
        );
      case SyncStatus.syncing:
        return RotationTransition(
          turns: _rotationAnimation,
          child: Icon(
            Icons.sync,
            size: 16,
            color: _getTextColor(),
          ),
        );
      case SyncStatus.success:
        return Icon(
          Icons.check_circle_outline,
          size: 16,
          color: _getTextColor(),
        );
      case SyncStatus.error:
        return Icon(
          Icons.error_outline,
          size: 16,
          color: _getTextColor(),
        );
    }
  }

  Color _getBackgroundColor() {
    switch (widget.status) {
      case SyncStatus.idle:
        return const Color(0xFFf0f4f5);
      case SyncStatus.syncing:
        return const Color(0xFF4ea8de).withOpacity(0.1);
      case SyncStatus.success:
        return const Color(0xFF006f1d).withOpacity(0.1);
      case SyncStatus.error:
        return const Color(0xFF9c4343).withOpacity(0.1);
    }
  }

  Color _getTextColor() {
    switch (widget.status) {
      case SyncStatus.idle:
        return const Color(0xFF727d7e);
      case SyncStatus.syncing:
        return const Color(0xFF4ea8de);
      case SyncStatus.success:
        return const Color(0xFF006f1d);
      case SyncStatus.error:
        return const Color(0xFF9c4343);
    }
  }

  String _getStatusText() {
    switch (widget.status) {
      case SyncStatus.idle:
        return tr('sync_idle');
      case SyncStatus.syncing:
        return tr('sync_syncing');
      case SyncStatus.success:
        return tr('sync_success');
      case SyncStatus.error:
        return tr('sync_error');
    }
  }
}

class LastSyncTime {
  static String format(DateTime? lastSync) {
    if (lastSync == null) {
      return '';
    }

    final now = DateTime.now();
    final diff = now.difference(lastSync);

    if (diff.inMinutes < 1) {
      return '刚刚';
    } else if (diff.inMinutes < 60) {
      return '${diff.inMinutes}分钟前';
    } else if (diff.inHours < 24) {
      return '${diff.inHours}小时前';
    } else {
      return '${diff.inDays}天前';
    }
  }
}
