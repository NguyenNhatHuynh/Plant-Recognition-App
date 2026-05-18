import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/plant.dart';
import '../../services/database_service.dart';
import '../../state/app_state.dart';
import '../widgets/plant_card.dart';
import 'plant_detail_screen.dart';

class LibraryScreen extends StatefulWidget {
  const LibraryScreen({super.key});

  @override
  State<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends State<LibraryScreen> {
  final TextEditingController _searchController = TextEditingController();
  final Set<int> _pendingFavoriteIds = <int>{};
  Timer? _debounce;
  String _query = '';

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      if (!mounted) {
        return;
      }
      setState(() {
        _query = value.trim();
      });
    });
  }

  Future<void> _toggleFavorite(Plant plant) async {
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
        title: const Text('ThÆ° viá»‡n'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: _searchController,
                onChanged: _onSearchChanged,
                decoration: InputDecoration(
                  hintText: 'TÃ¬m theo tÃªn, há», mÃ´ táº£...',
                  prefixIcon: const Icon(Icons.search),
                  filled: true,
                  fillColor: const Color(0xFFF5F7F5),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: FutureBuilder<List<Plant>>(
                  key: ValueKey('${revision}_$_query'),
                  future: dbService.getAllPlants(query: _query),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    final plants = snapshot.data ?? const <Plant>[];
                    if (plants.isEmpty) {
                      return const Center(
                        child: Text('KhÃ´ng tÃ¬m tháº¥y loÃ i phÃ¹ há»£p.'),
                      );
                    }
                    return ListView.builder(
                      itemCount: plants.length,
                      itemBuilder: (context, index) {
                        final plant = plants[index];
                        return PlantCard(
                          plant: plant,
                          isFavoriteLoading: plant.id != null &&
                              _pendingFavoriteIds.contains(plant.id),
                          onFavoriteTap: () => _toggleFavorite(plant),
                          onTap: () {
                            Navigator.push(
                              context,
                              PlantDetailScreen.route(plant),
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
