import 'package:flutter/material.dart';
import 'package:life_power_client/core/i18n.dart';

class CareBanner extends StatelessWidget {
  final String? senderName;
  final String? message;
  final String? timeAgo;
  final VoidCallback onTap;
  final VoidCallback onDismiss;

  const CareBanner({
    Key? key,
    this.senderName,
    this.message,
    this.timeAgo,
    required this.onTap,
    required this.onDismiss,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (senderName == null || message == null) {
      return const SizedBox.shrink();
    }

    return Dismissible(
      key: Key('care_banner_${senderName}_$message'),
      direction: DismissDirection.up,
      onDismissed: (_) => onDismiss(),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                const Color(0xFF9d4edd).withOpacity(0.15),
                const Color(0xFF9d4edd).withOpacity(0.05),
              ],
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: const Color(0xFF9d4edd).withOpacity(0.3),
              width: 1,
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFF9d4edd).withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.favorite,
                  color: Color(0xFF9d4edd),
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    RichText(
                      text: TextSpan(
                        children: [
                          TextSpan(
                            text: senderName,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF2a3435),
                            ),
                          ),
                          TextSpan(
                            text: ': $message',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w400,
                              color: Color(0xFF566162),
                            ),
                          ),
                        ],
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (timeAgo != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        timeAgo!,
                        style: const TextStyle(
                          fontSize: 11,
                          color: Color(0xFF727d7e),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFF9d4edd),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  tr('reply'),
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: onDismiss,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFf0f4f5),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.close,
                    size: 16,
                    color: Color(0xFF727d7e),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class CareBannerManager extends StatefulWidget {
  final List<dynamic> careMessages;
  final VoidCallback onViewAll;
  final Function(dynamic) onMessageTap;

  const CareBannerManager({
    Key? key,
    required this.careMessages,
    required this.onViewAll,
    required this.onMessageTap,
  }) : super(key: key);

  @override
  State<CareBannerManager> createState() => _CareBannerManagerState();
}

class _CareBannerManagerState extends State<CareBannerManager> {
  int _currentIndex = 0;
  bool _isDismissed = false;

  String _getTimeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final diff = now.difference(dateTime);

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

  @override
  void didUpdateWidget(CareBannerManager oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.careMessages.length != oldWidget.careMessages.length) {
      _currentIndex = 0;
      _isDismissed = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final unreadMessages = widget.careMessages
        .where((m) => m.emojiResponse == null)
        .toList();

    if (unreadMessages.isEmpty || _isDismissed) {
      return const SizedBox.shrink();
    }

    if (_currentIndex >= unreadMessages.length) {
      _currentIndex = 0;
    }

    final currentMessage = unreadMessages[_currentIndex];

    return CareBanner(
      senderName: 'User ${currentMessage.senderId}',
      message: currentMessage.content,
      timeAgo: _getTimeAgo(currentMessage.createdAt),
      onTap: () => widget.onMessageTap(currentMessage),
      onDismiss: () {
        setState(() {
          _isDismissed = true;
        });
      },
    );
  }
}
