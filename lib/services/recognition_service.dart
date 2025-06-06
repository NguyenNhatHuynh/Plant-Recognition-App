// services/recognition_service.dart
import 'package:http/http.dart' as http;
import 'dart:convert';

import 'package:plant_recognition_app/models/recognition_result.dart';

class RecognitionService {
  Future<RecognitionResult> recognizePlant(String imagePath) async {
    final uri = Uri.parse('https://api.plant.id/v2/identify');
    final request = http.MultipartRequest('POST', uri)
      ..files.add(await http.MultipartFile.fromPath('images', imagePath))
      ..fields['api_key'] = 'YOUR_API_KEY';

    final response = await request.send();
    final responseData = await response.stream.bytesToString();
    return RecognitionResult.fromJson(jsonDecode(responseData));
  }
}
