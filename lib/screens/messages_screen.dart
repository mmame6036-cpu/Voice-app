import 'package:flutter/material.dart';

class MessagesScreen extends StatefulWidget {
  const MessagesScreen({super.key});

  @override
  State<MessagesScreen> createState() => _MessagesScreenState();
}

class _MessagesScreenState extends State<MessagesScreen> {
  final List<Map<String, dynamic>> _systemNotices = [
    {
      "title": "Official Announcement",
      "subtitle": "Welcome to VIP Voice App! Protect your account.",
      "time": "Just now",
      "icon": Icons.campaign,
      "color": Colors.orangeAccent,
    },
    {
      "title": "Wallet & Rewards",
      "subtitle": "Recharge bonuses and daily free coins are active.",
      "time": "10:30 AM",
      "icon": Icons.monetization_on,
      "color": const Color(0xFFFFD700),
    },
  ];

  final List<Map<String, dynamic>> _chats = [
    {
      "name": "Customer Support",
      "lastMessage": "Hello! How can we assist you today?",
      "time": "Yesterday",
      "unread": 1,
      "avatar": "https://images.unsplash.com/photo-1534528741775-53994a69daeb?q=80&w=200&auto=format&fit=crop",
    },
    {
      "name": "Agency Manager",
      "lastMessage": "Your daily hosting target is active. Keep it up!",
      "time": "2 days ago",
      "unread": 0,
      "avatar": "https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?q=80&w=200&auto=format&fit=crop",
    },
  ];

  void _openChatRoom(String name) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PrivateChatScreen(userName: name),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7FBFB),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        title: const Text(
          "Messages",
          style: TextStyle(color: Colors.black, fontSize: 18, fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.done_all, color: Colors.black54),
            tooltip: "Mark all as read",
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("All messages marked as read")),
              );
            },
          ),
        ],
      ),
      body: ListView(
        children: [
          const SizedBox(height: 12),
          // Quick Notice Badges (System, Activity, Interactions)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _quickAction(Icons.notifications_active, "Notice", Colors.blueAccent),
                _quickAction(Icons.favorite, "Interaction", Colors.pinkAccent),
                _quickAction(Icons.person_add, "Followers", const Color(0xFF00C9A7)),
              ],
            ),
          ),
          const SizedBox(height: 16),
          const Divider(height: 1),

          // System Notices
          ..._systemNotices.map((notice) => ListTile(
                leading: CircleAvatar(
                  backgroundColor: (notice["color"] as Color).withOpacity(0.15),
                  child: Icon(notice["icon"] as IconData, color: notice["color"] as Color),
                ),
                title: Text(
                  notice["title"],
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
                subtitle: Text(
                  notice["subtitle"],
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 12, color: Colors.black54),
                ),
                trailing: Text(
                  notice["time"],
                  style: const TextStyle(fontSize: 11, color: Colors.black38),

),
                onTap: () {
                  showDialog(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      title: Text(notice["title"]),
                      content: Text(notice["subtitle"]),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(ctx),
                          child: const Text("OK"),
                        )
                      ],
                    ),
                  );
                },
              )),

          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Text(
              "Recent Chats",
              style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black45, fontSize: 12),
            ),
          ),

          // User Chats
          ..._chats.map((chat) => ListTile(
                leading: Stack(
                  children: [
                    CircleAvatar(
                      backgroundImage: NetworkImage(chat["avatar"]),
                    ),
                    if (chat["unread"] > 0)
                      Positioned(
                        right: 0,
                        top: 0,
                        child: Container(
                          width: 10,
                          height: 10,
                          decoration: const BoxDecoration(
                            color: Colors.redAccent,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                  ],
                ),
                title: Text(
                  chat["name"],
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
                subtitle: Text(
                  chat["lastMessage"],
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 12, color: Colors.black54),
                ),
                trailing: Text(
                  chat["time"],
                  style: const TextStyle(fontSize: 11, color: Colors.black38),
                ),
                onTap: () => _openChatRoom(chat["name"]),
              )),
        ],
      ),
    );
  }

  Widget _quickAction(IconData icon, String label, Color color) {
    return Column(
      children: [
        Container(
          width: 52,
          height: 52,
          decoration: BoxDecoration(
            color: color.withOpacity(0.12),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color, size: 24),
        ),
        const SizedBox(height: 6),
        Text(
          label,
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: Colors.black87),
        ),
      ],
    );
  }
}

// 1-on-1 Chat Screen
class PrivateChatScreen extends StatefulWidget {
  final String userName;

  const PrivateChatScreen({super.key, required this.userName});

  @override
  State<PrivateChatScreen> createState() => _PrivateChatScreenState();
}

class _PrivateChatScreenState extends State<PrivateChatScreen> {
  final List<String> _messages = ["Hello! Welcome to private chat."];
  final TextEditingController _controller = TextEditingController();

  void _send() {
    final txt = _controller.text.trim();
    if (txt.isNotEmpty) {
      setState(() {
        _messages.add(txt);
      });
      _controller.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7FBFB),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black, size: 20),

onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          widget.userName,
          style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 16),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _messages.length,
              itemBuilder: (context, idx) {
                final isMe = idx > 0;
                return Align(
                  alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: isMe ? const Color(0xFF00C9A7) : Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 2)],
                    ),
                    child: Text(
                      _messages[idx],
                      style: TextStyle(
                        color: isMe ? Colors.white : Colors.black87,
                        fontSize: 14,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            color: Colors.white,
            child: SafeArea(
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF0F3F4),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: TextField(
                        controller: _controller,
                        decoration: const InputDecoration(
                          hintText: "Type a message...",
                          border: InputBorder.none,
                          isDense: true,
                        ),
                        onSubmitted: (_) => _send(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.send, color: Color(0xFF00C9A7)),
                    onPressed: _send,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
