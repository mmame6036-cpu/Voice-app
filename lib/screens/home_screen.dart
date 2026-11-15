import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/room_service.dart';
import '../services/user_id_service.dart';
import '../widgets/story_tray_widget.dart';
import 'story_upload_screen.dart';
import 'voice_room_screen.dart';

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
  int _selectedTopTab = 1;
  bool _isSearching = false;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();
  final Set _followedRoomIds = {'room_abay_falls'};

  static const Color kShiroBg = Color(0xFFF3E2C7);
  static const Color kShiroCard = Color(0xFFE7CFA8);
  static const Color kBlackText = Color(0xFF1A1410);
  static const Color kSubBlack = Color(0xFF3E3124);
  static const Color kGoldBlack = Color(0xFF1E1810);
  static const Color kGoldAccent = Color(0xFFD49B42);

  static const String abayFallsUrl =
      "https://upload.wikimedia.org/wikipedia/commons/thumb/0/05/Blue_Nile_Falls_Ethiopia.jpg/1024px-Blue_Nile_Falls_Ethiopia.jpg";

  final List _rooms = [
    {
      "id": "room_abay_falls",
      "title": "Abay Falls 3D Lounge 🌊",
      "host": "Kedir Umer",
      "members": 184,
      "color": const Color(0xFF261D45),
    },
    {
      "id": "room_dessie_vip",
      "title": "Dessie VIP Chill 🎧",
      "host": "Amina",
      "members": 92,
      "color": const Color(0xFF1E2D45),
    },
    {
      "id": "room_habesha_club",
      "title": "Habesha Night Club 🌙",
      "host": "Yonas",
      "members": 320,
      "color": const Color(0xFF381E45),
    },
    {
      "id": "room_bole_cafe",
      "title": "Bole Cafe Chit-Chat ☕",
      "host": "Selam",
      "members": 76,
      "color": const Color(0xFF1E3C38),
    },
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _handleEnterMyRoom() async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(color: kGoldAccent),
      ),
    );

    try {
      final roomService = RoomService();
      final user = FirebaseAuth.instance.currentUser;
      final hostUid = user?.uid ?? 'guest_host_${DateTime.now().millisecondsSinceEpoch}';
      final hostName = user?.displayName ?? 'Host';
      final roomId = 'room_$hostUid';
      final roomTitle = "$hostName's Lounge";

      final permanentNumericId = await UserIdService.getOrCreatePermanentId(
        hostUid,
        defaultName: hostName,
      );

      try {
        await roomService.enterMyRoom(
          roomId: roomId,
          roomTitle: roomTitle,
          hostUid: hostUid,
          hostName: hostName,
        );
      } catch (_) {}

      if (mounted) {
        Navigator.pop(context);
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => VoiceRoomScreen(
              roomTitle: roomTitle,
              roomId: roomId,
              hostName: hostName,
              userNumericId: permanentNumericId,
              userUid: hostUid,
              userName: hostName,
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error entering room: $e")),
        );
      }
    }
  }

  Future<void> _joinExistingRoom(Map roomItem) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(color: kGoldAccent),
      ),
    );

try {
      final user = FirebaseAuth.instance.currentUser;
      final myUid = user?.uid ?? 'guest_${DateTime.now().millisecondsSinceEpoch}';
      final myName = user?.displayName ?? 'User';

      final permanentNumericId = await UserIdService.getOrCreatePermanentId(
        myUid,
        defaultName: myName,
      );

      if (mounted) {
        Navigator.pop(context);
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => VoiceRoomScreen(
              roomTitle: roomItem["title"].toString(),
              roomId: roomItem["id"].toString(),
              hostName: roomItem["host"].toString(),
              userNumericId: permanentNumericId,
              userUid: myUid,
              userName: "User $permanentNumericId",
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: $e")),
        );
      }
    }
  }

  void _showRankSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: kShiroBg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Top Active Rooms 🏆",
                style: TextStyle(
                  color: kBlackText,
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 10),
              ..._rooms.map((item) {
                final r = item as Map;
                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const CircleAvatar(
                    backgroundColor: kGoldBlack,
                    child: Icon(Icons.mic, color: Color(0xFFFFD700), size: 18),
                  ),
                  title: Text(
                    r["title"].toString(),
                    style: const TextStyle(
                      color: kBlackText,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                  subtitle: Text(
                    "Host: ${r["host"]} • ${r["members"]} online",
                    style: const TextStyle(color: kSubBlack, fontSize: 11),
                  ),
                  onTap: () {
                    Navigator.pop(ctx);
                    _joinExistingRoom(r);
                  },
                );
              }),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final visibleRooms = _rooms.where((item) {
      final r = item as Map;
      if (_selectedTopTab == 0 && !_followedRoomIds.contains(r["id"])) {
        return false;
      }
      if (_searchQuery.trim().isNotEmpty) {
        final q = _searchQuery.trim().toLowerCase();
        final title = r["title"].toString().toLowerCase();
        final host = r["host"].toString().toLowerCase();
        return title.contains(q) || host.contains(q);
      }
      return true;
    }).toList();

    return Container(
      color: kShiroBg,
      child: SafeArea(
        child: Stack(
          children: [
            Column(
              children: [
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
                            color: _selectedTopTab == 0 ? kBlackText : kSubBlack,
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
                                color: _selectedTopTab == 1 ? kBlackText : kSubBlack,
                              ),
                            ),
                            if (_selectedTopTab == 1)
                              Container(
                                margin: const EdgeInsets.only(top: 4),
                                width: 20,
                                height: 3,
                                decoration: BoxDecoration(
                                  color: kBlackText,
                                  borderRadius: BorderRadius.circular(2),
                                ),
                              ),
                          ],
                        ),
                      ),
                      const Spacer(),
                      IconButton(
                        icon: Icon(
                          _isSearching ? Icons.close : Icons.search,
                          color: kBlackText,
                          size: 26,
                        ),
                        onPressed: () {
                          setState(() {
                            _isSearching = !_isSearching;
                            if (!_isSearching) {
                              _searchQuery = '';
                              _searchController.clear();
                            }
                          });
                        },
                      ),
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: kGoldBlack,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: kGoldAccent, width: 1.2),
                        ),
                        child: IconButton(
                          padding: EdgeInsets.zero,
                          icon: const Icon(
                            Icons.grid_view_rounded,
                            color: Color(0xFFFFD700),
                            size: 20,
                          ),
                          onPressed: _showRankSheet,
                        ),
                      ),
                    ],
                  ),
                ),

                if (_isSearching)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
                    child: TextField(
                      controller: _searchController,
                      style: const TextStyle(color: kBlackText, fontSize: 14),
                      decoration: InputDecoration(
                        hintText: "Search rooms or hosts...",
                        hintStyle: const TextStyle(color: kSubBlack, fontSize: 13),
                        prefixIcon: const Icon(Icons.search, color: kBlackText),
                        filled: true,

fillColor: kShiroCard,
                        contentPadding: const EdgeInsets.symmetric(vertical: 8),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: kGoldAccent),
                        ),
                      ),
                      onChanged: (val) => setState(() => _searchQuery = val),
                    ),
                  ),

                const Divider(color: Colors.black12, height: 1),

                StoryTrayWidget(
                  onAddStoryTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const StoryUploadScreen(),
                      ),
                    );
                  },
                ),

                const Divider(color: Colors.black12, height: 1),

                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      Container(
                        height: 110,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: kGoldAccent, width: 1.2),
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
                              Text(
                                "Abay Festival 🎉",
                                style: TextStyle(
                                  color: Color(0xFFFFD700),
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18,
                                ),
                              ),
                              Text(
                                "Join top 3D voice rooms now!",
                                style: TextStyle(color: Colors.white70, fontSize: 12),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        _selectedTopTab == 0 ? "Followed Parties ♥" : "Live Parties 🎧",
                        style: const TextStyle(
                          color: kBlackText,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      if (visibleRooms.isEmpty)
                        const Padding(
                          padding: EdgeInsets.all(24),
                          child: Center(
                            child: Text(
                              "No rooms found.",
                              style: TextStyle(

color: kBlackText,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        )
                      else
                        GridView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: visibleRooms.length,
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            crossAxisSpacing: 12,
                            mainAxisSpacing: 12,
                            childAspectRatio: 0.95,
                          ),
                          itemBuilder: (context, index) {
                            final item = visibleRooms[index] as Map;
                            final roomId = item["id"].toString();
                            final roomTitle = item["title"].toString();
                            final roomHost = item["host"].toString();
                            final roomColor = item["color"] as Color;
                            final roomMembers = (item["members"] as num).toInt();
                            final isFollowed = _followedRoomIds.contains(roomId);

                            return GestureDetector(
                              onTap: () => _joinExistingRoom(item),
                              child: Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: roomColor,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(color: kGoldAccent, width: 1.2),
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
                                              Text(
                                                "$roomMembers",
                                                style: const TextStyle(color: Colors.white70, fontSize: 10),
                                              ),
                                            ],
                                          ),
                                        ),
                                        GestureDetector(
                                          onTap: () {
                                            setState(() {
                                              if (isFollowed) {
                                                _followedRoomIds.remove(roomId);
                                              } else {
                                                _followedRoomIds.add(roomId);

}
                                            });
                                          },
                                          child: Icon(
                                            isFollowed ? Icons.favorite : Icons.favorite_border,
                                            color: isFollowed ? Colors.redAccent : const Color(0xFFFFD700),
                                            size: 18,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const Spacer(),
                                    Text(
                                      roomTitle,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 13,
                                      ),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      "Host: $roomHost",
                                      style: const TextStyle(color: Colors.white60, fontSize: 11),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      const SizedBox(height: 80),
                    ],
                  ),
                ),
              ],
            ),

            Positioned(
              bottom: 24,
              right: 18,
              child: Container(
                height: 64,
                width: 64,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(
                    colors: [
                      Color(0xFF2B2118),
                      Color(0xFF140E08),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  border: Border.all(color: const Color(0xFFFFD700), width: 2),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.35),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(32),
                    onTap: _handleEnterMyRoom,
                    child: const Center(
                      child: Icon(
                        Icons.mic_rounded,
                        size: 32,
                        color: Color(0xFFFFD700),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
