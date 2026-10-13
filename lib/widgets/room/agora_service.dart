import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:permission_handler/permission_handler.dart';

class AgoraService {
  static final AgoraService _instance = AgoraService._internal();

  factory AgoraService() {
    return _instance;
  }

  AgoraService._internal();

  RtcEngine? _engine;
  bool isInitialized = false;
  bool isMuted = false;

  Future<void> initAgora({
    required String appId,
    required String channelId,
    required Function(List<AudioVolumeInfo> speakers) onVolumeChanged,
  }) async {
    await [Permission.microphone].request();

    _engine = createAgoraRtcEngine();
    await _engine!.initialize(RtcEngineContext(
      appId: appId,
      channelProfile: ChannelProfileType.channelProfileLiveBroadcasting,
    ));

    _engine!.registerEventHandler(
      RtcEngineEventHandler(
        onAudioVolumeIndication: (RtcConnection connection, List<AudioVolumeInfo> speakers, int totalVolume) {
          onVolumeChanged(speakers);
        },
      ),
    );

    await _engine!.enableAudio();
    await _engine!.enableAudioVolumeIndication(
      interval: 200,
      smooth: 3,
      reportVad: true,
    );

    await _engine!.setClientRole(role: ClientRoleType.clientRoleAudience);

    await _engine!.joinChannel(
      token: '',
      channelId: channelId,
      uid: 0,
      options: const ChannelMediaOptions(),
    );

    isInitialized = true;
  }

  Future<void> joinMicSeat() async {
    if (!isInitialized || _engine == null) return;
    await _engine!.setClientRole(role: ClientRoleType.clientRoleBroadcaster);
    await _engine!.muteLocalAudioStream(false);
    isMuted = false;
  }

  Future<void> leaveMicSeat() async {
    if (!isInitialized || _engine == null) return;
    await _engine!.muteLocalAudioStream(true);
    await _engine!.setClientRole(role: ClientRoleType.clientRoleAudience);
    isMuted = true;
  }

  Future<bool> toggleMute() async {
    if (!isInitialized || _engine == null) return isMuted;
    isMuted = !isMuted;
    await _engine!.muteLocalAudioStream(isMuted);
    return isMuted;
  }

  Future<void> leaveRoom() async {
    if (_engine != null) {
      await _engine!.leaveChannel();
      await _engine!.release();
      _engine = null;
      isInitialized = false;
    }
  }
}
