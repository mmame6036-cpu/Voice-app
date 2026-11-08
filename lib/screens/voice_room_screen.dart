import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:http/http.dart' as http;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:audioplayers/audioplayers.dart';
import '../services/agora_service.dart';
import '../widgets/gift_dialog.dart';
import '../widgets/floating_gift_combo.dart';
import '../widgets/room_tools_sheet.dart';
import 'wallet_screen.dart';

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
  final int targetSeatIndex;
  final bool isAll;
  final AnimationController controller;
  final Animation<double> flightAnimation;

  CenterFlyingGift({
    required this.id,
    required this.asset,
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
  final AgoraService _agoraService = AgoraService();
  IO.Socket? _socket;
  final AudioPlayer _audioPlayer = AudioPlayer();

  final StreamController<GiftSendEvent> _giftOverlayStreamController =
      StreamController<GiftSendEvent>.broadcast();

  bool _isMuted = false;
  int? _mySeatIndex;
  int _totalSeats = 30;
  late List<String?> _seats;
  late List<int> _seatGifts;
  late List<bool> _seatMutes;
  bool _isConnecting = true;

  int _myCoins = 0;
  StreamSubscription? _walletSubscription;
  StreamSubscription? _roomLiveSubscription;

  late AnimationController _waveController;
  final List<CenterFlyingGift> _activeFlyingGifts = [];

  bool _showComboButton = false;
  int _comboCount = 0;
  Timer? _comboTimer;
  late AnimationController _comboRingController;
  Map<String, dynamic>? _lastSentGiftConfig;

  // Global Win Banner
  bool _showFloatingBanner = false;
  Timer? _bannerTimer;
  int _currentWonRebate = 0;
  String _currentWinnerName = "";

  bool _showX100Badge = false;
  late AnimationController _x100BadgeController;

  // User Entry Marquee Banner
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

  @override
  void initState() {
    super.initState();
    _seats = List.filled(30, null);
    _seatGifts = List.filled(30, 0);
    _seatMutes = List.filled(30, false);

    _waveController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    )..repeat(reverse: true);

    _comboRingController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    );

    _x100BadgeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );

_x100BadgeController.addStatusListener((status) {
      if (status == AnimationStatus.completed && mounted) {
        setState(() => _showX100Badge = false);
      }
    });

    _entryMarqueeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3200),
    );
    _entryMarqueeAnimation = Tween<Offset>(
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

  void _startRocketBannerRotation() {
    _rocketBannerTimer?.cancel();
    _rocketBannerTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
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
        .doc(widget.userUid)
        .snapshots()
        .listen((snapshot) {
      if (snapshot.exists && snapshot.data() != null) {
        final data = snapshot.data()!;
        if (mounted) {
          setState(() {
            _myCoins = (data['coins'] as num?)?.toInt() ?? 0;
          });
        }
      }
    });
  }

  void _initRoomRealtimeSync() {
    _roomLiveSubscription = FirebaseFirestore.instance
        .collection('rooms')
        .doc(widget.roomId)
        .snapshots()
        .listen((snapshot) {
      if (!snapshot.exists  snapshot.data() == null  !mounted) return;
      final data = snapshot.data()!;

      if (data.containsKey('seatGifts')) {
        final List incoming = data['seatGifts'];
        setState(() {
          for (int i = 0; i < incoming.length && i < 30; i++) {
            _seatGifts[i] = (incoming[i] as num).toInt();
          }
        });
      }

      if (data.containsKey('latestWin')) {
        final winData = data['latestWin'] as Map<String, dynamic>?;
        if (winData != null) {
          final timestamp = (winData['time'] as num?)?.toInt() ?? 0;
          final nowMs = DateTime.now().millisecondsSinceEpoch;
          if (nowMs - timestamp < 4000) {
            final winner = winData['winnerName'] ?? "Player";
            final rebate = (winData['amount'] as num?)?.toInt() ?? 0;
            final combo = (winData['comboCount'] as num?)?.toInt() ?? 0;

            if (_currentWinnerName != winner || _currentWonRebate != rebate) {
              setState(() {
                _currentWinnerName = winner;
                _currentWonRebate = rebate;
                _showFloatingBanner = true;
                if (combo >= 100) {
                  _showX100Badge = true;
                  _x100BadgeController.reset();
                  _x100BadgeController.forward();
                }
              });

              _playCoinSound();

              _bannerTimer?.cancel();
              _bannerTimer = Timer(const Duration(seconds: 4), () {
                if (mounted) setState(() => _showFloatingBanner = false);
              });
            }
          }
        }
      }
    });
  }

  void _playCoinSound() async {
    try {
      final player = AudioPlayer();
      await player.setVolume(1.0);
      await player.play(AssetSource('sounds/five_win.mp3'));
      player.onPlayerComplete.listen((_) {
        player.dispose();
      });
    } catch (e) {
      debugPrint("Audio Error: $e");
    }
  }

void _addChatMessage(RoomChatMessage message) {
    if (!mounted) return;
    setState(() {
      _messages.add(message);
      if (_messages.length > 100) {
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

  void _connectSocket() {
    try {
      _socket = IO.io(
        _serverUrl,
        IO.OptionBuilder()
            .setTransports(['websocket'])
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
        if (!mounted || data == null) return;
        final joinedName = data['userName'] ?? "New User";
        _triggerEntryNotice(joinedName);
      });

      _socket!.on('room_state_sync', (data) {
        if (!mounted || data == null) return;
        setState(() {
          if (data['seats'] != null) {
            final List incomingSeats = data['seats'];
            for (int i = 0; i < incomingSeats.length && i < 30; i++) {
              _seats[i] = incomingSeats[i] as String?;
              if (_seats[i] == null) {
                _seatGifts[i] = 0;
              }
              if (_seats[i] == widget.userName) {
                _mySeatIndex = i;
                _agoraService.switchRole(isSpeaker: true);
              }
            }
          }
        });
      });

      _socket!.on('seat_state_updated', (data) {
        if (!mounted || data == null) return;
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
            _agoraService.switchRole(isSpeaker: true);
          } else if (_mySeatIndex == index && user != widget.userName) {
            _mySeatIndex = null;
            _agoraService.switchRole(isSpeaker: false);
          }
        });
        _saveRoomGiftsToFirestore();
      });

      _socket!.on('gift_broadcast', (data) {
        if (!mounted || data == null) return;
        final isAll = data['isAll'] ?? false;
        final sender = data['senderName'] ?? "Someone";
        final giftName = data['giftName'] ?? "Gift";

final giftCost = (data['giftCost'] as num?)?.toInt() ?? 0;
        final giftAsset = data['giftAsset'] ?? 'assets/images/wikimediaimages-candy-2201920.jpg';
        final giftIcon = data['giftIcon'] ?? "🎁";
        final isLucky = data['isLucky'] ?? false;
        final wonCoins = (data['wonCoins'] as num?)?.toInt() ?? 0;
        final luckyMultiplier = (data['luckyMultiplier'] as num?)?.toInt() ?? 0;
        final combo = (data['comboCount'] as num?)?.toInt() ?? 1;

        final List targets = (data['targetSeats'] as List?) ?? [];
        final targetIndex = (data['targetSeatIndex'] as num?)?.toInt() ?? 0;

        _giftOverlayStreamController.add(
          GiftSendEvent(
            senderName: sender,
            targetName: isAll ? "All Mics" : "Host",
            giftName: giftName,
            giftIcon: giftIcon,
            comboCount: combo,
            isLucky: isLucky,
            wonCoins: wonCoins,
            luckyMultiplier: luckyMultiplier,
          ),
        );

        setState(() {
          if (isAll) {
            for (int i = 0; i < _totalSeats; i++) {
              if (_seats[i] != null) {
                _seatGifts[i] += giftCost;
                _triggerCenterGiftAnimation(giftAsset.toString(), i, isToAll: true);
              }
            }
          } else if (targets.isNotEmpty) {
            for (var t in targets) {
              final idx = (t as num).toInt();
              if (idx >= 0 && idx < 30 && _seats[idx] != null) {
                _seatGifts[idx] += giftCost;
                _triggerCenterGiftAnimation(giftAsset.toString(), idx);
              }
            }
          } else {
            if (_seats[targetIndex] != null) {
              _seatGifts[targetIndex] += giftCost;
              _triggerCenterGiftAnimation(giftAsset.toString(), targetIndex);
            }
          }
        });

        _addChatMessage(
          RoomChatMessage(
            id: "${DateTime.now().microsecondsSinceEpoch}_$sender",
            sender: "System",
            message: isAll ? "$sender sent $giftName to All Mics!" : "$sender sent $giftName!",
            isSystem: true,
          ),
        );

        _saveRoomGiftsToFirestore();
      });

      _socket!.on('chat_message_received', (data) {
        if (!mounted || data == null) return;
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
        final Map<String, dynamic> data = jsonDecode(response.body);
        return data['token'] as String?;
      }
    } catch (_) {}
    return null;
  }

  Future<void> _setupAgora() async {
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
              if (speaker.uid == 0 || speaker.uid == widget.userNumericId) {
                if (_mySeatIndex != null && !_isMuted && !_seatMutes[_mySeatIndex!]) {
                  _speakingSeatIndices.add(_mySeatIndex!);
                }
              }
            }
          }
        });
      },
    );

    final dynamicToken = await _fetchToken(
      channelName: widget.roomId,
      uid: widget.userNumericId,
      isPublisher: false,
    );

    await _agoraService.joinRoom(
      channelId: widget.roomId,
      uid: widget.userNumericId,
      token: dynamicToken,
      isSpeaker: false,
    );

    if (mounted) setState(() => _isConnecting = false);
  }

  void _triggerCenterGiftAnimation(String asset, int targetSeatIndex, {bool isToAll = false}) {
    final controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );

    final animation = CurvedAnimation(
      parent: controller,
      curve: Curves.fastOutSlowIn,
    );

    final giftItem = CenterFlyingGift(
      id: "${DateTime.now().microsecondsSinceEpoch}_${Random().nextInt(9999)}_$targetSeatIndex",
      asset: asset,
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
    if (_mySeatIndex == index) {
      _socket?.emit('seat_action', {
        'roomId': widget.roomId,
        'seatIndex': index,
        'userName': widget.userName,
        'isLeaving': true,
      });
      return;
    }

    if (_seats[index] != null && _seats[index] != widget.userName) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Seat occupied")),
      );
      return;
    }

    final status = await Permission.microphone.request();
    if (!status.isGranted) return;

    _socket?.emit('seat_action', {
      'roomId': widget.roomId,
      'seatIndex': index,
      'userName': widget.userName,
      'isLeaving': false,
    });
  }

  void _toggleMute() {
    setState(() {
      _isMuted = !_isMuted;
      if (_mySeatIndex != null) {
        _seatMutes[_mySeatIndex!] = _isMuted;
        if (_isMuted) _speakingSeatIndices.remove(_mySeatIndex!);
      }
    });
    _agoraService.setMicrophoneMute(_isMuted);
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

  void _triggerMilestoneReward(int giftCost) {
    int rewardMultiplier = 2;
    if (_comboCount >= 100) {
      rewardMultiplier = 20;
    } else if (_comboCount >= 60) {
      rewardMultiplier = 8;
    } else if (_comboCount >= 30) {
      rewardMultiplier = 4;
    }

    final rebate = giftCost * rewardMultiplier;

setState(() {
      _currentWinnerName = widget.userName;
      _currentWonRebate = rebate;
      _myCoins += rebate;
      _showFloatingBanner = true;
    });

    _playCoinSound();

    FirebaseFirestore.instance
        .collection('users')
        .doc(widget.userUid)
        .update({
      'coins': FieldValue.increment(rebate),
    }).catchError((_) {});

    FirebaseFirestore.instance
        .collection('rooms')
        .doc(widget.roomId)
        .set({
      'latestWin': {
        'winnerName': widget.userName,
        'amount': rebate,
        'comboCount': _comboCount,
        'time': DateTime.now().millisecondsSinceEpoch,
      }
    }, SetOptions(merge: true)).catchError((_) {});

    if (_comboCount >= 100) {
      setState(() => _showX100Badge = true);
      _x100BadgeController.reset();
      _x100BadgeController.forward();
    }

    _bannerTimer?.cancel();
    _bannerTimer = Timer(const Duration(seconds: 4), () {
      if (mounted) setState(() => _showFloatingBanner = false);
    });
  }

  void _onComboTapped() {
    if (_lastSentGiftConfig == null) return;
    setState(() {
      _comboCount += 1;
    });

    final config = _lastSentGiftConfig!;
    final giftCost = config['cost'] as int;

    if (_comboCount % 5 == 0) {
      _triggerMilestoneReward(giftCost);
    }

    _executeMultiSeatSend(
      targetSeats: List<int>.from(config['targetSeats']),
      isAll: config['isAll'],
      cost: giftCost,
      name: config['name'],
      asset: config['asset'],
      icon: config['icon'] ?? "🎁",
      isLucky: config['isLucky'] ?? false,
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
          'uid': _seats[i]!,
          'name': _seats[i]!,
          'avatar': '',
        });
      }
    }

    final result = await showModalBottomSheet<GiftSendResult>(
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
      _giftOverlayStreamController.add(
        GiftSendEvent(
          senderName: widget.userName,
          targetName: result.isAll ? "All Mics" : "Host",
          giftName: result.gift.name,
          giftIcon: result.gift.icon,
          comboCount: result.multiplier,
          isLucky: result.gift.isLucky,
          wonCoins: result.wonCoins,
          luckyMultiplier: result.gift.isLucky ? result.multiplier : 0,
        ),
      );

      if (result.wonCoins > 0) {
        _playCoinSound();
        setState(() {
          _currentWinnerName = widget.userName;
          _currentWonRebate = result.wonCoins;
          _showFloatingBanner = true;
        });

        _bannerTimer?.cancel();
        _bannerTimer = Timer(const Duration(seconds: 4), () {
          if (mounted) setState(() => _showFloatingBanner = false);
        });
      }

      _executeMultiSeatSend(
        targetSeats: result.targetSeatIndices,
        isAll: result.isAll,
        cost: result.gift.price * result.multiplier,
        name: "${result.gift.name} x${result.multiplier}",
        asset: result.gift.imageAsset,
        icon: result.gift.icon,
        isLucky: result.gift.isLucky,
        wonCoins: result.wonCoins,
        luckyMultiplier: result.gift.isLucky ? result.multiplier : 0,
        fromCombo: false,
      );
    }
  }

  void _executeMultiSeatSend({
    required List<int> targetSeats,
    required bool isAll,
    required int cost,
    required String name,
    required String asset,
    String icon = "🎁",
    bool isLucky = false,
    int wonCoins = 0,
    int luckyMultiplier = 0,
    bool fromCombo = false,
  }) {
    if (targetSeats.isEmpty && !isAll) return;

setState(() {
      if (!fromCombo) {
        _comboCount = 1;
        _showComboButton = true;
      }

      if (isAll) {
        for (int i = 0; i < _totalSeats; i++) {
          if (_seats[i] != null) {
            _seatGifts[i] += cost;
            _triggerCenterGiftAnimation(asset, i, isToAll: true);
          }
        }
      } else {
        for (final seatIdx in targetSeats) {
          if (seatIdx >= 0 && seatIdx < 30 && _seats[seatIdx] != null) {
            _seatGifts[seatIdx] += cost;
            _triggerCenterGiftAnimation(asset, seatIdx);
          }
        }
      }
    });

    _saveRoomGiftsToFirestore();

    _lastSentGiftConfig = {
      'targetSeats': targetSeats,
      'isAll': isAll,
      'cost': cost,
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
    _walletSubscription?.cancel();
    _roomLiveSubscription?.cancel();
    _waveController.dispose();
    _comboRingController.dispose();
    _x100BadgeController.dispose();
    _entryMarqueeController.dispose();
    _comboTimer?.cancel();
    _bannerTimer?.cancel();
    _audioPlayer.dispose();
    _giftOverlayStreamController.close();
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

  @override
  Widget build(BuildContext context) {
    final int crossAxis = _totalSeats <= 12 ? 4 : (_totalSeats <= 20 ? 5 : 6);
    final double seatDimension = _totalSeats > 20 ? 44.0 : 50.0;
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: const Color(0xFF090614),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.roomTitle, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
            Text(
              _isConnecting ? "Connecting..." : "ID: ${widget.roomId} • My ID: ${widget.userNumericId}",
              style: TextStyle(fontSize: 11, color: _isConnecting ? const Color(0xFFFFD700) : Colors.white54),
            ),
          ],
        ),
        actions: [
          PopupMenuButton<int>(
            icon: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                border: Border.all(color: const Color(0xFFFFD700), width: 1.2),
                borderRadius: BorderRadius.circular(12),
                color: const Color(0xFF1E1638),
              ),
              child: Row(
                children: [
                  const Icon(Icons.event_seat, color: Color(0xFFFFD700), size: 14),
                  const SizedBox(width: 4),
                  Text("$_totalSeats", style: const TextStyle(color: Color(0xFFFFD700), fontSize: 12, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
            color: const Color(0xFF1F1A3A),
            onSelected: _changeSeatCount,
            itemBuilder: (context) => _allowedSeatOptions
                .map((count) => PopupMenuItem<int>(

value: count,
                      child: Text("$count Seats Layout",
                          style: TextStyle(color: count == _totalSeats ? const Color(0xFFFFD700) : Colors.white)),
                    ))
                .toList(),
          ),
          IconButton(
            icon: const Icon(Icons.grid_view_rounded, color: Color(0xFFFFD700)),
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
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10.0),
                    child: GridView.builder(
                      physics: const BouncingScrollPhysics(),
                      itemCount: _totalSeats,
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: crossAxis,
                        mainAxisSpacing: 10,
                        crossAxisSpacing: 6,
                        childAspectRatio: 0.68,
                      ),
                      itemBuilder: (context, index) {
                        final occupier = _seats[index];
                        final isOccupied = occupier != null;
                        final isSpeaking = _speakingSeatIndices.contains(index);
                        final isMuted = _seatMutes[index];
                        final giftsCount = _seatGifts[index];

                        final bool isHostSeat = index == 0;
                        final bool isCrownSeat = index >= 1 && index <= 6;

                        return GestureDetector(
                          onTap: () => _handleSeatTap(index),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Stack(
                                clipBehavior: Clip.none,
                                alignment: Alignment.center,
                                children: [
                                  if (isHostSeat && isOccupied)
                                    Positioned(
                                      top: -15,
                                      child: Image.asset('assets/images/wikimediaimages-candy-2201920.jpg', width: 36, errorBuilder: (c, e, s) => const SizedBox.shrink()),
                                    ),
                                  if (isCrownSeat && isOccupied)
                                    Positioned(
                                      top: -14,
                                      child: Image.asset('assets/images/weekly_lovers_heart_value.webp', width: 28, errorBuilder: (c, e, s) => const SizedBox.shrink()),
                                    ),
                                  AnimatedBuilder(
                                    animation: _waveController,
                                    builder: (context, child) {
                                      final wave = _waveController.value;
                                      return Container(
                                        width: seatDimension,
                                        height: seatDimension,
                                        decoration: BoxDecoration(

shape: BoxShape.circle,
                                          color: isOccupied ? const Color(0xFF2C2454) : Colors.white.withOpacity(0.06),
                                          boxShadow: isSpeaking
                                              ? [
                                                  BoxShadow(
                                                    color: const Color(0xFF00E5FF).withOpacity(0.5 + (wave * 0.4)),
                                                    blurRadius: 10 + (wave * 8),
                                                    spreadRadius: 2 + (wave * 3),
                                                  ),
                                                ]
                                              : null,
                                        ),
                                        child: Center(
                                          child: Icon(
                                            isOccupied ? Icons.person : Icons.chair,
                                            color: isCrownSeat && isOccupied
                                                ? const Color(0xFFFFD700)
                                                : (isOccupied ? Colors.white : Colors.white24),
                                            size: seatDimension * 0.45,
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                  if (isOccupied)
                                    Positioned(
                                      bottom: -2,
                                      right: -2,
                                      child: Container(
                                        padding: const EdgeInsets.all(2.5),
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: isMuted ? Colors.redAccent : const Color(0xFF00C9A7),
                                        ),
                                        child: Icon(isMuted ? Icons.mic_off : Icons.mic, size: 11, color: Colors.black),
                                      ),
                                    ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                isOccupied ? occupier : "${index + 1}",
                                style: TextStyle(
                                  color: isOccupied ? (isCrownSeat ? const Color(0xFFFFD700) : Colors.white) : Colors.white38,
                                  fontSize: 9.5,
                                  fontWeight: isOccupied ? FontWeight.bold : FontWeight.normal,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              Container(
                                margin: const EdgeInsets.only(top: 1.5),
                                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                                decoration: BoxDecoration(
                                  color: (giftsCount > 0 && isOccupied) ? const Color(0xFFFF1493).withOpacity(0.3) : Colors.white.withOpacity(0.06),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Text("🎁", style: TextStyle(fontSize: 8)),

const SizedBox(width: 2),
                                    Text(isOccupied ? "$giftsCount" : "0",
                                        style: TextStyle(
                                          color: (giftsCount > 0 && isOccupied) ? const Color(0xFFFFD700) : Colors.white38,
                                          fontSize: 8.5,
                                          fontWeight: FontWeight.bold,
                                        )),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ),

                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 600),
                    transitionBuilder: (child, anim) => SlideTransition(
                      position: Tween<Offset>(
                        begin: const Offset(0.0, 0.4),
                        end: Offset.zero,
                      ).animate(anim),
                      child: child,
                    ),
                    child: Container(
                      key: ValueKey<int>(_currentRocketLevel),
                      height: 36,
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF8A2387), Color(0xFFE94057), Color(0xFFF27121)],
                        ),
                        borderRadius: BorderRadius.circular(18),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.orangeAccent.withOpacity(0.35),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                        border: Border.all(color: const Color(0xFFFFD700), width: 1.0),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.rocket_launch, color: Color(0xFFFFD700), size: 18),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              "Super Rocket LV.$_currentRocketLevel Active! 🚀",
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                            decoration: BoxDecoration(
                              color: Colors.black38,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              "LV.$_currentRocketLevel",
                              style: const TextStyle(color: Color(0xFFFFD700), fontSize: 9.5, fontWeight: FontWeight.w900),
                            ),
                          ),
                        ],
                      ),
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
                                  ? const Color(0xFFFFD700).withOpacity(0.18)
                                  : Colors.black.withOpacity(0.55),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: item.isSystem ? const Color(0xFFFFD700).withOpacity(0.3) : Colors.white10,
                                width: 0.8,
                              ),
                            ),
                            child: RichText(
                              text: TextSpan(
                                children: [
                                  if (item.isSystem)
                                    const WidgetSpan(
                                      child: Padding(
                                        padding: EdgeInsets.only(right: 4.0),
                                        child: Icon(Icons.campaign, color: Color(0xFFFFD700), size: 13),
                                      ),
                                    ),
                                  TextSpan(
                                    text: "${item.sender}: ",
                                    style: TextStyle(
                                      color: item.isSystem ? const Color(0xFFFFD700) : const Color(0xFF00E5FF),
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                    ),
                                  ),
                                  TextSpan(
                                    text: item.message,
                                    style: const TextStyle(
                                      color: Colors.white,
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
                    color: Color(0xFF141026),
                    borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                  ),
                  child: Row(
                    children: [
                      IconButton(
                        icon: Icon(
                          _isMuted ? Icons.mic_off : Icons.mic,
                          color: _mySeatIndex != null ? (_isMuted ? Colors.redAccent : const Color(0xFF00E5FF)) : Colors.white24,
                          size: 26,
                        ),
                        onPressed: _mySeatIndex != null ? _toggleMute : null,
                      ),
                      Expanded(
                        child: Container(

padding: const EdgeInsets.symmetric(horizontal: 14),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.08),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: Colors.white12),
                          ),
                          child: TextField(
                            controller: _chatController,
                            style: const TextStyle(color: Colors.white, fontSize: 13),
                            decoration: const InputDecoration(
                              hintText: "Say something...",
                              hintStyle: TextStyle(color: Colors.white38),
                              border: InputBorder.none,
                              isDense: true,
                              contentPadding: EdgeInsets.symmetric(vertical: 10),
                            ),
                            onSubmitted: (_) => _sendMessage(),
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.send_rounded, color: Color(0xFFFFD700), size: 22),
                        onPressed: _sendMessage,
                      ),
                      IconButton(
                        icon: const Icon(Icons.card_giftcard, color: Color(0xFFFFD700), size: 24),
                        onPressed: _openGiftSheet,
                      ),
                    ],
                  ),
                ),
              ],
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
                          colors: [Color(0xFFFF8F00), Color(0xFFFF2A85)],
                        ),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: const Color(0xFFFFD700), width: 1.2),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.5),
                            blurRadius: 8,
                          ),
                        ],
                      ),
                      child: Text(
                        _entryBannerText!,
                        style: const TextStyle(
                          color: Colors.white,
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
                  final centerY = size.height * 0.45;

                  final col = gift.targetSeatIndex % crossAxis;
                  final row = gift.targetSeatIndex ~/ crossAxis;
                  final colWidth = (size.width - 20.0) / crossAxis;

                  final targetX = 10.0 + (col + 0.5) * colWidth;
                  final targetY = 15.0 + (row * (seatDimension + 34.0)) + (seatDimension * 0.5);

                  final currentX = centerX + (targetX - centerX) * t;
                  final currentY = centerY + (targetY - centerY) * t;

                  final scale = 1.4 - (0.85 * t);

return Positioned(
                    left: currentX - 35,
                    top: currentY - 35,
                    child: Opacity(
                      opacity: (1.0 - (t * 0.25)).clamp(0.0, 1.0),
                      child: Transform.scale(
                        scale: scale.clamp(0.4, 1.8),
                        child: Image.asset(
                          gift.asset,
                          width: 70,
                          height: 70,
                          fit: BoxFit.contain,
                          errorBuilder: (c, e, s) => const Icon(
                            Icons.card_giftcard,
                            color: Color(0xFFFFD700),
                            size: 45,
                          ),
                        ),
                      ),
                    ),
                  );
                },
              );
            }),

            Positioned.fill(
              child: IgnorePointer(
                child: FloatingGiftComboOverlay(
                  giftStream: _giftOverlayStreamController.stream,
                ),
              ),
            ),

            if (_showFloatingBanner)
              Positioned(
                bottom: 125,
                left: 16,
                right: 90,
                child: TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0.0, end: 1.0),
                  duration: const Duration(milliseconds: 350),
                  curve: Curves.easeOutBack,
                  builder: (context, value, child) {
                    return Transform.scale(
                      scale: value,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF38006B), Color(0xFF8E00A8), Color(0xFFFFD700)],
                            stops: [0.0, 0.7, 1.0],
                          ),
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(color: const Color(0xFFFFD700), width: 1.5),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 32,
                              height: 32,
                              decoration: const BoxDecoration(
                                shape: BoxShape.circle,
                                color: Color(0xFFFFD700),
                              ),
                              child: Center(
                                child: Text(
                                  _currentWinnerName.isNotEmpty ? _currentWinnerName[0].toUpperCase() : "U",
                                  style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 14),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    _currentWinnerName,
                                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const Text(

"Huge Coin Win! 🎉",
                                    style: TextStyle(color: Color(0xFFFFD700), fontWeight: FontWeight.bold, fontSize: 10),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFF1493),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                "+$_currentWonRebate",
                                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 12),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),

            if (_showX100Badge)
              Center(
                child: AnimatedBuilder(
                  animation: _x100BadgeController,
                  builder: (context, child) {
                    final t = _x100BadgeController.value;
                    final scale = (sin(t * pi) * 1.25).clamp(0.0, 1.3);
                    final opacity = (1.0 - t * 0.4).clamp(0.0, 1.0);

                    return Opacity(
                      opacity: opacity,
                      child: Transform.scale(
                        scale: scale,
                        child: Container(
                          width: 220,
                          height: 220,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: const RadialGradient(
                              colors: [Color(0xFF00E5FF), Color(0xFF2979FF), Color(0xFF1A237E)],
                            ),
                            border: Border.all(color: const Color(0xFFFFD700), width: 6),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF00E5FF).withOpacity(0.9),
                                blurRadius: 40,
                                spreadRadius: 15,
                              ),
                            ],
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.star, color: Color(0xFFFFD700), size: 36),
                              const Text(
                                "x100",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w900,
                                  fontSize: 48,
                                  letterSpacing: 2,
                                  shadows: [
                                    Shadow(color: Colors.black, blurRadius: 10, offset: Offset(2, 2)),
                                  ],
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 3),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFFD700),
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                child: const Text(

"MEGA WINNER",
                                  style: TextStyle(color: Colors.black, fontWeight: FontWeight.w900, fontSize: 11),
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

            if (_showComboButton)
              Positioned(
                bottom: 65,
                right: 20,
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
                              color: const Color(0xFFFFD700),
                              backgroundColor: Colors.white24,
                            );
                          },
                        ),
                      ),
                      Container(
                        width: 62,
                        height: 62,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: const LinearGradient(
                            colors: [Color(0xFFFF2A85), Color(0xFFBA00E5)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFFFF2A85).withOpacity(0.6),
                              blurRadius: 14,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text(
                              "Combo",
                              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                            ),
                            if (_comboCount > 1)
                              Text(
                                "x$_comboCount",
                                style: const TextStyle(color: Color(0xFFFFD700), fontWeight: FontWeight.w900, fontSize: 13),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
