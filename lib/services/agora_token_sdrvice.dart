import 'dart:convert';
import 'package:http/http.dart' as http;

class AgoraTokenService {
  static const String _serverBaseUrl = "https://nile-token-server.onrender.com/rtcToken";

  static Future<String?> fetchToken({
    required String channelName,
    required int uid,
    required bool isPublisher,
  }) async {
    try {
      final role = isPublisher ? "publisher" : "subscriber";
      final uri = Uri.parse("$_serverBaseUrl?channelName=$channelName&uid=$uid&role=$role");
      
      final response = await http.get(uri).timeout(const Duration(seconds: 12));

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        return data['token'] as String?;
      }
    } catch (_) {
      return null;
    }
    return null;
  }
}
