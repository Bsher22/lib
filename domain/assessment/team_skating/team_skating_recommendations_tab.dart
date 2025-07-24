// lib/widgets/domain/assessment/team_skating/team_skating_recommendations_tab.dart
// REFACTORED: Updated with full responsive system integration following established patterns
import 'package:flutter/material.dart';
import 'package:hockey_shot_tracker/utils/skating_utils.dart';
import 'package:hockey_shot_tracker/widgets/core/state/index.dart';
import 'package:hockey_shot_tracker/widgets/core/list/index.dart';
import 'package:hockey_shot_tracker/responsive_system/index.dart';
import 'package:hockey_shot_tracker/widgets/domain/training/recommended_drill_card.dart';

class TeamSkatingRecommendationsTab extends StatefulWidget {
  final String teamName;
  final Map<String, Map<String, dynamic>> playerResults;
  final Map<String, double> teamAverages;

  const TeamSkatingRecommendationsTab({
    Key? key,
    required this.teamName,
    required this.playerResults,
    required this.teamAverages,
  }) : super(key: key);

  @override
  State<TeamSkatingRecommendationsTab> createState() => _TeamSkatingRecommendationsTabState();
}

class _TeamSkatingRecommendationsTabState extends State<TeamSkatingRecommendationsTab> {
  final TextEditingController _notesController = TextEditingController();
  
  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.playerResults.isEmpty) {
      return EmptyStateDisplay(
        title: 'No Recommendations Available',
        description: 'There are no assessment results to generate recommendations from.',
        icon: Icons.lightbulb_outline,
        iconColor: Colors.amber,
        showCard: true,
      );
    }

    return AdaptiveLayout(
      builder: (deviceType, isLandscape) {
        switch (deviceType) {
          case DeviceType.mobile:
            return _buildMobileLayout();
          case DeviceType.tablet:
            return _buildTabletLayout();
          case DeviceType.desktop:
            return _buildDesktopLayout();
        }
      },
    );
  }

  // 📱 MOBILE LAYOUT: Vertical scrolling with essential recommendations
  Widget _buildMobileLayout() {
    return SingleChildScrollView(
      padding: ResponsiveConfig.paddingAll(context, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildResearchBasisCard(),
          ResponsiveSpacing(multiplier: 2),
          
          _buildBatchOverviewCard(),
          ResponsiveSpacing(multiplier: 3),
          
          _buildSectionTitle('Individual Player Recommendations'),
          ResponsiveSpacing(multiplier: 2),
          _buildPlayerRecommendations(),
          ResponsiveSpacing(multiplier: 3),
          
          _buildSectionTitle('Common Focus Areas'),
          ResponsiveSpacing(multiplier: 2),
          _buildCommonFocusAreas(),
          ResponsiveSpacing(multiplier: 3),
          
          _buildSectionTitle('Recommended Practice Drills'),
          ResponsiveSpacing(multiplier: 2),
          _buildPracticeDrills(),
          ResponsiveSpacing(multiplier: 3),
          
          _buildCoachNotesCard(),
        ],
      ),
    );
  }

  // 📱 TABLET LAYOUT: Two-column (Recommendations | Training Plans)
  Widget _buildTabletLayout() {
    return SingleChildScrollView(
      padding: ResponsiveConfig.paddingAll(context, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildResearchBasisCard(),
          ResponsiveSpacing(multiplier: 2),
          
          _buildBatchOverviewCard(),
          ResponsiveSpacing(multiplier: 3),
          
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Left Column: Individual Recommendations
              Expanded(
                flex: 3,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSectionTitle('Individual Player Recommendations'),
                    ResponsiveSpacing(multiplier: 2),
                    _buildPlayerRecommendations(),
                    ResponsiveSpacing(multiplier: 3),
                    
                    _buildSectionTitle('Common Focus Areas'),
                    ResponsiveSpacing(multiplier: 2),
                    _buildCommonFocusAreas(),
                  ],
                ),
              ),
              
              ResponsiveSpacing(multiplier: 3, direction: Axis.horizontal),
              
              // Right Column: Training Plans & Drills
              Expanded(
                flex: 2,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSectionTitle('Recommended Drills'),
                    ResponsiveSpacing(multiplier: 2),
                    _buildPracticeDrills(),
                    ResponsiveSpacing(multiplier: 3),
                    
                    _buildCoachNotesCard(),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // 🖥️ DESKTOP LAYOUT: Three-column with enhanced coaching insights sidebar
  Widget _buildDesktopLayout() {
    return Row(
      children: [
        // Main Content Area
        Expanded(
          flex: 4,
          child: SingleChildScrollView(
            padding: ResponsiveConfig.paddingAll(context, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildResearchBasisCard(),
                ResponsiveSpacing(multiplier: 2),
                
                _buildBatchOverviewCard(),
                ResponsiveSpacing(multiplier: 3),
                
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Individual Recommendations
                    Expanded(
                      flex: 3,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildSectionTitle('Individual Player Recommendations'),
                          ResponsiveSpacing(multiplier: 2),
                          _buildPlayerRecommendations(),
                        ],
                      ),
                    ),
                    
                    ResponsiveSpacing(multiplier: 3, direction: Axis.horizontal),
                    
                    // Common Areas & Drills
                    Expanded(
                      flex: 2,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildSectionTitle('Common Focus Areas'),
                          ResponsiveSpacing(multiplier: 2),
                          _buildCommonFocusAreas(),
                          ResponsiveSpacing(multiplier: 3),
                          
                          _buildSectionTitle('Recommended Drills'),
                          ResponsiveSpacing(multiplier: 2),
                          _buildPracticeDrills(),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        
        // Enhanced Coaching Insights Sidebar
        Container(
          width: 350,
          height: double.infinity,
          decoration: BoxDecoration(
            color: Colors.blueGrey.shade50,
            border: Border(left: BorderSide(color: Colors.blueGrey.shade200)),
          ),
          child: SingleChildScrollView(
            padding: ResponsiveConfig.paddingAll(context, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildDesktopSidebarHeader(),
                ResponsiveSpacing(multiplier: 3),
                
                _buildBatchInsightsPanel(),
                ResponsiveSpacing(multiplier: 3),
                
                _buildIndividualProgressPanel(),
                ResponsiveSpacing(multiplier: 3),
                
                _buildDevelopmentTimelinePanel(),
                ResponsiveSpacing(multiplier: 3),
                
                _buildCoachNotesCard(),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDesktopSidebarHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.insights, color: Colors.blueGrey[700]),
            ResponsiveSpacing(multiplier: 1, direction: Axis.horizontal),
            ResponsiveText(
              'Coaching Insights',
              baseFontSize: 18,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.blueGrey[800],
              ),
            ),
          ],
        ),
        ResponsiveSpacing(multiplier: 1),
        ResponsiveText(
          'Individual development insights for ${widget.playerResults.length} players',
          baseFontSize: 14,
          style: TextStyle(color: Colors.blueGrey[600]),
        ),
      ],
    );
  }

  Widget _buildBatchInsightsPanel() {
    final playerCount = widget.playerResults.length;
    final scores = widget.playerResults.values
        .map((result) {
          final categoryScores = result['categoryScores'] as Map<String, dynamic>? ?? {};
          return (categoryScores['Overall'] as num?)?.toDouble() ?? 0.0;
        })
        .where((score) => score > 0)
        .toList();
    
    final avgScore = scores.isNotEmpty ? scores.reduce((a, b) => a + b) / scores.length : 0.0;
    final highestScore = scores.isNotEmpty ? scores.reduce((a, b) => a > b ? a : b) : 0.0;
    final lowestScore = scores.isNotEmpty ? scores.reduce((a, b) => a < b ? a : b) : 0.0;
    
    return StandardCard(
      headerIcon: Icons.analytics,
      headerIconColor: Colors.blue,
      title: 'Batch Overview',
      child: Column(
        children: [
          _buildInsightRow('Players Assessed', '$playerCount', Icons.group),
          _buildInsightRow('Average Score', '${avgScore.toStringAsFixed(1)}/10', Icons.trending_up),
          _buildInsightRow('Score Range', '${lowestScore.toStringAsFixed(1)} - ${highestScore.toStringAsFixed(1)}', Icons.show_chart),
          _buildInsightRow('Development Level', _getBatchDevelopmentLevel(avgScore), Icons.school),
        ],
      ),
    );
  }

  Widget _buildIndividualProgressPanel() {
    final sortedPlayers = widget.playerResults.entries.toList()
      ..sort((a, b) {
        final aScores = a.value['categoryScores'] as Map<String, dynamic>? ?? {};
        final bScores = b.value['categoryScores'] as Map<String, dynamic>? ?? {};
        final aScore = (aScores['Overall'] as num?)?.toDouble() ?? 0.0;
        final bScore = (bScores['Overall'] as num?)?.toDouble() ?? 0.0;
        return bScore.compareTo(aScore); // Descending order
      });

    return StandardCard(
      headerIcon: Icons.person,
      headerIconColor: Colors.green,
      title: 'Individual Progress',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (sortedPlayers.isNotEmpty) ...[
            ResponsiveText(
              'Top Performer',
              baseFontSize: 14,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.blueGrey[700],
              ),
            ),
            ResponsiveSpacing(multiplier: 0.5),
            _buildPlayerQuickCard(sortedPlayers.first, Colors.green),
            
            ResponsiveSpacing(multiplier: 1),
            
            ResponsiveText(
              'Needs Focus',
              baseFontSize: 14,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.blueGrey[700],
              ),
            ),
            ResponsiveSpacing(multiplier: 0.5),
            _buildPlayerQuickCard(sortedPlayers.last, Colors.orange),
          ],
        ],
      ),
    );
  }

  Widget _buildPlayerQuickCard(MapEntry<String, Map<String, dynamic>> playerEntry, Color color) {
    final results = playerEntry.value;
    final playerName = results['playerName'] as String? ?? 'Unknown Player';
    final categoryScores = results['categoryScores'] as Map<String, dynamic>? ?? {};
    final overallScore = (categoryScores['Overall'] as num?)?.toDouble() ?? 0.0;

    return Container(
      padding: ResponsiveConfig.paddingAll(context, 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: ResponsiveConfig.borderRadius(context, 8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Expanded(
            child: ResponsiveText(
              playerName,
              baseFontSize: 13,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          Container(
            padding: ResponsiveConfig.paddingSymmetric(context, horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              borderRadius: ResponsiveConfig.borderRadius(context, 12),
            ),
            child: ResponsiveText(
              '${overallScore.toStringAsFixed(1)}',
              baseFontSize: 12,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDevelopmentTimelinePanel() {
    return StandardCard(
      headerIcon: Icons.timeline,
      headerIconColor: Colors.purple,
      title: 'Development Timeline',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildTimelineItem('Week 1-2', 'Individual skill assessment review', true),
          _buildTimelineItem('Week 3-4', 'Targeted individual practice', false),
          _buildTimelineItem('Week 5-6', 'Progress check and adjustment', false),
          _buildTimelineItem('Week 7-8', 'Re-assessment preparation', false),
          
          ResponsiveSpacing(multiplier: 1),
          Container(
            padding: ResponsiveConfig.paddingAll(context, 8),
            decoration: BoxDecoration(
              color: Colors.amber.withOpacity(0.1),
              borderRadius: ResponsiveConfig.borderRadius(context, 8),
              border: Border.all(color: Colors.amber.withOpacity(0.3)),
            ),
            child: Row(
              children: [
                Icon(Icons.schedule, color: Colors.amber, size: ResponsiveConfig.iconSize(context, 16)),
                ResponsiveSpacing(multiplier: 1, direction: Axis.horizontal),
                Expanded(
                  child: ResponsiveText(
                    'Re-assess individually after 6-8 weeks',
                    baseFontSize: 12,
                    style: TextStyle(
                      fontWeight: FontWeight.w500,
                      color: Colors.blueGrey[700],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimelineItem(String phase, String description, bool isActive) {
    return Padding(
      padding: ResponsiveConfig.paddingOnly(context, bottom: 8),
      child: Row(
        children: [
          Container(
            width: ResponsiveConfig.dimension(context, 8),
            height: ResponsiveConfig.dimension(context, 8),
            decoration: BoxDecoration(
              color: isActive ? Colors.purple : Colors.blueGrey.shade300,
              shape: BoxShape.circle,
            ),
          ),
          ResponsiveSpacing(multiplier: 1, direction: Axis.horizontal),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ResponsiveText(
                  phase,
                  baseFontSize: 12,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: isActive ? Colors.purple : Colors.blueGrey[600],
                  ),
                ),
                ResponsiveText(
                  description,
                  baseFontSize: 11,
                  style: TextStyle(color: Colors.blueGrey[600]),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInsightRow(String label, String value, IconData icon) {
    return Padding(
      padding: ResponsiveConfig.paddingSymmetric(context, vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: ResponsiveConfig.iconSize(context, 16), color: Colors.blueGrey[600]),
          ResponsiveSpacing(multiplier: 1, direction: Axis.horizontal),
          Expanded(
            child: ResponsiveText(
              label,
              baseFontSize: 13,
              style: TextStyle(color: Colors.blueGrey[700]),
            ),
          ),
          ResponsiveText(
            value,
            baseFontSize: 13,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildResearchBasisCard() {
    return StandardCard(
      headerIcon: Icons.science,
      headerIconColor: Colors.blue,
      title: 'Research-Based Individual Assessment',
      child: Container(
        padding: ResponsiveConfig.paddingAll(context, 12),
        decoration: BoxDecoration(
          color: Colors.blue.withOpacity(0.1),
          borderRadius: ResponsiveConfig.borderRadius(context, 8),
          border: Border.all(color: Colors.blue.withOpacity(0.3)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ResponsiveText(
              'Individual Development Benchmarks v3.0',
              baseFontSize: 14,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            ResponsiveSpacing(multiplier: 0.5),
            ResponsiveText(
              'These individual recommendations are based on analysis of 2,600+ hockey players, providing personalized development targets for each player.',
              baseFontSize: 12,
            ),
            ResponsiveSpacing(multiplier: 1),
            Row(
              children: [
                Icon(Icons.check_circle, color: Colors.green, size: ResponsiveConfig.iconSize(context, 16)),
                ResponsiveSpacing(multiplier: 0.5, direction: Axis.horizontal),
                Expanded(
                  child: ResponsiveText(
                    'Personalized strategies align with individual skill progression patterns',
                    baseFontSize: 11,
                    style: TextStyle(
                      color: Colors.blueGrey[700],
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return ResponsiveText(
      title,
      baseFontSize: 18,
      style: TextStyle(
        fontWeight: FontWeight.bold,
        color: Colors.blueGrey[800],
      ),
    );
  }

  Widget _buildBatchOverviewCard() {
    final playerCount = widget.playerResults.length;
    final scores = widget.playerResults.values
        .map((result) {
          final categoryScores = result['categoryScores'] as Map<String, dynamic>? ?? {};
          return (categoryScores['Overall'] as num?)?.toDouble() ?? 0.0;
        })
        .where((score) => score > 0)
        .toList();
    
    final avgScore = scores.isNotEmpty ? scores.reduce((a, b) => a + b) / scores.length : 0.0;
    final developmentLevel = _getBatchDevelopmentLevel(avgScore);

    return ResponsiveCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              ResponsiveText(
                'Batch Assessment Overview',
                baseFontSize: 16,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.blueGrey[800],
                ),
              ),
              Container(
                padding: ResponsiveConfig.paddingSymmetric(context, horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: SkatingUtils.getScoreColor(avgScore).withOpacity(0.2),
                  borderRadius: ResponsiveConfig.borderRadius(context, 16),
                ),
                child: ResponsiveText(
                  '${avgScore.toStringAsFixed(1)}/10 avg',
                  baseFontSize: 12,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: SkatingUtils.getScoreColor(avgScore),
                  ),
                ),
              ),
            ],
          ),
          ResponsiveSpacing(multiplier: 1),
          ResponsiveText(
            '$playerCount players assessed • $developmentLevel level',
            baseFontSize: 14,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.blueGrey[600],
            ),
          ),
          ResponsiveSpacing(multiplier: 2),
          ResponsiveText(
            _getBatchOverallRecommendation(avgScore, playerCount),
            baseFontSize: 14,
            style: TextStyle(color: Colors.blueGrey[600]),
          ),
        ],
      ),
    );
  }

  Widget _buildPlayerRecommendations() {
    final sortedPlayers = widget.playerResults.entries.toList()
      ..sort((a, b) {
        final aScores = a.value['categoryScores'] as Map<String, dynamic>? ?? {};
        final bScores = b.value['categoryScores'] as Map<String, dynamic>? ?? {};
        final aScore = (aScores['Overall'] as num?)?.toDouble() ?? 0.0;
        final bScore = (bScores['Overall'] as num?)?.toDouble() ?? 0.0;
        return aScore.compareTo(bScore); // Ascending order (lowest first for focus)
      });

    return Column(
      children: sortedPlayers.map((entry) {
        final results = entry.value;
        final playerName = results['playerName'] as String? ?? 'Unknown Player';
        final categoryScores = results['categoryScores'] as Map<String, dynamic>? ?? {};
        final overallScore = (categoryScores['Overall'] as num?)?.toDouble() ?? 0.0;

        // Find lowest category for individual focus
        String lowestCategory = '';
        double lowestScore = 10.0;

        for (final categoryEntry in categoryScores.entries) {
          if (categoryEntry.key != 'Overall' && categoryEntry.value is num) {
            final value = (categoryEntry.value as num).toDouble();
            if (lowestCategory.isEmpty || value < lowestScore) {
              lowestCategory = categoryEntry.key;
              lowestScore = value;
            }
          }
        }

        return ResponsiveCard(
          margin: ResponsiveConfig.paddingOnly(context, bottom: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  ResponsiveText(
                    playerName,
                    baseFontSize: 16,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Container(
                    padding: ResponsiveConfig.paddingSymmetric(context, horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: SkatingUtils.getScoreColor(overallScore).withOpacity(0.2),
                      borderRadius: ResponsiveConfig.borderRadius(context, 16),
                    ),
                    child: ResponsiveText(
                      '${overallScore.toStringAsFixed(1)}/10',
                      baseFontSize: 12,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: SkatingUtils.getScoreColor(overallScore),
                      ),
                    ),
                  ),
                ],
              ),
              if (lowestCategory.isNotEmpty) ...[
                ResponsiveSpacing(multiplier: 1),
                ResponsiveText(
                  'Primary Focus: $lowestCategory (${lowestScore.toStringAsFixed(1)}/10)',
                  baseFontSize: 14,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.blueGrey[600],
                  ),
                ),
                ResponsiveSpacing(multiplier: 2),
                ResponsiveText(
                  _getIndividualPlayerRecommendation(playerName, lowestCategory, lowestScore, overallScore),
                  baseFontSize: 14,
                  style: TextStyle(color: Colors.blueGrey[700]),
                ),
              ],
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildCommonFocusAreas() {
    // Calculate which categories need most attention across all players
    final Map<String, List<double>> categoryScores = {};
    
    for (var result in widget.playerResults.values) {
      final categoryValues = result['categoryScores'] as Map<String, dynamic>?;
      if (categoryValues != null) {
        for (var entry in categoryValues.entries) {
          if (entry.key != 'Overall' && entry.value is num) {
            final key = entry.key;
            final value = (entry.value as num).toDouble();
            
            categoryScores[key] ??= [];
            categoryScores[key]!.add(value);
          }
        }
      }
    }
    
    // Calculate averages and find areas needing most work
    final Map<String, double> categoryAverages = {};
    for (var entry in categoryScores.entries) {
      final scores = entry.value;
      categoryAverages[entry.key] = scores.reduce((a, b) => a + b) / scores.length;
    }

    final sortedCategories = categoryAverages.entries.toList()
      ..sort((a, b) => a.value.compareTo(b.value));

    final commonAreas = sortedCategories.take(2).toList(); // Show top 2 areas

    return Column(
      children: commonAreas.map((entry) {
        final category = entry.key;
        final avgScore = entry.value;
        
        // Count how many players struggle in this area
        final strugglingPlayers = categoryScores[category]!
            .where((score) => score < 5.0)
            .length;

        return ResponsiveCard(
          margin: ResponsiveConfig.paddingOnly(context, bottom: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(
                        _getCategoryIcon(category),
                        color: SkatingUtils.getScoreColor(avgScore),
                      ),
                      ResponsiveSpacing(multiplier: 1, direction: Axis.horizontal),
                      ResponsiveText(
                        category,
                        baseFontSize: 16,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  Container(
                    padding: ResponsiveConfig.paddingSymmetric(context, horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: SkatingUtils.getScoreColor(avgScore).withOpacity(0.2),
                      borderRadius: ResponsiveConfig.borderRadius(context, 16),
                    ),
                    child: ResponsiveText(
                      '${avgScore.toStringAsFixed(1)}/10',
                      baseFontSize: 12,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: SkatingUtils.getScoreColor(avgScore),
                      ),
                    ),
                  ),
                ],
              ),
              ResponsiveSpacing(multiplier: 1),
              ResponsiveText(
                '$strugglingPlayers of ${widget.playerResults.length} players need focus in this area',
                baseFontSize: 14,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.blueGrey[600],
                ),
              ),
              ResponsiveSpacing(multiplier: 2),
              ResponsiveText(
                _getCommonAreaRecommendation(category, avgScore, strugglingPlayers),
                baseFontSize: 14,
                style: TextStyle(color: Colors.blueGrey[700]),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildPracticeDrills() {
    // Generate drills based on common weak areas
    final Map<String, List<double>> categoryScores = {};
    
    for (var result in widget.playerResults.values) {
      final categoryValues = result['categoryScores'] as Map<String, dynamic>?;
      if (categoryValues != null) {
        for (var entry in categoryValues.entries) {
          if (entry.key != 'Overall' && entry.value is num) {
            final key = entry.key;
            final value = (entry.value as num).toDouble();
            
            categoryScores[key] ??= [];
            categoryScores[key]!.add(value);
          }
        }
      }
    }
    
    // Find categories with lowest averages
    final Map<String, double> categoryAverages = {};
    for (var entry in categoryScores.entries) {
      final scores = entry.value;
      categoryAverages[entry.key] = scores.reduce((a, b) => a + b) / scores.length;
    }

    final sortedCategories = categoryAverages.entries.toList()
      ..sort((a, b) => a.value.compareTo(b.value));

    final focusAreas = sortedCategories.take(2).map((e) => e.key).toList();
    final drills = _getDrillsForCategories(focusAreas);

    return Column(
      children: drills.map<Widget>((drill) {
        return Padding(
          padding: ResponsiveConfig.paddingOnly(context, bottom: 16),
          child: RecommendedDrillCard(
            name: drill['name']!,
            description: drill['description']!,
            repetitions: drill['repetitions'],
            frequency: drill['frequency'],
            keyPoints: drill['keyPoints'] as List<String>?,
            priorityLevel: drill['priorityLevel'],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildCoachNotesCard() {
    return StandardCard(
      headerIcon: Icons.edit_note,
      headerIconColor: Colors.blueGrey,
      title: 'Coach Notes',
      child: TextField(
        controller: _notesController,
        decoration: InputDecoration(
          hintText: 'Add notes about individual player performance and development plans...',
          border: OutlineInputBorder(
            borderRadius: ResponsiveConfig.borderRadius(context, 8),
          ),
          contentPadding: ResponsiveConfig.paddingAll(context, 12),
        ),
        maxLines: 4,
      ),
    );
  }

  // Helper methods

  String _getBatchDevelopmentLevel(double avgScore) {
    if (avgScore >= 7.0) return 'Advanced';
    if (avgScore >= 5.0) return 'Intermediate';
    if (avgScore >= 3.0) return 'Developing';
    return 'Beginner';
  }

  String _getBatchOverallRecommendation(double avgScore, int playerCount) {
    if (avgScore >= 7.0) {
      return 'This group shows advanced skating performance. Focus on individual refinements and position-specific skills. Each player can benefit from personalized high-level development.';
    } else if (avgScore >= 5.0) {
      return 'This group demonstrates solid skating fundamentals with room for advancement. Individual focus areas vary, so personalized development plans will be most effective.';
    } else if (avgScore >= 3.0) {
      return 'This group is developing their skating skills. Each player has specific areas that need attention. Consistent individual practice with targeted drills will drive improvement.';
    } else {
      return 'This group requires fundamental skating development. Focus on basic skills with each player receiving individual attention to build confidence and technique.';
    }
  }

  String _getIndividualPlayerRecommendation(String playerName, String category, double categoryScore, double overallScore) {
    final String baseRecommendation = '$playerName should prioritize $category development (${categoryScore.toStringAsFixed(1)}/10). ';

    switch (category) {
      case 'Forward Speed':
      case 'Speed':
        if (categoryScore < 4.0) {
          return baseRecommendation + 'Focus on basic stride mechanics with individual coaching. Work on proper knee bend, arm swing, and full leg extension. Start with short acceleration drills and gradually increase distance.';
        } else if (categoryScore < 6.0) {
          return baseRecommendation + 'Work on acceleration techniques and power development. Add resistance training and timed sprint intervals. Focus on maintaining form at higher speeds.';
        } else {
          return baseRecommendation + 'Refine top-end speed with advanced techniques. Work on maintaining maximum velocity and race-pace conditioning.';
        }

      case 'Backward Speed':
        if (categoryScore < 4.0) {
          return baseRecommendation + 'Start with fundamental c-cut technique and backward mobility. Practice proper posture and basic backward crossovers at slow speeds.';
        } else if (categoryScore < 6.0) {
          return baseRecommendation + 'Enhance backward skating with increased speed and more complex patterns. Work on maintaining balance at higher speeds.';
        } else {
          return baseRecommendation + 'Focus on maintaining technique at maximum backward speed and in defensive pressure situations.';
        }

      case 'Agility':
        if (categoryScore < 4.0) {
          return baseRecommendation + 'Work on fundamental edge control and basic direction changes. Start with simple cone drills and weight transfer exercises.';
        } else if (categoryScore < 6.0) {
          return baseRecommendation + 'Enhance with complex direction-change patterns and reaction-based training. Add competitive elements to drills.';
        } else {
          return baseRecommendation + 'Refine with advanced edge combinations and high-speed directional changes in game-like scenarios.';
        }

      case 'Transitions':
        if (categoryScore < 4.0) {
          return baseRecommendation + 'Focus on basic pivot techniques and simple direction changes at controlled speeds. Master the fundamentals before increasing pace.';
        } else if (categoryScore < 6.0) {
          return baseRecommendation + 'Work on maintaining speed through transitions with varied pattern practice. Add game-situation elements.';
        } else {
          return baseRecommendation + 'Implement advanced transition sequences in high-pressure, game-speed situations.';
        }

      default:
        return baseRecommendation + 'Work with coaches on developing a personalized improvement plan focusing on this specific skill area.';
    }
  }

  String _getCommonAreaRecommendation(String category, double avgScore, int strugglingCount) {
    final String baseInfo = 'Common focus area across multiple players. ';

    switch (category) {
      case 'Forward Speed':
      case 'Speed':
        return baseInfo + 'Consider group speed development sessions while maintaining individual technique focus. Use partner drills and competitive elements to motivate improvement.';

      case 'Backward Speed':
        return baseInfo + 'Group backward skating sessions can be effective. Players can practice together while receiving individual feedback on technique.';

      case 'Agility':
        return baseInfo + 'Agility courses work well in small groups. Set up stations where players can practice individually while encouraging each other.';

      case 'Transitions':
        return baseInfo + 'Transition drills can be practiced in groups with individual coaching points. Focus on each player\'s specific transition challenges.';

      default:
        return baseInfo + 'Consider group practice sessions with individual attention to each player\'s specific needs in this area.';
    }
  }

  IconData _getCategoryIcon(String category) {
    switch (category) {
      case 'Forward Speed':
      case 'Speed':
        return Icons.speed;
      case 'Backward Speed':
        return Icons.arrow_back;
      case 'Agility':
        return Icons.change_circle;
      case 'Transitions':
        return Icons.swap_horiz;
      default:
        return Icons.analytics;
    }
  }

  List<Map<String, dynamic>> _getDrillsForCategories(List<String> categories) {
    final Map<String, List<Map<String, dynamic>>> categoryDrills = {
      'Forward Speed': [
        {
          'name': 'Individual Acceleration Progression',
          'repetitions': '8-10 repetitions',
          'frequency': '3x per week',
          'description': 'Progressive acceleration drills starting from standstill, focusing on individual technique and gradual speed increase.',
          'keyPoints': ['Explosive first step', 'Low body position', 'Individual pacing', 'Technique focus'],
          'priorityLevel': 'high',
        },
      ],
      'Backward Speed': [
        {
          'name': 'Backward Skating Fundamentals',
          'repetitions': '3 sets x 45 seconds',
          'frequency': '2x per week',
          'description': 'Individual backward skating technique with focus on proper c-cuts and posture.',
          'keyPoints': ['Proper posture', 'C-cut technique', 'Individual feedback', 'Progressive speed'],
          'priorityLevel': 'medium',
        },
      ],
      'Agility': [
        {
          'name': 'Individual Agility Circuit',
          'repetitions': '5 patterns x 2 sets',
          'frequency': '3x per week',
          'description': 'Personalized agility patterns designed for individual skill level and improvement areas.',
          'keyPoints': ['Quick direction changes', 'Individual pacing', 'Varied patterns', 'Technique focus'],
          'priorityLevel': 'high',
        },
      ],
      'Transitions': [
        {
          'name': 'Individual Transition Training',
          'repetitions': '8 transitions each direction',
          'frequency': '2-3x per week',
          'description': 'Individual transition drills with personal coaching and technique refinement.',
          'keyPoints': ['Smooth transitions', 'Individual feedback', 'Progressive difficulty', 'Speed maintenance'],
          'priorityLevel': 'medium',
        },
      ],
    };

    final drills = <Map<String, dynamic>>[];

    for (final category in categories) {
      if (categoryDrills.containsKey(category)) {
        drills.addAll(categoryDrills[category]!);
      }
    }

    // Add general individual drill if needed
    if (drills.length < 3) {
      drills.add({
        'name': 'Individual Skating Fundamentals',
        'repetitions': '15-20 minutes',
        'frequency': '2x per week',
        'description': 'Personalized skating session covering multiple skill areas with individual coaching focus.',
        'keyPoints': ['Individual attention', 'Multiple skills', 'Personal progression', 'Technique refinement'],
        'priorityLevel': 'medium',
      });
    }

    return drills.take(3).toList(); // Limit to 3 drills
  }
}