import 'package:flutter/material.dart';

class MessagesScreen extends StatefulWidget {
  const MessagesScreen({super.key});

  @override
  State<MessagesScreen> createState() => _MessagesScreenState();
}

class _MessagesScreenState extends State<MessagesScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  final List<Map<String, dynamic>> _chats = [
    {
      "name": "Amina",
      "avatar": "👩",
      "lastMsg": "በክፍሉ ውስጥ ተገናኝተን እናውራ!",
      "time": "10:45 AM",
      "unread": 2,
      "online": true,
    },
    {
      "name": "Yonas (VIP)",
      "avatar": "🧔",
      "lastMsg": "ስጦታውን ልኬልሃለሁ ተመልከተው 🎁",
      "time": "ትናንት",
      "unread": 0,
      "online": false,
    },
    {
      "name": "Selam",
      "avatar": "🧕",
      "lastMsg": "ወደ ጢስ አባይ ክፍል እየመጣሁ ነው 🌊",
      "time": "ትናንት",
      "unread": 1,
      "online": true,
    },
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F1E),
      appBar: AppBar(
        backgroundColor: const Color(0xFF16162A),
        elevation: 0,
        title: const Text(
          "Messages",
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20, color: Colors.white),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.done_all, color: Color(0xFFFFD700)),
            tooltip: "ሁሉንም እንደተነበበ አድርግ",
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("ሁሉም መልዕክቶች እንደተነበቡ ተደርገዋል")),
              );
            },
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: const Color(0xFFFFD700),
          labelColor: const Color(0xFFFFD700),
          unselectedLabelColor: Colors.white60,
          tabs: const [
            Tab(text: "Chats"),
            Tab(text: "System"),
            Tab(text: "Invites"),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // 1. የግል ቻቶች (Chats List)
          _buildChatList(),

          // 2. የሲስተም ማሳወቂያዎች (System Notices)
          _buildSystemNotices(),

          // 3. የክፍል ጥሪዎች (Party Invites)
          _buildInvitesList(),
        ],
      ),
    );
  }

  Widget _buildChatList() {
    return Column(
      children: [
        // Search Box
        Padding(
          padding: const EdgeInsets.all(12.0),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            decoration: BoxDecoration(
              color: const Color(0xFF1E1B38),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const TextField(
              style: TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: "መልዕክት ወይም ጓደኛ ፈልግ...",
                hintStyle: TextStyle(color: Colors.white38, fontSize: 13),
                icon: Icon(Icons.search, color: Colors.white38, size: 20),
                border: InputBorder.none,
              ),
            ),
          ),
        ),

        // Chat ListView
        Expanded(
          child: ListView.separated(
            itemCount: _chats.length,
            separatorBuilder: (_, __) => const Divider(color: Colors.white10, height: 1),
            itemBuilder: (context, index) {
              final chat = _chats[index];
              return ListTile(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(

builder: (_) => ChatConversationScreen(userName: chat["name"]),
                    ),
                  );
                },
                leading: Stack(
                  children: [
                    CircleAvatar(
                      radius: 24,
                      backgroundColor: const Color(0xFF23233E),
                      child: Text(chat["avatar"], style: const TextStyle(fontSize: 22)),
                    ),
                    if (chat["online"])
                      Positioned(
                        right: 0,
                        bottom: 0,
                        child: Container(
                          width: 12,
                          height: 12,
                          decoration: BoxDecoration(
                            color: Colors.greenAccent,
                            shape: BoxShape.circle,
                            border: Border.all(color: const Color(0xFF0F0F1E), width: 2),
                          ),
                        ),
                      ),
                  ],
                ),
                title: Text(
                  chat["name"],
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
                ),
                subtitle: Text(
                  chat["lastMsg"],
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Colors.white60, fontSize: 13),
                ),
                trailing: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(chat["time"], style: const TextStyle(color: Colors.white38, fontSize: 11)),
                    const SizedBox(height: 4),
                    if (chat["unread"] > 0)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFD700),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          "${chat['unread']}",
                          style: const TextStyle(color: Colors.black, fontSize: 10, fontWeight: FontWeight.bold),
                        ),
                      ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildSystemNotices() {
    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        _systemCard(
          title: "የአካውንት ደህንነት ማስታወቂያ",
          desc: "እንኳን ወደ 3D Voice Party በደህና መጡ! የአካውንቶን መረጃ ለማንም አያጋሩ።",
          time: "ዛሬ",
          icon: Icons.security,
        ),
        _systemCard(
          title: "የኮይን ስጦታ ተበርክቶሎታል!",
          desc: "የመጀመሪያ መግቢያህን በማክበር 1,250 ነፃ ኮይኖች ተሸልመሃል።",
          time: "ትናንት",
          icon: Icons.monetization_on,
        ),
      ],
    );
  }

  Widget _buildInvitesList() {
    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0xFF1E1B38),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            children: [
              const CircleAvatar(
                backgroundColor: Color(0xFFFFD700),
                child: Icon(Icons.spatial_audio, color: Colors.black),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,

children: [
                    Text("Kedir Umer ጠርቶዎታል", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    Text("ክፍል: Abay Falls 3D Lounge 🌊", style: TextStyle(color: Colors.white60, fontSize: 12)),
                  ],
                ),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFFD700),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () {},
                child: const Text("ግባ", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _systemCard({required String title, required String desc, required String time, required IconData icon}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1B38),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            backgroundColor: Colors.blueAccent.withOpacity(0.2),
            child: Icon(icon, color: Colors.blueAccent),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                const SizedBox(height: 4),
                Text(desc, style: const TextStyle(color: Colors.white60, fontSize: 12)),
                const SizedBox(height: 6),
                Text(time, style: const TextStyle(color: Colors.white38, fontSize: 10)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ==================== የቀጥታ የግል ቻት ገጽ (CHAT ROOM) ====================
class ChatConversationScreen extends StatefulWidget {
  final String userName;
  const ChatConversationScreen({super.key, required this.userName});

  @override
  State<ChatConversationScreen> createState() => _ChatConversationScreenState();
}

class _ChatConversationScreenState extends State<ChatConversationScreen> {
  final TextEditingController _textController = TextEditingController();
  final List<Map<String, dynamic>> _messages = [
    {"sender": "them", "text": "ሰላም ከድር እንዴት ነህ?"},
    {"sender": "me", "text": "አለውልህ! አዲሱ 3D ድምፅ አፕ ተመችቶሃል?"},
    {"sender": "them", "text": "በጣም አሪፍ ነው፤ የአባይ ፏፏቴ ዳራውም ያምራል!"},
  ];

  void _sendMessage() {
    if (_textController.text.trim().isNotEmpty) {
      setState(() {
        _messages.add({
          "sender": "me",
          "text": _textController.text.trim(),
        });
      });
      _textController.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F1E),
      appBar: AppBar(
        backgroundColor: const Color(0xFF16162A),
        title: Text(widget.userName, style: const TextStyle(color: Colors.white, fontSize: 17)),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final isMe = _messages[index]["sender"] == "me";
                return Align(
                  alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),

decoration: BoxDecoration(
                      color: isMe ? const Color(0xFFFFD700) : const Color(0xFF1E1B38),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      _messages[index]["text"],
                      style: TextStyle(
                        color: isMe ? Colors.black : Colors.white,
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
            color: const Color(0xFF16162A),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    decoration: BoxDecoration(
                      color: const Color(0xFF23233E),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: TextField(
                      controller: _textController,
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(
                        hintText: "መልዕክት ፃፍ...",
                        hintStyle: TextStyle(color: Colors.white38),
                        border: InputBorder.none,
                      ),
                      onSubmitted: (_) => _sendMessage(),
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.send, color: Color(0xFFFFD700)),
                  onPressed: _sendMessage,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
