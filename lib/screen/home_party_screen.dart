import 'package:flutter/material.dart';
import 'start_live_screen.dart';
import 'live_audio_room_screen.dart';

class HomePartyScreen extends StatefulWidget {
  const HomePartyScreen({Key? key}) : super(key: key);

  @override
  State<HomePartyScreen> createState() => _HomePartyScreenState();
}

class _HomePartyScreenState extends State<HomePartyScreen> {
  int _selectedBottomNav = 0;

  // ለሙከራ የሚሆኑ የቀጥታ ክፍሎች ዝርዝር
  final List<Map<String, dynamic>> _liveRooms = [
    {
      'title': 'Habesha Chill & Music 🎵',
      'host': 'Sara_Des',
      'listeners': '1.2k',
      'tag': 'Music',
      'gradient': [const Color(0xFF4F46E5), const Color(0xFF06B6D4)],
    },
    {
      'title': 'Coffee & Life Chat ☕',
      'host': 'Aman_Voice',
      'listeners': '840',
      'tag': 'Chat',
      'gradient': [const Color(0xFFD97706), const Color(0xFFDC2626)],
    },
    {
      'title': 'Night Owls Gaming 🎮',
      'host': 'Rediet_Pro',
      'listeners': '2.5k',
      'tag': 'Game',
      'gradient': [const Color(0xFF7C3AED), const Color(0xFFDB2777)],
    },
    {
      'title': 'Friendship & Fun Lounge ✨',
      'host': 'Kedir_O',
      'listeners': '620',
      'tag': 'Friendly',
      'gradient': [const Color(0xFF059669), const Color(0xFF10B981)],
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0E1A),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'Party Lounge',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 20),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.search_rounded, color: Colors.white70),
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(Icons.notifications_none_rounded, color: Colors.white70),
            onPressed: () {},
          ),
        ],
      ),
      body: CustomScrollView(
        slivers: [
          // 1. ተንሸራታች የባነር ክፍል (Featured Banner)
          SliverToBoxAdapter(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              height: 120,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                gradient: const LinearGradient(
                  colors: [Color(0xFF6366F1), Color(0xFFA855F7)],
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF6366F1).withOpacity(0.35),
                    blurRadius: 15,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        Text(
                          'Host Voice Rooms 🎙️',
                          style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        SizedBox(height: 6),
                        Text(
                          'Connect with friends, receive gifts and earn daily rewards!',
                          style: TextStyle(color: Colors.white70, fontSize: 11),
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.stars_rounded, color: Colors.amberAccent, size: 55),
                ],
              ),
            ),
          ),

          // 2. የምድብ መራጮች (Category Tabs)

SliverToBoxAdapter(
            child: Container(
              height: 40,
              margin: const EdgeInsets.symmetric(vertical: 12),
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: [
                  _buildCategoryChip('🔥 Popular', isSelected: true),
                  _buildCategoryChip('🎵 Music', isSelected: false),
                  _buildCategoryChip('💬 Chat', isSelected: false),
                  _buildCategoryChip('🎮 Games', isSelected: false),
                  _buildCategoryChip('🌍 Ethiopia', isSelected: false),
                ],
              ),
            ),
          ),

          // 3. የቀጥታ ክፍሎች ግሪድ (Live Room Cards)
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            sliver: SliverGrid(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 14,
                crossAxisSpacing: 14,
                childAspectRatio: 0.88,
              ),
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final room = _liveRooms[index];
                  return GestureDetector(
                    onTap: () {
                      // ወደ ድምፅ ክፍሉ በቀጥታ ማስገባት
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => LiveAudioRoomScreen(
                            roomTitle: room['title'],
                            channelName: 'room_${index + 1}',
                          ),
                        ),
                      );
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(18),
                        gradient: LinearGradient(
                          colors: room['gradient'],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.4),
                            blurRadius: 10,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                                decoration: BoxDecoration(
                                  color: Colors.black38,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  room['tag'],
                                  style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                                ),
                              ),
                              Row(
                                children: [
                                  const Icon(Icons.headset_rounded, color: Colors.white, size: 12),
                                  const SizedBox(width: 4),
                                  Text(

room['listeners'],
                                    style: const TextStyle(color: Colors.white, fontSize: 10),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          const Spacer(),
                          Text(
                            room['title'],
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              const CircleAvatar(
                                radius: 10,
                                backgroundColor: Colors.white24,
                                child: Icon(Icons.person, color: Colors.white, size: 12),
                              ),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  room['host'],
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(color: Colors.white70, fontSize: 11),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
                childCount: _liveRooms.length,
              ),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 80)),
        ],
      ),

      // 4. የቀጥታ ክፍል መክፈቻ ቁልፍ (Floating Action Button)
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          // ወደ 3ቱ ደረጃዎች የ Go Live ፍሰት ይወስዳል
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const StartLiveScreen()),
          );
        },
        backgroundColor: const Color(0xFF2563EB),
        icon: const Icon(Icons.mic, color: Colors.white),
        label: const Text(
          'Go Live',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,

      // 5. የታችኛው የመዘዋወሪያ ሜኑ (Bottom Navigation Bar)
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedBottomNav,
        onTap: (index) => setState(() => _selectedBottomNav = index),
        backgroundColor: const Color(0xFF111827),
        selectedItemColor: const Color(0xFF38BDF8),
        unselectedItemColor: Colors.white38,
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.explore_rounded), label: 'Party'),
          BottomNavigationBarItem(icon: Icon(Icons.sports_esports_rounded), label: 'Games'),
          BottomNavigationBarItem(icon: SizedBox(width: 20), label: ''), // FAB Space
          BottomNavigationBarItem(icon: Icon(Icons.chat_bubble_outline_rounded), label: 'Chats'),
          BottomNavigationBarItem(icon: Icon(Icons.person_outline_rounded), label: 'Me'),
        ],
      ),
    );
  }

  Widget _buildCategoryChip(String title, {required bool isSelected}) {
    return Container(
      margin: const EdgeInsets.only(right: 10),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(

color: isSelected ? const Color(0xFF2563EB) : Colors.white.withOpacity(0.08),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Center(
        child: Text(
          title,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.white70,
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}
