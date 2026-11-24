import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AgencyScreen extends AgencyCenterScreen {
  const AgencyScreen({
    super.key,
    super.agencyId,
  });
}

class AgencyCenterScreen extends StatefulWidget {
  final String? agencyId;

  const AgencyCenterScreen({
    super.key,
    this.agencyId,
  });

  @override
  State<AgencyCenterScreen> createState() => _AgencyCenterScreenState();
}

class _AgencyCenterScreenState extends State<AgencyCenterScreen> {
  static const Color kBgPage = Color(0xFFF3F6F6);
  static const Color kCardWhite = Colors.white;
  static const Color kTealPrimary = Color(0xFF109C76);
  static const Color kTealBright = Color(0xFF16B98C);
  static const Color kBlueInvite = Color(0xFF1B86A8);
  static const Color kTextDark = Color(0xFF1A2026);
  static const Color kTextMuted = Color(0xFF6B7785);

  final User? _currentUser = FirebaseAuth.instance.currentUser;

  String _myUid = "";
  String _agencyId = "";
  String _agencyName = "Agency";
  String _agencyTag = "VIP Voice";
  String _avatarUrl = "";
  int _numericId = 0;

  String _adminWhatsapp = "+251993105987";
  String _adminTelegram = "@kediroumer";

  int _todayHostPoints = 0;
  int _past30HostPoints = 0;
  int _todaySubAgentPoints = 0;
  int _past30SubAgentPoints = 0;
  int _otherIncomePoints = 0;
  int _withdrawnCommissionPoints = 0;
  int _userCoins = 0;

  List> _hostsList = [];
  List> _subAgenciesList = [];

  StreamSubscription? _userSub;
  StreamSubscription? _agencySub;
  StreamSubscription? _hostsSub;
  StreamSubscription? _subAgenciesSub;
  StreamSubscription? _contactSub;

  @override
  void initState() {
    super.initState();
    _initAgencyStreams();
  }

  @override
  void dispose() {
    _userSub?.cancel();
    _agencySub?.cancel();
    _hostsSub?.cancel();
    _subAgenciesSub?.cancel();
    _contactSub?.cancel();
    super.dispose();
  }

  void _initAgencyStreams() {
    final uid = _currentUser?.uid ?? "";
    _myUid = uid;
    if (uid.isEmpty) return;

    final db = FirebaseFirestore.instance;

    _contactSub = db
        .collection('app_config')
        .doc('admin_contacts')
        .snapshots()
        .listen((doc) {
      if (!mounted) return;
      if (!doc.exists) return;
      final d = doc.data() ?? <String, dynamic>{};
      final wa = (d['whatsapp'] ?? '').toString().trim();
      final tg = (d['telegram'] ?? '').toString().trim();
      setState(() {
        if (wa.isNotEmpty) _adminWhatsapp = wa;
        if (tg.isNotEmpty) _adminTelegram = tg;
      });
    }, onError: (_) {});

    _userSub = db.collection('users').doc(uid).snapshots().listen((doc) {
      if (!mounted) return;
      if (!doc.exists) return;
      final d = doc.data() ?? <String, dynamic>{};

      final int numId = (d['numericId'] as num?)?.toInt() ?? 0;
      final String name =
          (d['name'] ?? d['nickname'] ?? 'Agency').toString().trim();
      final String avatar =
          (d['avatarUrl'] ?? d['photoURL'] ?? '').toString().trim();
      final int coins = (d['coins'] as num?)?.toInt() ?? 0;

      String resolvedId = (widget.agencyId ?? '').trim();
      if (resolvedId.isEmpty) {
        final ownedId =
            (d['ownedAgencyId'] ?? d['agencyId'] ?? '').toString().trim();
        if (ownedId.isNotEmpty) {
          resolvedId = ownedId;
        } else if (numId > 0) {
          resolvedId = "$numId";
        } else {
          resolvedId = uid;
        }
      }

      final bool idChanged = resolvedId != _agencyId;

      setState(() {
        _numericId = numId;
        _userCoins = coins;
        if (name.isNotEmpty && _agencyName == "Agency") {
          _agencyName = name;
        }
        if (avatar.isNotEmpty) {
          _avatarUrl = avatar;
        }
        _agencyId = resolvedId;
      });

if (idChanged && resolvedId.isNotEmpty) {
        _bindAgencyDataListeners(resolvedId);
      }
    }, onError: (_) {});
  }

  void _bindAgencyDataListeners(String agId) {
    final db = FirebaseFirestore.instance;

    _agencySub?.cancel();
    _agencySub = db.collection('agencies').doc(agId).snapshots().listen((doc) {
      if (!mounted) return;
      if (!doc.exists) return;
      final d = doc.data() ?? <String, dynamic>{};
      final String agName = (d['name'] ?? '').toString().trim();
      final String agTag = (d['tag'] ?? d['agencyTag'] ?? '').toString().trim();
      final int withdrawn =
          (d['withdrawnCommissionPoints'] as num?)?.toInt() ?? 0;
      final int otherPts = (d['otherIncomePoints'] as num?)?.toInt() ?? 0;

      setState(() {
        if (agName.isNotEmpty) _agencyName = agName;
        if (agTag.isNotEmpty) _agencyTag = agTag;
        _withdrawnCommissionPoints = withdrawn;
        _otherIncomePoints = otherPts;
      });
    }, onError: (_) {});

    _hostsSub?.cancel();
    _hostsSub = db
        .collection('users')
        .where('agencyId', isEqualTo: agId)
        .snapshots()
        .listen((snap) {
      if (!mounted) return;
      int sumToday = 0;
      int sum30Days = 0;
      final List> loadedHosts = [];

      for (final doc in snap.docs) {
        final d = doc.data();
        final int tPts = (d['todayTaskPoints'] as num?)?.toInt() ?? 0;
        final int wPts = (d['weekTaskPoints'] as num?)?.toInt() ?? 0;
        final int rPts = (d['receivedGiftPoints'] as num?)?.toInt() ?? 0;
        final int totPts = (d['points'] as num?)?.toInt() ?? 0;
        final int best30 = max(wPts, max(rPts, totPts));

        sumToday += tPts;
        sum30Days += best30;

        loadedHosts.add({
          'uid': doc.id,
          'name': (d['name'] ?? d['nickname'] ?? 'Host').toString(),
          'numericId': (d['numericId'] as num?)?.toInt() ?? 0,
          'avatarUrl': (d['avatarUrl'] ?? d['photoURL'] ?? '').toString(),
          'todayPoints': tPts,
          'periodPoints': best30,
          'todayMicMinutes': (d['todayMicMinutes'] as num?)?.toInt() ?? 0,
        });
      }

      loadedHosts.sort((a, b) =>
          ((b['periodPoints'] as num?)?.toInt() ?? 0)
              .compareTo((a['periodPoints'] as num?)?.toInt() ?? 0));

      setState(() {
        _hostsList = loadedHosts;
        _todayHostPoints = sumToday;
        _past30HostPoints = sum30Days;
      });
    }, onError: (_) {});

    _subAgenciesSub?.cancel();
    _subAgenciesSub = db
        .collection('agencies')
        .where('parentAgencyId', isEqualTo: agId)
        .snapshots()
        .listen((snap) {
      if (!mounted) return;
      int subToday = 0;
      int sub30 = 0;
      final List> loadedSubs = [];

      for (final doc in snap.docs) {
        final d = doc.data();
        final int tPts = (d['todayHostPoints'] as num?)?.toInt() ?? 0;
        final int pPts = (d['totalHostPoints'] as num?)?.toInt() ?? 0;
        subToday += tPts;
        sub30 += pPts;

        loadedSubs.add({
          'agencyId': doc.id,
          'name': (d['name'] ?? 'Sub-Agency').toString(),
          'ownerNumericId': (d['ownerNumericId'] as num?)?.toInt() ?? 0,
          'totalHosts': (d['totalHosts'] as num?)?.toInt() ?? 0,
          'todayPoints': tPts,
          'periodPoints': pPts,
        });
      }

      setState(() {
        _subAgenciesList = loadedSubs;
        _todaySubAgentPoints = subToday;
        _past30SubAgentPoints = sub30;
      });
    }, onError: (_) {});
  }

  int get _combined30DayPoints => _past30HostPoints + _past30SubAgentPoints;

  int get _commissionRate {
    final pts = _combined30DayPoints;
    if (pts >= 30000000) return 20;
    if (pts >= 15000000) return 16;
    if (pts >= 5000000) return 12;
    if (pts >= 2000000) return 8;
    return 4;
  }

int get _nextLevelTarget {
    final pts = _combined30DayPoints;
    if (pts < 2000000) return 2000000;
    if (pts < 5000000) return 5000000;
    if (pts < 15000000) return 15000000;
    if (pts < 30000000) return 30000000;
    return 30000000;
  }

  int get _nextLevelRate {
    final rate = _commissionRate;
    if (rate == 4) return 8;
    if (rate == 8) return 12;
    if (rate == 12) return 16;
    return 20;
  }

  int get _stillNeededPoints {
    final diff = _nextLevelTarget - _combined30DayPoints;
    if (diff <= 0) return 0;
    return diff;
  }

  double get _levelProgress {
    final target = _nextLevelTarget;
    if (target <= 0) return 1.0;
    return (_combined30DayPoints / target).clamp(0.0, 1.0);
  }

  int get _myIncomeToday {
    final double rate = _commissionRate / 100.0;
    final int hostComm = (_todayHostPoints * rate).round();
    final int subComm = (_todaySubAgentPoints * 0.02).round();
    return hostComm + subComm;
  }

  int get _totalCommissionEarned {
    final double rate = _commissionRate / 100.0;
    final int hostComm = (_past30HostPoints * rate).round();
    final int subComm = (_past30SubAgentPoints * 0.02).round();
    return hostComm + subComm + _otherIncomePoints;
  }

  int get _availableCommissionPoints {
    final avail = _totalCommissionEarned - _withdrawnCommissionPoints;
    if (avail <= 0) return 0;
    return avail;
  }

  String _fmtNum(int n) {
    final String s = n.toString();
    final StringBuffer buf = StringBuffer();
    int count = 0;
    for (int i = s.length - 1; i >= 0; i--) {
      buf.write(s[i]);
      count++;
      if (count == 3 && i != 0) {
        buf.write(',');
        count = 0;
      }
    }
    return buf.toString().split('').reversed.join();
  }

  ImageProvider? _resolveAvatar(String url) {
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

  void _copyText(String text, String label) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("$label copied: $text"),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _showInviteModal({required bool isHostInvite}) {
    final String title = isHostInvite ? "Invite Host" : "Invite Sub-Agency";
    final String code = _agencyId.isNotEmpty ? _agencyId : "$_numericId";
    final String inviteMsg = isHostInvite
        ? "Join my NILE Live Agency ($_agencyName)! Open Me > Join Agency and enter Agency ID: $code"
        : "Partner with $_agencyName as a Sub-Agency on NILE Live! Enter Parent Agency ID: $code";

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 26),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.black12,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const SizedBox(height: 14),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 18,

fontWeight: FontWeight.w900,
                  color: kTextDark,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                isHostInvite
                    ? "Share your Agency ID below with new hosts so their live points count toward your commission."
                    : "Share your Agency ID with sub-agents to earn 2% override commission on their team.",
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 12.5, color: kTextMuted),
              ),
              const SizedBox(height: 16),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: const Color(0xFFEAF7F3),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: kTealPrimary.withOpacity(0.4)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Your Agency ID",
                          style: TextStyle(fontSize: 11, color: kTextMuted),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          code,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w900,
                            color: kTealPrimary,
                          ),
                        ),
                      ],
                    ),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: kTealPrimary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: () {
                        Navigator.pop(ctx);
                        _copyText(code, "Agency ID");
                      },
                      icon: const Icon(Icons.copy, size: 16),
                      label: const Text("Copy ID"),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                height: 46,
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: kTealPrimary,
                    side: const BorderSide(color: kTealPrimary, width: 1.3),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  onPressed: () {
                    Navigator.pop(ctx);
                    _copyText(inviteMsg, "Invitation Message");
                  },
                  icon: const Icon(Icons.share_rounded, size: 18),
                  label: const Text(
                    "Copy Full Invitation Link & Text",
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showAgencySettingsDialog() {
    final nameCtrl = TextEditingController(text: _agencyName);
    final tagCtrl = TextEditingController(text: _agencyTag);

    showDialog(
      context: context,

builder: (ctx) {
        return AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          title: const Text(
            "Agency Settings",
            style: TextStyle(fontWeight: FontWeight.w900, fontSize: 17),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameCtrl,
                decoration: const InputDecoration(
                  labelText: "Agency Name",
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: tagCtrl,
                decoration: const InputDecoration(
                  labelText: "Agency Tag (e.g. VIP Voice)",
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: kTealPrimary,
                foregroundColor: Colors.white,
              ),
              onPressed: () async {
                final newName = nameCtrl.text.trim();
                final newTag = tagCtrl.text.trim();
                Navigator.pop(ctx);
                if (_agencyId.isEmpty) return;

                setState(() {
                  if (newName.isNotEmpty) _agencyName = newName;
                  if (newTag.isNotEmpty) _agencyTag = newTag;
                });

                await FirebaseFirestore.instance
                    .collection('agencies')
                    .doc(_agencyId)
                    .set({
                  'name': _agencyName,
                  'tag': _agencyTag,
                  'ownerUid': _myUid,
                  'ownerNumericId': _numericId,
                }, SetOptions(merge: true)).catchError((_) {});
              },
              child: const Text("Save"),
            ),
          ],
        );
      },
    );
  }

  void _showWithdrawCommissionDialog() {
    final int availPts = _availableCommissionPoints;
    final ptsCtrl = TextEditingController(text: availPts > 0 ? "$availPts" : "");
    final accountCtrl = TextEditingController();
    String selectedMethod = "Exchange to Coins";

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 18,
                bottom: MediaQuery.of(context).viewInsets.bottom + 24,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Center(
                    child: Text(
                      "Agency Commission Payout",
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w900,
                        color: kTextDark,
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(

color: const Color(0xFFEAF7F3),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          "Available Commission:",
                          style: TextStyle(
                              fontSize: 12.5, fontWeight: FontWeight.w600),
                        ),
                        Text(
                          "${_fmtNum(availPts)} Pts",
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w900,
                            color: kTealPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: selectedMethod,
                    decoration: const InputDecoration(
                      labelText: "Payout Method",
                      border: OutlineInputBorder(),
                    ),
                    items: const [
                      DropdownMenuItem(
                        value: "Exchange to Coins",
                        child: Text("Instant Exchange to Coins"),
                      ),
                      DropdownMenuItem(
                        value: "USDT (TRC20 / Binance)",
                        child: Text("USDT (TRC20 / Binance Pay)"),
                      ),
                      DropdownMenuItem(
                        value: "Telebirr / CBE",
                        child: Text("Telebirr / Bank Transfer"),
                      ),
                    ],
                    onChanged: (val) {
                      if (val != null) {
                        setModalState(() => selectedMethod = val);
                      }
                    },
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: ptsCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: "Commission Points Amount",
                      border: OutlineInputBorder(),
                    ),
                  ),
                  if (selectedMethod != "Exchange to Coins") ...[
                    const SizedBox(height: 10),
                    TextField(
                      controller: accountCtrl,
                      decoration: const InputDecoration(
                        labelText: "Wallet Address / Phone / Account Number",
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ],
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    height: 46,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: kTealPrimary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      onPressed: () async {
                        final int reqPts =
                            int.tryParse(ptsCtrl.text.trim()) ?? 0;
                        if (reqPts <= 0) {
                          ScaffoldMessenger.of(this.context).showSnackBar(
                            const SnackBar(
                                content: Text("Enter a valid points amount")),

);
                          return;
                        }
                        if (reqPts > availPts) {
                          ScaffoldMessenger.of(this.context).showSnackBar(
                            const SnackBar(
                                content: Text(
                                    "Insufficient available commission points")),
                          );
                          return;
                        }

                        final db = FirebaseFirestore.instance;
                        Navigator.pop(ctx);

                        if (selectedMethod == "Exchange to Coins") {
                          final int coinsToAdd = reqPts;
                          await db.collection('agencies').doc(_agencyId).set({
                            'withdrawnCommissionPoints':
                                FieldValue.increment(reqPts),
                          }, SetOptions(merge: true));

                          await db.collection('users').doc(_myUid).set({
                            'coins': FieldValue.increment(coinsToAdd),
                          }, SetOptions(merge: true));

                          if (mounted) {
                            ScaffoldMessenger.of(this.context).showSnackBar(
                              SnackBar(
                                content: Text(
                                    "Converted ${_fmtNum(reqPts)} Pts into ${_fmtNum(coinsToAdd)} Coins!"),
                              ),
                            );
                          }
                        } else {
                          final acc = accountCtrl.text.trim();
                          if (acc.isEmpty) {
                            ScaffoldMessenger.of(this.context).showSnackBar(
                              const SnackBar(
                                  content: Text("Please enter account details")),
                            );
                            return;
                          }

                          final double usdAmt =
                              double.parse((reqPts / 10000.0).toStringAsFixed(2));

                          await db.collection('agencies').doc(_agencyId).set({
                            'withdrawnCommissionPoints':
                                FieldValue.increment(reqPts),
                          }, SetOptions(merge: true));

                          await db.collection('withdrawals').add({
                            'userUid': _myUid,
                            'userName': "$_agencyName (Agency $_agencyId)",
                            'method': selectedMethod,
                            'account': acc,
                            'points': reqPts,
                            'usdAmount': usdAmt,
                            'status': 'PENDING',
                            'type': 'AGENCY',
                            'createdAt': FieldValue.serverTimestamp(),
                          });

                          if (mounted) {
                            ScaffoldMessenger.of(this.context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                    "Agency withdrawal request submitted to Admin!"),
                              ),
                            );
                          }
                        }
                      },
                      child: const Text(
                        "Confirm Payout",
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _showHostsBreakdownSheet() {
    showModalBottomSheet(

context: context,
      backgroundColor: Colors.white,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (ctx) {
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.62,
          maxChildSize: 0.9,
          minChildSize: 0.4,
          builder: (_, scrollCtrl) {
            return Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
              child: Column(
                children: [
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.black12,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    "My Hosts (${_hostsList.length}) • Rate $_commissionRate%",
                    style: const TextStyle(
                      fontSize: 16.5,
                      fontWeight: FontWeight.w900,
                      color: kTextDark,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Expanded(
                    child: _hostsList.isEmpty
                        ? const Center(
                            child: Text(
                              "No hosts joined yet.\nTap 'Invite Host' to share your Agency ID!",
                              textAlign: TextAlign.center,
                              style:
                                  TextStyle(color: kTextMuted, fontSize: 13.5),
                            ),
                          )
                        : ListView.separated(
                            controller: scrollCtrl,
                            itemCount: _hostsList.length,
                            separatorBuilder: (_, __) =>
                                const Divider(height: 1),
                            itemBuilder: (context, idx) {
                              final h = _hostsList[idx];
                              final String name =
                                  (h['name'] ?? 'Host').toString();
                              final int numId =
                                  (h['numericId'] as num?)?.toInt() ?? 0;
                              final int tPts =
                                  (h['todayPoints'] as num?)?.toInt() ?? 0;
                              final int pPts =
                                  (h['periodPoints'] as num?)?.toInt() ?? 0;
                              final int myComm =
                                  (pPts * (_commissionRate / 100.0)).round();
                              final ImageProvider? img = _resolveAvatar(
                                  (h['avatarUrl'] ?? '').toString());

                              return ListTile(
                                contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 4, vertical: 4),
                                leading: CircleAvatar(
                                  radius: 22,
                                  backgroundColor: const Color(0xFFD9F3F0),
                                  backgroundImage: img,
                                  child: img == null
                                      ? Text(
                                          name.isNotEmpty
                                              ? name[0].toUpperCase()
                                              : 'H',
                                          style: const TextStyle(
                                            color: kTealPrimary,
                                            fontWeight: FontWeight.bold,

),
                                        )
                                      : null,
                                ),
                                title: Text(
                                  name,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w800,
                                    fontSize: 14,
                                  ),
                                ),
                                subtitle: Text(
                                  "ID: $numId • Today: ${_fmtNum(tPts)} Pts",
                                  style: const TextStyle(
                                      fontSize: 11.5, color: kTextMuted),
                                ),
                                trailing: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text(
                                      "${_fmtNum(pPts)} Pts",
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w800,
                                        fontSize: 12.5,
                                        color: kTextDark,
                                      ),
                                    ),
                                    Text(
                                      "+${_fmtNum(myComm)} Comm",
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 11,
                                        color: kTealPrimary,
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _showSubAgenciesBreakdownSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (ctx) {
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.55,
          maxChildSize: 0.85,
          minChildSize: 0.35,
          builder: (_, scrollCtrl) {
            return Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
              child: Column(
                children: [
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.black12,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    "Sub-Agencies (${_subAgenciesList.length})",
                    style: const TextStyle(
                      fontSize: 16.5,
                      fontWeight: FontWeight.w900,
                      color: kTextDark,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Expanded(
                    child: _subAgenciesList.isEmpty
                        ? const Center(
                            child: Text(
                              "No sub-agencies yet.\nTap 'Invite Agency' to recruit sub-agents!",
                              textAlign: TextAlign.center,

style:
                                  TextStyle(color: kTextMuted, fontSize: 13.5),
                            ),
                          )
                        : ListView.separated(
                            controller: scrollCtrl,
                            itemCount: _subAgenciesList.length,
                            separatorBuilder: (_, __) =>
                                const Divider(height: 1),
                            itemBuilder: (context, idx) {
                              final sub = _subAgenciesList[idx];
                              final String name =
                                  (sub['name'] ?? 'Sub-Agency').toString();
                              final String agId =
                                  (sub['agencyId'] ?? '').toString();
                              final int hostsCnt =
                                  (sub['totalHosts'] as num?)?.toInt() ?? 0;
                              final int pPts =
                                  (sub['periodPoints'] as num?)?.toInt() ?? 0;
                              final int overrideComm = (pPts * 0.02).round();

                              return ListTile(
                                leading: const CircleAvatar(
                                  backgroundColor: Color(0xFFE0F2FE),
                                  child: Icon(Icons.apartment_rounded,
                                      color: kBlueInvite),
                                ),
                                title: Text(
                                  name,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w800,
                                      fontSize: 14),
                                ),
                                subtitle: Text(
                                  "ID: $agId • Hosts: $hostsCnt",
                                  style: const TextStyle(
                                      fontSize: 11.5, color: kTextMuted),
                                ),
                                trailing: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text(
                                      "${_fmtNum(pPts)} Pts",
                                      style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 12),
                                    ),
                                    Text(
                                      "+${_fmtNum(overrideComm)} (2%)",
                                      style: const TextStyle(
                                          color: kTealPrimary,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 11),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildCoinDot() {
    return Container(
      width: 15,
      height: 15,
      margin: const EdgeInsets.only(right: 5),
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        color: kTealBright,
      ),
      child: const Center(
        child: Icon(Icons.diamond, color: Colors.white, size: 9.5),
      ),
    );
  }

  Widget _buildOverviewCard({
    required String title,
    required String subtitle,
    required String valueText,

bool showCoinDot = true,
    bool showChevron = false,
    VoidCallback? onTap,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
          decoration: BoxDecoration(
            color: const Color(0xFFE9EFEF),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      title,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: kTextDark,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (showChevron)
                    const Icon(Icons.chevron_right,
                        size: 16, color: kTextMuted),
                ],
              ),
              if (subtitle.isNotEmpty) ...[
                const SizedBox(height: 1),
                Text(
                  subtitle,
                  style: const TextStyle(fontSize: 10, color: kTextMuted),
                ),
              ],
              const SizedBox(height: 6),
              Row(
                children: [
                  if (showCoinDot) _buildCoinDot(),
                  Text(
                    valueText,
                    style: const TextStyle(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w900,
                      color: kTextDark,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildIncomeTile({
    required IconData icon,
    required String title,
    required String trailingValue,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
        child: Row(
          children: [
            Icon(icon, size: 19, color: kTextMuted),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w700,
                  color: kTextDark,
                ),
              ),
            ),
            Text(
              trailingValue,
              style: const TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
                color: kTealPrimary,
              ),
            ),
            const SizedBox(width: 4),
            const Icon(Icons.chevron_right, size: 18, color: kTextMuted),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final ImageProvider? profileAvatar = _resolveAvatar(_avatarUrl);
    final String displayId = _agencyId.isNotEmpty ? _agencyId : "$_numericId";
    final int rate = _commissionRate;
    final int nextRate = _nextLevelRate;
    final int stillNeed = _stillNeededPoints;
    final int targetPts = _nextLevelTarget;
    final double progress = _levelProgress;

    return Scaffold(
      backgroundColor: kBgPage,
      appBar: AppBar(
        backgroundColor: kBgPage,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              color: kTextDark, size: 18),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(

"Agency Center",
          style: TextStyle(
            color: kTextDark,
            fontSize: 16.5,
            fontWeight: FontWeight.w800,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined,
                color: kTextDark, size: 21),
            onPressed: _showAgencySettingsDialog,
          ),
        ],
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(14, 4, 14, 28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border:
                        Border.all(color: const Color(0xFFD49B42), width: 1.8),
                  ),
                  child: CircleAvatar(
                    backgroundColor: const Color(0xFF1F242D),
                    backgroundImage: profileAvatar,
                    child: profileAvatar == null
                        ? const Icon(Icons.workspace_premium,
                            color: Color(0xFFFFD700), size: 24)
                        : null,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _agencyName,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                          color: kTextDark,
                        ),
                      ),
                      const SizedBox(height: 2),
                      GestureDetector(
                        onTap: () => _copyText(displayId, "Agency ID"),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              "ID: $displayId",
                              style: const TextStyle(
                                fontSize: 12,
                                color: kTextMuted,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(width: 5),
                            const Icon(Icons.copy_rounded,
                                size: 13, color: kTextMuted),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1E293B),
                    foregroundColor: const Color(0xFFFFD700),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  onPressed: _showWithdrawCommissionDialog,
                  child: const Text(
                    "Withdraw",
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 14),

            Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 40,

child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: kTealPrimary,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                      onPressed: () => _showInviteModal(isHostInvite: true),
                      child: const Text(
                        "Invite Host",
                        style: TextStyle(
                            fontWeight: FontWeight.w800, fontSize: 13),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: SizedBox(
                    height: 40,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: kBlueInvite,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                      onPressed: () => _showInviteModal(isHostInvite: false),
                      child: const Text(
                        "Invite Agency",
                        style: TextStyle(
                            fontWeight: FontWeight.w800, fontSize: 13),
                      ),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 10),

            GestureDetector(
              onTap: _showAgencySettingsDialog,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
                decoration: BoxDecoration(
                  color: kCardWhite,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Text(
                      "Agency Tag",
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: kTextDark,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE6F4F1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        _agencyTag,
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: kTealPrimary,
                        ),
                      ),
                    ),
                    const Spacer(),
                    const Icon(Icons.chevron_right,
                        size: 18, color: kTextMuted),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 10),

            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: kCardWhite,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [

Row(
                    children: [
                      const Text(
                        "My Income Today: ",
                        style: TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w600,
                            color: kTextDark),
                      ),
                      _buildCoinDot(),
                      Text(
                        _fmtNum(_myIncomeToday),
                        style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w900,
                            color: kTextDark),
                      ),
                      const Spacer(),
                      Text(
                        "Avail: ${_fmtNum(_availableCommissionPoints)}",
                        style: const TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w800,
                          color: kTealPrimary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Total Host Points:",
                            style: TextStyle(
                                fontSize: 12.5,
                                fontWeight: FontWeight.w600,
                                color: kTextDark),
                          ),
                          Text(
                            "Past 30 Days",
                            style: TextStyle(fontSize: 10, color: kTextMuted),
                          ),
                        ],
                      ),
                      const SizedBox(width: 8),
                      _buildCoinDot(),
                      Text(
                        _fmtNum(_combined30DayPoints),
                        style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w900,
                            color: kTextDark),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Text(
                        "Commission Rate: ",
                        style: TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w600,
                            color: kTextDark),
                      ),
                      _buildCoinDot(),
                      Text(
                        "$rate%",
                        style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w900,
                            color: kTextDark),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF6F9F9),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              stillNeed > 0
                                  ? "Still need "
                                  : "Max Tier Reached ",

style: const TextStyle(
                                  fontSize: 11.5, color: kTextMuted),
                            ),
                            if (stillNeed > 0) ...[
                              _buildCoinDot(),
                              Text(
                                "${_fmtNum(stillNeed)} ",
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w900,
                                  color: kTextDark,
                                ),
                              ),
                              Text(
                                "to reach next level $nextRate%",
                                style: const TextStyle(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFFD9534F),
                                ),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 8),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child: LinearProgressIndicator(
                            value: progress,
                            minHeight: 7,
                            backgroundColor: const Color(0xFFDCE4E4),
                            valueColor: const AlwaysStoppedAnimation<Color>(
                                kTealBright),
                          ),
                        ),
                        const SizedBox(height: 5),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                _buildCoinDot(),
                                Text(
                                  _fmtNum(_combined30DayPoints),
                                  style: const TextStyle(
                                      fontSize: 10.5,
                                      fontWeight: FontWeight.w700,
                                      color: kTextDark),
                                ),
                              ],
                            ),
                            Row(
                              children: [
                                _buildCoinDot(),
                                Text(
                                  _fmtNum(targetPts),
                                  style: const TextStyle(
                                      fontSize: 10.5,
                                      fontWeight: FontWeight.w700,
                                      color: kTextMuted),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 12),

            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: kCardWhite,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Overview",
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w900,
                      color: kTextDark,
                    ),
                  ),

const SizedBox(height: 10),
                  Row(
                    children: [
                      _buildOverviewCard(
                        title: "Host Points",
                        subtitle: "Today",
                        valueText: _fmtNum(_todayHostPoints),
                        onTap: _showHostsBreakdownSheet,
                      ),
                      const SizedBox(width: 8),
                      _buildOverviewCard(
                        title: "My Hosts Points",
                        subtitle: "Past 30 Days",
                        valueText: _fmtNum(_past30HostPoints),
                        onTap: _showHostsBreakdownSheet,
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      _buildOverviewCard(
                        title: "Sub-agent Host Points",
                        subtitle: "Today",
                        valueText: _fmtNum(_todaySubAgentPoints),
                        onTap: _showSubAgenciesBreakdownSheet,
                      ),
                      const SizedBox(width: 8),
                      _buildOverviewCard(
                        title: "Sub-agent Host Points",
                        subtitle: "Past 30 Days",
                        valueText: _fmtNum(_past30SubAgentPoints),
                        onTap: _showSubAgenciesBreakdownSheet,
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      _buildOverviewCard(
                        title: "Host Number",
                        subtitle: "",
                        valueText: "${_hostsList.length}",
                        showCoinDot: false,
                        showChevron: true,
                        onTap: _showHostsBreakdownSheet,
                      ),
                      const SizedBox(width: 8),
                      _buildOverviewCard(
                        title: "Sub-agency Number",
                        subtitle: "",
                        valueText: "${_subAgenciesList.length}",
                        showCoinDot: false,
                        showChevron: true,
                        onTap: _showSubAgenciesBreakdownSheet,
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 10),

            Container(
              decoration: BoxDecoration(
                color: kCardWhite,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Column(
                children: [
                  _buildIncomeTile(
                    icon: Icons.mic_none_rounded,
                    title: "Host Income",
                    trailingValue:
                        "${_fmtNum((_past30HostPoints * (rate / 100.0)).round())} Pts",
                    onTap: _showHostsBreakdownSheet,
                  ),
                  const Divider(height: 1, indent: 42),
                  _buildIncomeTile(
                    icon: Icons.verified_user_outlined,
                    title: "Sub-agency Income",
                    trailingValue:
                        "${_fmtNum((_past30SubAgentPoints * 0.02).round())} Pts",
                    onTap: _showSubAgenciesBreakdownSheet,
                  ),
                  const Divider(height: 1, indent: 42),
                  _buildIncomeTile(
                    icon: Icons.account_balance_wallet_outlined,
                    title: "Other income",
                    trailingValue: "${_fmtNum(_otherIncomePoints)} Pts",
                    onTap: _showWithdrawCommissionDialog,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 12),

// Contact Admin (WhatsApp: +251993105987 & Telegram: @kediroumer)
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: kCardWhite,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Contact Admin",
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w900,
                      color: kTextDark,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF3F8F6),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: const Color(0xFF25D366),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.chat_rounded,
                              color: Colors.white, size: 20),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                "WhatsApp",
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w800,
                                  color: kTextDark,
                                ),
                              ),
                              Text(
                                _adminWhatsapp,
                                style: const TextStyle(
                                    fontSize: 11.5, color: kTextMuted),
                              ),
                            ],
                          ),
                        ),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFD9F3EA),
                            foregroundColor: kTealPrimary,
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 6),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          onPressed: () =>
                              _copyText(_adminWhatsapp, "Admin WhatsApp"),
                          child: const Text(
                            "Contact",
                            style: TextStyle(
                                fontSize: 12, fontWeight: FontWeight.w800),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(

color: const Color(0xFFF0F7FC),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: const Color(0xFF0088CC),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.send_rounded,
                              color: Colors.white, size: 19),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                "Telegram",
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w800,
                                  color: kTextDark,
                                ),
                              ),
                              Text(
                                _adminTelegram,
                                style: const TextStyle(
                                    fontSize: 11.5, color: kTextMuted),
                              ),
                            ],
                          ),
                        ),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFD6EEFA),
                            foregroundColor: const Color(0xFF0077B5),
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 6),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          onPressed: () =>
                              _copyText(_adminTelegram, "Admin Telegram"),
                          child: const Text(
                            "Contact",
                            style: TextStyle(
                                fontSize: 12, fontWeight: FontWeight.w800),
                          ),
                        ),
                      ],
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
}
