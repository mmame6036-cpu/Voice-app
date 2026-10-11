import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'services/user_service.dart';

class MessagesScreen extends StatefulWidget {
  const MessagesScreen({Key? key}) : super(key: key);

  @override
  State<MessagesScreen> createState() => _MessagesScreenState();
}

class _MessagesScreenState extends State<MessagesScreen> {
  final UserService _userService = UserService();
  final TextEditingController _searchController = TextEditingController();
  
  Map<String, dynamic>? _foundUser;
  bool _isSearching = false;
  String _statusMessage = 'Search users by their unique ID to start chatting';

  Future<void> _handleSearch() async {
    final queryId = _searchController.text.trim();
    if (queryId.isEmpty) return;

    setState(() {
      _isSearching = true;
      _foundUser = null;
      _statusMessage = 'Searching...';
    });

    final result = await _userService.searchUser(queryId);

    setState(() {
      _isSearching = false;
      if (result != null) {
        _foundUser = result;
        _statusMessage = '';
      } else {
        _statusMessage = 'User not found with ID: $queryId';
      }
    });
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
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F141C),
      appBar: AppBar(
        backgroundColor: const Color(0xFF161B26),
        elevation: 0,
        title: const Text('Messages', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          // Top Notification Shortcuts (System, Event, Customer Support)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildTopCategoryItem(
                icon: Icons.notifications_active,
                iconColor: const Color(0xFF7986CB),
                label: 'System',
                onTap: () {},
              ),
              _buildTopCategoryItem(
                icon: Icons.star,
                iconColor: const Color(0xFFFF8A80),
                label: 'Event',
                onTap: () {},
              ),
              _buildTopCategoryItem(
                icon: Icons.support_agent,
                iconColor: const Color(0xFFFFD54F),
                label: 'Customer',
                onTap: () {
                  _openChat('1000', 'Customer Support');
                },
              ),
            ],
          ),
          const SizedBox(height: 20),

          // User ID Search Bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            decoration: BoxDecoration(
              color: const Color(0xFF161B26),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white12),
            ),
            child: Row(
              children: [
                const Icon(Icons.search, color: Colors.white54),
                const SizedBox(width: 10),
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    keyboardType: TextInputType.text,
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(
                      hintText: 'Enter User ID to chat...',

hintStyle: TextStyle(color: Colors.white38),
                      border: InputBorder.none,
                    ),
                    onSubmitted: (_) => _handleSearch(),
                  ),
                ),
                IconButton(
                  icon: _isSearching
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF00C9A7)),
                        )
                      : const Icon(Icons.arrow_forward, color: Color(0xFF00C9A7)),
                  onPressed: _handleSearch,
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Searched User Card
          if (_foundUser != null)
            Container(
              padding: const EdgeInsets.all(16),
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
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _foundUser!['name'] ?? 'User',
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                        Text(
                          'User ID: ${_foundUser!['userId']}',
                          style: const TextStyle(color: Color(0xFF00C9A7), fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF00C9A7),
                      foregroundColor: Colors.black,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    onPressed: () {
                      _openChat(
                        _foundUser!['userId'].toString(),
                        _foundUser!['name'] ?? 'User',
                      );
                    },
                    child: const Text('Chat', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            )
          else
            Padding(
              padding: const EdgeInsets.only(top: 40),
              child: Center(
                child: Text(
                  _statusMessage,
                  style: const TextStyle(color: Colors.white38, fontSize: 14),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildTopCategoryItem({
    required IconData icon,
    required Color iconColor,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              color: const Color(0xFF161B26),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white12),
            ),
            child: Icon(icon, color: iconColor, size: 28),
          ),
          const SizedBox(height: 8),
          Text(label, style: const TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w500)),
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
    _socket = IO.io('https://voice-app-backend.onrender.com', <String, dynamic>{
      'transports': ['websocket'],
      'autoConnect': true,
    });

    _socket?.onConnect((_) {
      _socket?.emit('user_connected', widget.currentUserId);
    });

    _socket?.on('receive_direct_message', (data) {
      if (!mounted) return;
      if (data['senderId'] == widget.peerId) {
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
        'https://voice-app-backend.onrender.com/api/chat-history?user1=${widget.currentUserId}&user2=${widget.peerId}',
      );
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true && mounted) {
          setState(() {
            _messages.clear();
            _messages.addAll(List<Map<String, dynamic>>.from(data['messages']));
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
      ),
      body: Column(
        children: [
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: Color(0xFF00C9A7)))
                : ListView.builder(
                    controller: _scrollController,

padding: const EdgeInsets.all(16),
                    itemCount: _messages.length,
                    itemBuilder: (context, index) {
                      final msg = _messages[index];
                      final isMe = msg['senderId'] == widget.currentUserId;

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
