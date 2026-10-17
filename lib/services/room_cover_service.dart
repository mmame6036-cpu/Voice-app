import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'user_service.dart';

class RoomCoverService {
  static final ImagePicker _picker = ImagePicker();

  static Future<void> pickAndUpload({
    required BuildContext context,
    required String roomId,
    required String hostId,
    required Function(String newCoverUrl) onUploaded,
  }) async {
    try {
      // 1. ጋለሪ ከፍቶ ፎቶ ማስመረጥ
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
      );

      if (image == null) return; // ካልመረጠ ይመለሳል

      // 2. Loading ማሳያ ማሳወቅ
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('ምስሉ እየተጫነ ነው፣ ትንሽ ይጠብቁ...'),
          duration: Duration(seconds: 2),
        ),
      );

      // 3. ወደ ሰርቨር አፕሎድ ማድረግ
      final uri = Uri.parse(UserService.serverUrl + '/api/room-cover/upload');
      final request = http.MultipartRequest('POST', uri);

      request.fields['roomId'] = roomId;
      request.fields['hostId'] = hostId;
      request.files.add(
        await http.MultipartFile.fromPath('coverImage', image.path),
      );

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);
      final data = jsonDecode(response.body);

      if (data['success'] == true) {
        final String newUrl = data['coverUrl'];
        onUploaded(newUrl);

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('የክፍሉ ምስል በተሳካ ሁኔታ ተቀይሯል!'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        throw Exception(data['message'] ?? 'ምስሉን መጫን አልተቻለም');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('ስህተት: ' + e.toString()),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}
