import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:http/http.dart' as http;

class AgoraService extends ChangeNotifier {
  static final AgoraService _instance = AgoraService._internal();
  factory AgoraService() => _instance;
  AgoraService._internal();

  static const String appId = "d00a25d96dfc44cc866cd8f41c496b36";
  static const String tokenServerBaseUrl = "https://nile-token-server.onrender.com";

  RtcEngine? _engine;
  RtcEngine? get engine => _engine;

  bool _isInRoom = false;
  bool _isChannelJoined = false;
  bool _isMinimized = false;
  bool _isMicMuted = false;
  bool _currentIsSpeaker = false;
  String _currentRoomTitle = "";
  String _currentChannelId = "";
  int _currentUid = 0;
  int _currentSeatCount = 30;
  String _lastError = "";

  bool get isInRoom => _isInRoom;
  bool get isChannelJoined => _isChannelJoined;
  bool get isMinimized => _isMinimized;
  bool get isMicMuted => _isMicMuted;
  String get currentRoomTitle => _currentRoomTitle;
  String get currentChannelId => _currentChannelId;
  int get currentSeatCount => _currentSeatCount;
  String get lastError => _lastError;

  Function(int uid)? onUserJoinedCallback;
  Function(int uid)? onUserOfflineCallback;
  Function(List<AudioVolumeInfo> speakers)? onVolumeChangedCallback;
  Function(String errorMessage)? onErrorCallback;

  Future<String> _fetchRtcToken({
    required String channelId,
    required int uid,
    required bool isSpeaker,
  }) async {
    final String roleParam = isSpeaker ? "publisher" : "subscriber";
    final uri = Uri.parse(
      "$tokenServerBaseUrl/rtcToken?channelName=$channelId&uid=$uid&role=$roleParam",
    );

    for (int attempt = 0; attempt < 2; attempt++) {
      try {
        final response = await http.get(uri).timeout(const Duration(seconds: 45));
        if (response.statusCode == 200) {
          final decoded = jsonDecode(response.body);
          if (decoded is Map && decoded['token'] != null) {
            final t = decoded['token'].toString().trim();
            if (t.isNotEmpty) return t;
          }
        }
      } catch (e) {
        _lastError = "Token fetch attempt ${attempt + 1} failed: $e";
        debugPrint(_lastError);
      }
    }
    return "";
  }

  Future<void> initEngine({
    required Function(int uid) onUserJoined,
    required Function(int uid) onUserOffline,
    required Function(List<AudioVolumeInfo> speakers) onVolumeChanged,
    Function(String errorMessage)? onError,
  }) async {
    onUserJoinedCallback = onUserJoined;
    onUserOfflineCallback = onUserOffline;
    onVolumeChangedCallback = onVolumeChanged;
    if (onError != null) onErrorCallback = onError;

    if (_engine != null) return;

    await Permission.microphone.request();

    _engine = createAgoraRtcEngine();

    await _engine!.initialize(const RtcEngineContext(
      appId: appId,
      channelProfile: ChannelProfileType.channelProfileLiveBroadcasting,
    ));

    _engine!.registerEventHandler(
      RtcEngineEventHandler(
        onJoinChannelSuccess: (RtcConnection connection, int elapsed) {
          _isChannelJoined = true;
          debugPrint("Joined Agora channel: ${connection.channelId}");
          _engine?.setEnableSpeakerphone(true);
          notifyListeners();
        },
        onLeaveChannel: (RtcConnection connection, RtcStats stats) {
          _isChannelJoined = false;
          notifyListeners();
        },
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
        onTokenPrivilegeWillExpire: (RtcConnection connection, String token) async {
          if (_currentChannelId.isNotEmpty) {
            final newToken = await _fetchRtcToken(
              channelId: _currentChannelId,
              uid: _currentUid,
              isSpeaker: _currentIsSpeaker,
            );
            if (newToken.isNotEmpty) {
              await _engine?.renewToken(newToken);
            }
          }
        },
        onError: (ErrorCodeType err, String msg) {
          _lastError = "Agora error $err: $msg";
          debugPrint(_lastError);
          onErrorCallback?.call(_lastError);
        },
      ),
    );

    await _engine!.setAudioProfile(
      profile: AudioProfileType.audioProfileDefault,
      scenario: AudioScenarioType.audioScenarioChatroom,
    );

    await _engine!.enableAudioVolumeIndication(
      interval: 250,
      smooth: 3,
      reportVad: true,
    );

    await _engine!.enableAudio();
    await _engine!.setDefaultAudioRouteToSpeakerphone(true);
    await _engine!.adjustRecordingSignalVolume(100);
    await _engine!.adjustPlaybackSignalVolume(100);
  }

  Future<void> joinRoom({
    required String channelId,
    required int uid,
    String? token,
    required bool isSpeaker,
    String roomTitle = "VIP Voice Room",
    int seatCount = 30,
  }) async {
    if (_engine == null) return;

    if (_isInRoom && _isChannelJoined && _currentChannelId == channelId) {
      _isMinimized = false;
      notifyListeners();
      return;
    }

    if (isSpeaker) {
      await Permission.microphone.request();
    }

    _currentChannelId = channelId;
    _currentUid = uid;
    _currentRoomTitle = roomTitle;
    _currentSeatCount = seatCount;
    _currentIsSpeaker = isSpeaker;
    _isInRoom = true;
    _isMinimized = false;
    _isMicMuted = !isSpeaker;
    notifyListeners();

    String activeToken = (token ?? "").trim();
    if (activeToken.isEmpty) {
      activeToken = await _fetchRtcToken(
        channelId: channelId,
        uid: uid,
        isSpeaker: isSpeaker,
      );
    }

    final ClientRoleType targetRole = isSpeaker
        ? ClientRoleType.clientRoleBroadcaster
        : ClientRoleType.clientRoleAudience;

    await _engine!.setClientRole(role: targetRole);
    await _engine!.enableLocalAudio(isSpeaker);

    await _engine!.joinChannel(
      token: activeToken,
      channelId: channelId,
      uid: uid,
      options: ChannelMediaOptions(
        clientRoleType: targetRole,
        channelProfile: ChannelProfileType.channelProfileLiveBroadcasting,
        publishMicrophoneTrack: isSpeaker,
        autoSubscribeAudio: true,
      ),
    );

    await _engine!.setDefaultAudioRouteToSpeakerphone(true);
    await _engine!.setEnableSpeakerphone(true);
    await _engine!.muteLocalAudioStream(!isSpeaker);
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
    _currentIsSpeaker = isSpeaker;

    if (isSpeaker) {
      final status = await Permission.microphone.request();
      if (!status.isGranted) {
        _lastError = "Microphone permission denied";
        onErrorCallback?.call(_lastError);
        return;
      }
    }

    // If initial channel join did not succeed yet, join now
    if (!_isChannelJoined && _currentChannelId.isNotEmpty) {
      await joinRoom(
        channelId: _currentChannelId,
        uid: _currentUid,
        isSpeaker: isSpeaker,
        roomTitle: _currentRoomTitle,
        seatCount: _currentSeatCount,
      );
      return;
    }

if (_currentChannelId.isNotEmpty) {
      final refreshedToken = await _fetchRtcToken(
        channelId: _currentChannelId,
        uid: _currentUid,
        isSpeaker: isSpeaker,
      );
      if (refreshedToken.isNotEmpty) {
        await _engine!.renewToken(refreshedToken);
      }
    }

    final ClientRoleType targetRole = isSpeaker
        ? ClientRoleType.clientRoleBroadcaster
        : ClientRoleType.clientRoleAudience;

    await _engine!.setClientRole(role: targetRole);
    await _engine!.enableLocalAudio(isSpeaker);

    await _engine!.updateChannelMediaOptions(
      ChannelMediaOptions(
        publishMicrophoneTrack: isSpeaker,
        autoSubscribeAudio: true,
        clientRoleType: targetRole,
      ),
    );

    await _engine!.setDefaultAudioRouteToSpeakerphone(true);
    await _engine!.setEnableSpeakerphone(true);
    if (isSpeaker) {
      _isMicMuted = false;
      await _engine!.muteLocalAudioStream(false);
    } else {
      _isMicMuted = true;
      await _engine!.muteLocalAudioStream(true);
    }
    notifyListeners();
  }

  Future<void> setMicrophoneMute(bool isMuted) async {
    _isMicMuted = isMuted;
    notifyListeners();
    if (_engine == null) return;
    if (!isMuted) {
      await _engine!.enableLocalAudio(true);
    }
    await _engine!.muteLocalAudioStream(isMuted);
  }

  Future<void> leaveRoom() async {
    _isInRoom = false;
    _isChannelJoined = false;
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
