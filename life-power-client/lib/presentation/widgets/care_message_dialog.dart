import 'package:flutter/material.dart';
import 'package:life_power_client/core/i18n.dart';
import 'package:life_power_client/data/models/watcher.dart';

class CareMessageDialog extends StatefulWidget {
  final String recipientName;
  final int recipientId;
  final Function(String message)? onSend;

  const CareMessageDialog({
    Key? key,
    required this.recipientName,
    required this.recipientId,
    this.onSend,
  }) : super(key: key);

  static Future<void> show({
    required BuildContext context,
    required String recipientName,
    required int recipientId,
    Function(String message)? onSend,
  }) {
    return showDialog(
      context: context,
      builder: (context) => CareMessageDialog(
        recipientName: recipientName,
        recipientId: recipientId,
        onSend: onSend,
      ),
    );
  }

  @override
  State<CareMessageDialog> createState() => _CareMessageDialogState();
}

class _CareMessageDialogState extends State<CareMessageDialog> {
  bool _showCustomInput = false;
  final _customController = TextEditingController();

  @override
  void dispose() {
    _customController.dispose();
    super.dispose();
  }

  final List<Map<String, dynamic>> _presetMessages = [
    {'text': 'You matter!', 'icon': Icons.favorite, 'key': 'care_preset_1'},
    {'text': 'Take care!', 'icon': Icons.health_and_safety, 'key': 'care_preset_2'},
    {'text': 'You are strong!', 'icon': Icons.bolt, 'key': 'care_preset_3'},
  ];

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Row(
        children: [
          const Icon(Icons.favorite, color: Color(0xFF9f403d), size: 24),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              '${tr('send_care')} ${widget.recipientName}',
              style: const TextStyle(fontSize: 18),
            ),
          ),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (!_showCustomInput) ...[
              ...(_presetMessages.map((msg) => _buildPresetOption(
                    msg['text'] as String,
                    msg['icon'] as IconData,
                  ))),
              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: () => setState(() => _showCustomInput = true),
                icon: const Icon(Icons.edit, size: 18),
                label: Text(tr('custom_message')),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF535f6f),
                  side: const BorderSide(color: Color(0xFFd9e5e6)),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ] else ...[
              TextField(
                controller: _customController,
                decoration: InputDecoration(
                  hintText: tr('enter_message'),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  contentPadding: const EdgeInsets.all(16),
                ),
                maxLines: 3,
                autofocus: true,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () => setState(() {
                        _showCustomInput = false;
                        _customController.clear();
                      }),
                      child: Text(tr('cancel')),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        if (_customController.text.isNotEmpty) {
                          Navigator.pop(context);
                          widget.onSend?.call(_customController.text);
                        }
                      },
                      icon: const Icon(Icons.send, size: 18),
                      label: Text(tr('send')),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF535f6f),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(
            tr('cancel'),
            style: const TextStyle(color: Color(0xFF727d7e)),
          ),
        ),
      ],
    );
  }

  Widget _buildPresetOption(String message, IconData icon) {
    return InkWell(
      onTap: () {
        Navigator.pop(context);
        widget.onSend?.call(message);
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          color: const Color(0xFFf8fafa),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFd9e5e6)),
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: const Color(0xFF9f403d).withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: const Color(0xFF9f403d), size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF2a3435),
                ),
              ),
            ),
            const Icon(Icons.send, color: Color(0xFF535f6f), size: 18),
          ],
        ),
      ),
    );
  }
}
