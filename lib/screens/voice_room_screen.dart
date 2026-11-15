import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:http/http.dart' as http;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:audioplayers/audioplayers.dart';
import '../services/agora_service.dart';
import '../widgets/gift_dialog.dart';
import '../widgets/fullscreen_gift_animator.dart';
import '../widgets/room_tools_sheet.dart';

class RoomChatMessage {
  final String id;
  final String sender;
  final String message;
  final bool isSystem;

  RoomChatMessage({
    required this.id,
    required this.sender,
    required this.message,
    this.isSystem = false,
  });
}

class CenterFlyingGift {
  final String id;
  final String asset;
  final String icon;
  final int targetSeatIndex;
  final bool isAll;
  final AnimationController controller;
  final Animation<double> flightAnimation;

  CenterFlyingGift({
    required this.id,
    required this.asset,
    this.icon = "🎁",
    required this.targetSeatIndex,
    required this.isAll,
    required this.controller,
    required this.flightAnimation,
  });
}

class VoiceRoomScreen extends StatefulWidget {
  final String roomTitle;
  final String roomId;
  final String hostName;
  final int userNumericId;
  final String userUid;
  final String userName;

  const VoiceRoomScreen({
    super.key,
    required this.roomTitle,
    required this.roomId,
    required this.hostName,
    required this.userNumericId,
    this.userUid = "user_guest_id",
    this.userName = "Me",
  });

  @override
  State<VoiceRoomScreen> createState() => _VoiceRoomScreenState();
}

class _VoiceRoomScreenState extends State<VoiceRoomScreen>
    with TickerProviderStateMixin {
  static const Color kShiroBg = Color(0xFFF3E2C7);
  static const Color kShiroCard = Color(0xFFE7CFA8);
  static const Color kBlackText = Color(0xFF1A1410);
  static const Color kSubBlack = Color(0xFF3E3124);
  static const Color kGoldBlackTop = Color(0xFF2D2216);
  static const Color kGoldBlackBottom = Color(0xFF120D08);
  static const Color kGoldBorder = Color(0xFFD49B42);
  static const Color kGoldBright = Color(0xFFFFD700);

  final AgoraService _agoraService = AgoraService();
  final User? _currentUser = FirebaseAuth.instance.currentUser;
  final Random _random = Random();
  IO.Socket? _socket;
  final AudioPlayer _audioPlayer = AudioPlayer();

  final StreamController<FullscreenGiftEvent> _fullscreenAnimStreamController =
      StreamController.broadcast();

  bool _isMuted = false;
  int? _mySeatIndex;
  int _totalSeats = 30;
  late List<String?> _seats;
  late List<int> _seatGifts;
  late List<bool> _seatMutes;
  bool _isConnecting = true;

  int _myCoins = 0;
  int _myPoints = 0;
  StreamSubscription? _walletSubscription;
  StreamSubscription? _pointsSubscription;
  StreamSubscription? _roomLiveSubscription;

  final List<CenterFlyingGift> _activeFlyingGifts = [];

  bool _showComboButton = false;
  int _comboCount = 0;
  Timer? _comboTimer;
  late AnimationController _comboRingController;
  Map<String, dynamic>? _lastSentGiftConfig;

  String? _luckyWinToast;
  Timer? _luckyWinToastTimer;

  String? _entryBannerText;
  late AnimationController _entryMarqueeController;
  late Animation<Offset> _entryMarqueeAnimation;

  final Set<int> _speakingSeatIndices = {};
  final List<int> _allowedSeatOptions = [6, 12, 20, 25, 30];

  final List<RoomChatMessage> _messages = [];
  final TextEditingController _chatController = TextEditingController();
  final ScrollController _chatScrollController = ScrollController();

  final String _serverUrl = "https://nile-token-server.onrender.com";

  int _currentRocketLevel = 1;
  Timer? _rocketBannerTimer;

  String get _resolvedUid {
    if (_currentUser != null) return _currentUser!.uid;
    if (widget.userUid.isNotEmpty) return widget.userUid;
    return "user_guest_id";
  }

int _getColsForSeats(int count) {
    if (count <= 6) return 3;
    if (count <= 12) return 4;
    if (count <= 20) return 5;
    if (count <= 25) return 5;
    return 6;
  }

  @override
  void initState() {
    super.initState();
    _seats = List.filled(30, null);
    _seatGifts = List.filled(30, 0);
    _seatMutes = List.filled(30, false);

    _comboRingController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    );

    _entryMarqueeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3200),
    );
    _entryMarqueeAnimation = Tween(
      begin: const Offset(1.3, 0.0),
      end: const Offset(-1.3, 0.0),
    ).animate(CurvedAnimation(
      parent: _entryMarqueeController,
      curve: Curves.easeInOut,
    ));

    _entryMarqueeController.addStatusListener((status) {
      if (status == AnimationStatus.completed && mounted) {
        setState(() => _entryBannerText = null);
      }
    });

    _startRocketBannerRotation();
    _initWalletSync();
    _initPointsSync();
    _initRoomRealtimeSync();
    _setupAgora();
    _connectSocket();
  }

  void _triggerEntryNotice(String name) {
    if (!mounted) return;
    setState(() {
      _entryBannerText = "🎉 $name joined the party room!";
    });
    _entryMarqueeController.reset();
    _entryMarqueeController.forward();
  }

  void _showCompactWinBadge(int wonCoins) {
    if (wonCoins <= 0 || !mounted) return;
    _luckyWinToastTimer?.cancel();
    setState(() {
      _luckyWinToast = "+$wonCoins Coins Won!";
    });
    _luckyWinToastTimer = Timer(const Duration(seconds: 2), () {
      if (mounted) setState(() => _luckyWinToast = null);
    });
  }

  void _startRocketBannerRotation() {
    _rocketBannerTimer?.cancel();
    _rocketBannerTimer = Timer.periodic(const Duration(seconds: 6), (timer) {
      if (mounted) {
        setState(() {
          _currentRocketLevel = (_currentRocketLevel % 5) + 1;
        });
      }
    });
  }

  void _initWalletSync() {
    _walletSubscription = FirebaseFirestore.instance
        .collection('users')
        .doc(_resolvedUid)
        .snapshots()
        .listen((snapshot) {
      if (snapshot.exists && snapshot.data() != null && mounted) {
        final data = snapshot.data()!;
        setState(() {
          _myCoins = (data['coins'] as num?)?.toInt() ?? 0;
        });
      }
    });
  }

  void _initPointsSync() {
    _pointsSubscription = FirebaseFirestore.instance
        .collection('users')
        .doc(_resolvedUid)
        .snapshots()
        .listen((snapshot) {
      if (snapshot.exists && snapshot.data() != null && mounted) {
        final data = snapshot.data()!;
        setState(() {
          _myPoints = (data['points'] as num?)?.toInt() ?? 0;
        });
      }
    });
  }

  void _initRoomRealtimeSync() {
    _roomLiveSubscription = FirebaseFirestore.instance
        .collection('rooms')
        .doc(widget.roomId)
        .snapshots()
        .listen((snapshot) {
      if (!snapshot.exists) return;
      if (snapshot.data() == null) return;
      if (!mounted) return;

      final data = snapshot.data()!;
      setState(() {
        if (data.containsKey('seatMap') && data['seatMap'] is Map) {
          final Map incomingMap = data['seatMap'];
          for (int i = 0; i < 30; i++) {
            final val = incomingMap['$i'];
            _seats[i] = (val is String && val.isNotEmpty) ? val : null;
            if (_seats[i] == null) {
              _seatGifts[i] = 0;
            }
          }
          final myIdx = _seats.indexOf(widget.userName);
          _mySeatIndex = myIdx != -1 ? myIdx : null;
        }

        if (data.containsKey('seatGifts') && data['seatGifts'] is List) {
          final List incoming = data['seatGifts'];
          for (int i = 0; i < incoming.length && i < 30; i++) {
            _seatGifts[i] = (incoming[i] as num).toInt();
          }
        }
      });
    });
  }

void _playCoinSound() async {
    try {
      final AudioPlayer player = AudioPlayer();
      await player.setPlayerMode(PlayerMode.mediaPlayer);
      await player.setVolume(1.0);
      try {
        await player.play(AssetSource('sounds/Five_win.mp3'));
      } catch (_) {
        await player.play(AssetSource('sounds/five_win.mp3'));
      }
      player.onPlayerComplete.listen((_) {
        player.dispose();
      });
    } catch (_) {}
  }

  void _addChatMessage(RoomChatMessage message) {
    if (!mounted) return;
    setState(() {
      _messages.add(message);
      if (_messages.length > 80) {
        _messages.removeAt(0);
      }
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_chatScrollController.hasClients) {
        _chatScrollController.animateTo(
          _chatScrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _saveRoomGiftsToFirestore() async {
    try {
      await FirebaseFirestore.instance
          .collection('rooms')
          .doc(widget.roomId)
          .set({
        'seatGifts': _seatGifts,
        'lastUpdated': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (_) {}
  }

  Future<void> _syncSeatToFirestore({
    required int seatIndex,
    int? oldSeatIndex,
    required bool isLeaving,
  }) async {
    try {
      final Map<String, dynamic> seatUpdates = {};
      if (isLeaving) {
        seatUpdates['$seatIndex'] = FieldValue.delete();
      } else {
        if (oldSeatIndex != null && oldSeatIndex != seatIndex) {
          seatUpdates['$oldSeatIndex'] = FieldValue.delete();
        }
        seatUpdates['$seatIndex'] = widget.userName;
      }

      await FirebaseFirestore.instance
          .collection('rooms')
          .doc(widget.roomId)
          .set({
        'seatMap': seatUpdates,
        'seatGifts': _seatGifts,
        'lastUpdated': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (_) {}
  }

  void _connectSocket() {
    try {
      _socket = IO.io(
        _serverUrl,
        IO.OptionBuilder()
            .setTransports(['websocket', 'polling'])
            .enableAutoConnect()
            .build(),
      );

      _socket!.connect();

      _socket!.onConnect((_) {
        _socket!.emit('join_room', {
          'roomId': widget.roomId,
          'userName': widget.userName,
          'hostName': widget.hostName,
        });
      });

      _socket!.on('user_joined_room', (data) {
        if (!mounted) return;
        if (data == null) return;
        final joinedName = data['userName'] ?? "New User";
        _triggerEntryNotice(joinedName);
      });

      _socket!.on('room_state_sync', (data) {
        if (!mounted) return;
        if (data == null) return;
        setState(() {
          if (data['seats'] != null) {
            final List incomingSeats = data['seats'];
            for (int i = 0; i < incomingSeats.length && i < 30; i++) {
              final sUser = incomingSeats[i] as String?;
              if (sUser != null && sUser.isNotEmpty) {
                _seats[i] = sUser;
              }
              if (_seats[i] == widget.userName) {
                _mySeatIndex = i;
              }
            }
          }
        });
      });

      _socket!.on('seat_state_updated', (data) {
        if (!mounted) return;
        if (data == null) return;
        final int index = (data['seatIndex'] as num).toInt();
        final String? user = data['userName'] as String?;

        setState(() {
          if (user != null) {
            final oldIndex = _seats.indexOf(user);
            if (oldIndex != -1 && oldIndex != index) {
              _seatGifts[index] = _seatGifts[oldIndex];
              _seatGifts[oldIndex] = 0;
              _seats[oldIndex] = null;
            }
          }

if (data['seats'] != null) {
            final List incomingSeats = data['seats'];
            for (int i = 0; i < incomingSeats.length && i < 30; i++) {
              _seats[i] = incomingSeats[i] as String?;
              if (_seats[i] == null) {
                _seatGifts[i] = 0;
              }
            }
          } else {
            _seats[index] = user;
            if (user == null) {
              _seatGifts[index] = 0;
            }
          }

          if (user == null) {
            _speakingSeatIndices.remove(index);
          }

          if (user == widget.userName) {
            _mySeatIndex = index;
            _isMuted = false;
          } else if (_mySeatIndex == index && user != widget.userName) {
            _mySeatIndex = null;
            _isMuted = true;
          }
        });
        _saveRoomGiftsToFirestore();
      });

      _socket!.on('gift_broadcast', (data) {
        if (!mounted) return;
        if (data == null) return;
        final sender = data['senderName'] ?? "Someone";
        final isAll = data['isAll'] == true;
        final isLucky = data['isLucky'] == true;
        final giftName = data['giftName'] ?? "Gift";
        final giftCost = (data['giftCost'] as num?)?.toInt() ?? 0;
        final giftAsset = (data['giftAsset'] ?? "").toString();
        final giftIcon = (data['giftIcon'] ?? "🎁").toString();

        final List targets = (data['targetSeats'] as List?) ?? [];
        final targetIndex = (data['targetSeatIndex'] as num?)?.toInt() ?? 0;

        if (!isLucky && giftCost >= 500) {
          _fullscreenAnimStreamController.add(
            FullscreenGiftEvent(
              giftId: "",
              giftName: giftName,
              asset: giftAsset,
              senderName: sender,
            ),
          );
        }

        if (sender != widget.userName) {
          setState(() {
            if (isAll) {
              for (int i = 0; i < _totalSeats; i++) {
                if (_seats[i] != null) {
                  _seatGifts[i] += giftCost;
                  _triggerCenterGiftAnimation(giftAsset, i, icon: giftIcon, isToAll: true);
                }
              }
            } else if (targets.isNotEmpty) {
              for (var t in targets) {
                final idx = (t as num).toInt();
                if (idx >= 0 && idx < 30 && _seats[idx] != null) {
                  _seatGifts[idx] += giftCost;
                  _triggerCenterGiftAnimation(giftAsset, idx, icon: giftIcon);
                }
              }
            } else {
              if (_seats[targetIndex] != null) {
                _seatGifts[targetIndex] += giftCost;
                _triggerCenterGiftAnimation(giftAsset, targetIndex, icon: giftIcon);
              }
            }
          });
          _saveRoomGiftsToFirestore();
        }

        if (!isLucky) {
          _addChatMessage(
            RoomChatMessage(
              id: "${DateTime.now().microsecondsSinceEpoch}_$sender",
              sender: "System",
              message: isAll ? "$sender sent $giftName to All Mics!" : "$sender sent $giftName!",
              isSystem: true,
            ),
          );
        }
      });

      _socket!.on('chat_message_received', (data) {
        if (!mounted) return;
        if (data == null) return;
        final sender = data['sender'] ?? 'User';
        if (sender == widget.userName) return;

        _addChatMessage(RoomChatMessage(
          id: "${DateTime.now().microsecondsSinceEpoch}",
          sender: sender,
          message: data['message'] ?? '',
          isSystem: data['isSystem'] ?? false,
        ));
      });
    } catch (_) {}
  }

  Future<String?> _fetchToken({
    required String channelName,
    required int uid,
    required bool isPublisher,
  }) async {
    try {

final role = isPublisher ? "publisher" : "subscriber";
      final uri = Uri.parse(
          "$_serverUrl/rtcToken?channelName=$channelName&uid=$uid&role=$role");
      final response = await http.get(uri).timeout(const Duration(seconds: 12));
      if (response.statusCode == 200) {
        final Map data = jsonDecode(response.body);
        return data['token'] as String?;
      }
    } catch (_) {}
    return null;
  }

  Future<void> _setupAgora() async {
    try {
      final status = await Permission.microphone.request();
      if (!status.isGranted && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Microphone permission required")),
        );
      }

      await _agoraService.initEngine(
        onUserJoined: (uid) {},
        onUserOffline: (uid) {},
        onVolumeChanged: (speakers) {
          if (!mounted) return;
          setState(() {
            _speakingSeatIndices.clear();
            for (var speaker in speakers) {
              final vol = speaker.volume ?? 0;
              if (vol > 4) {
                bool isMe = speaker.uid == 0;
                if (speaker.uid == widget.userNumericId) isMe = true;
                if (isMe && _mySeatIndex != null && !_isMuted && !_seatMutes[_mySeatIndex!]) {
                  _speakingSeatIndices.add(_mySeatIndex!);
                }
              }
            }
          });
        },
      );

      final dynamicToken = await _fetchToken(
        channelName: widget.roomId,
        uid: widget.userNumericId,
        isPublisher: true,
      );

      await _agoraService.joinRoom(
        channelId: widget.roomId,
        uid: widget.userNumericId,
        token: dynamicToken,
        isSpeaker: true,
      );
    } catch (_) {}

    if (mounted) setState(() => _isConnecting = false);
  }

  void _triggerCenterGiftAnimation(
    String asset,
    int targetSeatIndex, {
    String icon = "🎁",
    bool isToAll = false,
  }) {
    final controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );

    final animation = CurvedAnimation(
      parent: controller,
      curve: Curves.fastOutSlowIn,
    );

    final giftItem = CenterFlyingGift(
      id: "${DateTime.now().microsecondsSinceEpoch}_${Random().nextInt(9999)}_$targetSeatIndex",
      asset: asset,
      icon: icon,
      targetSeatIndex: targetSeatIndex,
      isAll: isToAll,
      controller: controller,
      flightAnimation: animation,
    );

    setState(() {
      _activeFlyingGifts.add(giftItem);
    });

    controller.forward().then((_) {
      if (mounted) {
        setState(() {
          _activeFlyingGifts.removeWhere((g) => g.id == giftItem.id);
        });
        controller.dispose();
      }
    });
  }

  void _handleSeatTap(int index) async {
    // 1. Leave seat if tapping own seat
    if (_mySeatIndex == index) {
      setState(() {
        _seats[index] = null;
        _seatGifts[index] = 0;
        _speakingSeatIndices.remove(index);
        _mySeatIndex = null;
        _isMuted = true;
      });

      try {
        _agoraService.switchRole(isSpeaker: false);
        _agoraService.setMicrophoneMute(true);
      } catch (_) {}

      _syncSeatToFirestore(seatIndex: index, isLeaving: true);

      if (_socket != null && _socket!.connected) {
        _socket!.emit('seat_action', {
          'roomId': widget.roomId,
          'seatIndex': index,
          'userName': widget.userName,
          'isLeaving': true,
        });
      }
      return;
    }

    // 2. Check if occupied by another user
    if (_seats[index] != null && _seats[index] != widget.userName) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("ይህ ወንበር ተይዟል (Seat occupied)")),
      );
      return;
    }

// 3. Request microphone permission
    final status = await Permission.microphone.request();
    if (!status.isGranted) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("ወንበር ላይ ለመውጣት የማይክሮፎን ፈቃድ ይፍቀዱ")),
        );
      }
      return;
    }

    // 4. Immediately seat user locally (0ms delay)
    final int? oldIndex = _seats.indexOf(widget.userName) != -1
        ? _seats.indexOf(widget.userName)
        : _mySeatIndex;

    setState(() {
      if (oldIndex != null && oldIndex != index) {
        _seatGifts[index] = _seatGifts[oldIndex];
        _seatGifts[oldIndex] = 0;
        _seats[oldIndex] = null;
        _speakingSeatIndices.remove(oldIndex);
      }
      _seats[index] = widget.userName;
      _mySeatIndex = index;
      _isMuted = false;
      _seatMutes[index] = false;
    });

    try {
      _agoraService.switchRole(isSpeaker: true);
      _agoraService.setMicrophoneMute(false);
    } catch (_) {}

    _syncSeatToFirestore(
      seatIndex: index,
      oldSeatIndex: oldIndex,
      isLeaving: false,
    );

    if (_socket != null && _socket!.connected) {
      _socket!.emit('seat_action', {
        'roomId': widget.roomId,
        'seatIndex': index,
        'userName': widget.userName,
        'isLeaving': false,
      });
    }
  }

  void _toggleMute() {
    setState(() {
      _isMuted = !_isMuted;
      if (_mySeatIndex != null) {
        _seatMutes[_mySeatIndex!] = _isMuted;
        if (_isMuted) _speakingSeatIndices.remove(_mySeatIndex!);
      }
    });
    try {
      _agoraService.setMicrophoneMute(_isMuted);
    } catch (_) {}
  }

  void _changeSeatCount(int newCount) {
    setState(() {
      _totalSeats = newCount;
      if (_mySeatIndex != null && _mySeatIndex! >= newCount) {
        _handleSeatTap(_mySeatIndex!);
      }
    });
  }

  void _sendMessage() {
    final text = _chatController.text.trim();
    if (text.isEmpty) return;

    _addChatMessage(RoomChatMessage(
      id: "${DateTime.now().microsecondsSinceEpoch}",
      sender: widget.userName,
      message: text,
      isSystem: false,
    ));

    if (_socket != null && _socket!.connected) {
      _socket!.emit('send_chat', {
        'roomId': widget.roomId,
        'sender': widget.userName,
        'message': text,
      });
    }

    _chatController.clear();
  }

  void _startComboTimer() {
    _comboTimer?.cancel();
    _comboRingController.reset();
    _comboRingController.forward();

    _comboTimer = Timer(const Duration(seconds: 3), () {
      if (mounted) {
        setState(() {
          _showComboButton = false;
          _comboCount = 0;
        });
      }
    });
  }

  int _rollLuckyWin(int unitPrice) {
    int roll = _random.nextInt(1000) + 1;
    if (roll <= 2) return unitPrice * 500;
    if (roll <= 10) return unitPrice * 100;
    if (roll <= 30) return unitPrice * 50;
    if (roll <= 90) return unitPrice * 10;
    if (roll <= 210) return unitPrice * 5;
    return 0;
  }

  void _onComboTapped() {
    if (_lastSentGiftConfig == null) return;

    final config = _lastSentGiftConfig!;
    final bool isLucky = config['isLucky'] == true;
    final List<int> targets = List<int>.from(config['targetSeats']);
    final bool isAll = config['isAll'] == true;
    final int unitPrice = (config['unitPrice'] as num).toInt();
    final int sendCost = isLucky ? unitPrice : (config['cost'] as num).toInt();
    final int seatCount = isAll
        ? _seats.where((s) => s != null).length
        : targets.length;
    final int totalSpend = sendCost * max(1, seatCount);

    if (_myCoins < totalSpend) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Insufficient coins balance!")),
      );
      return;
    }

    final int nextCombo = _comboCount + 1;
    setState(() {
      _comboCount = nextCombo;
    });

int wonCoins = 0;
    if (isLucky) {
      for (int i = 0; i < max(1, seatCount); i++) {
        wonCoins += _rollLuckyWin(unitPrice);
      }
      if (wonCoins > 0 || (nextCombo % 5 == 0)) {
        _playCoinSound();
      }
      if (wonCoins > 0) {
        _showCompactWinBadge(wonCoins);
      }
    } else {
      _playCoinSound();
    }

    final int netChange = -totalSpend + wonCoins;
    FirebaseFirestore.instance.collection('users').doc(_resolvedUid).set({
      'coins': FieldValue.increment(netChange),
      'wealthExp': FieldValue.increment(totalSpend),
    }, SetOptions(merge: true)).catchError((_) {});

    final double rate = isLucky ? 0.04 : 0.70;
    final int ptsPerSeat = max(1, (sendCost * rate).round());
    final List<int> activeTargets = isAll
        ? [for (int i = 0; i < _totalSeats; i++) if (_seats[i] != null) i]
        : targets;

    for (final seatIdx in activeTargets) {
      if (seatIdx >= 0 && seatIdx < 30 && _seats[seatIdx] != null) {
        final targetUid = _seats[seatIdx] == widget.userName ? _resolvedUid : _seats[seatIdx]!;
        FirebaseFirestore.instance.collection('users').doc(targetUid).set({
          'points': FieldValue.increment(ptsPerSeat),
          'charmExp': FieldValue.increment(ptsPerSeat),
        }, SetOptions(merge: true)).catchError((_) {});
      }
    }

    _executeMultiSeatSend(
      targetSeats: targets,
      isAll: isAll,
      cost: sendCost,
      unitPrice: unitPrice,
      name: config['name'],
      asset: config['asset'],
      icon: config['icon'] ?? "🎁",
      isLucky: isLucky,
      wonCoins: wonCoins,
      fromCombo: true,
    );

    _startComboTimer();
  }

  void _openGiftSheet() async {
    final seatedList = [];
    for (int i = 0; i < _totalSeats; i++) {
      if (_seats[i] != null) {
        seatedList.add({
          'seatIndex': i,
          'uid': _seats[i] == widget.userName ? _resolvedUid : _seats[i]!,
          'name': _seats[i]!,
          'avatar': '',
        });
      }
    }

    final GiftSendResult? result = await showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => GiftDialog(
        roomId: widget.roomId,
        activeUsers: seatedList,
        userCoins: _myCoins,
        onCoinsUpdated: (newCoins) {
          setState(() {
            _myCoins = newCoins;
          });
        },
      ),
    );

    if (result != null) {
      final bool isLucky = result.gift.isLucky;
      final String playAsset = result.gift.playAsset;

      if (isLucky) {
        if (result.wonCoins > 0) {
          _showCompactWinBadge(result.wonCoins);
        }
      } else {
        _fullscreenAnimStreamController.add(
          FullscreenGiftEvent(
            giftId: result.gift.id,
            giftName: "${result.gift.name} x${result.multiplier}",
            asset: playAsset,
            senderName: widget.userName,
          ),
        );
      }

      _executeMultiSeatSend(
        targetSeats: result.targetSeatIndices,
        isAll: result.isAll,
        cost: result.rawGiftCostPerSeat,
        unitPrice: result.gift.price,
        name: "${result.gift.name} x${result.multiplier}",
        asset: playAsset,
        icon: result.gift.icon,
        isLucky: isLucky,
        wonCoins: result.wonCoins,
        luckyMultiplier: isLucky ? result.multiplier : 0,
        fromCombo: false,
      );
    }
  }

  void _executeMultiSeatSend({
    required List<int> targetSeats,
    required bool isAll,
    required int cost,
    required int unitPrice,
    required String name,
    required String asset,
    String icon = "🎁",
    bool isLucky = false,
    int wonCoins = 0,
    int luckyMultiplier = 0,
    bool fromCombo = false,
  }) {
    if (targetSeats.isEmpty && !isAll) return;

    final bool isFifthMilestone = isLucky && fromCombo && (_comboCount % 5 == 0);
    final int burstCount = isFifthMilestone ? 3 : 1;

    setState(() {
      if (!fromCombo) {
        _comboCount = 1;
        _showComboButton = true;
      }

if (isAll) {
        for (int i = 0; i < _totalSeats; i++) {
          if (_seats[i] != null) {
            _seatGifts[i] += cost;
            for (int b = 0; b < burstCount; b++) {
              _triggerCenterGiftAnimation(asset, i, icon: icon, isToAll: true);
            }
          }
        }
      } else {
        for (final seatIdx in targetSeats) {
          if (seatIdx >= 0 && seatIdx < 30 && _seats[seatIdx] != null) {
            _seatGifts[seatIdx] += cost;
            for (int b = 0; b < burstCount; b++) {
              _triggerCenterGiftAnimation(asset, seatIdx, icon: icon);
            }
          }
        }
      }
    });

    _saveRoomGiftsToFirestore();

    _lastSentGiftConfig = {
      'targetSeats': targetSeats,
      'isAll': isAll,
      'cost': cost,
      'unitPrice': unitPrice,
      'name': name,
      'asset': asset,
      'icon': icon,
      'isLucky': isLucky,
    };

    _startComboTimer();

    if (_socket != null && _socket!.connected) {
      _socket!.emit('send_gift', {
        'roomId': widget.roomId,
        'senderName': widget.userName,
        'targetSeats': targetSeats,
        'isAll': isAll,
        'giftName': name,
        'giftCost': cost,
        'giftAsset': asset,
        'giftIcon': icon,
        'comboCount': _comboCount,
        'isLucky': isLucky,
        'wonCoins': wonCoins,
        'luckyMultiplier': luckyMultiplier,
      });
    }
  }

  @override
  void dispose() {
    _rocketBannerTimer?.cancel();
    _luckyWinToastTimer?.cancel();
    _walletSubscription?.cancel();
    _pointsSubscription?.cancel();
    _roomLiveSubscription?.cancel();
    _comboRingController.dispose();
    _entryMarqueeController.dispose();
    _comboTimer?.cancel();
    _audioPlayer.dispose();
    _fullscreenAnimStreamController.close();
    for (var g in _activeFlyingGifts) {
      g.controller.dispose();
    }
    _socket?.disconnect();
    _socket?.dispose();
    _agoraService.leaveRoom();
    _chatController.dispose();
    _chatScrollController.dispose();
    super.dispose();
  }

  Widget _buildSingleSeat({
    required int index,
    required double seatDimension,
    required double nameFontSize,
    required double badgeFontSize,
  }) {
    final occupier = _seats[index];
    final isOccupied = occupier != null;
    final isSpeaking = _speakingSeatIndices.contains(index);
    final isMuted = _seatMutes[index];
    final giftsCount = _seatGifts[index];
    final bool isHostSeat = index == 0;
    final bool isCrownSeat = index >= 1 && index <= 6;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => _handleSeatTap(index),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.center,
            children: [
              if (isHostSeat && isOccupied)
                Positioned(
                  top: -seatDimension * 0.32,
                  child: Image.asset(
                    'assets/images/wikimediaimages-candy-2201920.jpg',
                    width: seatDimension * 0.72,
                    errorBuilder: (c, e, s) => const SizedBox.shrink(),
                  ),
                ),
              if (isCrownSeat && isOccupied)
                Positioned(
                  top: -seatDimension * 0.28,
                  child: Image.asset(
                    'assets/images/weekly_lovers_heart_value.webp',
                    width: seatDimension * 0.58,
                    errorBuilder: (c, e, s) => const SizedBox.shrink(),
                  ),
                ),
              Container(
                width: seatDimension,
                height: seatDimension,
                decoration: BoxDecoration(

shape: BoxShape.circle,
                  gradient: const LinearGradient(
                    colors: [kGoldBlackTop, kGoldBlackBottom],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  border: Border.all(
                    color: isSpeaking
                        ? const Color(0xFF00B8D4)
                        : (isOccupied ? kGoldBright : kGoldBorder),
                    width: isSpeaking ? 2.6 : (isOccupied ? 2.0 : 1.3),
                  ),
                  boxShadow: [
                    if (isSpeaking)
                      BoxShadow(
                        color: const Color(0xFF00B8D4).withOpacity(0.55),
                        blurRadius: 10,
                        spreadRadius: 2,
                      )
                    else
                      BoxShadow(
                        color: Colors.black.withOpacity(0.25),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                  ],
                ),
                child: Center(
                  child: Icon(
                    isOccupied ? Icons.person : Icons.chair_rounded,
                    color: isOccupied ? kGoldBright : kGoldBorder,
                    size: seatDimension * 0.46,
                  ),
                ),
              ),
              if (isOccupied)
                Positioned(
                  bottom: -2,
                  right: -2,
                  child: Container(
                    padding: EdgeInsets.all(seatDimension * 0.05),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isMuted ? Colors.redAccent : const Color(0xFF107C41),
                      border: Border.all(color: kShiroBg, width: 1.2),
                    ),
                    child: Icon(
                      isMuted ? Icons.mic_off : Icons.mic,
                      size: (seatDimension * 0.22).clamp(9.0, 15.0),
                      color: Colors.white,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 2),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 2),
            child: Text(
              isOccupied ? occupier : "${index + 1}",
              style: TextStyle(
                color: kBlackText,
                fontSize: nameFontSize,
                fontWeight: FontWeight.bold,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Container(
            margin: const EdgeInsets.only(top: 1.0),
            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
            decoration: BoxDecoration(
              color: (giftsCount > 0 && isOccupied) ? kGoldBlackBottom : kShiroCard,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: kGoldBorder, width: 0.8),
            ),
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text("🎁", style: TextStyle(fontSize: badgeFontSize * 0.92)),
                  const SizedBox(width: 2),
                  Text(
                    isOccupied ? "$giftsCount" : "0",
                    style: TextStyle(
                      color: (giftsCount > 0 && isOccupied) ? kGoldBright : kBlackText,
                      fontSize: badgeFontSize,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final int crossAxis = _getColsForSeats(_totalSeats);
    final int rowCount = (_totalSeats / crossAxis).ceil();
    final size = MediaQuery.of(context).size;

final int comboTier = (_comboCount ~/ 5) + 1;
    final double comboScale = (1.0 + ((comboTier - 1) * 0.08)).clamp(1.0, 1.45);

    return Scaffold(
      backgroundColor: kShiroBg,
      appBar: AppBar(
        backgroundColor: kShiroBg,
        elevation: 0,
        iconTheme: const IconThemeData(color: kBlackText),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.roomTitle,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: kBlackText,
              ),
            ),
            Text(
              _isConnecting
                  ? "Connecting..."
                  : "ID: ${widget.roomId} • My ID: ${widget.userNumericId}",
              style: const TextStyle(
                fontSize: 11,
                color: kSubBlack,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        actions: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            margin: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              color: kGoldBlackBottom,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: kGoldBorder, width: 1.2),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.stars, color: kGoldBright, size: 12),
                const SizedBox(width: 4),
                Text(
                  "$_myPoints",
                  style: const TextStyle(
                    color: kGoldBright,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 4),
          PopupMenuButton(
            icon: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                border: Border.all(color: kGoldBorder, width: 1.3),
                borderRadius: BorderRadius.circular(12),
                color: kGoldBlackBottom,
              ),
              child: Row(
                children: [
                  const Icon(Icons.event_seat, color: kGoldBright, size: 14),
                  const SizedBox(width: 4),
                  Text(
                    "$_totalSeats",
                    style: const TextStyle(
                      color: kGoldBright,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            color: kGoldBlackTop,
            onSelected: (int count) => _changeSeatCount(count),
            itemBuilder: (context) => _allowedSeatOptions
                .map((int count) => PopupMenuItem(
                      value: count,
                      child: Text(
                        "$count Seats Layout",
                        style: TextStyle(
                          color: count == _totalSeats ? kGoldBright : Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ))
                .toList(),
          ),
          IconButton(
            icon: const Icon(Icons.grid_view_rounded, color: kBlackText),
            onPressed: () {
              RoomToolsSheet.show(
                context,
                roomId: widget.roomId,
                roomTitle: widget.roomTitle,
                userName: widget.userName,
                isHost: true,
                isVoiceOn: !_isMuted,

onToggleVoice: _toggleMute,
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.power_settings_new, color: Colors.redAccent),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              children: [
                Expanded(
                  flex: 6,
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final double areaW = constraints.maxWidth - 12.0;
                      final double areaH = constraints.maxHeight - 4.0;
                      final double cellW = areaW / crossAxis;
                      final double cellH = areaH / rowCount;

                      final double nameFontSize =
                          (cellH * 0.13).clamp(8.5, 15.0);
                      final double badgeFontSize =
                          (cellH * 0.11).clamp(7.5, 13.0);
                      final double reservedLabelH =
                          nameFontSize + badgeFontSize + 14.0;

                      final double maxByHeight =
                          (cellH - reservedLabelH).clamp(28.0, 125.0);
                      final double maxByWidth =
                          (cellW * 0.72).clamp(28.0, 125.0);
                      final double seatDimension = min(maxByHeight, maxByWidth);

                      return Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6.0, vertical: 2.0),
                        child: Column(
                          children: List.generate(rowCount, (r) {
                            return Expanded(
                              child: Row(
                                children: List.generate(crossAxis, (c) {
                                  final int seatIdx = (r * crossAxis) + c;
                                  if (seatIdx >= _totalSeats) {
                                    return const Expanded(child: SizedBox.shrink());
                                  }
                                  return Expanded(
                                    child: Center(
                                      child: _buildSingleSeat(
                                        index: seatIdx,
                                        seatDimension: seatDimension,
                                        nameFontSize: nameFontSize,
                                        badgeFontSize: badgeFontSize,
                                      ),
                                    ),
                                  );
                                }),
                              ),
                            );
                          }),
                        ),
                      );
                    },
                  ),
                ),

                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
                  child: Container(
                    height: 36,
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [kGoldBlackTop, kGoldBlackBottom],
                      ),
                      borderRadius: BorderRadius.circular(18),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.25),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                      border: Border.all(color: kGoldBorder, width: 1.2),

),
                    child: Row(
                      children: [
                        const Icon(Icons.rocket_launch, color: kGoldBright, size: 18),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            "Super Rocket LV.$_currentRocketLevel Active! 🚀",
                            style: const TextStyle(
                              color: kGoldBright,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                          decoration: BoxDecoration(
                            color: kGoldBorder,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            "LV.$_currentRocketLevel",
                            style: const TextStyle(
                              color: kBlackText,
                              fontSize: 9.5,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                Expanded(
                  flex: 3,
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                    child: ListView.builder(
                      controller: _chatScrollController,
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.only(bottom: 6),
                      itemCount: _messages.length,
                      itemBuilder: (context, index) {
                        final item = _messages[index];
                        return Align(
                          alignment: Alignment.centerLeft,
                          child: Container(
                            margin: const EdgeInsets.symmetric(vertical: 2.5),
                            padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 5.0),
                            decoration: BoxDecoration(
                              color: item.isSystem
                                  ? const Color(0xFFDFC08E)
                                  : kShiroCard,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: kGoldBorder.withOpacity(0.65),
                                width: 0.9,
                              ),
                            ),
                            child: RichText(
                              text: TextSpan(
                                children: [
                                  if (item.isSystem)
                                    const WidgetSpan(
                                      child: Padding(
                                        padding: EdgeInsets.only(right: 4.0),
                                        child: Icon(
                                          Icons.campaign,
                                          color: kBlackText,
                                          size: 13,
                                        ),
                                      ),
                                    ),
                                  TextSpan(
                                    text: "${item.sender}: ",
                                    style: const TextStyle(

color: kBlackText,
                                      fontWeight: FontWeight.w900,
                                      fontSize: 12,
                                    ),
                                  ),
                                  TextSpan(
                                    text: item.message,
                                    style: const TextStyle(
                                      color: kBlackText,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),

                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: const BoxDecoration(
                    color: kShiroCard,
                    border: Border(
                      top: BorderSide(color: kGoldBorder, width: 1.0),
                    ),
                    borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: _mySeatIndex != null ? kGoldBlackBottom : Colors.black12,
                        ),
                        child: IconButton(
                          icon: Icon(
                            _isMuted ? Icons.mic_off : Icons.mic,
                            color: _mySeatIndex != null
                                ? (_isMuted ? Colors.redAccent : kGoldBright)
                                : kSubBlack,
                            size: 24,
                          ),
                          onPressed: _mySeatIndex != null ? _toggleMute : null,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14),
                          decoration: BoxDecoration(
                            color: kShiroBg,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: kGoldBorder),
                          ),
                          child: TextField(
                            controller: _chatController,
                            style: const TextStyle(
                              color: kBlackText,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                            decoration: const InputDecoration(
                              hintText: "Say something...",
                              hintStyle: TextStyle(color: kSubBlack),
                              border: InputBorder.none,
                              isDense: true,
                              contentPadding: EdgeInsets.symmetric(vertical: 10),
                            ),
                            onSubmitted: (_) => _sendMessage(),
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Container(
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: kGoldBlackBottom,
                        ),
                        child: IconButton(
                          icon: const Icon(Icons.send_rounded, color: kGoldBright, size: 20),

onPressed: _sendMessage,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Container(
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: kGoldBlackBottom,
                        ),
                        child: IconButton(
                          icon: const Icon(Icons.card_giftcard, color: kGoldBright, size: 22),
                          onPressed: _openGiftSheet,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            if (_luckyWinToast != null)
              Positioned(
                top: 12,
                left: 0,
                right: 0,
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
                    decoration: BoxDecoration(
                      color: kGoldBlackBottom,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: kGoldBright, width: 1.4),
                    ),
                    child: Text(
                      _luckyWinToast!,
                      style: const TextStyle(
                        color: kGoldBright,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ),
              ),

            if (_entryBannerText != null)
              Positioned(
                bottom: 75,
                left: 0,
                right: 0,
                child: SlideTransition(
                  position: _entryMarqueeAnimation,
                  child: Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [kGoldBlackTop, kGoldBlackBottom],
                        ),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: kGoldBright, width: 1.2),
                      ),
                      child: Text(
                        _entryBannerText!,
                        style: const TextStyle(
                          color: kGoldBright,
                          fontSize: 11.5,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
              ),

            ..._activeFlyingGifts.map((gift) {
              return AnimatedBuilder(
                animation: gift.controller,
                builder: (context, child) {
                  final t = gift.flightAnimation.value;

                  final centerX = size.width * 0.5;
                  final centerY = size.height * 0.42;

                  final col = gift.targetSeatIndex % crossAxis;
                  final row = gift.targetSeatIndex ~/ crossAxis;
                  final colWidth = (size.width - 12.0) / crossAxis;
                  final rowHeight = (size.height * 0.52) / rowCount;

                  final targetX = 6.0 + (col + 0.5) * colWidth;
                  final targetY = 8.0 + (row + 0.5) * rowHeight;

                  final currentX = centerX + (targetX - centerX) * t;
                  final currentY = centerY + (targetY - centerY) * t;
                  final scale = 1.45 - (0.85 * t);

                  final bool isImageAsset = gift.asset.isNotEmpty &&
                      !gift.asset.toLowerCase().endsWith('.mp4');

return Positioned(
                    left: currentX - 35,
                    top: currentY - 35,
                    child: Opacity(
                      opacity: (1.0 - (t * 0.25)).clamp(0.0, 1.0),
                      child: Transform.scale(
                        scale: scale.clamp(0.4, 1.8),
                        child: isImageAsset
                            ? Image.asset(
                                gift.asset,
                                width: 68,
                                height: 68,
                                fit: BoxFit.contain,
                                errorBuilder: (c, e, s) => Text(
                                  gift.icon,
                                  style: const TextStyle(fontSize: 44),
                                ),
                              )
                            : Text(
                                gift.icon,
                                style: const TextStyle(fontSize: 44),
                              ),
                      ),
                    ),
                  );
                },
              );
            }),

            FullscreenGiftAnimator(
              giftStream: _fullscreenAnimStreamController.stream,
            ),

            if (_showComboButton)
              Positioned(
                bottom: 65,
                right: 20,
                child: Transform.scale(
                  scale: comboScale,
                  child: GestureDetector(
                    onTap: _onComboTapped,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        SizedBox(
                          width: 74,
                          height: 74,
                          child: AnimatedBuilder(
                            animation: _comboRingController,
                            builder: (context, child) {
                              return CircularProgressIndicator(
                                value: 1.0 - _comboRingController.value,
                                strokeWidth: 3.5,
                                color: kGoldBright,
                                backgroundColor: Colors.black26,
                              );
                            },
                          ),
                        ),
                        Container(
                          width: 62,
                          height: 62,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: LinearGradient(
                              colors: comboTier >= 2
                                  ? [const Color(0xFFB71C1C), const Color(0xFF4A0E0E)]
                                  : [kGoldBlackTop, kGoldBlackBottom],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            border: Border.all(
                              color: kGoldBright,
                              width: comboTier >= 2 ? 2.2 : 1.5,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.45),
                                blurRadius: 10,
                                spreadRadius: 1,
                              ),
                            ],
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                comboTier >= 2 ? "LV.$comboTier" : "Combo",
                                style: const TextStyle(

color: kGoldBright,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 11,
                                ),
                              ),
                              Text(
                                "x$_comboCount",
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w900,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
} 
