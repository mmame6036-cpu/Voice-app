import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

bool _gt(num a, num b) {
  return a.compareTo(b).sign == 1;
}

bool _lt(num a, num b) {
  return a.compareTo(b).sign == -1;
}

bool _gte(num a, num b) {
  return a.compareTo(b).sign != -1;
}

dynamic _d(Object? v) {
  return v;
}

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
  final TextEditingController _agencyPhoneController = TextEditingController();
  final TextEditingController _joinAgencyIdController = TextEditingController();
  final TextEditingController _hostIdController = TextEditingController();
  final TextEditingController _payoutAccountController = TextEditingController();

  bool _isLoading = false;
  bool _isCreatingAgency = false;
  bool _isMigratingId = false;
  String _selectedCountry = "Ethiopia 🇪🇹";
  String _selectedPayoutMethod = "Binance Pay (USDT)";

  static const int _pointsPerUsd = 10000;
  static const String _inviteBaseUrl = "https://nilevoiceapp.web.app/join";
  static const String kAdminWhatsapp = "+251993105987";
  static const String kAdminTelegram = "@kediroumer";

  static const List<String> _countries = [
    "Ethiopia 🇪🇹",
    "Saudi Arabia 🇸🇦",
    "UAE 🇦🇪",
    "Kuwait 🇰🇼",
    "Qatar 🇶🇦",
    "Bahrain 🇧🇭",
    "Oman 🇴🇲",
    "USA 🇺🇸",
    "UK 🇬🇧",
    "Other 🌍",
  ];

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

  final List> _tiers = const [
    {'min': 0, 'max': 2000000, 'rate': 0.04, 'nextRate': 0.08},
    {'min': 2000000, 'max': 5000000, 'rate': 0.08, 'nextRate': 0.12},
    {'min': 5000000, 'max': 15000000, 'rate': 0.12, 'nextRate': 0.15},
    {'min': 15000000, 'max': 50000000, 'rate': 0.15, 'nextRate': 0.20},
    {'min': 50000000, 'max': 100000000, 'rate': 0.20, 'nextRate': 0.25},
  ];

  @override
  void dispose() {
    _agencyNameController.dispose();
    _agencyPhoneController.dispose();
    _joinAgencyIdController.dispose();
    _hostIdController.dispose();
    _payoutAccountController.dispose();
    super.dispose();
  }

  String _buildHostInviteLink(String agencyId) {
    return "$_inviteBaseUrl?hostRef=$agencyId";
  }

  String _buildAgentInviteLink(String agencyId) {
    return "$_inviteBaseUrl?agentRef=$agencyId";
  }

  Map<String, dynamic> _parseInviteInput(String rawInput) {
    final String text = rawInput.trim();
    String extractedId = "";
    bool isSubAgentInvite = false;

    if (text.contains("agentRef=")) {
      isSubAgentInvite = true;
      final parts = text.split("agentRef=");
      if (_gt(parts.length, 1)) {
        final match = RegExp(r'\d+').firstMatch(parts[1]);

if (match != null) {
          extractedId = match.group(0) ?? "";
        }
      }
    } else if (text.contains("hostRef=")) {
      isSubAgentInvite = false;
      final parts = text.split("hostRef=");
      if (_gt(parts.length, 1)) {
        final match = RegExp(r'\d+').firstMatch(parts[1]);
        if (match != null) {
          extractedId = match.group(0) ?? "";
        }
      }
    } else {
      final match = RegExp(r'\d+').firstMatch(text);
      if (match != null) {
        extractedId = match.group(0) ?? "";
      }
    }

    return {
      'agencyId': extractedId,
      'isSubAgent': isSubAgentInvite,
    };
  }

  String _fmtNum(num val, {int decimals = 1}) {
    final double d = val.toDouble();
    bool isWhole = false;
    if (d == d.roundToDouble()) {
      if (decimals == 0) {
        isWhole = true;
      }
    }
    final String fixed =
        isWhole ? d.toInt().toString() : d.toStringAsFixed(decimals);
    final parts = fixed.split('.');
    final reg = RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))');
    final formattedInt = parts[0].replaceAllMapped(reg, (m) {
      return '${m[1]},';
    });
    if (_gt(parts.length, 1)) {
      if (_gt(decimals, 0)) {
        if (parts[1] == '0') return formattedInt;
        return '$formattedInt.${parts[1]}';
      }
    }
    return formattedInt;
  }

  Map<String, dynamic> _getTierForPoints(int points) {
    for (final t in _tiers) {
      if (_lt(points, (t['max'] as num).toInt())) {
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

  ImageProvider? _resolveAvatarProvider(String url) {
    if (url.isEmpty) return null;
    if (url.startsWith('data:image')) {
      try {
        final int commaIdx = url.indexOf(',');
        if (commaIdx != -1) {
          final Uint8List bytes = base64Decode(url.substring(commaIdx + 1));
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

  void _showJoinAgencyDialog({required int myNumericId}) {
    _joinAgencyIdController.clear();
    bool isJoining = false;

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20)),
              title: const Text(
                "Join via Link or Agency ID",
                style:
                    TextStyle(fontWeight: FontWeight.bold, color: kTextDark),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Paste the Host/Agent Invite Link or enter the Agency ID:",
                    style: TextStyle(fontSize: 13, color: kTextMuted),

),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _joinAgencyIdController,
                    decoration: InputDecoration(
                      hintText: "Paste invite link or ID (e.g. 100083)",
                      hintStyle: const TextStyle(fontSize: 12),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(ctx);
                  },
                  child:
                      const Text("Cancel", style: TextStyle(color: kTextMuted)),
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
                          final parsed = _parseInviteInput(
                              _joinAgencyIdController.text);
                          final String enteredAgencyId =
                              (parsed['agencyId'] ?? '').toString();
                          final bool isSubAgentLink =
                              parsed['isSubAgent'] == true;

                          if (enteredAgencyId.isEmpty) return;
                          if (_currentUser == null) return;

                          setDialogState(() {
                            isJoining = true;
                          });
                          try {
                            final agencyDoc = await FirebaseFirestore.instance
                                .collection('agencies')
                                .doc(enteredAgencyId)
                                .get();

                            if (!agencyDoc.exists) {
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                        "Invalid Invite Link or Agency ID!"),
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
                                    content: Text(
                                        "You cannot join your own agency."),
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
                                'agencyId': _d(enteredAgencyId),
                                'agencyName': _d(agencyName),
                                'isHost': _d(true),
                                'allowCreateAgency': _d(isSubAgentLink),
                                'joinedAgencyAt':
                                    _d(FieldValue.serverTimestamp()),
                              },
                              SetOptions(merge: true),
                            );

                            batch.set(
                              hostRef,
                              {
                                'agencyId': _d(enteredAgencyId),
                                'agencyName': _d(agencyName),
                                'status': _d('active'),
                                'updatedAt': _d(FieldValue.serverTimestamp()),
                              },
                              SetOptions(merge: true),
                            );

                            batch.update(agencyDoc.reference, {
                              'totalHosts': _d(FieldValue.increment(1)),
                            });

                            await batch.commit();

                            if (ctx.mounted) Navigator.pop(ctx);
                            if (mounted) {
                              if (isSubAgentLink) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                        "Joined under $agencyName! Complete your Sub-Agency form for their approval."),
                                    backgroundColor: kCyanBlue,
                                  ),
                                );
                                _openCreateAgencyForm(
                                  myNumericId: myNumericId,
                                  joinedAgencyId: enteredAgencyId,
                                  joinedAgencyName: agencyName,
                                );
                              } else {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                        "Successfully joined $agencyName as Host!"),
                                    backgroundColor: kTealGreen,
                                  ),
                                );
                              }
                            }
                          } catch (e) {
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text("Failed to join: $e")),
                              );
                            }
                          } finally {
                            if (ctx.mounted) {
                              setDialogState(() {
                                isJoining = false;
                              });
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
                          "Confirm Join",
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                ),
              ],
            );
          },
        );
      },
    );
  }

void _openCreateAgencyForm({
    required int myNumericId,
    required String joinedAgencyId,
    required String joinedAgencyName,
  }) {
    final bool isUnderParentAgent = joinedAgencyId.isNotEmpty;
    _agencyNameController.clear();
    _agencyPhoneController.clear();
    _selectedCountry = "Ethiopia 🇪🇹";

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setSheetState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 20,
                bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 44,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.black12,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: kOrangeCardStart.withOpacity(0.15),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.business_center_rounded,
                              color: kOrangeCardEnd),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            isUnderParentAgent
                                ? "Sub-Agency Application"
                                : "Create An Agency",
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w900,
                              color: kTextDark,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: kOverviewTileBg,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        isUnderParentAgent
                            ? "You are registered under \"$joinedAgencyName\" (ID: $joinedAgencyId). Your request will be sent to your agent for Agree / Reject approval."
                            : "Your Agency ID will match your Personal ID ($myNumericId). After submitting, Admin approval from the Dashboard will activate your Agency Center.",
                        style: const TextStyle(
                            fontSize: 12, color: kTextDark, height: 1.35),
                      ),
                    ),
                    const SizedBox(height: 14),
                    const Text(
                      "Agency Name *",
                      style: TextStyle(
                        fontSize: 13,

fontWeight: FontWeight.bold,
                        color: kTextDark,
                      ),
                    ),
                    const SizedBox(height: 6),
                    TextField(
                      controller: _agencyNameController,
                      decoration: InputDecoration(
                        hintText: "Enter full agency name (e.g. NILE FAMS)",
                        filled: true,
                        fillColor: kBgColor,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      "Phone Number (WhatsApp / Telegram) *",
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: kTextDark,
                      ),
                    ),
                    const SizedBox(height: 6),
                    TextField(
                      controller: _agencyPhoneController,
                      keyboardType: TextInputType.phone,
                      decoration: InputDecoration(
                        hintText: "e.g. +251911223344",
                        filled: true,
                        fillColor: kBgColor,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      "Country *",
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: kTextDark,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      decoration: BoxDecoration(
                        color: kBgColor,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: _selectedCountry,
                          isExpanded: true,
                          items: _countries.map((c) {
                            return DropdownMenuItem<String>(
                              value: c,
                              child: Text(
                                c,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  color: kTextDark,
                                ),
                              ),
                            );
                          }).toList(),
                          onChanged: (val) {
                            if (val != null) {
                              setSheetState(() {
                                _selectedCountry = val;
                              });
                            }
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: kTealGreen,

foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        onPressed: _isCreatingAgency
                            ? null
                            : () async {
                                final name = _agencyNameController.text.trim();
                                final phone =
                                    _agencyPhoneController.text.trim();

                                if (name.isEmpty) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                        content:
                                            Text("Please enter Agency Name")),
                                  );
                                  return;
                                }
                                if (phone.isEmpty) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                        content:
                                            Text("Please enter Phone Number")),
                                  );
                                  return;
                                }
                                if (_currentUser == null) return;

                                setSheetState(() {
                                  _isCreatingAgency = true;
                                });
                                setState(() {
                                  _isCreatingAgency = true;
                                });

                                try {
                                  int resolvedNumId = myNumericId;
                                  String applicantName = "User";
                                  final uDoc = await FirebaseFirestore.instance
                                      .collection('users')
                                      .doc(_currentUser!.uid)
                                      .get();
                                  if (uDoc.exists) {
                                    final uData = uDoc.data() ?? {};
                                    if (resolvedNumId == 0) {
                                      resolvedNumId =
                                          (uData['numericId'] as num?)
                                                  ?.toInt() ??
                                              0;
                                    }
                                    applicantName = (uData['name'] ??
                                            uData['nickname'] ??
                                            'User')
                                        .toString();
                                  }

                                  final String newAgencyId = resolvedNumId != 0
                                      ? resolvedNumId.toString()
                                      : _currentUser!.uid
                                          .substring(0, 6)
                                          .toUpperCase();

                                  final String initialStatus =
                                      isUnderParentAgent
                                          ? 'PENDING_PARENT'
                                          : 'PENDING';

                                  final batch =
                                      FirebaseFirestore.instance.batch();

                                  final agencyRef = FirebaseFirestore.instance
                                      .collection('agencies')
                                      .doc(newAgencyId);

batch.set(
                                    agencyRef,
                                    {
                                      'agencyId': _d(newAgencyId),
                                      'ownerUid': _d(_currentUser!.uid),
                                      'ownerNumericId': _d(resolvedNumId),
                                      'ownerName': _d(applicantName),
                                      'parentAgencyId': _d(joinedAgencyId),
                                      'parentAgencyName': _d(joinedAgencyName),
                                      'name': _d(name),
                                      'phone': _d(phone),
                                      'country': _d(_selectedCountry),
                                      'status': _d(initialStatus),
                                      'approvalType': _d(isUnderParentAgent
                                          ? 'PARENT_AGENT'
                                          : 'SUPER_ADMIN'),
                                      'commissionRate': _d(0.04),
                                      'totalHosts': _d(0),
                                      'tags': _d(['VIP Voice']),
                                      'withdrawnCommissionPoints': _d(0),
                                      'bonusCommissionPoints': _d(0),
                                      'createdAt':
                                          _d(FieldValue.serverTimestamp()),
                                    },
                                    SetOptions(merge: true),
                                  );

                                  if (!isUnderParentAgent) {
                                    final reqRef = FirebaseFirestore.instance
                                        .collection('agency_requests')
                                        .doc(newAgencyId);
                                    batch.set(
                                      reqRef,
                                      {
                                        'requestId': _d(newAgencyId),
                                        'agencyId': _d(newAgencyId),
                                        'ownerUid': _d(_currentUser!.uid),
                                        'ownerNumericId': _d(resolvedNumId),
                                        'ownerName': _d(applicantName),
                                        'agencyName': _d(name),
                                        'phone': _d(phone),
                                        'country': _d(_selectedCountry),
                                        'status': _d('PENDING'),
                                        'createdAt':
                                            _d(FieldValue.serverTimestamp()),
                                      },
                                      SetOptions(merge: true),
                                    );
                                  }

                                  await batch.commit();

                                  if (ctx.mounted) Navigator.pop(ctx);
                                  if (mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          isUnderParentAgent
                                              ? "Request sent to $joinedAgencyName! Waiting for Agree / Reject."
                                              : "Application submitted! Waiting for Admin Dashboard approval.",
                                        ),
                                        backgroundColor: kTealGreen,
                                      ),
                                    );
                                  }

} catch (e) {
                                  if (mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                          content: Text(
                                              "Failed to submit application: $e")),
                                    );
                                  }
                                } finally {
                                  if (ctx.mounted) {
                                    setSheetState(() {
                                      _isCreatingAgency = false;
                                    });
                                  }
                                  if (mounted) {
                                    setState(() {
                                      _isCreatingAgency = false;
                                    });
                                  }
                                }
                              },
                        child: _isCreatingAgency
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : Text(
                                isUnderParentAgent
                                    ? "Send Request to My Agent"
                                    : "Submit Agency Application",
                                style: const TextStyle(
                                    fontSize: 15, fontWeight: FontWeight.bold),
                              ),
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
  }

  Future<void> _respondToSubAgencyRequest({
    required String subAgencyId,
    required String subOwnerUid,
    required String subAgencyName,
    required bool agree,
  }) async {
    try {
      final batch = FirebaseFirestore.instance.batch();
      final subAgencyRef =
          FirebaseFirestore.instance.collection('agencies').doc(subAgencyId);
      final subUserRef =
          FirebaseFirestore.instance.collection('users').doc(subOwnerUid);

      if (agree) {
        batch.update(subAgencyRef, {
          'status': _d('APPROVED'),
          'approvedAt': _d(FieldValue.serverTimestamp()),
        });
        batch.set(
          subUserRef,
          {
            'isAgent': _d(true),
            'role': _d('agent'),
            'allowCreateAgency': _d(true),
          },
          SetOptions(merge: true),
        );
      } else {
        batch.update(subAgencyRef, {
          'status': _d('REJECTED'),
          'rejectedAt': _d(FieldValue.serverTimestamp()),
        });
        batch.set(
          subUserRef,
          {
            'allowCreateAgency': _d(false),
          },
          SetOptions(merge: true),
        );
      }

      await batch.commit();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              agree
                  ? "Agreed! $subAgencyName is now an active Sub-Agency."
                  : "Rejected sub-agency request from $subAgencyName.",
            ),
            backgroundColor: agree ? kTealGreen : kCoralRed,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error updating request: $e")),
        );
      }
    }
  }

  Future<void> _addHostToAgency(

BuildContext sheetCtx, String agencyId, String agencyName) async {
    final enteredId = int.tryParse(_hostIdController.text.trim());
    if (enteredId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please enter a valid Numeric User ID")),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });
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
        'agencyId': _d(agencyId),
        'agencyName': _d(agencyName),
        'isHost': _d(true),
        'allowCreateAgency': _d(false),
        'joinedAgencyAt': _d(FieldValue.serverTimestamp()),
      });

      final hostRef =
          FirebaseFirestore.instance.collection('hosts').doc(targetUserDoc.id);
      batch.set(
        hostRef,
        {
          'agencyId': _d(agencyId),
          'agencyName': _d(agencyName),
          'status': _d('active'),
          'updatedAt': _d(FieldValue.serverTimestamp()),
        },
        SetOptions(merge: true),
      );

      final agencyRef =
          FirebaseFirestore.instance.collection('agencies').doc(agencyId);
      batch.update(agencyRef, {
        'totalHosts': _d(FieldValue.increment(1)),
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
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _toggleHostCreateAgencyPermission(
      String hostUid, String hostName, bool allow) async {
    try {
      await FirebaseFirestore.instance.collection('users').doc(hostUid).update({
        'allowCreateAgency': _d(allow),
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
        'agencyId': _d(''),
        'agencyName': _d(''),
        'isHost': _d(false),
        'allowCreateAgency': _d(false),
      });

      batch.set(
        hostRef,
        {
          'agencyId': _d(''),
          'agencyName': _d(''),
          'status': _d('removed'),
          'updatedAt': _d(FieldValue.serverTimestamp()),
        },
        SetOptions(merge: true),
      );

      batch.update(agencyRef, {
        'totalHosts': _d(FieldValue.increment(-1)),
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
    final String hostLink = _buildHostInviteLink(agencyId);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (ctx) {
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
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: kTealGreen.withOpacity(0.12),
                      shape: BoxShape.circle,
                    ),
                    child:
                        const Icon(Icons.person_add_alt_1, color: kTealGreen),
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
                  border: Border.all(color: kTealGreen.withOpacity(0.35)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Host Invite Link (Send to Hosts):",
                      style: TextStyle(
                          fontSize: 12,
                          color: kTextMuted,
                          fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      hostLink,
                      style: const TextStyle(

fontSize: 12.5,
                        fontWeight: FontWeight.bold,
                        color: kTealGreen,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: kTealGreen,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(18),
                              ),
                            ),
                            onPressed: () {
                              _copyText(hostLink, "Host Invite Link");
                            },
                            icon: const Icon(Icons.link_rounded, size: 16),
                            label: const Text("Copy Link",
                                style: TextStyle(fontWeight: FontWeight.bold)),
                          ),
                        ),
                        const SizedBox(width: 8),
                        OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            foregroundColor: kTextDark,
                            side: const BorderSide(color: kTealGreen),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(18),
                            ),
                          ),
                          onPressed: () {
                            _copyText(agencyId, "Agency ID");
                          },
                          icon: const Icon(Icons.copy, size: 15),
                          label: Text("ID: $agencyId"),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                "Or Add Host Directly by Numeric ID:",
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
                        : () {
                            _addHostToAgency(ctx, agencyId, agencyName);

},
                    child: const Text(
                      "Add Host",
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  void _showInviteAgencySheet(String parentAgencyId) {
    final subOwnerCtrl = TextEditingController();
    bool permitting = false;
    final String agentLink = _buildAgentInviteLink(parentAgencyId);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setModalState) {
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
                        "Invite Agent / Sub-Agency",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: kTextDark,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE0F2FE),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: kCyanBlue.withOpacity(0.4)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Agent Invite Link (Send to Recruit Sub-Agents):",
                          style: TextStyle(
                              fontSize: 12,
                              color: kTextDark,
                              fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          agentLink,
                          style: const TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF0284C7),
                          ),
                        ),
                        const SizedBox(height: 10),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: kCyanBlue,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(18),

),
                            ),
                            onPressed: () {
                              _copyText(agentLink, "Agent Invite Link");
                            },
                            icon: const Icon(Icons.link_rounded, size: 16),
                            label: const Text("Copy Agent Invite Link",
                                style: TextStyle(fontWeight: FontWeight.bold)),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  const Text(
                    "Or Grant Sub-Agency Permission by Host Numeric ID:",
                    style: TextStyle(fontSize: 12.5, color: kTextMuted),
                  ),
                  const SizedBox(height: 8),
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
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: kTextDark,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 13),
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
                              setModalState(() {
                                permitting = true;
                              });

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
                                    'agencyId': _d(parentAgencyId),
                                    'allowCreateAgency': _d(true),
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
                                  setModalState(() {
                                    permitting = false;
                                  });
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
            );
          },
        );
      },
    );
  }

  void _showEditNameDialog(String agencyId, String currentName) {
    final ctrl = TextEditingController(text: currentName);
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          title: const Text(
            "Edit Agency Name",
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          content: TextField(
            controller: ctrl,
            decoration: InputDecoration(
              hintText: "Enter agency name",
              border:
                  OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(ctx);
              },
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
                      .update({'name': _d(val)});
                }
                if (ctx.mounted) Navigator.pop(ctx);
              },
              child: const Text("Save"),
            ),
          ],
        );
      },
    );
  }

  void _showAgencyTagSheet(String agencyId, List<dynamic> currentTags) {
    final allTags = [
      "VIP Voice",
      "PK Champions",
      "Music & Party",
      "24/7 Active",
      "Top Recruiters",
    ];
    final Set<String> selected = {};
    for (final item in currentTags) {
      selected.add(item.toString());
    }

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setModalState) {
            return Padding(
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
                            if (val && _lt(selected.length, 2)) {
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
                            .update({'tags': _d(selected.toList())});
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
            );
          },
        );
      },
    );
  }

  void _showRulesSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (ctx) {
        return Padding(
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
                final minStr =
                    _fmtNum((t['min'] as num).toInt(), decimals: 0);
                final maxStr =
                    _fmtNum((t['max'] as num).toInt(), decimals: 0);
                final pct = (((t['rate'] as num).toDouble()) * 100).round();
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
        );
      },
    );
  }

  void _showSupportSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (ctx) {
        return Padding(
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
                subtitle: const Text(kAdminWhatsapp),
                trailing: TextButton(
                  onPressed: () {
                    Navigator.pop(ctx);
                    _copyText(kAdminWhatsapp, "WhatsApp");
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
                subtitle: const Text(kAdminTelegram),
                trailing: TextButton(
                  onPressed: () {
                    Navigator.pop(ctx);
                    _copyText(kAdminTelegram, "Telegram");
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
        );
      },
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
      builder: (ctx) {
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.65,
          maxChildSize: 0.9,
          builder: (_, scrollCtrl) {
            return Padding(
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
                        separatorBuilder: (_, __) {
                          return const Divider(height: 1);
                        },
                        itemBuilder: (_, idx) {
                          final doc = hosts[idx];
                          final raw = doc.data();
                          final Map<String, dynamic> h =
                              raw is Map<String, dynamic> ? raw : {};
                          final name = (h['name'] ?? 'Host').toString();
                          final numericId =
                              (h['numericId'] as num?)?.toInt() ?? 0;
                          int pts = (h['points'] as num?)?.toInt() ?? 0;
                          if (pts == 0) {
                            pts = (h['diamonds'] as num?)?.toInt() ?? 0;
                          }
                          final bool canCreate = h['allowCreateAgency'] == true;
                          final String hAvatar =
                              (h['avatarUrl'] ?? h['photoURL'] ?? '')
                                  .toString();
                          final ImageProvider? hImg =
                              _resolveAvatarProvider(hAvatar);

return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            child: Row(
                              children: [
                                CircleAvatar(
                                  backgroundColor: kTealGreen.withOpacity(0.15),
                                  backgroundImage: hImg,
                                  child: hImg == null
                                      ? Text(
                                          name.isNotEmpty
                                              ? name[0].toUpperCase()
                                              : "H",
                                          style: const TextStyle(
                                            color: kTealGreen,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        )
                                      : null,
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
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
                                    _removeHostFromAgency(
                                        agencyId, doc.id, name);
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
            );
          },
        );
      },
    );
  }

  void _showSubAgenciesSheet(
    String parentAgencyId,
    List<QueryDocumentSnapshot> approvedSubAgencies,
    List<QueryDocumentSnapshot> pendingSubRequests,
  ) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Sub-agency Number (${approvedSubAgencies.length})",
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
              if (pendingSubRequests.isNotEmpty) ...[
                const SizedBox(height: 14),
                const Text(
                  "Pending Sub-Agency Requests:",
                  style: TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.bold,
                    color: kCoralRed,
                  ),
                ),
                const SizedBox(height: 8),
                ...pendingSubRequests.map((doc) {
                  final Map<String, dynamic> req =
                      doc.data() is Map<String, dynamic>
                          ? doc.data() as Map<String, dynamic>
                          : {};
                  final String subName =
                      (req['name'] ?? 'Sub-Agency').toString();
                  final String subOwnerUid =
                      (req['ownerUid'] ?? '').toString();
                  final String phone = (req['phone'] ?? '').toString();
                  final String country = (req['country'] ?? '').toString();

                  return Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF7ED),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: kOrangeCardStart),

),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "$subName (ID: ${doc.id})",
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color: kTextDark,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          "Phone: $phone • $country",
                          style: const TextStyle(
                            fontSize: 12,
                            color: kTextMuted,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Expanded(
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: kTealGreen,
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                                onPressed: () {
                                  Navigator.pop(ctx);
                                  _respondToSubAgencyRequest(
                                    subAgencyId: doc.id,
                                    subOwnerUid: subOwnerUid,
                                    subAgencyName: subName,
                                    agree: true,
                                  );
                                },
                                child: const Text("Agree",
                                    style:
                                        TextStyle(fontWeight: FontWeight.bold)),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: OutlinedButton(
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: kCoralRed,
                                  side: const BorderSide(color: kCoralRed),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                                onPressed: () {
                                  Navigator.pop(ctx);
                                  _respondToSubAgencyRequest(
                                    subAgencyId: doc.id,
                                    subOwnerUid: subOwnerUid,
                                    subAgencyName: subName,
                                    agree: false,
                                  );
                                },
                                child: const Text("Reject",
                                    style:
                                        TextStyle(fontWeight: FontWeight.bold)),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                }),
              ],
              const SizedBox(height: 12),
              if (approvedSubAgencies.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 20),
                  child: Center(

child: Text(
                      "No active sub-agencies yet.",
                      style: TextStyle(color: kTextMuted),
                    ),
                  ),
                )
              else
                Flexible(
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemCount: approvedSubAgencies.length,
                    separatorBuilder: (_, __) {
                      return const Divider(height: 1);
                    },
                    itemBuilder: (_, idx) {
                      final doc = approvedSubAgencies[idx];
                      final raw = doc.data();
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
                        subtitle: Text(
                            "ID: ${s['agencyId'] ?? doc.id} • ${s['country'] ?? ''}"),
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
        );
      },
    );
  }
