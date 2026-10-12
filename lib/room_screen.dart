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
    {'user': 'System', 'text': 'Welcome to Nile Voice 3D room! Please follow community rules.'},
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
        backgroundColor: const Color(0xFF131926),
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
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
                    _messages.add({'user': 'System', 'text': '$currentUser left seat${index + 1}'});
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
          content: Text('Seat ${index + 1} is occupied by${seat['user']}'),
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
      _messages.add({'user': 'System', 'text': '$currentUser joined seat${index + 1} 🎤'});
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
      backgroundColor: const Color(0xFF0F1420),
      shape: const RoundedRectangleBorder(

borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
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
                  const Text('3D Gifts', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
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
                            'text': '${_user.userName} sent a${gift['name']}! 🎉',
                          });
                        });
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(18),
                          gradient: const LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [Color(0xFF1E2638), Color(0xFF0C101A)],
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.6),
                              offset: const Offset(4, 4),
                              blurRadius: 8,
                            ),
                            BoxShadow(
                              color: Colors.white.withOpacity(0.05),
                              offset: const Offset(-2, -2),
                              blurRadius: 4,
                            ),
                          ],
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
      body: Container(
        // 1. ሙሉ ጥልቀት ያለው ባለ 3D የጀርባ ገጽ (Layered 3D Radial Depth Background)
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            center: Alignment(0, -0.4),
            radius: 1.25,
            colors: [
              Color(0xFF1C2438), // የላይኛው ማዕከላዊ ብርሃን
              Color(0xFF0C101A), // መካከለኛው የከባቢ ጥላ
              Color(0xFF05070B), // የታችኛው የጠለቀ 3D ወለል
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // 2. ባለ 3D የወጣ ራስጌ (Floating 3D Header)
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  gradient: const LinearGradient(
                    colors: [Color(0xFF1E283C), Color(0xFF121724)],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.55),
                      offset: const Offset(0, 6),
                      blurRadius: 10,
                    ),
                    BoxShadow(
                      color: Colors.white.withOpacity(0.08),
                      offset: const Offset(0, -1),
                      blurRadius: 2,
                    ),
                  ],
                ),
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

              // 3. ባለ 3D ሉላዊ የማይክ መቀመጫዎች (3D Spheres with Depth & Shadow)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),

gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 4,
                    mainAxisSpacing: 16,
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
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 250),
                            width: 62,
                            height: 62,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              // 3D ሉላዊ የቀለም ቅብ (3D Sphere Gradient)
                              gradient: RadialGradient(
                                center: const Alignment(-0.35, -0.35),
                                radius: 0.85,
                                colors: hasUser
                                    ? [
                                        const Color(0xFF00FFD5),
                                        const Color(0xFF00C9A7),
                                        const Color(0xFF005445),
                                      ]
                                    : [
                                        const Color(0xFF2C3549),
                                        const Color(0xFF181F2E),
                                        const Color(0xFF0B0E17),
                                      ],
                              ),
                              boxShadow: [
                                // የብርሃን የላይኛው ጥላ (Top Light)
                                BoxShadow(
                                  color: Colors.white.withOpacity(hasUser ? 0.35 : 0.08),
                                  offset: const Offset(-4, -4),
                                  blurRadius: 6,
                                ),
                                // የታችኛው የጠለቀ ጥላ (Deep Drop Shadow)
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.85),
                                  offset: const Offset(5, 7),
                                  blurRadius: 10,
                                ),
                                if (isSpeaking)
                                  BoxShadow(
                                    color: const Color(0xFF00FFD5).withOpacity(0.7),
                                    offset: const Offset(0, 0),
                                    blurRadius: 18,
                                    spreadRadius: 2,
                                  ),
                              ],
                            ),
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                Icon(
                                  hasUser ? Icons.person : Icons.mic_none,
                                  color: hasUser ? Colors.black87 : Colors.white30,
                                  size: 28,
                                ),
                                Positioned(
                                  bottom: 2,
                                  right: 2,
                                  child: Container(
                                    padding: const EdgeInsets.all(3),
                                    decoration: const BoxDecoration(

color: Color(0xFF101420),
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
                          ),
                          const SizedBox(height: 6),
                          Text(
                            hasUser ? seat['user'] : 'Empty',
                            style: TextStyle(
                              fontSize: 11,
                              color: hasUser ? Colors.white : Colors.white38,
                              fontWeight: hasUser ? FontWeight.w600 : FontWeight.normal,
                              shadows: hasUser
                                  ? const [Shadow(color: Colors.black, blurRadius: 4, offset: Offset(1, 1))]
                                  : null,
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

              // 4. ባለ 3D የቀጥታ ቻት ሰሌዳ (3D Layered Glass Panel)
              Expanded(
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(22),
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        const Color(0xFF161E2E).withOpacity(0.85),
                        const Color(0xFF0C101A).withOpacity(0.85),
                      ],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.65),
                        offset: const Offset(0, 8),
                        blurRadius: 12,
                      ),
                      BoxShadow(
                        color: Colors.white.withOpacity(0.05),
                        offset: const Offset(0, -1),
                        blurRadius: 3,
                      ),
                    ],
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
                                  color: isSystem ? const Color(0xFF00FFD5) : Colors.amber,
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

              const SizedBox(height: 6),

              // 5. ባለ 3D የታችኛው መቆጣጠሪያ አዝራሮች (3D Floating Buttons)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  children: [
                    Expanded(
                      child: Container(
                        height: 48,
                        padding: const EdgeInsets.symmetric(horizontal: 14),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(24),
                          color: const Color(0xFF101522),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.7),
                              offset: const Offset(3, 3),
                              blurRadius: 6,
                            ),
                            BoxShadow(
                              color: Colors.white.withOpacity(0.05),
                              offset: const Offset(-2, -2),
                              blurRadius: 4,
                            ),
                          ],
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
                              icon: const Icon(Icons.send, color: Color(0xFF00FFD5), size: 18),
                              onPressed: _sendMessage,
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    // 3D Mic Button
