import 'package:flutter/material.dart';

class MessagesScreen extends StatefulWidget {
  const MessagesScreen({Key? key}) : super(key: key);

  @override
  State<MessagesScreen> createState() => _MessagesScreenState();
}

class _MessagesScreenState extends State<MessagesScreen> {
  final List<Map<String, dynamic>> chats = [
    {
      'name': 'System Notice',
      'avatar': '📢',
      'lastMsg': 'Welcome to Nile Voice! Enjoy your rooms.',
      'time': '10:45 AM',
      'unread': 1,
      'color': const Color(0xFF00C9A7),
    },
    {
      'name': 'Mimi',
      'avatar': '👩',
      'lastMsg': 'Join my room, we are having a great time!',
      'time': '09:30 AM',
      'unread': 2,
      'color': const Color(0xFFD946EF),
    },
    {
      'name': 'Yared',
      'avatar': '🎤',
      'lastMsg': 'Thanks for the gift on stage!',
      'time': 'Yesterday',
      'unread': 0,
      'color': const Color(0xFF3B82F6),
    },
    {
      'name': 'Sara',
      'avatar': '🎮',
      'lastMsg': 'Are you playing today?',
      'time': 'Yesterday',
      'unread': 0,
      'color': const Color(0xFFF59E0B),
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F121C),
      appBar: AppBar(
        backgroundColor: const Color(0xFF161B26),
        elevation: 0,
        title: const Text(
          'Messages',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.mark_chat_read_outlined, color: Colors.white70),
            onPressed: () {
              setState(() {
                for (var chat in chats) {
                  chat['unread'] = 0;
                }
              });
            },
          ),
        ],
      ),
      body: ListView.separated(
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemCount: chats.length,
        separatorBuilder: (context, index) => const Divider(
          color: Colors.white10,
          indent: 72,
          endIndent: 16,
          height: 1,
        ),
        itemBuilder: (context, index) {
          final item = chats[index];
          return ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            leading: CircleAvatar(
              radius: 26,
              backgroundColor: (item['color'] as Color).withOpacity(0.2),
              child: Text(
                item['avatar'],
                style: const TextStyle(fontSize: 24),
              ),
            ),
            title: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  item['name'],
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  item['time'],
                  style: const TextStyle(color: Colors.white38, fontSize: 12),
                ),
              ],
            ),
            subtitle: Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      item['lastMsg'],
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: item['unread'] > 0 ? Colors.white70 : Colors.white38,
                        fontSize: 13,
                        fontWeight: item['unread'] > 0 ? FontWeight.w500 : FontWeight.normal,
                      ),
                    ),

),
                  if (item['unread'] > 0)
                    Container(
                      margin: const EdgeInsets.only(left: 8),
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFF00C9A7),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '${item['unread']}',
                        style: const TextStyle(color: Colors.black, fontSize: 11, fontWeight: FontWeight.bold),
                      ),
                    ),
                ],
              ),
            ),
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Chat with ${item['name']}'),
                  duration: const Duration(seconds: 1),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
