// lib/widgets/core/selection/toggle_button_group.dart
import 'package:flutter/material.dart';

/// A group of toggle buttons that allow exclusive selection
class ToggleButtonGroup<T> extends StatelessWidget {
  /// Available options to display as toggle buttons
  final List<T> options;

  /// Currently selected option
  final T? selectedOption;

  /// Callback when selection changes
  final ValueChanged<T>? onSelected;

  /// Function to get the display label for each option
  final String Function(T)? labelBuilder;
  
  /// Function to get the icon for each option
  final Widget Function(T)? iconBuilder;
  
  /// Function to get the color for each option
  final Color Function(T, bool)? colorBuilder;

  /// Map of colors for specific options (optional)
  final Map<T, Color>? colorMap;

  /// Default color for selected buttons without specific color
  final Color defaultSelectedColor;

  /// Border radius for the button group
  final BorderRadius? borderRadius;

  const ToggleButtonGroup({
    Key? key,
    required this.options,
    this.selectedOption,
    this.onSelected,
    this.labelBuilder,
    this.iconBuilder,
    this.colorBuilder,
    this.colorMap,
    this.defaultSelectedColor = Colors.blue,
    this.borderRadius,
  }) : super(key: key);

  /// Constructor that takes a list of strings directly
  static ToggleButtonGroup<String> fromStrings({
    required List<String> options,
    String? selectedOption,
    ValueChanged<String>? onSelected,
    Map<String, Color>? colorMap,
    Color defaultSelectedColor = Colors.blue,
    BorderRadius? borderRadius,
  }) {
    return ToggleButtonGroup<String>(
      options: options,
      selectedOption: selectedOption,
      onSelected: onSelected,
      labelBuilder: (option) => option,
      colorMap: colorMap,
      defaultSelectedColor: defaultSelectedColor,
      borderRadius: borderRadius,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (options.isEmpty) {
      return const SizedBox.shrink();
    }
    
    // Convert options to indexes for ToggleButtons widget
    final selectedIndex = selectedOption != null ? options.indexOf(selectedOption!) : -1;
    final isSelected = List.generate(
      options.length,
      (index) => index == selectedIndex,
    );

    return ToggleButtons(
      isSelected: isSelected,
      onPressed: onSelected == null ? null : (index) {
        if (index != selectedIndex) {
          onSelected!(options[index]);
        }
      },
      borderRadius: borderRadius ?? BorderRadius.circular(4),
      children: options.map((option) {
        final isThisSelected = option == selectedOption;
        
        // Determine color for this option
        Color color;
        if (colorBuilder != null) {
          color = colorBuilder!(option, isThisSelected);
        } else if (colorMap != null && colorMap!.containsKey(option)) {
          color = colorMap![option]!;
        } else {
          color = defaultSelectedColor;
        }

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          color: isThisSelected ? color.withOpacity(0.2) : null,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (iconBuilder != null) ...[
                iconBuilder!(option),
                const SizedBox(width: 8),
              ],
              Text(
                labelBuilder != null ? labelBuilder!(option) : option.toString(),
                style: TextStyle(
                  color: isThisSelected ? color : Colors.grey[800],
                  fontWeight: isThisSelected ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}