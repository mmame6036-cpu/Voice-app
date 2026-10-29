import 'package:flutter/material.dart';

class TaskScreen extends StatefulWidget {
  const TaskScreen({super.key});

  @override
  State<TaskScreen> createState() => _TaskScreenState();
}

class _TaskScreenState extends State<TaskScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF141226),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E1B38),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "Task Center",
          style: TextStyle(
            color: Colors.white,
            fontSize: 17,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) {
          return [
            // 1. Daily Check-in (የ 7 ቀናት ሰንጠረዥ)
            SliverToBoxAdapter(
              child: Container(
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF2C224D), Color(0xFF1E1B38)],
                  ),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFFFFD700).withOpacity(0.3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: const [
                        Row(
                          children: [
                            Icon(Icons.calendar_month, color: Color(0xFFFFD700), size: 20),
                            SizedBox(width: 8),
                            Text(
                              "Daily Check-in",
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                              ),
                            ),
                          ],
                        ),
                        Text(
                          "Streak: 0 Days",
                          style: TextStyle(color: Colors.white54, fontSize: 12),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),

                    // የ 7 ቀናት ሳጥኖች መደዳ
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: List.generate(7, (index) {
                        return Container(
                          width: 42,
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.06),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: index == 0
                                  ? const Color(0xFFFFD700)
                                  : Colors.white10,
                            ),
                          ),
                          child: Column(

children: [
                              Text(
                                "D${index + 1}",
                                style: const TextStyle(
                                  color: Colors.white60,
                                  fontSize: 10,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Icon(
                                Icons.monetization_on,
                                color: index == 6
                                    ? Colors.redAccent
                                    : const Color(0xFFFFD700),
                                size: 16,
                              ),
                              const SizedBox(height: 4),
                              Container(
                                width: 6,
                                height: 6,
                                decoration: BoxDecoration(
                                  color: index == 0
                                      ? const Color(0xFF00C9A7)
                                      : Colors.white24,
                                  shape: BoxShape.circle,
                                ),
                              ),
                            ],
                          ),
                        );
                      }),
                    ),
                  ],
                ),
              ),
            ),

            // 2. TabBar Header (Daily Tasks & Growth Tasks)
            SliverPersistentHeader(
              pinned: true,
              delegate: _SliverAppBarDelegate(
                TabBar(
                  controller: _tabController,
                  indicatorColor: const Color(0xFFFFD700),
                  indicatorWeight: 3,
                  labelColor: const Color(0xFFFFD700),
                  unselectedLabelColor: Colors.white54,
                  labelStyle: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                  tabs: const [
                    Tab(text: "Daily Tasks"),
                    Tab(text: "Growth Tasks"),
                  ],
                ),
              ),
            ),
          ];
        },
        body: TabBarView(
          controller: _tabController,
          children: [
            // Daily Tasks ዝርዝር ቦታ
            _buildTaskList([
              {"title": "Stay in Room for 10 min", "reward": "+20 Coins", "icon": Icons.timer},
              {"title": "Speak on Mic for 5 min", "reward": "+30 Coins", "icon": Icons.mic},
              {"title": "Send 1 Gift in Room", "reward": "+50 Coins", "icon": Icons.card_giftcard},
              {"title": "Send 3 Chat Messages", "reward": "+10 Coins", "icon": Icons.chat},
              {"title": "Share Room to Friends", "reward": "+15 Coins", "icon": Icons.share},
            ]),

            // Growth Tasks ዝርዝር ቦታ
            _buildTaskList([
              {"title": "Complete Profile Info", "reward": "+100 Coins", "icon": Icons.person},
              {"title": "Follow 3 Friends", "reward": "+50 Coins", "icon": Icons.person_add},
              {"title": "Create Your First Room", "reward": "+200 Coins", "icon": Icons.meeting_room},
              {"title": "Bind Phone Number", "reward": "+150 Coins", "icon": Icons.phone_android},
            ]),
          ],
        ),
      ),
    );
  }

  // የተግባራት ዝርዝር ካርዶች
  Widget _buildTaskList(List<Map<String, dynamic>> tasks) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: tasks.length,
      itemBuilder: (context, index) {
        final task = tasks[index];
        return Container(
          margin: const EdgeInsets.only(bottom: 12),

padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0xFF1E1B38),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white10),
          ),
          child: Row(
            children: [
              // የተግባሩ ምልክት
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.06),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  task["icon"] as IconData,
                  color: const Color(0xFFFFD700),
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),

              // የተግባሩ ስም እና የሽልማት መጠን
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      task["title"] as String,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      task["reward"] as String,
                      style: const TextStyle(
                        color: Color(0xFFFFD700),
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),

              // የሂደት መለኪያ እና ቁልፍ
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const Text(
                    "0/1",
                    style: TextStyle(color: Colors.white38, fontSize: 11),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFF00C9A7),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Text(
                      "Go",
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 11,
                      ),
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
}

// ለቋሚ TabBar ማስፈጸሚያ
class _SliverAppBarDelegate extends SliverPersistentHeaderDelegate {
  final TabBar _tabBar;

  _SliverAppBarDelegate(this._tabBar);

  @override
  double get minExtent => _tabBar.preferredSize.height;
  @override
  double get maxExtent => _tabBar.preferredSize.height;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: const Color(0xFF141226),
      child: _tabBar,
    );
  }

  @override
  bool shouldRebuild(_SliverAppBarDelegate oldDelegate) {
    return false;
  }
}
