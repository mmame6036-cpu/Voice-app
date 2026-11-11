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

  bool _pushNotifications = true;
  bool _roomSounds = true;
  bool _isProcessing = false;

  static const Color bgColor = Color(0xFFF5EFEB);
  static const Color cardBg = Colors.white;
  static const Color primaryBrown = Color(0xFF3E2723);
  static const Color accentGold = Color(0xFFD49B42);
  static const Color borderColor = Color(0xFFE2D6C5);
  static const Color buttonDark = Color(0xFF4A3528);

  @override
  void initState() {
    super.initState();
    _loadUserPreferences();
  }

  Future<void> _loadUserPreferences() async {
    if (_currentUser == null) return;
    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(_currentUser!.uid)
          .get();

      if (doc.exists && doc.data() != null) {
        final data = doc.data()!;
        if (mounted) {
          setState(() {
            _pushNotifications = data['pushNotifications'] ?? true;
            _roomSounds = data['roomSounds'] ?? true;
          });
        }
      }
    } catch (_) {}
  }

  Future<void> _updatePreference(String key, bool value) async {
    if (_currentUser == null) return;
    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(_currentUser!.uid)
          .set({key: value}, SetOptions(merge: true));
    } catch (_) {}
  }

  void _showToast(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: primaryBrown,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _showBindPhoneDialog(String currentPhone) {
    final phoneController = TextEditingController(text: currentPhone);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: bgColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          "Bind Phone Number",
          style: TextStyle(color: primaryBrown, fontSize: 16, fontWeight: FontWeight.bold),
        ),
        content: TextField(
          controller: phoneController,
          keyboardType: TextInputType.phone,
          style: const TextStyle(color: primaryBrown),
          decoration: InputDecoration(
            hintText: "Enter phone number (e.g. +251...)",
            hintStyle: const TextStyle(color: Colors.black38, fontSize: 12),
            filled: true,
            fillColor: cardBg,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: borderColor),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: borderColor),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Cancel", style: TextStyle(color: Colors.black54)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: buttonDark,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () async {

final newPhone = phoneController.text.trim();
              if (newPhone.isNotEmpty && _currentUser != null) {
                await FirebaseFirestore.instance
                    .collection('users')
                    .doc(_currentUser!.uid)
                    .set({'phoneNumber': newPhone}, SetOptions(merge: true));
                _showToast("Phone number linked successfully.");
              }
              if (mounted) Navigator.pop(ctx);
            },
            child: const Text("Save", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showPasswordResetDialog() {
    final email = _currentUser?.email ?? "";
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: bgColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          "Reset Login Password",
          style: TextStyle(color: primaryBrown, fontSize: 16, fontWeight: FontWeight.bold),
        ),
        content: Text(
          email.isNotEmpty
              ? "Send password reset link to $email?"
              : "No email bound to this account. Please update account email first.",
          style: const TextStyle(color: Colors.black87, fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Cancel", style: TextStyle(color: Colors.black54)),
          ),
          if (email.isNotEmpty)
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: buttonDark,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: () async {
                try {
                  await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
                  _showToast("Reset email sent to $email");
                } catch (e) {
                  _showToast("Failed to send reset email: $e");
                }
                if (mounted) Navigator.pop(ctx);
              },
              child: const Text("Send", style: TextStyle(color: Colors.white)),
            ),
        ],
      ),
    );
  }

  void _showPaymentPasswordDialog(bool hasPin) {
    final pinController = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: bgColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          hasPin ? "Change Payment PIN" : "Set Payment PIN",
          style: const TextStyle(color: primaryBrown, fontSize: 16, fontWeight: FontWeight.bold),
        ),
        content: TextField(
          controller: pinController,
          keyboardType: TextInputType.number,
          obscureText: true,
          maxLength: 6,
          style: const TextStyle(color: primaryBrown),
          decoration: InputDecoration(
            hintText: "Enter 6-digit numeric PIN",
            hintStyle: const TextStyle(color: Colors.black38, fontSize: 12),
            filled: true,
            fillColor: cardBg,
            counterText: "",
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: borderColor),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: borderColor),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Cancel", style: TextStyle(color: Colors.black54)),
          ),
          ElevatedButton(

style: ElevatedButton.styleFrom(
              backgroundColor: buttonDark,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () async {
              final pin = pinController.text.trim();
              if (pin.length == 6 && _currentUser != null) {
                await FirebaseFirestore.instance
                    .collection('users')
                    .doc(_currentUser!.uid)
                    .set({'paymentPin': pin}, SetOptions(merge: true));
                _showToast("Payment PIN saved successfully.");
                if (mounted) Navigator.pop(ctx);
              } else {
                _showToast("PIN must be exactly 6 digits.");
              }
            },
            child: const Text("Save", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showBlacklistModal() {
    if (_currentUser == null) return;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => Container(
        height: MediaQuery.of(context).size.height * 0.70,
        decoration: const BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 44,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.black26,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              "Blacklisted Users",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: primaryBrown),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: StreamBuilder<DocumentSnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('users')
                    .doc(_currentUser!.uid)
                    .snapshots(),
                builder: (context, snapshot) {
                  final data = (snapshot.hasData && snapshot.data!.exists)
                      ? snapshot.data!.data() as Map<String, dynamic>
                      : <String, dynamic>{};

                  final List blockedUsers = (data['blacklist'] as List?) ?? [];

                  if (blockedUsers.isEmpty) {
                    return const Center(
                      child: Text("No users in blacklist.", style: TextStyle(color: Colors.black45)),
                    );
                  }

                  return ListView.builder(
                    itemCount: blockedUsers.length,
                    itemBuilder: (context, index) {
                      final item = blockedUsers[index].toString();
                      return Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(
                          color: cardBg,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: borderColor),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text("User: $item", style: const TextStyle(color: primaryBrown, fontSize: 13)),
                            GestureDetector(
                              onTap: () async {

await FirebaseFirestore.instance
                                    .collection('users')
                                    .doc(_currentUser!.uid)
                                    .update({
                                  'blacklist': FieldValue.arrayRemove([item])
                                });
                                _showToast("User removed from blacklist.");
                              },
                              child: const Text("Unblock", style: TextStyle(color: Colors.redAccent, fontSize: 12, fontWeight: FontWeight.bold)),
                            ),
                          ],
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
    );
  }

  void _showAboutDialogCustom() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: bgColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          "About Nile Voice",
          style: TextStyle(color: primaryBrown, fontSize: 16, fontWeight: FontWeight.bold),
        ),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Nile Voice Live Streaming & Audio Rooms", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: primaryBrown)),
            SizedBox(height: 6),
            Text("Version: 1.0.4+build26", style: TextStyle(fontSize: 12, color: Colors.black54)),
            SizedBox(height: 6),
            Text("Engine: Agora RTC / Firebase Cloud", style: TextStyle(fontSize: 12, color: Colors.black54)),
          ],
        ),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: buttonDark),
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Close", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showPolicyDialog() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => Container(
        height: MediaQuery.of(context).size.height * 0.75,
        decoration: const BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 44,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.black26,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              "Privacy Policy & Terms of Service",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: primaryBrown),
            ),
            const SizedBox(height: 12),
            const Expanded(
              child: SingleChildScrollView(
                physics: BouncingScrollPhysics(),
                child: Text(
                  "1. User Conduct: All users must adhere to community standards. Harassment, abuse, or illegal broadcasts are prohibited.\n\n"
                  "2. Virtual Currency: Coins and Points are platform tokens subject to operational terms. Points conversion conforms to the standard 1 USD = 10,000 Points policy.\n\n"
                  "3. Account Integrity: Operating multiple fraudulent accounts or exploiting latency violates platform policies and leads to permanent suspension.\n\n"

"4. Data Privacy: User audio is processed in real time and is not stored permanently without explicit notice.",
                  style: TextStyle(fontSize: 12.5, color: Colors.black87, height: 1.4),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmLogout() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: bgColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text("Log Out", style: TextStyle(color: primaryBrown, fontWeight: FontWeight.bold)),
        content: const Text(
          "Are you sure you want to log out of your account?",
          style: TextStyle(color: Colors.black87, fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Cancel", style: TextStyle(color: Colors.black54)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () async {
              Navigator.pop(ctx);
              await FirebaseAuth.instance.signOut();
              if (mounted) {
                Navigator.of(context).popUntil((route) => route.isFirst);
              }
            },
            child: const Text("Log Out", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _confirmDeleteAccount() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: bgColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text("Delete Account", style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
        content: const Text(
          "This action is permanent and cannot be undone. All balances, points, and host records will be irreversibly erased.",
          style: TextStyle(color: Colors.black87, fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Cancel", style: TextStyle(color: Colors.black54)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () async {
              Navigator.pop(ctx);
              if (_currentUser != null) {
                setState(() => _isProcessing = true);
                try {
                  await FirebaseFirestore.instance
                      .collection('users')
                      .doc(_currentUser!.uid)
                      .delete();
                  await _currentUser!.delete();
                  if (mounted) {
                    Navigator.of(context).popUntil((route) => route.isFirst);
                  }
                } catch (e) {
                  _showToast("Account deletion failed. Re-authenticate and try again: $e");
                } finally {
                  if (mounted) setState(() => _isProcessing = false);
                }
              }
            },
            child: const Text("Delete", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final String uid = _currentUser?.uid ?? "";

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,

leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: primaryBrown, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "Settings",
          style: TextStyle(
            color: primaryBrown,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: uid.isNotEmpty
            ? FirebaseFirestore.instance.collection('users').doc(uid).snapshots()
            : null,
        builder: (context, snapshot) {
          final userData = (snapshot.hasData && snapshot.data!.exists)
              ? snapshot.data!.data() as Map<String, dynamic>
              : <String, dynamic>{};

          final String phone = userData['phoneNumber'] ?? "";
          final bool hasPin = (userData['paymentPin'] != null && userData['paymentPin'].toString().isNotEmpty);

          return SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSectionHeader("Account & Security"),
                _buildSettingsContainer([
                  _buildListTile(
                    icon: Icons.phone_android,
                    iconColor: accentGold,
                    title: "Bind Phone Number",
                    subtitle: "Protect your account",
                    trailingText: phone.isNotEmpty ? phone : "Not Linked",
                    onTap: () => _showBindPhoneDialog(phone),
                  ),
                  const Divider(height: 1, indent: 52, color: borderColor),
                  _buildListTile(
                    icon: Icons.lock_outline,
                    iconColor: primaryBrown,
                    title: "Login Password",
                    subtitle: "Set account password",
                    trailingText: "",
                    onTap: _showPasswordResetDialog,
                  ),
                  const Divider(height: 1, indent: 52, color: borderColor),
                  _buildListTile(
                    icon: Icons.security,
                    iconColor: accentGold,
                    title: "Payment Password",
                    subtitle: "Protect coin transactions",
                    trailingText: hasPin ? "Enabled" : "Not Set",
                    onTap: () => _showPaymentPasswordDialog(hasPin),
                  ),
                  const Divider(height: 1, indent: 52, color: borderColor),
                  _buildListTile(
                    icon: Icons.block,
                    iconColor: Colors.redAccent,
                    title: "Blacklist",
                    subtitle: "Manage blocked users",
                    trailingText: "",
                    onTap: _showBlacklistModal,
                  ),
                ]),

                const SizedBox(height: 20),

                _buildSectionHeader("Notifications & Audio"),
                _buildSettingsContainer([
                  SwitchListTile(
                    secondary: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: bgColor,
                        shape: BoxShape.circle,
                        border: Border.all(color: borderColor),
                      ),
                      child: const Icon(Icons.notifications_none, color: primaryBrown, size: 20),
                    ),
                    title: const Text(
                      "Push Notifications",
                      style: TextStyle(color: primaryBrown, fontSize: 13.5, fontWeight: FontWeight.bold),

),
                    subtitle: const Text(
                      "Messages, room invites and gifts",
                      style: TextStyle(color: Colors.black45, fontSize: 11),
                    ),
                    activeColor: buttonDark,
                    value: _pushNotifications,
                    onChanged: (val) {
                      setState(() => _pushNotifications = val);
                      _updatePreference('pushNotifications', val);
                    },
                  ),
                  const Divider(height: 1, indent: 52, color: borderColor),
                  SwitchListTile(
                    secondary: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: bgColor,
                        shape: BoxShape.circle,
                        border: Border.all(color: borderColor),
                      ),
                      child: const Icon(Icons.volume_up_outlined, color: primaryBrown, size: 20),
                    ),
                    title: const Text(
                      "Room Sound Effects",
                      style: TextStyle(color: primaryBrown, fontSize: 13.5, fontWeight: FontWeight.bold),
                    ),
                    subtitle: const Text(
                      "In-room gift and combo sounds",
                      style: TextStyle(color: Colors.black45, fontSize: 11),
                    ),
                    activeColor: buttonDark,
                    value: _roomSounds,
                    onChanged: (val) {
                      setState(() => _roomSounds = val);
                      _updatePreference('roomSounds', val);
                    },
                  ),
                ]),

                const SizedBox(height: 20),

                _buildSectionHeader("General"),
                _buildSettingsContainer([
                  _buildListTile(
                    icon: Icons.cleaning_services_outlined,
                    iconColor: accentGold,
                    title: "Clear Cache",
                    subtitle: "Free up storage space",
                    trailingText: "0.0 MB",
                    onTap: () => _showToast("Cache cleaned successfully."),
                  ),
                  const Divider(height: 1, indent: 52, color: borderColor),
                  _buildListTile(
                    icon: Icons.info_outline,
                    iconColor: primaryBrown,
                    title: "About Us",
                    subtitle: "Version info & build details",
                    trailingText: "v1.0.4",
                    onTap: _showAboutDialogCustom,
                  ),
                  const Divider(height: 1, indent: 52, color: borderColor),
                  _buildListTile(
                    icon: Icons.description_outlined,
                    iconColor: accentGold,
                    title: "Privacy Policy & Terms",
                    subtitle: "Legal agreements and rules",
                    trailingText: "",
                    onTap: _showPolicyDialog,
                  ),
                ]),

                const SizedBox(height: 28),

                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: cardBg,
                      foregroundColor: Colors.redAccent,
                      elevation: 0,
                      side: const BorderSide(color: Colors.redAccent, width: 1.2),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    onPressed: _confirmLogout,
                    child: const Text(
                      "Log Out",
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),

const SizedBox(height: 14),

                Center(
                  child: TextButton(
                    onPressed: _isProcessing ? null : _confirmDeleteAccount,
                    child: _isProcessing
                        ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                        : const Text(
                            "Delete Account",
                            style: TextStyle(color: Colors.black38, fontSize: 12),
                          ),
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 12.5,
          fontWeight: FontWeight.bold,
          color: primaryBrown,
        ),
      ),
    );
  }

  Widget _buildSettingsContainer(List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
      ),
      child: Column(children: children),
    );
  }

  Widget _buildListTile({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required String trailingText,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: bgColor,
          shape: BoxShape.circle,
          border: Border.all(color: borderColor),
        ),
        child: Icon(icon, color: iconColor, size: 20),
      ),
      title: Text(
        title,
        style: const TextStyle(color: primaryBrown, fontSize: 13.5, fontWeight: FontWeight.bold),
      ),
      subtitle: Text(
        subtitle,
        style: const TextStyle(color: Colors.black45, fontSize: 11),
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (trailingText.isNotEmpty)
            Text(trailingText, style: const TextStyle(color: Colors.black54, fontSize: 11.5)),
          const SizedBox(width: 4),
          const Icon(Icons.arrow_forward_ios, size: 12, color: Colors.black38),
        ],
      ),
      onTap: onTap,
    );
  }
}
