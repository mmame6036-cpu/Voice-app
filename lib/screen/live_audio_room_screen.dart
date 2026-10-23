import 'package:flutter/material.dart';

class LiveAudioRoomScreen extends StatefulWidget {
  final String roomTitle;
  const LiveAudioRoomScreen({Key? key, this.roomTitle = 'Voice Party Room'}) : super(key: key);

  @override
  State<LiveAudioRoomScreen> createState() => _LiveAudioRoomScreenState();
}

class _LiveAudioRoomScreenState extends State<LiveAudioRoomScreen> {
  bool _isMicMuted = false;
  final TextEditingController _messageController = TextEditingController();
  final List<Map<String, String>> _messages = [
    {'user': 'System', 'text': 'Welcome to the party room! Keep it friendly.'},
  ];

  void _sendMessage() {
    if (_messageController.text.trim().isEmpty) return;
    setState(() {
      _messages.add({
        'user': 'Me',
        'text': _messageController.text.trim(),
      });
    });
    _messageController.clear();
  }

  void _showGiftSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          height: 280,
          decoration: const BoxDecoration(
            color: Color(0xFF1E1B4B),
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(24),
              topRight: Radius.circular(24),
            ),
          ),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Send Gift',
                style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: GridView.count(
                  crossAxisCount: 4,
                  children: [
                    _buildGiftItem('🌹', 'Rose', '10 Coins'),
                    _buildGiftItem('👑', 'Crown', '100 Coins'),
                    _buildGiftItem('🚀', 'Rocket', '500 Coins'),
                    _buildGiftItem('💎', 'Diamond', '1000 Coins'),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildGiftItem(String emoji, String name, String price) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(emoji, style: const TextStyle(fontSize: 32)),
        const SizedBox(height: 4),
        Text(name, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
        Text(price, style: const TextStyle(color: Colors.amber, fontSize: 10)),
      ],
    );
  }

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A), // Dark stylish background
      body: SafeArea(
        child: Column(
          children: [
            // 1. የክፍሉ ራስጌ (Header)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      children: [
                        const CircleAvatar(
                          radius: 14,
                          backgroundColor: Colors.blueAccent,
                          child: Icon(Icons.person, color: Colors.white, size: 16),
                        ),
                        const SizedBox(width: 8),

Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.roomTitle,
                              style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                            ),
                            const Text(
                              'ID: 984210',
                              style: TextStyle(color: Colors.white70, fontSize: 10),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),

            // 2. 8ቱ የማይክራፎን መቀመጫዎች (Seat Grid)
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: 8,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 4,
                  mainAxisSpacing: 14,
                  crossAxisSpacing: 14,
                  childAspectRatio: 0.8,
                ),
                itemBuilder: (context, index) {
                  bool isHostSeat = index == 0;
                  return Column(
                    children: [
                      Stack(
                        alignment: Alignment.bottomRight,
                        children: [
                          CircleAvatar(
                            radius: 28,
                            backgroundColor: isHostSeat ? Colors.blueAccent : Colors.white.withOpacity(0.1),
                            child: Icon(
                              isHostSeat ? Icons.person : Icons.mic_none_rounded,
                              color: isHostSeat ? Colors.white : Colors.white38,
                              size: 26,
                            ),
                          ),
                          if (isHostSeat && _isMicMuted)
                            const CircleAvatar(
                              radius: 8,
                              backgroundColor: Colors.red,
                              child: Icon(Icons.mic_off, size: 10, color: Colors.white),
                            ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        isHostSeat ? 'Host' : '${index + 1}',
                        style: const TextStyle(color: Colors.white70, fontSize: 11),
                      ),
                    ],
                  );
                },
              ),
            ),

            const Spacer(),

            // 3. የቀጥታ የጽሑፍ መልዕክቶች ቦታ (Chat Area)
            Container(
              height: 160,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: ListView.builder(
                reverse: true,
                itemCount: _messages.length,
                itemBuilder: (context, index) {
                  final msg = _messages[_messages.length - 1 - index];
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 3),
                    child: RichText(
                      text: TextSpan(
                        children: [
                          TextSpan(
                            text: '${msg['user']}: ',
                            style: const TextStyle(color: Colors.amberAccent, fontWeight: FontWeight.bold, fontSize: 13),

),
                          TextSpan(
                            text: msg['text'],
                            style: const TextStyle(color: Colors.white, fontSize: 13),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),

            // 4. የታችኛው መቆጣጠሪያ ባር (Bottom Bar)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      height: 42,
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(21),
                      ),
                      child: TextField(
                        controller: _messageController,
                        style: const TextStyle(color: Colors.white, fontSize: 13),
                        decoration: InputDecoration(
                          hintText: 'Say something...',
                          hintStyle: const TextStyle(color: Colors.white54, fontSize: 13),
                          border: InputBorder.none,
                          suffixIcon: IconButton(
                            icon: const Icon(Icons.send, color: Colors.blueAccent, size: 18),
                            onPressed: _sendMessage,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  // የማይክራፎን ማብሪያ/ማጥፊያ ቁልፍ
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        _isMicMuted = !_isMicMuted;
                      });
                    },
                    child: CircleAvatar(
                      radius: 21,
                      backgroundColor: _isMicMuted ? Colors.red.withOpacity(0.2) : Colors.white.withOpacity(0.15),
                      child: Icon(
                        _isMicMuted ? Icons.mic_off : Icons.mic,
                        color: _isMicMuted ? Colors.redAccent : Colors.white,
                        size: 20,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  // የስጦታ (Gift) ቁልፍ
                  GestureDetector(
                    onTap: _showGiftSheet,
                    child: const CircleAvatar(
                      radius: 21,
                      backgroundColor: Colors.amber,
                      child: Icon(Icons.card_giftcard, color: Colors.black, size: 20),
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
