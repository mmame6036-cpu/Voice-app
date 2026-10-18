import 'dart:convert';
import 'package:http/http.dart' as http;

class TaskService {
  static const String baseUrl = 'https://voice-app-2-jd95.onrender.com/api/tasks';

  // Record activities (normal_seat, crown_seat, crown_gift, follow)
  static Future<void> recordActivity({
    required String userId,
    required String type,
    int value = 1,
  }) async {
    try {
      final url = Uri.parse('$baseUrl/record-activity');
      await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'userId': userId,
          'type': type,
          'value': value,
        }),
      );
    } catch (e) {
      // Ignore network errors silently during background tracking
    }
  }
}
