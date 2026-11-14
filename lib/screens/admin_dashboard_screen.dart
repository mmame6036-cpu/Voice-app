import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  static const Color bgDark = Color(0xFF0F0B1E);
  static const Color cardDark = Color(0xFF18122B);
  static const Color goldAccent = Color(0xFFF3BA2F);
  static const Color cyanAccent = Color(0xFF00E5FF);

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 4,
      child: Scaffold(
        backgroundColor: bgDark,
        appBar: AppBar(
          backgroundColor: cardDark,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new,
                color: Colors.white, size: 18),
            onPressed: () => Navigator.pop(context),
          ),
          title: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.admin_panel_settings, color: goldAccent, size: 22),
              SizedBox(width: 8),
              Text(
                "NILE Live Admin",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          centerTitle: true,
          bottom: const TabBar(
            isScrollable: true,
            indicatorColor: goldAccent,
            labelColor: goldAccent,
            unselectedLabelColor: Colors.white60,
            labelStyle: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
            tabs: [
              Tab(icon: Icon(Icons.payments, size: 18), text: "Withdraws"),
              Tab(icon: Icon(Icons.headset_mic, size: 18), text: "Support"),
              Tab(icon: Icon(Icons.campaign, size: 18), text: "Alerts"),
              Tab(icon: Icon(Icons.manage_accounts, size: 18), text: "Users"),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            _WithdrawRequestsTab(),
            _SupportInboxTab(),
            _BroadcastAlertsTab(),
            _UserManagerTab(),
          ],
        ),
      ),
    );
  }
}

// ============================================================================
// 1. WITHDRAW REQUESTS TAB (Approve / Reject Cashouts)
// ============================================================================
class _WithdrawRequestsTab extends StatelessWidget {
  const _WithdrawRequestsTab();

  Future<void> _approveRequest(
    BuildContext context,
    String docId,
    String userUid,
    int points,
    double usdAmount,
    String method,
  ) async {
    try {
      final db = FirebaseFirestore.instance;
      await db.collection('withdraw_requests').doc(docId).update({
        'status': 'APPROVED',
        'processedAt': FieldValue.serverTimestamp(),
      });

      if (userUid.isNotEmpty) {
        await db
            .collection('users')
            .doc(userUid)
            .collection('system_messages')
            .add({
          'title': 'Withdrawal Approved! ✅',
          'subtitle':
              'Your \$${usdAmount.toStringAsFixed(2)} payout via $method is sent.',
          'body':
              'Good news! Your withdrawal request of $points Points (\$${usdAmount.toStringAsFixed(2)}) via $method has been approved and paid out by NILE Live Admin.',
          'unread': true,
          'timestamp': FieldValue.serverTimestamp(),
        });
      }

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(

backgroundColor: Color(0xFF00C9A7),
            content: Text(
              "የወጪ ጥያቄው ጸድቋል (Approved)!",
              style:
                  TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
            ),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("ስህተት: $e")),
        );
      }
    }
  }

  Future<void> _rejectAndRefund(
    BuildContext context,
    String docId,
    String userUid,
    int points,
  ) async {
    try {
      final db = FirebaseFirestore.instance;
      await db.collection('withdraw_requests').doc(docId).update({
        'status': 'REJECTED',
        'processedAt': FieldValue.serverTimestamp(),
      });

      if (userUid.isNotEmpty) {
        await db.collection('users').doc(userUid).set({
          'points': FieldValue.increment(points),
        }, SetOptions(merge: true));

        await db
            .collection('users')
            .doc(userUid)
            .collection('system_messages')
            .add({
          'title': 'Withdrawal Rejected & Refunded',
          'subtitle': '$points Points returned to your wallet.',
          'body':
              'Your withdrawal request could not be processed (please verify your payment address/phone). $points Points have been refunded back to your Points Wallet.',
          'unread': true,
          'timestamp': FieldValue.serverTimestamp(),
        });
      }

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            backgroundColor: Colors.orangeAccent,
            content: Text(
              "ጥያቄው ተመልሷል፤ ነጥቡ ወደ ተጠቃሚው ዋሌት ገብቷል!",
              style:
                  TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
            ),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("ስህተት: $e")),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('withdraw_requests')
          .orderBy('createdAt', descending: true)
          .limit(50)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(
            child: CircularProgressIndicator(color: Color(0xFFF3BA2F)),
          );
        }
        if (snapshot.data == null) {
          return const Center(
            child: Text("No requests found",
                style: TextStyle(color: Colors.white54)),
          );
        }

        final docs = snapshot.data!.docs;
        if (docs.isEmpty) {
          return const Center(
            child: Text(
              "እስካሁን ምንም የወጪ ጥያቄ የለም",
              style: TextStyle(color: Colors.white60, fontSize: 14),
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(14),
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final doc = docs[index];
            final raw = doc.data();
            final Map d = raw is Map ? raw : {};

            final String status = (d['status'] ?? 'PENDING').toString();
            final int numericId = (d['userNumericId'] as num?)?.toInt() ?? 0;
            final String userUid = (d['userUid'] ?? '').toString();
            final int points = (d['points'] as num?)?.toInt() ?? 0;
            final double usdAmount =
                (d['usdAmount'] as num?)?.toDouble() ?? (points / 10000.0);
            final String method = (d['method'] ?? 'USDT').toString();
            final String account = (d['account'] ?? '').toString();

            Color statusColor = Colors.orangeAccent;
            if (status == 'APPROVED') statusColor = const Color(0xFF00C9A7);
            if (status == 'REJECTED') statusColor = Colors.redAccent;

return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFF18122B),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "User ID: $numericId",
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: statusColor.withOpacity(0.18),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          status,
                          style: TextStyle(
                            color: statusColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 11,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "Amount: \$${usdAmount.toStringAsFixed(2)} USD  (💎 $points Pts)",
                    style: const TextStyle(
                      color: Color(0xFF00E5FF),
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          "$method: $account",
                          style: const TextStyle(
                              color: Colors.white70, fontSize: 13),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.copy,
                            color: Color(0xFFF3BA2F), size: 18),
                        tooltip: "Copy Account",
                        onPressed: () {
                          Clipboard.setData(ClipboardData(text: account));
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content: Text("አካውንቱ ኮፒ ተደርጓል!")),
                          );
                        },
                      ),
                    ],
                  ),
                  if (status == 'PENDING') ...[
                    const Divider(color: Colors.white12),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.redAccent,
                              side: const BorderSide(color: Colors.redAccent),
                            ),
                            onPressed: () => _rejectAndRefund(
                                context, doc.id, userUid, points),
                            child: const Text("Reject & Refund"),
                          ),
                        ),
                        const SizedBox(width: 10),

Expanded(
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF00C9A7),
                              foregroundColor: Colors.black,
                            ),
                            onPressed: () => _approveRequest(
                              context,
                              doc.id,
                              userUid,
                              points,
                              usdAmount,
                              method,
                            ),
                            child: const Text(
                              "Approve Paid",
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                      ],
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
}

// ============================================================================
// 2. CUSTOMER SERVICE INBOX TAB (Live Support Reply)
// ============================================================================
class _SupportInboxTab extends StatelessWidget {
  const _SupportInboxTab();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('support_chats')
          .orderBy('updatedAt', descending: true)
          .limit(50)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(
            child: CircularProgressIndicator(color: Color(0xFFF3BA2F)),
          );
        }
        if (snapshot.data == null) {
          return const Center(
            child: Text("No support messages",
                style: TextStyle(color: Colors.white54)),
          );
        }

        final docs = snapshot.data!.docs;
        if (docs.isEmpty) {
          return const Center(
            child: Text(
              "እስካሁን ከደንበኞች የመጣ መልእክት የለም",
              style: TextStyle(color: Colors.white60, fontSize: 14),
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(12),
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final doc = docs[index];
            final raw = doc.data();
            final Map d = raw is Map ? raw : {};

            final String uid = doc.id;
            final String lastMsg = (d['lastMessage'] ?? '').toString();
            final int adminUnread = (d['adminUnread'] as num?)?.toInt() ?? 0;

            return Card(
              color: const Color(0xFF18122B),
              margin: const EdgeInsets.only(bottom: 10),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
                side: const BorderSide(color: Colors.white12),
              ),
              child: ListTile(
                leading: const CircleAvatar(
                  backgroundColor: Color(0xFF26A69A),
                  child: Icon(Icons.person, color: Colors.white),
                ),
                title: Text(
                  "User: $uid",
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                subtitle: Text(
                  lastMsg,
                  style: const TextStyle(color: Colors.white60, fontSize: 12.5),
                  maxLines: 1,

overflow: TextOverflow.ellipsis,
                ),
                trailing: adminUnread > 0
                    ? Container(
                        padding: const EdgeInsets.all(7),
                        decoration: const BoxDecoration(
                          color: Colors.redAccent,
                          shape: BoxShape.circle,
                        ),
                        child: Text(
                          "$adminUnread",
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      )
                    : const Icon(Icons.chevron_right, color: Colors.white38),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => AdminSupportReplyScreen(userUid: uid),
                    ),
                  );
                },
              ),
            );
          },
        );
      },
    );
  }
}

class AdminSupportReplyScreen extends StatefulWidget {
  final String userUid;
  const AdminSupportReplyScreen({super.key, required this.userUid});

  @override
  State<AdminSupportReplyScreen> createState() =>
      _AdminSupportReplyScreenState();
}

class _AdminSupportReplyScreenState extends State<AdminSupportReplyScreen> {
  final TextEditingController _replyController = TextEditingController();

  @override
  void initState() {
    super.initState();
    FirebaseFirestore.instance
        .collection('support_chats')
        .doc(widget.userUid)
        .set({'adminUnread': 0}, SetOptions(merge: true));
  }

  @override
  void dispose() {
    _replyController.dispose();
    super.dispose();
  }

  Future<void> _sendAdminReply() async {
    final text = _replyController.text.trim();
    if (text.isEmpty) return;
    _replyController.clear();

    final chatRef = FirebaseFirestore.instance
        .collection('support_chats')
        .doc(widget.userUid);

    await chatRef.collection('messages').add({
      'text': text,
      'isSupport': true,
      'timestamp': FieldValue.serverTimestamp(),
    });

    await chatRef.set({
      'lastMessage': text,
      'updatedAt': FieldValue.serverTimestamp(),
      'userUnread': FieldValue.increment(1),
      'adminUnread': 0,
    }, SetOptions(merge: true));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0B1E),
      appBar: AppBar(
        backgroundColor: const Color(0xFF18122B),
        title: Text(
          "Reply: ${widget.userUid}",
          style: const TextStyle(color: Colors.white, fontSize: 14),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('support_chats')
                  .doc(widget.userUid)
                  .collection('messages')
                  .orderBy('timestamp', descending: false)
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(
                    child: CircularProgressIndicator(color: Color(0xFFF3BA2F)),
                  );
                }
                if (snapshot.data == null) {
                  return const SizedBox.shrink();
                }

                final docs = snapshot.data!.docs;
                return ListView.builder(
                  padding: const EdgeInsets.all(14),
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    final raw = docs[index].data();
                    final Map data = raw is Map ? raw : {};
                    final bool isSupport = data['isSupport'] == true;
                    final String text = (data['text'] ?? '').toString();

return Align(
                      alignment: isSupport
                          ? Alignment.centerRight
                          : Alignment.centerLeft,
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 10),
                        constraints: BoxConstraints(
                          maxWidth: MediaQuery.of(context).size.width * 0.76,
                        ),
                        decoration: BoxDecoration(
                          color: isSupport
                              ? const Color(0xFFF3BA2F)
                              : const Color(0xFF261D45),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Text(
                          text,
                          style: TextStyle(
                            color: isSupport ? Colors.black : Colors.white,
                            fontSize: 14,
                            fontWeight:
                                isSupport ? FontWeight.w600 : FontWeight.normal,
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
              color: const Color(0xFF18122B),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _replyController,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        hintText: "መልስ ይጻፉ...",
                        hintStyle: const TextStyle(color: Colors.white38),
                        filled: true,
                        fillColor: const Color(0xFF0F0B1E),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      onSubmitted: (_) => _sendAdminReply(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  CircleAvatar(
                    backgroundColor: const Color(0xFFF3BA2F),
                    child: IconButton(
                      icon: const Icon(Icons.send, color: Colors.black),
                      onPressed: _sendAdminReply,
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

// ============================================================================
// 3. BROADCAST ALERTS TAB (Official Notification & Personal System Message)
// ============================================================================
class _BroadcastAlertsTab extends StatefulWidget {
  const _BroadcastAlertsTab();

  @override
  State<_BroadcastAlertsTab> createState() => _BroadcastAlertsTabState();
}

class _BroadcastAlertsTabState extends State<_BroadcastAlertsTab> {
  final _officialTitleCtrl = TextEditingController();
  final _officialSubCtrl = TextEditingController();
  final _officialBodyCtrl = TextEditingController();

  final _targetIdCtrl = TextEditingController();
  final _sysTitleCtrl = TextEditingController();
  final _sysBodyCtrl = TextEditingController();

  bool _isSending = false;

  @override
  void dispose() {
    _officialTitleCtrl.dispose();
    _officialSubCtrl.dispose();
    _officialBodyCtrl.dispose();
    _targetIdCtrl.dispose();
    _sysTitleCtrl.dispose();
    _sysBodyCtrl.dispose();
    super.dispose();
  }

Future<void> _sendOfficialBroadcast() async {
    final title = _officialTitleCtrl.text.trim();
    final body = _officialBodyCtrl.text.trim();
    final sub = _officialSubCtrl.text.trim().isEmpty
        ? body
        : _officialSubCtrl.text.trim();

    if (title.isEmpty) return;
    if (body.isEmpty) return;

    setState(() => _isSending = true);
    try {
      await FirebaseFirestore.instance
          .collection('official_notifications')
          .add({
        'title': title,
        'subtitle': sub,
        'details': body,
        'timestamp': FieldValue.serverTimestamp(),
      });

      _officialTitleCtrl.clear();
      _officialSubCtrl.clear();
      _officialBodyCtrl.clear();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            backgroundColor: Color(0xFF00C9A7),
            content: Text(
              "ማስታወቂያው ለሁሉም ተጠቃሚ ተልኳል!",
              style:
                  TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  Future<void> _sendPersonalSystemMsg() async {
    final numId = int.tryParse(_targetIdCtrl.text.trim());
    final title = _sysTitleCtrl.text.trim();
    final body = _sysBodyCtrl.text.trim();

    if (numId == null) return;
    if (title.isEmpty) return;
    if (body.isEmpty) return;

    setState(() => _isSending = true);
    try {
      final db = FirebaseFirestore.instance;
      final snap = await db
          .collection('users')
          .where('numericId', isEqualTo: numId)
          .limit(1)
          .get();

      if (snap.docs.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("ID $numId አልተገኘም!")),
          );
        }
        return;
      }

      final targetUid = snap.docs.first.id;
      await db
          .collection('users')
          .doc(targetUid)
          .collection('system_messages')
          .add({
        'title': title,
        'subtitle': body,
        'body': body,
        'unread': true,
        'timestamp': FieldValue.serverTimestamp(),
      });

      _targetIdCtrl.clear();
      _sysTitleCtrl.clear();
      _sysBodyCtrl.clear();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: const Color(0xFF00C9A7),
            content: Text(
              "መልእክቱ ለ ID $numId ተልኳል!",
              style: const TextStyle(
                  color: Colors.black, fontWeight: FontWeight.bold),
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section 1: Global Official Notification
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF18122B),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "📢 Official Notification (ለሁሉም ተጠቃሚ)",
                  style: TextStyle(
                    color: Color(0xFF00E5FF),
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 12),
                _darkField(_officialTitleCtrl, "Title (ርዕስ)"),

const SizedBox(height: 10),
                _darkField(_officialSubCtrl, "Short Summary (አጭር መግለጫ)"),
                const SizedBox(height: 10),
                _darkField(_officialBodyCtrl, "Full Message (ዝርዝር መልእክት)",
                    maxLines: 3),
                const SizedBox(height: 14),
                SizedBox(
                  width: double.infinity,
                  height: 45,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF00E5FF),
                      foregroundColor: Colors.black,
                    ),
                    onPressed: _isSending ? null : _sendOfficialBroadcast,
                    child: const Text(
                      "Send to All Users",
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Section 2: Personal System Message
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF18122B),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "✉️ System Message (ለአንድ ተጠቃሚ በ ID)",
                  style: TextStyle(
                    color: Color(0xFFF3BA2F),
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 12),
                _darkField(_targetIdCtrl, "User Numeric ID (ለምሳሌ 100001)",
                    isNumber: true),
                const SizedBox(height: 10),
                _darkField(_sysTitleCtrl, "Title (ርዕስ)"),
                const SizedBox(height: 10),
                _darkField(_sysBodyCtrl, "Message (መልእክት)", maxLines: 3),
                const SizedBox(height: 14),
                SizedBox(
                  width: double.infinity,
                  height: 45,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFF3BA2F),
                      foregroundColor: Colors.black,
                    ),
                    onPressed: _isSending ? null : _sendPersonalSystemMsg,
                    child: const Text(
                      "Send System Message",
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _darkField(TextEditingController ctrl, String hint,
      {int maxLines = 1, bool isNumber = false}) {
    return TextField(
      controller: ctrl,
      maxLines: maxLines,
      keyboardType: isNumber ? TextInputType.number : TextInputType.text,
      style: const TextStyle(color: Colors.white, fontSize: 14),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Colors.white38, fontSize: 13),
        filled: true,
        fillColor: const Color(0xFF0F0B1E),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}

// ============================================================================
// 4. USER & WALLET MANAGER TAB (Search ID, Add/Deduct Coins, Ban/Unban)
// ============================================================================
class _UserManagerTab extends StatefulWidget {
  const _UserManagerTab();

  @override
  State<_UserManagerTab> createState() => _UserManagerTabState();
}

class _UserManagerTabState extends State<_UserManagerTab> {
  final _searchIdCtrl = TextEditingController();
  String? _foundUserUid;
  bool _isSearching = false;

  @override
  void dispose() {
    _searchIdCtrl.dispose();
    super.dispose();
  }

  Future<void> _searchUser() async {
    final id = int.tryParse(_searchIdCtrl.text.trim());
    if (id == null) return;

    setState(() {
      _isSearching = true;
      _foundUserUid = null;
    });

    try {
      final snap = await FirebaseFirestore.instance
          .collection('users')
          .where('numericId', isEqualTo: id)
          .limit(1)
          .get();

      if (snap.docs.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("ተጠቃሚ ID $id አልተገኘም!")),
          );
        }
      } else {
        setState(() {
          _foundUserUid = snap.docs.first.id;
        });
      }
    } finally {
      if (mounted) setState(() => _isSearching = false);
    }
  }

  void _showAdjustCoinsDialog(String uid, int numericId, bool isAdd) {
    final amountCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF18122B),
        title: Text(
          isAdd ? "Add Coins to ID $numericId" : "Deduct Coins from ID $numericId",
          style: const TextStyle(color: Colors.white, fontSize: 16),
        ),
        content: TextField(
          controller: amountCtrl,
          keyboardType: TextInputType.number,
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(
            hintText: "Enter coins amount (ለምሳሌ 50000)",
            hintStyle: TextStyle(color: Colors.white38),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Cancel", style: TextStyle(color: Colors.white54)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor:
                  isAdd ? const Color(0xFFF3BA2F) : Colors.redAccent,
              foregroundColor: isAdd ? Colors.black : Colors.white,
            ),
            onPressed: () async {
              final amt = int.tryParse(amountCtrl.text.trim()) ?? 0;
              if (amt <= 0) return;
              Navigator.pop(ctx);

              final int delta = isAdd ? amt : -amt;
              final db = FirebaseFirestore.instance;
              await db.collection('users').doc(uid).set({
                'coins': FieldValue.increment(delta),
              }, SetOptions(merge: true));

              if (isAdd) {
                await db
                    .collection('users')
                    .doc(uid)
                    .collection('system_messages')
                    .add({
                  'title': 'Coins Credited! 🪙',
                  'subtitle': 'Admin added $amt Coins to your wallet.',
                  'body':
                      'Official NILE Live Admin has added 🪙 $amt Coins to your account (ID: $numericId).',
                  'unread': true,
                  'timestamp': FieldValue.serverTimestamp(),
                });
              }

              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(isAdd
                        ? "🪙 $amt Coins ተጨምሯል!"
                        : "🪙 $amt Coins ተቀንሷል!"),
                  ),
                );
              }
            },
            child: Text(isAdd ? "Add Coins" : "Deduct Coins"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),

child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _searchIdCtrl,
                  keyboardType: TextInputType.number,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: "Search User Numeric ID (ለምሳሌ 100001)",
                    hintStyle: const TextStyle(color: Colors.white38),
                    filled: true,
                    fillColor: const Color(0xFF18122B),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  onSubmitted: (_) => _searchUser(),
                ),
              ),
              const SizedBox(width: 10),
              SizedBox(
                height: 52,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFF3BA2F),
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                  ),
                  onPressed: _isSearching ? null : _searchUser,
                  child: const Icon(Icons.search),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          if (_isSearching)
            const CircularProgressIndicator(color: Color(0xFFF3BA2F)),
          if (_foundUserUid != null)
            StreamBuilder<DocumentSnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('users')
                  .doc(_foundUserUid)
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const SizedBox.shrink();
                if (snapshot.data == null) return const SizedBox.shrink();
                final raw = snapshot.data!.data();
                final Map d = raw is Map ? raw : {};

                final String name =
                    (d['name'] ?? d['displayName'] ?? 'NILE User').toString();
                final int numId = (d['numericId'] as num?)?.toInt() ?? 0;
                final int coins = (d['coins'] as num?)?.toInt() ?? 0;
                final int points = (d['points'] as num?)?.toInt() ?? 0;
                final bool isBanned = d['isBanned'] == true;

                return Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF18122B),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isBanned
                          ? Colors.redAccent
                          : const Color(0xFFF3BA2F),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            "$name (ID: $numId)",
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          if (isBanned)
                            const Chip(
                              label: Text("BANNED",
                                  style: TextStyle(

color: Colors.white, fontSize: 10)),
                              backgroundColor: Colors.redAccent,
                            ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          Text(
                            "🪙 Coins: $coins",
                            style: const TextStyle(
                              color: Color(0xFFF3BA2F),
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                            ),
                          ),
                          Text(
                            "💎 Points: $points",
                            style: const TextStyle(
                              color: Color(0xFF00E5FF),
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFFF3BA2F),
                                foregroundColor: Colors.black,
                              ),
                              onPressed: () => _showAdjustCoinsDialog(
                                  _foundUserUid!, numId, true),
                              icon: const Icon(Icons.add, size: 18),
                              label: const Text("Add Coins",
                                  style:
                                      TextStyle(fontWeight: FontWeight.bold)),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: OutlinedButton.icon(
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Colors.orangeAccent,
                                side: const BorderSide(
                                    color: Colors.orangeAccent),
                              ),
                              onPressed: () => _showAdjustCoinsDialog(
                                  _foundUserUid!, numId, false),
                              icon: const Icon(Icons.remove, size: 18),
                              label: const Text("Deduct"),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: isBanned
                                ? const Color(0xFF00C9A7)
                                : Colors.redAccent,
                            foregroundColor:
                                isBanned ? Colors.black : Colors.white,
                          ),
                          onPressed: () async {
                            await FirebaseFirestore.instance
                                .collection('users')
                                .doc(_foundUserUid)
                                .set({'isBanned': !isBanned},
                                    SetOptions(merge: true));
                          },
                          icon: Icon(

isBanned ? Icons.lock_open : Icons.block,
                              size: 18),
                          label: Text(
                            isBanned
                                ? "Unban User (እገዳ አንሳ)"
                                : "Ban User (አግድ)",
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
        ],
      ),
    );
  }
}
