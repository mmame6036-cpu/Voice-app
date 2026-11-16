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
  bool _isJoining = false;
  bool _isMinimized = false;
  bool _isMicMuted = true;
  bool _desiredSpeaker = false;

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
  Function(List speakers)? onVolumeChangedCallback;
  Function(String errorMessage)? onErrorCallback;

  void _reportError(String msg) {
    _lastError = msg;
    debugPrint(msg);
    onErrorCallback?.call(msg);
  }

  Future<String> _fetchPublisherToken({
    required String channelId,
    required int uid,
  }) async {
    final uri = Uri.parse(
      "$tokenServerBaseUrl/rtcToken?channelName=$channelId&uid=$uid&role=publisher",
    );

    for (int attempt = 0; attempt < 2; attempt++) {
      try {
        final response = await http.get(uri).timeout(const Duration(seconds: 45));
        if (response.statusCode == 200) {
          final decoded = jsonDecode(response.body);
          if (decoded is Map) {
            final raw = decoded['token'] ?? decoded['rtcToken'] ?? "";
            final t = raw.toString().trim();
            if (t.isNotEmpty) return t;
          }
        } else {
          _reportError("Token server HTTP ${response.statusCode}");
        }
      } catch (e) {
        _reportError("Token fetch error: $e");
      }
    }
    return "";
  }

  Future<void> _ensureEngineInitialized() async {
    if (_engine != null) return;

    await Permission.microphone.request();

    _engine = createAgoraRtcEngine();

    await _engine!.initialize(const RtcEngineContext(
      appId: appId,
      channelProfile: ChannelProfileType.channelProfileLiveBroadcasting,
    ));

    _engine!.registerEventHandler(
      RtcEngineEventHandler(
        onJoinChannelSuccess: (RtcConnection connection, int elapsed) async {
          _isChannelJoined = true;
          await _engine?.setDefaultAudioRouteToSpeakerphone(true);
          await _engine?.setEnableSpeakerphone(true);
          await _applyRoleAndAudio(_desiredSpeaker);
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
          List speakers,
          int totalVolume,
          int speakerNumber,
        ) {
          onVolumeChangedCallback?.call(speakers.cast<AudioVolumeInfo>());
        },
        onError: (ErrorCodeType err, String msg) {
          _reportError("Agora error $err: $msg");
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
    await _engine!.enableLocalAudio(true);
    await _engine!.setDefaultAudioRouteToSpeakerphone(true);
    await _engine!.adjustRecordingSignalVolume(150);
    await _engine!.adjustPlaybackSignalVolume(150);
  }

  Future<void> initEngine({
    required Function(int uid) onUserJoined,
    required Function(int uid) onUserOffline,
    required Function(List speakers) onVolumeChanged,
    Function(String errorMessage)? onError,
  }) async {
    onUserJoinedCallback = onUserJoined;
    onUserOfflineCallback = onUserOffline;
    onVolumeChangedCallback = onVolumeChanged;
    if (onError != null) onErrorCallback = onError;

    await _ensureEngineInitialized();
  }

  Future<void> _applyRoleAndAudio(bool isSpeaker) async {
    if (_engine == null) return;

    final ClientRoleType targetRole = isSpeaker
        ? ClientRoleType.clientRoleBroadcaster
        : ClientRoleType.clientRoleAudience;

    await _engine!.setClientRole(role: targetRole);

    if (isSpeaker) {
      await _engine!.enableLocalAudio(true);
    }

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
  }

  Future<void> joinRoom({
    required String channelId,
    required int uid,
    String? token,
    required bool isSpeaker,
    String roomTitle = "VIP Voice Room",
    int seatCount = 30,
  }) async {
    await _ensureEngineInitialized();
    if (_engine == null) return;

    _desiredSpeaker = isSpeaker;
    _isMicMuted = !isSpeaker;

    if (_isInRoom && _isChannelJoined && _currentChannelId == channelId) {
      _isMinimized = false;
      await _applyRoleAndAudio(_desiredSpeaker);
      notifyListeners();
      return;
    }

    if (_isJoining && _currentChannelId == channelId) {
      _isMinimized = false;
      notifyListeners();
      return;
    }

    _isJoining = true;
    _currentChannelId = channelId;
    _currentUid = uid;
    _currentRoomTitle = roomTitle;
    _currentSeatCount = seatCount;
    _isInRoom = true;
    _isMinimized = false;
    notifyListeners();

    try {
      await Permission.microphone.request();

      if (_isChannelJoined) {
        await _engine!.leaveChannel();
        _isChannelJoined = false;
      }

      String activeToken = (token ?? "").trim();
      if (activeToken.isEmpty) {
        activeToken = await _fetchPublisherToken(
          channelId: channelId,
          uid: uid,
        );
      }

      if (activeToken.isEmpty) {
        _reportError("Token is empty. Check Render server.");
      }

      final bool finalSpeaker = _desiredSpeaker;
      final ClientRoleType targetRole = finalSpeaker
          ? ClientRoleType.clientRoleBroadcaster
          : ClientRoleType.clientRoleAudience;

      await _engine!.setClientRole(role: targetRole);
      if (finalSpeaker) {
        await _engine!.enableLocalAudio(true);
      }

      await _engine!.joinChannel(
        token: activeToken,
        channelId: channelId,
        uid: uid,
        options: ChannelMediaOptions(
          clientRoleType: targetRole,
          channelProfile: ChannelProfileType.channelProfileLiveBroadcasting,
          publishMicrophoneTrack: finalSpeaker,
          autoSubscribeAudio: true,
        ),
      );

await _engine!.setDefaultAudioRouteToSpeakerphone(true);
      await _engine!.setEnableSpeakerphone(true);
      await _engine!.muteLocalAudioStream(!finalSpeaker);
    } catch (e) {
      _reportError("Join room failed: $e");
    } finally {
      _isJoining = false;
    }
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
    _desiredSpeaker = isSpeaker;
    _isMicMuted = !isSpeaker;
    notifyListeners();

    if (isSpeaker) {
      final status = await Permission.microphone.request();
      if (!status.isGranted) {
        _reportError("Microphone permission denied");
        return;
      }
    }

    if (_isJoining) {
      return;
    }

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

    await _applyRoleAndAudio(isSpeaker);
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
    _isJoining = false;
    _isMinimized = false;
    _desiredSpeaker = false;
    _currentChannelId = "";
    _currentRoomTitle = "";
    notifyListeners();

    if (_engine == null) return;
    await _engine!.leaveChannel();
    await _engine!.release();
    _engine = null;
  }
}
