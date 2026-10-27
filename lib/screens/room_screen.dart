import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:agora_rtc_engine/agora_rtc_engine.dart';

const String agoraAppId = "21091aff01114a66b580ce15b0f1b642";
const String agoraToken = "";
const String channelName = "habesha_vip_room";

class VoicePartyRoomScreen extends StatefulWidget {
  final String roomTitle;
  final int initialCoins;
  final Function(int) onCoinUpdate;
  final int seatCount; // 8, 12, 16, 20, 25, ወይም 30

  const VoicePartyRoomScreen({
    super.key,
    required this.roomTitle,
    required this.initialCoins,
    required this.onCoinUpdate,
    this.seatCount = 12, // መደበኛ የወንበር ብዛት
  });

  @override
  State<VoicePartyRoomScreen> createState() => _VoicePartyRoomScreenState();
}

class _VoicePartyRoomScreenState extends State<VoicePartyRoomScreen> {
  late int _currentCoins;
  late int _activeSeatCount;
  bool _isMicMuted = false;
  int? _mySeatIndex;
  late List<String?> _seats;
  final List<String> _chatMessages = ["🎧 Tis Abay Live Room Active."];
  final TextEditingController _msgController = TextEditingController();

  RtcEngine? _engine;
  bool _isEngineReady = false;

  static const String abayFallsUrl =
      "https://upload.wikimedia.org/wikipedia/commons/thumb/0/05/Blue_Nile_Falls_Ethiopia.jpg/1024px-Blue_Nile_Falls_Ethiopia.jpg";

  @override
  void initState() {
    super.initState();
    _currentCoins = widget.initialCoins;
    _activeSeatCount = widget.seatCount;
    _seats = List.filled(_activeSeatCount, null);
    _initVoiceEngine();
  }

  Future<void> _initVoiceEngine() async {
    await [Permission.microphone].request();

    if (agoraAppId.length > 5) {
      try {
        _engine = createAgoraRtcEngine();
        await _engine!.initialize(const RtcEngineContext(
          appId: agoraAppId,
          channelProfile: ChannelProfileType.channelProfileLiveBroadcasting,
        ));

        _engine!.registerEventHandler(
          RtcEngineEventHandler(
            onJoinChannelSuccess: (RtcConnection connection, int elapsed) {
              setState(() {
                _chatMessages.add("Connected to Voice Channel.");
              });
            },
          ),
        );

        await _engine!.setClientRole(role: ClientRoleType.clientRoleAudience);
        await _engine!.enableAudio();
        await _engine!.enableSpatialAudio(true);
        await _engine!.joinChannel(
          token: agoraToken,
          channelId: channelName,
          uid: 0,
          options: const ChannelMediaOptions(
            clientRoleType: ClientRoleType.clientRoleAudience,
            autoSubscribeAudio: true,
          ),
        );

        setState(() {
          _isEngineReady = true;
        });
      } catch (e) {
        debugPrint("Voice Engine Error: $e");
      }
    }
  }

  // የወንበር ብዛት መቀየሪያ (8, 12, 16, 20, 25, 30)
  void _changeSeatLayout(int newCount) {
    setState(() {
      _activeSeatCount = newCount;
      _seats = List.filled(_activeSeatCount, null);
      _mySeatIndex = null;
      _updateBroadcasterRole(false);
    });
    Navigator.pop(context);
  }

  void _openSeatLayoutPicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1E1B38),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              "የወንበሮች ብዛት ምረጥ (Seats)",
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 12,
              runSpacing: 12,

children: [8, 12, 16, 20, 25, 30].map((count) {
                final isSelected = _activeSeatCount == count;
                return ChoiceChip(
                  label: Text("$count ወንበሮች"),
                  selected: isSelected,
                  selectedColor: const Color(0xFFFFD700),
                  backgroundColor: const Color(0xFF2B2B4A),
                  labelStyle: TextStyle(
                    color: isSelected ? Colors.black : Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                  onSelected: (_) => _changeSeatLayout(count),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Future<void> _handleSeatTap(int index) async {
    setState(() {
      if (_seats[index] == null) {
        if (_mySeatIndex != null) _seats[_mySeatIndex!] = null;
        _seats[index] = "Kedir";
        _mySeatIndex = index;
        _updateBroadcasterRole(true);
      } else if (_mySeatIndex == index) {
        _seats[index] = null;
        _mySeatIndex = null;
        _updateBroadcasterRole(false);
      }
    });
  }

  Future<void> _updateBroadcasterRole(bool isSpeaker) async {
    if (_engine != null && _isEngineReady) {
      if (isSpeaker) {
        await _engine!.setClientRole(role: ClientRoleType.clientRoleBroadcaster);
        await _engine!.muteLocalAudioStream(_isMicMuted);
      } else {
        await _engine!.setClientRole(role: ClientRoleType.clientRoleAudience);
      }
    }
  }

  Future<void> _toggleMic() async {
    setState(() {
      _isMicMuted = !_isMicMuted;
    });
    if (_engine != null && _isEngineReady && _mySeatIndex != null) {
      await _engine!.muteLocalAudioStream(_isMicMuted);
    }
  }

  void _sendGift(String giftName, int cost) {
    if (_currentCoins >= cost) {
      setState(() {
        _currentCoins -= cost;
        _chatMessages.add("🎁 Kedir sent a $giftName!");
      });
      widget.onCoinUpdate(_currentCoins);
      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Insufficient coins!")),
      );
    }
  }

  void _openGiftSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1E1B38),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text("Send 3D Gift", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _giftItem("Rose", "🌹", 10),
                _giftItem("Crown", "👑", 100),
                _giftItem("Sports Car", "🏎️", 500),
                _giftItem("Spaceship", "🚀", 1000),
              ],
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _giftItem(String name, String icon, int cost) {
    return GestureDetector(
      onTap: () => _sendGift(name, cost),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white10,
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0xFFFFD700), width: 1),
            ),
            child: Text(icon, style: const TextStyle(fontSize: 26)),
          ),
          const SizedBox(height: 6),
          Text(name, style: const TextStyle(color: Colors.white, fontSize: 12)),
          Text("$cost 🪙", style: const TextStyle(color: Color(0xFFFFD700), fontSize: 11)),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _engine?.leaveChannel();
    _engine?.release();
    _msgController.dispose();
    super.dispose();
  }

@override
  Widget build(BuildContext context) {
    // እንደ ወንበሩ ብዛት ስፋቱ የሚስተካከል (8 ከሆነ 4 ረድፍ፣ ከዛ በላይ ከሆነ 5 ረድፍ)
    final int crossAxisCount = _activeSeatCount <= 8 ? 4 : 5;
    final double avatarRadius = _activeSeatCount > 16 ? 18 : 22;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          "${widget.roomTitle} (${_activeSeatCount} Seats)",
          style: const TextStyle(fontSize: 15, color: Colors.white, fontWeight: FontWeight.bold),
        ),
        actions: [
          // የወንበሮችን ብዛት መምረጫ አዶ
          IconButton(
            icon: const Icon(Icons.event_seat, color: Color(0xFFFFD700)),
            tooltip: "Change Seats Layout",
            onPressed: _openSeatLayoutPicker,
          ),
          IconButton(
            icon: const Icon(Icons.exit_to_app, color: Colors.redAccent),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: NetworkImage(abayFallsUrl),
            fit: BoxFit.cover,
            colorFilter: ColorFilter.mode(Color(0x77000000), BlendMode.darken
