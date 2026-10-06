import 'room_chairs_grid.dart';
import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
// ==========================================
// 🎙️ VOICE ROOM SCREEN (30 ወንበሮች፦ 1 ባለቤት + 6 ወርቃማ + 23 መደበኛ)
// ==========================================
class VoiceRoomScreen extends StatefulWidget {
  final String channelName;
  final String roomTitle;
  final bool isOwner;

  const VoiceRoomScreen({
    Key? key,
    required this.channelName,
    required this.roomTitle,
    this.isOwner = true,
  }) : super(key: key);

  @override
  State<VoiceRoomScreen> createState() => _VoiceRoomScreenState();
}

class _VoiceRoomScreenState extends State<VoiceRoomScreen> {
  late RtcEngine _engine;
  bool _isJoined = false;
  bool _isMuted = false;
  IO.Socket? socket;
  final List<int> _remoteUsers = [];
  final String _appId = "aab8b8f3e2444379a1f28b4d82b3d888";

  int? _myCurrentSeat;
  int _roomGameTurnover = 8500000;
  Timer? _seatRewardTimer;
  int _secondsOnGoldenSeat = 0;

  @override
  void initState() {
    super.initState();
    _initAgora();
    _initSocket();
  }

  Future<void> _initAgora() async {
    await [Permission.microphone].request();

    _engine = createAgoraRtcEngine();
    await _engine.initialize(RtcEngineContext(appId: _appId));

    _engine.registerEventHandler(
      RtcEngineEventHandler(
        onJoinChannelSuccess: (RtcConnection connection, int elapsed) {
          if (mounted) {
            setState(() {
              _isJoined = true;
            });
          }
        },
        onUserJoined: (RtcConnection connection, int remoteUid, int elapsed) {
          if (mounted) {
            setState(() {
              _remoteUsers.add(remoteUid);
            });
          }
        },
        onUserOffline: (RtcConnection connection, int remoteUid, UserOfflineReasonType reason) {
          if (mounted) {
            setState(() {
              _remoteUsers.remove(remoteUid);
            });
          }
        },
      ),
    );

    await _engine.setChannelProfile(ChannelProfileType.channelProfileLiveBroadcasting);
    await _engine.setClientRole(role: ClientRoleType.clientRoleBroadcaster);
    await _engine.enableAudio();

    await _engine.joinChannel(
      token: '',
      channelId: widget.channelName,
      uid: Random().nextInt(900000) + 100000,
      options: const ChannelMediaOptions(
        publishMicrophoneTrack: true,
        autoSubscribeAudio: true,
        clientRoleType: ClientRoleType.clientRoleBroadcaster,
      ),
    );
  }
void _initSocket() {
    socket = IO.io(
      'https://voice-app-9i6c.onrender.com',
      IO.OptionBuilder().setTransports(['websocket']).build(),
    );
    socket?.connect();
    socket?.onConnect((_) {
      socket?.emit('join_room', widget.channelName);
    });
  }
  void _toggleMute() {
    setState(() {
      _isMuted = !_isMuted;
    });
    _engine.muteLocalAudioStream(_isMuted);
  }

  void _startSeatRewardTimer() {
    _seatRewardTimer?.cancel();
    _secondsOnGoldenSeat = 0;
    _seatRewardTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          _secondsOnGoldenSeat++;
        });
      }
    });
  }
const RoomChairsGrid(),
  void _stopSeatRewardTimer() {
    _seatRewardTimer?.cancel();
    _secondsOnGoldenSeat = 0;
  }

  void _handleSeatTap(int seatNumber) {
    if (seatNumber == 1) {
      if (!widget.isOwner) {
        _showLockedDialog(
          title: 'የባለቤት ወንበር 👑',
          message: 'ይህ ወንበር ቁጥር 1 የክፍሉ ባለቤት ብቻ የሚቀመጥበት ነው!',
        );
        return;
      }
    }

    if (seatNumber >= 2 && seatNumber <= 4) {
      const int tier1Target = 7000000;
      if (_roomGameTurnover < tier1Target) {
        int remaining = tier1Target - _roomGameTurnover;
        _showLockedDialog(
          title: 'ወርቃማ ወንበር (ደረጃ 1) 🔒',
          message: 'ይህ ወርቃማ ወንበር እንዲከፈት ክፍሉ ውስጥ 7,000,000 የጌም ኮይን መንቀሳቀስ አለበት!\n\nየቀረው የጌም ኮይን፦ $remaining',
        );
        return;
      }
    }

    if (seatNumber >= 5 && seatNumber <= 7) {
      const int tier2Target = 14000000;

if (_roomGameTurnover < tier2Target) {
        int remaining = tier2Target - _roomGameTurnover;
        _showLockedDialog(
          title: 'ወርቃማ ወንበር (ደረጃ 2) 🔒',
          message: 'እነዚህ የመጨረሻዎቹ 3 ወርቃማ ወንበሮች እንዲከፈቱ ተጨማሪ 7 ሚሊየን (በድምሩ 14,000,000) የጌም ኮይን ያስፈልጋል!\n\nየቀረው የጌም ኮይን፦ $remaining',
        );
        return;
      }
    }

    setState(() {
      _myCurrentSeat = seatNumber;
    });

    bool isGolden = seatNumber >= 2 && seatNumber <= 7;
    if (isGolden) {
      _startSeatRewardTimer();
    } else {
      _stopSeatRewardTimer();
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          seatNumber == 1
              ? '👑 የክፍሉ ባለቤት ወንበር ላይ ተቀምጠዋል!'
              : (isGolden
                  ? '✨ እንኳን ደስ አለዎት! በተከፈተው ወርቃማ ወንበር ቁጥር $seatNumber ላይ ተቀምጠዋል!'
                  : 'በወንበር ቁጥር $seatNumber ላይ ተቀምጠዋል።'),
        ),
        backgroundColor: isGolden ? Colors.amber[800] : const Color(0xFF00C9A7),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _leaveSeat() {
    _stopSeatRewardTimer();
    setState(() {
      _myCurrentSeat = null;
    });
  }

  void _showLockedDialog({required String title, required String message}) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF161B26),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Icon(Icons.lock, color: Colors.amber, size: 24),
            const SizedBox(width: 8),
            Expanded(
              child: Text(title, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
        content: Text(message, style: const TextStyle(color: Colors.white70, fontSize: 13, height: 1.4)),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF00C9A7)),
            onPressed: () => Navigator.pop(context),
            child: const Text('እሺ', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _stopSeatRewardTimer();
    _engine.leaveChannel();
    _engine.release();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    bool tier1Unlocked = _roomGameTurnover >= 7000000;
    bool tier2Unlocked = _roomGameTurnover >= 14000000;

    return Scaffold(
      backgroundColor: const Color(0xFF0D111A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF161B26),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.roomTitle, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            Text(
              '🎮 Game Turnover: $_roomGameTurnover Coins',
              style: const TextStyle(fontSize: 11, color: Colors.amberAccent),
            ),
          ],
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            decoration: BoxDecoration(
              color: _isJoined ? Colors.green.withOpacity(0.2) : Colors.orange.withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              _myCurrentSeat != null && _myCurrentSeat! >= 2 && _myCurrentSeat! <= 7
                  ? '👑 Golden Seat Time: $_secondsOnGoldenSeat sec (Earning...)'
                  : (_isJoined ? '● Live in Nile Voice Room' : 'Connecting...'),

style: TextStyle(
                color: _myCurrentSeat != null && _myCurrentSeat! >= 2 && _myCurrentSeat! <= 7
                    ? Colors.amberAccent
                    : (_isJoined ? Colors.greenAccent : Colors.orangeAccent),
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ),
          const SizedBox(height: 10),
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              itemCount: 30,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 5,
                crossAxisSpacing: 10,
                mainAxisSpacing: 14,
                childAspectRatio: 0.72,
              ),
              itemBuilder: (context, index) {
                int seatNumber = index + 1;
                bool isOwnerSeat = seatNumber == 1;
                bool isGoldenTier1 = seatNumber >= 2 && seatNumber <= 4;
                bool isGoldenTier2 = seatNumber >= 5 && seatNumber <= 7;
                bool isGolden = isGoldenTier1 || isGoldenTier2;
                bool isOccupiedByMe = _myCurrentSeat == seatNumber;

                bool isLocked = false;
                if (isGoldenTier1 && !tier1Unlocked) isLocked = true;
                if (isGoldenTier2 && !tier2Unlocked) isLocked = true;

                return GestureDetector(
                  onTap: () => _handleSeatTap(seatNumber),
                  child: Column(
                    children: [
                      Stack(
                        alignment: Alignment.center,
                        children: [
                          Container(
                            width: 52,
                            height: 52,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: isOwnerSeat
                                  ? const LinearGradient(colors: [Color(0xFFE50914), Color(0xFFB71C1C)])
                                  : (isGolden
                                      ? (isLocked
                                          ? const LinearGradient(colors: [Color(0xFF5D4037), Color(0xFF3E2723)])
                                          : const LinearGradient(colors: [Color(0xFFFFD700), Color(0xFFFFA000)]))
                                      : null),
                              color: (isOwnerSeat || isGolden) ? null : const Color(0xFF1E2433),
                              border: Border.all(
                                color: isOwnerSeat
                                    ? Colors.redAccent
                                    : (isGolden
                                        ? (isLocked ? Colors.white24 : Colors.amberAccent)
                                        : (isOccupiedByMe ? const Color(0xFF00C9A7) : Colors.white12)),
                                width: (isOwnerSeat || isGolden) ? 2.5 : 1.5,
                              ),
                              boxShadow: (isOwnerSeat || (isGolden && !isLocked))
                                  ? [
                                      BoxShadow(
                                        color: (isOwnerSeat ? Colors.red : Colors.amber).withOpacity(0.4),
                                        blurRadius: 8,
                                        spreadRadius: 1,
                                      )
                                    ]
                                  : [],
                            ),
                            child: CircleAvatar(
                              backgroundColor: isOccupiedByMe
                                  ? const Color(0xFF00C9A7)
                                  : (isOwnerSeat

? const Color(0xFF3E0A0D)
                                      : (isGolden
                                          ? (isLocked ? Colors.black45 : const Color(0xFF2A2000))
                                          : const Color(0xFF141923))),
                              child: Icon(
                                isOccupiedByMe
                                    ? Icons.mic
                                    : (isOwnerSeat
                                        ? Icons.star
                                        : (isGolden
                                            ? (isLocked ? Icons.lock : Icons.workspace_premium)
                                            : Icons.airline_seat_recline_normal)),
                                color: isOccupiedByMe
                                    ? Colors.black
                                    : (isOwnerSeat
                                        ? Colors.redAccent
                                        : (isGolden
                                            ? (isLocked ? Colors.white38 : Colors.amber)
                                            : Colors.white24)),
                                size: (isOwnerSeat || isGolden) ? 22 : 18,
                              ),
                            ),
                          ),
                          if (isOwnerSeat)
                            const Positioned(
                              top: -2,
                              child: Icon(Icons.shield, size: 14, color: Colors.white),
                            )
                          else if (isGolden && !isLocked)
                            const Positioned(
                              top: -2,
                              child: Icon(Icons.star, size: 14, color: Colors.amberAccent),
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        isOccupiedByMe
                            ? 'You'
                            : (isOwnerSeat
                                ? 'Owner'
                                : (isGolden
                                    ? (isLocked ? '🔒 Gold $seatNumber' : 'Gold $seatNumber')
                                    : '$seatNumber')),
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: (isOwnerSeat || isGolden) ? FontWeight.bold : FontWeight.normal,
                          color: isOwnerSeat
                              ? Colors.redAccent
                              : (isGolden
                                  ? (isLocked ? Colors.white38 : Colors.amberAccent)
                                  : Colors.white60),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            decoration: const BoxDecoration(
              color: Color(0xFF161B26),
              borderRadius: BorderRadius.only(topLeft: Radius.circular(20), topRight: Radius.circular(20)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                IconButton(
                  onPressed: _toggleMute,
                  iconSize: 28,
                  icon: Icon(
                    _isMuted ? Icons.mic_off : Icons.mic,
                    color: _isMuted ? Colors.red : const Color(0xFF00C9A7),
                  ),
                ),
                if (_myCurrentSeat != null)

ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white12,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    onPressed: _leaveSeat,
                    icon: const Icon(Icons.arrow_downward, size: 16, color: Colors.white70),
                    label: const Text('ውረድ', style: TextStyle(color: Colors.white, fontSize: 12)),
                  ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  iconSize: 28,
                  icon: const Icon(Icons.call_end, color: Colors.redAccent),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
