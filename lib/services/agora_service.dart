import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:permission_handler/permission_handler.dart';

class AgoraService {
  static const String appId = "21091aff01114a66b580ce15b0f1b642";
  static const String token = "";

  RtcEngine? _engine;
  bool _isReady = false;

  Future<void> initEngine({
    required Function(int uid) onUserJoined,
    required Function(int uid) onUserOffline,
    required Function(List<AudioVolumeInfo> speakers) onVolumeChanged,
  }) async {
    if (_isReady) return;

    await [Permission.microphone].request();

    _engine = createAgoraRtcEngine();
    await _engine!.initialize(const RtcEngineContext(
      appId: appId,
      channelProfile: ChannelProfileType.channelProfileLiveBroadcasting,
      audioScenario: AudioScenarioType.audioScenarioGameStreaming,
    ));

    // የድምፅ መለኪያውን ማብራት
    await _engine!.enableAudioVolumeIndication(
      interval: 200,
      smooth: 3,
      reportVad: true,
    );

    _engine!.registerEventHandler(
      RtcEngineEventHandler(
        onJoinChannelSuccess: (RtcConnection connection, int elapsed) {},
        onUserJoined: (RtcConnection connection, int remoteUid, int elapsed) {
          onUserJoined(remoteUid);
        },
        onUserOffline: (RtcConnection connection, int remoteUid, UserOfflineReasonType reason) {
          onUserOffline(remoteUid);
        },
        onAudioVolumeIndication: (
          RtcConnection connection,
          List<AudioVolumeInfo> speakers,
          int totalVolume,
          int speakerNumber,
        ) {
          onVolumeChanged(speakers);
        },
      ),
    );

    await _engine!.enableAudio();
    await _engine!.setAudioProfile(
      profile: AudioProfileType.audioProfileMusicStandard,
      scenario: AudioScenarioType.audioScenarioGameStreaming,
    );

    _isReady = true;
  }

  Future<void> joinRoom({
    required String channelId,
    required int uid,
    required bool isSpeaker,
  }) async {
    if (!_isReady || _engine == null) return;

    await _engine!.setClientRole(
      role: isSpeaker
          ? ClientRoleType.clientRoleBroadcaster
          : ClientRoleType.clientRoleAudience,
    );

    await _engine!.joinChannel(
      token: token,
      channelId: channelId,
      uid: uid,
      options: ChannelMediaOptions(
        clientRoleType: isSpeaker
            ? ClientRoleType.clientRoleBroadcaster
            : ClientRoleType.clientRoleAudience,
        autoSubscribeAudio: true,
        publishMicrophoneTrack: isSpeaker,
      ),
    );
  }

  Future<void> switchRole({required bool isSpeaker}) async {
    if (!_isReady || _engine == null) return;

    await _engine!.setClientRole(
      role: isSpeaker
          ? ClientRoleType.clientRoleBroadcaster
          : ClientRoleType.clientRoleAudience,
    );

    await _engine!.updateChannelMediaOptions(
      ChannelMediaOptions(
        clientRoleType: isSpeaker
            ? ClientRoleType.clientRoleBroadcaster
            : ClientRoleType.clientRoleAudience,
        publishMicrophoneTrack: isSpeaker,
        autoSubscribeAudio: true,
      ),
    );

    if (!isSpeaker) {
      await _engine!.muteLocalAudioStream(true);
    } else {
      await _engine!.muteLocalAudioStream(false);
    }
  }

  Future<void> setMicrophoneMute(bool isMuted) async {
    if (!_isReady || _engine == null) return;
    await _engine!.muteLocalAudioStream(isMuted);
  }

  Future<void> leaveRoom() async {
    if (_engine != null && _isReady) {
      await _engine!.leaveChannel();
      await _engine!.release();
      _isReady = false;
    }
  }
}
