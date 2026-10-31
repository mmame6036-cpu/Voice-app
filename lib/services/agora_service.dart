import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:permission_handler/permission_handler.dart';

class AgoraService {
  // አዲሱ የ NILE-Live App ID
  static const String appId = "d00a25d96dfc44cc866cd8f41c496b36";
  static const String token = "";

  RtcEngine? _engine;
  bool _isReady = false;

  Future<void> initEngine({
    required Function(int uid) onUserJoined,
    required Function(int uid) onUserOffline,
    Function(List<AudioVolumeInfo> speakers)? onVolumeChanged,
  }) async {
    if (_isReady) return;

    await [Permission.microphone].request();

    _engine = createAgoraRtcEngine();
    await _engine!.initialize(const RtcEngineContext(
      appId: appId,
      channelProfile: ChannelProfileType.channelProfileLiveBroadcasting,
      audioScenario: AudioScenarioType.audioScenarioGameStreaming,
    ));

    // የድምፅ መለኪያውን ማብራት (ሰው ሲያወራ አኒሜሽን እንዲያሳይ)
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
          if (onVolumeChanged != null) {
            onVolumeChanged(speakers);
          }
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
