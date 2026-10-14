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
  int coins = 50000;
  bool isOwner = false;
  bool isInitialized = false;

  // የስልኩን ቋሚ ማከማቻ ፋይል ማግኛ
  Future<File> _getStorageFile() async {
    final dir = Directory.systemTemp;
    return File('${dir.path}/app_persistent_profile.json');
  }

  Future<void> initializeUser() async {
    if (isInitialized && userId.isNotEmpty) return;

    try {
      final file = await _getStorageFile();

      // 1. ስልኩ ውስጥ ቀድሞ የተቀመጠ ቋሚ ID ካለ መፈተሽ
      if (await file.exists()) {
        final content = await file.readAsString();
        final localData = jsonDecode(content);
        if (localData['userId'] != null && localData['userId'].toString().isNotEmpty) {
          userId = localData['userId'].toString();
          userName = localData['name'] ?? 'User_$userId';
          isOwner = (userId == '1000');
          isInitialized = true;
          return;
        }
      }

      // 2. ከሌለ ለእያንዳንዱ ስልክ የተለየ ልዩ ቁልፍ ማዘጋጀት
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
      debugPrint('UserService Server Error: $e');
    }

    // ሰርቨሩ ባይገኝም እንኳ ለእያንዳንዱ ስልክ የማይመሳሰል ቋሚ ID መስጠት
    if (userId.isEmpty) {
      final randomUnique = Random().nextInt(8999) + 1001;
      userId = randomUnique.toString();
      userName = 'User_$userId';
      isOwner = false;

      try {
        final file = await _getStorageFile();
        await file.writeAsString(jsonEncode({
          'userId': userId,
          'name': userName,
        }));
      } catch (_) {}
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
