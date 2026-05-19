import 'package:flutter/material.dart';

import '../../models/plant.dart';
import 'favorite_action_button.dart';
import 'plant_gallery_carousel.dart';
import 'plant_image.dart';

class PlantCard extends StatelessWidget {
  final Plant plant;
  final VoidCallback onTap;
  final bool compact;
  final VoidCallback? onFavoriteTap;
  final bool isFavoriteLoading;
  final bool showGalleryPreview;

  const PlantCard({
    super.key,
    required this.plant,
    required this.onTap,
    this.compact = false,
    this.onFavoriteTap,
    this.isFavoriteLoading = false,
    this.showGalleryPreview = false,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      color: Colors.white,
      shadowColor: Colors.black12,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      margin: const EdgeInsets.only(right: 16, bottom: 16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: SizedBox(
          width: compact ? 150 : double.infinity,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Stack(
                children: [
                  PlantImage(
                    plant: plant,
                    height: compact ? 120 : 140,
                    width: compact ? 150 : double.infinity,
                    borderRadius:
                        const BorderRadius.vertical(top: Radius.circular(20)),
                  ),
                  if (onFavoriteTap != null)
                    Positioned(
                      top: 10,
                      right: 10,
                      child: FavoriteActionButton(
                        isFavorite: plant.isFavorite,
                        isLoading: isFavoriteLoading,
                        onTap: onFavoriteTap,
                      ),
                    ),
                ],
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 10, 12, 11),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      plant.commonName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF1B4332),
                          ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      plant.scientificName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: const Color(0xFF7F5539),
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
