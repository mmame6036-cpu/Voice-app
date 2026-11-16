import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final User? _currentUser = FirebaseAuth.instance.currentUser;

  static const Color kBg = Color(0xFFF3F5F7);
  static const Color kCard = Colors.white;
  static const Color kDark = Color(0xFF182026);
  static const Color kMuted = Color(0xFF7A869A);
  static const Color kTeal = Color(0xFF00C875);
  static const Color kCyan = Color(0xFF00B4D8);
  static const Color kRed = Color(0xFFFF5252);
  static const Color kDivider = Color(0xFFF0F2F5);

  String _cacheSize = "12.4 MB";

  void _toast(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: const TextStyle(fontWeight: FontWeight.w600)),
        backgroundColor: kDark,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Future<void> _saveField(String key, dynamic value) async {
    if (_currentUser == null) return;
    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(_currentUser!.uid)
          .set({key: value}, SetOptions(merge: true));
    } catch (_) {}
  }

  void _openAccountManager(Map userData) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => _AccountManagerPage(
          userData: userData,
          onSaveField: _saveField,
          onToast: _toast,
        ),
      ),
    );
  }

  void _openMessageSettings(Map userData) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => _MessageSettingsPage(
          initialBanner: userData['topMessageBanner'] ?? true,
          initialSounds: userData['roomSounds'] ?? true,
          initialVibration: userData['vibrationEnabled'] ?? true,
          onSaveField: _saveField,
        ),
      ),
    );
  }

  void _openLanguageSettings(String currentLang) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => _LanguageSettingPage(
          currentLanguage: currentLang,
          onSaved: (lang) async {
            await _saveField('appLanguage', lang);
            _toast("Language updated to $lang");
          },
        ),
      ),
    );
  }

  void _openNetworkLine(String currentLine) {
    final lines = [
      {'name': 'Auto (Recommended)', 'ping': '24 ms'},
      {'name': 'Line 1 - Africa & Middle East', 'ping': '32 ms'},
      {'name': 'Line 2 - Europe Server', 'ping': '48 ms'},
      {'name': 'Line 3 - Global Backup', 'ping': '65 ms'},
    ];

    showModalBottomSheet(
      context: context,
      backgroundColor: kCard,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Network Line",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: kDark),
            ),
            const SizedBox(height: 6),
            const Text(
              "Select the fastest voice routing server for your region:",
              style: TextStyle(fontSize: 12.5, color: kMuted),
            ),
            const SizedBox(height: 12),
            ...lines.map((line) {
              final name = line['name']!;
              final ping = line['ping']!;

final selected = currentLine == name;
              return ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Icon(
                  selected ? Icons.radio_button_checked : Icons.radio_button_off,
                  color: selected ? kTeal : kMuted,
                ),
                title: Text(name, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                trailing: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEEF9F6),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    ping,
                    style: const TextStyle(color: kTeal, fontSize: 11.5, fontWeight: FontWeight.bold),
                  ),
                ),
                onTap: () async {
                  Navigator.pop(ctx);
                  await _saveField('networkLine', name);
                  _toast("Switched to $name");
                },
              );
            }),
          ],
        ),
      ),
    );
  }

  void _openPrivilegeSettings(Map userData) {
    bool hideOnline = userData['hideOnlineStatus'] == true;
    bool invisibleEntry = userData['invisibleEntry'] == true;
    bool hideLevel = userData['hideLevel'] == true;
    bool blockStrangerDm = userData['blockStrangerDm'] == true;

    showModalBottomSheet(
      context: context,
      backgroundColor: kCard,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Privilege Settings",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: kDark),
              ),
              const SizedBox(height: 8),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text("Hide Online Status", style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                subtitle: const Text("Appear offline to other users", style: TextStyle(fontSize: 12, color: kMuted)),
                activeColor: kTeal,
                value: hideOnline,
                onChanged: (v) {
                  setS(() => hideOnline = v);
                  _saveField('hideOnlineStatus', v);
                },
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text("Invisible Room Entry", style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                subtitle: const Text("Enter voice rooms without entry banner", style: TextStyle(fontSize: 12, color: kMuted)),
                activeColor: kTeal,
                value: invisibleEntry,
                onChanged: (v) {
                  setS(() => invisibleEntry = v);
                  _saveField('invisibleEntry', v);
                },
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text("Hide Wealth & Charm Level", style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                subtitle: const Text("Conceal level badges on profile card", style: TextStyle(fontSize: 12, color: kMuted)),
                activeColor: kTeal,
                value: hideLevel,
                onChanged: (v) {
                  setS(() => hideLevel = v);
                  _saveField('hideLevel', v);

},
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text("Block Stranger Messages", style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                subtitle: const Text("Only receive messages from friends", style: TextStyle(fontSize: 12, color: kMuted)),
                activeColor: kTeal,
                value: blockStrangerDm,
                onChanged: (v) {
                  setS(() => blockStrangerDm = v);
                  _saveField('blockStrangerDm', v);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _openBlockedUsers() {
    if (_currentUser == null) return;
    final blockIdCtrl = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: kCard,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 20,
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
        ),
        child: SizedBox(
          height: MediaQuery.of(ctx).size.height * 0.6,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Blocked Users",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: kDark),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: blockIdCtrl,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        hintText: "Enter User ID to block",
                        isDense: true,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: kRed, foregroundColor: Colors.white),
                    onPressed: () async {
                      final target = blockIdCtrl.text.trim();
                      if (target.isEmpty) return;
                      await FirebaseFirestore.instance
                          .collection('users')
                          .doc(_currentUser!.uid)
                          .set({
                        'blacklist': FieldValue.arrayUnion([target])
                      }, SetOptions(merge: true));
                      blockIdCtrl.clear();
                      _toast("User $target added to blocked list.");
                    },
                    child: const Text("Block"),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Expanded(
                child: StreamBuilder(
                  stream: FirebaseFirestore.instance
                      .collection('users')
                      .doc(_currentUser!.uid)
                      .snapshots(),
                  builder: (context, AsyncSnapshot snap) {
                    final doc = snap.data as DocumentSnapshot?;
                    final data = doc?.data() as Map? ?? {};
                    final List blocked = data['blacklist'] is List ? data['blacklist'] : [];

                    if (blocked.isEmpty) {
                      return const Center(
                        child: Text("No blocked users.", style: TextStyle(color: kMuted)),
                      );
                    }

return ListView.separated(
                      itemCount: blocked.length,
                      separatorBuilder: (_, __) => const Divider(height: 1),
                      itemBuilder: (_, i) {
                        final item = blocked[i].toString();
                        return ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: const CircleAvatar(
                            backgroundColor: Color(0xFFFFEBEE),
                            child: Icon(Icons.block, color: kRed, size: 20),
                          ),
                          title: Text("User ID: $item", style: const TextStyle(fontWeight: FontWeight.w600)),
                          trailing: TextButton(
                            onPressed: () async {
                              await FirebaseFirestore.instance
                                  .collection('users')
                                  .doc(_currentUser!.uid)
                                  .update({
                                'blacklist': FieldValue.arrayRemove([item])
                              });
                              _toast("Unblocked $item");
                            },
                            child: const Text("Unblock", style: TextStyle(color: kTeal, fontWeight: FontWeight.bold)),
                          ),
                        );
                      },
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

  void _clearCache() {
    PaintingBinding.instance.imageCache.clear();
    PaintingBinding.instance.imageCache.clearLiveImages();
    setState(() => _cacheSize = "0.0 MB");
    _toast("Cache cleared successfully.");
  }

  void _openAboutUs() {
    showModalBottomSheet(
      context: context,
      backgroundColor: kCard,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(22),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "About Us",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: kDark),
            ),
            const SizedBox(height: 10),
            const Text(
              "NILE Live - Global Voice Party & Social Platform",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: kDark),
            ),
            const SizedBox(height: 4),
            const Text("Version: v1.0.4 (Build 26)", style: TextStyle(fontSize: 12.5, color: kMuted)),
            const SizedBox(height: 14),
            const Text(
              "Terms & Privacy Policy",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5, color: kDark),
            ),
            const SizedBox(height: 6),
            const Text(
              "1. Community Safety: Respect all hosts and listeners in voice rooms.\n"
              "2. Virtual Economy: Coins and Points follow platform conversion rules (10,000 Points = \$1.00 USD).\n"
              "3. Privacy: Real-time audio streams are encrypted and never stored without consent.",
              style: TextStyle(fontSize: 12, color: kMuted, height: 1.45),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: kTeal, foregroundColor: Colors.white),
                onPressed: () => Navigator.pop(ctx),
                child: const Text("Close"),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _openDeleteAccount() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => _DeleteAccountPage(onToast: _toast),
      ),
    );
  }

void _confirmSignOut() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Text("Sign Out", style: TextStyle(fontWeight: FontWeight.bold)),
        content: const Text("Are you sure you want to sign out of your account?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Cancel", style: TextStyle(color: kMuted)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: kRed, foregroundColor: Colors.white),
            onPressed: () async {
              Navigator.pop(ctx);
              await FirebaseAuth.instance.signOut();
              if (mounted) {
                Navigator.of(context).popUntil((route) => route.isFirst);
              }
            },
            child: const Text("Sign Out", style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final uid = _currentUser?.uid ?? "";

    return Scaffold(
      backgroundColor: kBg,
      appBar: AppBar(
        backgroundColor: kBg,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: kDark, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "Setting",
          style: TextStyle(color: kDark, fontSize: 18, fontWeight: FontWeight.bold),
        ),
      ),
      body: StreamBuilder(
        stream: uid.isNotEmpty
            ? FirebaseFirestore.instance.collection('users').doc(uid).snapshots()
            : null,
        builder: (context, AsyncSnapshot snap) {
          final doc = snap.data as DocumentSnapshot?;
          final userData = doc?.data() as Map? ?? {};
          final currentLang = (userData['appLanguage'] ?? 'Follow System').toString();
          final currentLine = (userData['networkLine'] ?? 'Auto (Recommended)').toString();

          return SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
            child: Column(
              children: [
                _cardGroup([
                  _settingRow(
                    title: "Account Manager",
                    onTap: () => _openAccountManager(userData),
                  ),
                ]),
                const SizedBox(height: 12),
                _cardGroup([
                  _settingRow(
                    title: "Message Settings",
                    onTap: () => _openMessageSettings(userData),
                  ),
                  const Divider(height: 1, indent: 16, color: kDivider),
                  _settingRow(
                    title: "Language Setting",
                    trailing: currentLang,
                    onTap: () => _openLanguageSettings(currentLang),
                  ),
                  const Divider(height: 1, indent: 16, color: kDivider),
                  _settingRow(
                    title: "Network Line",
                    trailing: currentLine.split(' ').first,
                    onTap: () => _openNetworkLine(currentLine),
                  ),
                  const Divider(height: 1, indent: 16, color: kDivider),
                  _settingRow(
                    title: "Privilege settings",
                    onTap: () => _openPrivilegeSettings(userData),
                  ),
                  const Divider(height: 1, indent: 16, color: kDivider),
                  _settingRow(
                    title: "Blocked Users",
                    onTap: _openBlockedUsers,
                  ),
                ]),

const SizedBox(height: 12),
                _cardGroup([
                  _settingRow(
                    title: "Clear Cache",
                    trailing: _cacheSize,
                    onTap: _clearCache,
                  ),
                  const Divider(height: 1, indent: 16, color: kDivider),
                  _settingRow(
                    title: "About Us",
                    trailing: "v1.0.4",
                    onTap: _openAboutUs,
                  ),
                  const Divider(height: 1, indent: 16, color: kDivider),
                  _settingRow(
                    title: "Delete Account",
                    titleColor: kRed,
                    onTap: _openDeleteAccount,
                  ),
                ]),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: kCard,
                      foregroundColor: kRed,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    onPressed: _confirmSignOut,
                    child: const Text(
                      "Sign Out",
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
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

  Widget _cardGroup(List children) {
    return Container(
      decoration: BoxDecoration(
        color: kCard,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: List.generate(children.length, (i) => children[i] as Widget),
      ),
    );
  }

  Widget _settingRow({
    required String title,
    String trailing = "",
    Color titleColor = kDark,
    required VoidCallback onTap,
  }) {
    return ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
      title: Text(
        title,
        style: TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w500,
          color: titleColor,
        ),
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (trailing.isNotEmpty)
            Text(
              trailing,
              style: const TextStyle(fontSize: 13, color: kMuted),
            ),
          const SizedBox(width: 4),
          const Icon(Icons.chevron_right_rounded, color: kMuted, size: 22),
        ],
      ),
    );
  }
}

// ============================================================================
// 1. ACCOUNT MANAGER PAGE (Account Password, Security Password, Mail, Phone)
// ============================================================================
class _AccountManagerPage extends StatelessWidget {
  final Map userData;
  final Future<void> Function(String key, dynamic val) onSaveField;
  final void Function(String msg) onToast;

  const _AccountManagerPage({
    required this.userData,
    required this.onSaveField,
    required this.onToast,
  });

  void _openAccountPasswordDialog(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final passCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Text("Account Password", style: TextStyle(fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,

children: [
            const Text(
              "Set a new login password (minimum 6 characters):",
              style: TextStyle(fontSize: 12.5, color: Color(0xFF7A869A)),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: passCtrl,
              obscureText: true,
              decoration: InputDecoration(
                hintText: "Enter new password",
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Cancel")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF00C875),
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              final newPass = passCtrl.text.trim();
              if (newPass.length < 6) {
                onToast("Password must be at least 6 characters.");
                return;
              }
              Navigator.pop(ctx);
              try {
                if (user != null) {
                  await user.updatePassword(newPass);
                }
                await onSaveField('hasPassword', true);
                onToast("Account password updated successfully.");
              } catch (e) {
                if (user?.email != null && user!.email!.isNotEmpty) {
                  await FirebaseAuth.instance.sendPasswordResetEmail(email: user.email!);
                  onToast("Password reset link sent to ${user.email}");
                } else {
                  onToast("Please sign in again to change password.");
                }
              }
            },
            child: const Text("Save"),
          ),
        ],
      ),
    );
  }

  void _openSecurityPasswordDialog(BuildContext context, bool hasPin) {
    final pinCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: Text(
          hasPin ? "Change Security Password" : "Set Security Password",
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        content: TextField(
          controller: pinCtrl,
          keyboardType: TextInputType.number,
          obscureText: true,
          maxLength: 6,
          decoration: InputDecoration(
            hintText: "Enter 6-digit Security PIN",
            counterText: "",
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Cancel")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF00C875),
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              final pin = pinCtrl.text.trim();
              if (pin.length != 6) {
                onToast("Security password must be 6 digits.");
                return;
              }
              Navigator.pop(ctx);
              await onSaveField('paymentPin', pin);
              onToast("Security password saved.");
            },
            child: const Text("Save"),
          ),
        ],
      ),
    );
  }

  void _openBindMailPage(BuildContext context, String existingMail) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => _BindMailPage(
          existingEmail: existingMail,
          onBound: (email) async {
            await onSaveField('email', email);
            await onSaveField('isEmailBound', true);
            onToast("Mail bound successfully: $email");
          },
          onToast: onToast,
        ),
      ),
    );
  }

void _openBindPhoneDialog(BuildContext context, String currentPhone) {
    final phoneCtrl = TextEditingController(text: currentPhone);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Text("Bind Phone", style: TextStyle(fontWeight: FontWeight.bold)),
        content: TextField(
          controller: phoneCtrl,
          keyboardType: TextInputType.phone,
          decoration: InputDecoration(
            hintText: "+2519...",
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Cancel")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF00C875),
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              final p = phoneCtrl.text.trim();
              if (p.isEmpty) return;
              Navigator.pop(ctx);
              await onSaveField('phoneNumber', p);
              onToast("Phone number saved.");
            },
            child: const Text("Save"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final uid = user?.uid ?? "";

    return Scaffold(
      backgroundColor: const Color(0xFFF3F5F7),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF3F5F7),
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Color(0xFF182026), size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "Account Manager",
          style: TextStyle(color: Color(0xFF182026), fontSize: 18, fontWeight: FontWeight.bold),
        ),
      ),
      body: StreamBuilder(
        stream: uid.isNotEmpty
            ? FirebaseFirestore.instance.collection('users').doc(uid).snapshots()
            : null,
        builder: (context, AsyncSnapshot snap) {
          final doc = snap.data as DocumentSnapshot?;
          final live = doc?.data() as Map? ?? userData;
          final bool hasPass = live['hasPassword'] == true;
          final bool hasPin = (live['paymentPin'] ?? '').toString().isNotEmpty;
          final String boundMail = (live['email'] ?? user?.email ?? '').toString();
          final String phone = (live['phoneNumber'] ?? '').toString();

          return Padding(
            padding: const EdgeInsets.all(16),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ListTile(
                    title: const Text("Account Password", style: TextStyle(fontWeight: FontWeight.w500)),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(hasPass ? "Set" : "Not Set",
                            style: const TextStyle(color: Color(0xFF7A869A), fontSize: 13)),
                        const Icon(Icons.chevron_right_rounded, color: Color(0xFF7A869A)),
                      ],
                    ),
                    onTap: () => _openAccountPasswordDialog(context),
                  ),
                  const Divider(height: 1, indent: 16, color: Color(0xFFF0F2F5)),
                  ListTile(
                    title: const Text("Security Password", style: TextStyle(fontWeight: FontWeight.w500)),

trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(hasPin ? "Set" : "Not Set",
                            style: const TextStyle(color: Color(0xFF7A869A), fontSize: 13)),
                        const Icon(Icons.chevron_right_rounded, color: Color(0xFF7A869A)),
                      ],
                    ),
                    onTap: () => _openSecurityPasswordDialog(context, hasPin),
                  ),
                  const Divider(height: 1, indent: 16, color: Color(0xFFF0F2F5)),
                  ListTile(
                    title: const Text("Mail", style: TextStyle(fontWeight: FontWeight.w500)),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          boundMail.isNotEmpty ? boundMail : "Not Bound",
                          style: const TextStyle(color: Color(0xFF7A869A), fontSize: 13),
                        ),
                        const Icon(Icons.chevron_right_rounded, color: Color(0xFF7A869A)),
                      ],
                    ),
                    onTap: () => _openBindMailPage(context, boundMail),
                  ),
                  const Divider(height: 1, indent: 16, color: Color(0xFFF0F2F5)),
                  ListTile(
                    title: const Text("Phone Number", style: TextStyle(fontWeight: FontWeight.w500)),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          phone.isNotEmpty ? phone : "Not Bound",
                          style: const TextStyle(color: Color(0xFF7A869A), fontSize: 13),
                        ),
                        const Icon(Icons.chevron_right_rounded, color: Color(0xFF7A869A)),
                      ],
                    ),
                    onTap: () => _openBindPhoneDialog(context, phone),
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

// ============================================================================
// BIND MAIL SUB-PAGE (Matches Video: Email + Get Code + Bind Button)
// ============================================================================
class _BindMailPage extends StatefulWidget {
  final String existingEmail;
  final Future<void> Function(String email) onBound;
  final void Function(String msg) onToast;

  const _BindMailPage({
    required this.existingEmail,
    required this.onBound,
    required this.onToast,
  });

  @override
  State<_BindMailPage> createState() => _BindMailPageState();
}

class _BindMailPageState extends State<_BindMailPage> {
  late TextEditingController _emailCtrl;
  final TextEditingController _codeCtrl = TextEditingController();
  Timer? _timer;
  int _cooldown = 0;
  String _expectedCode = "";
  bool _binding = false;

  @override
  void initState() {
    super.initState();
    _emailCtrl = TextEditingController(text: widget.existingEmail);
  }

  @override
  void dispose() {
    _timer?.cancel();
    _emailCtrl.dispose();
    _codeCtrl.dispose();
    super.dispose();
  }

  void _sendCode() {
    final mail = _emailCtrl.text.trim();
    if (!mail.contains('@') || !mail.contains('.')) {
      widget.onToast("Please enter a valid email address.");
      return;
    }
    final code = "${100000 + Random().nextInt(899999)}";
    setState(() {
      _expectedCode = code;
      _cooldown = 60;
    });
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) {
        t.cancel();
        return;
      }
      if (_cooldown <= 1) {
        t.cancel();
        setState(() => _cooldown = 0);
      } else {
        setState(() => _cooldown -= 1);
      }
    });
    widget.onToast("Verification code sent: $code");
  }

@override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F5F7),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF3F5F7),
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Color(0xFF182026), size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "Bind Mail",
          style: TextStyle(color: Color(0xFF182026), fontSize: 18, fontWeight: FontWeight.bold),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Column(
                children: [
                  TextField(
                    controller: _emailCtrl,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(
                      hintText: "Please enter your email",
                      border: InputBorder.none,
                    ),
                  ),
                  const Divider(color: Color(0xFFF0F2F5)),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _codeCtrl,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            hintText: "Verification code",
                            border: InputBorder.none,
                          ),
                        ),
                      ),
                      TextButton(
                        onPressed: _cooldown > 0 ? null : _sendCode,
                        child: Text(
                          _cooldown > 0 ? "${_cooldown}s" : "Get Code",
                          style: const TextStyle(
                            color: Color(0xFF00C875),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF00C875),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                ),
                onPressed: _binding
                    ? null
                    : () async {
                        final mail = _emailCtrl.text.trim();
                        final entered = _codeCtrl.text.trim();
                        if (!mail.contains('@')) {
                          widget.onToast("Please enter a valid email.");
                          return;
                        }
                        if (_expectedCode.isEmpty || entered != _expectedCode) {
                          widget.onToast("Invalid verification code.");
                          return;
                        }
                        setState(() => _binding = true);
                        await widget.onBound(mail);
                        if (mounted) Navigator.pop(context);
                      },
                child: const Text(
                  "Bind",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================================
// 2. MESSAGE SETTINGS PAGE (Top Message Banner, Sounds, Vibration)
// ============================================================================
class _MessageSettingsPage extends StatefulWidget {
  final bool initialBanner;
  final bool initialSounds;
  final bool initialVibration;
  final Future<void> Function(String key, dynamic val) onSaveField;

  const _MessageSettingsPage({
    required this.initialBanner,
    required this.initialSounds,
    required this.initialVibration,
    required this.onSaveField,
  });

  @override
  State<_MessageSettingsPage> createState() => _MessageSettingsPageState();
}

class _MessageSettingsPageState extends State<_MessageSettingsPage> {
  late bool _banner;
  late bool _sounds;
  late bool _vibration;

  @override
  void initState() {
    super.initState();
    _banner = widget.initialBanner;
    _sounds = widget.initialSounds;
    _vibration = widget.initialVibration;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F5F7),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF3F5F7),
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Color(0xFF182026), size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "Message Settings",
          style: TextStyle(color: Color(0xFF182026), fontSize: 18, fontWeight: FontWeight.bold),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SwitchListTile(
                title: const Text("Top Message Banner", style: TextStyle(fontWeight: FontWeight.w500)),
                activeColor: const Color(0xFF00C875),
                value: _banner,
                onChanged: (v) {
                  setState(() => _banner = v);
                  widget.onSaveField('topMessageBanner', v);
                },
              ),
              const Divider(height: 1, indent: 16, color: Color(0xFFF0F2F5)),
              SwitchListTile(
                title: const Text("Sounds", style: TextStyle(fontWeight: FontWeight.w500)),
                activeColor: const Color(0xFF00C875),
                value: _sounds,
                onChanged: (v) {
                  setState(() => _sounds = v);
                  widget.onSaveField('roomSounds', v);
                },
              ),
              const Divider(height: 1, indent: 16, color: Color(0xFFF0F2F5)),
              SwitchListTile(
                title: const Text("Vibration", style: TextStyle(fontWeight: FontWeight.w500)),
                activeColor: const Color(0xFF00C875),
                value: _vibration,
                onChanged: (v) {
                  setState(() => _vibration = v);
                  widget.onSaveField('vibrationEnabled', v);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ============================================================================
// 3. LANGUAGE SETTING PAGE (Follow System, English, Amharic, Arabic, etc.)
// ============================================================================
class _LanguageSettingPage extends StatefulWidget {
  final String currentLanguage;
  final Future<void> Function(String lang) onSaved;

  const _LanguageSettingPage({
    required this.currentLanguage,
    required this.onSaved,
  });

  @override
  State<_LanguageSettingPage> createState() => _LanguageSettingPageState();
}

class _LanguageSettingPageState extends State<_LanguageSettingPage> {
  late String _selected;
  final List _languages = const [
    "Follow System",
    "English",
    "Amharic",
    "Arabic",
    "French",
    "Turkish",
  ];

  @override
  void initState() {
    super.initState();
    _selected = widget.currentLanguage;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F5F7),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF3F5F7),
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Color(0xFF182026), size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "Language Setting",
          style: TextStyle(color: Color(0xFF182026), fontSize: 18, fontWeight: FontWeight.bold),
        ),
        actions: [
          TextButton(
            onPressed: () async {
              await widget.onSaved(_selected);
              if (mounted) Navigator.pop(context);
            },
            child: const Text(
              "Save",
              style: TextStyle(
                color: Color(0xFF00C875),
                fontSize: 15,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
          ),
          child: ListView.separated(
            shrinkWrap: true,
            itemCount: _languages.length,
            separatorBuilder: (_, __) => const Divider(height: 1, indent: 16, color: Color(0xFFF0F2F5)),
            itemBuilder: (_, i) {
              final lang = _languages[i].toString();
              final isSelected = _selected == lang;
              return ListTile(
                title: Text(lang, style: const TextStyle(fontWeight: FontWeight.w500)),
                trailing: isSelected
                    ? const Icon(Icons.check_circle, color: Color(0xFF00C875))
                    : const Icon(Icons.circle_outlined, color: Color(0xFFCBD5E1)),
                onTap: () => setState(() => _selected = lang),
              );
            },
          ),
        ),
      ),
    );
  }
}

// ============================================================================
// 4. DELETE ACCOUNT PAGE (4 Warnings + Checkbox + 15-Second Countdown Timer)
// ============================================================================
class _DeleteAccountPage extends StatefulWidget {
  final void Function(String msg) onToast;

  const _DeleteAccountPage({required this.onToast});

  @override
  State<_DeleteAccountPage> createState() => _DeleteAccountPageState();
}

class _DeleteAccountPageState extends State<_DeleteAccountPage> {
  Timer? _timer;
  int _secondsLeft = 15;
  bool _agreed = false;
  bool _deleting = false;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) {
        t.cancel();
        return;
      }
      if (_secondsLeft <= 1) {
        t.cancel();
        setState(() => _secondsLeft = 0);
      } else {
        setState(() => _secondsLeft -= 1);
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _executeDeletion() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    setState(() => _deleting = true);
    try {
      await FirebaseFirestore.instance.collection('users').doc(user.uid).delete();
      await user.delete();
      if (mounted) {
        Navigator.of(context).popUntil((route) => route.isFirst);
      }
    } catch (e) {
      widget.onToast("Please re-login before deleting account: $e");
    } finally {
      if (mounted) setState(() => _deleting = false);
    }
  }

@override
  Widget build(BuildContext context) {
    final bool canConfirm = _secondsLeft == 0 && _agreed && !_deleting;

    return Scaffold(
      backgroundColor: const Color(0xFFF3F5F7),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF3F5F7),
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Color(0xFF182026), size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "Delete Account",
          style: TextStyle(color: Color(0xFF182026), fontSize: 18, fontWeight: FontWeight.bold),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.warning_amber_rounded, color: Color(0xFFFF5252), size: 26),
                      SizedBox(width: 8),
                      Text(
                        "Important Account Deletion Notice",
                        style: TextStyle(fontSize: 15.5, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  SizedBox(height: 14),
                  Text(
                    "1. Permanent Deletion: Once confirmed, your account cannot be restored.",
                    style: TextStyle(fontSize: 13, height: 1.4),
                  ),
                  SizedBox(height: 10),
                  Text(
                    "2. All Account Data Cannot Be Recovered: Remaining coins, points, VIP status, and agency records will be forfeited.",
                    style: TextStyle(fontSize: 13, height: 1.4),
                  ),
                  SizedBox(height: 10),
                  Text(
                    "3. 15-Day Grace Period: Logging in during review cancels pending deletion requests.",
                    style: TextStyle(fontSize: 13, height: 1.4),
                  ),
                  SizedBox(height: 10),
                  Text(
                    "4. Full Data Wipe: Personal profile, chat history, and room privileges will be permanently erased.",
                    style: TextStyle(fontSize: 13, height: 1.4),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            CheckboxListTile(
              contentPadding: EdgeInsets.zero,
              controlAffinity: ListTileControlAffinity.leading,
              activeColor: const Color(0xFFFF5252),
              title: const Text(
                "I have read and agree to permanently delete my account",
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
              ),
              value: _agreed,
              onChanged: (v) => setState(() => _agreed = v == true),
            ),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: canConfirm ? const Color(0xFFFF5252) : Colors.black26,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
                ),
                onPressed: canConfirm ? _executeDeletion : null,
                child: Text(
                  _secondsLeft > 0

? "Confirm Deletion (${_secondsLeft}s)"
                      : "Confirm Deletion",
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }
}
