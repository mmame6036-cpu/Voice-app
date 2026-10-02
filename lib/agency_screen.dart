import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// ============================================================================
// 🏢 NILE VOICE - OFFICIAL AGENCY CENTER
// ============================================================================
class AgencyScreen extends StatefulWidget {
  final String agencyName;
  final String agencyId;

  const AgencyScreen({
    Key? key,
    this.agencyName = "Nile Agency Leader",
    this.agencyId = "789012",
  }) : super(key: key);

  @override
  State<AgencyScreen> createState() => _AgencyScreenState();
}

class _AgencyScreenState extends State<AgencyScreen> {
  // ተለዋዋጭ ዳታዎች (Dynamic Agency Data)
  double myIncomeToday = 0.0;
  double totalHostPoints30Days = 250000.0;
  double commissionRate = 4.0;
  double nextLevelPoints = 2000000.0;

  double hostPointsToday = 0.0;
  double hostPoints30Days = 12500.0;
  double subAgentPointsToday = 450.0;
  double subAgentPoints30Days = 210000.0;

  int totalHostsCount = 128;
  int subAgenciesCount = 18;

  void _copyAgencyId() {
    Clipboard.setData(ClipboardData(text: widget.agencyId));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('የኤጀንሲ መለያ ቁጥር (ID) ኮፒ ተደርጓል!'),
        backgroundColor: Color(0xFF00C9A7),
      ),
    );
  }

  void _showComingSoon(String feature) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$feature በቅርቡ ይለቀቃል!'),
        duration: const Duration(seconds: 1),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    double progressRatio = (totalHostPoints30Days / nextLevelPoints).clamp(0.0, 1.0);
    double neededForNextLevel = (nextLevelPoints - totalHostPoints30Days).clamp(0.0, nextLevelPoints);

    return Scaffold(
      backgroundColor: const Color(0xFFF2FBF9),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black87, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Agency Center',
          style: TextStyle(color: Colors.black87, fontSize: 18, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.help_outline, color: Colors.black54),
            onPressed: () => _showComingSoon('Agency Rules & Help'),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ================= 1. ኤጀንሲ ፕሮፋይል እና ቁልፎች =================
            Row(
              children: [
                CircleAvatar(
                  radius: 28,
                  backgroundColor: const Color(0xFF00C9A7),
                  child: const Icon(Icons.business_center, color: Colors.white, size: 30),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.agencyName,
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Text(
                            'ID: ${widget.agencyId}',
                            style: const TextStyle(fontSize: 13, color: Colors.black54),

),
                          const SizedBox(width: 6),
                          GestureDetector(
                            onTap: _copyAgencyId,
                            child: const Icon(Icons.copy, size: 15, color: Colors.black45),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.edit_outlined, color: Colors.black45),
                  onPressed: () => _showComingSoon('Edit Profile'),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Invite Buttons
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF00E1B0),
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
                      padding: const EdgeInsets.symmetric(vertical: 11),
                    ),
                    onPressed: () => _showComingSoon('Invite Host'),
                    child: const Text(
                      'Invite Host',
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF26B8FF),
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
                      padding: const EdgeInsets.symmetric(vertical: 11),
                    ),
                    onPressed: () => _showComingSoon('Invite Agency'),
                    child: const Text(
                      'Invite Agency',
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Agency Tag Link
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 8, offset: const Offset(0, 2)),
                ],
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                Text('Agency Tag', style: TextStyle(fontWeight: FontWeight.w600, color: Colors.black87, fontSize: 14)),
                  Icon(Icons.arrow_forward_ios, size: 14, color: Colors.black38),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // ================= 2. የገቢ እና የኮሚሽን ካርድ =================
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFE5FAF3),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFB5EAD7)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Text('My Income Today: ', style: TextStyle(color: Colors.black87, fontSize: 14, fontWeight: FontWeight.w500)),

const Icon(Icons.token, size: 16, color: Color(0xFF00C9A7)),
                      const SizedBox(width: 4),
                      Text('${myIncomeToday.toInt()}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      const Text('Total Host Points: ', style: TextStyle(color: Colors.black87, fontSize: 14, fontWeight: FontWeight.w500)),
                      const Icon(Icons.token, size: 16, color: Color(0xFF00C9A7)),
                      const SizedBox(width: 4),
                      Text('${totalHostPoints30Days.toInt()}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                    ],
                  ),
                  const Text('Past 30 Days', style: TextStyle(color: Colors.black45, fontSize: 11)),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      const Text('Commission Rate: ', style: TextStyle(color: Colors.black87, fontSize: 14, fontWeight: FontWeight.w500)),
                      const Icon(Icons.token, size: 16, color: Color(0xFF00C9A7)),
                      const SizedBox(width: 4),
                      Text('${commissionRate.toInt()}%', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                    ],
                  ),
                  const SizedBox(height: 14),

                  // Progress Box
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Text('Still need ', style: TextStyle(fontSize: 12, color: Colors.black87)),
                            const Icon(Icons.token, size: 14, color: Color(0xFF00C9A7)),
                            const SizedBox(width: 2),
                            Text(
                              '${neededForNextLevel.toInt()}',
                              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                            ),
                            const Text(
                              ' to reach next level 8%',
                              style: TextStyle(fontSize: 12, color: Colors.deepOrangeAccent, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child: LinearProgressIndicator(
                            value: progressRatio,
                            minHeight: 7,
                            backgroundColor: const Color(0xFFE0E0E0),
                            valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF00C9A7)),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.token, size: 13, color: Color(0xFF00C9A7)),
                                const SizedBox(width: 2),
                                Text('${totalHostPoints30Days.toInt()}', style: const TextStyle(fontSize: 11, color: Colors.black54)),

],
                            ),
                            Row(
                              children: [
                                const Icon(Icons.token, size: 13, color: Color(0xFF00C9A7)),
                                const SizedBox(width: 2),
                                Text('${nextLevelPoints.toInt()}', style: const TextStyle(fontSize: 11, color: Colors.black54)),
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

            const SizedBox(height: 18),

            // ================= 3. OVERVIEW CARDS =================
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 8, offset: const Offset(0, 2)),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Overview', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87)),
                  const SizedBox(height: 14),

                  // Row 1: Host Points
                  Row(
                    children: [
                      Expanded(
                        child: _buildMetricCard(
                          title: 'Host Points',
                          subtitle: 'Today',
                          value: '${hostPointsToday.toInt()}',
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _buildMetricCard(
                          title: 'My Hosts Points',
                          subtitle: 'Past 30 Days',
                          value: '${hostPoints30Days.toInt()}',
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),

                  // Row 2: Sub-agent Host Points
                  Row(
                    children: [
                      Expanded(
                        child: _buildMetricCard(
                          title: 'Sub-agent Host Points',
                          subtitle: 'Today',
                          value: subAgentPointsToday.toStringAsFixed(1),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _buildMetricCard(
                          title: 'Sub-agent Host Points',
                          subtitle: 'Past 30 Days',
                          value: '${subAgentPoints30Days.toInt()}',
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),

                  // Row 3: Count Navigation Cards
                  Row(
                    children: [
                      Expanded(
                        child: _buildNavCountCard(
                          title: 'Host Number',
                          count: '$totalHostsCount',
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _buildNavCountCard(
                          title: 'Sub-agency Number',
                          count: '$subAgenciesCount',
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 18),

// ================= 4. INCOME LIST TILES =================
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 8, offset: const Offset(0, 2)),
                ],
              ),
              child: Column(
                children: [
                  _buildListTileItem(icon: Icons.mic_none, title: 'Host Income'),
                  const Divider(height: 1, indent: 56, endIndent: 16),
                  _buildListTileItem(icon: Icons.attach_money, title: 'Sub-agency Income'),
                  const Divider(height: 1, indent: 56, endIndent: 16),
                  _buildListTileItem(icon: Icons.more_horiz, title: 'Other income'),
                ],
              ),
            ),

            const SizedBox(height: 18),

            // ================= 5. CONTACT ADMIN =================
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 8, offset: const Offset(0, 2)),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Contact Admin', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.black87)),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      const CircleAvatar(
                        radius: 20,
                        backgroundColor: Color(0xFF25D366),
                        child: Icon(Icons.chat_bubble, color: Colors.white, size: 20),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Support Team', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.black87)),
                            SizedBox(height: 2),
                            Text('Nile Voice Official Desk', style: TextStyle(fontSize: 12, color: Colors.black54)),
                          ],
                        ),
                      ),
                      OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Color(0xFF00C9A7)),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        ),
                        onPressed: () => _showComingSoon('Official Support'),
                        child: const Text('Contact', style: TextStyle(color: Color(0xFF00C9A7), fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  // የመለኪያ ካርዶች ንዑስ ዊጅት
  Widget _buildMetricCard({required String title, required String subtitle, required String value}) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFD8F6ED),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,

children: [
          Text(title, style: const TextStyle(fontSize: 12, color: Colors.black87, fontWeight: FontWeight.w600)),
          Text(subtitle, style: const TextStyle(fontSize: 10, color: Colors.black54)),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.token, size: 14, color: Color(0xFF00C9A7)),
              const SizedBox(width: 4),
              Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.black87)),
            ],
          ),
        ],
      ),
    );
  }

  // የቁጥር ማሳያና ማዘዋወሪያ ካርድ
  Widget _buildNavCountCard({required String title, required String count}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFDFF1FD),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontSize: 11, color: Colors.black87, fontWeight: FontWeight.w500)),
              const SizedBox(height: 4),
              Text(count, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87)),
            ],
          ),
          const Icon(Icons.arrow_forward_ios, size: 12, color: Colors.black38),
        ],
      ),
    );
  }

  // የዝርዝር መደዳ (List Item)
  Widget _buildListTileItem({required IconData icon, required String title}) {
    return ListTile(
      leading: Icon(icon, color: Colors.black54),
      title: Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Colors.black87)),
      trailing: const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.black38),
      onTap: () => _showComingSoon(title),
    );
  }
}
