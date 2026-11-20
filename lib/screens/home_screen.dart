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
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  final Set _followedRoomIds = {'room_dessie_vip'};

  static const Color kTopTurquoise = Color(0xFF00BFA5);
  static const Color kMidEmerald = Color(0xFF00695C);
  static const Color kDeepTeal = Color(0xFF062426);
  static const Color kCardDark = Color(0xFF0B3539);
  static const Color kCardDeep = Color(0xFF072225);
  static const Color kGoldBright = Color(0xFFFFD700);
  static const Color kGoldSoft = Color(0xFFE5B84B);
  static const Color kMintGlow = Color(0xFF26E6C8);

  final List _defaultRooms = [
    {
      "id": "room_dessie_vip",
      "title": "Dessie VIP Chill 🎧",
      "host": "Amina",
      "members": 92,
    },
  ];

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  void _toggleSearch() {
    setState(() {
      _isSearching = !_isSearching;
      if (_isSearching) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            _searchFocusNode.requestFocus();
          }
        });
      } else {
        _searchQuery = '';
        _searchController.clear();
        _searchFocusNode.unfocus();
      }
    });
  }

  Future _handleEnterMyRoom() async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(color: kGoldBright),
      ),
    );

    try {
      final roomService = RoomService();
      final user = FirebaseAuth.instance.currentUser;
      final hostUid =
          user?.uid ?? 'guest_host_${DateTime.now().millisecondsSinceEpoch}';
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

  Future _joinExistingRoom(Map roomItem) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(color: kGoldBright),
      ),
    );

try {
      final user = FirebaseAuth.instance.currentUser;
      final myUid =
          user?.uid ?? 'guest_${DateTime.now().millisecondsSinceEpoch}';
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

  List _mergeWithLiveRooms(QuerySnapshot? snapshot) {
    final List combined =
        _defaultRooms.map((e) => Map.from(e as Map)).toList();
    final Set existingIds =
        combined.map((e) => (e as Map)["id"].toString()).toSet();

    if (snapshot != null) {
      for (final doc in snapshot.docs) {
        final rawData = doc.data();
        if (rawData is! Map) continue;
        final data = rawData;
        final String id = doc.id;
        final String title =
            (data['roomTitle'] ?? data['title'] ?? '').toString().trim();
        if (title.isEmpty) continue;

        final String host = (data['hostName'] ?? 'Host').toString();
        int activeCount = 1;
        if (data['activeSeats'] is Map) {
          final seatsMap = data['activeSeats'] as Map;
          if (seatsMap.isNotEmpty) {
            activeCount = seatsMap.length;
          }
        }

        if (existingIds.contains(id)) {
          final idx = combined.indexWhere((r) => (r as Map)["id"] == id);
          if (idx != -1) {
            final target = combined[idx] as Map;
            target["title"] = title;
            target["host"] = host;
            if (activeCount > 1) {
              target["members"] = activeCount;
            }
          }
        } else {
          existingIds.add(id);
          combined.add({
            "id": id,
            "title": title,
            "host": host,
            "members": activeCount,
          });
        }
      }
    }
    return combined;
  }

  void _showRankSheet(List roomsList) {
    showModalBottomSheet(
      context: context,
      backgroundColor: kCardDeep,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
        side: BorderSide(color: kGoldSoft, width: 1.2),
      ),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(Icons.emoji_events_rounded,
                      color: kGoldBright, size: 22),
                  SizedBox(width: 8),
                  Text(
                    "Top Active Rooms",
                    style: TextStyle(
                      color: kGoldBright,
                      fontSize: 17,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              ...roomsList.map((item) {
                final r = item as Map;
                return Container(
                  margin: const EdgeInsets.only(bottom: 8),

decoration: BoxDecoration(
                    color: kCardDark,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: kGoldSoft.withOpacity(0.45),
                      width: 1,
                    ),
                  ),
                  child: ListTile(
                    leading: const CircleAvatar(
                      backgroundColor: Color(0xFF14100A),
                      child: Icon(Icons.mic, color: kGoldBright, size: 18),
                    ),
                    title: Text(
                      r["title"].toString(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 13.5,
                      ),
                    ),
                    subtitle: Text(
                      "Host: ${r["host"]} • ${r["members"]} online",
                      style: const TextStyle(
                        color: Color(0xFFB8E6DF),
                        fontSize: 11.5,
                      ),
                    ),
                    trailing: const Icon(Icons.arrow_forward_ios_rounded,
                        color: kGoldBright, size: 14),
                    onTap: () {
                      Navigator.pop(ctx);
                      _joinExistingRoom(r);
                    },
                  ),
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
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [
            kTopTurquoise,
            kMidEmerald,
            kDeepTeal,
          ],
          stops: [0.0, 0.34, 0.85],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: SafeArea(
        child: StreamBuilder(
          stream: FirebaseFirestore.instance
              .collection('rooms')
              .limit(30)
              .snapshots(),
          builder: (context, snapshot) {
            final QuerySnapshot? querySnap = snapshot.data is QuerySnapshot
                ? snapshot.data as QuerySnapshot
                : null;
            final allRooms = _mergeWithLiveRooms(querySnap);
            final String q = _searchQuery.trim().toLowerCase();

            final visibleRooms = allRooms.where((item) {
              final r = item as Map;
              if (q.isNotEmpty) {
                final title = r["title"].toString().toLowerCase();
                final host = r["host"].toString().toLowerCase();
                final id = r["id"].toString().toLowerCase();
                return title.contains(q)  host.contains(q)  id.contains(q);
              }
              if (_selectedTopTab == 0) {
                return _followedRoomIds.contains(r["id"]);
              }
              return true;
            }).toList();

            return Stack(
              children: [
                Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
                      child: Row(
                        children: [
                          GestureDetector(
                            onTap: () => setState(() => _selectedTopTab = 0),
                            child: Column(
                              children: [
                                Text(
                                  "Follow",
                                  style: TextStyle(
                                    fontSize: _selectedTopTab == 0 ? 20 : 17,
                                    fontWeight: FontWeight.w900,
                                    color: _selectedTopTab == 0

? Colors.white
                                        : Colors.white70,
                                    shadows: const [
                                      Shadow(
                                        color: Colors.black38,
                                        blurRadius: 4,
                                        offset: Offset(0, 1),
                                      ),
                                    ],
                                  ),
                                ),
                                if (_selectedTopTab == 0)
                                  Container(
                                    margin: const EdgeInsets.only(top: 4),
                                    width: 24,
                                    height: 3.5,
                                    decoration: BoxDecoration(
                                      color: kGoldBright,
                                      borderRadius: BorderRadius.circular(2),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 20),
                          GestureDetector(
                            onTap: () => setState(() => _selectedTopTab = 1),
                            child: Column(
                              children: [
                                Text(
                                  "Party",
                                  style: TextStyle(
                                    fontSize: _selectedTopTab == 1 ? 21 : 17,
                                    fontWeight: FontWeight.w900,
                                    color: _selectedTopTab == 1
                                        ? Colors.white
                                        : Colors.white70,
                                    shadows: const [
                                      Shadow(
                                        color: Colors.black38,
                                        blurRadius: 4,
                                        offset: Offset(0, 1),
                                      ),
                                    ],
                                  ),
                                ),
                                if (_selectedTopTab == 1)
                                  Container(
                                    margin: const EdgeInsets.only(top: 4),
                                    width: 24,
                                    height: 3.5,
                                    decoration: BoxDecoration(
                                      color: kGoldBright,
                                      borderRadius: BorderRadius.circular(2),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          const Spacer(),
                          GestureDetector(
                            onTap: _toggleSearch,
                            child: Container(
                              width: 38,
                              height: 38,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: _isSearching
                                    ? kGoldBright
                                    : Colors.black.withOpacity(0.28),
                                border: Border.all(
                                  color: _isSearching
                                      ? kGoldBright
                                      : Colors.white38,
                                  width: 1.2,
                                ),

),
                              child: Icon(
                                _isSearching
                                    ? Icons.close_rounded
                                    : Icons.search_rounded,
                                color:
                                    _isSearching ? Colors.black : Colors.white,
                                size: 22,
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          GestureDetector(
                            onTap: () => _showRankSheet(allRooms),
                            child: Container(
                              width: 38,
                              height: 38,
                              decoration: BoxDecoration(
                                color: const Color(0xFF16110A),
                                borderRadius: BorderRadius.circular(12),
                                border:
                                    Border.all(color: kGoldBright, width: 1.4),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.3),
                                    blurRadius: 6,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: const Icon(
                                Icons.emoji_events_rounded,
                                color: kGoldBright,
                                size: 20,
                              ),
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
                          focusNode: _searchFocusNode,
                          autofocus: true,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                          cursorColor: kGoldBright,
                          decoration: InputDecoration(
                            hintText: "Search by room name, host, or ID...",
                            hintStyle: const TextStyle(
                              color: Colors.white60,
                              fontSize: 13,
                            ),
                            prefixIcon: const Icon(Icons.search_rounded,
                                color: kGoldBright),
                            suffixIcon: _searchQuery.isNotEmpty
                                ? IconButton(
                                    icon: const Icon(Icons.cancel_rounded,
                                        color: Colors.white70, size: 19),
                                    onPressed: () {
                                      setState(() {
                                        _searchQuery = '';
                                        _searchController.clear();
                                      });
                                    },
                                  )
                                : null,
                            filled: true,
                            fillColor: kCardDeep.withOpacity(0.92),
                            contentPadding:
                                const EdgeInsets.symmetric(vertical: 10),
                            enabledBorder: OutlineInputBorder(

borderRadius: BorderRadius.circular(14),
                              borderSide: const BorderSide(
                                  color: kGoldSoft, width: 1.2),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: const BorderSide(
                                  color: kGoldBright, width: 1.8),
                            ),
                          ),
                          onChanged: (val) =>
                              setState(() => _searchQuery = val),
                        ),
                      ),
                    Container(
                      margin: const EdgeInsets.symmetric(horizontal: 12),
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.22),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.white12),
                      ),
                      child: StoryTrayWidget(
                        onAddStoryTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const StoryUploadScreen(),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 8),
                    Expanded(
                      child: ListView(
                        padding: const EdgeInsets.fromLTRB(16, 4, 16, 90),
                        children: [
                          GestureDetector(
                            onTap: () => _showRankSheet(allRooms),
                            child: Container(
                              height: 112,
                              width: double.infinity,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(18),
                                gradient: const LinearGradient(
                                  colors: [
                                    Color(0xFF1A140E),
                                    Color(0xFF2D2110),
                                    Color(0xFF0A3A3A),
                                  ],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                border:
                                    Border.all(color: kGoldBright, width: 1.5),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.38),
                                    blurRadius: 12,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 18),
                              child: Row(
                                children: [
                                  const Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Row(

children: [
                                            Icon(Icons.auto_awesome,
                                                color: kGoldBright, size: 18),
                                            SizedBox(width: 6),
                                            Text(
                                              "Abay Festival 🎉",
                                              style: TextStyle(
                                                color: kGoldBright,
                                                fontWeight: FontWeight.w900,
                                                fontSize: 19,
                                                letterSpacing: 0.3,
                                              ),
                                            ),
                                          ],
                                        ),
                                        SizedBox(height: 5),
                                        Text(
                                          "Join top 3D voice rooms & win rewards!",
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 12.5,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Container(
                                    width: 56,
                                    height: 56,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      gradient: const LinearGradient(
                                        colors: [
                                          Color(0xFFFFD700),
                                          Color(0xFFFF8F00),
                                        ],
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: kGoldBright.withOpacity(0.45),
                                          blurRadius: 12,
                                        ),
                                      ],
                                    ),
                                    child: const Icon(
                                      Icons.workspace_premium_rounded,
                                      color: Colors.black,
                                      size: 32,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 18),
                          Row(
                            children: [
                              Text(
                                q.isNotEmpty
                                    ? "Search Results (${visibleRooms.length})"
                                    : (_selectedTopTab == 0
                                        ? "Followed Parties ♥"
                                        : "Live Parties 🎧"),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.w900,
                                  shadows: [
                                    Shadow(
                                      color: Colors.black45,
                                      blurRadius: 4,

offset: Offset(0, 1),
                                    ),
                                  ],
                                ),
                              ),
                              const Spacer(),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.black.withOpacity(0.3),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                      color: kMintGlow.withOpacity(0.5)),
                                ),
                                child: Text(
                                  "${visibleRooms.length} Live",
                                  style: const TextStyle(
                                    color: kMintGlow,
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          if (visibleRooms.isEmpty)
                            Container(
                              padding: const EdgeInsets.all(28),
                              decoration: BoxDecoration(
                                color: kCardDeep.withOpacity(0.85),
                                borderRadius: BorderRadius.circular(18),
                                border: Border.all(
                                    color: kGoldSoft.withOpacity(0.4)),
                              ),
                              child: Column(
                                children: [
                                  const Icon(Icons.search_off_rounded,
                                      color: kGoldBright, size: 38),
                                  const SizedBox(height: 8),
                                  Text(
                                    q.isNotEmpty
                                        ? "No room matched \"$_searchQuery\""
                                        : "No followed rooms yet.",
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ],
                              ),
                            )
                          else
                            GridView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: visibleRooms.length,
                              gridDelegate:
                                  const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 2,
                                crossAxisSpacing: 12,
                                mainAxisSpacing: 12,
                                childAspectRatio: 0.96,
                              ),
                              itemBuilder: (context, index) {
                                final item = visibleRooms[index] as Map;
                                final roomId = item["id"].toString();
                                final roomTitle = item["title"].toString();
                                final roomHost = item["host"].toString();

final roomMembers =
                                    (item["members"] as num).toInt();
                                final isFollowed =
                                    _followedRoomIds.contains(roomId);

                                return GestureDetector(
                                  onTap: () => _joinExistingRoom(item),
                                  child: Container(
                                    padding: const EdgeInsets.all(13),
                                    decoration: BoxDecoration(
                                      gradient: const LinearGradient(
                                        colors: [
                                          Color(0xFF0E4749),
                                          Color(0xFF08272B),
                                        ],
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                      ),
                                      borderRadius: BorderRadius.circular(18),
                                      border: Border.all(
                                          color: kGoldBright, width: 1.4),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withOpacity(0.35),
                                          blurRadius: 8,
                                          offset: const Offset(0, 4),
                                        ),
                                      ],
                                    ),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: [
                                            Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                      horizontal: 8,
                                                      vertical: 3),
                                              decoration: BoxDecoration(
                                                color: Colors.black
                                                    .withOpacity(0.45),
                                                borderRadius:
                                                    BorderRadius.circular(10),
                                                border: Border.all(
                                                    color: kMintGlow
                                                        .withOpacity(0.45)),
                                              ),
                                              child: Row(
                                                children: [
                                                  const Icon(Icons.whatshot,
                                                      color: Colors.orangeAccent,
                                                      size: 13),
                                                  const SizedBox(width: 4),
                                                  Text(
                                                    "$roomMembers",
                                                    style: const TextStyle(
                                                      color: Colors.white,
                                                      fontSize: 11,

fontWeight:
                                                          FontWeight.bold,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                            GestureDetector(
                                              onTap: () {
                                                setState(() {
                                                  if (isFollowed) {
                                                    _followedRoomIds
                                                        .remove(roomId);
                                                  } else {
                                                    _followedRoomIds
                                                        .add(roomId);
                                                  }
                                                });
                                              },
                                              child: Icon(
                                                isFollowed
                                                    ? Icons.favorite
                                                    : Icons.favorite_border,
                                                color: isFollowed
                                                    ? Colors.redAccent
                                                    : kGoldBright,
                                                size: 20,
                                              ),
                                            ),
                                          ],
                                        ),
                                        const Spacer(),
                                        Center(
                                          child: Container(
                                            width: 48,
                                            height: 48,
                                            decoration: BoxDecoration(
                                              shape: BoxShape.circle,
                                              color:
                                                  kGoldBright.withOpacity(0.14),
                                              border: Border.all(
                                                  color: kGoldBright
                                                      .withOpacity(0.6)),
                                            ),
                                            child: const Icon(
                                              Icons.graphic_eq_rounded,
                                              color: kGoldBright,
                                              size: 26,
                                            ),
                                          ),
                                        ),
                                        const Spacer(),
                                        Text(
                                          roomTitle,
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.w900,
                                            fontSize: 14,
                                          ),
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          "Host: $roomHost",

style: const TextStyle(
                                            color: kGoldBright,
                                            fontSize: 11.5,
                                            fontWeight: FontWeight.w700,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
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
                      border: Border.all(color: kGoldBright, width: 2.2),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.45),
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
                            color: kGoldBright,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
