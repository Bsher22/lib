import 'package:flutter/material.dart';
import 'package:hockey_shot_tracker/responsive_system/index.dart';
import 'package:hockey_shot_tracker/models/training_program.dart';
import 'package:hockey_shot_tracker/models/program_sequence.dart';
import 'package:provider/provider.dart';
import 'package:hockey_shot_tracker/providers/app_state.dart';
import 'package:hockey_shot_tracker/services/infrastructure/api_service_factory.dart';
import 'package:intl/intl.dart';
import 'package:hockey_shot_tracker/widgets/core/state/index.dart';

class WorkoutDetailsScreen extends StatefulWidget {
  final TrainingProgram? program;
  final int? workoutId;
  final List<ProgramSequence>? sequences; // Make sequences optional

  const WorkoutDetailsScreen({
    super.key,
    this.program,
    this.workoutId,
    this.sequences, // Allow passing sequences directly
  }) : assert(program != null || workoutId != null, "Either program or workoutId must be provided");

  @override
  State<WorkoutDetailsScreen> createState() => _WorkoutDetailsScreenState();
}

class _WorkoutDetailsScreenState extends State<WorkoutDetailsScreen> {
  bool _isLoading = true;
  TrainingProgram? _program;
  List<ProgramSequence> _sequences = [];
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    if (widget.program != null) {
      // Use directly provided program
      setState(() {
        _program = widget.program;
        _sequences = widget.sequences ?? [];
        _isLoading = widget.sequences != null ? false : true;
      });
      if (widget.sequences == null) {
        _loadWorkoutDetails();
      }
    } else if (widget.workoutId != null) {
      _loadProgramById(widget.workoutId!);
    }
  }

  Future<void> _loadProgramById(int id) async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final appState = Provider.of<AppState>(context, listen: false);
      final programDetails = await ApiServiceFactory.training.fetchTrainingProgramDetails(id);
      
      // Extract program and sequences from program details
      final program = TrainingProgram.fromJson(programDetails);
      final sequences = (programDetails['sequences'] as List<dynamic>)
          .map((seq) => ProgramSequence.fromJson(seq as Map<String, dynamic>))
          .toList();
      
      setState(() {
        _program = program;
        _sequences = sequences;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load workout details: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _loadWorkoutDetails() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final appState = Provider.of<AppState>(context, listen: false);
      final programDetails = await ApiServiceFactory.training.fetchTrainingProgramDetails(_program!.id!);
      
      // Extract sequences from program details
      final sequences = (programDetails['sequences'] as List<dynamic>)
          .map((seq) => ProgramSequence.fromJson(seq as Map<String, dynamic>))
          .toList();
      
      setState(() {
        _sequences = sequences;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load workout details: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_program == null && _isLoading) {
      // Using LoadingOverlay for initial loading
      return AdaptiveScaffold(
        title: 'Loading Workout...',
        body: LoadingOverlay.simple(
          message: 'Loading Workout...',
          color: Colors.cyanAccent,
        ),
      );
    }

    return AdaptiveScaffold(
      title: _program?.name ?? 'Workout Details',
      backgroundColor: Colors.grey[100],
      body: AdaptiveLayout(
        builder: (deviceType, isLandscape) {
          return ConstrainedBox(
            constraints: ResponsiveConfig.constraints(
              context,
              maxWidth: deviceType == DeviceType.desktop ? 1400 : null,
            ),
            child: LoadingOverlay(
              isLoading: _isLoading,
              message: 'Loading workout details...',
              color: Colors.cyanAccent,
              child: _errorMessage != null
                  ? ErrorDisplay(
                      message: 'Error Loading Workout',
                      details: _errorMessage,
                      onRetry: () => widget.workoutId != null 
                          ? _loadProgramById(widget.workoutId!) 
                          : _loadWorkoutDetails(),
                    )
                  : _buildWorkoutDetails(deviceType, isLandscape),
            ),
          );
        },
      ),
      floatingActionButton: _isLoading || _errorMessage != null
          ? null
          : _buildFloatingActionButton(),
    );
  }

  Widget _buildWorkoutDetails(DeviceType deviceType, bool isLandscape) {
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
          _buildProgramHeader(),
          ResponsiveSpacing(multiplier: 3),
          _buildProgramDescription(),
          ResponsiveSpacing(multiplier: 3),
          _buildSequencesList(),
          ResponsiveSpacing(multiplier: 3),
          _buildRequirements(),
          ResponsiveSpacing(multiplier: 8), // Extra space for FAB
        ],
      ),
    );
  }

  Widget _buildTabletLayout(bool isLandscape) {
    if (!isLandscape) {
      return _buildMobileLayout();
    }

    return SingleChildScrollView(
      padding: ResponsiveConfig.paddingAll(context, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 6,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildProgramHeader(),
                    ResponsiveSpacing(multiplier: 3),
                    _buildProgramDescription(),
                  ],
                ),
              ),
              ResponsiveSpacing(multiplier: 2, direction: Axis.horizontal),
              Expanded(
                flex: 4,
                child: _buildRequirements(),
              ),
            ],
          ),
          ResponsiveSpacing(multiplier: 3),
          _buildSequencesList(),
          ResponsiveSpacing(multiplier: 8), // Extra space for FAB
        ],
      ),
    );
  }

  Widget _buildDesktopLayout() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 7,
          child: SingleChildScrollView(
            padding: ResponsiveConfig.paddingAll(context, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildProgramHeader(),
                ResponsiveSpacing(multiplier: 3),
                _buildProgramDescription(),
                ResponsiveSpacing(multiplier: 3),
                _buildSequencesList(),
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
            'Workout Overview',
            baseFontSize: 18,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.blueGrey[800],
            ),
          ),
          ResponsiveSpacing(multiplier: 2),
          _buildRequirements(),
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
          ResponsiveButton(
            text: 'Start Workout',
            onPressed: _startWorkout,
            baseHeight: 48,
            width: double.infinity,
            backgroundColor: Colors.cyanAccent,
            foregroundColor: Colors.black87,
            icon: Icons.play_arrow,
          ),
          ResponsiveSpacing(multiplier: 2),
          ResponsiveButton(
            text: 'Training Programs',
            onPressed: () => Navigator.pushNamed(context, '/training-programs'),
            baseHeight: 48,
            width: double.infinity,
            backgroundColor: Colors.blueGrey[700],
            foregroundColor: Colors.white,
            icon: Icons.fitness_center,
          ),
        ],
      ),
    );
  }

  Widget _buildProgramHeader() {
    return ResponsiveCard(
      elevation: 2,
      baseBorderRadius: 12,
      child: Padding(
        padding: ResponsiveConfig.paddingAll(context, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      ResponsiveText(
                        _program!.name,
                        baseFontSize: 22,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.blueGrey[900],
                        ),
                      ),
                      ResponsiveSpacing(multiplier: 0.5),
                      ResponsiveText(
                        _program!.type,
                        baseFontSize: 16,
                        style: TextStyle(color: Colors.blueGrey[600]),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: ResponsiveConfig.paddingSymmetric(context, horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: _getDifficultyColor(_program!.difficulty).withAlpha(26),
                    borderRadius: ResponsiveConfig.borderRadius(context, 16),
                    border: Border.all(
                      color: _getDifficultyColor(_program!.difficulty),
                    ),
                  ),
                  child: ResponsiveText(
                    _program!.difficulty,
                    baseFontSize: 14,
                    style: TextStyle(
                      color: _getDifficultyColor(_program!.difficulty),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            ResponsiveSpacing(multiplier: 2),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildProgramStat(
                  icon: Icons.timer,
                  label: 'Duration',
                  value: _program!.estimatedDuration != null 
                      ? '${_program!.estimatedDuration} min'
                      : _program!.duration,
                ),
                _buildProgramStat(
                  icon: Icons.sports_hockey,
                  label: 'Total Shots',
                  value: _program!.totalShots.toString(),
                ),
                _buildProgramStat(
                  icon: Icons.calendar_today,
                  label: 'Created',
                  value: DateFormat('MMM d').format(_program!.createdAt),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProgramStat({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: Colors.blueGrey[600], size: ResponsiveConfig.iconSize(context, 24)),
        ResponsiveSpacing(multiplier: 0.5),
        ResponsiveText(
          value,
          baseFontSize: 16,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.blueGrey[900],
          ),
        ),
        ResponsiveText(
          label,
          baseFontSize: 12,
          style: TextStyle(color: Colors.blueGrey[600]),
        ),
      ],
    );
  }

  Widget _buildProgramDescription() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        ResponsiveText(
          'Description',
          baseFontSize: 18,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.blueGrey[800],
          ),
        ),
        ResponsiveSpacing(multiplier: 1),
        ResponsiveText(
          _program!.description ?? 'No description available.',
          baseFontSize: 16,
          style: TextStyle(color: Colors.blueGrey[700]),
        ),
      ],
    );
  }

  Widget _buildSequencesList() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        ResponsiveText(
          'Workout Sequence',
          baseFontSize: 18,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.blueGrey[800],
          ),
        ),
        ResponsiveSpacing(multiplier: 2),
        
        // If sequences are empty, show empty state
        _sequences.isEmpty
            ? EmptyStateDisplay(
                title: 'No Sequences Available',
                description: 'This workout does not have any sequences defined yet.',
                icon: Icons.format_list_numbered,
                iconSize: ResponsiveConfig.iconSize(context, 48),
              )
            : Column(
                mainAxisSize: MainAxisSize.min,
                children: List.generate(_sequences.length, (index) {
                  final sequence = _sequences[index];
                  return _buildSequenceCard(sequence);
                }),
              ),
      ],
    );
  }

  Widget _buildSequenceCard(ProgramSequence sequence) {
    final targetZones = sequence.getTargetZonesList();
    
    return ResponsiveCard(
      margin: ResponsiveConfig.paddingSymmetric(context, vertical: 8),
      baseBorderRadius: 12,
      elevation: 1,
      child: Padding(
        padding: ResponsiveConfig.paddingAll(context, 16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: ResponsiveConfig.dimension(context, 40),
              height: ResponsiveConfig.dimension(context, 40),
              decoration: const BoxDecoration(
                color: Colors.cyanAccent,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: ResponsiveText(
                  sequence.sequenceOrder.toString(),
                  baseFontSize: 20,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ),
            ),
            ResponsiveSpacing(multiplier: 2, direction: Axis.horizontal),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  ResponsiveText(
                    '${sequence.shotCount} ${sequence.shotType} Shots',
                    baseFontSize: 16,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.blueGrey[800],
                    ),
                  ),
                  ResponsiveSpacing(multiplier: 0.5),
                  ResponsiveText(
                    'Target Zones: ${targetZones.join(", ")}',
                    baseFontSize: 14,
                    style: TextStyle(color: Colors.blueGrey[600]),
                  ),
                  if (sequence.description != null) ...[
                    ResponsiveSpacing(multiplier: 1),
                    ResponsiveText(
                      sequence.description!,
                      baseFontSize: 14,
                      style: TextStyle(
                        color: Colors.blueGrey[700],
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRequirements() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        ResponsiveText(
          'Requirements',
          baseFontSize: 18,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.blueGrey[800],
          ),
        ),
        ResponsiveSpacing(multiplier: 1),
        _buildRequirementItem('Hockey stick and pucks'),
        _buildRequirementItem('Shooting area with net'),
        _buildRequirementItem('Water bottle for hydration'),
        if (_program!.difficulty == 'Advanced') ...[
          _buildRequirementItem('Shooting targets for precision'),
          _buildRequirementItem('Timer for measuring quick release'),
        ],
      ],
    );
  }

  Widget _buildRequirementItem(String text) {
    return Padding(
      padding: ResponsiveConfig.paddingSymmetric(context, vertical: 4),
      child: Row(
        children: [
          Icon(
            Icons.check_circle,
            size: ResponsiveConfig.iconSize(context, 16),
            color: Colors.green,
          ),
          ResponsiveSpacing(multiplier: 1, direction: Axis.horizontal),
          Expanded(
            child: ResponsiveText(
              text,
              baseFontSize: 14,
              style: TextStyle(color: Colors.blueGrey[700]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFloatingActionButton() {
    return AdaptiveLayout(
      builder: (deviceType, isLandscape) {
        // Hide FAB on desktop as we have sidebar actions
        if (deviceType == DeviceType.desktop) {
          return SizedBox.shrink();
        }

        return FloatingActionButton.extended(
          onPressed: _startWorkout,
          backgroundColor: Colors.cyanAccent,
          foregroundColor: Colors.black87,
          icon: Icon(Icons.play_arrow),
          label: ResponsiveText(
            'Start Workout',
            baseFontSize: 16,
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
        );
      },
    );
  }

  void _startWorkout() async {
    final appState = Provider.of<AppState>(context, listen: false);
    
    if (appState.selectedPlayer.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: ResponsiveText(
            'Please select a player first',
            baseFontSize: 16,
          ),
        ),
      );
      return;
    }
    
    // Set the workout as started in app state
    appState.beginWorkout(_program!);
    
    // Navigate to workout execution screen
    Navigator.pushNamed(
      context,
      '/workout-execution',
      arguments: {
        'program': _program,
        'sequences': _sequences,
      },
    );
  }

  Color _getDifficultyColor(String difficulty) {
    switch (difficulty.toLowerCase()) {
      case 'beginner':
        return Colors.green;
      case 'intermediate':
        return Colors.orange;
      case 'advanced':
        return Colors.red;
      default:
        return Colors.blueGrey;
    }
  }
}