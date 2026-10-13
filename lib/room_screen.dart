import 'package:flutter/material.dart';
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
}""

class _RoomScreenState extends State<RoomScreen> {
  final UserService _user = UserService();
  final SocketService _socket = SocketService();
  late final AgoraService _agora;

  bool _isMicMuted = false;
  int _currentSeatCount = 8;
  final TextEditingController _msgController = TextEditingController();

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

    // 1. ሰርቨሩን እና Socket ማገናኘት
    _initSocket();

    // 2. Agora ድምፅን ማገናኘት
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
      },
    );
  }

  void _initSocket() {
    _socket.connect();
    _socket.joinRoom(widget.roomId);

    // ሌሎች ስልኮች ወንበር ሲይዙ ወይም ሲለቁ በቅጽበት ይቀበላል
    _socket.onChairActionReceived = (data) {
      if (!mounted) return;
      final int? chairIndex = data['chairIndex'] != null
          ? int.tryParse(data['chairIndex'].toString())
          : null;
      final String? action = data['action'];
      final String? uName = data['userName'];
      final String? uId = data['userId'];

    if (chairIndex == null || chairIndex < 0  || chairIndex >= _seats.length) {
        return;
      }

      setState(() {
        if (action == 'take') {
          // ተጠቃሚው ሌላ ወንበር ላይ ከነበረ ነፃ ማድረግ
          for (var s in _seats) {
            if (s['userId'] == uId) {
              s['user'] = null;
              s['userId'] = null;
              s['isSpeaking'] = false;
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

    // ሌሎች ስልኮች የጻፉትን መልእክት በቅጽበት ይቀበላል
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
              for (var seat in _seats) {
                if (seat['user'] != null) {
                  seat['isSpeaking'] = true;
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

    // ወንበር ላይ የተቀመጠው ራሱ ከሆነ ለመልቀቅ
    if (seat['user'] == currentUser) {
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

    // ወንበሩ በሌላ ሰው ከተያዘ
    if (seat['user'] != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Seat ${index + 1} is occupied by ${seat['user']}'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    // ወንበሩን ለመያዝ ወደ ሰርቨር መላክ
    _socket.sendChairAction(
      roomId: widget.roomId,
      chairIndex: index,
      action: 'take',
    );

    for (var s in _seats) {
      if (s['user'] == currentUser) {
        s['user'] = null;
        s['userId'] = null;
        s['isSpeaking'] = false;
      }
    }

    setState(() {
      seat['user'] = currentUser;
      seat['userId'] = currentUserId;
      seat['isSpeaking'] = true;
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

    // መልእክቱን ወደ ሰርቨር መላክ
    _socket.sendChatMessage(roomId: widget.roomId, text: text);

    setState(() {
      _messages.add({'user': _user.userName, 'text': text});
      _msgController.clear();
    });
  }

  void _openGifts() {
    GiftPanel.show(
      context,
      userCoins: _user.coins,
      onSendGift: (name, price) {
        final giftText = '${_user.userName} sent a $name! 🎉';
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
    BasicToolsSheet.show(context);
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
      body: RoomBackground(
        child: Column(
          children: [
            RoomHeader(
              roomTitle: widget.roomTitle,
              roomId: widget.roomId,
              hostName: widget.hostName,
              onClose: () => Navigator.pop(context),
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
    );
  }
}
