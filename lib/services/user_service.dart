import 'dart:convert';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class UserService {
  static final UserService _instance = UserService._internal();
  factory UserService() => _instance;
  UserService._internal();

  static const String serverUrl = 'https://nile-voice-server.onrender.com';
  static const String agoraAppId = '388d62b7f0ef47a0821b470a635b9473';

  String userId = '100234';
  String userName = 'User_100234';
  int coins = 1000;
  int points = 0;
  bool isFaceVerified = false;

  Future<void> initializeUser() async {
    if (userId.isNotEmpty && userId != '100234') {
      return;
    }

    final randomId = (100000 + Random().nextInt(900000)).toString();
    final defaultName = 'User_$randomId';

    try {
      final response = await http
          .post(
            Uri.parse('$serverUrl/api/register-user'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'deviceId': randomId,
              'userName': defaultName,
            }),
          )
          .timeout(const Duration(seconds: 4));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true && data['user'] != null) {
          final u = data['user'];
          userId = u['userId']?.toString() ?? randomId;
          userName = u['userName']?.toString() ?? defaultName;
          coins = u['coins'] ?? 1000;
          return;
        }
      }
    } catch (e) {
      debugPrint('Server connection bypass: $e');
    }

    userId = randomId;
    userName = defaultName;
    coins = 1000;
    points = 0;
  }

  // login_screen.dart የሚጠራው ፈንክሽን
  Future<void> setUserData(Map<String, dynamic> data) async {
    userId = data['userId']?.toString() ?? userId;
    userName = data['userName']?.toString() ?? userName;
    coins = data['coins'] ?? coins;
    points = data['points'] ?? points;
    isFaceVerified = data['isFaceVerified'] ?? isFaceVerified;
  }

  // የፍለጋ ክፍሉ የሚጠራው ፈንክሽን
  Future<Map<String, dynamic>?> searchUser(String query) async {
    try {
      final response = await http
          .get(Uri.parse('$serverUrl/api/users/search?q=$query'))
          .timeout(const Duration(seconds: 4));

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
    } catch (_) {}
    return null;
  }
}
