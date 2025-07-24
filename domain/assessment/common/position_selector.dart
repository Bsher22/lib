// lib/widgets/domain/assessment/common/position_selector.dart
import 'package:flutter/material.dart';
import 'package:hockey_shot_tracker/widgets/core/selection/index.dart';

/// A component for selecting hockey positions
class PositionSelector extends StatelessWidget {
  /// Currently selected position
  final String selectedPosition;
  
  /// Callback when position selection changes
  final ValueChanged<String> onPositionSelected;
  
  /// Optional disabled state
  final bool disabled;

  const PositionSelector({
    Key? key,
    required this.selectedPosition,
    required this.onPositionSelected,
    this.disabled = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final positions = [
      'forward',
      'defenseman',
      'goalie',
    ];
    
    final positionLabels = {
      'forward': 'Forward',
      'defenseman': 'Defenseman',
      'goalie': 'Goalie',
    };
    
    final positionIcons = {
      'forward': Icons.arrow_forward,
      'defenseman': Icons.shield,
      'goalie': Icons.sports_hockey,
    };
    
    return ToggleButtonGroup<String>(
      options: positions,
      selectedOption: selectedPosition,
      onSelected: disabled ? (_) {} : onPositionSelected,
      labelBuilder: (position) => positionLabels[position] ?? position,
      colorMap: {
        'forward': Colors.blue,
        'defenseman': Colors.green,
        'goalie': Colors.orange,
      },
      borderRadius: BorderRadius.circular(8),
    );
  }
}