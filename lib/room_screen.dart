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
    {'user': 'System', 'text': 'Please protect your privacy and stay safe.'},
    {'user': 'Announcement', 'text': 'Welcome to Nile Voice live party room!'},
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

  void _handleSeatTap(int index) {
    final seat = _seats[index];
    final currentUser = _user.userName;
    final currentUserId = _user.userId;

    if (seat['user'] == currentUser) {
      showModalBottomSheet(
        context: context,
        backgroundColor: const Color(0xFF1E2536),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        builder: (ctx) => Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.exit_to_app, color: Colors.redAccent),
                title: const Text(
                  'Leave Mic Seat',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                ),
                onTap: () {
                  Navigator.pop(ctx);
                  setState(() {
                    seat['user'] = null;
                    seat['userId'] = null;
                    seat['isSpeaking'] = false;
                    _messages.add({
                      'user': 'System',
                      'text': '$currentUser left seat ${index + 1}',
                    });
                  });
                },
              ),
            ],
          ),
        ),
      );
      return;
    }

    if (seat['user'] != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Seat ${index + 1} is occupied by ${seat['user']}'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

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
      _messages.add({
        'user': 'System',
        'text': '$currentUser took seat ${index + 1}',
      });
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

  void _openGiftSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF161C2B),
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
                  const Text(
                    'Send Gift',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                  Row(
                    children: [
                      const Icon(Icons.monetization_on, color: Colors.amber, size: 20),
                      const SizedBox(width: 4),
                      Text(
                        '${_user.coins}',
                        style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.amber, fontSize: 16),
                      ),
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
                            'text': '${_user.userName} sent a ${gift['name']}! 🎁',
                          });
                        });
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          color: const Color(0xFF222C3D),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.white12),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(gift['icon'] as IconData, size: 36, color: gift['color'] as Color),
                            const SizedBox(height: 6),
                            Text(
                              gift['name'] as String,
                              style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${gift['price']} Coins',
                              style: const TextStyle(color: Colors.amber, fontSize: 11),
                            ),
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
      body: Stack(
        children: [
          // 1. የጀርባ ገጽታ
          Positioned.fill(
            child: Image.network(
              'https://images.unsplash.com/photo-1518709268805-4e9042af9f23?q=80&w=1000&auto=format&fit=crop',
              fit: BoxFit.cover,
            ),
          ),
          Positioned.fill(
            child: Container(
              color: Colors.black.withOpacity(0.4),
            ),
          ),

          SafeArea(
            child: Column(
              children: [
                // 2. የክፍሉ አናት (Header)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.amber, width: 2),
                        ),
                        child: CircleAvatar(
                          radius: 18,
                          backgroundColor: const Color(0xFF6C5CE7),
                          child: Text(
                            widget.hostName.isNotEmpty ? widget.hostName[0].toUpperCase() : 'H',
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.roomTitle,
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                                shadows: [Shadow(color: Colors.black, blurRadius: 4)],
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              'ID: ${widget.roomId}',
                              style: const TextStyle(fontSize: 11, color: Colors.white70),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.white),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                ),

                // 3. የወንበሮች ዝርዝር (8 Mic Seats)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 4,
                      mainAxisSpacing: 14,
                      crossAxisSpacing: 12,
                      childAspectRatio: 0.8,
                    ),
                    itemCount: _seats.length,
                    itemBuilder: (context, index) {
                      final seat = _seats[index];
                      final hasUser = seat['user'] != null;
                      final isSpeaking = seat['isSpeaking'] == true;
                      final userName = seat['user'] ?? '';

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
                                      border: Border.all(color: const Color(0xFF00FFD5), width: 2.5),
                                      boxShadow: [
                                        BoxShadow(
                                          color: const Color(0xFF00FFD5).withOpacity(0.5),
                                          blurRadius: 8,
                                          spreadRadius: 1,
                                        ),
                                      ],
                                    ),
                                  ),
                                CircleAvatar(
                                  radius: 24,
                                  backgroundColor: hasUser
                                      ? const Color(0xFF6C5CE7)
                                      : Colors.black.withOpacity(0.45),
                                  child: hasUser
                                      ? Text(
                                          userName.isNotEmpty ? userName[0].toUpperCase() : 'U',
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16,
                                          ),
                                        )
                                      : const Icon(Icons.mic_none, color: Colors.white54, size: 22),
                                ),
                                Positioned(
                                  bottom: 0,
                                  right: 0,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                                    decoration: BoxDecoration(
                                      color: Colors.black.withOpacity(0.7),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      '${seat['index']}',
                                      style: const TextStyle(
                                        fontSize: 9,
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              hasUser ? userName : '${seat['index']}',
                              style: const TextStyle(
                                fontSize: 11,
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                shadows: [Shadow(color: Colors.black, blurRadius: 4)],
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

                const Spacer(),

                // 4. የቻት መስኮት (Chat Feed)
                Container(
                  height: 160,
                  margin: const EdgeInsets.symmetric(horizontal: 14),
                  padding: const EdgeInsets.all(8),
                  child: ListView.builder(
                    reverse: true,
                    itemCount: _messages.length,
                    itemBuilder: (context, index) {
                      final msg = _messages[_messages.length - 1 - index];
                      final isSystem = msg['user'] == 'System' || msg['user'] == 'Announcement';

                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 2),
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.4),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: RichText(
                              text: TextSpan(
                                children: [
                                  TextSpan(
                                    text: '${msg['user']}: ',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: isSystem ? const Color(0xFF00FFD5) : Colors.amber,
                                      fontSize: 12,
                                    ),
                                  ),
                                  TextSpan(
                                    text: msg['text'],
                                    style: const TextStyle(color: Colors.white, fontSize: 12),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),

                // 5. የታችኛው መቆጣጠሪያ
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  child: Row(
                    children: [
                      Expanded(
                        child: Container(
                          height: 42,
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.5),
                            borderRadius: BorderRadius.circular(21),
                            border: Border.all(color: Colors.white24),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: TextField(
                                  controller: _msgController,
                                  style: const TextStyle(color: Colors.white, fontSize: 13),
                                  decoration: const InputDecoration(
                                    hintText: 'Say Hello...',
                                    hintStyle: TextStyle(color: Colors.white54, fontSize: 13),
                                    border: InputBorder.none,

),
                                  onSubmitted: (_) => _sendMessage(),
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.send, color: Color(0xFF00FFD5), size: 18),
                                onPressed: _sendMessage,
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      CircleAvatar(
                        radius: 20,
                        backgroundColor: Colors.black.withOpacity(0.5),
                        child: IconButton(
                          icon: Icon(
                            _isMicMuted ? Icons.mic_off : Icons.mic,
                            color: _isMicMuted ? Colors.redAccent : Colors.white,
                            size: 18,
                          ),
                          onPressed: () => setState(() => _isMicMuted = !_isMicMuted),
                        ),
                      ),
                      const SizedBox(width: 8),
                      CircleAvatar(
                        radius: 20,
                        backgroundColor: Colors.amber,
                        child: IconButton(
                          icon: const Icon(Icons.card_giftcard, color: Colors.black, size: 18),
                          onPressed: _openGiftSheet,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
