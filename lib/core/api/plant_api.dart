import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:plant_recognition_app/utils/constants.dart';


class PlantApi {
  Future<Map<String, dynamic>> identifyPlant(File image) async {
    final url = Uri.parse(Constants.apiBaseUrl);

    final request = http.MultipartRequest('POST', url)
      ..headers['Authorization'] = 'Bearer ${Constants.apiKey}'
      ..fields['modifiers'] = 'crops_fast'
      ..fields['plant_details'] = 'common_names,url'
      ..files.add(await http.MultipartFile.fromPath('images', image.path));

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to identify plant: ${response.body}');
    }
  }
}
