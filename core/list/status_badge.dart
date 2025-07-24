import 'package:flutter/material.dart';

/// A unified badge system for status indicators
///
/// Provides consistent styling for status badges throughout the app
class StatusBadge extends StatelessWidget {
  /// The text to display in the badge
  final String text;
  
  /// The primary color of the badge
  final Color color;
  
  /// Optional icon to display before text
  final IconData? icon;
  
  /// Size variant of the badge
  final StatusBadgeSize size;
  
  /// Shape of the badge
  final StatusBadgeShape shape;
  
  /// Optional border for the badge
  final bool withBorder;
  
  /// Whether to use bold text
  final bool bold;
  
  const StatusBadge({
    Key? key,
    required this.text,
    required this.color,
    this.icon,
    this.size = StatusBadgeSize.medium,
    this.shape = StatusBadgeShape.rounded,
    this.withBorder = true,
    this.bold = true,
  }) : super(key: key);
  
  /// Factory for success status (green)
  factory StatusBadge.success({
    required String text,
    IconData? icon,
    StatusBadgeSize size = StatusBadgeSize.medium,
    StatusBadgeShape shape = StatusBadgeShape.rounded,
  }) {
    return StatusBadge(
      text: text,
      color: Colors.green,
      icon: icon ?? Icons.check_circle,
      size: size,
      shape: shape,
    );
  }
  
  /// Factory for warning status (yellow/orange)
  factory StatusBadge.warning({
    required String text,
    IconData? icon,
    StatusBadgeSize size = StatusBadgeSize.medium,
    StatusBadgeShape shape = StatusBadgeShape.rounded,
  }) {
    return StatusBadge(
      text: text,
      color: Colors.orange,
      icon: icon ?? Icons.warning,
      size: size,
      shape: shape,
    );
  }
  
  /// Factory for error/critical status (red)
  factory StatusBadge.error({
    required String text,
    IconData? icon,
    StatusBadgeSize size = StatusBadgeSize.medium,
    StatusBadgeShape shape = StatusBadgeShape.rounded,
  }) {
    return StatusBadge(
      text: text,
      color: Colors.red,
      icon: icon ?? Icons.error,
      size: size,
      shape: shape,
    );
  }
  
  /// Factory for info status (blue)
  factory StatusBadge.info({
    required String text,
    IconData? icon,
    StatusBadgeSize size = StatusBadgeSize.medium,
    StatusBadgeShape shape = StatusBadgeShape.rounded,
  }) {
    return StatusBadge(
      text: text,
      color: Colors.blue,
      icon: icon ?? Icons.info,
      size: size,
      shape: shape,
    );
  }
  
  /// Factory for neutral/disabled status (grey)
  factory StatusBadge.neutral({
    required String text,
    IconData? icon,
    StatusBadgeSize size = StatusBadgeSize.medium,
    StatusBadgeShape shape = StatusBadgeShape.rounded,
  }) {
    return StatusBadge(
      text: text,
      color: Colors.grey,
      icon: icon,
      size: size,
      shape: shape,
    );
  }
  
  /// Factory for creating common status badges
  /// 
  /// Valid statuses: 'active', 'inactive', 'pending', 'completed', 'error'
  factory StatusBadge.fromStatus(String status, {
    StatusBadgeSize size = StatusBadgeSize.medium,
    StatusBadgeShape shape = StatusBadgeShape.rounded,
  }) {
    final statusLower = status.toLowerCase();
    
    switch (statusLower) {
      case 'active':
        return StatusBadge.success(
          text: 'Active',
          icon: Icons.check_circle,
          size: size,
          shape: shape,
        );
      case 'inactive':
        return StatusBadge.neutral(
          text: 'Inactive',
          icon: Icons.block,
          size: size,
          shape: shape,
        );
      case 'pending':
        return StatusBadge.warning(
          text: 'Pending',
          icon: Icons.hourglass_empty,
          size: size,
          shape: shape,
        );
      case 'completed':
        return StatusBadge.success(
          text: 'Completed',
          icon: Icons.done_all,
          size: size,
          shape: shape,
        );
      case 'error':
      case 'failed':
        return StatusBadge.error(
          text: 'Error',
          icon: Icons.error_outline,
          size: size,
          shape: shape,
        );
      default:
        // For custom statuses, return a blue info badge
        return StatusBadge.info(
          text: status,
          size: size,
          shape: shape,
        );
    }
  }
  
  @override
  Widget build(BuildContext context) {
    // Calculate padding based on size
    final EdgeInsetsGeometry effectivePadding = _getPaddingForSize(size);
    
    // Calculate border radius based on shape
    final BorderRadius effectiveBorderRadius = _getBorderRadiusForShape(shape);
    
    // Calculate text size based on badge size
    final double fontSize = _getFontSizeForSize(size);
    
    // Calculate icon size based on badge size
    final double iconSize = _getIconSizeForSize(size);
    
    return Container(
      padding: effectivePadding,
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: effectiveBorderRadius,
        border: withBorder ? Border.all(color: color.withOpacity(0.5)) : null,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(
              icon,
              size: iconSize,
              color: color,
            ),
            SizedBox(width: size == StatusBadgeSize.small ? 4 : 6),
          ],
          Text(
            text,
            style: TextStyle(
              fontSize: fontSize,
              fontWeight: bold ? FontWeight.bold : FontWeight.normal,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
  
  EdgeInsetsGeometry _getPaddingForSize(StatusBadgeSize size) {
    switch (size) {
      case StatusBadgeSize.small:
        return const EdgeInsets.symmetric(horizontal: 6, vertical: 2);
      case StatusBadgeSize.medium:
        return const EdgeInsets.symmetric(horizontal: 8, vertical: 4);
      case StatusBadgeSize.large:
        return const EdgeInsets.symmetric(horizontal: 12, vertical: 6);
    }
  }
  
  BorderRadius _getBorderRadiusForShape(StatusBadgeShape shape) {
    switch (shape) {
      case StatusBadgeShape.rounded:
        return BorderRadius.circular(16);
      case StatusBadgeShape.pill:
        return BorderRadius.circular(50);
      case StatusBadgeShape.square:
        return BorderRadius.circular(4);
    }
  }
  
  double _getFontSizeForSize(StatusBadgeSize size) {
    switch (size) {
      case StatusBadgeSize.small:
        return 10;
      case StatusBadgeSize.medium:
        return 12;
      case StatusBadgeSize.large:
        return 14;
    }
  }
  
  double _getIconSizeForSize(StatusBadgeSize size) {
    switch (size) {
      case StatusBadgeSize.small:
        return 10;
      case StatusBadgeSize.medium:
        return 12;
      case StatusBadgeSize.large:
        return 16;
    }
  }
}

/// Size variants for StatusBadge
enum StatusBadgeSize {
  small,
  medium,
  large,
}

/// Shape variants for StatusBadge
enum StatusBadgeShape {
  rounded,
  pill,
  square,
}