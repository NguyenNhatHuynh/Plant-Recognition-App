import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:plant_recognition_app/utils/constants.dart';

class PlantApi {
  Future<Map<String, dynamic>> identifyPlant(File image) async {
    final url = Uri.parse(Constants.apiBaseUrl);

    // Chuyển hình ảnh sang Base64
    final bytes = await image.readAsBytes();
    final base64Image = base64Encode(bytes);

    // Gửi request
    final response = await http.post(
      url,
      headers: {
        'Api-Key': Constants.apiKey,
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        "images": ["data:image/jpg;base64,$base64Image"],
        "latitude": 49.207,
        "longitude": 16.608,
        "similar_images": true,
      }),
    );

    if (response.statusCode == 200) {
      final jsonResponse = json.decode(response.body);

      // Kiểm tra nếu kết quả có suggestions
      if (jsonResponse['result']?['classification']?['suggestions'] != null) {
        final suggestions =
            jsonResponse['result']['classification']['suggestions'];
        return {
          "plant_name": suggestions[0]['name'],
          "similar_images": suggestions[0]['similar_images'] ?? [],
        };
      } else {
        throw Exception('No plant suggestions found.');
      }
    } else {
      throw Exception(
          'Failed to identify plant: ${response.statusCode} - ${response.body}');
    }
  }
}
