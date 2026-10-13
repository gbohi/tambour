import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:tambour_commun/core/theme.dart';

class LoadingWidget extends StatelessWidget {
  final String? message;
  final double size;

  const LoadingWidget({super.key, this.message, this.size = 48});

  @override
  Widget build(BuildContext context) {
    return Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
      Container(
        width: size, height: size,
        decoration: BoxDecoration(color: TamBourColors.primaryLight, shape: BoxShape.circle),
        child: Padding(
          padding: EdgeInsets.all(size * 0.2),
          child: CircularProgressIndicator(color: TamBourColors.primary, strokeWidth: 3))),
      if (message != null) ...[
        const SizedBox(height: 16),
        Text(message!, style: const TextStyle(fontFamily: 'Outfit', fontSize: 14, color: TamBourColors.textSecondary)),
      ],
    ]));
  }
}

class SkeletonBox extends StatelessWidget {
  final double width;
  final double height;
  final double borderRadius;

  const SkeletonBox({super.key, required this.width, required this.height, this.borderRadius = 8});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width, height: height,
      decoration: BoxDecoration(color: TamBourColors.border, borderRadius: BorderRadius.circular(borderRadius)),
    ).animate(onPlay: (c) => c.repeat()).shimmer(duration: 1200.ms, color: Colors.white.withOpacity(0.6));
  }
}
