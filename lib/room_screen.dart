import 'package:flutter/material.dart';
import 'services/user_service.dart';

import 'widgets/room/room_background.dart';
import 'widgets/room/room_header.dart';
import 'widgets/room/room_seats_grid.dart';
import 'widgets/room/room_chat_feed.dart';
import 'widgets/room/room_bottom_bar.dart';
import 'widgets/room/gift_panel.dart';
import 'widgets/room/basic_tools_sheet.dart';

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
    _initSeats(_currentSeatCount);
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

  void _handleSeatTap(int index) {
    final seat = _seats[index];
    final currentUser = _user.userName;
    final currentUserId = _user.userId;

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
                onTap: () {
                  Navigator.pop(ctx);
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

    if (seat['user'] != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Seat ${index + 1} is occupied by ${seat['user']}'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    setState(() {
      for (var s in _seats) {
        if (s['user'] == currentUser) {
          s['user'] = null;
          s['userId'] = null;
          s['isSpeaking'] = false;
        }
      }
      seat['user'] = currentUser;
      seat['userId'] = currentUserId;
      seat['isSpeaking'] = true;
      _messages.add({
        'user': 'System',
        'text': '$currentUser joined seat ${index + 1}',
      });
    });

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
        setState(() {
          _messages.add({
            'user': 'Announcement',
            'text': '${_user.userName} sent a $name! 🎉',
          });
        });
      },
    );
  }

  void _openBasicTools() {
    BasicToolsSheet.show(context);
  }

  void _toggleMic() {
    setState(() {
      _isMicMuted = !_isMicMuted;
    });
  }

  @override
  void dispose() {
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
