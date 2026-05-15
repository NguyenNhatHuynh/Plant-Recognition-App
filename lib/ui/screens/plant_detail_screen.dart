import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/plant.dart';
import '../../services/database_service.dart';
import '../../state/app_state.dart';
import '../widgets/plant_image.dart';

class PlantDetailScreen extends StatefulWidget {
  final Plant plant;

  const PlantDetailScreen({
    super.key,
    required this.plant,
  });

  @override
  State<PlantDetailScreen> createState() => _PlantDetailScreenState();
}

class _PlantDetailScreenState extends State<PlantDetailScreen> {
  late Plant _plant;

  @override
  void initState() {
    super.initState();
    _plant = widget.plant;
  }

  Future<void> _toggleFavorite() async {
    final plantId = _plant.id;
    if (plantId == null) {
      return;
    }

    final nextValue = !_plant.isFavorite;
    setState(() {
      _plant = _plant.copyWith(isFavorite: nextValue);
    });

    final db = context.read<DatabaseService>();
    final appState = context.read<AppState>();
    await db.toggleFavorite(plantId, nextValue);
    appState.markChanged();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back),
                    onPressed: () => Navigator.pop(context),
                  ),
                  IconButton(
                    icon: Icon(
                      _plant.isFavorite ? Icons.favorite : Icons.favorite_border,
                      color: const Color(0xFFB08968),
                    ),
                    onPressed: _plant.id == null ? null : _toggleFavorite,
                  ),
                ],
              ),
              const SizedBox(height: 16),
              PlantImage(
                plant: _plant,
                height: 240,
                width: double.infinity,
                borderRadius: BorderRadius.circular(24),
              ),
              const SizedBox(height: 20),
              Text(
                _plant.commonName,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
              ),
              const SizedBox(height: 6),
              Text(
                _plant.scientificName,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: const Color(0xFF7F5539),
                    ),
              ),
              const SizedBox(height: 20),
              _InfoSection(title: 'Họ thực vật', value: _plant.family),
              _InfoSection(title: 'Môi trường sống', value: _plant.habitat),
              _ChipSection(title: 'Ứng dụng', items: _plant.uses),
              _ChipSection(title: 'Tên gọi khác', items: _plant.aliases),
              const SizedBox(height: 8),
              Text(
                _plant.description,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      height: 1.45,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InfoSection extends StatelessWidget {
  final String title;
  final String value;

  const _InfoSection({
    required this.title,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: 6),
          Text(
            value.isEmpty ? 'Chưa có dữ liệu' : value,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }
}

class _ChipSection extends StatelessWidget {
  final String title;
  final List<String> items;

  const _ChipSection({
    required this.title,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
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
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: items
                .map(
                  (item) => Chip(
                    label: Text(item),
                    backgroundColor: const Color(0xFFE8F5E9),
                    side: BorderSide.none,
                  ),
                )
                .toList(growable: false),
          ),
        ],
      ),
    );
  }
}
