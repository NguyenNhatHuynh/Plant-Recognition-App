import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:plant_recognition_app/core/api/database.dart';
import 'package:plant_recognition_app/core/api/plant_api.dart';


class IdentifyScreen extends StatefulWidget {
  @override
  _IdentifyScreenState createState() => _IdentifyScreenState();
}

class _IdentifyScreenState extends State<IdentifyScreen> {
  final PlantApi _plantApi = PlantApi();
  XFile? _image;
  String? _result;
  bool _isSaving = false;

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final image = await picker.pickImage(source: ImageSource.gallery);

    if (image != null) {
      setState(() {
        _image = image;
        _result = null;
      });

      try {
        final result = await _plantApi.identifyPlant(image.path);
        final suggestions = result['suggestions'] as List<dynamic>;
        final firstSuggestion = suggestions.isNotEmpty ? suggestions[0] : null;

        if (firstSuggestion != null) {
          final plantName = firstSuggestion['plant_name'];
          final commonNames = (firstSuggestion['plant_details']['common_names']
                  as List<dynamic>)
              .join(', ');
          final probability = firstSuggestion['probability'];

          setState(() {
            _result =
                'Tên khoa học: $plantName\nTên thường gọi: $commonNames\nĐộ chính xác: ${(probability * 100).toStringAsFixed(2)}%';
          });

          await _saveToDatabase(
            plantName: plantName,
            commonNames: commonNames,
            probability: probability,
            imagePath: image.path,
          );
        }
      } catch (e) {
        setState(() {
          _result = 'Lỗi khi nhận diện cây: $e';
        });
      }
    }
  }

  Future<void> _saveToDatabase({
    required String plantName,
    required String commonNames,
    required double probability,
    required String imagePath,
  }) async {
    setState(() {
      _isSaving = true;
    });

    await PlantDatabase.instance.insertPlant({
      'plant_name': plantName,
      'common_names': commonNames,
      'probability': probability,
      'image_path': imagePath,
    });

    setState(() {
      _isSaving = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Nhận diện cây')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            _image != null
                ? Image.file(File(_image!.path))
                : Placeholder(fallbackHeight: 200),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: _isSaving ? null : _pickImage,
              child: _isSaving
                  ? CircularProgressIndicator()
                  : Text('Chọn ảnh từ thư viện'),
            ),
            SizedBox(height: 20),
            _result != null
                ? Text('Kết quả: $_result')
                : Text('Chưa nhận diện ảnh nào'),
          ],
        ),
      ),
    );
  }
}
