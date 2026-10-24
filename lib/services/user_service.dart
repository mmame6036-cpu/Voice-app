import 'dart:convert';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class UserService {
  static final UserService _instance = UserService._internal();
  factory UserService() => _instance;
  UserService._internal();

  static const String serverUrl = 'https://nile-voice-server.onrender.com';

  String userId = '';
  String userName = '';
  int coins = 1000;
  int points = 0;
  bool isFaceVerified = false;

  Future<void> initializeUser() async {
    final prefs = await SharedPreferences.getInstance();
    userId = prefs.getString('user_id') ?? '';
    userName = prefs.getString('user_name') ?? '';
    coins = prefs.getInt('user_coins') ?? 1000;
    points = prefs.getInt('user_points') ?? 0;
    isFaceVerified = prefs.getBool('is_face_verified') ?? false;

    // መታወቂያ አስቀድሞ ካለ ተጨማሪ ጥሪ አያስፈልግም
    if (userId.isNotEmpty) {
      return;
    }

    // አዲስ መታወቂያ ማመንጨት
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
          await _saveToStorage();
          return;
        }
      }
    } catch (e) {
      debugPrint('Server connection bypassed: $e');
    }

    // ሰርቨሩ 404 ቢል ወይም ባይመልስ እንኳ አፑ እንዳይቆም በራሱ ይከፍታል
    userId = randomId;
    userName = defaultName;
    coins = 1000;
    points = 0;
    await _saveToStorage();
  }

  Future<void> _saveToStorage() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_id', userId);
    await prefs.setString('user_name', userName);
    await prefs.setInt('user_coins', coins);
    await prefs.setInt('user_points', points);
    await prefs.setBool('is_face_verified', isFaceVerified);
  }
}
