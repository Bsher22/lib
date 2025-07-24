// widgets/assessment/shot/outcome_selector.dart
import 'package:flutter/material.dart';
import 'package:hockey_shot_tracker/widgets/core/selection/index.dart';
import 'package:hockey_shot_tracker/responsive_system/index.dart';

class OutcomeSelector extends StatelessWidget {
  final String selectedOutcome;
  final Function(String) onSelected;
  final List<String>? availableOutcomes; // NEW: Allow custom outcome options
  
  const OutcomeSelector({
    Key? key,
    required this.selectedOutcome,
    required this.onSelected,
    this.availableOutcomes,
  }) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    final outcomes = availableOutcomes ?? ['Goal', 'Save', 'Miss'];
    final colorMap = {
      'Goal': Colors.green,
      'Save': Colors.orange,
      'Miss': Colors.red,
    };

    return context.responsive<Widget>(
      mobile: _buildMobileOutcomeSelector(context, outcomes, colorMap),
      tablet: _buildTabletOutcomeSelector(context, outcomes, colorMap),
      desktop: _buildDesktopOutcomeSelector(context, outcomes, colorMap),
    );
  }

  Widget _buildMobileOutcomeSelector(
    BuildContext context, 
    List<String> outcomes, 
    Map<String, Color> colorMap
  ) {
    return Row(
      children: outcomes.map((outcome) {
        final isSelected = selectedOutcome == outcome;
        final color = colorMap[outcome] ?? Colors.grey;
        
        return Expanded(
          child: Container(
            margin: const EdgeInsets.only(right: 4),
            child: GestureDetector(
              onTap: () => onSelected(outcome),
              child: Container(
                padding: EdgeInsets.symmetric(
                  vertical: ResponsiveConfig.spacing(context, 1.5),
                ),
                decoration: BoxDecoration(
                  color: isSelected ? color : Colors.white,
                  border: Border.all(color: color),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  outcome,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: isSelected ? Colors.white : color,
                    fontSize: ResponsiveConfig.fontSize(context, 12),
                  ),
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildTabletOutcomeSelector(
    BuildContext context, 
    List<String> outcomes, 
    Map<String, Color> colorMap
  ) {
    return ToggleButtonGroup<String>(
      options: outcomes,
      selectedOption: selectedOutcome,
      onSelected: onSelected,
      labelBuilder: (option) => option,
      colorMap: colorMap,
      borderRadius: BorderRadius.circular(10),
    );
  }

  Widget _buildDesktopOutcomeSelector(
    BuildContext context, 
    List<String> outcomes, 
    Map<String, Color> colorMap
  ) {
    return Column(
      children: outcomes.map((outcome) {
        final isSelected = selectedOutcome == outcome;
        final color = colorMap[outcome] ?? Colors.grey;
        
        return Container(
          width: double.infinity,
          margin: const EdgeInsets.only(bottom: 8),
          child: GestureDetector(
            onTap: () => onSelected(outcome),
            child: Container(
              padding: EdgeInsets.symmetric(
                vertical: ResponsiveConfig.spacing(context, 2),
                horizontal: ResponsiveConfig.spacing(context, 2),
              ),
              decoration: BoxDecoration(
                color: isSelected ? color : Colors.white,
                border: Border.all(color: color, width: 2),
                borderRadius: BorderRadius.circular(12),
                boxShadow: isSelected ? [
                  BoxShadow(
                    color: color.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ] : null,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    _getOutcomeIcon(outcome),
                    color: isSelected ? Colors.white : color,
                    size: 20,
                  ),
                  SizedBox(width: ResponsiveConfig.spacing(context, 1)),
                  Text(
                    outcome,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: isSelected ? Colors.white : color,
                      fontSize: ResponsiveConfig.fontSize(context, 16),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  IconData _getOutcomeIcon(String outcome) {
    switch (outcome) {
      case 'Goal':
        return Icons.sports_hockey;
      case 'Save':
        return Icons.sports;
      case 'Miss':
        return Icons.close;
      default:
        return Icons.circle;
    }
  }
}