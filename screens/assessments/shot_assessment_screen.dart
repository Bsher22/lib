import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:hockey_shot_tracker/providers/app_state.dart';
import 'package:hockey_shot_tracker/models/shot.dart';
import 'package:hockey_shot_tracker/models/player.dart';
import 'package:hockey_shot_tracker/models/assessment_config.dart';
import 'package:hockey_shot_tracker/services/assessment_config_service.dart';
import 'package:hockey_shot_tracker/widgets/domain/assessment/shot/index.dart';
import 'package:hockey_shot_tracker/utils/assessment_shot_utils.dart';
import 'package:hockey_shot_tracker/widgets/core/state/index.dart';
import 'package:hockey_shot_tracker/services/dialog_service.dart';
import 'package:hockey_shot_tracker/services/infrastructure/api_service_factory.dart';
import 'package:hockey_shot_tracker/responsive_system/index.dart';

class ShotAssessmentScreen extends StatefulWidget {
  const ShotAssessmentScreen({Key? key}) : super(key: key);

  @override
  _ShotAssessmentScreenState createState() => _ShotAssessmentScreenState();
}

class _ShotAssessmentScreenState extends State<ShotAssessmentScreen> {
  // Assessment workflow states
  AssessmentWorkflowState _workflowState = AssessmentWorkflowState.setup;
  bool _isLoading = false;
  bool _showRecentShots = true; // Toggle state for Recent Shots panel
  bool _isInitialized = false; // Track initialization state

  Map<String, dynamic>? _assessment;
  Map<int, List<Shot>> _shotResults = {};
  String? _assessmentId;

  @override
  void initState() {
    super.initState();
    print('ShotAssessmentScreen: initState called at ${DateTime.now()}');
    _resetAssessment();
    
    Future.microtask(() => _initializeAsync());
  }

  Future<void> _initializeAsync() async {
    if (!mounted) return;
    
    try {
      await _ensurePlayerSelected();
      if (mounted) {
        setState(() {
          _isInitialized = true;
        });
      }
    } catch (e) {
      print('ShotAssessmentScreen: Error during initialization: $e');
      if (mounted) {
        setState(() {
          _isInitialized = true; // Show UI even if initialization failed
        });
      }
    }
  }

  Future<void> _ensurePlayerSelected() async {
    if (!mounted) return;
    
    final appState = Provider.of<AppState>(context, listen: false);
    
    // Wait for players to load if they haven't yet
    if (appState.isLoadingPlayers) {
      print('ShotAssessmentScreen: Waiting for players to load...');
      int attempts = 0;
      while (appState.isLoadingPlayers && attempts < 10 && mounted) {
        await Future.delayed(const Duration(milliseconds: 100));
        attempts++;
      }
    }
    
    // If still no players or still loading, try to load them
    if (appState.players.isEmpty && mounted) {
      print('ShotAssessmentScreen: Loading players...');
      try {
        await appState.loadPlayers();
      } catch (e) {
        print('ShotAssessmentScreen: Error loading players: $e');
      }
    }
    
    if (!mounted) return;
    
    // Now check if we have a valid selected player
    if (appState.players.isNotEmpty && 
        (appState.selectedPlayer == null || appState.selectedPlayer!.isEmpty)) {
      print('ShotAssessmentScreen: No player selected, setting default to first player');
      appState.setSelectedPlayer(appState.players.first.name);
      print('ShotAssessmentScreen: Set selected player to: ${appState.players.first.name}');
    }
  }

  void _resetAssessment() async {
    setState(() {
      _workflowState = AssessmentWorkflowState.setup;
      _assessmentId = null;
    });
    
    try {
      // Load default assessment from configuration
      final configService = AssessmentConfigService.instance;
      final templates = await configService.getTemplates();
      
      // Try to get the first available template
      AssessmentTemplate? template;
      if (templates.isNotEmpty) {
        template = templates.firstWhere(
          (t) => t.id == 'accuracy_precision_100',
          orElse: () => templates.first,
        );
      }
      
      if (template != null) {
        _assessment = {
          'type': template.id,
          'title': template.title,
          'description': template.description,
          'player_id': null,
          'date': DateTime.now().toIso8601String(),
          'estimatedDuration': template.estimatedDurationMinutes,
          'totalShots': template.totalShots,
          'category': template.category,
          'metadata': template.metadata,
          'groups': template.groups.map((group) => {
            'id': group.id,
            'title': group.title,
            'shot_types': group.allowedShotTypes.isNotEmpty ? group.allowedShotTypes : ['Wrist Shot', 'Snap Shot'],
            'zones': group.targetZones.isNotEmpty ? group.targetZones : ['1', '2', '3', '4', '5', '6', '7', '8', '9'],
            'shots': group.shots,
            'defaultType': group.defaultType,
            'location': group.location,
            'instructions': group.instructions,
            'intendedZones': group.parameters['intendedZones'] ?? group.targetZones,
            'adjacentZones': group.parameters['adjacentZones'] ?? [],
            'missZones': group.parameters['missZones'] ?? [],
            'successCriteria': group.parameters['successCriteria'] ?? 'standard',
            'parameters': group.parameters,
          }).toList(),
        };
        print('ShotAssessmentScreen: Loaded template: ${template.title} (${template.id})');
      } else {
        print('ShotAssessmentScreen: No templates available, using fallback');
        _assessment = _getDefaultAssessment();
      }
    } catch (e) {
      print('ShotAssessmentScreen: Error loading assessment configuration: $e');
      _assessment = _getDefaultAssessment();
    }
    
    // Initialize shot results tracking
    _shotResults = {};
    if (_assessment != null) {
      for (final group in _assessment!['groups']) {
        _shotResults[int.parse(group['id'])] = [];
      }
    }
  }

  Map<String, dynamic> _getDefaultAssessment() {
    return {
      'type': 'accuracy_precision_100',
      'description': 'Fallback accuracy assessment with intended zone targeting',
      'player_id': null,
      'title': 'Accuracy Precision Test',
      'date': DateTime.now().toIso8601String(),
      'estimatedDuration': 30,
      'totalShots': 100,
      'category': 'focused',
      'groups': [
        {
          'id': '0',
          'title': 'Right Side Precision',
          'shot_types': ['Wrist Shot', 'Snap Shot'],
          'zones': ['1', '2', '3', '4', '5', '6', '7', '8', '9'],
          'shots': 25,
          'defaultType': 'Wrist Shot',
          'location': 'Slot',
          'instructions': 'Target the right side of the net. Aim specifically for zones 3, 6, or 9.',
          'intendedZones': ['3', '6', '9'],
          'adjacentZones': ['2', '5', '8'],
          'missZones': ['1', '4', '7'],
          'successCriteria': 'shot_in_intended_zones',
        },
        {
          'id': '1',
          'title': 'Left Side Precision',
          'shot_types': ['Wrist Shot', 'Snap Shot'],
          'zones': ['1', '2', '3', '4', '5', '6', '7', '8', '9'],
          'shots': 25,
          'defaultType': 'Wrist Shot',
          'location': 'Slot',
          'instructions': 'Target the left side of the net. Aim specifically for zones 1, 4, or 7.',
          'intendedZones': ['1', '4', '7'],
          'adjacentZones': ['2', '5', '8'],
          'missZones': ['3', '6', '9'],
          'successCriteria': 'shot_in_intended_zones',
        },
        {
          'id': '2',
          'title': 'Center Line Targeting',
          'shot_types': ['Wrist Shot', 'Snap Shot'],
          'zones': ['1', '2', '3', '4', '5', '6', '7', '8', '9'],
          'shots': 25,
          'defaultType': 'Wrist Shot',
          'location': 'Slot',
          'instructions': 'Target the center line of the net. Aim specifically for zones 2, 5, or 8.',
          'intendedZones': ['2', '5', '8'],
          'adjacentZones': ['1', '3', '4', '6', '7', '9'],
          'missZones': [],
          'successCriteria': 'shot_in_intended_zones',
        },
        {
          'id': '3',
          'title': 'High Corner Precision',
          'shot_types': ['Wrist Shot', 'Snap Shot'],
          'zones': ['1', '2', '3', '4', '5', '6', '7', '8', '9'],
          'shots': 25,
          'defaultType': 'Wrist Shot',
          'location': 'Slot',
          'instructions': 'Target the top shelf of the net. Aim specifically for zones 1, 2, or 3.',
          'intendedZones': ['1', '2', '3'],
          'adjacentZones': ['4', '5', '6'],
          'missZones': ['7', '8', '9'],
          'successCriteria': 'shot_in_intended_zones',
        },
      ],
    };
  }

  bool _isValidPlayerSelected(AppState appState) {
    return appState.players.isNotEmpty && 
           appState.selectedPlayer != null && 
           appState.selectedPlayer!.isNotEmpty &&
           appState.players.any((p) => p.name == appState.selectedPlayer);
  }

  Player? _getSelectedPlayer(AppState appState) {
    if (!_isValidPlayerSelected(appState)) return null;
    
    try {
      return appState.players.firstWhere(
        (p) => p.name == appState.selectedPlayer,
      );
    } catch (e) {
      print('ShotAssessmentScreen: Error finding selected player: $e');
      return null;
    }
  }

  void _startAssessment(BuildContext context, Map<String, dynamic> assessment) {
    print('ShotAssessmentScreen: Starting assessment: $assessment');
    final assessmentId = assessment['assessmentId']?.toString() ?? DateTime.now().millisecondsSinceEpoch.toString();

    final appState = Provider.of<AppState>(context, listen: false);
    final selectedPlayer = _getSelectedPlayer(appState);
    
    if (selectedPlayer == null) {
      print('ShotAssessmentScreen: Error: No valid player selected');
      print('ShotAssessmentScreen: Players count: ${appState.players.length}');
      print('ShotAssessmentScreen: Selected player: "${appState.selectedPlayer}"');
      print('ShotAssessmentScreen: Available players: ${appState.players.map((p) => p.name).toList()}');
      
      DialogService.showError(
        context,
        title: 'No Player Selected',
        message: 'Please select a player before starting the assessment.',
      );
      return;
    }

    // Check if player has a valid ID
    if (selectedPlayer.id == null) {
      print('ShotAssessmentScreen: Error: Selected player has null ID');
      DialogService.showError(
        context,
        title: 'Invalid Player',
        message: 'The selected player has an invalid ID. Please try selecting a different player.',
      );
      return;
    }

    setState(() {
      _assessment = Map<String, dynamic>.from(assessment);
      _assessmentId = assessmentId;
      _assessment!['assessmentId'] = _assessmentId;
      
      if (_assessment!['date'] == null || _assessment!['date'] == '') {
        _assessment!['date'] = DateTime.now().toIso8601String();
      }
      
      if (_assessment!.containsKey('playerId')) {
        _assessment!['player_id'] = _assessment!['playerId'];
        _assessment!.remove('playerId');
      }
      _assessment!['player_id'] = selectedPlayer.id!;
      _assessment!['playerName'] = selectedPlayer.name;
      _workflowState = AssessmentWorkflowState.execution;
      _shotResults = {};
      final groups = assessment['groups'] as List<dynamic>? ?? [];
      for (final group in groups) {
        final groupMap = group as Map<String, dynamic>?;
        final groupId = groupMap?['id']?.toString();
        if (groupId != null && int.tryParse(groupId) != null) {
          _shotResults[int.parse(groupId)] = [];
        } else {
          print('ShotAssessmentScreen: Invalid group ID: $groupId');
        }
      }
    });

    appState.setCurrentAssessmentId(assessmentId);

    print('ShotAssessmentScreen: Assessment started with ID: $_assessmentId');
    print('ShotAssessmentScreen: Assessment groups initialized: ${_shotResults.keys}');
    print('ShotAssessmentScreen: Player: ${selectedPlayer.name} (ID: ${selectedPlayer.id})');

    DialogService.showInformation(
      context,
      title: 'Assessment Started',
      message: 'Assessment ID: $_assessmentId\nType: ${assessment['type']}\nPlayer: ${selectedPlayer.name}',
    );
  }

  void _completeAssessment() {
    setState(() {
      _workflowState = AssessmentWorkflowState.results;
    });
  }

  String _validateAssessmentType(String assessmentType) {
    const assessmentTypeMapping = {
      'accuracy_precision_100': 'accuracy',
      'east_west_50': 'accuracy',
      'north_south_50': 'accuracy', 
      'east_precision_mini': 'accuracy',
      'west_precision_mini': 'accuracy',
      'north_precision_mini': 'accuracy',
      'south_precision_mini': 'accuracy',
      'power_benchmark_60': 'power',
      'slap_shot_power_mini': 'power',
      'wrist_shot_power_mini': 'power',
      'one_timer_power_mini': 'power',
    };
    
    return assessmentTypeMapping[assessmentType] ?? 'accuracy';
  }

  // FIXED: Using correct method names that exist in ShotAssessmentService
  Future<void> _finishAssessment() async {
    setState(() {
      _isLoading = true;
    });

    final dialogContext = context;

    try {
      final appState = Provider.of<AppState>(dialogContext, listen: false);

      final List<Map<String, dynamic>> shots = [];
      _shotResults.forEach((groupId, groupShots) {
        for (var shot in groupShots) {
          shots.add({
            'player_id': _assessment!['player_id'],
            'zone': shot.zone,
            'type': shot.type,
            'success': shot.success,
            'outcome': shot.outcome,
            'power': shot.power,
            'quick_release': shot.quickRelease,
            'date': shot.timestamp.toIso8601String(),
            'assessment_id': _assessmentId,
            'source': 'assessment',
            'group_index': groupId,
            'intended_zone': shot.intendedZone,
            'intended_direction': shot.intendedDirection,
          });
        }
      });

      print('ShotAssessmentScreen: Creating assessment with ${shots.length} shots');

      final assessmentData = {
        'id': _assessmentId,
        'assessment_type': _validateAssessmentType(_assessment!['type']),
        'title': _assessment!['title'],
        'description': _assessment!['description'],
        'player_id': _assessment!['player_id'],
        'date': _assessment!['date'] ?? DateTime.now().toIso8601String(),
        'assessment_config': {
          'groups': _assessment!['groups'],
        },
        'shots': shots, // Include shots in the assessment data
      };

      print('ShotAssessmentScreen: Creating assessment with ID: $_assessmentId');

      // FIXED: Using the correct method name from ShotAssessmentService
      try {
        final assessmentResult = await ApiServiceFactory.shotAssessment.createShotAssessment(
          assessmentData,
        );
        
        if (assessmentResult != null && assessmentResult.containsKey('assessment')) {
          final assessment = assessmentResult['assessment'];
          if (assessment != null && assessment.containsKey('id')) {
            _assessmentId = assessment['id'].toString();
          }
        }
        
      } catch (e) {
        print('ShotAssessmentScreen: Error creating shot assessment: $e');
        await DialogService.showError(
          dialogContext,
          title: 'Error',
          message: 'Error creating shot assessment: $e',
        );
        setState(() {
          _isLoading = false;
        });
        return;
      }

      // FIXED: Using the correct method name from ShotAssessmentService
      try {
        await ApiServiceFactory.shotAssessment.completeShotAssessment(
          _assessmentId!,
          context: dialogContext,
        );

        print('ShotAssessmentScreen: Assessment completed successfully');
        
        await DialogService.showSuccess(
          dialogContext,
          title: 'Assessment Complete',
          message: 'Assessment ID: $_assessmentId\nAll shots have been recorded and analytics updated!',
        );
      } catch (e) {
        print('ShotAssessmentScreen: Error completing shot assessment: $e');
        await DialogService.showError(
          dialogContext,
          title: 'Error',
          message: 'Failed to complete assessment: $e',
        );
        setState(() {
          _isLoading = false;
        });
        return;
      }

      appState.clearCurrentAssessmentId();
      _resetAssessment();

      Navigator.pop(dialogContext, true);
    } catch (e) {
      print('ShotAssessmentScreen: Error finishing assessment: $e');
      await DialogService.showError(
        dialogContext,
        title: 'Error',
        message: 'Error completing assessment: $e',
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
    print('ShotAssessmentScreen: build called at ${DateTime.now()}');
    print('ShotAssessmentScreen: Navigation source: ${routeSettings?.name}, arguments: ${routeSettings?.arguments}');

    return AdaptiveScaffold(
      title: 'Shot Assessment',
      backgroundColor: Colors.grey[100],
      leading: _buildLeadingButton(),
      body: LoadingOverlay(
        isLoading: _isLoading,
        message: 'Updating analytics...',
        color: Colors.cyanAccent,
        child: Consumer<AppState>(
          builder: (context, appState, child) {
            print('ShotAssessmentScreen: Consumer rebuild - isLoadingPlayers: ${appState.isLoadingPlayers}');
            print('ShotAssessmentScreen: Players count: ${appState.players.length}');
            print('ShotAssessmentScreen: Selected player: "${appState.selectedPlayer}"');
            
            if (!_isInitialized || appState.isLoadingPlayers) {
              print('ShotAssessmentScreen: Still initializing...');
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const CircularProgressIndicator(),
                    ResponsiveSpacing(multiplier: 2),
                    ResponsiveText('Loading players...', baseFontSize: 16),
                  ],
                ),
              );
            }
            
            if (appState.players.isEmpty) {
              print('ShotAssessmentScreen: No players available');
              return Center(
                child: SingleChildScrollView(
                  padding: ResponsiveConfig.paddingAll(context, 16),
                  child: ConstrainedBox(
                    constraints: ResponsiveConfig.constraints(context, maxWidth: 400),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.people_outline,
                          size: ResponsiveConfig.iconSize(context, 80),
                          color: Colors.grey[400],
                        ),
                        ResponsiveSpacing(multiplier: 2),
                        ResponsiveText(
                          'No players available',
                          baseFontSize: 20,
                          style: TextStyle(fontWeight: FontWeight.bold),
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
                            print('ShotAssessmentScreen: Redirecting to player registration');
                            Navigator.pushReplacementNamed(context, '/player-registration');
                          },
                          baseHeight: 48,
                          width: double.infinity,
                          backgroundColor: Colors.cyanAccent,
                          foregroundColor: Colors.black87,
                          prefix: Icon(Icons.person_add, color: Colors.black87),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }
            
            if (!_isValidPlayerSelected(appState)) {
              print('ShotAssessmentScreen: No valid player selected, showing player selection');
              return Center(
                child: SingleChildScrollView(
                  padding: ResponsiveConfig.paddingAll(context, 16),
                  child: ConstrainedBox(
                    constraints: ResponsiveConfig.constraints(context, maxWidth: 400),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.person_search,
                          size: ResponsiveConfig.iconSize(context, 80),
                          color: Colors.grey[400],
                        ),
                        ResponsiveSpacing(multiplier: 2),
                        ResponsiveText(
                          'No player selected',
                          baseFontSize: 20,
                          style: TextStyle(fontWeight: FontWeight.bold),
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
                            print('ShotAssessmentScreen: Redirecting to PlayersScreen for selection');
                            Navigator.pushReplacementNamed(context, '/players');
                          },
                          baseHeight: 48,
                          width: double.infinity,
                          backgroundColor: Colors.cyanAccent,
                          foregroundColor: Colors.black87,
                          prefix: Icon(Icons.people, color: Colors.black87),
                        ),
                        ResponsiveSpacing(multiplier: 2),
                        DropdownButtonFormField<String>(
                          decoration: InputDecoration(
                            labelText: 'Quick Select Player',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          value: appState.selectedPlayer?.isNotEmpty == true ? appState.selectedPlayer : null,
                          items: appState.players.map((player) {
                            return DropdownMenuItem<String>(
                              value: player.name,
                              child: ResponsiveText(player.name, baseFontSize: 16),
                            );
                          }).toList(),
                          onChanged: (playerName) {
                            if (playerName != null) {
                              print('ShotAssessmentScreen: Quick selected player: $playerName');
                              appState.setSelectedPlayer(playerName);
                            }
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }
            
            return _buildBody(appState);
          },
        ),
      ),
    );
  }

  Widget? _buildLeadingButton() {
    if (_workflowState == AssessmentWorkflowState.execution) {
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
              final appState = Provider.of<AppState>(context, listen: false);
              appState.clearCurrentAssessmentId();
              _resetAssessment();
              Navigator.pop(context, false);
            }
          });
        },
      );
    }
    return null;
  }

  Widget _buildBody(AppState appState) {
    print('ShotAssessmentScreen: Building body for player: ${appState.selectedPlayer}');

    // Safely get the selected player
    final selectedPlayer = _getSelectedPlayer(appState);
    if (selectedPlayer == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error, size: ResponsiveConfig.iconSize(context, 80), color: Colors.red),
            ResponsiveSpacing(multiplier: 2),
            ResponsiveText('Error: No valid player selected', baseFontSize: 16),
            ResponsiveSpacing(multiplier: 2),
            ResponsiveButton(
              text: 'Select Player',
              onPressed: () => Navigator.pushReplacementNamed(context, '/players'),
              baseHeight: 48,
              backgroundColor: Colors.cyanAccent,
              foregroundColor: Colors.black87,
            ),
          ],
        ),
      );
    }

    // Safely set player information in assessment
    if (_assessment != null && _assessment!['player_id'] == null) {
      if (selectedPlayer.id != null) {
        _assessment!['player_id'] = selectedPlayer.id!;
        _assessment!['playerName'] = selectedPlayer.name;
      } else {
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error, size: ResponsiveConfig.iconSize(context, 80), color: Colors.red),
              ResponsiveSpacing(multiplier: 2),
              ResponsiveText('Error: Player "${selectedPlayer.name}" has invalid ID', baseFontSize: 16),
              ResponsiveSpacing(multiplier: 2),
              ResponsiveButton(
                text: 'Select Different Player',
                onPressed: () => Navigator.pushReplacementNamed(context, '/players'),
                baseHeight: 48,
                backgroundColor: Colors.cyanAccent,
                foregroundColor: Colors.black87,
                prefix: Icon(Icons.people, color: Colors.black87),
              ),
            ],
          ),
        );
      }
    }

    return AdaptiveLayout(
      builder: (deviceType, isLandscape) {
        return _buildWorkflowContent(deviceType, isLandscape, selectedPlayer);
      },
    );
  }

  Widget _buildWorkflowContent(DeviceType deviceType, bool isLandscape, Player selectedPlayer) {
    switch (_workflowState) {
      case AssessmentWorkflowState.setup:
        return _buildSetupContent(deviceType, isLandscape);
      case AssessmentWorkflowState.execution:
        return _buildExecutionContent(deviceType, isLandscape);
      case AssessmentWorkflowState.results:
        return _buildResultsContent(deviceType, isLandscape);
    }
  }

  Widget _buildSetupContent(DeviceType deviceType, bool isLandscape) {
    return SingleChildScrollView(
      padding: ResponsiveConfig.paddingAll(context, 16),
      child: ConstrainedBox(
        constraints: ResponsiveConfig.constraints(
          context,
          maxWidth: deviceType == DeviceType.desktop ? 800 : null,
        ),
        child: ShotAssessmentSetupScreen(
          onStart: _startAssessment,
        ),
      ),
    );
  }

  Widget _buildExecutionContent(DeviceType deviceType, bool isLandscape) {
    if (deviceType == DeviceType.mobile && !isLandscape) {
      // Mobile Portrait: Stack vertically with collapsible recent shots
      return Column(
        children: [
          Expanded(
            child: ShotAssessmentExecutionScreen(
              assessment: _assessment!,
              shotResults: _shotResults,
              onAddShot: _addShot,
              onComplete: _completeAssessment,
            ),
          ),
          if (_showRecentShots) 
            Container(
              height: ResponsiveConfig.dimension(context, 200),
              child: _buildRecentShots(),
            ),
        ],
      );
    } else {
      // Tablet/Desktop: Side-by-side with responsive ratios
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: _showRecentShots ? 7 : 10,
            child: ShotAssessmentExecutionScreen(
              assessment: _assessment!,
              shotResults: _shotResults,
              onAddShot: _addShot,
              onComplete: _completeAssessment,
            ),
          ),
          if (_showRecentShots)
            Expanded(
              flex: 3,
              child: _buildRecentShots(),
            )
          else
            Container(
              width: ResponsiveConfig.dimension(context, 40),
              child: _buildCollapsedRecentShots(),
            ),
        ],
      );
    }
  }

  Widget _buildResultsContent(DeviceType deviceType, bool isLandscape) {
    final resultsForDisplay = _shotResults.map((key, shots) => MapEntry(
          key.toString(),
          shots
              .map((shot) => {
                    'zone': shot.zone,
                    'type': shot.type,
                    'success': shot.success,
                    'outcome': shot.outcome,
                    'power': shot.power,
                    'quick_release': shot.quickRelease,
                    'date': shot.timestamp.toIso8601String(),
                    'source': 'assessment',
                    'assessment_id': _assessmentId,
                    'group_index': key,
                    'intended_zone': shot.intendedZone,
                    'intended_direction': shot.intendedDirection,
                  })
              .toList(),
        ));
    
    return ShotAssessmentResultsScreen(
      assessment: _assessment!,
      shotResults: resultsForDisplay,
      onReset: _resetAssessment,
      onSave: _finishAssessment,
      playerId: _assessment!['player_id'],
    );
  }

  Widget _buildRecentShots() {
    return Consumer<AppState>(
      builder: (context, appState, child) {
        print('ShotAssessmentScreen: Recent Shots Debug:');
        print('ShotAssessmentScreen: Current Assessment ID: $_assessmentId');
        print('ShotAssessmentScreen: Total shots in appState: ${appState.shots.length}');

        final recentShots = appState.shots.where((shot) {
          final isAssessmentSource = shot.source == 'assessment';
          final matchesAssessmentId = shot.assessmentId == _assessmentId;
          if (isAssessmentSource) {
            print('ShotAssessmentScreen: Assessment shot found: ID=${shot.id}, AssessmentId=${shot.assessmentId}, Zone=${shot.zone}, Type=${shot.type}');
          }
          return isAssessmentSource && matchesAssessmentId;
        }).toList()..sort((a, b) => b.timestamp.compareTo(a.timestamp));

        print('ShotAssessmentScreen: Recent shots to display: ${recentShots.length}');

        return Container(
          padding: ResponsiveConfig.paddingSymmetric(context, horizontal: 12, vertical: 8),
          color: Colors.grey[100],
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with toggle button
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ResponsiveText(
                          'Recent Shots',
                          baseFontSize: 14,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.blueGrey[800],
                          ),
                        ),
                        if (_assessmentId != null)
                          ResponsiveText(
                            'ID: ${_assessmentId!.substring(_assessmentId!.length - 6)}',
                            baseFontSize: 10,
                            style: TextStyle(
                              color: Colors.blueGrey[600],
                              fontFamily: 'monospace',
                            ),
                          ),
                      ],
                    ),
                  ),
                  // Toggle button
                  IconButton(
                    onPressed: () => setState(() => _showRecentShots = !_showRecentShots),
                    icon: Icon(Icons.chevron_right),
                    tooltip: 'Hide Recent Shots',
                    padding: EdgeInsets.all(ResponsiveConfig.spacing(context, 0.5)),
                    constraints: BoxConstraints(
                      minWidth: ResponsiveConfig.dimension(context, 32), 
                      minHeight: ResponsiveConfig.dimension(context, 32)
                    ),
                    iconSize: ResponsiveConfig.iconSize(context, 20),
                  ),
                ],
              ),
              ResponsiveSpacing(multiplier: 0.5),
              ResponsiveText(
                '${recentShots.length} shots recorded',
                baseFontSize: 11,
                style: TextStyle(color: Colors.blueGrey[600]),
              ),
              ResponsiveSpacing(multiplier: 0.75),
              Expanded(
                child: recentShots.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.sports_hockey,
                              size: ResponsiveConfig.iconSize(context, 40),
                              color: Colors.blueGrey[400],
                            ),
                            ResponsiveSpacing(multiplier: 0.75),
                            ResponsiveText(
                              'No shots recorded yet',
                              baseFontSize: 12,
                              style: TextStyle(color: Colors.blueGrey[600]),
                              textAlign: TextAlign.center,
                            ),
                            if (_assessmentId != null)
                              ResponsiveText(
                                'Assessment: ${_assessmentId!.substring(_assessmentId!.length - 6)}',
                                baseFontSize: 10,
                                style: TextStyle(color: Colors.blueGrey[500]),
                              ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        itemCount: recentShots.length,
                        itemBuilder: (context, index) {
                          final shot = recentShots[index];
                          return ResponsiveCard(
                            margin: ResponsiveConfig.paddingSymmetric(context, vertical: 2),
                            elevation: 1,
                            child: ListTile(
                              dense: true,
                              contentPadding: ResponsiveConfig.paddingSymmetric(context, horizontal: 8, vertical: 2),
                              title: ResponsiveText(
                                '${shot.type} - Zone ${shot.zone}',
                                baseFontSize: 12,
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.blueGrey[800],
                                ),
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  ResponsiveText(
                                    'Outcome: ${shot.outcome}',
                                    baseFontSize: 10,
                                    style: TextStyle(color: Colors.blueGrey[600]),
                                  ),
                                  ResponsiveText(
                                    shot.timestamp.toString().substring(11, 19),
                                    baseFontSize: 9,
                                    style: TextStyle(color: Colors.blueGrey[500]),
                                  ),
                                ],
                              ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  if (shot.power != null)
                                    Padding(
                                      padding: ResponsiveConfig.paddingSymmetric(context, horizontal: 6),
                                      child: ResponsiveText(
                                        '${shot.power!.toStringAsFixed(1)}mph',
                                        baseFontSize: 9,
                                        style: TextStyle(color: Colors.blueGrey[600]),
                                      ),
                                    ),
                                  shot.success
                                      ? Icon(Icons.check_circle, color: Colors.green, size: ResponsiveConfig.iconSize(context, 16))
                                      : Icon(Icons.cancel, color: Colors.red, size: ResponsiveConfig.iconSize(context, 16)),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCollapsedRecentShots() {
    return Container(
      color: Colors.grey[200],
      child: Column(
        children: [
          // Toggle button to expand
          Container(
            width: double.infinity,
            height: ResponsiveConfig.dimension(context, 50),
            child: IconButton(
              onPressed: () => setState(() => _showRecentShots = !_showRecentShots),
              icon: Icon(Icons.chevron_left),
              tooltip: 'Show Recent Shots',
            ),
          ),
          // Vertical "Recent Shots" text
          Expanded(
            child: RotatedBox(
              quarterTurns: 3,
              child: Center(
                child: ResponsiveText(
                  'Recent Shots',
                  baseFontSize: 12,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.blueGrey[600],
                  ),
                ),
              ),
            ),
          ),
          // Shot count indicator
          Consumer<AppState>(
            builder: (context, appState, child) {
              final recentShots = appState.shots.where((shot) {
                return shot.source == 'assessment' && shot.assessmentId == _assessmentId;
              }).toList();
              
              return Container(
                width: ResponsiveConfig.dimension(context, 32),
                height: ResponsiveConfig.dimension(context, 32),
                margin: ResponsiveConfig.paddingSymmetric(context, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.blueGrey[600],
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Center(
                  child: ResponsiveText(
                    '${recentShots.length}',
                    baseFontSize: 12,
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  // FIXED: Enhanced addShot method with proper type handling
  void _addShot(int groupIndex, Shot result) {
    setState(() {
      _shotResults[groupIndex] ??= [];
      _shotResults[groupIndex]!.add(result);
    });

    // FIXED: Also add to AppState with proper type conversion
    try {
      final appState = Provider.of<AppState>(context, listen: false);
      appState.addShot(result); // Pass Shot object directly
    } catch (e) {
      print('ShotAssessmentScreen: Error adding shot to AppState: $e');
    }

    print('ShotAssessmentScreen: Shot added to group $groupIndex: ${result.type} in zone ${result.zone} (Assessment: ${result.assessmentId})');
    print('ShotAssessmentScreen: Group $groupIndex now has ${_shotResults[groupIndex]!.length} shots');
  }
}

// Assessment workflow state enum
enum AssessmentWorkflowState { setup, execution, results }