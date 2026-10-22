import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'services/user_service.dart';
import 'services/agora_service.dart';
import 'services/socket_service.dart';

import 'settings_screen.dart';
import 'store_screen.dart';
import 'backpack_screen.dart';
import 'level_screen.dart';
import 'support_screen.dart';
import 'invite_screen.dart';
import 'teen_patti_dialog.dart';

import 'widgets/room/room_background.dart';
import 'widgets/room/room_header.dart';
import 'widgets/room/room_seats_grid.dart';
import 'widgets/room/room_chat_feed.dart';
import 'widgets/room/gift_panel.dart';
import 'widgets/room/gift_overlay.dart';
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
  int _hostDiamonds = 0;
  final TextEditingController _msgController = TextEditingController();

  String _activeVerticalTab = 'Room'; // 'Room' or 'Chat'

  Map<String, dynamic>? _active3DGift;
  String? _jackpotBannerText;

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

    _socket.socket?.on('gift_sent', (data) {
      if (!mounted || data == null) return;
      final sender = data['sender'] ?? data['senderName'] ?? 'User';
      final giftName = data['giftName'] ?? 'Gift';
      final count = int.tryParse(data['count']?.toString() ?? '1') ?? 1;
      final diamondReward = int.tryParse(data['diamondReward']?.toString() ?? '0') ?? 0;
      final receiverId = data['receiverId'];

      setState(() {
        _hostDiamonds += diamondReward;
        if (_seats.isNotEmpty && (receiverId == null || receiverId == 'all' ||  receiverId == _seats[0]['userId'])) {
          _seats[0]['diamonds'] = (_seats[0]['diamonds'] ?? 0) + diamondReward;
        }

        _active3DGift = {
          'sender': sender,
          'gift': giftName,
          'count': count,
          'image': _getGiftImage(giftName),
        };

        _messages.add({
          'user': 'Announcement',
          'text': '$sender sent $giftName x$count! (+${diamondReward} 💎)',
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

      if (chairIndex == null || chairIndex < 0 || chairIndex >= _seats.length) {
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

    final bool isVerified = _user.isFaceVerified;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          isVerified
              ? 'Seat ${index + 1} taken! Task counter active.'
              : 'Seat ${index + 1} taken! (Face unverified: Task counter paused)',
        ),
        backgroundColor: isVerified ? const Color(0xFF00C9A7) : const Color(0xFF4A5568),
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
    final nameLower = giftName.toLowerCase();
    if (nameLower.contains('lollipop')) {
      return 'assets/gifts/3d-lollipop.png';
    } else if (nameLower.contains('rocket')) {
      return 'assets/gifts/icons8-rocket-94.png';
    } else if (nameLower.contains('car')) {
      return 'assets/gifts/3d-car.png';
    }
    return 'assets/gifts/3d-car.png';
  }

  void _openGifts() {
    GiftPanel.show(
      context,
      userCoins: _user.coins,
      seats: _seats,
      onSendGift: (name, price, count, isLucky, targetUserId) {
        final int totalCost = price * count;
        final int diamondReward = (totalCost * 0.70).round();

        _socket.socket?.emit('gift_sent', {
          'senderId': _user.userId,
          'senderName': _user.userName,
          'receiverId': targetUserId,
          'giftName': name,
          'giftPrice': price,
          'count': count,
          'isLucky': isLucky,
          'roomId': widget.roomId,
        });

        setState(() {
          _hostDiamonds += diamondReward;
          if (_seats.isNotEmpty && (targetUserId == 'all' || targetUserId == _seats[0]['userId'])) {
            _seats[0]['diamonds'] = (_seats[0]['diamonds'] ?? 0) + diamondReward;
          }

_active3DGift = {
            'sender': _user.userName,
            'gift': name,
            'count': count,
            'image': _getGiftImage(name),
          };
        });

        if (isLucky) {
          final rand = Random().nextInt(100);
          int multiplier = 0;

          if (rand < 5) {
            multiplier = 250;
          } else if (rand < 15) {
            multiplier = 50;
          } else if (rand < 35) {
            multiplier = 25;
          }

          if (multiplier > 0) {
            final int winCoins = price * multiplier;
            _user.coins += winCoins;

            final bannerMsg = '${_user.userName} so lucky and won ${multiplier}x the prize ($winCoins Coins)!';
            setState(() {
              _jackpotBannerText = bannerMsg;
            });

            _socket.sendChatMessage(roomId: widget.roomId, text: '🎉 $bannerMsg');

            Future.delayed(const Duration(seconds: 4), () {
              if (mounted) setState(() => _jackpotBannerText = null);
            });
          }
        }
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

  void _openRoomQuickMenu() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF161826),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const Text(
                'Room Menu & Quick Navigation',
                style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 4,
                mainAxisSpacing: 16,
                crossAxisSpacing: 12,
                childAspectRatio: 0.85,
                children: [
                  _buildQuickActionItem(
                    icon: Icons.shopping_bag,
                    color: Colors.amberAccent,
                    title: 'Store',
                    onTap: () {
                      Navigator.pop(ctx);
                      Navigator.push(context, MaterialPageRoute(builder: (_) => const StoreScreen()));
                    },
                  ),
                  _buildQuickActionItem(
                    icon: Icons.inventory_2_outlined,
                    color: Colors.deepOrangeAccent,
                    title: 'Backpack',
                    onTap: () {
                      Navigator.pop(ctx);
                      Navigator.push(context, MaterialPageRoute(builder: (_) => const BackpackScreen()));
                    },
                  ),
                  _buildQuickActionItem(
                    icon: Icons.military_tech,
                    color: Colors.amber,

title: 'Level',
                    onTap: () {
                      Navigator.pop(ctx);
                      Navigator.push(context, MaterialPageRoute(builder: (_) => const LevelScreen()));
                    },
                  ),
                  _buildQuickActionItem(
                    icon: Icons.shield_outlined,
                    color: Colors.cyanAccent,
                    title: 'Medal Wall',
                    onTap: () {
                      Navigator.pop(ctx);
                      Navigator.push(context, MaterialPageRoute(builder: (_) => const InternalMedalWallScreen()));
                    },
                  ),
                  _buildQuickActionItem(
                    icon: Icons.person_add_alt_1,
                    color: Colors.tealAccent,
                    title: 'Invite',
                    onTap: () {
                      Navigator.pop(ctx);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => InviteScreen(
                            userId: _user.userId,
                            userName: _user.userName.isNotEmpty ? _user.userName : 'User_${_user.userId}',
                            onRewardClaimed: (bonusCoins) {
                              _user.coins += bonusCoins;
                            },
                          ),
                        ),
                      );
                    },
                  ),
                  _buildQuickActionItem(
                    icon: Icons.support_agent,
                    color: const Color(0xFF904BE6),
                    title: 'Support',
                    onTap: () {
                      Navigator.pop(ctx);
                      Navigator.push(context, MaterialPageRoute(builder: (_) => const SupportScreen()));
                    },
                  ),
                  _buildQuickActionItem(
                    icon: Icons.settings,
                    color: Colors.blueGrey,
                    title: 'Settings',
                    onTap: () {
                      Navigator.pop(ctx);
                      Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsScreen()));
                    },
                  ),
                ],
              ),
              const SizedBox(height: 12),
            ],
          ),
        );
      },
    );
  }

  Widget _buildQuickActionItem({
    required IconData icon,
    required Color color,
    required String title,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(height: 6),
          Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w500),
          ),
        ],
      ),
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

Stack(
                  alignment: Alignment.centerRight,
                  children: [
                    RoomHeader(
                      roomTitle: widget.roomTitle,
                      roomId: widget.roomId,
                      hostName: widget.hostName,
                      onClose: () => Navigator.pop(context),
                    ),
                    Positioned(
                      right: 48,
                      top: 6,
                      child: IconButton(
                        icon: const Icon(Icons.dashboard_customize_outlined, color: Colors.white, size: 22),
                        tooltip: 'Room Menu',
                        onPressed: _openRoomQuickMenu,
                      ),
                    ),
                  ],
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
                  child: Row(
                    children: [
                      // VERTICAL SIDE TABS: Room, Chat, Game
                      Container(
                        width: 52,
                        margin: const EdgeInsets.only(left: 6, top: 10),
                        child: Column(
                          children: [
                            _buildVerticalTabItem(
                              title: 'Room',
                              icon: Icons.meeting_room_outlined,
                              isActive: _activeVerticalTab == 'Room',
                              onTap: () => setState(() => _activeVerticalTab = 'Room'),
                            ),
                            const SizedBox(height: 12),
                            _buildVerticalTabItem(
                              title: 'Chat',
                              icon: Icons.chat_bubble_outline,
                              isActive: _activeVerticalTab == 'Chat',
                              onTap: () => setState(() => _activeVerticalTab = 'Chat'),
                            ),
                            const SizedBox(height: 12),
                            _buildVerticalTabItem(
                              title: 'Game',
                              icon: Icons.sports_esports_outlined,
                              isActive: false,
                              onTap: () {
                                TeenPattiDialog.show(context, onBalanceUpdated: () {
                                  setState(() {});
                                });
                              },
                            ),
                          ],
                        ),
                      ),
                      // MAIN CONTENT AREA
                      Expanded(
                        child: _activeVerticalTab == 'Room'
                            ? SingleChildScrollView(

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
                              )
                            : Container(
                                margin: const EdgeInsets.symmetric(horizontal: 8),
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.black38,
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: RoomChatFeed(messages: _messages),
                              ),
                      ),
                    ],
                  ),
                ),
                if (_activeVerticalTab == 'Room')
                  SizedBox(
                    height: 110,
                    child: RoomChatFeed(messages: _messages),
                  ),
                // BOTTOM BAR: Say Hello & Controls
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: const BoxDecoration(
                    color: Color(0xFF10121D),
                    borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
                  ),
                  child: Row(
                    children: [
                      // Say Hello Input
                      Expanded(
                        child: Container(
                          height: 38,
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.08),
                            borderRadius: BorderRadius.circular(19),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.chat_outlined, color: Colors.white38, size: 16),
                              const SizedBox(width: 8),
                              Expanded(
                                child: TextField(
                                  controller: _msgController,
                                  style: const TextStyle(color: Colors.white, fontSize: 13),
                                  decoration: const InputDecoration(
                                    hintText: 'Say Hello...',
                                    hintStyle: TextStyle(color: Colors.white38, fontSize: 12),
                                    border: InputBorder.none,
                                    isDense: true,
                                    contentPadding: EdgeInsets.zero,
                                  ),
                                  onSubmitted: (_) => _sendMessage(),
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.send, color: Color(0xFF00C9A7), size: 16),
                                onPressed: _sendMessage,
                                padding: EdgeInsets.zero,

constraints: const BoxConstraints(),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      // Tool Sheet
                      IconButton(
                        icon: const Icon(Icons.more_horiz, color: Colors.white70, size: 20),
                        onPressed: _openBasicTools,
                      ),
                      // Mic Button
                      IconButton(
                        icon: Icon(
                          _isMicMuted ? Icons.mic_off : Icons.mic,
                          color: _isMicMuted ? Colors.redAccent : const Color(0xFF00C9A7),
                          size: 20,
                        ),
                        onPressed: _toggleMic,
                      ),
                      // Gift Button
                      IconButton(
                        icon: const Icon(Icons.card_giftcard, color: Colors.amberAccent, size: 22),
                        onPressed: _openGifts,
                      ),
                      // Game Button
                      IconButton(
                        icon: const Icon(Icons.casino_outlined, color: Colors.deepOrangeAccent, size: 22),
                        onPressed: () {
                          TeenPattiDialog.show(context, onBalanceUpdated: () {
                            setState(() {});
                          });
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          if (_jackpotBannerText != null)
            Positioned(
              top: 80,
              left: 20,
              right: 20,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFFFB300), Color(0xFFFF6F00)],
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: const [
                    BoxShadow(color: Colors.black45, blurRadius: 10, offset: Offset(0, 4)),
                  ],
                ),
                child: Row(
                  children: [
                    const Icon(Icons.emoji_events, color: Colors.white, size: 22),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _jackpotBannerText!,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          if (_active3DGift != null)
            Big3DGiftOverlay(
              senderName: _active3DGift!['sender']!,
              giftName: _active3DGift!['gift']!,
              imageUrl: _active3DGift!['image']!,
              count: _active3DGift!['count'] ?? 1,
              onFinish: () {
                setState(() => _active3DGift = null);
              },
            ),
        ],
      ),
    );
  }

  Widget _buildVerticalTabItem({
    required String title,
    required IconData icon,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 44,
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? const Color(0xFF00C9A7) : const Color(0xFF161826),

borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isActive ? const Color(0xFF00C9A7) : Colors.white12,
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              size: 18,
              color: isActive ? Colors.black : Colors.white70,
            ),
            const SizedBox(height: 3),
            Text(
              title,
              style: TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.bold,
                color: isActive ? Colors.black : Colors.white70,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class InternalMedalWallScreen extends StatefulWidget {
  const InternalMedalWallScreen({super.key});

  @override
  State<InternalMedalWallScreen> createState() => _InternalMedalWallScreenState();
}

class _InternalMedalWallScreenState extends State<InternalMedalWallScreen>
    with SingleTickerProviderStateMixin {
  final UserService _userService = UserService();
  late TabController _tabController;
  String _equippedMedalId = 'm1';

  final List<String> _categories = ['All', 'Gifting', 'Host', 'Social', 'Events'];

  late List<Map<String, dynamic>> _allMedals;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _categories.length, vsync: this);
    _initMedals();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _initMedals() {
    _allMedals = [
      {
        'id': 'm1',
        'title': 'First Gifter',
        'description': 'Sent the first gift in a voice room.',
        'category': 'Gifting',
        'icon': Icons.card_giftcard,
        'color': Colors.amber,
        'isUnlocked': true,
        'requirement': 'Send any gift in any live voice room.',
      },
      {
        'id': 'm2',
        'title': 'Big Spender',
        'description': 'Spent over 100,000 coins on gifts.',
        'category': 'Gifting',
        'icon': Icons.diamond,
        'color': Colors.purpleAccent,
        'isUnlocked': _userService.coins >= 100000,
        'requirement': 'Send 100,000 coins worth of gifts.',
      },
      {
        'id': 'm3',
        'title': 'Lucky Striker',
        'description': 'Hit a major multiplier on Lucky Gifts.',
        'category': 'Gifting',
        'icon': Icons.casino,
        'color': Colors.orangeAccent,
        'isUnlocked': true,
        'requirement': 'Win a multiplier higher than 50x in Lucky Gifts.',
      },
      {
        'id': 'm4',
        'title': 'Rising Star',
        'description': 'Streamed for over 10 active hours.',
        'category': 'Host',
        'icon': Icons.mic,
        'color': Colors.tealAccent,
        'isUnlocked': true,
        'requirement': 'Host voice rooms for more than 10 hours.',
      },
      {
        'id': 'm5',
        'title': 'Diamond Magnet',
        'description': 'Collected over 500,000 diamonds.',
        'category': 'Host',
        'icon': Icons.workspace_premium,
        'color': Colors.lightBlueAccent,
        'isUnlocked': false,
        'requirement': 'Accumulate 500,000 diamonds as a room host.',
      },
      {
        'id': 'm6',
        'title': 'Super Ambassador',
        'description': 'Successfully invited 10 active friends.',
        'category': 'Social',
        'icon': Icons.people,
        'color': Colors.greenAccent,
        'isUnlocked': true,
        'requirement': 'Invite 10 users through your invitation code.',
      },
      {
        'id': 'm7',
        'title': 'Loyal Guardian',
        'description': 'Active for 30 consecutive days.',
        'category': 'Social',
        'icon': Icons.verified_user,
        'color': Colors.amberAccent,
        'isUnlocked': false,

'requirement': 'Log into Nile Voice for 30 consecutive days.',
      },
      {
        'id': 'm8',
        'title': 'Carnival Champion',
        'description': 'Ranked top 3 in the weekly voice event.',
        'category': 'Events',
        'icon': Icons.emoji_events,
        'color': Colors.pinkAccent,
        'isUnlocked': false,
        'requirement': 'Finish in the Top 3 leaderboard of any official event.',
      },
    ];
  }

  void _showMedalDetails(Map<String, dynamic> medal) {
    final bool isEquipped = (_equippedMedalId == medal['id']);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF161B26),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: medal['isUnlocked'] ? (medal['color'] as Color).withOpacity(0.15) : Colors.white10,
                shape: BoxShape.circle,
              ),
              child: Icon(
                medal['icon'],
                size: 48,
                color: medal['isUnlocked'] ? medal['color'] : Colors.white30,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              medal['title'],
              style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              medal['description'],
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white70, fontSize: 13),
            ),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFF0D111A),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.white10),
              ),
              child: Text(
                'Requirement: ${medal['requirement']}',
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white54, fontSize: 11),
              ),
            ),
          ],
        ),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          if (medal['isUnlocked'])
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: isEquipped ? Colors.grey : const Color(0xFF00C9A7),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
              ),
              onPressed: () {
                setState(() {
                  _equippedMedalId = isEquipped ? '' : medal['id'];
                });
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(isEquipped ? 'Medal removed' : 'Equipped ${medal['title']}!'),
                    backgroundColor: const Color(0xFF00C9A7),
                  ),
                );
              },
              child: Text(
                isEquipped ? 'Unequip' : 'Wear Medal',
                style: TextStyle(
                  color: isEquipped ? Colors.white : Colors.black,
                  fontWeight: FontWeight.bold,
                ),
              ),
            )
          else
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Close', style: TextStyle(color: Colors.white54)),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final int unlockedCount = _allMedals.where((m) => m['isUnlocked'] == true).length;

return Scaffold(
      backgroundColor: const Color(0xFF0F101A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF161826),
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Medal Wall',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
        ),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          indicatorColor: const Color(0xFF00C9A7),
          labelColor: const Color(0xFF00C9A7),
          unselectedLabelColor: Colors.white54,
          indicatorWeight: 3,
          tabs: _categories.map((c) => Tab(text: c)).toList(),
        ),
      ),
      body: Column(
        children: [
          Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF2C1E57), Color(0xFF1A1A32)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white10),
            ),
            child: Row(
              children: [
                const Icon(Icons.emoji_events, color: Colors.amberAccent, size: 40),
                const SizedBox(width: 14),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Honor & Achievements',
                      style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Unlocked: $unlockedCount / ${_allMedals.length} Medals',
                      style: const TextStyle(color: Colors.white70, fontSize: 13),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: _categories.map((cat) {
                final list = cat == 'All'
                    ? _allMedals
                    : _allMedals.where((m) => m['category'] == cat).toList();

                return GridView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  itemCount: list.length,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 14,
                    childAspectRatio: 0.82,
                  ),
                  itemBuilder: (context, idx) {
                    final medal = list[idx];
                    final bool isEquipped = (_equippedMedalId == medal['id']);
                    final bool isUnlocked = medal['isUnlocked'] == true;

                    return GestureDetector(
                      onTap: () => _showMedalDetails(medal),
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: const Color(0xFF161826),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: isEquipped
                                ? const Color(0xFF00C9A7)
                                : (isUnlocked ? (medal['color'] as Color).withOpacity(0.3) : Colors.white10),

width: isEquipped ? 2 : 1,
                          ),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Stack(
                              alignment: Alignment.center,
                              children: [
                                CircleAvatar(
                                  radius: 26,
                                  backgroundColor: isUnlocked
                                      ? (medal['color'] as Color).withOpacity(0.15)
                                      : Colors.white10,
                                  child: Icon(
                                    medal['icon'],
                                    size: 26,
                                    color: isUnlocked ? medal['color'] : Colors.white24,
                                  ),
                                ),
                                if (!isUnlocked)
                                  const Icon(Icons.lock, size: 16, color: Colors.white54),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              medal['title'],
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: isUnlocked ? Colors.white : Colors.white38,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              isEquipped
                                  ? 'Active'
                                  : (isUnlocked ? 'Unlocked' : 'Locked'),
                              style: TextStyle(
                                color: isEquipped
                                    ? const Color(0xFF00C9A7)
                                    : (isUnlocked ? Colors.white54 : Colors.white24),
                                fontSize: 10,
                                fontWeight: isEquipped ? FontWeight.bold : FontWeight.normal,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}
