// lib/screens/players/player_stats_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/player.dart';
import '../../providers/assessment_provider.dart';
import '../../providers/player_provider.dart';
import '../../utils/formatting_utils.dart';
import 'package:hockey_shot_tracker/widgets/domain/player/index.dart';

class PlayerStatsScreen extends StatefulWidget {
  final Player player;
  
  const PlayerStatsScreen({Key? key, required this.player}) : super(key: key);
  
  @override
  _PlayerStatsScreenState createState() => _PlayerStatsScreenState();
}

class _PlayerStatsScreenState extends State<PlayerStatsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = true;
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    
    // Load data when screen initializes
    _loadPlayerData();
  }
  
  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
  
  Future<void> _loadPlayerData() async {
    setState(() {
      _isLoading = true;
    });
    
    final assessmentProvider = Provider.of<AssessmentProvider>(context, listen: false);
    final playerProvider = Provider.of<PlayerProvider>(context, listen: false);
    
    // Load assessment results
    await assessmentProvider.fetchPlayerAssessmentResults(widget.player.id);
    
    // Load test results
    await assessmentProvider.fetchPlayerTestResults(widget.player.id);
    
    // Load recent assessments
    await assessmentProvider.fetchRecentAssessments(widget.player.id);
    
    // Load player's team if needed
    if (playerProvider.getPlayerTeam(widget.player.id) == null) {
      await playerProvider.fetchPlayerTeam(widget.player.id);
    }
    
    setState(() {
      _isLoading = false;
    });
  }
  
  @override
  Widget build(BuildContext context) {
    final assessmentProvider = Provider.of<AssessmentProvider>(context);
    final playerProvider = Provider.of<PlayerProvider>(context);
    
    final assessmentResults = assessmentProvider.getPlayerAssessmentResults(widget.player.id);
    final testResults = assessmentProvider.getPlayerTestResults(widget.player.id);
    final recentAssessments = assessmentProvider.getPlayerRecentAssessments(widget.player.id);
    final team = playerProvider.getPlayerTeam(widget.player.id);
    
    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.player.name} Stats'),
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(text: 'Overview'),
            Tab(text: 'Shot'),
            Tab(text: 'Skating'),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.info_outline),
            onPressed: () => _showFullDetails(context),
            tooltip: 'View Detailed Information',
          ),
        ],
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : assessmentResults != null
              ? _buildContent(context, assessmentResults, testResults, recentAssessments, team)
              : _buildNoDataContent(context),
    );
  }
  
  Widget _buildContent(
    BuildContext context, 
    dynamic assessmentResults, 
    List<dynamic> testResults, 
    List<dynamic> recentAssessments,
    dynamic team,
  ) {
    return TabBarView(
      controller: _tabController,
      children: [
        // Overview Tab
        SingleChildScrollView(
          padding: EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              PlayerPerformanceCard(
                player: widget.player,
                categoryScores: assessmentResults.categoryScores,
                performanceLevel: assessmentResults.performanceLevel,
                completedTests: assessmentResults.completedTests,
                totalTests: assessmentResults.totalTests,
                onTap: () => _showFullDetails(context),
              ),
              
              SizedBox(height: 24),
              _buildRecentAssessments(context, recentAssessments),
              
              SizedBox(height: 24),
              _buildActionButtons(context),
            ],
          ),
        ),
        
        // Shot Tab
        SingleChildScrollView(
          padding: EdgeInsets.all(16),
          child: _buildShotContent(context, assessmentResults, testResults),
        ),
        
        // Skating Tab
        SingleChildScrollView(
          padding: EdgeInsets.all(16),
          child: _buildSkatingContent(context, assessmentResults, testResults),
        ),
      ],
    );
  }
  
  Widget _buildNoDataContent(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.assessment_outlined,
            size: 64,
            color: Colors.blueGrey[300],
          ),
          SizedBox(height: 16),
          Text(
            'No assessment data available for this player',
            style: TextStyle(
              fontSize: 16,
              color: Colors.blueGrey[600],
            ),
          ),
          SizedBox(height: 24),
          ElevatedButton.icon(
            icon: Icon(Icons.add),
            label: Text('Start First Assessment'),
            onPressed: () => _showAssessmentOptions(context),
          ),
        ],
      ),
    );
  }
  
  Widget _buildRecentAssessments(BuildContext context, List<dynamic> recentAssessments) {
    if (recentAssessments.isEmpty) {
      return SizedBox();
    }
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Recent Assessments',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: 8),
        ListView.builder(
          shrinkWrap: true,
          physics: NeverScrollableScrollPhysics(),
          itemCount: recentAssessments.length,
          itemBuilder: (context, index) {
            final assessment = recentAssessments[index];
            return Card(
              margin: EdgeInsets.only(bottom: 8),
              child: ListTile(
                title: Text(assessment['title'] ?? 'Assessment'),
                subtitle: Text(
                  FormattingUtils.formatDate(
                    DateTime.parse(assessment['date'] ?? DateTime.now().toIso8601String())
                  ),
                ),
                trailing: Text(
                  FormattingUtils.formatPerformanceScore(
                    assessment['score'] != null 
                        ? (assessment['score'] as num).toDouble() 
                        : 0.0
                  ),
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: FormattingUtils.getPerformanceColor(
                      assessment['score'] != null 
                          ? (assessment['score'] as num).toDouble() 
                          : 0.0
                    ),
                  ),
                ),
                onTap: () {
                  // Navigate to assessment details
                },
              ),
            );
          },
        ),
      ],
    );
  }
  
  Widget _buildActionButtons(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Start New Assessment',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                icon: Icon(Icons.sports_hockey),
                label: Text('Shot Assessment'),
                onPressed: () => _startShotAssessment(context),
                style: OutlinedButton.styleFrom(
                  padding: EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
            SizedBox(width: 16),
            Expanded(
              child: OutlinedButton.icon(
                icon: Icon(Icons.directions_run),
                label: Text('Skating Assessment'),
                onPressed: () => _startSkatingAssessment(context),
                style: OutlinedButton.styleFrom(
                  padding: EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
  
  Widget _buildShotContent(BuildContext context, dynamic assessmentResults, List<dynamic> testResults) {
    // Filter test results for shot-related tests
    final shotTests = testResults.where((test) => 
      test.categoryName.toLowerCase().contains('shot') ||
      test.categoryName.toLowerCase().contains('shooting')
    ).toList();
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Shot Assessment',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: 16),
        // Shot assessment stats would go here
        SizedBox(height: 24),
        ElevatedButton.icon(
          icon: Icon(Icons.add),
          label: Text('New Shot Assessment'),
          onPressed: () => _startShotAssessment(context),
        ),
      ],
    );
  }
  
  Widget _buildSkatingContent(BuildContext context, dynamic assessmentResults, List<dynamic> testResults) {
    // Filter test results for skating-related tests
    final skatingTests = testResults.where((test) => 
      test.categoryName.toLowerCase().contains('skat') ||
      test.categoryName.toLowerCase().contains('speed') ||
      test.categoryName.toLowerCase().contains('agility')
    ).toList();
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Skating Assessment',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: 16),
        // Skating assessment stats would go here
        SizedBox(height: 24),
        ElevatedButton.icon(
          icon: Icon(Icons.add),
          label: Text('New Skating Assessment'),
          onPressed: () => _startSkatingAssessment(context),
        ),
      ],
    );
  }
  
  void _showFullDetails(BuildContext context) {
    final assessmentProvider = Provider.of<AssessmentProvider>(context, listen: false);
    final assessmentResults = assessmentProvider.getPlayerAssessmentResults(widget.player.id);
    
    if (assessmentResults != null) {
      showDialog(
        context: context,
        builder: (context) => PlayerDetailsDialog(
          player: widget.player,
          categoryScores: assessmentResults.categoryScores,
          performanceLevel: assessmentResults.performanceLevel,
          completedTests: assessmentResults.completedTests,
          totalTests: assessmentResults.totalTests,
          onViewFullReport: () {
            Navigator.pop(context);
            // Navigate to full report screen
            Navigator.pushNamed(
              context,
              '/player/${widget.player.id}/report',
              arguments: widget.player,
            );
          },
        ),
      );
    }
  }
  
  void _showAssessmentOptions(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Choose Assessment Type'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(Icons.sports_hockey),
              title: Text('Shot Assessment'),
              onTap: () {
                Navigator.pop(context);
                _startShotAssessment(context);
              },
            ),
            ListTile(
              leading: Icon(Icons.directions_run),
              title: Text('Skating Assessment'),
              onTap: () {
                Navigator.pop(context);
                _startSkatingAssessment(context);
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            child: Text('Cancel'),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }
  
  void _startShotAssessment(BuildContext context) {
    Navigator.pushNamed(
      context,
      '/assessments/shot',
      arguments: {
        'player': widget.player,
        'returnToStats': true,
      },
    );
  }
  
  void _startSkatingAssessment(BuildContext context) {
    Navigator.pushNamed(
      context,
      '/assessments/skating',
      arguments: {
        'player': widget.player,
        'returnToStats': true,
      },
    );
  }
}