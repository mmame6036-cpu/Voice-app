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

  // ከሰርቨር ቶከን ማምጫ ፈንክሽን
  Future<String> _fetchAgoraToken(String channelName) async {
    try {
      final url = Uri.parse('${UserService.serverUrl}/api/get-token?channelName=$channelName');
      final res = await http.get(url).timeout(const Duration(seconds: 5));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        if (data['success'] == true && data['token'] != null) {
          return data['token'];
        }
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
  }) async {
    // 1. የማይክ ፈቃድ መጠየቅ
    await [Permission.microphone].request();

    // 2. ቶከን ከሰርቨር ማምጣት
    final token = await _fetchAgoraToken(channelId);

    // 3. Engine መፍጠርና ማስነሳት
    _engine = createAgoraRtcEngine();
    await _engine!.initialize(RtcEngineContext(
      appId: appId,
      channelProfile: ChannelProfileType.channelProfileLiveBroadcasting,
    ));

    // 4. የድምፅ መለኪያ ክስተት (Volume Event)
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
      ),
    );

    await _engine!.enableAudio();
    await _engine!.enableAudioVolumeIndication(
      interval: 200,
      smooth: 3,
      reportVad: true,
    );

    // ተጠቃሚው መጀመሪያ ሲገባ አድማጭ (Audience) ይሆናል
    await _engine!.setClientRole(role: ClientRoleType.clientRoleAudience);

    // ወደ ቻናል መግባት
    await _engine!.joinChannel(
      token: token,
      channelId: channelId,
      uid: 0,
      options: const ChannelMediaOptions(
        clientRoleType: ClientRoleType.clientRoleAudience,
        channelProfile: ChannelProfileType.channelProfileLiveBroadcasting,
      ),
    );

    isInitialized = true;
  }

  // ወንበር ሲያዝ ማይክ መክፈት
  Future<void> joinMicSeat() async {
    if (!isInitialized || _engine == null) return;
    await _engine!.setClientRole(role: ClientRoleType.clientRoleBroadcaster);
    await _engine!.muteLocalAudioStream(false);
    isMuted = false;
  }

  // ወንበር ሲለቀቅ ማይክ መዝጋት
  Future<void> leaveMicSeat() async {
    if (!isInitialized || _engine == null) return;
    await _engine!.muteLocalAudioStream(true);
    await _engine!.setClientRole(role: ClientRoleType.clientRoleAudience);
    isMuted = true;
  }

  // የማይክ ማብሪያ/ማጥፊያ በተን (Mute / Unmute)
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
