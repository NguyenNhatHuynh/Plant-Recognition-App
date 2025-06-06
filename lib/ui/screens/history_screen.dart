// lib/ui/screens/history_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:plant_recognition_app/services/database_service.dart';
import 'package:plant_recognition_app/models/plant.dart';
import 'package:plant_recognition_app/ui/screens/plant_detail_screen.dart';
import 'package:plant_recognition_app/ui/widgets/plant_card.dart';

class HistoryScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final dbService = Provider.of<DatabaseService>(context, listen: false);

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'History',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              SizedBox(height: 16),
              Expanded(
                child: FutureBuilder<List<Plant>>(
                  future: dbService.getHistory(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return Center(child: CircularProgressIndicator());
                    }
                    if (snapshot.hasError || snapshot.data == null) {
                      return Center(child: Text('No history'));
                    }
                    final plants = snapshot.data!;
                    return ListView.builder(
                      itemCount: plants.length,
                      itemBuilder: (context, index) {
                        return PlantCard(
                          plant: plants[index],
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    PlantDetailScreen(plant: plants[index]),
                              ),
                            );
                          },
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
