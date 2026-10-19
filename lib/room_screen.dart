import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'services/user_service.dart';
import 'services/agora_service.dart';
import 'services/socket_service.dart';

import 'widgets/room/room_background.dart';
import 'widgets/room/room_header.dart';
import 'widgets/room/room_seats_grid.dart';
import 'widgets/room/room_chat_feed.dart';
import 'widgets/room/room_bottom_bar.dart';
import 'widgets/room/gift_panel.dart';
import 'widgets/room/basic_tools_sheet.dart';

const String agoraAppId = "1523b6d3b8144281a1a21f28bbbd7fef";

class RoomScreen extends StatefulWidget {
  final String roomId;
  final String roomTitle;
  final String hostName;

  const RoomScreen({
    Key? key,
    required this.roomId,
    required this.roomTitle,
    required this.hostName,
  }) : super(key: key);

  @override
  State<RoomScreen> createState() => _RoomScreenState();
}

class _RoomScreenState extends State<RoomScreen> {
  final UserService _user = UserService();
  final SocketService _socket = SocketService();
  late final AgoraService _agora;

  bool _isMicMuted = false;
  int _currentSeatCount = 25;
  int _hostDiamonds = 0; // የሆስቱ የተሰበሰበ ዳይመንድ ቆጣሪ
  final TextEditingController _msgController = TextEditingController();

  Map<String, String>? _active3DGift;

  final List<Map<String, String>> _messages = [
    {
      'user': 'System',
      'text': 'Welcome to the live room! Please follow community rules.',
    },
  ];

  late List<Map<String, dynamic>> _seats;

  @override
  void initState() {
    super.initState();
    _agora = AgoraService();
    _initSeats(_currentSeatCount);
    _initSocket();
    _initAudio();
  }

  void _initSeats(int count) {
    _seats = List.generate(
      count,
      (index) => {
        'index': index + 1,
        'user': index == 0 ? widget.hostName : null,
        'userId': index == 0 ? widget.roomId : null,
        'isSpeaking': false,
        'isMuted': false,
        'diamonds': 0,
      },
    );
  }

  void _initSocket() {
    _socket.connect();
    _socket.joinRoom(widget.roomId);

    _socket.socket?.on('sync_room_seats', (data) {
      if (!mounted || data == null) return;
      setState(() {
        final Map<String, dynamic> seatsMap = Map<String, dynamic>.from(data);
        seatsMap.forEach((seatIdxStr, seatInfo) {
          final idx = int.tryParse(seatIdxStr);
          if (idx != null && idx >= 0 && idx < _seats.length) {
            _seats[idx]['user'] = seatInfo['userName'];
            _seats[idx]['userId'] = seatInfo['userId'];
          }
        });
      });
    });

    _socket.onChairActionReceived = (data) {
      if (!mounted) return;
      final int? chairIndex = data['chairIndex'] != null
          ? int.tryParse(data['chairIndex'].toString())
          : null;
      final String? action = data['action'];
      final String? uName = data['userName'];
      final String? uId = data['userId'];

      if (chairIndex == null  chairIndex < 0  chairIndex >= _seats.length) {
        return;
      }

      setState(() {
        if (action == 'take') {
          for (int i = 0; i < _seats.length; i++) {
            if (_seats[i]['userId'] == uId && i != chairIndex) {
              _seats[i]['user'] = null;
              _seats[i]['userId'] = null;
              _seats[i]['isSpeaking'] = false;
            }
          }
          _seats[chairIndex]['user'] = uName;
          _seats[chairIndex]['userId'] = uId;
          _messages.add({
            'user': 'System',
            'text': '$uName joined seat ${chairIndex + 1}',
          });
        } else if (action == 'leave') {
          if (_seats[chairIndex]['userId'] == uId) {
            _seats[chairIndex]['user'] = null;
            _seats[chairIndex]['userId'] = null;
            _seats[chairIndex]['isSpeaking'] = false;
            _messages.add({
              'user': 'System',
              'text': '$uName left seat ${chairIndex + 1}',
            });
          }
        }
      });
    };

_socket.onChatMessageReceived = (data) {
      if (!mounted) return;
      final String? sender = data['sender'] ?? data['userName'] ?? 'User';
      final String? text = data['text'] ?? data['message'];

      if (text != null && text.isNotEmpty) {
        setState(() {
          _messages.add({'user': sender!, 'text': text});
        });
      }
    };
  }

  Future<void> _initAudio() async {
    String token = '';
    try {
      final url = Uri.parse('${UserService.serverUrl}/api/get-token?channelName=${widget.roomId}');
      final res = await http.get(url).timeout(const Duration(seconds: 4));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        if (data['success'] == true && data['token'] != null) {
          token = data['token'];
        }
      }
    } catch (_) {}

    await _agora.initAgora(
      appId: agoraAppId,
      channelId: widget.roomId,
      onVolumeChanged: (speakers) {
        if (!mounted) return;
        setState(() {
          for (var seat in _seats) {
            seat['isSpeaking'] = false;
          }

          for (var speaker in speakers) {
            if (speaker.volume != null && speaker.volume! > 10) {
              final speakerUid = speaker.uid?.toString();

              if (speaker.uid == 0) {
                for (var seat in _seats) {
                  if (seat['userId'] == _user.userId) {
                    seat['isSpeaking'] = true;
                  }
                }
              } else {
                for (var seat in _seats) {
                  if (seat['userId'] != null && seat['userId'].toString() == speakerUid) {
                    seat['isSpeaking'] = true;
                  }
                }
              }
            }
          }
        });
      },
    );
  }

  void _handleSeatTap(int index) async {
    final seat = _seats[index];
    final currentUser = _user.userName;
    final currentUserId = _user.userId;

    if (seat['userId'] == currentUserId || seat['user'] == currentUser) {
      showModalBottomSheet(
        context: context,
        backgroundColor: const Color(0xFF131926),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        builder: (ctx) => Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.exit_to_app, color: Colors.redAccent),
                title: const Text(
                  'Leave Mic Seat',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                ),
                onTap: () async {
                  Navigator.pop(ctx);
                  await _agora.leaveMicSeat();
                  _socket.sendChairAction(
                    roomId: widget.roomId,
                    chairIndex: index,
                    action: 'leave',
                  );
                  setState(() {
                    seat['user'] = null;
                    seat['userId'] = null;
                    seat['isSpeaking'] = false;
                    _messages.add({
                      'user': 'System',
                      'text': '$currentUser left seat ${index + 1}',
                    });
                  });
                },
              ),
            ],
          ),
        ),
      );
      return;
    }

    if (seat['user'] != null && seat['user'].toString().isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Seat ${index + 1} is occupied by ${seat['user']}'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    for (var s in _seats) {
      if (s['userId'] == currentUserId) {
        s['user'] = null;
        s['userId'] = null;
        s['isSpeaking'] = false;
      }
    }

    _socket.sendChairAction(
      roomId: widget.roomId,
      chairIndex: index,
      action: 'take',
    );

setState(() {
      seat['user'] = currentUser;
      seat['userId'] = currentUserId;
      seat['isSpeaking'] = false;
      _messages.add({
        'user': 'System',
        'text': '$currentUser joined seat ${index + 1}',
      });
    });

    await _agora.joinMicSeat();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('You took seat ${index + 1} 🎤'),
        backgroundColor: const Color(0xFF00C9A7),
      ),
    );
  }

  void _sendMessage() {
    final text = _msgController.text.trim();
    if (text.isEmpty) return;

    _socket.sendChatMessage(roomId: widget.roomId, text: text);

    setState(() {
      _messages.add({'user': _user.userName, 'text': text});
      _msgController.clear();
    });
  }

  String _getGiftImage(String giftName) {
    // በ assets/gifts ፎልደር ውስጥ ያለውን ምስል በቀጥታ ይጠቀማል
    return 'assets/gifts/car.png';
  }

  void _openGifts() {
    GiftPanel.show(
      context,
      userCoins: _user.coins,
      seats: _seats,
      onSendGift: (name, price) {
        setState(() {
          if (_user.coins >= price) {
            _user.coins -= price;
          }

          _hostDiamonds += price;
          if (_seats.isNotEmpty) {
            _seats[0]['diamonds'] = (_seats[0]['diamonds'] ?? 0) + price;
          }

          _active3DGift = {
            'sender': _user.userName,
            'gift': name,
            'image': _getGiftImage(name),
          };
        });

        final giftText = '${_user.userName} sent a $name! (+${price} 💎)';
        _socket.sendChatMessage(roomId: widget.roomId, text: giftText);
        setState(() {
          _messages.add({
            'user': 'Announcement',
            'text': giftText,
          });
        });
      },
    );
  }

  void _openBasicTools() {
    BasicToolsSheet.show(
      context,
      currentSeats: _currentSeatCount,
      roomId: widget.roomId,
      hostId: widget.roomId,
      onSeatsChanged: (newCount) {
        setState(() {
          _currentSeatCount = newCount;
          _initSeats(newCount);
        });
      },
      onToggleAllMics: (isMutedAll) {
        setState(() {
          for (var s in _seats) {
            s['isMuted'] = isMutedAll;
          }
        });
      },
    );
  }

  void _toggleMic() async {
    final muted = await _agora.toggleMute();
    setState(() {
      _isMicMuted = muted;
    });
  }

  @override
  void dispose() {
    _agora.leaveRoom();
    _socket.disconnect();
    _msgController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          RoomBackground(
            child: Column(
              children: [
                RoomHeader(
                  roomTitle: widget.roomTitle,
                  roomId: widget.roomId,
                  hostName: widget.hostName,
                  onClose: () => Navigator.pop(context),
                ),
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                  decoration: BoxDecoration(
                    color: Colors.black45,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.cyanAccent.withOpacity(0.5)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.diamond, color: Colors.cyanAccent, size: 16),
                      const SizedBox(width: 6),
                      Text(
                        'Room Diamonds: $_hostDiamonds',
                        style: const TextStyle(
                          color: Colors.white,

fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      children: [
                        RoomSeatsGrid(
                          seats: _seats,
                          currentSeatCount: _currentSeatCount,
                          onSeatTap: _handleSeatTap,
                          onSeatCountChanged: (count) {
                            setState(() {
                              _currentSeatCount = count;
                              _initSeats(count);
                            });
                          },
                        ),
                      ],
                    ),
                  ),
                ),
                RoomChatFeed(messages: _messages),
                RoomBottomBar(
                  controller: _msgController,
                  isMicMuted: _isMicMuted,
                  onSendMessage: _sendMessage,
                  onToggleMic: _toggleMic,
                  onOpenGifts: _openGifts,
                  onOpenTools: _openBasicTools,
                  onOpenGame: () {},
                ),
              ],
            ),
          ),
          if (_active3DGift != null)
            _Live3DGiftDisplay(
              sender: _active3DGift!['sender']!,
              giftName: _active3DGift!['gift']!,
              imageUrl: _active3DGift!['image']!,
              onComplete: () {
                setState(() => _active3DGift = null);
              },
            ),
        ],
      ),
    );
  }
}

class _Live3DGiftDisplay extends StatefulWidget {
  final String sender;
  final String giftName;
  final String imageUrl;
  final VoidCallback onComplete;

  const _Live3DGiftDisplay({
    Key? key,
    required this.sender,
    required this.giftName,
    required this.imageUrl,
    required this.onComplete,
  }) : super(key: key);

  @override
  State<_Live3DGiftDisplay> createState() => _Live3DGiftDisplayState();
}

class _Live3DGiftDisplayState extends State<_Live3DGiftDisplay>
    with SingleTickerProviderStateMixin {
  late AnimationController _anim;
  late Animation<double> _scale;
  late Animation<double> _opacity;

  @override
  void initState() {
    super.initState();
    _anim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2600),
    );

    _scale = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween(begin: 0.1, end: 1.2).chain(CurveTween(curve: Curves.elasticOut)),
        weight: 40,
      ),
      TweenSequenceItem(tween: Tween(begin: 1.2, end: 1.0), weight: 30),
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.4), weight: 30),
    ]).animate(_anim);

    _opacity = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: 1.0), weight: 20),
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.0), weight: 60),
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.0), weight: 20),
    ]).animate(_anim);

    _anim.forward().then((_) => widget.onComplete());
  }

  @override
  void dispose() {
    _anim.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Center(
        child: AnimatedBuilder(
          animation: _anim,
          builder: (context, child) {
            return Opacity(
              opacity: _opacity.value,
              child: Transform.scale(
                scale: _scale.value,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(

width: 220,
                      height: 220,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF00C9A7).withOpacity(0.45),
                            blurRadius: 40,
                            spreadRadius: 8,
                          ),
                        ],
                      ),
                      child: Image.asset(
                        widget.imageUrl,
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) {
                          return const Icon(
                            Icons.card_giftcard,
                            color: Colors.amberAccent,
                            size: 100,
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF00C9A7), Color(0xFF6C5CE7)],
                        ),
                        borderRadius: BorderRadius.circular(22),
                        boxShadow: const [
                          BoxShadow(color: Colors.black45, blurRadius: 10),
                        ],
                      ),
                      child: Text(
                        '${widget.sender} sent ${widget.giftName}!',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
