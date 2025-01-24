// features/identification/view/identify_screen.dart
import 'package:flutter/material.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import '../../../core/api/plant_api.dart';

class IdentifyScreen extends StatefulWidget {
  const IdentifyScreen({Key? key}) : super(key: key);

  @override
  _IdentifyScreenState createState() => _IdentifyScreenState();
}

class _IdentifyScreenState extends State<IdentifyScreen> {
  final PlantApi _plantApi = PlantApi();
  File? _selectedImage;
  String? _result;

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _selectedImage = File(pickedFile.path);
      });
    }
  }

  Future<void> _identifyPlant() async {
    if (_selectedImage == null) {
      setState(() {
        _result = 'Please select an image first!';
      });
      return;
    }

    try {
      final result = await _plantApi.identifyPlant(_selectedImage!);
      setState(() {
        _result = result['suggestions'][0]['plant_name'];
      });
    } catch (e) {
      setState(() {
        _result = 'Error: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Identify Plant'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (_selectedImage != null)
              Image.file(_selectedImage!,
                  height: 200, width: 200, fit: BoxFit.cover),
            ElevatedButton(
              onPressed: _pickImage,
              child: const Text('Select Image'),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _identifyPlant,
              child: const Text('Identify Plant'),
            ),
            const SizedBox(height: 20),
            if (_result != null)
              Text(
                _result!,
                style: const TextStyle(fontSize: 18),
                textAlign: TextAlign.center,
              ),
          ],
        ),
      ),
    );
  }
}
