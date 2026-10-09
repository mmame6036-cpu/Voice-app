import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:flutter/foundation.dart';

class UserService {
  static final UserService _instance = UserService._internal();
  factory UserService() => _instance;
  UserService._internal();

  static const String serverUrl = 'https://voice-app-2-jdqf.onrender.com';
  static const String agoraAppId = '21091aff01114a66b580ce15b0f1b642';

  String userId = '1000';
  String userName = 'User_1000';
  int coins = 50000;
  bool isOwner = false;
  bool isInitialized = false;

  Future<void> initializeUser() async {
    if (isInitialized) return;

    try {
      final dir = Directory.systemTemp;
      final file = File('${dir.path}/app_user_identity.json');

      if (await file.exists()) {
        final content = await file.readAsString();
        final localData = jsonDecode(content);
        userId = localData['userId'].toString();
        userName = localData['name'] ?? 'User_$userId';
        isOwner = (userId == '1000');
        isInitialized = true;
        return;
      }

      final deviceKey = 'device_${DateTime.now().millisecondsSinceEpoch}_${Random().nextInt(999999)}';

      final client = HttpClient();
      client.connectionTimeout = const Duration(seconds: 12);
      final request = await client.postUrl(Uri.parse('$serverUrl/api/register-user'));
      request.headers.set('content-type', 'application/json');

      request.add(utf8.encode(jsonEncode({
        'deviceId': deviceKey,
        'name': 'User',
        'isOwner': false,
      })));

      final response = await request.close();
      if (response.statusCode == 200) {
        final body = await response.transform(utf8.decoder).join();
        final resData = jsonDecode(body);

        if (resData['success'] == true && resData['user'] != null) {
          userId = resData['user']['userId'].toString();
          userName = resData['user']['name'] ?? 'User_$userId';
          isOwner = (userId == '1000');

          await file.writeAsString(jsonEncode({
            'userId': userId,
            'name': userName,
          }));

          isInitialized = true;
          return;
        }
      }
    } catch (e) {
      debugPrint('UserService Error: $e');
    }

    // ሰርቨሩ በሰዓቱ ምላሽ ባይሰጥ እንኳ ባዶ እንዳይሆን የተጠቃሚውን ቁጥር ማመንጨት
    if (userId.isEmpty || userId == '') {
      userId = '100${Random().nextInt(90) + 10}';
      userName = 'User_$userId';
    }
    isInitialized = true;
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
