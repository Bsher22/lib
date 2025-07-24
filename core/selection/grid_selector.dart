// lib/widgets/core/selection/grid_selector.dart
import 'package:flutter/material.dart';

/// A grid-based selector for choosing items from a grid layout
class GridSelector<T> extends StatelessWidget {
  /// List of options to display in the grid
  final List<T> options;

  /// Currently selected option
  final T? selectedOption;

  /// Callback when an option is selected
  final ValueChanged<T>? onSelected;

  /// Builder for main label text
  final String Function(T) labelBuilder;

  /// Builder for optional sublabel text
  final String Function(T)? sublabelBuilder;

  /// Function to determine if an option should be disabled
  final bool Function(T)? isOptionDisabled;

  /// Number of columns in the grid
  final int crossAxisCount;

  /// Spacing between grid items horizontally
  final double horizontalSpacing;

  /// Spacing between grid items vertically
  final double verticalSpacing;

  /// Color for selected items
  final Color selectedColor;

  /// Color for unselected items
  final Color unselectedColor;

  /// Border color for grid items
  final Color borderColor;
  
  /// Color for disabled items
  final Color disabledColor;

  const GridSelector({
    Key? key,
    required this.options,
    this.selectedOption,
    this.onSelected,
    required this.labelBuilder,
    this.sublabelBuilder,
    this.isOptionDisabled,
    this.crossAxisCount = 3,
    this.horizontalSpacing = 8.0,
    this.verticalSpacing = 8.0,
    this.selectedColor = Colors.blue,
    this.unselectedColor = Colors.white,
    this.borderColor = Colors.grey,
    this.disabledColor = Colors.grey,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        mainAxisSpacing: verticalSpacing,
        crossAxisSpacing: horizontalSpacing,
        childAspectRatio: 1.0,
      ),
      itemCount: options.length,
      itemBuilder: (context, index) {
        final option = options[index];
        final isSelected = option == selectedOption;
        final isDisabled = isOptionDisabled != null && isOptionDisabled!(option);

        return GestureDetector(
          onTap: isDisabled || onSelected == null ? null : () => onSelected!(option),
          child: Container(
            decoration: BoxDecoration(
              color: isDisabled 
                  ? disabledColor.withOpacity(0.2)
                  : isSelected 
                      ? selectedColor 
                      : unselectedColor,
              border: Border.all(
                color: isDisabled ? disabledColor : borderColor,
                width: 1,
              ),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    labelBuilder(option),
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: isDisabled 
                          ? disabledColor 
                          : isSelected 
                              ? Colors.black 
                              : Colors.grey[800],
                    ),
                  ),
                  if (sublabelBuilder != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      sublabelBuilder!(option),
                      style: TextStyle(
                        fontSize: 10,
                        color: isDisabled
                            ? disabledColor.withOpacity(0.7)
                            : isSelected 
                                ? Colors.black 
                                : Colors.grey[600],
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}