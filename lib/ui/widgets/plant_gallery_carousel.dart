import 'dart:io';

import 'package:flutter/material.dart';

import '../../models/plant.dart';
import '../../services/plant_reference_image_service.dart';
import 'plant_image.dart';

class PlantGalleryCarousel extends StatefulWidget {
  final Plant plant;
  final double height;
  final BorderRadius borderRadius;
  final bool showHint;
  final bool includePrimaryImageFirst;
  final bool showThumbnails;
  final bool showCounter;

  const PlantGalleryCarousel({
    super.key,
    required this.plant,
    required this.height,
    required this.borderRadius,
    this.showHint = true,
    this.includePrimaryImageFirst = true,
    this.showThumbnails = true,
    this.showCounter = true,
  });

  @override
  State<PlantGalleryCarousel> createState() => _PlantGalleryCarouselState();
}

class _PlantGalleryCarouselState extends State<PlantGalleryCarousel> {
  late final PageController _pageController;
  late final Future<List<String>> _futureImages;
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _futureImages = buildGalleryImages(
      widget.plant,
      includePrimaryImageFirst: widget.includePrimaryImageFirst,
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<String>>(
      future: _futureImages,
      builder: (context, snapshot) {
        final images = snapshot.data;
        if (images == null) {
          return _GalleryLoadingSkeleton(
            height: widget.height,
            borderRadius: widget.borderRadius,
          );
        }

        if (images.isEmpty) {
          return PlantImage(
            plant: widget.plant,
            height: widget.height,
            width: double.infinity,
            borderRadius: widget.borderRadius,
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              height: widget.height,
              child: ClipRRect(
                borderRadius: widget.borderRadius,
                child: Stack(
                  children: [
                    PageView.builder(
                      controller: _pageController,
                      itemCount: images.length,
                      onPageChanged: (index) {
                        if (!mounted) {
                          return;
                        }
                        setState(() {
                          _currentIndex = index;
                        });
                      },
                      itemBuilder: (context, index) {
                        final imagePath = images[index];
                        return _GalleryImageFrame(
                          key: ValueKey(imagePath),
                          imagePath: imagePath,
                          label: widget.plant.commonName,
                          heroTag:
                              index == 0 ? 'plant-${widget.plant.id}' : null,
                          borderRadius: widget.borderRadius,
                        );
                      },
                    ),
                    if (images.length > 1)
                      Positioned(
                        left: 14,
                        right: 14,
                        bottom: 14,
                        child: Row(
                          children: [
                            Expanded(
                              child: Wrap(
                                spacing: 6,
                                runSpacing: 6,
                                children: List<Widget>.generate(
                                  images.length,
                                  (index) => AnimatedContainer(
                                    duration: const Duration(milliseconds: 180),
                                    width: index == _currentIndex ? 20 : 7,
                                    height: 7,
                                    decoration: BoxDecoration(
                                      color: index == _currentIndex
                                          ? Colors.white
                                          : Colors.white.withValues(alpha: 0.46),
                                      borderRadius: BorderRadius.circular(999),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            if (widget.showCounter)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.black.withValues(alpha: 0.28),
                                  borderRadius: BorderRadius.circular(999),
                                ),
                                child: Text(
                                  '${_currentIndex + 1}/${images.length}',
                                  style: Theme.of(context)
                                      .textTheme
                                      .labelMedium
                                      ?.copyWith(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w700,
                                      ),
                                ),
                              ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ),
            if (widget.showThumbnails && images.length > 1) ...[
              const SizedBox(height: 12),
              SizedBox(
                height: 58,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: images.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemBuilder: (context, index) {
                    final imagePath = images[index];
                    final isActive = index == _currentIndex;

                    return GestureDetector(
                      onTap: () {
                        _pageController.animateToPage(
                          index,
                          duration: const Duration(milliseconds: 220),
                          curve: Curves.easeOutCubic,
                        );
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        width: 58,
                        height: 58,
                        padding: const EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: isActive
                                ? const Color(0xFF1C5A45)
                                : const Color(0xFFD7E0DA),
                            width: isActive ? 1.6 : 1,
                          ),
                          color: Colors.white,
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(11),
                          child: _GalleryThumb(
                            imagePath: imagePath,
                            label: widget.plant.commonName,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
            if (widget.showHint && images.length > 1) ...[
              const SizedBox(height: 10),
              Text(
                'Vuốt để xem thêm ảnh tham khảo của cây',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: const Color(0xFF69766F),
                      fontWeight: FontWeight.w500,
                    ),
              ),
            ],
          ],
        );
      },
    );
  }
}

class PlantGalleryPreviewStrip extends StatelessWidget {
  final Plant plant;
  final bool includePrimaryImageFirst;
  final int maxImages;

  const PlantGalleryPreviewStrip({
    super.key,
    required this.plant,
    this.includePrimaryImageFirst = true,
    this.maxImages = 4,
  });

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<String>>(
      future: buildGalleryImages(
        plant,
        includePrimaryImageFirst: includePrimaryImageFirst,
      ),
      builder: (context, snapshot) {
        final images = snapshot.data;
        if (images == null || images.length <= 1) {
          return const SizedBox.shrink();
        }

        final previewImages = images.take(maxImages).toList(growable: false);
        return SizedBox(
          height: 52,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: previewImages.length,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (context, index) {
              return Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFD7E0DA)),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(11),
                  child: _GalleryThumb(
                    imagePath: previewImages[index],
                    label: plant.commonName,
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }
}

Future<List<String>> buildGalleryImages(
  Plant plant, {
  required bool includePrimaryImageFirst,
}) async {
  final sources = <String>[];
  final primaryImage = plant.imagePath.trim();

  if (includePrimaryImageFirst && primaryImage.isNotEmpty) {
    sources.add(primaryImage);
  }

  final relatedImages = await PlantReferenceImageService.fetchImagesForPlant(
    plant,
  );
  sources.addAll(relatedImages);

  if (!includePrimaryImageFirst && primaryImage.isNotEmpty) {
    sources.add(primaryImage);
  }

  return sources.toSet().take(4).toList(growable: false);
}

class _GalleryLoadingSkeleton extends StatelessWidget {
  final double height;
  final BorderRadius borderRadius;

  const _GalleryLoadingSkeleton({
    required this.height,
    required this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: borderRadius,
      child: Container(
        height: height,
        width: double.infinity,
        color: const Color(0xFFEAF2EC),
        child: const Center(
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      ),
    );
  }
}

class _GalleryThumb extends StatelessWidget {
  final String imagePath;
  final String label;

  const _GalleryThumb({
    required this.imagePath,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    if (imagePath.startsWith('http')) {
      return Image.network(
        imagePath,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _thumbPlaceholder(),
      );
    }

    return Image.file(
      File(imagePath),
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => _thumbPlaceholder(),
    );
  }

  Widget _thumbPlaceholder() {
    return Container(
      color: const Color(0xFFE7F3EA),
      alignment: Alignment.center,
      child: const Icon(
        Icons.local_florist_rounded,
        color: Color(0xFF2C5B46),
        size: 20,
      ),
    );
  }
}

class _GalleryImageFrame extends StatelessWidget {
  final String imagePath;
  final String label;
  final String? heroTag;
  final BorderRadius borderRadius;

  const _GalleryImageFrame({
    super.key,
    required this.imagePath,
    required this.label,
    required this.borderRadius,
    this.heroTag,
  });

  @override
  Widget build(BuildContext context) {
    final image = imagePath.startsWith('http')
        ? Image.network(
            imagePath,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => _placeholder(),
          )
        : Image.file(
            File(imagePath),
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => _placeholder(),
          );

    final framed = Stack(
      fit: StackFit.expand,
      children: [
        image,
        const DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Color(0x04000000),
                Color(0x10000000),
                Color(0x3A000000),
              ],
            ),
          ),
        ),
      ],
    );

    final clipped = ClipRRect(
      borderRadius: borderRadius,
      child: framed,
    );

    if (heroTag == null) {
      return clipped;
    }
    return Hero(tag: heroTag!, child: clipped);
  }

  Widget _placeholder() {
    return Container(
      color: const Color(0xFFE7F3EA),
      child: Center(
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Color(0xFF2C5B46),
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
