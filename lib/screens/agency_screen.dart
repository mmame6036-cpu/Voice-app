import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AgencyScreen extends StatefulWidget {
  final int userNumericId;

  const AgencyScreen({
    super.key,
    this.userNumericId = 0,
  });

  @override
  State<AgencyScreen> createState() => _AgencyScreenState();
}

class _AgencyScreenState extends State<AgencyScreen> {
  final User? _currentUser = FirebaseAuth.instance.currentUser;
  final TextEditingController _agencyNameController = TextEditingController();
  final TextEditingController _joinAgencyIdController = TextEditingController();
  final TextEditingController _hostIdController = TextEditingController();
  final TextEditingController _payoutAccountController = TextEditingController();

  bool _isLoading = false;
  bool _isCreatingAgency = false;
  String _selectedPayoutMethod = "Binance Pay (USDT)";

  static const int _pointsPerUsd = 10000;

  // Colors matching Entry Screen (Photo) & Dashboard (Video)
  static const Color kBgColor = Color(0xFFF3F5F7);
  static const Color kTealGreen = Color(0xFF00C875);
  static const Color kCyanBlue = Color(0xFF00B4D8);
  static const Color kMintCardStart = Color(0xFFDDF7EE);
  static const Color kMintCardEnd = Color(0xFFE2F4FC);
  static const Color kOverviewTileBg = Color(0xFFEEF9F6);
  static const Color kTextDark = Color(0xFF182026);
  static const Color kTextMuted = Color(0xFF7A869A);
  static const Color kCoralRed = Color(0xFFFF5252);
  static const Color kPurpleBannerStart = Color(0xFFC239B3);
  static const Color kPurpleBannerEnd = Color(0xFF7B2CBF);
  static const Color kOrangeCardStart = Color(0xFFF39C12);
  static const Color kOrangeCardEnd = Color(0xFFE67E22);

  final List _tiers = const [
    {'min': 0, 'max': 2000000, 'rate': 0.04, 'nextRate': 0.08},
    {'min': 2000000, 'max': 5000000, 'rate': 0.08, 'nextRate': 0.12},
    {'min': 5000000, 'max': 15000000, 'rate': 0.12, 'nextRate': 0.15},
    {'min': 15000000, 'max': 50000000, 'rate': 0.15, 'nextRate': 0.20},
    {'min': 50000000, 'max': 100000000, 'rate': 0.20, 'nextRate': 0.25},
  ];

  @override
  void dispose() {
    _agencyNameController.dispose();
    _joinAgencyIdController.dispose();
    _hostIdController.dispose();
    _payoutAccountController.dispose();
    super.dispose();
  }

  String _fmtNum(num val, {int decimals = 1}) {
    final double d = val.toDouble();
    final bool isWhole = d == d.roundToDouble() && decimals == 0;
    final String fixed =
        isWhole ? d.toInt().toString() : d.toStringAsFixed(decimals);
    final parts = fixed.split('.');
    final reg = RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))');
    final formattedInt = parts[0].replaceAllMapped(reg, (m) => '${m[1]},');
    if (parts.length > 1 && decimals > 0) {
      if (parts[1] == '0') return formattedInt;
      return '$formattedInt.${parts[1]}';
    }
    return formattedInt;
  }

  Map<String, dynamic> _getTierForPoints(int points) {
    for (final t in _tiers) {
      if (points < (t['max'] as int)) {
        return t;
      }
    }
    return _tiers.last;
  }

  void _copyText(String value, String label) {
    Clipboard.setData(ClipboardData(text: value));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("$label copied: $value"),
        backgroundColor: kTextDark,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Widget _coinBadge() {
    return Container(
      width: 17,
      height: 17,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          colors: [Color(0xFF00D2FF), Color(0xFF00C875)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: const Center(
        child: Text(
          "N",
          style: TextStyle(
            color: Colors.white,
            fontSize: 10,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
    );
  }

// =========================================================================
  // 1. JOIN AN AGENCY (For independent users tapping "Join" on My Agent card)
  // =========================================================================
  void _showJoinAgencyDialog() {
    _joinAgencyIdController.clear();
    bool isJoining = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text(
            "Join Agency",
            style: TextStyle(fontWeight: FontWeight.bold, color: kTextDark),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Enter the Agency ID provided by your agent:",
                style: TextStyle(fontSize: 13, color: kTextMuted),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _joinAgencyIdController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  hintText: "e.g. 1753925",
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text("Cancel", style: TextStyle(color: kTextMuted)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: kTealGreen,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: isJoining
                  ? null
                  : () async {
                      final enteredAgencyId =
                          _joinAgencyIdController.text.trim();
                      if (enteredAgencyId.isEmpty || _currentUser == null) {
                        return;
                      }
                      setDialogState(() => isJoining = true);
                      try {
                        final agencyDoc = await FirebaseFirestore.instance
                            .collection('agencies')
                            .doc(enteredAgencyId)
                            .get();

                        if (!agencyDoc.exists) {
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text("Agency ID not found!"),
                                backgroundColor: Colors.redAccent,
                              ),
                            );
                          }
                          return;
                        }

                        final aData = agencyDoc.data() ?? {};
                        if (aData['ownerUid'] == _currentUser!.uid) {
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content:
                                    Text("You cannot join your own agency."),
                              ),
                            );
                          }
                          return;
                        }

                        final String agencyName =
                            (aData['name'] ?? 'Agency').toString();

final batch = FirebaseFirestore.instance.batch();
                        final userRef = FirebaseFirestore.instance
                            .collection('users')
                            .doc(_currentUser!.uid);
                        final hostRef = FirebaseFirestore.instance
                            .collection('hosts')
                            .doc(_currentUser!.uid);

                        batch.set(
                          userRef,
                          {
                            'agencyId': enteredAgencyId,
                            'agencyName': agencyName,
                            'isHost': true,
                            'allowCreateAgency': false,
                            'joinedAgencyAt': FieldValue.serverTimestamp(),
                          },
                          SetOptions(merge: true),
                        );

                        batch.set(
                          hostRef,
                          {
                            'agencyId': enteredAgencyId,
                            'agencyName': agencyName,
                            'status': 'active',
                            'updatedAt': FieldValue.serverTimestamp(),
                          },
                          SetOptions(merge: true),
                        );

                        batch.update(agencyDoc.reference, {
                          'totalHosts': FieldValue.increment(1),
                        });

                        await batch.commit();

                        if (ctx.mounted) Navigator.pop(ctx);
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text("Successfully joined $agencyName!"),
                              backgroundColor: kTealGreen,
                            ),
                          );
                        }
                      } catch (e) {
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text("Failed to join: $e")),
                          );
                        }
                      } finally {
                        if (ctx.mounted) {
                          setDialogState(() => isJoining = false);
                        }
                      }
                    },
              child: isJoining
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text(
                      "Join",
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  // =========================================================================
  // 2. CREATE AGENCY (Enforces permission if user is under another agent)
  // =========================================================================
  void _handleCreateAgencyTap({
    required String joinedAgencyId,
    required String joinedAgencyName,
    required bool allowCreateAgency,
  }) {
    // Rule: If user is registered under another agent, block unless permitted
    if (joinedAgencyId.isNotEmpty && !allowCreateAgency) {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Row(
            children: [
              Icon(Icons.lock_outline, color: kCoralRed),

SizedBox(width: 8),
              Expanded(
                child: Text(
                  "Permission Required",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
                ),
              ),
            ],
          ),
          content: Text(
            "You are currently registered under \"$joinedAgencyName\" (ID: $joinedAgencyId).\n\n"
            "You cannot create your own agency unless the agent who recruited you enables your agency creation permission.",
            style: const TextStyle(fontSize: 13.5, color: kTextDark, height: 1.4),
          ),
          actions: [
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: kTextDark,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: () => Navigator.pop(ctx),
              child: const Text("OK"),
            ),
          ],
        ),
      );
      return;
    }

    // Permitted or independent -> Open Create Agency Dialog
    _agencyNameController.clear();
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text(
            "Create An Agency",
            style: TextStyle(fontWeight: FontWeight.bold, color: kTextDark),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Enter your Agency Name to open your Agency Center:",
                style: TextStyle(fontSize: 13, color: kTextMuted),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _agencyNameController,
                decoration: InputDecoration(
                  hintText: "e.g. NILE FAMS",
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text("Cancel", style: TextStyle(color: kTextMuted)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: kTealGreen,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: _isCreatingAgency
                  ? null
                  : () async {
                      final name = _agencyNameController.text.trim();
                      if (name.isEmpty || _currentUser == null) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text("Please enter an agency name"),
                          ),
                        );
                        return;
                      }

                      setDialogState(() => _isCreatingAgency = true);
                      setState(() => _isCreatingAgency = true);

                      try {
                        final newAgencyId =
                            "${1000000 + Random().nextInt(8999999)}";
                        await FirebaseFirestore.instance
                            .collection('agencies')
                            .doc(newAgencyId)
                            .set({

'agencyId': newAgencyId,
                          'ownerUid': _currentUser!.uid,
                          'ownerNumericId': widget.userNumericId,
                          'parentAgencyId': joinedAgencyId,
                          'name': name,
                          'commissionRate': 0.04,
                          'totalHosts': 0,
                          'tags': ['VIP Voice'],
                          'withdrawnCommissionPoints': 0,
                          'bonusCommissionPoints': 0,
                          'createdAt': FieldValue.serverTimestamp(),
                        });

                        if (ctx.mounted) Navigator.pop(ctx);
                      } catch (e) {
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text("Failed to create agency: $e"),
                            ),
                          );
                        }
                      } finally {
                        if (ctx.mounted) {
                          setDialogState(() => _isCreatingAgency = false);
                        }
                        if (mounted) {
                          setState(() => _isCreatingAgency = false);
                        }
                      }
                    },
              child: _isCreatingAgency
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text(
                      "Create",
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  // =========================================================================
  // 3. HOST RECRUITMENT & PERMISSION MANAGEMENT
  // =========================================================================
  Future<void> _addHostToAgency(
      BuildContext sheetCtx, String agencyId, String agencyName) async {
    final enteredId = int.tryParse(_hostIdController.text.trim());
    if (enteredId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please enter a valid Numeric User ID")),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      final userQuery = await FirebaseFirestore.instance
          .collection('users')
          .where('numericId', isEqualTo: enteredId)
          .limit(1)
          .get();

      if (userQuery.docs.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("User not found with this ID"),
              backgroundColor: Colors.redAccent,
            ),
          );
        }
        return;
      }

      final targetUserDoc = userQuery.docs.first;
      final targetData = targetUserDoc.data();
      final String existingAgency = (targetData['agencyId'] ?? '').toString();

      if (existingAgency.isNotEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("This user already belongs to an agency"),
              backgroundColor: Colors.orange,
            ),
          );
        }
        return;
      }

      final batch = FirebaseFirestore.instance.batch();

      batch.update(targetUserDoc.reference, {
        'agencyId': agencyId,
        'agencyName': agencyName,
        'isHost': true,
        'allowCreateAgency': false,
        'joinedAgencyAt': FieldValue.serverTimestamp(),
      });

final hostRef =
          FirebaseFirestore.instance.collection('hosts').doc(targetUserDoc.id);
      batch.set(
        hostRef,
        {
          'agencyId': agencyId,
          'agencyName': agencyName,
          'status': 'active',
          'updatedAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );

      final agencyRef =
          FirebaseFirestore.instance.collection('agencies').doc(agencyId);
      batch.update(agencyRef, {
        'totalHosts': FieldValue.increment(1),
      });

      await batch.commit();

      _hostIdController.clear();
      if (sheetCtx.mounted) Navigator.pop(sheetCtx);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Host successfully added to your agency!"),
            backgroundColor: kTealGreen,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Failed to add host: $e"),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _toggleHostCreateAgencyPermission(
      String hostUid, String hostName, bool allow) async {
    try {
      await FirebaseFirestore.instance.collection('users').doc(hostUid).update({
        'allowCreateAgency': allow,
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              allow
                  ? "Granted agency creation permission to $hostName"
                  : "Revoked agency creation permission from $hostName",
            ),
            backgroundColor: allow ? kTealGreen : kTextDark,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error updating permission: $e")),
        );
      }
    }
  }

  Future<void> _removeHostFromAgency(
      String agencyId, String hostUid, String hostName) async {
    try {
      final batch = FirebaseFirestore.instance.batch();
      final userRef =
          FirebaseFirestore.instance.collection('users').doc(hostUid);
      final hostRef =
          FirebaseFirestore.instance.collection('hosts').doc(hostUid);
      final agencyRef =
          FirebaseFirestore.instance.collection('agencies').doc(agencyId);

      batch.update(userRef, {
        'agencyId': '',
        'agencyName': '',
        'isHost': false,
        'allowCreateAgency': false,
      });

      batch.set(
        hostRef,
        {
          'agencyId': '',
          'agencyName': '',
          'status': 'removed',
          'updatedAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );

      batch.update(agencyRef, {
        'totalHosts': FieldValue.increment(-1),
      });

      await batch.commit();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("$hostName removed from agency")),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error removing host: $e")),
        );
      }
    }
  }

  void _showInviteHostSheet(String agencyId, String agencyName) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 20,
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,

),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: kTealGreen.withOpacity(0.12),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.person_add_alt_1, color: kTealGreen),
                ),
                const SizedBox(width: 10),
                const Text(
                  "Invite Host",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: kTextDark,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: kOverviewTileBg,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Agency Invite ID",
                          style: TextStyle(fontSize: 12, color: kTextMuted),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          agencyId,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: kTextDark,
                          ),
                        ),
                      ],
                    ),
                  ),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: kTealGreen,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                    onPressed: () => _copyText(agencyId, "Agency ID"),
                    icon: const Icon(Icons.copy, size: 15),
                    label: const Text("Copy ID"),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              "Add Host by User Numeric ID:",
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: kTextDark,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _hostIdController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      hintText: "e.g. 100069",
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 12,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: kTealGreen,
                    foregroundColor: Colors.white,

padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 14,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: _isLoading
                      ? null
                      : () => _addHostToAgency(ctx, agencyId, agencyName),
                  child: const Text(
                    "Add Host",
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showInviteAgencySheet(String parentAgencyId) {
    final subOwnerCtrl = TextEditingController();
    bool permitting = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 20,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: kCyanBlue.withOpacity(0.12),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.group_add, color: kCyanBlue),
                  ),
                  const SizedBox(width: 10),
                  const Text(
                    "Invite Sub-Agency",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: kTextDark,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              const Text(
                "Enter the Numeric ID of your host to grant them permission to create their own sub-agency under you:",
                style: TextStyle(fontSize: 12.5, color: kTextMuted),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: subOwnerCtrl,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: "Host Numeric ID",
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: kCyanBlue,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  onPressed: permitting
                      ? null
                      : () async {
                          final targetId =
                              int.tryParse(subOwnerCtrl.text.trim());
                          if (targetId == null) return;
                          setModalState(() => permitting = true);

try {
                            final q = await FirebaseFirestore.instance
                                .collection('users')
                                .where('numericId', isEqualTo: targetId)
                                .limit(1)
                                .get();
                            if (q.docs.isEmpty) {
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text("User ID not found!"),
                                  ),
                                );
                              }
                            } else {
                              await q.docs.first.reference.set({
                                'agencyId': parentAgencyId,
                                'allowCreateAgency': true,
                              }, SetOptions(merge: true));
                              if (ctx.mounted) Navigator.pop(ctx);
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      "Permission granted to ID $targetId to create a sub-agency!",
                                    ),
                                    backgroundColor: kCyanBlue,
                                  ),
                                );
                              }
                            }
                          } finally {
                            if (ctx.mounted) {
                              setModalState(() => permitting = false);
                            }
                          }
                        },
                  child: const Text(
                    "Grant Sub-Agency Permission",
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showEditNameDialog(String agencyId, String currentName) {
    final ctrl = TextEditingController(text: currentName);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Text(
          "Edit Agency Name",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        content: TextField(
          controller: ctrl,
          decoration: InputDecoration(
            hintText: "Enter agency name",
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: kTealGreen,
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              final val = ctrl.text.trim();
              if (val.isNotEmpty) {
                await FirebaseFirestore.instance
                    .collection('agencies')
                    .doc(agencyId)
                    .update({'name': val});
              }
              if (ctx.mounted) Navigator.pop(ctx);
            },
            child: const Text("Save"),
          ),
        ],
      ),
    );
  }

  void _showAgencyTagSheet(String agencyId, List<String> currentTags) {
    final allTags = [
      "VIP Voice",
      "PK Champions",
      "Music & Party",
      "24/7 Active",
      "Top Recruiters",
    ];
    final selected = Set<String>.from(currentTags);

showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Agency Tag",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: kTextDark,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                "Choose up to 2 tags for your agency badge:",
                style: TextStyle(fontSize: 12.5, color: kTextMuted),
              ),
              const SizedBox(height: 14),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: allTags.map((tag) {
                  final isOn = selected.contains(tag);
                  return FilterChip(
                    label: Text(tag),
                    selected: isOn,
                    selectedColor: kTealGreen.withOpacity(0.2),
                    checkmarkColor: kTealGreen,
                    onSelected: (val) {
                      setModalState(() {
                        if (val && selected.length < 2) {
                          selected.add(tag);
                        } else {
                          selected.remove(tag);
                        }
                      });
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: kTealGreen,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 13),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  onPressed: () async {
                    await FirebaseFirestore.instance
                        .collection('agencies')
                        .doc(agencyId)
                        .update({'tags': selected.toList()});
                    if (ctx.mounted) Navigator.pop(ctx);
                  },
                  child: const Text(
                    "Save Tag",
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showRulesSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Commission Rules",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: kTextDark,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              "10,000 Points = \$1.00 USD • Minimum Payout: \$10.00 USD",
              style: TextStyle(fontSize: 12.5, color: kTextMuted),
            ),

const SizedBox(height: 12),
            ..._tiers.map((t) {
              final minStr = _fmtNum(t['min'] as int, decimals: 0);
              final maxStr = _fmtNum(t['max'] as int, decimals: 0);
              final pct = ((t['rate'] as double) * 100).round();
              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: kOverviewTileBg,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "$minStr – $maxStr pts",
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        color: kTextDark,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: kTealGreen,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        "$pct%",
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  void _showSupportSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Customer Support",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: kTextDark,
              ),
            ),
            const SizedBox(height: 14),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const CircleAvatar(
                backgroundColor: Color(0xFF25D366),
                child: Icon(Icons.chat_rounded, color: Colors.white),
              ),
              title: const Text(
                "WhatsApp Support",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: const Text("+251900000000"),
              trailing: TextButton(
                onPressed: () {
                  Navigator.pop(ctx);
                  _copyText("+251900000000", "WhatsApp");
                },
                child: const Text(
                  "Copy",
                  style: TextStyle(
                    color: kTealGreen,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const CircleAvatar(
                backgroundColor: Color(0xFF2AABEE),
                child: Icon(Icons.send_rounded, color: Colors.white),
              ),
              title: const Text(
                "Telegram Support",
                style: TextStyle(fontWeight: FontWeight.bold),

),
              subtitle: const Text("@NILELive_Support"),
              trailing: TextButton(
                onPressed: () {
                  Navigator.pop(ctx);
                  _copyText("@NILELive_Support", "Telegram");
                },
                child: const Text(
                  "Copy",
                  style: TextStyle(
                    color: kCyanBlue,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showHostsSheet(
      String agencyId, String agencyName, List<QueryDocumentSnapshot> hosts) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (ctx) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.65,
        maxChildSize: 0.9,
        builder: (_, scrollCtrl) => Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Host Number (${hosts.length})",
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: kTextDark,
                    ),
                  ),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: kTealGreen,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                      ),
                    ),
                    onPressed: () {
                      Navigator.pop(ctx);
                      _showInviteHostSheet(agencyId, agencyName);
                    },
                    icon: const Icon(Icons.add, size: 16),
                    label: const Text("Invite Host"),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              const Text(
                "Toggle 'Allow Agency' to permit a host to create their own sub-agency.",
                style: TextStyle(fontSize: 12, color: kTextMuted),
              ),
              const SizedBox(height: 12),
              if (hosts.isEmpty)
                const Expanded(
                  child: Center(
                    child: Text(
                      "No hosts recruited yet.",
                      style: TextStyle(color: kTextMuted),
                    ),
                  ),
                )
              else
                Expanded(
                  child: ListView.separated(
                    controller: scrollCtrl,
                    itemCount: hosts.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (_, idx) {
                      final doc = hosts[idx];
                      final raw = doc.data();
                      final Map<String, dynamic> h =
                          raw is Map<String, dynamic> ? raw : {};
                      final name = (h['name'] ?? 'Host').toString();
                      final numericId = (h['numericId'] as num?)?.toInt() ?? 0;
                      int pts = (h['points'] as num?)?.toInt() ?? 0;
                      if (pts == 0) {
                        pts = (h['diamonds'] as num?)?.toInt() ?? 0;
                      }
                      final bool canCreate = h['allowCreateAgency'] == true;

return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Row(
                          children: [
                            CircleAvatar(
                              backgroundColor: kTealGreen.withOpacity(0.15),
                              child: Text(
                                name.isNotEmpty ? name[0].toUpperCase() : "H",
                                style: const TextStyle(
                                  color: kTealGreen,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    name,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                    ),
                                  ),
                                  Text(
                                    "ID: $numericId • $pts pts",
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: kTextMuted,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Column(
                              children: [
                                const Text(
                                  "Allow Agency",
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: kTextMuted,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                SizedBox(
                                  height: 28,
                                  child: Switch(
                                    value: canCreate,
                                    activeColor: kTealGreen,
                                    onChanged: (val) {
                                      Navigator.pop(ctx);
                                      _toggleHostCreateAgencyPermission(
                                        doc.id,
                                        name,
                                        val,
                                      );
                                    },
                                  ),
                                ),
                              ],
                            ),
                            IconButton(
                              icon: const Icon(
                                Icons.remove_circle_outline,
                                color: Colors.redAccent,
                                size: 20,
                              ),
                              onPressed: () {
                                Navigator.pop(ctx);
                                _removeHostFromAgency(agencyId, doc.id, name);
                              },
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  void _showSubAgenciesSheet(
      String parentAgencyId, List<QueryDocumentSnapshot> subAgencies) {

showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Sub-agency Number (${subAgencies.length})",
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: kTextDark,
                  ),
                ),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: kCyanBlue,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                  ),
                  onPressed: () {
                    Navigator.pop(ctx);
                    _showInviteAgencySheet(parentAgencyId);
                  },
                  icon: const Icon(Icons.add, size: 16),
                  label: const Text("Invite Agency"),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (subAgencies.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: Center(
                  child: Text(
                    "No sub-agencies linked yet.",
                    style: TextStyle(color: kTextMuted),
                  ),
                ),
              )
            else
              Flexible(
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: subAgencies.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (_, idx) {
                    final raw = subAgencies[idx].data();
                    final Map<String, dynamic> s =
                        raw is Map<String, dynamic> ? raw : {};
                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: CircleAvatar(
                        backgroundColor: kCyanBlue.withOpacity(0.15),
                        child: const Icon(Icons.apartment, color: kCyanBlue),
                      ),
                      title: Text(
                        (s['name'] ?? 'Sub-Agency').toString(),
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle:
                          Text("ID: ${s['agencyId'] ?? subAgencies[idx].id}"),
                      trailing: Text(
                        "${s['totalHosts'] ?? 0} Hosts",
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: kCyanBlue,
                        ),
                      ),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _showIncomeAndPayoutSheet({
    required String title,
    required String agencyId,
    required String agencyName,
    required int availableCommissionPoints,
    required double commissionUsd,
    required int ratePct,
  }) {
    final bool canWithdraw = commissionUsd >= 10.0;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(

borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) {
          String accountHint = "Enter Binance Pay ID";
          if (_selectedPayoutMethod == "Telebirr") {
            accountHint = "Enter Telebirr Phone (+251...)";
          } else if (_selectedPayoutMethod == "CBE Bank") {
            accountHint = "Enter CBE Account (1000...)";
          }

          return Padding(
            padding: EdgeInsets.only(
              left: 20,
              right: 20,
              top: 20,
              bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: kTextDark,
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [kMintCardStart, kMintCardEnd],
                    ),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Available Net Commission ($ratePct% Rate)",
                        style: const TextStyle(fontSize: 12, color: kTextMuted),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "\$${commissionUsd.toStringAsFixed(2)} USD",
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w900,
                          color: kTextDark,
                        ),
                      ),
                      Text(
                        "$availableCommissionPoints Points (10,000 Pts = \$1)",
                        style:
                            const TextStyle(fontSize: 11.5, color: kTextMuted),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                const Text(
                  "Withdraw Method:",
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.bold,
                    color: kTextDark,
                  ),
                ),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 6,
                  children: [
                    "Binance Pay (USDT)",
                    "Telebirr",
                    "CBE Bank",
                  ].map((method) {
                    final isSel = _selectedPayoutMethod == method;
                    return ChoiceChip(
                      label: Text(method),
                      selected: isSel,
                      selectedColor: kTealGreen,
                      labelStyle: TextStyle(
                        color: isSel ? Colors.white : kTextDark,
                        fontSize: 11.5,
                        fontWeight: FontWeight.bold,
                      ),
                      onSelected: (_) {
                        setSheetState(() => _selectedPayoutMethod = method);
                      },
                    );
                  }).toList(),
                ),
                const SizedBox(height: 10),

TextField(
                  controller: _payoutAccountController,
                  decoration: InputDecoration(
                    hintText: accountHint,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                SizedBox(
                  width: double.infinity,
                  height: 46,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor:
                          canWithdraw ? kTealGreen : Colors.black26,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(23),
                      ),
                    ),
                    onPressed: canWithdraw
                        ? () async {
                            final accountVal =
                                _payoutAccountController.text.trim();
                            if (accountVal.isEmpty) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text("Please enter account details"),
                                ),
                              );
                              return;
                            }

                            Navigator.pop(ctx);

                            final String currencyCode =
                                _selectedPayoutMethod == "Binance Pay (USDT)"
                                    ? "USDT"
                                    : "ETB";

                            final batch = FirebaseFirestore.instance.batch();
                            final requestRef = FirebaseFirestore.instance
                                .collection('withdraw_requests')
                                .doc();

                            batch.set(requestRef, {
                              'requestId': requestRef.id,
                              'userUid': _currentUser!.uid,
                              'uid': _currentUser!.uid,
                              'userNumericId': widget.userNumericId,
                              'userName': "$agencyName (Agency)",
                              'agencyId': agencyId,
                              'points': availableCommissionPoints,
                              'usdAmount': commissionUsd,
                              'method': _selectedPayoutMethod,
                              'currency': currencyCode,
                              'account': accountVal,
                              'accountDetails': accountVal,
                              'type': 'AGENCY_COMMISSION',
                              'status': 'PENDING',
                              'createdAt': FieldValue.serverTimestamp(),
                            });

                            final agencyRef = FirebaseFirestore.instance
                                .collection('agencies')
                                .doc(agencyId);
                            batch.update(agencyRef, {
                              'withdrawnCommissionPoints': FieldValue.increment(
                                  availableCommissionPoints),
                            });

                            await batch.commit();
                            _payoutAccountController.clear();

                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    "Agency payout request submitted for review!",

),
                                  backgroundColor: kTealGreen,
                                ),
                              );
                            }
                          }
                        : null,
                    child: Text(
                      canWithdraw
                          ? "Withdraw Agency Profit"
                          : "Min. \$10.00 USD to Withdraw",
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  // =========================================================================
  // MAIN BUILD: Decides between Entry Screen (Photo) & Full Dashboard (Video)
  // =========================================================================
  @override
  Widget build(BuildContext context) {
    final user = _currentUser;
    if (user == null) {
      return const Scaffold(
        backgroundColor: kBgColor,
        body: Center(
          child: Text("Please login first", style: TextStyle(color: kTextDark)),
        ),
      );
    }

    // Listen to current user's doc to check if joined under an agency & permission
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .snapshots(),
      builder: (context, userSnap) {
        final rawUser = userSnap.data?.data();
        final Map<String, dynamic> userData =
            rawUser is Map<String, dynamic> ? rawUser : {};
        final String joinedAgencyId =
            (userData['agencyId'] ?? '').toString().trim();
        final String joinedAgencyName =
            (userData['agencyName'] ?? '').toString().trim();
        final bool allowCreateAgency = userData['allowCreateAgency'] == true;

        // Check if this user already owns an agency
        return StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('agencies')
              .where('ownerUid', isEqualTo: user.uid)
              .limit(1)
              .snapshots(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const Scaffold(
                backgroundColor: kBgColor,
                body: Center(
                  child: CircularProgressIndicator(color: kTealGreen),
                ),
              );
            }

            // If user does NOT own an agency yet -> Show Photo Entry Screen
            if (snapshot.data!.docs.isEmpty) {
              return _buildAgentEntryScreen(
                joinedAgencyId: joinedAgencyId,
                joinedAgencyName: joinedAgencyName,
                allowCreateAgency: allowCreateAgency,
              );
            }

            // User IS an agent -> Show Full Agency Center Dashboard (Video)
            final agencyDoc = snapshot.data!.docs.first;
            final rawAgency = agencyDoc.data();
            final Map<String, dynamic> agencyData =
                rawAgency is Map<String, dynamic> ? rawAgency : {};
            final agencyId = agencyDoc.id;

            final String agencyName =
                (agencyData['name'] ?? "MY AGENCY").toString();
            final int withdrawnPoints =
                (agencyData['withdrawnCommissionPoints'] as num?)?.toInt() ?? 0;
            final int bonusCommissionPoints =
                (agencyData['bonusCommissionPoints'] as num?)?.toInt() ?? 0;
            final List<String> tags = agencyData['tags'] is List
                ? List<String>.from(agencyData['tags'])
                : ["VIP Voice"];

            return StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance

.collection('users')
                  .where('agencyId', isEqualTo: agencyId)
                  .snapshots(),
              builder: (context, hostsSnap) {
                final List<QueryDocumentSnapshot> hostsList =
                    hostsSnap.hasData ? hostsSnap.data!.docs : [];

                int totalHostPoints = 0;
                int todayHostPoints = 0;

                for (final doc in hostsList) {
                  final rawH = doc.data();
                  final Map<String, dynamic> hData =
                      rawH is Map<String, dynamic> ? rawH : {};
                  int pts = (hData['points'] as num?)?.toInt() ?? 0;
                  if (pts == 0) {
                    pts = (hData['diamonds'] as num?)?.toInt() ?? 0;
                  }
                  final int tPts =
                      (hData['todayTaskPoints'] as num?)?.toInt() ?? 0;
                  totalHostPoints += pts;
                  todayHostPoints += tPts;
                }

                return StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('agencies')
                      .where('parentAgencyId', isEqualTo: agencyId)
                      .snapshots(),
                  builder: (context, subSnap) {
                    final List<QueryDocumentSnapshot> subAgenciesList =
                        subSnap.hasData ? subSnap.data!.docs : [];

                    final tier = _getTierForPoints(totalHostPoints);
                    final int tierMin = tier['min'] as int;
                    final int tierMax = tier['max'] as int;
                    final double rate = tier['rate'] as double;
                    final int currentPct = (rate * 100).round();
                    final int nextPct =
                        ((tier['nextRate'] as double) * 100).round();

                    final int remainingPoints =
                        max(0, tierMax - totalHostPoints);
                    final double progress = ((totalHostPoints - tierMin) /
                            max(1, tierMax - tierMin))
                        .clamp(0.0, 1.0);

                    final double myIncomeToday = todayHostPoints * rate;
                    final int grossCommissionPoints =
                        (totalHostPoints * rate).round() +
                            bonusCommissionPoints;
                    final int availableCommissionPoints =
                        max(0, grossCommissionPoints - withdrawnPoints);
                    final double commissionUsd =
                        availableCommissionPoints / _pointsPerUsd;

                    return Scaffold(
                      backgroundColor: kBgColor,
                      appBar: AppBar(
                        backgroundColor: kBgColor,
                        elevation: 0,
                        centerTitle: true,
                        leading: IconButton(
                          icon: const Icon(
                            Icons.arrow_back_ios_new,
                            color: kTextDark,
                            size: 20,
                          ),
                          onPressed: () => Navigator.pop(context),
                        ),
                        title: const Text(
                          "Agency Center",
                          style: TextStyle(
                            color: kTextDark,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        actions: [
                          IconButton(
                            icon: const Icon(
                              Icons.help_outline_rounded,
                              color: kTextDark,

size: 23,
                            ),
                            onPressed: _showRulesSheet,
                          ),
                        ],
                      ),
                      body: SingleChildScrollView(
                        physics: const BouncingScrollPhysics(),
                        padding: const EdgeInsets.fromLTRB(16, 6, 16, 28),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // 1. Agency Header Row
                            Row(
                              children: [
                                Container(
                                  width: 60,
                                  height: 60,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    gradient: const LinearGradient(
                                      colors: [
                                        Color(0xFF2D2216),
                                        Color(0xFF120D08),
                                      ],
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    ),
                                    border: Border.all(
                                      color: const Color(0xFFFFD700),
                                      width: 2,
                                    ),
                                  ),
                                  child: const Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.emoji_events,
                                        color: Color(0xFFFFD700),
                                        size: 22,
                                      ),
                                      Text(
                                        "KING",
                                        style: TextStyle(
                                          color: Color(0xFFFFD700),
                                          fontSize: 8.5,
                                          fontWeight: FontWeight.w900,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        agencyName,
                                        style: const TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.w800,
                                          color: kTextDark,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 4),
                                      GestureDetector(
                                        onTap: () =>
                                            _copyText(agencyId, "Agency ID"),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,

children: [
                                            Text(
                                              "ID:$agencyId",
                                              style: const TextStyle(
                                                fontSize: 13,
                                                color: kTextMuted,
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                            const SizedBox(width: 6),
                                            const Icon(
                                              Icons.copy_rounded,
                                              size: 15,
                                              color: kTextMuted,
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(
                                    Icons.edit_outlined,
                                    color: kTextMuted,
                                    size: 22,
                                  ),
                                  onPressed: () =>
                                      _showEditNameDialog(agencyId, agencyName),
                                ),
                              ],
                            ),

                            const SizedBox(height: 16),

                            // 2. Invite Host & Invite Agency Pill Buttons
                            Row(
                              children: [
                                Expanded(
                                  child: SizedBox(
                                    height: 46,
                                    child: ElevatedButton(
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: kTealGreen,
                                        foregroundColor: Colors.white,
                                        elevation: 0,
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(23),
                                        ),
                                      ),
                                      onPressed: () => _showInviteHostSheet(
                                          agencyId, agencyName),
                                      child: const Text(
                                        "Invite Host",
                                        style: TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: SizedBox(
                                    height: 46,
                                    child: ElevatedButton(
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: kCyanBlue,
                                        foregroundColor: Colors.white,
                                        elevation: 0,
                                        shape: RoundedRectangleBorder(

borderRadius:
                                              BorderRadius.circular(23),
                                        ),
                                      ),
                                      onPressed: () =>
                                          _showInviteAgencySheet(agencyId),
                                      child: const Text(
                                        "Invite Agency",
                                        style: TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(height: 14),

                            // 3. Agency Tag Card
                            GestureDetector(
                              onTap: () => _showAgencyTagSheet(agencyId, tags),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 14,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                child: Row(
                                  children: [
                                    const Text(
                                      "Agency Tag",
                                      style: TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w600,
                                        color: kTextDark,
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Wrap(
                                        spacing: 6,
                                        children: tags
                                            .take(2)
                                            .map(
                                              (t) => Container(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                  horizontal: 8,
                                                  vertical: 2,
                                                ),
                                                decoration: BoxDecoration(
                                                  color: kOverviewTileBg,
                                                  borderRadius:
                                                      BorderRadius.circular(8),
                                                ),
                                                child: Text(
                                                  t,
                                                  style: const TextStyle(
                                                    fontSize: 11,
                                                    color: kTealGreen,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                              ),
                                            )

.toList(),
                                      ),
                                    ),
                                    const Icon(
                                      Icons.chevron_right_rounded,
                                      color: kTextMuted,
                                    ),
                                  ],
                                ),
                              ),
                            ),

                            const SizedBox(height: 14),

                            // 4. Income & Next-Level Progress Card (Starts at 0)
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [kMintCardStart, kMintCardEnd],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Column(
                                children: [
                                  Row(
                                    children: [
                                      const Text(
                                        "My Income Today:",
                                        style: TextStyle(
                                          fontSize: 14.5,
                                          color: kTextDark,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      _coinBadge(),
                                      const SizedBox(width: 6),
                                      Text(
                                        _fmtNum(myIncomeToday, decimals: 1),
                                        style: const TextStyle(
                                          fontSize: 17,
                                          fontWeight: FontWeight.w800,
                                          color: kTextDark,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.center,
                                    children: [
                                      const Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            "Total Host Points:",
                                            style: TextStyle(
                                              fontSize: 14.5,
                                              color: kTextDark,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                          Text(
                                            "Past 30 Days",
                                            style: TextStyle(
                                              fontSize: 11,
                                              color: kTextMuted,
                                            ),

),
                                        ],
                                      ),
                                      const SizedBox(width: 8),
                                      _coinBadge(),
                                      const SizedBox(width: 6),
                                      Text(
                                        _fmtNum(totalHostPoints, decimals: 1),
                                        style: const TextStyle(
                                          fontSize: 17,
                                          fontWeight: FontWeight.w800,
                                          color: kTextDark,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  Row(
                                    children: [
                                      const Text(
                                        "Commission Rate",
                                        style: TextStyle(
                                          fontSize: 14.5,
                                          color: kTextDark,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      _coinBadge(),
                                      const SizedBox(width: 6),
                                      Text(
                                        "$currentPct%",
                                        style: const TextStyle(
                                          fontSize: 17,
                                          fontWeight: FontWeight.w800,
                                          color: kTextDark,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 14),
                                  Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Wrap(
                                          crossAxisAlignment:
                                              WrapCrossAlignment.center,
                                          spacing: 4,
                                          children: [
                                            const Text(
                                              "Still need",
                                              style: TextStyle(
                                                fontSize: 12.5,
                                                color: kTextDark,
                                              ),
                                            ),
                                            _coinBadge(),
                                            Text(
                                              _fmtNum(remainingPoints,
                                                  decimals: 1),
                                              style: const TextStyle(
                                                fontSize: 13,

fontWeight: FontWeight.bold,
                                                color: kTextDark,
                                              ),
                                            ),
                                            const Text(
                                              "to reach next level",
                                              style: TextStyle(
                                                fontSize: 12.5,
                                                color: kTextDark,
                                              ),
                                            ),
                                            Text(
                                              "$nextPct%",
                                              style: const TextStyle(
                                                fontSize: 13.5,
                                                fontWeight: FontWeight.w800,
                                                color: kCoralRed,
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 10),
                                        ClipRRect(
                                          borderRadius:
                                              BorderRadius.circular(6),
                                          child: LinearProgressIndicator(
                                            value: progress,
                                            minHeight: 7,
                                            backgroundColor:
                                                const Color(0xFFE6ECEF),
                                            valueColor:
                                                const AlwaysStoppedAnimation<
                                                    Color>(
                                              kTealGreen,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: [
                                            Row(
                                              children: [
                                                _coinBadge(),
                                                const SizedBox(width: 4),
                                                Text(
                                                  _fmtNum(tierMin, decimals: 0),
                                                  style: const TextStyle(
                                                    fontSize: 11.5,
                                                    color: kTextDark,
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                                ),
                                              ],
                                            ),
                                            Row(
                                              children: [
                                                _coinBadge(),
                                                const SizedBox(width: 4),
                                                Text(
                                                  _fmtNum(tierMax, decimals: 0),
                                                  style: const TextStyle(

fontSize: 11.5,
                                                    color: kTextDark,
                                                    fontWeight: FontWeight.w600,
                                                  ),
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

                            const SizedBox(height: 14),

                            // 5. Overview 2x3 Grid Card (Starts at 0)
                            Container(
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    "Overview",
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: kTextDark,
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: _overviewMetricBox(
                                          title: "Host Points",
                                          subtitle: "Today",
                                          value: _fmtNum(todayHostPoints),
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: _overviewMetricBox(
                                          title: "My Hosts Points",
                                          subtitle: "Past 30 Days",
                                          value: _fmtNum(totalHostPoints),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 10),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: _overviewMetricBox(
                                          title: "Sub-agent Host Points",
                                          subtitle: "Today",
                                          value: "0.0",
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: _overviewMetricBox(
                                          title: "Sub-agent Host Points",
                                          subtitle: "Past 30 Days",
                                          value: "0.0",
                                        ),

),
                                    ],
                                  ),
                                  const SizedBox(height: 10),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: _overviewCountBox(
                                          title: "Host Number",
                                          count: "${hostsList.length}",
                                          onTap: () => _showHostsSheet(
                                            agencyId,
                                            agencyName,
                                            hostsList,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: _overviewCountBox(
                                          title: "Sub-agency Number",
                                          count: "${subAgenciesList.length}",
                                          onTap: () => _showSubAgenciesSheet(
                                            agencyId,
                                            subAgenciesList,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),

                            const SizedBox(height: 14),

                            // 6. Income & Payout Navigation Card
                            Container(
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Column(
                                children: [
                                  _incomeNavRow(
                                    icon: Icons.mic_none_rounded,
                                    title: "Host Income",
                                    onTap: () => _showIncomeAndPayoutSheet(
                                      title: "Host Income & Profit Payout",
                                      agencyId: agencyId,
                                      agencyName: agencyName,
                                      availableCommissionPoints:
                                          availableCommissionPoints,
                                      commissionUsd: commissionUsd,
                                      ratePct: currentPct,
                                    ),
                                  ),
                                  const Divider(
                                    height: 1,
                                    indent: 50,
                                    color: Color(0xFFF0F2F5),
                                  ),
                                  _incomeNavRow(
                                    icon: Icons.verified_user_outlined,
                                    title: "Sub-agency Income",
                                    onTap: () => _showIncomeAndPayoutSheet(
                                      title: "Sub-agency Income",
                                      agencyId: agencyId,
                                      agencyName: agencyName,
                                      availableCommissionPoints:
                                          availableCommissionPoints,
                                      commissionUsd: commissionUsd,

ratePct: currentPct,
                                    ),
                                  ),
                                  const Divider(
                                    height: 1,
                                    indent: 50,
                                    color: Color(0xFFF0F2F5),
                                  ),
                                  _incomeNavRow(
                                    icon: Icons.pending_outlined,
                                    title: "Other income",
                                    onTap: () => _showIncomeAndPayoutSheet(
                                      title: "Other Income",
                                      agencyId: agencyId,
                                      agencyName: agencyName,
                                      availableCommissionPoints:
                                          availableCommissionPoints,
                                      commissionUsd: commissionUsd,
                                      ratePct: currentPct,
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            const SizedBox(height: 14),

                            // 7. Contact Admin Card
                            Container(
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    "Contact Admin",
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: kTextDark,
                                    ),
                                  ),
                                  const SizedBox(height: 14),
                                  Row(
                                    children: [
                                      Container(
                                        width: 40,
                                        height: 40,
                                        decoration: const BoxDecoration(
                                          color: Color(0xFF25D366),
                                          shape: BoxShape.circle,
                                        ),
                                        child: const Icon(
                                          Icons.chat_rounded,
                                          color: Colors.white,
                                          size: 22,
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      const Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              "WhatsApp",
                                              style: TextStyle(
                                                fontSize: 14.5,
                                                fontWeight: FontWeight.w600,
                                                color: kTextDark,

),
                                            ),
                                            SizedBox(height: 2),
                                            Text(
                                              "+251900000000",
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: kTextMuted,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      _contactPillButton(
                                        onTap: () => _copyText(
                                          "+251900000000",
                                          "Admin WhatsApp",
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 14),
                                  Row(
                                    children: [
                                      Container(
                                        width: 40,
                                        height: 40,
                                        decoration: const BoxDecoration(
                                          color: Color(0xFF2AABEE),
                                          shape: BoxShape.circle,
                                        ),
                                        child: const Icon(
                                          Icons.send_rounded,
                                          color: Colors.white,
                                          size: 20,
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      const Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              "Telegram",
                                              style: TextStyle(
                                                fontSize: 14.5,
                                                fontWeight: FontWeight.w600,
                                                color: kTextDark,
                                              ),
                                            ),
                                            SizedBox(height: 2),
                                            Text(
                                              "@NILELive_Support",
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: kTextMuted,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      _contactPillButton(
                                        onTap: () => _copyText(
                                          "@NILELive_Support",
                                          "Admin Telegram",
                                        ),
                                      ),
                                    ],
                                  ),

],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            );
          },
        );
      },
    );
  }

  // =========================================================================
  // AGENT CENTER ENTRY SCREEN (Matches Photo: My Agent + I am an agent + Support)
  // =========================================================================
  Widget _buildAgentEntryScreen({
    required String joinedAgencyId,
    required String joinedAgencyName,
    required bool allowCreateAgency,
  }) {
    final bool hasJoinedAgency = joinedAgencyId.isNotEmpty;

    return Scaffold(
      backgroundColor: kBgColor,
      appBar: AppBar(
        backgroundColor: kBgColor,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new,
            color: kTextDark,
            size: 20,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "Agent Center",
          style: TextStyle(
            color: kTextDark,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 24),
        child: Column(
          children: [
            // 1. "My Agent" Card (Purple-Magenta Header + Join / Dynamic Joined Info)
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 18,
                      vertical: 14,
                    ),
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [kPurpleBannerStart, kPurpleBannerEnd],
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                      ),
                      borderRadius: BorderRadius.vertical(
                        top: Radius.circular(18),
                      ),
                    ),
                    child: const Text(
                      "My Agent",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16.5,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 18,
                    ),
                    child: hasJoinedAgency
                        ? Row(
                            children: [
                              Container(
                                width: 52,
                                height: 52,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  gradient: const LinearGradient(
                                    colors: [
                                      Color(0xFF2D2216),
                                      Color(0xFF120D08),

],
                                  ),
                                  border: Border.all(
                                    color: const Color(0xFFFFD700),
                                    width: 1.8,
                                  ),
                                ),
                                child: const Icon(
                                  Icons.emoji_events,
                                  color: Color(0xFFFFD700),
                                  size: 26,
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      joinedAgencyName.isNotEmpty
                                          ? joinedAgencyName
                                          : "Agency",
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w800,
                                        color: kTextDark,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      "ID:$joinedAgencyId",
                                      style: const TextStyle(
                                        fontSize: 13,
                                        color: kTextMuted,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const Text(
                                "Joined",
                                style: TextStyle(
                                  color: Color(0xFF2B6CB0),
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          )
                        : Row(
                            children: [
                              Container(
                                width: 50,
                                height: 50,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: kOverviewTileBg,
                                  border: Border.all(
                                    color: kTealGreen.withOpacity(0.35),
                                  ),
                                ),
                                child: const Icon(
                                  Icons.groups_rounded,
                                  color: kTealGreen,
                                  size: 26,
                                ),
                              ),
                              const SizedBox(width: 14),
                              const Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      "Join an Agency",
                                      style: TextStyle(
                                        fontSize: 15.5,
                                        fontWeight: FontWeight.bold,

color: kTextDark,
                                      ),
                                    ),
                                    SizedBox(height: 3),
                                    Text(
                                      "Enter Agency ID to become a host",
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: kTextMuted,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: kTealGreen,
                                  foregroundColor: Colors.white,
                                  elevation: 0,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 20,
                                    vertical: 10,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                ),
                                onPressed: _showJoinAgencyDialog,
                                child: const Text(
                                  "Join",
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                            ],
                          ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // 2. "I am an agent / Create An Agency" Golden-Orange Banner Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [kOrangeCardStart, kOrangeCardEnd],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(18),
                boxShadow: [
                  BoxShadow(
                    color: kOrangeCardEnd.withOpacity(0.28),
                    blurRadius: 12,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    flex: 6,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "I am an agent",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 19,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: kOrangeCardEnd,
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 12,
                            ),

shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          onPressed: () => _handleCreateAgencyTap(
                            joinedAgencyId: joinedAgencyId,
                            joinedAgencyName: joinedAgencyName,
                            allowCreateAgency: allowCreateAgency,
                          ),
                          child: const Text(
                            "Create An Agency",
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    flex: 4,
                    child: Container(
                      height: 110,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.16),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.monetization_on_rounded,
                            color: Color(0xFFFFF59D),
                            size: 46,
                          ),
                          SizedBox(height: 6),
                          Icon(
                            Icons.thumb_up_alt_rounded,
                            color: Colors.white,
                            size: 28,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // 3. "Customer Support" Bottom Card
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.03),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: kOverviewTileBg,
                      border: Border.all(color: kTealGreen.withOpacity(0.3)),
                    ),
                    child: const Icon(
                      Icons.support_agent_rounded,
                      color: kTealGreen,
                      size: 26,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      "Customer Support",
                      style: TextStyle(
                        fontSize: 15.5,
                        fontWeight: FontWeight.bold,
                        color: kTextDark,
                      ),
                    ),
                  ),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1BC5BD),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(

horizontal: 20,
                        vertical: 10,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    onPressed: _showSupportSheet,
                    child: const Text(
                      "Contact",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
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

  Widget _overviewMetricBox({
    required String title,
    required String subtitle,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: kOverviewTileBg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 12.5,
              color: kTextDark,
              fontWeight: FontWeight.w500,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: const TextStyle(fontSize: 10.5, color: kTextMuted),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              _coinBadge(),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  value,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: kTextDark,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _overviewCountBox({
    required String title,
    required String count,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: kOverviewTileBg,
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
                      fontSize: 12.5,
                      color: kTextDark,
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const Icon(
                  Icons.chevron_right_rounded,
                  size: 18,
                  color: kTextMuted,
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              count,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: kTextDark,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _incomeNavRow({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return ListTile(
      onTap: onTap,
      leading: Icon(icon, color: kTextDark, size: 22),
      title: Text(
        title,
        style: const TextStyle(
          fontSize: 14.5,
          fontWeight: FontWeight.w600,
          color: kTextDark,
        ),
      ),
      trailing: const Icon(Icons.chevron_right_rounded, color: kTextMuted),
    );
  }

Widget _contactPillButton({required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
        decoration: BoxDecoration(
          color: const Color(0xFFE3F8F1),
          borderRadius: BorderRadius.circular(20),
        ),
        child: const Text(
          "Contact",
          style: TextStyle(
            color: Color(0xFF00A86B),
            fontWeight: FontWeight.bold,
            fontSize: 13,
          ),
        ),
      ),
    );
  }
}
