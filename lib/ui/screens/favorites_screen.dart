import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/plant.dart';
import '../../services/database_service.dart';
import '../../state/app_state.dart';
import '../widgets/favorite_action_button.dart';
import '../widgets/plant_image.dart';
import 'plant_detail_screen.dart';

class FavoritesScreen extends StatefulWidget {
  const FavoritesScreen({super.key});

  @override
  State<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen> {
  static const _pageBackground = Color(0xFFF6F8F4);

  final TextEditingController _searchController = TextEditingController();
  final Set<int> _pendingFavoriteIds = <int>{};
  final Set<int> _hiddenFavoriteIds = <int>{};

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _removeFromFavorites(Plant plant) async {
    final plantId = plant.id;
    if (plantId == null || _pendingFavoriteIds.contains(plantId)) {
      return;
    }

    setState(() {
      _pendingFavoriteIds.add(plantId);
    });

    final dbService = context.read<DatabaseService>();
    final appState = context.read<AppState>();

    try {
      await Future<void>.delayed(const Duration(milliseconds: 180));
      if (mounted) {
        setState(() {
          _hiddenFavoriteIds.add(plantId);
        });
      }

      await dbService.toggleFavorite(plantId, false);
      appState.markChanged();
    } catch (_) {
      if (mounted) {
        setState(() {
          _hiddenFavoriteIds.remove(plantId);
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

  bool _matchesQuery(Plant plant, String query) {
    if (query.isEmpty) {
      return true;
    }

    final normalized = query.toLowerCase();
    return plant.commonName.toLowerCase().contains(normalized) ||
        plant.scientificName.toLowerCase().contains(normalized) ||
        plant.family.toLowerCase().contains(normalized) ||
        plant.aliases.any((alias) => alias.toLowerCase().contains(normalized));
  }

  @override
  Widget build(BuildContext context) {
    context.watch<AppState>().revision;
    final dbService = context.read<DatabaseService>();

    return Scaffold(
      backgroundColor: _pageBackground,
      body: SafeArea(
        child: FutureBuilder<List<Plant>>(
          future: dbService.getFavoritePlants(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting &&
                !snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }

            final favoritePlants = (snapshot.data ?? const <Plant>[])
                .where((plant) =>
                    plant.id == null || !_hiddenFavoriteIds.contains(plant.id))
                .toList(growable: false);
            final query = _searchController.text.trim();
            final filteredPlants = favoritePlants
                .where((plant) => _matchesQuery(plant, query))
                .toList(growable: false);

            return AnimatedSwitcher(
              duration: const Duration(milliseconds: 220),
              child: _FavoritesContent(
                key: ValueKey('$query|${favoritePlants.length}'),
                title: 'Cây yêu thích',
                subtitle: 'Danh sách các loài cây bạn đã lưu.',
                searchController: _searchController,
                onSearchChanged: (_) => setState(() {}),
                plants: filteredPlants,
                hasAnyFavorites: favoritePlants.isNotEmpty,
                pendingFavoriteIds: _pendingFavoriteIds,
                onOpenPlant: (plant) {
                  Navigator.push(
                    context,
                    PlantDetailScreen.route(plant),
                  );
                },
                onToggleFavorite: _removeFromFavorites,
              ),
            );
          },
        ),
      ),
    );
  }
}

class _FavoritesContent extends StatelessWidget {
  final String title;
  final String subtitle;
  final TextEditingController searchController;
  final ValueChanged<String> onSearchChanged;
  final List<Plant> plants;
  final bool hasAnyFavorites;
  final Set<int> pendingFavoriteIds;
  final ValueChanged<Plant> onOpenPlant;
  final ValueChanged<Plant> onToggleFavorite;

  const _FavoritesContent({
    super.key,
    required this.title,
    required this.subtitle,
    required this.searchController,
    required this.onSearchChanged,
    required this.plants,
    required this.hasAnyFavorites,
    required this.pendingFavoriteIds,
    required this.onOpenPlant,
    required this.onToggleFavorite,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final horizontalPadding = constraints.maxWidth >= 720 ? 28.0 : 16.0;
        final spacing = constraints.maxWidth >= 720 ? 18.0 : 12.0;
        final columnCount = constraints.maxWidth >= 900
            ? 3
            : constraints.maxWidth >= 360
                ? 2
                : 1;
        final tileWidth =
            (constraints.maxWidth -
                    (horizontalPadding * 2) -
                    (spacing * (columnCount - 1))) /
                columnCount;
        final childAspectRatio = tileWidth / (tileWidth + 74);

        return CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            SliverPadding(
              padding: EdgeInsets.fromLTRB(
                horizontalPadding,
                14,
                horizontalPadding,
                0,
              ),
              sliver: SliverList(
                delegate: SliverChildListDelegate.fixed([
                  const _FavoritesHeader(),
                  const SizedBox(height: 18),
                  Text(
                    title,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          color: const Color(0xFF1D2A22),
                          fontWeight: FontWeight.w700,
                          fontSize: 21,
                          letterSpacing: -0.35,
                          height: 1.12,
                        ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    subtitle,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: const Color(0xFF68746D),
                          fontWeight: FontWeight.w400,
                          fontSize: 13.5,
                          height: 1.35,
                        ),
                  ),
                  const SizedBox(height: 20),
                  _FavoritesSearchField(
                    controller: searchController,
                    onChanged: onSearchChanged,
                  ),
                  const SizedBox(height: 20),
                ]),
              ),
            ),
            if (!hasAnyFavorites)
              SliverFillRemaining(
                hasScrollBody: false,
                child: const _EmptyFavoritesState(
                  message: 'Bạn chưa lưu cây nào vào mục yêu thích.',
                ),
              )
            else if (plants.isEmpty)
              SliverFillRemaining(
                hasScrollBody: false,
                child: const _EmptyFavoritesState(
                  message: 'Không tìm thấy cây phù hợp với từ khóa của bạn.',
                ),
              )
            else
              SliverPadding(
                padding: EdgeInsets.fromLTRB(
                  horizontalPadding,
                  0,
                  horizontalPadding,
                  28,
                ),
                sliver: SliverGrid(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final plant = plants[index];
                      final plantId = plant.id;
                      final isPending = plantId != null &&
                          pendingFavoriteIds.contains(plantId);

                      return _FavoritePlantCard(
                        plant: plant,
                        isPending: isPending,
                        onTap: () => onOpenPlant(plant),
                        onFavoriteTap: () => onToggleFavorite(plant),
                      );
                    },
                    childCount: plants.length,
                  ),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: columnCount,
                    mainAxisSpacing: spacing,
                    crossAxisSpacing: spacing,
                    childAspectRatio: childAspectRatio,
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

class _FavoritesHeader extends StatelessWidget {
  const _FavoritesHeader();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 30,
          height: 30,
          decoration: BoxDecoration(
            color: const Color(0xFFE6F2EA),
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Icon(
            Icons.spa_rounded,
            color: Color(0xFF1C5A45),
            size: 18,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            'Nhận Diện Cây Cối',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: const Color(0xFF1C5A45),
                  fontWeight: FontWeight.w500,
                  fontSize: 14.5,
                ),
          ),
        ),
        IconButton(
          onPressed: () => Scaffold.maybeOf(context)?.openEndDrawer(),
          icon: const Icon(
            Icons.menu_rounded,
            color: Color(0xFF36433C),
          ),
          tooltip: 'Mở menu',
        ),
      ],
    );
  }
}

class _FavoritesSearchField extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String> onChanged;

  const _FavoritesSearchField({
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
        hintText: 'Tìm kiếm trong danh sách...',
        prefixIcon: const Icon(
          Icons.search_rounded,
          color: Color(0xFF7A847D),
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
          vertical: 14,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: Color(0xFFD6DED8)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: Color(0xFFD6DED8)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(
            color: Color(0xFF9DCCA8),
            width: 1.4,
          ),
        ),
      ),
    );
  }
}

class _FavoritePlantCard extends StatelessWidget {
  final Plant plant;
  final bool isPending;
  final VoidCallback onTap;
  final VoidCallback onFavoriteTap;

  const _FavoritePlantCard({
    required this.plant,
    required this.isPending,
    required this.onTap,
    required this.onFavoriteTap,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedScale(
      scale: isPending ? 0.92 : 1,
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOutCubic,
      child: AnimatedOpacity(
        opacity: isPending ? 0 : 1,
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOutCubic,
        child: Material(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          shadowColor: const Color(0x12000000),
          elevation: 0,
          child: InkWell(
            onTap: isPending ? null : onTap,
            borderRadius: BorderRadius.circular(20),
            child: Ink(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x0F000000),
                    blurRadius: 20,
                    offset: Offset(0, 8),
                  ),
                ],
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
                                top: Radius.circular(20),
                              ),
                            ),
                          ),
                        ),
                        Positioned(
                          top: 8,
                          right: 8,
                          child: FavoriteActionButton(
                            isFavorite: true,
                            isLoading: isPending,
                            onTap: onFavoriteTap,
                            size: 20,
                            padding: const EdgeInsets.all(7),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          plant.commonName,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style:
                              Theme.of(context).textTheme.titleMedium?.copyWith(
                                    color: const Color(0xFF263129),
                                    fontWeight: FontWeight.w500,
                                    fontSize: 15,
                                    height: 1.18,
                                  ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          plant.scientificName.isEmpty
                              ? plant.family
                              : plant.scientificName,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style:
                              Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: const Color(0xFF6D756F),
                                    fontStyle: FontStyle.italic,
                                    fontSize: 12.5,
                                    height: 1.28,
                                  ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _EmptyFavoritesState extends StatelessWidget {
  final String message;

  const _EmptyFavoritesState({required this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 28),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 74,
              height: 74,
              decoration: BoxDecoration(
                color: const Color(0xFFE7F2EA),
                borderRadius: BorderRadius.circular(24),
              ),
              child: const Icon(
                Icons.favorite_border_rounded,
                size: 34,
                color: Color(0xFF1C5A45),
              ),
            ),
            const SizedBox(height: 18),
            Text(
              'Danh sách yêu thích đang trống',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: const Color(0xFF213028),
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
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
