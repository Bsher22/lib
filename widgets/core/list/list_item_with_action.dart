// lib/widgets/core/list/list_item_with_action.dart
import 'package:flutter/material.dart';

/// A reusable list item component with configurable actions
class ListItemWithActions extends StatelessWidget {
  /// Main title/label for the list item
  final String title;

  /// Optional subtitle text
  final String? subtitle;

  /// Optional second line of subtitle text
  final String? subtitle2;

  /// Optional leading widget (usually an icon or avatar)
  final Widget? leading;

  /// Optional list of action widgets to display at the end
  final List<Widget>? actions;

  /// Background color of the list item
  final Color? backgroundColor;

  /// Border configuration
  final Border? border;

  /// Border radius for the item
  final BorderRadius? borderRadius;

  /// Padding within the list item
  final EdgeInsetsGeometry padding;

  /// Margin around the list item
  final EdgeInsetsGeometry margin;

  /// Callback when the item is tapped
  final VoidCallback? onTap;

  /// Whether to display a trailing chevron/arrow
  final bool showChevron;

  /// Elevation for the card (if border is null)
  final double elevation;

  /// If true, renders with Card instead of Container
  final bool isCard;

  /// Whether the item is selected
  final bool isSelected;

  /// Color to use when item is selected
  final Color? selectedColor;

  /// Whether to show a divider after this item
  final bool showDivider;

  /// Extra spacing between leading widget and content
  final double leadingSpacing;

  /// Optional widget to display as a disclosure indicator instead of chevron
  final Widget? trailingWidget;

  const ListItemWithActions({
    Key? key,
    required this.title,
    this.subtitle,
    this.subtitle2,
    this.leading,
    this.actions,
    this.backgroundColor,
    this.border,
    this.borderRadius,
    this.padding = const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
    this.margin = EdgeInsets.zero,
    this.onTap,
    this.showChevron = false,
    this.elevation = 0,
    this.isCard = false,
    this.isSelected = false,
    this.selectedColor,
    this.showDivider = false,
    this.leadingSpacing = 16,
    this.trailingWidget,
  }) : super(key: key);

  /// Factory constructor for creating a list item with an icon
  factory ListItemWithActions.withIcon({
    required String title,
    String? subtitle,
    String? subtitle2,
    required IconData icon,
    Color? iconColor,
    List<Widget>? actions,
    Color? backgroundColor,
    Border? border,
    BorderRadius? borderRadius,
    EdgeInsetsGeometry padding = const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
    EdgeInsetsGeometry margin = EdgeInsets.zero,
    VoidCallback? onTap,
    bool showChevron = false,
    double elevation = 0,
    bool isCard = false,
    bool isSelected = false,
    Color? selectedColor,
    bool showDivider = false,
    double leadingSpacing = 16,
    Widget? trailingWidget,
  }) {
    return ListItemWithActions(
      title: title,
      subtitle: subtitle,
      subtitle2: subtitle2,
      leading: Icon(
        icon,
        color: iconColor ?? Colors.blue,
      ),
      actions: actions,
      backgroundColor: backgroundColor,
      border: border,
      borderRadius: borderRadius,
      padding: padding,
      margin: margin,
      onTap: onTap,
      showChevron: showChevron,
      elevation: elevation,
      isCard: isCard,
      isSelected: isSelected,
      selectedColor: selectedColor,
      showDivider: showDivider,
      leadingSpacing: leadingSpacing,
      trailingWidget: trailingWidget,
    );
  }

  /// Factory constructor for creating a list item with an avatar
  factory ListItemWithActions.withAvatar({
    required String title,
    String? subtitle,
    String? subtitle2,
    required String avatarText,
    Color? avatarColor,
    double avatarRadius = 20,
    List<Widget>? actions,
    Color? backgroundColor,
    Border? border,
    BorderRadius? borderRadius,
    EdgeInsetsGeometry padding = const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
    EdgeInsetsGeometry margin = EdgeInsets.zero,
    VoidCallback? onTap,
    bool showChevron = false,
    double elevation = 0,
    bool isCard = false,
    bool isSelected = false,
    Color? selectedColor,
    bool showDivider = false,
    double leadingSpacing = 16,
    Widget? trailingWidget,
  }) {
    return ListItemWithActions(
      title: title,
      subtitle: subtitle,
      subtitle2: subtitle2,
      leading: CircleAvatar(
        radius: avatarRadius,
        backgroundColor: avatarColor ?? Colors.blue,
        child: Text(
          avatarText.isNotEmpty ? avatarText.substring(0, 1).toUpperCase() : '?',
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      actions: actions,
      backgroundColor: backgroundColor,
      border: border,
      borderRadius: borderRadius,
      padding: padding,
      margin: margin,
      onTap: onTap,
      showChevron: showChevron,
      elevation: elevation,
      isCard: isCard,
      isSelected: isSelected,
      selectedColor: selectedColor,
      showDivider: showDivider,
      leadingSpacing: leadingSpacing,
      trailingWidget: trailingWidget,
    );
  }

  @override
  Widget build(BuildContext context) {
    final effectiveBackgroundColor = isSelected
        ? (selectedColor ?? Colors.blue[50])
        : (backgroundColor ?? Theme.of(context).canvasColor);

    final content = Padding(
      padding: padding,
      child: Row(
        children: [
          if (leading != null) ...[
            leading!,
            SizedBox(width: leadingSpacing),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    subtitle!,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
                if (subtitle2 != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    subtitle2!,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (actions != null && actions!.isNotEmpty) ...actions!,
          if (showChevron) ...[
            const SizedBox(width: 8),
            const Icon(
              Icons.chevron_right,
              color: Colors.grey,
            ),
          ],
          if (trailingWidget != null) ...[
            const SizedBox(width: 8),
            trailingWidget!,
          ],
        ],
      ),
    );

    final listItem = isCard
        ? Card(
            margin: margin,
            elevation: elevation,
            shape: borderRadius != null
                ? RoundedRectangleBorder(borderRadius: borderRadius!)
                : null,
            color: effectiveBackgroundColor,
            child: InkWell(
              onTap: onTap,
              borderRadius: borderRadius,
              child: content,
            ),
          )
        : Container(
            margin: margin,
            decoration: BoxDecoration(
              color: effectiveBackgroundColor,
              border: border,
              borderRadius: borderRadius,
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: onTap,
                borderRadius: borderRadius,
                child: content,
              ),
            ),
          );

    if (showDivider) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          listItem,
          const Divider(height: 1, indent: 16, endIndent: 16),
        ],
      );
    }

    return listItem;
  }

  /// Creates an action button with an icon
  static Widget createIconAction({
    required IconData icon,
    required VoidCallback onPressed,
    Color? color,
    String? tooltip,
  }) {
    return IconButton(
      icon: Icon(icon),
      tooltip: tooltip,
      color: color ?? Colors.blueGrey[400],
      onPressed: onPressed,
      constraints: const BoxConstraints(),
      padding: const EdgeInsets.all(8),
      iconSize: 20,
    );
  }

  /// Creates a list of common actions (edit, delete)
  static List<Widget> createCommonActions({
    VoidCallback? onEdit,
    VoidCallback? onDelete,
    VoidCallback? onView,
    Color? color,
  }) {
    final actions = <Widget>[];

    if (onView != null) {
      actions.add(createIconAction(
        icon: Icons.visibility,
        tooltip: 'View',
        onPressed: onView,
        color: color,
      ));
    }

    if (onEdit != null) {
      actions.add(createIconAction(
        icon: Icons.edit,
        tooltip: 'Edit',
        onPressed: onEdit,
        color: color,
      ));
    }

    if (onDelete != null) {
      actions.add(createIconAction(
        icon: Icons.delete,
        tooltip: 'Delete',
        onPressed: onDelete,
        color: Colors.red[400],
      ));
    }

    return actions;
  }
}