import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';

import 'vip_screen.dart';
import 'wallet_screen.dart';
import 'points_wallet_screen.dart';
import 'store_screen.dart';
import 'invitation_screen.dart';
import 'backpack_screen.dart';
import 'level_screen.dart';
import 'task_screen.dart';
import 'badge_screen.dart';
import 'host_center_screen.dart';
import 'agency_screen.dart';
import 'coin_seller_screen.dart';
import 'support_screen.dart';
import 'settings_screen.dart';
import '../widgets/lucky_island_dialog.dart';

bool _gte(num a, num b) {
  return a.compareTo(b).sign != -1;
}

bool _lte(num a, num b) {
  return a.compareTo(b).sign != 1;
}

dynamic _d(Object? v) {
  return v;
}

class ProfileScreen extends StatefulWidget {
  final int currentCoins;
  final Function(int)? onCoinsUpdated;

  const ProfileScreen({
    super.key,
    this.currentCoins = 0,
    this.onCoinsUpdated,
  });

  @override
  State createState() {
    return _ProfileScreenState();
  }
}

class _ProfileScreenState extends State {
  ProfileScreen get _w {
    return widget as ProfileScreen;
  }

  final User? _currentUser = FirebaseAuth.instance.currentUser;
  final ImagePicker _picker = ImagePicker();
  late int _coins;
  bool _isUploadingAvatar = false;
  bool _isAgencyOwnerFromDb = false;
  String _checkedAgentCacheKey = "";

  @override
  void initState() {
    super.initState();
    _coins = _w.currentCoins;
  }

  void _updateCoins(int newAmount) {
    setState(() {
      _coins = newAmount;
    });
    _w.onCoinsUpdated?.call(newAmount);
  }

  void _showSnack(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        backgroundColor:
            isError ? const Color(0xFFE54D42) : const Color(0xFF1F2329),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _copyId(String displayId) {
    Clipboard.setData(ClipboardData(text: displayId));
    _showSnack("ID $displayId copied to clipboard");
  }

  bool _isUserAgentFromMap(Map data) {
    if (data['isAgent'] == true) return true;
    if (data['isCoinSeller'] == true) return true;
    final String role = (data['role'] ?? '').toString().trim().toLowerCase();
    if (role == 'agent') return true;
    if (role == 'agency') return true;
    if (role == 'coinseller') return true;
    if (role == 'agency_owner') return true;
    final String agencyId = (data['agencyId'] ?? '').toString().trim();
    if (agencyId.isNotEmpty) return true;
    return false;
  }

  Future _verifyAgencyOwnershipFromDb(String uid, int numericId) async {
    if (uid.isEmpty) return;
    final String cacheKey = "${uid}_$numericId";
    if (_checkedAgentCacheKey == cacheKey) return;
    _checkedAgentCacheKey = cacheKey;

    try {
      final byUid = await FirebaseFirestore.instance
          .collection('agencies')
          .where('ownerUid', isEqualTo: uid)
          .limit(1)
          .get();
      if (byUid.docs.isNotEmpty) {
        if (mounted) {
          setState(() {
            _isAgencyOwnerFromDb = true;
          });
        }
        return;
      }
      if (numericId != 0) {
        final byNum = await FirebaseFirestore.instance
            .collection('agencies')
            .where('ownerNumericId', isEqualTo: numericId)
            .limit(1)
            .get();
        if (byNum.docs.isNotEmpty) {
          if (mounted) {
            setState(() {
              _isAgencyOwnerFromDb = true;
            });
          }
        }
      }
    } catch (_) {}
  }

  ImageProvider? _resolveAvatarProvider(String? avatarUrl) {
    if (avatarUrl == null) return null;
    if (avatarUrl.isEmpty) return null;
    if (avatarUrl.startsWith('data:image')) {
      try {
        final commaIdx = avatarUrl.indexOf(',');
        if (commaIdx != -1) {
          final Uint8List bytes =
              base64Decode(avatarUrl.substring(commaIdx + 1));
          return MemoryImage(bytes);
        }
      } catch (_) {
        return null;
      }
    }
    return NetworkImage(avatarUrl);
  }

  void _showAvatarPickerSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
          ),
          child: SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 10),
                Container(
                  width: 38,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.black12,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 14),
                  child: Text(
                    "Change Profile Photo",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF111827),
                    ),
                  ),
                ),
                const Divider(height: 1, color: Color(0xFFF1F5F9)),
                ListTile(
                  leading: const CircleAvatar(
                    backgroundColor: Color(0xFFE6F9F5),
                    child: Icon(Icons.photo_library_rounded,
                        color: Color(0xFF14B8A6)),
                  ),
                  title: const Text(
                    "Choose from Gallery",
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                  ),
                  subtitle: const Text(
                    "Select a photo from your phone gallery",
                    style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                  ),
                  onTap: () {
                    Navigator.pop(ctx);
                    _pickAndSaveAvatar(ImageSource.gallery);
                  },
                ),
                const Divider(height: 1, indent: 16, color: Color(0xFFF1F5F9)),
                ListTile(
                  leading: const CircleAvatar(
                    backgroundColor: Color(0xFFFFF7E6),
                    child: Icon(Icons.folder_open_rounded,
                        color: Color(0xFFF59E0B)),
                  ),
                  title: const Text(
                    "Choose from Files",
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                  ),
                  subtitle: const Text(
                    "Browse device storage and image folders",
                    style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                  ),
                  onTap: () {
                    Navigator.pop(ctx);
                    _pickAndSaveAvatar(ImageSource.gallery,
                        useMediaPicker: true);
                  },
                ),
                const Divider(height: 1, indent: 16, color: Color(0xFFF1F5F9)),
                ListTile(
                  leading: const CircleAvatar(
                    backgroundColor: Color(0xFFEEF2FF),
                    child: Icon(Icons.camera_alt_rounded,
                        color: Color(0xFF4F46E5)),
                  ),
                  title: const Text(
                    "Take Photo",
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                  ),
                  onTap: () {
                    Navigator.pop(ctx);
                    _pickAndSaveAvatar(ImageSource.camera);
                  },
                ),
                Container(height: 8, color: const Color(0xFFF3F5F7)),
                InkWell(
                  onTap: () {
                    Navigator.pop(ctx);
                  },
                  child: const SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: Center(
                      child: Text(
                        "Cancel",
                        style: TextStyle(
                          fontSize: 15.5,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF64748B),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future _pickAndSaveAvatar(
    ImageSource source, {
    bool useMediaPicker = false,
  }) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      _showSnack("Please sign in to update your profile photo.", isError: true);
      return;
    }

    try {
      XFile? picked;
      if (useMediaPicker) {
        picked = await _picker.pickMedia(
          maxWidth: 512,
          maxHeight: 512,
          imageQuality: 75,
        );
      } else {
        picked = await _picker.pickImage(
          source: source,
          maxWidth: 512,
          maxHeight: 512,
          imageQuality: 75,
        );
      }

      if (picked == null) return;

      setState(() {
        _isUploadingAvatar = true;
      });

      final Uint8List imageBytes = await picked.readAsBytes();
      String savedUrl = "";

      try {
        final storageRef = FirebaseStorage.instance
            .ref()
            .child('profile_avatars')
            .child('${user.uid}_${DateTime.now().millisecondsSinceEpoch}.jpg');

        final uploadTask = await storageRef.putData(
          imageBytes,
          SettableMetadata(contentType: 'image/jpeg'),
        );
        savedUrl = await uploadTask.ref.getDownloadURL();
      } catch (_) {
        if (_lte(imageBytes.length, 700000)) {
          savedUrl = "data:image/jpeg;base64,${base64Encode(imageBytes)}";
        } else {
          final XFile? smaller = await _picker.pickImage(
            source: source,
            maxWidth: 256,
            maxHeight: 256,
            imageQuality: 60,
          );
          if (smaller != null) {
            final smallBytes = await smaller.readAsBytes();
            savedUrl = "data:image/jpeg;base64,${base64Encode(smallBytes)}";
          }
        }
      }

      if (savedUrl.isEmpty) {
        throw Exception("Could not process selected image");
      }

      await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
        'avatarUrl': _d(savedUrl),
        'photoURL': _d(savedUrl),
        'updatedAt': _d(FieldValue.serverTimestamp()),
      }, SetOptions(merge: true));

      if (savedUrl.startsWith('http')) {
        try {
          await user.updatePhotoURL(savedUrl);
        } catch (_) {}
      }

      _showSnack("Profile photo updated successfully!");
    } catch (e) {
      _showSnack("Failed to update photo: $e", isError: true);
    } finally {
      if (mounted) {
        setState(() {
          _isUploadingAvatar = false;
        });
      }
    }
  }

  void _openEditProfile({
    required String currentName,
    required String currentBio,
    required String currentGender,
    required String currentCountry,
    required String? avatarUrl,
    required int numericId,
  }) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) {
          return _EditProfileScreen(
            currentName: currentName,
            currentBio: currentBio,
            currentGender: currentGender,
            currentCountry: currentCountry,
            currentAvatarUrl: avatarUrl,
            numericId: numericId,
            onChangePhotoTap: _showAvatarPickerSheet,
            resolveAvatar: _resolveAvatarProvider,
          );
        },
      ),
    );
  }

  void _openVipClub() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) {
          return const VipScreen();
        },
      ),
    );
  }

  void _openLuckyIsland() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) {
        return const LuckyIslandDialog();
      },
    );
  }

  void _openPointsWallet() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) {
          return const PointsWalletScreen();
        },
      ),
    );
  }

  void _openSettings() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) {
          return const SettingsScreen();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    String uid = "";
    if (_currentUser != null) {
      uid = _currentUser!.uid;
    }

    Stream? userStream;
    if (uid.isNotEmpty) {
      userStream =
          FirebaseFirestore.instance.collection('users').doc(uid).snapshots();
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF3F5F7),
      body: Stack(
        children: [
          StreamBuilder(
            stream: userStream,
            builder: (context, snapshot) {
              DocumentSnapshot? docSnap;
              if (snapshot.hasData) {
                docSnap = snapshot.data as DocumentSnapshot?;
              }

              Object? rawData;
              if (docSnap != null) {
                if (docSnap.exists) {
                  rawData = docSnap.data();
                }
              }
              final Map userData = rawData is Map ? rawData : {};

              String fallbackName = "User";
              if (_currentUser != null) {
                if (_currentUser!.displayName != null) {
                  if (_currentUser!.displayName!.isNotEmpty) {
                    fallbackName = _currentUser!.displayName!;
                  }
                }
              }

              final String displayName =
                  (userData['name'] ?? userData['nickname'] ?? fallbackName)
                      .toString();
              final String bio = (userData['bio'] ?? '').toString();
              final String gender = (userData['gender'] ?? 'Male').toString();
              final String country =
                  (userData['country'] ?? 'Ethiopia 🇪🇹').toString();

              final int numericId =
                  (userData['numericId'] as num?)?.toInt() ?? 0;
              String displayId = "000000";
              if (numericId != 0) {
                displayId = numericId.toString();
              } else if (_gte(uid.length, 6)) {
                displayId = uid.substring(0, 6).toUpperCase();
              } else if (uid.isNotEmpty) {
                displayId = uid;
              }

              _verifyAgencyOwnershipFromDb(uid, numericId);
              bool isAuthorizedAgent = _isUserAgentFromMap(userData);
              if (_isAgencyOwnerFromDb) {
                isAuthorizedAgent = true;
              }

              final int firestoreCoins =
                  (userData['coins'] as num?)?.toInt() ?? _coins;
              final double points =
                  (userData['diamonds'] as num?)?.toDouble() ??
                      (userData['points'] as num?)?.toDouble() ??
                      0.0;

              final int followedCount =
                  (userData['followedCount'] as num?)?.toInt() ?? 0;
              final int followingCount =
                  (userData['followingCount'] as num?)?.toInt() ?? 0;
              final int friendsCount =
                  (userData['friendsCount'] as num?)?.toInt() ?? 0;

              final int wealthExp =
                  (userData['wealthExp'] as num?)?.toInt() ?? 0;
              final int rawWealthLvl =
                  (userData['wealthLevel'] as num?)?.toInt() ?? 0;
              final int computedWealthLvl =
                  wealthExp > 0 ? ((wealthExp ~/ 250000) + 1).clamp(1, 99) : 0;
              final int wealthLevel = rawWealthLvl > 0
                  ? rawWealthLvl.clamp(1, 99)
                  : computedWealthLvl;

              int charmExp = (userData['charmExp'] as num?)?.toInt() ?? 0;
              final int recPts =
                  (userData['receivedGiftPoints'] as num?)?.toInt() ?? 0;
              if (recPts > charmExp) charmExp = recPts;
              final int rawCharmLvl =
                  (userData['charmLevel'] as num?)?.toInt() ?? 0;
              final int computedCharmLvl =
                  charmExp > 0 ? ((charmExp ~/ 100000) + 1).clamp(1, 99) : 0;
              final int charmLevel = rawCharmLvl > 0
                  ? rawCharmLvl.clamp(1, 99)
                  : computedCharmLvl;
              final int chatLevel =
                  (userData['chatLevel'] as num?)?.toInt() ?? 0;
              final int vipLevel =
                  (userData['vipLevel'] as num?)?.toInt() ?? 0;
              final int activeVipFrame =
                  (userData['activeVipFrameLevel'] as num?)?.toInt() ??
                      vipLevel;
              final Timestamp? vipExpiresAt =
                  userData['vipExpiresAt'] as Timestamp?;
              bool isVipActive = false;
              if (vipLevel > 0) {
                if (vipExpiresAt == null) {
                  isVipActive = true;
                } else if (vipExpiresAt.toDate().isAfter(DateTime.now())) {
                  isVipActive = true;
                }
              }
              final int effectiveFrameLevel =
                  isVipActive ? activeVipFrame : 0;

              final String? agencyId = userData['agencyId']?.toString();
              final String? avatarUrl =
                  (userData['avatarUrl'] ?? userData['photoURL'])?.toString();

              bool hasAgency = false;
              if (agencyId != null) {
                if (agencyId.isNotEmpty) {
                  hasAgency = true;
                }
              }

              return SingleChildScrollView(
                child: Column(
                  children: [
                    Container(
                      padding: EdgeInsets.fromLTRB(
                        16,
                        MediaQuery.of(context).padding.top + 14,
                        16,
                        14,
                      ),
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Color(0xFFC2ECE3),
                            Color(0xFFE3F6F2),
                            Color(0xFFF3F5F7),
                          ],
                        ),
                      ),
                      child: Column(
                        children: [
                          _buildHeaderSection(
                            name: displayName,
                            bio: bio,
                            gender: gender,
                            country: country,
                            displayId: displayId,
                            numericId: numericId,
                            avatarUrl: avatarUrl,
                            wealthLevel: wealthLevel,
                            charmLevel: charmLevel,
                            chatLevel: chatLevel,
                            vipLevel: isVipActive ? vipLevel : 0,
                            activeFrameLevel: effectiveFrameLevel,
                            hasAgency: hasAgency,
                            followed: followedCount,
                            following: followingCount,
                            friends: friendsCount,
                          ),
                          const SizedBox(height: 16),
                          _buildVipClubCard(
                            activeVipLevel: isVipActive ? vipLevel : 0,
                          ),
                        ],
                      ),
                    ),

                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      child: _buildAssetsCard(
                        coins: firestoreCoins,
                        points: points,
                        numericId: numericId,
                      ),
                    ),
                    const SizedBox(height: 12),

                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      child: _buildMainFeaturesGrid(
                        coins: firestoreCoins,
                        numericId: numericId,
                      ),
                    ),
                    const SizedBox(height: 12),

                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      child: _buildPromoRechargeBanner(
                        coins: firestoreCoins,
                        numericId: numericId,
                      ),
                    ),
                    const SizedBox(height: 12),

                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      child: _buildBusinessSection(
                        numericId: numericId,
                        showCoinSeller: isAuthorizedAgent,
                      ),
                    ),
                    const SizedBox(height: 28),
                  ],
                ),
              );
            },
          ),
          if (_isUploadingAvatar)
            Container(
              color: Colors.black45,
              child: const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(color: Color(0xFF14B8A6)),
                    SizedBox(height: 12),
                    Text(
                      "Uploading profile photo...",
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildHeaderSection({
    required String name,
    required String bio,
    required String gender,
    required String country,
    required String displayId,
    required int numericId,
    required String? avatarUrl,
    required int wealthLevel,
    required int charmLevel,
    required int chatLevel,
    required int vipLevel,
    required int activeFrameLevel,
    required bool hasAgency,
    required int followed,
    required int following,
    required int friends,
  }) {
    final ImageProvider? avatarImg = _resolveAvatarProvider(avatarUrl);

    final Widget baseAvatar = Container(
      width: 74,
      height: 74,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 2.8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.14),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: CircleAvatar(
        backgroundColor: const Color(0xFF9B87B5),
        backgroundImage: avatarImg,
        child: avatarImg == null
            ? const Icon(
                Icons.person_rounded,
                size: 42,
                color: Colors.white,
              )
            : null,
      ),
    );

    return Column(
      children: [
        Row(
          children: [
            GestureDetector(
              onTap: _showAvatarPickerSheet,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  activeFrameLevel > 0
                      ? VipAvatarFrame(
                          vipLevel: activeFrameLevel,
                          size: 74,
                          showBadge: true,
                          child: CircleAvatar(
                            backgroundColor: const Color(0xFF9B87B5),
                            backgroundImage: avatarImg,
                            child: avatarImg == null
                                ? const Icon(
                                    Icons.person_rounded,
                                    size: 40,
                                    color: Colors.white,
                                  )
                                : null,
                          ),
                        )
                      : baseAvatar,
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      width: 25,
                      height: 25,
                      decoration: BoxDecoration(
                        color: const Color(0xFF14B8A6),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                      child: const Icon(
                        Icons.camera_alt_rounded,
                        color: Colors.white,
                        size: 13,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () {
                  _openEditProfile(
                    currentName: name,
                    currentBio: bio,
                    currentGender: gender,
                    currentCountry: country,
                    avatarUrl: avatarUrl,
                    numericId: numericId,
                  );
                },
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Flexible(
                                child: Text(
                                  name,
                                  style: const TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.w900,
                                    color: Color(0xFF111827),
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 6),
                              const Icon(
                                Icons.edit_rounded,
                                size: 16,
                                color: Color(0xFF14B8A6),
                              ),
                            ],
                          ),
                          const SizedBox(height: 5),
                          Wrap(
                            spacing: 6,
                            runSpacing: 4,
                            children: [
                              if (vipLevel > 0)
                                _buildLevelTag(
                                  Icons.workspace_premium_rounded,
                                  "VIP$vipLevel",
                                  const Color(0xFFD97706),
                                ),
                              _buildLevelTag(Icons.shield, "$wealthLevel",
                                  const Color(0xFF14B8A6)),
                              _buildLevelTag(Icons.arrow_upward, "$charmLevel",
                                  const Color(0xFF22C55E)),
                              _buildLevelTag(Icons.auto_awesome, "$chatLevel",
                                  const Color(0xFF9333EA)),
                              if (hasAgency || _isAgencyOwnerFromDb)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 7, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF2563EB),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: const Text(
                                    "AGENCY",
                                    style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 9.5,
                                        fontWeight: FontWeight.w800),
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          GestureDetector(
                            onTap: () {
                              _copyId(displayId);
                            },
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  "ID:$displayId",
                                  style: const TextStyle(
                                      fontSize: 13,
                                      color: Color(0xFF475569),
                                      fontWeight: FontWeight.w700),
                                ),
                                const SizedBox(width: 6),
                                const Icon(Icons.copy_rounded,
                                    size: 14, color: Color(0xFF475569)),
                              ],
                            ),
                          ),
                          if (bio.isNotEmpty) ...[
                            const SizedBox(height: 4),
                            Text(
                              bio,
                              style: const TextStyle(
                                fontSize: 12,
                                color: Color(0xFF64748B),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ],
                      ),
                    ),
                    const Icon(Icons.chevron_right_rounded,
                        color: Color(0xFF475569), size: 28),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 18),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildStatItem("$followed", "Followed"),
            Container(height: 22, width: 1, color: Colors.black12),
            _buildStatItem("$following", "Following"),
            Container(height: 22, width: 1, color: Colors.black12),
            _buildStatItem("$friends", "Friends"),
          ],
        ),
      ],
    );
  }

  Widget _buildLevelTag(IconData icon, String value, Color bgColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 10, color: Colors.white),
          const SizedBox(width: 2.5),
          Text(
            value,
            style: const TextStyle(
                color: Colors.white, fontSize: 10, fontWeight: FontWeight.w800),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String count, String label) {
    return Column(
      children: [
        Text(
          count,
          style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w900,
              color: Color(0xFF111827)),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
              color: Color(0xFF475569)),
        ),
      ],
    );
  }

  Widget _buildVipClubCard({int activeVipLevel = 0}) {
    final String subtitleText = activeVipLevel > 0
        ? "VIP$activeVipLevel Active • Claim your free coins daily"
        : "Upgrade to VIP and get free coins daily";
    final String buttonLabel = activeVipLevel > 0 ? "My VIP" : "Get VIP";

    return GestureDetector(
      onTap: _openVipClub,
      behavior: HitTestBehavior.opaque,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF3E2D1D), Color(0xFF26190E)],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.12),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          children: [
            const Icon(Icons.workspace_premium,
                color: Color(0xFFFFD580), size: 32),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "VIP Club",
                    style: TextStyle(
                        color: Color(0xFFFFE099),
                        fontSize: 15.5,
                        fontWeight: FontWeight.w900),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitleText,
                    style: const TextStyle(
                        color: Color(0xFFE5D3C5),
                        fontSize: 11.5,
                        fontWeight: FontWeight.w500),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFFFDF9E), Color(0xFFF3BA2F)],
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                buttonLabel,
                style: const TextStyle(
                    color: Color(0xFF2B1D10),
                    fontSize: 12.5,
                    fontWeight: FontWeight.w900),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAssetsCard({
    required int coins,
    required double points,
    required int numericId,
  }) {
    String currentUid = "";
    if (_currentUser != null) {
      currentUid = _currentUser!.uid;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: InkWell(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) {
                      return WalletScreen(
                        currentCoins: coins,
                        userNumericId: numericId,
                        userUid: currentUid,
                        onCoinsRecharged: _updateCoins,
                      );
                    },
                  ),
                );
              },
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Text(
                        "Coins",
                        style: TextStyle(
                            fontSize: 13.5,
                            color: Color(0xFF334155),
                            fontWeight: FontWeight.w700),
                      ),
                      SizedBox(width: 3),
                      Icon(Icons.chevron_right_rounded,
                          size: 18, color: Color(0xFF64748B)),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(Icons.monetization_on_rounded,
                          color: Color(0xFFF59E0B), size: 26),
                      const SizedBox(width: 7),
                      Text(
                        "$coins",
                        style: const TextStyle(
                            fontSize: 21,
                            fontWeight: FontWeight.w900,
                            color: Color(0xFF111827)),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          Container(width: 1, height: 40, color: const Color(0xFFE2E8F0)),
          const SizedBox(width: 18),
          Expanded(
            child: InkWell(
              onTap: _openPointsWallet,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Text(
                        "Points",
                        style: TextStyle(
                            fontSize: 13.5,
                            color: Color(0xFF334155),
                            fontWeight: FontWeight.w700),
                      ),
                      SizedBox(width: 3),
                      Icon(Icons.chevron_right_rounded,
                          size: 18, color: Color(0xFF64748B)),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(Icons.stars_rounded,
                          color: Color(0xFF14B8A6), size: 26),
                      const SizedBox(width: 7),
                      Text(
                        points.toInt().toString(),
                        style: const TextStyle(
                            fontSize: 21,
                            fontWeight: FontWeight.w900,
                            color: Color(0xFF14B8A6)),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMainFeaturesGrid({required int coins, required int numericId}) {
    String currentUid = "";
    if (_currentUser != null) {
      currentUid = _currentUser!.uid;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: GridView.count(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        crossAxisCount: 4,
        mainAxisSpacing: 16,
        crossAxisSpacing: 6,
        childAspectRatio: 0.88,
        children: [
          _buildBoldFeatureTile(
            icon: Icons.account_balance_wallet_rounded,
            colors: const [Color(0xFFFFB703), Color(0xFFFB8500)],
            label: "Recharge",
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) {
                    return WalletScreen(
                      currentCoins: coins,
                      userNumericId: numericId,
                      userUid: currentUid,
                      onCoinsRecharged: _updateCoins,
                    );
                  },
                ),
              );
            },
          ),
          _buildBoldFeatureTile(
            icon: Icons.storefront_rounded,
            colors: const [Color(0xFFFF5A5F), Color(0xFFE01E37)],
            label: "Store",
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) {
                    return StoreScreen(
                      userCoins: coins,
                      userNumericId: numericId,
                      onCoinsDeducted: _updateCoins,
                    );
                  },
                ),
              );
            },
          ),
          _buildBoldFeatureTile(
            icon: Icons.mark_email_unread_rounded,
            colors: const [Color(0xFFFF758F), Color(0xFFC9184A)],
            label: "Invitation",
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) {
                    return const InvitationScreen();
                  },
                ),
              );
            },
          ),
          _buildBoldFeatureTile(
            icon: Icons.backpack_rounded,
            colors: const [Color(0xFF4CC9F0), Color(0xFF3A86FF)],
            label: "Backpack",
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) {
                    return const BackpackScreen();
                  },
                ),
              );
            },
          ),
          _buildBoldFeatureTile(
            icon: Icons.beach_access_rounded,
            colors: const [Color(0xFF52B788), Color(0xFF2D6A4F)],
            label: "Lucky Island",
            onTap: _openLuckyIsland,
          ),
          _buildBoldFeatureTile(
            icon: Icons.military_tech_rounded,
            colors: const [Color(0xFFB5179E), Color(0xFF7209B7)],
            label: "Level",
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) {
                    return const LevelScreen();
                  },
                ),
              );
            },
          ),
          _buildBoldFeatureTile(
            icon: Icons.event_available_rounded,
            colors: const [Color(0xFF2EC4B6), Color(0xFF0096C7)],
            label: "Task",
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) {
                    return const TaskScreen();
                  },
                ),
              );
            },
          ),
          _buildBoldFeatureTile(
            icon: Icons.verified_rounded,
            colors: const [Color(0xFFFF9E00), Color(0xFFFF6D00)],
            label: "Badge",
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) {
                    return const BadgeScreen();
                  },
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildPromoRechargeBanner(
      {required int coins, required int numericId}) {
    String currentUid = "";
    if (_currentUser != null) {
      currentUid = _currentUser!.uid;
    }

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) {
              return WalletScreen(
                currentCoins: coins,
                userNumericId: numericId,
                userUid: currentUid,
                onCoinsRecharged: _updateCoins,
              );
            },
          ),
        );
      },
      child: Container(
        width: double.infinity,
        height: 94,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: const LinearGradient(
            colors: [Color(0xFFEF233C), Color(0xFFD90429)],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFEF233C).withOpacity(0.28),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        padding: const EdgeInsets.symmetric(horizontal: 18),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "UP TO 60% OFF",
                  style: TextStyle(
                      color: Color(0xFFFFE58F),
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.8,
                      fontSize: 11.5),
                ),
                SizedBox(height: 3),
                Text(
                  "COIN RECHARGE",
                  style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                      fontSize: 19),
                ),
              ],
            ),
            Icon(Icons.savings_rounded, color: Color(0xFFFFD166), size: 46),
          ],
        ),
      ),
    );
  }

  Widget _buildBusinessSection({
    required int numericId,
    required bool showCoinSeller,
  }) {
    final List items = [
      _buildTealServiceTile(
        icon: Icons.stars_rounded,
        label: "Points Wallet",
        onTap: _openPointsWallet,
      ),
      _buildTealServiceTile(
        icon: Icons.record_voice_over_rounded,
        label: "Host Center",
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) {
                return const HostCenterScreen();
              },
            ),
          );
        },
      ),
      _buildTealServiceTile(
        icon: Icons.business_center_rounded,
        label: "Agency",
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) {
                return AgencyScreen(userNumericId: numericId);
              },
            ),
          );
        },
      ),
      if (showCoinSeller)
        _buildTealServiceTile(
          icon: Icons.currency_exchange_rounded,
          label: "Coin Seller",
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) {
                  return const CoinSellerScreen();
                },
              ),
            );
          },
        ),
      _buildTealServiceTile(
        icon: Icons.headset_mic_rounded,
        label: "Support",
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) {
                return const SupportScreen();
              },
            ),
          );
        },
      ),
      _buildTealServiceTile(
        icon: Icons.settings_rounded,
        label: "Settings",
        onTap: _openSettings,
      ),
    ];

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: GridView.count(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        crossAxisCount: 4,
        mainAxisSpacing: 16,
        crossAxisSpacing: 6,
        childAspectRatio: 0.9,
        children: List.generate(items.length, (i) {
          return items[i] as Widget;
        }),
      ),
    );
  }

  Widget _buildBoldFeatureTile({
    required IconData icon,
    required List colors,
    required String label,
    required VoidCallback onTap,
  }) {
    final List typedColors = List.generate(colors.length, (i) {
      return colors[i] as Color;
    });
    final Color lastColor = typedColors.last as Color;

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  typedColors[0] as Color,
                  lastColor,
                ],
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: lastColor.withOpacity(0.32),
                  blurRadius: 6,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Icon(icon, color: Colors.white, size: 28),
          ),
          const SizedBox(height: 7),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w800,
              color: Color(0xFF1E293B),
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildTealServiceTile({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            color: const Color(0xFF14B8A6),
            size: 34,
          ),
          const SizedBox(height: 7),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w800,
              color: Color(0xFF1E293B),
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// FULL EDIT PROFILE PAGE (Photo + Nickname + Bio + Gender + Country)
// ============================================================================
class _EditProfileScreen extends StatefulWidget {
  final String currentName;
  final String currentBio;
  final String currentGender;
  final String currentCountry;
  final String? currentAvatarUrl;
  final int numericId;
  final VoidCallback onChangePhotoTap;
  final ImageProvider? Function(String? url) resolveAvatar;

  const _EditProfileScreen({
    required this.currentName,
    required this.currentBio,
    required this.currentGender,
    required this.currentCountry,
    required this.currentAvatarUrl,
    required this.numericId,
    required this.onChangePhotoTap,
    required this.resolveAvatar,
  });

  @override
  State createState() {
    return _EditProfileScreenState();
  }
}

class _EditProfileScreenState extends State {
  _EditProfileScreen get _w {
    return widget as _EditProfileScreen;
  }

  late TextEditingController _nameController;
  late TextEditingController _bioController;
  late String _selectedGender;
  late String _selectedCountry;
  bool _saving = false;

  static const List _countries = [
    "Ethiopia 🇪🇹",
    "Saudi Arabia 🇸🇦",
    "UAE 🇦🇪",
    "Kuwait 🇰🇼",
    "Qatar 🇶🇦",
    "USA 🇺🇸",
    "UK 🇬🇧",
    "Global 🌍",
  ];

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: _w.currentName);
    _bioController = TextEditingController(text: _w.currentBio);
    _selectedGender =
        _w.currentGender.isNotEmpty ? _w.currentGender : "Male";
    _selectedCountry = _countries.contains(_w.currentCountry)
        ? _w.currentCountry
        : "Ethiopia 🇪🇹";
  }

  @override
  void dispose() {
    _nameController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  Future _saveProfile() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final String newName = _nameController.text.trim();
    if (newName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Nickname cannot be empty.")),
      );
      return;
    }

    setState(() {
      _saving = true;
    });
    try {
      final String newBio = _bioController.text.trim();
      final String flagOnly = _selectedCountry.split(' ').last;

      await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
        'name': _d(newName),
        'nickname': _d(newName),
        'bio': _d(newBio),
        'gender': _d(_selectedGender),
        'country': _d(_selectedCountry),
        'flag': _d(flagOnly),
        'updatedAt': _d(FieldValue.serverTimestamp()),
      }, SetOptions(merge: true));

      try {
        await user.updateDisplayName(newName);
      } catch (_) {}

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            backgroundColor: Color(0xFF14B8A6),
            content: Text(
              "Profile saved permanently!",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Failed to save profile: $e")),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _saving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final uid = user?.uid ?? "";

    return Scaffold(
      backgroundColor: const Color(0xFFF3F5F7),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF3F5F7),
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new,
              color: Color(0xFF111827), size: 19),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        title: const Text(
          "Edit Profile",
          style: TextStyle(
            color: Color(0xFF111827),
            fontSize: 18,
            fontWeight: FontWeight.w800,
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12, top: 10, bottom: 10),
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF14B8A6),
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              onPressed: _saving ? null : _saveProfile,
              child: const Text(
                "Save",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5),
              ),
            ),
          ),
        ],
      ),
      body: StreamBuilder(
        stream: uid.isNotEmpty
            ? FirebaseFirestore.instance.collection('users').doc(uid).snapshots()
            : null,
        builder: (context, snapshot) {
          String? liveAvatar = _w.currentAvatarUrl;
          if (snapshot.hasData) {
            final doc = snapshot.data as DocumentSnapshot?;
            final data = doc?.data() as Map?;
            if (data != null) {
              liveAvatar =
                  (data['avatarUrl'] ?? data['photoURL'] ?? liveAvatar)
                      ?.toString();
            }
          }
          final avatarImg = _w.resolveAvatar(liveAvatar);

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                GestureDetector(
                  onTap: _w.onChangePhotoTap,
                  child: Column(
                    children: [
                      Stack(
                        clipBehavior: Clip.none,
                        children: [
                          Container(
                            width: 96,
                            height: 96,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border:
                                  Border.all(color: Colors.white, width: 3.5),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.12),
                                  blurRadius: 12,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: CircleAvatar(
                              backgroundColor: const Color(0xFF9B87B5),
                              backgroundImage: avatarImg,
                              child: avatarImg == null
                                  ? const Icon(Icons.person_rounded,
                                      size: 50, color: Colors.white)
                                  : null,
                            ),
                          ),
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: Container(
                              width: 30,
                              height: 30,
                              decoration: BoxDecoration(
                                color: const Color(0xFF14B8A6),
                                shape: BoxShape.circle,
                                border:
                                    Border.all(color: Colors.white, width: 2.2),
                              ),
                              child: const Icon(Icons.camera_alt_rounded,
                                  color: Colors.white, size: 15),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        "Tap to change photo (Gallery / Files)",
                        style: TextStyle(
                          color: Color(0xFF14B8A6),
                          fontSize: 12.5,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 22),

                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Nickname",
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF475569),
                        ),
                      ),
                      const SizedBox(height: 6),
                      TextField(
                        controller: _nameController,
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF111827),
                        ),
                        decoration: InputDecoration(
                          hintText: "Enter your nickname",
                          filled: true,
                          fillColor: const Color(0xFFF3F5F7),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        "Gender",
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF475569),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Expanded(
                            child: GestureDetector(
                              onTap: () {
                                setState(() {
                                  _selectedGender = "Male";
                                });
                              },
                              child: Container(
                                height: 44,
                                decoration: BoxDecoration(
                                  color: _selectedGender == "Male"
                                      ? const Color(0xFF14B8A6)
                                      : const Color(0xFFF3F5F7),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Center(
                                  child: Text(
                                    "♂ Male",
                                    style: TextStyle(
                                      fontWeight: FontWeight.w700,
                                      color: _selectedGender == "Male"
                                          ? Colors.white
                                          : const Color(0xFF475569),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: GestureDetector(
                              onTap: () {
                                setState(() {
                                  _selectedGender = "Female";
                                });
                              },
                              child: Container(
                                height: 44,
                                decoration: BoxDecoration(
                                  color: _selectedGender == "Female"
                                      ? const Color(0xFFEC4899)
                                      : const Color(0xFFF3F5F7),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Center(
                                  child: Text(
                                    "♀ Female",
                                    style: TextStyle(
                                      fontWeight: FontWeight.w700,
                                      color: _selectedGender == "Female"
                                          ? Colors.white
                                          : const Color(0xFF475569),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        "Country / Region",
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF475569),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF3F5F7),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton(
                            value: _selectedCountry,
                            isExpanded: true,
                            items: _countries.map((rawC) {
                              final String c = rawC.toString();
                              return DropdownMenuItem(
                                value: c,
                                child: Text(
                                  c,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF111827),
                                  ),
                                ),
                              );
                            }).toList(),
                            onChanged: (val) {
                              if (val != null) {
                                setState(() {
                                  _selectedCountry = val.toString();
                                });
                              }
                            },
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        "Bio",
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF475569),
                        ),
                      ),
                      const SizedBox(height: 6),
                      TextField(
                        controller: _bioController,
                        maxLines: 3,
                        maxLength: 100,
                        style: const TextStyle(
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF111827),
                        ),
                        decoration: InputDecoration(
                          hintText: "Write something about yourself...",
                          filled: true,
                          fillColor: const Color(0xFFF3F5F7),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
