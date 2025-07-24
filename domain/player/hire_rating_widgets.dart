// lib/widgets/domain/player/hire_rating_widgets.dart

import 'package:flutter/material.dart';
import 'package:hockey_shot_tracker/models/development_plan.dart';
import 'package:hockey_shot_tracker/utils/hockey_ratings_config.dart';
import 'package:hockey_shot_tracker/responsive_system/index.dart';

// ============================================================================
// MAIN HIRE RATING SECTION
// ============================================================================

class HIRERatingSection extends StatelessWidget {
  final HIREPlayerRatings ratings;
  final bool isCalculating;
  final Function(String key, double value) onRatingChanged;
  final String? calculationError;
  final VoidCallback? onRetryCalculation;
  final int playerAge; // Required for age-specific factors

  const HIRERatingSection({
    super.key,
    required this.ratings,
    required this.isCalculating,
    required this.onRatingChanged,
    required this.playerAge,
    this.calculationError,
    this.onRetryCalculation,
  });

  @override
  Widget build(BuildContext context) {
    return context.responsive<Widget>(
      mobile: _buildMobileLayout(context),
      tablet: _buildTabletLayout(context),
      desktop: _buildDesktopLayout(context),
    );
  }

  Widget _buildMobileLayout(BuildContext context) {
    return Column(
      children: [
        // HIRE Scores Header
        _buildHIREScoresHeader(context),
        
        // Rating Categories
        _buildOnIceRatingsCard(context),
        const SizedBox(height: 16),
        _buildOffIceRatingsCard(context),
        const SizedBox(height: 16),
        _buildAgeSpecificRatingsCard(context),
        
        // Error display
        if (calculationError != null)
          _buildErrorCard(context),
      ],
    );
  }

  Widget _buildTabletLayout(BuildContext context) {
    return Column(
      children: [
        _buildHIREScoresHeader(context),
        const SizedBox(height: 16),
        
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                children: [
                  _buildOnIceRatingsCard(context),
                  const SizedBox(height: 16),
                  _buildAgeSpecificRatingsCard(context),
                ],
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildOffIceRatingsCard(context),
            ),
          ],
        ),
        
        if (calculationError != null) ...[
          const SizedBox(height: 16),
          _buildErrorCard(context),
        ],
      ],
    );
  }

  Widget _buildDesktopLayout(BuildContext context) {
    return Column(
      children: [
        _buildHIREScoresHeader(context),
        const SizedBox(height: 24),
        
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 2,
              child: _buildOnIceRatingsCard(context),
            ),
            const SizedBox(width: 20),
            Expanded(
              flex: 2,
              child: _buildOffIceRatingsCard(context),
            ),
            const SizedBox(width: 20),
            Expanded(
              flex: 1,
              child: _buildAgeSpecificRatingsCard(context),
            ),
          ],
        ),
        
        if (calculationError != null) ...[
          const SizedBox(height: 16),
          _buildErrorCard(context),
        ],
      ],
    );
  }

  // ============================================================================
  // HIRE SCORES HEADER
  // ============================================================================

  Widget _buildHIREScoresHeader(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                const Icon(Icons.assessment, size: 24),
                const SizedBox(width: 8),
                Text(
                  'HIRE Character Assessment',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const Spacer(),
                if (isCalculating)
                  const Row(
                    children: [
                      SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                      SizedBox(width: 8),
                      Text('Calculating...'),
                    ],
                  ),
              ],
            ),
            const SizedBox(height: 8),
            
            // Age group indicator
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: Theme.of(context).primaryColor.withOpacity(0.3),
                ),
              ),
              child: Text(
                '${AgeGroup.fromAge(playerAge).label} Player (Age $playerAge)',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).primaryColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // HIRE Score Circles
            context.responsive<Widget>(
              mobile: _buildMobileScoreRow(),
              tablet: _buildTabletScoreRow(),
              desktop: _buildDesktopScoreRow(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMobileScoreRow() {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            HIREScoreCircle(
              letter: 'H',
              label: 'Humility/Hardwork',
              score: ratings.hScore,
              isLoading: isCalculating,
              size: 80,
            ),
            HIREScoreCircle(
              letter: 'I',
              label: 'Initiative/Integrity',
              score: ratings.iScore,
              isLoading: isCalculating,
              size: 80,
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            HIREScoreCircle(
              letter: 'R',
              label: 'Responsibility/Respect',
              score: ratings.rScore,
              isLoading: isCalculating,
              size: 80,
            ),
            HIREScoreCircle(
              letter: 'E',
              label: 'Enthusiasm',
              score: ratings.eScore,
              isLoading: isCalculating,
              size: 80,
            ),
          ],
        ),
        const SizedBox(height: 16),
        HIREScoreCircle(
          letter: 'HIRE',
          label: 'Overall Score',
          score: ratings.overallHIREScore,
          isLoading: isCalculating,
          size: 100,
          isOverall: true,
        ),
      ],
    );
  }

  Widget _buildTabletScoreRow() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        HIREScoreCircle(
          letter: 'H',
          label: 'Humility/Hardwork',
          score: ratings.hScore,
          isLoading: isCalculating,
          size: 90,
        ),
        HIREScoreCircle(
          letter: 'I',
          label: 'Initiative/Integrity',
          score: ratings.iScore,
          isLoading: isCalculating,
          size: 90,
        ),
        HIREScoreCircle(
          letter: 'R',
          label: 'Responsibility/Respect',
          score: ratings.rScore,
          isLoading: isCalculating,
          size: 90,
        ),
        HIREScoreCircle(
          letter: 'E',
          label: 'Enthusiasm',
          score: ratings.eScore,
          isLoading: isCalculating,
          size: 90,
        ),
        HIREScoreCircle(
          letter: 'HIRE',
          label: 'Overall',
          score: ratings.overallHIREScore,
          isLoading: isCalculating,
          size: 110,
          isOverall: true,
        ),
      ],
    );
  }

  Widget _buildDesktopScoreRow() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        HIREScoreCircle(
          letter: 'H',
          label: 'Humility/Hardwork',
          score: ratings.hScore,
          isLoading: isCalculating,
          size: 100,
        ),
        HIREScoreCircle(
          letter: 'I',
          label: 'Initiative/Integrity',
          score: ratings.iScore,
          isLoading: isCalculating,
          size: 100,
        ),
        HIREScoreCircle(
          letter: 'R',
          label: 'Responsibility/Respect',
          score: ratings.rScore,
          isLoading: isCalculating,
          size: 100,
        ),
        HIREScoreCircle(
          letter: 'E',
          label: 'Enthusiasm',
          score: ratings.eScore,
          isLoading: isCalculating,
          size: 100,
        ),
        HIREScoreCircle(
          letter: 'HIRE',
          label: 'Overall',
          score: ratings.overallHIREScore,
          isLoading: isCalculating,
          size: 120,
          isOverall: true,
        ),
      ],
    );
  }

  // ============================================================================
  // RATING CATEGORY CARDS
  // ============================================================================

  Widget _buildOnIceRatingsCard(BuildContext context) {
    return _RatingCategoryCard(
      title: 'On-Ice Performance',
      icon: Icons.sports_hockey,
      ratings: [
        _RatingItem('hockeyIQ', 'Hockey IQ', ratings.hockeyIQ),
        _RatingItem('competitiveness', 'Competitiveness', ratings.competitiveness),
        _RatingItem('workEthic', 'Work Ethic', ratings.workEthic),
        _RatingItem('coachability', 'Coachability', ratings.coachability),
        _RatingItem('leadership', 'Leadership', ratings.leadership),
        _RatingItem('teamPlay', 'Team Play', ratings.teamPlay),
        _RatingItem('decisionMaking', 'Decision Making', ratings.decisionMaking),
        _RatingItem('adaptability', 'Adaptability', ratings.adaptability),
        _RatingItem('mentalToughness', 'Mental Toughness', ratings.mentalToughness),
      ],
      isCalculating: isCalculating,
      onRatingChanged: onRatingChanged,
    );
  }

  Widget _buildOffIceRatingsCard(BuildContext context) {
    return _RatingCategoryCard(
      title: 'Off-Ice Factors',
      icon: Icons.fitness_center,
      ratings: [
        _RatingItem('physicalFitness', 'Physical Fitness', ratings.physicalFitness),
        _RatingItem('nutritionHabits', 'Nutrition Habits', ratings.nutritionHabits),
        _RatingItem('sleepQuality', 'Sleep Quality', ratings.sleepQuality),
        _RatingItem('timeManagement', 'Time Management', ratings.timeManagement),
        _RatingItem('respectForOthers', 'Respect for Others', ratings.respectForOthers),
        _RatingItem('commitment', 'Commitment', ratings.commitment),
        _RatingItem('goalSetting', 'Goal Setting', ratings.goalSetting),
        _RatingItem('communicationSkills', 'Communication Skills', ratings.communicationSkills),
      ],
      isCalculating: isCalculating,
      onRatingChanged: onRatingChanged,
    );
  }

  Widget _buildAgeSpecificRatingsCard(BuildContext context) {
    final ageSpecificRatings = _getAgeSpecificRatings();
    
    if (ageSpecificRatings.isEmpty) {
      return const SizedBox.shrink();
    }

    final ageSpecificItems = ageSpecificRatings
        .map((item) => _RatingItem(item.key, item.label, item.value))
        .toList();

    final ageGroup = AgeGroup.fromAge(playerAge);
    String cardTitle;
    IconData cardIcon;

    switch (ageGroup) {
      case AgeGroup.youth:
        cardTitle = 'Youth Factors (Ages 8-12)';
        cardIcon = Icons.child_friendly;
        break;
      case AgeGroup.teen:
        cardTitle = 'Teen Factors (Ages 13-17)';
        cardIcon = Icons.school;
        break;
      case AgeGroup.adult:
        cardTitle = 'Adult Factors (Ages 18+)';
        cardIcon = Icons.work;
        break;
    }

    return _RatingCategoryCard(
      title: cardTitle,
      icon: cardIcon,
      ratings: ageSpecificItems,
      isCalculating: isCalculating,
      onRatingChanged: onRatingChanged,
    );
  }

  Widget _buildErrorCard(BuildContext context) {
    return Card(
      color: Colors.red.shade50,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(Icons.error, color: Colors.red.shade700),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Calculation Error',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.red.shade700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    calculationError!,
                    style: TextStyle(color: Colors.red.shade600),
                  ),
                ],
              ),
            ),
            if (onRetryCalculation != null) ...[
              const SizedBox(width: 12),
              TextButton.icon(
                onPressed: onRetryCalculation,
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
                style: TextButton.styleFrom(
                  foregroundColor: Colors.red.shade700,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // ============================================================================
  // AGE-SPECIFIC RATING HELPERS
  // ============================================================================

  List<_AgeSpecificRatingItem> _getAgeSpecificRatings() {
    final ageGroup = AgeGroup.fromAge(playerAge);
    final List<_AgeSpecificRatingItem> ageSpecificRatings = [];

    switch (ageGroup) {
      case AgeGroup.youth:
        // Youth (8-12) specific factors
        ageSpecificRatings.addAll([
          _AgeSpecificRatingItem('funEnjoyment', 'Fun & Enjoyment Level', _getRatingValue('funEnjoyment')),
          _AgeSpecificRatingItem('attentionSpan', 'Attention Span', _getRatingValue('attentionSpan')),
          _AgeSpecificRatingItem('followingInstructions', 'Following Instructions', _getRatingValue('followingInstructions')),
          _AgeSpecificRatingItem('sharing', 'Sharing & Teamwork', _getRatingValue('sharing')),
          _AgeSpecificRatingItem('equipmentCare', 'Equipment Care', _getRatingValue('equipmentCare')),
          _AgeSpecificRatingItem('parentSupport', 'Parent Support Level', _getRatingValue('parentSupport')),
        ]);
        break;
        
      case AgeGroup.teen:
        // Teen (13-17) specific factors
        ageSpecificRatings.addAll([
          _AgeSpecificRatingItem('academicPerformance', 'Academic Performance', _getRatingValue('academicPerformance')),
          _AgeSpecificRatingItem('socialMediaHabits', 'Social Media Habits', _getRatingValue('socialMediaHabits')),
          _AgeSpecificRatingItem('peerInfluence', 'Peer Influence Management', _getRatingValue('peerInfluence')),
          _AgeSpecificRatingItem('independence', 'Independence & Responsibility', _getRatingValue('independence')),
          _AgeSpecificRatingItem('substanceAwareness', 'Substance Awareness', _getRatingValue('substanceAwareness')),
          _AgeSpecificRatingItem('conflictResolution', 'Conflict Resolution', _getRatingValue('conflictResolution')),
        ]);
        break;
        
      case AgeGroup.adult:
        // Adult (18+) specific factors
        ageSpecificRatings.addAll([
          _AgeSpecificRatingItem('professionalBalance', 'Work/Career Balance', _getRatingValue('professionalBalance')),
          _AgeSpecificRatingItem('financialManagement', 'Financial Management', _getRatingValue('financialManagement')),
          _AgeSpecificRatingItem('familyCommitments', 'Family Commitments', _getRatingValue('familyCommitments')),
          _AgeSpecificRatingItem('careerPlanning', 'Hockey Career Planning', _getRatingValue('careerPlanning')),
          _AgeSpecificRatingItem('stressManagement', 'Stress Management', _getRatingValue('stressManagement')),
          _AgeSpecificRatingItem('longTermVision', 'Long-term Vision', _getRatingValue('longTermVision')),
        ]);
        break;
    }

    // Filter out any ratings that haven't been set (default is 5.0, so show all)
    return ageSpecificRatings.where((item) => item.value > 0).toList();
  }

  // FIXED: Updated _getRatingValue method with proper value conversion
  double _getRatingValue(String key) {
    // Use the getRatingValue method from HIREPlayerRatings
    final rawValue = ratings.getRatingValue(key);
    
    // Convert to double safely
    final doubleValue = rawValue.toDouble();
    
    // Check if value is in normalized range (0-1) and convert to UI range (1-10)
    if (doubleValue >= 0.0 && doubleValue <= 1.0) {
      // Convert from 0-1 to 1-10: value * 9 + 1
      return (doubleValue * 9.0 + 1.0).clamp(1.0, 10.0);
    }
    
    // Value is already in 1-10 range, just clamp it
    return doubleValue.clamp(1.0, 10.0);
  }

  String _formatRatingLabel(String key) {
    // Convert camelCase to readable labels
    return key.replaceAllMapped(
      RegExp(r'([A-Z])'),
      (match) => ' ${match.group(1)}',
    ).trim();
  }
}

// ============================================================================
// HIRE SCORE CIRCLE WIDGET
// ============================================================================

class HIREScoreCircle extends StatelessWidget {
  final String letter;
  final String label;
  final double score;
  final bool isLoading;
  final double size;
  final bool isOverall;

  const HIREScoreCircle({
    super.key,
    required this.letter,
    required this.label,
    required this.score,
    required this.isLoading,
    required this.size,
    this.isOverall = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = HockeyRatingsConfig.getColorForRating(score);
    
    return Column(
      children: [
        Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color.withOpacity(0.1),
            border: Border.all(
              color: color,
              width: isOverall ? 4 : 3,
            ),
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              if (isLoading)
                SizedBox(
                  width: size * 0.6,
                  height: size * 0.6,
                  child: CircularProgressIndicator(
                    color: color,
                    strokeWidth: 3,
                  ),
                )
              else
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      letter,
                      style: TextStyle(
                        fontSize: isOverall ? size * 0.15 : size * 0.2,
                        fontWeight: FontWeight.bold,
                        color: color,
                      ),
                    ),
                    if (score > 0) ...[
                      const SizedBox(height: 2),
                      Text(
                        score.toStringAsFixed(1),
                        style: TextStyle(
                          fontSize: size * 0.15,
                          fontWeight: FontWeight.w600,
                          color: color,
                        ),
                      ),
                    ],
                  ],
                ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          width: size + 20,
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              fontWeight: isOverall ? FontWeight.bold : FontWeight.normal,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

// ============================================================================
// ENHANCED HIRE RATING SLIDER WITH INFO ICON
// ============================================================================

class HIRERatingSlider extends StatelessWidget {
  final String label;
  final double value;
  final bool isCalculating;
  final ValueChanged<double> onChanged;
  final RatingFactor? ratingFactor; // NEW: Added rating factor for info display

  const HIRERatingSlider({
    super.key,
    required this.label,
    required this.value,
    required this.isCalculating,
    required this.onChanged,
    this.ratingFactor, // NEW: Optional rating factor
  });

  @override
  Widget build(BuildContext context) {
    final color = HockeyRatingsConfig.getColorForRating(value);
    final ratingLevel = HockeyRatingsConfig.getRatingLevel(value);
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
              // NEW: Info icon button
              if (ratingFactor != null)
                IconButton(
                  onPressed: () => _showRatingFactorInfo(context),
                  icon: Icon(
                    Icons.info_outline,
                    size: 20,
                    color: Theme.of(context).primaryColor.withOpacity(0.7),
                  ),
                  tooltip: 'Show rating information',
                  padding: const EdgeInsets.all(4),
                  constraints: const BoxConstraints(
                    minWidth: 32,
                    minHeight: 32,
                  ),
                ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: color.withOpacity(0.3)),
                ),
                child: Text(
                  value.toStringAsFixed(1),
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          
          // Rating level indicator
          Text(
            ratingLevel,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w500,
            ),
          ),
          
          const SizedBox(height: 8),
          
          Stack(
            children: [
              SliderTheme(
                data: SliderTheme.of(context).copyWith(
                  activeTrackColor: color,
                  inactiveTrackColor: color.withOpacity(0.3),
                  thumbColor: color,
                  overlayColor: color.withOpacity(0.2),
                  trackHeight: 6,
                  thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),
                ),
                child: Slider(
                  value: value,
                  min: 0.0,
                  max: 10.0,
                  divisions: 18, // 0.5 increments
                  onChanged: isCalculating ? null : onChanged,
                ),
              ),
              
              // Loading overlay
              if (isCalculating)
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.7),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Center(
                      child: SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  // NEW: Show rating factor information dialog
  void _showRatingFactorInfo(BuildContext context) {
    if (ratingFactor == null) return;

    showDialog(
      context: context,
      builder: (context) => RatingFactorInfoDialog(ratingFactor: ratingFactor!),
    );
  }
}

// ============================================================================
// NEW: RATING FACTOR INFO DIALOG
// ============================================================================

class RatingFactorInfoDialog extends StatelessWidget {
  final RatingFactor ratingFactor;

  const RatingFactorInfoDialog({
    super.key,
    required this.ratingFactor,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 600, maxHeight: 700),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor.withOpacity(0.1),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(8),
                  topRight: Radius.circular(8),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.assessment,
                        color: Theme.of(context).primaryColor,
                        size: 24,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          ratingFactor.title,
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).primaryColor,
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(Icons.close),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(
                          minWidth: 32,
                          minHeight: 32,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    ratingFactor.description,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
            
            // Content
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Why it matters section
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.blue.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: Colors.blue.withOpacity(0.2),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.lightbulb_outline,
                                color: Colors.blue[700],
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Why This Matters',
                                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.blue[700],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            ratingFactor.whyItMatters,
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ],
                      ),
                    ),
                    
                    const SizedBox(height: 20),
                    
                    // Rating scale descriptions
                    Text(
                      'Rating Scale Guide',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    
                    ...ratingFactor.scaleDescriptions.map((scale) => 
                      _buildScaleDescriptionItem(context, scale)
                    ),
                  ],
                ),
              ),
            ),
            
            // Footer
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(8),
                  bottomRight: Radius.circular(8),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Close'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildScaleDescriptionItem(BuildContext context, RatingScale scale) {
    final color = HockeyRatingsConfig.getColorForRating(scale.value.toDouble());
    
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: color.withOpacity(0.2),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Score circle
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                scale.value.toString(),
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          
          // Description
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  scale.label,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  scale.description,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// HIRE SCORES SIDEBAR
// ============================================================================

class HIREScoresSidebar extends StatelessWidget {
  final HIREPlayerRatings ratings;
  final bool isCalculating;
  final DateTime? lastCalculated;
  final VoidCallback? onRecalculate;
  final int playerAge;

  const HIREScoresSidebar({
    super.key,
    required this.ratings,
    required this.isCalculating,
    required this.playerAge,
    this.lastCalculated,
    this.onRecalculate,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // HIRE Scores Card
          _buildHIREScoresCard(context),
          const SizedBox(height: 16),
          
          // Component Breakdown
          _buildComponentBreakdownCard(context),
          const SizedBox(height: 16),
          
          // Age-Specific Insights
          _buildAgeSpecificInsightsCard(context),
          const SizedBox(height: 16),
          
          // Insights
          _buildInsightsCard(context),
          const SizedBox(height: 16),
          
          // Actions
          _buildActionsCard(context),
        ],
      ),
    );
  }

  Widget _buildHIREScoresCard(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  'HIRE Scores',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: Theme.of(context).primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'Age $playerAge',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).primaryColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            HIREScoreCircle(
              letter: 'HIRE',
              label: 'Overall Score',
              score: ratings.overallHIREScore,
              isLoading: isCalculating,
              size: 120,
              isOverall: true,
            ),
            
            const SizedBox(height: 16),
            
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildMiniScoreCircle('H', ratings.hScore),
                _buildMiniScoreCircle('I', ratings.iScore),
                _buildMiniScoreCircle('R', ratings.rScore),
                _buildMiniScoreCircle('E', ratings.eScore),
              ],
            ),
            
            if (lastCalculated != null) ...[
              const SizedBox(height: 16),
              Text(
                'Last updated: ${_formatDateTime(lastCalculated!)}',
                style: Theme.of(context).textTheme.bodySmall,
                textAlign: TextAlign.center,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildMiniScoreCircle(String letter, double score) {
    final color = HockeyRatingsConfig.getColorForRating(score);
    
    return Column(
      children: [
        Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color.withOpacity(0.1),
            border: Border.all(color: color, width: 2),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                letter,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              if (score > 0)
                Text(
                  score.toStringAsFixed(1),
                  style: TextStyle(
                    fontSize: 10,
                    color: color,
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildComponentBreakdownCard(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Component Breakdown',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            
            _buildComponentRow(context, 'Humility', ratings.humilityScore),
            _buildComponentRow(context, 'Hardwork', ratings.hardworkScore),
            const Divider(),
            _buildComponentRow(context, 'Initiative', ratings.initiativeScore),
            _buildComponentRow(context, 'Integrity', ratings.integrityScore),
            const Divider(),
            _buildComponentRow(context, 'Responsibility', ratings.responsibilityScore),
            _buildComponentRow(context, 'Respect', ratings.respectScore),
            const Divider(),
            _buildComponentRow(context, 'Enthusiasm', ratings.enthusiasmScore),
          ],
        ),
      ),
    );
  }

  Widget _buildComponentRow(BuildContext context, String label, double score) {
    final color = HockeyRatingsConfig.getColorForRating(score);
    
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: color.withOpacity(0.3)),
            ),
            child: Text(
              score.toStringAsFixed(1),
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAgeSpecificInsightsCard(BuildContext context) {
    final ageGroup = AgeGroup.fromAge(playerAge);
    final String ageGroupLabel = ageGroup.label;
    final String ageGroupDescription = _getAgeGroupDescription(ageGroup);
    final List<String> keyFocusAreas = _getKeyFocusAreas(ageGroup);
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  _getAgeGroupIcon(ageGroup),
                  size: 20,
                  color: Theme.of(context).primaryColor,
                ),
                const SizedBox(width: 8),
                Text(
                  '$ageGroupLabel Development Focus',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              ageGroupDescription,
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 12),
            Text(
              'Key Focus Areas:',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            ...keyFocusAreas.map((area) => 
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '• ',
                      style: TextStyle(
                        color: Theme.of(context).primaryColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Expanded(
                      child: Text(
                        area,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInsightsCard(BuildContext context) {
    final insights = DevelopmentInsights.fromRatings(ratings, playerAge);
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Development Insights',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            
            Text(
              'Level: ${insights.developmentLevel}',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            
            if (insights.characterStrengths.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(
                'Character Strengths:',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              ...insights.characterStrengths.map((strength) => Padding(
                padding: const EdgeInsets.only(left: 8, bottom: 2),
                child: Text(
                  '• $strength',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              )),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildActionsCard(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Actions',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            
            ElevatedButton.icon(
              onPressed: isCalculating ? null : onRecalculate,
              icon: isCalculating 
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.calculate),
              label: const Text('Recalculate Scores'),
            ),
            
            const SizedBox(height: 8),
            
            OutlinedButton.icon(
              onPressed: () => _showHIREMethodology(context),
              icon: const Icon(Icons.info_outline),
              label: const Text('HIRE Methodology'),
            ),

            const SizedBox(height: 8),
            
            OutlinedButton.icon(
              onPressed: () => _showAgeSpecificFactors(context),
              icon: Icon(_getAgeGroupIcon(AgeGroup.fromAge(playerAge))),
              label: Text('${AgeGroup.fromAge(playerAge).label} Factors'),
            ),

            const SizedBox(height: 8),
            
            OutlinedButton.icon(
              onPressed: () => _showDevelopmentRecommendations(context),
              icon: const Icon(Icons.lightbulb_outline),
              label: const Text('Development Tips'),
            ),
          ],
        ),
      ),
    );
  }

  IconData _getAgeGroupIcon(AgeGroup ageGroup) {
    switch (ageGroup) {
      case AgeGroup.youth:
        return Icons.child_friendly;
      case AgeGroup.teen:
        return Icons.school;
      case AgeGroup.adult:
        return Icons.work;
    }
  }

  String _getAgeGroupDescription(AgeGroup ageGroup) {
    switch (ageGroup) {
      case AgeGroup.youth:
        return 'Focus on fun, basic skills, and positive experiences. Building love for the game is priority #1.';
      case AgeGroup.teen:
        return 'Developing independence, handling peer pressure, and balancing multiple priorities while maintaining hockey excellence.';
      case AgeGroup.adult:
        return 'Managing life balance, career integration, and long-term hockey goals while juggling multiple responsibilities.';
    }
  }

  List<String> _getKeyFocusAreas(AgeGroup ageGroup) {
    switch (ageGroup) {
      case AgeGroup.youth:
        return [
          'Fun and enjoyment of the game',
          'Basic listening and instruction following',
          'Sharing and teamwork fundamentals',
          'Equipment care and responsibility',
          'Positive family support environment'
        ];
      case AgeGroup.teen:
        return [
          'Academic performance balance',
          'Responsible social media use',
          'Positive peer influence choices',
          'Independence and responsibility development',
          'Smart substance choices',
          'Conflict resolution skills'
        ];
      case AgeGroup.adult:
        return [
          'Work-hockey life balance',
          'Financial management of hockey expenses',
          'Family support and understanding',
          'Realistic hockey career planning',
          'Effective stress management',
          'Long-term vision maintenance'
        ];
    }
  }

  void _showHIREMethodology(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.assessment, size: 24),
            SizedBox(width: 8),
            Text('HIRE Methodology'),
          ],
        ),
        content: const SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'HIRE is an acronym representing core values that drive hockey excellence:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 12),
              Text('• H - Humility / Hardwork (25% of overall)'),
              Text('• I - Initiative / Integrity (30% of overall)'),
              Text('• R - Responsibility / Respect (25% of overall)'),
              Text('• E - Enthusiasm (20% of overall)'),
              SizedBox(height: 12),
              Text(
                'Each player receives ratings on a 1-10 scale across multiple factors, which are weighted and combined to create individual category scores and an overall HIRE composite score.',
              ),
              SizedBox(height: 12),
              Text(
                'Age-specific factors are included to ensure developmentally appropriate evaluation.',
                style: TextStyle(fontStyle: FontStyle.italic),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showAgeSpecificFactors(BuildContext context) {
    final ageGroup = AgeGroup.fromAge(playerAge);
    final factors = _getAgeSpecificFactorsList(ageGroup);
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(_getAgeGroupIcon(ageGroup), size: 24),
            const SizedBox(width: 8),
            Text('${ageGroup.label} Specific Factors'),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Additional factors evaluated for ${ageGroup.label.toLowerCase()} players (ages ${ageGroup.minAge}-${ageGroup.maxAge}):',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              ...factors.map((factor) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '• ${factor['title']!}',
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(left: 12, top: 2),
                      child: Text(
                        factor['description']!,
                        style: const TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                    ),
                    if (factor['whyItMatters'] != null) ...[
                      Padding(
                        padding: const EdgeInsets.only(left: 12, top: 2),
                        child: Text(
                          'Why it matters: ${factor['whyItMatters']!}',
                          style: const TextStyle(fontSize: 11, fontStyle: FontStyle.italic),
                        ),
                      ),
                    ],
                  ],
                ),
              )),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showDevelopmentRecommendations(BuildContext context) {
    final ageGroup = AgeGroup.fromAge(playerAge);
    final recommendations = _getDevelopmentRecommendations(ageGroup);
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.lightbulb_outline, size: 24),
            SizedBox(width: 8),
            Text('Development Recommendations'),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Recommended development focus for ${ageGroup.label.toLowerCase()} players:',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              ...recommendations.map((rec) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('• ', style: TextStyle(fontWeight: FontWeight.bold)),
                    Expanded(child: Text(rec)),
                  ],
                ),
              )),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  List<Map<String, String?>> _getAgeSpecificFactorsList(AgeGroup ageGroup) {
    switch (ageGroup) {
      case AgeGroup.youth:
        return [
          {
            'title': 'Fun & Enjoyment Level',
            'description': 'How much they love playing hockey and being at the rink',
            'whyItMatters': 'If kids don\'t enjoy hockey, they\'ll quit'
          },
          {
            'title': 'Attention Span',
            'description': 'Ability to focus during practices and listen to instruction',
            'whyItMatters': 'Young players need to focus to learn'
          },
          {
            'title': 'Following Instructions',
            'description': 'Listening to coaches and doing what is asked',
            'whyItMatters': 'Players who follow instructions learn faster'
          },
          {
            'title': 'Sharing & Teamwork',
            'description': 'Willingness to pass the puck and include teammates',
            'whyItMatters': 'Learning to share and work with teammates is essential'
          },
          {
            'title': 'Equipment Care',
            'description': 'Taking care of their gear and being responsible',
            'whyItMatters': 'Caring for equipment teaches responsibility'
          },
          {
            'title': 'Parent Support Level',
            'description': 'Positive family environment and encouragement',
            'whyItMatters': 'Family support is crucial for young players'
          },
        ];
      case AgeGroup.teen:
        return [
          {
            'title': 'Academic Performance',
            'description': 'Maintaining good grades and study habits',
            'whyItMatters': 'Academic failure can end hockey careers'
          },
          {
            'title': 'Social Media Habits',
            'description': 'Responsible use of social media and technology',
            'whyItMatters': 'Poor social media habits can damage reputation'
          },
          {
            'title': 'Peer Influence Management',
            'description': 'Choosing friends who support their hockey goals',
            'whyItMatters': 'Peer influence is huge during teen years'
          },
          {
            'title': 'Independence & Responsibility',
            'description': 'Taking ownership of their development and choices',
            'whyItMatters': 'Teens must learn independence to succeed'
          },
          {
            'title': 'Substance Awareness',
            'description': 'Making smart choices about alcohol, drugs, and substances',
            'whyItMatters': 'Substance issues can derail promising careers'
          },
          {
            'title': 'Conflict Resolution',
            'description': 'Handling disagreements and problems maturely',
            'whyItMatters': 'Teens face many conflicts. Learning to resolve them builds character'
          },
        ];
      case AgeGroup.adult:
        return [
          {
            'title': 'Work/Career Balance',
            'description': 'Managing career demands with hockey commitments',
            'whyItMatters': 'Adults must balance multiple priorities'
          },
          {
            'title': 'Financial Management',
            'description': 'Budgeting for hockey expenses and financial responsibility',
            'whyItMatters': 'Hockey is expensive. Good financial management ensures sustainable participation'
          },
          {
            'title': 'Family Commitments',
            'description': 'Balancing family responsibilities with hockey',
            'whyItMatters': 'Family support is crucial for adult players'
          },
          {
            'title': 'Hockey Career Planning',
            'description': 'Having realistic goals and plans for hockey future',
            'whyItMatters': 'Adults need realistic hockey goals to maintain motivation'
          },
          {
            'title': 'Stress Management',
            'description': 'Handling life pressures while maintaining performance',
            'whyItMatters': 'Adult life involves many stressors'
          },
          {
            'title': 'Long-term Vision',
            'description': 'Understanding hockey\'s role in their overall life plan',
            'whyItMatters': 'Adults with clear vision make better decisions about hockey investment'
          },
        ];
    }
  }

  List<String> _getDevelopmentRecommendations(AgeGroup ageGroup) {
    switch (ageGroup) {
      case AgeGroup.youth:
        return [
          'Prioritize fun and enjoyment over winning at all costs',
          'Develop basic listening and instruction-following skills',
          'Encourage sharing puck and including all teammates',
          'Build good equipment care habits and personal responsibility',
          'Maintain positive, supportive family environment around hockey',
          'Focus on effort and improvement rather than results',
          'Create positive memories and experiences with the game'
        ];
      case AgeGroup.teen:
        return [
          'Balance academic performance with hockey commitments',
          'Develop responsible social media habits and digital citizenship',
          'Choose positive peer influences who support hockey goals',
          'Build independence and personal responsibility skills',
          'Make smart choices about substances and peer pressure',
          'Learn healthy conflict resolution and communication skills',
          'Set realistic short and long-term hockey goals',
          'Develop time management and organizational skills'
        ];
      case AgeGroup.adult:
        return [
          'Create sustainable work-hockey balance that works long-term',
          'Manage hockey expenses responsibly within overall budget',
          'Build family support and understanding for hockey commitments',
          'Set realistic hockey career goals appropriate for life stage',
          'Develop effective stress management techniques',
          'Maintain long-term vision and motivation for continued play',
          'Network with other adult players for support and motivation',
          'Consider coaching or mentoring opportunities to give back'
        ];
    }
  }

  String _formatDateTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);
    
    if (difference.inMinutes < 1) {
      return 'just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes} minutes ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours} hours ago';
    } else {
      return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
    }
  }
}

// ============================================================================
// ENHANCED RATING CATEGORY CARD WITH PROPER FACTOR LOOKUP (UPDATED)
// ============================================================================

class _RatingCategoryCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final List<_RatingItem> ratings;
  final bool isCalculating;
  final Function(String key, double value) onRatingChanged;

  const _RatingCategoryCard({
    required this.title,
    required this.icon,
    required this.ratings,
    required this.isCalculating,
    required this.onRatingChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                if (isCalculating) ...[
                  const SizedBox(width: 8),
                  const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 16),
            
            ...ratings.map((rating) {
              // Get the rating factor for info display
              final ratingFactor = HockeyRatingsConfig.getFactor(rating.key);
              
              // FIXED: Ensure value is in correct UI range
              final displayValue = _convertToUIValue(rating.value);
              
              return HIRERatingSlider(
                label: rating.label,
                value: displayValue,
                isCalculating: isCalculating,
                onChanged: (value) => onRatingChanged(rating.key, value),
                ratingFactor: ratingFactor,
              );
            }),
          ],
        ),
      ),
    );
  }
  
  // FIXED: Helper method to ensure proper value conversion
  double _convertToUIValue(double value) {
    // Check if value is in normalized range (0-1) and convert to UI range (1-10)
    if (value >= 0.0 && value <= 1.0) {
      return (value * 9.0 + 1.0).clamp(1.0, 10.0);
    }
    
    // Value is already in 1-10 range
    return value.clamp(1.0, 10.0);
  }
}

// ============================================================================
// HELPER CLASSES
// ============================================================================

class _RatingItem {
  final String key;
  final String label;
  final double value;

  const _RatingItem(this.key, this.label, this.value);
}

class _AgeSpecificRatingItem {
  final String key;
  final String label;
  final double value;

  const _AgeSpecificRatingItem(this.key, this.label, this.value);
}