import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:path/path.dart';

class FaceAuthResult {
  final String? userId;
  final String? fullName;
  final String? error;

  FaceAuthResult({this.userId, this.fullName, this.error});

  factory FaceAuthResult.fromJson(Map<String, dynamic> json) {
    return FaceAuthResult(
      userId: json['userId'],
      fullName: json['fullName'],
      error: json['error'],
    );
  }
}

class FaceAuthService {
  // ⚠️ Chỉnh lại cho phù hợp:
  // - Emulator thì dùng 10.0.2.2
  // - Device thật thì dùng IP LAN (vd: 192.168.1.125)
  static const String _baseUrl = "http://10.0.2.2:8080";

  /// Gửi ảnh lên server Flask để verify
  static Future<FaceAuthResult> verifyFace(File imageFile) async {
    try {
      final uri = Uri.parse("$_baseUrl/verify_face");
      var request = http.MultipartRequest("POST", uri);

      request.files.add(
        await http.MultipartFile.fromPath(
          "image",
          imageFile.path,
          filename: basename(imageFile.path),
        ),
      );

      final response = await request.send();
      final resBody = await response.stream.bytesToString();

      if (response.statusCode == 200) {
        final jsonData = json.decode(resBody);
        return FaceAuthResult.fromJson(jsonData);
      } else {
        return FaceAuthResult(error: "Server error: ${response.statusCode}");
      }
    } catch (e) {
      return FaceAuthResult(error: "Network error: $e");
    }
  }
}
