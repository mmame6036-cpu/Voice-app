import 'package:flutter/material.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'room_chairs_grid.dart';
import 'room_games_sheet.dart';
import 'main.dart';

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
  IO.Socket? socket;

  @override
  void initState() {
    super.initState();
    _connectSocket();
  }

  void _connectSocket() {
    try {
      socket = IO.io(
        AppData.serverUrl,
        IO.OptionBuilder()
            .setTransports(['websocket'])
            .disableAutoConnect()
            .build(),
      );

      socket?.connect();

      socket?.onConnect((_) {
        // ወደ ክፍሉ መግባትን ለሰርቨር ማሳወቅ
        socket?.emit('join_room', {
          'room': widget.roomTitle,
          'user': AppData.currentUserName,
        });
      });

      // ሌላ ሰው ወንበር ሲይዝ ወይም ሲለቅ ከሰርቨር የሚመጣውን መቀበል
      socket?.on('chair_action', (data) {
        if (mounted) {
          setState(() {
            int chair = data['chairNum'];
            String user = data['userName'];
            String action = data['action'];

            if (action == 'join') {
              occupiedChairs.removeWhere((k, v) => v == user);
              occupiedChairs[chair] = user;
            } else if (action == 'leave') {
              occupiedChairs.remove(chair);
            }
          });
        }
      });
    } catch (e) {
      debugPrint('Socket connection error: $e');
    }
  }

  @override
  void dispose() {
    socket?.disconnect();
    socket?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0C0517),
      appBar: AppBar(
        backgroundColor: const Color(0xFF25103F),
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
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF25103F),
              Color(0xFF150A26),
              Color(0xFF0C0517),
            ],
          ),
        ),
        child: SafeArea(
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
                          border: Border.all(color: Colors.redAccent),
                        ),
                        child: const Row(
                          children: [
                            CircleAvatar(radius: 4, backgroundColor: Colors.redAccent),
                            SizedBox(width: 6),
                            Text('LIVE', style: TextStyle(color: Colors.redAccent, fontSize: 10, fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // Chairs Grid (ሶኬቱ የተሰጠው ክፍል)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: RoomChairsGrid(
                    socket: socket,
                  ),
                ),

                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        color: const Color(0xFF161B26),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            IconButton(
              icon: Icon(isMuted ? Icons.mic_off : Icons.mic, color: Colors.white),
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
              icon: const Icon(Icons.sports_esports_rounded, color: Color(0xFFFFD700)),
              onPressed: () {
                RoomGamesSheet.show(context, onCoinsChanged: () {
                  setState(() {});
                });
              },
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
