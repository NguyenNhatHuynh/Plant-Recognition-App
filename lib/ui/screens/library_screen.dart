import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/plant.dart';
import '../../services/database_service.dart';
import '../../state/app_state.dart';
import '../widgets/favorite_action_button.dart';
import '../widgets/plant_gallery_carousel.dart';
import '../widgets/plant_image.dart';
import 'plant_detail_screen.dart';

class LibraryScreen extends StatefulWidget {
  const LibraryScreen({super.key});

  @override
  State<LibraryScreen> createState() => _LibraryScreenState();
}

enum _LibraryCategory {
  all,
  indoor,
  outdoor,
}

class _LibraryScreenState extends State<LibraryScreen> {
  static const _pageBackground = Color(0xFFF6F8F4);

  final TextEditingController _searchController = TextEditingController();
  final Set<int> _pendingFavoriteIds = <int>{};
  final Map<int, bool> _favoriteOverrides = <int, bool>{};
  Timer? _debounce;
  String _query = '';
  _LibraryCategory _selectedCategory = _LibraryCategory.all;

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 260), () {
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

    final nextValue = !(_favoriteOverrides[plantId] ?? plant.isFavorite);

    setState(() {
      _pendingFavoriteIds.add(plantId);
      _favoriteOverrides[plantId] = nextValue;
    });

    try {
      final dbService = context.read<DatabaseService>();
      final appState = context.read<AppState>();
      await dbService.toggleFavorite(plantId, nextValue);
      appState.markChanged();
    } catch (_) {
      if (mounted) {
        setState(() {
          _favoriteOverrides[plantId] = !nextValue;
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _pendingFavoriteIds.remove(plantId);
        });
      }
    }
  }

  bool _matchesCategory(Plant plant) {
    if (_selectedCategory == _LibraryCategory.all) {
      return true;
    }

    final haystack = [
      plant.description,
      plant.habitat,
      plant.lightRequirement,
      ...plant.uses,
    ].join(' ').toLowerCase();

    const indoorSignals = <String>[
      'trong nhà',
      'nội thất',
      'văn phòng',
      'bóng râm',
      'ánh sáng gián tiếp',
      'ánh sáng văn phòng',
      'bóng bán phần',
    ];

    const outdoorSignals = <String>[
      'ngoài trời',
      'sân vườn',
      'nắng trực tiếp',
      'cảnh quan',
      'chịu nắng',
      'khô hạn',
    ];

    final hasIndoorSignal =
        indoorSignals.any((signal) => haystack.contains(signal));
    final hasOutdoorSignal =
        outdoorSignals.any((signal) => haystack.contains(signal));

    switch (_selectedCategory) {
      case _LibraryCategory.all:
        return true;
      case _LibraryCategory.indoor:
        return hasIndoorSignal || !hasOutdoorSignal;
      case _LibraryCategory.outdoor:
        return hasOutdoorSignal;
    }
  }

  @override
  Widget build(BuildContext context) {
    context.watch<AppState>().revision;
    final dbService = context.read<DatabaseService>();

    return Scaffold(
      backgroundColor: _pageBackground,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 8),
              _LibrarySearchField(
                controller: _searchController,
                onChanged: _onSearchChanged,
              ),
              const SizedBox(height: 18),
              _CategoryChips(
                selectedCategory: _selectedCategory,
                onSelected: (category) {
                  setState(() {
                    _selectedCategory = category;
                  });
                },
              ),
              const SizedBox(height: 18),
              Expanded(
                child: FutureBuilder<List<Plant>>(
                  future: dbService.getAllPlants(query: _query),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting &&
                        !snapshot.hasData) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    final plants = (snapshot.data ?? const <Plant>[])
                        .where(_matchesCategory)
                        .toList(growable: false);

                    if (plants.isEmpty) {
                      return const _EmptyLibraryState();
                    }

                    return LayoutBuilder(
                      builder: (context, constraints) {
                        const spacing = 16.0;
                        final columnCount = constraints.maxWidth >= 760 ? 3 : 2;
                        final tileWidth = (constraints.maxWidth -
                                (spacing * (columnCount - 1))) /
                            columnCount;
                        final childAspectRatio = tileWidth / (tileWidth + 86);

                        return GridView.builder(
                          physics: const BouncingScrollPhysics(),
                          padding: const EdgeInsets.only(bottom: 24),
                          gridDelegate:
                              SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: columnCount,
                            crossAxisSpacing: spacing,
                            mainAxisSpacing: 18,
                            childAspectRatio: childAspectRatio,
                          ),
                          itemCount: plants.length,
                          itemBuilder: (context, index) {
                            final plant = plants[index];
                            final plantId = plant.id;
                            final effectiveFavorite = plantId != null &&
                                    _favoriteOverrides.containsKey(plantId)
                                ? _favoriteOverrides[plantId]!
                                : plant.isFavorite;

                            return _LibraryPlantCard(
                              plant: plant.copyWith(isFavorite: effectiveFavorite),
                              isFavoriteLoading: plantId != null &&
                                  _pendingFavoriteIds.contains(plantId),
                              showGalleryPreview: _query.isNotEmpty,
                              onFavoriteTap: () => _toggleFavorite(plant),
                              onTap: () {
                                Navigator.push(
                                  context,
                                  PlantDetailScreen.route(
                                    plant.copyWith(isFavorite: effectiveFavorite),
                                  ),
                                );
                              },
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

class _LibrarySearchField extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String> onChanged;

  const _LibrarySearchField({
    required this.controller,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      onChanged: onChanged,
      textInputAction: TextInputAction.search,
      decoration: InputDecoration(
        hintText: 'Tìm kiếm tên cây...',
        hintStyle: const TextStyle(
          color: Color(0xFF88938D),
          fontSize: 15,
        ),
        prefixIcon: const Icon(
          Icons.search_rounded,
          color: Color(0xFF7A847D),
          size: 25,
        ),
        suffixIcon: controller.text.isEmpty
            ? null
            : IconButton(
                onPressed: () {
                  controller.clear();
                  onChanged('');
                },
                icon: const Icon(Icons.close_rounded),
                tooltip: 'Xóa tìm kiếm',
              ),
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 18,
          vertical: 16,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0xFFD5DED7)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0xFFD5DED7)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(
            color: Color(0xFF9DCCA8),
            width: 1.4,
          ),
        ),
      ),
    );
  }
}

class _CategoryChips extends StatelessWidget {
  final _LibraryCategory selectedCategory;
  final ValueChanged<_LibraryCategory> onSelected;

  const _CategoryChips({
    required this.selectedCategory,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _CategoryChip(
            label: 'Tất cả',
            selected: selectedCategory == _LibraryCategory.all,
            onTap: () => onSelected(_LibraryCategory.all),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _CategoryChip(
            label: 'Trong nhà',
            selected: selectedCategory == _LibraryCategory.indoor,
            onTap: () => onSelected(_LibraryCategory.indoor),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _CategoryChip(
            label: 'Ngoài trời',
            selected: selectedCategory == _LibraryCategory.outdoor,
            onTap: () => onSelected(_LibraryCategory.outdoor),
          ),
        ),
      ],
    );
  }
}

class _CategoryChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _CategoryChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? const Color(0xFF2F785B) : const Color(0xFFBFEFD0),
      borderRadius: BorderRadius.circular(999),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: selected ? Colors.white : const Color(0xFF416252),
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                ),
          ),
        ),
      ),
    );
  }
}

class _LibraryPlantCard extends StatelessWidget {
  final Plant plant;
  final bool isFavoriteLoading;
  final bool showGalleryPreview;
  final VoidCallback onTap;
  final VoidCallback onFavoriteTap;

  const _LibraryPlantCard({
    required this.plant,
    required this.isFavoriteLoading,
    required this.showGalleryPreview,
    required this.onTap,
    required this.onFavoriteTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Ink(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            boxShadow: const [
              BoxShadow(
                color: Color(0x0D000000),
                blurRadius: 16,
                offset: Offset(0, 8),
              ),
            ],
            border: Border.all(color: const Color(0xFFEEF2EE)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: Hero(
                        tag: 'plant-${plant.id}',
                        child: PlantImage(
                          plant: plant,
                          height: double.infinity,
                          width: double.infinity,
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(18),
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      top: 10,
                      right: 10,
                      child: FavoriteActionButton(
                        isFavorite: plant.isFavorite,
                        isLoading: isFavoriteLoading,
                        onTap: onFavoriteTap,
                        size: 20,
                        padding: const EdgeInsets.all(7),
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 11, 12, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      plant.commonName,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            color: const Color(0xFF1E2A22),
                            fontWeight: FontWeight.w700,
                            fontSize: 15.5,
                            height: 1.15,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      plant.scientificName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: const Color(0xFF636F69),
                            fontStyle: FontStyle.italic,
                            fontWeight: FontWeight.w500,
                            height: 1.2,
                          ),
                    ),
                    if (showGalleryPreview) ...[
                      const SizedBox(height: 10),
                      PlantGalleryPreviewStrip(
                        plant: plant,
                        includePrimaryImageFirst: false,
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyLibraryState extends StatelessWidget {
  const _EmptyLibraryState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 28),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 76,
              height: 76,
              decoration: BoxDecoration(
                color: const Color(0xFFE7F2EA),
                borderRadius: BorderRadius.circular(24),
              ),
              child: const Icon(
                Icons.menu_book_rounded,
                size: 34,
                color: Color(0xFF1C5A45),
              ),
            ),
            const SizedBox(height: 18),
            Text(
              'Không tìm thấy cây phù hợp',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: const Color(0xFF213028),
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'Hãy thử tên khác hoặc đổi bộ lọc để khám phá thêm nhiều loài cây.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: const Color(0xFF68746D),
                    height: 1.55,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}
