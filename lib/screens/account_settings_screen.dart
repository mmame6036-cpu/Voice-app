import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AccountSettingsScreen extends StatefulWidget {
  final String currentName;
  final String? currentAvatarUrl;
  final int numericId;

  const AccountSettingsScreen({
    super.key,
    required this.currentName,
    this.currentAvatarUrl,
    required this.numericId,
  });

  @override
  State<AccountSettingsScreen> createState() => _AccountSettingsScreenState();
}

class _AccountSettingsScreenState extends State<AccountSettingsScreen> {
  final User? _user = FirebaseAuth.instance.currentUser;
  late TextEditingController _nameController;
  String? _avatarUrl;
  bool _isBusy = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.currentName);
    _avatarUrl = widget.currentAvatarUrl;
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _pickAndUploadAvatar() async {
    final user = _user;
    if (user == null) return;

    try {
      final picker = ImagePicker();
      final XFile? picked = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 80,
      );
      if (picked == null) return;

      setState(() => _isBusy = true);

      final storageRef = FirebaseStorage.instance
          .ref()
          .child('avatars')
          .child('${user.uid}.jpg');

      await storageRef.putFile(File(picked.path));
      final String downloadUrl = await storageRef.getDownloadURL();

      await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
        'avatarUrl': downloadUrl,
      }, SetOptions(merge: true));

      await user.updatePhotoURL(downloadUrl);

      if (mounted) {
        setState(() {
          _avatarUrl = downloadUrl;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            backgroundColor: Color(0xFF107C41),
            content: Text("የፕሮፋይል ፎቶዎ ተቀይሯል!"),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("ፎቶ መጫን አልተቻለም: $e")),
        );
      }
    } finally {
      if (mounted) setState(() => _isBusy = false);
    }
  }

  Future<void> _saveDisplayName() async {
    final user = _user;
    if (user == null) return;
    final newName = _nameController.text.trim();
    if (newName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("እባክዎ ስም ያስገቡ!")),
      );
      return;
    }

    setState(() => _isBusy = true);
    try {
      await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
        'name': newName,
        'nickname': newName,
      }, SetOptions(merge: true));

      await user.updateDisplayName(newName);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            backgroundColor: Color(0xFF107C41),
            content: Text("ስምዎ በትክክል ተቀይሯል!"),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("ስህተት: $e")),
        );
      }
    } finally {
      if (mounted) setState(() => _isBusy = false);
    }
  }

  Future<void> _signOut() async {
    setState(() => _isBusy = true);
    try {
      try {
        await GoogleSignIn().signOut();
      } catch (_) {}
      await FirebaseAuth.instance.signOut();
      if (mounted) {

Navigator.of(context).popUntil((route) => route.isFirst);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isBusy = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("መውጣት አልተቻለም: $e")),
        );
      }
    }
  }

  void _confirmDeleteAccount() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.redAccent),
            SizedBox(width: 8),
            Text(
              "Delete Account",
              style: TextStyle(
                color: Color(0xFF1D2129),
                fontWeight: FontWeight.bold,
                fontSize: 17,
              ),
            ),
          ],
        ),
        content: const Text(
          "አካውንትዎን ሲሰርዙ ያለዎት ሳንቲም (Coins)፣ ነጥብ (Points) እና የፕሮፋይል መረጃዎ በሙሉ ለዘላለም ይጠፋሉ። እርግጠኛ ነዎት?",
          style: TextStyle(color: Color(0xFF4E5969), fontSize: 13.5, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Cancel", style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              Navigator.pop(ctx);
              await _executeAccountDeletion();
            },
            child: const Text(
              "Delete Permanently",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _executeAccountDeletion() async {
    final user = _user;
    if (user == null) return;

    setState(() => _isBusy = true);
    try {
      final uid = user.uid;

      try {
        await FirebaseStorage.instance
            .ref()
            .child('avatars')
            .child('$uid.jpg')
            .delete();
      } catch (_) {}

      await FirebaseFirestore.instance.collection('users').doc(uid).delete();

      await user.delete();

      try {
        await GoogleSignIn().signOut();
      } catch (_) {}

      if (mounted) {
        Navigator.of(context).popUntil((route) => route.isFirst);
      }
    } on FirebaseAuthException catch (e) {
      if (mounted) {
        setState(() => _isBusy = false);
        String msg = "አካውንቱን መሰረዝ አልተቻለም: ${e.message}";
        if (e.code == 'requires-recent-login') {
          msg =
              "ለደህንነት ሲባል መጀመሪያ Sign Out አድርገው እንደገና ከገቡ በኋላ Delete Account ይጫኑ።";
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: Colors.redAccent,
            duration: const Duration(seconds: 5),
            content: Text(msg),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isBusy = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("ስህተት: $e")),
        );
      }
    }
  }

  void _showPrivacyPolicyDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Text(
          "NILE Live Privacy Policy",
          style: TextStyle(
            color: Color(0xFF1D2129),
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        content: const SingleChildScrollView(
          child: Text(
            "1. Information We Collect:\n"
            "NILE Live collects your display name, profile photo, user ID, and authentication identifier to provide voice chat rooms and social features.\n\n"

"2. Microphone & Audio:\n"
            "Microphone permission is used exclusively when you take a speaker seat in a live voice room.\n\n"
            "3. Virtual Coins & Points:\n"
            "Virtual items, coins, and host points are managed securely within your account.\n\n"
            "4. Account Deletion:\n"
            "You may permanently delete your account and associated personal data at any time from Account Settings -> Delete Account.",
            style: TextStyle(
              color: Color(0xFF4E5969),
              fontSize: 12.5,
              height: 1.45,
            ),
          ),
        ),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF3E2723),
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Close"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    ImageProvider? avatarImg;
    if (_avatarUrl != null) {
      if (_avatarUrl!.isNotEmpty) {
        avatarImg = NetworkImage(_avatarUrl!);
      }
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF6F8FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new,
              color: Color(0xFF1D2129), size: 18),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "Profile & Account Settings",
          style: TextStyle(
            color: Color(0xFF1D2129),
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // 1. Avatar & Name Card
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Column(
                    children: [
                      GestureDetector(
                        onTap: _isBusy ? null : _pickAndUploadAvatar,
                        child: Stack(
                          children: [
                            CircleAvatar(
                              radius: 44,
                              backgroundColor: const Color(0xFFF2F3F5),
                              backgroundImage: avatarImg,
                              child: avatarImg == null
                                  ? const Icon(Icons.person,
                                      size: 44, color: Color(0xFFC7CBD1))
                                  : null,
                            ),
                            Positioned(
                              bottom: 0,
                              right: 0,
                              child: Container(
                                padding: const EdgeInsets.all(6),
                                decoration: const BoxDecoration(
                                  color: Color(0xFFF3BA2F),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.camera_alt,
                                    size: 16, color: Colors.black),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),

Text(
                        "ID: ${widget.numericId}",
                        style: const TextStyle(
                          color: Color(0xFF86909C),
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: _nameController,
                        style: const TextStyle(
                          color: Color(0xFF1D2129),
                          fontWeight: FontWeight.bold,
                        ),
                        decoration: InputDecoration(
                          labelText: "Display Name (ስም)",
                          filled: true,
                          fillColor: const Color(0xFFF6F8FA),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),
                      SizedBox(
                        width: double.infinity,
                        height: 46,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF3E2723),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          onPressed: _isBusy ? null : _saveDisplayName,
                          child: const Text(
                            "Save Profile Changes",
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // 2. Legal & Security Actions Card
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Column(
                    children: [
                      ListTile(
                        leading: const Icon(Icons.privacy_tip_outlined,
                            color: Color(0xFF1890FF)),
                        title: const Text(
                          "Privacy Policy",
                          style: TextStyle(
                            color: Color(0xFF1D2129),
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                        trailing: const Icon(Icons.chevron_right,
                            color: Color(0xFFC9CDD4)),
                        onTap: _showPrivacyPolicyDialog,
                      ),
                      const Divider(height: 1, color: Color(0xFFF2F3F5)),
                      ListTile(
                        leading: const Icon(Icons.logout,
                            color: Color(0xFFFF7A45)),
                        title: const Text(
                          "Sign Out (ውጣ)",
                          style: TextStyle(
                            color: Color(0xFF1D2129),
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                        trailing: const Icon(Icons.chevron_right,
                            color: Color(0xFFC9CDD4)),

onTap: _isBusy ? null : _signOut,
                      ),
                      const Divider(height: 1, color: Color(0xFFF2F3F5)),
                      ListTile(
                        leading: const Icon(Icons.delete_forever,
                            color: Colors.redAccent),
                        title: const Text(
                          "Delete Account (አካውንት ሰርዝ)",
                          style: TextStyle(
                            color: Colors.redAccent,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                        subtitle: const Text(
                          "Permanently delete your account & data",
                          style: TextStyle(fontSize: 11, color: Colors.grey),
                        ),
                        trailing: const Icon(Icons.chevron_right,
                            color: Colors.redAccent),
                        onTap: _isBusy ? null : _confirmDeleteAccount,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          if (_isBusy)
            Container(
              color: Colors.black38,
              child: const Center(
                child: CircularProgressIndicator(color: Color(0xFFF3BA2F)),
              ),
            ),
        ],
      ),
    );
  }
}
