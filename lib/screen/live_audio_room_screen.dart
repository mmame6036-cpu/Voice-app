import 'dart:math';
import 'package:flutter/material.dart';
import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:permission_handler/permission_handler.dart';
import '../services/user_service.dart';
import '../recharge_screen.dart';

class LiveAudioRoomScreen extends StatefulWidget {
  final String roomTitle;
  final String channelName;

  const LiveAudioRoomScreen({
    Key? key,
    required this.roomTitle,
    required this.channelName,
  }) : super(key: key);

  @override
  State<LiveAudioRoomScreen> createState() => _LiveAudioRoomScreenState();
}

class _LiveAudioRoomScreenState extends State<LiveAudioRoomScreen>
    with SingleTickerProviderStateMixin {
  final UserService _user = UserService();
  RtcEngine? _engine;
  bool _isJoined = false;
  bool _isMuted = false;
  int? _mySeatIndex;

  late AnimationController _giftAnimController;
  late Animation<double> _giftScaleAnimation;
  Map<String, dynamic>? _activeScreenGift;

  final List<Map<String, dynamic>> _seats = List.generate(8, (index) {
    return {
      'index': index,
      'isHost': index == 0,
      'userId': index == 0 ? '1001' : null,
      'userName': index == 0 ? 'Host' : 'Seat ${index + 1}',
      'isSpeaking': false,
    };
  });

  final List<Map<String, dynamic>> _gifts = [
    {'name': 'Rose', 'coins': 10, 'icon': '🌹', 'color': Colors.redAccent},
    {'name': 'Love Heart', 'coins': 50, 'icon': '💖', 'color': Colors.pinkAccent},
    {'name': 'Super Car', 'coins': 200, 'icon': '🏎️', 'color': Colors.amberAccent},
    {'name': 'King Crown', 'coins': 500, 'icon': '👑', 'color': Colors.amber},
    {'name': 'Rocket', 'coins': 1000, 'icon': '🚀', 'color': Colors.cyanAccent},
  ];

  @override
  void initState() {
    super.initState();
    _initAgoraAudio();

    _giftAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2500),
    );

    _giftScaleAnimation = CurvedAnimation(
      parent: _giftAnimController,
      curve: Curves.elasticOut,
    );

    _giftAnimController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        setState(() => _activeScreenGift = null);
        _giftAnimController.reset();
      }
    });
  }

  Future<void> _initAgoraAudio() async {
    await [Permission.microphone].request();
    try {
      _engine = createAgoraRtcEngine();
      await _engine!.initialize(const RtcEngineContext(
        appId: UserService.agoraAppId,
        channelProfile: ChannelProfileType.channelProfileLiveBroadcasting,
      ));

      _engine!.registerEventHandler(
        RtcEngineEventHandler(
          onJoinChannelSuccess: (RtcConnection connection, int elapsed) {
            if (mounted) setState(() => _isJoined = true);
          },
          onAudioVolumeIndication: (RtcConnection connection,
              List<AudioVolumeInfo> speakers, int totalVolume, int speakerNumber) {
            for (var speaker in speakers) {
              _updateSpeakerVisual(speaker.uid.toString(), (speaker.volume ?? 0) > 5);
            }
          },
        ),
      );

      await _engine!.setClientRole(role: ClientRoleType.clientRoleAudience);
      await _engine!.enableAudio();
      await _engine!.enableAudioVolumeIndication(
          interval: 250, smooth: 3, reportVad: true);

      await _engine!.joinChannel(
        token: '',
        channelId: widget.channelName,
        uid: int.tryParse(_user.userId) ?? Random().nextInt(100000),
        options: const ChannelMediaOptions(
          clientRoleType: ClientRoleType.clientRoleAudience,
        ),
      );
    } catch (e) {
      debugPrint('Agora Audio Error: $e');
    }
  }

  void _updateSpeakerVisual(String uid, bool speaking) {
    if (!mounted) return;
    setState(() {
      for (var seat in _seats) {
        if (seat['userId'] == uid) {
          seat['isSpeaking'] = speaking;
        }
      }
    });
  }

Future<void> _toggleSeat(int seatIndex) async {
    if (_mySeatIndex == seatIndex) {
      await _engine?.setClientRole(role: ClientRoleType.clientRoleAudience);
      setState(() {
        _seats[seatIndex]['userId'] = null;
        _seats[seatIndex]['userName'] = 'Seat ${seatIndex + 1}';
        _mySeatIndex = null;
      });
    } else if (_seats[seatIndex]['userId'] == null) {
      await _engine?.setClientRole(role: ClientRoleType.clientRoleBroadcaster);
      setState(() {
        if (_mySeatIndex != null) {
          _seats[_mySeatIndex!]['userId'] = null;
          _seats[_mySeatIndex!]['userName'] = 'Seat ${_mySeatIndex! + 1}';
        }
        _seats[seatIndex]['userId'] = _user.userId;
        _seats[seatIndex]['userName'] = _user.userName;
        _mySeatIndex = seatIndex;
      });
    }
  }

  Future<void> _toggleMute() async {
    if (_engine == null || _mySeatIndex == null) return;
    final nextState = !_isMuted;
    await _engine!.muteLocalAudioStream(nextState);
    setState(() => _isMuted = nextState);
  }

  Future<void> _sendLiveGift(Map<String, dynamic> gift) async {
    final int cost = gift['coins'];

    if (_user.coins < cost) {
      Navigator.pop(context);
      _showRechargeDialog();
      return;
    }

    final bool success = await _user.sendGift(
      receiverId: '1001',
      giftName: gift['name'],
      coinCost: cost,
    );

    if (success) {
      Navigator.pop(context);
      setState(() {
        _activeScreenGift = gift;
      });
      _giftAnimController.forward();
    }
  }

  void _showRechargeDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        title: const Text('Insufficient Coins', style: TextStyle(color: Colors.white)),
        content: const Text(
          'You need more coins to send this gift. Would you like to recharge?',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: Colors.white54)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF00C9A7)),
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const RechargeScreen()),
              ).then((_) => setState(() {}));
            },
            child: const Text('Recharge Now', style: TextStyle(color: Colors.black)),
          ),
        ],
      ),
    );
  }

  void _openGiftSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF111827),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Container(
              padding: const EdgeInsets.all(20),
              height: 360,
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Send 3D Gift',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1F2937),

borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.amber.withOpacity(0.4)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.monetization_on,
                                color: Colors.amber, size: 18),
                            const SizedBox(width: 6),
                            Text(
                              '${_user.coins}',
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  Expanded(
                    child: GridView.builder(
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 3,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                        childAspectRatio: 0.95,
                      ),
                      itemCount: _gifts.length,
                      itemBuilder: (context, index) {
                        final gift = _gifts[index];
                        return GestureDetector(
                          onTap: () => _sendLiveGift(gift),
                          child: Container(
                            decoration: BoxDecoration(
                              color: const Color(0xFF1F2937),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                  color: (gift['color'] as Color).withOpacity(0.3)),
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(gift['icon'],
                                    style: const TextStyle(fontSize: 34)),
                                const SizedBox(height: 6),
                                Text(
                                  gift['name'],
                                  style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Icon(Icons.monetization_on,
                                        color: Colors.amber, size: 12),
                                    const SizedBox(width: 4),
                                    Text(
                                      '${gift['coins']}',
                                      style: const TextStyle(
                                          color: Colors.amber,
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold),
                                    ),
                                  ],
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
      },
    );
  }

  @override
  void dispose() {
    _giftAnimController.dispose();
    _engine?.leaveChannel();
    _engine?.release();
    super.dispose();
  }

@override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0E1A),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white10,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  const Icon(Icons.mic, color: Color(0xFF00C9A7), size: 16),
                  const SizedBox(width: 6),
                  Text(
                    widget.roomTitle,
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.close_rounded, color: Colors.white70),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
      body: Stack(
        children: [
          SafeArea(
            child: Column(
              children: [
                const SizedBox(height: 12),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: GridView.builder(
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 4,
                        mainAxisSpacing: 24,
                        crossAxisSpacing: 16,
                        childAspectRatio: 0.75,
                      ),
                      itemCount: 8,
                      itemBuilder: (context, index) {
                        final seat = _seats[index];
                        final bool isTaken = seat['userId'] != null;
                        final bool isMe = _mySeatIndex == index;
                        final bool isSpeaking = seat['isSpeaking'] ?? false;

                        return GestureDetector(
                          onTap: () => _toggleSeat(index),
                          child: Column(
                            children: [
                              AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                width: 62,
                                height: 62,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: isTaken
                                      ? const Color(0xFF1E293B)
                                      : Colors.white.withOpacity(0.04),
                                  border: Border.all(
                                    color: isSpeaking
                                        ? const Color(0xFF00C9A7)
                                        : (isMe
                                            ? const Color(0xFF2563EB)
                                            : Colors.white12),
                                    width: isSpeaking ? 3 : 1.5,
                                  ),
                                  boxShadow: isSpeaking
                                      ? [
                                          BoxShadow(
                                            color: const Color(0xFF00C9A7)
                                                .withOpacity(0.6),
                                            blurRadius: 12,
                                            spreadRadius: 2,
                                          ),

]
                                      : [],
                                ),
                                child: Icon(
                                  isTaken
                                      ? (seat['isHost']
                                          ? Icons.person
                                          : Icons.mic)
                                      : Icons.add,
                                  color: isTaken
                                      ? (seat['isHost']
                                          ? const Color(0xFF38BDF8)
                                          : Colors.white)
                                      : Colors.white24,
                                  size: 26,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                seat['userName'],
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: isMe
                                      ? const Color(0xFF00C9A7)
                                      : Colors.white70,
                                  fontSize: 10,
                                  fontWeight: isMe
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: const BoxDecoration(
                    color: Color(0xFF111827),
                    borderRadius:
                        BorderRadius.vertical(top: Radius.circular(20)),
                  ),
                  child: Row(
                    children: [
                      if (_mySeatIndex != null) ...[
                        IconButton(
                          icon: Icon(
                            _isMuted ? Icons.mic_off : Icons.mic,
                            color: _isMuted
                                ? Colors.redAccent
                                : const Color(0xFF00C9A7),
                          ),
                          onPressed: _toggleMute,
                        ),
                        const SizedBox(width: 8),
                      ],
                      const Text(
                        'Tap any seat to speak',
                        style: TextStyle(color: Colors.white38, fontSize: 11),
                      ),
                      const Spacer(),
                      GestureDetector(
                        onTap: _openGiftSheet,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 8),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFFEC4899), Color(0xFF8B5CF6)],
                            ),
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFFEC4899).withOpacity(0.4),
                                blurRadius: 8,
                              ),
                            ],
                          ),
                          child: const Row(

children: [
                              Icon(Icons.card_giftcard,
                                  color: Colors.white, size: 18),
                              SizedBox(width: 6),
                              Text(
                                'Gift',
                                style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          if (_activeScreenGift != null)
            Center(
              child: ScaleTransition(
                scale: _giftScaleAnimation,
                child: Container(
                  padding: const EdgeInsets.all(28),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.85),
                    shape: BoxShape.circle,
                    border: Border.all(
                        color: _activeScreenGift!['color'] as Color, width: 4),
                    boxShadow: [
                      BoxShadow(
                        color: (_activeScreenGift!['color'] as Color)
                            .withOpacity(0.6),
                        blurRadius: 30,
                        spreadRadius: 8,
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _activeScreenGift!['icon'],
                        style: const TextStyle(fontSize: 80),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _activeScreenGift!['name'],
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold),
                      ),
                      Text(
                        '-${_activeScreenGift!['coins']} Coins',
                        style: const TextStyle(
                            color: Colors.amber,
                            fontSize: 14,
                            fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
