// lib/screens/assessments/skating_assessment_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:hockey_shot_tracker/providers/app_state.dart';
import 'package:hockey_shot_tracker/models/player.dart';
import 'package:hockey_shot_tracker/models/skating.dart';
import 'package:hockey_shot_tracker/widgets/domain/assessment/skating/index.dart';
import 'package:hockey_shot_tracker/utils/assessment_skating_utils.dart';
import 'package:hockey_shot_tracker/widgets/core/state/index.dart';
import 'package:hockey_shot_tracker/services/dialog_service.dart';
import 'package:hockey_shot_tracker/responsive_system/index.dart';

class SkatingAssessmentScreen extends StatefulWidget {
  const SkatingAssessmentScreen({Key? key}) : super(key: key);

  @override
  _SkatingAssessmentScreenState createState() => _SkatingAssessmentScreenState();
}

class _SkatingAssessmentScreenState extends State<SkatingAssessmentScreen> {
  // ✅ PHASE 4: Enhanced assessment phase management
  AssessmentPhase _currentPhase = AssessmentPhase.setup;
  bool _isLoading = false;

  // Use Map<String, dynamic> instead of assessment models
  late Map<String, dynamic> _assessment;
  Map<String, Map<String, dynamic>> _testResults = {};
  String? _assessmentId;

  @override
  void initState() {
    super.initState();
    print('SkatingAssessmentScreen: initState called at ${DateTime.now()}');
    _resetAssessment();
    _ensurePlayerSelected();
  }

  // ✅ UNIFIED: Copy exact player validation methods from ShotAssessmentScreen
  Future<void> _ensurePlayerSelected() async {
    final appState = Provider.of<AppState>(context, listen: false);
    
    // Wait for players to load if they haven't yet
    if (appState.isLoadingPlayers) {
      print('SkatingAssessmentScreen: Waiting for players to load...');
      // Wait a bit for loading to complete
      await Future.delayed(const Duration(milliseconds: 500));
    }
    
    // If still no players or still loading, try to load them
    if (appState.players.isEmpty) {
      print('SkatingAssessmentScreen: Loading players...');
      try {
        await appState.loadPlayers();
      } catch (e) {
        print('SkatingAssessmentScreen: Error loading players: $e');
      }
    }
    
    // Now check if we have a valid selected player
    if (appState.players.isNotEmpty && 
        (appState.selectedPlayer == null || appState.selectedPlayer!.isEmpty)) {
      print('SkatingAssessmentScreen: No player selected, setting default to first player');
      appState.setSelectedPlayer(appState.players.first.name);
      print('SkatingAssessmentScreen: Set selected player to: ${appState.players.first.name}');
    }
    
    if (mounted) {
      setState(() {}); // Trigger rebuild with updated state
    }
  }

  // ✅ UNIFIED: Copy exact validation methods from ShotAssessmentScreen
  bool _isValidPlayerSelected(AppState appState) {
    return appState.players.isNotEmpty && 
           appState.selectedPlayer != null && 
           appState.selectedPlayer!.isNotEmpty &&
           appState.players.any((p) => p.name == appState.selectedPlayer);
  }

  // ✅ UNIFIED: Copy exact player getter from ShotAssessmentScreen
  Player? _getSelectedPlayer(AppState appState) {
    if (!_isValidPlayerSelected(appState)) return null;
    
    try {
      return appState.players.firstWhere(
        (p) => p.name == appState.selectedPlayer,
      );
    } catch (e) {
      print('SkatingAssessmentScreen: Error finding selected player: $e');
      return null;
    }
  }

  void _resetAssessment() {
    setState(() {
      _currentPhase = AssessmentPhase.setup;
      _assessmentId = null;
      _assessment = {
        'id': 0,
        'date': DateTime.now().toIso8601String(),
        'age_group': 'youth_15_18',
        'position': 'forward',
        'test_times': <String, double>{},
        'scores': <String, double>{'Overall': 0.0},
        'title': 'Skating Assessment',
        'description': 'Standard skating assessment',
        'assessment_type': 'Comprehensive',
        'team_assessment': false,
        'strengths': <String>[],
        'improvements': <String>[],
        'groups': <Map<String, dynamic>>[], // Reset groups
        'assessmentId': null, // Reset assessment ID
      };
      _testResults = {};
    });
  }

  // ✅ UNIFIED: Updated to use same validation pattern as ShotAssessmentScreen
  void _startAssessment(Map<String, dynamic> assessment, Player player) {
    print('SkatingAssessmentScreen: Starting assessment: $assessment');
    final assessmentId = assessment['assessmentId']?.toString() ?? DateTime.now().millisecondsSinceEpoch.toString();

    final appState = Provider.of<AppState>(context, listen: false);
    
    // ✅ UNIFIED: Use same validation as ShotAssessmentScreen
    if (player.id == null) {
      print('SkatingAssessmentScreen: Error: Selected player has null ID');
      DialogService.showError(
        context,
        title: 'Invalid Player',
        message: 'The selected player has an invalid ID. Please try selecting a different player.',
      );
      return;
    }

    print('=== STARTING SKATING ASSESSMENT DEBUG ===');
    print('Assessment received: ${assessment.keys.toList()}');
    print('Assessment groups: ${(assessment['groups'] as List?)?.length ?? 0}');
    print('Assessment ID: $assessmentId');
    
    setState(() {
      // CRITICAL FIX: Copy ALL fields from assessment, especially 'groups' and 'assessmentId'
      _assessment = {
        ...assessment,
        'id': assessment['id'] ?? 0,
        'test_times': assessment['test_times'] ?? <String, double>{},
        'scores': assessment['scores'] ?? <String, double>{'Overall': 0.0},
        'strengths': assessment['strengths'] ?? <String>[],
        'improvements': assessment['improvements'] ?? <String>[],
        'team_assessment': assessment['team_assessment'] ?? false,
        // CRITICAL FIXES: Copy the missing essential fields
        'groups': assessment['groups'] ?? <Map<String, dynamic>>[], // ✅ Copy groups
        'assessmentId': assessmentId, // ✅ Always ensure assessment ID is set
        'totalTests': assessment['totalTests'] ?? 0, // ✅ Copy total tests count
        'ageGroup': assessment['ageGroup'] ?? 'youth_15_18', // ✅ Copy age group
        'position': assessment['position'] ?? 'forward', // ✅ Copy position
        'playerName': assessment['playerName'] ?? player.name, // ✅ Copy player name
        'playerId': assessment['playerId'] ?? player.id, // ✅ Copy player ID
        'player_id': player.id, // ✅ Ensure player_id is set
        // ✅ UNIFIED: Ensure date field is always set (same as ShotAssessmentScreen)
        'date': assessment['date'] ?? DateTime.now().toIso8601String(),
      };
      _assessmentId = assessmentId;
      _currentPhase = AssessmentPhase.execution;
      _testResults = {};
    });

    // ✅ UNIFIED: Use AppState method properly (same as ShotAssessmentScreen)
    appState.setCurrentSkatingAssessmentId(assessmentId);
    
    // Verify the data was copied correctly
    final groups = _assessment['groups'] as List?;
    int totalTests = 0;
    if (groups != null) {
      for (var group in groups) {
        final tests = (group as Map<String, dynamic>)['tests'] as List? ?? [];
        totalTests += tests.length;
      }
    }
    
    print('Assessment copied - Groups: ${groups?.length ?? 0}, Total tests: $totalTests');
    print('Assessment ID copied: $_assessmentId');
    print('Player: ${player.name} (ID: ${player.id})');
    print('========================================');

    DialogService.showInformation(
      context,
      title: 'Assessment Started',
      message: 'Assessment ID: $_assessmentId\nType: ${assessment['type'] ?? assessment['assessment_type']}\nPlayer: ${player.name}',
    );
  }

  void _completeAssessment() {
    setState(() {
      _currentPhase = AssessmentPhase.results;
    });
  }

  Future<void> _saveAssessment() async {
    setState(() {
      _isLoading = true;
    });

    final dialogContext = context;

    try {
      final appState = Provider.of<AppState>(dialogContext, listen: false);
      final selectedPlayer = _getSelectedPlayer(appState);
      
      if (selectedPlayer == null || selectedPlayer.id == null) {
        throw Exception('No player selected or player ID is missing');
      }

      // Convert test results to the format expected by API
      final testTimes = <String, double>{};
      _testResults.forEach((testId, result) {
        testTimes[testId] = result['time'] as double;
      });

      // ENHANCED: Include assessment ID in the save data
      final skatingData = {
        'player_id': selectedPlayer.id,
        'date': _assessment['date'],
        'age_group': _assessment['ageGroup'] ?? _assessment['age_group'] ?? 'youth_15_18', // ✅ Use consistent field
        'position': _assessment['position'] ?? 'forward',
        'test_times': testTimes,
        'scores': _assessment['scores'],
        'title': _assessment['title'],
        'description': _assessment['description'],
        'assessment_type': _assessment['assessment_type'],
        'team_assessment': _assessment['team_assessment'] ?? false,
        'strengths': _assessment['strengths'],
        'improvements': _assessment['improvements'],
        'player_name': selectedPlayer.name,
        'assessment_id': _assessmentId, // ✅ Include assessment ID
        'is_assessment': true, // ✅ Mark as assessment
        'save': true, // ✅ Tell backend to save
      };

      print('Saving skating assessment with ID: $_assessmentId');
      
      await appState.addSkating(skatingData); // Use addSkating instead of saveSkating for consistency

      await DialogService.showSuccess(
        dialogContext,
        title: 'Assessment Saved',
        message: 'Assessment ID: $_assessmentId\nSkating assessment saved successfully!',
      );

      // ✅ UNIFIED: Clear assessment ID same as ShotAssessmentScreen
      appState.clearCurrentSkatingAssessmentId();
      _resetAssessment();

      Navigator.pop(dialogContext, true);
    } catch (e) {
      print('SkatingAssessmentScreen: Error saving assessment: $e');
      await DialogService.showError(
        dialogContext,
        title: 'Error',
        message: 'Error saving assessment: $e',
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final routeSettings = ModalRoute.of(context)?.settings;
    print('SkatingAssessmentScreen: build called at ${DateTime.now()}');
    print('SkatingAssessmentScreen: Navigation source: ${routeSettings?.name}, arguments: ${routeSettings?.arguments}');

    // ✅ PHASE 4: Enhanced scaffold with responsive design
    return Scaffold(
      appBar: AppBar(
        title: ResponsiveText(
          'Skating Assessment',
          baseFontSize: 20,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: Colors.blueGrey[900],
        leading: _buildLeadingButton(),
        actions: _buildAppBarActions(),
      ),
      body: FullScreenContainer(
        backgroundColor: Colors.grey[100],
        child: SafeArea(
          child: LoadingOverlay(
            isLoading: _isLoading,
            message: 'Processing assessment...',
            color: Colors.cyanAccent,
            child: Consumer<AppState>(
              builder: (context, appState, child) {
                print('SkatingAssessmentScreen: Consumer rebuild - isLoadingPlayers: ${appState.isLoadingPlayers}');
                print('SkatingAssessmentScreen: Players count: ${appState.players.length}');
                print('SkatingAssessmentScreen: Selected player: "${appState.selectedPlayer}"');
                
                // ✅ UNIFIED: Copy exact loading/empty states from ShotAssessmentScreen
                if (appState.isLoadingPlayers) {
                  return _buildLoadingState();
                }
                
                if (appState.players.isEmpty) {
                  return _buildNoPlayersState();
                }
                
                if (!_isValidPlayerSelected(appState)) {
                  return _buildPlayerSelectionState(appState);
                }
                
                return _buildAssessmentContent(appState);
              },
            ),
          ),
        ),
      ),
      backgroundColor: Colors.transparent,
    );
  }

  // ✅ PHASE 4: Enhanced app bar actions with phase indicator
  List<Widget> _buildAppBarActions() {
    if (_currentPhase == AssessmentPhase.setup) {
      return [];
    }

    return [
      Container(
        margin: ResponsiveConfig.paddingSymmetric(context, horizontal: 8),
        child: Center(
          child: ResponsiveText(
            'ID: ${_assessmentId?.substring(0, 8) ?? 'N/A'}',
            baseFontSize: 12,
            style: TextStyle(
              color: Colors.white70,
              fontFamily: 'monospace',
            ),
          ),
        ),
      ),
    ];
  }

  Widget _buildLeadingButton() {
    if (_currentPhase != AssessmentPhase.setup) {
      return IconButton(
        icon: const Icon(Icons.close),
        onPressed: () {
          DialogService.showConfirmation(
            context,
            title: 'Cancel Assessment?',
            message: 'Assessment ID: $_assessmentId\nProgress will be lost. Are you sure?',
            confirmLabel: 'Yes',
            cancelLabel: 'No',
            isDestructive: true,
          ).then((confirmed) {
            if (confirmed == true) {
              // ✅ UNIFIED: Clear assessment ID from AppState on cancel (same as ShotAssessmentScreen)
              final appState = Provider.of<AppState>(context, listen: false);
              appState.clearCurrentSkatingAssessmentId();
              _resetAssessment();
              Navigator.pop(context, false);
            }
          });
        },
      );
    } else {
      return IconButton(
        icon: const Icon(Icons.arrow_back),
        onPressed: () => Navigator.pop(context, false),
      );
    }
  }

  // ✅ PHASE 4: Responsive loading state
  Widget _buildLoadingState() {
    return AdaptiveLayout(
      builder: (deviceType, isLandscape) {
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(
                color: Colors.cyanAccent,
                strokeWidth: ResponsiveConfig.dimension(context, 4),
              ),
              ResponsiveSpacing(multiplier: 2),
              ResponsiveText(
                'Loading players...',
                baseFontSize: 16,
                style: TextStyle(color: Colors.blueGrey[600]),
              ),
            ],
          ),
        );
      },
    );
  }

  // ✅ PHASE 4: Responsive no players state
  Widget _buildNoPlayersState() {
    return AdaptiveLayout(
      builder: (deviceType, isLandscape) {
        return SingleChildScrollView(
          padding: ResponsiveConfig.paddingAll(context, 32),
          child: ConstrainedBox(
            constraints: ResponsiveConfig.constraints(
              context,
              maxWidth: deviceType == DeviceType.desktop ? 600 : null,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.people_outline,
                  size: ResponsiveConfig.iconSize(context, 64),
                  color: Colors.grey[400],
                ),
                ResponsiveSpacing(multiplier: 2),
                ResponsiveText(
                  'No players available',
                  baseFontSize: 24,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.blueGrey[800],
                  ),
                  textAlign: TextAlign.center,
                ),
                ResponsiveSpacing(multiplier: 1),
                ResponsiveText(
                  'Please add players before starting an assessment',
                  baseFontSize: 16,
                  style: TextStyle(color: Colors.blueGrey[600]),
                  textAlign: TextAlign.center,
                ),
                ResponsiveSpacing(multiplier: 3),
                ResponsiveButton(
                  text: 'Add Player',
                  onPressed: () {
                    print('SkatingAssessmentScreen: Redirecting to player registration');
                    Navigator.pushReplacementNamed(context, '/player-registration');
                  },
                  baseHeight: 48,
                  backgroundColor: Colors.cyanAccent,
                  foregroundColor: Colors.black87,
                  icon: Icons.person_add,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ✅ PHASE 4: Responsive player selection state
  Widget _buildPlayerSelectionState(AppState appState) {
    return AdaptiveLayout(
      builder: (deviceType, isLandscape) {
        return SingleChildScrollView(
          padding: ResponsiveConfig.paddingAll(context, 32),
          child: ConstrainedBox(
            constraints: ResponsiveConfig.constraints(
              context,
              maxWidth: deviceType == DeviceType.desktop ? 600 : null,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.person_search,
                  size: ResponsiveConfig.iconSize(context, 64),
                  color: Colors.grey[400],
                ),
                ResponsiveSpacing(multiplier: 2),
                ResponsiveText(
                  'No player selected',
                  baseFontSize: 24,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.blueGrey[800],
                  ),
                  textAlign: TextAlign.center,
                ),
                ResponsiveSpacing(multiplier: 1),
                ResponsiveText(
                  'Please select a player to start the assessment',
                  baseFontSize: 16,
                  style: TextStyle(color: Colors.blueGrey[600]),
                  textAlign: TextAlign.center,
                ),
                ResponsiveSpacing(multiplier: 3),
                ResponsiveButton(
                  text: 'Select Player',
                  onPressed: () {
                    print('SkatingAssessmentScreen: Redirecting to PlayersScreen for selection');
                    Navigator.pushReplacementNamed(context, '/players');
                  },
                  baseHeight: 48,
                  backgroundColor: Colors.cyanAccent,
                  foregroundColor: Colors.black87,
                  icon: Icons.people,
                ),
                ResponsiveSpacing(multiplier: 2),
                // ✅ UNIFIED: Enhanced quick selection dropdown
                _buildQuickPlayerSelection(appState, deviceType),
              ],
            ),
          ),
        );
      },
    );
  }

  // ✅ PHASE 4: Responsive quick player selection
  Widget _buildQuickPlayerSelection(AppState appState, DeviceType deviceType) {
    return ResponsiveCard(
      padding: ResponsiveConfig.paddingAll(context, 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ResponsiveText(
            'Quick Select Player',
            baseFontSize: 16,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.blueGrey[800],
            ),
          ),
          ResponsiveSpacing(multiplier: 1),
          DropdownButtonFormField<String>(
            decoration: InputDecoration(
              border: OutlineInputBorder(
                borderRadius: ResponsiveConfig.borderRadius(context, 8),
              ),
              contentPadding: ResponsiveConfig.paddingSymmetric(
                context,
                horizontal: 16,
                vertical: 12,
              ),
            ),
            value: appState.selectedPlayer?.isNotEmpty == true ? appState.selectedPlayer : null,
            items: appState.players.map((player) {
              return DropdownMenuItem<String>(
                value: player.name,
                child: ResponsiveText(
                  player.name,
                  baseFontSize: 16,
                ),
              );
            }).toList(),
            onChanged: (playerName) {
              if (playerName != null) {
                print('SkatingAssessmentScreen: Quick selected player: $playerName');
                appState.setSelectedPlayer(playerName);
              }
            },
          ),
        ],
      ),
    );
  }

  // ✅ PHASE 4: Main assessment content with phase management
  Widget _buildAssessmentContent(AppState appState) {
    print('SkatingAssessmentScreen: Building assessment content for player: ${appState.selectedPlayer}');

    // ✅ UNIFIED: Copy exact player validation from ShotAssessmentScreen
    final selectedPlayer = _getSelectedPlayer(appState);
    if (selectedPlayer == null) {
      return _buildPlayerErrorState('Error: No valid player selected');
    }

    // ✅ UNIFIED: Copy exact player ID validation from ShotAssessmentScreen
    if (selectedPlayer.id == null) {
      return _buildPlayerErrorState('Error: Player "${selectedPlayer.name}" has invalid ID');
    }

    // ✅ UNIFIED: Copy exact player info setting from ShotAssessmentScreen
    if (_assessment['player_id'] == null) {
      _assessment['player_id'] = selectedPlayer.id!;
      _assessment['playerName'] = selectedPlayer.name;
    }

    return AdaptiveLayout(
      builder: (deviceType, isLandscape) {
        return Column(
          children: [
            // ✅ PHASE 4: Assessment phase indicator
            if (_currentPhase != AssessmentPhase.setup)
              _buildPhaseIndicator(deviceType),
            
            // ✅ PHASE 4: Main content area
            Expanded(
              child: _buildPhaseContent(selectedPlayer, deviceType, isLandscape),
            ),
          ],
        );
      },
    );
  }

  // ✅ PHASE 4: Assessment phase indicator
  Widget _buildPhaseIndicator(DeviceType deviceType) {
    return Container(
      margin: ResponsiveConfig.paddingAll(context, 16),
      child: ResponsiveCard(
        padding: ResponsiveConfig.paddingSymmetric(context, horizontal: 16, vertical: 12),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: AssessmentPhase.values.asMap().entries.map((entry) {
            final phase = entry.value;
            final isActive = phase == _currentPhase;
            final isCompleted = _getPhaseIndex(phase) < _getPhaseIndex(_currentPhase);
            
            return Row(
              children: [
                _buildPhaseStep(phase, isActive, isCompleted),
                if (entry.key < AssessmentPhase.values.length - 1)
                  Container(
                    width: ResponsiveConfig.dimension(context, 40),
                    height: 2,
                    color: isCompleted ? Colors.green : Colors.grey[300],
                  ),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildPhaseStep(AssessmentPhase phase, bool isActive, bool isCompleted) {
    return Container(
      width: ResponsiveConfig.dimension(context, 32),
      height: ResponsiveConfig.dimension(context, 32),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: isCompleted ? Colors.green : (isActive ? Colors.cyanAccent : Colors.grey[300]),
      ),
      child: Center(
        child: isCompleted
          ? Icon(
              Icons.check, 
              color: Colors.white, 
              size: ResponsiveConfig.iconSize(context, 16),
            )
          : ResponsiveText(
              '${_getPhaseIndex(phase) + 1}',
              baseFontSize: 14,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: isActive ? Colors.black87 : Colors.grey[600],
              ),
            ),
      ),
    );
  }

  int _getPhaseIndex(AssessmentPhase phase) {
    return AssessmentPhase.values.indexOf(phase);
  }

  // ✅ PHASE 4: Phase-specific content routing
  Widget _buildPhaseContent(Player selectedPlayer, DeviceType deviceType, bool isLandscape) {
    switch (_currentPhase) {
      case AssessmentPhase.setup:
        return _buildSetupPhase(selectedPlayer, deviceType, isLandscape);
      case AssessmentPhase.execution:
        return _buildExecutionPhase(selectedPlayer, deviceType, isLandscape);
      case AssessmentPhase.results:
        return _buildResultsPhase(selectedPlayer, deviceType, isLandscape);
    }
  }

  // ✅ PHASE 4: Responsive setup phase
  Widget _buildSetupPhase(Player selectedPlayer, DeviceType deviceType, bool isLandscape) {
    return SingleChildScrollView(
      padding: ResponsiveConfig.paddingAll(context, 16),
      child: ConstrainedBox(
        constraints: ResponsiveConfig.constraints(
          context,
          maxWidth: deviceType == DeviceType.desktop ? 800 : null,
        ),
        child: SkatingAssessmentSetupScreen(
          onStart: _startAssessment,
        ),
      ),
    );
  }

  // ✅ PHASE 4: Responsive execution phase
  Widget _buildExecutionPhase(Player selectedPlayer, DeviceType deviceType, bool isLandscape) {
    // ENHANCED: Debug log before passing to execution screen
    final groups = _assessment['groups'] as List?;
    int totalTests = 0;
    if (groups != null) {
      for (var group in groups) {
        final tests = (group as Map<String, dynamic>)['tests'] as List? ?? [];
        totalTests += tests.length;
      }
    }
    
    print('Passing to execution screen:');
    print('  Groups: ${groups?.length ?? 0}');
    print('  Total tests: $totalTests');
    print('  Assessment ID: $_assessmentId');
    
    return SkatingAssessmentExecutionScreen(
      assessment: _assessment,
      testResults: _testResults,
      onAddResult: _addTestResult,
      onComplete: _completeAssessment,
    );
  }

  // ✅ PHASE 4: Responsive results phase
  Widget _buildResultsPhase(Player selectedPlayer, DeviceType deviceType, bool isLandscape) {
    // Convert testResults to format expected by SkatingAssessmentResultsScreen
    final resultsForDisplay = <String, double>{};
    _testResults.forEach((testId, result) {
      resultsForDisplay[testId] = result['time'] as double;
    });
    
    // Convert _assessment to Skating using fromJson
    final skatingAssessment = Skating.fromJson({
      ..._assessment,
      'test_times': resultsForDisplay.map((key, value) => MapEntry(key, value)),
      'player_id': selectedPlayer.id,
      'player_name': selectedPlayer.name,
      'assessment_id': _assessmentId, // ✅ Include assessment ID
    });
    
    return SkatingAssessmentResultsScreen(
      player: selectedPlayer,
      assessment: skatingAssessment,
      testResults: resultsForDisplay,
      assessmentId: _assessmentId, // ✅ Pass assessment ID
      onReset: _resetAssessment,
      onSave: _saveAssessment,
    );
  }

  // ✅ PHASE 4: Responsive error state
  Widget _buildPlayerErrorState(String errorMessage) {
    return AdaptiveLayout(
      builder: (deviceType, isLandscape) {
        return Center(
          child: ResponsiveCard(
            padding: ResponsiveConfig.paddingAll(context, 32),
            maxWidth: deviceType == DeviceType.desktop ? 600 : null,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.error, 
                  size: ResponsiveConfig.iconSize(context, 64), 
                  color: Colors.red,
                ),
                ResponsiveSpacing(multiplier: 2),
                ResponsiveText(
                  errorMessage,
                  baseFontSize: 18,
                  style: TextStyle(color: Colors.red[700]),
                  textAlign: TextAlign.center,
                ),
                ResponsiveSpacing(multiplier: 3),
                ResponsiveButton(
                  text: 'Select Different Player',
                  onPressed: () => Navigator.pushReplacementNamed(context, '/players'),
                  baseHeight: 48,
                  backgroundColor: Colors.cyanAccent,
                  foregroundColor: Colors.black87,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _addTestResult(String testId, Map<String, dynamic> result) {
    if (result['time'] is! double) {
      throw Exception('Invalid time value in test result');
    }
    
    // ENHANCED: Include assessment ID in test result
    final enhancedResult = {
      ...result,
      'assessmentId': _assessmentId, // ✅ Link to assessment
    };
    
    setState(() {
      _testResults[testId] = enhancedResult;
    });
    
    print('Added test result: $testId = ${result['time']}s (Assessment: $_assessmentId)');
  }
}

// ✅ PHASE 4: Assessment phase enumeration
enum AssessmentPhase { setup, execution, results }