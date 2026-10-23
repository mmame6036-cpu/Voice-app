import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:http/http.dart' as http;
import '../services/user_service.dart';
import '../services/task_tracker_service.dart';

class VoiceRoomScreen extends StatefulWidget {
  final String channelId;
  final String roomName;
  final bool isHost;

  const VoiceRoomScreen({
    Key? key,
    required this.channelId,
    required this.roomName,
    this.isHost = false,
  }) : super(key: key);

  @override
  State<VoiceRoomScreen> createState() => _VoiceRoomScreenState();
}

class _VoiceRoomScreenState extends State<VoiceRoomScreen> {
  final UserService _userService = UserService();
  final TaskTrackerService _taskTracker = TaskTrackerService();

  late RtcEngine _engine;
  bool _isJoined = false;
  bool _isMuted = false;
  int? _mySeatIndex;

  final List<Map<String, dynamic>?> _seats = List.filled(8, null);

  @override
  void initState() {
    super.initState();
    _initAgoraAndJoin();
  }

  @override
  void dispose() {
    _taskTracker.stopSeatTracking();
    _leaveChannel();
    super.dispose();
  }

  Future<void> _initAgoraAndJoin() async {
    await [Permission.microphone].request();

    try {
      final tokenUrl = Uri.parse(
        '${UserService.serverUrl}/api/agora/token?channelName=${widget.channelId}&uid=${_userService.userId}',
      );
      final res = await http.get(tokenUrl);
      final resData = jsonDecode(res.body);

      final String appId = resData['appId'] ?? '';
      final String token = resData['token'] ?? '';

      _engine = createAgoraRtcEngine();
      await _engine.initialize(RtcEngineContext(
        appId: appId,
        channelProfile: ChannelProfileType.channelProfileLiveBroadcasting,
      ));

      _engine.registerEventHandler(
        RtcEngineEventHandler(
          onJoinChannelSuccess: (RtcConnection connection, int elapsed) {
            setState(() => _isJoined = true);
            if (widget.isHost) {
              _takeSeat(0);
            }
          },
          onUserMuteAudio: (RtcConnection connection, int remoteUid, bool muted) {
            setState(() {
              for (var seat in _seats) {
                if (seat != null && seat['userId'] == remoteUid.toString()) {
                  seat['isMuted'] = muted;
                }
              }
            });
          },
        ),
      );

      await _engine.setClientRole(role: ClientRoleType.clientRoleAudience);
      await _engine.enableAudio();

      await _engine.setAudioProfile(
        profile: AudioProfileType.audioProfileMusicStandard,
        scenario: AudioScenarioType.audioScenarioGameStreaming,
      );

      await _engine.setParameters('{"che.audio.opensl":true}');
      await _engine.setParameters('{"che.audio.specify.codec":"OPUS"}');

      await _engine.adjustRecordingSignalVolume(100);
      await _engine.adjustPlaybackSignalVolume(100);

      await _engine.joinChannel(
        token: token,
        channelId: widget.channelId,
        uid: int.tryParse(_userService.userId) ?? 0,
        options: const ChannelMediaOptions(
          clientRoleType: ClientRoleType.clientRoleAudience,
          autoSubscribeAudio: true,
          publishMicrophoneTrack: false,
          enableAudioRecordingOrPlayout: true,
        ),
      );
    } catch (e) {
      debugPrint('Agora initialization error: $e');
    }
  }

  Future<void> _leaveChannel() async {
    try {
      await _engine.leaveChannel();
      await _engine.release();
    } catch (e) {
      debugPrint('Error leaving agora channel: $e');
    }
  }

  Future<void> _takeSeat(int seatIndex) async {
    if (_seats[seatIndex] != null) return;

    if (_mySeatIndex != null) {
      _leaveSeat();
    }

setState(() {
      _mySeatIndex = seatIndex;
      _seats[seatIndex] = {
        'userId': _userService.userId,
        'userName': _userService.userName,
        'isCrown': seatIndex == 0,
        'isMuted': false,
        'receivedGifts': 0,
      };
    });

    await _engine.setClientRole(role: ClientRoleType.clientRoleBroadcaster);
    await _engine.updateChannelMediaOptions(
      const ChannelMediaOptions(
        publishMicrophoneTrack: true,
        clientRoleType: ClientRoleType.clientRoleBroadcaster,
      ),
    );
    await _engine.muteLocalAudioStream(false);
    setState(() => _isMuted = false);

    if (seatIndex == 0) {
      _taskTracker.startSeatTracking('crown_seat');
    } else {
      _taskTracker.startSeatTracking('normal_seat');
    }
  }

  Future<void> _leaveSeat() async {
    if (_mySeatIndex == null) return;

    setState(() {
      _seats[_mySeatIndex!] = null;
      _mySeatIndex = null;
    });

    _taskTracker.stopSeatTracking();
    await _engine.muteLocalAudioStream(true);
    await _engine.updateChannelMediaOptions(
      const ChannelMediaOptions(
        publishMicrophoneTrack: false,
        clientRoleType: ClientRoleType.clientRoleAudience,
      ),
    );
    await _engine.setClientRole(role: ClientRoleType.clientRoleAudience);
  }

  void _toggleMute() {
    if (_mySeatIndex == null) return;
    final newMuteState = !_isMuted;
    _engine.muteLocalAudioStream(newMuteState);
    setState(() {
      _isMuted = newMuteState;
      if (_seats[_mySeatIndex!] != null) {
        _seats[_mySeatIndex!]['isMuted'] = newMuteState;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0C20),
      appBar: AppBar(
        backgroundColor: const Color(0xFF191432),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.roomName, style: const TextStyle(fontSize: 16, color: Colors.white, fontWeight: FontWeight.bold)),
            Text('ID: ${widget.channelId}', style: const TextStyle(fontSize: 11, color: Colors.white54)),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.exit_to_app, color: Colors.redAccent),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
              child: _buildSeatsGrid(),
            ),
          ),
          _buildBottomBar(),
        ],
      ),
    );
  }

  Widget _buildSeatsGrid() {
    return GridView.builder(
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        crossAxisSpacing: 12,
        mainAxisSpacing: 16,
        childAspectRatio: 0.65,
      ),
      itemCount: 8,
      itemBuilder: (context, index) {
        final seat = _seats[index];
        final isCrown = index == 0;
        final isMySeat = _mySeatIndex == index;
        final bool isSeatOccupied = seat != null;
        final bool seatMuted = seat != null ? (seat['isMuted'] ?? false) : true;
        final int gifts = seat != null ? (seat['receivedGifts'] ?? 0) : 0;

        return GestureDetector(
          onTap: () {
            if (seat == null) {
              _takeSeat(index);
            } else if (isMySeat) {
              _leaveSeat();
            }
          },
          child: Column(
            children: [

Stack(
                clipBehavior: Clip.none,
                alignment: Alignment.center,
                children: [
                  Container(
                    width: 62,
                    height: 62,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: const Color(0xFF1E1742),
                      border: Border.all(
                        color: isCrown ? Colors.amber : (isSeatOccupied ? const Color(0xFF00C9A7) : Colors.white12),
                        width: 2,
                      ),
                    ),
                    child: Center(
                      child: isSeatOccupied
                          ? Text(
                              seat['userName'] != null && seat['userName'].isNotEmpty
                                  ? seat['userName'][0].toUpperCase()
                                  : 'U',
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 20),
                            )
                          : Icon(
                              isCrown ? Icons.military_tech : Icons.weekend,
                              color: isCrown ? Colors.amber : Colors.white24,
                              size: 28,
                            ),
                    ),
                  ),
                  if (isCrown)
                    const Positioned(
                      top: -6,
                      child: Icon(Icons.star, color: Colors.amber, size: 16),
                    ),
                  if (isSeatOccupied)
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        padding: const EdgeInsets.all(3),
                        decoration: BoxDecoration(
                          color: seatMuted ? Colors.redAccent : const Color(0xFF00C9A7),
                          shape: BoxShape.circle,
                          border: Border.all(color: const Color(0xFF0F0C20), width: 1.5),
                        ),
                        child: Icon(
                          seatMuted ? Icons.mic_off : Icons.mic,
                          color: Colors.white,
                          size: 11,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                isSeatOccupied ? (isMySeat ? 'You' : seat['userName']) : '${index + 1}',
                style: TextStyle(
                  color: isSeatOccupied ? Colors.white : Colors.white38,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E1742),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.white10),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.card_giftcard, size: 10, color: Colors.amber),
                    const SizedBox(width: 3),
                    Text(
                      '$gifts',
                      style: const TextStyle(
                        color: Colors.amber,
                        fontSize: 10,
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
    );
  }

  Widget _buildBottomBar() {
    final bool onSeat = _mySeatIndex != null;

return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: const BoxDecoration(
        color: Color(0xFF191432),
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: Icon(
              onSeat
                  ? (_isMuted ? Icons.mic_off : Icons.mic)
                  : Icons.mic_none,
              color: onSeat ? (_isMuted ? Colors.redAccent : const Color(0xFF00C9A7)) : Colors.white24,
            ),
            onPressed: onSeat ? _toggleMute : null,
          ),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: onSeat ? Colors.redAccent.withOpacity(0.8) : const Color(0xFF6C4AB6),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
            ),
            icon: Icon(onSeat ? Icons.call_end : Icons.airline_seat_recline_normal, size: 18, color: Colors.white),
            label: Text(
              onSeat ? 'Leave Seat' : 'Take Free Seat',
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
            onPressed: () {
              if (onSeat) {
                _leaveSeat();
              } else {
                for (int i = 0; i < _seats.length; i++) {
                  if (_seats[i] == null) {
                    _takeSeat(i);
                    break;
                  }
                }
              }
            },
          ),
        ],
      ),
    );
  }
}
