import 'dart:convert';
import 'dart:typed_data';
import 'dart:io' show File;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:http/http.dart' as http;

class ImageUploadService {
  static const String _apiKey = '9afc0a1d4f5f20ef5d6832bfa4c14930';

  static Future<String?> uploadToImgBB({File? file, Uint8List? bytes}) async {
    try {
      final uri = Uri.parse('https://api.imgbb.com/1/upload?key=$_apiKey');

      http.Response response;

      if (kIsWeb && bytes != null) {
        // Web: send base64
        final base64Image = base64Encode(bytes);
        response = await http.post(uri, body: {'image': base64Image});
      } else if (!kIsWeb && file != null) {
        // Mobile: use multipart/form-data
        var request = http.MultipartRequest('POST', uri);
        request.files.add(await http.MultipartFile.fromPath('image', file.path));
        var streamed = await request.send();
        response = await http.Response.fromStream(streamed);
      } else {
        throw Exception('No image provided for upload');
      }

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['data']['display_url'] as String?;
      } else {
        print('ImgBB upload error: ${response.body}');
        return null;
      }
    } catch (e) {
      print('ImgBB upload exception: $e');
      return null;
    }
  }
}
