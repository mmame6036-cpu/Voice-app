import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class MessagesScreen extends StatefulWidget {
  const MessagesScreen({super.key});

  @override
  State<MessagesScreen> createState() => _MessagesScreenState();
}

class _MessagesScreenState extends State<MessagesScreen> {
  bool _showAll = true;
  bool _isSearching = false;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  int _unreadSystemCount = 1;
  int _unreadOfficialCount = 1;
  int _unreadSupportCount = 0;

  int _unreadNoticeCount = 2;
  int _unreadInteractionCount = 5;
  int _unreadFollowerCount = 3;

  String _latestSystemSubtitle = "WELCOME to NILE Live!";
  String _latestSystemTime = "08-10 19:29";

  String _latestOfficialSubtitle = "NILE Live 1st Anniversary & Bonus";
  String _latestOfficialTime = "Today";

  String _latestSupportSubtitle = "Tap to chat with NILE Live Support";
  String _latestSupportTime = "";

  StreamSubscription? _systemSub;
  StreamSubscription? _officialSub;
  StreamSubscription? _supportSub;

  String get _uid => FirebaseAuth.instance.currentUser?.uid ?? 'guest_user';

  @override
  void initState() {
    super.initState();
    _initFirebaseListeners();
  }

  @override
  void dispose() {
    _systemSub?.cancel();
    _officialSub?.cancel();
    _supportSub?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _initFirebaseListeners() {
    final db = FirebaseFirestore.instance;

    _systemSub = db
        .collection('users')
        .doc(_uid)
        .collection('system_messages')
        .orderBy('timestamp', descending: true)
        .snapshots()
        .listen((snap) {
      if (!mounted || snap.docs.isEmpty) return;
      int unread = 0;
      for (final d in snap.docs) {
        if (d.data()['unread'] == true) unread++;
      }
      final latest = snap.docs.first.data();
      setState(() {
        _unreadSystemCount = unread;
        _latestSystemSubtitle =
            (latest['subtitle'] ?? latest['title'] ?? _latestSystemSubtitle)
                .toString();
        _latestSystemTime = _formatTime(latest['timestamp']);
      });
    }, onError: (_) {});

    _officialSub = db
        .collection('official_notifications')
        .orderBy('timestamp', descending: true)
        .limit(10)
        .snapshots()
        .listen((snap) {
      if (!mounted || snap.docs.isEmpty) return;
      final latest = snap.docs.first.data();
      setState(() {
        _latestOfficialSubtitle =
            (latest['title'] ?? _latestOfficialSubtitle).toString();
        _latestOfficialTime = _formatTime(latest['timestamp']);
      });
    }, onError: (_) {});

    _supportSub = db
        .collection('support_chats')
        .doc(_uid)
        .snapshots()
        .listen((doc) {
      if (!mounted  !doc.exists  doc.data() == null) return;
      final data = doc.data()!;
      setState(() {
        _latestSupportSubtitle =
            (data['lastMessage'] ?? _latestSupportSubtitle).toString();
        _latestSupportTime = _formatTime(data['updatedAt']);
        _unreadSupportCount = (data['userUnread'] ?? 0) as int;
      });
    }, onError: (_) {});
  }

  String _formatTime(dynamic ts) {
    if (ts == null) return '';
    DateTime dt;
    if (ts is Timestamp) {
      dt = ts.toDate();
    } else if (ts is DateTime) {
      dt = ts;
    } else {
      return ts.toString();
    }
    final String m = dt.month.toString().padLeft(2, '0');
    final String d = dt.day.toString().padLeft(2, '0');
    final String h = dt.hour.toString().padLeft(2, '0');
    final String min = dt.minute.toString().padLeft(2, '0');
    return "$m-$d $h:$min";
  }

  Future<void> _markAllAsRead() async {
    setState(() {
      _unreadSystemCount = 0;
      _unreadOfficialCount = 0;
      _unreadSupportCount = 0;
      _unreadNoticeCount = 0;
      _unreadInteractionCount = 0;
      _unreadFollowerCount = 0;
    });

try {
      final db = FirebaseFirestore.instance;
      final sysSnap = await db
          .collection('users')
          .doc(_uid)
          .collection('system_messages')
          .where('unread', isEqualTo: true)
          .get();
      for (final doc in sysSnap.docs) {
        await doc.reference.update({'unread': false});
      }
      await db.collection('support_chats').doc(_uid).set(
        {'userUnread': 0},
        SetOptions(merge: true),
      );
    } catch (_) {}

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("All messages marked as read"),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _openSettingsSheet() {
    bool soundOn = true;
    bool systemAlertsOn = true;

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Message Settings",
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                activeColor: const Color(0xFF00B4DB),
                title: const Text("System & Official Alerts"),
                subtitle:
                    const Text("Receive wallet, security & event updates"),
                value: systemAlertsOn,
                onChanged: (v) => setModalState(() => systemAlertsOn = v),
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                activeColor: const Color(0xFF00B4DB),
                title: const Text("Message Sound & Vibration"),
                value: soundOn,
                onChanged: (v) => setModalState(() => soundOn = v),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final List channels = [
      {
        'icon': Icons.mark_email_unread_rounded,
        'bgColor': const Color(0xFF29B6F6),
        'title': 'System Message',
        'subtitle': _latestSystemSubtitle,
        'time': _latestSystemTime,
        'unread': _unreadSystemCount,
        'onTap': () async {
          setState(() => _unreadSystemCount = 0);
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => SystemMessageScreen(uid: _uid),
            ),
          );
        },
      },
      {
        'icon': Icons.notifications_none_rounded,
        'bgColor': const Color(0xFF26C6DA),
        'title': 'Official Notification',
        'subtitle': _latestOfficialSubtitle,
        'time': _latestOfficialTime,
        'unread': _unreadOfficialCount,
        'onTap': () async {
          setState(() => _unreadOfficialCount = 0);
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const OfficialNotificationScreen(),
            ),
          );
        },
      },
      {
        'icon': Icons.headset_mic_rounded,
        'bgColor': const Color(0xFF26A69A),
        'title': 'Customer Service',
        'subtitle': _latestSupportSubtitle,
        'time': _latestSupportTime,
        'unread': _unreadSupportCount,
        'onTap': () async {
          setState(() => _unreadSupportCount = 0);
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => CustomerServiceChatScreen(uid: _uid),
            ),
          );
        },
      },
    ];

final filteredChannels = channels.where((ch) {
      if (!_showAll && (ch['unread'] as int) == 0) return false;
      if (_searchQuery.isNotEmpty) {
        final q = _searchQuery.toLowerCase();
        final t = ch['title'].toString().toLowerCase();
        final s = ch['subtitle'].toString().toLowerCase();
        return t.contains(q) || s.contains(q);
      }
      return true;
    }).toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7F9),
      body: Column(
        children: [
          Container(
            padding: EdgeInsets.only(
              top: MediaQuery.of(context).padding.top + 8,
              left: 16,
              right: 12,
              bottom: 18,
            ),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Color(0xFF1BB3C8),
                  Color(0xFF4CD4C0),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Row(
              children: [
                const SizedBox(width: 72),
                const Expanded(
                  child: Center(
                    child: Text(
                      'Message',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 20,
                        letterSpacing: 0.4,
                      ),
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.mark_chat_read_outlined,
                      color: Colors.white, size: 23),
                  tooltip: 'Mark all as read',
                  onPressed: _markAllAsRead,
                ),
                IconButton(
                  icon: const Icon(Icons.settings_outlined,
                      color: Colors.white, size: 23),
                  tooltip: 'Settings',
                  onPressed: _openSettingsSheet,
                ),
              ],
            ),
          ),
          Expanded(
            child: Container(
              transform: Matrix4.translationValues(0, -10, 0),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
                    child: Row(
                      children: [
                        _buildTabButton('All', _showAll, () {
                          setState(() => _showAll = true);
                        }),
                        const SizedBox(width: 12),
                        _buildTabButton('Unread', !_showAll, () {
                          setState(() => _showAll = false);
                        }),
                        const Spacer(),
                        IconButton(
                          icon: Icon(
                            _isSearching ? Icons.close : Icons.search,
                            color: Colors.black54,
                            size: 25,
                          ),
                          onPressed: () {
                            setState(() {
                              _isSearching = !_isSearching;
                              if (!_isSearching) {
                                _searchQuery = '';
                                _searchController.clear();
                              }
                            });
                          },
                        ),
                      ],
                    ),
                  ),
                  if (_isSearching)

Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
                      child: TextField(
                        controller: _searchController,
                        autofocus: true,
                        onChanged: (val) => setState(() => _searchQuery = val),
                        decoration: InputDecoration(
                          hintText: 'Search messages...',
                          prefixIcon: const Icon(Icons.search, size: 20),
                          filled: true,
                          fillColor: const Color(0xFFF3F6F8),
                          contentPadding:
                              const EdgeInsets.symmetric(vertical: 0),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                    ),
                  Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _quickActionButton(
                          icon: Icons.notifications_active,
                          label: "Notice",
                          color: Colors.blueAccent,
                          badgeCount: _unreadNoticeCount,
                          onTap: () {
                            setState(() => _unreadNoticeCount = 0);
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const NoticeDetailScreen(),
                              ),
                            );
                          },
                        ),
                        _quickActionButton(
                          icon: Icons.favorite,
                          label: "Interaction",
                          color: Colors.pinkAccent,
                          badgeCount: _unreadInteractionCount,
                          onTap: () {
                            setState(() => _unreadInteractionCount = 0);
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const InteractionDetailScreen(),
                              ),
                            );
                          },
                        ),
                        _quickActionButton(
                          icon: Icons.person_add,
                          label: "Followers",
                          color: const Color(0xFF00C9A7),
                          badgeCount: _unreadFollowerCount,
                          onTap: () {
                            setState(() => _unreadFollowerCount = 0);
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const FollowersListScreen(),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                  const Divider(height: 1, color: Color(0xFFEEEEEE)),
                  Expanded(
                    child: filteredChannels.isEmpty
                        ? Center(
                            child: Text(
                              _showAll
                                  ? 'No matching messages'
                                  : 'No unread messages',

style: const TextStyle(
                                  color: Colors.black45, fontSize: 14),
                            ),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.only(top: 4),
                            itemCount: filteredChannels.length,
                            itemBuilder: (context, index) {
                              final item = filteredChannels[index];
                              return _buildMessageTile(
                                icon: item['icon'] as IconData,
                                iconBgColor: item['bgColor'] as Color,
                                title: item['title'] as String,
                                subtitle: item['subtitle'] as String,
                                time: item['time'] as String,
                                unreadCount: item['unread'] as int,
                                onTap: item['onTap'] as VoidCallback,
                              );
                            },
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

  Widget _buildTabButton(String text, bool isSelected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFD9F3F0) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          text,
          style: TextStyle(
            color: isSelected ? const Color(0xFF159A8C) : Colors.black54,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            fontSize: 15,
          ),
        ),
      ),
    );
  }

  Widget _buildMessageTile({
    required IconData icon,
    required Color iconBgColor,
    required String title,
    required String subtitle,
    required String time,
    required int unreadCount,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: const BoxDecoration(
          color: Colors.white,
          border:
              Border(bottom: BorderSide(color: Color(0xFFF3F4F6), width: 1)),
        ),
        child: Row(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: iconBgColor,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: Colors.white, size: 26),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          title,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                            color: Colors.black87,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 5),
                      const Icon(Icons.verified,
                          color: Color(0xFF29B6F6), size: 17),
                    ],
                  ),
                  if (subtitle.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      subtitle,

style: const TextStyle(
                        color: Colors.black45,
                        fontSize: 13.5,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                if (time.isNotEmpty)
                  Text(
                    time,
                    style: const TextStyle(color: Colors.black38, fontSize: 12),
                  ),
                const SizedBox(height: 6),
                if (unreadCount > 0)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                    decoration: const BoxDecoration(
                      color: Color(0xFFE53935),
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      unreadCount > 99 ? '99+' : '$unreadCount',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _quickActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required int badgeCount,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              if (badgeCount > 0)
                Positioned(
                  top: -2,
                  right: -2,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: Colors.redAccent,
                      shape: BoxShape.circle,
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 18,
                      minHeight: 18,
                    ),
                    child: Center(
                      child: Text(
                        badgeCount > 99 ? "99+" : "$badgeCount",
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 5),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }
}

class SystemMessageScreen extends StatefulWidget {
  final String uid;
  const SystemMessageScreen({super.key, required this.uid});

  @override
  State<SystemMessageScreen> createState() => _SystemMessageScreenState();
}

class _SystemMessageScreenState extends State<SystemMessageScreen> {
  final List _defaultSystemMessages = [
    {
      'title': 'WELCOME to NILE Live!',

'time': '08-10 19:29:14',
      'body':
          'Welcome to NILE Live Voice Party! Enjoy 30-seat live voice lounges, exciting mini-games like Ocean Hunt, and daily host rewards. Never share your OTP code or password with anyone.',
      'icon': Icons.verified_user,
      'color': const Color(0xFF29B6F6),
    },
    {
      'title': 'Account Security Reminder',
      'time': 'Yesterday 14:10',
      'body':
          'Official NILE Live administrators will never ask for your account password or Telebirr PIN. Keep your account safe.',
      'icon': Icons.security,
      'color': Colors.orangeAccent,
    },
  ];

  @override
  void initState() {
    super.initState();
    _markSystemMessagesRead();
  }

  Future<void> _markSystemMessagesRead() async {
    try {
      final snap = await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.uid)
          .collection('system_messages')
          .where('unread', isEqualTo: true)
          .get();
      for (final doc in snap.docs) {
        await doc.reference.update({'unread': false});
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7F9),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black, size: 18),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'System Message',
              style: TextStyle(
                  color: Colors.black,
                  fontSize: 17,
                  fontWeight: FontWeight.bold),
            ),
            SizedBox(width: 5),
            Icon(Icons.verified, color: Color(0xFF29B6F6), size: 17),
          ],
        ),
        centerTitle: true,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(widget.uid)
            .collection('system_messages')
            .orderBy('timestamp', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          final List items = [];

          if (snapshot.hasData && snapshot.data != null) {
            for (final doc in snapshot.data!.docs) {
              final raw = doc.data();
              final Map d = raw is Map ? raw : {};
              items.add({
                'title': (d['title'] ?? 'System Notice').toString(),
                'time': d['timestamp'] is Timestamp
                    ? (d['timestamp'] as Timestamp)
                        .toDate()
                        .toString()
                        .substring(0, 16)
                    : 'Recent',
                'body': (d['body'] ?? d['subtitle'] ?? '').toString(),
                'icon': Icons.campaign,
                'color': const Color(0xFF29B6F6),
              });
            }
          }
          items.addAll(_defaultSystemMessages);

          return ListView.builder(
            padding: const EdgeInsets.all(14),
            itemCount: items.length,
            itemBuilder: (context, index) {
              final msg = items[index];
              return Container(
                margin: const EdgeInsets.only(bottom: 14),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.03),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),

],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 18,
                          backgroundColor:
                              (msg['color'] as Color).withOpacity(0.15),
                          child: Icon(msg['icon'] as IconData,
                              color: msg['color'] as Color, size: 20),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            msg['title'].toString(),
                            style: const TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 15),
                          ),
                        ),
                        Text(
                          msg['time'].toString(),
                          style: const TextStyle(
                              color: Colors.black38, fontSize: 11),
                        ),
                      ],
                    ),
                    const Divider(height: 20, color: Color(0xFFF0F2F5)),
                    Text(
                      msg['body'].toString(),
                      style: const TextStyle(
                          fontSize: 13.5, color: Colors.black87, height: 1.45),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class OfficialNotificationScreen extends StatelessWidget {
  const OfficialNotificationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final List defaultAnnouncements = [
      {
        'title': 'NILE Live 1st Anniversary Celebration!',
        'time': 'Today',
        'subtitle': 'Join VIP voice rooms & win exclusive anniversary frames.',
        'details':
            'Celebrate NILE Live 1st Anniversary with us! Host daily voice rooms, send special anniversary gifts, and climb the leaderboard to win VIP badges, entrance vehicles, and bonus coins.',
        'icon': Icons.celebration,
        'color': const Color(0xFF26C6DA),
      },
      {
        'title': 'Telebirr Recharge Bonus +20%',
        'time': 'Yesterday',
        'subtitle': 'Get 20% extra coins on every top-up today.',
        'details':
            'Top up your NILE Live wallet using Telebirr or CBE Birr and receive an instant 20% bonus coin reward! Valid for all coin packages.',
        'icon': Icons.monetization_on,
        'color': const Color(0xFFFFB300),
      },
    ];

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7F9),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black, size: 18),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Official Notification',
              style: TextStyle(
                  color: Colors.black,
                  fontSize: 17,
                  fontWeight: FontWeight.bold),
            ),
            SizedBox(width: 5),
            Icon(Icons.verified, color: Color(0xFF29B6F6), size: 17),
          ],
        ),
        centerTitle: true,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('official_notifications')
            .orderBy('timestamp', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          final List list = [];

if (snapshot.hasData && snapshot.data != null) {
            for (final doc in snapshot.data!.docs) {
              final raw = doc.data();
              final Map d = raw is Map ? raw : {};
              list.add({
                'title': (d['title'] ?? 'Official Update').toString(),
                'time': d['timestamp'] is Timestamp
                    ? (d['timestamp'] as Timestamp)
                        .toDate()
                        .toString()
                        .substring(0, 16)
                    : 'New',
                'subtitle': (d['subtitle'] ?? d['body'] ?? '').toString(),
                'details': (d['details'] ?? d['body'] ?? '').toString(),
                'icon': Icons.campaign,
                'color': const Color(0xFF26C6DA),
              });
            }
          }
          list.addAll(defaultAnnouncements);

          return ListView.builder(
            padding: const EdgeInsets.all(14),
            itemCount: list.length,
            itemBuilder: (context, index) {
              final item = list[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                elevation: 0.5,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
                child: ListTile(
                  contentPadding: const EdgeInsets.all(14),
                  leading: CircleAvatar(
                    radius: 24,
                    backgroundColor: (item['color'] as Color).withOpacity(0.15),
                    child: Icon(item['icon'] as IconData,
                        color: item['color'] as Color, size: 26),
                  ),
                  title: Text(
                    item['title'].toString(),
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 15),
                  ),
                  subtitle: Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(
                      item['subtitle'].toString(),
                      style:
                          const TextStyle(fontSize: 13, color: Colors.black54),
                    ),
                  ),
                  trailing: const Icon(Icons.arrow_forward_ios,
                      size: 14, color: Colors.black38),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => NoticeContentScreen(
                          title: item['title'].toString(),
                          time: item['time'].toString(),
                          content: item['details'].toString(),
                          color: item['color'] as Color,
                          icon: item['icon'] as IconData,
                        ),
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class CustomerServiceChatScreen extends StatefulWidget {
  final String uid;
  const CustomerServiceChatScreen({super.key, required this.uid});

  @override
  State<CustomerServiceChatScreen> createState() =>
      _CustomerServiceChatScreenState();
}

class _CustomerServiceChatScreenState extends State<CustomerServiceChatScreen> {
  final TextEditingController _msgController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  final List _quickFaqs = [
    {
      'q': '💰 Coin Recharge / Telebirr',
      'a':
          'To recharge coins: Go to Me > Wallet > Select Coin Package > Pay via Telebirr or Bank. Coins arrive immediately!',
    },
    {
      'q': '🎙️ Host Salary & Agency',
      'a':
          'Hosts earn diamonds from gifts in live voice rooms. Reach your daily target and withdraw via Agency Center or Wallet.',

},
    {
      'q': '🔒 Account & Password Help',
      'a':
          'You can update your phone/password in Settings > Account Security. Our support team is here if you need manual recovery.',
    },
    {
      'q': '🚨 Report User / Room',
      'a':
          'Please send us the User ID or Room ID here along with a brief description, and our moderation team will take immediate action.',
    },
  ];

  @override
  void initState() {
    super.initState();
    _ensureWelcomeMessage();
  }

  @override
  void dispose() {
    _msgController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _ensureWelcomeMessage() async {
    try {
      final db = FirebaseFirestore.instance;
      final chatRef = db.collection('support_chats').doc(widget.uid);
      await chatRef.set({'userUnread': 0}, SetOptions(merge: true));

      final msgs = await chatRef.collection('messages').limit(1).get();
      if (msgs.docs.isEmpty) {
        await chatRef.collection('messages').add({
          'text':
              'Hello! Welcome to NILE Live Official Customer Service. Tap a topic below or type your message to chat with our team.',
          'isSupport': true,
          'timestamp': FieldValue.serverTimestamp(),
        });
      }
    } catch (_) {}
  }

  Future<void> _sendMessage(String text, {String? autoReply}) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return;
    _msgController.clear();

    try {
      final db = FirebaseFirestore.instance;
      final chatRef = db.collection('support_chats').doc(widget.uid);

      await chatRef.collection('messages').add({
        'text': trimmed,
        'isSupport': false,
        'senderId': widget.uid,
        'timestamp': FieldValue.serverTimestamp(),
      });

      await chatRef.set({
        'userId': widget.uid,
        'lastMessage': trimmed,
        'updatedAt': FieldValue.serverTimestamp(),
        'adminUnread': FieldValue.increment(1),
        'userUnread': 0,
      }, SetOptions(merge: true));

      if (autoReply != null) {
        await Future.delayed(const Duration(milliseconds: 500));
        await chatRef.collection('messages').add({
          'text': autoReply,
          'isSupport': true,
          'timestamp': FieldValue.serverTimestamp(),
        });
        await chatRef.set({
          'lastMessage': autoReply,
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      }

      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent + 120,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to send: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF2F5F8),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black, size: 18),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircleAvatar(
              radius: 15,
              backgroundColor: Color(0xFF26A69A),
              child: Icon(Icons.headset_mic, color: Colors.white, size: 16),
            ),
            SizedBox(width: 8),
            Text(
              'Customer Service',
              style: TextStyle(
                  color: Colors.black,
                  fontSize: 16,
                  fontWeight: FontWeight.bold),
            ),
            SizedBox(width: 4),

Icon(Icons.verified, color: Color(0xFF29B6F6), size: 16),
          ],
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('support_chats')
                  .doc(widget.uid)
                  .collection('messages')
                  .orderBy('timestamp', descending: false)
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData || snapshot.data == null) {
                  return const Center(
                    child: CircularProgressIndicator(color: Color(0xFF26A69A)),
                  );
                }
                final docs = snapshot.data!.docs;
                return ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(14),
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    final raw = docs[index].data();
                    final Map data = raw is Map ? raw : {};
                    final bool isSupport = data['isSupport'] == true;
                    final String text = (data['text'] ?? '').toString();

                    return Align(
                      alignment: isSupport
                          ? Alignment.centerLeft
                          : Alignment.centerRight,
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 10),
                        constraints: BoxConstraints(
                          maxWidth: MediaQuery.of(context).size.width * 0.76,
                        ),
                        decoration: BoxDecoration(
                          color: isSupport
                              ? Colors.white
                              : const Color(0xFF1BB3C8),
                          borderRadius: BorderRadius.only(
                            topLeft: const Radius.circular(16),
                            topRight: const Radius.circular(16),
                            bottomLeft: Radius.circular(isSupport ? 4 : 16),
                            bottomRight: Radius.circular(isSupport ? 16 : 4),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.04),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Text(
                          text,
                          style: TextStyle(
                            color: isSupport ? Colors.black87 : Colors.white,
                            fontSize: 14,
                            height: 1.4,
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
          Container(
            height: 44,
            color: Colors.white,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              itemCount: _quickFaqs.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final faq = _quickFaqs[index];
                return ActionChip(
                  backgroundColor: const Color(0xFFE0F7FA),
                  label: Text(

faq['q'].toString(),
                    style: const TextStyle(
                      color: Color(0xFF00838F),
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  onPressed: () => _sendMessage(
                    faq['q'].toString(),
                    autoReply: faq['a'].toString(),
                  ),
                );
              },
            ),
          ),
          SafeArea(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: const BoxDecoration(
                color: Colors.white,
                border: Border(top: BorderSide(color: Color(0xFFEEEEEE))),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _msgController,
                      textInputAction: TextInputAction.send,
                      onSubmitted: (v) => _sendMessage(v),
                      decoration: InputDecoration(
                        hintText: 'Type your question to support...',
                        hintStyle: const TextStyle(fontSize: 14),
                        filled: true,
                        fillColor: const Color(0xFFF3F6F8),
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 10),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  CircleAvatar(
                    radius: 22,
                    backgroundColor: const Color(0xFF1BB3C8),
                    child: IconButton(
                      icon:
                          const Icon(Icons.send, color: Colors.white, size: 20),
                      onPressed: () => _sendMessage(_msgController.text),
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

class NoticeDetailScreen extends StatelessWidget {
  const NoticeDetailScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final notices = [
      {
        "title": "System Security Maintenance Completed",
        "date": "Today 08:30 AM",
        "body":
            "Our audio routing servers have been upgraded for low latency Agora audio streaming across all 30-seat rooms.",
      },
      {
        "title": "Community Guidelines Update",
        "date": "Yesterday 04:15 PM",
        "body":
            "Respect fellow broadcasters and guests. Any form of harassment in live audio lounges will result in room locks.",
      },
      {
        "title": "Welcome Gift Package Available",
        "date": "3 days ago",
        "body":
            "Check your wallet to claim the newly registered broadcaster badge and bonus gifts.",
      },
    ];

    return Scaffold(
      backgroundColor: const Color(0xFFF7FBFB),
      appBar: AppBar(
        title: const Text("Notices",
            style: TextStyle(
                color: Colors.black,
                fontSize: 17,
                fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0.5,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black, size: 18),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(14),
        itemCount: notices.length,

itemBuilder: (context, index) {
          final item = notices[index];
          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            elevation: 0.5,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item["title"]!,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    item["date"]!,
                    style: const TextStyle(color: Colors.black38, fontSize: 11),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    item["body"]!,
                    style: const TextStyle(
                        color: Colors.black87, fontSize: 13, height: 1.3),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class InteractionDetailScreen extends StatelessWidget {
  const InteractionDetailScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final interactions = [
      {
        "user": "Amina",
        "action": "sent you a Rose gift in Dessie VIP Chill",
        "time": "15m ago",
        "icon": Icons.card_giftcard,
        "color": Colors.pinkAccent,
      },
      {
        "user": "Yonas",
        "action": "joined your 30-seat voice lounge",
        "time": "1h ago",
        "icon": Icons.meeting_room,
        "color": Colors.blueAccent,
      },
      {
        "user": "Selam",
        "action": "liked your room audio stream",
        "time": "3h ago",
        "icon": Icons.favorite,
        "color": Colors.redAccent,
      },
    ];

    return Scaffold(
      backgroundColor: const Color(0xFFF7FBFB),
      appBar: AppBar(
        title: const Text("Interactions",
            style: TextStyle(
                color: Colors.black,
                fontSize: 17,
                fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0.5,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black, size: 18),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: ListView.separated(
        padding: const EdgeInsets.all(12),
        itemCount: interactions.length,
        separatorBuilder: (_, __) =>
            const Divider(height: 1, color: Color(0xFFE8ECEF)),
        itemBuilder: (context, index) {
          final item = interactions[index];
          return ListTile(
            leading: CircleAvatar(
              backgroundColor: (item["color"] as Color).withOpacity(0.15),
              child: Icon(item["icon"] as IconData,
                  color: item["color"] as Color, size: 20),
            ),
            title: RichText(
              text: TextSpan(
                style: const TextStyle(color: Colors.black87, fontSize: 13),
                children: [
                  TextSpan(
                    text: "${item["user"]} ",
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  TextSpan(text: item["action"].toString()),
                ],
              ),
            ),
            trailing: Text(
              item["time"].toString(),
              style: const TextStyle(color: Colors.black38, fontSize: 11),
            ),
          );
        },
      ),
    );
  }
}

class FollowersListScreen extends StatefulWidget {
  const FollowersListScreen({super.key});

  @override
  State<FollowersListScreen> createState() => _FollowersListScreenState();
}

class _FollowersListScreenState extends State<FollowersListScreen> {
  final _followers = [
    {
      "name": "Hamza Voice",
      "bio": "Host Agency Lead • Dessie",
      "isFollowing": true,
    },
    {
      "name": "Sara Ahmed",
      "bio": "Music & Lounge Enthusiast",
      "isFollowing": false,
    },
    {
      "name": "DJ Mike",
      "bio": "Broadcasting live parties every night",
      "isFollowing": true,
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7FBFB),
      appBar: AppBar(
        title: const Text("Followers",
            style: TextStyle(
                color: Colors.black,
                fontSize: 17,
                fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0.5,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black, size: 18),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: _followers.length,
        itemBuilder: (context, index) {
          final person = _followers[index];
          final bool isFollowing = person["isFollowing"] as bool;

          return Card(
            elevation: 0.3,
            margin: const EdgeInsets.symmetric(vertical: 4),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: const Color(0xFF261D45),
                child: Text(
                  person["name"].toString()[0],
                  style: const TextStyle(
                      color: Color(0xFFFFD700), fontWeight: FontWeight.bold),
                ),
              ),
              title: Text(
                person["name"].toString(),
                style:
                    const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
              subtitle: Text(
                person["bio"].toString(),
                style: const TextStyle(fontSize: 12, color: Colors.black54),
              ),
              trailing: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  elevation: 0,
                  backgroundColor: isFollowing
                      ? const Color(0xFFE8ECEF)
                      : const Color(0xFF00C9A7),
                  foregroundColor:
                      isFollowing ? Colors.black87 : Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18)),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                ),
                onPressed: () {
                  setState(() {
                    person["isFollowing"] = !isFollowing;
                  });
                },
                child: Text(
                  isFollowing ? "Following" : "Follow Back",
                  style: const TextStyle(
                      fontSize: 11, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class NoticeContentScreen extends StatelessWidget {
  final String title;
  final String time;
  final String content;
  final Color color;
  final IconData icon;

  const NoticeContentScreen({
    super.key,
    required this.title,
    required this.time,
    required this.content,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7FBFB),
      appBar: AppBar(
        title: Text(title,
            style: const TextStyle(

color: Colors.black,
                fontSize: 16,
                fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0.5,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black, size: 18),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(18),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.black.withOpacity(0.05)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.03),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    backgroundColor: color.withOpacity(0.15),
                    radius: 24,
                    child: Icon(icon, color: color, size: 26),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          time,
                          style: const TextStyle(
                              fontSize: 12, color: Colors.black38),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              const Divider(color: Color(0xFFECEFF1)),
              const SizedBox(height: 14),
              Text(
                content,
                style: const TextStyle(
                  fontSize: 14,
                  height: 1.5,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF16122C),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  onPressed: () => Navigator.pop(context),
                  child: const Text(
                    "Acknowledge",
                    style: TextStyle(
                        color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
