import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:life_power_client/presentation/providers/energy_provider.dart';

class CarePage extends ConsumerStatefulWidget {
  const CarePage({Key? key}) : super(key: key);

  @override
  _CarePageState createState() => _CarePageState();
}

class _CarePageState extends ConsumerState<CarePage> {
  final TextEditingController _messageController = TextEditingController();
  final TextEditingController _recipientController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // 初始化时获取关怀消息列表
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(energyProvider.notifier).getCareMessages();
    });
  }

  void _sendMessage() {
    final recipientId = int.tryParse(_recipientController.text);
    if (recipientId == null || _messageController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请输入有效的接收者ID和消息内容')),
      );
      return;
    }

    ref.read(energyProvider.notifier).sendCareMessage(
          recipientId,
          _messageController.text,
        );
    _messageController.clear();
    _recipientController.clear();
  }

  @override
  Widget build(BuildContext context) {
    final energyState = ref.watch(energyProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('关怀')),
      body: Column(
        children: [
          // 发送消息表单
          Card(
            margin: const EdgeInsets.all(16),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  TextField(
                    controller: _recipientController,
                    decoration: const InputDecoration(
                      labelText: '接收者ID',
                      hintText: '输入用户ID',
                    ),
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _messageController,
                    decoration: const InputDecoration(
                      labelText: '消息内容',
                      hintText: '输入关怀消息',
                    ),
                    maxLines: 3,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _sendMessage,
                    child: const Text('发送消息'),
                  ),
                ],
              ),
            ),
          ),

          // 消息列表
          Expanded(
            child: energyState.isLoading
                ? const Center(child: CircularProgressIndicator())
                : energyState.careMessages != null && energyState.careMessages!.isNotEmpty
                    ? ListView.builder(
                        itemCount: energyState.careMessages!.length,
                        itemBuilder: (context, index) {
                          final message = energyState.careMessages![index];
                          return Card(
                            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: Colors.green,
                                child: const Icon(Icons.message),
                              ),
                              title: Text('来自: ${message.senderId}'),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(message.content),
                                  if (message.emojiResponse != null)
                                    Text('回复: ${message.emojiResponse}'),
                                ],
                              ),
                              trailing: IconButton(
                                icon: const Icon(Icons.reply),
                                onPressed: () {
                                  // 回复消息
                                  _replyMessage(message.id);
                                },
                              ),
                            ),
                          );
                        },
                      )
                    : const Center(
                        child: Text('暂无关怀消息'),
                      ),
          ),
        ],
      ),
    );
  }

  void _replyMessage(int messageId) {
    showDialog(
      context: context,
      builder: (context) {
        final replyController = TextEditingController();
        return AlertDialog(
          title: const Text('回复消息'),
          content: TextField(
            controller: replyController,
            decoration: const InputDecoration(
              labelText: 'Emoji 回复',
              hintText: '输入 emoji',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('取消'),
            ),
            ElevatedButton(
              onPressed: () {
                ref.read(energyProvider.notifier).replyCareMessage(
                      messageId,
                      replyController.text,
                    );
                Navigator.pop(context);
              },
              child: const Text('发送'),
            ),
          ],
        );
      },
    );
  }
}
