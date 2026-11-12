import 'package:flutter/foundation.dart';
import 'package:agora_rtc_engine/agora_rtc_engine.dart';

class AgoraService extends ChangeNotifier {
  static final AgoraService _instance = AgoraService._internal();
  factory AgoraService() => _instance;
  AgoraService._internal();

  static const String appId = "d00a25d96dfc44cc866cd8f41c496b36";
  RtcEngine? _engine;

  RtcEngine? get engine => _engine;

  bool _isInRoom = false;
  bool _isMinimized = false;
  bool _isMicMuted = false;
  String _currentRoomTitle = "";
  String _currentChannelId = "";
  int _currentSeatCount = 12;

  bool get isInRoom => _isInRoom;
  bool get isMinimized => _isMinimized;
  bool get isMicMuted => _isMicMuted;
  String get currentRoomTitle => _currentRoomTitle;
  String get currentChannelId => _currentChannelId;
  int get currentSeatCount => _currentSeatCount;

  Function(int uid)? onUserJoinedCallback;
  Function(int uid)? onUserOfflineCallback;
  Function(List<AudioVolumeInfo> speakers)? onVolumeChangedCallback;

  Future<void> initEngine({
    required Function(int uid) onUserJoined,
    required Function(int uid) onUserOffline,
    required Function(List<AudioVolumeInfo> speakers) onVolumeChanged,
  }) async {
    onUserJoinedCallback = onUserJoined;
    onUserOfflineCallback = onUserOffline;
    onVolumeChangedCallback = onVolumeChanged;

    if (_engine != null) return;

    _engine = createAgoraRtcEngine();

    await _engine!.initialize(const RtcEngineContext(
      appId: appId,
      channelProfile: ChannelProfileType.channelProfileLiveBroadcasting,
    ));

    _engine!.registerEventHandler(
      RtcEngineEventHandler(
        onJoinChannelSuccess: (RtcConnection connection, int elapsed) {},
        onUserJoined: (RtcConnection connection, int remoteUid, int elapsed) {
          onUserJoinedCallback?.call(remoteUid);
        },
        onUserOffline: (RtcConnection connection, int remoteUid, UserOfflineReasonType reason) {
          onUserOfflineCallback?.call(remoteUid);
        },
        onAudioVolumeIndication: (
          RtcConnection connection,
          List<AudioVolumeInfo> speakers,
          int totalVolume,
          int speakerNumber,
        ) {
          onVolumeChangedCallback?.call(speakers);
        },
      ),
    );

    await _engine!.setAudioProfile(
      profile: AudioProfileType.audioProfileMusicStandard,
      scenario: AudioScenarioType.audioScenarioGameStreaming,
    );

    await _engine!.enableAudioVolumeIndication(
      interval: 200,
      smooth: 3,
      reportVad: true,
    );

    await _engine!.setParameters('{"che.audio.opensles":true}');
    await _engine!.setParameters('{"che.audio.aec.enable":true}');
    await _engine!.setParameters('{"che.audio.ans.enable":true}');
    await _engine!.setParameters('{"che.audio.agc.enable":true}');

    await _engine!.enableAudio();
  }

  Future<void> joinRoom({
    required String channelId,
    required int uid,
    String? token,
    required bool isSpeaker,
    String roomTitle = "VIP Voice Room",
    int seatCount = 12,
  }) async {
    if (_engine == null) return;

    if (_isInRoom && _currentChannelId == channelId) {
      _isMinimized = false;
      notifyListeners();
      return;
    }

    _currentChannelId = channelId;
    _currentRoomTitle = roomTitle;
    _currentSeatCount = seatCount;
    _isInRoom = true;
    _isMinimized = false;
    notifyListeners();

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

void minimizeRoom() {
    if (_isInRoom) {
      _isMinimized = true;
      notifyListeners();
    }
  }

  void restoreRoom() {
    if (_isInRoom) {
      _isMinimized = false;
      notifyListeners();
    }
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
    _isMicMuted = isMuted;
    notifyListeners();
    if (_engine == null) return;
    await _engine!.muteLocalAudioStream(isMuted);
  }

  Future<void> leaveRoom() async {
    _isInRoom = false;
    _isMinimized = false;
    _currentChannelId = "";
    _currentRoomTitle = "";
    notifyListeners();

    if (_engine == null) return;
    await _engine!.leaveChannel();
    await _engine!.release();
    _engine = null;
  }
}
