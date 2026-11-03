import 'package:flutter/material.dart';

class MessagesScreen extends StatefulWidget {
  const MessagesScreen({super.key});

  @override
  State<MessagesScreen> createState() => _MessagesScreenState();
}

class _MessagesScreenState extends State<MessagesScreen> {
  int _unreadNoticeCount = 2;
  int _unreadInteractionCount = 5;
  int _unreadFollowerCount = 3;

  final List> _systemNotices = [
    {
      "id": "announcement_1",
      "title": "Official Announcement",
      "subtitle": "Welcome to VIP Voice App! Protect your account.",
      "time": "Just now",
      "icon": Icons.campaign,
      "color": Colors.orangeAccent,
      "unread": true,
      "details":
          "Welcome to our live voice party platform! To keep your account safe, never share your password, verification codes, or personal payment credentials with anyone. Official staff will never ask for your private keys.",
    },
    {
      "id": "wallet_1",
      "title": "Wallet & Rewards",
      "subtitle": "Recharge bonuses and daily free coins are active.",
      "time": "10:30 AM",
      "icon": Icons.monetization_on,
      "color": const Color(0xFFFFD700),
      "unread": true,
      "details":
          "Today's recharge rewards are now live! Get up to a 20% bonus coin multiplier on all Telebirr and local payment top-ups. Check your wallet balance to claim your daily check-in rewards.",
    },
  ];

  void _markAllAsRead() {
    setState(() {
      _unreadNoticeCount = 0;
      _unreadInteractionCount = 0;
      _unreadFollowerCount = 0;
      for (var notice in _systemNotices) {
        notice["unread"] = false;
      }
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("All notifications marked as read"),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _openNoticeDetail(Map<String, dynamic> notice) {
    setState(() {
      notice["unread"] = false;
    });
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => NoticeContentScreen(
          title: notice["title"],
          time: notice["time"],
          content: notice["details"],
          color: notice["color"],
          icon: notice["icon"],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7FBFB),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        title: const Text(
          "Messages",
          style: TextStyle(
            color: Colors.black,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.done_all, color: Colors.black54),
            tooltip: "Mark all as read",
            onPressed: _markAllAsRead,
          ),
        ],
      ),
      body: ListView(
        physics: const BouncingScrollPhysics(),
        children: [
          const SizedBox(height: 16),
          // Quick Action Badges (Notice, Interaction, Followers)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _quickActionButton(
                  icon: Icons.notifications_active,
                  label: "Notice",
                  color: Colors.blueAccent,
                  badgeCount: _unreadNoticeCount,
                  onTap: () {
                    setState(() => _unreadNoticeCount = 0);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const NoticeDetailScreen(),
                      ),
                    );
                  },

),
                _quickActionButton(
                  icon: Icons.favorite,
                  label: "Interaction",
                  color: Colors.pinkAccent,
                  badgeCount: _unreadInteractionCount,
                  onTap: () {
                    setState(() => _unreadInteractionCount = 0);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const InteractionDetailScreen(),
                      ),
                    );
                  },
                ),
                _quickActionButton(
                  icon: Icons.person_add,
                  label: "Followers",
                  color: const Color(0xFF00C9A7),
                  badgeCount: _unreadFollowerCount,
                  onTap: () {
                    setState(() => _unreadFollowerCount = 0);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const FollowersListScreen(),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          const Divider(height: 1, color: Color(0xFFE8ECEF)),
          const SizedBox(height: 8),

          // Official Channels / System Notices Section
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Text(
              "Official Channels",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.black45,
                fontSize: 12,
                letterSpacing: 0.5,
              ),
            ),
          ),

          ..._systemNotices.map((notice) {
            final bool isUnread = notice["unread"] as bool;
            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.black.withOpacity(0.04)),
              ),
              child: ListTile(
                leading: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    CircleAvatar(
                      radius: 22,
                      backgroundColor:
                          (notice["color"] as Color).withOpacity(0.15),
                      child: Icon(
                        notice["icon"] as IconData,
                        color: notice["color"] as Color,
                        size: 22,
                      ),
                    ),
                    if (isUnread)
                      Positioned(
                        right: -1,
                        top: -1,
                        child: Container(
                          width: 10,
                          height: 10,
                          decoration: const BoxDecoration(
                            color: Colors.redAccent,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                  ],
                ),
                title: Text(
                  notice["title"],
                  style: TextStyle(
                    fontWeight: isUnread ? FontWeight.bold : FontWeight.w600,
                    fontSize: 14,
                    color: Colors.black87,
                  ),
                ),
                subtitle: Text(
                  notice["subtitle"],
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 12, color: Colors.black54),

),
                trailing: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      notice["time"],
                      style: const TextStyle(fontSize: 11, color: Colors.black38),
                    ),
                    const SizedBox(height: 4),
                    const Icon(Icons.arrow_forward_ios,
                        size: 12, color: Colors.black26),
                  ],
                ),
                onTap: () => _openNoticeDetail(notice),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _quickActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required int badgeCount,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                width: 54,
                height: 54,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 26),
              ),
              if (badgeCount > 0)
                Positioned(
                  top: -2,
                  right: -2,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: Colors.redAccent,
                      shape: BoxShape.circle,
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 18,
                      minHeight: 18,
                    ),
                    child: Center(
                      child: Text(
                        badgeCount > 99 ? "99+" : "$badgeCount",
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }
}

// ----------------------------------------------------
// 1. ዝርዝር የማሳሰቢያ ገጽ (Notice Detail Screen)
// ----------------------------------------------------
class NoticeDetailScreen extends StatelessWidget {
  const NoticeDetailScreen({super.key});

  final List> _notices = const [
    {
      "title": "System Security Maintenance Completed",
      "date": "Today 08:30 AM",
      "body":
          "Our audio routing servers have been upgraded for low latency Agora audio streaming across all 30-seat rooms.",
    },
    {
      "title": "Community Guidelines Update",
      "date": "Yesterday 04:15 PM",
      "body":
          "Respect fellow broadcasters and guests. Any form of harassment in live audio lounges will result in room locks.",
    },
    {
      "title": "Welcome Gift Package Available",
      "date": "3 days ago",
      "body":
          "Check your wallet to claim the newly registered broadcaster badge and bonus gifts.",
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7FBFB),
      appBar: AppBar(
        title: const Text("Notices",
            style: TextStyle(color: Colors.black, fontSize: 17, fontWeight: FontWeight.bold)),

backgroundColor: Colors.white,
        elevation: 0.5,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black, size: 18),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(14),
        itemCount: _notices.length,
        itemBuilder: (context, index) {
          final item = _notices[index];
          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            elevation: 0.5,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        item["title"]!,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    item["date"]!,
                    style: const TextStyle(color: Colors.black38, fontSize: 11),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    item["body"]!,
                    style: const TextStyle(color: Colors.black87, fontSize: 13, height: 1.3),
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

// ----------------------------------------------------
// 2. የመስተጋብር ዝርዝር ገጽ (Interaction Detail Screen)
// ----------------------------------------------------
class InteractionDetailScreen extends StatelessWidget {
  const InteractionDetailScreen({super.key});

  final List> _interactions = const [
    {
      "user": "Amina",
      "action": "sent you a Rose gift in Dessie VIP Chill",
      "time": "15m ago",
      "icon": Icons.card_giftcard,
      "color": Colors.pinkAccent,
    },
    {
      "user": "Yonas",
      "action": "joined your 30-seat voice lounge",
      "time": "1h ago",
      "icon": Icons.meeting_room,
      "color": Colors.blueAccent,
    },
    {
      "user": "Selam",
      "action": "liked your room audio stream",
      "time": "3h ago",
      "icon": Icons.favorite,
      "color": Colors.redAccent,
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7FBFB),
      appBar: AppBar(
        title: const Text("Interactions",
            style: TextStyle(color: Colors.black, fontSize: 17, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0.5,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black, size: 18),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: ListView.separated(
        padding: const EdgeInsets.all(12),
        itemCount: _interactions.length,
        separatorBuilder: (_, __) => const Divider(height: 1, color: Color(0xFFE8ECEF)),
        itemBuilder: (context, index) {
          final item = _interactions[index];
          return ListTile(
            leading: CircleAvatar(
              backgroundColor: (item["color"] as Color).withOpacity(0.15),
              child: Icon(item["icon"] as IconData, color: item["color"] as Color, size: 20),
            ),
            title: RichText(
              text: TextSpan(
                style: const TextStyle(color: Colors.black87, fontSize: 13),
                children: [
                  TextSpan(

text: "${item["user"]} ",
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  TextSpan(text: item["action"]),
                ],
              ),
            ),
            trailing: Text(
              item["time"],
              style: const TextStyle(color: Colors.black38, fontSize: 11),
            ),
          );
        },
      ),
    );
  }
}

// ----------------------------------------------------
// 3. የተከታዮች ዝርዝር እና አስተዳደር (Followers List Screen)
// ----------------------------------------------------
class FollowersListScreen extends StatefulWidget {
  const FollowersListScreen({super.key});

  @override
  State<FollowersListScreen> createState() => _FollowersListScreenState();
}

class _FollowersListScreenState extends State<FollowersListScreen> {
  final List> _followers = [
    {
      "name": "Hamza Voice",
      "bio": "Host Agency Lead • Dessie",
      "isFollowing": true,
    },
    {
      "name": "Sara Ahmed",
      "bio": "Music & Lounge Enthusiast",
      "isFollowing": false,
    },
    {
      "name": "DJ Mike",
      "bio": "Broadcasting live parties every night",
      "isFollowing": true,
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7FBFB),
      appBar: AppBar(
        title: const Text("Followers",
            style: TextStyle(color: Colors.black, fontSize: 17, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0.5,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black, size: 18),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: _followers.length,
        itemBuilder: (context, index) {
          final person = _followers[index];
          final bool isFollowing = person["isFollowing"] as bool;

          return Card(
            elevation: 0.3,
            margin: const EdgeInsets.symmetric(vertical: 4),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: const Color(0xFF261D45),
                child: Text(
                  person["name"][0],
                  style: const TextStyle(color: Color(0xFFFFD700), fontWeight: FontWeight.bold),
                ),
              ),
              title: Text(
                person["name"],
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
              subtitle: Text(
                person["bio"],
                style: const TextStyle(fontSize: 12, color: Colors.black54),
              ),
              trailing: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  elevation: 0,
                  backgroundColor: isFollowing ? const Color(0xFFE8ECEF) : const Color(0xFF00C9A7),
                  foregroundColor: isFollowing ? Colors.black87 : Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                ),
                onPressed: () {
                  setState(() {
                    person["isFollowing"] = !isFollowing;
                  });
                },
                child: Text(
                  isFollowing ? "Following" : "Follow Back",
                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

// ----------------------------------------------------

// 4. የሲስተም ኖቲስ ዝርዝር ይዘት ማሳያ (Notice Content Screen)
// ----------------------------------------------------
class NoticeContentScreen extends StatelessWidget {
  final String title;
  final String time;
  final String content;
  final Color color;
  final IconData icon;

  const NoticeContentScreen({
    super.key,
    required this.title,
    required this.time,
    required this.content,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7FBFB),
      appBar: AppBar(
        title: Text(title,
            style: const TextStyle(color: Colors.black, fontSize: 16, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0.5,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black, size: 18),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(18),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.black.withOpacity(0.05)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.03),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    backgroundColor: color.withOpacity(0.15),
                    radius: 24,
                    child: Icon(icon, color: color, size: 26),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          time,
                          style: const TextStyle(fontSize: 12, color: Colors.black38),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              const Divider(color: Color(0xFFECEFF1)),
              const SizedBox(height: 14),
              Text(
                content,
                style: const TextStyle(
                  fontSize: 14,
                  height: 1.5,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF16122C),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  onPressed: () => Navigator.pop(context),
                  child: const Text(
                    "Acknowledge",
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
