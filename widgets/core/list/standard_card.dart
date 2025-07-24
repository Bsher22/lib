import 'package:flutter/material.dart';

/// A reusable card widget with consistent styling
///
/// Provides standardized elevation, padding, and corner radius
/// with customizable content and appearance options.
class StandardCard extends StatelessWidget {
  /// The card's content
  final Widget child;

  /// Optional card title
  final String? title;

  /// Optional card subtitle
  final String? subtitle;

  /// Card elevation (shadow depth)
  final double elevation;

  /// Corner radius for the card
  final double borderRadius;

  /// Padding inside the card
  final EdgeInsetsGeometry padding;

  /// Card background color
  final Color? backgroundColor;

  /// Optional border for the card
  final BorderSide? border;

  /// Optional icon to display in the header
  final IconData? headerIcon;

  /// Color for the header icon
  final Color? headerIconColor;

  /// Whether to show a divider between header and content
  final bool showHeaderDivider;

  /// Optional callback when card is tapped
  final VoidCallback? onTap;

  /// Optional color when card is tapped (ripple effect)
  final Color? splashColor;

  /// Optional margin around the card
  final EdgeInsetsGeometry? margin;

  const StandardCard({
    Key? key,
    required this.child,
    this.title,
    this.subtitle,
    this.elevation = 2,
    this.borderRadius = 12,
    this.padding = const EdgeInsets.all(16),
    this.backgroundColor,
    this.border,
    this.headerIcon,
    this.headerIconColor,
    this.showHeaderDivider = true,
    this.onTap,
    this.splashColor,
    this.margin,
  }) : super(key: key);

  /// Factory constructor for a card with only a title
  factory StandardCard.titled({
    required String title,
    required Widget child,
    String? subtitle,
    IconData? icon,
    Color? iconColor,
    VoidCallback? onTap,
    double elevation = 2,
    EdgeInsetsGeometry? margin,
  }) {
    return StandardCard(
      title: title,
      subtitle: subtitle,
      headerIcon: icon,
      headerIconColor: iconColor,
      child: child,
      elevation: elevation,
      onTap: onTap,
      margin: margin,
    );
  }

  /// Factory constructor for a card with a colored border
  factory StandardCard.bordered({
    required Widget child,
    String? title,
    Color borderColor = Colors.blue,
    double borderWidth = 1.0,
    VoidCallback? onTap,
    EdgeInsetsGeometry? margin,
  }) {
    return StandardCard(
      title: title,
      child: child,
      border: BorderSide(color: borderColor, width: borderWidth),
      onTap: onTap,
      margin: margin,
    );
  }

  /// Factory constructor for a card with a colored background
  factory StandardCard.colored({
    required Widget child,
    String? title,
    required Color backgroundColor,
    Color textColor = Colors.black,
    VoidCallback? onTap,
    EdgeInsetsGeometry? margin,
  }) {
    return StandardCard(
      title: title,
      child: child,
      backgroundColor: backgroundColor,
      headerIconColor: textColor,
      onTap: onTap,
      margin: margin,
    );
  }

  /// Factory constructor for a card with no padding or elevation (flat)
  factory StandardCard.flat({
    required Widget child,
    String? title,
    VoidCallback? onTap,
    Color? backgroundColor,
    EdgeInsetsGeometry? margin,
  }) {
    return StandardCard(
      title: title,
      child: child,
      elevation: 0,
      padding: EdgeInsets.zero,
      backgroundColor: backgroundColor,
      onTap: onTap,
      margin: margin,
    );
  }

  @override
  Widget build(BuildContext context) {
    final hasHeader = title != null || headerIcon != null;

    final card = Card(
      margin: margin ?? EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(borderRadius),
        side: border ?? BorderSide.none,
      ),
      color: backgroundColor,
      elevation: elevation,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(borderRadius),
        splashColor: splashColor,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Optional header
            if (hasHeader)
              Padding(
                padding: padding is EdgeInsets
                    ? EdgeInsets.only(
                        left: (padding as EdgeInsets).left,
                        right: (padding as EdgeInsets).right,
                        top: (padding as EdgeInsets).top,
                        bottom: showHeaderDivider
                            ? 8
                            : (padding as EdgeInsets).bottom,
                      )
                    : const EdgeInsets.all(16), // Fallback padding
                child: _buildHeader(context),
              ),

            // Optional divider after header
            if (hasHeader && showHeaderDivider) const Divider(height: 1),

            // Main content with padding
            if (!hasHeader || showHeaderDivider)
              Padding(
                padding: padding,
                child: child,
              )
            else
              child,
          ],
        ),
      ),
    );

    return card;
  }

  Widget _buildHeader(BuildContext context) {
    return Row(
      children: [
        // Optional header icon
        if (headerIcon != null) ...[
          Icon(
            headerIcon,
            color: headerIconColor ?? Theme.of(context).primaryColor,
            size: 24,
          ),
          const SizedBox(width: 12),
        ],

        // Title and optional subtitle
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (title != null)
                Text(
                  title!,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.blueGrey[800],
                  ),
                ),
              if (subtitle != null) ...[
                const SizedBox(height: 4),
                Text(
                  subtitle!,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.blueGrey[600],
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}