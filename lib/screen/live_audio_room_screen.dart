import 'dart:async';
import 'package:flutter/material.dart';
import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:permission_handler/permission_handler.dart';
import '../services/user_service.dart';

class LiveAudioRoomScreen extends StatefulWidget {
  final String? roomTitle;
  final String? channelName;
  final String category;
  final String? coverImagePath;

  const LiveAudioRoomScreen({
    Key? key,
    this.roomTitle,
    this.channelName,
    this.category = 'Chat',
    this.coverImagePath,
  }) : super(key: key);

  @override
  State<LiveAudioRoomScreen> createState() => _LiveAudioRoomScreenState();
}

class _LiveAudioRoomScreenState extends State<LiveAudioRoomScreen>
    with SingleTickerProviderStateMixin {
  final UserService _user = UserService();
  RtcEngine? _engine;
  bool _isMicMuted = false;
  int? _mySeatIndex = 0;

  late List<Map<String, dynamic>> _seats;

  final List<Map<String, String>> _messages = [
    {'user': 'System', 'text': 'Welcome to the live voice lounge! 🎙️'},
  ];
  final TextEditingController _chatController = TextEditingController();

  // Full Screen Gift Animation Controllers
  late AnimationController _giftAnimController;
  late Animation<Offset> _carSlideAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<Offset> _rocketFlyAnimation;

  String? _activeGiftName;
  String? _activeGiftSender;
  Timer? _giftTimer;

  int _onlineCount = 8;

  String get effectiveTitle =>
      widget.roomTitle ?? widget.channelName ?? 'Habesha Voice Lounge';

  @override
  void initState() {
    super.initState();

    // 8 Seats Setup
    _seats = List.generate(8, (index) {
      if (index == 0) {
        return {
          'index': 0,
          'title': 'Host',
          'userId': _user.userId,
          'userName': _user.userName,
          'isMuted': false,
          'isSpeaking': false,
        };
      }
      return {
        'index': index,
        'title': 'Seat ${index + 1}',
        'userId': null,
        'userName': null,
        'isMuted': false,
        'isSpeaking': false,
      };
    });

    // Setup Animations
    _giftAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3200),
    );

    // Car drives left to right across screen
    _carSlideAnimation = Tween<Offset>(
      begin: const Offset(-1.6, 0.0),
      end: const Offset(1.6, 0.0),
    ).animate(CurvedAnimation(
      parent: _giftAnimController,
      curve: Curves.easeInOutCubic,
    ));

    // Rocket flies upwards
    _rocketFlyAnimation = Tween<Offset>(
      begin: const Offset(0.0, 1.8),
      end: const Offset(0.0, -1.8),
    ).animate(CurvedAnimation(
      parent: _giftAnimController,
      curve: Curves.easeInOutQuart,
    ));

    // Pop and scale for Crown, Rose, Heart
    _scaleAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.1, end: 1.3), weight: 30),
      TweenSequenceItem(tween: Tween(begin: 1.3, end: 1.0), weight: 20),
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.1), weight: 30),
      TweenSequenceItem(tween: Tween(begin: 1.1, end: 0.0), weight: 20),
    ]).animate(_giftAnimController);

    _initAgora();
  }

  Future<void> _initAgora() async {
    await [Permission.microphone].request();
    try {
      _engine = createAgoraRtcEngine();
      await _engine!.initialize(const RtcEngineContext(
        appId: UserService.agoraAppId,
        channelProfile: ChannelProfileType.channelProfileLiveBroadcasting,
      ));

      _engine!.registerEventHandler(
        RtcEngineEventHandler(
          onAudioVolumeIndication: (RtcConnection connection,
              List<AudioVolumeInfo> speakers, int totalVolume, int? speakerNumber) {
            if (!mounted) return;
            for (var speaker in speakers) {

final speakerUid = speaker.uid.toString();
              setState(() {
                for (var seat in _seats) {
                  if (seat['userId'] == speakerUid ||
                      (speaker.uid == 0 && seat['userId'] == _user.userId)) {
                    seat['isSpeaking'] = (speaker.volume ?? 0) > 10;
                  }
                }
              });
            }
          },
        ),
      );

      await _engine!.enableAudio();
      await _engine!.enableAudioVolumeIndication(
        interval: 250,
        smooth: 3,
        reportVad: true,
      );
      await _engine!.setClientRole(role: ClientRoleType.clientRoleBroadcaster);
      await _engine!.joinChannel(
        token: '',
        channelId: effectiveTitle.replaceAll(' ', '_'),
        uid: int.tryParse(_user.userId) ?? 0,
        options: const ChannelMediaOptions(
          clientRoleType: ClientRoleType.clientRoleBroadcaster,
        ),
      );
    } catch (e) {
      debugPrint('Agora Error: $e');
    }
  }

  void _triggerGift(String giftName, int cost) {
    if (_user.coins < cost) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Insufficient Coins!'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    _user.coins -= cost;
    Navigator.pop(context); // Close dialog

    setState(() {
      _activeGiftName = giftName;
      _activeGiftSender = _user.userName;
      _messages.add({
        'user': 'GIFT',
        'text': '${_user.userName} sent $giftName to Host!',
      });
    });

    _giftAnimController.forward(from: 0.0);

    _giftTimer?.cancel();
    _giftTimer = Timer(const Duration(milliseconds: 3300), () {
      if (mounted) {
        setState(() {
          _activeGiftName = null;
          _activeGiftSender = null;
        });
      }
    });
  }

  void _sendMessage() {
    final text = _chatController.text.trim();
    if (text.isEmpty) return;
    setState(() {
      _messages.add({
        'user': _user.userName,
        'text': text,
      });
    });
    _chatController.clear();
  }

  void _toggleMic() async {
    final nextState = !_isMicMuted;
    await _engine?.muteLocalAudioStream(nextState);
    setState(() {
      _isMicMuted = nextState;
      if (_mySeatIndex != null) {
        _seats[_mySeatIndex!]['isMuted'] = nextState;
      }
    });
  }

  void _showGameSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF161F30),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) {
        return Container(
          padding: const EdgeInsets.all(20),
          height: 280,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Room Mini Games & PK 🎮',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _gameItem('Lucky Wheel', '🎡', Colors.purpleAccent),
                  _gameItem('PK Battle', '⚔️', Colors.redAccent),
                  _gameItem('Dice Roll', '🎲', Colors.amberAccent),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _gameItem(String title, String icon, Color color) {
    return Column(
      children: [
        Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            color: color.withOpacity(0.15),

borderRadius: BorderRadius.circular(20),
            border: Border.all(color: color.withOpacity(0.5), width: 1.5),
          ),
          child: Center(
            child: Text(icon, style: const TextStyle(fontSize: 30)),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          title,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _giftAnimController.dispose();
    _chatController.dispose();
    _giftTimer?.cancel();
    _engine?.leaveChannel();
    _engine?.release();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF070B14),
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              children: [
                _buildTopBar(),
                _buildSeatsGrid(),
                const Spacer(),
                _buildChatStream(),
                _buildBottomControls(),
              ],
            ),

            // 4. FULL-SCREEN 3D ANIMATION LAYER
            if (_activeGiftName != null) _buildFullScreenGiftOverlay(),
          ],
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: const BoxDecoration(
        color: Color(0xFF101726),
        border: Border(bottom: BorderSide(color: Colors.white10)),
      ),
      child: Row(
        children: [
          IconButton(
            constraints: const BoxConstraints(),
            padding: const EdgeInsets.all(6),
            icon: const Icon(Icons.picture_in_picture_alt_rounded,
                color: Colors.white70, size: 20),
            onPressed: () => Navigator.pop(context),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Row(
              children: [
                CircleAvatar(
                  radius: 16,
                  backgroundColor: const Color(0xFF2563EB),
                  child: const Icon(Icons.mic, color: Colors.white, size: 16),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        effectiveTitle,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        widget.category,
                        style: const TextStyle(color: Colors.white54, fontSize: 10),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFF1E293B),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.white12),
            ),
            child: Row(
              children: [
                const Icon(Icons.local_fire_department, size: 14, color: Colors.amber),
                const SizedBox(width: 4),
                Text(
                  '$_onlineCount',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,

fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 6),
          IconButton(
            constraints: const BoxConstraints(),
            padding: const EdgeInsets.all(6),
            icon: const Icon(Icons.power_settings_new_rounded,
                color: Colors.redAccent, size: 20),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }

  Widget _buildSeatsGrid() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: 8,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 4,
          mainAxisSpacing: 16,
          crossAxisSpacing: 16,
          childAspectRatio: 0.78,
        ),
        itemBuilder: (context, index) {
          final seat = _seats[index];
          final bool isOccupied = seat['userId'] != null;
          final bool isSpeaking = seat['isSpeaking'] == true;
          final bool isMuted = seat['isMuted'] == true;

          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFF161F30),
                  border: Border.all(
                    color: isSpeaking
                        ? const Color(0xFF00FFC2)
                        : (isOccupied ? const Color(0xFF38BDF8) : Colors.white12),
                    width: isSpeaking ? 3 : 1.5,
                  ),
                  boxShadow: isSpeaking
                      ? [
                          BoxShadow(
                            color: const Color(0xFF00FFC2).withOpacity(0.5),
                            blurRadius: 14,
                            spreadRadius: 3,
                          )
                        ]
                      : [],
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Icon(
                      isOccupied ? Icons.person : Icons.add_rounded,
                      color: isOccupied ? Colors.white : Colors.white24,
                      size: isOccupied ? 28 : 24,
                    ),
                    if (isOccupied && isMuted)
                      Positioned(
                        bottom: 2,
                        right: 2,
                        child: Container(
                          padding: const EdgeInsets.all(2),
                          decoration: const BoxDecoration(
                            color: Colors.redAccent,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.mic_off, size: 10, color: Colors.white),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 6),
              Text(
                isOccupied ? seat['userName'] : seat['title'],
                style: TextStyle(
                  color: isOccupied ? Colors.white : Colors.white38,
                  fontSize: 10,
                  fontWeight: isOccupied ? FontWeight.bold : FontWeight.normal,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildChatStream() {
    return Container(
      height: 150,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      child: ListView.builder(
        itemCount: _messages.length,
        itemBuilder: (context, index) {
          final msg = _messages[index];
          final bool isGift = msg['user'] == 'GIFT';

if (isGift) {
            return Container(
              margin: const EdgeInsets.symmetric(vertical: 4),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFEC4899), Color(0xFF8B5CF6)],
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  const Icon(Icons.card_giftcard, color: Colors.amber, size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      msg['text']!,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }

          return Container(
            margin: const EdgeInsets.symmetric(vertical: 3),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.35),
              borderRadius: BorderRadius.circular(12),
            ),
            child: RichText(
              text: TextSpan(
                children: [
                  TextSpan(
                    text: '${msg['user']}: ',
                    style: const TextStyle(
                      color: Color(0xFF38BDF8),
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  TextSpan(
                    text: msg['text']!,
                    style: const TextStyle(color: Colors.white70, fontSize: 11),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildBottomControls() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: const BoxDecoration(
        color: Color(0xFF101726),
        border: Border(top: BorderSide(color: Colors.white10)),
      ),
      child: Row(
        children: [
          IconButton(
            icon: Icon(
              _isMicMuted ? Icons.mic_off : Icons.mic,
              color: _isMicMuted ? Colors.redAccent : const Color(0xFF00FFC2),
              size: 22,
            ),
            onPressed: _toggleMic,
          ),
          IconButton(
            icon: const Icon(Icons.sports_esports_rounded, color: Colors.amber, size: 22),
            onPressed: _showGameSheet,
          ),
          Expanded(
            child: Container(
              height: 38,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: const Color(0xFF1C2538),
                borderRadius: BorderRadius.circular(20),
              ),
              child: TextField(
                controller: _chatController,
                style: const TextStyle(color: Colors.white, fontSize: 12),
                decoration: InputDecoration(
                  hintText: 'Say something...',
                  hintStyle: const TextStyle(color: Colors.white30, fontSize: 11),
                  border: InputBorder.none,
                  suffixIcon: IconButton(
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    icon: const Icon(Icons.send_rounded,
                        color: Color(0xFF38BDF8), size: 16),
                    onPressed: _sendMessage,
                  ),
                ),
              ),

),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: _showGiftPanel,
            child: Container(
              padding: const EdgeInsets.all(9),
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [Color(0xFFFF007A), Color(0xFF7928CA)],
                ),
              ),
              child: const Icon(Icons.card_giftcard, color: Colors.white, size: 18),
            ),
          ),
        ],
      ),
    );
  }

  // --- 4. FULL-SCREEN 3D DYNAMIC ANIMATION LAYER ---
  Widget _buildFullScreenGiftOverlay() {
    final bool isCar = _activeGiftName == 'Super Car';
    final bool isRocket = _activeGiftName == 'Rocket';

    Widget giftVisual;
    if (isCar) {
      giftVisual = SlideTransition(
        position: _carSlideAnimation,
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            boxShadow: [
              BoxShadow(
                color: Colors.redAccent.withOpacity(0.5),
                blurRadius: 50,
                spreadRadius: 10,
              ),
            ],
          ),
          child: const Text('🏎️💨', style: TextStyle(fontSize: 100)),
        ),
      );
    } else if (isRocket) {
      giftVisual = SlideTransition(
        position: _rocketFlyAnimation,
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            boxShadow: [
              BoxShadow(
                color: Colors.orangeAccent.withOpacity(0.6),
                blurRadius: 60,
                spreadRadius: 15,
              ),
            ],
          ),
          child: const Text('🚀🔥', style: TextStyle(fontSize: 110)),
        ),
      );
    } else {
      String icon = '🌹';
      if (_activeGiftName == 'Love Heart') icon = '💖';
      if (_activeGiftName == 'Crown') icon = '👑';

      giftVisual = ScaleTransition(
        scale: _scaleAnimation,
        child: Container(
          padding: const EdgeInsets.all(30),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.pinkAccent.withOpacity(0.5),
                blurRadius: 50,
                spreadRadius: 10,
              ),
            ],
          ),
          child: Text(icon, style: const TextStyle(fontSize: 100)),
        ),
      );
    }

    return Positioned.fill(
      child: IgnorePointer(
        child: Container(
          color: Colors.black.withOpacity(0.3),
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Floating Title Banner
              Positioned(
                top: 90,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.7),
                    borderRadius: BorderRadius.circular(25),
                    border: Border.all(color: Colors.amberAccent, width: 1.5),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.auto_awesome, color: Colors.amber, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        '${_activeGiftSender!} sent ${_activeGiftName!}!',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Animated Graphic
              giftVisual,
            ],
          ),
        ),
      ),
    );
  }

void _showGiftPanel() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF161F30),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) {
        return Container(
          padding: const EdgeInsets.all(18),
          height: 320,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Send Gift',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.black26,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.monetization_on, color: Colors.amber, size: 16),
                        const SizedBox(width: 4),
                        Text(
                          '${_user.coins}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Expanded(
                child: GridView.count(
                  crossAxisCount: 3,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  children: [
                    _giftItem('Rose', '🌹', 10),
                    _giftItem('Love Heart', '💖', 50),
                    _giftItem('Super Car', '🏎️', 200),
                    _giftItem('Crown', '👑', 500),
                    _giftItem('Rocket', '🚀', 1000),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _giftItem(String name, String icon, int cost) {
    return GestureDetector(
      onTap: () => _triggerGift(name, cost),
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF1C2538),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white10),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(icon, style: const TextStyle(fontSize: 28)),
            const SizedBox(height: 6),
            Text(name, style: const TextStyle(color: Colors.white, fontSize: 11)),
            Text('$cost Coins',
                style: const TextStyle(color: Colors.amber, fontSize: 10)),
          ],
        ),
      ),
    );
  }
}
