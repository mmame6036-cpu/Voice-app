import 'dart:convert';
import 'package:http/http.dart' as http;
import 'user_service.dart';

class TaskService {
  static String get baseUrl => '${UserService.serverUrl}/api/tasks';

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
