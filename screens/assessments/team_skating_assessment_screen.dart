// lib/screens/assessments/team_skating_assessment_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:hockey_shot_tracker/providers/app_state.dart';
import 'package:hockey_shot_tracker/models/skating.dart';
import 'package:hockey_shot_tracker/models/player.dart';
import 'package:hockey_shot_tracker/models/assessment/assessment_state.dart';
import 'package:hockey_shot_tracker/widgets/domain/assessment/team_skating/index.dart';
import 'package:hockey_shot_tracker/widgets/core/state/index.dart';
import 'package:hockey_shot_tracker/responsive_system/index.dart';

class TeamSkatingAssessmentScreen extends StatefulWidget {
  const TeamSkatingAssessmentScreen({Key? key}) : super(key: key);

  @override
  _TeamSkatingAssessmentScreenState createState() => _TeamSkatingAssessmentScreenState();
}

class _TeamSkatingAssessmentScreenState extends State<TeamSkatingAssessmentScreen> {
  // Screen states
  AssessmentState _currentState = AssessmentState.setup;
  bool _isLoading = false;

  // Assessment data
  String _assessmentType = 'Comprehensive';
  String _teamName = '';
  int _teamId = 0;
  List<Player> _selectedPlayers = [];
  late Map<String, dynamic> _assessment;

  // Results storage: Map<playerId, Map<testId, Map<String, dynamic>>>
  Map<String, Map<String, Map<String, dynamic>>> _playerTestResults = {};

  @override
  void initState() {
    super.initState();
    _resetAssessment();
  }

  void _resetAssessment() async {
    setState(() {
      _currentState = AssessmentState.setup;
      _assessment = {
        'type': _assessmentType,
        'title': _assessmentType,
        'description': 'Standard skating assessment',
        'position': 'forward',
        'groups': [
          {
            'id': '1',
            'name': 'Speed Tests',
            'description': 'Forward and backward skating speed',
            'tests': [
              {'id': 'forward_skate', 'title': 'Forward Skate', 'category': 'Speed'},
              {'id': 'backward_skate', 'title': 'Backward Skate', 'category': 'Speed'},
            ],
          },
          {
            'id': '2',
            'name': 'Agility Tests',
            'description': 'Lateral movement and transitions',
            'tests': [
              {'id': 'lateral_movement', 'title': 'Lateral Movement', 'category': 'Agility'},
              {'id': 'transition', 'title': 'Transition Skate', 'category': 'Agility'},
            ],
          },
        ],
      };
      _teamId = 0;
      _selectedPlayers = [];
      _playerTestResults = {};
    });
  }

  @override
  Widget build(BuildContext context) {
    return AdaptiveScaffold(
      title: 'Team Skating Assessment',
      backgroundColor: Colors.grey[100],
      leading: _buildLeadingButton(),
      actions: _buildAppBarActions(),
      body: LoadingOverlay(
        isLoading: _isLoading,
        message: _getLoadingMessage(),
        color: Colors.cyanAccent,
        child: AdaptiveLayout(
          builder: (deviceType, isLandscape) {
            return Column(
              children: [
                _buildStateIndicator(deviceType),
                Expanded(child: _buildStateContent(deviceType, isLandscape)),
              ],
            );
          },
        ),
      ),
    );
  }

  String _getLoadingMessage() {
    switch (_currentState) {
      case AssessmentState.setup:
        return 'Preparing assessment...';
      case AssessmentState.execution:
        return 'Processing test results...';
      case AssessmentState.results:
        return 'Calculating performance metrics...';
    }
  }

  Widget? _buildLeadingButton() {
    if (_currentState != AssessmentState.setup) {
      return IconButton(
        icon: const Icon(Icons.close),
        onPressed: () {
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: ResponsiveText('Cancel Assessment?', baseFontSize: 18),
              content: ResponsiveText('Progress will be lost. Are you sure?', baseFontSize: 14),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: ResponsiveText('No', baseFontSize: 14),
                ),
                ResponsiveButton(
                  text: 'Yes',
                  onPressed: () {
                    Navigator.pop(context);
                    _resetAssessment();
                  },
                  baseHeight: 36,
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                ),
              ],
            ),
          );
        },
      );
    }
    return null;
  }

  List<Widget> _buildAppBarActions() {
    if (_currentState == AssessmentState.execution) {
      return [
        TextButton.icon(
          icon: Icon(Icons.stop_circle, color: Colors.white, size: ResponsiveConfig.iconSize(context, 20)),
          label: ResponsiveText('End Session', baseFontSize: 14, style: TextStyle(color: Colors.white)),
          onPressed: () => _showEndSessionDialog(),
        ),
      ];
    }
    return [];
  }

  Widget _buildStateIndicator(DeviceType deviceType) {
    return ResponsiveCard(
      padding: ResponsiveConfig.paddingSymmetric(context, horizontal: 16, vertical: 12),
      margin: ResponsiveConfig.paddingSymmetric(context, horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: AssessmentState.values.asMap().entries.map((entry) {
          final state = entry.value;
          final index = entry.key;
          final isActive = state == _currentState;
          final isCompleted = _getStateIndex(state) < _getStateIndex(_currentState);
          
          return Row(
            children: [
              _buildStateStep(state, isActive, isCompleted),
              if (index < AssessmentState.values.length - 1)
                Container(
                  width: ResponsiveConfig.dimension(context, 40),
                  height: 2,
                  margin: ResponsiveConfig.paddingSymmetric(context, horizontal: 8),
                  color: isCompleted ? Colors.green : Colors.grey[300],
                ),
            ],
          );
        }).toList(),
      ),
    );
  }

  Widget _buildStateStep(AssessmentState state, bool isActive, bool isCompleted) {
    final stepSize = ResponsiveConfig.dimension(context, 32);
    
    return Column(
      children: [
        Container(
          width: stepSize,
          height: stepSize,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isCompleted ? Colors.green : (isActive ? Colors.cyanAccent : Colors.grey[300]),
          ),
          child: Center(
            child: isCompleted
              ? Icon(Icons.check, color: Colors.white, size: ResponsiveConfig.iconSize(context, 16))
              : ResponsiveText(
                  '${_getStateIndex(state) + 1}',
                  baseFontSize: 14,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: isActive ? Colors.black87 : Colors.grey[600],
                  ),
                ),
          ),
        ),
        ResponsiveSpacing(multiplier: 0.5),
        ResponsiveText(
          _getStateTitle(state),
          baseFontSize: 12,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: isActive ? Colors.blueGrey[800] : Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Widget _buildStateContent(DeviceType deviceType, bool isLandscape) {
    switch (_currentState) {
      case AssessmentState.setup:
        return _buildSetupState(deviceType, isLandscape);
      case AssessmentState.execution:
        return _buildExecutionState(deviceType, isLandscape);
      case AssessmentState.results:
        return _buildResultsState(deviceType, isLandscape);
    }
  }

  Widget _buildSetupState(DeviceType deviceType, bool isLandscape) {
    return SingleChildScrollView(
      padding: ResponsiveConfig.paddingAll(context, 16),
      child: ConstrainedBox(
        constraints: ResponsiveConfig.constraints(
          context,
          maxWidth: deviceType == DeviceType.desktop ? 800 : null,
        ),
        child: TeamSkatingSetupView(
          onStart: _startAssessment,
        ),
      ),
    );
  }

  Widget _buildExecutionState(DeviceType deviceType, bool isLandscape) {
    if (_assessment.isEmpty || _selectedPlayers.isEmpty) {
      return Center(
        child: ResponsiveText(
          'Assessment data not available',
          baseFontSize: 16,
          style: TextStyle(color: Colors.red),
        ),
      );
    }

    if (deviceType == DeviceType.desktop) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 7,
            child: TeamSkatingExecutionView(
              assessment: _assessment,
              players: _selectedPlayers,
              playerTestResults: _playerTestResults,
              onAddResult: _addTestResult,
              onComplete: _completeAssessment,
            ),
          ),
          Container(
            width: ResponsiveConfig.dimension(context, 300),
            child: _buildExecutionSidebar(),
          ),
        ],
      );
    } else {
      return TeamSkatingExecutionView(
        assessment: _assessment,
        players: _selectedPlayers,
        playerTestResults: _playerTestResults,
        onAddResult: _addTestResult,
        onComplete: _completeAssessment,
      );
    }
  }

  Widget _buildExecutionSidebar() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[50],
        border: Border(left: BorderSide(color: Colors.grey[300]!)),
      ),
      child: SingleChildScrollView(
        padding: ResponsiveConfig.paddingAll(context, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ResponsiveText(
              'Assessment Progress',
              baseFontSize: 18,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.blueGrey[800],
              ),
            ),
            ResponsiveSpacing(multiplier: 3),
            _buildProgressOverview(),
            ResponsiveSpacing(multiplier: 3),
            _buildTestInstructions(),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressOverview() {
    final totalTests = _calculateTotalTests();
    final completedTests = _calculateCompletedTests();
    final progress = totalTests > 0 ? completedTests / totalTests : 0.0;

    return ResponsiveCard(
      padding: ResponsiveConfig.paddingAll(context, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ResponsiveText(
            'Overall Progress',
            baseFontSize: 14,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.blue[700],
            ),
          ),
          ResponsiveSpacing(multiplier: 1),
          LinearProgressIndicator(
            value: progress,
            backgroundColor: Colors.grey[200],
            valueColor: AlwaysStoppedAnimation<Color>(Colors.cyanAccent),
            minHeight: ResponsiveConfig.dimension(context, 8),
          ),
          ResponsiveSpacing(multiplier: 1),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              ResponsiveText(
                '$completedTests / $totalTests tests',
                baseFontSize: 12,
                style: TextStyle(color: Colors.blue[600]),
              ),
              ResponsiveText(
                '${(progress * 100).toInt()}%',
                baseFontSize: 12,
                style: TextStyle(
                  color: Colors.blue[600],
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTestInstructions() {
    final groups = _assessment['groups'] as List? ?? [];
    
    return ResponsiveCard(
      padding: ResponsiveConfig.paddingAll(context, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ResponsiveText(
            'Test Categories',
            baseFontSize: 14,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.green[700],
            ),
          ),
          ResponsiveSpacing(multiplier: 1),
          ...groups.map((group) => _buildTestCategoryItem(group)).toList(),
        ],
      ),
    );
  }

  Widget _buildTestCategoryItem(Map<String, dynamic> group) {
    final tests = group['tests'] as List? ?? [];
    
    return Container(
      margin: ResponsiveConfig.paddingSymmetric(context, vertical: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ResponsiveText(
            group['name'] ?? 'Test Group',
            baseFontSize: 12,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.green[800],
            ),
          ),
          ResponsiveText(
            group['description'] ?? '',
            baseFontSize: 11,
            style: TextStyle(color: Colors.green[600]),
          ),
          ResponsiveText(
            '${tests.length} tests',
            baseFontSize: 10,
            style: TextStyle(color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }

  Widget _buildResultsState(DeviceType deviceType, bool isLandscape) {
    if (deviceType == DeviceType.desktop) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 7,
            child: _buildMainResultsContent(),
          ),
          Container(
            width: ResponsiveConfig.dimension(context, 320),
            child: _buildResultsSidebar(),
          ),
        ],
      );
    } else {
      return _buildMainResultsContent();
    }
  }

  Widget _buildMainResultsContent() {
    return TeamSkatingResultsView(
      assessment: _assessment,
      teamId: _teamId,
      teamName: _teamName,
      playerTestResults: _playerTestResults,
      onReset: _resetAssessment,
      onSave: _saveAssessment,
    );
  }

  Widget _buildResultsSidebar() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[50],
        border: Border(left: BorderSide(color: Colors.grey[300]!)),
      ),
      child: SingleChildScrollView(
        padding: ResponsiveConfig.paddingAll(context, 16),
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
            ResponsiveSpacing(multiplier: 3),
            _buildQuickActions(),
            ResponsiveSpacing(multiplier: 4),
            _buildAssessmentSummary(),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActions() {
    return Column(
      children: [
        ResponsiveButton(
          text: 'Export Results',
          onPressed: _exportResults,
          baseHeight: 48,
          width: double.infinity,
          backgroundColor: Colors.green[600],
          foregroundColor: Colors.white,
          prefix: Icon(Icons.download, color: Colors.white),
        ),
        ResponsiveSpacing(multiplier: 1),
        ResponsiveButton(
          text: 'Share Report',
          onPressed: _shareResults,
          baseHeight: 48,
          width: double.infinity,
          backgroundColor: Colors.blue[600],
          foregroundColor: Colors.white,
          prefix: Icon(Icons.share, color: Colors.white),
        ),
        ResponsiveSpacing(multiplier: 2),
        ResponsiveButton(
          text: 'New Assessment',
          onPressed: _resetAssessment,
          baseHeight: 48,
          width: double.infinity,
          backgroundColor: Colors.cyanAccent,
          foregroundColor: Colors.black87,
          prefix: Icon(Icons.refresh, color: Colors.black87),
        ),
      ],
    );
  }

  Widget _buildAssessmentSummary() {
    return ResponsiveCard(
      padding: ResponsiveConfig.paddingAll(context, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ResponsiveText(
            'Assessment Summary',
            baseFontSize: 14,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.blue[700],
            ),
          ),
          ResponsiveSpacing(multiplier: 1),
          _buildSummaryRow('Team', _teamName.isNotEmpty ? _teamName : 'Unknown'),
          _buildSummaryRow('Type', _assessmentType),
          _buildSummaryRow('Players', '${_selectedPlayers.length}'),
          _buildSummaryRow('Tests', '${_calculateTotalTests()}'),
          _buildSummaryRow('Completed', '${_calculateCompletedTests()}'),
          _buildSummaryRow('Date', DateTime.now().toString().split(' ')[0]),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value) {
    return Padding(
      padding: ResponsiveConfig.paddingSymmetric(context, vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: ResponsiveConfig.dimension(context, 80),
            child: ResponsiveText(
              '$label:',
              baseFontSize: 12,
              style: TextStyle(
                color: Colors.blue[600],
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: ResponsiveText(
              value,
              baseFontSize: 12,
              style: TextStyle(color: Colors.blue[800]),
            ),
          ),
        ],
      ),
    );
  }

  void _startAssessment(String assessmentType, String teamName, List<Player> players) {
    setState(() {
      _isLoading = true;
    });

    _assessmentType = assessmentType;
    _teamName = teamName;
    _teamId = 1; // Placeholder; replace with actual teamId
    _selectedPlayers = players;
    _assessment = {
      'type': assessmentType,
      'title': assessmentType,
      'description': 'Team skating assessment',
      'position': 'forward',
      'groups': [
        {
          'id': '1',
          'name': 'Speed Tests',
          'description': 'Forward and backward skating speed',
          'tests': [
            {'id': 'forward_skate', 'title': 'Forward Skate', 'category': 'Speed'},
            {'id': 'backward_skate', 'title': 'Backward Skate', 'category': 'Speed'},
          ],
        },
        {
          'id': '2',
          'name': 'Agility Tests',
          'description': 'Lateral movement and transitions',
          'tests': [
            {'id': 'lateral_movement', 'title': 'Lateral Movement', 'category': 'Agility'},
            {'id': 'transition', 'title': 'Transition Skate', 'category': 'Agility'},
          ],
        },
      ],
    };

    // Initialize result storage for all players
    _playerTestResults = {};
    for (var player in _selectedPlayers) {
      _playerTestResults[player.id.toString()] = {};
    }

    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _currentState = AssessmentState.execution;
        });
      }
    });
  }

  void _addTestResult(String playerId, String testId, Map<String, dynamic> result) {
    if (_playerTestResults.containsKey(playerId)) {
      setState(() {
        _playerTestResults[playerId]![testId] = result;
      });
    }
  }

  void _completeAssessment() {
    setState(() {
      _isLoading = true;
    });

    Future.delayed(const Duration(milliseconds: 800), () {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _currentState = AssessmentState.results;
        });
      }
    });
  }

  // FIXED: Completely corrected parameter types and order for saveTeamSkating method call
  Future<void> _saveAssessment() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final appState = Provider.of<AppState>(context, listen: false);

      // Convert _playerTestResults to Map<String, Map<String, double>> for skatingData
      final Map<String, Map<String, double>> convertedResults = {};
      for (var playerId in _playerTestResults.keys) {
        convertedResults[playerId] = {};
        for (var testId in _playerTestResults[playerId]!.keys) {
          final testResult = _playerTestResults[playerId]![testId]!;
          final timeValue = testResult['time'];
          if (timeValue is double) {
            convertedResults[playerId]![testId] = timeValue;
          } else if (timeValue is num) {
            convertedResults[playerId]![testId] = timeValue.toDouble();
          } else {
            convertedResults[playerId]![testId] = 0.0; // Default fallback
          }
        }
      }

      // Convert _assessment to Skating object
      final skatingAssessment = Skating(
        id: 0,
        date: DateTime.now(),
        ageGroup: '',
        position: 'forward',
        testTimes: convertedResults.isNotEmpty
            ? convertedResults[convertedResults.keys.first]!
                .map((key, value) => MapEntry(key, value))
            : {},
        scores: {'Overall': 0.0},
        title: _assessmentType,
        description: 'Team skating assessment',
        assessmentType: _assessmentType,
        teamAssessment: true,
        teamId: _teamId,
        teamName: _teamName,
      );

      // Get or generate assessmentId
      final assessmentId = appState.getCurrentSkatingAssessmentId() ?? DateTime.now().millisecondsSinceEpoch.toString();

      // Prepare skatingData with results
      final skatingData = skatingAssessment.toJson()
        ..['test_results'] = convertedResults; // Add test results to skatingData

      // FIXED: Call saveTeamSkating with correct parameter types and order
      // Method signature: saveTeamSkating(Map<String, dynamic> skatingData, int teamId, String assessmentId, List<int> playerIds)
      final success = await appState.saveTeamSkating(
        skatingData,                                                  // Map<String, dynamic>
        _teamId,                                                     // int (team ID)
        assessmentId,                                                // String (assessment ID)
        _selectedPlayers.map((p) => p.id).whereType<int>().toList(), // List<int> (player IDs)
      );

      // Show appropriate message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            success
                ? 'Team assessment saved successfully!'
                : 'Assessment saved with some errors. Some data may only be available offline.',
          ),
        ),
      );

      if (success) {
        _resetAssessment();
      }
    } catch (e) {
      print('Team Skating Assessment Error: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error saving assessment: $e')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _showEndSessionDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: ResponsiveText('End Assessment Session?', baseFontSize: 18),
        content: ResponsiveText('Do you want to end the session and view results?', baseFontSize: 14),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: ResponsiveText('Cancel', baseFontSize: 14),
          ),
          ResponsiveButton(
            text: 'End Session',
            onPressed: () {
              Navigator.pop(context);
              _completeAssessment();
            },
            baseHeight: 36,
            backgroundColor: Colors.orange,
            foregroundColor: Colors.white,
          ),
        ],
      ),
    );
  }

  void _exportResults() {
    // Implementation for exporting results
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Exporting results...'),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _shareResults() {
    // Implementation for sharing results
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Sharing results...'),
        backgroundColor: Colors.blue,
      ),
    );
  }

  // Calculation helpers
  int _calculateTotalTests() {
    final groups = _assessment['groups'] as List? ?? [];
    int total = 0;
    for (var group in groups) {
      final tests = group['tests'] as List? ?? [];
      total += tests.length * _selectedPlayers.length;
    }
    return total;
  }

  int _calculateCompletedTests() {
    int completed = 0;
    for (var playerResults in _playerTestResults.values) {
      completed += playerResults.length;
    }
    return completed;
  }

  // Helper methods
  int _getStateIndex(AssessmentState state) {
    return AssessmentState.values.indexOf(state);
  }

  String _getStateTitle(AssessmentState state) {
    switch (state) {
      case AssessmentState.setup:
        return 'Setup';
      case AssessmentState.execution:
        return 'Execute';
      case AssessmentState.results:
        return 'Results';
    }
  }
}