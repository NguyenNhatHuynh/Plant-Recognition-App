import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../models/plant.dart';
import '../../models/recognition_record.dart';
import '../../services/auth_service.dart';
import '../../services/database_service.dart';
import '../../state/app_state.dart';
import '../widgets/app_side_menu.dart';
import '../widgets/favorite_action_button.dart';
import '../widgets/plant_image.dart';
import 'about_screen.dart';
import 'favorites_screen.dart';
import 'feedback_screen.dart';
import 'history_screen.dart';
import 'library_screen.dart';
import 'plant_detail_screen.dart';
import 'profile_screen.dart';
import 'recognition_screen.dart';
import 'settings_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  static const _primaryGreen = Color(0xFF185B43);
  static const _lightGreen = Color(0xFFCFF0D7);
  static const _pageBackground = Color(0xFFF9FAF7);

  int _selectedIndex = 0;
  late final AnimationController _controller;
  late final Animation<double> _animation;
  late final List<Widget> _screens;
  final ImagePicker _picker = ImagePicker();
  final Set<int> _pendingFavoriteIds = <int>{};
  final Map<int, bool> _favoriteOverrides = <int, bool>{};

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 380),
    );
    _animation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    );
    _screens = [
      _buildHomeTab(),
      const LibraryScreen(),
      const HistoryScreen(),
      const FavoritesScreen(),
    ];
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onTabTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
    _controller
      ..reset()
      ..forward();
  }

  String _displayNameForCurrentUser() {
    final user = context.read<AuthService>().currentUser;
    if (user == null) {
      return 'Người dùng';
    }

    final metadata = user.userMetadata;
    final candidates = <Object?>[
      metadata?['display_name'],
      metadata?['full_name'],
      metadata?['name'],
      user.email?.split('@').first,
    ];

    for (final candidate in candidates) {
      final text = candidate?.toString().trim() ?? '';
      if (text.isNotEmpty) {
        return text;
      }
    }

    return 'Người dùng';
  }

  Future<void> _openHeaderMenu() async {
    final authService = context.read<AuthService>();
    final user = authService.currentUser;
    final displayName = _displayNameForCurrentUser();
    final email = user?.email?.trim().isNotEmpty == true
        ? user!.email!.trim()
        : 'Chưa có email';

    final action = await showAppSideMenu(
      context: context,
      displayName: displayName,
      email: email,
      selectedAction: AppSideMenuAction.profile,
    );

    if (!mounted || action == null) {
      return;
    }

    switch (action) {
      case AppSideMenuAction.profile:
        Navigator.push(context, ProfileScreen.route());
      case AppSideMenuAction.library:
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => const LibraryScreen(),
          ),
        );
      case AppSideMenuAction.history:
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => const HistoryScreen(),
          ),
        );
      case AppSideMenuAction.settings:
        Navigator.push(context, SettingsScreen.route());
      case AppSideMenuAction.careGuide:
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Hướng dẫn chăm sóc sẽ sớm được hoàn thiện.'),
          ),
        );
      case AppSideMenuAction.about:
        Navigator.push(context, AboutScreen.route());
      case AppSideMenuAction.feedback:
        Navigator.push(context, FeedbackScreen.route());
      case AppSideMenuAction.signOut:
        _signOut();
    }
  }

  Future<void> _signOut() async {
    final shouldSignOut = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xác nhận đăng xuất'),
        content: const Text(
          'Bạn có chắc muốn đăng xuất khỏi tài khoản này không?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Ở lại'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFB3261E),
              foregroundColor: Colors.white,
            ),
            child: const Text('Đăng xuất'),
          ),
        ],
      ),
    );

    if (shouldSignOut != true || !mounted) {
      return;
    }

    final authService = context.read<AuthService>();
    final messenger = ScaffoldMessenger.of(context);
    final errorColor = Theme.of(context).colorScheme.error;

    try {
      await authService.signOut();
      if (!mounted) {
        return;
      }
      messenger.showSnackBar(
        const SnackBar(content: Text('Bạn đã đăng xuất.')),
      );
    } catch (error) {
      if (!mounted) {
        return;
      }
      messenger.showSnackBar(
        SnackBar(
          content: Text(error.toString()),
          backgroundColor: errorColor,
        ),
      );
    }
  }

  Future<void> _pickAndRecognize(ImageSource source) async {
    final image = await _picker.pickImage(
      source: source,
      imageQuality: 90,
      maxWidth: 1600,
    );

    if (image == null || !mounted) {
      return;
    }

    await Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => RecognitionScreen(imageFile: image),
        transitionsBuilder: (_, animation, __, child) {
          return FadeTransition(
            opacity: animation,
            child: child,
          );
        },
        transitionDuration: const Duration(milliseconds: 220),
      ),
    );
  }

  Future<void> _toggleFavorite(Plant plant) async {
    final plantId = plant.id;
    if (plantId == null || _pendingFavoriteIds.contains(plantId)) {
      return;
    }

    final nextValue = !plant.isFavorite;

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

  Widget _buildHomeTab() {
    return SafeArea(
      child: Consumer2<AppState, DatabaseService>(
        builder: (context, appState, dbService, _) {
          return AnimatedBuilder(
            animation: _animation,
            builder: (context, child) {
              return Transform.translate(
                offset: Offset(0, 14 * (1 - _animation.value)),
                child: Opacity(
                  opacity: _animation.value,
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _HomeHeader(onOpenMenu: _openHeaderMenu),
                        const SizedBox(height: 12),
                        Text(
                          'Chào người yêu cây!',
                          style:
                              Theme.of(context).textTheme.titleSmall?.copyWith(
                                    color: const Color(0xFF4D5A53),
                                    fontWeight: FontWeight.w500,
                                  ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Bạn muốn tìm hiểu cây gì\nhôm nay?',
                          style:
                              Theme.of(context).textTheme.headlineSmall?.copyWith(
                                    color: _primaryGreen,
                                    fontWeight: FontWeight.w700,
                                    height: 1.17,
                                  ),
                        ),
                        const SizedBox(height: 18),
                        _HomeHeroCard(
                          onScanNow: () => _pickAndRecognize(ImageSource.camera),
                          onUpload: () => _pickAndRecognize(ImageSource.gallery),
                          onOpenHistory: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const HistoryScreen(),
                              ),
                            );
                          },
                        ),
                        const SizedBox(height: 28),
                        _SectionHeader(
                          title: 'Quét gần đây',
                          actionLabel: 'Xem tất cả',
                          onAction: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const HistoryScreen(),
                              ),
                            );
                          },
                        ),
                        const SizedBox(height: 16),
                        FutureBuilder<List<RecognitionRecord>>(
                          future: dbService.getHistory(),
                          builder: (context, snapshot) {
                            if (snapshot.connectionState ==
                                    ConnectionState.waiting &&
                                !snapshot.hasData) {
                              return const SizedBox(
                                height: 220,
                                child: Center(
                                  child: CircularProgressIndicator(),
                                ),
                              );
                            }

                            final records =
                                snapshot.data ?? const <RecognitionRecord>[];
                            if (records.isEmpty) {
                              return _EmptyRecentState(
                                onAction: () =>
                                    _pickAndRecognize(ImageSource.camera),
                              );
                            }

                            return SizedBox(
                              height: 230,
                              child: ListView.separated(
                                scrollDirection: Axis.horizontal,
                                itemCount:
                                    records.length > 6 ? 6 : records.length,
                                separatorBuilder: (_, __) =>
                                    const SizedBox(width: 14),
                                itemBuilder: (context, index) {
                                  final record = records[index];
                                  final basePlant = record.plant.copyWith(
                                    imagePath: record.imagePath,
                                  );
                                  final override = basePlant.id == null
                                      ? null
                                      : _favoriteOverrides[basePlant.id];
                                  final plant = override == null
                                      ? basePlant
                                      : basePlant.copyWith(
                                          isFavorite: override,
                                        );

                                  return _RecentPlantCard(
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
                              ),
                            );
                          },
                        ),
                        const SizedBox(height: 92),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _pageBackground,
      body: IndexedStack(
        index: _selectedIndex,
        children: _screens,
      ),
      bottomNavigationBar: _BottomNavBar(
        selectedIndex: _selectedIndex,
        onTap: _onTabTapped,
      ),
    );
  }
}

class _HomeHeader extends StatelessWidget {
  final VoidCallback onOpenMenu;

  const _HomeHeader({
    required this.onOpenMenu,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: const Color(0xFF2D6A4F),
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Icon(
            Icons.spa_rounded,
            size: 17,
            color: Colors.white,
          ),
        ),
        const SizedBox(width: 10),
        Text(
          'Nhận Diện Cây Cối',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: const Color(0xFF185B43),
                fontWeight: FontWeight.w800,
              ),
        ),
        const Spacer(),
        Material(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          child: InkWell(
            onTap: onOpenMenu,
            borderRadius: BorderRadius.circular(14),
            child: Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFE4ECE6)),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x12000000),
                    blurRadius: 16,
                    offset: Offset(0, 6),
                  ),
                ],
              ),
              child: const Icon(
                Icons.menu_rounded,
                color: Color(0xFF185B43),
                size: 24,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _HomeHeroCard extends StatelessWidget {
  final VoidCallback onScanNow;
  final VoidCallback onUpload;
  final VoidCallback onOpenHistory;

  const _HomeHeroCard({
    required this.onScanNow,
    required this.onUpload,
    required this.onOpenHistory,
  });

  @override
  Widget build(BuildContext context) {
    final isCompact = MediaQuery.sizeOf(context).width < 390;

    return Container(
      padding: EdgeInsets.fromLTRB(
        isCompact ? 20 : 24,
        isCompact ? 22 : 28,
        isCompact ? 20 : 24,
        isCompact ? 20 : 22,
      ),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: const LinearGradient(
          colors: [Color(0xFF2E6B4A), Color(0xFF23563E)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x18000000),
            blurRadius: 26,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned.fill(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: const _HeroLeafBackdrop(),
            ),
          ),
          Column(
            children: [
              Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                ),
                child: InkWell(
                  onTap: onScanNow,
                  borderRadius: BorderRadius.circular(18),
                  child: Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: isCompact ? 15 : 18,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.camera_alt_rounded,
                          color: Color(0xFF185B43),
                          size: 21,
                        ),
                        const SizedBox(width: 9),
                        Text(
                          'Chụp cây để nhận diện',
                          style:
                              Theme.of(context).textTheme.titleLarge?.copyWith(
                                    color: const Color(0xFF185B43),
                                    fontWeight: FontWeight.w500,
                                  ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _HeroSmallButton(
                      icon: Icons.image_outlined,
                      label: 'Tải ảnh lên',
                      onTap: onUpload,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _HeroSmallButton(
                      icon: Icons.history_rounded,
                      label: 'Lịch sử',
                      onTap: onOpenHistory,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _HeroSmallButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _HeroSmallButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withValues(alpha: 0.12),
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 15),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.18),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: Colors.white, size: 18),
              const SizedBox(width: 7),
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w400,
                      ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final String actionLabel;
  final VoidCallback onAction;

  const _SectionHeader({
    required this.title,
    required this.actionLabel,
    required this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: const Color(0xFF1B2320),
                  fontWeight: FontWeight.w500,
                ),
          ),
        ),
        TextButton(
          onPressed: onAction,
          style: TextButton.styleFrom(
            padding: EdgeInsets.zero,
            minimumSize: const Size(0, 0),
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
          child: Text(
            actionLabel,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: const Color(0xFF185B43),
                  fontWeight: FontWeight.w500,
                ),
          ),
        ),
      ],
    );
  }
}

class _RecentPlantCard extends StatelessWidget {
  final Plant plant;
  final VoidCallback onTap;
  final VoidCallback onFavoriteTap;
  final bool isFavoriteLoading;

  const _RecentPlantCard({
    required this.plant,
    required this.onTap,
    required this.onFavoriteTap,
    required this.isFavoriteLoading,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 162,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Stack(
                children: [
                  Hero(
                    tag: 'plant-${plant.id}',
                    child: PlantImage(
                      plant: plant,
                      height: 160,
                      width: 162,
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                  Positioned(
                    right: 8,
                    top: 8,
                    child: FavoriteActionButton(
                      isFavorite: plant.isFavorite,
                      isLoading: isFavoriteLoading,
                      onTap: onFavoriteTap,
                      size: 19,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                plant.commonName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: const Color(0xFF1E2420),
                      fontWeight: FontWeight.w400,
                    ),
              ),
              const SizedBox(height: 2),
              Text(
                plant.scientificName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: const Color(0xFF6F7872),
                      fontStyle: FontStyle.italic,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyRecentState extends StatelessWidget {
  final VoidCallback onAction;

  const _EmptyRecentState({required this.onAction});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE4E9E4)),
      ),
      child: Column(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: const Color(0xFFEEF8F0),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(
              Icons.eco_outlined,
              color: Color(0xFF185B43),
            ),
          ),
          const SizedBox(height: 14),
          Text(
            'Chưa có lượt quét nào',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'Chụp hoặc tải ảnh cây lên để bắt đầu nhận diện.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: const Color(0xFF66726B),
                ),
          ),
          const SizedBox(height: 18),
          ElevatedButton(
            onPressed: onAction,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF185B43),
              foregroundColor: Colors.white,
            ),
            child: const Text('Chụp cây ngay'),
          ),
        ],
      ),
    );
  }
}

class _HeroLeafBackdrop extends StatelessWidget {
  const _HeroLeafBackdrop();

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: const [
        _LeafShape(
          alignment: Alignment.topLeft,
          width: 230,
          height: 120,
          angle: -0.42,
        ),
        _LeafShape(
          alignment: Alignment.centerRight,
          width: 230,
          height: 120,
          angle: 0.28,
        ),
        _LeafShape(
          alignment: Alignment.bottomLeft,
          width: 180,
          height: 100,
          angle: 0.58,
        ),
        _LeafShape(
          alignment: Alignment.center,
          width: 170,
          height: 90,
          angle: -0.18,
        ),
      ],
    );
  }
}

class _LeafShape extends StatelessWidget {
  final Alignment alignment;
  final double width;
  final double height;
  final double angle;

  const _LeafShape({
    required this.alignment,
    required this.width,
    required this.height,
    required this.angle,
  });

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: alignment,
      child: Transform.rotate(
        angle: angle,
        child: Container(
          width: width,
          height: height,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(999),
            gradient: LinearGradient(
              colors: [
                Colors.white.withValues(alpha: 0.10),
                Colors.black.withValues(alpha: 0.04),
              ],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
        ),
      ),
    );
  }
}

class _BottomNavBar extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onTap;

  const _BottomNavBar({
    required this.selectedIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Color(0x11000000),
            blurRadius: 22,
            offset: Offset(0, -4),
          ),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            _BottomNavItem(
              icon: Icons.home_outlined,
              activeIcon: Icons.home_rounded,
              label: 'Trang chủ',
              selected: selectedIndex == 0,
              onTap: () => onTap(0),
            ),
            _BottomNavItem(
              icon: Icons.menu_book_outlined,
              activeIcon: Icons.menu_book_rounded,
              label: 'Thư viện',
              selected: selectedIndex == 1,
              onTap: () => onTap(1),
            ),
            _BottomNavItem(
              icon: Icons.history_rounded,
              activeIcon: Icons.history_rounded,
              label: 'Lịch sử',
              selected: selectedIndex == 2,
              onTap: () => onTap(2),
            ),
            _BottomNavItem(
              icon: Icons.favorite_border_rounded,
              activeIcon: Icons.favorite_rounded,
              label: 'Yêu thích',
              selected: selectedIndex == 3,
              onTap: () => onTap(3),
            ),
          ],
        ),
      ),
    );
  }
}

class _BottomNavItem extends StatelessWidget {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _BottomNavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOutCubic,
        margin: const EdgeInsets.symmetric(horizontal: 4),
        decoration: BoxDecoration(
          color: selected ? _HomeScreenState._lightGreen : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    selected ? activeIcon : icon,
                    color: selected
                        ? _HomeScreenState._primaryGreen
                        : const Color(0xFF4F5A53),
                    size: 23,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          color: selected
                              ? _HomeScreenState._primaryGreen
                              : const Color(0xFF4F5A53),
                          fontSize: 12,
                          fontWeight:
                              selected ? FontWeight.w600 : FontWeight.w500,
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
