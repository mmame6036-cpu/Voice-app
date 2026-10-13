import 'package:flutter/material.dart';

class RoomChatFeed extends StatelessWidget {
  final List<Map<String, String>> messages;

  const RoomChatFeed({
    Key? key,
    required this.messages,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 150,
      margin: const EdgeInsets.symmetric(horizontal: 14),
      child: ListView.builder(
        reverse: true,
        itemCount: messages.length,
        itemBuilder: (context, index) {
          final msg = messages[messages.length - 1 - index];
          final user = msg['user'] ?? '';
          final text = msg['text'] ?? '';
          final isSystem = user == 'System' || user == 'Announcement';

          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 2),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.35),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: RichText(
                  text: TextSpan(
                    children: [
                      TextSpan(
                        text: '$user: ',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: isSystem ? const Color(0xFF00FFD5) : Colors.amber,
                          fontSize: 12,
                        ),
                      ),
                      TextSpan(
                        text: text,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
