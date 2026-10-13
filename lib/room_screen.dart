import 'package:flutter/material.dart';
import 'services/user_service.dart';
import 'services/agora_service.dart';
import 'widgets/room/room_background.dart';
import 'widgets/room/room_header.dart';
import 'widgets/room/room_seats_grid.dart';
import 'widgets/room/room_chat_feed.dart';
import 'widgets/room/room_bottom_bar.dart';
import 'widgets/room/gift_panel.dart';
import 'widgets/room/basic_tools_sheet.dart';

const String agoraAppId = "YOUR_AGORA_APP_ID";

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
  final AgoraService _agora = AgoraService();
  bool _isMicMuted = false;
  int _currentSeatCount = 30;
  final TextEditingController _msgController = TextEditingController();

  final List<Map<String, String>> _messages = [];
  late List<Map<String, dynamic>> _seats;

  @override
  void initState() {
    super.initState();
    _seats = List.generate(
      30,
      (index) => {
        'index': index + 1,
        'user': index == 0 ? widget.hostName : null,
        'userId': index == 0 ? widget.roomId : null,
        'isSpeaking': false,
      },
    );
    _initAudio();
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

    if (seat['user'] == currentUser) {
      await _agora.leaveMicSeat();
      setState(() {
        seat['user'] = null;
        seat['userId'] = null;
        seat['isSpeaking'] = false;
      });
      return;
    }

    if (seat['user'] != null) return;

    for (var s in _seats) {
      if (s['user'] == currentUser) {
        s['user'] = null;
        s['userId'] = null;
        s['isSpeaking'] = false;
      }
    }

    setState(() {
      seat['user'] = currentUser;
      seat['userId'] = _user.userId;
    });
    await _agora.joinMicSeat();
  }

  void _toggleMic() async {
    final muted = await _agora.toggleMute();
    setState(() {
      _isMicMuted = muted;
    });
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
            'text': '${_user.userName} sent a $name!',
          });
        });
      },
    );
  }

  void _openBasicTools() {
    BasicToolsSheet.show(context);
  }

  @override
  void dispose() {
    _agora.leaveRoom();
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
