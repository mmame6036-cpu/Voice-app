KEDER:
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
    {'user': 'System', 'text': 'Welcome to the live room! Please follow community rules.'},
  ];

  late List<Map<String, dynamic>> _seats;

  @override
  void initState() {
    super.initState();
    // 8 የማይክ መቀመጫዎች
    _seats = List.generate(
      8,
      (index) => {
        'index': index + 1,
        'user': index == 0 ? widget.hostName : null,
        'userId': index == 0 ? widget.roomId : null,
        'isSpeaking': false,
        'isMuted': false,
      },
    );
  }

  // ወንበር ላይ የመቀመጥ ወይም የመውረድ ተግባር
  void _handleSeatTap(int index) {
    final seat = _seats[index];
    final currentUser = _user.userName;
    final currentUserId = _user.userId;

    // ተጠቃሚው አስቀድሞ በዚህ ወንበር ላይ ተቀምጦ ከሆነ
    if (seat['user'] == currentUser) {
      showModalBottomSheet(
        context: context,
        backgroundColor: const Color(0xFF161B26),
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
        builder: (ctx) => Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.exit_to_app, color: Colors.redAccent),
                title: const Text('Leave Mic Seat', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                onTap: () {
                  Navigator.pop(ctx);
                  setState(() {
                    seat['user'] = null;
                    seat['userId'] = null;
                    seat['isSpeaking'] = false;
                    _messages.add({'user': 'System', 'text': '$currentUser left seat ${index + 1}'});
                  });
                },
              ),
            ],
          ),
        ),
      );
      return;
    }

    // ወንበሩ በሌላ ሰው ተይዞ ከሆነ
    if (seat['user'] != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Seat ${index + 1} is occupied by ${seat['user']}'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    // ወንበሩ ባዶ ከሆነ፦ ተጠቃሚውን ከሌላ ወንበር አውርዶ እዚህ ያስቀምጠዋል
    setState(() {
      for (var s in _seats) {
        if (s['user'] == currentUser) {
          s['user'] = null;
          s['userId'] = null;
          s['isSpeaking'] = false;
        }
      }
      seat['user'] = currentUser;
      seat['userId'] = currentUserId;
      seat['isSpeaking'] = true;
      _messages.add({'user': 'System', 'text': '$currentUser joined seat ${index + 1}'});
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('You took seat ${index + 1} 🎤'),
        backgroundColor: const Color(0xFF00C9A7),
      ),
    );
  }

  void _sendMessage() {
    final text = _msgController.text.trim();
    if (text.isEmpty) return;
    setState(() {
      _messages.add({'user': _user.userName, 'text': text});
      _msgController.clear();
    });
  }

  void _openGiftSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF161B26),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),

),
      builder: (context) {
        final gifts = [
          {'name': 'Rose', 'price': 10, 'icon': Icons.local_florist, 'color': Colors.pinkAccent},
          {'name': 'Heart', 'price': 50, 'icon': Icons.favorite, 'color': Colors.redAccent},
          {'name': 'Crown', 'price': 500, 'icon': Icons.military_tech, 'color': Colors.amber},
          {'name': 'Rocket', 'price': 2000, 'icon': Icons.rocket_launch, 'color': Colors.purpleAccent},
          {'name': 'Diamond', 'price': 5000, 'icon': Icons.diamond, 'color': Colors.cyanAccent},
          {'name': 'Super Car', 'price': 10000, 'icon': Icons.directions_car, 'color': Colors.orangeAccent},
        ];

        return Container(
          padding: const EdgeInsets.all(20),
          height: 380,
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Send Gift', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                  Row(
                    children: [
                      const Icon(Icons.monetization_on, color: Colors.amber, size: 18),
                      const SizedBox(width: 4),
                      Text('${_user.coins}', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.amber)),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Expanded(
                child: GridView.builder(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    childAspectRatio: 0.95,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                  ),
                  itemCount: gifts.length,
                  itemBuilder: (context, index) {
                    final gift = gifts[index];
                    return GestureDetector(
                      onTap: () {
                        Navigator.pop(context);
                        setState(() {
                          _messages.add({
                            'user': 'Announcement',
                            'text': '${_user.userName} sent a ${gift['name']}! 🎉',
                          });
                        });
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          color: const Color(0xFF0F141C),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.white10),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(gift['icon'] as IconData, size: 36, color: gift['color'] as Color),
                            const SizedBox(height: 6),
                            Text(gift['name'] as String, style: const TextStyle(color: Colors.white, fontSize: 13)),
                            const SizedBox(height: 4),
                            Text('${gift['price']} Coins', style: const TextStyle(color: Colors.white54, fontSize: 11)),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0E17),
      body: SafeArea(
        child: Column(
          children: [
            // 1. Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),

child: Row(
                children: [
                  CircleAvatar(
                    radius: 20,
                    backgroundColor: const Color(0xFF00C9A7),
                    child: Text(
                      widget.hostName.isNotEmpty ? widget.hostName[0].toUpperCase() : 'H',
                      style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.roomTitle,
                          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          'ID: ${widget.roomId} • Host: ${widget.hostName}',
                          style: const TextStyle(fontSize: 11, color: Colors.white54),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white70),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),

            const Divider(color: Colors.white10, height: 1),

            // 2. 8 Mic Seats (ሙሉ ንክኪ ያለው)
            Padding(
              padding: const EdgeInsets.all(16),
              child: GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 4,
                  mainAxisSpacing: 14,
                  crossAxisSpacing: 14,
                  childAspectRatio: 0.8,
                ),
                itemCount: _seats.length,
                itemBuilder: (context, index) {
                  final seat = _seats[index];
                  final hasUser = seat['user'] != null;
                  final isSpeaking = seat['isSpeaking'] == true;

                  return GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () => _handleSeatTap(index),
                    child: Column(
                      children: [
                        Stack(
                          alignment: Alignment.center,
                          children: [
                            if (isSpeaking)
                              Container(
                                width: 58,
                                height: 58,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(color: const Color(0xFF00C9A7), width: 2.5),
                                ),
                              ),
                            CircleAvatar(
                              radius: 24,
                              backgroundColor: hasUser ? const Color(0xFF1F2937) : Colors.white10,
                              child: hasUser
                                  ? const Icon(Icons.person, color: Color(0xFF00C9A7), size: 28)
                                  : const Icon(Icons.mic_none, color: Colors.white38, size: 22),
                            ),
                            Positioned(
                              bottom: 0,
                              right: 0,
                              child: Container(
                                padding: const EdgeInsets.all(3),

decoration: const BoxDecoration(
                                  color: Color(0xFF161B26),
                                  shape: BoxShape.circle,
                                ),
                                child: Text(
                                  '${seat['index']}',
                                  style: const TextStyle(fontSize: 9, color: Colors.white70, fontWeight: FontWeight.bold),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          hasUser ? seat['user'] : 'Empty',
                          style: TextStyle(
                            fontSize: 11,
                            color: hasUser ? Colors.white : Colors.white38,
                            fontWeight: hasUser ? FontWeight.w600 : FontWeight.normal,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),

            // 3. Real-time Messages Feed
            Expanded(
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF161B26).withOpacity(0.6),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: ListView.builder(
                  reverse: true,
                  itemCount: _messages.length,
                  itemBuilder: (context, index) {
                    final msg = _messages[_messages.length - 1 - index];
                    final isSystem = msg['user'] == 'System' || msg['user'] == 'Announcement';

                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: RichText(
                        text: TextSpan(
                          children: [
                            TextSpan(
                              text: '${msg['user']}: ',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: isSystem ? const Color(0xFF00C9A7) : Colors.amber,
                                fontSize: 13,
                              ),
                            ),
                            TextSpan(
                              text: msg['text'],
                              style: TextStyle(
                                color: isSystem ? Colors.white70 : Colors.white,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),

            const SizedBox(height: 10),

            // 4. Bottom Controls
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      height: 44,
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: const Color(0xFF161B26),
                        borderRadius: BorderRadius.circular(22),
                        border: Border.all(color: Colors.white12),
                      ),

child: Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _msgController,
                              style: const TextStyle(color: Colors.white, fontSize: 13),
                              decoration: const InputDecoration(
                                hintText: 'Type message...',
                                hintStyle: TextStyle(color: Colors.white38, fontSize: 13),
                                border: InputBorder.none,
                              ),
                              onSubmitted: (_) => _sendMessage(),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.send, color: Color(0xFF00C9A7), size: 18),
                            onPressed: _sendMessage,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  CircleAvatar(
                    radius: 22,
                    backgroundColor: const Color(0xFF161B26),
                    child: IconButton(
                      icon: Icon(
                        _isMicMuted ? Icons.mic_off : Icons.mic,
                        color: _isMicMuted ? Colors.redAccent : const Color(0xFF00C9A7),
                        size: 20,
                      ),
                      onPressed: () => setState(() => _isMicMuted = !_isMicMuted),
                    ),
                  ),
                  const SizedBox(width: 8),
                  CircleAvatar(
                    radius: 22,
                    backgroundColor: Colors.amber,
                    child: IconButton(
                      icon: const Icon(Icons.card_giftcard, color: Colors.black, size: 20),
                      onPressed: _openGiftSheet,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
