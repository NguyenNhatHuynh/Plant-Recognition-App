import 'dart:io';

import 'package:flutter/material.dart';

import '../../models/plant.dart';
import '../../services/plant_reference_image_service.dart';

class PlantImage extends StatelessWidget {
  final Plant plant;
  final double height;
  final double width;
  final BorderRadius borderRadius;
  final BoxFit fit;

  const PlantImage({
    super.key,
    required this.plant,
    required this.height,
    required this.width,
    required this.borderRadius,
    this.fit = BoxFit.cover,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: borderRadius,
      child: SizedBox(
        height: height,
        width: width,
        child: FutureBuilder<_ResolvedPlantImage>(
          future: _resolvePlantImage(plant),
          builder: (context, snapshot) {
            final resolved = snapshot.data;
            if (resolved == null || resolved.path.isEmpty) {
              return _Placeholder(
                height: height,
                width: width,
                label: plant.commonName,
              );
            }

            if (resolved.isNetwork) {
              return Image.network(
                resolved.path,
                height: height,
                width: width,
                fit: fit,
                errorBuilder: (_, __, ___) => _Placeholder(
                  height: height,
                  width: width,
                  label: plant.commonName,
                ),
              );
            }

            return Image.file(
              File(resolved.path),
              height: height,
              width: width,
              fit: fit,
              errorBuilder: (_, __, ___) => _Placeholder(
                height: height,
                width: width,
                label: plant.commonName,
              ),
            );
          },
        ),
      ),
    );
  }
}

Future<_ResolvedPlantImage> _resolvePlantImage(Plant plant) async {
  final imagePath = plant.imagePath.trim();
  if (imagePath.startsWith('http')) {
    return _ResolvedPlantImage(path: imagePath, isNetwork: true);
  }

  if (imagePath.isNotEmpty) {
    final file = File(imagePath);
    if (await file.exists()) {
      return _ResolvedPlantImage(path: imagePath, isNetwork: false);
    }
  }

  final referenceImage =
      await PlantReferenceImageService.fetchPrimaryImageForPlant(plant);
  if (referenceImage != null && referenceImage.isNotEmpty) {
    return _ResolvedPlantImage(path: referenceImage, isNetwork: true);
  }

  return const _ResolvedPlantImage.empty();
}

class _ResolvedPlantImage {
  final String path;
  final bool isNetwork;

  const _ResolvedPlantImage({
    required this.path,
    required this.isNetwork,
  });

  const _ResolvedPlantImage.empty()
    : path = '',
      isNetwork = false;
}

class _Placeholder extends StatelessWidget {
  final double height;
  final double width;
  final String label;

  const _Placeholder({
    required this.height,
    required this.width,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      width: width,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFE8F5E9), Color(0xFFC8E6C9)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.eco, size: 40, color: Color(0xFF2D6A4F)),
              const SizedBox(height: 8),
              Text(
                label,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Color(0xFF2D6A4F),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
