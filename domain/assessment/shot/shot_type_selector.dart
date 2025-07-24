// widgets/assessment/shot/shot_type_selector.dart
import 'package:flutter/material.dart';
import 'package:hockey_shot_tracker/widgets/core/selection/index.dart';

class ShotTypeSelector extends StatelessWidget {
  final String selectedType;
  final Function(String) onSelected;
  
  const ShotTypeSelector({
    Key? key,
    required this.selectedType,
    required this.onSelected,
  }) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    final shotTypes = ['Wrist', 'Snap', 'Slap', 'Backhand', 'One-timer'];
    
    // Replace fromStrings with direct constructor usage
    return FilterChipGroup<String>(
      options: shotTypes,
      selectedOptions: selectedType.isNotEmpty ? [selectedType] : [],
      onSelected: (type, selected) {
        if (selected) {
          onSelected(type);
        }
      },
      labelBuilder: (option) => option,
      selectedColor: Colors.cyanAccent,
      backgroundColor: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    );
  }
}