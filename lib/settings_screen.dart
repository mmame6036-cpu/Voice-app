import 'package:flutter/material.dart';
import 'services/user_service.dart';
import 'wallet_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final UserService _user = UserService();
  double _cacheSizeMB = 78.32;

  void _clearCache() {
    setState(() => _cacheSizeMB = 0.0);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Cache cleared successfully!'),
        backgroundColor: Color(0xFF00C9A7),
      ),
    );
  }

  void _confirmSignOut() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Sign out', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        content: const Text('Are you sure you want to sign out?', style: TextStyle(color: Colors.black87)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
            },
            child: const Text('Sign out', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Settings',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 18),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        children: [
          // Section 1: Wallet, Account, Language, Privacy, Blocklist
          _buildGroupCard([
            _buildTile(
              title: 'Wallet & Top-up',
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.monetization_on, color: Colors.amber, size: 16),
                  const SizedBox(width: 4),
                  Text(
                    '${_user.coins}',
                    style: const TextStyle(color: Colors.black87, fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                ],
              ),
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const WalletScreen())),
            ),
            const Divider(height: 1, indent: 16, endIndent: 16),
            _buildTile(
              title: 'Account Management',
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AccountManagementScreen())),
            ),
            const Divider(height: 1, indent: 16, endIndent: 16),
            _buildTile(
              title: 'Language',
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const LanguageScreen())),
            ),
            const Divider(height: 1, indent: 16, endIndent: 16),

_buildTile(
              title: 'Privacy',
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Privacy settings are default.')));
              },
            ),
            const Divider(height: 1, indent: 16, endIndent: 16),
            _buildTile(
              title: 'Blocklist',
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const BlocklistScreen())),
            ),
          ]),
          const SizedBox(height: 14),

          // Section 2: Clear cache & About
          _buildGroupCard([
            _buildTile(
              title: 'Clear cache',
              trailing: Text(
                _cacheSizeMB > 0 ? '${_cacheSizeMB.toStringAsFixed(2)}MB' : '0.00MB',
                style: const TextStyle(color: Colors.black54, fontSize: 14),
              ),
              onTap: _clearCache,
            ),
            const Divider(height: 1, indent: 16, endIndent: 16),
            _buildTile(
              title: 'About',
              onTap: () {
                showAboutDialog(
                  context: context,
                  applicationName: 'Nile Voice',
                  applicationVersion: '1.0.0',
                  applicationLegalese: '© 2026 Nile Voice Team',
                );
              },
            ),
          ]),
          const SizedBox(height: 14),

          // Section 3: Sign out
          _buildGroupCard([
            ListTile(
              title: const Text(
                'Sign out',
                style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.w600, fontSize: 15),
              ),
              onTap: _confirmSignOut,
            ),
          ]),
        ],
      ),
    );
  }

  Widget _buildGroupCard(List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(children: children),
    );
  }

  Widget _buildTile({required String title, Widget? trailing, VoidCallback? onTap}) {
    return ListTile(
      title: Text(title, style: const TextStyle(color: Colors.black87, fontSize: 15, fontWeight: FontWeight.w500)),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (trailing != null) trailing,
          const SizedBox(width: 6),
          const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.black26),
        ],
      ),
      onTap: onTap,
    );
  }
}

// ----------------------------------------------------
// 1. Account Management Screen
// ----------------------------------------------------
class AccountManagementScreen extends StatelessWidget {
  const AccountManagementScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Account Manager', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 18)),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        children: [
          Center(
            child: Column(
              children: [
                const SizedBox(height: 16),
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const LinearGradient(colors: [Color(0xFF6C5CE7), Color(0xFFA29BFE)]),

boxShadow: [
                      BoxShadow(color: const Color(0xFF6C5CE7).withOpacity(0.3), blurRadius: 16, spreadRadius: 2),
                    ],
                  ),
                  child: const Icon(Icons.shield_outlined, color: Colors.white, size: 42),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Your account security is protected.',
                  style: TextStyle(color: Colors.black45, fontSize: 13),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
          Container(
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
            child: Column(
              children: [
                _buildActionTile(context, 'Change Email'),
                const Divider(height: 1, indent: 16, endIndent: 16),
                _buildActionTile(context, 'Account Password'),
                const Divider(height: 1, indent: 16, endIndent: 16),
                _buildActionTile(context, 'Security Password'),
                const Divider(height: 1, indent: 16, endIndent: 16),
                _buildActionTile(context, 'Link Account'),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Container(
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
            child: ListTile(
              title: const Text('Delete account', style: TextStyle(color: Colors.redAccent, fontSize: 15, fontWeight: FontWeight.w600)),
              trailing: const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.black26),
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const DeleteAccountScreen())),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionTile(BuildContext context, String title) {
    return ListTile(
      title: Text(title, style: const TextStyle(color: Colors.black87, fontSize: 15, fontWeight: FontWeight.w500)),
      trailing: const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.black26),
      onTap: () {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$title screen is ready.')));
      },
    );
  }
}

// ----------------------------------------------------
// 2. Language Screen
// ----------------------------------------------------
class LanguageScreen extends StatefulWidget {
  const LanguageScreen({Key? key}) : super(key: key);

  @override
  State<LanguageScreen> createState() => _LanguageScreenState();
}

class _LanguageScreenState extends State<LanguageScreen> {
  String _selectedLang = 'English';

  final List<String> _languages = [
    'Follow system',
    'English',
    'Chinese',
    'Arabic',
    'Amharic',
    'Spanish',
    'French',
    'Myanmar',
    'Nepali',
    'Portuguese',
    'Russian',
    'Turkish',
    'Vietnamese',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Language', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 18)),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Language saved: $_selectedLang'), backgroundColor: const Color(0xFF6C5CE7)),
              );
            },

child: const Text('Save', style: TextStyle(color: Color(0xFF6C5CE7), fontWeight: FontWeight.bold, fontSize: 16)),
          ),
        ],
      ),
      body: ListView.separated(
        itemCount: _languages.length,
        separatorBuilder: (_, __) => const Divider(height: 1, indent: 16, endIndent: 16),
        itemBuilder: (ctx, i) {
          final lang = _languages[i];
          final isChosen = _selectedLang == lang;
          return ListTile(
            title: Text(lang, style: TextStyle(color: isChosen ? const Color(0xFF6C5CE7) : Colors.black87, fontWeight: isChosen ? FontWeight.bold : FontWeight.normal)),
            trailing: isChosen ? const Icon(Icons.check, color: Color(0xFF6C5CE7)) : null,
            onTap: () => setState(() => _selectedLang = lang),
          );
        },
      ),
    );
  }
}

// ----------------------------------------------------
// 3. Blocklist Screen
// ----------------------------------------------------
class BlocklistScreen extends StatelessWidget {
  const BlocklistScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Blocklist', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 18)),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.person_off_outlined, color: Colors.grey, size: 54),
            ),
            const SizedBox(height: 16),
            const Text(
              'No blocked users',
              style: TextStyle(color: Colors.black45, fontSize: 14, fontWeight: FontWeight.w500),
            ),
          ],
        ),
      ),
    );
  }
}

// ----------------------------------------------------
// 4. Delete Account Details Screen
// ----------------------------------------------------
class DeleteAccountScreen extends StatelessWidget {
  const DeleteAccountScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Delete Account', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 18)),
      ),
      body: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
              child: const Text('You have no pending account deletion request.', style: TextStyle(color: Colors.black54, fontSize: 13)),
            ),
            const SizedBox(height: 20),
            const Text('Account Asset Cleared', style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold, fontSize: 15)),
            const SizedBox(height: 4),

const Text('All information on Nile Voice will be cleared, including profile and transaction history.', style: TextStyle(color: Colors.black45, fontSize: 13)),
            const SizedBox(height: 16),
            const Text('Pre-Cancellation Period', style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold, fontSize: 15)),
            const SizedBox(height: 4),
            const Text('You can log in within 30 days to cancel this deletion request.', style: TextStyle(color: Colors.black45, fontSize: 13)),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              height: 46,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF6C5CE7), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24))),
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ),
            const SizedBox(height: 10),
            Center(
              child: TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
                },
                child: const Text('Continue to Delete', style: TextStyle(color: Colors.redAccent, fontSize: 14)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
