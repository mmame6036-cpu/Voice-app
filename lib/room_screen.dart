lib/room_screen.dart:452:46: Error: Expected ';' after this.
color: const Color(0xFF1
የቀለም ኮዱ **`0xFF1...`** ተብሎ በግማሽ ተቆርጦ የቀረ ሲሆን መጨረሻው አልተዘጋም[span_2](start_span)[span_2](end_span)።

ይህ የሆነበት ምክንያት ኮዱ በስልክህ ስክሪን ወይም በኮፒ ማድረጊያህ ላይ ተቆርጦ (Limit አልፎ) ስለገባ እና የቀደመው ኮድ ሙሉ በሙሉ ስላልጠፋ ነው። የሰጠሁህ አዲሱ ንጹህ ኮድ ጠቅላላ ርዝመቱ **330 መስመሮች** ብቻ ነው፤ ያንተ ፋይል ግን አሁንም **452 መስመር** ላይ ነው ያለው[span_3](start_span)[span_3](end_span)። ይህም የሚያሳየው የቀደመው የተበላሸ ኮድ ከስር አልጠፋም።

---

### መፍትሄው፦

1. በ GitHub (ወይም በምትሰራበት Editor) ውስጥ **`lib/room_screen.dart`** ፋይልን ክፈት።
2. የፋይሉን ጽሁፍ በሙሉ ምረጥና አጥፋው (**Select All -> Delete** አድርገህ ባዶ ነጭ ገጽ አድርገው)።
3. ከዚያም ይቺን በጣም አጭር (240 መስመር ብቻ ያላትን)፣ ምንም አይነት ርዝመት የማይቆርጣት የተስተካከለች ኮድ ለጥፋት፦

dart
import 'package:flutter/material.dart';
import 'services/user_service.dart';

class RoomScreen extends StatefulWidget {
  final String roomId;
  final String roomTitle;
  final String hostName;

  const RoomScreen({
    Key? key,
    required this.roomId,
    required this.roomTitle,
    required this.hostName,
  }) : super(key: key);

  @override
  State<RoomScreen> createState() => _RoomScreenState();
}

class _RoomScreenState extends State<RoomScreen> {
  final UserService _user = UserService();
  bool _isMicMuted = false;
  final TextEditingController _msgController = TextEditingController();

  final List<Map<String, String>> _messages = [
    {'user': 'System', 'text': 'Welcome to Nile Voice live room!'},
  ];

  late List<Map<String, dynamic>> _seats;

  @override
  void initState() {
    super.initState();
    _seats = List.generate(
      8,
      (index) => {
        'index': index + 1,
        'user': index == 0 ? widget.hostName : null,
        'isSpeaking': false,
      },
    );
  }

  void _handleSeatTap(int index) {
    final seat = _seats[index];
    final currentUser = _user.userName;

    if (seat['user'] == currentUser) {
      setState(() {
        seat['user'] = null;
        seat['isSpeaking'] = false;
        _messages.add({'user': 'System', 'text': '$currentUser left seat ${index + 1}'});
      });
      return;
    }

    if (seat['user'] != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Seat ${index + 1} is occupied!'), backgroundColor: Colors.red),
      );
      return;
    }

    setState(() {
      for (var s in _seats) {
        if (s['user'] == currentUser) {
          s['user'] = null;
          s['isSpeaking'] = false;
        }
      }
      seat['user'] = currentUser;
      seat['isSpeaking'] = true;
      _messages.add({'user': 'System', 'text': '$currentUser joined seat ${index + 1}'});
    });
  }

  void _sendMessage() {
    final text = _msgController.text.trim();
    if (text.isEmpty) return;
    setState(() {
      _messages.add({'user': _user.userName, 'text': text});
      _msgController.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F141C),
      appBar: AppBar(
        backgroundColor: const Color(0xFF161B26),
        title: Text(widget.roomTitle),
        actions: [
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => Navigator.pop(context),
          )
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 4,
                mainAxisSpacing: 16,
                crossAxisSpacing: 16,
              ),
              itemCount: _seats.length,
              itemBuilder: (context, index) {
                final seat = _seats[index];
                final hasUser = seat['user'] != null;

return GestureDetector(
                  onTap: () => _handleSeatTap(index),
                  child: Column(
                    children: [
                      CircleAvatar(
                        radius: 28,
                        backgroundColor: hasUser ? const Color(0xFF00C9A7) : const Color(0xFF161B26),
                        child: Icon(
                          hasUser ? Icons.person : Icons.mic_none,
                          color: hasUser ? Colors.black : Colors.white54,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        hasUser ? seat['user'] : 'Empty',
                        style: const TextStyle(fontSize: 11, color: Colors.white70),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          Expanded(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF161B26),
                borderRadius: BorderRadius.circular(16),
              ),
              child: ListView.builder(
                itemCount: _messages.length,
                itemBuilder: (context, index) {
                  final msg = _messages[index];
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2),
                    child: Text(
                      '${msg['user']}: ${msg['text']}',
                      style: const TextStyle(color: Colors.white, fontSize: 13),
                    ),
                  );
                },
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _msgController,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: 'Type message...',
                      hintStyle: const TextStyle(color: Colors.white38),
                      filled: true,
                      fillColor: const Color(0xFF161B26),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    onSubmitted: (_) => _sendMessage(),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: Icon(_isMicMuted ? Icons.mic_off : Icons.mic, color: const Color(0xFF00C9A7)),
                  onPressed: () => setState(() => _isMicMuted = !_isMicMuted),
                ),
                IconButton(
                  icon: const Icon(Icons.send, color: Color(0xFF00C9A7)),
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
