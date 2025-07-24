// lib/screens/players/tabs/player_history_tab.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:hockey_shot_tracker/models/player.dart';
import 'package:hockey_shot_tracker/models/shot.dart';
import 'package:hockey_shot_tracker/models/skating.dart';
import 'package:hockey_shot_tracker/models/shot_assessment.dart';
import 'package:hockey_shot_tracker/providers/app_state.dart';
import 'package:hockey_shot_tracker/widgets/core/list/standard_card.dart';
import 'package:hockey_shot_tracker/widgets/core/list/status_badge.dart';
import 'package:hockey_shot_tracker/widgets/core/selection/filter_chip_group.dart';
import 'package:hockey_shot_tracker/widgets/core/selection/toggle_button_group.dart';
import 'package:hockey_shot_tracker/services/dialog_service.dart';
import 'package:hockey_shot_tracker/widgets/domain/assessment/shot/shot_assessment_results_screen.dart';
import 'package:hockey_shot_tracker/widgets/domain/assessment/skating/skating_assessment_results_screen.dart';
import 'package:intl/intl.dart';

enum HistoryType { shooting, skating, combined }

class PlayerHistoryTab extends StatefulWidget {
  final Player player;
  final List<Shot> shots;
  final List<Skating> skatings;
  final VoidCallback? onRecordSkating;

  const PlayerHistoryTab({
    Key? key,
    required this.player,
    required this.shots,
    this.skatings = const [],
    this.onRecordSkating,
  }) : super(key: key);

  @override
  State<PlayerHistoryTab> createState() => _PlayerHistoryTabState();
}

class _PlayerHistoryTabState extends State<PlayerHistoryTab> {
  HistoryType _currentHistoryType = HistoryType.shooting;
  
  // Shooting filters
  List<String> _selectedShotTypes = ['All'];
  List<String> _selectedZones = ['All'];
  List<Shot> _filteredShots = [];
  
  // Skating filters
  List<String> _selectedSkatingTypes = ['All'];
  List<Skating> _filteredSkatings = [];
  
  // Assessment data
  List<Map<String, dynamic>> _shotAssessments = [];
  List<Map<String, dynamic>> _skatingAssessments = [];
  
  bool _isLoadingAssessments = false;
  String _viewMode = 'assessments'; // 'assessments' or 'individual' or 'all'

  @override
  void initState() {
    super.initState();
    _loadAssessments();
    _updateFilteredData();
  }

  @override
  void didUpdateWidget(PlayerHistoryTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.shots != oldWidget.shots || 
        widget.skatings != oldWidget.skatings ||
        widget.player.id != oldWidget.player.id) {
      _loadAssessments();
      _updateFilteredData();
    }
  }

  Future<void> _loadAssessments() async {
    if (!mounted) return;

    setState(() {
      _isLoadingAssessments = true;
    });

    try {
      final appState = Provider.of<AppState>(context, listen: false);

      // Load shot assessments (existing logic)
      final assessmentShots = widget.shots.where((shot) => 
        shot.isFromAssessment && shot.assessmentId != null).toList();
      
      print('🔍 Found ${assessmentShots.length} shots from assessments');
      
      // Group shots by assessment ID
      final Map<String, List<Shot>> groupedByAssessment = {};
      for (final shot in assessmentShots) {
        final assessmentId = shot.assessmentId!;
        if (!groupedByAssessment.containsKey(assessmentId)) {
          groupedByAssessment[assessmentId] = [];
        }
        groupedByAssessment[assessmentId]!.add(shot);
      }
      
      print('📊 Grouped into ${groupedByAssessment.length} shot assessments');
      
      // Create shot assessment summaries
      final List<Map<String, dynamic>> shotAssessments = [];
      for (final entry in groupedByAssessment.entries) {
        final assessmentId = entry.key;
        final shots = entry.value;
        
        shots.sort((a, b) => a.timestamp.compareTo(b.timestamp));
        final firstShot = shots.first;
        final lastShot = shots.last;
        
        final totalShots = shots.length;
        final successfulShots = shots.where((s) => s.success).length;
        final successRate = totalShots > 0 ? successfulShots / totalShots : 0.0;
        
        String performanceLevel;
        Color performanceColor;
        if (successRate >= 0.8) {
          performanceLevel = 'Excellent';
          performanceColor = Colors.green;
        } else if (successRate >= 0.6) {
          performanceLevel = 'Good';
          performanceColor = Colors.lightGreen;
        } else if (successRate >= 0.4) {
          performanceLevel = 'Average';
          performanceColor = Colors.orange;
        } else {
          performanceLevel = 'Needs Improvement';
          performanceColor = Colors.red;
        }
        
        final Map<String, dynamic> assessmentMap = {
          'id': assessmentId,
          'date': firstShot.timestamp,
          'endDate': lastShot.timestamp,
          'totalShots': totalShots,
          'successfulShots': successfulShots,
          'successRate': successRate,
          'performanceLevel': performanceLevel,
          'performanceColor': performanceColor,
          'shots': shots,
          'title': 'Shot Assessment',
          'type': shots.first.type ?? 'Mixed',
        };
        
        shotAssessments.add(assessmentMap);
      }
      
      shotAssessments.sort((a, b) => 
        (b['date'] as DateTime).compareTo(a['date'] as DateTime));

      // FIXED: Load skating assessments using fetchSkatings
      List<Map<String, dynamic>> skatingAssessments = [];
      try {
        // Fetch all skating data for the player using fetchSkatings
        final allSkatingData = await appState.api.fetchSkatings(widget.player.id!);
        print('🛼 Found ${allSkatingData.length} total skating sessions');
        
        // FIXED: Filter for skating sessions that are from assessments and have assessment IDs
        final assessmentSkatings = allSkatingData.where((skating) => 
          skating.isAssessment && skating.assessmentId != null && skating.assessmentId.toString().isNotEmpty).toList();
        
        print('🛼 Found ${assessmentSkatings.length} skating sessions from assessments');
        
        // Group skating sessions by assessment ID
        final Map<String, List<Skating>> groupedSkatingByAssessment = {};
        for (final skating in assessmentSkatings) {
          final assessmentId = skating.assessmentId.toString(); // Convert to String to handle both int and String cases
          if (!groupedSkatingByAssessment.containsKey(assessmentId)) {
            groupedSkatingByAssessment[assessmentId] = [];
          }
          groupedSkatingByAssessment[assessmentId]!.add(skating);
        }
        
        print('📊 Grouped into ${groupedSkatingByAssessment.length} skating assessments');
        
        // Create skating assessment summaries as Map<String, dynamic>
        for (final entry in groupedSkatingByAssessment.entries) {
          final assessmentId = entry.key;
          final skatingSessions = entry.value;
          
          // Sort sessions by date to get the assessment date
          skatingSessions.sort((a, b) => a.date.compareTo(b.date));
          final firstSession = skatingSessions.first;
          final lastSession = skatingSessions.last;
          
          // Calculate summary stats from skating sessions
          final totalSessions = skatingSessions.length;
          final averageScore = skatingSessions
              .map((s) => s.scores.values.isNotEmpty 
                  ? s.scores.values.reduce((a, b) => a + b) / s.scores.length 
                  : 0.0)
              .reduce((a, b) => a + b) / totalSessions;
          
          // Determine performance level based on average score
          String performanceLevel;
          Color performanceColor;
          if (averageScore >= 8.0) {
            performanceLevel = 'Elite';
            performanceColor = Colors.green;
          } else if (averageScore >= 6.5) {
            performanceLevel = 'Advanced';
            performanceColor = Colors.lightGreen;
          } else if (averageScore >= 5.0) {
            performanceLevel = 'Proficient';
            performanceColor = Colors.orange;
          } else if (averageScore >= 3.5) {
            performanceLevel = 'Developing';
            performanceColor = Colors.deepOrange;
          } else {
            performanceLevel = 'Basic';
            performanceColor = Colors.red;
          }
          
          final Map<String, dynamic> skatingAssessmentMap = {
            'id': assessmentId,
            'date': firstSession.date,
            'endDate': lastSession.date,
            'totalSessions': totalSessions,
            'averageScore': averageScore,
            'performanceLevel': performanceLevel,
            'performanceColor': performanceColor,
            'skatingSessions': skatingSessions,
            'title': firstSession.title ?? 'Skating Assessment',
            'type': firstSession.assessmentType,
            'position': firstSession.position,
            'ageGroup': firstSession.ageGroup,
            // Aggregate test results from all sessions
            'testResults': _aggregateTestResults(skatingSessions),
          };
          
          skatingAssessments.add(skatingAssessmentMap);
        }
        
        // Sort skating assessments by date (most recent first)
        skatingAssessments.sort((a, b) => 
          (b['date'] as DateTime).compareTo(a['date'] as DateTime));
        
        print('📱 Skating assessments processed: ${skatingAssessments.length}');
        
      } catch (e) {
        print('❌ Error loading skating assessments: $e');
        skatingAssessments = []; // Ensure it's not null
      }

      if (mounted) {
        setState(() {
          _shotAssessments = shotAssessments;
          _skatingAssessments = skatingAssessments; // Now using Map<String, dynamic>
          _isLoadingAssessments = false;
        });
        
        print('📱 UI Updated - Shot assessments: ${_shotAssessments.length}, Skating assessments: ${_skatingAssessments.length}');
      }
    } catch (e) {
      print('💥 Error loading assessments: $e');
      if (mounted) {
        setState(() {
          _shotAssessments = <Map<String, dynamic>>[];
          _skatingAssessments = <Map<String, dynamic>>[];
          _isLoadingAssessments = false;
        });
      }
    }
  }

  // Helper method to aggregate test results from multiple skating sessions
  Map<String, double> _aggregateTestResults(List<Skating> skatingSessions) {
    final Map<String, List<double>> testTimes = {};
    
    for (final session in skatingSessions) {
      session.testTimes.forEach((testName, time) {
        if (time != null) {
          if (!testTimes.containsKey(testName)) {
            testTimes[testName] = [];
          }
          testTimes[testName]!.add(time);
        }
      });
    }
    
    // Calculate average times for each test
    final Map<String, double> aggregatedResults = {};
    testTimes.forEach((testName, times) {
      if (times.isNotEmpty) {
        aggregatedResults[testName] = times.reduce((a, b) => a + b) / times.length;
      }
    });
    
    return aggregatedResults;
  }

  // Update method to open skating assessment results
  Future<void> _openSkatingAssessmentResults(Map<String, dynamic> assessmentData) async {
    try {
      final skatingSessions = assessmentData['skatingSessions'] as List<Skating>;
      final testResults = assessmentData['testResults'] as Map<String, double>;
      
      // Use the first session as the primary assessment data
      final primarySession = skatingSessions.first;
      
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => SkatingAssessmentResultsScreen(
            assessment: primarySession,
            player: widget.player,
            testResults: testResults,
            assessmentId: assessmentData['id'] as String?, // Pass assessment ID
            onReset: () {
              Navigator.pop(context);
            },
            onSave: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Assessment already saved')),
              );
            },
          ),
        ),
      );
    } catch (e) {
      print('Error opening skating assessment results: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error opening assessment: $e')),
      );
    }
  }

  Future<void> _openAssessmentResults(Map<String, dynamic> assessment) async {
    try {
      final shots = assessment['shots'] as List<Shot>;
      
      // Convert shots to the format expected by ShotAssessmentResultsScreen
      final Map<String, List<Map<String, dynamic>>> shotResults = {};
      
      // Group shots by group index or create a single group
      final Map<int, List<Shot>> groupedShots = {};
      for (final shot in shots) {
        final groupIndex = shot.groupIndex ?? 0;
        if (!groupedShots.containsKey(groupIndex)) {
          groupedShots[groupIndex] = [];
        }
        groupedShots[groupIndex]!.add(shot);
      }
      
      // Convert to the expected format
      for (final entry in groupedShots.entries) {
        final groupIndex = entry.key;
        final groupShots = entry.value;
        
        shotResults[groupIndex.toString()] = groupShots.map((shot) => {
          'zone': shot.zone,
          'type': shot.type,
          'success': shot.success,
          'outcome': shot.outcome,
          'power': shot.power,
          'quick_release': shot.quickRelease,
          'timestamp': shot.timestamp.toIso8601String(),
          'assessment_id': shot.assessmentId,
          'group_index': shot.groupIndex,
          'group_id': shot.groupId,
          'intended_zone': shot.intendedZone,
        }).toList();
      }
      
      // Create assessment object for the results screen
      final assessmentData = {
        'id': assessment['id'],
        'title': assessment['title'],
        'playerName': widget.player.name,
        'playerId': widget.player.id,
        'date': assessment['date'],
        'groups': groupedShots.entries.map((entry) => {
          'id': entry.key,
          'name': 'Group ${entry.key + 1}',
          'shots': entry.value.length,
          'location': 'Assessment Zone',
          'defaultType': entry.value.first.type ?? 'Wrist Shot',
        }).toList(),
      };
      
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ShotAssessmentResultsScreen(
            assessment: assessmentData,
            shotResults: shotResults,
            onReset: () {
              Navigator.pop(context);
            },
            onSave: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Assessment already saved')),
              );
            },
            playerId: widget.player.id,
            assessmentId: assessment['id'] as String,
          ),
        ),
      );
    } catch (e) {
      print('Error opening assessment results: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error opening assessment: $e')),
      );
    }
  }

  void _navigateToShotAssessment() {
    Navigator.pushNamed(context, '/shot-assessment').then((_) {
      // Refresh assessments when returning from assessment
      _loadAssessments();
    });
  }

  void _navigateToSkatingAssessment() {
    Navigator.pushNamed(context, '/skating-assessment').then((_) {
      // Refresh assessments when returning from assessment
      _loadAssessments();
    });
  }

  // Rest of the existing methods remain the same...
  void _onHistoryTypeChanged(HistoryType type) {
    setState(() {
      _currentHistoryType = type;
      _updateFilteredData();
    });
  }

  void _onShotTypeFilterChanged(String type, bool selected) {
    setState(() {
      if (type == 'All') {
        if (selected) {
          _selectedShotTypes = ['All'];
        } else {
          _selectedShotTypes = [];
        }
      } else {
        _selectedShotTypes.remove('All');
        if (selected) {
          _selectedShotTypes.add(type);
        } else {
          _selectedShotTypes.remove(type);
        }
        if (_selectedShotTypes.isEmpty) {
          _selectedShotTypes = ['All'];
        }
      }
      _updateFilteredData();
    });
  }

  void _onZoneFilterChanged(String zone, bool selected) {
    setState(() {
      if (zone == 'All') {
        if (selected) {
          _selectedZones = ['All'];
        } else {
          _selectedZones = [];
        }
      } else {
        _selectedZones.remove('All');
        if (selected) {
          _selectedZones.add(zone);
        } else {
          _selectedZones.remove(zone);
        }
        if (_selectedZones.isEmpty) {
          _selectedZones = ['All'];
        }
      }
      _updateFilteredData();
    });
  }

  void _onSkatingTypeFilterChanged(String type, bool selected) {
    setState(() {
      if (type == 'All') {
        if (selected) {
          _selectedSkatingTypes = ['All'];
        } else {
          _selectedSkatingTypes = [];
        }
      } else {
        _selectedSkatingTypes.remove('All');
        if (selected) {
          _selectedSkatingTypes.add(type);
        } else {
          _selectedSkatingTypes.remove(type);
        }
        if (_selectedSkatingTypes.isEmpty) {
          _selectedSkatingTypes = ['All'];
        }
      }
      _updateFilteredData();
    });
  }

  void _updateFilteredData() {
    setState(() {
      // Filter shots
      List<Shot> filteredShots = widget.shots;

      if (_viewMode == 'assessments') {
        filteredShots = filteredShots.where((shot) => shot.isFromAssessment).toList();
      } else if (_viewMode == 'individual') {
        filteredShots = filteredShots.where((shot) => shot.isIndividual).toList();
      }

      if (!_selectedShotTypes.contains('All')) {
        filteredShots = filteredShots.where((shot) => _selectedShotTypes.contains(shot.type)).toList();
      }
      if (!_selectedZones.contains('All')) {
        filteredShots = filteredShots.where((shot) => _selectedZones.contains(shot.zone)).toList();
      }
      _filteredShots = filteredShots;

      // Filter skating sessions
      List<Skating> filteredSkatings = widget.skatings;

      if (_viewMode == 'assessments') {
        filteredSkatings = filteredSkatings.where((skating) => skating.isAssessment).toList();
      } else if (_viewMode == 'individual') {
        filteredSkatings = filteredSkatings.where((skating) => !skating.isAssessment).toList();
      }

      if (!_selectedSkatingTypes.contains('All')) {
        filteredSkatings = filteredSkatings.where((skating) {
          if (_selectedSkatingTypes.contains('Assessment')) {
            return skating.isAssessment;
          } else if (_selectedSkatingTypes.contains('Practice')) {
            return !skating.isAssessment;
          }
          return true;
        }).toList();
      }
      _filteredSkatings = filteredSkatings;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_hasNoData()) {
      return _buildEmptyState(context);
    }

    return Column(
      children: [
        _buildHistoryTypeSelector(),
        _buildViewControls(),
        _buildFilterSection(),
        Expanded(
          child: _buildContent(),
        ),
      ],
    );
  }

  Widget _buildHistoryTypeSelector() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ToggleButtonGroup<HistoryType>(
        options: const [HistoryType.shooting, HistoryType.skating, HistoryType.combined],
        selectedOption: _currentHistoryType,
        onSelected: _onHistoryTypeChanged,
        labelBuilder: (type) {
          switch (type) {
            case HistoryType.shooting:
              return 'Shooting';
            case HistoryType.skating:
              return 'Skating';
            case HistoryType.combined:
              return 'Combined';
          }
        },
        defaultSelectedColor: Colors.blue,
        borderRadius: BorderRadius.circular(8),
      ),
    );
  }

  bool _hasNoData() {
    switch (_currentHistoryType) {
      case HistoryType.shooting:
        return widget.shots.isEmpty && _shotAssessments.isEmpty;
      case HistoryType.skating:
        return widget.skatings.isEmpty && _skatingAssessments.isEmpty;
      case HistoryType.combined:
        return widget.shots.isEmpty && widget.skatings.isEmpty && 
               _shotAssessments.isEmpty && _skatingAssessments.isEmpty;
    }
  }

  Widget _buildViewControls() {
    if (_currentHistoryType == HistoryType.combined) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          children: [
            Text(
              'View:',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.blueGrey[700],
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: FilterChipGroup<String>(
                options: const ['assessments', 'sessions', 'all'],
                selectedOptions: [_viewMode],
                onSelected: (mode, selected) {
                  if (selected) {
                    setState(() {
                      _viewMode = mode;
                      _updateFilteredData();
                    });
                  }
                },
                labelBuilder: (option) {
                  switch (option) {
                    case 'assessments':
                      return 'Assessments';
                    case 'sessions':
                      return 'Practice Sessions';
                    case 'all':
                      return 'All Activity';
                    default:
                      return option;
                  }
                },
                selectedColor: Colors.blue,
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Text(
            'View:',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.blueGrey[700],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: FilterChipGroup<String>(
              options: const ['assessments', 'individual', 'all'],
              selectedOptions: [_viewMode],
              onSelected: (mode, selected) {
                if (selected) {
                  setState(() {
                    _viewMode = mode;
                    _updateFilteredData();
                  });
                }
              },
              labelBuilder: (option) {
                switch (option) {
                  case 'assessments':
                    return 'Assessments';
                  case 'individual':
                    return 'Individual Sessions';
                  case 'all':
                    return 'All Activity';
                  default:
                    return option;
                }
              },
              selectedColor: Colors.blue,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    if (_isLoadingAssessments) {
      return const Center(child: CircularProgressIndicator());
    }

    switch (_currentHistoryType) {
      case HistoryType.shooting:
        return _buildShootingHistory();
      case HistoryType.skating:
        return _buildSkatingHistory();
      case HistoryType.combined:
        return _buildCombinedHistory();
    }
  }

  Widget _buildSkatingHistory() {
    if (_viewMode == 'assessments') {
      return _buildSkatingAssessmentsList();
    } else {
      return _buildSkatingSessionsList();
    }
  }

  Widget _buildShootingHistory() {
    if (_viewMode == 'assessments') {
      return _buildShootingAssessmentsList();
    } else {
      return _buildShotsList();
    }
  }

  Widget _buildCombinedHistory() {
    if (_viewMode == 'assessments') {
      return _buildCombinedAssessmentsList();
    } else if (_viewMode == 'sessions') {
      return _buildCombinedSessionsList();
    } else {
      return _buildAllCombinedActivity();
    }
  }

  // Updated skating assessments list to use Map<String, dynamic>
  Widget _buildSkatingAssessmentsList() {
    if (_skatingAssessments.isEmpty) {
      return _buildNoSkatingAssessmentsState();
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _skatingAssessments.length,
      itemBuilder: (context, index) {
        final assessment = _skatingAssessments[index];
        return _buildSkatingAssessmentCard(assessment);
      },
    );
  }

  Widget _buildShootingAssessmentsList() {
    if (_shotAssessments.isEmpty) {
      return _buildNoShootingAssessmentsState();
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _shotAssessments.length,
      itemBuilder: (context, index) {
        final assessment = _shotAssessments[index];
        return _buildShotAssessmentCard(assessment);
      },
    );
  }

  Widget _buildCombinedAssessmentsList() {
    final combinedAssessments = <Map<String, dynamic>>[];
    
    for (final assessment in _shotAssessments) {
      combinedAssessments.add({
        'type': 'shot',
        'data': assessment,
        'date': assessment['date'],
      });
    }
    
    for (final assessment in _skatingAssessments) {
      combinedAssessments.add({
        'type': 'skating',
        'data': assessment,
        'date': assessment['date'],
      });
    }
    
    combinedAssessments.sort((a, b) => (b['date'] as DateTime).compareTo(a['date'] as DateTime));
    
    if (combinedAssessments.isEmpty) {
      return _buildNoAssessmentsState();
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: combinedAssessments.length,
      itemBuilder: (context, index) {
        final item = combinedAssessments[index];
        if (item['type'] == 'shot') {
          return _buildShotAssessmentCard(item['data'] as Map<String, dynamic>);
        } else {
          return _buildSkatingAssessmentCard(item['data'] as Map<String, dynamic>);
        }
      },
    );
  }

  // Updated skating assessment card to work with Map<String, dynamic>
  Widget _buildSkatingAssessmentCard(Map<String, dynamic> assessment) {
    final date = assessment['date'] as DateTime;
    final totalSessions = assessment['totalSessions'] as int;
    final averageScore = assessment['averageScore'] as double;
    final performanceLevel = assessment['performanceLevel'] as String;
    final performanceColor = assessment['performanceColor'] as Color;

    return StandardCard(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 3,
      child: InkWell(
        onTap: () => _openSkatingAssessmentResults(assessment),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header row
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          assessment['title'] as String,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          DateFormat('MMM d, yyyy • h:mm a').format(date),
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.blueGrey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.chevron_right,
                    color: Colors.blueGrey[400],
                    size: 24,
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Compact stats row
              Row(
                children: [
                  _buildCompactStatItem(
                    'Sessions',
                    totalSessions.toString(),
                    Icons.sports,
                    Colors.blue,
                  ),
                  const SizedBox(width: 24),
                  _buildCompactStatItem(
                    'Avg Score',
                    '${averageScore.toStringAsFixed(1)}/10',
                    Icons.assessment,
                    Colors.green,
                  ),
                  const SizedBox(width: 24),
                  _buildCompactStatItem(
                    'Performance',
                    performanceLevel,
                    Icons.trending_up,
                    performanceColor,
                  ),
                ],
              ),
              
              const SizedBox(height: 16),
              
              // Badges
              Row(
                children: [
                  StatusBadge(
                    text: 'Assessment',
                    color: Colors.green,
                    size: StatusBadgeSize.small,
                  ),
                  const SizedBox(width: 8),
                  StatusBadge(
                    text: 'ID: ${assessment['id']}',
                    color: Colors.grey,
                    size: StatusBadgeSize.small,
                    shape: StatusBadgeShape.pill,
                  ),
                  if (assessment['type'] != null) ...[
                    const SizedBox(width: 8),
                    StatusBadge(
                      text: assessment['type'] as String,
                      color: Colors.purple,
                      size: StatusBadgeSize.small,
                      shape: StatusBadgeShape.pill,
                    ),
                  ],
                ],
              ),
              
              const SizedBox(height: 12),
              
              // Tap instruction
              Row(
                children: [
                  Icon(
                    Icons.touch_app,
                    size: 16,
                    color: Colors.blueGrey[600],
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Tap to view detailed results',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.blueGrey[600],
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildShotAssessmentCard(Map<String, dynamic> assessment) {
    final date = assessment['date'] as DateTime;
    final totalShots = assessment['totalShots'] as int;
    final successRate = assessment['successRate'] as double;
    final performanceLevel = assessment['performanceLevel'] as String;
    final performanceColor = assessment['performanceColor'] as Color;

    return StandardCard(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 3,
      child: InkWell(
        onTap: () => _openAssessmentResults(assessment),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header row
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          assessment['title'] as String,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          DateFormat('MMM d, yyyy • h:mm a').format(date),
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.blueGrey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.chevron_right,
                    color: Colors.blueGrey[400],
                    size: 24,
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Compact stats row
              Row(
                children: [
                  _buildCompactStatItem(
                    'Total Shots',
                    totalShots.toString(),
                    Icons.sports_hockey,
                    Colors.blue,
                  ),
                  const SizedBox(width: 24),
                  _buildCompactStatItem(
                    'Success Rate',
                    '${(successRate * 100).toStringAsFixed(1)}%',
                    Icons.check_circle,
                    Colors.green,
                  ),
                  const SizedBox(width: 24),
                  _buildCompactStatItem(
                    'Performance',
                    performanceLevel,
                    Icons.assessment,
                    performanceColor,
                  ),
                ],
              ),
              
              const SizedBox(height: 16),
              
              // Badges
              Row(
                children: [
                  StatusBadge(
                    text: 'Assessment',
                    color: Colors.blue,
                    size: StatusBadgeSize.small,
                  ),
                  const SizedBox(width: 8),
                  StatusBadge(
                    text: 'ID: ${assessment['id']}',
                    color: Colors.grey,
                    size: StatusBadgeSize.small,
                    shape: StatusBadgeShape.pill,
                  ),
                ],
              ),
              
              const SizedBox(height: 12),
              
              // Tap instruction
              Row(
                children: [
                  Icon(
                    Icons.touch_app,
                    size: 16,
                    color: Colors.blueGrey[600],
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Tap to view detailed results',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.blueGrey[600],
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCompactStatItem(String label, String value, IconData icon, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 16),
            const SizedBox(width: 4),
            Text(
              value,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.blueGrey[800],
              ),
            ),
          ],
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: Colors.blueGrey[600],
          ),
        ),
      ],
    );
  }

  // Rest of the existing methods for filtering, building other sections, etc.
  Widget _buildFilterSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_currentHistoryType != HistoryType.skating && _viewMode != 'assessments') ...[
            _buildShootingFilters(),
            if (_currentHistoryType == HistoryType.combined) const SizedBox(height: 16),
          ],
          
          if (_currentHistoryType != HistoryType.shooting && _viewMode != 'assessments') ...[
            _buildSkatingFilters(),
          ],
          
          const Divider(),
        ],
      ),
    );
  }

  Widget _buildShootingFilters() {
    final shotTypeSet = widget.shots.map((s) => s.type ?? 'Unknown').toSet();
    final zoneSet = widget.shots.map((s) => s.zone).whereType<String>().toSet();

    final availableShotTypes = ['All', ...shotTypeSet];
    final availableZones = ['All', ...zoneSet];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Shooting Filters',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.blueGrey[800],
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Text(
              'Type:',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.blueGrey[700],
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        FilterChipGroup<String>(
          options: availableShotTypes,
          selectedOptions: _selectedShotTypes,
          onSelected: _onShotTypeFilterChanged,
          labelBuilder: (option) => option,
          selectedColor: Colors.blue,
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Text(
              'Zone:',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.blueGrey[700],
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        FilterChipGroup<String>(
          options: availableZones,
          selectedOptions: _selectedZones,
          onSelected: _onZoneFilterChanged,
          labelBuilder: (option) => option,
          selectedColor: Colors.green,
        ),
      ],
    );
  }

  Widget _buildSkatingFilters() {
    final availableSkatingTypes = ['All', 'Assessment', 'Practice'];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Skating Filters',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.blueGrey[800],
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Text(
              'Session Type:',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.blueGrey[700],
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        FilterChipGroup<String>(
          options: availableSkatingTypes,
          selectedOptions: _selectedSkatingTypes,
          onSelected: _onSkatingTypeFilterChanged,
          labelBuilder: (option) => option,
          selectedColor: Colors.purple,
        ),
      ],
    );
  }

  Widget _buildNoSkatingAssessmentsState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.speed,
            size: 64,
            color: Colors.blueGrey[300],
          ),
          const SizedBox(height: 24),
          Text(
            'No Skating Assessments Found',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.blueGrey[800],
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Complete skating assessments to see them here',
            style: TextStyle(
              fontSize: 16,
              color: Colors.blueGrey[600],
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _navigateToSkatingAssessment,
            icon: const Icon(Icons.speed),
            label: const Text('Take Skating Assessment'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNoShootingAssessmentsState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.assessment_outlined,
            size: 64,
            color: Colors.blueGrey[300],
          ),
          const SizedBox(height: 24),
          Text(
            'No Shooting Assessments Found',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.blueGrey[800],
            ),
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              'Complete shooting assessments to see them here.',
              style: TextStyle(
                fontSize: 16,
                color: Colors.blueGrey[600],
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _navigateToShotAssessment,
            icon: const Icon(Icons.assessment),
            label: const Text('Take Shot Assessment'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.cyanAccent,
              foregroundColor: Colors.black87,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNoAssessmentsState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.assessment_outlined,
            size: 64,
            color: Colors.blueGrey[300],
          ),
          const SizedBox(height: 24),
          Text(
            'No Assessments Found',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.blueGrey[800],
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Complete assessments to see them here',
            style: TextStyle(
              fontSize: 16,
              color: Colors.blueGrey[600],
            ),
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton.icon(
                onPressed: _navigateToShotAssessment,
                icon: const Icon(Icons.sports_hockey),
                label: const Text('Shot Assessment'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.cyanAccent,
                  foregroundColor: Colors.black87,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              ElevatedButton.icon(
                onPressed: _navigateToSkatingAssessment,
                icon: const Icon(Icons.speed),
                label: const Text('Skating Assessment'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    String title;
    String subtitle;
    List<Widget> actionButtons;

    switch (_currentHistoryType) {
      case HistoryType.shooting:
        title = 'No Shooting History';
        subtitle = 'Take shooting assessments or record practice sessions to build shooting history';
        actionButtons = [
          ElevatedButton.icon(
            onPressed: _navigateToShotAssessment,
            icon: const Icon(Icons.assessment),
            label: const Text('Take Shot Assessment'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.cyanAccent,
              foregroundColor: Colors.black87,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          const SizedBox(width: 12),
          ElevatedButton.icon(
            onPressed: widget.onRecordSkating ?? () {},
            icon: const Icon(Icons.speed),
            label: const Text('Record Practice'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ];
        break;
      case HistoryType.skating:
        title = 'No Skating History';
        subtitle = 'Take skating assessments or record practice sessions to build skating history';
        actionButtons = [
          ElevatedButton.icon(
            onPressed: _navigateToSkatingAssessment,
            icon: const Icon(Icons.assessment),
            label: const Text('Take Skating Assessment'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          const SizedBox(width: 12),
          ElevatedButton.icon(
            onPressed: widget.onRecordSkating ?? () {},
            icon: const Icon(Icons.speed),
            label: const Text('Record Practice'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.purple,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ];
        break;
      case HistoryType.combined:
        title = 'No Training History';
        subtitle = 'Take assessments and record practice sessions to build training history';
        actionButtons = [
          ElevatedButton.icon(
            onPressed: _navigateToShotAssessment,
            icon: const Icon(Icons.sports_hockey),
            label: const Text('Shot Assessment'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.cyanAccent,
              foregroundColor: Colors.black87,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          const SizedBox(width: 8),
          ElevatedButton.icon(
            onPressed: _navigateToSkatingAssessment,
            icon: const Icon(Icons.speed),
            label: const Text('Skating Assessment'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ];
        break;
    }

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            _currentHistoryType == HistoryType.shooting ? Icons.sports_hockey :
            _currentHistoryType == HistoryType.skating ? Icons.speed : Icons.history,
            size: 64,
            color: Colors.blueGrey[300],
          ),
          const SizedBox(height: 24),
          Text(
            title,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.blueGrey[800],
            ),
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              subtitle,
              style: TextStyle(
                fontSize: 16,
                color: Colors.blueGrey[600],
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: actionButtons,
          ),
        ],
      ),
    );
  }

  // Add remaining methods for skating sessions, combined views, etc.
  Widget _buildSkatingSessionsList() {
    if (_filteredSkatings.isEmpty) {
      return _buildEmptyFilteredState('skating');
    }

    final sessionsByDate = _groupSkatingsByDate(_filteredSkatings);
    final sortedDates = sessionsByDate.keys.toList()..sort((a, b) => b.compareTo(a));

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: sortedDates.length,
      itemBuilder: (context, index) {
        final date = sortedDates[index];
        final daySessions = sessionsByDate[date]!;
        return _buildSkatingDayGroup(context, date, daySessions);
      },
    );
  }

  Widget _buildCombinedSessionsList() {
    final combinedSessions = <Map<String, dynamic>>[];
    
    for (final shot in _filteredShots) {
      combinedSessions.add({
        'type': 'shot',
        'data': shot,
        'timestamp': shot.timestamp,
      });
    }
    
    for (final skating in _filteredSkatings.where((s) => !s.isAssessment)) {
      combinedSessions.add({
        'type': 'skating',
        'data': skating,
        'timestamp': skating.date,
      });
    }
    
    combinedSessions.sort((a, b) => (b['timestamp'] as DateTime).compareTo(a['timestamp'] as DateTime));
    
    if (combinedSessions.isEmpty) {
      return _buildEmptyFilteredState('combined');
    }

    final sessionsByDate = <DateTime, List<Map<String, dynamic>>>{};
    for (final session in combinedSessions) {
      final timestamp = session['timestamp'] as DateTime;
      final date = DateTime(timestamp.year, timestamp.month, timestamp.day);
      if (!sessionsByDate.containsKey(date)) {
        sessionsByDate[date] = [];
      }
      sessionsByDate[date]!.add(session);
    }

    final sortedDates = sessionsByDate.keys.toList()..sort((a, b) => b.compareTo(a));

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: sortedDates.length,
      itemBuilder: (context, index) {
        final date = sortedDates[index];
        final daySessions = sessionsByDate[date]!;
        return _buildCombinedDayGroup(context, date, daySessions);
      },
    );
  }

  Widget _buildAllCombinedActivity() {
    final allActivity = <Map<String, dynamic>>[];
    
    for (final assessment in _shotAssessments) {
      allActivity.add({
        'type': 'shot_assessment',
        'data': assessment,
        'timestamp': assessment['date'],
      });
    }
    
    for (final assessment in _skatingAssessments) {
      allActivity.add({
        'type': 'skating_assessment',
        'data': assessment,
        'timestamp': assessment['date'],
      });
    }
    
    for (final shot in _filteredShots) {
      allActivity.add({
        'type': 'shot',
        'data': shot,
        'timestamp': shot.timestamp,
      });
    }
    
    for (final skating in _filteredSkatings) {
      allActivity.add({
        'type': 'skating',
        'data': skating,
        'timestamp': skating.date,
      });
    }
    
    allActivity.sort((a, b) => (b['timestamp'] as DateTime).compareTo(a['timestamp'] as DateTime));
    
    if (allActivity.isEmpty) {
      return _buildEmptyFilteredState('all');
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: allActivity.length,
      itemBuilder: (context, index) {
        final activity = allActivity[index];
        return _buildActivityItem(activity);
      },
    );
  }

  Widget _buildActivityItem(Map<String, dynamic> activity) {
    switch (activity['type']) {
      case 'shot_assessment':
        return _buildShotAssessmentCard(activity['data'] as Map<String, dynamic>);
      case 'skating_assessment':
        return _buildSkatingAssessmentCard(activity['data'] as Map<String, dynamic>);
      case 'shot':
        return _buildShotHistoryItem(activity['data'] as Shot);
      case 'skating':
        return _buildSkatingHistoryItem(activity['data'] as Skating);
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildShotsList() {
    if (_filteredShots.isEmpty) {
      return _buildEmptyFilteredState('shooting');
    }

    final shotsByDate = _groupShotsByDate(_filteredShots);
    final sortedDates = shotsByDate.keys.toList()..sort((a, b) => b.compareTo(a));

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: sortedDates.length,
      itemBuilder: (context, index) {
        final date = sortedDates[index];
        final dayShots = shotsByDate[date]!;
        return _buildDayGroup(context, date, dayShots);
      },
    );
  }

  Widget _buildSkatingDayGroup(BuildContext context, DateTime date, List<Skating> daySessions) {
    final sortedSessions = List<Skating>.from(daySessions)
      ..sort((a, b) => b.date.compareTo(a.date));

    final totalSessions = daySessions.length;
    final assessmentSessions = daySessions.where((s) => s.isAssessment).length;

    return StandardCard(
      margin: const EdgeInsets.only(bottom: 16),
      headerIcon: Icons.calendar_today,
      title: DateFormat('MMM d, yyyy').format(date),
      subtitle: '$totalSessions sessions - $assessmentSessions assessments',
      child: Column(
        children: sortedSessions.map((session) => _buildSkatingHistoryItem(session)).toList(),
      ),
    );
  }

  Widget _buildCombinedDayGroup(BuildContext context, DateTime date, List<Map<String, dynamic>> daySessions) {
    final sortedSessions = List<Map<String, dynamic>>.from(daySessions)
      ..sort((a, b) => (b['timestamp'] as DateTime).compareTo(a['timestamp'] as DateTime));

    final totalSessions = daySessions.length;
    final shotSessions = daySessions.where((s) => s['type'] == 'shot').length;
    final skatingSessions = daySessions.where((s) => s['type'] == 'skating').length;

    return StandardCard(
      margin: const EdgeInsets.only(bottom: 16),
      headerIcon: Icons.calendar_today,
      title: DateFormat('MMM d, yyyy').format(date),
      subtitle: '$totalSessions sessions - $shotSessions shots, $skatingSessions skating',
      child: Column(
        children: sortedSessions.map((session) {
          if (session['type'] == 'shot') {
            return _buildShotHistoryItem(session['data'] as Shot);
          } else {
            return _buildSkatingHistoryItem(session['data'] as Skating);
          }
        }).toList(),
      ),
    );
  }

  Widget _buildSkatingHistoryItem(Skating skating) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          SizedBox(
            width: 48,
            child: Text(
              DateFormat('HH:mm').format(skating.date),
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Colors.blueGrey[700],
              ),
            ),
          ),
          StatusBadge(
            text: skating.sessionTypeDisplay,
            color: skating.isAssessment ? Colors.blue : Colors.green,
            size: StatusBadgeSize.small,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  skating.title ?? skating.assessmentType,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.blueGrey[800],
                  ),
                ),
                if (skating.performanceLevel != null)
                  Text(
                    'Performance: ${skating.performanceLevel}',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.blueGrey[600],
                    ),
                  ),
              ],
            ),
          ),
          if (skating.scores.isNotEmpty)
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.assessment,
                      size: 16,
                      color: Colors.green,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${(skating.scores.values.reduce((a, b) => a + b) / skating.scores.length).toStringAsFixed(1)}/10',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.blueGrey[700],
                      ),
                    ),
                  ],
                ),
                Text(
                  '${skating.scores.length} categories',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.blueGrey[500],
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }

  Map<DateTime, List<Skating>> _groupSkatingsByDate(List<Skating> skatings) {
    final result = <DateTime, List<Skating>>{};

    for (final skating in skatings) {
      final date = DateTime(skating.date.year, skating.date.month, skating.date.day);
      if (!result.containsKey(date)) {
        result[date] = [];
      }
      result[date]!.add(skating);
    }

    return result;
  }

  Widget _buildEmptyFilteredState(String type) {
    String title;
    String subtitle;
    IconData icon;

    switch (type) {
      case 'shooting':
        title = 'No Shots Match Filters';
        subtitle = 'Try adjusting your filters or record more shots';
        icon = Icons.sports_hockey;
        break;
      case 'skating':
        title = 'No Skating Sessions Match Filters';
        subtitle = 'Try adjusting your filters or record more skating sessions';
        icon = Icons.speed;
        break;
      case 'combined':
        title = 'No Sessions Match Filters';
        subtitle = 'Try adjusting your filters or record more activity';
        icon = Icons.filter_alt_off;
        break;
      case 'all':
        title = 'No Activity Found';
        subtitle = 'Start training to build your history';
        icon = Icons.history;
        break;
      default:
        title = 'No Data Found';
        subtitle = 'Try adjusting your filters';
        icon = Icons.filter_alt_off;
    }

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: 64,
            color: Colors.blueGrey[300],
          ),
          const SizedBox(height: 24),
          Text(
            title,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.blueGrey[800],
            ),
          ),
          const SizedBox(height: 12),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 16,
              color: Colors.blueGrey[600],
            ),
          ),
        ],
      ),
    );
  }

  Map<DateTime, List<Shot>> _groupShotsByDate(List<Shot> shots) {
    final result = <DateTime, List<Shot>>{};

    for (final shot in shots) {
      final date = DateTime(shot.timestamp.year, shot.timestamp.month, shot.timestamp.day);
      if (!result.containsKey(date)) {
        result[date] = [];
      }
      result[date]!.add(shot);
    }

    return result;
  }

  Widget _buildDayGroup(BuildContext context, DateTime date, List<Shot> dayShots) {
    final sortedShots = List<Shot>.from(dayShots)
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));

    final totalShots = dayShots.length;
    final successfulShots = dayShots.where((s) => s.success).length;
    final successRate = totalShots > 0 ? successfulShots / totalShots : 0;

    return StandardCard(
      margin: const EdgeInsets.only(bottom: 16),
      headerIcon: Icons.calendar_today,
      title: DateFormat('MMM d, yyyy').format(date),
      subtitle: '$totalShots shots - ${(successRate * 100).toStringAsFixed(0)}% success rate',
      child: Column(
        children: sortedShots.map((shot) => _buildShotHistoryItem(shot)).toList(),
      ),
    );
  }

  Widget _buildShotHistoryItem(Shot shot) {
    final isSuccess = shot.success;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          SizedBox(
            width: 48,
            child: Text(
              DateFormat('HH:mm').format(shot.timestamp),
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Colors.blueGrey[700],
              ),
            ),
          ),
          StatusBadge(
            text: isSuccess ? 'Success' : 'Miss',
            color: isSuccess ? Colors.green : Colors.red,
            size: StatusBadgeSize.small,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      shot.type ?? 'Shot',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.blueGrey[800],
                      ),
                    ),
                    const SizedBox(width: 8),
                    StatusBadge(
                      text: shot.sourceDisplayName,
                      color: shot.isFromAssessment ? Colors.blue : 
                             shot.isFromWorkout ? Colors.purple : Colors.grey,
                      size: StatusBadgeSize.small,
                    ),
                  ],
                ),
                Text(
                  'Zone: ${shot.zone ?? 'Unknown'}',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.blueGrey[600],
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (shot.power != null)
                Row(
                  children: [
                    Icon(
                      Icons.bolt,
                      size: 16,
                      color: Colors.orange,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${shot.power!.toStringAsFixed(1)} mph',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.blueGrey[700],
                      ),
                    ),
                  ],
                ),
              if (shot.quickRelease != null)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Row(
                    children: [
                      Icon(
                        Icons.timer,
                        size: 16,
                        color: Colors.blue,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${shot.quickRelease!.toStringAsFixed(2)} sec',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.blueGrey[700],
                        ),
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
}