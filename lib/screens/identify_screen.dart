import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:plant_recognition_app/core/api/plant_api.dart';

class IdentifyScreen extends StatefulWidget {
  const IdentifyScreen({Key? key}) : super(key: key);

  @override
  State<IdentifyScreen> createState() => _IdentifyScreenState();
}

class _IdentifyScreenState extends State<IdentifyScreen> {
  final PlantApi _plantApi = PlantApi();
  File? _selectedImage;
  Map<String, dynamic>? _plantInfo;
  String _error = "";

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() {
        _selectedImage = File(pickedFile.path);
        _plantInfo = null;
        _error = "";
      });

      try {
        final response = await _plantApi.identifyPlant(_selectedImage!);
        setState(() {
          _plantInfo = response;
        });
      } catch (e) {
        setState(() {
          _error = "Error: ${e.toString()}";
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Plant Identifier'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            if (_selectedImage != null)
              Image.file(
                _selectedImage!,
                height: 200,
                fit: BoxFit.cover,
              ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _pickImage,
              child: const Text('Pick an Image'),
            ),
            const SizedBox(height: 20),
            if (_error.isNotEmpty)
              Text(_error, style: const TextStyle(color: Colors.red)),
            if (_plantInfo != null) ...[
              Text("Scientific Name: ${_plantInfo!['plant_name']}",
                  style: const TextStyle(fontSize: 16)),
              const SizedBox(height: 20),
              Text("Similar Images:",
                  style: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              if (_plantInfo!['similar_images'] != null)
                Wrap(
                  spacing: 10,
                  children: (_plantInfo!['similar_images'] as List)
                      .map<Widget>(
                        (img) => Image.network(
                          img['url_small'],
                          height: 100,
                          width: 100,
                          fit: BoxFit.cover,
                        ),
                      )
                      .toList(),
                ),
            ],
          ],
        ),
      ),
    );
  }
}
