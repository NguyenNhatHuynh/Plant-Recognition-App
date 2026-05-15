import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../models/plant.dart';
import '../../models/recognition_candidate.dart';
import '../../models/recognition_result.dart';
import '../../services/database_service.dart';
import '../../services/recognition_service.dart';
import '../../state/app_state.dart';
import '../widgets/plant_image.dart';
import 'plant_detail_screen.dart';

class RecognitionScreen extends StatefulWidget {
  final XFile imageFile;

  const RecognitionScreen({
    super.key,
    required this.imageFile,
  });

  @override
  State<RecognitionScreen> createState() => _RecognitionScreenState();
}

class _RecognitionScreenState extends State<RecognitionScreen> {
  RecognitionResult? _result;
  Plant? _savedPlant;
  String? _error;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _runRecognition();
  }

  Future<void> _runRecognition() async {
    final recognitionService = context.read<RecognitionService>();
    final databaseService = context.read<DatabaseService>();
    final appState = context.read<AppState>();

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final result = await recognitionService.recognizePlant(widget.imageFile);
      final savedPlant = await databaseService.saveRecognition(
        result,
        imagePath: widget.imageFile.path,
      );
      appState.markChanged();
      if (!mounted) return;
      setState(() {
        _result = result;
        _savedPlant = savedPlant;
        _loading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error = error.toString();
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Kết quả nhận diện'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SafeArea(
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
                ? _ErrorState(
                    error: _error!,
                    onRetry: _runRecognition,
                  )
                : _ResultState(
                    result: _result!,
                    savedPlant: _savedPlant!,
                  ),
      ),
    );
  }
}

class _ResultState extends StatelessWidget {
  final RecognitionResult result;
  final Plant savedPlant;

  const _ResultState({
    required this.result,
    required this.savedPlant,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          PlantImage(
            plant: savedPlant,
            height: 260,
            width: double.infinity,
            borderRadius: BorderRadius.circular(24),
          ),
          const SizedBox(height: 20),
          Text(
            result.primary.commonName,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
          ),
          const SizedBox(height: 6),
          Text(
            result.primary.scientificName,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: const Color(0xFF7F5539),
                ),
          ),
          const SizedBox(height: 16),
          _ConfidenceBar(confidence: result.primary.confidence),
          const SizedBox(height: 16),
          _DetailCard(
            title: 'Mô tả',
            content: result.primary.description,
          ),
          _DetailCard(
            title: 'Môi trường sống',
            content: result.primary.habitat,
          ),
          _ChipCard(
            title: 'Ứng dụng',
            items: result.primary.uses,
          ),
          if (result.analysisNote.isNotEmpty)
            _DetailCard(
              title: 'Nhận xét',
              content: result.analysisNote,
            ),
          if (result.alternatives.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              'Loài có thể nhầm lẫn',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: 8),
            ...result.alternatives
                .take(3)
                .map(
                  (candidate) => _AlternativeTile(candidate: candidate),
                ),
          ],
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => PlantDetailScreen(plant: savedPlant),
                      ),
                    );
                  },
                  child: const Text('Xem chi tiết'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ConfidenceBar extends StatelessWidget {
  final double confidence;

  const _ConfidenceBar({required this.confidence});

  @override
  Widget build(BuildContext context) {
    final percent = (confidence.clamp(0.0, 1.0) * 100).toStringAsFixed(0);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFE8F5E9),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Độ tin cậy',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
              ),
              Text(
                '$percent%',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF2D6A4F),
                    ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: confidence.clamp(0.0, 1.0),
              minHeight: 10,
              backgroundColor: Colors.white,
              valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF2D6A4F)),
            ),
          ),
        ],
      ),
    );
  }
}

class _DetailCard extends StatelessWidget {
  final String title;
  final String content;

  const _DetailCard({
    required this.title,
    required this.content,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              content.isEmpty ? 'Chưa có dữ liệu' : content,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    height: 1.4,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ChipCard extends StatelessWidget {
  final String title;
  final List<String> items;

  const _ChipCard({
    required this.title,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return const SizedBox.shrink();
    }

    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: items
                  .map(
                    (item) => Chip(
                      label: Text(item),
                      backgroundColor: const Color(0xFFE8F5E9),
                    ),
                  )
                  .toList(growable: false),
            ),
          ],
        ),
      ),
    );
  }
}

class _AlternativeTile extends StatelessWidget {
  final RecognitionCandidate candidate;

  const _AlternativeTile({required this.candidate});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        title: Text(candidate.commonName),
        subtitle: Text(candidate.scientificName),
        trailing: Text(
          '${(candidate.confidence * 100).toStringAsFixed(0)}%',
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final String error;
  final VoidCallback onRetry;

  const _ErrorState({
    required this.error,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.redAccent),
            const SizedBox(height: 12),
            Text(
              'Không thể nhận diện ảnh',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              error,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 18),
            ElevatedButton(
              onPressed: onRetry,
              child: const Text('Thử lại'),
            ),
          ],
        ),
      ),
    );
  }
}
