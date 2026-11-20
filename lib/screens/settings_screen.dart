import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final User? _currentUser = FirebaseAuth.instance.currentUser;

  static const Color kBg = Color(0xFFF5F6F8);
  static const Color kCard = Colors.white;
  static const Color kDark = Color(0xFF1F2329);
  static const Color kMuted = Color(0xFF86909C);
  static const Color kTeal = Color(0xFF1ED7B5);
  static const Color kRed = Color(0xFFE54D42);
  static const Color kDivider = Color(0xFFF2F3F5);

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
        builder: (_) => _AccountSettingsPage(
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
          initialBanner: userData['topMessageBanner'] != false,
          initialSounds: userData['roomSounds'] != false,
          initialVibration: userData['vibrationEnabled'] != false,
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
            _toast("Language saved: $lang");
          },
        ),
      ),
    );
  }

  void _openNetworkLine(String currentLine) {
    final lines = ["Line1", "Line2"];

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: const BoxDecoration(
          color: kCard,
          borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 8),
              ...lines.map((lineName) {
                final bool isSelected = currentLine == lineName;
                return Column(
                  children: [
                    InkWell(
                      onTap: () async {
                        Navigator.pop(ctx);
                        await _saveField('networkLine', lineName);
                        _toast("Connected to $lineName");
                      },
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            if (isSelected) ...[
                              const Icon(Icons.check_circle,

color: kTeal, size: 22),
                              const SizedBox(width: 8),
                            ],
                            Text(
                              lineName,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: kDark,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 2.5),
                              decoration: BoxDecoration(
                                color: const Color(0xFFE8F9F4),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: const Text(
                                "Good",
                                style: TextStyle(
                                  color: Color(0xFF00B578),
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const Divider(height: 1, color: kDivider),
                  ],
                );
              }),
              Container(height: 8, color: kBg),
              InkWell(
                onTap: () => Navigator.pop(ctx),
                child: const SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: Center(
                    child: Text(
                      "Cancel",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: kDark,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _openPrivilegeSettings(Map userData) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => _PrivilegeSettingsPage(
          initialMysteryMan: userData['mysteryManOnRank'] == true,
          initialHideOnline: userData['hideOnlineStatus'] == true,
          initialInvisibleEntry: userData['invisibleEntry'] == true,
          onSaveField: _saveField,
        ),
      ),
    );
  }

  void _openBlockedUsers() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => _BlockedUsersPage(onToast: _toast),
      ),
    );
  }

  void _clearCache() {
    PaintingBinding.instance.imageCache.clear();
    PaintingBinding.instance.imageCache.clearLiveImages();
    setState(() => _cacheSize = "0.0 MB");
    _toast("Cache cleared.");
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
              style: TextStyle(
                  fontSize: 18, fontWeight: FontWeight.bold, color: kDark),
            ),
            const SizedBox(height: 10),
            const Text(
              "NILE Live - Global Voice Chat & Party Platform",
              style: TextStyle(

fontWeight: FontWeight.bold, fontSize: 14, color: kDark),
            ),
            const SizedBox(height: 4),
            const Text("Version: v1.0.5",
                style: TextStyle(fontSize: 12.5, color: kMuted)),
            const SizedBox(height: 14),
            const Text(
              "1. Community Guidelines: Respect all hosts and guests in voice rooms.\n"
              "2. Wallet & Rewards: 10,000 Points = \$1.00 USD withdrawal value.\n"
              "3. Real-Time Audio: Low-latency encrypted voice channels.",
              style: TextStyle(fontSize: 12.5, color: kMuted, height: 1.45),
            ),
            const SizedBox(height: 18),
            SizedBox(
              width: double.infinity,
              height: 46,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: kTeal,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(23)),
                ),
                onPressed: () => Navigator.pop(ctx),
                child: const Text("Close",
                    style: TextStyle(fontWeight: FontWeight.bold)),
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
        backgroundColor: kCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Text("Sign Out",
            style: TextStyle(fontWeight: FontWeight.bold, color: kDark)),
        content: const Text(
          "Are you sure you want to sign out?",
          style: TextStyle(color: kMuted),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Cancel", style: TextStyle(color: kMuted)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: kRed,
              foregroundColor: Colors.white,
              elevation: 0,
            ),
            onPressed: () async {
              Navigator.pop(ctx);
              await FirebaseAuth.instance.signOut();
              if (mounted) {
                Navigator.of(context).popUntil((route) => route.isFirst);
              }
            },
            child: const Text("Sign Out",
                style: TextStyle(fontWeight: FontWeight.bold)),
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
          icon: const Icon(Icons.arrow_back_ios_new, color: kDark, size: 19),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "Setting",
          style: TextStyle(
              color: kDark, fontSize: 18, fontWeight: FontWeight.w700),
        ),
      ),
      body: StreamBuilder(
        stream: uid.isNotEmpty
            ? FirebaseFirestore.instance.collection('users').doc(uid).snapshots()
            : null,
        builder: (context, AsyncSnapshot snap) {
          final doc = snap.data as DocumentSnapshot?;
          final userData = doc?.data() as Map? ?? {};
          final currentLang =
              (userData['appLanguage'] ?? 'English').toString();
          final currentLine =
              (userData['networkLine'] ?? 'Line1').toString();

return SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 28),
            child: Column(
              children: [
                // Card 1: Account Manager
                _cardGroup([
                  _settingRow(
                    title: "Account Manager",
                    onTap: () => _openAccountManager(userData),
                  ),
                ]),
                const SizedBox(height: 12),

                // Card 2: Message, Language, Network, Privilege, Blocked
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
                    trailing: currentLine,
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

                // Card 3: Cache, About, Delete Account
                _cardGroup([
                  _settingRow(
                    title: "Clear Cache",
                    trailing: _cacheSize,
                    onTap: _clearCache,
                  ),
                  const Divider(height: 1, indent: 16, color: kDivider),
                  _settingRow(
                    title: "About Us",
                    trailing: "v1.0.5",
                    onTap: _openAboutUs,
                  ),
                  const Divider(height: 1, indent: 16, color: kDivider),
                  _settingRow(
                    title: "Delete Account",
                    titleColor: kRed,
                    onTap: _openDeleteAccount,
                  ),
                ]),
                const SizedBox(height: 18),

                // Sign Out Card Button
                SizedBox(
                  width: double.infinity,
                  height: 54,
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
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
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
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 3),
      title: Text(
        title,
        style: TextStyle(
          fontSize: 15.5,
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
              style: const TextStyle(fontSize: 13.5, color: kMuted),
            ),
          const SizedBox(width: 4),
          const Icon(Icons.chevron_right_rounded, color: kMuted, size: 22),
        ],
      ),
    );
  }
}

// ============================================================================
// 1. ACCOUNT SETTINGS PAGE (Account Password, Security Password, Mail)
// ============================================================================
class _AccountSettingsPage extends StatelessWidget {
  final Map userData;
  final Future<void> Function(String key, dynamic val) onSaveField;
  final void Function(String msg) onToast;

  const _AccountSettingsPage({
    required this.userData,
    required this.onSaveField,
    required this.onToast,
  });

  String _maskEmail(String email) {
    if (email.isEmpty || !email.contains('@')) return "Not Bound";
    final parts = email.split('@');
    final name = parts[0];
    final domain = parts[1];
    if (name.length <= 3) return "$name***@$domain";
    return "${name.substring(0, 4)}***@$domain";
  }

  void _openSetPasswordScreen(BuildContext context, {required bool isSecurity}) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => _SetPasswordPage(
          isSecurityPassword: isSecurity,
          onSaveField: onSaveField,
          onToast: onToast,
        ),
      ),
    );
  }

  void _openMailBottomSheet(BuildContext context, String currentMail) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              InkWell(
                onTap: () {
                  Navigator.pop(ctx);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => _BindMailPage(
                        existingEmail: currentMail,
                        onBound: (newMail) async {
                          await onSaveField('email', newMail);
                          await onSaveField('isEmailBound', true);
                          onToast("Email updated: $newMail");
                        },
                        onToast: onToast,
                      ),
                    ),
                  );
                },
                child: const SizedBox(
                  width: double.infinity,
                  height: 58,
                  child: Center(
                    child: Text(
                      "Reset Email",
                      style: TextStyle(
                        fontSize: 16.5,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF1F2329),
                      ),
                    ),
                  ),
                ),
              ),
              Container(height: 8, color: const Color(0xFFF5F6F8)),
              InkWell(
                onTap: () => Navigator.pop(ctx),

child: const SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: Center(
                    child: Text(
                      "Cancel",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF1F2329),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final uid = user?.uid ?? "";

    return Scaffold(
      backgroundColor: const Color(0xFFF5F6F8),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF5F6F8),
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new,
              color: Color(0xFF1F2329), size: 19),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "Account Settings",
          style: TextStyle(
              color: Color(0xFF1F2329),
              fontSize: 18,
              fontWeight: FontWeight.w700),
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
          final String boundMail =
              (live['email'] ?? user?.email ?? '').toString();

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
                    contentPadding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    title: const Text(
                      "Account Password",
                      style: TextStyle(
                        fontSize: 15.5,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1F2329),
                      ),
                    ),
                    subtitle: const Padding(
                      padding: EdgeInsets.only(top: 4),
                      child: Text(
                        "This password is used for account login",
                        style: TextStyle(
                          fontSize: 12.5,
                          color: Color(0xFF86909C),
                        ),
                      ),
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          hasPass ? "Change" : "Set",
                          style: const TextStyle(
                            color: Color(0xFF86909C),
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(width: 2),
                        const Icon(Icons.chevron_right_rounded,
                            color: Color(0xFF86909C), size: 22),
                      ],
                    ),
                    onTap: () =>
                        _openSetPasswordScreen(context, isSecurity: false),

),
                  const Divider(height: 1, indent: 16, color: Color(0xFFF2F3F5)),
                  ListTile(
                    contentPadding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    title: const Text(
                      "Security Password",
                      style: TextStyle(
                        fontSize: 15.5,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1F2329),
                      ),
                    ),
                    subtitle: const Padding(
                      padding: EdgeInsets.only(top: 4),
                      child: Text(
                        "This password is used for payments and transfers",
                        style: TextStyle(
                          fontSize: 12.5,
                          color: Color(0xFF86909C),
                        ),
                      ),
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          hasPin ? "Change" : "Set",
                          style: const TextStyle(
                            color: Color(0xFF86909C),
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(width: 2),
                        const Icon(Icons.chevron_right_rounded,
                            color: Color(0xFF86909C), size: 22),
                      ],
                    ),
                    onTap: () =>
                        _openSetPasswordScreen(context, isSecurity: true),
                  ),
                  const Divider(height: 1, indent: 16, color: Color(0xFFF2F3F5)),
                  ListTile(
                    contentPadding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    title: const Text(
                      "Mail",
                      style: TextStyle(
                        fontSize: 15.5,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1F2329),
                      ),
                    ),
                    subtitle: Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        _maskEmail(boundMail),
                        style: const TextStyle(
                          fontSize: 12.5,
                          color: Color(0xFF86909C),
                        ),
                      ),
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          boundMail.isNotEmpty ? "Reset" : "Bind",
                          style: const TextStyle(
                            color: Color(0xFF86909C),
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(width: 2),
                        const Icon(Icons.chevron_right_rounded,
                            color: Color(0xFF86909C), size: 22),
                      ],
                    ),
                    onTap: () => _openMailBottomSheet(context, boundMail),
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
// SET PASSWORD FULL SCREEN (2 Rounded Inputs + Teal Pill "Set" Button)
// ============================================================================
class _SetPasswordPage extends StatefulWidget {
  final bool isSecurityPassword;
  final Future<void> Function(String key, dynamic val) onSaveField;
  final void Function(String msg) onToast;

  const _SetPasswordPage({
    required this.isSecurityPassword,
    required this.onSaveField,
    required this.onToast,
  });

@override
  State<_SetPasswordPage> createState() => _SetPasswordPageState();
}

class _SetPasswordPageState extends State<_SetPasswordPage> {
  final TextEditingController _pass1Ctrl = TextEditingController();
  final TextEditingController _pass2Ctrl = TextEditingController();
  bool _saving = false;

  @override
  void dispose() {
    _pass1Ctrl.dispose();
    _pass2Ctrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final p1 = _pass1Ctrl.text.trim();
    final p2 = _pass2Ctrl.text.trim();

    if (p1.length < 6) {
      widget.onToast("Password must be at least 6 characters.");
      return;
    }
    if (p1 != p2) {
      widget.onToast("Both passwords must match.");
      return;
    }

    setState(() => _saving = true);
    try {
      if (widget.isSecurityPassword) {
        await widget.onSaveField('paymentPin', p1);
        widget.onToast("Security password saved successfully.");
        if (mounted) Navigator.pop(context);
      } else {
        final user = FirebaseAuth.instance.currentUser;
        try {
          if (user != null) {
            await user.updatePassword(p1);
          }
          await widget.onSaveField('hasPassword', true);
          widget.onToast("Account password set successfully.");
          if (mounted) Navigator.pop(context);
        } catch (_) {
          await widget.onSaveField('hasPassword', true);
          if (user?.email != null && user!.email!.isNotEmpty) {
            await FirebaseAuth.instance
                .sendPasswordResetEmail(email: user.email!);
            widget.onToast("Verification link sent to ${user.email}");
          } else {
            widget.onToast("Account password saved.");
          }
          if (mounted) Navigator.pop(context);
        }
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6F8),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF5F6F8),
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new,
              color: Color(0xFF1F2329), size: 19),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          widget.isSecurityPassword ? "Security Password" : "Set",
          style: const TextStyle(
              color: Color(0xFF1F2329),
              fontSize: 18,
              fontWeight: FontWeight.w700),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.fromLTRB(20, 22, 20, 20),
        child: Column(
          children: [
            Container(
              height: 52,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: const Color(0xFFEDEEF2),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Center(
                child: TextField(
                  controller: _pass1Ctrl,
                  obscureText: true,
                  keyboardType: widget.isSecurityPassword
                      ? TextInputType.number
                      : TextInputType.text,
                  decoration: const InputDecoration(
                    hintText: "Password",
                    hintStyle:
                        TextStyle(color: Color(0xFF86909C), fontSize: 15),
                    border: InputBorder.none,
                    isDense: true,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Container(
              height: 52,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: const Color(0xFFEDEEF2),

borderRadius: BorderRadius.circular(14),
              ),
              child: Center(
                child: TextField(
                  controller: _pass2Ctrl,
                  obscureText: true,
                  keyboardType: widget.isSecurityPassword
                      ? TextInputType.number
                      : TextInputType.text,
                  decoration: const InputDecoration(
                    hintText: "Password",
                    hintStyle:
                        TextStyle(color: Color(0xFF86909C), fontSize: 15),
                    border: InputBorder.none,
                    isDense: true,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 28),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1ED7B5),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(25)),
                ),
                onPressed: _saving ? null : _submit,
                child: const Text(
                  "Set",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
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
// BIND / RESET MAIL PAGE
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
    widget.onToast("Verification code: $code");
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6F8),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF5F6F8),
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new,
              color: Color(0xFF1F2329), size: 19),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "Reset Email",
          style: TextStyle(
              color: Color(0xFF1F2329),

fontSize: 18,
              fontWeight: FontWeight.w700),
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
                      hintText: "Enter new email address",
                      border: InputBorder.none,
                    ),
                  ),
                  const Divider(color: Color(0xFFF2F3F5)),
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
                            color: Color(0xFF1ED7B5),
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
              height: 50,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1ED7B5),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(25)),
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
                  "Confirm",
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
      backgroundColor: const Color(0xFFF5F6F8),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF5F6F8),
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new,
              color: Color(0xFF1F2329), size: 19),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "Message Settings",
          style: TextStyle(
              color: Color(0xFF1F2329),
              fontSize: 18,
              fontWeight: FontWeight.w700),
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
                title: const Text("Top Message Banner",
                    style: TextStyle(
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF1F2329))),
                activeColor: Colors.white,
                activeTrackColor: const Color(0xFF1ED7B5),
                value: _banner,
                onChanged: (v) {
                  setState(() => _banner = v);
                  widget.onSaveField('topMessageBanner', v);
                },
              ),
              const Divider(height: 1, indent: 16, color: Color(0xFFF2F3F5)),
              SwitchListTile(
                title: const Text("Sounds",
                    style: TextStyle(
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF1F2329))),
                activeColor: Colors.white,
                activeTrackColor: const Color(0xFF1ED7B5),
                value: _sounds,
                onChanged: (v) {
                  setState(() => _sounds = v);
                  widget.onSaveField('roomSounds', v);
                },
              ),
              const Divider(height: 1, indent: 16, color: Color(0xFFF2F3F5)),
              SwitchListTile(
                title: const Text("Vibration",
                    style: TextStyle(
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF1F2329))),
                activeColor: Colors.white,
                activeTrackColor: const Color(0xFF1ED7B5),
                value: _vibration,
                onChanged: (v) {
                  if (v) {
                    HapticFeedback.mediumImpact();
                  }
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
// 3. LANGUAGE SETTING PAGE (With Top-Right Teal "Save" Pill Button)
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
    "Filipino",
    "Burmese",
    "Amharic",
    "Nepali",
    "Japanese",
    "Francais",
    "Portugues",
    "Arabic",
  ];

  @override
  void initState() {
    super.initState();
    _selected = widget.currentLanguage;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6F8),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF5F6F8),
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new,
              color: Color(0xFF1F2329), size: 19),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "Language Setting",
          style: TextStyle(
              color: Color(0xFF1F2329),
              fontSize: 18,
              fontWeight: FontWeight.w700),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 14, top: 10, bottom: 10),
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1ED7B5),
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(horizontal: 18),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              onPressed: () async {
                await widget.onSaved(_selected);
                if (mounted) Navigator.pop(context);
              },
              child: const Text(
                "Save",
                style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700),
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
            separatorBuilder: (_, __) =>
                const Divider(height: 1, indent: 16, color: Color(0xFFF2F3F5)),
            itemBuilder: (_, i) {
              final lang = _languages[i].toString();
              final isSelected = _selected == lang;
              return ListTile(
                title: Text(
                  lang,
                  style: const TextStyle(
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF1F2329),
                  ),
                ),
                trailing: isSelected
                    ? const Icon(Icons.check_circle,
                        color: Color(0xFF1ED7B5), size: 22)
                    : const Icon(Icons.circle_outlined,
                        color: Color(0xFFE5E6EB), size: 22),
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
// 4. PRIVILEGE SETTINGS PAGE ("Mystery man on rank" + Privacy Toggles)
// ============================================================================
class _PrivilegeSettingsPage extends StatefulWidget {
  final bool initialMysteryMan;
  final bool initialHideOnline;
  final bool initialInvisibleEntry;
  final Future<void> Function(String key, dynamic val) onSaveField;

  const _PrivilegeSettingsPage({
    required this.initialMysteryMan,
    required this.initialHideOnline,
    required this.initialInvisibleEntry,
    required this.onSaveField,
  });

  @override
  State<_PrivilegeSettingsPage> createState() => _PrivilegeSettingsPageState();
}

class _PrivilegeSettingsPageState extends State<_PrivilegeSettingsPage> {
  late bool _mysteryMan;
  late bool _hideOnline;
  late bool _invisibleEntry;

@override
  void initState() {
    super.initState();
    _mysteryMan = widget.initialMysteryMan;
    _hideOnline = widget.initialHideOnline;
    _invisibleEntry = widget.initialInvisibleEntry;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6F8),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF5F6F8),
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new,
              color: Color(0xFF1F2329), size: 19),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "Privilege settings",
          style: TextStyle(
              color: Color(0xFF1F2329),
              fontSize: 18,
              fontWeight: FontWeight.w700),
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
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                title: const Text(
                  "Mystery man on rank",
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                    color: Color(0xFF1F2329),
                  ),
                ),
                subtitle: const Padding(
                  padding: EdgeInsets.only(top: 4),
                  child: Text(
                    'Displayed on the rank as a "Mystery Man"',
                    style: TextStyle(fontSize: 12, color: Color(0xFF86909C)),
                  ),
                ),
                activeColor: Colors.white,
                activeTrackColor: const Color(0xFF1ED7B5),
                value: _mysteryMan,
                onChanged: (v) {
                  setState(() => _mysteryMan = v);
                  widget.onSaveField('mysteryManOnRank', v);
                },
              ),
              const Divider(height: 1, indent: 16, color: Color(0xFFF2F3F5)),
              SwitchListTile(
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                title: const Text(
                  "Invisible Room Entry",
                  style: TextStyle(
                    fontWeight: FontWeight.w500,
                    fontSize: 15,
                    color: Color(0xFF1F2329),
                  ),
                ),
                subtitle: const Text(
                  "Enter voice rooms without entry banner",
                  style: TextStyle(fontSize: 12, color: Color(0xFF86909C)),
                ),
                activeColor: Colors.white,
                activeTrackColor: const Color(0xFF1ED7B5),
                value: _invisibleEntry,
                onChanged: (v) {
                  setState(() => _invisibleEntry = v);
                  widget.onSaveField('invisibleEntry', v);
                },
              ),
              const Divider(height: 1, indent: 16, color: Color(0xFFF2F3F5)),
              SwitchListTile(
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                title: const Text(
                  "Hide Online Status",
                  style: TextStyle(
                    fontWeight: FontWeight.w500,
                    fontSize: 15,
                    color: Color(0xFF1F2329),
                  ),
                ),
                subtitle: const Text(
                  "Appear offline to other users",

style: TextStyle(fontSize: 12, color: Color(0xFF86909C)),
                ),
                activeColor: Colors.white,
                activeTrackColor: const Color(0xFF1ED7B5),
                value: _hideOnline,
                onChanged: (v) {
                  setState(() => _hideOnline = v);
                  widget.onSaveField('hideOnlineStatus', v);
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
// 5. BLOCKED USERS PAGE ("Blocked" + Golden Heart Empty State + Unblock)
// ============================================================================
class _BlockedUsersPage extends StatelessWidget {
  final void Function(String msg) onToast;

  const _BlockedUsersPage({required this.onToast});

  void _showAddBlockDialog(BuildContext context, String uid) {
    final ctrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Text("Block User ID",
            style: TextStyle(fontWeight: FontWeight.bold)),
        content: TextField(
          controller: ctrl,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            hintText: "Enter numeric User ID",
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Cancel",
                style: TextStyle(color: Color(0xFF86909C))),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1ED7B5),
              foregroundColor: Colors.white,
              elevation: 0,
            ),
            onPressed: () async {
              final target = ctrl.text.trim();
              if (target.isEmpty) return;
              Navigator.pop(ctx);
              await FirebaseFirestore.instance
                  .collection('users')
                  .doc(uid)
                  .set({
                'blacklist': FieldValue.arrayUnion([target])
              }, SetOptions(merge: true));
              onToast("Blocked User ID: $target");
            },
            child: const Text("Block"),
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
      backgroundColor: const Color(0xFFF5F6F8),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF5F6F8),
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new,
              color: Color(0xFF1F2329), size: 19),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "Blocked",
          style: TextStyle(
              color: Color(0xFF1F2329),
              fontSize: 18,
              fontWeight: FontWeight.w700),
        ),
        actions: [
          if (uid.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.person_add_disabled_rounded,
                  color: Color(0xFF1F2329), size: 22),
              onPressed: () => _showAddBlockDialog(context, uid),
            ),
        ],
      ),
      body: uid.isEmpty
          ? const Center(
              child: Text("Have no Friends yet",
                  style: TextStyle(color: Color(0xFF86909C), fontSize: 14)),
            )
          : StreamBuilder(
              stream: FirebaseFirestore.instance

.collection('users')
                  .doc(uid)
                  .snapshots(),
              builder: (context, AsyncSnapshot snap) {
                final doc = snap.data as DocumentSnapshot?;
                final data = doc?.data() as Map? ?? {};
                final List blocked =
                    data['blacklist'] is List ? data['blacklist'] : [];

                if (blocked.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox(
                          width: 110,
                          height: 95,
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              const Icon(
                                Icons.favorite_rounded,
                                color: Color(0xFFF3C86A),
                                size: 88,
                              ),
                              Positioned(
                                right: 12,
                                bottom: 8,
                                child: Container(
                                  padding: const EdgeInsets.all(2),
                                  decoration: const BoxDecoration(
                                    color: Color(0xFFF5F6F8),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.favorite_rounded,
                                    color: Color(0xFFFBE3A3),
                                    size: 40,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          "Have no Friends yet",
                          style: TextStyle(
                            color: Color(0xFF86909C),
                            fontSize: 14.5,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 60),
                      ],
                    ),
                  );
                }

                return Padding(
                  padding: const EdgeInsets.all(16),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: ListView.separated(
                      shrinkWrap: true,
                      itemCount: blocked.length,
                      separatorBuilder: (_, __) => const Divider(
                          height: 1, indent: 16, color: Color(0xFFF2F3F5)),
                      itemBuilder: (_, i) {
                        final item = blocked[i].toString();
                        return ListTile(
                          leading: const CircleAvatar(
                            backgroundColor: Color(0xFFFFF3CD),
                            child: Icon(Icons.person_off_rounded,
                                color: Color(0xFFD97724), size: 20),
                          ),
                          title: Text(
                            "User ID: $item",
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF1F2329),
                            ),
                          ),
                          trailing: TextButton(

onPressed: () async {
                              await FirebaseFirestore.instance
                                  .collection('users')
                                  .doc(uid)
                                  .update({
                                'blacklist': FieldValue.arrayRemove([item])
                              });
                              onToast("Unblocked $item");
                            },
                            child: const Text(
                              "Unblock",
                              style: TextStyle(
                                color: Color(0xFF1ED7B5),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                );
              },
            ),
    );
  }
}

// ============================================================================
// 6. DELETE ACCOUNT PAGE
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
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .delete();
      await user.delete();
      if (mounted) {
        Navigator.of(context).popUntil((route) => route.isFirst);
      }
    } catch (e) {
      widget.onToast("Please sign in again before deleting account.");
    } finally {
      if (mounted) setState(() => _deleting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool canConfirm = _secondsLeft == 0 && _agreed && !_deleting;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F6F8),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF5F6F8),
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new,
              color: Color(0xFF1F2329), size: 19),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "Delete Account",
          style: TextStyle(
              color: Color(0xFF1F2329),
              fontSize: 18,
              fontWeight: FontWeight.w700),
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
                      Icon(Icons.warning_amber_rounded,

color: Color(0xFFE54D42), size: 26),
                      SizedBox(width: 8),
                      Text(
                        "Important Account Deletion Notice",
                        style: TextStyle(
                            fontSize: 15.5, fontWeight: FontWeight.bold),
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
              activeColor: const Color(0xFFE54D42),
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
                  backgroundColor:
                      canConfirm ? const Color(0xFFE54D42) : Colors.black26,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(25)),
                ),
                onPressed: canConfirm ? _executeDeletion : null,
                child: Text(
                  _secondsLeft > 0
                      ? "Confirm Deletion (${_secondsLeft}s)"
                      : "Confirm Deletion",
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.bold),
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
