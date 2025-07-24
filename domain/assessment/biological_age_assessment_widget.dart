// widgets/domain/assessment/biological_age_assessment_widget.dart
import 'package:flutter/material.dart';
import 'package:hockey_shot_tracker/widgets/core/list/standard_card.dart';
import 'package:hockey_shot_tracker/widgets/core/form/standard_text_field.dart';
import 'package:hockey_shot_tracker/widgets/core/form/standard_dropdown.dart';

class BiologicalAgeAssessmentWidget extends StatefulWidget {
  final DateTime? birthDate;
  final String? ageGroup;
  final double? currentHeight; // in inches
  final double? currentWeight; // in pounds
  final Map<String, dynamic>? previousMeasurements;
  final ValueChanged<Map<String, dynamic>>? onAssessmentChanged;
  final bool showExplanation;
  final bool enableAdvancedFeatures; // For easy Option C upgrade

  const BiologicalAgeAssessmentWidget({
    Key? key,
    this.birthDate,
    this.ageGroup,
    this.currentHeight,
    this.currentWeight,
    this.previousMeasurements,
    this.onAssessmentChanged,
    this.showExplanation = true,
    this.enableAdvancedFeatures = false, // Set to true for Option C
  }) : super(key: key);

  @override
  State<BiologicalAgeAssessmentWidget> createState() => _BiologicalAgeAssessmentWidgetState();
}

class _BiologicalAgeAssessmentWidgetState extends State<BiologicalAgeAssessmentWidget> {
  final TextEditingController _heightController = TextEditingController();
  final TextEditingController _weightController = TextEditingController();
  
  // OPTION C CONTROLLERS (currently unused but ready for expansion)
  // final TextEditingController _parentHeight1Controller = TextEditingController();
  // final TextEditingController _parentHeight2Controller = TextEditingController();
  
  String? _growthSpurtStatus;
  String? _maturationCategory;
  double? _heightVelocity; // inches per year
  Map<String, dynamic> _assessmentResults = {};
  
  // OPTION C VARIABLES (currently unused but ready for expansion)
  // String? _voiceChangeStatus;
  // String? _facialHairStatus;
  // double? _predictedAdultHeight;

  @override
  void initState() {
    super.initState();
    _initializeFields();
    _calculateAssessment();
  }

  void _initializeFields() {
    if (widget.currentHeight != null) {
      _heightController.text = widget.currentHeight!.toStringAsFixed(1);
    }
    if (widget.currentWeight != null) {
      _weightController.text = widget.currentWeight!.toStringAsFixed(1);
    }
  }

  @override
  void dispose() {
    _heightController.dispose();
    _weightController.dispose();
    // OPTION C DISPOSAL (add when enabling advanced features)
    // _parentHeight1Controller.dispose();
    // _parentHeight2Controller.dispose();
    super.dispose();
  }

  void _calculateAssessment() {
    final age = _getAge();
    if (age == null || age < 8 || age > 18) {
      return; // Only applicable for youth players
    }

    final height = double.tryParse(_heightController.text);
    final weight = double.tryParse(_weightController.text);
    
    if (height == null || weight == null) {
      return;
    }

    // Calculate basic biological age indicators
    _heightVelocity = _calculateHeightVelocity(height);
    _maturationCategory = _determineMaturationType(age, height, weight);

    _assessmentResults = {
      'chronological_age': age,
      'height_inches': height,
      'weight_pounds': weight,
      'height_velocity_inches_per_year': _heightVelocity,
      'maturation_category': _maturationCategory,
      'growth_spurt_status': _growthSpurtStatus,
      'assessment_date': DateTime.now().toIso8601String(),
      'skating_expectation_adjustment': _getSkatingExpectationAdjustment(),
      'assessment_version': 'option_b', // Track which version was used
    };

    // OPTION C ADDITIONS (uncomment when enabling advanced features)
    // _assessmentResults.addAll({
    //   'voice_change_status': _voiceChangeStatus,
    //   'facial_hair_status': _facialHairStatus,
    //   'predicted_adult_height': _predictedAdultHeight,
    //   'phv_status': _estimatePHVStatus(age, height, _heightVelocity),
    // });

    widget.onAssessmentChanged?.call(_assessmentResults);
    setState(() {});
  }

  double? _getAge() {
    if (widget.birthDate == null) return null;
    final now = DateTime.now();
    final difference = now.difference(widget.birthDate!);
    return difference.inDays / 365.25;
  }

  double? _calculateHeightVelocity(double currentHeightInches) {
    if (widget.previousMeasurements == null) return null;
    
    final previousHeight = widget.previousMeasurements!['height_inches'] as double?;
    final previousDate = widget.previousMeasurements!['date'] as String?;
    
    if (previousHeight == null || previousDate == null) return null;
    
    final prevDate = DateTime.tryParse(previousDate);
    if (prevDate == null) return null;
    
    final timeDifference = DateTime.now().difference(prevDate).inDays / 365.25;
    if (timeDifference < 0.25) return null; // Need at least 3 months
    
    return (currentHeightInches - previousHeight) / timeDifference; // inches/year
  }

  String _determineMaturationType(double age, double height, double weight) {
    // Simplified maturation assessment based on height percentiles for age
    final heightPercentile = _calculateHeightPercentile(age, height);
    
    // Check for rapid growth phase
    if (_heightVelocity != null && _growthSpurtStatus != null) {
      if (_heightVelocity! > 3.0 && // More than 3 inches/year
          (_growthSpurtStatus == 'peak' || _growthSpurtStatus == 'beginning') &&
          age >= 11 && age <= 15) {
        return 'Rapid Growth Phase';
      }
    }
    
    // Basic categorization based on height percentile
    if (heightPercentile >= 85) {
      return 'Early Maturer';
    } else if (heightPercentile >= 15) {
      return 'Average Maturer';
    } else {
      return 'Late Maturer';
    }
  }

  double _calculateHeightPercentile(double age, double heightInches) {
    // Simplified height percentile calculation using inches
    // In practice, this would use WHO/CDC growth charts
    final ageInt = age.round();
    
    // Rough height standards for males in inches (would need gender-specific data)
    final heightStandards = {
      8: {'p15': 45, 'p50': 49, 'p85': 53},
      9: {'p15': 47, 'p50': 51, 'p85': 55},
      10: {'p15': 49, 'p50': 53, 'p85': 57},
      11: {'p15': 51, 'p50': 55, 'p85': 59},
      12: {'p15': 53, 'p50': 57, 'p85': 63},
      13: {'p15': 57, 'p50': 61, 'p85': 67},
      14: {'p15': 61, 'p50': 65, 'p85': 69},
      15: {'p15': 63, 'p50': 67, 'p85': 71},
      16: {'p15': 65, 'p50': 69, 'p85': 73},
      17: {'p15': 66, 'p50': 70, 'p85': 74},
      18: {'p15': 66, 'p50': 70, 'p85': 74},
    };
    
    final standards = heightStandards[ageInt];
    if (standards == null) return 50.0;
    
    if (heightInches >= standards['p85']!) return 85.0;
    if (heightInches >= standards['p50']!) return 50.0;
    if (heightInches >= standards['p15']!) return 15.0;
    return 5.0;
  }

  // OPTION C METHODS (currently unused but ready for expansion)
  /*
  String _estimatePHVStatus(double age, double height, double? heightVelocity) {
    if (heightVelocity == null) return 'Unknown';
    
    // Convert to inches per year thresholds
    if (heightVelocity > 3.2) { // ~8cm/year
      return 'At or Near PHV';
    } else if (heightVelocity > 1.6 && age >= 11 && age <= 16) { // ~4cm/year
      return 'Approaching PHV';
    } else if (heightVelocity < 0.8 && age > 15) { // ~2cm/year
      return 'Post-PHV';
    } else if (age < 12) {
      return 'Pre-PHV';
    } else {
      return 'Transitional';
    }
  }

  double? _calculatePredictedAdultHeight(double currentHeight, double age) {
    // Simplified prediction using Khamis-Roche method approximation
    final parent1Height = double.tryParse(_parentHeight1Controller.text);
    final parent2Height = double.tryParse(_parentHeight2Controller.text);
    
    if (parent1Height != null && parent2Height != null) {
      // Mid-parental height method (convert to inches)
      final midParentalHeight = (parent1Height + parent2Height) / 2;
      return midParentalHeight + (age > 16 ? 2.5 : 0); // Rough adjustment for males
    }
    
    // Fallback: Use age-based growth curve estimation
    if (age >= 16) {
      return currentHeight * 1.02; // Minimal growth remaining
    } else if (age >= 14) {
      return currentHeight * 1.08; // Some growth remaining
    } else if (age >= 12) {
      return currentHeight * 1.15; // Moderate growth remaining
    } else {
      return currentHeight * 1.25; // Significant growth remaining
    }
  }
  */

  Map<String, dynamic> _getSkatingExpectationAdjustment() {
    if (_maturationCategory == null) {
      return {'adjustment': 'none', 'explanation': 'No adjustment needed'};
    }
    
    switch (_maturationCategory!) {
      case 'Early Maturer':
        return {
          'adjustment': 'expect_higher_performance',
          'explanation': 'Early maturers often show temporarily superior athletic performance',
          'coaching_notes': 'Focus on skill development, avoid overreliance on physical advantages'
        };
      case 'Late Maturer':
        return {
          'adjustment': 'expect_lower_performance_temporarily',
          'explanation': 'Late maturers may appear less skilled but will likely catch up by age 18-20',
          'coaching_notes': 'Emphasize technical skills, be patient with physical development'
        };
      case 'Rapid Growth Phase':
        return {
          'adjustment': 'expect_temporary_coordination_issues',
          'explanation': 'Rapid growth can temporarily affect coordination and skating mechanics',
          'coaching_notes': 'Focus on maintaining technique during growth spurts'
        };
      default:
        return {
          'adjustment': 'standard_expectations',
          'explanation': 'Average maturation pattern - use standard benchmarks'
        };
    }
  }

  @override
  Widget build(BuildContext context) {
    final age = _getAge();
    
    // Only show for youth players (8-18 years old)
    if (age == null || age < 8 || age > 18) {
      return _buildNotApplicableCard();
    }

    return StandardCard(
      headerIcon: Icons.child_care,
      headerIconColor: Colors.purple,
      title: 'Growth & Maturation Tracking',
      subtitle: 'Basic maturation awareness for fair performance evaluation',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (widget.showExplanation) ...[
            _buildExplanationCard(),
            const SizedBox(height: 16),
          ],
          
          _buildCurrentMeasurements(),
          const SizedBox(height: 16),
          
          _buildGrowthStatus(),
          const SizedBox(height: 16),
          
          // OPTION C SECTIONS (uncomment when enabling advanced features)
          // if (widget.enableAdvancedFeatures) ...[
          //   _buildParentalHeights(),
          //   const SizedBox(height: 16),
          //   _buildSecondaryCharacteristics(),
          //   const SizedBox(height: 16),
          // ],
          
          if (_assessmentResults.isNotEmpty) ...[
            _buildAssessmentResults(),
            const SizedBox(height: 16),
            _buildSkatingImplications(),
          ],
        ],
      ),
    );
  }

  Widget _buildNotApplicableCard() {
    return StandardCard(
      headerIcon: Icons.info_outline,
      headerIconColor: Colors.blue,
      title: 'Growth & Maturation Tracking',
      child: Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(
              Icons.child_care,
              size: 48,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 12),
            const Text(
              'Not Applicable',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Growth tracking is only relevant for youth players (ages 8-18) where maturation significantly affects performance.',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExplanationCard() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.purple.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.purple.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.science, color: Colors.purple[600], size: 16),
              const SizedBox(width: 8),
              const Text(
                'Why Growth Tracking Matters',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            'Players of the same age can be at very different stages of physical development. This basic tracking helps provide fair evaluation and appropriate development expectations.',
            style: TextStyle(fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildCurrentMeasurements() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Current Measurements',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: StandardTextField(
                controller: _heightController,
                labelText: 'Height (inches)',
                keyboardType: TextInputType.number,
                onChanged: (_) => _calculateAssessment(),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: StandardTextField(
                controller: _weightController,
                labelText: 'Weight (lbs)',
                keyboardType: TextInputType.number,
                onChanged: (_) => _calculateAssessment(),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildGrowthStatus() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Growth Pattern',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Recent growth patterns help understand development stage',
          style: TextStyle(
            fontSize: 12,
            color: Colors.blueGrey[600],
          ),
        ),
        const SizedBox(height: 12),
        
        StandardDropdown<String>(
          value: _growthSpurtStatus,
          hint: 'Recent growth patterns',
          items: const [
            DropdownMenuItem(value: 'none', child: Text('No recent growth spurt')),
            DropdownMenuItem(value: 'beginning', child: Text('Growth spurt beginning')),
            DropdownMenuItem(value: 'peak', child: Text('In peak growth phase')),
            DropdownMenuItem(value: 'slowing', child: Text('Growth slowing down')),
            DropdownMenuItem(value: 'complete', child: Text('Growth spurt complete')),
          ],
          onChanged: (value) {
            setState(() {
              _growthSpurtStatus = value;
            });
            _calculateAssessment();
          },
        ),
      ],
    );
  }

  // OPTION C UI SECTIONS (currently unused but ready for expansion)
  /*
  Widget _buildParentalHeights() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Parental Heights (Optional)',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Helps predict adult height for better maturation assessment',
          style: TextStyle(
            fontSize: 12,
            color: Colors.blueGrey[600],
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: StandardTextField(
                controller: _parentHeight1Controller,
                labelText: 'Parent 1 Height (inches)',
                keyboardType: TextInputType.number,
                onChanged: (_) => _calculateAssessment(),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: StandardTextField(
                controller: _parentHeight2Controller,
                labelText: 'Parent 2 Height (inches)',
                keyboardType: TextInputType.number,
                onChanged: (_) => _calculateAssessment(),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSecondaryCharacteristics() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Secondary Sexual Characteristics',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Indicators of pubertal development (for ages 11+)',
          style: TextStyle(
            fontSize: 12,
            color: Colors.blueGrey[600],
          ),
        ),
        const SizedBox(height: 12),
        
        StandardDropdown<String>(
          value: _voiceChangeStatus,
          hint: 'Voice change status',
          items: const [
            DropdownMenuItem(value: 'none', child: Text('No voice change')),
            DropdownMenuItem(value: 'beginning', child: Text('Voice beginning to change')),
            DropdownMenuItem(value: 'changing', child: Text('Voice actively changing')),
            DropdownMenuItem(value: 'complete', child: Text('Voice change complete')),
          ],
          onChanged: (value) {
            setState(() {
              _voiceChangeStatus = value;
            });
            _calculateAssessment();
          },
        ),
        
        const SizedBox(height: 12),
        
        StandardDropdown<String>(
          value: _facialHairStatus,
          hint: 'Facial hair development',
          items: const [
            DropdownMenuItem(value: 'none', child: Text('No facial hair')),
            DropdownMenuItem(value: 'light', child: Text('Light/sparse facial hair')),
            DropdownMenuItem(value: 'moderate', child: Text('Moderate facial hair')),
            DropdownMenuItem(value: 'full', child: Text('Full facial hair development')),
          ],
          onChanged: (value) {
            setState(() {
              _facialHairStatus = value;
            });
            _calculateAssessment();
          },
        ),
      ],
    );
  }
  */

  Widget _buildAssessmentResults() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.green.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.green.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.assessment, color: Colors.green[600], size: 16),
              const SizedBox(width: 8),
              const Text(
                'Assessment Results',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          
          _buildResultRow('Maturation Type', _maturationCategory ?? 'Unknown'),
          
          if (_heightVelocity != null)
            _buildResultRow('Height Velocity', '${_heightVelocity!.toStringAsFixed(1)} inches/year'),
          
          // OPTION C RESULTS (uncomment when enabling advanced features)
          // if (widget.enableAdvancedFeatures) ...[
          //   if (_predictedAdultHeight != null)
          //     _buildResultRow('Predicted Adult Height', '${_predictedAdultHeight!.toStringAsFixed(1)} inches'),
          //   _buildResultRow('PHV Status', _assessmentResults['phv_status'] ?? 'Unknown'),
          // ],
        ],
      ),
    );
  }

  Widget _buildResultRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 12),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSkatingImplications() {
    final adjustment = _assessmentResults['skating_expectation_adjustment'] as Map<String, dynamic>?;
    if (adjustment == null) return const SizedBox.shrink();
    
    Color cardColor;
    IconData icon;
    
    switch (adjustment['adjustment']) {
      case 'expect_higher_performance':
        cardColor = Colors.blue;
        icon = Icons.trending_up;
        break;
      case 'expect_lower_performance_temporarily':
        cardColor = Colors.orange;
        icon = Icons.schedule;
        break;
      case 'expect_temporary_coordination_issues':
        cardColor = Colors.amber;
        icon = Icons.warning;
        break;
      default:
        cardColor = Colors.green;
        icon = Icons.check_circle;
    }
    
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: cardColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: cardColor.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: cardColor[600], size: 16),
              const SizedBox(width: 8),
              const Text(
                'Skating Performance Implications',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            adjustment['explanation'] ?? '',
            style: const TextStyle(fontSize: 12),
          ),
          if (adjustment['coaching_notes'] != null) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: cardColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Row(
                children: [
                  Icon(Icons.sports_hockey, size: 14, color: cardColor[700]),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'Coaching Note: ${adjustment['coaching_notes']}',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: cardColor[700],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/*
=============================================================================
OPTION C UPGRADE INSTRUCTIONS
=============================================================================

To enable full biological age assessment (Option C), make these changes:

1. SET enableAdvancedFeatures = true when creating the widget:
   BiologicalAgeAssessmentWidget(
     enableAdvancedFeatures: true,
     // ... other parameters
   )

2. UNCOMMENT the following sections in this file:
   - All variables marked with "OPTION C VARIABLES"
   - All disposal code marked with "OPTION C DISPOSAL"
   - All methods marked with "OPTION C METHODS"
   - All UI sections marked with "OPTION C SECTIONS"
   - All results marked with "OPTION C RESULTS"
   - All additions marked with "OPTION C ADDITIONS"

3. ADD these imports if using Option C:
   // No additional imports needed

4. UPDATE the explanation text to mention the additional features:
   Change "Basic maturation awareness" to "Comprehensive biological age assessment"

5. CONSIDER PRIVACY/SENSITIVITY:
   - Add privacy notice for sensitive data collection
   - Ensure data storage compliance
   - Add option to skip sensitive questions
   - Consider parental consent for minors

6. OPTIONAL ENHANCEMENTS for Option C:
   - Add gender-specific growth charts
   - Integrate with medical growth references
   - Add BMI calculations
   - Include bone age estimation
   - Add sport-specific maturation norms

The framework is designed for easy expansion - just uncomment the marked
sections and set enableAdvancedFeatures = true.
=============================================================================
*/