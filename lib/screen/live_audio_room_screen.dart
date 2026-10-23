import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:agora_rtc_engine/agora_rtc_engine.dart';

class LiveAudioRoomScreen extends StatefulWidget {
  final String roomTitle;
  final String channelName;
  const LiveAudioRoomScreen({
    Key? key,
    this.roomTitle = '3D Voice Party',
    this.channelName = 'party_room_1',
  }) : super(key: key);

  @override
  State<LiveAudioRoomScreen> createState() => _LiveAudioRoomScreenState();
}

class _LiveAudioRoomScreenState extends State<LiveAudioRoomScreen>
    with SingleTickerProviderStateMixin {
  // Agora State
  RtcEngine? _engine;
  bool _isJoined = false;
  bool _isMuted = false;
  int _localUid = 0;

  // 3D Audio Ripple Animation Controller
  late AnimationController _pulseController;

  final TextEditingController _msgController = TextEditingController();
  final List<Map<String, String>> _messages = [
    {'user': 'System', 'text': 'Welcome to the 3D Audio Lounge ✨'},
  ];

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat();
    _initAgoraAudio();
  }

  Future<void> _initAgoraAudio() async {
    // 1. የማይክራፎን ፈቃድ መጠየቅ
    await [Permission.microphone].request();

    try {
      // 2. የአጎራ ሞተር ማዘጋጀት (App ID እዚህ ይቀየራል)
      _engine = createAgoraRtcEngine();
      await _engine!.initialize(const RtcEngineContext(
        appId: 'YOUR_AGORA_APP_ID',
        channelProfile: ChannelProfileType.channelProfileLiveBroadcasting,
      ));

      _engine!.registerEventHandler(
        RtcEngineEventHandler(
          onJoinChannelSuccess: (RtcConnection connection, int elapsed) {
            setState(() {
              _isJoined = true;
              _localUid = connection.localUid ?? 0;
            });
          },
          onUserMuteAudio: (RtcConnection connection, int remoteUid, bool muted) {
            setState(() {});
          },
        ),
      );

      // 3. ድምፅ ላይ ብቻ እንዲያተኩር ማድረግ
      await _engine!.setClientRole(role: ClientRoleType.clientRoleBroadcaster);
      await _engine!.enableAudio();
      await _engine!.enableAudioVolumeIndication(interval: 250, smooth: 3, reportVad: true);

      // 4. ወደ ድምፅ ቻነሉ መግባት
      await _engine!.joinChannel(
        token: '', // የሰርቨር ቶክን እስኪገናኝ ባዶ
        channelId: widget.channelName,
        uid: 0,
        options: const ChannelMediaOptions(
          clientRoleType: ClientRoleType.clientRoleBroadcaster,
          channelProfile: ChannelProfileType.channelProfileLiveBroadcasting,
        ),
      );
    } catch (e) {
      debugPrint('Agora Audio Engine Init Error: $e');
    }
  }

  void _toggleMute() async {
    setState(() {
      _isMuted = !_isMuted;
    });
    await _engine?.muteLocalAudioStream(_isMuted);
  }

  void _sendMessage() {
    if (_msgController.text.trim().isEmpty) return;
    setState(() {
      _messages.add({'user': 'Me', 'text': _msgController.text.trim()});
    });
    _msgController.clear();
  }

  void _show3DGiftSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          height: 320,
          decoration: BoxDecoration(
            color: const Color(0xFF111827).withOpacity(0.95),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
            border: Border.all(color: Colors.white.withOpacity(0.15)),
            boxShadow: [
              BoxShadow(
                color: Colors.purpleAccent.withOpacity(0.2),
                blurRadius: 30,
                spreadRadius: 5,
              ),
            ],
          ),
          padding: const EdgeInsets.all(20),

child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                '3D Virtual Gifts',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.8,
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: GridView.count(
                  crossAxisCount: 4,
                  children: [
                    _build3DGiftCard('🚀', 'Rocket', '500'),
                    _build3DGiftCard('👑', 'Crown', '300'),
                    _build3DGiftCard('💎', 'Diamond', '1000'),
                    _build3DGiftCard('🌹', 'Rose', '10'),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _build3DGiftCard(String emoji, String title, String cost) {
    return Container(
      margin: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.06),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.12)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.4),
            offset: const Offset(0, 4),
            blurRadius: 8,
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 32)),
          const SizedBox(height: 4),
          Text(title, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600)),
          Text('$cost Coins', style: const TextStyle(color: Colors.amberAccent, fontSize: 10)),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _msgController.dispose();
    _engine?.leaveChannel();
    _engine?.release();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF090D16),
      body: Stack(
        children: [
          // 3D Background Lighting Balls
          Positioned(
            top: -60,
            left: -40,
            child: Container(
              width: 220,
              height: 220,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF6366F1).withOpacity(0.35),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF6366F1).withOpacity(0.5),
                    blurRadius: 100,
                    spreadRadius: 30,
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            bottom: 120,
            right: -50,
            child: Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFFEC4899).withOpacity(0.25),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFEC4899).withOpacity(0.4),
                    blurRadius: 120,
                    spreadRadius: 40,
                  ),
                ],
              ),
            ),
          ),

          SafeArea(
            child: Column(
              children: [
                // 1. 3D Header Glassmorphism Bar
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.08),

borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: Colors.white.withOpacity(0.15)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(2),
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                            colors: [Color(0xFF38BDF8), Color(0xFF818CF8)],
                          ),
                        ),
                        child: const CircleAvatar(
                          radius: 16,
                          backgroundColor: Color(0xFF1E293B),
                          child: Icon(Icons.mic, color: Colors.white, size: 18),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.roomTitle,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Row(
                            children: [
                              Container(
                                width: 6,
                                height: 6,
                                decoration: const BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Color(0xFF22C55E),
                                ),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                _isJoined ? 'Live Room' : 'Connecting...',
                                style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 10),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const Spacer(),
                      IconButton(
                        icon: const Icon(Icons.close_rounded, color: Colors.white),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 15),

                // 2. 8ቱ 3D Audio Pod Seats
                Expanded(
                  flex: 5,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: GridView.builder(
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: 8,
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 4,
                        mainAxisSpacing: 16,
                        crossAxisSpacing: 16,
                        childAspectRatio: 0.78,
                      ),
                      itemBuilder: (context, index) {
                        bool isHost = index == 0;
                        return _build3DPodSeat(index, isHost);
                      },
                    ),
                  ),
                ),

                // 3. 3D Floating Live Chat Section
                Expanded(
                  flex: 3,
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 16),
                    padding: const EdgeInsets.all(12),

decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.25),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.white.withOpacity(0.08)),
                    ),
                    child: ListView.builder(
                      reverse: true,
                      itemCount: _messages.length,
                      itemBuilder: (context, index) {
                        final msg = _messages[_messages.length - 1 - index];
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 2.5),
                          child: RichText(
                            text: TextSpan(
                              children: [
                                TextSpan(
                                  text: '${msg['user']}: ',
                                  style: const TextStyle(
                                    color: Color(0xFF38BDF8),
                                    fontWeight: FontWeight.bold,
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
                        );
                      },
                    ),
                  ),
                ),

                // 4. 3D Bottom Floating Glass Toolbar
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Expanded(
                        child: Container(
                          height: 46,
                          padding: const EdgeInsets.symmetric(horizontal: 14),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(23),
                            border: Border.all(color: Colors.white.withOpacity(0.15)),
                          ),
                          child: TextField(
                            controller: _msgController,
                            style: const TextStyle(color: Colors.white, fontSize: 13),
                            decoration: InputDecoration(
                              hintText: 'Share your thoughts...',
                              hintStyle: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 13),
                              border: InputBorder.none,
                              suffixIcon: IconButton(
                                icon: const Icon(Icons.send_rounded, color: Color(0xFF38BDF8), size: 18),
                                onPressed: _sendMessage,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),

                      // 3D Mic Button
                      GestureDetector(
                        onTap: _toggleMute,
                        child: Container(
                          width: 46,
                          height: 46,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: LinearGradient(
                              colors: _isMuted
                                  ? [Colors.redAccent, Colors.red.shade800]
                                  : [const Color(0xFF38BDF8), const Color(0xFF2563EB)],

),
                            boxShadow: [
                              BoxShadow(
                                color: (_isMuted ? Colors.red : Colors.blue).withOpacity(0.5),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Icon(
                            _isMuted ? Icons.mic_off : Icons.mic,
                            color: Colors.white,
                            size: 22,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),

                      // 3D Gift Button
                      GestureDetector(
                        onTap: _show3DGiftSheet,
                        child: Container(
                          width: 46,
                          height: 46,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: const LinearGradient(
                              colors: [Color(0xFFF59E0B), Color(0xFFD97706)],
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.amber.withOpacity(0.4),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: const Icon(Icons.card_giftcard, color: Colors.white, size: 22),
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

  Widget _build3DPodSeat(int index, bool isHost) {
    return Column(
      children: [
        Stack(
          alignment: Alignment.center,
          children: [
            // 3D Animated Soundwave Ripple for Host
            if (isHost && !_isMuted)
              AnimatedBuilder(
                animation: _pulseController,
                builder: (context, child) {
                  return Container(
                    width: 58 + (_pulseController.value * 12),
                    height: 58 + (_pulseController.value * 12),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: const Color(0xFF38BDF8).withOpacity(1.0 - _pulseController.value),
                        width: 2,
                      ),
                    ),
                  );
                },
              ),

            // 3D Sphere Avatar Container
            Container(
              width: 54,
              height: 54,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: isHost
                      ? [const Color(0xFF38BDF8), const Color(0xFF1E3A8A)]
                      : [Colors.white.withOpacity(0.18), Colors.white.withOpacity(0.04)],
                ),
                boxShadow: [
                  BoxShadow(
                    color: isHost ? const Color(0xFF38BDF8).withOpacity(0.4) : Colors.black45,
                    blurRadius: 10,
                    offset: const Offset(0, 5),
                  ),
                ],
                border: Border.all(
                  color: isHost ? Colors.white : Colors.white.withOpacity(0.2),
                  width: 1.5,
                ),
              ),

child: Icon(
                isHost ? Icons.person_rounded : Icons.mic_none_rounded,
                color: isHost ? Colors.white : Colors.white54,
                size: 26,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          isHost ? 'Host' : 'Seat ${index + 1}',
          style: TextStyle(
            color: isHost ? Colors.amberAccent : Colors.white60,
            fontSize: 11,
            fontWeight: isHost ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ],
    );
  }
}
