import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:http/http.dart' as http;
import '../services/agora_service.dart';

class RoomChatMessage {
  final String sender;
  final String message;
  final bool isSystem;

  RoomChatMessage({
    required this.sender,
    required this.message,
    this.isSystem = false,
  });
}

class VoiceRoomScreen extends StatefulWidget {
  final String roomTitle;
  final String roomId;
  final String hostName;
  final int userNumericId;
  final String userUid;
  final String userName;

  const VoiceRoomScreen({
    super.key,
    required this.roomTitle,
    required this.roomId,
    required this.hostName,
    required this.userNumericId,
    this.userUid = "user_guest_id",
    this.userName = "Me",
  });

  @override
  State<VoiceRoomScreen> createState() => _VoiceRoomScreenState();
}

class _VoiceRoomScreenState extends State<VoiceRoomScreen>
    with TickerProviderStateMixin {
  final AgoraService _agoraService = AgoraService();
  bool _isMuted = false;
  int? _mySeatIndex;
  int _totalSeats = 30;
  late List<String?> _seats;
  late List<int> _seatGifts;
  late List<bool> _seatMutes;
  bool _isConnecting = true;

  int _myCoins = 2500;

  late AnimationController _waveController;
  late AnimationController _giftFlyController;
  late Animation<double> _giftFlyScale;
  late Animation<double> _giftFlyOpacity;
  bool _isShowingGiftAnim = false;
  String _activeGiftAsset = 'assets/images/lv3.png';

  final Set<int> _speakingSeatIndices = {};
  final List<int> _allowedSeatOptions = [6, 12, 20, 25, 30];

  final List<RoomChatMessage> _messages = [];
  final TextEditingController _chatController = TextEditingController();
  final ScrollController _chatScrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _seats = List.filled(30, null);
    _seatGifts = List.filled(30, 0);
    _seatMutes = List.filled(30, false);
    _seats[0] = widget.hostName;

    _messages.add(RoomChatMessage(
      sender: "System",
      message: "Welcome to ${widget.roomTitle}! Protect your account and enjoy the party.",
      isSystem: true,
    ));

    _waveController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    )..repeat(reverse: true);

    _giftFlyController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );

    _giftFlyScale = Tween<double>(begin: 0.2, end: 1.4).animate(
      CurvedAnimation(parent: _giftFlyController, curve: Curves.elasticOut),
    );

    _giftFlyOpacity = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _giftFlyController,
        curve: const Interval(0.7, 1.0, curve: Curves.easeOut),
      ),
    );

    _giftFlyController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        if (mounted) {
          setState(() {
            _isShowingGiftAnim = false;
          });
        }
      }
    });

    _setupAgora();
  }

  Future<String?> _fetchToken({
    required String channelName,
    required int uid,
    required bool isPublisher,
  }) async {
    try {
      final role = isPublisher ? "publisher" : "subscriber";
      final uri = Uri.parse(
          "https://nile-token-server.onrender.com/rtcToken?channelName=$channelName&uid=$uid&role=$role");
      final response =
          await http.get(uri).timeout(const Duration(seconds: 12));
      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        return data['token'] as String?;
      }
    } catch (_) {
      return null;
    }
    return null;
  }

Future<void> _setupAgora() async {
    final status = await Permission.microphone.request();
    if (status != PermissionStatus.granted && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text("Microphone permission required for voice chat")),
      );
    }

    await _agoraService.initEngine(
      onUserJoined: (uid) {
        if (!mounted) return;
        setState(() {
          _messages.add(RoomChatMessage(
            sender: "System",
            message: "User $uid joined the room.",
            isSystem: true,
          ));
        });
        _scrollToBottom();
      },
      onUserOffline: (uid) {
        if (!mounted) return;
        setState(() {
          _messages.add(RoomChatMessage(
            sender: "System",
            message: "User $uid left the room.",
            isSystem: true,
          ));
        });
        _scrollToBottom();
      },
      onVolumeChanged: (speakers) {
        if (!mounted) return;
        setState(() {
          _speakingSeatIndices.clear();
          for (var speaker in speakers) {
            final vol = speaker.volume ?? 0;
            if (vol > 4) {
              if (speaker.uid == 0 || speaker.uid == widget.userNumericId) {
                if (_mySeatIndex != null && !_isMuted && !_seatMutes[_mySeatIndex!]) {
                  _speakingSeatIndices.add(_mySeatIndex!);
                }
              }
            }
          }
        });
      },
    );

    final dynamicToken = await _fetchToken(
      channelName: widget.roomId,
      uid: widget.userNumericId,
      isPublisher: false,
    );

    await _agoraService.joinRoom(
      channelId: widget.roomId,
      uid: widget.userNumericId,
      token: dynamicToken,
      isSpeaker: false,
    );

    if (mounted) {
      setState(() {
        _isConnecting = false;
      });
    }
  }

  void _triggerGiftAnimation(String asset) {
    setState(() {
      _activeGiftAsset = asset;
      _isShowingGiftAnim = true;
    });
    _giftFlyController.reset();
    _giftFlyController.forward();
  }

  void _sendMessage() {
    final text = _chatController.text.trim();
    if (text.isEmpty) return;

    setState(() {
      _messages.add(RoomChatMessage(
        sender: widget.userName,
        message: text,
      ));
    });
    _chatController.clear();
    _scrollToBottom();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_chatScrollController.hasClients) {
        _chatScrollController.animateTo(
          _chatScrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _handleSeatTap(int index) async {
    if (_mySeatIndex == index) {
      setState(() {
        _seats[index] = null;
        _mySeatIndex = null;
        _speakingSeatIndices.remove(index);
      });
      await _agoraService.switchRole(isSpeaker: false);
      return;
    }

    if (_seats[index] == null) {
      final status = await Permission.microphone.request();
      if (!status.isGranted) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text("Allow microphone access to take seat")),
          );
        }
        return;
      }

      setState(() {
        if (_mySeatIndex != null) {
          _seats[_mySeatIndex!] = null;
          _speakingSeatIndices.remove(_mySeatIndex!);
        }
        _seats[index] = widget.userName;
        _mySeatIndex = index;
        _isMuted = false;
        _seatMutes[index] = false;
      });

      await _agoraService.switchRole(isSpeaker: true);
    }
  }

  void _toggleMute() {
    setState(() {
      _isMuted = !_isMuted;
      if (_mySeatIndex != null) {
        _seatMutes[_mySeatIndex!] = _isMuted;
        if (_isMuted) {
          _speakingSeatIndices.remove(_mySeatIndex!);
        }
      }
    });
    _agoraService.setMicrophoneMute(_isMuted);
  }

void _changeSeatCount(int newCount) {
    setState(() {
      _totalSeats = newCount;
      if (_mySeatIndex != null && _mySeatIndex! >= newCount) {
        _seats[_mySeatIndex!] = null;
        _mySeatIndex = null;
        _agoraService.switchRole(isSpeaker: false);
      }
    });
  }

  void _openGiftSheet() {
    int selectedSeat = 0;
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF141026),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              child: Column(
                mainAxisSize: dynamic,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.monetization_on, color: Color(0xFFFFD700), size: 20),
                          const SizedBox(width: 6),
                          Text(
                            "Coins: $_myCoins",
                            style: const TextStyle(
                              color: Color(0xFFFFD700),
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.white24),
                        ),
                        child: DropdownButton<int>(
                          value: selectedSeat,
                          dropdownColor: const Color(0xFF231C3D),
                          underline: const SizedBox(),
                          style: const TextStyle(color: Colors.white, fontSize: 13),
                          items: List.generate(_totalSeats, (i) {
                            return DropdownMenuItem<int>(
                              value: i,
                              child: Text(i == 0 ? "Host (Seat 1)" : "Seat ${i + 1}"),
                            );
                          }),
                          onChanged: (val) {
                            if (val != null) {
                              setSheetState(() => selectedSeat = val);
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                  const Divider(color: Colors.white12, height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _giftChoiceItem(
                        name: "Crown Crest",
                        price: 100,
                        asset: 'assets/images/lv3.png',
                        onTap: () => _executeGiftSend(
                          ctx,
                          selectedSeat,
                          cost: 100,
                          name: "Crown Crest 🛡️",
                          asset: 'assets/images/lv3.png',
                        ),
                      ),
                      _giftChoiceItem(
                        name: "Gold Wings",
                        price: 300,
                        asset: 'assets/images/2.png',

onTap: () => _executeGiftSend(
                          ctx,
                          selectedSeat,
                          cost: 300,
                          name: "Golden Wings 👑",
                          asset: 'assets/images/2.png',
                        ),
                      ),
                      _giftChoiceItem(
                        name: "Tiger VIP",
                        price: 500,
                        asset: 'assets/images/4.png',
                        onTap: () => _executeGiftSend(
                          ctx,
                          selectedSeat,
                          cost: 500,
                          name: "Tiger VIP 🐯",
                          asset: 'assets/images/4.png',
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _giftChoiceItem({
    required String name,
    required int price,
    required String asset,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 72,
            height: 72,
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.06),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFFFD700).withOpacity(0.4), width: 1.2),
            ),
            child: Image.asset(
              asset,
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) => const Icon(
                Icons.card_giftcard,
                color: Color(0xFFFFD700),
                size: 28,
              ),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            name,
            style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
          ),
          Text(
            "$price Coins",
            style: const TextStyle(color: Color(0xFFFFD700), fontSize: 10),
          ),
        ],
      ),
    );
  }

  void _executeGiftSend(BuildContext ctx, int seatIndex, {required int cost, required String name, required String asset}) {
    if (_myCoins >= cost) {
      setState(() {
        _myCoins -= cost;
        _seatGifts[seatIndex] += cost;
        _messages.add(RoomChatMessage(
          sender: "System",
          message: "${widget.userName} sent $name to Seat ${seatIndex + 1}!",
          isSystem: true,
        ));
      });
      _scrollToBottom();
      Navigator.pop(ctx);
      _triggerGiftAnimation(asset);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Insufficient coins balance!")),
      );
    }
  }

  @override
  void dispose() {
    _waveController.dispose();
    _giftFlyController.dispose();
    _agoraService.leaveRoom();
    _chatController.dispose();
    _chatScrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final int crossAxis = _totalSeats <= 12 ? 4 : (_totalSeats <= 20 ? 5 : 6);
    final double seatDimension = _totalSeats > 20 ? 44.0 : 50.0;

    return Scaffold(
      backgroundColor: const Color(0xFF090614),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.roomTitle,
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
            ),
            Text(
              _isConnecting

? "Connecting..."
                  : "ID: ${widget.roomId} • $_totalSeats Seats",
              style: TextStyle(
                fontSize: 11,
                color: _isConnecting ? const Color(0xFFFFD700) : Colors.white54,
              ),
            ),
          ],
        ),
        actions: [
          PopupMenuButton<int>(
            icon: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                border: Border.all(color: const Color(0xFFFFD700), width: 1.2),
                borderRadius: BorderRadius.circular(12),
                color: const Color(0xFF1E1638),
              ),
              child: Row(
                children: [
                  const Icon(Icons.event_seat, color: Color(0xFFFFD700), size: 14),
                  const SizedBox(width: 4),
                  Text(
                    "$_totalSeats",
                    style: const TextStyle(
                      color: Color(0xFFFFD700),
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            color: const Color(0xFF1F1A3A),
            onSelected: _changeSeatCount,
            itemBuilder: (context) => _allowedSeatOptions
                .map((count) => PopupMenuItem<int>(
                      value: count,
                      child: Text(
                        "$count Seats Layout",
                        style: TextStyle(
                          color: count == _totalSeats
                              ? const Color(0xFFFFD700)
                              : Colors.white,
                          fontWeight: count == _totalSeats
                              ? FontWeight.bold
                              : FontWeight.normal,
                        ),
                      ),
                    ))
                .toList(),
          ),
          IconButton(
            icon: const Icon(Icons.power_settings_new, color: Colors.redAccent),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              children: [
                Expanded(
                  flex: 6,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10.0),
                    child: GridView.builder(
                      physics: const BouncingScrollPhysics(),
                      itemCount: _totalSeats,
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: crossAxis,
                        mainAxisSpacing: 10,
                        crossAxisSpacing: 6,
                        childAspectRatio: 0.68,
                      ),
                      itemBuilder: (context, index) {
                        final occupier = _seats[index];
                        final isOccupied = occupier != null;
                        final isSpeaking = _speakingSeatIndices.contains(index);
                        final isMuted = _seatMutes[index];
                        final giftsCount = _seatGifts[index];

                        final bool isHostSeat = index == 0;
                        final bool isCrownSeat = index >= 1 && index <= 6;

                        return GestureDetector(
                          onTap: () => _handleSeatTap(index),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Stack(
                                clipBehavior: Clip.none,
                                alignment: Alignment.center,

children: [
                                  // 1. Host Crown Crest Badge
                                  if (isHostSeat)
                                    Positioned(
                                      top: -15,
                                      child: Image.asset(
                                        'assets/images/lv3.png',
                                        width: 36,
                                        errorBuilder: (context, error, stackTrace) => const Icon(
                                          Icons.military_tech,
                                          color: Color(0xFFFFD700),
                                          size: 18,
                                        ),
                                      ),
                                    ),

                                  // 2. Seats 2-7 Golden Wing Crown
                                  if (isCrownSeat)
                                    Positioned(
                                      top: -14,
                                      child: Image.asset(
                                        'assets/images/2.png',
                                        width: 28,
                                        errorBuilder: (context, error, stackTrace) => const Icon(
                                          Icons.star,
                                          color: Color(0xFFFFD700),
                                          size: 16,
                                        ),
                                      ),
                                    ),

                                  // 3. Avatar Inner Circle
                                  AnimatedBuilder(
                                    animation: _waveController,
                                    builder: (context, child) {
                                      final wave = _waveController.value;

                                      return Container(
                                        width: seatDimension,
                                        height: seatDimension,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: isOccupied
                                              ? const Color(0xFF2C2454)
                                              : Colors.white.withOpacity(0.06),
                                          boxShadow: isSpeaking
                                              ? [
                                                  BoxShadow(
                                                    color: const Color(0xFF00E5FF)
                                                        .withOpacity(0.5 + (wave * 0.4)),
                                                    blurRadius: 10 + (wave * 8),
                                                    spreadRadius: 2 + (wave * 3),
                                                  ),
                                                ]
                                              : null,
                                        ),
                                        child: Center(
                                          child: Icon(
                                            isOccupied ? Icons.person : Icons.chair,
                                            color: isCrownSeat
                                                ? const Color(0xFFFFD700)
                                                : (isOccupied ? Colors.white : Colors.white24),
                                            size: seatDimension * 0.45,
                                          ),
                                        ),
                                      );
                                    },
                                  ),

// 4. Frames: VIP 4 for Seats 2-7, VIP 1 for occupied others
                                  if (isCrownSeat)
                                    Positioned.fill(
                                      child: IgnorePointer(
                                        child: Image.asset(
                                          'assets/images/4.png',
                                          fit: BoxFit.contain,
                                          errorBuilder: (context, error, stackTrace) => const SizedBox.shrink(),
                                        ),
                                      ),
                                    )
                                  else if (isOccupied && !isHostSeat)
                                    Positioned.fill(
                                      child: IgnorePointer(
                                        child: Image.asset(
                                          'assets/images/1.png',
                                          fit: BoxFit.contain,
                                          errorBuilder: (context, error, stackTrace) => const SizedBox.shrink(),
                                        ),
                                      ),
                                    ),

                                  // 5. Mic Status Badge
                                  if (isOccupied)
                                    Positioned(
                                      bottom: -2,
                                      right: -2,
                                      child: AnimatedBuilder(
                                        animation: _waveController,
                                        builder: (context, child) {
                                          final wave = _waveController.value;
                                          return Transform.scale(
                                            scale: isSpeaking ? (1.0 + wave * 0.25) : 1.0,
                                            child: Container(
                                              padding: const EdgeInsets.all(2.5),
                                              decoration: BoxDecoration(
                                                shape: BoxShape.circle,
                                                color: isMuted
                                                    ? Colors.redAccent
                                                    : (isSpeaking
                                                        ? const Color(0xFF00E5FF)
                                                        : const Color(0xFF00C9A7)),
                                              ),
                                              child: Icon(
                                                isMuted ? Icons.mic_off : Icons.mic,
                                                size: 11,
                                                color: Colors.black,
                                              ),
                                            ),
                                          );
                                        },
                                      ),
                                    ),
                                ],
                              ),
                              const SizedBox(height: 4),

                              Text(
                                isOccupied ? occupier : "${index + 1}",
                                style: TextStyle(
                                  color: isCrownSeat
                                      ? const Color(0xFFFFD700)
                                      : (isOccupied ? Colors.white : Colors.white38),
                                  fontSize: 9.5,
                                  fontWeight: isOccupied

? FontWeight.bold
                                      : FontWeight.normal,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),

                              Container(
                                margin: const EdgeInsets.only(top: 1.5),
                                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                                decoration: BoxDecoration(
                                  color: giftsCount > 0
                                      ? const Color(0xFFFF1493).withOpacity(0.3)
                                      : Colors.white.withOpacity(0.06),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Text("🎁", style: TextStyle(fontSize: 8)),
                                    const SizedBox(width: 2),
                                    Text(
                                      "$giftsCount",
                                      style: TextStyle(
                                        color: giftsCount > 0
                                            ? const Color(0xFFFFD700)
                                            : Colors.white38,
                                        fontSize: 8.5,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ),

                // Messages Container
                Expanded(
                  flex: 4,
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.25),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.white10),
                    ),
                    child: ListView.builder(
                      controller: _chatScrollController,
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      itemCount: _messages.length,
                      itemBuilder: (context, index) {
                        final item = _messages[index];
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 3.0),
                          child: RichText(
                            text: TextSpan(
                              children: [
                                TextSpan(
                                  text: item.isSystem ? "📢 ${item.sender}: " : "${item.sender}: ",
                                  style: TextStyle(
                                    color: item.isSystem
                                        ? const Color(0xFFFFD700)
                                        : const Color(0xFF00E5FF),
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                  ),
                                ),
                                TextSpan(
                                  text: item.message,
                                  style: TextStyle(

color: item.isSystem ? Colors.white70 : Colors.white,
                                    fontSize: 12,
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

                // Bottom Bar
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: const BoxDecoration(
                    color: Color(0xFF141026),
                    borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                  ),
                  child: Row(
                    children: [
                      IconButton(
                        icon: Icon(
                          _isMuted ? Icons.mic_off : Icons.mic,
                          color: _mySeatIndex != null
                              ? (_isMuted ? Colors.redAccent : const Color(0xFF00E5FF))
                              : Colors.white24,
                          size: 26,
                        ),
                        onPressed: _mySeatIndex != null ? _toggleMute : null,
                      ),
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.08),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: Colors.white12),
                          ),
                          child: TextField(
                            controller: _chatController,
                            style: const TextStyle(color: Colors.white, fontSize: 13),
                            decoration: const InputDecoration(
                              hintText: "Say something...",
                              hintStyle: TextStyle(color: Colors.white38),
                              border: InputBorder.none,
                              isDense: true,
                              contentPadding: EdgeInsets.symmetric(vertical: 10),
                            ),
                            onSubmitted: (_) => _sendMessage(),
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.send_rounded, color: Color(0xFFFFD700), size: 22),
                        onPressed: _sendMessage,
                      ),
                      IconButton(
                        icon: const Icon(Icons.card_giftcard, color: Color(0xFFFFD700), size: 24),
                        onPressed: _openGiftSheet,
                      ),
                    ],
                  ),
                ),
              ],
            ),

            // Floating Gift Animation Overlay
            if (_isShowingGiftAnim)
              Positioned.fill(
                child: IgnorePointer(
                  child: Center(
                    child: FadeTransition(
                      opacity: _giftFlyOpacity,
                      child: ScaleTransition(
                        scale: _giftFlyScale,
                        child: Image.asset(
                          _activeGiftAsset,
                          width: 140,
                          height: 140,
                          fit: BoxFit.contain,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
