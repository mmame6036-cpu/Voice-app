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

  const RoomScreen({
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
  bool isMuted = false; // ድምፅ ወዲያውኑ ክፍት እንዲሆን
  int myUid = 0;
  int? myChairNum;

  Map<int, String> occupiedChairs = {};
  Map<int, bool> speakingChairs = {};

  List<String> liveAnnouncements = [
    '✨ Welcome to Ethio Nile Room!',
  ];
  List<String> chatMessages = [
    'System: Please protect your privacy and stay safe.',
  ];
  Timer? _bannerTimer;

  @override
  void initState() {
    super.initState();
    // ለእያንዳንዱ ስልክ የተለየ እና ትክክለኛ የቁጥር UID ማዘጋጀት
    final cleanId = AppData.currentUserId.replaceAll(RegExp(r'[^0-9]'), '');
    myUid = int.tryParse(cleanId) ?? 0;
    if (myUid == 0) {
      myUid = (DateTime.now().millisecondsSinceEpoch % 89999) + 10000;
    }

    _connectSocket();
    _initAgoraVoice();

    _bannerTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      if (mounted) {
        setState(() {
          liveAnnouncements.add('🔥 Voice Room Live & Active!');
          if (liveAnnouncements.length > 5) liveAnnouncements.removeAt(0);
        });
      }
    });
  }

  Future<void> _initAgoraVoice() async {
    try {
      // የማይክሮፎን ፈቃድ ማረጋገጥ
      await Permission.microphone.request();

      _engine = createAgoraRtcEngine();
      await _engine!.initialize(RtcEngineContext(
        appId: AppData.agoraAppId,
        channelProfile: ChannelProfileType.channelProfileCommunication,
      ));

      _engine!.registerEventHandler(
        RtcEngineEventHandler(
          onJoinChannelSuccess: (RtcConnection connection, int elapsed) {
            debugPrint('Agora Voice Connected successfully on UID: $myUid');
            if (mounted) {
              setState(() {
                isJoinedVoice = true;
              });
            }
          },
          onUserJoined: (RtcConnection connection, int remoteUid, int elapsed) {
            debugPrint('Remote user entered audio channel: $remoteUid');
          },
          onError: (ErrorCodeType err, String msg) {
            debugPrint('Agora Error: $err - $msg');
          },
        ),
      );

      // ድምፅ ማሰራጫውንና መቀበያውን ሙሉ በሙሉ መክፈት
      await _engine!.enableAudio();
      await _engine!.enableLocalAudio(true);
      await _engine!.muteLocalAudioStream(false);
      await _engine!.muteAllRemoteAudioStreams(false);
      await _engine!.setDefaultAudioRouteToSpeakerphone(true);
      await _engine!.adjustRecordingSignalVolume(100);
      await _engine!.adjustPlaybackSignalVolume(100);

      const String channelName = 'NileVoiceMainRoom';
      String rtcToken = '';

      // የራሱን myUid ልኮ ለራሱ UID የሚሆን ትክክለኛ ቶከን መጠየቅ
      try {
        final client = HttpClient();
        client.connectionTimeout = const Duration(seconds: 10);
        final request = await client.getUrl(
          Uri.parse('${AppData.serverUrl}/rtc-token?channelName=$channelName&uid=$myUid'),
        );
        final response = await request.close();
        if (response.statusCode == 200) {
          final responseBody = await response.transform(utf8.decoder).join();
          final data = jsonDecode(responseBody);
          rtcToken = data['token'] ?? '';
          debugPrint('Token received for UID $myUid');
        }
      } catch (tokenErr) {
        debugPrint('Token fetch error: $tokenErr');
      }

// ሁለቱም ስልኮች እርስ በእርስ እንዲደማመጡ ቻነሉን መቀላቀል
      await _engine!.joinChannel(
        token: rtcToken,
        channelId: channelName,
        uid: myUid,
        options: const ChannelMediaOptions(
          clientRoleType: ClientRoleType.clientRoleBroadcaster,
          publishMicrophoneTrack: true,
          autoSubscribeAudio: true,
        ),
      );
    } catch (e) {
      debugPrint('Agora init error: $e');
    }
  }

  void _toggleMic() async {
    if (_engine == null) return;
    setState(() {
      isMuted = !isMuted;
      if (myChairNum != null) {
        speakingChairs[myChairNum!] = !isMuted;
      }
    });

    await _engine!.muteLocalAudioStream(isMuted);

    if (myChairNum != null) {
      socket?.emit('chair_speaking', {
        'chairNum': myChairNum,
        'isSpeaking': !isMuted,
      });
    }

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

      // ወንበር ሲያዝ ወይም ሲለቀቅ
      socket?.on('chair_action', (data) {
        if (mounted) {
          setState(() {
            int chair = data['chairNum'];
            String user = data['userName'];
            String action = data['action'];

            if (action == 'join') {
              occupiedChairs.removeWhere((k, v) => v == user);
              occupiedChairs[chair] = user;
              chatMessages.add('💺 $user ወንበር #$chair ያዘ');

              if (user == AppData.currentUserName) {
                myChairNum = chair;
                isMuted = false;
                speakingChairs[chair] = true;
                _engine?.muteLocalAudioStream(false);
              }
            } else {
              occupiedChairs.remove(chair);
              speakingChairs[chair] = false;
              chatMessages.add('🚪 $user ከወንበር #$chair ወጣ');

              if (user == AppData.currentUserName) {
                myChairNum = null;
                isMuted = true;
                _engine?.muteLocalAudioStream(true);
              }
            }
          });
        }
      });

      // የሌላው ሰው ድምፅ ሞገድ ሲበራ
      socket?.on('chair_speaking', (data) {
        if (mounted) {
          setState(() {
            int chair = data['chairNum'];
            bool isSpk = data['isSpeaking'];
            speakingChairs[chair] = isSpk;
          });
        }
      });

      socket?.on('chat_message', (data) {
        if (mounted) {
          setState(() {
            chatMessages.add('${data['sender']}: ${data['text']}');
          });
        }
      });

      socket?.on('gift_sent', (data) {
        if (mounted) {
          setState(() {
            liveAnnouncements.add('🎁 ${data['sender']} sent ${data['giftName']}!');
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
                // 1. ራስጌ
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
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
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                            ),
                            Text(
                              'ID: ${AppData.currentUserId}',
                              style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 10),
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
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),

padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF880E4F), Color(0xFF4A148C)],
                    ),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFFFD700).withOpacity(0.5)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.auto_awesome, color: Color(0xFFFFD700), size: 15),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          liveAnnouncements.isNotEmpty ? liveAnnouncements.last : '',
                          style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 4),

                // 3. የተጣበቡ ወንበሮች እና ቻት
                Expanded(
                  child: Column(
                    children: [
                      RoomChairsGrid(
                        socket: socket,
                        occupiedChairs: occupiedChairs,
                        speakingUsers: speakingChairs,
                        onChairTap: (chair) => setState(() {}),
                      ),
                      const Spacer(),
                      Container(
                        height: 80,
                        margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
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

                // 4. ታችኛው ባር
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
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
                          height: 36,

margin: const EdgeInsets.only(right: 8),
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          decoration: BoxDecoration(
                            color: Colors.white12,
                            borderRadius: BorderRadius.circular(18),
                          ),
                          child: TextField(
                            style: const TextStyle(color: Colors.white, fontSize: 12),
                            decoration: const InputDecoration(
                              hintText: 'Say Hello...',
                              hintStyle: TextStyle(color: Colors.white38, fontSize: 11),
                              border: InputBorder.none,
                              isDense: true,
                              contentPadding: EdgeInsets.symmetric(vertical: 8),
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
                            icon: const Icon(Icons.sports_esports_rounded, color: Colors.amberAccent, size: 22),
                            onPressed: () {
                              RoomGamesSheet.show(
                                context,
                                socket: socket,
                                onCoinsChanged: () => setState(() {}),
                              );
                            },
                          ),
                          IconButton(
                            icon: const Icon(Icons.card_giftcard_rounded, color: Color(0xFFFFD700), size: 22),
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
