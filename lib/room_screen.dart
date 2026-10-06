import 'package:flutter/material.dart';
import 'room_chairs_grid.dart';

class RoomScreen extends StatefulWidget {
  final String roomTitle;
  final String hostName;

  const RoomScreen({
    Key? key,
    this.roomTitle = 'Live Room',
    this.hostName = 'Host',
  }) : super(key: key);

  @override
  State<RoomScreen> createState() => _RoomScreenState();
}

class _RoomScreenState extends State<RoomScreen> {
  bool isMuted = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F121C),
      appBar: AppBar(
        backgroundColor: const Color(0xFF161B26),
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.roomTitle,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
            ),
            Text(
              'Host: ${widget.hostName}',
              style: const TextStyle(fontSize: 12, color: Colors.white54),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.share, color: Colors.white70),
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(Icons.close, color: Colors.redAccent),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Column(
            children: [
              const SizedBox(height: 12),

              // Host Stage Header
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF1B2234),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white10),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 28,
                      backgroundColor: Colors.tealAccent.withOpacity(0.2),
                      child: const Icon(Icons.mic, color: Colors.tealAccent, size: 28),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.hostName,
                            style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'Main Stage Host',
                            style: TextStyle(color: Colors.white54, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.redAccent.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Text(
                        'LIVE',
                        style: TextStyle(color: Colors.redAccent, fontSize: 11, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 12),

              // 30 Chairs Grid Section
              const RoomChairsGrid(
                userCoinsSpent: 0,
              ),

              const SizedBox(height: 16),

// Room Chat / Activity Area Placeholder
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                height: 120,
                decoration: BoxDecoration(
                  color: const Color(0xFF131722).withOpacity(0.6),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.white10),
                ),
                alignment: Alignment.center,
                child: const Text(
                  'Welcome to the live stage! Chat will appear here.',
                  style: TextStyle(color: Colors.white38, fontSize: 13),
                ),
              ),

              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        color: const Color(0xFF161B26),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            IconButton(
              icon: Icon(isMuted ? Icons.mic_off : Icons.mic, color: isMuted ? Colors.redAccent : Colors.tealAccent),
              onPressed: () {
                setState(() {
                  isMuted = !isMuted;
                });
              },
            ),
            IconButton(
              icon: const Icon(Icons.card_giftcard, color: Colors.amber),
              onPressed: () {},
            ),
            IconButton(
              icon: const Icon(Icons.message_outlined, color: Colors.white70),
              onPressed: () {},
            ),
          ],
        ),
      ),
    );
  }
}
