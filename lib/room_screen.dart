import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:agora_rtc_engine/agora_rtc_engine.dart';

const String appId = "YOUR_AGORA_APP_ID";
const String channelId = "voice_room_1";

class RoomScreen extends StatefulWidget {
  const RoomScreen({super.key});

  @override
  State<RoomScreen> createState() => _RoomScreenState();
}

class _RoomScreenState extends State<RoomScreen>
    with SingleTickerProviderStateMixin {
  late RtcEngine _engine;
  bool _isJoined = false;
  bool _isMuted = false;
  bool _isSpeaking = false;
  late AnimationController _waveController;

  @override
  void initState() {
    super.initState();
    _waveController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);

    _initVoiceEngine();
  }

  Future<void> _initVoiceEngine() async {
    await [Permission.microphone].request();

    _engine = createAgoraRtcEngine();
    await _engine.initialize(const RtcEngineContext(
      appId: appId,
      channelProfile: ChannelProfileType.channelProfileLiveBroadcasting,
    ));

    _engine.registerEventHandler(
      RtcEngineEventHandler(
        onJoinChannelSuccess: (RtcConnection connection, int elapsed) {
          if (mounted) {
            setState(() {
              _isJoined = true;
            });
          }
        },
        onAudioVolumeIndication: (RtcConnection connection,
            List<AudioVolumeInfo> speakers, int totalVolume, int? vad) {
          if (mounted) {
            setState(() {
              _isSpeaking = totalVolume > 5;
            });
          }
        },
      ),
    );

    await _engine.enableAudioVolumeIndication(
        interval: 200, smooth: 3, reportVad: true);
    await _engine.setClientRole(role: ClientRoleType.clientRoleBroadcaster);
    await _engine.enableAudio();

    await _engine.joinChannel(
      token: "",
      channelId: channelId,
      uid: 0,
      options: const ChannelMediaOptions(
        clientRoleType: ClientRoleType.clientRoleBroadcaster,
        autoSubscribeAudio: true,
        publishMicrophoneTrack: true,
      ),
    );
  }

  void _toggleMic() async {
    setState(() {
      _isMuted = !_isMuted;
    });
    await _engine.muteLocalAudioStream(_isMuted);
  }

  @override
  void dispose() {
    _waveController.dispose();
    _engine.leaveChannel();
    _engine.release();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0C20),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          children: [
            const CircleAvatar(
              radius: 18,
              backgroundColor: Colors.purpleAccent,
              child: Icon(Icons.mic, color: Colors.white, size: 20),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('VIP Live Room',
                    style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: Colors.white)),
                Text(
                  _isJoined ? 'የተገናኘ (Live)' : 'በመገናኘት ላይ...',
                  style: TextStyle(
                      fontSize: 11,
                      color:
                          _isJoined ? Colors.greenAccent : Colors.orangeAccent),
                ),
              ],
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          const SizedBox(height: 25),
          Center(
            child: Column(
              children: [
                AnimatedBuilder(
                  animation: _waveController,
                  builder: (context, child) {
                    return Container(
                      padding: EdgeInsets.all(_isSpeaking && !_isMuted
                          ? _waveController.value * 8
                          : 0),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: _isSpeaking && !_isMuted
                              ? Colors.greenAccent
                              : Colors.amber,
                          width: 3,
                        ),
                        boxShadow: [
                          if (_isSpeaking && !_isMuted)
                            BoxShadow(
                              color: Colors.greenAccent.withAlpha(128),
                              blurRadius: 15,
                              spreadRadius: 4,
                            ),
                        ],
                      ),
                      child: child,
                    );
                  },
                  child: const CircleAvatar(
                    radius: 40,
                    backgroundColor: Color(0xFF2A2247),
                    child: Icon(Icons.person, size: 45, color: Colors.amber),
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('Host',
                        style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 15)),
                    const SizedBox(width: 5),
                    Icon(
                      _isMuted ? Icons.mic_off : Icons.mic,
                      color: _isMuted ? Colors.redAccent : Colors.greenAccent,
                      size: 16,
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 35),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: GridView.builder(
                physics: const NeverScrollableScrollPhysics(),
                itemCount: 8,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 4,
                  mainAxisSpacing: 20,
                  crossAxisSpacing: 20,
                  childAspectRatio: 0.8,
                ),
                itemBuilder: (context, index) {
                  return Column(
                    children: [
                      Container(
                        height: 52,
                        width: 52,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: const Color(0xFF1E1736),
                          border: Border.all(color: Colors.white12),
                        ),
                        child: Icon(Icons.chair,
                            color: Colors.white.withAlpha(77), size: 22),
                      ),
                      const SizedBox(height: 6),
                      Text('${index + 1}',
                          style: const TextStyle(
                              color: Colors.white54, fontSize: 12)),
                    ],
                  );
                },
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            decoration: const BoxDecoration(
              color: Color(0xFF16112C),
              borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(25), topRight: Radius.circular(25)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Row(
                  children: [
                    Icon(Icons.headset, color: Colors.white54, size: 20),
                    SizedBox(width: 8),
                    Text('የድምፅ ክፍል ክፍት ነው',
                        style: TextStyle(color: Colors.white54, fontSize: 12)),
                  ],
                ),
                FloatingActionButton.small(
                  backgroundColor:
                      _isMuted ? Colors.redAccent : Colors.tealAccent,
                  onPressed: _toggleMic,
                  child: Icon(
                    _isMuted ? Icons.mic_off : Icons.mic,
                    color: _isMuted ? Colors.white : Colors.black,
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
