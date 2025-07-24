// lib/widgets/domain/assessment/team_skating/team_skating_summary_tab.dart
// PHASE 4: Updated with full responsiveness following established patterns
import 'package:flutter/material.dart';
import 'package:hockey_shot_tracker/models/player.dart';
import 'package:hockey_shot_tracker/utils/skating_utils.dart';
import 'package:hockey_shot_tracker/widgets/domain/analysis/charts/radar_chart_widget.dart';
import 'package:hockey_shot_tracker/widgets/domain/assessment/common/performance_level_badge.dart';
import 'package:hockey_shot_tracker/responsive_system/index.dart';

class TeamSkatingSummaryTab extends StatelessWidget {
  final String teamName;
  final List<Player> players;
  final Map<String, Map<String, dynamic>> playerResults;
  final Map<String, double> teamAverages;
  final Map<String, Map<String, dynamic>> playerTestResults;

  const TeamSkatingSummaryTab({
    Key? key,
    required this.teamName,
    required this.players,
    required this.playerResults,
    required this.teamAverages,
    required this.playerTestResults,
  }) : super(key: key);

  String _getPerformanceLevel(double score) {
    if (score >= 8.5) return 'Elite';
    if (score >= 7.0) return 'Advanced';
    if (score >= 5.5) return 'Proficient';
    if (score >= 4.0) return 'Developing';
    if (score >= 2.5) return 'Basic';
    return 'Beginner';
  }

  @override
  Widget build(BuildContext context) {
    return AdaptiveLayout(
      builder: (deviceType, isLandscape) {
        switch (deviceType) {
          case DeviceType.mobile:
            return _buildMobileLayout(context);
          case DeviceType.tablet:
            return _buildTabletLayout(context);
          case DeviceType.desktop:
            return _buildDesktopLayout(context);
        }
      },
    );
  }

  // 📱 MOBILE LAYOUT: Vertical stack with essential information
  Widget _buildMobileLayout(BuildContext context) {
    return SingleChildScrollView(
      child: Padding(
        padding: ResponsiveConfig.paddingAll(context, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildTeamSummary(context),
            ResponsiveSpacing(multiplier: 2.5),
            _buildMobileCategoryBreakdown(context),
            ResponsiveSpacing(multiplier: 2.5),
            _buildTopPerformers(context),
            ResponsiveSpacing(multiplier: 2.5),
            _buildAreasForImprovement(context),
            ResponsiveSpacing(multiplier: 2.5),
            _buildMobilePlayerCards(context),
          ],
        ),
      ),
    );
  }

  // 📱 TABLET LAYOUT: Two-column layout with charts
  Widget _buildTabletLayout(BuildContext context) {
    return SingleChildScrollView(
      child: Padding(
        padding: ResponsiveConfig.paddingAll(context, 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildTeamSummary(context),
            ResponsiveSpacing(multiplier: 3),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: _buildCategoryBreakdown(context)),
                ResponsiveSpacing(multiplier: 2.5, direction: Axis.horizontal),
                Expanded(child: _buildTopPerformers(context)),
              ],
            ),
            ResponsiveSpacing(multiplier: 3),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: _buildAreasForImprovement(context)),
                ResponsiveSpacing(multiplier: 2.5, direction: Axis.horizontal),
                Expanded(child: _buildTeamInsights(context)),
              ],
            ),
            ResponsiveSpacing(multiplier: 3),
            _buildPlayerGrid(context),
          ],
        ),
      ),
    );
  }

  // 🖥️ DESKTOP LAYOUT: Three-column comprehensive view
  Widget _buildDesktopLayout(BuildContext context) {
    return SingleChildScrollView(
      child: Padding(
        padding: ResponsiveConfig.paddingAll(context, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildTeamSummary(context),
            ResponsiveSpacing(multiplier: 4),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 2,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _buildCategoryBreakdown(context),
                      ResponsiveSpacing(multiplier: 3),
                      _buildAreasForImprovement(context),
                    ],
                  ),
                ),
                ResponsiveSpacing(multiplier: 3, direction: Axis.horizontal),
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _buildTopPerformers(context),
                      ResponsiveSpacing(multiplier: 3),
                      _buildTeamInsights(context),
                    ],
                  ),
                ),
                ResponsiveSpacing(multiplier: 3, direction: Axis.horizontal),
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _buildPerformanceDistribution(context),
                      ResponsiveSpacing(multiplier: 3),
                      _buildQuickStats(context),
                    ],
                  ),
                ),
              ],
            ),
            ResponsiveSpacing(multiplier: 4),
            _buildPlayerGrid(context),
          ],
        ),
      ),
    );
  }

  // SHARED COMPONENTS
  Widget _buildTeamSummary(BuildContext context) {
    double overallScore = teamAverages['skating_Overall'] ?? 0.0;

    if (overallScore == 0.0) {
      double total = 0;
      int count = 0;

      for (var result in playerResults.values) {
        final categoryScores = result['categoryScores'] as Map<String, dynamic>?;
        if (categoryScores != null && categoryScores.containsKey('Overall')) {
          total += (categoryScores['Overall'] as num).toDouble();
          count++;
        }
      }

      if (count > 0) {
        overallScore = total / count;
      }
    }

    int totalPlayers = playerResults.length;
    int playersWithAdvancedSkills = 0;
    int playersWithProficientSkills = 0;
    int playersNeedingDevelopment = 0;

    for (var result in playerResults.values) {
      final categoryScores = result['categoryScores'] as Map<String, dynamic>?;
      final playerScore = categoryScores != null
          ? (categoryScores['Overall'] as num?)?.toDouble() ?? 0.0
          : 0.0;

      if (playerScore >= 7.0) {
        playersWithAdvancedSkills++;
      } else if (playerScore >= 5.5) {
        playersWithProficientSkills++;
      } else {
        playersNeedingDevelopment++;
      }
    }

    return ResponsiveCard(
      baseBorderRadius: 12,
      elevation: 2,
      padding: ResponsiveConfig.paddingAll(context, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          ResponsiveText(
            'Team Skating Overview',
            baseFontSize: 16,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.blueGrey[800],
            ),
          ),
          ResponsiveSpacing(multiplier: 2),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ResponsiveText(
                      'Overall Skating Score',
                      baseFontSize: 14,
                      style: TextStyle(
                        color: Colors.blueGrey[700],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    ResponsiveText(
                      overallScore.toStringAsFixed(1),
                      baseFontSize: 36,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: SkatingUtils.getScoreColor(overallScore),
                      ),
                    ),
                    ResponsiveSpacing(multiplier: 1),
                    PerformanceLevelBadge(
                      level: _getPerformanceLevel(overallScore),
                      color: SkatingUtils.getScoreColor(overallScore),
                    ),
                  ],
                ),
              ),
              ResponsiveSpacing(multiplier: 2, direction: Axis.horizontal),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ResponsiveText(
                      'Player Distribution',
                      baseFontSize: 14,
                      style: TextStyle(
                        color: Colors.blueGrey[700],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    ResponsiveSpacing(multiplier: 1),
                    _buildPlayerStatRow(
                      context,
                      'Advanced+',
                      playersWithAdvancedSkills,
                      totalPlayers,
                      Colors.green,
                    ),
                    ResponsiveSpacing(multiplier: 0.5),
                    _buildPlayerStatRow(
                      context,
                      'Proficient',
                      playersWithProficientSkills,
                      totalPlayers,
                      Colors.blue,
                    ),
                    ResponsiveSpacing(multiplier: 0.5),
                    _buildPlayerStatRow(
                      context,
                      'Developing',
                      playersNeedingDevelopment,
                      totalPlayers,
                      Colors.orange,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPlayerStatRow(BuildContext context, String label, int count, int total, Color color) {
    final percentage = total > 0 ? count / total * 100 : 0;

    return Row(
      children: [
        Container(
          width: ResponsiveConfig.dimension(context, 12),
          height: ResponsiveConfig.dimension(context, 12),
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        ResponsiveSpacing(multiplier: 1, direction: Axis.horizontal),
        Expanded(
          child: ResponsiveText(
            label,
            baseFontSize: 14,
            style: TextStyle(color: Colors.blueGrey[800]),
          ),
        ),
        ResponsiveText(
          '$count (${percentage.toInt()}%)',
          baseFontSize: 14,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  // MOBILE-SPECIFIC COMPONENTS
  Widget _buildMobileCategoryBreakdown(BuildContext context) {
    final Map<String, double> categoryScores = {};

    for (var key in teamAverages.keys) {
      if (key.startsWith('skating_') && key != 'skating_Overall') {
        final category = key.replaceAll('skating_', '');
        categoryScores[category] = teamAverages[key]!;
      }
    }

    if (categoryScores.isEmpty) {
      final Set<String> categories = {};
      for (var result in playerResults.values) {
        final playerCategoryScores = result['categoryScores'] as Map<String, dynamic>?;
        if (playerCategoryScores != null) {
          categories.addAll(playerCategoryScores.keys.whereType<String>());
        }
      }

      for (var category in categories) {
        if (category != 'Overall') {
          double sum = 0;
          int count = 0;

          for (var result in playerResults.values) {
            final playerCategoryScores = result['categoryScores'] as Map<String, dynamic>?;
            if (playerCategoryScores != null && playerCategoryScores.containsKey(category)) {
              final value = playerCategoryScores[category];
              if (value is num) {
                sum += value.toDouble();
                count++;
              }
            }
          }

          if (count > 0) {
            categoryScores[category] = sum / count;
          }
        }
      }
    }

    if (categoryScores.isEmpty) {
      return ResponsiveCard(
        baseBorderRadius: 12,
        elevation: 2,
        padding: ResponsiveConfig.paddingAll(context, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.analytics, color: Colors.grey[400], size: ResponsiveConfig.iconSize(context, 48)),
            ResponsiveSpacing(multiplier: 2),
            ResponsiveText(
              'Category Breakdown Unavailable',
              baseFontSize: 16,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.grey[600],
              ),
            ),
            ResponsiveSpacing(multiplier: 1),
            ResponsiveText(
              'Category-specific data is not available for this assessment.',
              baseFontSize: 14,
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[600]),
            ),
          ],
        ),
      );
    }

    return ResponsiveCard(
      baseBorderRadius: 12,
      elevation: 2,
      padding: ResponsiveConfig.paddingAll(context, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          ResponsiveText(
            'Team Skill Breakdown',
            baseFontSize: 16,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.blueGrey[800],
            ),
          ),
          ResponsiveSpacing(multiplier: 2),
          ...categoryScores.entries.map((entry) {
            final category = entry.key;
            final score = entry.value;
            
            return Padding(
              padding: ResponsiveConfig.paddingSymmetric(context, vertical: 6),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      ResponsiveText(
                        category,
                        baseFontSize: 14,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      ResponsiveText(
                        score.toStringAsFixed(1),
                        baseFontSize: 14,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: SkatingUtils.getScoreColor(score),
                        ),
                      ),
                    ],
                  ),
                  ResponsiveSpacing(multiplier: 0.5),
                  LinearProgressIndicator(
                    value: score / 10,
                    backgroundColor: Colors.grey[200],
                    valueColor: AlwaysStoppedAnimation<Color>(
                      SkatingUtils.getScoreColor(score),
                    ),
                    minHeight: ResponsiveConfig.dimension(context, 8),
                  ),
                ],
              ),
            );
          }).toList(),
        ],
      ),
    );
  }

  Widget _buildMobilePlayerCards(BuildContext context) {
    return ResponsiveCard(
      baseBorderRadius: 12,
      elevation: 2,
      padding: ResponsiveConfig.paddingAll(context, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          ResponsiveText(
            'Player Results',
            baseFontSize: 16,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.blueGrey[800],
            ),
          ),
          ResponsiveSpacing(multiplier: 2),
          ...players.map((player) {
            final playerId = player.id.toString();
            final results = playerResults[playerId];
            
            if (results != null) {
              final testResultsForPlayer = playerTestResults[playerId] ?? {};
              
              final categoryScoresMap = results['categoryScores'];
              final Map<String, double> scores = {};
              
              if (categoryScoresMap is Map<String, dynamic>) {
                categoryScoresMap.forEach((key, value) {
                  if (value is num) {
                    scores[key] = value.toDouble();
                  }
                });
              }

              return TeamPlayerCard(
                player: player,
                testResults: testResultsForPlayer,
                scores: scores,
                createdAt: DateTime.now(),
              );
            }
            return const SizedBox.shrink();
          }).where((widget) => widget is! SizedBox),
        ],
      ),
    );
  }

  // TABLET/DESKTOP COMPONENTS
  Widget _buildCategoryBreakdown(BuildContext context) {
    final Map<String, double> categoryScores = {};

    for (var key in teamAverages.keys) {
      if (key.startsWith('skating_') && key != 'skating_Overall') {
        final category = key.replaceAll('skating_', '');
        categoryScores[category] = teamAverages[key]!;
      }
    }

    if (categoryScores.isEmpty) {
      final Set<String> categories = {};
      for (var result in playerResults.values) {
        final playerCategoryScores = result['categoryScores'] as Map<String, dynamic>?;
        if (playerCategoryScores != null) {
          categories.addAll(playerCategoryScores.keys.whereType<String>());
        }
      }

      for (var category in categories) {
        if (category != 'Overall') {
          double sum = 0;
          int count = 0;

          for (var result in playerResults.values) {
            final playerCategoryScores = result['categoryScores'] as Map<String, dynamic>?;
            if (playerCategoryScores != null && playerCategoryScores.containsKey(category)) {
              final value = playerCategoryScores[category];
              if (value is num) {
                sum += value.toDouble();
                count++;
              }
            }
          }

          if (count > 0) {
            categoryScores[category] = sum / count;
          }
        }
      }
    }

    if (categoryScores.isEmpty) {
      return ResponsiveCard(
        baseBorderRadius: 12,
        elevation: 2,
        padding: ResponsiveConfig.paddingAll(context, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.analytics, color: Colors.grey[400], size: ResponsiveConfig.iconSize(context, 48)),
            ResponsiveSpacing(multiplier: 2),
            ResponsiveText(
              'Category Breakdown Unavailable',
              baseFontSize: 16,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.grey[600],
              ),
            ),
            ResponsiveSpacing(multiplier: 1),
            ResponsiveText(
              'Category-specific data is not available for this assessment.',
              baseFontSize: 14,
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[600]),
            ),
          ],
        ),
      );
    }

    return ResponsiveCard(
      baseBorderRadius: 12,
      elevation: 2,
      padding: ResponsiveConfig.paddingAll(context, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          ResponsiveText(
            'Team Skill Breakdown',
            baseFontSize: 16,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.blueGrey[800],
            ),
          ),
          ResponsiveSpacing(multiplier: 2),
          AspectRatio(
            aspectRatio: 1.5,
            child: RadarChartWidget(
              dataPoints: categoryScores,
              comparisonDataPoints: null,
              title: 'Team Skills',
              subtitle: 'Skating performance by category',
              primaryColor: Colors.blue,
              secondaryColor: Colors.grey,
              primaryLabel: 'Team Average',
              secondaryLabel: '',
              maxValue: 10.0,
              normalizeValues: true,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopPerformers(BuildContext context) {
    final sortedPlayers = playerResults.entries.toList()
      ..sort((a, b) {
        final aCategoryScores = a.value['categoryScores'] as Map<String, dynamic>?;
        final aScore = aCategoryScores != null 
            ? (aCategoryScores['Overall'] as num?)?.toDouble() ?? 0.0
            : 0.0;
            
        final bCategoryScores = b.value['categoryScores'] as Map<String, dynamic>?;
        final bScore = bCategoryScores != null 
            ? (bCategoryScores['Overall'] as num?)?.toDouble() ?? 0.0
            : 0.0;
            
        return bScore.compareTo(aScore);
      });

    final topPlayers = sortedPlayers.take(3).toList();

    return ResponsiveCard(
      baseBorderRadius: 12,
      elevation: 2,
      padding: ResponsiveConfig.paddingAll(context, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          ResponsiveText(
            'Top Performers',
            baseFontSize: 16,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.blueGrey[800],
            ),
          ),
          ResponsiveSpacing(multiplier: 2),
          ...topPlayers.map((entry) {
            final playerName = entry.value['playerName'] as String? ?? _getPlayerName(entry.key);
            final categoryScores = entry.value['categoryScores'] as Map<String, dynamic>?;
            final score = categoryScores != null
                ? (categoryScores['Overall'] as num?)?.toDouble() ?? 0.0
                : 0.0;

            final List<MapEntry<String, dynamic>> sortedCategories = [];
            if (categoryScores != null) {
              sortedCategories.addAll(
                categoryScores.entries
                    .where((e) => e.key != 'Overall' && e.value is num)
                    .toList(),
              );
              sortedCategories.sort((a, b) => (b.value as num).toDouble().compareTo((a.value as num).toDouble()));
            }

            final topStrengths = sortedCategories.take(2).map((e) => e.key).join(', ');

            return Padding(
              padding: ResponsiveConfig.paddingSymmetric(context, vertical: 6),
              child: Row(
                children: [
                  CircleAvatar(
                    backgroundColor: SkatingUtils.getScoreColor(score).withOpacity(0.2),
                    child: ResponsiveText(
                      playerName.isNotEmpty ? playerName.substring(0, 1).toUpperCase() : '?',
                      baseFontSize: 14,
                      style: TextStyle(
                        color: SkatingUtils.getScoreColor(score),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  ResponsiveSpacing(multiplier: 1.5, direction: Axis.horizontal),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        ResponsiveText(
                          playerName,
                          baseFontSize: 14,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        if (topStrengths.isNotEmpty)
                          ResponsiveText(
                            'Strengths: $topStrengths',
                            baseFontSize: 12,
                            style: TextStyle(color: Colors.blueGrey[600]),
                          ),
                      ],
                    ),
                  ),
                  Container(
                    padding: ResponsiveConfig.paddingSymmetric(context, horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: SkatingUtils.getScoreColor(score).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: ResponsiveText(
                      score.toStringAsFixed(1),
                      baseFontSize: 12,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: SkatingUtils.getScoreColor(score),
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildAreasForImprovement(BuildContext context) {
    final Map<String, double> categoryAverages = {};
    final Map<String, int> categoryCounts = {};

    for (var result in playerResults.values) {
      final categoryScores = result['categoryScores'] as Map<String, dynamic>?;
      if (categoryScores != null) {
        for (var entry in categoryScores.entries) {
          if (entry.key != 'Overall' && entry.value is num) {
            final key = entry.key;
            final value = (entry.value as num).toDouble();
            
            categoryAverages[key] = (categoryAverages[key] ?? 0) + value;
            categoryCounts[key] = (categoryCounts[key] ?? 0) + 1;
          }
        }
      }
    }

    for (var category in categoryAverages.keys) {
      final count = categoryCounts[category] ?? 1;
      categoryAverages[category] = categoryAverages[category]! / count;
    }

    final lowestCategories = categoryAverages.entries.toList()
      ..sort((a, b) => a.value.compareTo(b.value));

    final improvementAreas = lowestCategories.take(3).toList();

    return ResponsiveCard(
      baseBorderRadius: 12,
      elevation: 2,
      padding: ResponsiveConfig.paddingAll(context, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          ResponsiveText(
            'Areas for Team Improvement',
            baseFontSize: 16,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.blueGrey[800],
            ),
          ),
          ResponsiveSpacing(multiplier: 2),
          if (improvementAreas.isEmpty)
            ResponsiveText(
              'No specific areas identified for improvement',
              baseFontSize: 14,
              style: TextStyle(
                fontStyle: FontStyle.italic,
                color: Colors.blueGrey[600],
              ),
            )
          else
            ...improvementAreas.map((entry) {
              final category = entry.key;
              final score = entry.value;

              return Padding(
                padding: ResponsiveConfig.paddingSymmetric(context, vertical: 6),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ResponsiveText(
                      category,
                      baseFontSize: 14,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    ResponsiveSpacing(multiplier: 0.5),
                    Row(
                      children: [
                        Expanded(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                              value: score / 10,
                              backgroundColor: Colors.grey[200],
                              valueColor: AlwaysStoppedAnimation<Color>(
                                SkatingUtils.getScoreColor(score),
                              ),
                              minHeight: ResponsiveConfig.dimension(context, 8),
                            ),
                          ),
                        ),
                        ResponsiveSpacing(multiplier: 1, direction: Axis.horizontal),
                        ResponsiveText(
                          score.toStringAsFixed(1),
                          baseFontSize: 12,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: SkatingUtils.getScoreColor(score),
                          ),
                        ),
                      ],
                    ),
                    ResponsiveSpacing(multiplier: 0.5),
                    ResponsiveText(
                      _getImprovementSuggestion(category),
                      baseFontSize: 12,
                      style: TextStyle(
                        color: Colors.blueGrey[600],
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }

  // DESKTOP-SPECIFIC COMPONENTS
  Widget _buildTeamInsights(BuildContext context) {
    final overallScore = _calculateTeamOverallScore();
    final insights = _generateTeamInsights(overallScore);
    
    return ResponsiveCard(
      baseBorderRadius: 12,
      elevation: 2,
      padding: ResponsiveConfig.paddingAll(context, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Icon(Icons.lightbulb, color: Colors.amber[600]),
              ResponsiveSpacing(multiplier: 1, direction: Axis.horizontal),
              ResponsiveText(
                'Team Insights',
                baseFontSize: 16,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.blueGrey[800],
                ),
              ),
            ],
          ),
          ResponsiveSpacing(multiplier: 2),
          ...insights.map((insight) => Padding(
            padding: ResponsiveConfig.paddingSymmetric(context, vertical: 6),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: ResponsiveConfig.dimension(context, 4),
                  height: ResponsiveConfig.dimension(context, 4),
                  margin: ResponsiveConfig.paddingSymmetric(context, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.amber[600],
                    shape: BoxShape.circle,
                  ),
                ),
                ResponsiveSpacing(multiplier: 1, direction: Axis.horizontal),
                Expanded(
                  child: ResponsiveText(
                    insight,
                    baseFontSize: 13,
                    style: TextStyle(
                      color: Colors.blueGrey[700],
                      height: 1.3,
                    ),
                  ),
                ),
              ],
            ),
          )),
        ],
      ),
    );
  }

  Widget _buildPerformanceDistribution(BuildContext context) {
    final performanceLevels = <String, int>{
      'Elite': 0,
      'Advanced': 0,
      'Proficient': 0,
      'Developing': 0,
      'Basic': 0,
      'Beginner': 0,
    };

    for (var result in playerResults.values) {
      final categoryScores = result['categoryScores'] as Map<String, dynamic>?;
      final playerScore = categoryScores != null
          ? (categoryScores['Overall'] as num?)?.toDouble() ?? 0.0
          : 0.0;
      
      final level = _getPerformanceLevel(playerScore);
      performanceLevels[level] = (performanceLevels[level] ?? 0) + 1;
    }

    return ResponsiveCard(
      baseBorderRadius: 12,
      elevation: 2,
      padding: ResponsiveConfig.paddingAll(context, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Icon(Icons.bar_chart, color: Colors.purple[600]),
              ResponsiveSpacing(multiplier: 1, direction: Axis.horizontal),
              ResponsiveText(
                'Performance Distribution',
                baseFontSize: 16,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.blueGrey[800],
                ),
              ),
            ],
          ),
          ResponsiveSpacing(multiplier: 2),
          ...performanceLevels.entries.where((e) => e.value > 0).map((entry) {
            final level = entry.key;
            final count = entry.value;
            final percentage = (count / players.length * 100).round();
            final color = _getLevelColor(level);
            
            return Padding(
              padding: ResponsiveConfig.paddingSymmetric(context, vertical: 4),
              child: Row(
                children: [
                  Container(
                    width: ResponsiveConfig.dimension(context, 12),
                    height: ResponsiveConfig.dimension(context, 12),
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                    ),
                  ),
                  ResponsiveSpacing(multiplier: 1, direction: Axis.horizontal),
                  Expanded(
                    child: ResponsiveText(
                      level,
                      baseFontSize: 13,
                      style: const TextStyle(fontWeight: FontWeight.w500),
                    ),
                  ),
                  ResponsiveText(
                    '$count ($percentage%)',
                    baseFontSize: 13,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildQuickStats(BuildContext context) {
    final allScores = <double>[];
    for (var result in playerResults.values) {
      final categoryScores = result['categoryScores'] as Map<String, dynamic>?;
      final playerScore = categoryScores != null
          ? (categoryScores['Overall'] as num?)?.toDouble() ?? 0.0
          : 0.0;
      if (playerScore > 0) allScores.add(playerScore);
    }

    double highestScore = 0;
    double lowestScore = 0;
    double scoreRange = 0;

    if (allScores.isNotEmpty) {
      allScores.sort();
      highestScore = allScores.last;
      lowestScore = allScores.first;
      scoreRange = highestScore - lowestScore;
    }

    return ResponsiveCard(
      baseBorderRadius: 12,
      elevation: 2,
      padding: ResponsiveConfig.paddingAll(context, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Icon(Icons.speed, color: Colors.green[600]),
              ResponsiveSpacing(multiplier: 1, direction: Axis.horizontal),
              ResponsiveText(
                'Quick Stats',
                baseFontSize: 16,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.blueGrey[800],
                ),
              ),
            ],
          ),
          ResponsiveSpacing(multiplier: 2),
          _buildStatItem(context, 'Highest Score', highestScore.toStringAsFixed(1), Colors.green),
          _buildStatItem(context, 'Lowest Score', lowestScore.toStringAsFixed(1), Colors.orange),
          _buildStatItem(context, 'Score Range', scoreRange.toStringAsFixed(1), Colors.blue),
          _buildStatItem(context, 'Total Players', players.length.toString(), Colors.purple),
        ],
      ),
    );
  }

  Widget _buildStatItem(BuildContext context, String label, String value, Color color) {
    return Padding(
      padding: ResponsiveConfig.paddingSymmetric(context, vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          ResponsiveText(
            label,
            baseFontSize: 13,
            style: TextStyle(color: Colors.blueGrey[600]),
          ),
          ResponsiveText(
            value,
            baseFontSize: 13,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlayerGrid(BuildContext context) {
    return ResponsiveCard(
      baseBorderRadius: 12,
      elevation: 2,
      padding: ResponsiveConfig.paddingAll(context, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          ResponsiveText(
            'Player Results',
            baseFontSize: 16,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.blueGrey[800],
            ),
          ),
          ResponsiveSpacing(multiplier: 2),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: _getGridCrossAxisCount(context),
              childAspectRatio: 3.5,
              crossAxisSpacing: ResponsiveConfig.spacing(context, 12),
              mainAxisSpacing: ResponsiveConfig.spacing(context, 12),
            ),
            itemCount: players.length,
            itemBuilder: (context, index) {
              final player = players[index];
              final playerId = player.id.toString();
              final results = playerResults[playerId];
              
              if (results != null) {
                final testResultsForPlayer = playerTestResults[playerId] ?? {};
                
                final categoryScoresMap = results['categoryScores'];
                final Map<String, double> scores = {};
                
                if (categoryScoresMap is Map<String, dynamic>) {
                  categoryScoresMap.forEach((key, value) {
                    if (value is num) {
                      scores[key] = value.toDouble();
                    }
                  });
                }

                return TeamPlayerCard(
                  player: player,
                  testResults: testResultsForPlayer,
                  scores: scores,
                  createdAt: DateTime.now(),
                );
              }
              return const SizedBox.shrink();
            },
          ),
        ],
      ),
    );
  }

  // HELPER METHODS
  double _calculateTeamOverallScore() {
    double overallScore = teamAverages['skating_Overall'] ?? teamAverages['Overall'] ?? 0.0;
    
    if (overallScore == 0.0) {
      double total = 0;
      int count = 0;

      for (var result in playerResults.values) {
        final categoryScores = result['categoryScores'] as Map<String, dynamic>?;
        if (categoryScores != null && categoryScores.containsKey('Overall')) {
          final score = categoryScores['Overall'];
          if (score is num) {
            total += score.toDouble();
            count++;
          }
        }
      }

      if (count > 0) {
        overallScore = total / count;
      }
    }
    
    return overallScore;
  }

  int _getGridCrossAxisCount(BuildContext context) {
    // This would be dynamically determined by the AdaptiveLayout context
    // For now, return a reasonable default
    return 2;
  }

  Color _getLevelColor(String level) {
    switch (level) {
      case 'Elite':
        return Colors.green;
      case 'Advanced':
        return Colors.lightGreen;
      case 'Proficient':
        return Colors.blue;
      case 'Developing':
        return Colors.orange;
      case 'Basic':
        return Colors.red;
      case 'Beginner':
        return Colors.red[300]!;
      default:
        return Colors.grey;
    }
  }

  List<String> _generateTeamInsights(double overallScore) {
    final insights = <String>[];
    
    if (overallScore >= 8.0) {
      insights.add('Exceptional team performance indicates excellent coaching and development programs.');
      insights.add('Focus on maintaining this high level through advanced skill refinement.');
    } else if (overallScore >= 6.0) {
      insights.add('Strong team foundation with opportunities for targeted skill enhancement.');
      insights.add('Consider position-specific training to maximize individual potential.');
    } else if (overallScore >= 4.0) {
      insights.add('Developing team with solid fundamentals requiring consistent practice.');
      insights.add('Focus on basic skill mastery before advancing to complex techniques.');
    } else {
      insights.add('Foundation building phase requiring dedicated fundamental skill development.');
      insights.add('Prioritize basic skating mechanics and confidence building exercises.');
    }
    
    // Add team composition insight
    final positionCounts = <String, int>{};
    for (var player in players) {
      final position = player.position ?? 'Unknown';
      positionCounts[position] = (positionCounts[position] ?? 0) + 1;
    }
    
    if (positionCounts.length > 1) {
      insights.add('Diverse position mix allows for comprehensive team development strategies.');
    }
    
    return insights;
  }

  String _getPlayerName(String playerId) {
    try {
      final player = players.firstWhere(
        (player) => player.id.toString() == playerId,
      );
      return player.name;
    } catch (e) {
      return 'Unknown Player';
    }
  }

  String _getImprovementSuggestion(String category) {
    switch (category) {
      case 'Forward Speed':
      case 'Speed':
        return 'Work on stride efficiency and power development';
      case 'Backward Speed':
        return 'Practice backward skating technique and stride extension';
      case 'Agility':
        return 'Incorporate more edge work and quick direction change drills';
      case 'Transitions':
        return 'Practice forward-to-backward transitions in both directions';
      case 'Crossovers':
      case 'Technique':
        return 'Develop inside and outside edge control with crossover drills';
      default:
        return 'Focus on regular practice with proper technique';
    }
  }
}

class TeamPlayerCard extends StatelessWidget {
  final Player player;
  final Map<String, dynamic> testResults;
  final Map<String, double> scores;
  final DateTime createdAt;

  const TeamPlayerCard({
    Key? key,
    required this.player,
    required this.testResults,
    required this.scores,
    required this.createdAt,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final overallScore = scores['Overall'] ?? 0.0;
    
    return ResponsiveCard(
      margin: ResponsiveConfig.paddingSymmetric(context, vertical: 4),
      baseBorderRadius: 8,
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: SkatingUtils.getScoreColor(overallScore).withOpacity(0.2),
          child: ResponsiveText(
            player.jerseyNumber?.toString() ?? '?',
            baseFontSize: 12,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: SkatingUtils.getScoreColor(overallScore),
            ),
          ),
        ),
        title: ResponsiveText(
          player.name,
          baseFontSize: 14,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: ResponsiveText(
          '${player.position ?? 'Unknown'} • ${testResults.length} tests completed',
          baseFontSize: 12,
          style: TextStyle(color: Colors.blueGrey[600]),
        ),
        trailing: Container(
          padding: ResponsiveConfig.paddingSymmetric(context, horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: SkatingUtils.getScoreColor(overallScore).withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: ResponsiveText(
            overallScore.toStringAsFixed(1),
            baseFontSize: 12,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: SkatingUtils.getScoreColor(overallScore),
            ),
          ),
        ),
      ),
    );
  }
}