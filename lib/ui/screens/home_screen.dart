import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/plant.dart';
import '../../models/recognition_record.dart';
import '../../services/auth_service.dart';
import '../../services/database_service.dart';
import '../../state/app_state.dart';
import '../widgets/plant_image.dart';
import 'camera_screen.dart';
import 'favorites_screen.dart';
import 'history_screen.dart';
import 'library_screen.dart';
import 'plant_detail_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  static const _primaryGreen = Color(0xFF185B43);
  static const _lightGreen = Color(0xFFBFEFCA);
  static const _pageBackground = Color(0xFFF9FAF7);

  int _selectedIndex = 0;
  late final AnimationController _controller;
  late final Animation<double> _animation;
  late final List<Widget> _screens;

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

  Future<void> _signOut() async {
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

  void _openCamera() {
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => const CameraScreen(),
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

  Widget _buildHomeTab() {
    return SafeArea(
      child: Consumer2<AppState, DatabaseService>(
        builder: (context, appState, dbService, _) {
          final revision = appState.revision;

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
                        _HomeHeader(
                          onOpenLibrary: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const LibraryScreen(),
                              ),
                            );
                          },
                          onOpenHistory: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const HistoryScreen(),
                              ),
                            );
                          },
                          onSignOut: _signOut,
                        ),
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
                          onScanNow: _openCamera,
                          onUpload: _openCamera,
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
                          key: ValueKey('home-history-$revision'),
                          future: dbService.getHistory(),
                          builder: (context, snapshot) {
                            if (snapshot.connectionState ==
                                ConnectionState.waiting) {
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
                              return _EmptyRecentState(onAction: _openCamera);
                            }

                            return SizedBox(
                              height: 230,
                              child: ListView.separated(
                                scrollDirection: Axis.horizontal,
                                itemCount: records.length > 6 ? 6 : records.length,
                                separatorBuilder: (_, __) =>
                                    const SizedBox(width: 14),
                                itemBuilder: (context, index) {
                                  final record = records[index];
                                  final plant = record.plant.copyWith(
                                    imagePath: record.imagePath,
                                  );

                                  return _RecentPlantCard(
                                    plant: plant,
                                    onTap: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) =>
                                              PlantDetailScreen(plant: plant),
                                        ),
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
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Color(0x11000000),
              blurRadius: 20,
              offset: Offset(0, -4),
            ),
          ],
        ),
        padding: const EdgeInsets.fromLTRB(10, 8, 10, 12),
        child: BottomNavigationBar(
          currentIndex: _selectedIndex,
          onTap: _onTabTapped,
          type: BottomNavigationBarType.fixed,
          backgroundColor: Colors.white,
          elevation: 0,
          selectedItemColor: _primaryGreen,
          unselectedItemColor: const Color(0xFF4F5A53),
          selectedLabelStyle: const TextStyle(
            fontSize: 11.5,
            fontWeight: FontWeight.w500,
          ),
          unselectedLabelStyle: const TextStyle(
            fontSize: 11.5,
            fontWeight: FontWeight.w400,
          ),
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.home_outlined),
              activeIcon: _ActiveNavIcon(icon: Icons.home_rounded),
              label: 'Trang chủ',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.menu_book_outlined),
              activeIcon: _ActiveNavIcon(icon: Icons.menu_book_rounded),
              label: 'Thư viện',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.history_rounded),
              activeIcon: _ActiveNavIcon(icon: Icons.history_rounded),
              label: 'Lịch sử',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.favorite_border_rounded),
              activeIcon: _ActiveNavIcon(icon: Icons.favorite_rounded),
              label: 'Yêu thích',
            ),
          ],
        ),
      ),
    );
  }
}

class _HomeHeader extends StatelessWidget {
  final VoidCallback onOpenLibrary;
  final VoidCallback onOpenHistory;
  final VoidCallback onSignOut;

  const _HomeHeader({
    required this.onOpenLibrary,
    required this.onOpenHistory,
    required this.onSignOut,
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
        const Spacer(),
        PopupMenuButton<_HeaderAction>(
          tooltip: 'Mở menu',
          color: Colors.white,
          elevation: 10,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          onSelected: (value) {
            switch (value) {
              case _HeaderAction.library:
                onOpenLibrary();
              case _HeaderAction.history:
                onOpenHistory();
              case _HeaderAction.signOut:
                onSignOut();
            }
          },
          itemBuilder: (context) => const [
            PopupMenuItem(
              value: _HeaderAction.library,
              child: Text('Thư viện'),
            ),
            PopupMenuItem(
              value: _HeaderAction.history,
              child: Text('Lịch sử'),
            ),
            PopupMenuItem(
              value: _HeaderAction.signOut,
              child: Text('Đăng xuất'),
            ),
          ],
          child: const Padding(
            padding: EdgeInsets.all(6),
            child: Icon(
              Icons.menu_rounded,
              color: Color(0xFF185B43),
              size: 26,
            ),
          ),
        ),
      ],
    );
  }
}

enum _HeaderAction { library, history, signOut }

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
                          'Nhận diện ngay',
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

  const _RecentPlantCard({
    required this.plant,
    required this.onTap,
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
                    child: Container(
                      width: 34,
                      height: 34,
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        plant.isFavorite
                            ? Icons.favorite_rounded
                            : Icons.favorite_border_rounded,
                        color: plant.isFavorite
                            ? const Color(0xFFD12727)
                            : const Color(0xFF8B928E),
                        size: 19,
                      ),
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
            child: const Text('Nhận diện ngay'),
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

class _ActiveNavIcon extends StatelessWidget {
  final IconData icon;

  const _ActiveNavIcon({required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 9),
      decoration: BoxDecoration(
        color: _HomeScreenState._lightGreen,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Icon(
        icon,
        color: _HomeScreenState._primaryGreen,
        size: 22,
      ),
    );
  }
}
