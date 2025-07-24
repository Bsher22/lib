// lib/widgets/domain/player/player_details_dialog.dart
import 'package:flutter/material.dart';
import 'package:hockey_shot_tracker/models/player.dart';
import 'package:hockey_shot_tracker/models/skating_assessment.dart';
import 'package:hockey_shot_tracker/widgets/domain/assessment/common/category_performance_display.dart';
import 'package:hockey_shot_tracker/services/dialog_service.dart';

class PlayerDetailsDialog extends StatelessWidget {
  final Player player;
  final SkatingAssessmentResults assessmentResults;
  final Map<String, SkatingTestResult> testResults;
  final int totalTests;
  final Function(String)? onCategorySelected;
  final VoidCallback? onViewFullReport;
  
  const PlayerDetailsDialog({
    Key? key,
    required this.player,
    required this.assessmentResults,
    required this.testResults,
    required this.totalTests,
    this.onCategorySelected,
    this.onViewFullReport,
  }) : super(key: key);
  
  static void show(
    BuildContext context, {
    required Player player,
    required SkatingAssessmentResults assessmentResults,
    required Map<String, SkatingTestResult> testResults,
    required int totalTests,
    Function(String)? onCategorySelected,
    VoidCallback? onViewFullReport,
  }) {
    // Use the DialogService to show a custom dialog with our content
    DialogService.showCustom(
      context,
      content: PlayerDetailsDialog(
        player: player,
        assessmentResults: assessmentResults,
        testResults: testResults,
        totalTests: totalTests,
        onCategorySelected: onCategorySelected,
        onViewFullReport: onViewFullReport,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: MediaQuery.of(context).size.width * 0.8,
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Dialog header with player info
          Row(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: Colors.cyanAccent[700],
                child: Text(
                  player.jerseyNumber.toString(),
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    fontSize: 16,
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
                        fontSize: 18,
                      ),
                    ),
                    Text(
                      player.position,
                      style: TextStyle(
                        color: Colors.blueGrey[600],
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.close),
              ),
            ],
          ),
          
          const Divider(height: 24),
          
          // Scrollable content area
          ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.6,
            ),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Performance overview
                  Text(
                    'Performance Overview',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.blueGrey[800],
                    ),
                  ),
                  const SizedBox(height: 12),
                  
                  // Performance stats
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildStatBadge(
                        'Overall',
                        assessmentResults.categoryScores['Overall']?.toStringAsFixed(1) ?? '0.0',
                        Colors.blue,
                      ),
                      _buildStatBadge(
                        'Tests',
                        '${testResults.length}/$totalTests',
                        Colors.green,
                      ),
                      _buildStatBadge(
                        'Level',
                        assessmentResults.performanceLevel,
                        Colors.orange,
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Category breakdown
                  Text(
                    'Category Performance',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.blueGrey[800],
                    ),
                  ),
                  const SizedBox(height: 12),
                  CategoryPerformanceDisplay(
                    categoryScores: assessmentResults.categoryScores,
                    onCategoryTap: onCategorySelected != null 
                        ? (category, score) {
                            Navigator.of(context).pop();
                            onCategorySelected!(category);
                          }
                        : null,
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Strengths and weaknesses
                  Text(
                    'Player Analysis',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.blueGrey[800],
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildPlayerAnalysis(),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Action buttons
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Close'),
              ),
              const SizedBox(width: 8),
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.of(context).pop();
                  
                  if (onViewFullReport != null) {
                    onViewFullReport!();
                  }
                },
                icon: const Icon(Icons.analytics),
                label: const Text('View Full Report'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.cyanAccent[700],
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
  
  Widget _buildStatBadge(String label, String value, Color color) {
    return Column(
      children: [
        Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            shape: BoxShape.circle,
            border: Border.all(color: color),
          ),
          child: Center(
            child: Text(
              value,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: color,
                fontSize: 14,
              ),
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.blueGrey[700],
          ),
        ),
      ],
    );
  }
  
  Widget _buildPlayerAnalysis() {
    // Find strengths and weaknesses
    final categoryScores = Map.of(assessmentResults.categoryScores);
    categoryScores.remove('Overall');
    
    final sortedScores = categoryScores.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    
    final strengths = sortedScores.take(2).where((e) => e.value >= 7.0).toList();
    final weaknesses = sortedScores.reversed.take(2).where((e) => e.value <= 6.0).toList();
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Strengths
        Text(
          'Strengths',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.green[700],
          ),
        ),
        const SizedBox(height: 4),
        if (strengths.isEmpty)
          Text(
            'No standout strengths identified',
            style: TextStyle(
              fontStyle: FontStyle.italic,
              color: Colors.blueGrey[600],
              fontSize: 12,
            ),
          )
        else
          for (var strength in strengths)
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(
                children: [
                  const Icon(Icons.check_circle, color: Colors.green, size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '${strength.key} (${strength.value.toStringAsFixed(1)})',
                      style: const TextStyle(fontSize: 14),
                    ),
                  ),
                ],
              ),
            ),
        
        const SizedBox(height: 12),
        
        // Weaknesses
        Text(
          'Areas for Development',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.orange[700],
          ),
        ),
        const SizedBox(height: 4),
        if (weaknesses.isEmpty)
          Text(
            'No specific development areas identified',
            style: TextStyle(
              fontStyle: FontStyle.italic,
              color: Colors.blueGrey[600],
              fontSize: 12,
            ),
          )
        else
          for (var weakness in weaknesses)
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(
                children: [
                  const Icon(Icons.trending_up, color: Colors.orange, size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '${weakness.key} (${weakness.value.toStringAsFixed(1)})',
                      style: const TextStyle(fontSize: 14),
                    ),
                  ),
                ],
              ),
            ),
      ],
    );
  }
}