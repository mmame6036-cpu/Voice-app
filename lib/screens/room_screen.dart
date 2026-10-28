import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:svgaplayer_flutter/svgaplayer_flutter.dart';
import 'wallet_screen.dart';
import '../widgets/lucky_wheel_dialog.dart';

const String agoraAppId = "21091aff01114a66b580ce15b0f1b642";
const String agoraToken = "";
const String channelName = "habesha_vip_room";

class GiftModel {
  final String id;
  final String name;
  final String icon;
  final int cost;
  final String svgaUrl;

  const GiftModel({
    required this.id,
    required this.name,
    required this.icon,
    this.cost = 0,
    required this.svgaUrl,
  });
}

const List<GiftModel> availableGifts = [
  GiftModel(
    id: "1",
    name: "Rocket",
    icon: "🚀",
    cost: 0,
    svgaUrl: "https://raw.githubusercontent.com/svga/SVGA-Samples/master/rocket.svga",
  ),
  GiftModel(
    id: "2",
    name: "Sports Car",
    icon: "🏎️",
    cost: 0,
    svgaUrl: "https://raw.githubusercontent.com/svga/SVGA-Samples/master/posche.svga",
  ),
  GiftModel(
    id: "3",
    name: "Crown Rose",
    icon: "🌹",
    cost: 0,
    svgaUrl: "https://raw.githubusercontent.com/svga/SVGA-Samples/master/rose.svga",
  ),
  GiftModel(
    id: "4",
    name: "VIP Angel",
    icon: "💎",
    cost: 0,
    svgaUrl: "https://raw.githubusercontent.com/svga/SVGA-Samples/master/angel.svga",
  ),
];

class VoicePartyRoomScreen extends StatefulWidget {
  final String roomTitle;
  final int initialCoins;
  final Function(int) onCoinUpdate;
  final int seatCount;

  const VoicePartyRoomScreen({
    super.key,
    required this.roomTitle,
    required this.initialCoins,
    required this.onCoinUpdate,
    this.seatCount = 12,
  });

  @override
  State<VoicePartyRoomScreen> createState() => _VoicePartyRoomScreenState();
}

class _VoicePartyRoomScreenState extends State<VoicePartyRoomScreen>
    with SingleTickerProviderStateMixin {
  late int _currentCoins;
  late int _activeSeatCount;
  bool _isMicMuted = false;
  int? _mySeatIndex;
  late List<String?> _seats;
  final List<String> _chatMessages = ["3D VIP Live Room Active."];
  final TextEditingController _msgController = TextEditingController();

  RtcEngine? _engine;
  bool _isEngineReady = false;

  SVGAAnimationController? _svgaController;
  bool _isPlayingAnimation = false;
  String _currentPlayingGift = "";

  static const String royalBackgroundUrl =
      "https://images.unsplash.com/photo-1518709268805-4e9042af9f23?q=80&w=1000&auto=format&fit=crop";

  @override
  void initState() {
    super.initState();
    _currentCoins = widget.initialCoins;
    _activeSeatCount = widget.seatCount;
    _seats = List.filled(_activeSeatCount, null);
    _svgaController = SVGAAnimationController(vsync: this);
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
          audioScenario: AudioScenarioType.audioScenarioGameStreaming,
        ));

        await _engine!.enableAudioVolumeIndication(
          interval: 250,
          smooth: 3,
          reportVad: true,
        );

        _engine!.registerEventHandler(
          RtcEngineEventHandler(
            onJoinChannelSuccess: (RtcConnection connection, int elapsed) {
              setState(() {
                _chatMessages.add("Connected to voice network");
              });
            },
            onAudioVolumeIndication: (
              RtcConnection connection,
              List<AudioVolumeInfo> speakers,
              int totalVolume,
              int speakerNumber,
            ) {},
          ),
        );

await _engine!.enableAudio();
        await _engine!.enableSpatialAudio(true);
        await _engine!.setAudioProfile(
          profile: AudioProfileType.audioProfileMusicStandard,
          scenario: AudioScenarioType.audioScenarioGameStreaming,
        );

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
      backgroundColor: const Color(0xFF141226),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              "Select Seats Layout",
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [8, 12, 16, 20, 25, 30].map((count) {
                final isSelected = _activeSeatCount == count;
                return ChoiceChip(
                  label: Text("$count Seats"),
                  selected: isSelected,
                  selectedColor: const Color(0xFFFFD700),
                  backgroundColor: const Color(0xFF221F3A),
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

  Future<void> _playGiftAnimation(GiftModel gift) async {
    if (_svgaController == null) return;
    try {
      final parser = SVGAParser.shared;
      final videoItem = await parser.decodeFromURL(gift.svgaUrl);
      setState(() {
        _isPlayingAnimation = true;
        _currentPlayingGift = gift.name;
      });
      _svgaController!.videoItem = videoItem;

_svgaController!.reset();
      await _svgaController!.forward();
      if (mounted) {
        setState(() {
          _isPlayingAnimation = false;
        });
      }
    } catch (e) {
      debugPrint("SVGA Play Error: $e");
      if (mounted) {
        setState(() {
          _isPlayingAnimation = false;
        });
      }
    }
  }

  void _sendGift({required GiftModel gift, required String target}) {
    setState(() {
      _chatMessages.add("Gift sent: ${gift.name} to $target");
    });
    Navigator.pop(context);
    _playGiftAnimation(gift);
  }

  void _openGiftSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF141226),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        GiftModel selectedGift = availableGifts[0];
        String selectedTarget = "All Seats";

        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Container(
              height: 480,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Column(
                children: [
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.white24,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _targetChip(
                          title: "All Seats",
                          isSelected: selectedTarget == "All Seats",
                          onTap: () => setSheetState(() => selectedTarget = "All Seats"),
                        ),
                        ...List.generate(_activeSeatCount, (i) {
                          final seatLabel = "Seat ${i + 1}";
                          return _targetChip(
                            title: seatLabel,
                            isSelected: selectedTarget == seatLabel,
                            onTap: () => setSheetState(() => selectedTarget = seatLabel),
                          );
                        }),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  Expanded(
                    child: GridView.builder(
                      itemCount: availableGifts.length,
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 4,
                        mainAxisSpacing: 12,
                        crossAxisSpacing: 12,
                        childAspectRatio: 0.78,
                      ),
                      itemBuilder: (context, index) {
                        final gift = availableGifts[index];
                        final isSelected = selectedGift.id == gift.id;

                        return GestureDetector(
                          onTap: () {
                            setSheetState(() {
                              selectedGift = gift;
                            });
                          },
                          child: Container(
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? const Color(0xFF2A244D)
                                  : const Color(0xFF1E1B38),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(

color: isSelected
                                    ? const Color(0xFFFFD700)
                                    : Colors.white10,
                                width: isSelected ? 2 : 1,
                              ),
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(gift.icon, style: const TextStyle(fontSize: 32)),
                                const SizedBox(height: 6),
                                Text(
                                  gift.name,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                  ),
                                  textAlign: TextAlign.center,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Icon(Icons.monetization_on,
                                        size: 12, color: Color(0xFFFFD700)),
                                    const SizedBox(width: 2),
                                    Text(
                                      "${gift.cost}",
                                      style: const TextStyle(
                                        color: Color(0xFFFFD700),
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.monetization_on,
                                color: Color(0xFFFFD700), size: 18),
                            const SizedBox(width: 4),
                            Text(
                              "$_currentCoins",
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                              ),
                            ),
                            const SizedBox(width: 8),
                            GestureDetector(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => WalletScreen(
                                      currentCoins: _currentCoins,
                                      onCoinsRecharged: (newCoins) {
                                        setState(() {
                                          _currentCoins = newCoins;
                                        });
                                        setSheetState(() {});

widget.onCoinUpdate(newCoins);
                                      },
                                    ),
                                  ),
                                );
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF2B224F),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                      color: const Color(0xFFFFD700), width: 0.8),
                                ),
                                child: const Row(
                                  children: [
                                    Text(
                                      "Recharge",
                                      style: TextStyle(
                                        color: Color(0xFFFFD700),
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    Icon(Icons.chevron_right,
                                        size: 14, color: Color(0xFFFFD700)),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFFFD700),
                            foregroundColor: Colors.black,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 36, vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(24),
                            ),
                          ),
                          onPressed: () => _sendGift(
                            gift: selectedGift,
                            target: selectedTarget,
                          ),
                          child: const Text(
                            "Send",
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _targetChip({
    required String title,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFFFD700) : const Color(0xFF221F3A),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? const Color(0xFFFFD700) : Colors.white12,
          ),
        ),
        child: Text(
          title,
          style: TextStyle(
            color: isSelected ? Colors.black : Colors.white70,
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _engine?.leaveChannel();
    _engine?.release();
    _svgaController?.dispose();
    _msgController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final int crossAxisCount = _activeSeatCount <= 8 ? 4 : 5;
    final double avatarSize = _activeSeatCount > 16 ? 48 : 58;

return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          "${widget.roomTitle} ($_activeSeatCount Seats)",
          style: const TextStyle(fontSize: 15, color: Colors.white, fontWeight: FontWeight.bold),
        ),
        actions: [
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
      body: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              image: DecorationImage(
                image: const NetworkImage(royalBackgroundUrl),
                fit: BoxFit.cover,
                colorFilter: ColorFilter.mode(
                  Colors.black.withOpacity(0.7),
                  BlendMode.darken,
                ),
              ),
            ),
            child: Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
                    child: GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _activeSeatCount,
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: crossAxisCount,
                        crossAxisSpacing: 10,
                        mainAxisSpacing: 12,
                        childAspectRatio: 0.75,
                      ),
                      itemBuilder: (context, index) {
                        final isTaken = _seats[index] != null;
                        final isMeSpeaking = _mySeatIndex == index && !_isMicMuted;
                        final seatTitle = index == 0 ? "Host" : "No.${index + 1}";

                        return GestureDetector(
                          onTap: () => _handleSeatTap(index),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                width: avatarSize,
                                height: avatarSize,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  gradient: RadialGradient(
                                    colors: [
                                      const Color(0xFFFFE082).withOpacity(0.3),
                                      const Color(0xFF141226).withOpacity(0.85),
                                    ],
                                  ),
                                  border: Border.all(
                                    color: isMeSpeaking
                                        ? Colors.greenAccent
                                        : const Color(0xFFFFD700).withOpacity(0.85),
                                    width: isMeSpeaking ? 2.5 : 1.8,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: isMeSpeaking
                                          ? Colors.greenAccent.withOpacity(0.5)
                                          : const Color(0xFFFFD700).withOpacity(0.35),
                                      blurRadius: 10,
                                      spreadRadius: 1,
                                    ),

],
                                ),
                                child: Center(
                                  child: isTaken
                                      ? const Icon(
                                          Icons.person,
                                          color: Color(0xFFFFD700),
                                          size: 26,
                                        )
                                      : const Icon(
                                          Icons.mic,
                                          color: Color(0xFFFFD700),
                                          size: 24,
                                        ),
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                isTaken ? _seats[index]! : seatTitle,
                                style: TextStyle(
                                  color: isTaken ? const Color(0xFFFFD700) : Colors.white70,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 2),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: const [
                                  Icon(Icons.favorite, color: Colors.pinkAccent, size: 10),
                                  SizedBox(width: 2),
                                  Text(
                                    "0",
                                    style: TextStyle(color: Colors.white60, fontSize: 10),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ),
                Container(
                  height: 120,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: ListView.builder(
                    itemCount: _chatMessages.length,
                    itemBuilder: (context, index) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 2.0),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: const Color(0x66000000),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          _chatMessages[index],
                          style: const TextStyle(color: Colors.white, fontSize: 12),
                        ),
                      ),
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  color: Colors.black.withOpacity(0.9),
                  child: Row(
                    children: [
                      IconButton(
                        icon: Icon(
                          _isMicMuted ? Icons.mic_off : Icons.mic,
                          color: _isMicMuted ? Colors.redAccent : Colors.greenAccent,
                        ),
                        onPressed: _toggleMic,
                      ),
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12),

decoration: BoxDecoration(
                            color: Colors.white12,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: TextField(
                            controller: _msgController,
                            style: const TextStyle(color: Colors.white, fontSize: 13),
                            decoration: const InputDecoration(
                              hintText: "Say something...",
                              hintStyle: TextStyle(color: Colors.white54),
                              border: InputBorder.none,
                            ),
                            onSubmitted: (val) {
                              if (val.trim().isNotEmpty) {
                                setState(() => _chatMessages.add("Kedir: $val"));
                                _msgController.clear();
                              }
                            },
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.sports_esports, color: Color(0xFFFFD700)),
                        onPressed: () {
                          showModalBottomSheet(
                            context: context,
                            isScrollControlled: true,
                            backgroundColor: Colors.transparent,
                            builder: (_) => LuckyWheelDialog(
                              currentCoins: _currentCoins,
                              onCoinsUpdated: (newCoins) {
                                setState(() {
                                  _currentCoins = newCoins;
                                });
                                widget.onCoinUpdate(newCoins);
                              },
                            ),
                          );
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.card_giftcard, color: Color(0xFFFFD700)),
                        onPressed: _openGiftSheet,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          if (_isPlayingAnimation && _svgaController != null)
            IgnorePointer(
              ignoring: true,
              child: Center(
                child: SizedBox(
                  width: MediaQuery.of(context).size.width,
                  height: MediaQuery.of(context).size.height,
                  child: SVGAImage(_svgaController!),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
