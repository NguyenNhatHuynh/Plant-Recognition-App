import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/recognition_record.dart';
import '../../services/database_service.dart';
import '../../state/app_state.dart';
import '../widgets/plant_image.dart';
import 'plant_detail_screen.dart';

class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final revision = context.watch<AppState>().revision;
    final dbService = context.read<DatabaseService>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Lịch sử'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: FutureBuilder<List<RecognitionRecord>>(
            key: ValueKey(revision),
            future: dbService.getHistory(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              final records = snapshot.data ?? const <RecognitionRecord>[];
              if (records.isEmpty) {
                return const Center(
                  child: Text('Chưa có lịch sử nhận diện.'),
                );
              }
              return ListView.builder(
                itemCount: records.length,
                itemBuilder: (context, index) {
                  final record = records[index];
                  return Card(
                    elevation: 0,
                    child: ListTile(
                      contentPadding: const EdgeInsets.all(12),
                      leading: SizedBox(
                        width: 72,
                        height: 72,
                        child: PlantImage(
                          plant: record.plant.copyWith(
                            imagePath: record.imagePath,
                          ),
                          height: 72,
                          width: 72,
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      title: Text(record.plant.commonName),
                      subtitle: Text(
                        '${record.plant.scientificName}\n${_formatDate(record.capturedAt)}',
                      ),
                      isThreeLine: true,
                      trailing: Text(
                        '${(record.confidence * 100).toStringAsFixed(0)}%',
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                PlantDetailScreen(plant: record.plant),
                          ),
                        );
                      },
                    ),
                  );
                },
              );
            },
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime dateTime) {
    final day = dateTime.day.toString().padLeft(2, '0');
    final month = dateTime.month.toString().padLeft(2, '0');
    final year = dateTime.year.toString();
    final hour = dateTime.hour.toString().padLeft(2, '0');
    final minute = dateTime.minute.toString().padLeft(2, '0');
    return '$day/$month/$year $hour:$minute';
  }
}
