import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:permission_handler/permission_handler.dart';

class AgoraService {
  static const String appId = "YOUR_AGORA_APP_ID";

  late RtcEngine _engine;
  bool _isInitialized = false;

  Future<void> initAgora({
    required Function(int uid) onUserJoined,
    required Function(int uid) onUserOffline,
    required Function(bool isMuted) onMicrophoneChanged,
  }) async {
    if (_isInitialized) return;

    await [Permission.microphone].request();

    _engine = createAgoraRtcEngine();
    await _engine.initialize(const RtcEngineContext(
      appId: appId,
      channelProfile: ChannelProfileType.channelProfileLiveBroadcasting,
    ));

    _engine.registerEventHandler(
      RtcEngineEventHandler(
        onJoinChannelSuccess: (RtcConnection connection, int elapsed) {},
        onUserJoined: (RtcConnection connection, int remoteUid, int elapsed) {
          onUserJoined(remoteUid);
        },
        onUserOffline: (RtcConnection connection, int remoteUid, UserOfflineReasonType reason) {
          onUserOffline(remoteUid);
        },
      ),
    );

    await _engine.enableAudio();
    await _engine.setAudioProfile(
      profile: AudioProfileType.audioProfileMusicStandard,
      scenario: AudioScenarioType.audioScenarioGameStreaming,
    );

    _isInitialized = true;
  }

  Future<void> joinVoiceRoom({
    required String channelId,
    required int uid,
    required bool isBroadcaster,
  }) async {
    if (!_isInitialized) return;

    await _engine.setClientRole(
      role: isBroadcaster 
          ? ClientRoleType.clientRoleBroadcaster 
          : ClientRoleType.clientRoleAudience,
    );

    await _engine.joinChannel(
      token: "",
      channelId: channelId,
      uid: uid,
      options: const ChannelMediaOptions(
        autoSubscribeAudio: true,
        publishMicrophoneTrack: true,
        clientRoleType: ClientRoleType.clientRoleAudience,
      ),
    );
  }

  Future<void> updateRole({required bool isBroadcaster}) async {
    if (!_isInitialized) return;
    await _engine.setClientRole(
      role: isBroadcaster 
          ? ClientRoleType.clientRoleBroadcaster 
          : ClientRoleType.clientRoleAudience,
    );
    if (!isBroadcaster) {
      await _engine.muteLocalAudioStream(true);
    } else {
      await _engine.muteLocalAudioStream(false);
    }
  }

  Future<void> toggleMute(bool isMuted) async {
    if (!_isInitialized) return;
    await _engine.muteLocalAudioStream(isMuted);
  }

  Future<void> leaveRoom() async {
    if (!_isInitialized) return;
    await _engine.leaveChannel();
  }

  Future<void> dispose() async {
    if (_isInitialized) {
      await _engine.leaveChannel();
      await _engine.release();
      _isInitialized = false;
    }
  }
}
