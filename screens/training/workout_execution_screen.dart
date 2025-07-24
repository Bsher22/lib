import 'package:flutter/material.dart';
import 'package:hockey_shot_tracker/responsive_system/index.dart';
import 'package:hockey_shot_tracker/models/training_program.dart';
import 'package:hockey_shot_tracker/models/program_sequence.dart';
import 'package:hockey_shot_tracker/models/shot.dart';
import 'package:hockey_shot_tracker/services/dialog_service.dart';
import 'package:hockey_shot_tracker/services/infrastructure/api_service_factory.dart';
import 'package:provider/provider.dart';
import 'package:hockey_shot_tracker/providers/app_state.dart';
import 'package:hockey_shot_tracker/widgets/core/form/index.dart';
import 'package:hockey_shot_tracker/widgets/core/state/index.dart';
import 'package:hockey_shot_tracker/widgets/core/selection/index.dart';
import 'package:hockey_shot_tracker/widgets/core/timer/index.dart';

class WorkoutExecutionScreen extends StatefulWidget {
  const WorkoutExecutionScreen({super.key});

  @override
  State<WorkoutExecutionScreen> createState() => _WorkoutExecutionScreenState();
}

class _WorkoutExecutionScreenState extends State<WorkoutExecutionScreen> {
  int _currentSequenceIndex = 0;
  int _shotsCompleted = 0;
  int _successfulShots = 0;
  final List<Shot> _recordedShots = [];
  bool _isRecording = false;
  bool _isCompleting = false;
  String? _temporaryZone;
  int? _currentWorkoutSessionId; // Track the current workout session

  // Notes field
  final TextEditingController _notesController = TextEditingController();
  String _workoutNotes = '';

  // Outcome selection
  String? _selectedOutcome;

  // Timer controller
  final UnifiedTimerController _workoutTimerController = UnifiedTimerController(updateInterval: 1000);

  // Late initialized properties from route arguments
  late TrainingProgram program;
  late List<ProgramSequence> sequences;

  ProgramSequence get _currentSequence => sequences[_currentSequenceIndex];
  bool get _isLastSequence => _currentSequenceIndex >= sequences.length - 1;

  @override
  void initState() {
    super.initState();
    _workoutTimerController.start();

    // Schedule initialization after the widget is built
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeFromArguments();
    });
  }

  void _initializeFromArguments() {
    final args = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
    setState(() {
      program = args['program'] as TrainingProgram;
      sequences = args['sequences'] as List<ProgramSequence>;
    });
  }

  @override
  void dispose() {
    _workoutTimerController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _recordShotOutcome(bool success, String outcome) async {
    setState(() {
      _selectedOutcome = outcome;
    });

    final zone = _temporaryZone ?? _currentSequence.getTargetZonesList().first;

    final appState = Provider.of<AppState>(context, listen: false);
    final playerId = appState.players.firstWhere((p) => p.name == appState.selectedPlayer).id ?? 0;

    // Enhanced shot data with source tracking
    final shotData = {
      'player_id': playerId,
      'zone': zone,
      'type': _currentSequence.shotType,
      'success': success,
      'outcome': outcome,
      'date': DateTime.now().toIso8601String(),
      'power': 75.0, // Could make this configurable
      'quick_release': 0.5, // Could make this configurable
      'workout': program.name,
      'source': 'workout', // Mark as workout shot
      'workout_id': _currentWorkoutSessionId, // Link to workout session
      'session_notes': 'Sequence ${_currentSequence.sequenceOrder}/${sequences.length}',
    };

    try {
      final result = await ApiServiceFactory.shot.addShot(shotData);

      // Check if widget is still mounted
      if (!mounted) return;

      // Create a Shot object based on the recorded data
      final shot = Shot(
        id: result['id'],
        playerId: playerId,
        timestamp: DateTime.now(),
        success: success,
        zone: zone,
        type: _currentSequence.shotType,
        outcome: outcome,
        workout: program.name,
        power: 75.0,
        quickRelease: 0.5,
        source: 'workout',
        workoutId: _currentWorkoutSessionId,
        sessionNotes: 'Sequence ${_currentSequence.sequenceOrder}/${sequences.length}',
      );

      setState(() {
        _recordedShots.add(shot);
        _shotsCompleted++;
        if (success) _successfulShots++;
        _isRecording = false;
        _temporaryZone = null;
        _selectedOutcome = null;
      });

      // Check if current sequence is complete
      if (_calculateSequenceShotsDone() >= _currentSequence.shotCount) {
        _showSequenceCompleteDialog();
      }
    } catch (e) {
      // Check if widget is still mounted
      if (!mounted) return;

      print('Error recording workout shot: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to record shot: $e')),
      );
      setState(() {
        _isRecording = false;
        _temporaryZone = null;
        _selectedOutcome = null;
      });
    }
  }

  Future<void> _completeWorkout() async {
    if (_isCompleting) return;

    setState(() {
      _isCompleting = true;
    });

    try {
      final appState = Provider.of<AppState>(context, listen: false);
      final playerId = appState.players.firstWhere((p) => p.name == appState.selectedPlayer).id ?? 0;

      // Record the completed workout first
      final workoutData = {
        'player_id': playerId,
        'program_id': program.id,
        'program_name': program.name,
        'date_completed': DateTime.now().toIso8601String(),
        'total_shots': _shotsCompleted,
        'successful_shots': _successfulShots,
        'duration_seconds': _workoutTimerController.elapsed.inSeconds,
        'notes': _workoutNotes.isNotEmpty ? _workoutNotes : 'Completed in ${TimeFormatter.formatMMSS(_workoutTimerController.elapsed)}',
      };

      final completedWorkout = await ApiServiceFactory.training.recordCompletedWorkout(workoutData);

      // Get the completed workout ID to link shots
      final completedWorkoutId = completedWorkout['id'] as int?;

      // Update all recorded shots to link them to this completed workout
      if (completedWorkoutId != null) {
        _currentWorkoutSessionId = completedWorkoutId;
        // Note: Bulk update for existing shots would require an API endpoint
      }

      // Check if widget is still mounted
      if (!mounted) return;

      // Prepare results data for app state
      final results = {
        'workout': completedWorkout,
        'shots': _recordedShots,
        'time': _workoutTimerController.elapsed.inSeconds,
        'success_rate': _shotsCompleted > 0 ? _successfulShots / _shotsCompleted : 0,
        'workout_id': completedWorkoutId,
      };

      // Complete the workout in app state (this will handle navigation)
      appState.completeWorkout(results);
    } catch (e) {
      // Check if widget is still mounted
      if (!mounted) return;

      print('Error completing workout: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to record completed workout: $e'),
          backgroundColor: Colors.red,
        ),
      );
      setState(() {
        _isCompleting = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (ModalRoute.of(context)!.settings.arguments == null) {
      return AdaptiveScaffold(
        title: 'Loading Workout...',
        body: LoadingOverlay.simple(
          message: 'Loading workout...',
          color: Colors.cyanAccent,
        ),
      );
    }

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        _onWillPop();
      },
      child: AdaptiveScaffold(
        title: program.name,
        backgroundColor: Colors.grey[100],
        actions: [
          Container(
            padding: ResponsiveConfig.paddingSymmetric(context, horizontal: 8),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.timer, 
                  color: Colors.white,
                  size: ResponsiveConfig.iconSize(context, 20),
                ),
                ResponsiveSpacing(multiplier: 0.5, direction: Axis.horizontal),
                ResponsiveText(
                  TimeFormatter.formatMMSS(_workoutTimerController.elapsed),
                  baseFontSize: 16,
                  style: const TextStyle(color: Colors.white),
                ),
              ],
            ),
          ),
        ],
        body: AdaptiveLayout(
          builder: (deviceType, isLandscape) {
            return ConstrainedBox(
              constraints: ResponsiveConfig.constraints(
                context,
                maxWidth: deviceType == DeviceType.desktop ? 1400 : null,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildProgressIndicator(deviceType, isLandscape),
                  Expanded(
                    child: _buildWorkoutContent(deviceType, isLandscape),
                  ),
                  _buildBottomControls(deviceType, isLandscape),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildProgressIndicator(DeviceType deviceType, bool isLandscape) {
    final totalShots = program.totalShots;
    final progress = _shotsCompleted / totalShots;

    return Container(
      padding: ResponsiveConfig.paddingSymmetric(context, vertical: 8, horizontal: 16),
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              ResponsiveText(
                'Progress: $_shotsCompleted/$totalShots shots',
                baseFontSize: 16,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.blueGrey[700],
                ),
              ),
              ResponsiveText(
                '${(_successfulShots > 0 && _shotsCompleted > 0) ? (_successfulShots / _shotsCompleted * 100).toStringAsFixed(0) : 0}% Success',
                baseFontSize: 16,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.green[700],
                ),
              ),
            ],
          ),
          ResponsiveSpacing(multiplier: 1),
          LinearProgressIndicator(
            value: progress,
            backgroundColor: Colors.grey[300],
            valueColor: const AlwaysStoppedAnimation<Color>(Colors.cyanAccent),
            minHeight: ResponsiveConfig.dimension(context, 8),
            borderRadius: ResponsiveConfig.borderRadius(context, 4),
          ),
        ],
      ),
    );
  }

  Widget _buildWorkoutContent(DeviceType deviceType, bool isLandscape) {
    return AdaptiveLayout(
      builder: (deviceType, isLandscape) {
        switch (deviceType) {
          case DeviceType.mobile:
            return _buildMobileLayout();
          case DeviceType.tablet:
            return _buildTabletLayout(isLandscape);
          case DeviceType.desktop:
            return _buildDesktopLayout();
        }
      },
    );
  }

  Widget _buildMobileLayout() {
    return SingleChildScrollView(
      padding: ResponsiveConfig.paddingAll(context, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildCurrentSequenceCard(),
          ResponsiveSpacing(multiplier: 3),
          _buildZoneSelector(),
          ResponsiveSpacing(multiplier: 3),
          _buildShotTypeCard(),
          ResponsiveSpacing(multiplier: 3),
          _buildNotesCard(),
          ResponsiveSpacing(multiplier: 8), // Extra space for bottom controls
        ],
      ),
    );
  }

  Widget _buildTabletLayout(bool isLandscape) {
    if (!isLandscape) {
      return _buildMobileLayout();
    }

    return Row(
      children: [
        Expanded(
          flex: 6,
          child: SingleChildScrollView(
            padding: ResponsiveConfig.paddingAll(context, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildCurrentSequenceCard(),
                ResponsiveSpacing(multiplier: 3),
                _buildZoneSelector(),
                ResponsiveSpacing(multiplier: 3),
                _buildShotTypeCard(),
              ],
            ),
          ),
        ),
        Expanded(
          flex: 4,
          child: SingleChildScrollView(
            padding: ResponsiveConfig.paddingAll(context, 16),
            child: _buildNotesCard(),
          ),
        ),
      ],
    );
  }

  Widget _buildDesktopLayout() {
    return Row(
      children: [
        Expanded(
          flex: 7,
          child: SingleChildScrollView(
            padding: ResponsiveConfig.paddingAll(context, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: _buildCurrentSequenceCard(),
                    ),
                    ResponsiveSpacing(multiplier: 2, direction: Axis.horizontal),
                    Expanded(
                      child: _buildShotTypeCard(),
                    ),
                  ],
                ),
                ResponsiveSpacing(multiplier: 3),
                _buildZoneSelector(),
              ],
            ),
          ),
        ),
        Container(
          width: 320,
          decoration: BoxDecoration(
            color: Colors.grey[50],
            border: Border(left: BorderSide(color: Colors.grey[300]!)),
          ),
          child: _buildDesktopSidebar(),
        ),
      ],
    );
  }

  Widget _buildDesktopSidebar() {
    return SingleChildScrollView(
      padding: ResponsiveConfig.paddingAll(context, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          ResponsiveText(
            'Workout Progress',
            baseFontSize: 18,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.blueGrey[800],
            ),
          ),
          ResponsiveSpacing(multiplier: 2),
          _buildProgressCard('Sequences', '${_currentSequenceIndex + 1}/${sequences.length}'),
          ResponsiveSpacing(multiplier: 2),
          _buildProgressCard('Success Rate', '${(_successfulShots > 0 && _shotsCompleted > 0) ? (_successfulShots / _shotsCompleted * 100).toStringAsFixed(0) : 0}%'),
          ResponsiveSpacing(multiplier: 3),
          _buildNotesCard(),
          ResponsiveSpacing(multiplier: 3),
          ResponsiveText(
            'Quick Actions',
            baseFontSize: 18,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.blueGrey[800],
            ),
          ),
          ResponsiveSpacing(multiplier: 2),
          if (!_isRecording) ...[
            ResponsiveButton(
              text: 'Record Shot',
              onPressed: _openShotRecording,
              baseHeight: 48,
              width: double.infinity,
              backgroundColor: Colors.cyanAccent,
              foregroundColor: Colors.black87,
              icon: Icons.add,
            ),
            ResponsiveSpacing(multiplier: 2),
          ],
          ResponsiveButton(
            text: _isLastSequence ? 'Complete' : 'Next Sequence',
            onPressed: _isLastSequence ? _completeWorkout : _moveToNextSequence,
            baseHeight: 48,
            width: double.infinity,
            backgroundColor: _isLastSequence ? Colors.green : Colors.blueGrey[700],
            foregroundColor: Colors.white,
          ),
        ],
      ),
    );
  }

  Widget _buildProgressCard(String label, String value) {
    return ResponsiveCard(
      padding: ResponsiveConfig.paddingAll(context, 12),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ResponsiveText(
            value,
            baseFontSize: 24,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.blueGrey[800],
            ),
          ),
          ResponsiveText(
            label,
            baseFontSize: 12,
            style: TextStyle(color: Colors.blueGrey[600]),
          ),
        ],
      ),
    );
  }

  Widget _buildCurrentSequenceCard() {
    final targetZones = _currentSequence.getTargetZonesList();
    final sequenceShotsTotal = _currentSequence.shotCount;
    final sequenceShotsDone = _calculateSequenceShotsDone();

    return ResponsiveCard(
      elevation: 4,
      baseBorderRadius: 16,
      child: Padding(
        padding: ResponsiveConfig.paddingAll(context, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                ResponsiveText(
                  'Sequence ${_currentSequence.sequenceOrder}/${sequences.length}',
                  baseFontSize: 18,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.blueGrey[900],
                  ),
                ),
                ResponsiveText(
                  '$sequenceShotsDone/$sequenceShotsTotal shots',
                  baseFontSize: 16,
                  style: TextStyle(color: Colors.blueGrey[700]),
                ),
              ],
            ),
            ResponsiveSpacing(multiplier: 2),
            ResponsiveText(
              '${_currentSequence.shotCount} ${_currentSequence.shotType} Shots',
              baseFontSize: 20,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.blueGrey[800],
              ),
            ),
            ResponsiveSpacing(multiplier: 1),
            if (_currentSequence.description != null) ...[
              ResponsiveText(
                _currentSequence.description!,
                baseFontSize: 16,
                style: TextStyle(color: Colors.blueGrey[600]),
              ),
              ResponsiveSpacing(multiplier: 2),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildZoneSelector() {
    final targetZones = _currentSequence.getTargetZonesList();
    final allZones = List.generate(9, (index) => (index + 1).toString());

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        ResponsiveText(
          'Target Zones',
          baseFontSize: 18,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.blueGrey[900],
          ),
        ),
        ResponsiveSpacing(multiplier: 2),
        AspectRatio(
          aspectRatio: 1.5,
          child: GridSelector<String>(
            options: allZones,
            selectedOption: _temporaryZone,
            onSelected: (zone) => _recordShot(zone),
            labelBuilder: (zone) => zone,
            sublabelBuilder: (zone) => targetZones.contains(zone) ? 'Tap to record' : '',
            crossAxisCount: 3,
            selectedColor: Colors.cyanAccent,
            unselectedColor: Colors.grey[200]!,
            isOptionDisabled: (zone) => !targetZones.contains(zone),
          ),
        ),
      ],
    );
  }

  Widget _buildShotTypeCard() {
    return ResponsiveCard(
      padding: ResponsiveConfig.paddingAll(context, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          ResponsiveText(
            'Shot Type',
            baseFontSize: 18,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.blueGrey[900],
            ),
          ),
          ResponsiveSpacing(multiplier: 1),
          Container(
            padding: ResponsiveConfig.paddingAll(context, 16),
            decoration: BoxDecoration(
              color: Colors.blueGrey[50],
              borderRadius: ResponsiveConfig.borderRadius(context, 12),
              border: Border.all(color: Colors.blueGrey[200]!),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.sports_hockey, 
                  color: Colors.blueGrey[700],
                  size: ResponsiveConfig.iconSize(context, 24),
                ),
                ResponsiveSpacing(multiplier: 1.5, direction: Axis.horizontal),
                ResponsiveText(
                  _currentSequence.shotType,
                  baseFontSize: 18,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.blueGrey[700],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotesCard() {
    return ResponsiveCard(
      padding: ResponsiveConfig.paddingAll(context, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          ResponsiveText(
            'Workout Notes',
            baseFontSize: 18,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.blueGrey[900],
            ),
          ),
          ResponsiveSpacing(multiplier: 1),
          StandardTextField(
            controller: _notesController,
            labelText: 'Workout Notes',
            prefixIcon: Icons.note_alt,
            helperText: 'Add any observations or notes about this workout',
            maxLines: 3,
            onChanged: (value) {
              _workoutNotes = value;
            },
          ),
        ],
      ),
    );
  }

  Widget _buildBottomControls(DeviceType deviceType, bool isLandscape) {
    return AdaptiveLayout(
      builder: (deviceType, isLandscape) {
        // Hide bottom controls on desktop as we have sidebar actions
        if (deviceType == DeviceType.desktop) {
          return SizedBox.shrink();
        }

        return Container(
          padding: ResponsiveConfig.paddingAll(context, 16),
          decoration: const BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black12,
                blurRadius: 4,
                offset: Offset(0, -2),
              ),
            ],
          ),
          child: _isRecording
              ? _buildShotRecordingControls()
              : _buildMainControls(),
        );
      },
    );
  }

  Widget _buildMainControls() {
    return Row(
      children: [
        Expanded(
          child: ResponsiveButton(
            text: 'Record Shot',
            onPressed: _openShotRecording,
            baseHeight: 48,
            backgroundColor: Colors.cyanAccent,
            foregroundColor: Colors.black87,
            icon: Icons.add,
          ),
        ),
        ResponsiveSpacing(multiplier: 2, direction: Axis.horizontal),
        ResponsiveButton(
          text: _isLastSequence ? 'Complete' : 'Next',
          onPressed: _isLastSequence ? _completeWorkout : _moveToNextSequence,
          baseHeight: 48,
          width: ResponsiveConfig.dimension(context, 120),
          backgroundColor: _isLastSequence ? Colors.green : Colors.blueGrey[700],
          foregroundColor: Colors.white,
        ),
      ],
    );
  }

  Widget _buildShotRecordingControls() {
    final outcomes = [
      {'label': 'Goal', 'value': 'Goal', 'color': Colors.green, 'success': true},
      {'label': 'Miss', 'value': 'Miss', 'color': Colors.red, 'success': false},
      {'label': 'Save', 'value': 'Save', 'color': Colors.orange, 'success': false},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        ResponsiveText(
          'Shot Outcome',
          baseFontSize: 16,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.blueGrey[900],
          ),
        ),
        ResponsiveSpacing(multiplier: 1.5),
        ToggleButtonGroup<Map<String, dynamic>>(
          options: outcomes,
          selectedOption: _selectedOutcome != null
              ? outcomes.firstWhere((o) => o['value'] == _selectedOutcome)
              : null,
          onSelected: (outcome) => _recordShotOutcome(
            outcome['success'] as bool,
            outcome['value'] as String,
          ),
          labelBuilder: (outcome) => outcome['label'] as String,
          iconBuilder: (outcome) => Icon(
            outcome['success'] as bool
                ? Icons.check_circle
                : outcome['value'] == 'Miss'
                    ? Icons.cancel
                    : Icons.shield,
            size: ResponsiveConfig.iconSize(context, 18),
          ),
          colorBuilder: (outcome, isSelected) => outcome['color'] as Color,
          borderRadius: ResponsiveConfig.borderRadius(context, 12),
        ),
        ResponsiveSpacing(multiplier: 1.5),
        Center(
          child: TextButton(
            onPressed: () {
              setState(() {
                _isRecording = false;
                _temporaryZone = null;
                _selectedOutcome = null;
              });
            },
            child: ResponsiveText(
              'Cancel',
              baseFontSize: 16,
            ),
          ),
        ),
      ],
    );
  }

  void _openShotRecording() {
    setState(() {
      _isRecording = true;
    });
  }

  void _recordShot(String zone) {
    setState(() {
      _temporaryZone = zone;
      _isRecording = true;
    });
  }

  int _calculateSequenceShotsDone() {
    if (_currentSequenceIndex == 0) {
      return _shotsCompleted;
    }

    int previousShots = 0;
    for (int i = 0; i < _currentSequenceIndex; i++) {
      previousShots += sequences[i].shotCount;
    }

    return _shotsCompleted - previousShots;
  }

  void _showSequenceCompleteDialog() {
    DialogService.showCustom<void>(
      context,
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: ResponsiveConfig.paddingAll(context, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.check_circle,
                  color: Colors.green,
                  size: ResponsiveConfig.iconSize(context, 64),
                ),
                ResponsiveSpacing(multiplier: 2),
                ResponsiveText(
                  'Sequence Complete!',
                  baseFontSize: 18,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.blueGrey[800],
                  ),
                ),
                ResponsiveSpacing(multiplier: 1),
                ResponsiveText(
                  'You have completed sequence ${_currentSequence.sequenceOrder}.',
                  baseFontSize: 16,
                  textAlign: TextAlign.center,
                ),
                ResponsiveSpacing(multiplier: 3),
                ResponsiveButton(
                  text: _isLastSequence ? 'Complete Workout' : 'Next Sequence',
                  onPressed: () {
                    Navigator.of(context).pop();
                    if (_isLastSequence) {
                      _showWorkoutCompleteDialog();
                    } else {
                      _moveToNextSequence();
                    }
                  },
                  baseHeight: 48,
                  backgroundColor: Colors.cyanAccent[700],
                  foregroundColor: Colors.white,
                ),
              ],
            ),
          ),
        ],
      ),
      barrierDismissible: false,
    );
  }

  void _moveToNextSequence() {
    if (_isLastSequence) return;

    setState(() {
      _currentSequenceIndex++;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: ResponsiveText(
          'Moving to sequence ${_currentSequenceIndex + 1}',
          baseFontSize: 16,
        ),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _showWorkoutCompleteDialog() {
    DialogService.showCustom<void>(
      context,
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: ResponsiveConfig.paddingAll(context, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.emoji_events,
                  color: Colors.amber,
                  size: ResponsiveConfig.iconSize(context, 64),
                ),
                ResponsiveSpacing(multiplier: 2),
                ResponsiveText(
                  'Workout Complete!',
                  baseFontSize: 18,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.blueGrey[800],
                  ),
                ),
                ResponsiveSpacing(multiplier: 1),
                ResponsiveText(
                  'Congratulations! You have completed the entire workout.',
                  baseFontSize: 16,
                  textAlign: TextAlign.center,
                ),
                ResponsiveSpacing(multiplier: 2),
                ResponsiveText(
                  'Total Shots: $_shotsCompleted',
                  baseFontSize: 14,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                ResponsiveText(
                  'Successful Shots: $_successfulShots',
                  baseFontSize: 14,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                ResponsiveText(
                  'Success Rate: ${(_successfulShots / _shotsCompleted * 100).toStringAsFixed(1)}%',
                  baseFontSize: 14,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                ResponsiveText(
                  'Time: ${TimeFormatter.formatMMSS(_workoutTimerController.elapsed)}',
                  baseFontSize: 14,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                ResponsiveSpacing(multiplier: 3),
                ResponsiveButton(
                  text: 'Save & Finish',
                  onPressed: () {
                    Navigator.of(context).pop();
                    _completeWorkout();
                  },
                  baseHeight: 48,
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                ),
              ],
            ),
          ),
        ],
      ),
      barrierDismissible: false,
    );
  }

  void _onWillPop() async {
    final appState = Provider.of<AppState>(context, listen: false);
    final navigator = Navigator.of(context);

    if (_shotsCompleted > 0) {
      final result = await DialogService.showConfirmation(
        context,
        title: 'Exit Workout?',
        message: 'Your progress will be lost if you exit now. Are you sure you want to quit this workout?',
        confirmLabel: 'Exit',
        cancelLabel: 'Cancel',
        isDestructive: true,
      );

      if (result == true) {
        appState.cancelWorkout();
        navigator.pop();
      }
    } else {
      appState.cancelWorkout();
      navigator.pop();
    }
  }
}