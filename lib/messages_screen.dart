import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'services/user_service.dart';
import 'call_screen.dart';

class MessagesScreen extends StatefulWidget {
  const MessagesScreen({Key? key}) : super(key: key);

  @override
  State<MessagesScreen> createState() => _MessagesScreenState();
}

class _MessagesScreenState extends State<MessagesScreen> {
  final UserService _userService = UserService();
  final TextEditingController _searchController = TextEditingController();
  IO.Socket? _globalSocket;

  String _selectedTab = 'All';
  bool _isSearching = false;
  Map<String, dynamic>? _foundUser;
  List<Map<String, dynamic>> _activeConversations = [];
  bool _isLoadingChats = true;

  @override
  void initState() {
    super.initState();
    _initGlobalSocket();
    _fetchRecentConversations();
  }

  void _initGlobalSocket() {
    _globalSocket = IO.io(
      UserService.serverUrl,
      IO.OptionBuilder()
          .setTransports(['websocket'])
          .enableAutoConnect()
          .build(),
    );

    _globalSocket?.onConnect((_) {
      _globalSocket?.emit('user_connected', _userService.userId);
    });

    _globalSocket?.on('receive_direct_message', (data) {
      if (!mounted) return;
      _fetchRecentConversations();
    });

    _globalSocket?.on('incoming_call', (data) {
      if (!mounted) return;
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => CallScreen(
            targetUserId: data['callerId'].toString(),
            targetUserName: data['callerName'] ?? 'Unknown Caller',
            channelName: data['channelName'] ?? 'call_room',
            isIncoming: true,
          ),
        ),
      );
    });
  }

  Future<void> _fetchRecentConversations() async {
    try {
      final url = Uri.parse('${UserService.serverUrl}/api/user-conversations?userId=${_userService.userId}');
      final res = await http.get(url).timeout(const Duration(seconds: 5));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        if (data['success'] == true && data['conversations'] != null && mounted) {
          setState(() {
            _activeConversations = List<Map<String, dynamic>>.from(data['conversations']);
            _isLoadingChats = false;
          });
          return;
        }
      }
    } catch (_) {}

    if (mounted) {
      setState(() => _isLoadingChats = false);
    }
  }

  Future<void> _handleSearch() async {
    final queryId = _searchController.text.trim();
    if (queryId.isEmpty) return;

    setState(() {
      _isSearching = true;
      _foundUser = null;
    });

    final result = await _userService.searchUser(queryId);

    setState(() {
      _isSearching = false;
      _foundUser = result;
    });

    if (result == null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('User not found with ID: $queryId')),
      );
    }
  }

  void _openChat(String peerId, String peerName) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ChatDetailScreen(
          currentUserId: _userService.userId,
          peerId: peerId,
          peerName: peerName,
        ),
      ),
    ).then((_) => _fetchRecentConversations());
  }

  void _startCall(String peerId, String peerName) {
    final channelName = 'call_${_userService.userId}_${peerId}_${DateTime.now().millisecondsSinceEpoch}';
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CallScreen(
          targetUserId: peerId,
          targetUserName: peerName,
          channelName: channelName,
          isIncoming: false,
        ),
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    _globalSocket?.disconnect();
    _globalSocket?.dispose();
    super.dispose();
  }

@override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F141C),
      appBar: AppBar(
        backgroundColor: const Color(0xFF161B26),
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'Message',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        children: [
          Row(
            children: [
              _buildFilterChip('All'),
              const SizedBox(width: 8),
              _buildFilterChip('Unread'),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            decoration: BoxDecoration(
              color: const Color(0xFF161B26),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white12),
            ),
            child: Row(
              children: [
                const Icon(Icons.search, color: Colors.white54, size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    style: const TextStyle(color: Colors.white, fontSize: 13),
                    decoration: const InputDecoration(
                      hintText: 'Enter User ID to start new chat...',
                      hintStyle: TextStyle(color: Colors.white38, fontSize: 12),
                      border: InputBorder.none,
                    ),
                    onSubmitted: (_) => _handleSearch(),
                  ),
                ),
                IconButton(
                  icon: _isSearching
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF00C9A7)),
                        )
                      : const Icon(Icons.arrow_forward, color: Color(0xFF00C9A7), size: 20),
                  onPressed: _handleSearch,
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          if (_foundUser != null) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF161B26),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFF00C9A7).withOpacity(0.5)),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    backgroundColor: const Color(0xFF00C9A7),
                    child: Text(
                      (_foundUser!['name'] ?? 'U')[0].toUpperCase(),
                      style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _foundUser!['name'] ?? 'User',
                          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                        Text(
                          'ID: ${_foundUser!['userId']}',
                          style: const TextStyle(color: Color(0xFF00C9A7), fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                  IconButton(

icon: const Icon(Icons.call, color: Color(0xFF00C9A7), size: 22),
                    onPressed: () {
                      _startCall(
                        _foundUser!['userId'].toString(),
                        _foundUser!['name'] ?? 'User',
                      );
                    },
                  ),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF00C9A7),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    ),
                    onPressed: () {
                      _openChat(
                        _foundUser!['userId'].toString(),
                        _foundUser!['name'] ?? 'User',
                      );
                    },
                    child: const Text('Chat', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
          ],
          _buildSystemCard(
            icon: Icons.laptop_chromebook,
            iconColor: const Color(0xFF00C9A7),
            bgColor: const Color(0xFF00C9A7).withOpacity(0.12),
            title: 'System Message',
            subtitle: 'Withdrawal received',
            time: '08-25 14:21:11',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SystemMessageDetailScreen()),
              );
            },
          ),
          _buildSystemCard(
            icon: Icons.notifications_active,
            iconColor: const Color(0xFF00E676),
            bgColor: const Color(0xFF00E676).withOpacity(0.12),
            title: 'Official Notification',
            subtitle: 'Hala 1st Anniversary',
            time: '',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const OfficialNotificationScreen()),
              );
            },
          ),
          _buildSystemCard(
            icon: Icons.receipt_long,
            iconColor: const Color(0xFFFF9100),
            bgColor: const Color(0xFFFF9100).withOpacity(0.12),
            title: 'Order Messages',
            subtitle: '',
            time: '',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const OrderMessagesScreen()),
              );
            },
          ),
          _buildSystemCard(
            icon: Icons.headset_mic,
            iconColor: const Color(0xFF00B0FF),
            bgColor: const Color(0xFF00B0FF).withOpacity(0.12),
            title: 'Customer Service',
            subtitle: '',
            time: '',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const CustomerServiceScreen()),
              );
            },
          ),
          const SizedBox(height: 12),
          const Divider(color: Colors.white10),
          const SizedBox(height: 6),
          if (_isLoadingChats)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(24.0),
                child: CircularProgressIndicator(color: Color(0xFF00C9A7), strokeWidth: 2),
              ),
            )
          else if (_activeConversations.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 40),
              child: Center(
                child: Column(
                  children: [
                    Icon(Icons.chat_bubble_outline, size: 48, color: Colors.white.withOpacity(0.15)),

const SizedBox(height: 12),
                    const Text(
                      'No messages yet',
                      style: TextStyle(color: Colors.white38, fontSize: 13),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Search a user ID above to start chatting.',
                      style: TextStyle(color: Colors.white24, fontSize: 11),
                    ),
                  ],
                ),
              ),
            )
          else
            ..._activeConversations.map((chat) {
              final peerName = chat['peerName'] ?? 'User';
              final peerId = chat['peerId']?.toString() ?? '';
              final lastMsg = chat['lastMessage'] ?? '';
              final time = chat['time'] ?? '';

              return ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                leading: CircleAvatar(
                  radius: 24,
                  backgroundColor: const Color(0xFF232838),
                  child: Text(
                    peerName.isNotEmpty ? peerName[0].toUpperCase() : 'U',
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                ),
                title: Text(
                  peerName,
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                ),
                subtitle: Text(
                  lastMsg,
                  style: const TextStyle(color: Colors.white54, fontSize: 12),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                trailing: Text(
                  time,
                  style: const TextStyle(color: Colors.white38, fontSize: 11),
                ),
                onTap: () {
                  _openChat(peerId, peerName);
                },
              );
            }).toList(),
          const SizedBox(height: 70),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label) {
    final bool isSelected = _selectedTab == label;
    return GestureDetector(
      onTap: () => setState(() => _selectedTab = label),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF00C9A7) : const Color(0xFF161B26),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? const Color(0xFF00C9A7) : Colors.white12,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.black : Colors.white70,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            fontSize: 12,
          ),
        ),
      ),
    );
  }

  Widget _buildSystemCard({
    required IconData icon,
    required Color iconColor,
    required Color bgColor,
    required String title,
    required String subtitle,
    required String time,
    required VoidCallback onTap,
  }) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      onTap: onTap,
      leading: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: bgColor,
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: iconColor, size: 24),
      ),
      title: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
          ),
          if (time.isNotEmpty)

Text(time, style: const TextStyle(color: Colors.white38, fontSize: 11)),
        ],
      ),
      subtitle: subtitle.isNotEmpty
          ? Text(
              subtitle,
              style: const TextStyle(color: Colors.white54, fontSize: 12),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            )
          : null,
    );
  }
}

class SystemMessageDetailScreen extends StatelessWidget {
  const SystemMessageDetailScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F141C),
      appBar: AppBar(
        backgroundColor: const Color(0xFF161B26),
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 18),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('System Message', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Center(
            child: Text('2026-08-25 14:21:11', style: TextStyle(color: Colors.white38, fontSize: 12)),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF161B26),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white10),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Withdrawal received', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                const SizedBox(height: 12),
                const Center(
                  child: Column(
                    children: [
                      Text('Amount', style: TextStyle(color: Colors.white54, fontSize: 12)),
                      SizedBox(height: 4),
                      Text(
                        'Br 1746.0',
                        style: TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.bold),
                      ),
                      SizedBox(height: 6),
                      Text('Done', style: TextStyle(color: Color(0xFF00C9A7), fontSize: 11, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
                const Divider(color: Colors.white10, height: 24),
                _buildRow('Order ID', '2026082513361672517539250336'),
                _buildRow('Applicant', 'KEDIR UMER'),
                _buildRow('Method', 'Telebirr'),
                _buildRow('Application Time', '2026-08-25 13:36:17'),
                _buildRow('Finish time', '2026-08-25 16:22:00'),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  height: 42,
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Color(0xFF00C9A7)),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(21)),
                    ),
                    onPressed: () {},
                    child: const Text('Contact payroll', style: TextStyle(color: Color(0xFF00C9A7), fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.white54, fontSize: 12)),
          Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
        ],
      ),
    );
  }
}

class OfficialNotificationScreen extends StatelessWidget {
  const OfficialNotificationScreen({Key? key}) : super(key: key);

  final List<Map<String, dynamic>> _events = const [
    {
      'title': 'Hala 1st Anniversary',
      'tag': 'Event Ended',
      'desc': 'Hala! One Year Louder.',
      'gradient': [Color(0xFF4A148C), Color(0xFF880E4F)],
    },
    {
      'title': 'Get Extra Bonus From Single Recharge',
      'tag': 'Event Ended',
      'desc': 'Claim your bonus after completing a recharge! Limited bonuses.',
      'gradient': [Color(0xFF0D47A1), Color(0xFF1976D2)],
    },
    {
      'title': 'Ramadan Mubarak',
      'tag': 'Event Ended',
      'desc': 'Complete the Daily Prayer check-in to claim decoration rewards.',
      'gradient': [Color(0xFFE65100), Color(0xFFF57C00)],
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F141C),
      appBar: AppBar(
        backgroundColor: const Color(0xFF161B26),
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 18),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Official Notification', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
      ),
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: _events.length,
        separatorBuilder: (_, __) => const SizedBox(height: 16),
        itemBuilder: (context, idx) {
          final ev = _events[idx];
          return Container(
            decoration: BoxDecoration(
              color: const Color(0xFF161B26),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white10),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  height: 120,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(colors: ev['gradient'] as List<Color>),
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                  ),
                  padding: const EdgeInsets.all(14),
                  alignment: Alignment.bottomLeft,
                  child: Text(
                    ev['title'],
                    style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(ev['title'], style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.white12,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(ev['tag'], style: const TextStyle(color: Colors.white54, fontSize: 10)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(ev['desc'], style: const TextStyle(color: Colors.white60, fontSize: 12)),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class OrderMessagesScreen extends StatelessWidget {
  const OrderMessagesScreen({Key? key}) : super(key: key);

@override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F141C),
      appBar: AppBar(
        backgroundColor: const Color(0xFF161B26),
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 18),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Order Messages', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
      ),
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inventory_2_outlined, size: 64, color: Colors.white24),
            SizedBox(height: 12),
            Text('No content yet', style: TextStyle(color: Colors.white54, fontSize: 14)),
          ],
        ),
      ),
    );
  }
}

class CustomerServiceScreen extends StatefulWidget {
  const CustomerServiceScreen({Key? key}) : super(key: key);

  @override
  State<CustomerServiceScreen> createState() => _CustomerServiceScreenState();
}

class _CustomerServiceScreenState extends State<CustomerServiceScreen> {
  final TextEditingController _msgCtrl = TextEditingController();
  final List<Map<String, dynamic>> _chatLogs = [
    {
      'isAgent': true,
      'text': 'Customer Service Hours (Mon-Fri, UTC+8 9:30AM-12:00PM). How can I help you?',
    },
  ];

  void _sendSupportMessage() {
    final t = _msgCtrl.text.trim();
    if (t.isEmpty) return;
    setState(() {
      _chatLogs.add({'isAgent': false, 'text': t});
      _msgCtrl.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F141C),
      appBar: AppBar(
        backgroundColor: const Color(0xFF161B26),
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 18),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Column(
          children: [
            Text('Support Service', style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold)),
            Text('Online', style: TextStyle(color: Color(0xFF00C9A7), fontSize: 11)),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _chatLogs.length,
              itemBuilder: (ctx, idx) {
                final item = _chatLogs[idx];
                final bool isAgent = item['isAgent'];
                return Align(
                  alignment: isAgent ? Alignment.centerLeft : Alignment.centerRight,
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: isAgent ? const Color(0xFF1E2433) : const Color(0xFF00C9A7),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
                    child: Text(
                      item['text'],
                      style: TextStyle(
                        color: isAgent ? Colors.white70 : Colors.black,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),

decoration: const BoxDecoration(
              color: Color(0xFF161B26),
              border: Border(top: BorderSide(color: Colors.white10)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _msgCtrl,
                    style: const TextStyle(color: Colors.white, fontSize: 13),
                    decoration: const InputDecoration(
                      hintText: 'Type a message...',
                      hintStyle: TextStyle(color: Colors.white38),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    ),
                    onSubmitted: (_) => _sendSupportMessage(),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.send, color: Color(0xFF00C9A7)),
                  onPressed: _sendSupportMessage,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class ChatDetailScreen extends StatefulWidget {
  final String currentUserId;
  final String peerId;
  final String peerName;

  const ChatDetailScreen({
    Key? key,
    required this.currentUserId,
    required this.peerId,
    required this.peerName,
  }) : super(key: key);

  @override
  State<ChatDetailScreen> createState() => _ChatDetailScreenState();
}

class _ChatDetailScreenState extends State<ChatDetailScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<Map<String, dynamic>> _messages = [];
  IO.Socket? _socket;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchChatHistory();
    _connectSocket();
  }

  void _connectSocket() {
    _socket = IO.io(
      UserService.serverUrl,
      IO.OptionBuilder()
          .setTransports(['websocket'])
          .enableAutoConnect()
          .build(),
    );

    _socket?.onConnect((_) {
      _socket?.emit('user_connected', widget.currentUserId);
    });

    _socket?.on('receive_direct_message', (data) {
      if (!mounted) return;
      if (data['senderId'].toString() == widget.peerId) {
        setState(() {
          _messages.add(Map<String, dynamic>.from(data));
        });
        _scrollToBottom();
      }
    });
  }

  Future<void> _fetchChatHistory() async {
    try {
      final url = Uri.parse(
        '${UserService.serverUrl}/api/chat-history?user1=${widget.currentUserId}&user2=${widget.peerId}',
      );
      final response = await http.get(url).timeout(const Duration(seconds: 6));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true && mounted) {
          setState(() {
            _messages.clear();
            _messages.addAll(List<Map<String, dynamic>>.from(data['messages'] ?? []));
            _isLoading = false;
          });
          _scrollToBottom();
          return;
        }
      }
    } catch (_) {}

    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  void _sendMessage() {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    final msgData = {
      'senderId': widget.currentUserId,
      'receiverId': widget.peerId,
      'text': text,
      'timestamp': DateTime.now().toIso8601String(),
    };

    _socket?.emit('send_direct_message', msgData);

    setState(() {
      _messages.add(msgData);
    });

    _messageController.clear();
    _scrollToBottom();
  }

  void _triggerCall() {
    final channelName = 'call_${widget.currentUserId}_${widget.peerId}_${DateTime.now().millisecondsSinceEpoch}';
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CallScreen(
          targetUserId: widget.peerId,
          targetUserName: widget.peerName,
          channelName: channelName,
          isIncoming: false,
        ),
      ),
    );
  }

void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  void dispose() {
    _socket?.disconnect();
    _socket?.dispose();
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F141C),
      appBar: AppBar(
        backgroundColor: const Color(0xFF161B26),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.peerName, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            Text('ID: ${widget.peerId}', style: const TextStyle(fontSize: 12, color: Color(0xFF00C9A7))),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.call, color: Color(0xFF00C9A7)),
            tooltip: 'Call User',
            onPressed: _triggerCall,
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: Color(0xFF00C9A7)))
                : _messages.isEmpty
                    ? Center(
                        child: Text(
                          'Say hello to ${widget.peerName}!',
                          style: const TextStyle(color: Colors.white38, fontSize: 13),
                        ),
                      )
                    : ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.all(16),
                        itemCount: _messages.length,
                        itemBuilder: (context, index) {
                          final msg = _messages[index];
                          final isMe = msg['senderId'].toString() == widget.currentUserId;

                          return Align(
                            alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                            child: Container(
                              margin: const EdgeInsets.only(bottom: 10),
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                              decoration: BoxDecoration(
                                color: isMe ? const Color(0xFF00C9A7) : const Color(0xFF161B26),
                                borderRadius: BorderRadius.only(
                                  topLeft: const Radius.circular(14),
                                  topRight: const Radius.circular(14),
                                  bottomLeft: isMe ? const Radius.circular(14) : Radius.zero,
                                  bottomRight: isMe ? Radius.zero : const Radius.circular(14),
                                ),
                                border: Border.all(
                                  color: isMe ? Colors.transparent : Colors.white10,
                                ),
                              ),
                              child: Text(
                                msg['text'] ?? '',
                                style: TextStyle(
                                  color: isMe ? Colors.black : Colors.white,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          );
                        },
                      ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),

color: const Color(0xFF161B26),
            child: SafeArea(
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _messageController,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        hintText: 'Type a message...',
                        hintStyle: const TextStyle(color: Colors.white38),
                        filled: true,
                        fillColor: Colors.white.withOpacity(0.05),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      ),
                      onSubmitted: (_) => _sendMessage(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  CircleAvatar(
                    backgroundColor: const Color(0xFF00C9A7),
                    child: IconButton(
                      icon: const Icon(Icons.send, color: Colors.black, size: 20),
                      onPressed: _sendMessage,
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
}
