import 'package:flutter/material.dart';
import 'services/user_service.dart';

class LevelScreen extends StatefulWidget {
  const LevelScreen({super.key});

  @override
  State<LevelScreen> createState() => _LevelScreenState();
}

class _LevelScreenState extends State<LevelScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final UserService _userService = UserService();

  final List<Map<String, dynamic>> levels = [
    {'range': 'Lv.1-9', 'tagVal': '1', 'color': Colors.grey, 'hasMedal': false},
    {'range': 'Lv.10-19', 'tagVal': '10', 'color': Colors.amber, 'hasMedal': true, 'medal': Icons.shield},
    {'range': 'Lv.20-29', 'tagVal': '20', 'color': Colors.teal, 'hasMedal': true, 'medal': Icons.military_tech},
    {'range': 'Lv.30-39', 'tagVal': '30', 'color': Colors.purpleAccent, 'hasMedal': true, 'medal': Icons.workspace_premium},
    {'range': 'Lv.40-49', 'tagVal': '40', 'color': Colors.blueAccent, 'hasMedal': true, 'medal': Icons.verified},
    {'range': 'Lv.50-59', 'tagVal': '50', 'color': Colors.orangeAccent, 'hasMedal': true, 'medal': Icons.stars},
    {'range': 'Lv.60-69', 'tagVal': '60', 'color': Colors.redAccent, 'hasMedal': true, 'medal': Icons.diamond},
    {'range': 'Lv.70-79', 'tagVal': '70', 'color': Colors.pinkAccent, 'hasMedal': true, 'medal': Icons.auto_awesome},
    {'range': 'Lv.80-89', 'tagVal': '80', 'color': Colors.cyanAccent, 'hasMedal': true, 'medal': Icons.brightness_auto},
    {'range': 'Lv.90-99', 'tagVal': '90', 'color': Colors.amberAccent, 'hasMedal': true, 'medal': Icons.emoji_events},
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  int _calculateLevel(int value) {
    if (value <= 0) return 1;
    int calculated = (value / 5000).floor() + 1;
    return calculated > 99 ? 99 : calculated;
  }

  double _calculateProgress(int value) {
    int currentLevelBase = ((value / 5000).floor()) * 5000;
    int remainder = value - currentLevelBase;
    double progress = remainder / 5000.0;
    return progress.clamp(0.0, 1.0);
  }

  int _calculateNeeded(int value) {
    int nextLevelTarget = (((value / 5000).floor()) + 1) * 5000;
    return nextLevelTarget - value;
  }

  @override
  Widget build(BuildContext context) {
    final bool isWealth = _tabController.index == 0;
    final int userWealthValue = _userService.coins;
    final int userCharmValue = _userService.points;

    final int currentWealthLv = _calculateLevel(userWealthValue);
    final int currentCharmLv = _calculateLevel(userCharmValue);

    return Scaffold(
      backgroundColor: const Color(0xFF0F0F14),
      appBar: AppBar(
        backgroundColor: const Color(0xFF161822),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: TabBar(
          controller: _tabController,
          indicatorColor: isWealth ? Colors.amber : Colors.purpleAccent,
          indicatorWeight: 3,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white54,
          labelStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          tabs: const [
            Tab(text: 'Wealth'),
            Tab(text: 'Charm'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildLevelTab(
            isWealth: true,
            titleValue: 'Wealth Value: $userWealthValue',
            currentLv: 'Lv.$currentWealthLv',
            nextLv: 'Lv.${currentWealthLv + 1}',

needed: 'Need ${_calculateNeeded(userWealthValue)} coins for upgrade',
            progress: _calculateProgress(userWealthValue),
            levelDesc: 'Wealth level is determined by the total coins spent and recharged.',
          ),
          _buildLevelTab(
            isWealth: false,
            titleValue: 'Charm Value: $userCharmValue',
            currentLv: 'Lv.$currentCharmLv',
            nextLv: 'Lv.${currentCharmLv + 1}',
            needed: 'Need ${_calculateNeeded(userCharmValue)} points for upgrade',
            progress: _calculateProgress(userCharmValue),
            levelDesc: 'Charm level is determined by gifts and points received in rooms.',
          ),
        ],
      ),
    );
  }

  Widget _buildLevelTab({
    required bool isWealth,
    required String titleValue,
    required String currentLv,
    required String nextLv,
    required String needed,
    required double progress,
    required String levelDesc,
  }) {
    final String displayName = _userService.userName.isNotEmpty ? _userService.userName : 'User_${_userService.userId}';

    return ListView(
      padding: const EdgeInsets.all(16.0),
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: isWealth
                  ? [const Color(0xFF3A2E12), const Color(0xFF1C1917)]
                  : [const Color(0xFF331730), const Color(0xFF19121E)],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 26,
                    backgroundColor: isWealth ? Colors.amber.withOpacity(0.2) : Colors.purpleAccent.withOpacity(0.2),
                    child: Icon(
                      isWealth ? Icons.monetization_on : Icons.favorite,
                      color: isWealth ? Colors.amber : Colors.purpleAccent,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          displayName,
                          style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          titleValue,
                          style: const TextStyle(color: Colors.white70, fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(currentLv, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                  Text(needed, style: const TextStyle(color: Colors.white54, fontSize: 11)),
                  Text(nextLv, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                ],
              ),
              const SizedBox(height: 8),
              LinearProgressIndicator(
                value: progress,
                backgroundColor: Colors.white10,
                color: isWealth ? Colors.amber : Colors.purpleAccent,

minHeight: 6,
                borderRadius: BorderRadius.circular(5),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Text(
          isWealth ? 'Wealth Level' : 'Charm Level',
          style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 4),
        Text(
          levelDesc,
          style: const TextStyle(color: Colors.white54, fontSize: 12),
        ),
        const SizedBox(height: 14),
        ...levels.map((item) {
          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: const Color(0xFF1A1C24),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.white10),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item['range'],
                  style: const TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                        decoration: BoxDecoration(
                          color: const Color(0xFF252836),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              isWealth ? 'Wealth Tag' : 'Charm Tag',
                              style: const TextStyle(color: Colors.white70, fontSize: 13),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: (item['color'] as Color).withOpacity(0.3),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    isWealth ? Icons.diamond : Icons.favorite,
                                    color: item['color'],
                                    size: 14,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    item['tagVal'],
                                    style: TextStyle(color: item['color'], fontWeight: FontWeight.bold, fontSize: 12),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    if (item['hasMedal']) ...[
                      const SizedBox(width: 12),
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                          decoration: BoxDecoration(
                            color: const Color(0xFF252836),
                            borderRadius: BorderRadius.circular(20),

),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Text('Medal Details', style: TextStyle(color: Colors.white70, fontSize: 12)),
                              const SizedBox(width: 6),
                              Icon(item['medal'], color: item['color'], size: 22),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          );
        }).toList(),
      ],
    );
  }
}
