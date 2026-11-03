import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:http/http.dart' as http;
import '../services/agora_service.dart';

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
    with SingleTickerProviderStateMixin {
  final AgoraService _agoraService = AgoraService();
  bool _isMuted = false;
  int? _mySeatIndex;
  int _totalSeats = 30; // Options: 6, 12, 20, 25, 30
  late List<String?> _seats;
  late List<int> _seatGifts;
  late List<bool> _seatMutes;
  bool _isConnecting = true;

  late AnimationController _waveController;
  final Set<int> _speakingSeatIndices = {};

  final List<int> _allowedSeatOptions = [6, 12, 20, 25, 30];

  @override
  void initState() {
    super.initState();
    _seats = List.filled(30, null);
    _seatGifts = List.filled(30, 0);
    _seatMutes = List.filled(30, false);
    _seats[0] = widget.hostName;

    _waveController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    )..repeat(reverse: true);

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
      onUserJoined: (uid) {},
      onUserOffline: (uid) {},
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

  @override
  void dispose() {
    _waveController.dispose();
    _agoraService.leaveRoom();
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
          // Seats Selector Dropdown (6, 12, 20, 25, 30)
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
        child: Column(
          children: [
            const SizedBox(height: 6),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10.0),
                child: GridView.builder(
                  physics: const BouncingScrollPhysics(),
                  itemCount: _totalSeats,
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: crossAxis,
                    mainAxisSpacing: 8,
                    crossAxisSpacing: 6,
                    childAspectRatio: 0.68,
                  ),
                  itemBuilder: (context, index) {
                    final occupier = _seats[index];
                    final isOccupied = occupier != null;
                    final isMe = _mySeatIndex == index;
                    final isSpeaking = _speakingSeatIndices.contains(index);
                    final isMuted = _seatMutes[index];
                    final giftsCount = _seatGifts[index];

                    // Seats 2,3,4,5,6,7 (Index 1 to 6) get Crown
                    final bool isCrownSeat = index >= 1 && index <= 6;
                    final bool isHostSeat = index == 0;

                    return GestureDetector(
                      onTap: () => _handleSeatTap(index),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Stack(
                            clipBehavior: Clip.none,
                            alignment: Alignment.center,
                            children: [
                              // Crown on top for seats 2, 3, 4, 5, 6, 7 & Host
                              if (isCrownSeat || isHostSeat)
                                Positioned(
                                  top: -12,
                                  child: Icon(
                                    Icons.military_tech_rounded,
                                    size: 18,
                                    color: isHostSeat
                                        ? const Color(0xFFFF5252)
                                        : const Color(0xFFFFD700),
                                  ),
                                ),

                              // Animated Seat Circle
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
                                          ? (isMe
                                              ? const Color(0xFF00C9A7)
                                              : (isCrownSeat
                                                  ? const Color(0xFF382900)
                                                  : const Color(0xFF2C2454)))
                                          : Colors.white.withOpacity(0.06),

border: Border.all(
                                        color: isSpeaking
                                            ? const Color(0xFF00E5FF)
                                            : (isCrownSeat
                                                ? const Color(0xFFFFD700)
                                                : (isOccupied
                                                    ? Colors.white70
                                                    : Colors.white24)),
                                        width: isSpeaking
                                            ? (2.0 + wave * 1.5)
                                            : (isCrownSeat ? 2.0 : 1.2),
                                      ),
                                      boxShadow: isSpeaking
                                          ? [
                                              BoxShadow(
                                                color: const Color(0xFF00E5FF)
                                                    .withOpacity(0.5 + (wave * 0.4)),
                                                blurRadius: 10 + (wave * 8),
                                                spreadRadius: 2 + (wave * 3),
                                              ),
                                            ]
                                          : (isCrownSeat
                                              ? [
                                                  BoxShadow(
                                                    color: const Color(0xFFFFD700)
                                                        .withOpacity(0.3),
                                                    blurRadius: 6,
                                                  )
                                                ]
                                              : null),
                                    ),
                                    child: Center(
                                      child: Icon(
                                        isOccupied ? Icons.person : Icons.chair,
                                        color: isOccupied
                                            ? (isCrownSeat
                                                ? const Color(0xFFFFD700)
                                                : Colors.white)
                                            : Colors.white24,
                                        size: seatDimension * 0.45,
                                      ),
                                    ),
                                  );
                                },
                              ),

                              // Bottom-Right Microphone Status Badge
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
                                            boxShadow: [
                                              BoxShadow(
                                                color: Colors.black.withOpacity(0.6),
                                                blurRadius: 4,
                                              ),
                                            ],
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

                          // Seat Name / Number
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

                          // Gift Counter under each seat
                          Container(
                            margin: const EdgeInsets.only(top: 1.5),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 4, vertical: 1),
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
                                        ? const Color(0xFFFF69B4)
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

            // Bottom Controller Bar
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
              decoration: const BoxDecoration(
                color: Color(0xFF141026),

borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: Icon(
                      _isMuted ? Icons.mic_off : Icons.mic,
                      color: _mySeatIndex != null
                          ? (_isMuted ? Colors.redAccent : const Color(0xFF00E5FF))
                          : Colors.white24,
                      size: 28,
                    ),
                    onPressed: _mySeatIndex != null ? _toggleMute : null,
                  ),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFFD700),
                      foregroundColor: Colors.black,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                    ),
                    icon: const Icon(Icons.card_giftcard, size: 18),
                    label: const Text(
                      "Send Gift",
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                    onPressed: () {
                      // Demo: sends gift point to seat 1 and crown seat 2
                      setState(() {
                        _seatGifts[0] += 10;
                        _seatGifts[1] += 5;
                      });
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("Gifts added to counters!")),
                      );
                    },
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
