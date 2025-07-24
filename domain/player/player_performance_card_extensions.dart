import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/player.dart';
import '../assessment/common/player_details_dialog.dart';
import '../../providers/assessment_provider.dart';
import '../../providers/app_state.dart';
import './player_performance_card.dart';

/// Extension methods for PlayerPerformanceCard
extension PlayerPerformanceCardExtension on PlayerPerformanceCard {
  /// Show detailed performance dialog
  void showDetailsDialog(BuildContext context) {
    final appState = Provider.of<AppState>(context, listen: false);
    final assessmentProvider = Provider.of<AssessmentProvider>(context, listen: false);
    
    // Show the player details dialog
    showDialog(
      context: context,
      builder: (context) => PlayerDetailsDialog(
        player: player,
        categoryScores: categoryScores,
        performanceLevel: performanceLevel,
        completedTests: completedTests,
        totalTests: totalTests,
        onViewFullReport: () {
          Navigator.pop(context);
          // Navigate to full report screen 
          Navigator.pushNamed(
            context, 
            '/player/${player.id}/report',
            arguments: player,
          );
        },
        onCategorySelected: (category) {
          Navigator.pop(context);
          // Navigate to category details
          Navigator.pushNamed(
            context,
            '/player/${player.id}/category/$category',
            arguments: {
              'player': player,
              'category': category
            },
          );
        },
      ),
    );
  }
  
  /// Navigate to player stats screen
  void navigateToStats(BuildContext context) {
    Navigator.pushNamed(
      context,
      '/player/${player.id}/stats',
      arguments: player,
    );
  }
}