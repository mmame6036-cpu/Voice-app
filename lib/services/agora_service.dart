import 'package:agora_rtc_engine/agora_rtc_engine.dart';

class AgoraService {
  static const String appId = "d00a25d96dfc44cc866cd8f41c496b36";
  RtcEngine? _engine;

  RtcEngine? get engine => _engine;

  Future<void> initEngine({
    required Function(int uid) onUserJoined,
    required Function(int uid) onUserOffline,
    required Function(List<AudioVolumeInfo> speakers) onVolumeChanged,
  }) async {
    _engine = createAgoraRtcEngine();
    await _engine!.initialize(const RtcEngineContext(
      appId: appId,
      channelProfile: ChannelProfileType.channelProfileLiveBroadcasting,
    ));

    _engine!.registerEventHandler(
      RtcEngineEventHandler(
        onJoinChannelSuccess: (RtcConnection connection, int elapsed) {},
        onUserJoined: (RtcConnection connection, int remoteUid, int elapsed) {
          onUserJoined(remoteUid);
        },
        onUserOffline: (RtcConnection connection, int remoteUid, UserOfflineReasonType reason) {
          onUserOffline(remoteUid);
        },
        onAudioVolumeIndication: (RtcConnection connection, List<AudioVolumeInfo> speakers, int totalVolume, int speakerNumber) {
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
  }

  Future<void> joinRoom({
    required String channelId,
    required int uid,
    String? token,
    required bool isSpeaker,
  }) async {
    if (_engine == null) return;

    await _engine!.setClientRole(
      role: isSpeaker
          ? ClientRoleType.clientRoleBroadcaster
          : ClientRoleType.clientRoleAudience,
    );

    await _engine!.joinChannel(
      token: token ?? '',
      channelId: channelId,
      uid: uid,
      options: ChannelMediaOptions(
        clientRoleType: isSpeaker
            ? ClientRoleType.clientRoleBroadcaster
            : ClientRoleType.clientRoleAudience,
        channelProfile: ChannelProfileType.channelProfileLiveBroadcasting,
        publishMicrophoneTrack: isSpeaker,
        autoSubscribeAudio: true,
      ),
    );
  }

  Future<void> switchRole({required bool isSpeaker}) async {
    if (_engine == null) return;

    await _engine!.setClientRole(
      role: isSpeaker
          ? ClientRoleType.clientRoleBroadcaster
          : ClientRoleType.clientRoleAudience,
    );

    await _engine!.updateChannelMediaOptions(
      ChannelMediaOptions(
        publishMicrophoneTrack: isSpeaker,
        clientRoleType: isSpeaker
            ? ClientRoleType.clientRoleBroadcaster
            : ClientRoleType.clientRoleAudience,
      ),
    );
  }

  Future<void> setMicrophoneMute(bool isMuted) async {
    if (_engine == null) return;
    await _engine!.muteLocalAudioStream(isMuted);
  }

  Future<void> leaveRoom() async {
    if (_engine == null) return;
    await _engine!.leaveChannel();
    await _engine!.release();
    _engine = null;
  }
}
