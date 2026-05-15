// ui/animations/leaf_transition.dart
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

class LeafTransition extends StatelessWidget {
  const LeafTransition({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Lottie.asset('assets/animations/leaf_fall.json',
          width: 100, height: 100),
    );
  }
}
