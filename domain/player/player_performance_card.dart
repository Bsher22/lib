// lib/widgets/domain/player/player_performance_card.dart
import 'package:flutter/material.dart';
import 'package:hockey_shot_tracker/models/player.dart';
import 'package:hockey_shot_tracker/utils/skating_utils.dart';
import 'package:hockey_shot_tracker/utils/assessment_skating_utils.dart';
import 'package:hockey_shot_tracker/widgets/core/list/standard_card.dart';
import 'package:hockey_shot_tracker/widgets/core/list/status_badge.dart';

/// A reusable widget for displaying player performance metrics
class PlayerPerformanceCard extends StatelessWidget {
  /// The player to display
  final Player player;
  
  /// Map of category names to score values (0-10)
  final Map<String, double> categoryScores;
  
  /// Performance level of the player (e.g. "Elite", "Advanced")
  final String performanceLevel;
  
  /// Number of tests completed by the player
  final int completedTests;
  
  /// Total number of available tests
  final int totalTests;
  
  /// Optional callback when card is tapped
  final VoidCallback? onTap;
  
  const PlayerPerformanceCard({
    Key? key,
    required this.player,
    required this.categoryScores,
    required this.performanceLevel,
    required this.completedTests,
    required this.totalTests,
    this.onTap,
  }) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    final overallScore = categoryScores['Overall'] ?? 0.0;
    
    return StandardCard(
      borderRadius: 12,
      elevation: 2,
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Player header
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.cyanAccent[700],
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      player.jerseyNumber.toString(),
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        player.name,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        player.position ?? 'Unknown',
                        style: TextStyle(
                          color: Colors.blueGrey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                StatusBadge(
                  text: overallScore.toStringAsFixed(1),
                  color: SkatingUtils.getScoreColor(overallScore),
                  size: StatusBadgeSize.medium,
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 16),
            
            // Category scores
            Text(
              'Category Scores',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.blueGrey[700],
              ),
            ),
            const SizedBox(height: 8),
            Column(
              children: [
                for (var entry in categoryScores.entries)
                  if (entry.key != 'Overall')
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8.0),
                      child: Row(
                        children: [
                          Expanded(
                            flex: 2,
                            child: Text(entry.key),
                          ),
                          Expanded(
                            flex: 3,
                            child: LinearProgressIndicator(
                              value: entry.value / 10,
                              backgroundColor: Colors.grey[200],
                              valueColor: AlwaysStoppedAnimation<Color>(
                                SkatingUtils.getScoreColor(entry.value),
                              ),
                              minHeight: 8,
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            entry.value.toStringAsFixed(1),
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: SkatingUtils.getScoreColor(entry.value),
                            ),
                          ),
                        ],
                      ),
                    ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // Player performance level
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.emoji_events,
                    color: SkatingUtils.getScoreColor(overallScore),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Performance Level',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          performanceLevel,
                          style: TextStyle(
                            color: SkatingUtils.getScoreColor(overallScore),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Completion status
            Text(
              'Tests Completed: $completedTests of $totalTests',
              style: TextStyle(
                fontStyle: FontStyle.italic,
                color: Colors.blueGrey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }
}