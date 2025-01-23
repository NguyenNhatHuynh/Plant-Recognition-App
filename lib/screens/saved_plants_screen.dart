import 'dart:io';
import 'package:flutter/material.dart';
import 'package:plant_recognition_app/core/api/database.dart';

class SavedPlantsScreen extends StatelessWidget {
  Future<List<Map<String, dynamic>>> _fetchSavedPlants() async {
    return await PlantDatabase.instance.fetchPlants();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Danh sách cây đã lưu')),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _fetchSavedPlants(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(child: Text('Chưa có cây nào được lưu.'));
          }

          final plants = snapshot.data!;

          return ListView.builder(
            itemCount: plants.length,
            itemBuilder: (context, index) {
              final plant = plants[index];
              return ListTile(
                leading: Image.file(File(plant['image_path']),
                    width: 50, height: 50),
                title: Text(plant['plant_name']),
                subtitle: Text(
                    'Độ chính xác: ${(plant['probability'] * 100).toStringAsFixed(2)}%'),
              );
            },
          );
        },
      ),
    );
  }
}
