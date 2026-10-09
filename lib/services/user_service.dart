import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:flutter/foundation.dart';

class UserService {
  // ነጠላ ማዕከላዊ አሰራር (Singleton)
  static final UserService _instance = UserService._internal();
  factory UserService() => _instance;
  UserService._internal();

  // የሰርቨርህ ቋሚ አድራሻ
  static const String serverUrl = 'https://voice-app-2-jdqf.onrender.com';
  static const String agoraAppId = '21091aff01114a66b580ce15b0f1b642';

  // የተጠቃሚው ቋሚ መረጃዎች
  String userId = '';
  String userName = '';
  int coins = 50000;
  bool isOwner = false;
  bool isInitialized = false;

  // አፑ እንደተከፈተ ስልኩን ለይቶ ID የሚሰጥ ዋና ፈንክሽን
  Future<void> initializeUser() async {
    if (isInitialized) return;

    try {
      final dir = Directory.systemTemp;
      final file = File('${dir.path}/app_user_identity.json');

      // 1. ስልኩ ላይ አስቀድሞ የተቀመጠ ID ካለ ማንበብ
      if (await file.exists()) {
        final content = await file.readAsString();
        final localData = jsonDecode(content);
        userId = localData['userId'].toString();
        userName = localData['name'] ?? 'User_$userId';
        isOwner = (userId == '1000');
        isInitialized = true;
        return;
      }

      // 2. አዲስ ስልክ ከሆነ ለየት ያለ መለያ (Device Fingerprint) ማመንጨት
      final deviceKey = 'device_${DateTime.now().millisecondsSinceEpoch}_${Random().nextInt(999999)}';

      // 3. ሰርቨሩን ጠይቆ አዲስ ተከታታይ ID መቀበል
      final client = HttpClient();
      client.connectionTimeout = const Duration(seconds: 10);
      final request = await client.postUrl(Uri.parse('$serverUrl/api/register-user'));
      request.headers.set('content-type', 'application/json');

      request.add(utf8.encode(jsonEncode({
        'deviceId': deviceKey,
        'name': 'User',
        'isOwner': false, // ለተጠቃሚዎች ተከታታይ 1001, 1002... ይሰጣል
      })));

      final response = await request.close();
      if (response.statusCode == 200) {
        final body = await response.transform(utf8.decoder).join();
        final resData = jsonDecode(body);

        if (resData['success'] == true && resData['user'] != null) {
          userId = resData['user']['userId'].toString();
          userName = resData['user']['name'] ?? 'User_$userId';
          isOwner = (userId == '1000');

          // በስልኩ ቋሚ ሚሞሪ ላይ ማስቀመጥ (ዳግም እንዳይቀየር)
          await file.writeAsString(jsonEncode({
            'userId': userId,
            'name': userName,
          }));

          isInitialized = true;
        }
      }
    } catch (e) {
      debugPrint('UserService Error: $e');
    }
  }

  // በአይዲ ሰውን ከዳታቤዝ መፈለጊያ
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
