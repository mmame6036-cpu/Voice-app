import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:audioplayers/audioplayers.dart';
import '../services/agora_service.dart';
import '../services/room_session_manager.dart';
import '../widgets/gift_dialog.dart';
import '../widgets/fullscreen_gift_animator.dart';
import '../widgets/room_tools_sheet.dart';
import '../main.dart';

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
  static const Color kRoomBgTop = Color(0xFF0A1628);
  static const Color kRoomBgMid = Color(0xFF0E2938);
  static const Color kRoomBgBottom = Color(0xFF060E18);
  static const Color kGlassDark = Color(0xFF101C2C);
  static const Color kGlassCard = Color(0xFF152538);
  static const Color kGoldBlackTop = Color(0xFF2B2014);
  static const Color kGoldBlackBottom = Color(0xFF120D08);
  static const Color kGoldBorder = Color(0xFFD49B42);
  static const Color kGoldBright = Color(0xFFFFD700);
  static const Color kMintLive = Color(0xFF26E6C8);

  late AgoraService _agoraService;
  final User? _currentUser = FirebaseAuth.instance.currentUser;
  final Random _random = Random();
  final AudioPlayer _audioPlayer = AudioPlayer();
  final AudioPlayer _musicPlayer = AudioPlayer();

  final StreamController<FullscreenGiftEvent> _fullscreenAnimStreamController =
      StreamController.broadcast();

  bool _isMuted = true;
  bool _isRoomVoiceOn = true;
  bool _allMicsClosed = false;
  String? _roomPassword;
  List<String> _roomAdmins = [];
  String _liveRoomTitle = "";
  String _roomHostUid = "";
  String _roomAnnouncement = "";
  String _equippedFrame = "default";
  final List<String> _seatFrames = List.filled(30, 'default');
  final GlobalKey _roomStackKey = GlobalKey();
  final List<GlobalKey> _seatKeys = List.generate(30, (_) => GlobalKey());
  bool _isRoomOwnerAgent = false;
  int get _goldenSeatsCount => _isRoomOwnerAgent ? 6 : 3;

  Map<String, dynamic>? _pkData;
  Timer? _pkTickerTimer;
  int _pkSecondsLeft = 0;

  Map<String, dynamic>? _musicData;
  String _activeMusicKey = "";

  Map<String, dynamic>? _activeRedPacket;
  String? _activeRedPacketId;
  bool _isClaimingPacket = false;

  int? _mySeatIndex;
  int _totalSeats = 30;
  late List<String?> _seats;
  late List<String?> _seatUids;
  late List<int> _seatNumericIds;
  late List<int> _seatGifts;
  late List<bool> _seatMutes;
  bool _isConnecting = true;
  bool _hasCleanedUp = false;
  bool _isMinimizing = false;
  bool _resumedFromMinimize = false;
  int _myAgoraUid = 0;

  int _myCoins = 0;
  int _myPoints = 0;
  int _myWealthExp = 0;
  int get _myLevel => (_myWealthExp ~/ 1000) + 1;

StreamSubscription? _walletSubscription;
  StreamSubscription? _roomLiveSubscription;
  StreamSubscription? _eventsSubscription;
  StreamSubscription? _chatSubscription;
  StreamSubscription? _redPacketSubscription;
  Timer? _heartbeatTimer;

  final Set<String> _processedEventIds = {};
  final Set<String> _processedChatIds = {};
  late final int _sessionStartMs;

  final List<CenterFlyingGift> _activeFlyingGifts = [];

  bool _showComboButton = false;
  int _comboCount = 0;
  Timer? _comboTimer;
  late AnimationController _comboRingController;
  late AnimationController _speakingWaveController;
  Map? _lastSentGiftConfig;

  String? _luckyWinToast;
  Timer? _luckyWinToastTimer;

  String? _entryBannerText;
  String _entryBannerLevel = "Lv.1";
  late AnimationController _entryMarqueeController;
  late Animation<Offset> _entryMarqueeAnimation;

  final List<String> _winnerMarqueeItems = [
    "🏆 Amina won 100x in Lucky Gift!",
    "🎉 Kedir won 50x in Prism Diamond!",
    "🔥 Yonas won 80x in Lucky Gift!",
    "💎 Selam won 500x Mega Jackpot!",
  ];
  int _winnerMarqueeIndex = 0;
  Timer? _winnerMarqueeTimer;

  int _chatFilterIndex = 0;

  final Set<int> _speakingSeatIndices = {};
  final List<int> _allowedSeatOptions = [6, 12, 20, 25, 30];

  final List<RoomChatMessage> _messages = [];
  final TextEditingController _chatController = TextEditingController();
  final ScrollController _chatScrollController = ScrollController();

  String get _resolvedUid {
    if (_currentUser != null) return _currentUser!.uid;
    if (widget.userUid.isNotEmpty) {
      if (widget.userUid != "user_guest_id") {
        return widget.userUid;
      }
    }
    return "guest_${widget.userNumericId}";
  }

  bool get _isRoomOwner {
    if (widget.roomId == 'room_$_resolvedUid') return true;
    if (_roomHostUid.isNotEmpty && _resolvedUid == _roomHostUid) return true;
    if (_roomHostUid.isEmpty &&
        widget.hostName.isNotEmpty &&
        widget.userName == widget.hostName) {
      return true;
    }
    return false;
  }

  bool get _isHostUser => _isRoomOwner;

  bool get _isAdminUser {
    if (_isRoomOwner) return true;
    if (_roomAdmins.contains(_resolvedUid)) return true;
    if (_roomAdmins.contains(widget.userName)) return true;
    return false;
  }

  int _getColsForSeats(int count) {
    if (count <= 6) return 3;
    if (count <= 12) return 4;
    if (count <= 20) return 5;
    if (count <= 25) return 5;
    return 6;
  }

  void _onAgoraChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  void initState() {
    super.initState();
    _liveRoomTitle = widget.roomTitle;
    _sessionStartMs = DateTime.now().millisecondsSinceEpoch;
    _seats = List.filled(30, null);
    _seatUids = List.filled(30, null);
    _seatNumericIds = List.filled(30, 0);
    _seatGifts = List.filled(30, 0);
    _seatMutes = List.filled(30, false);

    final mgr = RoomSessionManager.instance;
    if (mgr.hasActiveRoom &&
        mgr.roomId == widget.roomId &&
        mgr.activeEngine is AgoraService) {
      _agoraService = mgr.activeEngine as AgoraService;
      _isMuted = mgr.isMuted;
      _mySeatIndex = mgr.seatedIndex;
      _isConnecting = false;
      _resumedFromMinimize = true;
      mgr.clearSessionOnly();
    } else {
      if (mgr.hasActiveRoom) {
        mgr.closeMinimizedRoom();
      }
      _agoraService = AgoraService();
    }

    _agoraService.addListener(_onAgoraChanged);

    _speakingWaveController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    )..repeat();

    _comboRingController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    );

    _entryMarqueeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3400),
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

    _startWinnerMarqueeRotation();
    _startPkCountdownTicker();
    _initWalletAndProfileSync();
    _initRoomLiveSync();
    _initRedPacketSync();
    _startSeatHeartbeat();
    _setupAgora();
    if (!_resumedFromMinimize) {
      _announceEntry();
    }
  }

  void _startWinnerMarqueeRotation() {
    _winnerMarqueeTimer?.cancel();
    _winnerMarqueeTimer = Timer.periodic(const Duration(seconds: 4), (_) {
      if (mounted && _winnerMarqueeItems.isNotEmpty) {
        setState(() {
          _winnerMarqueeIndex =
              (_winnerMarqueeIndex + 1) % _winnerMarqueeItems.length;
        });
      }
    });
  }

  void _pushWinnerToMarquee(String text) {
    if (!mounted) return;
    setState(() {
      _winnerMarqueeItems.insert(0, text);
      if (_winnerMarqueeItems.length > 15) {
        _winnerMarqueeItems.removeLast();
      }
      _winnerMarqueeIndex = 0;
    });
  }

  void _announceEntry() {
    final String lvTag = "Lv.$_myLevel";
    _triggerEntryNotice(widget.userName, levelTag: lvTag);

    _addChatMessage(RoomChatMessage(
      id: "${DateTime.now().microsecondsSinceEpoch}_join",
      sender: "System",
      message: "$lvTag ${widget.userName} joined",
      isSystem: true,
    ));

    FirebaseFirestore.instance
        .collection('rooms')
        .doc(widget.roomId)
        .collection('messages')
        .add({
      'sender': 'System',
      'senderUid': _resolvedUid,
      'message': '$lvTag ${widget.userName} joined',
      'isSystem': true,
      'isJoinEvent': true,
      'joinUserName': widget.userName,
      'joinLevel': lvTag,
      'ts': DateTime.now().millisecondsSinceEpoch,
    }).catchError((_) {});
  }

  void _triggerEntryNotice(String name, {String levelTag = "Lv.1"}) {
    if (!mounted) return;
    setState(() {
      _entryBannerLevel = levelTag;
      _entryBannerText = "$name Joined";
    });
    _entryMarqueeController.reset();
    _entryMarqueeController.forward();
  }

  void _showCompactWinBadge(int wonCoins) {
    if (wonCoins <= 0) return;
    if (!mounted) return;
    _luckyWinToastTimer?.cancel();
    setState(() {
      _luckyWinToast = "+$wonCoins Coins Won!";
    });
    _luckyWinToastTimer = Timer(const Duration(seconds: 2), () {
      if (mounted) setState(() => _luckyWinToast = null);
    });
  }

  Future<void> _playLuckyCoinSound() async {
    try {
      final AudioPlayer player = AudioPlayer();
      await player.setPlayerMode(PlayerMode.mediaPlayer);
      await player.setVolume(1.0);
      try {
        await player.play(AssetSource('sounds/Five_win.mp3'));
      } catch (_) {
        await player.play(AssetSource('sounds/five_win.mp3'));
      }
      await player.setVolume(1.0);
      player.onPlayerComplete.listen((_) {
        player.dispose();
      });
    } catch (_) {}
  }

  void _postGiftToChat(String senderName, String giftDisplayText, String icon) {
    final String msgText = "🎉 $senderName sent $giftDisplayText! $icon";
    _addChatMessage(RoomChatMessage(
      id: "${DateTime.now().microsecondsSinceEpoch}_${_random.nextInt(999)}",
      sender: "System",
      message: msgText,
      isSystem: true,
    ));

    FirebaseFirestore.instance
        .collection('rooms')
        .doc(widget.roomId)
        .collection('messages')
        .add({
      'sender': 'System',
      'senderUid': _resolvedUid,
      'message': msgText,
      'isSystem': true,
      'ts': DateTime.now().millisecondsSinceEpoch,
    }).catchError((_) {});
  }

  void _ensureSpeakerLoud() {
    try {
      final eng = (_agoraService as dynamic).engine;
      eng?.setDefaultAudioRouteToSpeakerphone(true);
      eng?.setEnableSpeakerphone(true);
      eng?.adjustPlaybackSignalVolume(100);
    } catch (_) {}
  }

void _startPkCountdownTicker() {
    _pkTickerTimer?.cancel();
    _pkTickerTimer = Timer.periodic(const Duration(seconds: 1), (_) async {
      if (!mounted) return;
      if (_pkData != null && _pkData!['active'] == true) {
        final int endMs = (_pkData!['endTimeMs'] as num?)?.toInt() ?? 0;
        final int diffSec =
            ((endMs - DateTime.now().millisecondsSinceEpoch) / 1000).ceil();
        if (diffSec <= 0) {
          setState(() => _pkSecondsLeft = 0);
          if (_isAdminUser) {
            final int rScore = (_pkData!['redScore'] as num?)?.toInt() ?? 0;
            final int bScore = (_pkData!['blueScore'] as num?)?.toInt() ?? 0;
            String winMsg = "PK Ended in a Draw! 🤝";
            if (rScore > bScore) {
              winMsg =
                  "🏆 ${_pkData!['redName'] ?? 'Red Team'} won the PK Battle ($rScore vs $bScore)!";
            } else if (bScore > rScore) {
              winMsg =
                  "🏆 ${_pkData!['blueName'] ?? 'Blue Team'} won the PK Battle ($bScore vs $rScore)!";
            }
            await FirebaseFirestore.instance
                .collection('rooms')
                .doc(widget.roomId)
                .set({
              'pkBattle': {'active': false},
            }, SetOptions(merge: true)).catchError((_) {});

            await FirebaseFirestore.instance
                .collection('rooms')
                .doc(widget.roomId)
                .collection('messages')
                .add({
              'sender': 'System',
              'senderUid': _resolvedUid,
              'message': winMsg,
              'isSystem': true,
              'ts': DateTime.now().millisecondsSinceEpoch,
            }).catchError((_) {});
          }
        } else {
          setState(() => _pkSecondsLeft = diffSec);
        }
      }
    });
  }

  void _initWalletAndProfileSync() {
    _walletSubscription = FirebaseFirestore.instance
        .collection('users')
        .doc(_resolvedUid)
        .snapshots()
        .listen((snapshot) {
      if (snapshot.exists && snapshot.data() != null && mounted) {
        final data = snapshot.data()!;
        final bool amAgent = (data['isAgent'] == true)
            ? true
            : (data['role'] == 'agent' ? true : (data['isAgency'] == true));
        setState(() {
          _myCoins = (data['coins'] as num?)?.toInt() ?? 0;
          _myPoints = (data['points'] as num?)?.toInt() ?? 0;
          _myWealthExp = (data['wealthExp'] as num?)?.toInt() ?? 0;
          final frame = (data['equippedFrame'] ?? 'default').toString();
          _equippedFrame = frame;
          if (_mySeatIndex != null) {
            _seatFrames[_mySeatIndex!] = frame;
          }
          if (_isRoomOwner) {
            _isRoomOwnerAgent = amAgent;
          }
        });
        if (_isRoomOwner) {
          FirebaseFirestore.instance
              .collection('rooms')
              .doc(widget.roomId)
              .set({
            'hostUid': _resolvedUid,
            'isAgentHost': amAgent,
            'goldenSeatCount': amAgent ? 6 : 3,
          }, SetOptions(merge: true)).catchError((_) {});
        }
      }
    });
  }

  void _initRedPacketSync() {
    _redPacketSubscription = FirebaseFirestore.instance
        .collection('rooms')
        .doc(widget.roomId)
        .collection('red_packets')
        .orderBy('createdAt', descending: true)
        .limit(5)
        .snapshots()
        .listen((snap) {
      if (!mounted) return;
      Map<String, dynamic>? foundPacket;
      String? foundId;

      for (final doc in snap.docs) {
        final d = doc.data();
        final int rem = (d['remainingCount'] as num?)?.toInt() ?? 0;
        final List claimed = (d['claimedBy'] as List?) ?? [];
        if (rem > 0 && !claimed.contains(_resolvedUid)) {
          foundPacket = d;
          foundId = doc.id;
          break;
        }
      }

      setState(() {
        _activeRedPacket = foundPacket;
        _activeRedPacketId = foundId;
      });
    });
  }

Future<void> _claimRedPacket() async {
    if (_isClaimingPacket) return;
    if (_activeRedPacketId == null) return;
    _isClaimingPacket = true;

    final packetRef = FirebaseFirestore.instance
        .collection('rooms')
        .doc(widget.roomId)
        .collection('red_packets')
        .doc(_activeRedPacketId!);

    int wonAmount = 0;
    String senderName = "User";

    try {
      await FirebaseFirestore.instance.runTransaction((tx) async {
        final snap = await tx.get(packetRef);
        if (!snap.exists) return;
        if (snap.data() == null) return;
        final data = snap.data()!;
        final int remCount = (data['remainingCount'] as num?)?.toInt() ?? 0;
        final int remCoins = (data['remainingCoins'] as num?)?.toInt() ?? 0;
        final List claimed = List.from((data['claimedBy'] as List?) ?? []);
        senderName = (data['senderName'] ?? 'User').toString();

        if (remCount <= 0) return;
        if (remCoins <= 0) return;
        if (claimed.contains(_resolvedUid)) return;

        if (remCount == 1) {
          wonAmount = remCoins;
        } else {
          final int maxGrab = max(1, ((remCoins / remCount) * 2).floor());
          wonAmount =
              min(remCoins - (remCount - 1), _random.nextInt(maxGrab) + 1);
        }

        claimed.add(_resolvedUid);
        tx.update(packetRef, {
          'remainingCount': remCount - 1,
          'remainingCoins': remCoins - wonAmount,
          'claimedBy': claimed,
        });
      });

      if (wonAmount > 0) {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(_resolvedUid)
            .set({
          'coins': FieldValue.increment(wonAmount),
        }, SetOptions(merge: true));

        _showCompactWinBadge(wonAmount);

        await FirebaseFirestore.instance
            .collection('rooms')
            .doc(widget.roomId)
            .collection('messages')
            .add({
          'sender': 'System',
          'senderUid': _resolvedUid,
          'message':
              "🧧 ${widget.userName} grabbed $wonAmount coins from $senderName's Red Packet!",
          'isSystem': true,
          'ts': DateTime.now().millisecondsSinceEpoch,
        });
      }
    } catch (_) {}

    _isClaimingPacket = false;
  }

  Future<void> _syncMusicPlayback(Map<String, dynamic>? music) async {
    if (music == null) {
      if (_activeMusicKey.isNotEmpty) {
        _activeMusicKey = "";
        try {
          await _musicPlayer.stop();
        } catch (_) {}
      }
      return;
    }
    if (music['isPlaying'] != true) {
      if (_activeMusicKey.isNotEmpty) {
        _activeMusicKey = "";
        try {
          await _musicPlayer.stop();
        } catch (_) {}
      }
      return;
    }

    final String title = (music['trackTitle'] ?? '').toString();
    final String asset = (music['trackAsset'] ?? '').toString();
    final String url = (music['trackUrl'] ?? '').toString();
    final double vol = _isRoomVoiceOn
        ? ((music['volume'] as num?)?.toDouble() ?? 0.6).clamp(0.0, 1.0)
        : 0.0;
    final String key = "$title|$asset|$url";

    try {
      await _musicPlayer.setVolume(vol);
      if (_activeMusicKey != key) {
        _activeMusicKey = key;
        await _musicPlayer.stop();
        await _musicPlayer.setReleaseMode(ReleaseMode.loop);
        if (asset.isNotEmpty) {
          await _musicPlayer.play(AssetSource(asset));
        } else if (url.isNotEmpty) {
          await _musicPlayer.play(UrlSource(url));
        }
      }
    } catch (_) {}
  }

  void _startSeatHeartbeat() {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = Timer.periodic(const Duration(seconds: 10), (_) {
      if (_hasCleanedUp) return;
      if (_isMinimizing) return;
      if (!mounted) return;

if (_mySeatIndex != null) {
        final idx = _mySeatIndex!;
        FirebaseFirestore.instance
            .collection('rooms')
            .doc(widget.roomId)
            .set({
          'activeSeats': {
            '$idx': {
              'uid': _resolvedUid,
              'name': widget.userName,
              'numericId': _myAgoraUid > 0 ? _myAgoraUid : widget.userNumericId,
              'isMuted': _isMuted,
              'frame': _equippedFrame,
              'updatedAt': DateTime.now().millisecondsSinceEpoch,
            }
          }
        }, SetOptions(merge: true)).catchError((_) {});
      }
    });
  }

  void _initRoomLiveSync() {
    final roomRef =
        FirebaseFirestore.instance.collection('rooms').doc(widget.roomId);

    _roomLiveSubscription = roomRef.snapshots().listen((snapshot) async {
      if (!mounted) return;
      if (_hasCleanedUp) return;
      final nowMs = DateTime.now().millisecondsSinceEpoch;
      final Map<String, dynamic> activeMap = {};
      final Map<String, dynamic> staleCleanup = {};

      if (snapshot.exists && snapshot.data() != null) {
        final data = snapshot.data()!;

        final List<String> kicked =
            (data['kickedUsers'] as List?)?.map((e) => e.toString()).toList() ??
                [];
        if (kicked.contains(_resolvedUid) && !_isRoomOwner) {
          _cleanupAndLeave();
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text("You were removed from this room.")),
            );
            Navigator.of(context).pop();
          }
          return;
        }

        final String updatedTitle =
            (data['roomTitle'] ?? data['title'] ?? '').toString();
        final String hostUidDoc = (data['hostUid'] ?? '').toString();
        final String announcementText =
            (data['announcement'] ?? '').toString();
        final bool allClosed = data['allMicsClosed'] == true;
        final bool agentHost = (data['isAgentHost'] == true)
            ? true
            : ((data['goldenSeatCount'] as num?)?.toInt() == 6);
        final String? pass = data['password']?.toString();
        final List<String> admins =
            (data['admins'] as List?)?.map((e) => e.toString()).toList() ?? [];
        final Map<String, dynamic>? pk = data['pkBattle'] is Map
            ? Map<String, dynamic>.from(data['pkBattle'])
            : null;
        final Map<String, dynamic>? music = data['musicState'] is Map
            ? Map<String, dynamic>.from(data['musicState'])
            : null;

        await _syncMusicPlayback(music);

        if (data['activeSeats'] is Map) {
          final raw = data['activeSeats'] as Map;
          raw.forEach((key, value) {
            if (value is Map) {
              final int updatedAt = (value['updatedAt'] as num?)?.toInt() ?? 0;
              final String uid = (value['uid'] ?? '').toString();
              if (uid.isNotEmpty && (nowMs - updatedAt) < 25000) {
                activeMap[key.toString()] = value;
              } else {
                staleCleanup[key.toString()] = FieldValue.delete();
              }
            }
          });
        }

        if (staleCleanup.isNotEmpty) {
          roomRef
              .set({'activeSeats': staleCleanup}, SetOptions(merge: true))
              .catchError((_) {});
        }

        if (!mounted) return;
        setState(() {
          if (updatedTitle.isNotEmpty) {
            _liveRoomTitle = updatedTitle;
          }
          if (hostUidDoc.isNotEmpty) {
            _roomHostUid = hostUidDoc;
          }
          if (announcementText.isNotEmpty) {
            _roomAnnouncement = announcementText;
          }
          _allMicsClosed = allClosed;
          _isRoomOwnerAgent = agentHost;
          _roomPassword = (pass != null && pass.isNotEmpty) ? pass : null;
          _roomAdmins = admins;
          _pkData = pk;
          _musicData = music;

int? foundMySeat;
          for (int i = 0; i < 30; i++) {
            final entry = activeMap['$i'];
            if (entry is Map) {
              final uid = (entry['uid'] ?? '').toString();
              final name = (entry['name'] ?? 'User').toString();
              final muted = entry['isMuted'] == true;
              final numId = (entry['numericId'] as num?)?.toInt() ?? 0;
              final frame = (entry['frame'] ?? 'default').toString();
              _seats[i] = name;
              _seatUids[i] = uid;
              _seatNumericIds[i] = numId;
              _seatMutes[i] = muted;
              _seatFrames[i] = frame;
              if (uid == _resolvedUid) {
                foundMySeat = i;
                _isMuted = muted;
              }
            } else {
              if (_mySeatIndex == i && _seatUids[i] == _resolvedUid) {
                foundMySeat = i;
              } else {
                _seats[i] = null;
                _seatUids[i] = null;
                _seatNumericIds[i] = 0;
                _seatGifts[i] = 0;
                _seatMutes[i] = false;
                _seatFrames[i] = 'default';
                _speakingSeatIndices.remove(i);
              }
            }
          }
          _mySeatIndex = foundMySeat;

          if (_allMicsClosed &&
              !_isAdminUser &&
              _mySeatIndex != null &&
              !_isMuted) {
            _isMuted = true;
            _seatMutes[_mySeatIndex!] = true;
            _speakingSeatIndices.remove(_mySeatIndex!);
            _agoraService.setMicrophoneMute(true);
          }
        });
      }
    });

    _chatSubscription = roomRef
        .collection('messages')
        .orderBy('ts', descending: false)
        .limitToLast(30)
        .snapshots()
        .listen((snap) {
      if (!mounted) return;
      for (final doc in snap.docs) {
        if (_processedChatIds.contains(doc.id)) continue;
        _processedChatIds.add(doc.id);
        final d = doc.data();
        final int ts = (d['ts'] as num?)?.toInt() ?? 0;
        if (ts < _sessionStartMs - 5000) continue;
        final senderUid = (d['senderUid'] ?? '').toString();
        if (senderUid == _resolvedUid) continue;

        if (d['isJoinEvent'] == true) {
          final String jName = (d['joinUserName'] ?? 'User').toString();
          final String jLv = (d['joinLevel'] ?? 'Lv.1').toString();
          _triggerEntryNotice(jName, levelTag: jLv);
        }

        _addChatMessage(RoomChatMessage(
          id: doc.id,
          sender: (d['sender'] ?? 'User').toString(),
          message: (d['message'] ?? '').toString(),
          isSystem: d['isSystem'] == true,
        ));
      }
    });

    _eventsSubscription = roomRef
        .collection('events')
        .orderBy('createdAt', descending: true)
        .limit(10)
        .snapshots()
        .listen((snap) {
      if (!mounted) return;
      for (final doc in snap.docs) {
        if (_processedEventIds.contains(doc.id)) continue;
        _processedEventIds.add(doc.id);

        final d = doc.data();
        if (d['type'] != 'gift') continue;
        final Timestamp? createdTs = d['createdAt'] as Timestamp?;
        if (createdTs != null &&
            createdTs.millisecondsSinceEpoch < _sessionStartMs - 3000) {
          continue;
        }

        final String senderId = (d['senderId'] ?? '').toString();
        if (senderId == _resolvedUid) continue;

        final String giftName = (d['giftName'] ?? 'Gift').toString();
        final String giftIcon = (d['giftIcon'] ?? '🎁').toString();
        final String asset = (d['imageAsset'] ?? '').toString();
        final int mult = (d['multiplier'] as num?)?.toInt() ?? 1;
        final int totalCost = (d['totalCost'] as num?)?.toInt() ?? 0;
        final int wonCoins = (d['wonCoins'] as num?)?.toInt() ?? 0;
        final int luckyMult = (d['luckyMultiplier'] as num?)?.toInt() ?? 0;
        final List seats = (d['seats'] as List?) ?? [];
        final int perSeatCost =
            seats.isNotEmpty ? (totalCost ~/ seats.length) : totalCost;

if (wonCoins > 0) {
          final String multLabel = luckyMult > 0 ? "${luckyMult}x" : "Lucky";
          _pushWinnerToMarquee(
              "🏆 VIP won $multLabel ($wonCoins Coins) in $giftName!");
        }

        _ensureSpeakerLoud();
        _fullscreenAnimStreamController.add(
          FullscreenGiftEvent(
            giftId: (d['giftId'] ?? '').toString(),
            giftName: "$giftName x$mult",
            asset: asset,
            giftIcon: giftIcon,
            senderName: "VIP",
          ),
        );

        setState(() {
          for (final s in seats) {
            final idx = (s as num).toInt();
            if (idx >= 0 && idx < 30 && _seats[idx] != null) {
              _seatGifts[idx] += perSeatCost;
              _triggerCenterGiftAnimation(asset, idx, icon: giftIcon);
            }
          }
        });
      }
    });
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

  Future<void> _setupAgora() async {
    try {
      final int effectiveUid = widget.userNumericId > 0
          ? widget.userNumericId
          : (100000 + _random.nextInt(899999));
      _myAgoraUid = effectiveUid;

      if (_resumedFromMinimize && _agoraService.isChannelJoined) {
        _ensureSpeakerLoud();
        if (mounted) setState(() => _isConnecting = false);
        return;
      }

      await Permission.microphone.request();

      await _agoraService.initEngine(
        onUserJoined: (uid) {
          _ensureSpeakerLoud();
          if (mounted) setState(() {});
        },
        onUserOffline: (uid) {
          if (mounted) setState(() {});
        },
        onVolumeChanged: (speakers) {
          if (!mounted) return;
          setState(() {
            _speakingSeatIndices.clear();
            for (var speaker in speakers) {
              final vol = speaker.volume ?? 0;
              if (vol > 5) {
                final int sUid = speaker.uid ?? 0;
                final bool isMe = (sUid == 0) ? true : (sUid == _myAgoraUid);
                if (isMe &&
                    _mySeatIndex != null &&
                    !_isMuted &&
                    !_seatMutes[_mySeatIndex!]) {
                  _speakingSeatIndices.add(_mySeatIndex!);
                } else if (!isMe) {
                  for (int i = 0; i < _totalSeats; i++) {
                    if (_seats[i] != null && _seatNumericIds[i] == sUid) {
                      _speakingSeatIndices.add(i);
                    }
                  }
                }
              }
            }
          });
        },
        onError: (errMsg) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text("Audio warning: $errMsg")),
            );
          }
        },
      );

      final String cleanChannelId = widget.roomId.trim();

      await _agoraService.joinRoom(
        channelId: cleanChannelId,
        uid: effectiveUid,
        isSpeaker: _mySeatIndex != null,
        roomTitle: widget.roomTitle,
        seatCount: _totalSeats,
      );
      _ensureSpeakerLoud();
    } catch (_) {}

    if (mounted) setState(() => _isConnecting = false);
  }

  void _minimizeRoom() {
    if (_isMinimizing) return;
    _isMinimizing = true;

    final String rId = widget.roomId;
    final String rTitle = _liveRoomTitle;
    final String hName = widget.hostName;

final int uNumId = widget.userNumericId;
    final String uUid = widget.userUid;
    final String uName = widget.userName;
    final String resolvedU = _resolvedUid;
    final int activeNumId = _myAgoraUid > 0 ? _myAgoraUid : uNumId;
    final AgoraService engineRef = _agoraService;
    final List<String?> seatUidsSnapshot = List<String?>.from(_seatUids);
    final int? currentSeatSnapshot = _mySeatIndex;

    RoomSessionManager.instance.registerActiveRoom(
      id: rId,
      title: rTitle,
      muted: _isMuted,
      engine: engineRef,
      seatIndex: currentSeatSnapshot,
      expandCallback: () {
        final nav = appNavigatorKey.currentState;
        if (nav != null) {
          nav.push(
            MaterialPageRoute(
              builder: (_) => VoiceRoomScreen(
                roomTitle: rTitle,
                roomId: rId,
                hostName: hName,
                userNumericId: uNumId,
                userUid: uUid,
                userName: uName,
              ),
            ),
          );
        }
      },
      leaveCallback: () async {
        final Map<String, dynamic> removeSeats = {};
        for (int i = 0; i < 30; i++) {
          final bool matchSeat = (seatUidsSnapshot[i] == resolvedU)
              ? true
              : (currentSeatSnapshot == i);
          if (matchSeat) {
            removeSeats['$i'] = FieldValue.delete();
          }
        }
        if (removeSeats.isNotEmpty) {
          try {
            await FirebaseFirestore.instance
                .collection('rooms')
                .doc(rId)
                .set({'activeSeats': removeSeats}, SetOptions(merge: true));
          } catch (_) {}
        }
        try {
          await engineRef.leaveRoom();
        } catch (_) {}
      },
      muteCallback: (bool mute) async {
        final int? seatIdx = RoomSessionManager.instance.seatedIndex;
        if (seatIdx != null) {
          FirebaseFirestore.instance.collection('rooms').doc(rId).set({
            'activeSeats': {
              '$seatIdx': {
                'uid': resolvedU,
                'name': uName,
                'numericId': activeNumId,
                'isMuted': mute,
                'updatedAt': DateTime.now().millisecondsSinceEpoch,
              }
            }
          }, SetOptions(merge: true)).catchError((_) {});
        }
        await engineRef.setMicrophoneMute(mute);
      },
      heartbeatCallback: () {
        final int? seatIdx = RoomSessionManager.instance.seatedIndex;
        if (seatIdx != null) {
          FirebaseFirestore.instance.collection('rooms').doc(rId).set({
            'activeSeats': {
              '$seatIdx': {
                'uid': resolvedU,
                'name': uName,
                'numericId': activeNumId,
                'isMuted': RoomSessionManager.instance.isMuted,
                'updatedAt': DateTime.now().millisecondsSinceEpoch,
              }
            }
          }, SetOptions(merge: true)).catchError((_) {});
        }
      },
    );

    RoomSessionManager.instance.minimizeRoom();
    Navigator.of(context).pop();
  }

  void _triggerCenterGiftAnimation(
    String asset,
    int targetSeatIndex, {
    String icon = "🎁",
    bool isToAll = false,
  }) {
    final controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 950),
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

Future<void> _leaveMySeat(int index) async {
    final roomRef =
        FirebaseFirestore.instance.collection('rooms').doc(widget.roomId);

    setState(() {
      _seats[index] = null;
      _seatUids[index] = null;
      _seatNumericIds[index] = 0;
      _seatGifts[index] = 0;
      _seatMutes[index] = false;
      _speakingSeatIndices.remove(index);
      if (_mySeatIndex == index) {
        _mySeatIndex = null;
        _isMuted = true;
      }
    });

    roomRef.set({
      'activeSeats': {'$index': FieldValue.delete()}
    }, SetOptions(merge: true)).catchError((_) {});

    await _agoraService.switchRole(isSpeaker: false);
  }

  void _showHostTaskSheet() {
    final double ptsProgress = (_myPoints / 7000).clamp(0.0, 1.0);
    showModalBottomSheet(
      context: context,
      backgroundColor: kGlassDark,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        side: BorderSide(color: kGoldBright, width: 1.4),
      ),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: kGoldBright.withOpacity(0.16),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.task_alt_rounded,
                        color: kGoldBright, size: 22),
                  ),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Text(
                      "Daily Host Task 🎯",
                      style: TextStyle(
                        color: kGoldBright,
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: kGoldBlackBottom,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: kGoldBorder),
                    ),
                    child: Text(
                      "$_myPoints / 7,000 Pts",
                      style: const TextStyle(
                        color: kGoldBright,
                        fontSize: 11.5,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: kGlassCard,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: kGoldBorder.withOpacity(0.6)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "1. Daily Points Target",
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 13.5,
                          ),
                        ),

Text(
                          "7,000 Pts / Day",
                          style: TextStyle(
                            color: kMintLive,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: LinearProgressIndicator(
                        value: ptsProgress,
                        minHeight: 9,
                        backgroundColor: Colors.black38,
                        valueColor:
                            const AlwaysStoppedAnimation<Color>(kGoldBright),
                      ),
                    ),
                    const SizedBox(height: 14),
                    const Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "2. Online Mic Duration",
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 13.5,
                          ),
                        ),
                        Text(
                          "3 Hours (7 Days Streak)",
                          style: TextStyle(
                            color: kGoldBright,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      "• 75% Host Payout • 100,000 Pts Withdrawal Threshold",
                      style: TextStyle(color: Colors.white70, fontSize: 11),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                height: 44,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: kGoldBright,
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(22),
                    ),
                  ),
                  onPressed: () {
                    Navigator.pop(ctx);
                    if (_mySeatIndex == null) {
                      _handleSeatTap(_isRoomOwner ? 0 : 1);
                    }
                  },
                  child: Text(
                    _mySeatIndex == null
                        ? "Take Mic Now to Start Task"
                        : "On Mic • Task Active ✅",
                    style: const TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 13.5,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showQuickGameSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: kGlassDark,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        side: BorderSide(color: kGoldBright, width: 1.4),
      ),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(

"Party Games & Lucky Win 🎮",
                style: TextStyle(
                  color: kGoldBright,
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        Navigator.pop(ctx);
                        _openGiftSheet();
                      },
                      child: Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [kGoldBlackTop, kGoldBlackBottom],
                          ),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: kGoldBright, width: 1.3),
                        ),
                        child: const Column(
                          children: [
                            Text("💎", style: TextStyle(fontSize: 30)),
                            SizedBox(height: 6),
                            Text(
                              "Lucky 500x",
                              style: TextStyle(
                                color: kGoldBright,
                                fontWeight: FontWeight.w900,
                                fontSize: 13.5,
                              ),
                            ),
                            SizedBox(height: 2),
                            Text(
                              "Win up to 500x Coins",
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 10.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        Navigator.pop(ctx);
                        RoomToolsSheet.show(
                          context,
                          roomId: widget.roomId,
                          roomTitle: _liveRoomTitle,
                          userName: widget.userName,
                          userUid: _resolvedUid,
                          userCoins: _myCoins,
                          isHost: _isHostUser,
                          isAdmin: _isAdminUser,
                          isVoiceOn: _isRoomVoiceOn,
                          onToggleVoice: _toggleRoomIncomingVoice,
                          isAllMicClosed: _allMicsClosed,
                          currentPassword: _roomPassword,
                          admins: _roomAdmins,
                          seatedUsers: _buildSeatedUsersList(),
                          pkData: _pkData,
                          musicData: _musicData,
                          equippedFrame: _equippedFrame,
                          onFrameChanged: (newFrame) {
                            setState(() {
                              _equippedFrame = newFrame;
                              if (_mySeatIndex != null) {
                                _seatFrames[_mySeatIndex!] = newFrame;
                              }
                            });
                          },
                        );
                      },
                      child: Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: kGlassCard,
                          borderRadius: BorderRadius.circular(16),

border: Border.all(color: kMintLive, width: 1.3),
                        ),
                        child: const Column(
                          children: [
                            Text("🧧", style: TextStyle(fontSize: 30)),
                            SizedBox(height: 6),
                            Text(
                              "Red Packet & PK",
                              style: TextStyle(
                                color: kMintLive,
                                fontWeight: FontWeight.w900,
                                fontSize: 13.5,
                              ),
                            ),
                            SizedBox(height: 2),
                            Text(
                              "Room Tools & Battles",
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 10.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  void _showSeatUserProfileSheet(int seatIndex) {
    final String occupierName = _seats[seatIndex] ?? "User";
    final String occupierUid = _seatUids[seatIndex] ?? "";
    final int occupierNumId = _seatNumericIds[seatIndex];
    final int receivedGifts = _seatGifts[seatIndex];
    final bool isSeatMuted = _seatMutes[seatIndex];
    final bool isMe =
        (_mySeatIndex == seatIndex) ? true : (occupierUid == _resolvedUid);
    final bool isSeatHost =
        (seatIndex == 0) ? true : (occupierName == widget.hostName);

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) {
        return FutureBuilder<DocumentSnapshot>(
          future: occupierUid.isNotEmpty
              ? FirebaseFirestore.instance
                  .collection('users')
                  .doc(occupierUid)
                  .get()
              : null,
          builder: (context, snapshot) {
            Map<String, dynamic> userData = {};
            if (snapshot.hasData &&
                snapshot.data != null &&
                snapshot.data!.exists &&
                snapshot.data!.data() is Map) {
              userData = Map<String, dynamic>.from(snapshot.data!.data() as Map);
            }

            final int wealthExp =
                (userData['wealthExp'] as num?)?.toInt() ?? 0;
            final int userLevel =
                (userData['level'] as num?)?.toInt() ?? ((wealthExp ~/ 1000) + 1);
            final int vipLevel = (userData['vipLevel'] as num?)?.toInt() ?? 0;
            final String flag = (userData['flag'] ?? '🇪🇹').toString();
            final String displayUid = occupierNumId > 0
                ? "$occupierNumId"
                : (occupierUid.length > 8
                    ? occupierUid.substring(0, 8)
                    : occupierUid);

            return Padding(
              padding: const EdgeInsets.only(top: 44),
              child: Stack(
                clipBehavior: Clip.none,
                alignment: Alignment.topCenter,
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.fromLTRB(18, 54, 18, 22),
                    decoration: const BoxDecoration(
                      color: Color(0xFF101C2C),
                      borderRadius:
                          BorderRadius.vertical(top: Radius.circular(26)),
                      border: Border(
                        top: BorderSide(color: kGoldBright, width: 1.5),

),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black54,
                          blurRadius: 18,
                          offset: Offset(0, -4),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Flexible(
                              child: Text(
                                occupierName,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.w900,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(flag, style: const TextStyle(fontSize: 17)),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 9, vertical: 2.5),
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [
                                    Color(0xFF2979FF),
                                    Color(0xFF00B0FF)
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                "Lv.$userLevel",
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            if (isSeatHost) ...[
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 9, vertical: 2.5),
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [kGoldBlackTop, kGoldBlackBottom],
                                  ),
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                      color: kGoldBright, width: 1.0),
                                ),
                                child: const Text(
                                  "👑 Host",
                                  style: TextStyle(
                                    color: kGoldBright,
                                    fontSize: 10.5,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                            const SizedBox(width: 6),

Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 9, vertical: 2.5),
                              decoration: BoxDecoration(
                                color: kGlassCard,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                    color: kGoldBorder, width: 0.9),
                              ),
                              child: Text(
                                "No.${seatIndex + 1}",
                                style: const TextStyle(
                                  color: kGoldBright,
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        GestureDetector(
                          onTap: () {
                            Clipboard.setData(ClipboardData(text: displayUid));
                            ScaffoldMessenger.of(this.context).showSnackBar(
                              SnackBar(
                                content: Text("UID $displayUid copied!"),
                                duration: const Duration(seconds: 1),
                              ),
                            );
                          },
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                "UID: $displayUid",
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(width: 5),
                              const Icon(Icons.copy_rounded,
                                  size: 14, color: kGoldBright),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: Container(
                                height: 64,
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 8),
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [kGoldBlackTop, kGoldBlackBottom],
                                  ),
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                      color: kGoldBorder, width: 1.2),
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 36,
                                      height: 36,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: kGoldBright.withOpacity(0.18),
                                      ),
                                      child: const Center(
                                        child: Text("👑",
                                            style: TextStyle(fontSize: 20)),

),
                                    ),
                                    const SizedBox(width: 8),
                                    Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Text(
                                          "VIP$vipLevel",
                                          style: const TextStyle(
                                            color: kGoldBright,
                                            fontSize: 15,
                                            fontWeight: FontWeight.w900,
                                          ),
                                        ),
                                        const Text(
                                          "Noble Privilege",
                                          style: TextStyle(
                                            color: Colors.white70,
                                            fontSize: 10,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Container(
                                height: 64,
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 8),
                                decoration: BoxDecoration(
                                  color: kGlassCard,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                      color: kGoldBorder, width: 1.2),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        const Text(
                                          "Gifts",
                                          style: TextStyle(
                                            color: Colors.white70,
                                            fontSize: 11,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        Text(
                                          "x$receivedGifts",
                                          style: const TextStyle(
                                            color: kGoldBright,
                                            fontSize: 12.5,
                                            fontWeight: FontWeight.w900,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    const Row(
                                      children: [

Text("🌹",
                                            style: TextStyle(fontSize: 16)),
                                        SizedBox(width: 6),
                                        Text("👑",
                                            style: TextStyle(fontSize: 16)),
                                        SizedBox(width: 6),
                                        Text("💎",
                                            style: TextStyle(fontSize: 16)),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                        if (_isAdminUser && !isMe) ...[
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: OutlinedButton.icon(
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: Colors.white,
                                    side: const BorderSide(color: kGoldBorder),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                  ),
                                  icon: Icon(
                                    isSeatMuted ? Icons.mic : Icons.mic_off,
                                    size: 16,
                                  ),
                                  label: Text(
                                    isSeatMuted ? "Unmute Mic" : "Mute Mic",
                                    style: const TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold),
                                  ),
                                  onPressed: () async {
                                    Navigator.pop(ctx);
                                    await FirebaseFirestore.instance
                                        .collection('rooms')
                                        .doc(widget.roomId)
                                        .set({
                                      'activeSeats': {
                                        '$seatIndex': {
                                          'isMuted': !isSeatMuted,
                                          'updatedAt': DateTime.now()
                                              .millisecondsSinceEpoch,
                                        }
                                      }
                                    }, SetOptions(merge: true)).catchError(
                                            (_) {});
                                  },
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: OutlinedButton.icon(
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: Colors.redAccent,
                                    side: const BorderSide(
                                        color: Colors.redAccent),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                  ),
                                  icon: const Icon(Icons.person_remove,
                                      size: 16),
                                  label: const Text(

"Remove Seat",
                                    style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold),
                                  ),
                                  onPressed: () async {
                                    Navigator.pop(ctx);
                                    await FirebaseFirestore.instance
                                        .collection('rooms')
                                        .doc(widget.roomId)
                                        .set({
                                      'activeSeats': {
                                        '$seatIndex': FieldValue.delete(),
                                      }
                                    }, SetOptions(merge: true)).catchError(
                                            (_) {});
                                  },
                                ),
                              ),
                            ],
                          ),
                        ],
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: SizedBox(
                                height: 46,
                                child: OutlinedButton(
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: isMe
                                        ? Colors.redAccent
                                        : Colors.white,
                                    side: BorderSide(
                                      color: isMe
                                          ? Colors.redAccent
                                          : kGoldBorder,
                                      width: 1.4,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(24),
                                    ),
                                  ),
                                  onPressed: () {
                                    Navigator.pop(ctx);
                                    if (isMe) {
                                      _leaveMySeat(seatIndex);
                                    } else {
                                      _chatController.text =
                                          "@$occupierName ";
                                      _chatController.selection =
                                          TextSelection.fromPosition(
                                        TextPosition(
                                            offset:
                                                _chatController.text.length),
                                      );
                                    }
                                  },
                                  child: Text(
                                    isMe
                                        ? "Leave the microphone"
                                        : "@ Mention",
                                    style: const TextStyle(
                                      fontSize: 12.5,
                                      fontWeight: FontWeight.bold,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: SizedBox(

height: 46,
                                child: ElevatedButton.icon(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: kGoldBright,
                                    foregroundColor: Colors.black,
                                    elevation: 2,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(24),
                                    ),
                                  ),
                                  icon: const Icon(Icons.card_giftcard,
                                      size: 18, color: Colors.black),
                                  label: const Text(
                                    "Send gifts",
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w900,
                                      color: Colors.black,
                                    ),
                                  ),
                                  onPressed: () {
                                    Navigator.pop(ctx);
                                    _openGiftSheet(preselectSeat: seatIndex);
                                  },
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Positioned(
                    top: -40,
                    child: Container(
                      width: 82,
                      height: 82,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: const LinearGradient(
                          colors: [kGoldBlackTop, kGoldBlackBottom],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        border: Border.all(color: kGoldBright, width: 3.0),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.45),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: const Center(
                        child: Icon(
                          Icons.person,
                          color: kGoldBright,
                          size: 44,
                        ),
                      ),
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

  void _handleSeatTap(int index) async {
    if (_seats[index] != null) {
      _showSeatUserProfileSheet(index);
      return;
    }

    if (index == 0 && !_isRoomOwner) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("👑 Seat 1 is reserved for the Host only!"),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    final roomRef =
        FirebaseFirestore.instance.collection('rooms').doc(widget.roomId);

    final status = await Permission.microphone.request();
    if (!status.isGranted) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Please allow microphone permission")),
        );
      }
      return;
    }

    final int? oldIndex = _mySeatIndex;
    final int activeNumId =
        _myAgoraUid > 0 ? _myAgoraUid : widget.userNumericId;
    final bool shouldMuteOnJoin = _allMicsClosed && !_isAdminUser;

setState(() {
      if (oldIndex != null && oldIndex != index) {
        _seatGifts[index] = _seatGifts[oldIndex];
        _seatGifts[oldIndex] = 0;
        _seats[oldIndex] = null;
        _seatUids[oldIndex] = null;
        _seatNumericIds[oldIndex] = 0;
        _seatMutes[oldIndex] = false;
        _speakingSeatIndices.remove(oldIndex);
      }
      _seats[index] = widget.userName;
      _seatUids[index] = _resolvedUid;
      _seatNumericIds[index] = activeNumId;
      _seatFrames[index] = _equippedFrame;
      _mySeatIndex = index;
      _isMuted = shouldMuteOnJoin;
      _seatMutes[index] = shouldMuteOnJoin;
    });

    final Map<String, dynamic> seatUpdates = {
      '$index': {
        'uid': _resolvedUid,
        'name': widget.userName,
        'numericId': activeNumId,
        'isMuted': shouldMuteOnJoin,
        'frame': _equippedFrame,
        'updatedAt': DateTime.now().millisecondsSinceEpoch,
      }
    };
    if (oldIndex != null && oldIndex != index) {
      seatUpdates['$oldIndex'] = FieldValue.delete();
    }

    roomRef
        .set({'activeSeats': seatUpdates}, SetOptions(merge: true))
        .catchError((_) {});

    await _agoraService.switchRole(isSpeaker: true);
    await _agoraService.setMicrophoneMute(shouldMuteOnJoin);
  }

  void _toggleMute() async {
    if (_allMicsClosed && !_isAdminUser && _isMuted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("All mics are closed by the Host")),
      );
      return;
    }

    setState(() {
      _isMuted = !_isMuted;
      if (_mySeatIndex != null) {
        _seatMutes[_mySeatIndex!] = _isMuted;
        if (_isMuted) _speakingSeatIndices.remove(_mySeatIndex!);
      }
    });

    if (_mySeatIndex != null) {
      final idx = _mySeatIndex!;
      FirebaseFirestore.instance
          .collection('rooms')
          .doc(widget.roomId)
          .set({
        'activeSeats': {
          '$idx': {
            'uid': _resolvedUid,
            'name': widget.userName,
            'numericId': _myAgoraUid > 0 ? _myAgoraUid : widget.userNumericId,
            'isMuted': _isMuted,
            'frame': _equippedFrame,
            'updatedAt': DateTime.now().millisecondsSinceEpoch,
          }
        }
      }, SetOptions(merge: true)).catchError((_) {});
    }

    await _agoraService.setMicrophoneMute(_isMuted);
  }

  Future<void> _toggleRoomIncomingVoice() async {
    final nextState = !_isRoomVoiceOn;
    setState(() {
      _isRoomVoiceOn = nextState;
    });

    try {
      await (_agoraService as dynamic).muteAllRemoteAudioStreams(!nextState);
    } catch (_) {
      try {
        await (_agoraService as dynamic)
            .engine
            ?.muteAllRemoteAudioStreams(!nextState);
      } catch (_) {}
    }

    try {
      final double targetVol = nextState
          ? (((_musicData?['volume'] as num?)?.toDouble() ?? 0.6)
              .clamp(0.0, 1.0))
          : 0.0;
      await _musicPlayer.setVolume(targetVol);
    } catch (_) {}

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            nextState
                ? "Room Audio Restored (Voice On) 🔊"
                : "Room Audio Muted (Voice Off) 🔇",
          ),
        ),
      );
    }
  }

  void _changeSeatCount(int newCount) {
    setState(() {
      _totalSeats = newCount;
      if (_mySeatIndex != null && _mySeatIndex! >= newCount) {
        _leaveMySeat(_mySeatIndex!);
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

    FirebaseFirestore.instance

.collection('rooms')
        .doc(widget.roomId)
        .collection('messages')
        .add({
      'sender': widget.userName,
      'senderUid': _resolvedUid,
      'message': text,
      'isSystem': false,
      'ts': DateTime.now().millisecondsSinceEpoch,
    }).catchError((_) {});

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

  void _addPkPointsForSeats(List<int> targetSeats, bool isAll, int costPerSeat) {
    if (_pkData == null) return;
    if (_pkData!['active'] != true) return;
    int redAdd = 0;
    int blueAdd = 0;

    final List<int> seatsToScore = isAll
        ? <int>[
            for (int i = 0; i < _totalSeats; i++)
              if (_seats[i] != null) i
          ]
        : targetSeats;

    for (final idx in seatsToScore) {
      if (idx % 2 == 0) {
        redAdd += costPerSeat;
      } else {
        blueAdd += costPerSeat;
      }
    }

    if (redAdd > 0) {
      FirebaseFirestore.instance.collection('rooms').doc(widget.roomId).set({
        'pkBattle': {
          'redScore': FieldValue.increment(redAdd),
        }
      }, SetOptions(merge: true)).catchError((_) {});
    }
    if (blueAdd > 0) {
      FirebaseFirestore.instance.collection('rooms').doc(widget.roomId).set({
        'pkBattle': {
          'blueScore': FieldValue.increment(blueAdd),
        }
      }, SetOptions(merge: true)).catchError((_) {});
    }
  }

  void _onComboTapped() {
    if (_lastSentGiftConfig == null) return;

    final config = _lastSentGiftConfig!;
    final bool isLucky = config['isLucky'] == true;
    if (!isLucky) return;

    final List<int> targets = List<int>.from(config['targetSeats'] as List);
    final bool isAll = config['isAll'] == true;
    final int unitPrice = (config['unitPrice'] as num).toInt();
    final int sendCost = unitPrice;
    final int seatCount =
        isAll ? _seats.where((s) => s != null).length : targets.length;
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
    for (int i = 0; i < max(1, seatCount); i++) {
      wonCoins += _rollLuckyWin(unitPrice);
    }
    _ensureSpeakerLoud();
    _playLuckyCoinSound();

    final String giftIconStr = (config['icon'] ?? "🎁").toString();
    final String giftAssetStr = (config['asset'] ?? "").toString();
    final String giftNameStr = (config['name'] ?? "Gift").toString();

    if (wonCoins > 0) {
      _showCompactWinBadge(wonCoins);
      final int multX = max(1, wonCoins ~/ max(1, unitPrice));
      _pushWinnerToMarquee(
          "🏆 ${widget.userName} won ${multX}x ($wonCoins Coins)!");
    }

    _postGiftToChat(
      widget.userName,
      "$giftNameStr (Combo x$nextCombo)",
      giftIconStr,
    );

    _fullscreenAnimStreamController.add(
      FullscreenGiftEvent(
        giftId: (config['giftId'] ?? "").toString(),
        giftName: "$giftNameStr (Combo x$nextCombo)",
        asset: giftAssetStr,
        giftIcon: giftIconStr,
        senderName: widget.userName,
      ),
    );

final int netChange = -totalSpend + wonCoins;
    FirebaseFirestore.instance.collection('users').doc(_resolvedUid).set({
      'coins': FieldValue.increment(netChange),
      'wealthExp': FieldValue.increment(totalSpend),
    }, SetOptions(merge: true)).catchError((_) {});

    const double rate = 0.04;
    final int ptsPerSeat = max(1, (sendCost * rate).round());
    final List<int> activeTargets = isAll
        ? <int>[
            for (int i = 0; i < _totalSeats; i++)
              if (_seats[i] != null) i
          ]
        : targets;

    for (final seatIdx in activeTargets) {
      if (seatIdx >= 0 && seatIdx < 30 && _seats[seatIdx] != null) {
        final targetUid = _seatUids[seatIdx] ?? _resolvedUid;
        FirebaseFirestore.instance.collection('users').doc(targetUid).set({
          'points': FieldValue.increment(ptsPerSeat),
          'charmExp': FieldValue.increment(ptsPerSeat),
        }, SetOptions(merge: true)).catchError((_) {});
      }
    }

    FirebaseFirestore.instance
        .collection('rooms')
        .doc(widget.roomId)
        .collection('events')
        .add({
      'type': 'gift',
      'senderId': _resolvedUid,
      'giftId': (config['giftId'] ?? "").toString(),
      'giftName': giftNameStr,
      'giftIcon': giftIconStr,
      'imageAsset': giftAssetStr,
      'multiplier': nextCombo,
      'seats': activeTargets,
      'totalCost': totalSpend,
      'isLucky': true,
      'wonCoins': wonCoins,
      'luckyMultiplier': wonCoins > 0 ? (wonCoins ~/ max(1, unitPrice)) : 0,
      'createdAt': FieldValue.serverTimestamp(),
    }).catchError((_) {});

    _executeMultiSeatSend(
      giftId: (config['giftId'] ?? "").toString(),
      targetSeats: targets,
      isAll: isAll,
      cost: sendCost,
      unitPrice: unitPrice,
      name: giftNameStr,
      asset: giftAssetStr,
      icon: giftIconStr,
      isLucky: true,
      wonCoins: wonCoins,
      fromCombo: true,
    );

    _startComboTimer();
  }

  void _openGiftSheet({int? preselectSeat}) async {
    dynamic dynVal = '';
    final sampleItem = {'seatIndex': 0, 'uid': dynVal, 'name': '', 'avatar': ''};
    final seatedList = [sampleItem]..clear();

    if (preselectSeat != null &&
        preselectSeat >= 0 &&
        preselectSeat < _totalSeats &&
        _seats[preselectSeat] != null) {
      seatedList.add({
        'seatIndex': preselectSeat,
        'uid': _seatUids[preselectSeat] ?? _resolvedUid,
        'name': _seats[preselectSeat]!,
        'avatar': '',
      });
    }

    for (int i = 0; i < _totalSeats; i++) {
      if (i == preselectSeat) continue;
      if (_seats[i] != null) {
        seatedList.add({
          'seatIndex': i,
          'uid': _seatUids[i] ?? _resolvedUid,
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

      if (isLucky && result.wonCoins > 0) {
        _showCompactWinBadge(result.wonCoins);
        final int multX = max(1, result.wonCoins ~/ max(1, result.gift.price));
        _pushWinnerToMarquee(
            "🏆 ${widget.userName} won ${multX}x (${result.wonCoins} Coins)!");
      }

      _ensureSpeakerLoud();
      _postGiftToChat(
        widget.userName,
        "${result.gift.name} x${result.multiplier}",
        result.gift.icon,
      );

_fullscreenAnimStreamController.add(
        FullscreenGiftEvent(
          giftId: result.gift.id,
          giftName: "${result.gift.name} x${result.multiplier}",
          asset: playAsset,
          giftIcon: result.gift.icon,
          senderName: widget.userName,
        ),
      );

      _executeMultiSeatSend(
        giftId: result.gift.id,
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
    String giftId = "",
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

    _addPkPointsForSeats(targetSeats, isAll, cost);

    final bool isFifthMilestone =
        isLucky && fromCombo && (_comboCount % 5 == 0);
    final int burstCount = isFifthMilestone ? 3 : 1;

    setState(() {
      if (!fromCombo) {
        if (isLucky) {
          _comboCount = 1;
          _showComboButton = true;
        } else {
          _comboCount = 0;
          _showComboButton = false;
          _comboTimer?.cancel();
        }
      }

      if (isAll) {
        bool anyOccupied = false;
        for (int i = 0; i < _totalSeats; i++) {
          if (_seats[i] != null) {
            anyOccupied = true;
            _seatGifts[i] += cost;
            for (int b = 0; b < burstCount; b++) {
              _triggerCenterGiftAnimation(asset, i, icon: icon, isToAll: true);
            }
          }
        }
        if (!anyOccupied) {
          _triggerCenterGiftAnimation(asset, 0, icon: icon, isToAll: true);
        }
      } else {
        for (final seatIdx in targetSeats) {
          if (seatIdx >= 0 && seatIdx < 30) {
            if (_seats[seatIdx] != null) {
              _seatGifts[seatIdx] += cost;
            }
            for (int b = 0; b < burstCount; b++) {
              _triggerCenterGiftAnimation(asset, seatIdx, icon: icon);
            }
          }
        }
      }
    });

    if (isLucky) {
      _lastSentGiftConfig = {
        'giftId': giftId,
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
    } else {
      _lastSentGiftConfig = null;
    }
  }

  void _cleanupAndLeave() {
    if (_hasCleanedUp) return;
    _hasCleanedUp = true;
    _heartbeatTimer?.cancel();
    RoomSessionManager.instance.clearSessionOnly();

    final roomRef =
        FirebaseFirestore.instance.collection('rooms').doc(widget.roomId);
    final Map<String, dynamic> removeSeats = {};
    for (int i = 0; i < 30; i++) {
      final bool isMySeat =
          (_seatUids[i] == _resolvedUid) ? true : (_mySeatIndex == i);
      if (isMySeat) {
        removeSeats['$i'] = FieldValue.delete();
      }
    }
    if (removeSeats.isNotEmpty) {
      roomRef
          .set({'activeSeats': removeSeats}, SetOptions(merge: true))
          .catchError((_) {});
    }

    _agoraService.leaveRoom();
  }

  @override
  void dispose() {
    _agoraService.removeListener(_onAgoraChanged);
    if (!_isMinimizing) {
      _cleanupAndLeave();
    }
    _winnerMarqueeTimer?.cancel();

_pkTickerTimer?.cancel();
    _luckyWinToastTimer?.cancel();
    _walletSubscription?.cancel();
    _roomLiveSubscription?.cancel();
    _eventsSubscription?.cancel();
    _chatSubscription?.cancel();
    _redPacketSubscription?.cancel();
    _speakingWaveController.dispose();
    _comboRingController.dispose();
    _entryMarqueeController.dispose();
    _comboTimer?.cancel();
    _audioPlayer.dispose();
    _musicPlayer.dispose();
    _fullscreenAnimStreamController.close();
    for (var g in _activeFlyingGifts) {
      g.controller.dispose();
    }
    _chatController.dispose();
    _chatScrollController.dispose();
    super.dispose();
  }

  bool _isGoldenSeat(int index) {
    return index >= 1 && index <= _goldenSeatsCount;
  }

  Color _getSeatFrameColor(int index, bool isOccupied, bool isSpeaking) {
    if (isSpeaking) return kGoldBright;
    if (index == 0) return kGoldBright;
    if (_isGoldenSeat(index)) return kGoldBright;
    if (!isOccupied) return Colors.white38;
    final frame = _seatFrames[index];
    if (frame == 'cyber_neon') return const Color(0xFF00E5FF);
    if (frame == 'emerald_vip') return const Color(0xFF00E676);
    if (frame == 'royal_fire') return const Color(0xFFFFAB00);
    return kMintLive;
  }

  Widget _buildSpeakingRippleRings(double seatDimension) {
    final double maxRingSize = seatDimension * 1.26;
    final double offset = -(maxRingSize - seatDimension) / 2;

    return Positioned(
      left: offset,
      top: offset,
      width: maxRingSize,
      height: maxRingSize,
      child: IgnorePointer(
        child: AnimatedBuilder(
          animation: _speakingWaveController,
          builder: (context, child) {
            final double w1 = _speakingWaveController.value;
            final double w2 = (_speakingWaveController.value + 0.5) % 1.0;

            final double size1 = seatDimension * (1.0 + (0.25 * w1));
            final double size2 = seatDimension * (1.0 + (0.25 * w2));
            final double op1 = (0.85 * (1.0 - w1)).clamp(0.0, 1.0);
            final double op2 = (0.85 * (1.0 - w2)).clamp(0.0, 1.0);

            return Stack(
              alignment: Alignment.center,
              children: [
                Container(
                  width: size1,
                  height: size1,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: kGoldBright.withOpacity(op1),
                      width: 1.6,
                    ),
                  ),
                ),
                Container(
                  width: size2,
                  height: size2,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: kGoldBright.withOpacity(op2),
                      width: 1.4,
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildSingleSeat({
    required int index,
    required double seatDimension,
    required double nameFontSize,
    required double badgeFontSize,
  }) {
    final occupier = _seats[index];
    final isOccupied = occupier != null;
    final isMuted = _seatMutes[index];
    final isSpeaking =
        isOccupied && !isMuted && _speakingSeatIndices.contains(index);
    final giftsCount = _seatGifts[index];
    final bool isHostSeat = index == 0;
    final bool isCrownSeat = _isGoldenSeat(index);
    final Color frameColor = _getSeatFrameColor(index, isOccupied, isSpeaking);
    final bool hasCustomFrame = isOccupied && _seatFrames[index] != 'default';
    final bool showGlow = isSpeaking
        ? true
        : (hasCustomFrame ? true : (isCrownSeat ? true : isHostSeat));

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
              if (isSpeaking) _buildSpeakingRippleRings(seatDimension),
              if (isHostSeat)
                Positioned(
                  top: -seatDimension * 0.22,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFFFFD700), Color(0xFFFF8F00)],
                      ),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      "HOST",
                      style: TextStyle(
                        color: Colors.black,
                        fontSize: (seatDimension * 0.16).clamp(6.5, 9.5),
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ),
              if (isCrownSeat)
                Positioned(
                  top: -seatDimension * 0.22,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 4, vertical: 0.5),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1A1205),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: kGoldBright, width: 0.9),
                    ),
                    child: Text(
                      "👑",
                      style: TextStyle(
                          fontSize: (seatDimension * 0.20).clamp(7.5, 12.0)),
                    ),
                  ),
                ),
              Container(
                key: _seatKeys[index],
                width: seatDimension,
                height: seatDimension,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: isOccupied
                        ? const [Color(0xFF2D2216), Color(0xFF120D08)]
                        : (isHostSeat
                            ? [
                                const Color(0xFF4A330D),
                                const Color(0xFF1E1405),
                              ]
                            : (isCrownSeat
                                ? [
                                    const Color(0xFF3A2A10).withOpacity(0.75),
                                    const Color(0xFF1A1308).withOpacity(0.85),
                                  ]
                                : [
                                    Colors.white.withOpacity(0.11),
                                    Colors.black.withOpacity(0.32),
                                  ])),
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  border: Border.all(
                    color: frameColor,
                    width: isSpeaking
                        ? 2.6
                        : (isHostSeat
                            ? 2.2
                            : (hasCustomFrame
                                ? 2.4
                                : (isCrownSeat
                                    ? 1.8
                                    : (isOccupied ? 1.9 : 1.2)))),
                  ),
                  boxShadow: [
                    if (showGlow)

BoxShadow(
                        color: frameColor.withOpacity(0.5),
                        blurRadius: 9,
                        spreadRadius: 1,
                      )
                    else
                      BoxShadow(
                        color: Colors.black.withOpacity(0.35),
                        blurRadius: 5,
                        offset: const Offset(0, 2),
                      ),
                  ],
                ),
                child: Center(
                  child: Icon(
                    isOccupied
                        ? Icons.person
                        : (isHostSeat
                            ? Icons.lock_person_rounded
                            : (_allMicsClosed
                                ? Icons.lock_outline
                                : Icons.chair_rounded)),
                    color: isOccupied
                        ? frameColor
                        : (isHostSeat
                            ? kGoldBright
                            : (isCrownSeat
                                ? kGoldBright
                                : kGoldBright.withOpacity(0.72))),
                    size: seatDimension * 0.45,
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
                      color:
                          isMuted ? Colors.redAccent : const Color(0xFF00C853),
                      border: Border.all(color: kRoomBgBottom, width: 1.2),
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
          const SizedBox(height: 3),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 2),
            child: Text(
              isOccupied ? occupier : "${index + 1}",
              style: TextStyle(
                color: isOccupied
                    ? Colors.white
                    : ((isCrownSeat || isHostSeat)
                        ? kGoldBright
                        : Colors.white70),
                fontSize: nameFontSize,
                fontWeight: FontWeight.w800,
                height: 1.05,
                shadows: const [
                  Shadow(
                    color: Colors.black87,
                    blurRadius: 3,
                    offset: Offset(0, 1),
                  ),
                ],
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Container(
            margin: const EdgeInsets.only(top: 2.0),
            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
            decoration: BoxDecoration(
              color: (giftsCount > 0 && isOccupied)
                  ? kGoldBlackBottom
                  : Colors.black.withOpacity(0.38),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: (giftsCount > 0 && isOccupied)
                    ? kGoldBright
                    : kGoldBorder.withOpacity(0.45),
                width: 0.8,
              ),
            ),
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text("🎁", style: TextStyle(fontSize: badgeFontSize * 0.90)),

const SizedBox(width: 2),
                  Text(
                    isOccupied ? "$giftsCount" : "0",
                    style: TextStyle(
                      color: (giftsCount > 0 && isOccupied)
                          ? kGoldBright
                          : Colors.white70,
                      fontSize: badgeFontSize,
                      fontWeight: FontWeight.bold,
                      height: 1.0,
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

  Widget _buildTopLuckyWinnerMarquee() {
    final String activeWinnerText = _winnerMarqueeItems.isNotEmpty
        ? _winnerMarqueeItems[_winnerMarqueeIndex % _winnerMarqueeItems.length]
        : "🏆 Win up to 500x in Lucky Gifts!";

    return Container(
      margin: const EdgeInsets.fromLTRB(12, 2, 12, 4),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xFF38260E),
            Color(0xFF5C3E14),
            Color(0xFF2B1D0A),
          ],
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: kGoldBright, width: 1.1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.35),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          const Icon(Icons.campaign_rounded, color: kGoldBright, size: 17),
          const SizedBox(width: 6),
          Expanded(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 450),
              transitionBuilder: (child, anim) {
                return FadeTransition(
                  opacity: anim,
                  child: SlideTransition(
                    position: Tween<Offset>(
                      begin: const Offset(0.15, 0.0),
                      end: Offset.zero,
                    ).animate(anim),
                    child: child,
                  ),
                );
              },
              child: Align(
                key: ValueKey<String>(activeWinnerText),
                alignment: Alignment.centerLeft,
                child: Text(
                  activeWinnerText,
                  style: const TextStyle(
                    color: Color(0xFFFFF3C4),
                    fontSize: 11.5,
                    fontWeight: FontWeight.w800,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
          ),
          const SizedBox(width: 6),
          GestureDetector(
            onTap: () => _openGiftSheet(),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 2.5),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFFFD700), Color(0xFFFF8F00)],
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    "Play",
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: 10.5,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  Icon(Icons.chevron_right_rounded,
                      color: Colors.black, size: 14),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPkScoreboard() {
    if (_pkData == null) return const SizedBox.shrink();

if (_pkData!['active'] != true) return const SizedBox.shrink();
    final int rScore = (_pkData!['redScore'] as num?)?.toInt() ?? 0;
    final int bScore = (_pkData!['blueScore'] as num?)?.toInt() ?? 0;
    final int total = rScore + bScore;
    final double redRatio =
        total == 0 ? 0.5 : (rScore / total).clamp(0.15, 0.85);
    final int mins = _pkSecondsLeft ~/ 60;
    final int secs = _pkSecondsLeft % 60;
    final String timeStr =
        "${mins.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}";

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 3),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: kGoldBlackBottom.withOpacity(0.9),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: kGoldBright, width: 1.2),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "${_pkData!['redName'] ?? 'Red'}: $rScore",
                style: const TextStyle(
                    color: Colors.redAccent,
                    fontSize: 11,
                    fontWeight: FontWeight.bold),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: kGoldBright,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  "PK $timeStr",
                  style: const TextStyle(
                      color: Colors.black,
                      fontSize: 10.5,
                      fontWeight: FontWeight.w900),
                ),
              ),
              Text(
                "$bScore :${_pkData!['blueName'] ?? 'Blue'}",
                style: const TextStyle(
                    color: Color(0xFF448AFF),
                    fontSize: 11,
                    fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 4),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: SizedBox(
              height: 7,
              child: Row(
                children: [
                  Expanded(
                    flex: (redRatio * 100).round(),
                    child: Container(color: Colors.redAccent),
                  ),
                  Expanded(
                    flex: ((1.0 - redRatio) * 100).round(),
                    child: Container(color: const Color(0xFF2979FF)),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMusicMiniBar() {
    if (_musicData == null) return const SizedBox.shrink();
    if (_musicData!['isPlaying'] != true) return const SizedBox.shrink();
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: kGlassDark.withOpacity(0.9),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFFF4081), width: 1),
      ),
      child: Row(
        children: [
          const Icon(Icons.music_note, color: Color(0xFFFF4081), size: 16),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              "Playing: ${_musicData!['trackTitle'] ?? 'Room Music'}",
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.bold),
              overflow: TextOverflow.ellipsis,

),
          ),
          if (_isAdminUser)
            GestureDetector(
              onTap: () async {
                await FirebaseFirestore.instance
                    .collection('rooms')
                    .doc(widget.roomId)
                    .set({
                  'musicState': {'isPlaying': false}
                }, SetOptions(merge: true));
              },
              child: const Icon(Icons.stop_circle,
                  color: Colors.redAccent, size: 18),
            ),
        ],
      ),
    );
  }

  Widget _buildChatFilterPill(String label, int tabIdx) {
    final bool active = _chatFilterIndex == tabIdx;
    return GestureDetector(
      onTap: () => setState(() => _chatFilterIndex = tabIdx),
      child: Container(
        width: 44,
        margin: const EdgeInsets.only(bottom: 6),
        padding: const EdgeInsets.symmetric(vertical: 5),
        decoration: BoxDecoration(
          color: active ? kGoldBright : Colors.black.withOpacity(0.45),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: active ? kGoldBright : Colors.white24,
            width: 1,
          ),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              color: active ? Colors.black : Colors.white70,
              fontSize: 10.5,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
      ),
    );
  }

  dynamic _buildSeatedUsersList() {
    dynamic dynVal = '';
    final sampleItem = {'seatIndex': 0, 'uid': dynVal, 'name': ''};
    final list = [sampleItem]..clear();
    for (int i = 0; i < _totalSeats; i++) {
      if (_seats[i] != null) {
        list.add({
          'seatIndex': i,
          'uid': _seatUids[i] ?? '',
          'name': _seats[i]!,
        });
      }
    }
    return list;
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    final int comboTier = (_comboCount ~/ 5) + 1;
    final double comboScale =
        (1.0 + ((comboTier - 1) * 0.08)).clamp(1.0, 1.45);
    final String audioStatus = _agoraService.isChannelJoined
        ? "Audio: Live"
        : (_isConnecting ? "Connecting..." : "Audio: Wait");

    final List<RoomChatMessage> filteredMessages = _messages.where((m) {
      if (_chatFilterIndex == 1) return m.isSystem;
      if (_chatFilterIndex == 2) return !m.isSystem;
      return true;
    }).toList();

    final String announcementBody = _roomAnnouncement.isNotEmpty
        ? _roomAnnouncement
        : "Welcome to $_liveRoomTitle! Respect everyone, have fun, and enjoy the party 🎧";

    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) {
        if (!didPop && !_isMinimizing) {
          _minimizeRoom();
        }
      },
      child: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              kRoomBgTop,
              kRoomBgMid,
              kRoomBgBottom,
            ],
            stops: [0.0, 0.42, 1.0],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Scaffold(
          backgroundColor: Colors.transparent,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.keyboard_arrow_down_rounded,
                  color: Colors.white, size: 30),
              tooltip: "Minimize",
              onPressed: _minimizeRoom,
            ),
            iconTheme: const IconThemeData(color: Colors.white),
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [

Flexible(
                      child: Text(
                        _liveRoomTitle,
                        style: const TextStyle(
                          fontSize: 15.5,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                          shadows: [
                            Shadow(
                              color: Colors.black54,
                              blurRadius: 4,
                              offset: Offset(0, 1),
                            ),
                          ],
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (_roomPassword != null) ...[
                      const SizedBox(width: 4),
                      const Icon(Icons.lock, color: kGoldBright, size: 14),
                    ],
                  ],
                ),
                Text(
                  "$audioStatus • ID: ${widget.roomId}",
                  style: TextStyle(
                    fontSize: 10.5,
                    color: _agoraService.isChannelJoined
                        ? kMintLive
                        : Colors.white70,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            actions: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                margin: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: kGoldBlackBottom.withOpacity(0.85),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: kGoldBright, width: 1.2),
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
              PopupMenuButton<int>(
                icon: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    border: Border.all(color: kGoldBright, width: 1.2),
                    borderRadius: BorderRadius.circular(12),
                    color: kGoldBlackBottom.withOpacity(0.85),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.event_seat,
                          color: kGoldBright, size: 14),
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
                color: kGlassDark,
                onSelected: (int count) => _changeSeatCount(count),
                itemBuilder: (context) => _allowedSeatOptions
                    .map((int count) => PopupMenuItem<int>(
                          value: count,
                          child: Text(
                            "$count Seats Layout",

style: TextStyle(
                              color: count == _totalSeats
                                  ? kGoldBright
                                  : Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ))
                    .toList(),
              ),
              IconButton(
                icon: const Icon(Icons.grid_view_rounded, color: Colors.white),
                onPressed: () {
                  RoomToolsSheet.show(
                    context,
                    roomId: widget.roomId,
                    roomTitle: _liveRoomTitle,
                    userName: widget.userName,
                    userUid: _resolvedUid,
                    userCoins: _myCoins,
                    isHost: _isHostUser,
                    isAdmin: _isAdminUser,
                    isVoiceOn: _isRoomVoiceOn,
                    onToggleVoice: _toggleRoomIncomingVoice,
                    isAllMicClosed: _allMicsClosed,
                    currentPassword: _roomPassword,
                    admins: _roomAdmins,
                    seatedUsers: _buildSeatedUsersList(),
                    pkData: _pkData,
                    musicData: _musicData,
                    equippedFrame: _equippedFrame,
                    onFrameChanged: (newFrame) {
                      setState(() {
                        _equippedFrame = newFrame;
                        if (_mySeatIndex != null) {
                          _seatFrames[_mySeatIndex!] = newFrame;
                        }
                      });
                    },
                  );
                },
              ),
              IconButton(
                icon: const Icon(Icons.power_settings_new,
                    color: Colors.redAccent),
                onPressed: () {
                  _cleanupAndLeave();
                  Navigator.pop(context);
                },
              ),
            ],
          ),
          body: SafeArea(
            child: Stack(
              key: _roomStackKey,
              children: [
                Positioned(
                  top: -60,
                  left: 0,
                  right: 0,
                  child: IgnorePointer(
                    child: Container(
                      height: 240,
                      decoration: BoxDecoration(
                        gradient: RadialGradient(
                          colors: [
                            kMintLive.withOpacity(0.14),
                            kGoldBright.withOpacity(0.06),
                            Colors.transparent,
                          ],
                          radius: 0.85,
                        ),
                      ),
                    ),
                  ),
                ),
                Column(
                  children: [
                    _buildTopLuckyWinnerMarquee(),
                    _buildPkScoreboard(),
                    _buildMusicMiniBar(),
                    Expanded(
                      flex: 6,
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          final double areaW = constraints.maxWidth - 12.0;
                          final double areaH = constraints.maxHeight - 8.0;

                          final int goldenCount =
                              min(_goldenSeatsCount, max(0, _totalSeats - 1));
                          final int topRowCount = 1 + goldenCount;
                          final int regularStart = topRowCount;
                          final int regularCount =
                              max(0, _totalSeats - regularStart);
                          final int regularCols = _totalSeats <= 12 ? 4 : 6;
                          final int regularRows =
                              (regularCount / regularCols).ceil();
                          final int totalVisualRows = 1 + regularRows;

final double rowSpacing = 6.0;
                          final double usableH =
                              areaH - (rowSpacing * max(0, totalVisualRows - 1));
                          final double dynamicCellH = usableH / totalVisualRows;

                          final double nameFontSize =
                              (dynamicCellH * 0.14).clamp(8.5, 13.0);
                          final double badgeFontSize =
                              (dynamicCellH * 0.115).clamp(7.5, 11.5);
                          final double reservedLabelH =
                              nameFontSize + badgeFontSize + 18.0;

                          final int maxColsInAnyRow =
                              max(regularCols, topRowCount);
                          final double dynamicSeatDim = min(
                            (dynamicCellH - reservedLabelH).clamp(24.0, 96.0),
                            ((areaW / maxColsInAnyRow) * 0.70)
                                .clamp(24.0, 96.0),
                          );

                          return Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6.0, vertical: 4.0),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                Expanded(
                                  child: Row(
                                    children: List.generate(topRowCount, (idx) {
                                      return Expanded(
                                        child: Center(
                                          child: _buildSingleSeat(
                                            index: idx,
                                            seatDimension: dynamicSeatDim,
                                            nameFontSize: nameFontSize,
                                            badgeFontSize: badgeFontSize,
                                          ),
                                        ),
                                      );
                                    }),
                                  ),
                                ),
                                ...List.generate(regularRows, (r) {
                                  return Expanded(
                                    child: Padding(
                                      padding:
                                          const EdgeInsets.only(top: 4.0),
                                      child: Row(
                                        children:
                                            List.generate(regularCols, (c) {
                                          final int seatIdx = regularStart +
                                              (r * regularCols) +
                                              c;
                                          if (seatIdx >= _totalSeats) {
                                            return const Expanded(
                                                child: SizedBox.shrink());
                                          }
                                          return Expanded(
                                            child: Center(
                                              child: _buildSingleSeat(
                                                index: seatIdx,
                                                seatDimension: dynamicSeatDim,
                                                nameFontSize: nameFontSize,
                                                badgeFontSize: badgeFontSize,
                                              ),
                                            ),
                                          );
                                        }),

),
                                    ),
                                  );
                                }),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                    Expanded(
                      flex: 3,
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(10, 4, 54, 4),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                _buildChatFilterPill("All", 0),
                                _buildChatFilterPill("Room", 1),
                                _buildChatFilterPill("Chat", 2),
                              ],
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: ListView.builder(
                                controller: _chatScrollController,
                                physics: const BouncingScrollPhysics(),
                                padding: const EdgeInsets.only(bottom: 6),
                                itemCount: filteredMessages.length + 1,
                                itemBuilder: (context, index) {
                                  if (index == 0) {
                                    return Container(
                                      margin:
                                          const EdgeInsets.only(bottom: 4.0),
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 10.0, vertical: 6.0),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF1F2B3E)
                                            .withOpacity(0.92),
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(
                                          color: kGoldBright.withOpacity(0.75),
                                          width: 1.0,
                                        ),
                                      ),
                                      child: RichText(
                                        text: TextSpan(
                                          children: [
                                            const TextSpan(
                                              text: "📢 Announcement: ",
                                              style: TextStyle(
                                                color: kGoldBright,
                                                fontWeight: FontWeight.w900,
                                                fontSize: 11.5,
                                              ),
                                            ),
                                            TextSpan(
                                              text: announcementBody,
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontWeight: FontWeight.w600,
                                                fontSize: 11.5,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    );
                                  }

final item = filteredMessages[index - 1];
                                  return Align(
                                    alignment: Alignment.centerLeft,
                                    child: Container(
                                      margin: const EdgeInsets.symmetric(
                                          vertical: 2.5),
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 10.0, vertical: 5.0),
                                      decoration: BoxDecoration(
                                        color: item.isSystem
                                            ? const Color(0xFF281F12)
                                                .withOpacity(0.88)
                                            : Colors.black.withOpacity(0.42),
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(
                                          color: item.isSystem
                                              ? kGoldBright.withOpacity(0.75)
                                              : Colors.white.withOpacity(0.16),
                                          width: 0.9,
                                        ),
                                      ),
                                      child: RichText(
                                        text: TextSpan(
                                          children: [
                                            if (item.isSystem)
                                              const WidgetSpan(
                                                child: Padding(
                                                  padding: EdgeInsets.only(
                                                      right: 4.0),
                                                  child: Icon(
                                                    Icons.campaign,
                                                    color: kGoldBright,
                                                    size: 13.5,
                                                  ),
                                                ),
                                              ),
                                            TextSpan(
                                              text: "${item.sender}: ",
                                              style: TextStyle(
                                                color: item.isSystem
                                                    ? kGoldBright
                                                    : kMintLive,
                                                fontWeight: FontWeight.w900,
                                                fontSize: 12,
                                              ),
                                            ),
                                            TextSpan(
                                              text: item.message,
                                              style: TextStyle(
                                                color: item.isSystem
                                                    ? const Color(0xFFFFF3D1)
                                                    : Colors.white,
                                                fontWeight: FontWeight.w600,
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
                          ],
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: kGlassDark.withOpacity(0.95),
                        border: const Border(
                          top: BorderSide(color: kGoldBorder, width: 1.1),
                        ),
                        borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(20)),
                      ),
                      child: Row(
                        children: [
                          Container(
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: _mySeatIndex != null
                                  ? kGoldBlackBottom
                                  : Colors.white10,
                              border: Border.all(
                                color: _mySeatIndex != null
                                    ? kGoldBorder
                                    : Colors.white24,
                              ),
                            ),
                            child: IconButton(
                              icon: Icon(
                                _isMuted ? Icons.mic_off : Icons.mic,
                                color: _mySeatIndex != null
                                    ? (_isMuted
                                        ? Colors.redAccent
                                        : kGoldBright)
                                    : Colors.white54,
                                size: 24,
                              ),
                              onPressed:
                                  _mySeatIndex != null ? _toggleMute : null,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Container(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 14),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.09),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                    color: kGoldBorder.withOpacity(0.65)),
                              ),
                              child: TextField(
                                controller: _chatController,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                ),
                                cursorColor: kGoldBright,
                                decoration: const InputDecoration(
                                  hintText: "Say Hello...",
                                  hintStyle: TextStyle(color: Colors.white54),
                                  border: InputBorder.none,
                                  isDense: true,
                                  contentPadding:
                                      EdgeInsets.symmetric(vertical: 10),
                                ),
                                onSubmitted: (_) => _sendMessage(),
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Container(
                            decoration: BoxDecoration(

shape: BoxShape.circle,
                              color: kGoldBlackBottom,
                              border: Border.all(color: kGoldBorder),
                            ),
                            child: IconButton(
                              icon: const Icon(Icons.send_rounded,
                                  color: kGoldBright, size: 20),
                              onPressed: _sendMessage,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Container(
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: const LinearGradient(
                                colors: [Color(0xFFFFD700), Color(0xFFFF8F00)],
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: kGoldBright.withOpacity(0.35),
                                  blurRadius: 8,
                                ),
                              ],
                            ),
                            child: IconButton(
                              icon: const Icon(Icons.card_giftcard,
                                  color: Colors.black, size: 22),
                              onPressed: () => _openGiftSheet(),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                Positioned(
                  right: 10,
                  bottom: _showComboButton ? 148 : 74,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      GestureDetector(
                        onTap: _showHostTaskSheet,
                        child: Container(
                          width: 44,
                          padding: const EdgeInsets.symmetric(vertical: 6),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [kGoldBlackTop, kGoldBlackBottom],
                            ),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: kGoldBright, width: 1.2),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.45),
                                blurRadius: 8,
                              ),
                            ],
                          ),
                          child: const Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.assignment_turned_in_rounded,
                                  color: kGoldBright, size: 20),
                              SizedBox(height: 2),
                              Text(
                                "Task",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 9.5,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      GestureDetector(
                        onTap: _showQuickGameSheet,
                        child: Container(
                          width: 44,
                          padding: const EdgeInsets.symmetric(vertical: 6),

decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF00796B), Color(0xFF004D40)],
                            ),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: kMintLive, width: 1.2),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.45),
                                blurRadius: 8,
                              ),
                            ],
                          ),
                          child: const Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.sports_esports_rounded,
                                  color: kGoldBright, size: 20),
                              SizedBox(height: 2),
                              Text(
                                "Game",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 9.5,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                if (_activeRedPacket != null)
                  Positioned(
                    top: 64,
                    right: 14,
                    child: GestureDetector(
                      onTap: _claimRedPacket,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFFD32F2F), Color(0xFF7B1FA2)],
                          ),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: kGoldBright, width: 1.6),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.redAccent.withOpacity(0.5),
                              blurRadius: 10,
                            ),
                          ],
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text("🧧", style: TextStyle(fontSize: 26)),
                            Text(
                              "${_activeRedPacket!['senderName'] ?? 'VIP'}",
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold),
                            ),
                            Container(
                              margin: const EdgeInsets.only(top: 3),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: kGoldBright,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Text(
                                "GRAB",
                                style: TextStyle(
                                    color: Colors.black,
                                    fontSize: 9.5,

fontWeight: FontWeight.w900),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                if (_luckyWinToast != null)
                  Positioned(
                    top: 42,
                    left: 0,
                    right: 0,
                    child: Center(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 5),
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
                    bottom: 195,
                    left: 0,
                    right: 0,
                    child: SlideTransition(
                      position: _entryMarqueeAnimation,
                      child: Center(
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 5),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF00897B), Color(0xFF004D40)],
                            ),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: kGoldBright, width: 1.3),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.5),
                                blurRadius: 8,
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 7, vertical: 1.5),
                                decoration: BoxDecoration(
                                  color: kGoldBright,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(
                                  _entryBannerLevel,
                                  style: const TextStyle(
                                    color: Colors.black,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 7),
                              Text(
                                _entryBannerText!,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),

],
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

                      Offset? exactTarget;
                      if (gift.targetSeatIndex >= 0 &&
                          gift.targetSeatIndex < _seatKeys.length) {
                        final seatCtx =
                            _seatKeys[gift.targetSeatIndex].currentContext;
                        final stackCtx = _roomStackKey.currentContext;
                        if (seatCtx != null && stackCtx != null) {
                          final seatBox =
                              seatCtx.findRenderObject() as RenderBox?;
                          final stackBox =
                              stackCtx.findRenderObject() as RenderBox?;
                          if (seatBox != null &&
                              seatBox.hasSize &&
                              stackBox != null &&
                              stackBox.hasSize) {
                            final globalCenter = seatBox.localToGlobal(
                              Offset(seatBox.size.width / 2,
                                  seatBox.size.height / 2),
                            );
                            exactTarget = stackBox.globalToLocal(globalCenter);
                          }
                        }
                      }

                      final double targetX =
                          exactTarget?.dx ?? (size.width * 0.5);
                      final double targetY =
                          exactTarget?.dy ?? (size.height * 0.25);

                      final currentX = centerX + (targetX - centerX) * t;
                      final currentY = centerY + (targetY - centerY) * t;
                      final scale = 1.75 - (0.95 * t);

                      final bool isImageAsset = gift.asset.isNotEmpty &&
                          !gift.asset.toLowerCase().endsWith('.mp4');

                      return Positioned(
                        left: currentX - 60,
                        top: currentY - 60,
                        child: Opacity(
                          opacity: (1.0 - (t * 0.20)).clamp(0.0, 1.0),
                          child: Transform.scale(
                            scale: scale.clamp(0.55, 2.0),
                            child: isImageAsset
                                ? Image.asset(
                                    gift.asset,
                                    width: 120,
                                    height: 120,
                                    fit: BoxFit.contain,
                                    errorBuilder: (c, e, s) => Text(
                                      gift.icon,
                                      style: const TextStyle(fontSize: 76),
                                    ),
                                  )
                                : Text(
                                    gift.icon,
                                    style: const TextStyle(fontSize: 76),
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
                    bottom: 66,

right: 14,
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
                                gradient: LinearGradient(
                                  colors: comboTier >= 2
                                      ? [
                                          const Color(0xFFB71C1C),
                                          const Color(0xFF4A0E0E)
                                        ]
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
                                    color: Colors.black.withOpacity(0.55),
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
        ),
      ),
    );
  }
}
