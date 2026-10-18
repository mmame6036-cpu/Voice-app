import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'task_service.dart';

class UserService {
  static final UserService _instance = UserService._internal();
  factory UserService() => _instance;
  UserService._internal();

  static const String serverUrl = 'https://voice-app-2-jd95.onrender.com';
  static const String agoraAppId = '1523b6d3b8144281a1a21f28bbbd7fef';

  String userId = '';
  String userName = '';
  String avatar = '';
  int coins = 0;
  int points = 0;
  bool isOwner = false;
  bool isInitialized = false;

  Future<File> _getStorageFile() async {
    final dir = Directory.systemTemp;
    return File('${dir.path}/app_persistent_profile.json');
  }

  Future<void> initializeUser() async {
    if (isInitialized && userId.isNotEmpty) {
      await refreshUserData();
      return;
    }

    try {
      final file = await _getStorageFile();

      // 1. Check local persistent storage
      if (await file.exists()) {
        final content = await file.readAsString();
        final localData = jsonDecode(content);
        if (localData['userId'] != null && localData['userId'].toString().isNotEmpty) {
          userId = localData['userId'].toString();
          userName = localData['name'] ?? 'User_$userId';
          avatar = localData['avatar'] ?? '';
          coins = localData['coins'] ?? 0;
          points = localData['points'] ?? 0;
          isOwner = (userId == '1000');
          isInitialized = true;

          // Sync latest values from database
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

    if (userId.isEmpty) {
      final randomUnique = Random().nextInt(8999) + 1001;
      userId = randomUnique.toString();
      userName = 'User_$userId';
      coins = 1000;
      points = 0;
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
    coins = (userMap['coins'] is num) ? (userMap['coins'] as num).toInt() : 0;
    points = (userMap['points'] is num) ? (userMap['points'] as num).toInt() : 0;
    isOwner = (userId == '1000');
  }

  Future<void> _saveToStorage() async {
    try {
      final file = await _getStorageFile();
      await file.writeAsString(jsonEncode({
        'userId': userId,
        'name': userName,
        'avatar': avatar,
        'coins': coins,
        'points': points,
      }));
    } catch (e) {
      debugPrint('Storage write error: $e');
    }
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

  // Follow a user and trigger the follower task activity tracker
  Future<bool> followUser({
    required String currentUserId,
    required String targetUserId,
  }) async {
    try {
      final client = HttpClient();
      client.connectionTimeout = const Duration(seconds: 8);
      final request = await client.postUrl(Uri.parse('$serverUrl/api/users/follow'));
      request.headers.set('content-type', 'application/json');

      request.add(utf8.encode(jsonEncode({
        'userId': currentUserId,
        'targetUserId': targetUserId,
      })));

      final response = await request.close();
      if (response.statusCode == 200) {
        await TaskService.recordActivity(
          userId: targetUserId,
          type: 'follow',
          value: 1,
        );
        return true;
      }
    } catch (e) {
      debugPrint('Follow User Error: $e');
    }
    return false;
  }
}
