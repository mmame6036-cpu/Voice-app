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

  // ነባሪው ባዶ ነው፤ በዘፈቀደ 1000 አይሆንም
  String userId = '';
  String userName = '';
  int coins = 50000;
  bool isOwner = false;
  bool isInitialized = false;

  Future<void> initializeUser() async {
    if (isInitialized && userId.isNotEmpty) return;

    try {
      final dir = Directory.systemTemp;
      // እያንዳንዱ ስልክ የራሱ ልዩ ስቶሬጅ ፋይል
      final file = File('${dir.path}/app_identity_v2.json');

      if (await file.exists()) {
        final content = await file.readAsString();
        final localData = jsonDecode(content);
        userId = localData['userId'].toString();
        userName = localData['name'] ?? 'User_$userId';
        isOwner = (userId == '1000');
        isInitialized = true;
        return;
      }

      // ለእያንዳንዱ ስልክ የተለየ ልዩ ቁጥር ማመንጨት
      final randomSeed = Random().nextInt(8999) + 1001; // ከ 1001 እስከ 9999
      final deviceKey = 'device_${Platform.operatingSystem}_${DateTime.now().millisecondsSinceEpoch}_$randomSeed';

      // ሰርቨሩን መጠየቅ
      final client = HttpClient();
      client.connectionTimeout = const Duration(seconds: 8);
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
      debugPrint('UserService Server Error: $e');
    }

    // ሰርቨሩ ምላሽ ካልሰጠ ለእያንዳንዱ ስልክ የተለየ ልዩ ID ይሰጠዋል (1000 አይሰጠውም)
    if (userId.isEmpty) {
      final newRandomId = '${Random().nextInt(8999) + 1001}';
      userId = newRandomId;
      userName = 'User_$userId';
      isOwner = false;

      try {
        final dir = Directory.systemTemp;
        final file = File('${dir.path}/app_identity_v2.json');
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
