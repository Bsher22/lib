// PHASE 4 REFACTORED: skating_assessment_results_screen.dart
// Assessment Results & Analytics Screen with Full Responsive Foundation

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:hockey_shot_tracker/models/skating.dart';
import 'package:hockey_shot_tracker/models/player.dart';
import 'package:hockey_shot_tracker/providers/app_state.dart';
import 'package:hockey_shot_tracker/services/index.dart';
import 'package:hockey_shot_tracker/widgets/domain/assessment/skating/skating_result_summary_tab.dart';
import 'package:hockey_shot_tracker/widgets/domain/assessment/skating/skating_result_details_tab.dart';
import 'package:hockey_shot_tracker/widgets/domain/assessment/skating/skating_result_recommendations_tab.dart';
import 'package:hockey_shot_tracker/widgets/domain/assessment/common/assessment_results_display.dart';
import 'package:hockey_shot_tracker/utils/skating_utils.dart';
import 'package:hockey_shot_tracker/services/pdf_report_service.dart';
import 'package:hockey_shot_tracker/screens/pdf/pdf_preview_screen.dart';
import 'package:hockey_shot_tracker/responsive_system/index.dart';

class SkatingAssessmentResultsScreen extends StatefulWidget {
  final Skating assessment;
  final Player player;
  final VoidCallback onReset;
  final VoidCallback onSave;
  final Map<String, double> testResults;
  final String? assessmentId;

  const SkatingAssessmentResultsScreen({
    Key? key,
    required this.assessment,
    required this.player,
    required this.onReset,
    required this.onSave,
    required this.testResults,
    this.assessmentId,
  }) : super(key: key);

  @override
  _SkatingAssessmentResultsScreenState createState() => _SkatingAssessmentResultsScreenState();
}

class _SkatingAssessmentResultsScreenState extends State<SkatingAssessmentResultsScreen> {
  bool _isLoading = true;
  bool _isSaving = false;
  Map<String, dynamic> _sessionData = {};
  Map<String, dynamic> _analysisResults = {};
  String? _error;
  String? _sessionId;

  ApiService get _apiService {
    final appState = Provider.of<AppState>(context, listen: false);
    return appState.api;
  }

  @override
  void initState() {
    super.initState();
    _initializeSessionData();
  }

  Future<void> _initializeSessionData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final appState = Provider.of<AppState>(context, listen: false);
      _sessionId = widget.assessmentId ?? 
                   widget.assessment.assessmentId ?? 
                   appState.getCurrentSkatingAssessmentId();

      if (_sessionId == null || _sessionId!.isEmpty) {
        throw Exception('No session ID available for results');
      }

      print('🔍 Loading session results for ID: $_sessionId');

      _sessionData = await _apiService.getSkatingSession(_sessionId!);

      print('✅ Session data loaded successfully');
      print('  Status: ${_sessionData['status']}');
      print('  Tests: ${(_sessionData['tests'] as List?)?.length ?? 0}');
      print('  Analytics: ${_sessionData['analytics'] != null}');

      _analysisResults = _sessionData['analytics'] as Map<String, dynamic>? ?? {};

      if (_analysisResults.isEmpty) {
        print('⚠️ No analytics in session data - session may be incomplete');
        await _generateAnalytics();
      }

      setState(() {
        _isLoading = false;
      });

    } catch (e) {
      print('❌ Error loading session data: $e');
      setState(() {
        _error = 'Failed to load session results: $e';
        _isLoading = false;
      });

      await _generateLocalAnalytics();
    }
  }

  Future<void> _generateAnalytics() async {
    try {
      print('🔄 Generating analytics for session...');
      
      final tests = _sessionData['tests'] as List? ?? [];
      final testTimes = <String, double>{};
      
      for (final test in tests) {
        final testData = test as Map<String, dynamic>;
        final times = testData['test_times'] as Map<String, dynamic>? ?? {};
        times.forEach((key, value) {
          if (value is num) {
            testTimes[key] = value.toDouble();
          }
        });
      }

      if (testTimes.isNotEmpty) {
        final analysisData = {
          'player_id': widget.player.id,
          'date': DateTime.now().toIso8601String(),
          'age_group': widget.player.ageGroup ?? 'youth_15_18',
          'position': widget.player.position?.toLowerCase() ?? 'forward',
          'test_times': testTimes,
          'assessment_id': _sessionId,
          'save': false,
        };

        final analysisResponse = await _apiService.analyzeSkating(analysisData);
        _analysisResults = analysisResponse['analytics'] ?? analysisResponse;
        
        print('✅ Analytics generated successfully');
      }
    } catch (e) {
      print('❌ Failed to generate analytics: $e');
    }
  }

  Future<void> _generateLocalAnalytics() async {
    try {
      print('🔄 Generating local analytics as fallback...');
      
      _analysisResults = {
        'scores': _calculateLocalScores(widget.testResults),
        'strengths': _generateLocalStrengths(widget.testResults),
        'improvements': _generateLocalImprovements(widget.testResults),
        'performance_level': _calculateLocalPerformanceLevel(widget.testResults),
        'insights': ['Analysis based on local data'],
      };

      _sessionData = {
        'assessment_id': _sessionId ?? 'local',
        'player_id': widget.player.id,
        'player_name': widget.player.name,
        'status': 'completed',
        'completed_tests': widget.testResults.length,
        'total_tests_planned': widget.testResults.length,
        'tests': widget.testResults.entries.map((entry) => {
          'id': entry.key,
          'test_times': {entry.key: entry.value},
          'timestamp': DateTime.now().toIso8601String(),
        }).toList(),
        'analytics': _analysisResults,
      };

      setState(() {
        _isLoading = false;
        _error = null;
      });

      print('✅ Local analytics generated successfully');
    } catch (e) {
      setState(() {
        _error = 'Failed to generate results: $e';
        _isLoading = false;
      });
    }
  }

  Map<String, double> _calculateLocalScores(Map<String, double> testResults) {
    final scores = <String, double>{};
    double totalScore = 0.0;
    int scoreCount = 0;

    testResults.forEach((testId, time) {
      double score = 10.0 - (time / 2.0);
      score = score.clamp(1.0, 10.0);
      
      final category = _getCategoryFromTestId(testId);
      scores[category] = (scores[category] ?? 0.0) + score;
      totalScore += score;
      scoreCount++;
    });

    scores.updateAll((key, value) => value / scores.length);
    scores['Overall'] = scoreCount > 0 ? totalScore / scoreCount : 5.0;

    return scores;
  }

  List<String> _generateLocalStrengths(Map<String, double> testResults) {
    final bestTests = testResults.entries.toList()
      ..sort((a, b) => a.value.compareTo(b.value));
    
    return bestTests.take(2).map((e) => 
        '${_getTestDisplayName(e.key)} performance').toList();
  }

  List<String> _generateLocalImprovements(Map<String, double> testResults) {
    final worstTests = testResults.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    
    return worstTests.take(2).map((e) => 
        'Improve ${_getTestDisplayName(e.key)} technique').toList();
  }

  String _calculateLocalPerformanceLevel(Map<String, double> testResults) {
    final avgTime = testResults.values.reduce((a, b) => a + b) / testResults.length;
    
    if (avgTime < 5.0) return 'Excellent';
    if (avgTime < 7.0) return 'Good';
    if (avgTime < 9.0) return 'Average';
    return 'Developing';
  }

  String _getCategoryFromTestId(String testId) {
    if (testId.contains('speed')) return 'Speed';
    if (testId.contains('agility')) return 'Agility';
    if (testId.contains('crossover') || testId.contains('stop')) return 'Technique';
    return 'General';
  }

  String _getTestDisplayName(String testId) {
    const names = {
      'forward_speed_test': 'Forward Speed',
      'backward_speed_test': 'Backward Speed',
      'agility_test': 'Agility',
      'transitions_test': 'Transitions',
      'crossovers_test': 'Crossovers',
      'stop_start_test': 'Stop & Start',
    };
    return names[testId] ?? testId.replaceAll('_', ' ');
  }

  Future<void> _generatePDF() async {
    setState(() => _isLoading = true);
    
    try {
      final testResultsForPdf = <String, Map<String, dynamic>>{};
      final tests = _sessionData['tests'] as List? ?? [];
      
      for (final test in tests) {
        final testData = test as Map<String, dynamic>;
        final testTimes = testData['test_times'] as Map<String, dynamic>? ?? {};
        
        testTimes.forEach((testId, time) {
          testResultsForPdf[testId] = {
            'testId': testId,
            'time': time,
            'timestamp': testData['timestamp'] ?? DateTime.now().toIso8601String(),
            'notes': testData['notes'] ?? '',
          };
        });
      }
      
      final assessmentMap = {
        'title': _sessionData['session_title'] ?? 'Skating Assessment',
        'type': 'skating_assessment',
        'position': widget.player.position ?? 'Forward',
        'date': DateTime.now().toIso8601String(),
        'assessmentId': _sessionId,
        'playerName': widget.player.name,
        'playerId': widget.player.id,
        'groups': _generateTestGroupsFromSession(),
      };

      final pdfData = await PdfReportService.generateSkatingAssessmentPDF(
        player: widget.player,
        assessment: assessmentMap,
        results: _analysisResults,
        testResults: testResultsForPdf,
      );
      
      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => PDFPreviewScreen(
              pdfData: pdfData,
              fileName: 'skating_session_${widget.player.name}_${_sessionId?.substring(_sessionId!.length - 6) ?? DateTime.now().millisecondsSinceEpoch}.pdf',
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error generating PDF: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  List<Map<String, dynamic>> _generateTestGroupsFromSession() {
    final tests = _sessionData['tests'] as List? ?? [];
    final Map<String, List<Map<String, dynamic>>> groupedTests = {
      'Speed Tests': [],
      'Agility Tests': [],
      'Technique Tests': [],
    };

    for (final test in tests) {
      final testData = test as Map<String, dynamic>;
      final testTimes = testData['test_times'] as Map<String, dynamic>? ?? {};
      
      testTimes.forEach((testId, time) {
        final testInfo = {
          'id': testId,
          'title': _getTestDisplayName(testId),
          'category': _getCategoryFromTestId(testId),
          'description': 'Skating assessment test',
          'time': time,
        };

        final category = _getCategoryFromTestId(testId);
        if (category == 'Speed') {
          groupedTests['Speed Tests']!.add(testInfo);
        } else if (category == 'Agility') {
          groupedTests['Agility Tests']!.add(testInfo);
        } else {
          groupedTests['Technique Tests']!.add(testInfo);
        }
      });
    }

    return groupedTests.entries.where((entry) => entry.value.isNotEmpty).map((entry) {
      return {
        'name': entry.key,
        'tests': entry.value,
      };
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return _buildLoadingScreen();
    }

    if (_error != null) {
      return _buildErrorScreen();
    }

    final scores = (_analysisResults['scores'] as Map<String, dynamic>?) ?? {};
    final overallScore = scores['Overall'] as double? ?? 0.0;
    final performanceLevel = _analysisResults['performance_level'] as String? ?? 
                            _determinePerformanceLevel(overallScore);

    final assessmentAsMap = {
      'title': _sessionData['session_title'] ?? 'Skating Assessment',
      'type': 'skating_assessment',
      'position': widget.player.position ?? 'Forward',
      'ageGroup': widget.player.ageGroup ?? 'youth_15_18',
      'date': DateTime.now().toIso8601String(),
      'assessmentId': _sessionId,
      'playerName': widget.player.name,
      'playerId': widget.player.id,
      'groups': _generateTestGroupsFromSession(),
    };

    final testResultsMap = <String, Map<String, dynamic>>{};
    final tests = _sessionData['tests'] as List? ?? [];
    
    for (final test in tests) {
      final testData = test as Map<String, dynamic>;
      final testTimes = testData['test_times'] as Map<String, dynamic>? ?? {};
      
      testTimes.forEach((testId, time) {
        testResultsMap[testId] = {
          'testId': testId,
          'time': time,
          'timestamp': testData['timestamp'] ?? DateTime.now().toIso8601String(),
          'notes': testData['notes'] ?? '',
          'assessmentId': _sessionId,
        };
      });
    }

    return AdaptiveLayout(
      builder: (deviceType, isLandscape) {
        switch (deviceType) {
          case DeviceType.mobile:
            return _buildMobileLayout(assessmentAsMap, testResultsMap, overallScore, performanceLevel);
          case DeviceType.tablet:
            return _buildTabletLayout(assessmentAsMap, testResultsMap, overallScore, performanceLevel);
          case DeviceType.desktop:
            return _buildDesktopLayout(assessmentAsMap, testResultsMap, overallScore, performanceLevel);
        }
      },
    );
  }

  // ✅ MOBILE LAYOUT: Tabbed interface
  Widget _buildMobileLayout(Map<String, dynamic> assessmentAsMap, Map<String, Map<String, dynamic>> testResultsMap, double overallScore, String performanceLevel) {
    return AdaptiveScaffold(
      title: _sessionData['session_title'] ?? 'Skating Assessment',
      body: AssessmentResultsDisplay(
        title: _sessionData['session_title'] ?? 'Skating Assessment',
        subjectName: widget.player.name,
        subjectType: 'player',
        overallScore: overallScore,
        performanceLevel: performanceLevel,
        scoreColorProvider: SkatingUtils.getScoreColor,
        tabs: [
          AssessmentResultTab(
            label: 'Summary',
            contentBuilder: (context) => SkatingResultSummaryTab(
              assessment: widget.assessment,
              player: widget.player,
              analysisResults: _analysisResults,
            ),
          ),
          AssessmentResultTab(
            label: 'Details',
            contentBuilder: (context) => SkatingResultDetailsTab(
              assessment: assessmentAsMap,
              results: _analysisResults,
              testResults: testResultsMap,
            ),
          ),
          AssessmentResultTab(
            label: 'Recommendations',
            contentBuilder: (context) => SkatingResultRecommendationsTab(
              results: _analysisResults,
              playerId: widget.player.id,
              assessmentId: _sessionId,
            ),
          ),
        ],
        onReset: widget.onReset,
        onSave: () async {
          try {
            await _saveSessionResults();
            widget.onSave();
          } catch (e) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Failed to save session: $e')),
              );
            }
          }
        },
        onExportPdf: _generatePDF,
      ),
    );
  }

  // ✅ TABLET LAYOUT: Side navigation with content
  Widget _buildTabletLayout(Map<String, dynamic> assessmentAsMap, Map<String, Map<String, dynamic>> testResultsMap, double overallScore, String performanceLevel) {
    return AdaptiveScaffold(
      title: _sessionData['session_title'] ?? 'Skating Assessment',
      body: Row(
        children: [
          // Navigation Rail
          Container(
            width: ResponsiveConfig.dimension(context, 200),
            decoration: BoxDecoration(
              color: Colors.blueGrey[50],
              border: Border(right: BorderSide(color: Colors.grey[300]!)),
            ),
            child: _buildTabletNavigation(),
          ),
          
          // Main content
          Expanded(
            child: DefaultTabController(
              length: 3,
              child: Column(
                children: [
                  _buildTabletHeader(overallScore, performanceLevel),
                  Expanded(
                    child: TabBarView(
                      children: [
                        SkatingResultSummaryTab(
                          assessment: widget.assessment,
                          player: widget.player,
                          analysisResults: _analysisResults,
                        ),
                        SkatingResultDetailsTab(
                          assessment: assessmentAsMap,
                          results: _analysisResults,
                          testResults: testResultsMap,
                        ),
                        SkatingResultRecommendationsTab(
                          results: _analysisResults,
                          playerId: widget.player.id,
                          assessmentId: _sessionId,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ✅ DESKTOP LAYOUT: Full sidebar with enhanced features
  Widget _buildDesktopLayout(Map<String, dynamic> assessmentAsMap, Map<String, Map<String, dynamic>> testResultsMap, double overallScore, String performanceLevel) {
    return AdaptiveScaffold(
      title: _sessionData['session_title'] ?? 'Skating Assessment',
      body: Row(
        children: [
          // Main content area
          Expanded(
            flex: 4,
            child: DefaultTabController(
              length: 3,
              child: Column(
                children: [
                  _buildDesktopHeader(overallScore, performanceLevel),
                  _buildDesktopTabBar(),
                  Expanded(
                    child: TabBarView(
                      children: [
                        SkatingResultSummaryTab(
                          assessment: widget.assessment,
                          player: widget.player,
                          analysisResults: _analysisResults,
                        ),
                        SkatingResultDetailsTab(
                          assessment: assessmentAsMap,
                          results: _analysisResults,
                          testResults: testResultsMap,
                        ),
                        SkatingResultRecommendationsTab(
                          results: _analysisResults,
                          playerId: widget.player.id,
                          assessmentId: _sessionId,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          // Desktop Action Sidebar
          Container(
            width: ResponsiveConfig.dimension(context, 350),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              border: Border(left: BorderSide(color: Colors.grey[300]!)),
            ),
            child: _buildDesktopSidebar(overallScore, performanceLevel),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingScreen() {
    return AdaptiveScaffold(
      title: 'Loading Results',
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.cyanAccent[700]!),
              strokeWidth: 3,
            ),
            ResponsiveSpacing(multiplier: 2),
            ResponsiveText(
              'Loading session results...',
              baseFontSize: 16,
              style: TextStyle(color: Colors.blueGrey[700]),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorScreen() {
    return AdaptiveScaffold(
      title: 'Error',
      body: Center(
        child: ConstrainedBox(
          constraints: ResponsiveConfig.constraints(context, maxWidth: 400),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error,
                size: ResponsiveConfig.iconSize(context, 64),
                color: Colors.red[700],
              ),
              ResponsiveSpacing(multiplier: 2),
              ResponsiveText(
                _error!,
                baseFontSize: 16,
                style: TextStyle(color: Colors.red[700]),
                textAlign: TextAlign.center,
              ),
              ResponsiveSpacing(multiplier: 3),
              ResponsiveButton(
                text: 'Retry',
                onPressed: _initializeSessionData,
                baseHeight: 48,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTabletNavigation() {
    return Column(
      children: [
        Container(
          padding: ResponsiveConfig.paddingAll(context, 16),
          child: ResponsiveText(
            'Assessment Results',
            baseFontSize: 18,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.blueGrey[800],
            ),
          ),
        ),
        Divider(),
        TabBar(
          isScrollable: true,
          labelColor: Colors.cyanAccent[700],
          unselectedLabelColor: Colors.blueGrey[600],
          indicatorColor: Colors.cyanAccent[700],
          tabs: [
            Tab(
              icon: Icon(Icons.summarize),
              text: 'Summary',
            ),
            Tab(
              icon: Icon(Icons.analytics),
              text: 'Details',
            ),
            Tab(
              icon: Icon(Icons.lightbulb),
              text: 'Tips',
            ),
          ],
        ),
        Spacer(),
        _buildQuickActions(),
      ],
    );
  }

  Widget _buildTabletHeader(double overallScore, String performanceLevel) {
    return Container(
      padding: ResponsiveConfig.paddingAll(context, 16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Colors.grey[300]!)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ResponsiveText(
                  _sessionData['session_title'] ?? 'Skating Assessment',
                  baseFontSize: 20,
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                ResponsiveText(
                  widget.player.name,
                  baseFontSize: 16,
                  style: TextStyle(color: Colors.blueGrey[600]),
                ),
              ],
            ),
          ),
          Container(
            padding: ResponsiveConfig.paddingSymmetric(context, horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: SkatingUtils.getScoreColor(overallScore).withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: ResponsiveText(
              '${overallScore.toStringAsFixed(1)}/10',
              baseFontSize: 18,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: SkatingUtils.getScoreColor(overallScore),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDesktopHeader(double overallScore, String performanceLevel) {
    return Container(
      padding: ResponsiveConfig.paddingAll(context, 24),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Colors.grey[300]!)),
      ),
      child: Row(
        children: [
          Icon(
            Icons.sports_hockey,
            size: ResponsiveConfig.iconSize(context, 32),
            color: Colors.cyanAccent[700],
          ),
          ResponsiveSpacing(multiplier: 2, direction: Axis.horizontal),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ResponsiveText(
                  _sessionData['session_title'] ?? 'Skating Assessment',
                  baseFontSize: 24,
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                ResponsiveText(
                  '${widget.player.name} • ${widget.player.position ?? 'Player'} • Session ${_sessionId?.substring(_sessionId!.length - 6) ?? 'N/A'}',
                  baseFontSize: 14,
                  style: TextStyle(color: Colors.blueGrey[600]),
                ),
              ],
            ),
          ),
          Row(
            children: [
              Container(
                padding: ResponsiveConfig.paddingSymmetric(context, horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: SkatingUtils.getScoreColor(overallScore).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: ResponsiveText(
                  '${overallScore.toStringAsFixed(1)}/10',
                  baseFontSize: 20,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: SkatingUtils.getScoreColor(overallScore),
                  ),
                ),
              ),
              ResponsiveSpacing(multiplier: 2, direction: Axis.horizontal),
              Container(
                padding: ResponsiveConfig.paddingSymmetric(context, horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: ResponsiveText(
                  performanceLevel,
                  baseFontSize: 16,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.blue[800],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDesktopTabBar() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[50],
        border: Border(bottom: BorderSide(color: Colors.grey[300]!)),
      ),
      child: TabBar(
        labelColor: Colors.cyanAccent[700],
        unselectedLabelColor: Colors.blueGrey[600],
        indicatorColor: Colors.cyanAccent[700],
        indicatorWeight: 3,
        labelStyle: TextStyle(
          fontSize: ResponsiveConfig.fontSize(context, 16),
          fontWeight: FontWeight.bold,
        ),
        tabs: [
          Tab(
            icon: Icon(Icons.summarize),
            text: 'Performance Summary',
          ),
          Tab(
            icon: Icon(Icons.analytics),
            text: 'Detailed Analysis',
          ),
          Tab(
            icon: Icon(Icons.lightbulb),
            text: 'Training Recommendations',
          ),
        ],
      ),
    );
  }

  Widget _buildDesktopSidebar(double overallScore, String performanceLevel) {
    return Column(
      children: [
        // Session Information
        Container(
          padding: ResponsiveConfig.paddingAll(context, 24),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border(bottom: BorderSide(color: Colors.grey[200]!)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ResponsiveText(
                'Session Information',
                baseFontSize: 18,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.blueGrey[800],
                ),
              ),
              ResponsiveSpacing(multiplier: 2),
              _buildInfoRow('Player', widget.player.name),
              _buildInfoRow('Position', widget.player.position ?? 'N/A'),
              _buildInfoRow('Session ID', _sessionId?.substring(_sessionId!.length - 6) ?? 'N/A'),
              _buildInfoRow('Tests Completed', '${(_sessionData['completed_tests'] ?? 0)}'),
              _buildInfoRow('Overall Score', '${overallScore.toStringAsFixed(1)}/10'),
              _buildInfoRow('Performance Level', performanceLevel),
            ],
          ),
        ),
        
        // Quick Actions
        Container(
          padding: ResponsiveConfig.paddingAll(context, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ResponsiveText(
                'Quick Actions',
                baseFontSize: 18,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.blueGrey[800],
                ),
              ),
              ResponsiveSpacing(multiplier: 2),
              _buildQuickActions(),
            ],
          ),
        ),
        
        Spacer(),
        
        // Debug Info (development only)
        Container(
          margin: ResponsiveConfig.paddingAll(context, 16),
          child: ResponsiveButton(
            text: 'Session Debug Info',
            onPressed: _showDebugInfo,
            baseHeight: 40,
            backgroundColor: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.only(bottom: ResponsiveConfig.spacing(context, 8)),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: ResponsiveText(
              label,
              baseFontSize: 14,
              style: TextStyle(color: Colors.blueGrey[600]),
            ),
          ),
          Expanded(
            flex: 3,
            child: ResponsiveText(
              value,
              baseFontSize: 14,
              style: TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: double.infinity,
          child: ResponsiveButton(
            text: 'Export PDF Report',
            onPressed: _generatePDF,
            baseHeight: 48,
          ),
        ),
        ResponsiveSpacing(multiplier: 1.5),
        SizedBox(
          width: double.infinity,
          child: ResponsiveButton(
            text: 'Save Results',
            onPressed: () async {
              try {
                await _saveSessionResults();
                widget.onSave();
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Failed to save session: $e')),
                  );
                }
              }
            },
            baseHeight: 48,
            backgroundColor: Colors.green[600],
          ),
        ),
        ResponsiveSpacing(multiplier: 1.5),
        SizedBox(
          width: double.infinity,
          child: ResponsiveButton(
            text: 'Start New Assessment',
            onPressed: widget.onReset,
            baseHeight: 48,
            backgroundColor: Colors.blueGrey[600],
          ),
        ),
      ],
    );
  }

  Future<void> _saveSessionResults() async {
    if (_sessionId == null) {
      throw Exception('No session ID available');
    }

    setState(() => _isSaving = true);

    try {
      print('💾 Marking session as complete: $_sessionId');
      
      print('✅ Session completion confirmed');
      
      final appState = Provider.of<AppState>(context, listen: false);
      appState.clearCurrentSkatingAssessmentId();
      
    } catch (e) {
      print('❌ Error confirming session completion: $e');
      throw Exception('Failed to confirm session completion: $e');
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  void _showDebugInfo() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: ResponsiveText('Session Debug Information', baseFontSize: 18),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              ResponsiveText('Session ID: ${_sessionId ?? "Not available"}', baseFontSize: 14),
              ResponsiveSpacing(multiplier: 1),
              ResponsiveText('Player ID: ${widget.player.id}', baseFontSize: 14),
              ResponsiveSpacing(multiplier: 1),
              ResponsiveText('Player Name: ${widget.player.name}', baseFontSize: 14),
              ResponsiveSpacing(multiplier: 1),
              ResponsiveText('Session Status: ${_sessionData['status'] ?? "Unknown"}', baseFontSize: 14),
              ResponsiveSpacing(multiplier: 1),
              ResponsiveText('Completed Tests: ${_sessionData['completed_tests'] ?? 0}', baseFontSize: 14),
              ResponsiveSpacing(multiplier: 1),
              ResponsiveText('Total Tests Planned: ${_sessionData['total_tests_planned'] ?? 0}', baseFontSize: 14),
              ResponsiveSpacing(multiplier: 1),
              ResponsiveText('Has Analytics: ${_analysisResults.isNotEmpty}', baseFontSize: 14),
              ResponsiveSpacing(multiplier: 1),
              ResponsiveText('Analytics Keys: ${_analysisResults.keys.toList()}', baseFontSize: 14),
              ResponsiveSpacing(multiplier: 1),
              ResponsiveText('Test Results from Widget:', baseFontSize: 14),
              ...widget.testResults.entries.map((entry) => 
                ResponsiveText('  ${entry.key}: ${entry.value}s', baseFontSize: 12)
              ).toList(),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: ResponsiveText('Close', baseFontSize: 14),
          ),
        ],
      ),
    );
  }

  String _determinePerformanceLevel(double score) {
    if (score >= 9.0) return 'Elite';
    if (score >= 7.5) return 'Advanced';
    if (score >= 6.0) return 'Proficient';
    if (score >= 4.5) return 'Developing';
    if (score >= 3.0) return 'Basic';
    return 'Beginner';
  }
}