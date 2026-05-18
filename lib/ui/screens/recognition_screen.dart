import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
      backgroundColor: const Color(0xFFF8F9F6),
      appBar: AppBar(
        title: const Text('Kết quả nhận diện'),
        backgroundColor: Colors.transparent,
        foregroundColor: const Color(0xFF185B43),
        elevation: 0,
        centerTitle: false,
        actions: [
          IconButton(
            onPressed: _loading ? null : _runRecognition,
            icon: const Icon(Icons.more_vert_rounded),
            tooltip: 'Nhận diện lại',
          ),
        ],
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
                    initialPlant: _savedPlant!,
                  ),
      ),
    );
  }
}

class _ResultState extends StatefulWidget {
  final RecognitionResult result;
  final Plant initialPlant;

  const _ResultState({
    required this.result,
    required this.initialPlant,
  });

  @override
  State<_ResultState> createState() => _ResultStateState();
}

class _ResultStateState extends State<_ResultState> {
  late Plant _plant;
  bool _isSavingFavorite = false;

  @override
  void initState() {
    super.initState();
    _plant = widget.initialPlant;
  }

  Future<void> _toggleFavorite() async {
    final plantId = _plant.id;
    if (plantId == null || _isSavingFavorite) {
      return;
    }

    final nextValue = !_plant.isFavorite;
    setState(() {
      _isSavingFavorite = true;
      _plant = _plant.copyWith(isFavorite: nextValue);
    });

    try {
      final db = context.read<DatabaseService>();
      final appState = context.read<AppState>();
      await db.toggleFavorite(plantId, nextValue);
      appState.markChanged();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            nextValue
                ? 'Đã thêm vào yêu thích.'
                : 'Đã xóa khỏi yêu thích.',
          ),
        ),
      );
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _plant = _plant.copyWith(isFavorite: !nextValue);
      });
    } finally {
      if (mounted) {
        setState(() {
          _isSavingFavorite = false;
        });
      }
    }
  }

  Future<void> _shareSummary() async {
    final primary = widget.result.primary;
    final summary = '''
Kết quả nhận diện cây

Tên cây: ${primary.commonName}
Tên khoa học: ${primary.scientificName}
Mô tả: ${primary.description}
Môi trường sống: ${primary.habitat}
Nhận xét: ${widget.result.analysisNote}
''';

    await Clipboard.setData(ClipboardData(text: summary.trim()));
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Đã sao chép kết quả để chia sẻ.'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final primary = widget.result.primary;
    final topTags = <String>[
      ...primary.uses.take(3),
      if (primary.uses.isEmpty) 'Nhận diện AI',
    ];

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          PlantImage(
            plant: _plant,
            height: 262,
            width: double.infinity,
            borderRadius: BorderRadius.circular(24),
          ),
          const SizedBox(height: 22),
          Text(
            primary.commonName,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: const Color(0xFF185B43),
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: 6),
          Text(
            primary.scientificName,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: const Color(0xFF7B827E),
                  fontStyle: FontStyle.italic,
                ),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: topTags
                .map(
                  (tag) => Chip(
                    label: Text(tag),
                    backgroundColor: const Color(0xFFCFF0D7),
                    labelStyle: Theme.of(context).textTheme.labelMedium?.copyWith(
                          color: const Color(0xFF2E5D44),
                          fontWeight: FontWeight.w500,
                        ),
                    side: BorderSide.none,
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                  ),
                )
                .toList(growable: false),
          ),
          const SizedBox(height: 18),
          _ContentCard(
            icon: Icons.description_outlined,
            title: 'Mô tả',
            child: Text(
              _fallbackText(primary.description),
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: const Color(0xFF3D4741),
                    height: 1.7,
                  ),
            ),
          ),
          _ContentCard(
            icon: Icons.eco_outlined,
            title: 'Môi trường sống',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: _buildHabitatLines(context, primary.habitat),
            ),
          ),
          _ContentCard(
            icon: Icons.auto_awesome_outlined,
            title: 'Ứng dụng',
            child: Text(
              _buildUsesParagraph(primary.uses),
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: const Color(0xFF3D4741),
                    height: 1.7,
                  ),
            ),
          ),
          _ContentCard(
            icon: Icons.tips_and_updates_outlined,
            title: 'Nhận xét',
            child: Text(
              _fallbackText(widget.result.analysisNote),
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: const Color(0xFF3D4741),
                    height: 1.7,
                  ),
            ),
          ),
          if (widget.result.alternatives.isNotEmpty)
            _ContentCard(
              icon: Icons.compare_arrows_rounded,
              title: 'Loài có thể nhầm lẫn',
              child: Column(
                children: widget.result.alternatives
                    .take(3)
                    .map((candidate) => _AlternativeTile(candidate: candidate))
                    .toList(growable: false),
              ),
            ),
          const SizedBox(height: 18),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _isSavingFavorite ? null : _toggleFavorite,
              icon: Icon(
                _plant.isFavorite
                    ? Icons.favorite_rounded
                    : Icons.favorite_border_rounded,
                color: Colors.white,
              ),
              label: Text(
                _plant.isFavorite ? 'Đã thêm yêu thích' : 'Thêm vào yêu thích',
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF185B43),
                foregroundColor: Colors.white,
                minimumSize: const Size.fromHeight(56),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
              ),
            ),
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _shareSummary,
              icon: const Icon(Icons.share_outlined),
              label: const Text('Chia sẻ kết quả'),
              style: OutlinedButton.styleFrom(
                backgroundColor: const Color(0xFFCFF0D7),
                foregroundColor: const Color(0xFF436853),
                side: BorderSide.none,
                minimumSize: const Size.fromHeight(56),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Center(
            child: TextButton(
              onPressed: () {
                Navigator.push(
                  context,
                  PlantDetailScreen.route(_plant),
                );
              },
              child: const Text('Xem thông tin chi tiết'),
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildHabitatLines(BuildContext context, String habitat) {
    final fallback = _fallbackText(habitat);
    final pieces = habitat
        .split(RegExp(r'[.;]'))
        .map((item) => item.trim())
        .where((item) => item.isNotEmpty)
        .take(3)
        .toList(growable: false);

    final lines = pieces.isEmpty
        ? <String>[fallback]
        : pieces;

    final icons = <IconData>[
      Icons.wb_sunny_outlined,
      Icons.thermostat_outlined,
      Icons.water_drop_outlined,
    ];

    return List<Widget>.generate(lines.length, (index) {
      return Padding(
        padding: EdgeInsets.only(bottom: index == lines.length - 1 ? 0 : 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              icons[index < icons.length ? index : icons.length - 1],
              size: 18,
              color: const Color(0xFF8A5B16),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                lines[index],
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: const Color(0xFF3D4741),
                      height: 1.6,
                    ),
              ),
            ),
          ],
        ),
      );
    });
  }

  String _buildUsesParagraph(List<String> uses) {
    if (uses.isEmpty) {
      return 'Chưa có dữ liệu ứng dụng cụ thể cho cây này.';
    }
    return '${uses.join('. ')}.';
  }

  String _fallbackText(String text) {
    final trimmed = text.trim();
    if (trimmed.isEmpty) {
      return 'Chưa có dữ liệu.';
    }
    return trimmed;
  }
}

class _ContentCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final Widget child;

  const _ContentCard({
    required this.icon,
    required this.title,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 18),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE2E7E2)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A000000),
            blurRadius: 14,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                icon,
                color: const Color(0xFF185B43),
                size: 24,
              ),
              const SizedBox(width: 8),
              Text(
                title,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: const Color(0xFF185B43),
                      fontWeight: FontWeight.w700,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }
}

class _AlternativeTile extends StatelessWidget {
  final RecognitionCandidate candidate;

  const _AlternativeTile({required this.candidate});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAF7),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  candidate.commonName,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: const Color(0xFF203027),
                        fontWeight: FontWeight.w600,
                      ),
                ),
                const SizedBox(height: 2),
                Text(
                  candidate.scientificName,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: const Color(0xFF717B75),
                        fontStyle: FontStyle.italic,
                      ),
                ),
              ],
            ),
          ),
          Text(
            '${(candidate.confidence * 100).toStringAsFixed(0)}%',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: const Color(0xFF185B43),
                  fontWeight: FontWeight.w700,
                ),
          ),
        ],
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
            const Icon(
              Icons.error_outline_rounded,
              size: 48,
              color: Colors.redAccent,
            ),
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
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: const Color(0xFF65726B),
                    height: 1.5,
                  ),
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
