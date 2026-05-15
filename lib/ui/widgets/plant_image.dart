import 'dart:io';

import 'package:flutter/material.dart';

import '../../models/plant.dart';

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
    final imagePath = plant.imagePath.trim();
    final child = imagePath.isEmpty
        ? _Placeholder(height: height, width: width, label: plant.commonName)
        : imagePath.startsWith('http')
            ? Image.network(
                imagePath,
                height: height,
                width: width,
                fit: fit,
                errorBuilder: (_, __, ___) =>
                    _Placeholder(height: height, width: width, label: plant.commonName),
              )
            : Image.file(
                File(imagePath),
                height: height,
                width: width,
                fit: fit,
                errorBuilder: (_, __, ___) =>
                    _Placeholder(height: height, width: width, label: plant.commonName),
              );

    return ClipRRect(
      borderRadius: borderRadius,
      child: child,
    );
  }
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
