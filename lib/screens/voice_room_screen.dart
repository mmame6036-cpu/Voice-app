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
import '../widgets/continuous_rocket_banner.dart';
import '../widgets/gift_dialog.dart';
import '../widgets/floating_gift_combo.dart';
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

class FlyingGiftItem {
  final String id;
  final String asset;
  final int targetSeatIndex;
  final bool isAll;
  final AnimationController controller;
  final Animation<double> animation;

  FlyingGiftItem({
    required this.id,
    required this.asset,
    required this.targetSeatIndex,
    required this.isAll,
    required this.controller,
    required this.animation,
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
  final StreamController<GiftSendEvent> _comboEventController =
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

  late AnimationController _waveController;
  final List<FlyingGiftItem> _activeFlyingGifts = [];

  bool _showComboButton = false;
  int _comboCount = 0;
  Timer? _comboTimer;
  late AnimationController _comboRingController;
  Map<String, dynamic>? _lastSentGiftConfig;

  bool _showFloatingBanner = false;
  Timer? _bannerTimer;
  int _currentWonRebate = 0;

  bool _showX100Badge = false;
  late AnimationController _x100BadgeController;

  final Set<int> _speakingSeatIndices = {};
  final List<int> _allowedSeatOptions = [6, 12, 20, 25, 30];

  final List<RoomChatMessage> _messages = [];
  final TextEditingController _chatController = TextEditingController();
  final ScrollController _chatScrollController = ScrollController();

  final String _serverUrl = "https://nile-token-server.onrender.com";

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
      duration: const Duration(milliseconds: 1600),
    );

    _x100BadgeController.addStatusListener((status) {
      if (status == AnimationStatus.completed && mounted) {
        setState(() => _showX100Badge = false);
      }
    });

    _initWalletSync();
    _loadRoomGiftsFromFirestore();
    _setupAgora();
    _connectSocket();
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

  void _playCoinSound() {
    try {
      _audioPlayer.stop();
      _audioPlayer.play(
        AssetSource('sounds/five-win.mp3'),
        mode: PlayerMode.lowLatency,
      );
    } catch (_) {}
  }

  void _addExpiringMessage(RoomChatMessage message, {int seconds = 4}) {
    if (!mounted) return;
    setState(() {
      _messages.add(message);
    });
    _scrollToBottom();

    Timer(Duration(seconds: seconds), () {
      if (mounted) {
        setState(() {
          _messages.removeWhere((m) => m.id == message.id);
        });
      }
    });
  }

  Future<void> _loadRoomGiftsFromFirestore() async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('rooms')
          .doc(widget.roomId)
          .get();

      if (doc.exists && doc.data()!.containsKey('seatGifts')) {
        final List incoming = doc.data()!['seatGifts'];
        if (mounted) {
          setState(() {
            for (int i = 0; i < incoming.length && i < 30; i++) {
              _seatGifts[i] = (incoming[i] as num).toInt();
            }
          });
        }
      }
    } catch (_) {}
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

      _socket!.on('room_state_sync', (data) {
        if (!mounted || data == null) return;
        setState(() {
          if (data['seats'] != null) {
            final List incomingSeats = data['seats'];
            for (int i = 0; i < incomingSeats.length && i < 30; i++) {
              _seats[i] = incomingSeats[i] as String?;
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
          if (data['seats'] != null) {
            final List incomingSeats = data['seats'];
            for (int i = 0; i < incomingSeats.length && i < 30; i++) {
              _seats[i] = incomingSeats[i] as String?;
            }
          } else {
            _seats[index] = user;
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
      });

_socket!.on('gift_broadcast', (data) {
        if (!mounted || data == null) return;
        final isAll = data['isAll'] ?? false;
        final sender = data['senderName'] ?? "Someone";
        final giftName = data['giftName'] ?? "Gift";
        final giftCost = (data['giftCost'] as num?)?.toInt() ?? 0;
        final giftAsset = data['giftAsset'] ?? 'assets/images/wikimediaimages-candy-2201920.jpg';
        final targetIndex = (data['targetSeatIndex'] as num?)?.toInt() ?? 0;
        final combo = (data['comboCount'] as num?)?.toInt() ?? 1;

        setState(() {
          if (isAll) {
            for (int i = 0; i < _totalSeats; i++) {
              if (_seats[i] != null) {
                _seatGifts[i] += giftCost;
              }
            }
          } else {
            _seatGifts[targetIndex] += giftCost;
          }
        });

        _playCoinSound();

        final msgText = isAll
            ? "$sender sent $giftName to All Mics!"
            : "$sender sent $giftName to Seat ${targetIndex + 1}!";

        _addExpiringMessage(
          RoomChatMessage(
            id: "${DateTime.now().microsecondsSinceEpoch}_$sender",
            sender: "System",
            message: msgText,
            isSystem: true,
          ),
          seconds: 4,
        );

        _comboEventController.add(GiftSendEvent(
          senderName: sender,
          targetName: isAll ? "All Mics" : "Seat ${targetIndex + 1}",
          giftName: giftName,
          giftIcon: "🎁",
          comboCount: combo,
        ));

        _saveRoomGiftsToFirestore();
        _triggerGiftAnimation(giftAsset.toString(), targetIndex, isToAll: isAll);
      });

      _socket!.on('chat_message_received', (data) {
        if (!mounted || data == null) return;
        setState(() {
          _messages.add(RoomChatMessage(
            id: "${DateTime.now().microsecondsSinceEpoch}",
            sender: data['sender'] ?? 'User',
            message: data['message'] ?? '',
            isSystem: data['isSystem'] ?? false,
          ));
        });
        _scrollToBottom();
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

void _triggerGiftAnimation(String asset, int targetSeatIndex, {bool isToAll = false}) {
    final controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    );

    final animation = CurvedAnimation(
      parent: controller,
      curve: Curves.easeInOutCubic,
    );

    final giftItem = FlyingGiftItem(
      id: "${DateTime.now().microsecondsSinceEpoch}_$targetSeatIndex",
      asset: asset,
      targetSeatIndex: targetSeatIndex,
      isAll: isToAll,
      controller: controller,
      animation: animation,
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

    if (_socket != null && _socket!.connected) {
      _socket!.emit('send_chat', {
        'roomId': widget.roomId,
        'sender': widget.userName,
        'message': text,
      });
    }
    _chatController.clear();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_chatScrollController.hasClients) {
        _chatScrollController.animateTo(
          _chatScrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
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
          _showFloatingBanner = false;
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
      _currentWonRebate = rebate;
      _myCoins += rebate;
      _showFloatingBanner = true;
    });

    FirebaseFirestore.instance
        .collection('users')
        .doc(widget.userUid)
        .update({
      'coins': FieldValue.increment(rebate),
    }).catchError((_) {});

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

    if (_comboCount % 10 == 0) {
      _triggerMilestoneReward(giftCost);
    }

    _executeGiftSend(
      null,
      targetSeat: config['targetSeat'],
      isAll: config['isAll'],
      cost: giftCost,
      multiplier: config['multiplier'],
      name: config['name'],
      asset: config['asset'],
      fromCombo: true,
    );

    _startComboTimer();
  }

  void _openGiftSheet() {
    final List> seatedUsers = [];
    for (int i = 0; i < _totalSeats; i++) {
      if (_seats[i] != null) {
        seatedUsers.add({
          'seatIndex': i,
          'uid': _seats[i]!,
          'name': _seats[i]!,
          'avatar': '',
        });
      }
    }

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => GiftDialog(
        roomId: widget.roomId,
        activeUsers: seatedUsers,
        userCoins: _myCoins,
        onCoinsUpdated: (newCoins) {
          setState(() {
            _myCoins = newCoins;
            _comboCount += 1;
            _showComboButton = true;
          });
          _startComboTimer();
          _comboEventController.add(GiftSendEvent(
            senderName: widget.userName,
            targetName: "Room Members",
            giftName: "Lollipop",
            giftIcon: "🍭",
            comboCount: _comboCount,
          ));
        },
      ),
    );
  }

  void _executeGiftSend(
    BuildContext? ctx, {
    required int? targetSeat,
    required bool isAll,
    required int cost,
    required int multiplier,
    required String name,
    required String asset,
    bool fromCombo = false,
  }) {
    int activeSeatsCount = 0;
    if (isAll) {
      for (var s in _seats) {
        if (s != null) activeSeatsCount++;
      }
      if (activeSeatsCount == 0) activeSeatsCount = 1;
    }

    final totalCost = isAll ? (cost * multiplier * activeSeatsCount) : (cost * multiplier);

    if (_myCoins < totalCost) {
      if (ctx != null) {
        ScaffoldMessenger.of(ctx).showSnackBar(
          const SnackBar(content: Text("Insufficient coins balance!")),
        );
      }
      return;
    }

    setState(() {
      _myCoins -= totalCost;
      if (!fromCombo) {
        _comboCount = 1;
        _showComboButton = true;
      }
    });

    FirebaseFirestore.instance
        .collection('users')
        .doc(widget.userUid)
        .update({
      'coins': FieldValue.increment(-totalCost),
    }).catchError((_) {});

    _lastSentGiftConfig = {
      'targetSeat': targetSeat,
      'isAll': isAll,
      'cost': cost,
      'multiplier': multiplier,
      'name': name,
      'asset': asset,
    };

    _startComboTimer();

    _comboEventController.add(GiftSendEvent(
      senderName: widget.userName,
      targetName: isAll ? "All Mics" : "Seat ${(targetSeat ?? 0) + 1}",
      giftName: name,
      giftIcon: "🎁",
      comboCount: _comboCount,
    ));

    if (_socket != null && _socket!.connected) {
      _socket!.emit('send_gift', {
        'roomId': widget.roomId,
        'senderName': widget.userName,
        'targetSeatIndex': targetSeat ?? 0,
        'isAll': isAll,
        'giftName': "$name x$multiplier",
        'giftCost': totalCost,
        'giftAsset': asset,
        'comboCount': _comboCount,
      });
    }
  }

  @override
  void dispose() {
    _comboEventController.close();
    _walletSubscription?.cancel();
    _waveController.dispose();
    _comboRingController.dispose();
    _x100BadgeController.dispose();
    _comboTimer?.cancel();
    _bannerTimer?.cancel();
    _audioPlayer.dispose();
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
                                  color: giftsCount > 0 ? const Color(0xFFFF1493).withOpacity(0.3) : Colors.white.withOpacity(0.06),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Text("🎁", style: TextStyle(fontSize: 8)),
                                    const SizedBox(width: 2),
                                    Text("$giftsCount",
                                        style: TextStyle(
                                          color: giftsCount > 0 ? const Color(0xFFFFD700) : Colors.white38,
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
                Expanded(
                  flex: 4,
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.25),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.white10),
                    ),
                    child: ListView.builder(
                      controller: _chatScrollController,
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      itemCount: _messages.length,
                      itemBuilder: (context, index) {
                        final item = _messages[index];
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 3.0),
                          child: RichText(
                            text: TextSpan(
                              children: [
                                TextSpan(
                                  text: item.isSystem ? "📢 ${item.sender}: " : "${item.sender}: ",
                                  style: TextStyle(
                                    color: item.isSystem ? const Color(0xFFFFD700) : const Color(0xFF00E5FF),
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                  ),
                                ),
                                TextSpan(
                                  text: item.message,

style: TextStyle(color: item.isSystem ? Colors.white70 : Colors.white, fontSize: 12),
                                ),
                              ],
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

            // Continuous 5s Rocket Banner
            const ContinuousRocketBanner(isRunning: true),

            // Combo Overlay with Central 5x Burst
            FloatingGiftComboOverlay(
              giftStream: _comboEventController.stream,
            ),

            ..._activeFlyingGifts.map((gift) {
              return AnimatedBuilder(
                animation: gift.animation,
                builder: (context, child) {
                  final t = gift.animation.value;
                  final col = gift.targetSeatIndex % crossAxis;
                  final row = gift.targetSeatIndex ~/ crossAxis;

                  final targetX = gift.isAll ? (size.width * 0.5) : ((col + 0.5) * (size.width / crossAxis));
                  final targetY = gift.isAll ? (size.height * 0.25) : (60.0 + (row * 65.0));

                  final startX = size.width * 0.85;
                  final startY = size.height * 0.90;

                  final currentX = startX + (targetX - startX) * t;

final currentY = startY + (targetY - startY) * t;
                  final scale = gift.isAll
                      ? (0.6 + 1.2 * (1.0 - (t - 0.5).abs() * 2))
                      : (0.5 + 0.9 * (1.0 - (t - 0.5).abs() * 2));

                  return Positioned(
                    left: currentX - 40,
                    top: currentY - 40,
                    child: Opacity(
                      opacity: (1.0 - t * 0.2).clamp(0.0, 1.0),
                      child: Transform.scale(
                        scale: scale.clamp(0.4, 2.0),
                        child: Image.asset(
                          gift.asset,
                          width: 80,
                          height: 80,
                          fit: BoxFit.contain,
                          errorBuilder: (c, e, s) => const Icon(Icons.card_giftcard, color: Color(0xFFFFD700), size: 45),
                        ),
                      ),
                    ),
                  );
                },
              );
            }),

            if (_showFloatingBanner && _lastSentGiftConfig != null)
              Positioned(
                bottom: 120,
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
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFFFF2A85).withOpacity(0.5),
                              blurRadius: 10,
                              offset: const Offset(0, 3),
                            ),
                          ],
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
                                  widget.userName.isNotEmpty ? widget.userName[0].toUpperCase() : "U",
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
                                    widget.userName,
                                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11),

maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  Text(
                                    "Combo x$_comboCount Hits!",
                                    style: const TextStyle(color: Color(0xFFFFD700), fontWeight: FontWeight.bold, fontSize: 10),
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
                    final scale = (sin(t * pi) * 1.2).clamp(0.0, 1.3);
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
