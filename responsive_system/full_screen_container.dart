// ============================================================================
// File: lib/responsive_system/full_screen_container.dart (NEW)
// ============================================================================
import 'package:flutter/material.dart';

/// Container that ensures full viewport coverage with no white space
class FullScreenContainer extends StatelessWidget {
  final Widget child;
  final Gradient? gradient;
  final Color? backgroundColor;
  final DecorationImage? backgroundImage;
  
  const FullScreenContainer({
    super.key,
    required this.child,
    this.gradient,
    this.backgroundColor,
    this.backgroundImage,
  });
  
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: BoxDecoration(
        gradient: gradient,
        color: backgroundColor ?? Colors.white,
        image: backgroundImage,
      ),
      child: child,
    );
  }
}
