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

  static Route<void> route(Plant plant) {
    return PageRouteBuilder<void>(
      transitionDuration: const Duration(milliseconds: 320),
      reverseTransitionDuration: const Duration(milliseconds: 240),
      pageBuilder: (_, __, ___) => PlantDetailScreen(plant: plant),
      transitionsBuilder: (_, animation, __, child) {
        final fade = CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutCubic,
        );
        final slide = Tween<Offset>(
          begin: const Offset(0, 0.06),
          end: Offset.zero,
        ).animate(
          CurvedAnimation(
            parent: animation,
            curve: Curves.easeOutCubic,
          ),
        );

        return FadeTransition(
          opacity: fade,
          child: SlideTransition(
            position: slide,
            child: child,
          ),
        );
      },
    );
  }

  @override
  State<PlantDetailScreen> createState() => _PlantDetailScreenState();
}

class _PlantDetailScreenState extends State<PlantDetailScreen> {
  static const _primaryGreen = Color(0xFF1C5A45);
  static const _pageBackground = Color(0xFFF5F7F3);
  static const _cardBorder = Color(0xFFE3E9E2);
  static const _sectionTitle = Color(0xFF203029);
  static const _bodyText = Color(0xFF4E5D55);

  late Plant _plant;
  bool _isSavingFavorite = false;

  @override
  void initState() {
    super.initState();
    _plant = widget.plant;
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _pageBackground,
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _DetailTopBar(
                isFavorite: _plant.isFavorite,
                isSavingFavorite: _isSavingFavorite,
                onBack: () => Navigator.pop(context),
                onToggleFavorite: _toggleFavorite,
              ),
              const SizedBox(height: 14),
              _RevealOnOpen(
                index: 0,
                child: _PlantHeroSection(plant: _plant),
              ),
              const SizedBox(height: 18),
              _RevealOnOpen(
                index: 1,
                child: _PlantSummaryCard(plant: _plant),
              ),
              const SizedBox(height: 16),
              _RevealOnOpen(
                index: 2,
                child: _DetailInfoCard(
                  icon: Icons.apartment_rounded,
                  title: 'Họ thực vật',
                  child: _DetailParagraph(text: _fallbackText(_plant.family)),
                ),
              ),
              const SizedBox(height: 14),
              _RevealOnOpen(
                index: 3,
                child: _DetailInfoCard(
                  icon: Icons.park_outlined,
                  title: 'Môi trường sống',
                  child: _DetailParagraph(text: _fallbackText(_plant.habitat)),
                ),
              ),
              const SizedBox(height: 14),
              _RevealOnOpen(
                index: 4,
                child: _DetailInfoCard(
                  icon: Icons.auto_awesome_outlined,
                  title: 'Ứng dụng',
                  child: _TagWrap(
                    items: _plant.uses,
                    emptyText: 'Chưa có dữ liệu ứng dụng.',
                  ),
                ),
              ),
              const SizedBox(height: 14),
              _RevealOnOpen(
                index: 5,
                child: _DetailInfoCard(
                  icon: Icons.local_florist_outlined,
                  title: 'Tên gọi khác',
                  child: _TagWrap(
                    items: _plant.aliases,
                    emptyText: 'Chưa có tên gọi khác.',
                  ),
                ),
              ),
              const SizedBox(height: 14),
              _RevealOnOpen(
                index: 6,
                child: _DetailInfoCard(
                  icon: Icons.description_outlined,
                  title: 'Mô tả',
                  child:
                      _DetailParagraph(text: _fallbackText(_plant.description)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _fallbackText(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) {
      return 'Chưa có dữ liệu.';
    }
    return trimmed;
  }
}

class _RevealOnOpen extends StatelessWidget {
  final int index;
  final Widget child;

  const _RevealOnOpen({
    required this.index,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final routeAnimation = ModalRoute.of(context)?.animation;
    if (routeAnimation == null) {
      return child;
    }

    final start = (index * 0.08).clamp(0, 0.45).toDouble();
    final curved = CurvedAnimation(
      parent: routeAnimation,
      curve: Interval(start, 1, curve: Curves.easeOutCubic),
    );

    return AnimatedBuilder(
      animation: curved,
      child: child,
      builder: (context, child) {
        final value = curved.value;
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, (1 - value) * 22),
            child: child,
          ),
        );
      },
    );
  }
}

class _DetailTopBar extends StatelessWidget {
  final bool isFavorite;
  final bool isSavingFavorite;
  final VoidCallback onBack;
  final VoidCallback onToggleFavorite;

  const _DetailTopBar({
    required this.isFavorite,
    required this.isSavingFavorite,
    required this.onBack,
    required this.onToggleFavorite,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _CircleIconButton(
          icon: Icons.arrow_back_rounded,
          onTap: onBack,
        ),
        const Spacer(),
        _CircleIconButton(
          icon: isFavorite ? Icons.favorite_rounded : Icons.favorite_border,
          iconColor:
              isFavorite ? const Color(0xFFD22D2D) : const Color(0xFF506057),
          onTap: isSavingFavorite ? null : onToggleFavorite,
          isLoading: isSavingFavorite,
        ),
      ],
    );
  }
}

class _PlantHeroSection extends StatelessWidget {
  final Plant plant;

  const _PlantHeroSection({required this.plant});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        boxShadow: const [
          BoxShadow(
            color: Color(0x16000000),
            blurRadius: 28,
            offset: Offset(0, 14),
          ),
        ],
      ),
      child: Hero(
        tag: 'plant-${plant.id}',
        child: Stack(
          children: [
            PlantImage(
              plant: plant,
              height: 290,
              width: double.infinity,
              borderRadius: BorderRadius.circular(28),
            ),
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(28),
                  gradient: const LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Color(0x05000000),
                      Color(0x14000000),
                      Color(0x8A102219),
                    ],
                    stops: [0.0, 0.45, 1.0],
                  ),
                ),
              ),
            ),
            Positioned(
              left: 18,
              right: 18,
              bottom: 18,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    plant.commonName,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 24,
                          height: 1.12,
                          shadows: const [
                            Shadow(
                              color: Color(0x50000000),
                              blurRadius: 12,
                              offset: Offset(0, 2),
                            ),
                          ],
                        ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    plant.scientificName.isEmpty
                        ? 'Chưa có tên khoa học'
                        : plant.scientificName,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: Colors.white.withValues(alpha: 0.92),
                          fontStyle: FontStyle.italic,
                          fontWeight: FontWeight.w500,
                          shadows: const [
                            Shadow(
                              color: Color(0x50000000),
                              blurRadius: 10,
                              offset: Offset(0, 2),
                            ),
                          ],
                        ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PlantSummaryCard extends StatelessWidget {
  final Plant plant;

  const _PlantSummaryCard({required this.plant});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: _PlantDetailScreenState._cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Thông tin nhanh',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: _PlantDetailScreenState._sectionTitle,
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _MetaPill(
                icon: Icons.eco_outlined,
                label: plant.family.isEmpty ? 'Chưa rõ họ thực vật' : plant.family,
              ),
              _MetaPill(
                icon: Icons.offline_bolt_rounded,
                label: plant.isOfflineAvailable
                    ? 'Đã lưu ngoại tuyến'
                    : 'Chưa lưu ngoại tuyến',
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _DetailInfoCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final Widget child;

  const _DetailInfoCard({
    required this.icon,
    required this.title,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: _PlantDetailScreenState._cardBorder),
        boxShadow: const [
          BoxShadow(
            color: Color(0x08000000),
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: const Color(0xFFE9F4EC),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  size: 18,
                  color: _PlantDetailScreenState._primaryGreen,
                ),
              ),
              const SizedBox(width: 10),
              Text(
                title,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: _PlantDetailScreenState._sectionTitle,
                      fontWeight: FontWeight.w700,
                      fontSize: 15.5,
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

class _DetailParagraph extends StatelessWidget {
  final String text;

  const _DetailParagraph({required this.text});

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
            color: _PlantDetailScreenState._bodyText,
            fontSize: 14.5,
            height: 1.55,
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
      return _DetailParagraph(text: emptyText);
    }

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: items
          .map(
            (item) => Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
              decoration: BoxDecoration(
                color: const Color(0xFFEAF5ED),
                borderRadius: BorderRadius.circular(999),
                border: Border.all(color: const Color(0xFFD4E8D9)),
              ),
              child: Text(
                item,
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: const Color(0xFF254634),
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
              ),
            ),
          )
          .toList(growable: false),
    );
  }
}

class _MetaPill extends StatelessWidget {
  final IconData icon;
  final String label;

  const _MetaPill({
    required this.icon,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFF0F6F1),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 16,
            color: _PlantDetailScreenState._primaryGreen,
          ),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              label,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: const Color(0xFF345344),
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CircleIconButton extends StatelessWidget {
  final IconData icon;
  final Color? iconColor;
  final VoidCallback? onTap;
  final bool isLoading;

  const _CircleIconButton({
    required this.icon,
    required this.onTap,
    this.iconColor,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          width: 46,
          height: 46,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE1E8E2)),
          ),
          child: Center(
            child: isLoading
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Icon(
                    icon,
                    color: iconColor ?? const Color(0xFF23342B),
                    size: 22,
                  ),
          ),
        ),
      ),
    );
  }
}
