import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../models/plant.dart';
import '../../models/recognition_candidate.dart';
import '../../models/recognition_result.dart';
import '../../services/auth_service.dart';
import '../../services/database_service.dart';
import '../../services/recognition_service.dart';
import '../../state/app_state.dart';
import '../widgets/plant_gallery_carousel.dart';
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
    final authService = context.read<AuthService>();
    final recognitionService = context.read<RecognitionService>();
    final databaseService = context.read<DatabaseService>();
    final appState = context.read<AppState>();

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final userId = authService.currentUser?.id.trim() ?? '';
      if (userId.isEmpty) {
        throw const RecognitionException(
          'Bạn cần đăng nhập để sử dụng tính năng nhận diện cây.',
        );
      }

      if (recognitionService.remoteBaseUrl.isEmpty) {
        final didReserveAttempt =
            await databaseService.tryConsumeRecognitionAttempt(
          userId: userId,
        );
        if (!didReserveAttempt) {
          final usedAttempts =
              await databaseService.getRecognitionAttemptsToday(
            userId: userId,
          );
          throw RecognitionException(
            'Bạn đã dùng hết $usedAttempts/${DatabaseService.dailyRecognitionLimit} lượt nhận diện hôm nay. Vui lòng quay lại vào ngày mai.',
          );
        }
      }

      final accessToken = authService.currentSession?.accessToken;
      final result = await recognitionService.recognizePlant(
        widget.imageFile,
        accessToken: accessToken,
      );
      final savedPlant = await databaseService.saveRecognition(
        result,
        imagePath: widget.imageFile.path,
      );
      appState.markChanged();
      if (!mounted) {
        return;
      }
      setState(() {
        _result = result;
        _savedPlant = savedPlant;
        _loading = false;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }
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
            icon: const Icon(Icons.refresh_rounded),
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
    } catch (_) {
      if (!mounted) {
        return;
      }
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
    final summary = '''
Kết quả nhận diện cây

Tên tiếng Việt: ${_fallbackText(_plant.commonName)}
Tên tiếng Anh: ${_fallbackText(_plant.englishName)}
Tên khoa học: ${_fallbackText(_plant.scientificName)}
Mô tả ngắn: ${_fallbackText(_plant.description)}
Ánh sáng: ${_fallbackText(_plant.lightRequirement)}
Tưới nước: ${_fallbackText(_plant.wateringNeeds)}
Công dụng: ${_plant.uses.isEmpty ? 'Chưa có dữ liệu.' : _plant.uses.join(', ')}
Nhận xét AI: ${_fallbackText(widget.result.analysisNote)}
''';

    await Clipboard.setData(ClipboardData(text: summary.trim()));
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Đã sao chép tóm tắt kết quả.'),
      ),
    );
  }

  String _fallbackText(String text) {
    final trimmed = text.trim();
    return trimmed.isEmpty ? 'Chưa có dữ liệu.' : trimmed;
  }

  @override
  Widget build(BuildContext context) {
    final topTags = <String>[
      if (_plant.careLevel.trim().isNotEmpty) _plant.careLevel,
      ..._plant.uses.take(2),
      if (_plant.uses.isEmpty) 'Nhận diện AI',
    ];

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _RecognitionHero(plant: _plant),
          const SizedBox(height: 20),
          Text(
            _plant.commonName,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: const Color(0xFF185B43),
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: 6),
          if (_plant.englishName.trim().isNotEmpty)
            Text(
              _plant.englishName,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: const Color(0xFF607168),
                    fontWeight: FontWeight.w600,
                  ),
            ),
          if (_plant.scientificName.trim().isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              _plant.scientificName,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: const Color(0xFF7B827E),
                    fontStyle: FontStyle.italic,
                  ),
            ),
          ],
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: topTags
                .map(
                  (tag) => Chip(
                    label: Text(tag),
                    backgroundColor: const Color(0xFFCFF0D7),
                    labelStyle:
                        Theme.of(context).textTheme.labelMedium?.copyWith(
                              color: const Color(0xFF2E5D44),
                              fontWeight: FontWeight.w600,
                            ),
                    side: BorderSide.none,
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                  ),
                )
                .toList(growable: false),
          ),
          const SizedBox(height: 18),
          _ContentCard(
            icon: Icons.badge_outlined,
            title: 'Tên gọi',
            child: Column(
              children: [
                _InfoRow(
                  label: 'Tên tiếng Việt',
                  value: _fallbackText(_plant.commonName),
                ),
                _InfoRow(
                  label: 'Tên gọi khác',
                  value: _plant.aliases.isEmpty
                      ? 'Chưa có dữ liệu.'
                      : _plant.aliases.join(', '),
                ),
                _InfoRow(
                  label: 'Tên tiếng Anh',
                  value: _fallbackText(_plant.englishName),
                ),
                _InfoRow(
                  label: 'Tên khoa học',
                  value: _fallbackText(_plant.scientificName),
                  italicValue: true,
                  isLast: true,
                ),
              ],
            ),
          ),
          _ContentCard(
            icon: Icons.description_outlined,
            title: 'Mô tả ngắn',
            child: Text(
              _fallbackText(_plant.description),
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: const Color(0xFF3D4741),
                    height: 1.7,
                  ),
            ),
          ),
          _ContentCard(
            icon: Icons.spa_outlined,
            title: 'Chăm sóc nhanh',
            child: _CareGrid(
              items: [
                _CareMetric(
                  icon: Icons.wb_sunny_outlined,
                  label: 'Ánh sáng',
                  value: _fallbackText(_plant.lightRequirement),
                ),
                _CareMetric(
                  icon: Icons.water_drop_outlined,
                  label: 'Tưới nước',
                  value: _fallbackText(_plant.wateringNeeds),
                ),
                _CareMetric(
                  icon: Icons.emoji_objects_outlined,
                  label: 'Độ dễ chăm',
                  value: _fallbackText(_plant.careLevel),
                ),
                _CareMetric(
                  icon: Icons.thermostat_outlined,
                  label: 'Nhiệt độ',
                  value: _fallbackText(_plant.suitableTemperature),
                ),
                _CareMetric(
                  icon: Icons.grass_outlined,
                  label: 'Loại đất',
                  value: _fallbackText(_plant.soilType),
                ),
                _CareMetric(
                  icon: Icons.compost_outlined,
                  label: 'Bón phân',
                  value: _fallbackText(_plant.fertilizingTips),
                ),
              ],
            ),
          ),
          _ContentCard(
            icon: Icons.auto_awesome_outlined,
            title: 'Lợi ích và công dụng',
            child: _TagWrap(
              items: _plant.uses,
              emptyText: 'Chưa có dữ liệu công dụng cụ thể.',
            ),
          ),
          _ContentCard(
            icon: Icons.public_outlined,
            title: 'Nguồn gốc và sinh trưởng',
            child: Column(
              children: [
                _InfoRow(
                  label: 'Họ thực vật',
                  value: _fallbackText(_plant.family),
                ),
                _InfoRow(
                  label: 'Nguồn gốc',
                  value: _fallbackText(_plant.origin),
                ),
                _InfoRow(
                  label: 'Môi trường sống',
                  value: _fallbackText(_plant.habitat),
                ),
                _InfoRow(
                  label: 'Kích thước tối đa',
                  value: _fallbackText(_plant.maximumSize),
                  isLast: true,
                ),
              ],
            ),
          ),
          _ContentCard(
            icon: Icons.health_and_safety_outlined,
            title: 'An toàn và lưu ý',
            child: Column(
              children: [
                _InfoRow(
                  label: 'Cảnh báo độc tính',
                  value: _fallbackText(_plant.toxicityWarning),
                ),
                _InfoRow(
                  label: 'Bệnh thường gặp',
                  value: _fallbackText(_plant.commonIssues),
                ),
                _InfoRow(
                  label: 'Phong thủy',
                  value: _fallbackText(_plant.fengShuiMeaning),
                  isLast: true,
                ),
              ],
            ),
          ),
          _ContentCard(
            icon: Icons.tips_and_updates_outlined,
            title: 'Nhận xét AI',
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
}

class _RecognitionHero extends StatelessWidget {
  final Plant plant;

  const _RecognitionHero({
    required this.plant,
  });

  @override
  Widget build(BuildContext context) {
    return PlantGalleryCarousel(
      plant: plant,
      height: 262,
      borderRadius: BorderRadius.circular(24),
      includePrimaryImageFirst: true,
      showThumbnails: true,
      showCounter: true,
    );
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
              Expanded(
                child: Text(
                  title,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: const Color(0xFF185B43),
                        fontWeight: FontWeight.w700,
                      ),
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

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  final bool italicValue;
  final bool isLast;

  const _InfoRow({
    required this.label,
    required this.value,
    this.italicValue = false,
    this.isLast = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: isLast ? 0 : 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 116,
            child: Padding(
              padding: const EdgeInsets.only(top: 1),
              child: Text(
                label,
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: const Color(0xFF6A746F),
                      fontWeight: FontWeight.w700,
                    ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              value,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: const Color(0xFF3D4741),
                    height: 1.6,
                    fontStyle:
                        italicValue ? FontStyle.italic : FontStyle.normal,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CareMetric {
  final IconData icon;
  final String label;
  final String value;

  const _CareMetric({
    required this.icon,
    required this.label,
    required this.value,
  });
}

class _CareGrid extends StatelessWidget {
  final List<_CareMetric> items;

  const _CareGrid({required this.items});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final itemWidth = constraints.maxWidth >= 640
            ? (constraints.maxWidth - 12) / 2
            : constraints.maxWidth;

        return Wrap(
          spacing: 12,
          runSpacing: 12,
          children: items
              .map(
                (item) => SizedBox(
                  width: itemWidth,
                  child: _CareTile(item: item),
                ),
              )
              .toList(growable: false),
        );
      },
    );
  }
}

class _CareTile extends StatelessWidget {
  final _CareMetric item;

  const _CareTile({required this.item});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAF7),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8E3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                item.icon,
                size: 18,
                color: const Color(0xFF185B43),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  item.label,
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        color: const Color(0xFF22322A),
                        fontWeight: FontWeight.w700,
                      ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            item.value,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: const Color(0xFF3D4741),
                  height: 1.5,
                ),
          ),
        ],
      ),
    );
  }
}

class _TagWrap extends StatelessWidget {
  final List<String> items;
  final String emptyText;

  const _TagWrap({
    required this.items,
    required this.emptyText,
  });

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return Text(
        emptyText,
        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: const Color(0xFF3D4741),
              height: 1.6,
            ),
      );
    }

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: items
          .map(
            (item) => Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFFE8F4EC),
                borderRadius: BorderRadius.circular(999),
                border: Border.all(color: const Color(0xFFD3E7D8)),
              ),
              child: Text(
                item,
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: const Color(0xFF2E5D44),
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ),
          )
          .toList(growable: false),
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
                if (candidate.englishName.trim().isNotEmpty)
                  Text(
                    candidate.englishName,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: const Color(0xFF556760),
                          fontWeight: FontWeight.w500,
                        ),
                  ),
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
