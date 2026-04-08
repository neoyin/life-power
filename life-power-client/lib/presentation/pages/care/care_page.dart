import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:life_power_client/core/theme.dart';
import 'package:life_power_client/core/i18n.dart';
import 'package:life_power_client/presentation/providers/energy_provider.dart';
import 'package:life_power_client/presentation/widgets/watcher_avatar.dart';

class CarePage extends ConsumerStatefulWidget {
  const CarePage({Key? key}) : super(key: key);

  @override
  _CarePageState createState() => _CarePageState();
}

class _CarePageState extends ConsumerState<CarePage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(energyProvider.notifier).getCareMessages();
    });
  }

  @override
  Widget build(BuildContext context) {
    final energyState = ref.watch(energyProvider);
    final messages = energyState.careMessages ?? [];

    return Scaffold(
      backgroundColor: const Color(0xFFf8fafa),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          tr('care_messages'),
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: Color(0xFF2a3435),
          ),
        ),
        centerTitle: true,
      ),
      body: energyState.isLoading
          ? const Center(child: CircularProgressIndicator())
          : messages.isEmpty
              ? _buildEmptyState()
              : ListView.builder(
                  padding: const EdgeInsets.all(24),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final message = messages[index];
                    return _buildMessageBubble(message);
                  },
                ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: const Color(0xFFd7e3f7).withOpacity(0.3),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.favorite_border,
              size: 64,
              color: Color(0xFF535f6f),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            tr('care_messages'),
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2a3435),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            tr('care_empty_desc'),
            style: const TextStyle(
              color: Color(0xFF727d7e),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(message) {
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          WatcherAvatar(
            name: 'User ${message.senderId}',
            size: 48,
            showGradientBorder: true,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: const BorderRadius.only(
                      topRight: Radius.circular(24),
                      bottomLeft: Radius.circular(24),
                      bottomRight: Radius.circular(24),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF2a3435).withOpacity(0.04),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        message.content,
                        style: const TextStyle(
                          fontSize: 16,
                          color: Color(0xFF2a3435),
                          height: 1.4,
                        ),
                      ),
                      if (message.emojiResponse != null) ...[
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: const Color(0xFFf0f4f5),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '${tr('replied')}: ${message.emojiResponse}',
                            style: const TextStyle(fontSize: 12),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                if (message.emojiResponse == null)
                  _buildEmojiReplyBar(message.id)
                else
                  Padding(
                    padding: const EdgeInsets.only(left: 8.0),
                    child: Text(
                      tr('responded'),
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF006f1d),
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmojiReplyBar(int messageId) {
    final emojis = ['❤️', '💪', '🙏', '🔥', '✨'];
    return Row(
      children: emojis
          .map((emoji) => GestureDetector(
                onTap: () {
                  ref.read(energyProvider.notifier).replyCareMessage(messageId, emoji);
                },
                child: Container(
                  margin: const EdgeInsets.only(right: 8),
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    border: Border.all(color: const Color(0xFFd9e5e6)),
                  ),
                  child: Text(emoji, style: const TextStyle(fontSize: 16)),
                ),
              ))
          .toList(),
    );
  }
}
