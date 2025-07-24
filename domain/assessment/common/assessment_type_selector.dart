// File: lib/widgets/assessment/common/assessment_type_selector.dart
import 'package:flutter/material.dart';

/// A unified assessment type selector that can be used for both shot and skating assessments.
class AssessmentTypeSelector extends StatelessWidget {
  /// The currently selected assessment type
  final String selectedType;
  
  /// Callback function called when a type is selected
  final Function(String) onTypeSelected;
  
  /// Map of assessment types containing 'title' and 'description' for each type
  final Map<String, Map<String, dynamic>> assessmentTypes;
  
  /// Display style for the assessment types
  /// - 'radio': Uses RadioListTile (default)
  /// - 'card': Uses card-based selection
  final String displayStyle;
  
  /// Custom colors for selection
  final Color? activeColor;
  final Color? backgroundColor;
  final Color? selectedBackgroundColor;
  
  const AssessmentTypeSelector({
    Key? key,
    required this.selectedType,
    required this.onTypeSelected,
    required this.assessmentTypes,
    this.displayStyle = 'radio',
    this.activeColor,
    this.backgroundColor,
    this.selectedBackgroundColor,
  }) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    // Determine which style to use
    if (displayStyle == 'card') {
      return _buildCardStyle(context);
    } else {
      return _buildRadioStyle(context);
    }
  }
  
  /// Builds the radio list tile style selector
  Widget _buildRadioStyle(BuildContext context) {
    // Filter out null keys to be safe
    final validTypes = assessmentTypes.keys.where((type) => type != null).toList();

    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: validTypes.map((type) {
          bool isSelected = selectedType == type;
          final assessmentData = assessmentTypes[type]!;
          
          return RadioListTile<String>(
            title: Text(
              assessmentData['title']?.toString() ?? 'Unknown', // Safe access with fallback
              style: TextStyle(
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
            subtitle: Text(
              assessmentData['description']?.toString() ?? 'No description', // Safe access with fallback
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[700],
              ),
            ),
            value: type,
            groupValue: selectedType,
            onChanged: (value) {
              if (value != null) {
                onTypeSelected(value);
              }
            },
            activeColor: activeColor ?? Colors.cyanAccent[700],
            selected: isSelected,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          );
        }).toList(),
      ),
    );
  }
  
  /// Builds the card style selector
  Widget _buildCardStyle(BuildContext context) {
    // Filter out null keys to be safe
    final validTypes = assessmentTypes.keys.where((type) => type != null).toList();

    return Column(
      children: validTypes.map((type) {
        final isSelected = selectedType == type;
        final assessmentData = assessmentTypes[type]!;
        
        return InkWell(
          onTap: () => onTypeSelected(type),
          borderRadius: BorderRadius.circular(8),
          child: Container(
            width: double.infinity,
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isSelected 
                  ? (selectedBackgroundColor ?? Colors.cyanAccent.withOpacity(0.15)) 
                  : (backgroundColor ?? Colors.white),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: isSelected 
                    ? (activeColor ?? Colors.cyanAccent)
                    : Colors.grey[300]!,
                width: isSelected ? 2 : 1,
              ),
            ),
            child: Row(
              children: [
                // Radio button or checkbox indicator
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isSelected 
                        ? (activeColor ?? Colors.cyanAccent)
                        : Colors.transparent,
                    border: Border.all(
                      color: isSelected
                          ? (activeColor ?? Colors.cyanAccent)
                          : Colors.grey[400]!,
                      width: 2,
                    ),
                  ),
                  child: isSelected
                      ? const Icon(
                          Icons.check,
                          size: 16,
                          color: Colors.black,
                        )
                      : null,
                ),
                const SizedBox(width: 16),
                // Content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        assessmentData['title']?.toString() ?? 'Unknown', // Safe access with fallback
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          color: Colors.blueGrey[800],
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        assessmentData['description']?.toString() ?? 'No description', // Safe access with fallback
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.blueGrey[600],
                        ),
                      ),
                      if (assessmentData.containsKey('details') && assessmentData['details'] != null) ...[
                        const SizedBox(height: 8),
                        Text(
                          assessmentData['details']?.toString() ?? '', // Safe access with fallback
                          style: TextStyle(
                            fontSize: 11,
                            fontStyle: FontStyle.italic,
                            color: Colors.blueGrey[500],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
  
  /// Factory constructor for shot assessments
  factory AssessmentTypeSelector.forShotAssessment({
    required String selectedType,
    required Function(String) onTypeSelected,
    required Map<String, Map<String, dynamic>> assessmentTypes,
    String displayStyle = 'radio',
    Color? activeColor,
    Color? backgroundColor,
    Color? selectedBackgroundColor,
  }) {
    return AssessmentTypeSelector(
      selectedType: selectedType,
      onTypeSelected: onTypeSelected,
      assessmentTypes: assessmentTypes,
      displayStyle: displayStyle,
      activeColor: activeColor ?? Colors.green[700],
      backgroundColor: backgroundColor,
      selectedBackgroundColor: selectedBackgroundColor,
    );
  }
  
  /// Factory constructor for skating assessments
  factory AssessmentTypeSelector.forSkatingAssessment({
    required String selectedType,
    required Function(String) onTypeSelected,
    required Map<String, Map<String, dynamic>> assessmentTypes,
    String displayStyle = 'radio',
    Color? activeColor,
    Color? backgroundColor,
    Color? selectedBackgroundColor,
  }) {
    return AssessmentTypeSelector(
      selectedType: selectedType,
      onTypeSelected: onTypeSelected,
      assessmentTypes: assessmentTypes,
      displayStyle: displayStyle,
      activeColor: activeColor ?? Colors.blue[700],
      backgroundColor: backgroundColor,
      selectedBackgroundColor: selectedBackgroundColor,
    );
  }
}