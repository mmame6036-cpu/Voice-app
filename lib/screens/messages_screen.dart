import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'settings_screen.dart';
import 'voice_room_screen.dart';
import '../services/room_session_manager.dart';

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

  int _unreadSystemCount = 0;
  int _unreadOfficialCount = 0;
  int _unreadSupportCount = 0;

  int _unreadNoticeCount = 0;
  int _unreadInteractionCount = 0;
  int _unreadFollowerCount = 0;

  String _latestSystemSubtitle = "WELCOME to NILE Live!";
  String _latestSystemTime = "08-10 19:29";

  String _latestOfficialSubtitle = "NILE Live 1st Anniversary & Bonus";
  String _latestOfficialTime = "Today";

  String _latestSupportSubtitle = "Tap to chat with NILE Live Support";
  String _latestSupportTime = "";

  List _directChats = [];
  List _searchedUsers = [];
  bool _isSearchingUsers = false;

  StreamSubscription? _systemSub;
  StreamSubscription? _officialSub;
  StreamSubscription? _supportSub;
  StreamSubscription? _noticeSub;
  StreamSubscription? _interactionSub;
  StreamSubscription? _followerSub;
  StreamSubscription? _dmSub;
  Timer? _searchDebounce;

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
    _noticeSub?.cancel();
    _interactionSub?.cancel();
    _followerSub?.cancel();
    _dmSub?.cancel();
    _searchDebounce?.cancel();
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
        .limit(20)
        .snapshots()
        .listen((snap) {
      if (!mounted) return;
      if (snap.docs.isEmpty) return;
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
      if (!mounted) return;
      if (snap.docs.isEmpty) return;
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
      if (!mounted) return;
      if (!doc.exists) return;
      if (doc.data() == null) return;
      final data = doc.data()!;
      setState(() {
        _latestSupportSubtitle =
            (data['lastMessage'] ?? _latestSupportSubtitle).toString();
        _latestSupportTime = _formatTime(data['updatedAt']);
        _unreadSupportCount = (data['userUnread'] as num?)?.toInt() ?? 0;
      });
    }, onError: (_) {});

_noticeSub = db
        .collection('users')
        .doc(_uid)
        .collection('notices')
        .limit(30)
        .snapshots()
        .listen((snap) {
      if (!mounted) return;
      int unread = 0;
      for (final d in snap.docs) {
        if (d.data()['unread'] == true) unread++;
      }
      setState(() => _unreadNoticeCount = unread);
    }, onError: (_) {});

    _interactionSub = db
        .collection('users')
        .doc(_uid)
        .collection('interactions')
        .limit(30)
        .snapshots()
        .listen((snap) {
      if (!mounted) return;
      int unread = 0;
      for (final d in snap.docs) {
        if (d.data()['unread'] == true) unread++;
      }
      setState(() => _unreadInteractionCount = unread);
    }, onError: (_) {});

    _followerSub = db
        .collection('users')
        .doc(_uid)
        .collection('followers')
        .limit(50)
        .snapshots()
        .listen((snap) {
      if (!mounted) return;
      int unread = 0;
      for (final d in snap.docs) {
        if (d.data()['unread'] == true) unread++;
      }
      setState(() => _unreadFollowerCount = unread);
    }, onError: (_) {});

    _dmSub = db
        .collection('direct_chats')
        .where('participants', arrayContains: _uid)
        .snapshots()
        .listen((snap) {
      if (!mounted) return;
      final List chats = [];
      for (final doc in snap.docs) {
        final d = doc.data();
        final List participants =
            d['participants'] is List ? d['participants'] as List : [];
        String peerUid = '';
        for (final p in participants) {
          if (p.toString() != _uid) {
            peerUid = p.toString();
            break;
          }
        }
        if (peerUid.isEmpty) continue;

        final Map namesMap =
            d['participantNames'] is Map ? d['participantNames'] as Map : {};
        final Map avatarsMap = d['participantAvatars'] is Map
            ? d['participantAvatars'] as Map
            : {};
        final Map unreadMap =
            d['unreadCounts'] is Map ? d['unreadCounts'] as Map : {};

        final String peerName = (namesMap[peerUid] ?? 'User').toString();
        final String peerAvatar = (avatarsMap[peerUid] ?? '').toString();
        final int unread = (unreadMap[_uid] as num?)?.toInt() ?? 0;

        int updatedMs = 0;
        final rawTs = d['updatedAt'];
        if (rawTs is Timestamp) {
          updatedMs = rawTs.millisecondsSinceEpoch;
        } else if (rawTs is int) {
          updatedMs = rawTs;
        }

        chats.add({
          'chatId': doc.id,
          'peerUid': peerUid,
          'peerName': peerName,
          'peerAvatar': peerAvatar,
          'lastMessage': (d['lastMessage'] ?? '').toString(),
          'time': _formatTime(rawTs),
          'updatedMs': updatedMs,
          'unread': unread,
        });
      }

      chats.sort((a, b) => ((b['updatedMs'] as num?)?.toInt() ?? 0)
          .compareTo((a['updatedMs'] as num?)?.toInt() ?? 0));

      setState(() {
        _directChats = chats;
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
    } else if (ts is int) {
      dt = DateTime.fromMillisecondsSinceEpoch(ts);
    } else {
      return ts.toString();
    }
    final String m = dt.month.toString().padLeft(2, '0');
    final String d = dt.day.toString().padLeft(2, '0');
    final String h = dt.hour.toString().padLeft(2, '0');
    final String min = dt.minute.toString().padLeft(2, '0');
    return "$m-$d $h:$min";
  }

  void _onSearchChanged(String val) {
    setState(() => _searchQuery = val);
    _searchDebounce?.cancel();
    final trimmed = val.trim();
    if (trimmed.isEmpty) {
      setState(() {
        _searchedUsers = [];
        _isSearchingUsers = false;
      });
      return;
    }

_searchDebounce = Timer(const Duration(milliseconds: 350), () async {
      if (!mounted) return;
      setState(() => _isSearchingUsers = true);
      try {
        final db = FirebaseFirestore.instance;
        final List found = [];
        final Set seenUids = {_uid};

        final int? numQuery = int.tryParse(trimmed);
        if (numQuery != null) {
          final byIdSnap = await db
              .collection('users')
              .where('numericId', isEqualTo: numQuery)
              .limit(10)
              .get();
          for (final doc in byIdSnap.docs) {
            if (seenUids.contains(doc.id)) continue;
            seenUids.add(doc.id);
            final d = doc.data();
            found.add({
              'uid': doc.id,
              'name': (d['name'] ?? d['nickname'] ?? 'User').toString(),
              'numericId': (d['numericId'] as num?)?.toInt() ?? 0,
              'avatarUrl': (d['avatarUrl'] ?? d['photoURL'] ?? '').toString(),
            });
          }
        }

        final recentUsers = await db.collection('users').limit(40).get();
        final qLower = trimmed.toLowerCase();
        for (final doc in recentUsers.docs) {
          if (seenUids.contains(doc.id)) continue;
          final d = doc.data();
          final name = (d['name'] ?? d['nickname'] ?? '').toString();
          final numIdStr = ((d['numericId'] as num?)?.toInt() ?? 0).toString();
          if (name.toLowerCase().contains(qLower) ||
              numIdStr.contains(trimmed)) {
            seenUids.add(doc.id);
            found.add({
              'uid': doc.id,
              'name': name.isNotEmpty ? name : 'User',
              'numericId': (d['numericId'] as num?)?.toInt() ?? 0,
              'avatarUrl': (d['avatarUrl'] ?? d['photoURL'] ?? '').toString(),
            });
          }
        }

        if (mounted) {
          setState(() {
            _searchedUsers = found;
            _isSearchingUsers = false;
          });
        }
      } catch (_) {
        if (mounted) setState(() => _isSearchingUsers = false);
      }
    });
  }

  Future _markAllAsRead() async {
    setState(() {
      _unreadSystemCount = 0;
      _unreadOfficialCount = 0;
      _unreadSupportCount = 0;
      _unreadNoticeCount = 0;
      _unreadInteractionCount = 0;
      _unreadFollowerCount = 0;
      for (final c in _directChats) {
        c['unread'] = 0;
      }
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

      final noticeSnap = await db
          .collection('users')
          .doc(_uid)
          .collection('notices')
          .where('unread', isEqualTo: true)
          .get();
      for (final doc in noticeSnap.docs) {
        await doc.reference.update({'unread': false});
      }

      final interSnap = await db
          .collection('users')
          .doc(_uid)
          .collection('interactions')
          .where('unread', isEqualTo: true)
          .get();
      for (final doc in interSnap.docs) {
        await doc.reference.update({'unread': false});
      }

      final folSnap = await db
          .collection('users')
          .doc(_uid)
          .collection('followers')
          .where('unread', isEqualTo: true)
          .get();
      for (final doc in folSnap.docs) {
        await doc.reference.update({'unread': false});
      }

      for (final c in _directChats) {
        final cid = (c['chatId'] ?? '').toString();
        if (cid.isNotEmpty) {
          await db.collection('direct_chats').doc(cid).set({
            'unreadCounts': {_uid: 0}
          }, SetOptions(merge: true));
        }
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

  void _openDirectChat({
    required String peerUid,
    required String peerName,
    String peerAvatar = '',
  }) {
    if (peerUid.isEmpty || peerUid == _uid) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => DirectChatScreen(
          myUid: _uid,
          peerUid: peerUid,
          peerName: peerName,
          peerAvatar: peerAvatar,
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
        if (t.contains(q)) return true;
        return s.contains(q);
      }
      return true;
    }).toList();

    final filteredDms = _directChats.where((dm) {
      if (!_showAll && (dm['unread'] as int) == 0) return false;
      if (_searchQuery.isNotEmpty) {
        final q = _searchQuery.toLowerCase();
        final name = dm['peerName'].toString().toLowerCase();
        final last = dm['lastMessage'].toString().toLowerCase();
        return name.contains(q) || last.contains(q);
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
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const SettingsScreen(),
                      ),
                    );
                  },
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
                                _searchedUsers = [];
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
                        onChanged: _onSearchChanged,
                        decoration: InputDecoration(
                          hintText: 'Search messages or User ID / Name...',
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
                                builder: (_) => NoticeDetailScreen(uid: _uid),
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
                                builder: (_) =>
                                    InteractionDetailScreen(uid: _uid),
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
                                builder: (_) => FollowersListScreen(
                                  uid: _uid,
                                  onMessageUser: (pUid, pName, pAvatar) {
                                    _openDirectChat(
                                      peerUid: pUid,
                                      peerName: pName,
                                      peerAvatar: pAvatar,
                                    );
                                  },
                                ),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                  const Divider(height: 1, color: Color(0xFFEEEEEE)),
                  Expanded(
                    child: ListView(
                      padding: const EdgeInsets.only(top: 4, bottom: 20),
                      children: [
                        if (_isSearching && _searchQuery.trim().isNotEmpty) ...[
                          Padding(
                            padding: const EdgeInsets.fromLTRB(16, 10, 16, 4),
                            child: Text(
                              _isSearchingUsers
                                  ? "Searching users..."
                                  : "Users Found (${_searchedUsers.length})",

style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF159A8C),
                              ),
                            ),
                          ),
                          ..._searchedUsers.map((u) {
                            final pUid = u['uid'].toString();
                            final pName = u['name'].toString();
                            final int pId =
                                (u['numericId'] as num?)?.toInt() ?? 0;
                            final pAvatar = u['avatarUrl'].toString();
                            return ListTile(
                              leading: CircleAvatar(
                                backgroundColor: const Color(0xFFD9F3F0),
                                backgroundImage: _buildAvatarImage(pAvatar),
                                child: _buildAvatarImage(pAvatar) == null
                                    ? Text(
                                        pName.isNotEmpty
                                            ? pName[0].toUpperCase()
                                            : 'U',
                                        style: const TextStyle(
                                          color: Color(0xFF159A8C),
                                          fontWeight: FontWeight.bold,
                                        ),
                                      )
                                    : null,
                              ),
                              title: Text(
                                pName,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 14.5,
                                ),
                              ),
                              subtitle: Text(
                                "ID: $pId",
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Colors.black54,
                                ),
                              ),
                              trailing: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF1BB3C8),
                                  foregroundColor: Colors.white,
                                  elevation: 0,
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 14),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                ),
                                onPressed: () => _openDirectChat(
                                  peerUid: pUid,
                                  peerName: pName,
                                  peerAvatar: pAvatar,
                                ),
                                child: const Text(
                                  "Chat",
                                  style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold),
                                ),
                              ),
                            );
                          }),
                          const Divider(height: 12, color: Color(0xFFEEEEEE)),
                        ],
                        ...filteredChannels.map((item) {
                          return _buildMessageTile(
                            icon: item['icon'] as IconData,

iconBgColor: item['bgColor'] as Color,
                            title: item['title'] as String,
                            subtitle: item['subtitle'] as String,
                            time: item['time'] as String,
                            unreadCount: item['unread'] as int,
                            onTap: item['onTap'] as VoidCallback,
                          );
                        }),
                        ...filteredDms.map((dm) {
                          final peerUid = dm['peerUid'].toString();
                          final peerName = dm['peerName'].toString();
                          final peerAvatar = dm['peerAvatar'].toString();
                          return _buildDirectChatTile(
                            peerName: peerName,
                            peerAvatar: peerAvatar,
                            subtitle: dm['lastMessage'].toString(),
                            time: dm['time'].toString(),
                            unreadCount: dm['unread'] as int,
                            onTap: () => _openDirectChat(
                              peerUid: peerUid,
                              peerName: peerName,
                              peerAvatar: peerAvatar,
                            ),
                          );
                        }),
                        if (filteredChannels.isEmpty &&
                            filteredDms.isEmpty &&
                            _searchedUsers.isEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 60),
                            child: Center(
                              child: Text(
                                _showAll
                                    ? 'No matching messages'
                                    : 'No unread messages',
                                style: const TextStyle(
                                    color: Colors.black45, fontSize: 14),
                              ),
                            ),
                          ),
                      ],
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

  ImageProvider? _buildAvatarImage(String url) {
    if (url.isEmpty) return null;
    if (url.startsWith('data:image')) {
      try {
        final idx = url.indexOf(',');
        if (idx != -1) {
          final Uint8List bytes = base64Decode(url.substring(idx + 1));
          return MemoryImage(bytes);
        }
      } catch (_) {
        return null;
      }
    }
    if (url.startsWith('http')) {
      return NetworkImage(url);
    }
    return null;
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

  Widget _buildDirectChatTile({
    required String peerName,
    required String peerAvatar,
    required String subtitle,
    required String time,
    required int unreadCount,
    required VoidCallback onTap,
  }) {
    final avatarImg = _buildAvatarImage(peerAvatar);
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
        decoration: const BoxDecoration(
          color: Colors.white,
          border:
              Border(bottom: BorderSide(color: Color(0xFFF3F4F6), width: 1)),
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 26,
              backgroundColor: const Color(0xFF9B87B5),
              backgroundImage: avatarImg,
              child: avatarImg == null

? Text(
                      peerName.isNotEmpty ? peerName[0].toUpperCase() : 'U',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    )
                  : null,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    peerName,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                      color: Colors.black87,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle.isNotEmpty ? subtitle : "Tap to chat",
                    style: const TextStyle(
                      color: Colors.black45,
                      fontSize: 13.5,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
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

class DirectChatScreen extends StatefulWidget {
  final String myUid;
  final String peerUid;
  final String peerName;
  final String peerAvatar;

  const DirectChatScreen({
    super.key,
    required this.myUid,
    required this.peerUid,
    required this.peerName,
    this.peerAvatar = '',
  });

  @override
  State<DirectChatScreen> createState() => _DirectChatScreenState();
}

class _DirectChatScreenState extends State<DirectChatScreen> {
  final TextEditingController _msgCtrl = TextEditingController();
  final ScrollController _scrollCtrl = ScrollController();
  bool _isSending = false;

  String get _chatId {
    final ids = [widget.myUid, widget.peerUid]..sort();
    return "${ids[0]}_${ids[1]}";
  }

  @override
  void initState() {
    super.initState();
    _markChatRead();
  }

  @override
  void dispose() {
    _msgCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  Future _markChatRead() async {
    try {
      await FirebaseFirestore.instance
          .collection('direct_chats')
          .doc(_chatId)
          .set({
        'unreadCounts': {widget.myUid: 0}
      }, SetOptions(merge: true));
    } catch (_) {}
  }

  Future _sendDirectMessage(
      {String? roomInviteId, String? roomInviteTitle}) async {
    final text = roomInviteId != null
        ? "🎙️ Join my Voice Room: ${roomInviteTitle ?? 'Party Lounge'}"
        : _msgCtrl.text.trim();
    if (text.isEmpty || _isSending) return;

    setState(() => _isSending = true);
    if (roomInviteId == null) _msgCtrl.clear();

    try {
      final db = FirebaseFirestore.instance;

      final peerDoc = await db.collection('users').doc(widget.peerUid).get();
      final myDoc = await db.collection('users').doc(widget.myUid).get();

      final peerData = peerDoc.data() ?? {};
      final myData = myDoc.data() ?? {};

      final String myNumIdStr =
          ((myData['numericId'] as num?)?.toInt() ?? 0).toString();
      final List peerBlacklist =
          peerData['blacklist'] is List ? peerData['blacklist'] as List : [];

      if (peerBlacklist.contains(widget.myUid) ||
          (myNumIdStr != '0' && peerBlacklist.contains(myNumIdStr))) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              backgroundColor: Colors.redAccent,
              content:
                  Text("Message could not be delivered (Blocked by user)."),
            ),
          );
        }
        return;
      }

      final bool blockStrangers = peerData['blockStrangerDm'] == true;
      if (blockStrangers) {
        final followCheck = await db
            .collection('users')
            .doc(widget.peerUid)
            .collection('following')
            .doc(widget.myUid)
            .get();
        if (!followCheck.exists) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                backgroundColor: Colors.orangeAccent,
                content: Text(
                  "This user only accepts messages from friends.",
                  style: TextStyle(color: Colors.black),
                ),
              ),
            );
          }
          return;
        }
      }

      if (myData['vibrationEnabled'] != false) {
        HapticFeedback.lightImpact();
      }

final String myName = (myData['name'] ??
              myData['nickname'] ??
              FirebaseAuth.instance.currentUser?.displayName ??
              'User')
          .toString();
      final String myAvatar =
          (myData['avatarUrl'] ?? myData['photoURL'] ?? '').toString();

      final chatRef = db.collection('direct_chats').doc(_chatId);
      await chatRef.collection('messages').add({
        'senderUid': widget.myUid,
        'text': text,
        'roomId': roomInviteId ?? '',
        'roomTitle': roomInviteTitle ?? '',
        'timestamp': FieldValue.serverTimestamp(),
      });

      await chatRef.set({
        'participants': [widget.myUid, widget.peerUid],
        'participantNames': {
          widget.myUid: myName,
          widget.peerUid: widget.peerName,
        },
        'participantAvatars': {
          widget.myUid: myAvatar,
          widget.peerUid: widget.peerAvatar,
        },
        'lastMessage': text,
        'updatedAt': FieldValue.serverTimestamp(),
        'unreadCounts': {
          widget.peerUid: FieldValue.increment(1),
          widget.myUid: 0,
        },
      }, SetOptions(merge: true));

      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(
          _scrollCtrl.position.maxScrollExtent + 100,
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOut,
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error sending message: $e")),
        );
      }
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  Future<void> _respondToAgencyForm({
    required DocumentReference msgDocRef,
    required Map data,
    required bool agree,
  }) async {
    final String msgType = (data['type'] ?? 'agency_join_form').toString();
    final String requestId = (data['requestId'] ?? '').toString();
    final String agencyId = (data['agencyId'] ?? '').toString();
    final String agencyName = (data['agencyName'] ?? agencyId).toString();
    final String subAgencyId = (data['subAgencyId'] ?? requestId).toString();
    final String subAgencyName = (data['subAgencyName'] ?? 'Sub-Agency').toString();
    final bool isSubAgentInvite = data['isSubAgentInvite'] == true;
    final String applicantUid = (data['applicantUid'] ?? '').toString();
    final String applicantName = (data['applicantName'] ?? 'Host').toString();
    final String newStatus = agree ? 'AGREED' : 'REJECTED';

    try {
      final db = FirebaseFirestore.instance;
      await msgDocRef.set({'formStatus': newStatus}, SetOptions(merge: true));

      if (msgType == 'sub_agency_form') {
        if (subAgencyId.isNotEmpty) {
          await db.collection('agencies').doc(subAgencyId).set({
            'status': agree ? 'APPROVED' : 'REJECTED',
            if (agree) 'approvedAt': FieldValue.serverTimestamp(),
            if (!agree) 'rejectedAt': FieldValue.serverTimestamp(),
          }, SetOptions(merge: true));
        }
        if (applicantUid.isNotEmpty) {
          await db.collection('users').doc(applicantUid).set({
            'isAgent': agree,
            'role': agree ? 'agent' : 'user',
            'allowCreateAgency': agree,
          }, SetOptions(merge: true));
        }
      } else {
        if (requestId.isNotEmpty) {
          await db.collection('agency_join_requests').doc(requestId).set({
            'status': newStatus,
            'respondedAt': FieldValue.serverTimestamp(),
          }, SetOptions(merge: true));
        }

        if (agree && applicantUid.isNotEmpty && agencyId.isNotEmpty) {
          await db.collection('users').doc(applicantUid).set({
            'agencyId': agencyId,
            'agencyName': agencyName,
            'isHost': true,
            if (isSubAgentInvite) 'allowCreateAgency': true,
            'joinedAgencyAt': FieldValue.serverTimestamp(),
          }, SetOptions(merge: true));

          await db.collection('hosts').doc(applicantUid).set({
            'agencyId': agencyId,
            'agencyName': agencyName,
            'pendingAgencyId': FieldValue.delete(),
            'pendingAgencyName': FieldValue.delete(),
            'status': 'active',
            'updatedAt': FieldValue.serverTimestamp(),
          }, SetOptions(merge: true));

          await db.collection('agencies').doc(agencyId).set({
            'totalHosts': FieldValue.increment(1),
          }, SetOptions(merge: true));
        } else if (!agree && applicantUid.isNotEmpty) {
          await db.collection('hosts').doc(applicantUid).set({
            'pendingAgencyId': FieldValue.delete(),
            'pendingAgencyName': FieldValue.delete(),
            'status': 'rejected',
            'updatedAt': FieldValue.serverTimestamp(),
          }, SetOptions(merge: true));
        }
      }

      final String replyText = agree
          ? "✅ Agreed! $applicantName has been approved to join $agencyName."
          : "❌ Rejected: Host application for $agencyName was declined.";

      final chatRef = db.collection('direct_chats').doc(_chatId);
      await chatRef.collection('messages').add({
        'senderUid': widget.myUid,
        'text': replyText,
        'timestamp': FieldValue.serverTimestamp(),
      });
      await chatRef.set({
        'lastMessage': replyText,
        'updatedAt': FieldValue.serverTimestamp(),
        if (applicantUid.isNotEmpty)
          'unreadCounts': {applicantUid: FieldValue.increment(1)},
      }, SetOptions(merge: true));

      if (applicantUid.isNotEmpty) {
        await db
            .collection('users')
            .doc(applicantUid)
            .collection('system_messages')
            .add({
          'title': agree
              ? 'Agency Application Approved!'
              : 'Agency Application Rejected',
          'subtitle': replyText,
          'body': replyText,
          'unread': true,
          'timestamp': FieldValue.serverTimestamp(),
        });
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor:
                agree ? const Color(0xFF107C41) : Colors.redAccent,
            content: Text(agree
                ? "Approved $applicantName!"
                : "Rejected $applicantName's request."),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Action failed: $e")),
        );
      }
    }
  }

  Future _joinInvitedRoom(String roomId, String roomTitle) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      final myUid = user?.uid ?? widget.myUid;
      final myDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(myUid)
          .get();
      final d = myDoc.data() ?? {};
      final myName =
          (d['name'] ?? d['nickname'] ?? user?.displayName ?? 'User')
              .toString();
      final int numId = (d['numericId'] as num?)?.toInt() ?? 100001;

      if (!mounted) return;
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => VoiceRoomScreen(
            roomTitle: roomTitle.isNotEmpty ? roomTitle : "Party Lounge",
            roomId: roomId,
            hostName: widget.peerName,
            userNumericId: numId,
            userUid: myUid,
            userName: myName,
          ),
        ),
      );
    } catch (_) {}
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
        title: Text(
          widget.peerName,
          style: const TextStyle(
            color: Colors.black,
            fontSize: 16.5,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.mic_rounded, color: Color(0xFF1BB3C8)),
            tooltip: "Invite to Voice Room",
            onPressed: () {
              final mgr = RoomSessionManager.instance;
              final activeRoomId =
                  mgr.hasActiveRoom ? mgr.roomId : 'room_${widget.myUid}';
              final activeRoomTitle =
                  mgr.hasActiveRoom ? mgr.roomTitle : 'VIP Party Lounge';
              _sendDirectMessage(
                roomInviteId: activeRoomId,
                roomInviteTitle: activeRoomTitle,

);
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder(
              stream: FirebaseFirestore.instance
                  .collection('direct_chats')
                  .doc(_chatId)
                  .collection('messages')
                  .orderBy('timestamp', descending: false)
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData || snapshot.data == null) {
                  return const Center(
                    child: CircularProgressIndicator(color: Color(0xFF1BB3C8)),
                  );
                }
                final qSnap = snapshot.data as QuerySnapshot;
                final docs = qSnap.docs;
                if (docs.isEmpty) {
                  return Center(
                    child: Text(
                      "Say hello to ${widget.peerName}!",
                      style:
                          const TextStyle(color: Colors.black45, fontSize: 14),
                    ),
                  );
                }

                return ListView.builder(
                  controller: _scrollCtrl,
                  padding: const EdgeInsets.all(14),
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    final docRef = docs[index].reference;
                    final raw = docs[index].data();
                    final Map data = raw is Map ? raw : {};
                    final bool isMe = data['senderUid'] == widget.myUid;
                    final String msgType = (data['type'] ?? '').toString();
                    final String text = (data['text'] ?? '').toString();
                    final String roomId = (data['roomId'] ?? '').toString();
                    final String roomTitle =
                        (data['roomTitle'] ?? 'Party Lounge').toString();

                    if (msgType == 'agency_join_form' || msgType == 'sub_agency_form') {
                      final String appName =
                          (data['applicantName'] ?? 'Applicant').toString();
                      final String appNumId =
                          (data['applicantNumericId'] ?? '-').toString();
                      final String phone = (data['phone'] ?? '-').toString();
                      final String country =
                          (data['country'] ?? '-').toString();
                      final String note = (data['note'] ?? '').toString();
                      final String agName =
                          (data['agencyName'] ?? 'Agency').toString();
                      final String agId =
                          (data['agencyId'] ?? '').toString();
                      final String ownerUid =
                          (data['ownerUid'] ?? '').toString();
                      final String formStatus =
                          (data['formStatus'] ?? 'PENDING')
                              .toString()
                              .toUpperCase();
                      final bool canAct =
                          formStatus == 'PENDING' && ownerUid == widget.myUid;

                      return Align(
                        alignment: isMe
                            ? Alignment.centerRight
                            : Alignment.centerLeft,
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.all(14),
                          constraints: BoxConstraints(
                            maxWidth: MediaQuery.of(context).size.width * 0.84,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFFBF4),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                                color: const Color(0xFFD49B42), width: 1.5),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.06),
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
                                  const Icon(Icons.assignment_ind_rounded,
                                      color: Color(0xFFB45309), size: 20),
                                  const SizedBox(width: 6),
                                  Expanded(
                                    child: Text(
                                      msgType == 'sub_agency_form'
                                          ? "Sub-Agency Request • ${data['subAgencyName'] ?? ''}"
                                          : "Host Join Request • $agName ($agId)",
                                      style: const TextStyle(
                                        color: Color(0xFF3E2723),
                                        fontWeight: FontWeight.w900,
                                        fontSize: 13.5,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const Divider(
                                  height: 14, color: Color(0xFFE2D6C5)),
                              Text("• Name: $appName (ID: $appNumId)",
                                  style: const TextStyle(
                                      fontSize: 12.5,
                                      color: Colors.black87,
                                      fontWeight: FontWeight.w600)),
                              const SizedBox(height: 3),
                              Text("• Phone/Contact: $phone",
                                  style: const TextStyle(
                                      fontSize: 12.5, color: Colors.black87)),
                              const SizedBox(height: 3),
                              Text("• Country: $country",
                                  style: const TextStyle(
                                      fontSize: 12.5, color: Colors.black87)),
                              if (note.isNotEmpty) ...[
                                const SizedBox(height: 3),
                                Text("• Note: $note",
                                    style: const TextStyle(
                                        fontSize: 12,
                                        color: Colors.black54)),
                              ],
                              const SizedBox(height: 12),
                              if (canAct)
                                Row(
                                  children: [
                                    Expanded(
                                      child: ElevatedButton(
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor:
                                              const Color(0xFF107C41),
                                          foregroundColor: Colors.white,
                                          padding: const EdgeInsets.symmetric(
                                              vertical: 9),
                                          shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(10),
                                          ),
                                        ),
                                        onPressed: () => _respondToAgencyForm(
                                          msgDocRef: docRef,
                                          data: data,
                                          agree: true,
                                        ),
                                        child: const Text(
                                          "Agree",
                                          style: TextStyle(
                                              fontWeight: FontWeight.w900,
                                              fontSize: 13),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: ElevatedButton(
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor:
                                              const Color(0xFFD32F2F),
                                          foregroundColor: Colors.white,
                                          padding: const EdgeInsets.symmetric(
                                              vertical: 9),
                                          shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(10),
                                          ),
                                        ),
                                        onPressed: () => _respondToAgencyForm(
                                          msgDocRef: docRef,
                                          data: data,
                                          agree: false,
                                        ),
                                        child: const Text(
                                          "Reject",
                                          style: TextStyle(
                                              fontWeight: FontWeight.w900,
                                              fontSize: 13),
                                        ),
                                      ),
                                    ),
                                  ],
                                )
                              else
                                Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.symmetric(
                                      vertical: 7, horizontal: 10),
                                  decoration: BoxDecoration(
                                    color: formStatus == 'AGREED'
                                        ? const Color(0xFFE8F5E9)
                                        : (formStatus == 'REJECTED'
                                            ? const Color(0xFFFEE2E2)
                                            : const Color(0xFFFEF3C7)),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    formStatus == 'AGREED'
                                        ? "✅ Status: Agreed & Linked"
                                        : (formStatus == 'REJECTED'
                                            ? "❌ Status: Rejected"
                                            : "⏳ Status: Pending Agent Approval"),
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w800,
                                      color: formStatus == 'AGREED'
                                          ? const Color(0xFF107C41)
                                          : (formStatus == 'REJECTED'
                                              ? const Color(0xFFB91C1C)
                                              : const Color(0xFFB45309)),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      );
                    }

                    return Align(
                      alignment:
                          isMe ? Alignment.centerRight : Alignment.centerLeft,
                      child: GestureDetector(
                        onTap: roomId.isNotEmpty
                            ? () => _joinInvitedRoom(roomId, roomTitle)
                            : null,
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 10),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 10),
                          constraints: BoxConstraints(
                            maxWidth: MediaQuery.of(context).size.width * 0.76,
                          ),
                          decoration: BoxDecoration(
                            color: roomId.isNotEmpty
                                ? const Color(0xFF182026)
                                : (isMe
                                    ? const Color(0xFF1BB3C8)
                                    : Colors.white),
                            borderRadius: BorderRadius.circular(16),
                            border: roomId.isNotEmpty
                                ? Border.all(
                                    color: const Color(0xFFFFD700), width: 1.2)
                                : null,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                text,
                                style: TextStyle(
                                  color: roomId.isNotEmpty
                                      ? const Color(0xFFFFD700)
                                      : (isMe ? Colors.white : Colors.black87),
                                  fontSize: 14,
                                  fontWeight: roomId.isNotEmpty
                                      ? FontWeight.bold

: FontWeight.normal,
                                ),
                              ),
                              if (roomId.isNotEmpty) ...[
                                const SizedBox(height: 6),
                                const Text(
                                  "Tap to enter voice room >",
                                  style: TextStyle(
                                    color: Color(0xFF26E6C8),
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    );
                  },
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
                      controller: _msgCtrl,
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => _sendDirectMessage(),
                      decoration: InputDecoration(
                        hintText: 'Write a message...',
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
                      onPressed: () => _sendDirectMessage(),
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
          'Welcome to NILE Live Voice Party! Enjoy 30-seat live voice lounges, exciting mini-games, and daily host rewards. Never share your password with anyone.',
      'icon': Icons.verified_user,
      'color': const Color(0xFF29B6F6),
    },
    {
      'title': 'Account Security Reminder',
      'time': 'Yesterday 14:10',
      'body':
          'Official NILE Live administrators will never ask for your account password or Security PIN. Keep your account safe.',
      'icon': Icons.security,
      'color': Colors.orangeAccent,
    },
  ];

  @override
  void initState() {
    super.initState();
    _markSystemMessagesRead();
  }

  Future _markSystemMessagesRead() async {

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
      body: StreamBuilder(
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(widget.uid)
            .collection('system_messages')
            .orderBy('timestamp', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          final List items = [];

          if (snapshot.hasData && snapshot.data != null) {
            final qSnap = snapshot.data as QuerySnapshot;
            for (final doc in qSnap.docs) {
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
              final msg = items[index] as Map;
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
            'Celebrate NILE Live 1st Anniversary with us! Host daily voice rooms, send special anniversary gifts, and climb the leaderboard to win VIP badges and bonus coins.',
        'icon': Icons.celebration,
        'color': const Color(0xFF26C6DA),
      },
      {
        'title': 'Official Agency Recharge Bonus +20%',
        'time': 'Yesterday',
        'subtitle': 'Get 20% extra coins on USDT top-ups.',
        'details':
            'Top up your NILE Live wallet via verified USDT payment and receive instant bonus coin rewards!',
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
      body: StreamBuilder(
        stream: FirebaseFirestore.instance
            .collection('official_notifications')
            .orderBy('timestamp', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          final List list = [];

          if (snapshot.hasData && snapshot.data != null) {
            final qSnap = snapshot.data as QuerySnapshot;
            for (final doc in qSnap.docs) {
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
              final item = list[index] as Map;
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
      'q': '💰 Coin Recharge (USDT)',
      'a':
          'To recharge coins: Go to Me > Recharge > Select Coin Package > Pay via Binance Pay (USDT). Coins arrive immediately upon verification!',
    },
    {
      'q': '🎙️ Host Salary & Agency',
      'a':
          'Hosts earn points from gifts in live voice rooms (7,000 pts/day target, 100,000 pts minimum withdrawal).',
    },
    {
      'q': '🔒 Account & Password Help',
      'a':
          'You can update your password, security PIN, or email in Setting > Account Manager.',
    },
    {
      'q': '🚨 Report User / Room',
      'a':
          'Please send the User ID or Room ID here with details, and our moderation team will take immediate action.',
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

  Future _ensureWelcomeMessage() async {
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

  Future _sendMessage(String text, {String? autoReply}) async {
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
            child: StreamBuilder(
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
                final qSnap = snapshot.data as QuerySnapshot;
                final docs = qSnap.docs;

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
                final faq = _quickFaqs[index] as Map;
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

class NoticeDetailScreen extends StatefulWidget {
  final String uid;
  const NoticeDetailScreen({super.key, required this.uid});

  @override
  State<NoticeDetailScreen> createState() => _NoticeDetailScreenState();
}

class _NoticeDetailScreenState extends State<NoticeDetailScreen> {
  @override
  void initState() {
    super.initState();
    _markNoticesRead();
  }

  Future _markNoticesRead() async {
    try {
      final snap = await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.uid)
          .collection('notices')
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
      backgroundColor: const Color(0xFFF7FBFB),
      appBar: AppBar(
        title: const Text("Notices",
            style: TextStyle(
                color: Colors.black,
                fontSize: 17,
                fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0.5,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black, size: 18),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: StreamBuilder(
        stream: FirebaseFirestore.instance
            .collection('recharge_transactions')
            .where('userUid', isEqualTo: widget.uid)
            .limit(20)
            .snapshots(),
        builder: (context, txnSnap) {
          final List items = [];

          if (txnSnap.hasData && txnSnap.data != null) {
            final qSnap = txnSnap.data as QuerySnapshot;
            for (final doc in qSnap.docs) {
              final raw = doc.data();
              final Map d = raw is Map ? raw : {};
              final coins = (d['coins'] as num?)?.toInt() ?? 0;
              final amount = (d['amount'] ?? '').toString();
              final status = (d['status'] ?? 'VERIFIED').toString();
              items.add({
                "title": "Wallet Recharge: +$coins Coins",
                "date": status,
                "body":
                    "Your recharge of $coins Coins ($amount) via Binance Pay (USDT) has been processed.",
              });
            }
          }

items.addAll([
            {
              "title": "System Security Maintenance Completed",
              "date": "System",
              "body":
                  "Our audio routing servers are active for low-latency Agora voice streaming across all 30-seat rooms.",
            },
            {
              "title": "Community Guidelines Update",
              "date": "Policy",
              "body":
                  "Respect fellow broadcasters and guests in live audio lounges.",
            },
          ]);

          return ListView.builder(
            padding: const EdgeInsets.all(14),
            itemCount: items.length,
            itemBuilder: (context, index) {
              final item = items[index] as Map;
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                elevation: 0.5,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item["title"].toString(),
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        item["date"].toString(),
                        style: const TextStyle(
                            color: Color(0xFF159A8C),
                            fontSize: 11,
                            fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        item["body"].toString(),
                        style: const TextStyle(
                            color: Colors.black87, fontSize: 13, height: 1.3),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class InteractionDetailScreen extends StatefulWidget {
  final String uid;
  const InteractionDetailScreen({super.key, required this.uid});

  @override
  State<InteractionDetailScreen> createState() =>
      _InteractionDetailScreenState();
}

class _InteractionDetailScreenState extends State<InteractionDetailScreen> {
  @override
  void initState() {
    super.initState();
    _markInteractionsRead();
  }

  Future _markInteractionsRead() async {
    try {
      final snap = await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.uid)
          .collection('interactions')
          .where('unread', isEqualTo: true)
          .get();
      for (final doc in snap.docs) {
        await doc.reference.update({'unread': false});
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final fallbackInteractions = [
      {
        "user": "Amina",
        "action": "sent you a Rose gift in Dessie VIP Chill",
        "time": "Recent",
        "icon": Icons.card_giftcard,
        "color": Colors.pinkAccent,
        "roomId": "room_dessie_vip",
        "roomTitle": "Dessie VIP Chill 🎧",
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
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black, size: 18),

onPressed: () => Navigator.pop(context),
        ),
      ),
      body: StreamBuilder(
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(widget.uid)
            .collection('interactions')
            .orderBy('timestamp', descending: true)
            .limit(30)
            .snapshots(),
        builder: (context, snapshot) {
          final List list = [];
          if (snapshot.hasData && snapshot.data != null) {
            final qSnap = snapshot.data as QuerySnapshot;
            for (final doc in qSnap.docs) {
              final raw = doc.data();
              final Map d = raw is Map ? raw : {};
              list.add({
                "user": (d['senderName'] ?? 'User').toString(),
                "action": (d['action'] ?? 'interacted with you').toString(),
                "time": d['timestamp'] is Timestamp
                    ? (d['timestamp'] as Timestamp)
                        .toDate()
                        .toString()
                        .substring(11, 16)
                    : 'New',
                "icon": Icons.favorite,
                "color": Colors.pinkAccent,
                "roomId": (d['roomId'] ?? '').toString(),
                "roomTitle": (d['roomTitle'] ?? 'Party Lounge').toString(),
              });
            }
          }
          if (list.isEmpty) {
            list.addAll(fallbackInteractions);
          }

          return ListView.separated(
            padding: const EdgeInsets.all(12),
            itemCount: list.length,
            separatorBuilder: (_, __) =>
                const Divider(height: 1, color: Color(0xFFE8ECEF)),
            itemBuilder: (context, index) {
              final item = list[index] as Map;
              final roomId = (item["roomId"] ?? "").toString();
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
                onTap: roomId.isNotEmpty
                    ? () async {
                        final user = FirebaseAuth.instance.currentUser;
                        final myUid = user?.uid ?? widget.uid;
                        final myDoc = await FirebaseFirestore.instance
                            .collection('users')
                            .doc(myUid)
                            .get();
                        final d = myDoc.data() ?? {};
                        final myName = (d['name'] ??
                                d['nickname'] ??
                                user?.displayName ??
                                'User')
                            .toString();
                        final int numId =
                            (d['numericId'] as num?)?.toInt() ?? 100001;
                        if (!context.mounted) return;
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => VoiceRoomScreen(

roomTitle: (item["roomTitle"] ?? "Party Lounge")
                                  .toString(),
                              roomId: roomId,
                              hostName: item["user"].toString(),
                              userNumericId: numId,
                              userUid: myUid,
                              userName: myName,
                            ),
                          ),
                        );
                      }
                    : null,
              );
            },
          );
        },
      ),
    );
  }
}

class FollowersListScreen extends StatefulWidget {
  final String uid;
  final void Function(String peerUid, String peerName, String peerAvatar)
      onMessageUser;

  const FollowersListScreen({
    super.key,
    required this.uid,
    required this.onMessageUser,
  });

  @override
  State<FollowersListScreen> createState() => _FollowersListScreenState();
}

class _FollowersListScreenState extends State<FollowersListScreen> {
  final Set _followingUids = {};

  @override
  void initState() {
    super.initState();
    _markFollowersRead();
    _loadFollowing();
  }

  Future _markFollowersRead() async {
    try {
      final snap = await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.uid)
          .collection('followers')
          .where('unread', isEqualTo: true)
          .get();
      for (final doc in snap.docs) {
        await doc.reference.update({'unread': false});
      }
    } catch (_) {}
  }

  Future _loadFollowing() async {
    try {
      final snap = await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.uid)
          .collection('following')
          .get();
      if (!mounted) return;
      setState(() {
        for (final d in snap.docs) {
          _followingUids.add(d.id);
        }
      });
    } catch (_) {}
  }

  Future _toggleFollowBack(
      String peerUid, String peerName, String peerAvatar) async {
    final db = FirebaseFirestore.instance;
    final bool currentlyFollowing = _followingUids.contains(peerUid);

    setState(() {
      if (currentlyFollowing) {
        _followingUids.remove(peerUid);
      } else {
        _followingUids.add(peerUid);
      }
    });

    try {
      final myUserRef = db.collection('users').doc(widget.uid);
      final peerUserRef = db.collection('users').doc(peerUid);

      if (currentlyFollowing) {
        await myUserRef.collection('following').doc(peerUid).delete();
        await peerUserRef.collection('followers').doc(widget.uid).delete();
        await myUserRef.set({
          'followingCount': FieldValue.increment(-1),
          'friendsCount': FieldValue.increment(-1),
        }, SetOptions(merge: true));
      } else {
        await myUserRef.collection('following').doc(peerUid).set({
          'uid': peerUid,
          'name': peerName,
          'avatarUrl': peerAvatar,
          'timestamp': FieldValue.serverTimestamp(),
        });
        await peerUserRef.collection('followers').doc(widget.uid).set({
          'uid': widget.uid,
          'name': FirebaseAuth.instance.currentUser?.displayName ?? 'User',
          'unread': true,
          'timestamp': FieldValue.serverTimestamp(),
        });
        await myUserRef.set({
          'followingCount': FieldValue.increment(1),
          'friendsCount': FieldValue.increment(1),
        }, SetOptions(merge: true));
      }
    } catch (_) {}
  }

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
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black, size: 18),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: StreamBuilder(
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(widget.uid)
            .collection('followers')
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData || snapshot.data == null) {
            return const Center(
              child: CircularProgressIndicator(color: Color(0xFF00C9A7)),
            );
          }
          final qSnap = snapshot.data as QuerySnapshot;
          final docs = qSnap.docs;
          if (docs.isEmpty) {
            return const Center(
              child: Text(
                "No followers yet",
                style: TextStyle(color: Colors.black45, fontSize: 14),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final raw = docs[index].data();
              final Map person = raw is Map ? raw : {};
              final peerUid = docs[index].id;
              final peerName = (person['name'] ?? 'User').toString();
              final peerBio = (person['bio'] ?? 'NILE Live Member').toString();
              final peerAvatar = (person['avatarUrl'] ?? '').toString();
              final bool isFollowing = _followingUids.contains(peerUid);

              return Card(
                elevation: 0.3,
                margin: const EdgeInsets.symmetric(vertical: 4),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: const Color(0xFF261D45),
                    child: Text(
                      peerName.isNotEmpty ? peerName[0].toUpperCase() : 'U',
                      style: const TextStyle(
                          color: Color(0xFFFFD700),
                          fontWeight: FontWeight.bold),
                    ),
                  ),
                  title: Text(
                    peerName,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  subtitle: Text(
                    peerBio,
                    style: const TextStyle(fontSize: 12, color: Colors.black54),
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.chat_bubble_outline_rounded,
                            color: Color(0xFF1BB3C8), size: 20),
                        onPressed: () {
                          Navigator.pop(context);
                          widget.onMessageUser(peerUid, peerName, peerAvatar);
                        },
                      ),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          elevation: 0,
                          backgroundColor: isFollowing
                              ? const Color(0xFFE8ECEF)
                              : const Color(0xFF00C9A7),
                          foregroundColor:
                              isFollowing ? Colors.black87 : Colors.white,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(18)),
                          padding: const EdgeInsets.symmetric(

horizontal: 12, vertical: 8),
                        ),
                        onPressed: () =>
                            _toggleFollowBack(peerUid, peerName, peerAvatar),
                        child: Text(
                          isFollowing ? "Friends" : "Follow Back",
                          style: const TextStyle(
                              fontSize: 11, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
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
