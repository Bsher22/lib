// lib/widgets/core/selection/filter_chip_group.dart
import 'package:flutter/material.dart';

/// A group of filter chips that allow multiple selections
class FilterChipGroup<T> extends StatelessWidget {
  /// Available options to display as chips
  final List<T> options;

  /// Currently selected options
  final List<T> selectedOptions;

  /// Callback when selection changes
  final void Function(T, bool) onSelected;

  /// Function to get the display label for each option
  final String Function(T)? labelBuilder;

  /// Color for selected chips
  final Color selectedColor;

  /// Background color for unselected chips
  final Color backgroundColor;

  /// Padding within each chip
  final EdgeInsetsGeometry padding;

  /// Spacing between chips
  final double spacing;

  /// Spacing between rows
  final double runSpacing;

  const FilterChipGroup({
    Key? key,
    required this.options,
    required this.selectedOptions,
    required this.onSelected,
    this.labelBuilder,
    this.selectedColor = Colors.blue,
    this.backgroundColor = Colors.white,
    this.padding = const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    this.spacing = 8.0,
    this.runSpacing = 8.0,
  }) : super(key: key);

  /// Constructor that takes a list of strings directly
  static FilterChipGroup<String> fromStrings({
    required List<String> options,
    required List<String> selectedOptions,
    required void Function(String, bool) onSelected,
    Color selectedColor = Colors.blue,
    Color backgroundColor = Colors.white,
    EdgeInsetsGeometry padding = const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    double spacing = 8.0,
    double runSpacing = 8.0,
  }) {
    return FilterChipGroup<String>(
      options: options,
      selectedOptions: selectedOptions,
      onSelected: onSelected,
      labelBuilder: (option) => option,
      selectedColor: selectedColor,
      backgroundColor: backgroundColor,
      padding: padding,
      spacing: spacing,
      runSpacing: runSpacing,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (options.isEmpty) {
      return const SizedBox.shrink();
    }

    return Wrap(
      spacing: spacing,
      runSpacing: runSpacing,
      children: options.map((option) {
        final isSelected = selectedOptions.contains(option);

        return FilterChip(
          label: Text(
            labelBuilder != null ? labelBuilder!(option) : option.toString(),
            style: TextStyle(
              color: isSelected ? Colors.white : Colors.black87,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          selected: isSelected,
          onSelected: (selected) => onSelected(option, selected),
          selectedColor: selectedColor,
          backgroundColor: backgroundColor,
          checkmarkColor: Colors.white,
          padding: padding,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(
              color: isSelected ? selectedColor : Colors.grey[300]!,
            ),
          ),
        );
      }).toList(),
    );
  }
}