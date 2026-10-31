import 'dart:convert';
import 'package:http/http.dart' as http;

class AgoraTokenService {
  // Replace this URL once your backend server is deployed
  static const String _serverBaseUrl = "https://your-token-server.com/rtcToken";

  static Future<String?> fetchToken({
    required String channelName,
    required int uid,
    required bool isPublisher,
  }) async {
    try {
      final role = isPublisher ? "publisher" : "subscriber";
      final uri = Uri.parse("$_serverBaseUrl?channelName=$channelName&uid=$uid&role=$role");
      
      final response = await http.get(uri).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        return data['token'] as String?;
      }
    } catch (_) {
      // In case server is offline during initial testing
      return null;
    }
    return null;
  }
}
