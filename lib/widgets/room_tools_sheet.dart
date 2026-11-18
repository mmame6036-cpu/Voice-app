import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../screens/room_settings_screen.dart';
import 'dragon_tiger_sheet.dart';

class RoomToolsSheet extends StatelessWidget {
  final String roomId;
  final String roomTitle;
  final String userName;
  final String userUid;
  final int userCoins;
  final bool isHost;
  final bool isAdmin;
  final VoidCallback onToggleVoice;
  final bool isVoiceOn;
  final bool isAllMicClosed;
  final String? currentPassword;
  final List<String> admins;
  final List seatedUsers;
  final Map<String, dynamic>? pkData;
  final Map<String, dynamic>? musicData;
  final String equippedFrame;
  final Function(String frameId)? onFrameChanged;

  const RoomToolsSheet({
    super.key,
    required this.roomId,
    required this.roomTitle,
    required this.userName,
    this.userUid = '',
    this.userCoins = 0,
    required this.isHost,
    this.isAdmin = false,
    required this.onToggleVoice,
    required this.isVoiceOn,
    this.isAllMicClosed = false,
    this.currentPassword,
    this.admins = const [],
    this.seatedUsers = const [],
    this.pkData,
    this.musicData,
    this.equippedFrame = 'default',
    this.onFrameChanged,
  });

  static void show(
    BuildContext context, {
    required String roomId,
    required String roomTitle,
    required String userName,
    String userUid = '',
    int userCoins = 0,
    required bool isHost,
    bool isAdmin = false,
    required VoidCallback onToggleVoice,
    required bool isVoiceOn,
    bool isAllMicClosed = false,
    String? currentPassword,
    List<String> admins = const [],
    List seatedUsers = const [],
    Map<String, dynamic>? pkData,
    Map<String, dynamic>? musicData,
    String equippedFrame = 'default',
    Function(String frameId)? onFrameChanged,
  }) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => RoomToolsSheet(
        roomId: roomId,
        roomTitle: roomTitle,
        userName: userName,
        userUid: userUid,
        userCoins: userCoins,
        isHost: isHost,
        isAdmin: isAdmin,
        onToggleVoice: onToggleVoice,
        isVoiceOn: isVoiceOn,
        isAllMicClosed: isAllMicClosed,
        currentPassword: currentPassword,
        admins: admins,
        seatedUsers: seatedUsers,
        pkData: pkData,
        musicData: musicData,
        equippedFrame: equippedFrame,
        onFrameChanged: onFrameChanged,
      ),
    );
  }

  bool get _canManageRoom => isHost || isAdmin;

  Future<void> _sendSystemChat(String text) async {
    await FirebaseFirestore.instance
        .collection('rooms')
        .doc(roomId)
        .collection('messages')
        .add({
      'sender': 'System',
      'senderUid': userUid,
      'message': text,
      'isSystem': true,
      'ts': DateTime.now().millisecondsSinceEpoch,
    }).catchError((_) {});
  }

  void _showShareSheet(BuildContext context) {
    final inviteText =
        "🎙️ Join my live voice room '$roomTitle' on NILE Live!\n🔑 Room ID: $roomId\n👑 Invited by: $userName";

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(20),
        decoration: const BoxDecoration(
          color: Color(0xFF130F26),
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(2),

),
            ),
            const SizedBox(height: 14),
            const Text(
              "Share Room",
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 14),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.06),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFFFD700).withOpacity(0.4)),
              ),
              child: Text(
                inviteText,
                style: const TextStyle(color: Colors.white70, fontSize: 12.5, height: 1.4),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFFFFD700),
                      side: const BorderSide(color: Color(0xFFFFD700)),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    icon: const Icon(Icons.tag, size: 18),
                    label: Text("Copy ID ($roomId)", style: const TextStyle(fontSize: 12)),
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: roomId));
                      Navigator.pop(ctx);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text("Room ID $roomId copied!")),
                      );
                    },
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFFD700),
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    icon: const Icon(Icons.copy, size: 18),
                    label: const Text("Copy Invite",
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: inviteText));
                      Navigator.pop(ctx);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("Room invite copied to clipboard!")),
                      );
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showSetPasswordDialog(BuildContext context) {
    final controller = TextEditingController(text: currentPassword ?? '');
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E1638),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Text("Set Room Password",
            style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              maxLength: 6,

style: const TextStyle(color: Colors.white, letterSpacing: 3),
              decoration: const InputDecoration(
                hintText: "Enter 4-digit PIN",
                hintStyle: TextStyle(color: Colors.white38, letterSpacing: 0),
                counterStyle: TextStyle(color: Colors.white38),
              ),
            ),
          ],
        ),
        actions: [
          if (currentPassword != null && currentPassword!.isNotEmpty)
            TextButton(
              onPressed: () async {
                await FirebaseFirestore.instance.collection('rooms').doc(roomId).set({
                  'password': FieldValue.delete(),
                }, SetOptions(merge: true));
                await _sendSystemChat("$userName unlocked the room password 🔓");
                if (ctx.mounted) Navigator.pop(ctx);
              },
              child: const Text("Remove PIN", style: TextStyle(color: Colors.redAccent)),
            ),
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Cancel", style: TextStyle(color: Colors.white54)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFFFD700)),
            onPressed: () async {
              final pin = controller.text.trim();
              if (pin.isEmpty) {
                await FirebaseFirestore.instance.collection('rooms').doc(roomId).set({
                  'password': FieldValue.delete(),
                }, SetOptions(merge: true));
                await _sendSystemChat("$userName unlocked the room password 🔓");
              } else {
                await FirebaseFirestore.instance.collection('rooms').doc(roomId).set({
                  'password': pin,
                }, SetOptions(merge: true));
                await _sendSystemChat("$userName set a room password 🔒");
              }
              if (ctx.mounted) Navigator.pop(ctx);
            },
            child: const Text("Save",
                style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _showAdminManagementSheet(BuildContext context) {
    final controller = TextEditingController();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
        child: Container(
          height: 430,
          padding: const EdgeInsets.all(18),
          decoration: const BoxDecoration(
            color: Color(0xFF130F26),
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: StreamBuilder<DocumentSnapshot>(
            stream: FirebaseFirestore.instance.collection('rooms').doc(roomId).snapshots(),
            builder: (context, snap) {
              final data = (snap.data?.data() as Map<String, dynamic>?) ?? {};
              final List<String> liveAdmins =
                  (data['admins'] as List?)?.map((e) => e.toString()).toList() ?? [];

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.white24,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    "Room Admin & Member Control",
                    style: TextStyle(
                        color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),

),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: controller,
                          style: const TextStyle(color: Colors.white, fontSize: 13),
                          decoration: InputDecoration(
                            hintText: "Enter username or UID to add admin",
                            hintStyle: const TextStyle(color: Colors.white38, fontSize: 12),
                            filled: true,
                            fillColor: Colors.white.withOpacity(0.06),
                            contentPadding:
                                const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFFFD700),
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: () async {
                          final target = controller.text.trim();
                          if (target.isNotEmpty) {
                            await FirebaseFirestore.instance.collection('rooms').doc(roomId).set({
                              'admins': FieldValue.arrayUnion([target]),
                            }, SetOptions(merge: true));
                            controller.clear();
                          }
                        },
                        child: const Text("Add",
                            style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Text("Seated Users & Active Admins",
                      style: TextStyle(color: Colors.white54, fontSize: 12)),
                  const SizedBox(height: 8),
                  Expanded(
                    child: ListView(
                      children: [
                        ...seatedUsers.map((u) {
                          final String name = (u['name'] ?? 'User').toString();
                          final String uid = (u['uid'] ?? '').toString();
                          final int seatNum = ((u['seatIndex'] as num?)?.toInt() ?? 0) + 1;
                          final bool isUserAdmin =
                              liveAdmins.contains(uid) || liveAdmins.contains(name);

                          return Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.06),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              children: [
                                CircleAvatar(
                                  radius: 16,
                                  backgroundColor: const Color(0xFFFFD700).withOpacity(0.2),
                                  child: Text("$seatNum",
                                      style: const TextStyle(

color: Color(0xFFFFD700),
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold)),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    name,
                                    style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 13),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                TextButton(
                                  onPressed: () async {
                                    final key = uid.isNotEmpty ? uid : name;
                                    if (isUserAdmin) {
                                      await FirebaseFirestore.instance
                                          .collection('rooms')
                                          .doc(roomId)
                                          .set({
                                        'admins': FieldValue.arrayRemove([uid, name]),
                                      }, SetOptions(merge: true));
                                    } else {
                                      await FirebaseFirestore.instance
                                          .collection('rooms')
                                          .doc(roomId)
                                          .set({
                                        'admins': FieldValue.arrayUnion([key]),
                                      }, SetOptions(merge: true));
                                    }
                                  },
                                  child: Text(
                                    isUserAdmin ? "Remove Admin" : "Make Admin",
                                    style: TextStyle(
                                      color: isUserAdmin
                                          ? Colors.orangeAccent
                                          : const Color(0xFF00E5FF),
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                if (uid != userUid)
                                  IconButton(
                                    icon: const Icon(Icons.block,
                                        color: Colors.redAccent, size: 18),
                                    tooltip: "Kick User",
                                    onPressed: () async {
                                      await FirebaseFirestore.instance
                                          .collection('rooms')
                                          .doc(roomId)
                                          .set({
                                        'kickedUsers': FieldValue.arrayUnion([uid]),
                                      }, SetOptions(merge: true));
                                      await _sendSystemChat("$name was kicked from the room");
                                    },
                                  ),
                              ],
                            ),
                          );
                        }),
                        ...liveAdmins
                            .where((a) => !seatedUsers
                                .any((u) => u['uid'] == a || u['name'] == a))
                            .map((adminName) => Container(

margin: const EdgeInsets.only(bottom: 8),
                                  padding:
                                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.05),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Row(
                                    children: [
                                      const Icon(Icons.shield,
                                          color: Color(0xFF00E5FF), size: 18),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: Text(adminName,
                                            style: const TextStyle(
                                                color: Colors.white, fontSize: 13)),
                                      ),
                                      TextButton(
                                        onPressed: () async {
                                          await FirebaseFirestore.instance
                                              .collection('rooms')
                                              .doc(roomId)
                                              .set({
                                            'admins': FieldValue.arrayRemove([adminName]),
                                          }, SetOptions(merge: true));
                                        },
                                        child: const Text("Remove",
                                            style: TextStyle(
                                                color: Colors.redAccent, fontSize: 11)),
                                      ),
                                    ],
                                  ),
                                )),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Future<void> _setAllMicsState(BuildContext context, bool closeAll) async {
    await FirebaseFirestore.instance.collection('rooms').doc(roomId).set({
      'allMicsClosed': closeAll,
    }, SetOptions(merge: true));

    await _sendSystemChat(
      closeAll
          ? "$userName closed all microphones 🔇"
          : "$userName opened all microphones 🎙️",
    );

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(closeAll ? "All mics closed!" : "All mics opened!"),
        ),
      );
    }
  }

  void _showRedPacketSheet(BuildContext context) {
    int selectedCoins = 100;
    int selectedQty = 5;
    final noteCtrl = TextEditingController(text: "Good luck everyone! 🧧");

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) => Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF4A0E0E), Color(0xFF1A0812)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [

Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.white24,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      "🧧 Send Room Red Packet",
                      style: TextStyle(
                          color: Color(0xFFFFD700),
                          fontSize: 17,
                          fontWeight: FontWeight.bold),
                    ),
                    Text(
                      "Balance: $userCoins",
                      style: const TextStyle(color: Colors.white70, fontSize: 12),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Text("Total Coins",
                    style: TextStyle(color: Colors.white70, fontSize: 12)),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [100, 500, 1000, 2000].map((amt) {
                    final sel = selectedCoins == amt;
                    return Expanded(
                      child: GestureDetector(
                        onTap: () => setSheetState(() => selectedCoins = amt),
                        child: Container(
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          decoration: BoxDecoration(
                            color: sel
                                ? const Color(0xFFFFD700)
                                : Colors.white.withOpacity(0.08),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Center(
                            child: Text(
                              "$amt",
                              style: TextStyle(
                                color: sel ? Colors.black : Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 14),
                const Text("Number of Packets",
                    style: TextStyle(color: Colors.white70, fontSize: 12)),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [3, 5, 10, 20].map((qty) {
                    final sel = selectedQty == qty;
                    return Expanded(
                      child: GestureDetector(
                        onTap: () => setSheetState(() => selectedQty = qty),
                        child: Container(
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          decoration: BoxDecoration(
                            color: sel
                                ? const Color(0xFFFFD700)
                                : Colors.white.withOpacity(0.08),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Center(
                            child: Text(

"$qty pcs",
                              style: TextStyle(
                                color: sel ? Colors.black : Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: noteCtrl,
                  style: const TextStyle(color: Colors.white, fontSize: 13),
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: Colors.white.withOpacity(0.08),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFFD700),
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    onPressed: () async {
                      if (userCoins < selectedCoins) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text("Insufficient coins balance!")),
                        );
                        return;
                      }
                      if (userUid.isNotEmpty) {
                        await FirebaseFirestore.instance
                            .collection('users')
                            .doc(userUid)
                            .set({
                          'coins': FieldValue.increment(-selectedCoins),
                        }, SetOptions(merge: true));
                      }

                      await FirebaseFirestore.instance
                          .collection('rooms')
                          .doc(roomId)
                          .collection('red_packets')
                          .add({
                        'senderUid': userUid,
                        'senderName': userName,
                        'totalCoins': selectedCoins,
                        'remainingCoins': selectedCoins,
                        'totalCount': selectedQty,
                        'remainingCount': selectedQty,
                        'note': noteCtrl.text.trim().isEmpty
                            ? "Good luck!"
                            : noteCtrl.text.trim(),
                        'claimedBy': [],
                        'createdAt': FieldValue.serverTimestamp(),
                      });

                      await _sendSystemChat(
                        "🧧 $userName dropped a $selectedCoins-coin Red Packet ($selectedQty packets)!",
                      );

                      if (ctx.mounted) Navigator.pop(ctx);
                    },
                    child: Text(
                      "Send Red Packet ($selectedCoins Coins)",
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showMusicSheet(BuildContext context) {
    final urlController = TextEditingController(
      text: (musicData?['trackUrl'] ?? '').toString(),
    );

final List tracks = [
      {
        'title': '🎉 VIP Party Celebration Beat',
        'asset': 'sounds/Five_win.mp3',
        'url': '',
      },
      {
        'title': '🌙 Chill Lounge Ambient',
        'asset': '',
        'url': 'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-1.mp3',
      },
      {
        'title': '🔥 Habesha Night Vibe',
        'asset': '',
        'url': 'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-2.mp3',
      },
    ];

    double currentVol = ((musicData?['volume'] as num?)?.toDouble() ?? 0.6).clamp(0.1, 1.0);
    bool isPlaying = musicData?['isPlaying'] == true;
    String activeTitle = (musicData?['trackTitle'] ?? tracks[0]['title']!).toString();

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) => Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: const BoxDecoration(
              color: Color(0xFF130F26),
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.white24,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      "🎵 Room Music Player",
                      style: TextStyle(
                          color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    if (isPlaying)
                      TextButton.icon(
                        onPressed: () async {
                          await FirebaseFirestore.instance
                              .collection('rooms')
                              .doc(roomId)
                              .set({
                            'musicState': {
                              'isPlaying': false,
                              'trackTitle': activeTitle,
                              'volume': currentVol,
                            }
                          }, SetOptions(merge: true));
                          setSheetState(() => isPlaying = false);
                        },
                        icon: const Icon(Icons.stop_circle, color: Colors.redAccent, size: 18),
                        label: const Text("Stop", style: TextStyle(color: Colors.redAccent)),
                      ),
                  ],
                ),
                const SizedBox(height: 10),
                ...tracks.map((t) {
                  final selected = activeTitle == t['title'] && isPlaying;
                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    decoration: BoxDecoration(
                      color: selected
                          ? const Color(0xFFFF4081).withOpacity(0.18)
                          : Colors.white.withOpacity(0.06),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: selected ? const Color(0xFFFF4081) : Colors.transparent,
                      ),
                    ),

child: ListTile(
                      dense: true,
                      leading: Icon(
                        selected ? Icons.equalizer : Icons.music_note,
                        color: const Color(0xFFFF4081),
                      ),
                      title: Text(
                        t['title']!,
                        style: const TextStyle(
                            color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13),
                      ),
                      trailing: IconButton(
                        icon: Icon(
                          selected ? Icons.pause_circle_filled : Icons.play_circle_fill,
                          color: const Color(0xFFFFD700),
                          size: 28,
                        ),
                        onPressed: () async {
                          final nextPlay = !selected;
                          setSheetState(() {
                            activeTitle = t['title']!;
                            isPlaying = nextPlay;
                          });
                          await FirebaseFirestore.instance
                              .collection('rooms')
                              .doc(roomId)
                              .set({
                            'musicState': {
                              'isPlaying': nextPlay,
                              'trackTitle': t['title'],
                              'trackAsset': t['asset'],
                              'trackUrl': t['url'],
                              'volume': currentVol,
                              'updatedBy': userName,
                            }
                          }, SetOptions(merge: true));
                        },
                      ),
                    ),
                  );
                }),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: urlController,
                        style: const TextStyle(color: Colors.white, fontSize: 12),
                        decoration: InputDecoration(
                          hintText: "Or paste direct MP3 audio link...",
                          hintStyle: const TextStyle(color: Colors.white38, fontSize: 12),
                          filled: true,
                          fillColor: Colors.white.withOpacity(0.06),
                          contentPadding:
                              const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFFF4081),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: () async {
                        final customUrl = urlController.text.trim();
                        if (customUrl.isEmpty) return;
                        setSheetState(() {
                          activeTitle = "Custom Stream";
                          isPlaying = true;
                        });
                        await FirebaseFirestore.instance
                            .collection('rooms')
                            .doc(roomId)
                            .set({
                          'musicState': {
                            'isPlaying': true,

'trackTitle': "Custom Stream",
                            'trackAsset': '',
                            'trackUrl': customUrl,
                            'volume': currentVol,
                            'updatedBy': userName,
                          }
                        }, SetOptions(merge: true));
                      },
                      child: const Text("Play",
                          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    const Icon(Icons.volume_down, color: Colors.white54, size: 20),
                    Expanded(
                      child: Slider(
                        value: currentVol,
                        min: 0.1,
                        max: 1.0,
                        activeColor: const Color(0xFFFFD700),
                        onChanged: (val) {
                          setSheetState(() => currentVol = val);
                        },
                        onChangeEnd: (val) async {
                          await FirebaseFirestore.instance
                              .collection('rooms')
                              .doc(roomId)
                              .set({
                            'musicState': {
                              'volume': val,
                            }
                          }, SetOptions(merge: true));
                        },
                      ),
                    ),
                    const Icon(Icons.volume_up, color: Colors.white54, size: 20),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showBackpackSheet(BuildContext context) {
    String selectedFrame = equippedFrame;
    final List frames = [
      {
        'id': 'default',
        'name': 'Classic Gold Ring',
        'desc': 'Standard VIP seat frame',
        'color': const Color(0xFFD49B42),
      },
      {
        'id': 'royal_fire',
        'name': 'Royal Dragon Gold',
        'desc': 'Glowing golden aura around your seat',
        'color': const Color(0xFFFFD700),
      },
      {
        'id': 'cyber_neon',
        'name': 'Cyber Cyan Neon',
        'desc': 'Electric cyan pulse ring',
        'color': const Color(0xFF00E5FF),
      },
      {
        'id': 'emerald_vip',
        'name': 'Emerald Sultan',
        'desc': 'Imperial green & gold seat border',
        'color': const Color(0xFF00E676),
      },
    ];

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) => Container(
          height: 420,
          padding: const EdgeInsets.all(20),
          decoration: const BoxDecoration(
            color: Color(0xFF130F26),
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                "🎒 My Backpack & Seat Frames",
                style: TextStyle(
                    color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),

const Text(
                "Equip a frame to highlight your seat in the room",
                style: TextStyle(color: Colors.white54, fontSize: 12),
              ),
              const SizedBox(height: 14),
              Expanded(
                child: GridView.builder(
                  itemCount: frames.length,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: 10,
                    crossAxisSpacing: 10,
                    childAspectRatio: 1.25,
                  ),
                  itemBuilder: (context, idx) {
                    final item = frames[idx];
                    final bool isEquipped = selectedFrame == item['id'];
                    final Color ringColor = item['color'] as Color;

                    return Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.06),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: isEquipped ? const Color(0xFFFFD700) : Colors.white12,
                          width: isEquipped ? 1.8 : 1.0,
                        ),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            width: 38,
                            height: 38,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.black,
                              border: Border.all(color: ringColor, width: 2.5),
                            ),
                            child: Icon(Icons.person, color: ringColor, size: 20),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            item['name'] as String,
                            style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 11.5),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 6),
                          SizedBox(
                            height: 26,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: isEquipped
                                    ? Colors.white24
                                    : const Color(0xFFFFD700),
                                padding: const EdgeInsets.symmetric(horizontal: 14),
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8)),
                              ),
                              onPressed: () async {
                                final newId = item['id'] as String;
                                setSheetState(() => selectedFrame = newId);
                                if (onFrameChanged != null) {
                                  onFrameChanged!(newId);
                                }
                                if (userUid.isNotEmpty) {
                                  await FirebaseFirestore.instance
                                      .collection('users')
                                      .doc(userUid)
                                      .set({'equippedFrame': newId}, SetOptions(merge: true));

}
                              },
                              child: Text(
                                isEquipped ? "Equipped" : "Equip",
                                style: TextStyle(
                                  color: isEquipped ? Colors.white : Colors.black,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showPkSheet(BuildContext context) {
    int selectedMinutes = 3;
    final redCtrl = TextEditingController(text: "Red Team 🔥");
    final blueCtrl = TextEditingController(text: "Blue Team ⚡");
    final bool isPkActive = pkData?['active'] == true;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) => Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: const BoxDecoration(
              color: Color(0xFF130F26),
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  "🥊 Room PK Battle",
                  style: TextStyle(
                      color: Colors.white, fontSize: 17, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 6),
                const Text(
                  "Gifts to odd seats score for Red Team; even seats score for Blue Team!",
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white54, fontSize: 11.5),
                ),
                const SizedBox(height: 16),
                if (isPkActive) ...[
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.06),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        Column(
                          children: [
                            Text(
                              (pkData?['redName'] ?? 'Red Team').toString(),
                              style: const TextStyle(
                                  color: Colors.redAccent, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              "${(pkData?['redScore'] as num?)?.toInt() ?? 0}",
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),

const Text("VS",
                            style: TextStyle(
                                color: Color(0xFFFFD700),
                                fontSize: 18,
                                fontWeight: FontWeight.w900)),
                        Column(
                          children: [
                            Text(
                              (pkData?['blueName'] ?? 'Blue Team').toString(),
                              style: const TextStyle(
                                  color: Color(0xFF2979FF), fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              "${(pkData?['blueScore'] as num?)?.toInt() ?? 0}",
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.redAccent,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      onPressed: () async {
                        final int rScore = (pkData?['redScore'] as num?)?.toInt() ?? 0;
                        final int bScore = (pkData?['blueScore'] as num?)?.toInt() ?? 0;
                        String resultMsg = "PK Ended in a Draw! 🤝";
                        if (rScore > bScore) {
                          resultMsg = "🏆 ${pkData?['redName'] ?? 'Red Team'} won the PK Battle!";
                        } else if (bScore > rScore) {
                          resultMsg = "🏆 ${pkData?['blueName'] ?? 'Blue Team'} won the PK Battle!";
                        }
                        await FirebaseFirestore.instance.collection('rooms').doc(roomId).set({
                          'pkBattle': {'active': false},
                        }, SetOptions(merge: true));
                        await _sendSystemChat(resultMsg);
                        if (ctx.mounted) Navigator.pop(ctx);
                      },
                      child: const Text("End PK Battle Now",
                          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ] else ...[
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: redCtrl,
                          style: const TextStyle(color: Colors.white, fontSize: 13),
                          decoration: InputDecoration(
                            labelText: "Left Side (Red)",
                            labelStyle: const TextStyle(color: Colors.redAccent, fontSize: 12),
                            filled: true,
                            fillColor: Colors.white.withOpacity(0.06),
                            border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide.none),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: TextField(

controller: blueCtrl,
                          style: const TextStyle(color: Colors.white, fontSize: 13),
                          decoration: InputDecoration(
                            labelText: "Right Side (Blue)",
                            labelStyle:
                                const TextStyle(color: Color(0xFF2979FF), fontSize: 12),
                            filled: true,
                            fillColor: Colors.white.withOpacity(0.06),
                            border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide.none),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [3, 5, 10].map((mins) {
                      final sel = selectedMinutes == mins;
                      return Expanded(
                        child: GestureDetector(
                          onTap: () => setSheetState(() => selectedMinutes = mins),
                          child: Container(
                            margin: const EdgeInsets.symmetric(horizontal: 4),
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            decoration: BoxDecoration(
                              color: sel
                                  ? const Color(0xFF2979FF)
                                  : Colors.white.withOpacity(0.08),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Center(
                              child: Text(
                                "$mins Min",
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12.5),
                              ),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 18),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFFFD700),
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      onPressed: () async {
                        final endMs = DateTime.now()
                            .add(Duration(minutes: selectedMinutes))
                            .millisecondsSinceEpoch;
                        await FirebaseFirestore.instance.collection('rooms').doc(roomId).set({
                          'pkBattle': {
                            'active': true,
                            'redName': redCtrl.text.trim().isEmpty
                                ? 'Red Team 🔥'
                                : redCtrl.text.trim(),
                            'blueName': blueCtrl.text.trim().isEmpty
                                ? 'Blue Team ⚡'
                                : blueCtrl.text.trim(),
                            'redScore': 0,
                            'blueScore': 0,
                            'endTimeMs': endMs,
                            'startedBy': userName,
                          },

}, SetOptions(merge: true));
                        await _sendSystemChat(
                            "🥊 $userName started a $selectedMinutes-minute PK Battle!");
                        if (ctx.mounted) Navigator.pop(ctx);
                      },
                      child: const Text("Start PK Battle",
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF130F26),
        borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
      ),
      padding: const EdgeInsets.only(top: 14, bottom: 24, left: 16, right: 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 38,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.white24,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 14),
          const Text(
            "Room Games & Tools",
            style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),
          GridView.count(
            crossAxisCount: 4,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 16,
            crossAxisSpacing: 10,
            children: [
              _buildToolItem(
                icon: Icons.casino,
                label: "Dragon Tiger",
                iconColor: const Color(0xFFFFD700),
                onTap: () {
                  final nav = Navigator.of(context);
                  nav.pop();
                  DragonTigerSheet.show(
                    nav.context,
                    roomId: roomId,
                    userName: userName,
                  );
                },
              ),
              _buildToolItem(
                icon: isVoiceOn ? Icons.volume_up : Icons.volume_off,
                label: isVoiceOn ? "Voice Off" : "Voice On",
                iconColor: isVoiceOn ? const Color(0xFF00E5FF) : Colors.redAccent,
                onTap: () {
                  onToggleVoice();
                  Navigator.pop(context);
                },
              ),
              _buildToolItem(
                icon: Icons.send_outlined,
                label: "Share",
                iconColor: Colors.white,
                onTap: () {
                  final nav = Navigator.of(context);
                  nav.pop();
                  _showShareSheet(nav.context);
                },
              ),
              _buildToolItem(
                icon: Icons.music_note,
                label: "Music",
                iconColor: const Color(0xFFFF4081),
                onTap: () {
                  final nav = Navigator.of(context);
                  nav.pop();
                  _showMusicSheet(nav.context);
                },
              ),
              _buildToolItem(
                icon: Icons.settings,
                label: "Room Settings",
                iconColor: const Color(0xFFFFD700),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (ctx) => RoomSettingsScreen(
                        roomId: roomId,
                        currentRoomTitle: roomTitle,
                      ),
                    ),
                  );
                },
              ),
              _buildToolItem(

icon: Icons.people_outline,
                label: "Room Admin",
                iconColor: const Color(0xFF00E5FF),
                onTap: () {
                  final nav = Navigator.of(context);
                  nav.pop();
                  if (!_canManageRoom) {
                    ScaffoldMessenger.of(nav.context).showSnackBar(
                      const SnackBar(content: Text("Only Host or Admins can manage admins")),
                    );
                    return;
                  }
                  _showAdminManagementSheet(nav.context);
                },
              ),
              _buildToolItem(
                icon: Icons.lock_outline,
                label: "Set Password",
                iconColor: const Color(0xFFFFD700),
                onTap: () {
                  final nav = Navigator.of(context);
                  nav.pop();
                  if (!_canManageRoom) {
                    ScaffoldMessenger.of(nav.context).showSnackBar(
                      const SnackBar(content: Text("Only Host or Admins can set password")),
                    );
                    return;
                  }
                  _showSetPasswordDialog(nav.context);
                },
              ),
              _buildToolItem(
                icon: Icons.mic,
                label: "Open all mic",
                iconColor: const Color(0xFF00E676),
                onTap: () {
                  final nav = Navigator.of(context);
                  nav.pop();
                  if (!_canManageRoom) {
                    ScaffoldMessenger.of(nav.context).showSnackBar(
                      const SnackBar(content: Text("Only Host or Admins can open all mics")),
                    );
                    return;
                  }
                  _setAllMicsState(nav.context, false);
                },
              ),
              _buildToolItem(
                icon: Icons.mic_off,
                label: "Close all mic",
                iconColor: Colors.redAccent,
                onTap: () {
                  final nav = Navigator.of(context);
                  nav.pop();
                  if (!_canManageRoom) {
                    ScaffoldMessenger.of(nav.context).showSnackBar(
                      const SnackBar(content: Text("Only Host or Admins can close all mics")),
                    );
                    return;
                  }
                  _setAllMicsState(nav.context, true);
                },
              ),
              _buildToolItem(
                icon: Icons.mail_outline,
                label: "Red Packet",
                iconColor: Colors.redAccent,
                onTap: () {
                  final nav = Navigator.of(context);
                  nav.pop();
                  _showRedPacketSheet(nav.context);
                },
              ),
              _buildToolItem(
                icon: Icons.work_outline,
                label: "Backpack",
                iconColor: const Color(0xFFFFB300),
                onTap: () {
                  final nav = Navigator.of(context);
                  nav.pop();
                  _showBackpackSheet(nav.context);
                },
              ),
              _buildToolItem(
                icon: Icons.sports_mma,
                label: "PK",
                iconColor: const Color(0xFF2979FF),
                onTap: () {
                  final nav = Navigator.of(context);
                  nav.pop();
                  if (!_canManageRoom) {
                    ScaffoldMessenger.of(nav.context).showSnackBar(
                      const SnackBar(content: Text("Only Host or Admins can manage PK")),
                    );
                    return;
                  }
                  _showPkSheet(nav.context);
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

Widget _buildToolItem({
    required IconData icon,
    required String label,
    required Color iconColor,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withOpacity(0.06),
            ),
            child: Icon(icon, color: iconColor, size: 22),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: const TextStyle(color: Colors.white70, fontSize: 10),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
