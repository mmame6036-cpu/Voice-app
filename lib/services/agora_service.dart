import 'dart:convert';
import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:http/http.dart' as http;
import 'package:permission_handler/permission_handler.dart';
import 'user_service.dart';

class AgoraService {
  static final AgoraService _instance = AgoraService._internal();
  factory AgoraService() => _instance;
  AgoraService._internal();

  RtcEngine? _engine;
  bool isInitialized = false;
  bool isMuted = false;

  Future<String> _fetchAgoraToken(String channelName, int uid, bool isHost) async {
    try {
      final url = Uri.parse(
        '${UserService.serverUrl}/api/agora/token?channelName=$channelName&uid=$uid&isHost=$isHost',
      );
      final res = await http.get(url).timeout(const Duration(seconds: 8));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        if (data['token'] != null) {
          return data['token'];
        }
      } else {
        print('Failed to load token: ${res.statusCode} - ${res.body}');
      }
    } catch (e) {
      print('Token fetch failed: $e');
    }
    return '';
  }

  Future<void> initAgora({
    required String appId,
    required String channelId,
    required Function(List<AudioVolumeInfo> speakers) onVolumeChanged,
    int uid = 0,
    bool isHost = false,
  }) async {
    await [Permission.microphone].request();

    final token = await _fetchAgoraToken(channelId, uid, isHost);

    _engine = createAgoraRtcEngine();
    await _engine!.initialize(RtcEngineContext(
      appId: appId,
      channelProfile: ChannelProfileType.channelProfileLiveBroadcasting,
    ));

    _engine!.registerEventHandler(
      RtcEngineEventHandler(
        onAudioVolumeIndication: (
          RtcConnection connection,
          List<AudioVolumeInfo> speakers,
          int speakerNumber,
          int totalVolume,
        ) {
          onVolumeChanged(speakers);
        },
        onJoinChannelSuccess: (RtcConnection connection, int elapsed) {
          print('Successfully joined channel: ${connection.channelId}');
        },
        onError: (ErrorCodeType err, String msg) {
          print('Agora error: $err - $msg');
        },
      ),
    );

    await _engine!.enableAudio();
    await _engine!.enableAudioVolumeIndication(
      interval: 200,
      smooth: 3,
      reportVad: true,
    );

    final initialRole = isHost 
        ? ClientRoleType.clientRoleBroadcaster 
        : ClientRoleType.clientRoleAudience;

    await _engine!.setClientRole(role: initialRole);

    await _engine!.joinChannel(
      token: token,
      channelId: channelId,
      uid: uid,
      options: ChannelMediaOptions(
        clientRoleType: initialRole,
        channelProfile: ChannelProfileType.channelProfileLiveBroadcasting,
      ),
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
