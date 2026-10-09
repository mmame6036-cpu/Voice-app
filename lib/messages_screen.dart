import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'main.dart';

class MessagesScreen extends StatefulWidget {
  const MessagesScreen({Key? key}) : super(key: key);

  @override
  State<MessagesScreen> createState() => _MessagesScreenState();
}

class _MessagesScreenState extends State<MessagesScreen> {
  int _selectedFilter = 0;
  final TextEditingController _searchController = TextEditingController();
  bool _isSearching = false;
  Map<String, dynamic>? _searchedUser;
  String _searchError = '';

  Future<void> _searchUserById(String searchId) async {
    if (searchId.trim().isEmpty) return;
    setState(() {
      _isSearching = true;
      _searchError = '';
      _searchedUser = null;
    });

    try {
      final client = HttpClient();
      client.connectionTimeout = const Duration(seconds: 8);
      final request = await client.getUrl(
        Uri.parse('${AppData.serverUrl}/api/search-user?userId=${searchId.trim()}'),
      );
      final response = await request.close();
      if (response.statusCode == 200) {
        final responseBody = await response.transform(utf8.decoder).join();
        final data = jsonDecode(responseBody);
        if (data['success'] == true && data['user'] != null) {
          setState(() {
            _searchedUser = data['user'];
            _isSearching = false;
          });
          return;
        }
      }
      setState(() {
        _searchError = 'ተጠቃሚው አልተገኘም (ID: $searchId)';
        _isSearching = false;
      });
    } catch (e) {
      setState(() {
        _searchError = 'የሰርቨር ግንኙነት ችግር አጋጥሟል';
        _isSearching = false;
      });
    }
  }

  void _openSearchDialog() {
    _searchController.clear();
    setState(() {
      _searchedUser = null;
      _searchError = '';
    });

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF161B26),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom + 20,
                left: 16,
                right: 16,
                top: 20,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'ተጠቃሚ በአይዲ (ID) ይፈልጉ',
                    style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _searchController,
                          keyboardType: TextInputType.number,
                          style: const TextStyle(color: Colors.white),
                          decoration: InputDecoration(
                            hintText: 'አይዲ ያስገቡ (ለምሳሌ: 1001)',
                            hintStyle: const TextStyle(color: Colors.white38),
                            filled: true,
                            fillColor: Colors.white.withOpacity(0.08),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                          ),
                        ),

),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF00C9A7),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        ),
                        onPressed: () async {
                          await _searchUserById(_searchController.text);
                          setModalState(() {});
                        },
                        child: _isSearching
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(color: Colors.black, strokeWidth: 2),
                              )
                            : const Text('ፈልግ', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                  if (_searchError.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Text(_searchError, style: const TextStyle(color: Colors.redAccent, fontSize: 13)),
                  ],
                  if (_searchedUser != null) ...[
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: const Color(0xFF00C9A7).withOpacity(0.4)),
                      ),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: const Color(0xFF00C9A7),
                          child: Text(
                            (_searchedUser!['name'] ?? 'U')[0].toUpperCase(),
                            style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
                          ),
                        ),
                        title: Text(
                          _searchedUser!['name'] ?? 'User',
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text(
                          'ID: ${_searchedUser!['userId']}',
                          style: const TextStyle(color: Color(0xFF00C9A7), fontSize: 12),
                        ),
                        trailing: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF00C9A7),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          onPressed: () {
                            Navigator.pop(ctx);
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => DirectChatScreen(
                                  targetUserId: _searchedUser!['userId'].toString(),
                                  targetUserName: _searchedUser!['name'] ?? 'User',
                                ),
                              ),
                            );
                          },
                          child: const Text('አውራ (Chat)', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            );
          },
        );
      },
    );
  }

void _showNoticeDialog(String title, String content, IconData icon, Color color) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E2430),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            CircleAvatar(
              backgroundColor: color.withOpacity(0.2),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        content: Text(
          content,
          style: const TextStyle(color: Colors.white70, fontSize: 14, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('OK', style: TextStyle(color: Color(0xFF00C9A7), fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0B0E14),
      appBar: AppBar(
        backgroundColor: const Color(0xFF161B26),
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'Message',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.person_search_rounded, color: Color(0xFF00C9A7), size: 26),
            tooltip: 'በአይዲ ፈልግ',
            onPressed: _openSearchDialog,
          ),
          const SizedBox(width: 6),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
          color: Color(0xFF161B26),
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(24),
            topRight: Radius.circular(24),
          ),
        ),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => setState(() => _selectedFilter = 0),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: _selectedFilter == 0 ? const Color(0xFF00C9A7).withOpacity(0.2) : Colors.transparent,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: _selectedFilter == 0 ? const Color(0xFF00C9A7) : Colors.white24,
                        ),
                      ),
                      child: Text(
                        'All',
                        style: TextStyle(
                          color: _selectedFilter == 0 ? const Color(0xFF00C9A7) : Colors.white60,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: () => setState(() => _selectedFilter = 1),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: _selectedFilter == 1 ? const Color(0xFF00C9A7).withOpacity(0.2) : Colors.transparent,
                        borderRadius: BorderRadius.circular(20),

border: Border.all(
                          color: _selectedFilter == 1 ? const Color(0xFF00C9A7) : Colors.white24,
                        ),
                      ),
                      child: Text(
                        'Unread',
                        style: TextStyle(
                          color: _selectedFilter == 1 ? const Color(0xFF00C9A7) : Colors.white60,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.search, color: Colors.white70),
                    onPressed: _openSearchDialog,
                  ),
                ],
              ),
            ),
            const Divider(height: 1, color: Colors.white10),
            Expanded(
              child: ListView(
                children: [
                  _buildMessageTile(
                    title: 'System Message',
                    subtitle: 'የመለያዎ አይዲ: ${AppData.currentUserId}',
                    time: 'Just now',
                    icon: Icons.markunread_mailbox_outlined,
                    iconBg: const Color(0xFF00A3FF),
                    onTap: () => _showNoticeDialog(
                      'System Message',
                      'የመለያዎ አይዲ ${AppData.currentUserId} ነው። ሌሎች ተጠቃሚዎች በዚህ ቁጥር ሊያገኙዎት ይችላሉ።',
                      Icons.markunread_mailbox_outlined,
                      const Color(0xFF00A3FF),
                    ),
                  ),
                  _buildMessageTile(
                    title: 'Official Notification',
                    subtitle: 'Nile Voice P2P Direct Messaging Live',
                    time: '',
                    icon: Icons.notifications_none,
                    iconBg: const Color(0xFF00D287),
                    onTap: () => _showNoticeDialog(
                      'Official Notification',
                      'በቀጥታ በአይዲ ፈልገው ከማንኛውም ተጠቃሚ ጋር በግል መወያየት ይችላሉ።',
                      Icons.notifications_none,
                      const Color(0xFF00D287),
                    ),
                  ),
                  _buildMessageTile(
                    title: 'Customer Service',
                    subtitle: 'Support Online (Owner: 1000)',
                    time: '',
                    icon: Icons.headset_mic_outlined,
                    iconBg: const Color(0xFF00C9A7),
                    onTap: () {
                      if (AppData.currentUserId != '1000') {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const DirectChatScreen(
                              targetUserId: '1000',
                              targetUserName: 'Master Admin (Kedir)',
                            ),
                          ),
                        );
                      } else {
                        _showNoticeDialog(
                          'Customer Service',
                          'እርስዎ ራሶ የሲስተሙ ዋና ባለቤት (ID 1000) ነዎት።',
                          Icons.headset_mic_outlined,
                          const Color(0xFF00C9A7),
                        );
                      }
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageTile({
    required String title,
    required String subtitle,
    required String time,
    required IconData icon,
    required Color iconBg,
    required VoidCallback onTap,
  }) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),

leading: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: iconBg,
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: Colors.white, size: 24),
      ),
      title: Row(
        children: [
          Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white),
          ),
          const SizedBox(width: 6),
          const Icon(Icons.verified, color: Color(0xFF00C9A7), size: 16),
        ],
      ),
      subtitle: Padding(
        padding: const EdgeInsets.only(top: 4),
        child: Text(
          subtitle,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(color: Colors.white54, fontSize: 13),
        ),
      ),
      trailing: time.isNotEmpty
          ? Text(
              time,
              style: const TextStyle(color: Colors.white38, fontSize: 11),
            )
          : null,
      onTap: onTap,
    );
  }
}

// 1-ON-1 DIRECT CHAT SCREEN
class DirectChatScreen extends StatefulWidget {
  final String targetUserId;
  final String targetUserName;

  const DirectChatScreen({
    Key? key,
    required this.targetUserId,
    required this.targetUserName,
  }) : super(key: key);

  @override
  State<DirectChatScreen> createState() => _DirectChatScreenState();
}

class _DirectChatScreenState extends State<DirectChatScreen> {
  IO.Socket? socket;
  final TextEditingController _msgController = TextEditingController();
  final List<Map<String, dynamic>> _messages = [];
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _connectSocket();
    _loadChatHistory();
  }

  void _connectSocket() {
    socket = IO.io(
      AppData.serverUrl,
      IO.OptionBuilder().setTransports(['websocket']).disableAutoConnect().build(),
    );
    socket?.connect();

    socket?.onConnect((_) {
      socket?.emit('user_connected', AppData.currentUserId);
    });

    socket?.on('receive_direct_message', (data) {
      if (mounted) {
        if (data['senderId'] == widget.targetUserId) {
          setState(() {
            _messages.add({
              'senderId': data['senderId'],
              'text': data['text'],
              'isMe': false,
            });
          });
          _scrollToBottom();
        }
      }
    });

    socket?.on('message_sent', (data) {
      if (mounted) {
        setState(() {
          _messages.add({
            'senderId': AppData.currentUserId,
            'text': data['text'],
            'isMe': true,
          });
        });
        _scrollToBottom();
      }
    });
  }

  Future<void> _loadChatHistory() async {
    try {
      final client = HttpClient();
      client.connectionTimeout = const Duration(seconds: 8);
      final request = await client.getUrl(
        Uri.parse('${AppData.serverUrl}/api/chat-history?user1=${AppData.currentUserId}&user2=${widget.targetUserId}'),
      );
      final response = await request.close();
      if (response.statusCode == 200) {
        final body = await response.transform(utf8.decoder).join();
        final data = jsonDecode(body);
        if (data['success'] == true && data['messages'] != null) {
          setState(() {
            _messages.clear();
            for (var m in data['messages']) {
              _messages.add({
                'senderId': m['senderId'],
                'text': m['text'],
                'isMe': m['senderId'] == AppData.currentUserId,
              });
            }
          });
          _scrollToBottom();
        }
      }
    } catch (e) {
      debugPrint('History load error: $e');
    }
  }

  void _sendMessage() {
    final text = _msgController.text.trim();
    if (text.isEmpty) return;

    socket?.emit('send_direct_message', {
      'senderId': AppData.currentUserId,
      'receiverId': widget.targetUserId,
      'text': text,
    });

    _msgController.clear();
  }

void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
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
    socket?.disconnect();
    socket?.dispose();
    _msgController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0B0E14),
      appBar: AppBar(
        backgroundColor: const Color(0xFF161B26),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.targetUserName, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            Text('ID: ${widget.targetUserId}', style: const TextStyle(fontSize: 11, color: Color(0xFF00C9A7))),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              itemCount: _messages.length,
              itemBuilder: (context, idx) {
                final msg = _messages[idx];
                final isMe = msg['isMe'] == true;
                return Align(
                  alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
