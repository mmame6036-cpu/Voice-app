import 'dart:convert';
import 'package:http/http.dart' as http;

class WalletService {
  static const String baseUrl = 'https://voice-app-backend.onrender.com';

  // 1. Deduct Bet
  static Future<Map<String, dynamic>> deductBet({
    required String token,
    required int betAmount,
    required String gameName,
  }) async {
    final url = Uri.parse('$baseUrl/api/wallet/bet');

    try {
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'betAmount': betAmount,
          'gameName': gameName,
        }),
      );

      return jsonDecode(response.body);
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  // 2. Credit Win
  static Future<Map<String, dynamic>> creditWin({
    required String token,
    required int winAmount,
    required String gameName,
  }) async {
    final url = Uri.parse('$baseUrl/api/wallet/win');

    try {
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'winAmount': winAmount,
          'gameName': gameName,
        }),
      );

      return jsonDecode(response.body);
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  // 3. Request Refund
  static Future<Map<String, dynamic>> requestRefund({
    required String token,
    required int refundAmount,
    required String reason,
  }) async {
    final url = Uri.parse('$baseUrl/api/wallet/refund');

    try {
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'refundAmount': refundAmount,
          'reason': reason,
        }),
      );

      return jsonDecode(response.body);
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  // 4. Fetch Ledger History
  static Future<Map<String, dynamic>> fetchHistory({
    required String token,
  }) async {
    final url = Uri.parse('$baseUrl/api/wallet/history');

    try {
      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      return jsonDecode(response.body);
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }
}
