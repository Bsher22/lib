// lib/screens/players/tabs/player_profile_tab.dart

import 'package:flutter/material.dart';
import 'package:hockey_shot_tracker/models/player.dart';
import 'package:hockey_shot_tracker/models/team.dart';
import 'package:hockey_shot_tracker/models/user.dart';
import 'package:hockey_shot_tracker/widgets/core/list/standard_card.dart';
import 'package:hockey_shot_tracker/widgets/core/list/status_badge.dart';
import 'package:hockey_shot_tracker/widgets/domain/player/player_action_buttons.dart';
import 'package:intl/intl.dart';

class PlayerProfileTab extends StatelessWidget {
  final Player player;
  final Team? team;
  final User? coach;
  final User? coordinator;
  final Map<String, dynamic> analytics;
  final Map<String, dynamic>? skatingAnalytics;
  final VoidCallback? onEdit;
  final VoidCallback? onAssignCoach;
  final VoidCallback? onAssignTeam;
  final VoidCallback? onRecordSkating; // UPDATED: Removed required onRecordShot
  final VoidCallback onExport;
  final VoidCallback? onViewAnalytics;
  final VoidCallback? onViewSkatingAnalytics;
  
  const PlayerProfileTab({
    Key? key,
    required this.player,
    this.team,
    this.coach,
    this.coordinator,
    required this.analytics,
    this.skatingAnalytics,
    this.onEdit,
    this.onAssignCoach,
    this.onAssignTeam,
    // REMOVED: required this.onRecordShot,
    this.onRecordSkating,
    required this.onExport,
    this.onViewAnalytics,
    this.onViewSkatingAnalytics,
  }) : super(key: key);

  // NEW: Assessment navigation methods
  void _navigateToShotAssessment(BuildContext context) {
    Navigator.pushNamed(context, '/shot-assessment');
  }

  void _navigateToSkatingAssessment(BuildContext context) {
    Navigator.pushNamed(context, '/skating-assessment');
  }
  
  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildProfileCard(context),
          const SizedBox(height: 24),
          _buildUpdatedActionButtons(context), // UPDATED: New action buttons
        ],
      ),
    );
  }

  // NEW: Updated action buttons without onRecordShot
  Widget _buildUpdatedActionButtons(BuildContext context) {
    return StandardCard(
      title: 'Player Actions',
      headerIcon: Icons.person,
      child: Column(
        children: [
          // Assessment Actions Row
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _navigateToShotAssessment(context),
                  icon: const Icon(Icons.assessment),
                  label: const Text('Shot Assessment'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.cyanAccent,
                    foregroundColor: Colors.black87,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _navigateToSkatingAssessment(context),
                  icon: const Icon(Icons.speed),
                  label: const Text('Skating Assessment'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 12),
          
          // Management Actions Row
          Row(
            children: [
              if (onEdit != null)
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onEdit,
                    icon: const Icon(Icons.edit),
                    label: const Text('Edit Player'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
              if (onEdit != null) const SizedBox(width: 12),
              if (onRecordSkating != null)
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onRecordSkating,
                    icon: const Icon(Icons.speed),
                    label: const Text('Record Skating'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
            ],
          ),

          const SizedBox(height: 12),

          // Analytics Actions Row
          Row(
            children: [
              if (onViewAnalytics != null)
                Expanded(
                  child: TextButton.icon(
                    onPressed: onViewAnalytics,
                    icon: const Icon(Icons.analytics),
                    label: const Text('View Shooting Analytics'),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              if (onViewAnalytics != null && onViewSkatingAnalytics != null) 
                const SizedBox(width: 12),
              if (onViewSkatingAnalytics != null)
                Expanded(
                  child: TextButton.icon(
                    onPressed: onViewSkatingAnalytics,
                    icon: const Icon(Icons.speed),
                    label: const Text('View Skating Analytics'),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
  
  Widget _buildProfileCard(BuildContext context) {
    return StandardCard(
      title: player.name,
      headerIcon: Icons.person,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeaderInfo(),
          const SizedBox(height: 16),
          const Divider(),
          const SizedBox(height: 16),
          _buildPersonalInfo(),
          const SizedBox(height: 24),
          _buildTeamInfo(context),
          const SizedBox(height: 24),
          _buildPerformanceSummary(),
        ],
      ),
    );
  }
  
  Widget _buildHeaderInfo() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CircleAvatar(
          radius: 40,
          backgroundColor: Colors.blueGrey[200],
          child: Text(
            player.name.isNotEmpty ? player.name[0].toUpperCase() : '?',
            style: const TextStyle(
              fontSize: 30,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (player.preferredPosition != null && player.preferredPosition!.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    player.preferredPosition!,
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.blueGrey[600],
                    ),
                  ),
                ),
              if (player.jerseyNumber != null)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: StatusBadge(
                    text: '#${player.jerseyNumber}',
                    color: Colors.blue,
                    shape: StatusBadgeShape.pill,
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
  
  Widget _buildPersonalInfo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Personal Information',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.blueGrey[800],
          ),
        ),
        const SizedBox(height: 12),
        if (player.email != null && player.email!.isNotEmpty)
          _buildInfoItem(Icons.email, 'Email', player.email!),
        if (player.phone != null && player.phone!.isNotEmpty)
          _buildInfoItem(Icons.phone, 'Phone', player.phone!),
        if (player.birthDate != null)
          _buildInfoItem(
            Icons.cake,
            'Birth Date',
            DateFormat('MMMM d, yyyy').format(player.birthDate!),
          ),
        if (player.height != null && player.weight != null)
          _buildInfoItem(
            Icons.height,
            'Height/Weight',
            '${player.height} in / ${player.weight} lbs',
          ),
      ],
    );
  }
  
  Widget _buildTeamInfo(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Team & Staff',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.blueGrey[800],
          ),
        ),
        const SizedBox(height: 12),
        _buildInfoItem(
          Icons.group,
          'Team',
          team?.name ?? 'Not Assigned',
          onTap: team != null ? () => _viewTeam(context, team!) : null,
        ),
        _buildInfoItem(
          Icons.sports,
          'Primary Coach',
          coach?.name ?? 'Not Assigned',
          onTap: coach != null ? () => _viewCoach(context, coach!) : null,
        ),
        _buildInfoItem(
          Icons.people_alt,
          'Coordinator',
          coordinator?.name ?? 'Not Assigned',
          onTap: coordinator != null ? () => _viewCoordinator(context, coordinator!) : null,
        ),
      ],
    );
  }
  
  Widget _buildPerformanceSummary() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Performance Summary',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.blueGrey[800],
          ),
        ),
        const SizedBox(height: 16),
        
        DefaultTabController(
          length: 2,
          child: Column(
            children: [
              TabBar(
                labelColor: Colors.blueGrey[800],
                unselectedLabelColor: Colors.blueGrey[500],
                indicatorColor: Colors.blue,
                tabs: const [
                  Tab(
                    icon: Icon(Icons.sports_hockey),
                    text: 'Shooting',
                  ),
                  Tab(
                    icon: Icon(Icons.speed),
                    text: 'Skating',
                  ),
                ],
              ),
              const SizedBox(height: 16),
              SizedBox(
                height: 300,
                child: TabBarView(
                  children: [
                    _buildShootingPerformance(),
                    _buildSkatingPerformance(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildShootingPerformance() {
    final totalShots = analytics['total_shots'] as int? ?? 0;
    // FIXED: Use safe numeric casting
    final successRate = ((analytics['overall_success_rate'] as num?)?.toDouble() ?? 0.0) * 100;
    final avgPower = (analytics['average_power'] as num?)?.toDouble() ?? 0.0;
    final avgQuickRelease = (analytics['average_quick_release'] as num?)?.toDouble() ?? 0.0;
    
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Shot Performance',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.blueGrey[700],
                ),
              ),
              if (onViewAnalytics != null)
                TextButton.icon(
                  onPressed: onViewAnalytics,
                  icon: const Icon(Icons.analytics, size: 18),
                  label: const Text('View Analytics'),
                ),
            ],
          ),
          const SizedBox(height: 12),
          _buildInfoItem(
            Icons.sports_hockey,
            'Total Shots',
            '$totalShots',
          ),
          _buildSuccessRateItem(successRate),
          _buildInfoItem(
            Icons.bolt,
            'Avg Shot Power',
            '${avgPower.toStringAsFixed(1)} mph',
          ),
          _buildInfoItem(
            Icons.timer,
            'Avg Quick Release',
            '${avgQuickRelease.toStringAsFixed(2)} sec',
          ),
          if (analytics['successful_shots'] != null)
            _buildInfoItem(
              Icons.check_circle_outline,
              'Successful Shots',
              '${analytics['successful_shots']}',
            ),
          
          if (analytics['latest_assessment_date'] != null) ...[
            const SizedBox(height: 8),
            _buildInfoItem(
              Icons.assessment,
              'Latest Assessment',
              _formatDate(analytics['latest_assessment_date']),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSkatingPerformance() {
    final skatingData = skatingAnalytics ?? {};
    // FIXED: Use safe numeric casting
    final overallScore = (skatingData['overall_score'] as num?)?.toDouble() ?? 0;
    final totalSessions = skatingData['total_sessions'] as int? ?? 0;
    final assessmentCount = skatingData['assessment_count'] as int? ?? 0;
    final avgSpeed = (skatingData['average_speed'] as num?)?.toDouble() ?? 0;
    final performanceLevel = skatingData['performance_level'] as String?;
    final latestAssessmentDate = skatingData['latest_assessment_date'] as String?;
    
    if (totalSessions == 0) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.speed,
              size: 48,
              color: Colors.blueGrey[300],
            ),
            const SizedBox(height: 16),
            Text(
              'No Skating Data',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.blueGrey[600],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Complete skating assessments to see performance data',
              style: TextStyle(
                fontSize: 14,
                color: Colors.blueGrey[500],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            if (onRecordSkating != null)
              ElevatedButton.icon(
                onPressed: onRecordSkating,
                icon: const Icon(Icons.speed),
                label: const Text('Record Skating'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                ),
              ),
          ],
        ),
      );
    }
    
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Skating Performance',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.blueGrey[700],
                ),
              ),
              if (onViewSkatingAnalytics != null)
                TextButton.icon(
                  onPressed: onViewSkatingAnalytics,
                  icon: const Icon(Icons.analytics, size: 18),
                  label: const Text('View Analytics'),
                ),
            ],
          ),
          const SizedBox(height: 12),
          _buildInfoItem(
            Icons.sports,
            'Total Sessions',
            '$totalSessions',
          ),
          _buildInfoItem(
            Icons.assessment,
            'Assessments Completed',
            '$assessmentCount',
          ),
          _buildSkatingScoreItem(overallScore, performanceLevel),
          _buildInfoItem(
            Icons.speed,
            'Avg Speed Score',
            '${avgSpeed.toStringAsFixed(1)} sec',
          ),
          
          if (skatingData['category_scores'] != null) ...[
            const SizedBox(height: 8),
            _buildSkatingCategoriesPreview(skatingData['category_scores'] as Map<String, dynamic>),
          ],
          
          if (latestAssessmentDate != null) ...[
            const SizedBox(height: 8),
            _buildInfoItem(
              Icons.assessment,
              'Latest Assessment',
              _formatDate(latestAssessmentDate),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSkatingScoreItem(double score, String? performanceLevel) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: Colors.blueGrey[50],
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(
              Icons.assessment,
              size: 16,
              color: Colors.blueGrey[400],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Overall Skating Score',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.blueGrey[400],
                  ),
                ),
                Row(
                  children: [
                    Text(
                      '${score.toStringAsFixed(1)}/10',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.blueGrey[800],
                      ),
                    ),
                    if (performanceLevel != null) ...[
                      const SizedBox(width: 8),
                      StatusBadge(
                        text: performanceLevel,
                        color: _getPerformanceLevelColor(performanceLevel),
                        size: StatusBadgeSize.small,
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSkatingCategoriesPreview(Map<String, dynamic> categoryScores) {
    final sortedCategories = categoryScores.entries.toList()
      ..sort((a, b) => (b.value as double).compareTo(a.value as double));
    
    final topCategories = sortedCategories.take(3).toList();
    
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Top Skating Categories',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Colors.blueGrey[600],
            ),
          ),
          const SizedBox(height: 8),
          ...topCategories.map((entry) {
            final category = entry.key;
            // FIXED: Safe casting for skating scores
            final score = (entry.value as num).toDouble();
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: Row(
                children: [
                  Container(
                    width: 4,
                    height: 4,
                    decoration: BoxDecoration(
                      color: _getCategoryColor(category),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      category,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.blueGrey[700],
                      ),
                    ),
                  ),
                  Text(
                    '${score.toStringAsFixed(1)}',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.blueGrey[800],
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ],
      ),
    );
  }

  Color _getCategoryColor(String category) {
    switch (category.toLowerCase()) {
      case 'speed':
      case 'forward speed':
        return Colors.blue;
      case 'backward speed':
        return Colors.indigo;
      case 'agility':
        return Colors.green;
      case 'transitions':
        return Colors.orange;
      case 'technique':
        return Colors.purple;
      case 'power':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  Color _getPerformanceLevelColor(String level) {
    switch (level.toLowerCase()) {
      case 'elite':
      case 'excellent':
        return Colors.green;
      case 'advanced':
      case 'good':
        return Colors.lightGreen;
      case 'proficient':
      case 'average':
        return Colors.orange;
      case 'developing':
      case 'below average':
        return Colors.deepOrange;
      case 'basic':
      case 'beginner':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _formatDate(String? dateString) {
    if (dateString == null) return 'N/A';
    try {
      final date = DateTime.parse(dateString);
      return DateFormat('MMM d, yyyy').format(date);
    } catch (e) {
      return dateString;
    }
  }
  
  Widget _buildInfoItem(IconData icon, String label, String value, {VoidCallback? onTap}) {
    final content = Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: Colors.blueGrey[50],
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(
              icon,
              size: 16,
              color: Colors.blueGrey[400],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.blueGrey[400],
                  ),
                ),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.blueGrey[800],
                  ),
                ),
              ],
            ),
          ),
          if (onTap != null)
            Icon(
              Icons.chevron_right,
              size: 20,
              color: Colors.blueGrey[400],
            ),
        ],
      ),
    );

    if (onTap != null) {
      return InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: content,
      );
    }

    return content;
  }
  
  Widget _buildSuccessRateItem(double successRate) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: Colors.blueGrey[50],
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(
              Icons.check_circle_outline,
              size: 16,
              color: Colors.blueGrey[400],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Success Rate',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.blueGrey[400],
                  ),
                ),
                Row(
                  children: [
                    Text(
                      '${successRate.toStringAsFixed(1)}%',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.blueGrey[800],
                      ),
                    ),
                    const SizedBox(width: 8),
                    StatusBadge(
                      text: _getSuccessRateDescription(successRate),
                      color: _getSuccessRateColor(successRate),
                      size: StatusBadgeSize.small,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _getSuccessRateDescription(double rate) {
    if (rate >= 90) return 'Excellent';
    if (rate >= 75) return 'Very Good';
    if (rate >= 60) return 'Good';
    if (rate >= 45) return 'Average';
    if (rate >= 30) return 'Needs Work';
    return 'Poor';
  }

  Color _getSuccessRateColor(double rate) {
    if (rate >= 90) return Colors.green;
    if (rate >= 75) return Colors.green;
    if (rate >= 60) return Colors.lightGreen;
    if (rate >= 45) return Colors.orange;
    if (rate >= 30) return Colors.deepOrange;
    return Colors.red;
  }
  
  void _viewTeam(BuildContext context, Team team) {
    Navigator.pushNamed(context, '/team-details', arguments: team);
  }
  
  void _viewCoach(BuildContext context, User coach) {
    Navigator.pushNamed(context, '/coach-details', arguments: coach);
  }
  
  void _viewCoordinator(BuildContext context, User coordinator) {
    Navigator.pushNamed(context, '/coordinator-details', arguments: coordinator);
  }
}