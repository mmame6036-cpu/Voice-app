import 'package:flutter/material.dart';

class MessagesScreen extends StatefulWidget {
  const MessagesScreen({Key? key}) : super(key: key);

  @override
  State<MessagesScreen> createState() => _MessagesScreenState();
}

class _MessagesScreenState extends State<MessagesScreen> {
  int _selectedFilter = 0; // 0 for All, 1 for Unread

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
      backgroundColor: const Color(0xFFF6F8FA),
      appBar: AppBar(
        backgroundColor: const Color(0xFF00C9A7),
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'Message',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.chat_bubble_outline, color: Colors.white),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Chat messages'), duration: Duration(seconds: 1)),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.settings_outlined, color: Colors.white),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Message Settings'), duration: Duration(seconds: 1)),
              );
            },
          ),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(24),
            topRight: Radius.circular(24),
          ),
        ),
        child: Column(
          children: [
            // Filter Pills & Search
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => setState(() => _selectedFilter = 0),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: _selectedFilter == 0 ? const Color(0xFFE6F8F5) : Colors.transparent,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: _selectedFilter == 0 ? const Color(0xFF00C9A7) : Colors.black12,
                        ),
                      ),
                      child: Text(
                        'All',
                        style: TextStyle(
                          color: _selectedFilter == 0 ? const Color(0xFF00C9A7) : Colors.black54,

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
                        color: _selectedFilter == 1 ? const Color(0xFFE6F8F5) : Colors.transparent,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: _selectedFilter == 1 ? const Color(0xFF00C9A7) : Colors.black12,
                        ),
                      ),
                      child: Text(
                        'Unread',
                        style: TextStyle(
                          color: _selectedFilter == 1 ? const Color(0xFF00C9A7) : Colors.black54,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.search, color: Colors.black54),
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Search messages...'), duration: Duration(seconds: 1)),
                      );
                    },
                  ),
                ],
              ),
            ),

            const Divider(height: 1, color: Colors.black12),

            // Message Items List
            Expanded(
              child: ListView(
                children: [
                  // 1. System Message
                  _buildMessageTile(
                    title: 'System Message',
                    subtitle: 'Withdrawal received',
                    time: '08-25 14:21:11',
                    icon: Icons.markunread_mailbox_outlined,
                    iconBg: const Color(0xFF00A3FF),
                    onTap: () => _showNoticeDialog(
                      'System Message',
                      'Your withdrawal request has been received and processed successfully.',
                      Icons.markunread_mailbox_outlined,
                      const Color(0xFF00A3FF),
                    ),
                  ),

                  // 2. Official Notification
                  _buildMessageTile(
                    title: 'Official Notification',
                    subtitle: 'Hala 1st Anniversary',
                    time: '',
                    icon: Icons.notifications_none,
                    iconBg: const Color(0xFF00D287),
                    onTap: () => _showNoticeDialog(
                      'Official Notification',
                      'Welcome to our 1st Anniversary event! Join rooms, enjoy gifts, and win prizes.',
                      Icons.notifications_none,
                      const Color(0xFF00D287),
                    ),
                  ),

                  // 3. Order Messages
                  _buildMessageTile(
                    title: 'Order Messages',
                    subtitle: 'No order updates currently',
                    time: '',
                    icon: Icons.description_outlined,
                    iconBg: const Color(0xFFFF9500),
                    onTap: () => _showNoticeDialog(
                      'Order Messages',
                      'All your coin recharge and gift orders will appear here.',
                      Icons.description_outlined,
                      const Color(0xFFFF9500),
                    ),
                  ),

// 4. Customer Service
                  _buildMessageTile(
                    title: 'Customer Service',
                    subtitle: 'Contact support online',
                    time: '',
                    icon: Icons.headset_mic_outlined,
                    iconBg: const Color(0xFF00C9A7),
                    onTap: () => _showNoticeDialog(
                      'Customer Service',
                      'Our 24/7 support is ready to help you. Send your inquiries to the agency admin.',
                      Icons.headset_mic_outlined,
                      const Color(0xFF00C9A7),
                    ),
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
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black87),
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
          style: const TextStyle(color: Colors.black45, fontSize: 13),
        ),
      ),
      trailing: time.isNotEmpty
          ? Text(
              time,
              style: const TextStyle(color: Colors.black38, fontSize: 11),
            )
          : null,
      onTap: onTap,
    );
  }
}
