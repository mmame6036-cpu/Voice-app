import 'dart:convert';
import 'package:http/http.dart' as http;
import 'user_service.dart';

class AgencyTaskService {
  static final AgencyTaskService _instance = AgencyTaskService._internal();
  factory AgencyTaskService() => _instance;
  AgencyTaskService._internal();

  Future<Map<String, dynamic>?> getUserTasks(String userId) async {
    try {
      final url = Uri.parse('${UserService.serverUrl}/api/tasks/$userId');
      final res = await http.get(url).timeout(const Duration(seconds: 8));

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        if (data['success'] == true) {
          return data['data'];
        }
      }
    } catch (e) {
      print('Failed to get tasks: $e');
    }
    return null;
  }

  Future<bool> claimTaskReward(String userId, String taskId, int rewardCoins) async {
    try {
      final url = Uri.parse('${UserService.serverUrl}/api/tasks/claim');
      final res = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'userId': userId,
          'taskId': taskId,
          'rewardCoins': rewardCoins,
        }),
      ).timeout(const Duration(seconds: 8));

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        return data['success'] == true;
      }
    } catch (e) {
      print('Failed to claim reward: $e');
    }
    return false;
  }

  Future<Map<String, dynamic>?> getAgencyDetails(String agentId) async {
    try {
      final url = Uri.parse('${UserService.serverUrl}/api/agency/details?agentId=$agentId');
      final res = await http.get(url).timeout(const Duration(seconds: 8));

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        if (data['success'] == true) {
          return data;
        }
      }
    } catch (e) {
      print('Failed to get agency details: $e');
    }
    return null;
  }

  Future<bool> addHostToAgency(String agentId, String hostUserId) async {
    try {
      final url = Uri.parse('${UserService.serverUrl}/api/agency/add-host');
      final res = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'agentId': agentId,
          'hostUserId': hostUserId,
        }),
      ).timeout(const Duration(seconds: 8));

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        return data['success'] == true;
      }
    } catch (e) {
      print('Failed to add host: $e');
    }
    return false;
  }
}
