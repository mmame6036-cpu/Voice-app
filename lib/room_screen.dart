import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:permission_handler/permission_handler.dart';
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
  RtcEngine? _engine;
  bool isJoinedVoice = false;
  bool isMuted = false;

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
    _initAgoraVoice();

    _bannerTimer = Timer.periodic(const Duration(seconds: 4), (timer) {
      if (mounted) {
        setState(() {
          liveAnnouncements.add('🔥 Room activity active now!');
          if (liveAnnouncements.length > 5) liveAnnouncements.removeAt(0);
        });
      }
    });
  }

  // የአጎራ ድምፅ ሞተር ማስጀመሪያ
  Future<void> _initAgoraVoice() async {
    try {
      // 1. የማይክሮፎን ፈቃድ መጠየቅ
      await Permission.microphone.request();

      // 2. የአጎራ ሞተር ማዘጋጀት
      _engine = createAgoraRtcEngine();
      await _engine!.initialize(const RtcEngineContext(
        appId: AppData.agoraAppId,
        channelProfile: ChannelProfileType.channelProfileLiveBroadcasting,
      ));

      _engine!.registerEventHandler(
        RtcEngineEventHandler(
          onJoinChannelSuccess: (RtcConnection connection, int elapsed) {
            debugPrint('Agora Voice Joined: ${connection.channelId}');
            if (mounted) {
              setState(() => isJoinedVoice = true);
            }
          },
          onUserJoined: (RtcConnection connection, int remoteUid, int elapsed) {
            debugPrint('Remote user joined voice: $remoteUid');
          },
          onError: (ErrorCodeType err, String msg) {
            debugPrint('Agora Error: $err - $msg');
          },
        ),
      );

      // 3. ድምፅ ማስተካከያዎች
      await _engine!.setClientRole(role: ClientRoleType.clientRoleBroadcaster);
      await _engine!.enableAudio();
      await _engine!.enableLocalAudio(true);
      await _engine!.muteLocalAudioStream(false);
      await _engine!.setDefaultAudioRouteToSpeakerphone(true);

      // 4. ከ Render ሰርቨርህ ቶከን መጠየቅ (በ dart:io HttpClient አማካኝነት)
      const String channelName = 'NileVoiceMainRoom';
      String rtcToken = '';

      try {
        final client = HttpClient();
        client.connectionTimeout = const Duration(seconds: 10);
        final request = await client.getUrl(
          Uri.parse('${AppData.serverUrl}/rtc-token?channelName=$channelName&uid=0'),
        );
        final response = await request.close();
        if (response.statusCode == 200) {
          final responseBody = await response.transform(utf8.decoder).join();
          final data = jsonDecode(responseBody);
          rtcToken = data['token'] ?? '';
          debugPrint('Token fetched successfully!');
        }
      } catch (tokenErr) {
        debugPrint('Token fetch error: $tokenErr');
      }

      // 5. በቶከኑ ወደ ድምፅ ክፍሉ መግባት
      await _engine!.joinChannel(
        token: rtcToken,
        channelId: channelName,

uid: 0,
        options: const ChannelMediaOptions(
          clientRoleType: ClientRoleType.clientRoleBroadcaster,
          channelProfile: ChannelProfileType.channelProfileLiveBroadcasting,
          publishMicrophoneTrack: true,
          autoSubscribeAudio: true,
        ),
      );
    } catch (e) {
      debugPrint('Agora init error: $e');
    }
  }

  // ማይክራፎን ማብሪያና ማጥፊያ
  void _toggleMic() async {
    if (_engine == null) return;
    setState(() {
      isMuted = !isMuted;
    });
    await _engine!.muteLocalAudioStream(isMuted);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(isMuted ? '🔇 ማይክራፎን ተዘግቷል' : '🎙️ ማይክራፎን ተከፍቷል'),
        duration: const Duration(milliseconds: 700),
      ),
    );
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
          'room': 'NileVoiceMainRoom',
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
              if (user == AppData.currentUserName) {
                isMuted = false;
                _engine?.muteLocalAudioStream(false);
              }
            } else {
              occupiedChairs.remove(chair);
              chatMessages.add('$user left chair #$chair');
              if (user == AppData.currentUserName) {
                isMuted = true;
                _engine?.muteLocalAudioStream(true);
              }
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
    _engine?.leaveChannel();
    _engine?.release();
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
                // 1. የላይኛው ራስጌ
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
                              'ID: ${AppData.currentUserId}',
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.5),
                                fontSize: 10,
                              ),
                            ),
                          ],
                        ),
                      ),
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

                // 2. ባነር
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

                // 3. ወንበሮችና ቻት
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

                // 4. ታችኛው ባር
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  color: Colors.black.withOpacity(0.6),
                  child: Row(
                    children: [
                      GestureDetector(
                        onTap: _toggleMic,
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          margin: const EdgeInsets.only(right: 8),
                          decoration: BoxDecoration(
                            color: isMuted ? Colors.white12 : Colors.green.withOpacity(0.3),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: isMuted ? Colors.white24 : Colors.greenAccent,
                            ),
                          ),
                          child: Icon(
                            isMuted ? Icons.mic_off_rounded : Icons.mic_rounded,
                            color: isMuted ? Colors.white54 : Colors.greenAccent,
                            size: 20,
                          ),
                        ),
                      ),
                      Expanded(
                        child: Container(
                          height: 38,
                          margin: const EdgeInsets.only(right: 8),
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
                      Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.sports_esports_rounded, color: Colors.amberAccent, size: 24),
                            onPressed: () {
                              RoomGamesSheet.show(
                                context,
                                socket: socket,
                                onCoinsChanged: () => setState(() {}),
                              );
                            },
                          ),
                          IconButton(
                            icon: const Icon(Icons.card_giftcard_rounded, color: Color(0xFFFFD700), size: 24),
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
