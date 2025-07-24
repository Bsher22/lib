import 'package:flutter/material.dart';

/// A widget that displays a performance level as a badge.
/// 
/// Used to visually indicate performance levels across the app with consistent styling.
class PerformanceLevelBadge extends StatelessWidget {
  /// The performance level text to display
  final String level;
  
  /// The color of the badge background (with reduced opacity)
  /// and the text (with full opacity)
  final Color color;
  
  /// Optional custom text style to override default
  final TextStyle? textStyle;
  
  /// Optional size modifier (defaults to medium)
  final PerformanceBadgeSize size;

  const PerformanceLevelBadge({
    Key? key,
    required this.level,
    required this.color,
    this.textStyle,
    this.size = PerformanceBadgeSize.medium,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final paddingSize = _getPaddingForSize(size);
    final fontSize = _getFontSizeForSize(size);
    
    return Container(
      padding: EdgeInsets.symmetric(horizontal: paddingSize, vertical: paddingSize / 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(paddingSize),
      ),
      child: Text(
        level,
        style: textStyle ?? TextStyle(
          color: color,
          fontWeight: FontWeight.bold,
          fontSize: fontSize,
        ),
      ),
    );
  }
  
  double _getPaddingForSize(PerformanceBadgeSize size) {
    switch (size) {
      case PerformanceBadgeSize.small:
        return 6.0;
      case PerformanceBadgeSize.medium:
        return 8.0;
      case PerformanceBadgeSize.large:
        return 12.0;
    }
  }
  
  double _getFontSizeForSize(PerformanceBadgeSize size) {
    switch (size) {
      case PerformanceBadgeSize.small:
        return 10.0;
      case PerformanceBadgeSize.medium:
        return 12.0;
      case PerformanceBadgeSize.large:
        return 14.0;
    }
  }
}

/// Size options for the performance badge
enum PerformanceBadgeSize {
  small,
  medium,
  large,
}
