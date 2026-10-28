import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:svgaplayer_flutter/svgaplayer_flutter.dart';
import 'wallet_screen.dart';
import '../widgets/lucky_wheel_dialog.dart';
import '../widgets/teen_patti_dialog.dart';
import '../widgets/room_control_sheets.dart';

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
    cost: 100,
    svgaUrl: "https://raw.githubusercontent.com/yyued/SVGAPlayer-Android/master/app/src/main/assets/rose.svga",
  ),
  GiftModel(
    id: "2",
    name: "Sports Car",
    icon: "🏎️",
    cost: 300,
    svgaUrl: "https://raw.githubusercontent.com/yyued/SVGAPlayer-Android/master/app/src/main/assets/posche.svga",
  ),
  GiftModel(
    id: "3",
    name: "Crown Rose",
    icon: "🌹",
    cost: 50,
    svgaUrl: "https://raw.githubusercontent.com/yyued/SVGAPlayer-Android/master/app/src/main/assets/rose_2.0.svga",
  ),
  GiftModel(
    id: "4",
    name: "VIP Angel",
    icon: "💎",
    cost: 500,
    svgaUrl: "https://raw.githubusercontent.com/yyued/SVGAPlayer-Android/master/app/src/main/assets/angel.svga",
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
    this.seatCount = 25,
  });

  @override
  State<VoicePartyRoomScreen> createState() => _VoicePartyRoomScreenState();
}

class _VoicePartyRoomScreenState extends State<VoicePartyRoomScreen>
    with TickerProviderStateMixin {
  late int _currentCoins;
  late int _activeSeatCount;
  bool _isMicMuted = false;
  int? _mySeatIndex;
  late List<String?> _seats;
  final List<String> _chatMessages = [
    "System: Please protect your privacy and stay safe.",
    "Announcement: Welcome to VIP Live Party!"
  ];
  final TextEditingController _msgController = TextEditingController();

  RtcEngine? _engine;
  bool _isEngineReady = false;
  late final int _myUid;

  SVGAAnimationController? _svgaController;
  bool _isPlayingAnimation = false;

  late AnimationController _pulseController;
  final Set<int> _speakingSeatIndices = {};
  final Set<int> _mutedSeats = {};

  late RoomSettingsData _roomSettings;

  static const String nightSkyBgUrl =
      "https://images.unsplash.com/photo-1534447677768-be436bb09401?q=80&w=1080&auto=format&fit=crop";

  @override
  void initState() {
    super.initState();
    _currentCoins = widget.initialCoins;
    _activeSeatCount = widget.seatCount;
    _seats = List.filled(_activeSeatCount, null);
    _myUid = Random().nextInt(899999) + 100000;
    _svgaController = SVGAAnimationController(vsync: this);

    _roomSettings = RoomSettingsData(
      roomName: widget.roomTitle,
      roomDescription: "Welcome to our room!",
      seatCount: _activeSeatCount,
    );

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);

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
          interval: 200,
          smooth: 3,
          reportVad: true,
        );

        _engine!.registerEventHandler(
          RtcEngineEventHandler(
            onJoinChannelSuccess: (RtcConnection connection, int elapsed) {
              setState(() {
                _chatMessages.add("Connected to voice network (UID: $_myUid)");
              });
            },
            onUserJoined: (RtcConnection connection, int remoteUid, int elapsed) {
              setState(() {
                _chatMessages.add("User $remoteUid joined");
              });
            },
            onAudioVolumeIndication: (
              RtcConnection connection,
              List<AudioVolumeInfo> speakers,
              int totalVolume,
              int speakerNumber,
            ) {
              if (mounted) {
                setState(() {
                  _speakingSeatIndices.clear();
                  for (var speaker in speakers) {
                    if ((speaker.volume ?? 0) > 4) {
                      if (speaker.uid == 0 || speaker.uid == _myUid) {
                        if (_mySeatIndex != null) _speakingSeatIndices.add(_mySeatIndex!);
                      }
                    }
                  }
                });
              }
            },
          ),
        );

        await _engine!.enableAudio();
        await _engine!.setAudioProfile(
          profile: AudioProfileType.audioProfileMusicStandard,
          scenario: AudioScenarioType.audioScenarioGameStreaming,
        );

        await _engine!.joinChannel(
          token: agoraToken,
          channelId: channelName,
          uid: _myUid,
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

  Future<void> _updateBroadcasterRole(bool isSpeaker) async {
    if (_engine != null && _isEngineReady) {
      if (isSpeaker) {
        await _engine!.setClientRole(role: ClientRoleType.clientRoleBroadcaster);
        await _engine!.updateChannelMediaOptions(
          const ChannelMediaOptions(
            clientRoleType: ClientRoleType.clientRoleBroadcaster,
            publishMicrophoneTrack: true,
            autoSubscribeAudio: true,
          ),
        );
        await _engine!.muteLocalAudioStream(_isMicMuted);
      } else {
        await _engine!.setClientRole(role: ClientRoleType.clientRoleAudience);
        await _engine!.updateChannelMediaOptions(
          const ChannelMediaOptions(
            clientRoleType: ClientRoleType.clientRoleAudience,
            publishMicrophoneTrack: false,
            autoSubscribeAudio: true,
          ),
        );
      }
    }
  }

  void _handleSeatTap(int index) {
    if (_roomSettings.isAllMicClosed && index != 0 && _mySeatIndex != 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("All mics are closed by the host")),
      );
      return;
    }

    final user = _seats[index];
    if (user != null && _mySeatIndex != index) {
      _openSeatUserAction(index, user);
      return;
    }

    setState(() {
      if (_seats[index] == null) {
        if (_mySeatIndex != null) _seats[_mySeatIndex!] = null;
        _seats[index] = "User_$_myUid";
        _mySeatIndex = index;
        _updateBroadcasterRole(true);
      } else if (_mySeatIndex == index) {
        _seats[index] = null;
        _mySeatIndex = null;
        _updateBroadcasterRole(false);
      }
    });
  }

  Future<void> _toggleMic() async {
    setState(() {
      _isMicMuted = !_isMicMuted;
    });
    if (_engine != null && _isEngineReady && _mySeatIndex != null) {
      await _engine!.muteLocalAudioStream(_isMicMuted);
    }
  }

void _toggleRoomVoice() {
    setState(() {
      _roomSettings.isRoomAudioMuted = !_roomSettings.isRoomAudioMuted;
    });
    _engine?.muteAllRemoteAudioStreams(_roomSettings.isRoomAudioMuted);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(_roomSettings.isRoomAudioMuted ? "Room Voice Muted" : "Room Voice Active")),
    );
  }

  void _toggleAllMic() {
    setState(() {
      _roomSettings.isAllMicClosed = !_roomSettings.isAllMicClosed;
      if (_roomSettings.isAllMicClosed) {
        if (_mySeatIndex != 0) {
          _isMicMuted = true;
          _engine?.muteLocalAudioStream(true);
        }
      }
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(_roomSettings.isAllMicClosed ? "All Mics Closed" : "All Mics Opened")),
    );
  }

  void _openPasswordDialog() {
    final passCtrl = TextEditingController(text: _roomSettings.password ?? "");
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF1E1B38),
        title: const Text("Set Room Password", style: TextStyle(color: Colors.white)),
        content: TextField(
          controller: passCtrl,
          keyboardType: TextInputType.number,
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(
            hintText: "Enter 4-digit code (Leave blank to remove)",
            hintStyle: TextStyle(color: Colors.white38),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() {
                final txt = passCtrl.text.trim();
                _roomSettings.password = txt.isEmpty ? null : txt;
              });
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(_roomSettings.password == null ? "Password removed" : "Password set successfully")),
              );
            },
            child: const Text("Save"),
          ),
        ],
      ),
    );
  }

  void _openAdminSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF141226),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => Container(
        height: 320,
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Room Administrators",
              style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: ListView.builder(
                itemCount: _seats.length,
                itemBuilder: (context, idx) {
                  final u = _seats[idx];
                  if (u == null) return const SizedBox.shrink();
                  final isAdmin = _roomSettings.admins.contains(u);
                  return ListTile(
                    leading: const CircleAvatar(
                      backgroundColor: Color(0xFF2A224E),
                      child: Icon(Icons.person, color: Color(0xFFFFD700)),
                    ),
                    title: Text(u, style: const TextStyle(color: Colors.white)),
                    trailing: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isAdmin ? Colors.redAccent : const Color(0xFF00C9A7),
                      ),
                      onPressed: () {
                        setState(() {
                          if (isAdmin) {

_roomSettings.admins.remove(u);
                          } else {
                            _roomSettings.admins.add(u);
                          }
                        });
                        Navigator.pop(context);
                      },
                      child: Text(isAdmin ? "Remove Admin" : "Make Admin", style: const TextStyle(color: Colors.white)),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _openRedPacketDialog() {
    int selectedAmount = 100;
    int selectedCount = 5;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF1B162B),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => StatefulBuilder(
        builder: (ctx, setDialogState) => Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2)),
                ),
              ),
              const SizedBox(height: 16),
              const Center(
                child: Text(
                  "🧧 Send Red Packet",
                  style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(height: 16),
              const Text("Total Coins in Red Packets", style: TextStyle(color: Colors.white70, fontSize: 13)),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [100, 500, 1000].map((amt) {
                  final sel = selectedAmount == amt;
                  return ChoiceChip(
                    label: Text("🪙 $amt"),
                    selected: sel,
                    selectedColor: const Color(0xFFFFD700),
                    backgroundColor: const Color(0xFF2A224E),
                    labelStyle: TextStyle(color: sel ? Colors.black : Colors.white, fontWeight: FontWeight.bold),
                    onSelected: (_) => setDialogState(() => selectedAmount = amt),
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),
              const Text("Red Packet Quantity", style: TextStyle(color: Colors.white70, fontSize: 13)),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [5, 10, 15, 20].map((qty) {
                  final sel = selectedCount == qty;
                  return ChoiceChip(
                    label: Text("x$qty"),
                    selected: sel,
                    selectedColor: const Color(0xFFFFD700),
                    backgroundColor: const Color(0xFF2A224E),
                    labelStyle: TextStyle(color: sel ? Colors.black : Colors.white, fontWeight: FontWeight.bold),
                    onSelected: (_) => setDialogState(() => selectedCount = qty),
                  );
                }).toList(),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFF3366),
                    padding: const EdgeInsets.symmetric(vertical: 14),

shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                  ),
                  onPressed: () {
                    if (_currentCoins < selectedAmount) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("Insufficient coins to send Red Packet!")),
                      );
                      return;
                    }
                    setState(() {
                      _currentCoins -= selectedAmount;
                      _chatMessages.add("🧧 Red Packet of $selectedAmount Coins dropped in room!");
                    });
                    widget.onCoinUpdate(_currentCoins);
                    Navigator.pop(context);
                  },
                  child: const Text("Send Red Packets", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(height: 10),
            ],
          ),
        ),
      ),
    );
  }

  void _openSeatUserAction(int index, String user) {
    final isMuted = _mutedSeats.contains(index);
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF141226),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(user, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            ListTile(
              leading: Icon(isMuted ? Icons.mic : Icons.mic_off, color: const Color(0xFFFFD700)),
              title: Text(isMuted ? "Unmute User" : "Mute User", style: const TextStyle(color: Colors.white)),
              onTap: () {
                setState(() {
                  if (isMuted) {
                    _mutedSeats.remove(index);
                  } else {
                    _mutedSeats.add(index);
                  }
                });
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.exit_to_app, color: Colors.redAccent),
              title: const Text("Kick from Seat", style: TextStyle(color: Colors.redAccent)),
              onTap: () {
                setState(() {
                  _seats[index] = null;
                });
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _playGiftAnimation(GiftModel gift) async {
    if (_svgaController == null) return;
    try {
      final parser = SVGAParser.shared;
      final videoItem = await parser.decodeFromURL(gift.svgaUrl);
      setState(() {
        _isPlayingAnimation = true;
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
    if (_currentCoins < gift.cost) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Insufficient coins! Please recharge.")),
      );
      return;
    }

    setState(() {
      _currentCoins -= gift.cost;
      _chatMessages.add("Gift sent: ${gift.name} to $target");
    });
    widget.onCoinUpdate(_currentCoins);
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
    _pulseController.dispose();
    _engine?.leaveChannel();
    _engine?.release();
    _svgaController?.dispose();
    _msgController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Dynamic Responsive Seat Sizing for up to 30 seats
    final double seatSize = _activeSeatCount > 20 ? 38.0 : 44.0;
    final int crossCount = _activeSeatCount > 20 ? 6 : 5;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white, size: 20),
          onPressed: () => Navigator.pop(context),

),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _roomSettings.roomName,
              style: const TextStyle(fontSize: 15, color: Colors.white, fontWeight: FontWeight.bold),
            ),
            Row(
              children: [
                Text("UID: $_myUid", style: const TextStyle(fontSize: 11, color: Colors.white70)),
                if (_roomSettings.password != null) ...[
                  const SizedBox(width: 6),
                  const Icon(Icons.lock, color: Color(0xFFFFD700), size: 12),
                ],
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.share, color: Colors.white),
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(Icons.power_settings_new, color: Colors.redAccent),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
      body: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              image: DecorationImage(
                image: const NetworkImage(nightSkyBgUrl),
                fit: BoxFit.cover,
                colorFilter: ColorFilter.mode(
                  Colors.black.withOpacity(0.45),
                  BlendMode.darken,
                ),
              ),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                const SizedBox(height: 6),
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      children: [
                        _buildHostSeat(),
                        const SizedBox(height: 10),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 14),
                          child: GridView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: _activeSeatCount > 1 ? _activeSeatCount - 1 : 0,
                            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: crossCount,
                              mainAxisSpacing: 10,
                              crossAxisSpacing: 8,
                              childAspectRatio: 0.85,
                            ),
                            itemBuilder: (context, index) {
                              final seatIndex = index + 1;
                              final isTaken = _seats[seatIndex] != null;
                              final isSpeaking = (_mySeatIndex == seatIndex && !_isMicMuted) ||
                                  _speakingSeatIndices.contains(seatIndex);
                              final isMuted = _mutedSeats.contains(seatIndex) || _roomSettings.isAllMicClosed;

                              return GestureDetector(
                                onTap: () => _handleSeatTap(seatIndex),
                                child: Column(
                                  children: [
                                    AnimatedBuilder(
                                      animation: _pulseController,
                                      builder: (context, _) {
                                        final pulse = _pulseController.value;
                                        return Container(
                                          width: seatSize,
                                          height: seatSize,
                                          decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            color: Colors.white.withOpacity(0.12),

border: Border.all(
                                              color: isSpeaking
                                                  ? Colors.cyanAccent
                                                  : Colors.white24,
                                              width: isSpeaking ? (2.0 + pulse * 1.5) : 1,
                                            ),
                                            boxShadow: isSpeaking
                                                ? [
                                                    BoxShadow(
                                                      color: Colors.cyanAccent.withOpacity(0.5),
                                                      blurRadius: 8 + (pulse * 6),
                                                      spreadRadius: 2,
                                                    )
                                                  ]
                                                : null,
                                          ),
                                          child: Center(
                                            child: isTaken
                                                ? (isMuted
                                                    ? const Icon(Icons.mic_off, color: Colors.redAccent, size: 18)
                                                    : const Icon(Icons.person, color: Color(0xFFFFD700), size: 20))
                                                : (isMuted
                                                    ? const Icon(Icons.lock, color: Colors.white38, size: 16)
                                                    : const Icon(Icons.chair, color: Colors.white70, size: 18)),
                                          ),
                                        );
                                      },
                                    ),
                                    const SizedBox(height: 3),
                                    Text(
                                      isTaken ? _seats[seatIndex]! : "$seatIndex",
                                      style: TextStyle(
                                        color: isTaken ? const Color(0xFFFFD700) : Colors.white70,
                                        fontSize: 9,
                                        fontWeight: FontWeight.bold,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                // Chat Box Area
                Container(
                  height: 90,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  alignment: Alignment.bottomLeft,
                  child: ListView.builder(
                    reverse: true,
                    itemCount: _chatMessages.length,
                    itemBuilder: (context, index) {
                      final msg = _chatMessages[_chatMessages.length - 1 - index];
                      final isSystem = msg.startsWith("System:")  msg.startsWith("Announcement:")  msg.startsWith("🧧");
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 2.0),
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),

decoration: BoxDecoration(
                              color: isSystem ? Colors.purple.withOpacity(0.4) : Colors.black45,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              msg,
                              style: TextStyle(
                                color: isSystem ? const Color(0xFFFFD700) : Colors.white,
                                fontSize: 11,
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                // Bottom Action Bar
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.75),
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                  ),
                  child: Row(
                    children: [
                      IconButton(
                        icon: Icon(
                          _isMicMuted ? Icons.mic_off : Icons.mic,
                          color: _isMicMuted ? Colors.redAccent : Colors.cyanAccent,
                        ),
                        onPressed: _toggleMic,
                      ),
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: TextField(
                            controller: _msgController,
                            style: const TextStyle(color: Colors.white, fontSize: 13),
                            decoration: const InputDecoration(
                              hintText: "Say Hello...",
                              hintStyle: TextStyle(color: Colors.white54),
                              border: InputBorder.none,
                            ),
                            onSubmitted: (val) {
                              if (val.trim().isNotEmpty) {
                                setState(() => _chatMessages.add("User_$_myUid: $val"));
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
                            backgroundColor: const Color(0xFF141226),
                            shape: const RoundedRectangleBorder(
                              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                            ),
                            builder: (context) => Padding(
                              padding: const EdgeInsets.all(20.0),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    width: 40,
                                    height: 4,
                                    decoration: BoxDecoration(
                                      color: Colors.white24,
                                      borderRadius: BorderRadius.circular(2),

),
                                  ),
                                  const SizedBox(height: 16),
                                  const Text(
                                    "Select Mini-Game",
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 18,
                                    ),
                                  ),
                                  const SizedBox(height: 20),
                                  ListTile(
                                    leading: const CircleAvatar(
                                      backgroundColor: Color(0xFF2A224E),
                                      child: Text("🎰", style: TextStyle(fontSize: 20)),
                                    ),
                                    title: const Text(
                                      "Lucky Spin Wheel",
                                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                                    ),
                                    trailing: const Icon(Icons.chevron_right, color: Color(0xFFFFD700)),
                                    onTap: () {
                                      Navigator.pop(context);
                                      showModalBottomSheet(
                                        context: context,
                                        isScrollControlled: true,
                                        backgroundColor: Colors.transparent,
                                        builder: (_) => LuckyWheelDialog(
                                          currentCoins: _currentCoins,
                                          onCoinsUpdated: (newCoins) {
                                            setState(() => _currentCoins = newCoins);
                                            widget.onCoinUpdate(newCoins);
                                          },
                                        ),
                                      );
                                    },
                                  ),
                                  const Divider(color: Colors.white10),
                                  ListTile(
                                    leading: const CircleAvatar(
                                      backgroundColor: Color(0xFF2A224E),
                                      child: Text("🃏", style: TextStyle(fontSize: 20)),
                                    ),
                                    title: const Text(
                                      "Teen Patti (3 Cards)",
                                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                                    ),
                                    trailing: const Icon(Icons.chevron_right, color: Color(0xFFFFD700)),
                                    onTap: () {
                                      Navigator.pop(context);
                                      showModalBottomSheet(
                                        context: context,
                                        isScrollControlled: true,
                                        backgroundColor: Colors.transparent,
                                        builder: (_) => TeenPattiDialog(
                                          currentCoins: _currentCoins,
                                          onCoinsUpdated: (newCoins) {
                                            setState(() => _currentCoins = newCoins);
                                            widget.onCoinUpdate(newCoins);
                                          },
                                        ),

);
                                    },
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.card_giftcard, color: Color(0xFFFFD700)),
                        onPressed: _openGiftSheet,
                      ),
                      IconButton(
                        icon: const Icon(Icons.grid_view_rounded, color: Colors.white70),
                        onPressed: () {
                          showModalBottomSheet(
                            context: context,
                            backgroundColor: Colors.transparent,
                            builder: (_) => BasicToolsSheet(
                              settings: _roomSettings,
                              onToggleRoomVoice: _toggleRoomVoice,
                              onToggleAllMic: _toggleAllMic,
                              onOpenPasswordDialog: _openPasswordDialog,
                              onOpenAdminSheet: _openAdminSheet,
                              onOpenRedPacket: _openRedPacketDialog,
                              onOpenRoomSettings: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => RoomSettingsScreen(
                                      settings: _roomSettings,
                                      currentSeats: _seats,
                                      onKickSeat: (idx) {
                                        setState(() => _seats[idx] = null);
                                      },
                                      onUpdateSettings: (newSet) {
                                        setState(() {
                                          _roomSettings = newSet;
                                          _activeSeatCount = newSet.seatCount;
                                          _seats = List.filled(_activeSeatCount, null);
                                        });
                                      },
                                    ),
                                  ),
                                );
                              },
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          if (_isPlayingAnimation && _svgaController != null)
            Positioned.fill(
              child: IgnorePointer(
                ignoring: true,
                child: SVGAImage(_svgaController!),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildHostSeat() {
    final isTaken = _seats[0] != null;
    final isSpeaking = (_mySeatIndex == 0 && !_isMicMuted) || _speakingSeatIndices.contains(0);

    return GestureDetector(
      onTap: () => _handleSeatTap(0),
      child: Column(
        children: [
          AnimatedBuilder(
            animation: _pulseController,
            builder: (context, _) {
              final pulse = _pulseController.value;
              return Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      isSpeaking
                          ? Colors.cyanAccent.withOpacity(0.5)
                          : const Color(0xFF6C5CE7).withOpacity(0.4),
                      const Color(0xFF141226).withOpacity(0.85),

],
                  ),
                  border: Border.all(
                    color: isSpeaking ? Colors.cyanAccent : const Color(0xFFFFD700),
                    width: isSpeaking ? (2.5 + pulse * 1.5) : 2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: isSpeaking
                          ? Colors.cyanAccent.withOpacity(0.7)
                          : const Color(0xFFFFD700).withOpacity(0.4),
                      blurRadius: 12 + (pulse * 8),
                      spreadRadius: 2 + (pulse * 3),
                    ),
                  ],
                ),
                child: Center(
                  child: isTaken
                      ? const Icon(Icons.person, color: Color(0xFFFFD700), size: 34)
                      : const Icon(Icons.chair, color: Color(0xFFFFD700), size: 30),
                ),
              );
            },
          ),
          const SizedBox(height: 4),
          Text(
            isTaken ? _seats[0]! : "1",
            style: const TextStyle(
              color: Color(0xFFFFD700),
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
