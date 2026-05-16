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
  static const _pageBackground = Color(0xFFF7F8F4);

  int _selectedIndex = 0;
  late final AnimationController _controller;
  late final Animation<double> _animation;
  late final List<Widget> _screens;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 450),
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
        transitionDuration: const Duration(milliseconds: 250),
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
                offset: Offset(0, 18 * (1 - _animation.value)),
                child: Opacity(
                  opacity: _animation.value,
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _HomeTopBar(
                          onOpenLibrary: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const LibraryScreen(),
                              ),
                            );
                          },
                          onSignOut: _signOut,
                        ),
                        const SizedBox(height: 14),
                        Text(
                          'Chào người yêu cây!',
                          style:
                              Theme.of(context).textTheme.titleSmall?.copyWith(
                                    color: const Color(0xFF4D5B52),
                                    fontWeight: FontWeight.w600,
                                  ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Bạn muốn tìm hiểu cây gì\nhôm nay?',
                          style:
                              Theme.of(context).textTheme.headlineSmall?.copyWith(
                                    color: _primaryGreen,
                                    fontWeight: FontWeight.w800,
                                    height: 1.15,
                                  ),
                        ),
                        const SizedBox(height: 20),
                        _HeroScanCard(
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
                        const SizedBox(height: 22),
                        FutureBuilder<List<Plant>>(
                          key: ValueKey('home-favorites-$revision'),
                          future: dbService.getFavoritePlants(),
                          builder: (context, snapshot) {
                            final favorites = snapshot.data ?? const <Plant>[];
                            return Row(
                              children: [
                                Expanded(
                                  child: _SummaryTile(
                                    icon: Icons.favorite_rounded,
                                    label: 'Đã lưu',
                                    value: favorites.length.toString(),
                                    tone: const Color(0xFFFFF2F0),
                                    iconColor: const Color(0xFFBE3F39),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: _SummaryTile(
                                    icon: Icons.menu_book_rounded,
                                    label: 'Khám phá',
                                    value: 'Khám phá',
                                    tone: const Color(0xFFEFF8F2),
                                    iconColor: _primaryGreen,
                                    onTap: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) => const LibraryScreen(),
                                        ),
                                      );
                                    },
                                  ),
                                ),
                              ],
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
                        const SizedBox(height: 14),
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
                              return _EmptyPanel(
                                title: 'Chưa có lượt quét nào',
                                description:
                                    'Hãy chụp hoặc tải ảnh lên để bắt đầu nhận diện cây ngay.',
                                actionLabel: 'Nhận diện ngay',
                                onAction: _openCamera,
                              );
                            }

                            return LayoutBuilder(
                              builder: (context, constraints) {
                                final cardWidth =
                                    ((constraints.maxWidth - 14) / 2).clamp(
                                  146.0,
                                  172.0,
                                );
                                final cardHeight = cardWidth + 68;

                                return SizedBox(
                                  height: cardHeight,
                                  child: ListView.separated(
                                    scrollDirection: Axis.horizontal,
                                    itemCount:
                                        records.length > 5 ? 5 : records.length,
                                    separatorBuilder: (_, __) =>
                                        const SizedBox(width: 14),
                                    itemBuilder: (context, index) {
                                      final record = records[index];
                                      final plant = record.plant.copyWith(
                                        imagePath: record.imagePath,
                                      );

                                      return _RecentRecognitionCard(
                                        width: cardWidth,
                                        plant: plant,
                                        confidence: record.confidence,
                                        isFavorite: plant.isFavorite,
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
                            );
                          },
                        ),
                        const SizedBox(height: 28),
                        _SectionHeader(
                          title: 'Đi nhanh',
                          actionLabel: 'Xem thư viện',
                          onAction: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const LibraryScreen(),
                              ),
                            );
                          },
                        ),
                        const SizedBox(height: 14),
                        Row(
                          children: [
                            Expanded(
                              child: _ShortcutTile(
                                icon: Icons.photo_library_outlined,
                                title: 'Thư viện cây',
                                subtitle: 'Xem danh sách cây đã lưu',
                                tone: const Color(0xFFF0F8F2),
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => const LibraryScreen(),
                                    ),
                                  );
                                },
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _ShortcutTile(
                                icon: Icons.favorite_border_rounded,
                                title: 'Cây yêu thích',
                                subtitle: 'Mở bộ sưu tập riêng của bạn',
                                tone: const Color(0xFFFFF8F2),
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => const FavoritesScreen(),
                                    ),
                                  );
                                },
                              ),
                            ),
                          ],
                        ),
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
              color: Color(0x12000000),
              blurRadius: 24,
              offset: Offset(0, -6),
            ),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: _selectedIndex,
          onTap: _onTabTapped,
          selectedItemColor: _primaryGreen,
          unselectedItemColor: const Color(0xFF56635B),
          backgroundColor: Colors.white,
          elevation: 0,
          type: BottomNavigationBarType.fixed,
          selectedLabelStyle: const TextStyle(fontWeight: FontWeight.w700),
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.home_outlined),
              activeIcon: Icon(Icons.home_rounded),
              label: 'Trang chủ',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.menu_book_outlined),
              activeIcon: Icon(Icons.menu_book_rounded),
              label: 'Thư viện',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.history_toggle_off_rounded),
              activeIcon: Icon(Icons.history_rounded),
              label: 'Lịch sử',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.favorite_border_rounded),
              activeIcon: Icon(Icons.favorite_rounded),
              label: 'Yêu thích',
            ),
          ],
        ),
      ),
    );
  }
}

class _HomeTopBar extends StatelessWidget {
  final VoidCallback onOpenLibrary;
  final VoidCallback onSignOut;

  const _HomeTopBar({
    required this.onOpenLibrary,
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
            Icons.spa_outlined,
            color: Colors.white,
            size: 18,
          ),
        ),
        const Spacer(),
        IconButton(
          onPressed: onOpenLibrary,
          icon: const Icon(Icons.search_rounded),
          color: const Color(0xFF214C3C),
          tooltip: 'Mở thư viện',
        ),
        IconButton(
          onPressed: onSignOut,
          icon: const Icon(Icons.logout_rounded),
          color: const Color(0xFF214C3C),
          tooltip: 'Đăng xuất',
        ),
      ],
    );
  }
}

class _HeroScanCard extends StatelessWidget {
  final VoidCallback onScanNow;
  final VoidCallback onUpload;
  final VoidCallback onOpenHistory;

  const _HeroScanCard({
    required this.onScanNow,
    required this.onUpload,
    required this.onOpenHistory,
  });

  @override
  Widget build(BuildContext context) {
    final isCompact = MediaQuery.sizeOf(context).width < 390;

    return Container(
      padding: EdgeInsets.all(isCompact ? 18 : 22),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: const LinearGradient(
          colors: [Color(0xFF255C43), Color(0xFF1C4E3A)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x1A1C4E3A),
            blurRadius: 24,
            offset: Offset(0, 14),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned.fill(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(28),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.white.withValues(alpha: 0.08),
                      Colors.transparent,
                      Colors.black.withValues(alpha: 0.08),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: const _LeafPattern(),
              ),
            ),
          ),
          Column(
            children: [
              SizedBox(height: isCompact ? 24 : 36),
              Container(
                width: double.infinity,
                padding: EdgeInsets.symmetric(
                  horizontal: isCompact ? 14 : 18,
                  vertical: isCompact ? 14 : 18,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: InkWell(
                  onTap: onScanNow,
                  borderRadius: BorderRadius.circular(18),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.camera_alt_rounded,
                        color: Color(0xFF185B43),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        'Nhận diện ngay',
                        style:
                            Theme.of(context).textTheme.titleLarge?.copyWith(
                                  color: const Color(0xFF185B43),
                                  fontWeight: FontWeight.w500,
                                  fontSize: isCompact ? 24 : null,
                                ),
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(height: isCompact ? 12 : 16),
              Row(
                children: [
                  Expanded(
                    child: _HeroActionButton(
                      icon: Icons.image_outlined,
                      label: 'Tải ảnh lên',
                      onTap: onUpload,
                      compact: isCompact,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: _HeroActionButton(
                      icon: Icons.history_rounded,
                      label: 'Xem lịch sử',
                      onTap: onOpenHistory,
                      compact: isCompact,
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

class _HeroActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool compact;

  const _HeroActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withValues(alpha: 0.14),
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: EdgeInsets.symmetric(vertical: compact ? 13 : 16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.18),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: Colors.white, size: compact ? 19 : 22),
              SizedBox(width: compact ? 6 : 8),
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w500,
                        fontSize: compact ? 14 : null,
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
                  color: const Color(0xFF1F2E25),
                  fontWeight: FontWeight.w500,
                ),
          ),
        ),
        TextButton(
          onPressed: onAction,
          child: Text(
            actionLabel,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: const Color(0xFF185B43),
                  fontWeight: FontWeight.w600,
                ),
          ),
        ),
      ],
    );
  }
}

class _SummaryTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color tone;
  final Color iconColor;
  final VoidCallback? onTap;

  const _SummaryTile({
    required this.icon,
    required this.label,
    required this.value,
    required this.tone,
    required this.iconColor,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: tone,
      borderRadius: BorderRadius.circular(22),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(22),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.72),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: iconColor),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: const Color(0xFF536259),
                          ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      value,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: const Color(0xFF1F2E25),
                            fontWeight: FontWeight.w700,
                          ),
                    ),
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

class _RecentRecognitionCard extends StatelessWidget {
  final double width;
  final Plant plant;
  final double confidence;
  final bool isFavorite;
  final VoidCallback onTap;

  const _RecentRecognitionCard({
    this.width = 168,
    required this.plant,
    required this.confidence,
    required this.isFavorite,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final imageHeight = width * 0.95;

    return SizedBox(
      width: width,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(24),
          child: Padding(
            padding: const EdgeInsets.only(bottom: 2),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Stack(
                  children: [
                    Hero(
                      tag: 'plant-${plant.id}',
                      child: PlantImage(
                        plant: plant,
                        height: imageHeight,
                        width: width,
                        borderRadius: BorderRadius.circular(22),
                      ),
                    ),
                    Positioned(
                      right: 10,
                      top: 10,
                      child: Container(
                        width: 34,
                        height: 34,
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          isFavorite
                              ? Icons.favorite_rounded
                              : Icons.favorite_border_rounded,
                          color: isFavorite
                              ? const Color(0xFFD12C2C)
                              : const Color(0xFF7A867F),
                          size: 20,
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
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: const Color(0xFF202D25),
                        fontWeight: FontWeight.w600,
                      ),
                ),
                const SizedBox(height: 2),
                Text(
                  plant.scientificName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: const Color(0xFF707B74),
                        fontStyle: FontStyle.italic,
                        fontSize: 13,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Độ tin cậy ${(confidence.clamp(0.0, 1.0) * 100).toStringAsFixed(0)}%',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: const Color(0xFF7C847F),
                        fontSize: 11.5,
                      ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ShortcutTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color tone;
  final VoidCallback onTap;

  const _ShortcutTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.tone,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: tone,
      borderRadius: BorderRadius.circular(24),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.9),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  icon,
                  color: const Color(0xFF185B43),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                title,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: const Color(0xFF203026),
                      fontWeight: FontWeight.w700,
                    ),
              ),
              const SizedBox(height: 6),
              Text(
                subtitle,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: const Color(0xFF65726B),
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

class _EmptyPanel extends StatelessWidget {
  final String title;
  final String description;
  final String actionLabel;
  final VoidCallback onAction;

  const _EmptyPanel({
    required this.title,
    required this.description,
    required this.actionLabel,
    required this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: const Color(0xFFE5EBE6)),
      ),
      child: Column(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: const Color(0xFFE8F5EC),
              borderRadius: BorderRadius.circular(18),
            ),
            child: const Icon(
              Icons.eco_outlined,
              color: Color(0xFF185B43),
            ),
          ),
          const SizedBox(height: 14),
          Text(
            title,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: const Color(0xFF203026),
                  fontWeight: FontWeight.w700,
                ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            description,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: const Color(0xFF65726B),
                  height: 1.5,
                ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 18),
          ElevatedButton(
            onPressed: onAction,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF185B43),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
              padding: const EdgeInsets.symmetric(
                horizontal: 18,
                vertical: 14,
              ),
            ),
            child: Text(actionLabel),
          ),
        ],
      ),
    );
  }
}

class _LeafPattern extends StatelessWidget {
  const _LeafPattern();

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: const [
        _LeafBlur(
          alignment: Alignment.topLeft,
          rotation: -0.35,
          size: 150,
        ),
        _LeafBlur(
          alignment: Alignment.centerRight,
          rotation: 0.2,
          size: 170,
        ),
        _LeafBlur(
          alignment: Alignment.bottomLeft,
          rotation: 0.65,
          size: 130,
        ),
      ],
    );
  }
}

class _LeafBlur extends StatelessWidget {
  final Alignment alignment;
  final double rotation;
  final double size;

  const _LeafBlur({
    required this.alignment,
    required this.rotation,
    required this.size,
  });

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: alignment,
      child: Transform.rotate(
        angle: rotation,
        child: Container(
          width: size,
          height: size * 0.56,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(size),
            gradient: LinearGradient(
              colors: [
                Colors.white.withValues(alpha: 0.12),
                Colors.white.withValues(alpha: 0.02),
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
