import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// እውነተኛ ገጾች ማያያዣዎች
import 'store_screen.dart';
import 'invitation_screen.dart';
import 'backpack_screen.dart';
import 'level_screen.dart';
import 'task_screen.dart';
import 'badge_screen.dart';
import 'host_center_screen.dart';
import 'agency_screen.dart';
import 'coin_seller_screen.dart';
import 'support_screen.dart';
import 'settings_screen.dart';
import '../widgets/lucky_island_dialog.dart';

class ProfileScreen extends StatefulWidget {
  final int currentCoins;
  final Function(int)? onCoinsUpdated;

  const ProfileScreen({
    super.key,
    this.currentCoins = 0,
    this.onCoinsUpdated,
  });

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  // ቋሚ መለያ ቁጥር
  final String _userId = "1000";
  String _userName = "User Name";
  late int _coins;

  // ቀለማት፡ ወርቃማ እና ኤመራልድ አረንጓዴ
  static const Color goldColor = Color(0xFFFFD700);
  static const Color emeraldColor = Color(0xFF00E676);

  @override
  void initState() {
    super.initState();
    _coins = widget.currentCoins;
  }

  void _updateCoins(int newAmount) {
    setState(() => _coins = newAmount);
    widget.onCoinsUpdated?.call(newAmount);
  }

  void _copyId() {
    Clipboard.setData(ClipboardData(text: _userId));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("ID 1000 Copied to clipboard"),
        duration: Duration(seconds: 1),
      ),
    );
  }

  void _openLuckyIsland() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const LuckyIslandDialog(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0E17),
      appBar: AppBar(
        backgroundColor: const Color(0xFF171524),
        elevation: 0,
        title: const Text(
          "Me",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined, color: Colors.white70),
            onPressed: () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => SettingsScreen()));
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Column(
          children: [
            // 1. የፕሮፋይል ራስጌ (ምንም ውጫዊ ምስል የሌለው ንጹህ አቀማመጥ + ቋሚ ID 1000)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF1E1B2E),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white10),
              ),
              child: Row(
                children: [
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.06),
                      shape: BoxShape.circle,
                      border: Border.all(color: emeraldColor, width: 1.5),
                    ),
                    child: const Center(
                      child: Icon(Icons.person, color: Colors.white38, size: 36),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _userName,
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),

),
                        const SizedBox(height: 6),
                        GestureDetector(
                          onTap: _copyId,
                          child: Row(
                            children: [
                              Text(
                                "ID: $_userId",
                                style: const TextStyle(fontSize: 13, color: Colors.white70, fontWeight: FontWeight.w600),
                              ),
                              const SizedBox(width: 6),
                              const Icon(Icons.copy, size: 13, color: emeraldColor),
                            ],
                          ),
                        ),
                        const SizedBox(height: 6),
                        GestureDetector(
                          onTap: () {
                            Navigator.push(context, MaterialPageRoute(builder: (_) => const LevelScreen()));
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: goldColor.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: goldColor.withOpacity(0.5)),
                            ),
                            child: const Text(
                              "Lv.0 >",
                              style: TextStyle(color: goldColor, fontSize: 10, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 12),

            // 2. የዋሌት እና ሳንቲም ባነር
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF2E2210), Color(0xFF1E1B2E)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: goldColor.withOpacity(0.3)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.monetization_on, color: goldColor, size: 28),
                      const SizedBox(width: 8),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text("Coins Balance", style: TextStyle(color: Colors.white54, fontSize: 11)),
                          Text(
                            "🪙 $_coins",
                            style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ],
                  ),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: goldColor,
                      foregroundColor: Colors.black,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      elevation: 0,
                    ),
                    onPressed: () {
                      Navigator.push(context, MaterialPageRoute(builder: (_) => const CoinSellerScreen()));
                    },
                    child: const Text("Recharge", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                  ),
                ],
              ),
            ),

const SizedBox(height: 16),

            // 3. Entertainment & Assets (Store, Backpack, Invitation, Lucky Island)
            _buildSectionCard(
              "Entertainment & Assets",
              [
                _buildGridItem(Icons.storefront, "Store", goldColor, () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => StoreScreen(
                        userCoins: _coins,
                        onCoinsDeducted: _updateCoins,
                      ),
                    ),
                  );
                }),
                _buildGridItem(Icons.backpack_outlined, "Backpack", goldColor, () {
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const BackpackScreen()));
                }),
                _buildGridItem(Icons.mail_outline, "Invitation", emeraldColor, () {
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const InvitationScreen()));
                }),
                _buildGridItem(Icons.sailing, "Lucky Island", emeraldColor, _openLuckyIsland),
              ],
            ),

            const SizedBox(height: 14),

            // 4. Growth & Honor (Level, Task, Badge, Support)
            _buildSectionCard(
              "Growth & Honor",
              [
                _buildGridItem(Icons.military_tech_outlined, "Level", goldColor, () {
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const LevelScreen()));
                }),
                _buildGridItem(Icons.assignment_outlined, "Task Center", goldColor, () {
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const TaskScreen()));
                }),
                _buildGridItem(Icons.shield_outlined, "Badges", emeraldColor, () {
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const BadgeScreen()));
                }),
                _buildGridItem(Icons.headset_mic_outlined, "Support", emeraldColor, () {
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const SupportScreen()));
                }),
              ],
            ),

            const SizedBox(height: 14),

            // 5. Creator & Business (Host Center, Agency, Coin Seller, Settings)
            _buildSectionCard(
              "Creator & Business",
              [
                _buildGridItem(Icons.mic_none, "Host Center", goldColor, () {
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const HostCenterScreen()));
                }),
                _buildGridItem(Icons.domain, "Agency", goldColor, () {
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const AgencyScreen()));
                }),
                _buildGridItem(Icons.point_of_sale, "Coin Seller", emeraldColor, () {
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const CoinSellerScreen()));
                }),
                _buildGridItem(Icons.settings_suggest_outlined, "Settings", emeraldColor, () {
                  Navigator.push(context, MaterialPageRoute(builder: (_) => SettingsScreen()));
                }),
              ],
            ),

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionCard(String title, List<Widget> items) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1B2E),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(

padding: const EdgeInsets.only(left: 6, bottom: 12),
            child: Text(
              title,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.white54),
            ),
          ),
          GridView.count(
            crossAxisCount: 4,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 12,
            crossAxisSpacing: 8,
            childAspectRatio: 0.9,
            children: items,
          ),
        ],
      ),
    );
  }

  Widget _buildGridItem(IconData icon, String label, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              shape: BoxShape.circle,
              border: Border.all(color: color.withOpacity(0.25), width: 1),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: Colors.white),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
