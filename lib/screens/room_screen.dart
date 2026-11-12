import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:video_player/video_player.dart';
import 'wallet_screen.dart';
import '../widgets/lucky_wheel_dialog.dart';
import '../widgets/teen_patti_dialog.dart';
import '../widgets/room_control_sheets.dart';
import '../services/agora_service.dart';

const String channelName = "habesha_vip_room";

class GiftModel {
  final String id;
  final String name;
  final String icon;
  final int cost;
  final String videoPath;
  final bool isLucky;

  const GiftModel({
    required this.id,
    required this.name,
    required this.icon,
    this.cost = 0,
    required this.videoPath,
    this.isLucky = false,
  });
}

const List<GiftModel> availableGifts = [
  GiftModel(
    id: "1",
    name: "Rocket",
    icon: "🚀",
    cost: 100,
    videoPath: "assets/svga/svga10.mp4",
  ),
  GiftModel(
    id: "2",
    name: "Sports Car",
    icon: "🏎️",
    cost: 300,
    videoPath: "assets/svga/svga11.mp4",
  ),
  GiftModel(
    id: "3",
    name: "Crown Rose",
    icon: "🌹",
    cost: 50,
    videoPath: "assets/svga/svga12.mp4",
  ),
  GiftModel(
    id: "4",
    name: "VIP Angel",
    icon: "💎",
    cost: 500,
    videoPath: "assets/svga/svga13.mp4",
    isLucky: true,
  ),
];

const List<int> giftMultipliers = [1, 3, 7, 10, 33, 77, 100];

class GiftComboData {
  final String senderName;
  final String targetName;
  final String giftName;
  final String giftIcon;
  final int comboCount;

  GiftComboData({
    required this.senderName,
    required this.targetName,
    required this.giftName,
    required this.giftIcon,
    required this.comboCount,
  });
}

class RoomScreen extends StatefulWidget {
  final String roomTitle;
  final int initialCoins;
  final Function(int) onCoinUpdate;
  final int seatCount;

  const RoomScreen({
    super.key,
    required this.roomTitle,
    required this.initialCoins,
    required this.onCoinUpdate,
    this.seatCount = 12,
  });

  @override
  State<RoomScreen> createState() => _RoomScreenState();
}

class _RoomScreenState extends State<RoomScreen>
    with TickerProviderStateMixin {
  final User? _currentUser = FirebaseAuth.instance.currentUser;
  final AgoraService _agoraService = AgoraService();

  late int _currentCoins;
  late int _activeSeatCount;
  bool _isMicMuted = false;
  int? _mySeatIndex;
  late List<String?> _seats;
  late List<String?> _seatUids;
  late List<int> _seatGiftsCount;

  bool _isAllSeatsTargeted = false;

  final List<String> _chatMessages = [
    "System: Please protect your privacy and stay safe.",
    "Announcement: Welcome to VIP Live Party!"
  ];
  final TextEditingController _msgController = TextEditingController();

  late int _myUid;
  String _myDisplayName = "User";

  VideoPlayerController? _videoController;
  bool _isPlayingVideo = false;

  GiftComboData? _activeComboData;
  Timer? _comboDismissTimer;
  late AnimationController _comboScaleController;
  late Animation<double> _comboScaleAnimation;
  int _currentComboStreak = 0;
  DateTime? _lastGiftTimestamp;
  String? _lastGiftTargetKey;

  late AnimationController _pulseController;
  final Set<int> _speakingSeatIndices = {};
  final Set<int> _mutedSeats = {};

  late RoomSettingsData _roomSettings;

  Timer? _micTrackerTimer;
  StreamSubscription<DocumentSnapshot>? _roomSubscription;
  StreamSubscription<QuerySnapshot>? _chatSubscription;

  static const Color bgColor = Color(0xFFF5EFEB);
  static const Color cardBg = Colors.white;
  static const Color primaryBrown = Color(0xFF3E2723);
  static const Color accentGold = Color(0xFFD49B42);
  static const Color borderColor = Color(0xFFE2D6C5);
  static const Color buttonDark = Color(0xFF4A3528);

  @override

void initState() {
    super.initState();
    _currentCoins = widget.initialCoins;
    _activeSeatCount = widget.seatCount;
    _seats = List.filled(_activeSeatCount, null);
    _seatUids = List.filled(_activeSeatCount, null);
    _seatGiftsCount = List.filled(_activeSeatCount, 0);
    _myUid = 100001;

    _roomSettings = RoomSettingsData(
      roomName: widget.roomTitle,
      roomDescription: "Welcome to our room!",
      seatCount: _activeSeatCount,
    );

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);

    _comboScaleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
    );

    _comboScaleAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.55), weight: 50),
      TweenSequenceItem(tween: Tween(begin: 1.55, end: 1.0), weight: 50),
    ]).animate(CurvedAnimation(
      parent: _comboScaleController,
      curve: Curves.easeOutBack,
    ));

    _fetchUserProfile();
    _initVoiceEngine();
    _syncRoomWithFirestore();
    _listenToLiveRoomChats();
  }

  Future<void> _fetchUserProfile() async {
    if (_currentUser != null) {
      final snap = await FirebaseFirestore.instance
          .collection('users')
          .doc(_currentUser!.uid)
          .get();
      if (snap.exists && snap.data() != null) {
        final d = snap.data()!;
        if (mounted) {
          setState(() {
            _myUid = (d['numericId'] as num?)?.toInt() ?? 100001;
            _myDisplayName = (d['name'] ?? d['displayName'] ?? "User").toString();
            _currentCoins = (d['coins'] as num?)?.toInt() ?? _currentCoins;
          });
        }
      }
    }
  }

  void _syncRoomWithFirestore() {
    final roomRef = FirebaseFirestore.instance.collection('rooms').doc(channelName);
    _roomSubscription = roomRef.snapshots().listen((snapshot) {
      if (snapshot.exists && snapshot.data() != null) {
        final data = snapshot.data()!;
        if (data['seats'] is List) {
          final List incomingSeats = data['seats'] as List;
          final List incomingUids = (data['seatUids'] as List?) ?? [];
          final List incomingGifts = (data['seatGifts'] as List?) ?? [];

          if (mounted) {
            setState(() {
              for (int i = 0; i < _activeSeatCount; i++) {
                if (i < incomingSeats.length) {
                  _seats[i] = incomingSeats[i];
                }
                if (i < incomingUids.length) {
                  _seatUids[i] = incomingUids[i];
                }
                if (i < incomingGifts.length) {
                  _seatGiftsCount[i] = (incomingGifts[i] as num).toInt();
                }
              }

              if (_currentUser != null && _seatUids.contains(_currentUser!.uid)) {
                _mySeatIndex = _seatUids.indexOf(_currentUser!.uid);
              } else {
                _mySeatIndex = null;
              }
            });
          }
        }
      }
    });
  }

  void _listenToLiveRoomChats() {
    _chatSubscription = FirebaseFirestore.instance
        .collection('rooms')
        .doc(channelName)
        .collection('chats')
        .orderBy('timestamp', descending: true)
        .limit(30)
        .snapshots()
        .listen((querySnapshot) {
      if (querySnapshot.docs.isNotEmpty && mounted) {
        final List<String> loadedMsgs = [];
        for (var doc in querySnapshot.docs.reversed) {
          final d = doc.data();
          final sender = d['sender'] ?? "User";
          final txt = d['text'] ?? "";
          if (txt.toString().isNotEmpty) {
            loadedMsgs.add("$sender: $txt");
          }
        }
        setState(() {
          _chatMessages.clear();
          _chatMessages.addAll(loadedMsgs);
        });
      }
    });
  }

void _startMicMinutesTracking() {
    _micTrackerTimer?.cancel();
    _micTrackerTimer = Timer.periodic(const Duration(minutes: 1), (timer) {
      if (_currentUser != null && _mySeatIndex != null && !_isMicMuted) {
        FirebaseFirestore.instance
            .collection('users')
            .doc(_currentUser!.uid)
            .set({
          'todayMicMinutes': FieldValue.increment(1),
        }, SetOptions(merge: true));
      }
    });
  }

  void _stopMicMinutesTracking() {
    _micTrackerTimer?.cancel();
  }

  Future<void> _initVoiceEngine() async {
    try {
      await _agoraService.initEngine(
        onUserJoined: (uid) {
          if (mounted) {
            setState(() {
              _chatMessages.add("User $uid joined");
            });
          }
        },
        onUserOffline: (uid) {
          if (mounted) {
            setState(() {
              _chatMessages.add("User $uid left");
            });
          }
        },
        onVolumeChanged: (speakers) {
          if (mounted) {
            setState(() {
              _speakingSeatIndices.clear();
              for (var speaker in speakers) {
                if ((speaker.volume ?? 0) > 4) {
                  if (speaker.uid == 0 || speaker.uid == _myUid) {
                    if (_mySeatIndex != null) {
                      _speakingSeatIndices.add(_mySeatIndex!);
                    }
                  }
                }
              }
            });
          }
        },
      );

      await _agoraService.joinRoom(
        channelId: channelName,
        uid: _myUid,
        isSpeaker: _mySeatIndex != null,
        roomTitle: widget.roomTitle,
        seatCount: _activeSeatCount,
      );

      if (mounted) {
        setState(() {
          _chatMessages.add("Connected to voice network (UID: $_myUid)");
        });
      }
    } catch (e) {
      debugPrint("Voice Engine Error: $e");
    }
  }

  Future<void> _updateBroadcasterRole(bool isSpeaker) async {
    await _agoraService.switchRole(isSpeaker: isSpeaker);
  }

  void _handleSeatTap(int index) async {
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

    if (_seats[index] == null) {
      if (_mySeatIndex != null) {
        _seats[_mySeatIndex!] = null;
        _seatUids[_mySeatIndex!] = null;
      }
      _seats[index] = _myDisplayName;
      _seatUids[index] = _currentUser?.uid;
      _mySeatIndex = index;
      _isMicMuted = false;
      _updateBroadcasterRole(true);
      _startMicMinutesTracking();
    } else if (_mySeatIndex == index) {
      _seats[index] = null;
      _seatUids[index] = null;
      _mySeatIndex = null;
      _isMicMuted = true;
      _updateBroadcasterRole(false);
      _stopMicMinutesTracking();
    }

    setState(() {});

    await FirebaseFirestore.instance.collection('rooms').doc(channelName).set({
      'seats': _seats,
      'seatUids': _seatUids,
      'seatGifts': _seatGiftsCount,
    }, SetOptions(merge: true));
  }

  Future<void> _toggleMic() async {
    setState(() {
      _isMicMuted = !_isMicMuted;
    });
    if (_mySeatIndex != null) {
      await _agoraService.setMicrophoneMute(_isMicMuted);
      if (_isMicMuted) {
        _stopMicMinutesTracking();
      } else {
        _startMicMinutesTracking();
      }
    }
  }

  void _toggleRoomVoice() {
    setState(() {
      _roomSettings.isRoomAudioMuted = !_roomSettings.isRoomAudioMuted;
    });
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
          _agoraService.setMicrophoneMute(true);
          _stopMicMinutesTracking();
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
        backgroundColor: bgColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text("Set Room Password", style: TextStyle(color: primaryBrown, fontWeight: FontWeight.bold)),
        content: TextField(
          controller: passCtrl,
          keyboardType: TextInputType.number,
          style: const TextStyle(color: primaryBrown),
          decoration: InputDecoration(
            hintText: "Enter 4-digit code (Leave blank to remove)",
            hintStyle: const TextStyle(color: Colors.black38, fontSize: 12),
            filled: true,
            fillColor: cardBg,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: borderColor)),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: borderColor)),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel", style: TextStyle(color: Colors.black54)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: buttonDark),
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
            child: const Text("Save", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _openAdminSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        height: 340,
        padding: const EdgeInsets.all(18),
        decoration: const BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(width: 44, height: 4, decoration: BoxDecoration(color: Colors.black26, borderRadius: BorderRadius.circular(2))),
            ),
            const SizedBox(height: 14),
            const Text(
              "Room Administrators",
              style: TextStyle(color: primaryBrown, fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: ListView.builder(
                itemCount: _seats.length,
                itemBuilder: (context, idx) {
                  final u = _seats[idx];
                  if (u == null) return const SizedBox.shrink();
                  final isAdmin = _roomSettings.admins.contains(u);
                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    decoration: BoxDecoration(

color: cardBg,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: borderColor),
                    ),
                    child: ListTile(
                      leading: const CircleAvatar(
                        backgroundColor: bgColor,
                        child: Icon(Icons.person, color: primaryBrown),
                      ),
                      title: Text(u, style: const TextStyle(color: primaryBrown, fontWeight: FontWeight.bold, fontSize: 13)),
                      trailing: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: isAdmin ? Colors.redAccent : const Color(0xFF107C41),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          elevation: 0,
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
                        child: Text(isAdmin ? "Remove Admin" : "Make Admin", style: const TextStyle(color: Colors.white, fontSize: 11)),
                      ),
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
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (ctx, setDialogState) => Container(
          padding: const EdgeInsets.all(20),
          decoration: const BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 44,
                  height: 4,
                  decoration: BoxDecoration(color: Colors.black26, borderRadius: BorderRadius.circular(2)),
                ),
              ),
              const SizedBox(height: 16),
              const Center(
                child: Text(
                  "Send Red Packet",
                  style: TextStyle(color: primaryBrown, fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(height: 16),
              const Text("Total Coins in Red Packets", style: TextStyle(color: Colors.black54, fontSize: 12.5)),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [100, 500, 1000].map((amt) {
                  final sel = selectedAmount == amt;
                  return ChoiceChip(
                    label: Text("$amt Coins"),
                    selected: sel,
                    selectedColor: buttonDark,
                    backgroundColor: cardBg,
                    labelStyle: TextStyle(color: sel ? Colors.white : primaryBrown, fontWeight: FontWeight.bold, fontSize: 12),
                    onSelected: (_) => setDialogState(() => selectedAmount = amt),
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),
              const Text("Red Packet Quantity", style: TextStyle(color: Colors.black54, fontSize: 12.5)),

const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [5, 10, 15, 20].map((qty) {
                  final sel = selectedCount == qty;
                  return ChoiceChip(
                    label: Text("x$qty"),
                    selected: sel,
                    selectedColor: buttonDark,
                    backgroundColor: cardBg,
                    labelStyle: TextStyle(color: sel ? Colors.white : primaryBrown, fontWeight: FontWeight.bold, fontSize: 12),
                    onSelected: (_) => setDialogState(() => selectedCount = qty),
                  );
                }).toList(),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF107C41),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    elevation: 0,
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
                    });

                    FirebaseFirestore.instance.collection('rooms').doc(channelName).collection('chats').add({
                      'sender': 'System',
                      'text': "Red Packet of $selectedAmount Coins dropped in room!",
                      'timestamp': FieldValue.serverTimestamp(),
                    });

                    if (_currentUser != null) {
                      FirebaseFirestore.instance
                          .collection('users')
                          .doc(_currentUser!.uid)
                          .update({'coins': FieldValue.increment(-selectedAmount)});
                    }
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
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        padding: const EdgeInsets.all(18),
        decoration: const BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Center(
              child: Container(width: 44, height: 4, decoration: BoxDecoration(color: Colors.black26, borderRadius: BorderRadius.circular(2))),
            ),
            const SizedBox(height: 12),
            Text(user, style: const TextStyle(color: primaryBrown, fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 14),
            Container(
              decoration: BoxDecoration(color: cardBg, borderRadius: BorderRadius.circular(14), border: Border.all(color: borderColor)),
              child: Column(
                children: [
                  ListTile(
                    leading: Icon(isMuted ? Icons.mic : Icons.mic_off, color: primaryBrown),

title: Text(isMuted ? "Unmute User" : "Mute User", style: const TextStyle(color: primaryBrown, fontWeight: FontWeight.w600)),
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
                  const Divider(height: 1, color: borderColor),
                  ListTile(
                    leading: const Icon(Icons.exit_to_app, color: Colors.redAccent),
                    title: const Text("Kick from Seat", style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.w600)),
                    onTap: () async {
                      setState(() {
                        _seats[index] = null;
                        _seatUids[index] = null;
                      });
                      Navigator.pop(context);

                      await FirebaseFirestore.instance.collection('rooms').doc(channelName).set({
                        'seats': _seats,
                        'seatUids': _seatUids,
                      }, SetOptions(merge: true));
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _playGiftVideo(GiftModel gift) async {
    try {
      _videoController?.dispose();
      _videoController = VideoPlayerController.asset(gift.videoPath);
      await _videoController!.initialize();

      if (mounted) {
        setState(() {
          _isPlayingVideo = true;
        });
        _videoController!.play();
      }

      _videoController!.addListener(() {
        if (_videoController != null &&
            _videoController!.value.isInitialized &&
            _videoController!.value.position >= _videoController!.value.duration) {
          if (mounted) {
            setState(() {
              _isPlayingVideo = false;
            });
          }
        }
      });
    } catch (e) {
      debugPrint("Video Play Error: $e");
      if (mounted) {
        setState(() {
          _isPlayingVideo = false;
        });
      }
    }
  }

  void _triggerFloatingGiftCombo({
    required GiftModel gift,
    required String target,
    required int multiplier,
  }) {
    final now = DateTime.now();
    final targetKey = "${gift.id}_$target";

    if (_lastGiftTargetKey == targetKey &&
        _lastGiftTimestamp != null &&
        now.difference(_lastGiftTimestamp!).inSeconds < 4) {
      _currentComboStreak += multiplier;
    } else {
      _currentComboStreak = multiplier;
    }

    _lastGiftTargetKey = targetKey;
    _lastGiftTimestamp = now;

    _comboDismissTimer?.cancel();

    setState(() {
      _activeComboData = GiftComboData(
        senderName: _myDisplayName,
        targetName: target,
        giftName: gift.name,
        giftIcon: gift.icon,
        comboCount: _currentComboStreak,
      );
    });

    _comboScaleController.reset();
    _comboScaleController.forward();

    _comboDismissTimer = Timer(const Duration(milliseconds: 2800), () {
      if (mounted) {
        setState(() {
          _activeComboData = null;
        });
      }
    });
  }

  void _sendGift({
    required GiftModel gift,
    required String target,
    int? targetSeatIndex,
    required int multiplier,
  }) async {
    final int totalCost = gift.cost * multiplier;

    if (_currentCoins < totalCost) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Insufficient coins! Please recharge.")),
      );
      return;
    }

    final double rate = gift.isLucky ? 0.04 : 0.70;
    final int pointsPerRecipient = (totalCost * rate).round();

    setState(() {
      _currentCoins -= totalCost;

if (targetSeatIndex != null && targetSeatIndex < _seatGiftsCount.length) {
        _seatGiftsCount[targetSeatIndex] += totalCost;
        final recipientUid = _seatUids[targetSeatIndex];
        if (recipientUid != null && recipientUid.isNotEmpty) {
          FirebaseFirestore.instance.collection('users').doc(recipientUid).set({
            'points': FieldValue.increment(pointsPerRecipient),
            'charmExp': FieldValue.increment(pointsPerRecipient),
            'todayTaskPoints': FieldValue.increment(pointsPerRecipient),
            'weekTaskPoints': FieldValue.increment(pointsPerRecipient),
          }, SetOptions(merge: true));
        }
      } else if (target == "All Seats") {
        for (int i = 0; i < _seatGiftsCount.length; i++) {
          if (_seats[i] != null) {
            _seatGiftsCount[i] += totalCost;
            final recipientUid = _seatUids[i];
            if (recipientUid != null && recipientUid.isNotEmpty) {
              FirebaseFirestore.instance.collection('users').doc(recipientUid).set({
                'points': FieldValue.increment(pointsPerRecipient),
                'charmExp': FieldValue.increment(pointsPerRecipient),
                'todayTaskPoints': FieldValue.increment(pointsPerRecipient),
                'weekTaskPoints': FieldValue.increment(pointsPerRecipient),
              }, SetOptions(merge: true));
            }
          }
        }
      }
    });

    await FirebaseFirestore.instance.collection('rooms').doc(channelName).collection('chats').add({
      'sender': _myDisplayName,
      'text': "sent ${gift.name} ${gift.icon} x$multiplier to $target",
      'timestamp': FieldValue.serverTimestamp(),
    });

    await FirebaseFirestore.instance.collection('rooms').doc(channelName).set({
      'seatGifts': _seatGiftsCount,
    }, SetOptions(merge: true));

    if (_currentUser != null) {
      await FirebaseFirestore.instance.collection('users').doc(_currentUser!.uid).set({
        'coins': FieldValue.increment(-totalCost),
        'wealthExp': FieldValue.increment(totalCost),
      }, SetOptions(merge: true));
    }

    widget.onCoinUpdate(_currentCoins);
    Navigator.pop(context);

    _triggerFloatingGiftCombo(gift: gift, target: target, multiplier: multiplier);
    _playGiftVideo(gift);
  }

  void _openGiftSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        GiftModel selectedGift = availableGifts[0];
        String selectedTarget = "All Seats";
        int? selectedSeatIndex;
        int selectedMultiplier = 1;

        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Container(
              height: 530,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: const BoxDecoration(
                color: bgColor,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Column(
                children: [
                  Container(
                    width: 44,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.black26,
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
                          onTap: () {
                            setSheetState(() {

selectedTarget = "All Seats";
                              selectedSeatIndex = null;
                            });
                            setState(() {
                              _isAllSeatsTargeted = true;
                            });
                          },
                        ),
                        ...List.generate(_activeSeatCount, (i) {
                          final seatLabel = i == 0 ? "Host (1)" : "Seat ${i + 1}";
                          return _targetChip(
                            title: seatLabel,
                            isSelected: selectedTarget == seatLabel,
                            onTap: () {
                              setSheetState(() {
                                selectedTarget = seatLabel;
                                selectedSeatIndex = i;
                              });
                              setState(() {
                                _isAllSeatsTargeted = false;
                              });
                            },
                          );
                        }),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  Expanded(
                    child: GridView.builder(
                      itemCount: availableGifts.length,
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 4,
                        mainAxisSpacing: 10,
                        crossAxisSpacing: 10,
                        childAspectRatio: 0.8,
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
                              color: isSelected ? const Color(0xFFFBF4E6) : cardBg,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: isSelected ? accentGold : borderColor,
                                width: isSelected ? 2 : 1,
                              ),
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(gift.icon, style: const TextStyle(fontSize: 30)),
                                const SizedBox(height: 4),
                                Text(
                                  gift.name,
                                  style: const TextStyle(
                                    color: primaryBrown,
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
                                    const Icon(Icons.monetization_on, size: 12, color: accentGold),
                                    const SizedBox(width: 2),

Text(
                                      "${gift.cost}",
                                      style: const TextStyle(
                                        color: accentGold,
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
                  const SizedBox(height: 8),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: giftMultipliers.map((mult) {
                        final isChosen = selectedMultiplier == mult;
                        return GestureDetector(
                          onTap: () {
                            setSheetState(() {
                              selectedMultiplier = mult;
                            });
                          },
                          child: Container(
                            margin: const EdgeInsets.only(right: 8),
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              color: isChosen ? buttonDark : cardBg,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: isChosen ? buttonDark : borderColor,
                              ),
                            ),
                            child: Text(
                              "x$mult",
                              style: TextStyle(
                                color: isChosen ? Colors.white : primaryBrown,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.monetization_on, color: accentGold, size: 20),
                          const SizedBox(width: 4),
                          Text(
                            "$_currentCoins",
                            style: const TextStyle(
                              color: primaryBrown,
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                            ),
                          ),
                          const SizedBox(width: 8),
                          GestureDetector(
                            GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => WalletScreen(
                                    userUid: _currentUser?.uid ?? '',
                                    userNumericId: _myUid,
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
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: cardBg,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: borderColor),
                              ),
                              child: const Row(
                                children: [
                                  Text(
                                    "Recharge",
                                    style: TextStyle(
                                      color: primaryBrown,
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Icon(Icons.chevron_right, size: 14, color: primaryBrown),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF107C41),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          elevation: 0,
                        ),
                        onPressed: () => _sendGift(
                          gift: selectedGift,
                          target: selectedTarget,
                          targetSeatIndex: selectedSeatIndex,
                          multiplier: selectedMultiplier,
                        ),
                        child: Text(
                          "Send (Total: ${selectedGift.cost * selectedMultiplier})",
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    ).whenComplete(() {
      setState(() {
        _isAllSeatsTargeted = false;
      });
    });
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
          color: isSelected ? buttonDark : cardBg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? buttonDark : borderColor,
          ),
        ),
        child: Text(
          title,
          style: TextStyle(
            color: isSelected ? Colors.white : primaryBrown,
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _stopMicMinutesTracking();
    _roomSubscription?.cancel();
    _chatSubscription?.cancel();
    _pulseController.dispose();
    _comboScaleController.dispose();
    _comboDismissTimer?.cancel();
    _videoController?.dispose();
    _msgController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final double seatSize = _activeSeatCount > 20 ? 38.0 : 44.0;
    final int crossCount = _activeSeatCount > 20 ? 6 : (_activeSeatCount > 12 ? 5 : 4);

return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.keyboard_arrow_down, color: primaryBrown, size: 28),
          tooltip: "Minimize Room",
          onPressed: () {
            _agoraService.minimizeRoom();
            Navigator.pop(context);
          },
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _roomSettings.roomName,
              style: const TextStyle(fontSize: 15, color: primaryBrown, fontWeight: FontWeight.bold),
            ),
            Row(
              children: [
                Text("UID: $_myUid", style: const TextStyle(fontSize: 11, color: Colors.black54)),
                if (_roomSettings.password != null) ...[
                  const SizedBox(width: 6),
                  const Icon(Icons.lock, color: accentGold, size: 12),
                ],
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.share, color: primaryBrown),
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(Icons.power_settings_new, color: Colors.redAccent),
            onPressed: () async {
              await _agoraService.leaveRoom();
              if (mounted) Navigator.pop(context);
            },
          ),
        ],
      ),
      body: Stack(
        children: [
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
                              childAspectRatio: 0.82,
                            ),
                            itemBuilder: (context, index) {
                              final seatIndex = index + 1;
                              final isTaken = _seats[seatIndex] != null;
                              final isSpeaking = (_mySeatIndex == seatIndex && !_isMicMuted) ||
                                  _speakingSeatIndices.contains(seatIndex);
                              final isMuted = _mutedSeats.contains(seatIndex) || _roomSettings.isAllMicClosed;
                              final giftPoints = _seatGiftsCount[seatIndex];

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
                                            color: cardBg,
                                            border: Border.all(
                                              color: _isAllSeatsTargeted
                                                  ? accentGold
                                                  : (isSpeaking
                                                      ? const Color(0xFF107C41)
                                                      : borderColor),
                                              width: _isAllSeatsTargeted
                                                  ? 2.5
                                                  : (isSpeaking ? (2.0 + pulse * 1.5) : 1),
                                            ),
                                            boxShadow: [
                                              BoxShadow(
                                                color: _isAllSeatsTargeted
                                                    ? accentGold.withOpacity(0.4)
                                                    : (isSpeaking
                                                        ? const Color(0xFF107C41).withOpacity(0.3)
                                                        : Colors.black.withOpacity(0.04)),
                                                blurRadius: 6 + (pulse * 4),
                                                spreadRadius: 1,
                                              ),
                                            ],
                                          ),
                                          child: Center(
                                            child: isTaken
                                                ? (isMuted
                                                    ? const Icon(Icons.mic_off, color: Colors.redAccent, size: 18)
                                                    : const Icon(Icons.person, color: primaryBrown, size: 20))
                                                : (isMuted
                                                    ? const Icon(Icons.lock, color: Colors.black26, size: 16)
                                                    : const Icon(Icons.chair, color: Colors.black38, size: 18)),
                                          ),
                                        );
                                      },
                                    ),
                                    const SizedBox(height: 3),
                                    Text(
                                      isTaken ? _seats[seatIndex]! : "$seatIndex",
                                      style: TextStyle(
                                        color: isTaken ? primaryBrown : Colors.black54,
                                        fontSize: 9.5,
                                        fontWeight: FontWeight.bold,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    if (giftPoints > 0)
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFFBF4E6),
                                          borderRadius: BorderRadius.circular(6),
                                          border: Border.all(color: accentGold.withOpacity(0.5)),
                                        ),
                                        child: Text(

"$giftPoints",
                                          style: const TextStyle(color: accentGold, fontSize: 8.5, fontWeight: FontWeight.bold),
                                        ),
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
                Container(
                  height: 90,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  alignment: Alignment.bottomLeft,
                  child: ListView.builder(
                    reverse: true,
                    itemCount: _chatMessages.length,
                    itemBuilder: (context, index) {
                      final msg = _chatMessages[_chatMessages.length - 1 - index];
                      final isSystem = msg.startsWith("System:") || msg.startsWith("Announcement:") || msg.startsWith("Red Packet");

                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 2.0),
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: isSystem ? const Color(0xFFFBF4E6) : cardBg.withOpacity(0.9),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: borderColor),
                            ),
                            child: Text(
                              msg,
                              style: TextStyle(
                                color: isSystem ? accentGold : primaryBrown,
                                fontSize: 11,
                                fontWeight: isSystem ? FontWeight.bold : FontWeight.normal,
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: cardBg,
                    border: const Border(top: BorderSide(color: borderColor)),
                  ),
                  child: Row(
                    children: [
                      IconButton(
                        icon: Icon(
                          _isMicMuted ? Icons.mic_off : Icons.mic,
                          color: _isMicMuted ? Colors.redAccent : const Color(0xFF107C41),
                        ),
                        onPressed: _toggleMic,
                      ),
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14),
                          decoration: BoxDecoration(
                            color: bgColor,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: borderColor),
                          ),
                          child: TextField(
                            controller: _msgController,
                            style: const TextStyle(color: primaryBrown, fontSize: 13),
                            decoration: const InputDecoration(
                              hintText: "Say Hello...",
                              hintStyle: TextStyle(color: Colors.black38),

border: InputBorder.none,
                            ),
                            onSubmitted: (val) async {
                              final txt = val.trim();
                              if (txt.isNotEmpty) {
                                _msgController.clear();
                                await FirebaseFirestore.instance
                                    .collection('rooms')
                                    .doc(channelName)
                                    .collection('chats')
                                    .add({
                                  'sender': _myDisplayName,
                                  'text': txt,
                                  'timestamp': FieldValue.serverTimestamp(),
                                });
                              }
                            },
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.sports_esports, color: accentGold),
                        onPressed: () {
                          showModalBottomSheet(
                            context: context,
                            backgroundColor: Colors.transparent,
                            builder: (context) => Container(
                              padding: const EdgeInsets.all(20.0),
                              decoration: const BoxDecoration(
                                color: bgColor,
                                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                              ),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Center(
                                    child: Container(
                                      width: 44,
                                      height: 4,
                                      decoration: BoxDecoration(color: Colors.black26, borderRadius: BorderRadius.circular(2)),
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  const Text(
                                    "Select Mini-Game",
                                    style: TextStyle(
                                      color: primaryBrown,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 17,
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  Container(
                                    decoration: BoxDecoration(color: cardBg, borderRadius: BorderRadius.circular(16), border: Border.all(color: borderColor)),
                                    child: Column(
                                      children: [
                                        ListTile(
                                          leading: const CircleAvatar(
                                            backgroundColor: bgColor,
                                            child: Text("🎰", style: TextStyle(fontSize: 20)),
                                          ),
                                          title: const Text(
                                            "Lucky Spin Wheel",
                                            style: TextStyle(color: primaryBrown, fontWeight: FontWeight.bold, fontSize: 13),
                                          ),
                                          trailing: const Icon(Icons.chevron_right, color: primaryBrown),
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
                                        const Divider(height: 1, color: borderColor),
                                        ListTile(
                                          leading: const CircleAvatar(
                                            backgroundColor: bgColor,
                                            child: Text("🃏", style: TextStyle(fontSize: 20)),
                                          ),
                                          title: const Text(
                                            "Teen Patti (3 Cards)",
                                            style: TextStyle(color: primaryBrown, fontWeight: FontWeight.bold, fontSize: 13),
                                          ),
                                          trailing: const Icon(Icons.chevron_right, color: primaryBrown),
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
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.card_giftcard, color: accentGold),
                        onPressed: _openGiftSheet,
                      ),
                      IconButton(
                        icon: const Icon(Icons.grid_view_rounded, color: primaryBrown),
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
                                      onKickSeat: (idx) async {
                                        setState(() {
                                          _seats[idx] = null;
                                          _seatUids[idx] = null;
                                        });
                                        await FirebaseFirestore.instance.collection('rooms').doc(channelName).set({
                                          'seats': _seats,
                                          'seatUids': _seatUids,
                                        }, SetOptions(merge: true));
                                      },
                                      onUpdateSettings: (newSet) {
                                        setState(() {
                                          _roomSettings = newSet;
                                          _activeSeatCount = newSet.seatCount;
                                          _seats = List.filled(_activeSeatCount, null);
                                          _seatUids = List.filled(_activeSeatCount, null);
                                          _seatGiftsCount = List.filled(_activeSeatCount, 0);
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
          
          if (_activeComboData != null)
            Positioned(
              left: 16,
              top: 110,
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: cardBg,
                      borderRadius: BorderRadius.circular(30),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.08),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                      border: Border.all(color: accentGold, width: 1.5),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const CircleAvatar(
                          radius: 16,
                          backgroundColor: bgColor,
                          child: Icon(Icons.person, color: primaryBrown, size: 20),
                        ),
                        const SizedBox(width: 8),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              _activeComboData!.senderName,

style: const TextStyle(
                                color: primaryBrown,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              "Sent ${_activeComboData!.giftName} to ${_activeComboData!.targetName}",
                              style: const TextStyle(
                                color: accentGold,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _activeComboData!.giftIcon,
                          style: const TextStyle(fontSize: 26),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  ScaleTransition(
                    scale: _comboScaleAnimation,
                    child: Text(
                      "x${_activeComboData!.comboCount}",
                      style: const TextStyle(
                        fontSize: 30,
                        fontWeight: FontWeight.w900,
                        fontStyle: FontStyle.italic,
                        color: accentGold,
                      ),
                    ),
                  ),
                ],
              ),
            ),

          if (_isPlayingVideo && _videoController != null && _videoController!.value.isInitialized)
            Positioned.fill(
              child: IgnorePointer(
                ignoring: true,
                child: FittedBox(
                  fit: BoxFit.cover,
                  child: SizedBox(
                    width: _videoController!.value.size.width,
                    height: _videoController!.value.size.height,
                    child: VideoPlayer(_videoController!),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildHostSeat() {
    final isTaken = _seats[0] != null;
    final isSpeaking = (_mySeatIndex == 0 && !_isMicMuted) || _speakingSeatIndices.contains(0);
    final hostGifts = _seatGiftsCount[0];

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
                  color: cardBg,
                  border: Border.all(
                    color: _isAllSeatsTargeted
                        ? accentGold
                        : (isSpeaking ? const Color(0xFF107C41) : accentGold),
                    width: _isAllSeatsTargeted ? 3.0 : (isSpeaking ? (2.5 + pulse * 1.5) : 2),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: _isAllSeatsTargeted
                          ? accentGold.withOpacity(0.5)
                          : (isSpeaking
                              ? const Color(0xFF107C41).withOpacity(0.4)
                              : accentGold.withOpacity(0.25)),
                      blurRadius: 10 + (pulse * 6),
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: Center(
                  child: isTaken
                      ? const Icon(Icons.person, color: accentGold, size: 34)

: const Icon(Icons.chair, color: accentGold, size: 30),
                ),
              );
            },
          ),
          const SizedBox(height: 4),
          Text(
            isTaken ? _seats[0]! : "Host (1)",
            style: const TextStyle(
              color: primaryBrown,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
          if (hostGifts > 0)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
              decoration: BoxDecoration(
                color: const Color(0xFFFBF4E6),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: accentGold.withOpacity(0.5)),
              ),
              child: Text(
                "$hostGifts",
                style: const TextStyle(color: accentGold, fontSize: 9, fontWeight: FontWeight.bold),
              ),
            ),
        ],
      ),
    );
  }
}
