import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/recognition_record.dart';
import '../../services/database_service.dart';
import '../../state/app_state.dart';
import '../widgets/favorite_action_button.dart';
import '../widgets/plant_image.dart';
import 'plant_detail_screen.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  final Set<int> _pendingFavoriteIds = <int>{};

  Future<void> _toggleFavorite(RecognitionRecord record) async {
    final plant = record.plant;
    final plantId = plant.id;
    if (plantId == null || _pendingFavoriteIds.contains(plantId)) {
      return;
    }

    setState(() {
      _pendingFavoriteIds.add(plantId);
    });

    try {
      final dbService = context.read<DatabaseService>();
      final appState = context.read<AppState>();
      final nextValue = !plant.isFavorite;
      await dbService.toggleFavorite(plantId, nextValue);
      appState.markChanged();
    } finally {
      if (mounted) {
        setState(() {
          _pendingFavoriteIds.remove(plantId);
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final revision = context.watch<AppState>().revision;
    final dbService = context.read<DatabaseService>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Lá»‹ch sá»­'),
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
                  child: Text('ChÆ°a cÃ³ lá»‹ch sá»­ nháº­n diá»‡n.'),
                );
              }
              return ListView.builder(
                itemCount: records.length,
                itemBuilder: (context, index) {
                  final record = records[index];
                  final plant = record.plant;
                  final plantId = plant.id;
                  final isLoading =
                      plantId != null && _pendingFavoriteIds.contains(plantId);

                  return Card(
                    elevation: 0,
                    child: ListTile(
                      contentPadding: const EdgeInsets.all(12),
                      leading: SizedBox(
                        width: 72,
                        height: 72,
                        child: PlantImage(
                          plant: plant.copyWith(
                            imagePath: record.imagePath,
                          ),
                          height: 72,
                          width: 72,
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      title: Text(plant.commonName),
                      subtitle: Text(
                        '${plant.scientificName}\n${_formatDate(record.capturedAt)}',
                      ),
                      isThreeLine: true,
                      trailing: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            '${(record.confidence * 100).toStringAsFixed(0)}%',
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          ),
                          const SizedBox(height: 8),
                          if (plantId != null)
                            FavoriteActionButton(
                              isFavorite: plant.isFavorite,
                              isLoading: isLoading,
                              onTap: () => _toggleFavorite(record),
                              size: 20,
                              padding: const EdgeInsets.all(4),
                            ),
                        ],
                      ),
                      onTap: () {
                        Navigator.push(
                          context,
                          PlantDetailScreen.route(plant),
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
