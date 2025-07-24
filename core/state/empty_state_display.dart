// lib/widgets/common/state/empty_state_display.dart
import 'package:flutter/material.dart';

/// A reusable empty state widget that displays a message when no data is available
/// with optional action buttons and customizable appearance.
class EmptyStateDisplay extends StatelessWidget {
  /// The title message to display
  final String title;
  
  /// Optional description text
  final String? description;
  
  /// Icon to display above the message
  final IconData icon;
  
  /// Color of the icon
  final Color? iconColor;
  
  /// Size of the icon
  final double iconSize;
  
  /// Primary action button text
  final String? primaryActionLabel;
  
  /// Primary action callback
  final VoidCallback? onPrimaryAction;
  
  /// Secondary action button text
  final String? secondaryActionLabel;
  
  /// Secondary action callback
  final VoidCallback? onSecondaryAction;
  
  /// Background color of primary action button
  final Color? primaryActionColor;
  
  /// Whether to show the empty state in a card
  final bool showCard;
  
  /// Style for the title text
  final TextStyle? titleStyle;
  
  /// Style for the description text
  final TextStyle? descriptionStyle;
  
  /// Custom widget to display instead of the icon
  final Widget? customImage;
  
  /// Whether to animate the icon/image
  final bool animate;
  
  /// Background color of the card or container
  final Color? backgroundColor;

  const EmptyStateDisplay({
    Key? key,
    required this.title,
    this.description,
    this.icon = Icons.inbox,
    this.iconColor,
    this.iconSize = 72.0,
    this.primaryActionLabel,
    this.onPrimaryAction,
    this.secondaryActionLabel,
    this.onSecondaryAction,
    this.primaryActionColor,
    this.showCard = false,
    this.titleStyle,
    this.descriptionStyle,
    this.customImage,
    this.animate = false,
    this.backgroundColor,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final defaultIconColor = iconColor ?? Colors.blueGrey[300];
    
    Widget iconWidget;
    if (customImage != null) {
      iconWidget = customImage!;
    } else {
      iconWidget = Icon(
        icon,
        size: iconSize,
        color: defaultIconColor,
      );
    }
    
    // Add animation if requested
    if (animate) {
      iconWidget = _buildAnimatedIcon(iconWidget);
    }
    
    final emptyStateContent = Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        iconWidget,
        const SizedBox(height: 24),
        Text(
          title,
          style: titleStyle ?? 
            TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.blueGrey[800],
            ),
          textAlign: TextAlign.center,
        ),
        if (description != null) ...[
          const SizedBox(height: 12),
          Text(
            description!,
            style: descriptionStyle ?? 
              TextStyle(
                fontSize: 16,
                color: Colors.blueGrey[600],
              ),
            textAlign: TextAlign.center,
          ),
        ],
        if (onPrimaryAction != null && primaryActionLabel != null) ...[
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: onPrimaryAction,
            icon: _getPrimaryActionIcon(),
            label: Text(primaryActionLabel!),
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryActionColor ?? Colors.cyanAccent,
              foregroundColor: Colors.black87,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
        if (onSecondaryAction != null && secondaryActionLabel != null) ...[
          const SizedBox(height: 12),
          TextButton(
            onPressed: onSecondaryAction,
            child: Text(secondaryActionLabel!),
          ),
        ],
      ],
    );

    if (showCard) {
      return Card(
        elevation: 1,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        margin: const EdgeInsets.all(16),
        color: backgroundColor,
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: emptyStateContent,
        ),
      );
    } else {
      return Container(
        color: backgroundColor,
        padding: const EdgeInsets.all(24),
        child: Center(
          child: emptyStateContent,
        ),
      );
    }
  }
  
  /// Returns the appropriate icon for the primary action based on the label
  Widget _getPrimaryActionIcon() {
    if (primaryActionLabel == null) {
      return const Icon(Icons.add);
    }
    
    final label = primaryActionLabel!.toLowerCase();
    
    if (label.contains('add') || label.contains('create') || label.contains('new')) {
      return const Icon(Icons.add);
    } else if (label.contains('refresh') || label.contains('retry') || label.contains('again')) {
      return const Icon(Icons.refresh);
    } else if (label.contains('search') || label.contains('find')) {
      return const Icon(Icons.search);
    } else if (label.contains('import') || label.contains('upload')) {
      return const Icon(Icons.upload);
    } else if (label.contains('download')) {
      return const Icon(Icons.download);
    } else {
      return const Icon(Icons.arrow_forward);
    }
  }
  
  /// Wraps the icon widget with a simple animation
  Widget _buildAnimatedIcon(Widget iconWidget) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0.8, end: 1.0),
      duration: const Duration(seconds: 2),
      curve: Curves.easeInOut,
      builder: (context, value, child) {
        return Transform.scale(
          scale: value,
          child: child,
        );
      },
      child: iconWidget,
    );
  }
  
  /// Creates an empty list state display with predefined settings
  static Widget emptyList({
    String title = 'No Items',
    String? description = 'There are no items to display right now.',
    IconData icon = Icons.list_alt,
    String? actionLabel,
    VoidCallback? onAction,
    bool showCard = false,
  }) {
    return EmptyStateDisplay(
      title: title,
      description: description,
      icon: icon,
      primaryActionLabel: actionLabel,
      onPrimaryAction: onAction,
      showCard: showCard,
    );
  }
  
  /// Creates an empty search results state display with predefined settings
  static Widget noSearchResults({
    String title = 'No Results Found',
    String? description = 'Your search did not match any items. Try different keywords or filters.',
    String? actionLabel = 'Clear Search',
    VoidCallback? onAction,
    bool showCard = false,
  }) {
    return EmptyStateDisplay(
      title: title,
      description: description,
      icon: Icons.search_off,
      primaryActionLabel: actionLabel,
      onPrimaryAction: onAction,
      showCard: showCard,
    );
  }
  
  /// Creates a "no data yet" state display with predefined settings
  static Widget noDataYet({
    String title = 'No Data Yet',
    String? description = 'Start adding data to see it here.',
    String? actionLabel = 'Add New',
    VoidCallback? onAction,
    bool showCard = false,
  }) {
    return EmptyStateDisplay(
      title: title,
      description: description,
      icon: Icons.add_chart,
      primaryActionLabel: actionLabel,
      onPrimaryAction: onAction,
      showCard: showCard,
    );
  }
}