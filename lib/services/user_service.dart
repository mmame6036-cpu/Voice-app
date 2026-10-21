import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:flutter/foundation.dart';

class UserService {
  static final UserService _instance = UserService._internal();
  factory UserService() => _instance;
  UserService._internal();

  static const String serverUrl = 'https://voice-app-2-jd95.onrender.com';
  static const String agoraAppId = '1523b6d3b8144281a1a21f28bbbd7fef';

  String userId = '';
  String userName = '';
  String avatar = '';
  String invitedBy = '';
  int _coins = 0;
  int _points = 0;
  bool isOwner = false;
  bool isInitialized = false;

  // Face Verification & Task Lock State
  bool isFaceVerified = false;

  // Backpack Equipment
  String equippedFrame = '';
  String equippedEntry = '';
  String equippedTheme = '';

  int get coins => _coins;
  set coins(int value) {
    _coins = value;
    _saveToStorage();
    _syncBalanceToServer();
  }

  int get points => _points;
  set points(int value) {
    _points = value;
    _saveToStorage();
  }

  void setFaceVerified(bool value) {
    isFaceVerified = value;
    _saveToStorage();
    _syncFaceVerificationToServer();
  }

  void equipItem(String category, String itemName) {
    if (category == 'Frame') {
      equippedFrame = equippedFrame == itemName ? '' : itemName;
    } else if (category == 'Entry') {
      equippedEntry = equippedEntry == itemName ? '' : itemName;
    } else if (category == 'Theme') {
      equippedTheme = equippedTheme == itemName ? '' : itemName;
    }
    _saveToStorage();
  }

  Future<File> _getStorageFile() async {
    final dir = Directory.systemTemp;
    return File('${dir.path}/nile_voice_permanent_user.json');
  }

  Future<void> initializeUser({String? inviterId}) async {
    if (isInitialized && userId.isNotEmpty) {
      await refreshUserData();
      return;
    }

    try {
      final file = await _getStorageFile();

      // 1. Check local persistent profile
      if (await file.exists()) {
        final content = await file.readAsString();
        final localData = jsonDecode(content);
        if (localData['userId'] != null && localData['userId'].toString().isNotEmpty) {
          userId = localData['userId'].toString();
          userName = localData['name'] ?? 'User_$userId';
          avatar = localData['avatar'] ?? '';
          _coins = localData['coins'] ?? 0;
          _points = localData['points'] ?? 0;
          invitedBy = localData['invitedBy'] ?? '';
          isFaceVerified = localData['isFaceVerified'] == true;
          equippedFrame = localData['equippedFrame'] ?? '';
          equippedEntry = localData['equippedEntry'] ?? '';
          equippedTheme = localData['equippedTheme'] ?? '';
          isOwner = (userId == '1000');
          isInitialized = true;

          // Sync with database
          await refreshUserData();
          return;
        }
      }

      // 2. Register fallback device account if no profile exists
      final randomDeviceSeed = Random().nextInt(899999) + 100000;
      final deviceKey = 'dev_${Platform.operatingSystem}_$randomDeviceSeed';

      final client = HttpClient();
      client.connectionTimeout = const Duration(seconds: 8);
      final request = await client.postUrl(Uri.parse('$serverUrl/api/register-user'));
      request.headers.set('content-type', 'application/json');

      request.add(utf8.encode(jsonEncode({
        'deviceId': deviceKey,
        'name': 'User_$randomDeviceSeed',
        'isOwner': false,
        'inviterId': inviterId ?? '',
      })));

      final response = await request.close();
      if (response.statusCode == 200) {
        final body = await response.transform(utf8.decoder).join();
        final resData = jsonDecode(body);

        if (resData['success'] == true && resData['user'] != null) {
          _updateFromUserMap(resData['user']);
          await _saveToStorage();
          isInitialized = true;
          return;
        }
      }
    } catch (e) {
      debugPrint('UserService Initialization Error: $e');
    }

// Default initialization if server is unreachable
    if (userId.isEmpty) {
      userId = '1001';
      userName = 'User_$userId';
      _coins = 1000;
      _points = 0;
      isFaceVerified = false;
      isOwner = false;
      await _saveToStorage();
    }

    isInitialized = true;
  }

  // Set user directly after successful Google Login
  Future<void> setUserData(Map<String, dynamic> userData) async {
    _updateFromUserMap(userData);
    await _saveToStorage();
  }

  // Refresh latest coins, points, and profile from MongoDB
  Future<void> refreshUserData() async {
    if (userId.isEmpty) return;
    try {
      final client = HttpClient();
      client.connectionTimeout = const Duration(seconds: 8);
      final request = await client.getUrl(
        Uri.parse('$serverUrl/api/search-user?userId=${userId.trim()}'),
      );
      final response = await request.close();

      if (response.statusCode == 200) {
        final body = await response.transform(utf8.decoder).join();
        final data = jsonDecode(body);
        if (data['success'] == true && data['user'] != null) {
          _updateFromUserMap(data['user']);
          await _saveToStorage();
        }
      }
    } catch (e) {
      debugPrint('UserService Refresh Error: $e');
    }
  }

  void _updateFromUserMap(Map<String, dynamic> userMap) {
    userId = userMap['userId'].toString();
    userName = userMap['name'] ?? 'User_$userId';
    avatar = userMap['avatar'] ?? '';
    invitedBy = userMap['invitedBy'] ?? '';
    _coins = (userMap['coins'] is num) ? (userMap['coins'] as num).toInt() : 0;
    _points = (userMap['points'] is num) ? (userMap['points'] as num).toInt() : 0;
    isFaceVerified = userMap['isFaceVerified'] == true || isFaceVerified;
    isOwner = (userId == '1000');
  }

  Future<void> _saveToStorage() async {
    try {
      final file = await _getStorageFile();
      await file.writeAsString(jsonEncode({
        'userId': userId,
        'name': userName,
        'avatar': avatar,
        'coins': _coins,
        'points': _points,
        'invitedBy': invitedBy,
        'isFaceVerified': isFaceVerified,
        'equippedFrame': equippedFrame,
        'equippedEntry': equippedEntry,
        'equippedTheme': equippedTheme,
      }));
    } catch (e) {
      debugPrint('Storage write error: $e');
    }
  }

  Future<void> _syncBalanceToServer() async {
    if (userId.isEmpty) return;
    try {
      final client = HttpClient();
      client.connectionTimeout = const Duration(seconds: 4);
      final request = await client.postUrl(Uri.parse('$serverUrl/api/wallet/sync-balance'));
      request.headers.set('content-type', 'application/json');
      request.add(utf8.encode(jsonEncode({
        'userId': userId,
        'coins': _coins,
      })));
      await request.close();
    } catch (_) {}
  }

  Future<void> _syncFaceVerificationToServer() async {
    if (userId.isEmpty) return;
    try {
      final client = HttpClient();
      client.connectionTimeout = const Duration(seconds: 4);
      final request = await client.postUrl(Uri.parse('$serverUrl/api/user/verify-face'));
      request.headers.set('content-type', 'application/json');
      request.add(utf8.encode(jsonEncode({
        'userId': userId,
        'isFaceVerified': isFaceVerified,
      })));
      await request.close();
    } catch (_) {}
  }

  Future<Map<String, dynamic>?> searchUser(String queryId) async {
    try {
      final client = HttpClient();
      client.connectionTimeout = const Duration(seconds: 8);
      final request = await client.getUrl(
        Uri.parse('$serverUrl/api/search-user?userId=${queryId.trim()}'),
      );
      final response = await request.close();
      if (response.statusCode == 200) {
        final body = await response.transform(utf8.decoder).join();
        final data = jsonDecode(body);
        if (data['success'] == true && data['user'] != null) {
          return data['user'];
        }
      }
    } catch (e) {
      debugPrint('Search error: $e');
    }
    return null;
  }
}
