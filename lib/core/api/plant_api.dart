import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

class PlantApi {
  final String apiKey =
      'dwY958M8MkZNCmxyzhMVNahxEHfapTXqXi4nsvVrVNWp5u8ufc'; // Thay bằng API key của bạn.

  Future<Map<String, dynamic>> identifyPlant(String imagePath) async {
    final url = Uri.parse('https://api.plant.id/v2/identify');
    final headers = {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $apiKey',
    };
    final body = jsonEncode({
      'images': [base64Encode(File(imagePath).readAsBytesSync())],
      'organs': ['leaf'], // Loại hình ảnh: lá, hoa...
    });

    final response = await http.post(url, headers: headers, body: body);

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to identify plant');
    }
  }
}
