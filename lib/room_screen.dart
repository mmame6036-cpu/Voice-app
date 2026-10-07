import 'dart:async';
import 'package:flutter/material.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'room_chairs_grid.dart';
import 'room_gift_sheet.dart';
import 'room_games_sheet.dart';
import 'recharge_screen.dart';
import 'main.dart';

class RoomScreen extends StatefulWidget {
  final String roomTitle;
  final String hostName;

  RoomScreen({
    Key? key,
    this.roomTitle = 'Ethio Nile Coffee Club',
    this.hostName = 'Kedir oumer',
  }) : super(key: key);

  @override
  State<RoomScreen> createState() => _RoomScreenState();
}

class _RoomScreenState extends State<RoomScreen> {
  IO.Socket? socket;
  List<String> liveAnnouncements = [
    '✨ VIP5 🌟 STAR entered room',
    '🎁 User sent Star x18 and won prizes!',
  ];
  List<String> chatMessages = [
    'System: Please protect your privacy and stay safe.',
  ];
  Map<int, String> occupiedChairs = {};
  Timer? _bannerTimer;

  @override
  void initState() {
    super.initState();
    _connectSocket();

    _bannerTimer = Timer.periodic(const Duration(seconds: 4), (timer) {
      if (mounted) {
        setState(() {
          liveAnnouncements.add('🔥 Room activity active now!');
          if (liveAnnouncements.length > 5) liveAnnouncements.removeAt(0);
        });
      }
    });
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
        socket?.emit('join_room', {
          'room': widget.roomTitle,
          'user': AppData.currentUserName,
        });
      });

      socket?.on('chair_action', (data) {
        if (mounted) {
          setState(() {
            int chair = data['chairNum'];
            String user = data['userName'];
            String action = data['action'];

            if (action == 'join') {
              occupiedChairs.removeWhere((k, v) => v == user);
              occupiedChairs[chair] = user;
              chatMessages.add('$user entered chair #$chair');
            } else {
              occupiedChairs.remove(chair);
              chatMessages.add('$user left chair #$chair');
            }
          });
        }
      });

      socket?.on('gift_sent', (data) {
        if (mounted) {
          setState(() {
            liveAnnouncements.add('🎁 ${data['sender']} sent ${data['giftName']}!');
            chatMessages.add('${data['sender']} sent ${data['giftName']}');
          });
        }
      });

      socket?.on('game_win', (data) {
        if (mounted) {
          setState(() {
            liveAnnouncements.add('🎉 ${data['winner']} won ${data['amount']} in ${data['game']}!');
          });
        }
      });
    } catch (e) {
      debugPrint('Socket error: $e');
    }
  }

  @override
  void dispose() {
    _bannerTimer?.cancel();
    socket?.disconnect();
    socket?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF070B18),
      body: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0xFF0F172A),
                  Color(0xFF090D1C),
                  Color(0xFF02040A),
                ],
              ),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                // 1. የላይኛው ራስጌ (Header)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  child: Row(

children: [
                      CircleAvatar(
                        radius: 18,
                        backgroundColor: Colors.teal,
                        child: Text(
                          widget.hostName.isNotEmpty ? widget.hostName[0] : 'U',
                          style: const TextStyle(color: Colors.white),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.hostName,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                            Text(
                              'ID: 1410685',
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.5),
                                fontSize: 10,
                              ),
                            ),
                          ],
                        ),
                      ),
                      // ሳንቲም ባላንስ ማሳያና ወደ Recharge መግቢያ
                      GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => RechargeScreen(
                                socket: socket,
                                onCoinsUpdated: () => setState(() {}),
                              ),
                            ),
                          );
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: const Color(0xFFFFD700).withOpacity(0.4)),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.monetization_on, color: Color(0xFFFFD700), size: 16),
                              const SizedBox(width: 4),
                              Text(
                                '${AppData.userCoins}',
                                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11),
                              ),
                              const SizedBox(width: 4),
                              const Icon(Icons.add_circle, color: Color(0xFFFFD700), size: 14),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      IconButton(
                        icon: const Icon(Icons.close_rounded, color: Colors.white70),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                ),

                // 2. የቀጥታ ባነር (Live Announcement Banner)
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(

colors: [Color(0xFF880E4F), Color(0xFF4A148C)],
                    ),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFFFD700).withOpacity(0.5)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.auto_awesome, color: Color(0xFFFFD700), size: 16),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          liveAnnouncements.isNotEmpty ? liveAnnouncements.last : '',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 6),

                // 3. ወንበሮች እና ቻት ዝርዝር
                Expanded(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    child: Column(
                      children: [
                        RoomChairsGrid(
                          socket: socket,
                          onChairTap: (chair) => setState(() {}),
                        ),
                        const SizedBox(height: 12),
                        Container(
                          height: 90,
                          margin: const EdgeInsets.symmetric(horizontal: 16),
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.35),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: ListView.builder(
                            itemCount: chatMessages.length,
                            itemBuilder: (context, idx) => Text(
                              chatMessages[idx],
                              style: const TextStyle(color: Colors.white70, fontSize: 11),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // 4. የታችኛው የመቆጣጠሪያ ባር (Bottom Control Bar)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  color: Colors.black.withOpacity(0.6),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // የቻት መጻፊያ ሳጥን
                      Expanded(
                        child: Container(
                          height: 38,
                          margin: const EdgeInsets.only(right: 12),
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          decoration: BoxDecoration(
                            color: Colors.white12,
                            borderRadius: BorderRadius.circular(19),
                          ),
                          child: TextField(
                            style: const TextStyle(color: Colors.white, fontSize: 12),
                            decoration: const InputDecoration(
                              hintText: 'Say Hello...',
                              hintStyle: TextStyle(color: Colors.white38, fontSize: 12),
                              border: InputBorder.none,
                              isDense: true,
                              contentPadding: EdgeInsets.symmetric(vertical: 10),

),
                            onSubmitted: (text) {
                              if (text.trim().isNotEmpty && socket != null) {
                                socket?.emit('chat_message', {
                                  'sender': AppData.currentUserName,
                                  'text': text.trim(),
                                });
                              }
                            },
                          ),
                        ),
                      ),
                      // የጌም እና የስጦታ ቁልፎች
                      Row(
                        children: [
                          IconButton(
                            icon: const Icon(
                              Icons.sports_esports_rounded,
                              color: Colors.amberAccent,
                              size: 26,
                            ),
                            onPressed: () {
                              RoomGamesSheet.show(
                                context,
                                socket: socket,
                                onCoinsChanged: () => setState(() {}),
                              );
                            },
                          ),
                          IconButton(
                            icon: const Icon(
                              Icons.card_giftcard_rounded,
                              color: Color(0xFFFFD700),
                              size: 26,
                            ),
                            onPressed: () {
                              RoomGiftSheet.show(
                                context,
                                socket: socket,
                                onGiftSent: () => setState(() {}),
                              );
                            },
                          ),
                        ],
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
