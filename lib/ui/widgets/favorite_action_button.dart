import 'package:flutter/material.dart';

class FavoriteActionButton extends StatelessWidget {
  final bool isFavorite;
  final bool isLoading;
  final VoidCallback? onTap;
  final double size;
  final EdgeInsets padding;

  const FavoriteActionButton({
    super.key,
    required this.isFavorite,
    required this.onTap,
    this.isLoading = false,
    this.size = 20,
    this.padding = const EdgeInsets.all(8),
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      shape: const CircleBorder(),
      elevation: 1,
      child: InkWell(
        onTap: isLoading ? null : onTap,
        customBorder: const CircleBorder(),
        child: Padding(
          padding: padding,
          child: isLoading
              ? SizedBox(
                  width: size,
                  height: size,
                  child: const CircularProgressIndicator(
                    strokeWidth: 2,
                  ),
                )
              : Icon(
                  isFavorite
                      ? Icons.favorite_rounded
                      : Icons.favorite_border_rounded,
                  color: isFavorite
                      ? const Color(0xFFD12727)
                      : const Color(0xFF8B928E),
                  size: size,
                ),
        ),
      ),
    );
  }
}
