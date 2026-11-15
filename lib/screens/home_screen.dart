import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
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
  bool _dailyClaimed = false;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();
  final Set<String> _followedRoomIds = {'room_abay_falls'};

  static const Color kShiroBg = Color(0xFFF3E2C7);
  static const Color kShiroCard = Color(0xFFE7CFA8);
  static const Color kBlackText = Color(0xFF1A1410);
  static const Color kSubBlack = Color(0xFF3E3124);
  static const Color kGoldBlack = Color(0xFF1E1810);
  static const Color kGoldAccent = Color(0xFFD49B42);

  static const String abayFallsUrl =
      "https://upload.wikimedia.org/wikipedia/commons/thumb/0/05/Blue_Nile_Falls_Ethiopia.jpg/1024px-Blue_Nile_Falls_Ethiopia.jpg";

  final List> _defaultRooms = [
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

      widget.onJoinRoom(roomId);

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

Future<void> _joinExistingRoom(Map<String, dynamic> roomItem) async {
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

      final rId = roomItem["id"] as String;
      widget.onJoinRoom(rId);

      if (mounted) {
        Navigator.pop(context);
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => VoiceRoomScreen(
              roomTitle: roomItem["title"] as String,
              roomId: rId,
              hostName: roomItem["host"] as String,
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

  void _openRankAndActivitySheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: kShiroBg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        "Daily Rewards & Top Ranks 🏆",
                        style: TextStyle(
                          color: kBlackText,
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, color: kBlackText),
                        onPressed: () => Navigator.pop(ctx),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: kShiroCard,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: kGoldAccent, width: 1.2),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.monetization_on, color: kGoldBlack, size: 32),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "Daily Check-In Bonus",
                                style: TextStyle(
                                  color: kBlackText,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                              Text(

"Claim +50 free coins every day!",
                                style: TextStyle(color: kSubBlack, fontSize: 12),
                              ),
                            ],
                          ),
                        ),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _dailyClaimed ? Colors.grey : kGoldBlack,
                            foregroundColor: const Color(0xFFFFD700),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          onPressed: _dailyClaimed
                              ? null
                              : () {
                                  setState(() => _dailyClaimed = true);
                                  setModalState(() {});
                                  widget.onCoinUpdate(widget.coins + 50);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text("+50 Daily Bonus Coins Added!")),
                                  );
                                },
                          child: Text(_dailyClaimed ? "Claimed" : "Claim +50"),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  const Text(
                    "Top Active Rooms Today",
                    style: TextStyle(
                      color: kBlackText,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ..._defaultRooms.take(3).map((r) {
                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: CircleAvatar(
                        backgroundColor: kGoldBlack,
                        child: const Icon(Icons.mic, color: Color(0xFFFFD700), size: 18),
                      ),
                      title: Text(
                        r["title"] as String,
                        style: const TextStyle(color: kBlackText, fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                      subtitle: Text(
                        "Host: ${r["host"]} • ${r["members"]} online",
                        style: const TextStyle(color: kSubBlack, fontSize: 11),
                      ),
                      trailing: TextButton(
                        onPressed: () {
                          Navigator.pop(ctx);
                          _joinExistingRoom(r);
                        },
                        child: const Text(
                          "Join",
                          style: TextStyle(color: kBlackText, fontWeight: FontWeight.bold),
                        ),
                      ),
                    );
                  }),
                ],
              ),
            );
          },
        );
      },
    );
  }

  List> _mergeRooms(QuerySnapshot? snapshot) {
    final List> merged = List.from(_defaultRooms);
    if (snapshot != null) {
      for (final doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        final id = doc.id;
        final exists = merged.any((r) => r["id"] == id);
        if (!exists) {
          merged.insert(0, {
            "id": id,
            "title": (data["roomTitle"] ?? data["title"] ?? "Live Voice Room").toString(),
            "host": (data["hostName"] ?? "Host").toString(),
            "members": (data["memberCount"] is int) ? data["memberCount"] : 1,
            "color": const Color(0xFF2B2118),
          });
        }
      }
    }
    return merged;
  }

List> _filterRooms(List> allRooms) {
    List> list = allRooms;
    if (_selectedTopTab == 0) {
      list = list.where((r) => _followedRoomIds.contains(r["id"])).toList();
    }
    if (_searchQuery.trim().isNotEmpty) {
      final q = _searchQuery.trim().toLowerCase();
      list = list.where((r) {
        final title = (r["title"] as String).toLowerCase();
        final host = (r["host"] as String).toLowerCase();
        final id = (r["id"] as String).toLowerCase();
        if (title.contains(q)) return true;
        if (host.contains(q)) return true;
        if (id.contains(q)) return true;
        return false;
      }).toList();
    }
    return list;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: kShiroBg,
      child: SafeArea(
        child: Stack(
          children: [
            Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
                  child: Row(
                    children: [
                      GestureDetector(
                        onTap: () => setState(() => _selectedTopTab = 0),
                        child: Column(
                          children: [
                            Text(
                              "Follow",
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: _selectedTopTab == 0 ? kBlackText : kSubBlack,
                              ),
                            ),
                            if (_selectedTopTab == 0)
                              Container(
                                margin: const EdgeInsets.only(top: 4),
                                width: 22,
                                height: 3,
                                decoration: BoxDecoration(
                                  color: kBlackText,
                                  borderRadius: BorderRadius.circular(2),
                                ),
                              ),
                          ],
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
                                width: 22,
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
                          border: Border.all(color: kGoldAccent, width: 1.4),
                        ),
                        child: IconButton(
                          padding: EdgeInsets.zero,
                          icon: const Icon(
                            Icons.grid_view_rounded,
                            color: Color(0xFFFFD700),
                            size: 20,
                          ),
                          onPressed: _openRankAndActivitySheet,
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
                        hintText: "Search room name, host, or ID...",
                        hintStyle: const TextStyle(color: kSubBlack, fontSize: 13),
                        prefixIcon: const Icon(Icons.search, color: kBlackText),
                        filled: true,
                        fillColor: kShiroCard,
                        contentPadding: const EdgeInsets.symmetric(vertical: 10),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: kGoldAccent),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: kGoldAccent),
                        ),
                      ),
                      onChanged: (val) => setState(() => _searchQuery = val),
                    ),
                  ),

                const Divider(color: Colors.black12, height: 1),

                // Story Tray Widget
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

                // Rooms Grid
                Expanded(
                  child: StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance.collection('rooms').limit(30).snapshots(),
                    builder: (context, snapshot) {
                      final allRooms = _mergeRooms(snapshot.data);
                      final visibleRooms = _filterRooms(allRooms);

                      return ListView(
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
                                  colors: [Colors.black87, Colors.black26],
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
                                    style: TextStyle(color: Colors.white, fontSize: 12),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                _selectedTopTab == 0 ? "Followed Parties ♥" : "Live Parties 🎧",
                                style: const TextStyle(
                                  color: kBlackText,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                "${visibleRooms.length} Rooms",
                                style: const TextStyle(
                                  color: kSubBlack,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          if (visibleRooms.isEmpty)
                            Container(
                              padding: const EdgeInsets.all(24),
                              decoration: BoxDecoration(
                                color: kShiroCard,
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Column(
                                children: [
                                  const Text(
                                    "No rooms found here.",
                                    style: TextStyle(
                                      color: kBlackText,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  ElevatedButton(

style: ElevatedButton.styleFrom(
                                      backgroundColor: kGoldBlack,
                                      foregroundColor: const Color(0xFFFFD700),
                                    ),
                                    onPressed: () => setState(() {
                                      _selectedTopTab = 1;
                                      _searchQuery = '';
                                      _searchController.clear();
                                    }),
                                    child: const Text("Show All Live Parties"),
                                  ),
                                ],
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
                                final item = visibleRooms[index];
                                final roomId = item["id"] as String;
                                final roomTitle = item["title"] as String;
                                final roomHost = item["host"] as String;
                                final roomColor = item["color"] as Color;
                                final roomMembers = item["members"] as int;
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
                                                color: Colors.black54,
                                                borderRadius: BorderRadius.circular(8),
                                              ),
                                              child: Row(
                                                children: [
                                                  const Icon(Icons.whatshot, color: Colors.orangeAccent, size: 12),
                                                  const SizedBox(width: 4),
                                                  Text(
                                                    "$roomMembers",
                                                    style: const TextStyle(color: Colors.white, fontSize: 10),

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
                                          style: const TextStyle(color: Colors.white70, fontSize: 11),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                          const SizedBox(height: 80),
                        ],
                      );
                    },
                  ),
                ),
              ],
            ),

            // Floating Golden-Black Mic Button to Create/Enter My Room
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
                      offset: const Offset(0, 5),
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
