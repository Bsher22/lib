// ============================================================================
// File: lib/responsive_system/adaptive_layout.dart (ENHANCED)
// ============================================================================
import 'package:flutter/material.dart';
import 'device_type.dart';
import 'device_detector.dart';

/// Enhanced adaptive layout with smooth transitions (per specification)
typedef AdaptiveLayoutBuilder = Widget Function(
  DeviceType deviceType, 
  bool isLandscape,
);

class AdaptiveLayout extends StatelessWidget {
  final AdaptiveLayoutBuilder? builder;
  final Widget? mobile;
  final Widget? tablet;
  final Widget? desktop;
  final Widget? largeDesktop;
  final Widget? fallback;
  final Duration animationDuration;
  
  const AdaptiveLayout({
    super.key,
    this.builder,
    this.mobile,
    this.tablet,
    this.desktop,
    this.largeDesktop,
    this.fallback,
    this.animationDuration = const Duration(milliseconds: 300),
  }) : assert(
    builder != null || fallback != null,
    'Either builder or fallback must be provided',
  );
  
  @override
  Widget build(BuildContext context) {
    return OrientationBuilder(
      builder: (context, orientation) {
        return LayoutBuilder(
          builder: (context, constraints) {
            final deviceType = DeviceDetector.getDeviceType(context);
            final isLandscape = DeviceDetector.isLandscape(context);
            
            Widget child;
            
            if (builder != null) {
              child = builder!(deviceType, isLandscape);
            } else {
              // Use widget-based approach (keeping your existing pattern)
              switch (deviceType) {
                case DeviceType.mobile:
                  child = mobile ?? fallback!;
                  break;
                case DeviceType.tablet:
                  child = tablet ?? mobile ?? fallback!;
                  break;
                case DeviceType.desktop:
                  // Check for large desktop
                  if (MediaQuery.of(context).size.width >= 1440) {
                    child = largeDesktop ?? desktop ?? tablet ?? mobile ?? fallback!;
                  } else {
                    child = desktop ?? tablet ?? mobile ?? fallback!;
                  }
                  break;
              }
            }
            
            // Smooth transitions (per specification: 300ms)
            return AnimatedSwitcher(
              duration: animationDuration,
              transitionBuilder: (child, animation) {
                return FadeTransition(
                  opacity: animation,
                  child: ScaleTransition(
                    scale: Tween<double>(begin: 0.95, end: 1.0).animate(
                      CurvedAnimation(parent: animation, curve: Curves.easeOutCubic),
                    ),
                    child: child,
                  ),
                );
              },
              child: Container(
                key: ValueKey('${deviceType.toString()}_${isLandscape}'),
                child: child,
              ),
            );
          },
        );
      },
    );
  }
}

// Keep your existing adaptive widgets but update them to use new device detection
class AdaptiveBuilder extends StatelessWidget {
  final Widget Function(BuildContext context, DeviceType deviceType) builder;

  const AdaptiveBuilder({
    super.key,
    required this.builder,
  });

  @override
  Widget build(BuildContext context) {
    return builder(context, DeviceDetector.getDeviceType(context));
  }
}