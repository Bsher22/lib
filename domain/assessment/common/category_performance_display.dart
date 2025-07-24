// widgets/assessment/common/category_performance_display.dart
import 'package:flutter/material.dart';
import 'package:hockey_shot_tracker/utils/skating_assessment_utils.dart';
import 'package:hockey_shot_tracker/widgets/standard_card.dart';
import 'package:hockey_shot_tracker/widgets/status_badge.dart';

/// A reusable widget for displaying performance metrics by category
class CategoryPerformanceDisplay extends StatelessWidget {
  /// Map of category names to score values (0-10)
  final Map<String, double> categoryScores;
  
  /// Optional list of categories to exclude from display (e.g., "Overall")
  final List<String> excludeCategories;
  
  /// Optional callback when a category is tapped
  final Function(String category, double score)? onCategoryTap;
  
  /// Optional custom text style for category names
  final TextStyle? categoryStyle;
  
  /// Optional custom text style for score values
  final TextStyle? scoreStyle;
  
  /// Whether to show badges for score values
  final bool showBadges;
  
  /// Whether to use card container
  final bool useCardContainer;
  
  /// Optional title for the card
  final String? cardTitle;
  
  const CategoryPerformanceDisplay({
    Key? key,
    required this.categoryScores,
    this.excludeCategories = const ['Overall'],
    this.onCategoryTap,
    this.categoryStyle,
    this.scoreStyle,
    this.showBadges = true,
    this.useCardContainer = false,
    this.cardTitle,
  }) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (cardTitle != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Text(
              cardTitle!,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.blueGrey[800],
              ),
            ),
          ),
        for (var entry in categoryScores.entries)
          if (!excludeCategories.contains(entry.key))
            _buildCategoryItem(context, entry.key, entry.value),
      ],
    );
    
    if (useCardContainer) {
      return StandardCard(
        padding: const EdgeInsets.all(16),
        child: content,
      );
    }
    
    return content;
  }
  
  Widget _buildCategoryItem(BuildContext context, String category, double score) {
    return InkWell(
      onTap: onCategoryTap != null 
          ? () => onCategoryTap!(category, score)
          : null,
      borderRadius: BorderRadius.circular(4),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  category,
                  style: categoryStyle ?? const TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                showBadges 
                    ? _buildScoreBadge(score)
                    : Text(
                        '${score.toStringAsFixed(1)}/10',
                        style: scoreStyle ?? TextStyle(
                          fontWeight: FontWeight.bold,
                          color: SkatingAssessmentUtils.getScoreColor(score),
                        ),
                      ),
              ],
            ),
            const SizedBox(height: 4),
            LinearProgressIndicator(
              value: score / 10,
              backgroundColor: Colors.grey[200],
              valueColor: AlwaysStoppedAnimation<Color>(
                SkatingAssessmentUtils.getScoreColor(score),
              ),
              minHeight: 8,
              borderRadius: BorderRadius.circular(4),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildScoreBadge(double score) {
    // Determine badge type based on score
    if (score >= 8.0) {
      return StatusBadge.success(
        text: '${score.toStringAsFixed(1)}/10',
        size: StatusBadgeSize.small,
        shape: StatusBadgeShape.pill,
      );
    } else if (score >= 6.0) {
      return StatusBadge(
        text: '${score.toStringAsFixed(1)}/10',
        color: Colors.green[500]!,
        size: StatusBadgeSize.small,
        shape: StatusBadgeShape.pill,
      );
    } else if (score >= 4.0) {
      return StatusBadge.warning(
        text: '${score.toStringAsFixed(1)}/10',
        size: StatusBadgeSize.small,
        shape: StatusBadgeShape.pill,
      );
    } else if (score >= 2.0) {
      return StatusBadge(
        text: '${score.toStringAsFixed(1)}/10',
        color: Colors.orange[700]!,
        size: StatusBadgeSize.small,
        shape: StatusBadgeShape.pill,
      );
    } else {
      return StatusBadge.error(
        text: '${score.toStringAsFixed(1)}/10',
        size: StatusBadgeSize.small,
        shape: StatusBadgeShape.pill,
      );
    }
  }
  
  /// Factory method for creating a card-based performance display
  factory CategoryPerformanceDisplay.asCard({
    required Map<String, double> categoryScores,
    required String title,
    List<String> excludeCategories = const ['Overall'],
    Function(String category, double score)? onCategoryTap,
    bool showBadges = true,
  }) {
    return CategoryPerformanceDisplay(
      categoryScores: categoryScores,
      excludeCategories: excludeCategories,
      onCategoryTap: onCategoryTap,
      showBadges: showBadges,
      useCardContainer: true,
      cardTitle: title,
    );
  }
}