import 'package:flutter/material.dart';

class HomeScreen extends StatefulWidget {
  final int coins;
  final Function(int) onCoinUpdate;
  final Function(String) onJoinRoom;

  const HomeScreen({
    super.key,
    required this.coins,
    required this.onCoinUpdate,
    required this.onJoinRoom,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedTopTab = 1; // 0 = Follow, 1 = Party

  static const String abayFallsUrl =
      "https://upload.wikimedia.org/wikipedia/commons/thumb/0/05/Blue_Nile_Falls_Ethiopia.jpg/1024px-Blue_Nile_Falls_Ethiopia.jpg";

  final List<Map<String, dynamic>> _rooms = [
    {
      "title": "Abay Falls 3D Lounge 🌊",
      "host": "Kedir Umer",
      "members": 184,
      "color": const Color(0xFF261D45),
    },
    {
      "title": "Dessie VIP Chill 🎧",
      "host": "Amina",
      "members": 92,
      "color": const Color(0xFF1E2D45),
    },
    {
      "title": "Habesha Night Club 🌙",
      "host": "Yonas",
      "members": 320,
      "color": const Color(0xFF381E45),
    },
    {
      "title": "Bole Cafe Chit-Chat ☕",
      "host": "Selam",
      "members": 76,
      "color": const Color(0xFF1E3C38),
    },
  ];

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        children: [
          // አናት ላይ፦ በግራ (Follow, Party) | በቀኝ (Search, Square Box)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
            child: Row(
              children: [
                GestureDetector(
                  onTap: () => setState(() => _selectedTopTab = 0),
                  child: Text(
                    "Follow",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: _selectedTopTab == 0 ? const Color(0xFFFFD700) : Colors.white60,
                    ),
                  ),
                ),
                const SizedBox(width: 18),
                GestureDetector(
                  onTap: () => setState(() => _selectedTopTab = 1),
                  child: Column(
                    children: [
                      Text(
                        "Party",
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: _selectedTopTab == 1 ? Colors.white : Colors.white60,
                        ),
                      ),
                      if (_selectedTopTab == 1)
                        Container(
                          margin: const EdgeInsets.only(top: 4),
                          width: 20,
                          height: 3,
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFD700),
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                    ],
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.search, color: Colors.white, size: 26),
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Search rooms or users...")),
                    );
                  },
                ),
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: const Color(0xFF23233E),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFFFFD700), width: 1.2),

),
                  child: IconButton(
                    padding: EdgeInsets.zero,
                    icon: const Icon(Icons.grid_view_rounded, color: Color(0xFFFFD700), size: 20),
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("Rank & Activity Box Opened")),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          const Divider(color: Colors.white12, height: 1),

          // የክፍሎች ዝርዝር
          Expanded(
            child: _selectedTopTab == 0
                ? const Center(
                    child: Text("No followed hosts live right now.", style: TextStyle(color: Colors.white54)),
                  )
                : ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      // Banner
                      Container(
                        height: 110,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          image: const DecorationImage(
                            image: NetworkImage(abayFallsUrl),
                            fit: BoxFit.cover,
                          ),
                        ),
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16),
                            gradient: const LinearGradient(
                              colors: [Colors.black87, Colors.transparent],
                            ),
                          ),
                          padding: const EdgeInsets.all(14),
                          child: const Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text("Abay Festival 🎉", style: TextStyle(color: Color(0xFFFFD700), fontWeight: FontWeight.bold, fontSize: 18)),
                              Text("Join top 3D voice rooms now!", style: TextStyle(color: Colors.white70, fontSize: 12)),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        "Live Parties 🎧",
                        style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 12),
                      GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _rooms.length,
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                          childAspectRatio: 0.95,
                        ),
                        itemBuilder: (context, index) {
                          final item = _rooms[index];
                          return GestureDetector(
                            onTap: () => widget.onJoinRoom(item["title"]),
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: item["color"],
                                borderRadius: BorderRadius.circular(16),

border: Border.all(color: Colors.white12),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: Colors.black45,
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: Row(
                                          children: [
                                            const Icon(Icons.whatshot, color: Colors.orangeAccent, size: 12),
                                            const SizedBox(width: 4),
                                            Text("${item['members']}", style: const TextStyle(color: Colors.white70, fontSize: 10)),
                                          ],
                                        ),
                                      ),
                                      const Icon(Icons.spatial_audio, color: Color(0xFFFFD700), size: 16),
                                    ],
                                  ),
                                  const Spacer(),
                                  Text(
                                    item["title"],
                                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    "Host: ${item['host']}",
                                    style: const TextStyle(color: Colors.white60, fontSize: 11),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}
