import 'package:flutter/material.dart';
import 'package:hockey_shot_tracker/responsive_system/index.dart';
import 'package:hockey_shot_tracker/models/training_program.dart';
import 'package:hockey_shot_tracker/models/program_sequence.dart';
import 'package:provider/provider.dart';
import 'package:hockey_shot_tracker/providers/app_state.dart';
import 'package:hockey_shot_tracker/services/infrastructure/api_service_factory.dart';
import 'package:hockey_shot_tracker/screens/training/workout_details_screen.dart';
import 'package:hockey_shot_tracker/widgets/core/state/index.dart';
import 'package:hockey_shot_tracker/widgets/core/list/index.dart';

class TrainingProgramsScreen extends StatefulWidget {
  const TrainingProgramsScreen({super.key});

  @override
  State<TrainingProgramsScreen> createState() => _TrainingProgramsScreenState();
}

class _TrainingProgramsScreenState extends State<TrainingProgramsScreen> {
  bool _isLoading = true;
  List<TrainingProgram> _programs = [];
  List<TrainingProgram> _filteredPrograms = [];
  String? _errorMessage;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadPrograms();
  }

  Future<void> _loadPrograms() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final appState = Provider.of<AppState>(context, listen: false);
      final programs = await ApiServiceFactory.training.fetchTrainingPrograms();

      if (!mounted) return;

      setState(() {
        _programs = programs;
        _filteredPrograms = programs;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _errorMessage = 'Failed to load training programs: $e';
        _isLoading = false;
      });
    }
  }

  void _filterPrograms(String query) {
    setState(() {
      _searchQuery = query;
      if (query.isEmpty) {
        _filteredPrograms = _programs;
      } else {
        _filteredPrograms = _programs.where((program) {
          return program.name.toLowerCase().contains(query.toLowerCase()) ||
              (program.description ?? '').toLowerCase().contains(query.toLowerCase());
        }).toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return AdaptiveScaffold(
      title: 'Training Programs',
      backgroundColor: Colors.grey[100],
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
                _buildSearchHeader(deviceType, isLandscape),
                Expanded(
                  child: LoadingOverlay(
                    isLoading: _isLoading,
                    message: 'Loading programs...',
                    color: Colors.cyanAccent,
                    child: _errorMessage != null
                        ? ErrorDisplay(
                            message: 'Error Loading Programs',
                            details: _errorMessage,
                            onRetry: _loadPrograms,
                            showCard: true,
                          )
                        : _buildProgramsList(deviceType, isLandscape),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildSearchHeader(DeviceType deviceType, bool isLandscape) {
    return Container(
      padding: ResponsiveConfig.paddingAll(context, 16),
      color: Colors.white,
      child: TextField(
        onChanged: _filterPrograms,
        decoration: InputDecoration(
          labelText: 'Search Programs',
          prefixIcon: const Icon(Icons.search),
          border: OutlineInputBorder(
            borderRadius: ResponsiveConfig.borderRadius(context, 12),
          ),
          filled: true,
          fillColor: Colors.white,
          contentPadding: ResponsiveConfig.paddingSymmetric(
            context,
            horizontal: 16,
            vertical: 12,
          ),
        ),
        style: TextStyle(
          fontSize: ResponsiveConfig.fontSize(context, 16),
          color: Colors.blueGrey[900],
        ),
      ),
    );
  }

  Widget _buildProgramsList(DeviceType deviceType, bool isLandscape) {
    if (_filteredPrograms.isEmpty) {
      return _searchQuery.isEmpty
          ? EmptyStateDisplay.noDataYet(
              title: 'No Training Programs',
              description: 'There are no training programs available right now.',
              actionLabel: 'Refresh',
              onAction: _loadPrograms,
              showCard: true,
            )
          : EmptyStateDisplay.noSearchResults(
              title: 'No Results Found',
              description: 'No programs match "$_searchQuery"',
              actionLabel: 'Clear Search',
              onAction: () {
                setState(() {
                  _searchQuery = '';
                  _filteredPrograms = _programs;
                });
              },
              showCard: true,
            );
    }

    return AdaptiveLayout(
      builder: (deviceType, isLandscape) {
        switch (deviceType) {
          case DeviceType.mobile:
            return _buildMobileList();
          case DeviceType.tablet:
            return _buildTabletList(isLandscape);
          case DeviceType.desktop:
            return _buildDesktopList();
        }
      },
    );
  }

  Widget _buildMobileList() {
    return ListView.builder(
      padding: ResponsiveConfig.paddingAll(context, 16),
      itemCount: _filteredPrograms.length,
      itemBuilder: (context, index) {
        final program = _filteredPrograms[index];
        return _buildMobileProgramCard(program);
      },
    );
  }

  Widget _buildTabletList(bool isLandscape) {
    final crossAxisCount = isLandscape ? 2 : 1;
    
    if (crossAxisCount == 1) {
      return _buildMobileList();
    }

    return GridView.builder(
      padding: ResponsiveConfig.paddingAll(context, 16),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        childAspectRatio: 1.5,
        crossAxisSpacing: ResponsiveConfig.spacing(context, 16),
        mainAxisSpacing: ResponsiveConfig.spacing(context, 16),
      ),
      itemCount: _filteredPrograms.length,
      itemBuilder: (context, index) {
        final program = _filteredPrograms[index];
        return _buildTabletProgramCard(program);
      },
    );
  }

  Widget _buildDesktopList() {
    return Row(
      children: [
        Expanded(
          flex: 7,
          child: GridView.builder(
            padding: ResponsiveConfig.paddingAll(context, 16),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 1.4,
              crossAxisSpacing: ResponsiveConfig.spacing(context, 16),
              mainAxisSpacing: ResponsiveConfig.spacing(context, 16),
            ),
            itemCount: _filteredPrograms.length,
            itemBuilder: (context, index) {
              final program = _filteredPrograms[index];
              return _buildTabletProgramCard(program);
            },
          ),
        ),
        Container(
          width: 300,
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
            'Quick Stats',
            baseFontSize: 18,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.blueGrey[800],
            ),
          ),
          ResponsiveSpacing(multiplier: 2),
          _buildStatsCard('Total Programs', _programs.length.toString()),
          ResponsiveSpacing(multiplier: 2),
          _buildStatsCard('Filtered Results', _filteredPrograms.length.toString()),
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
            text: 'Refresh List',
            onPressed: _loadPrograms,
            baseHeight: 48,
            width: double.infinity,
            backgroundColor: Colors.cyanAccent,
            foregroundColor: Colors.black87,
            icon: Icons.refresh,
          ),
          ResponsiveSpacing(multiplier: 2),
          ResponsiveButton(
            text: 'View All Workouts',
            onPressed: () => Navigator.pushNamed(context, '/workouts'),
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

  Widget _buildStatsCard(String label, String value) {
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

  Widget _buildMobileProgramCard(TrainingProgram program) {
    final difficultyColor = _getDifficultyColor(program.difficulty);

    return ResponsiveCard(
      margin: ResponsiveConfig.paddingSymmetric(context, vertical: 8),
      elevation: 2,
      baseBorderRadius: 12,
      onTap: () => _showProgramDetails(program),
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
                  child: ResponsiveText(
                    program.name,
                    baseFontSize: 18,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.blueGrey[900],
                    ),
                  ),
                ),
                StatusBadge(
                  text: '${program.totalShots} shots',
                  color: Colors.cyanAccent.shade700,
                  size: StatusBadgeSize.small,
                ),
              ],
            ),
            ResponsiveSpacing(multiplier: 1),
            ResponsiveText(
              program.description ?? 'No description',
              baseFontSize: 14,
              style: TextStyle(color: Colors.blueGrey[700]),
            ),
            ResponsiveSpacing(multiplier: 2),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(Icons.timer, size: ResponsiveConfig.iconSize(context, 16), color: Colors.blueGrey[400]),
                    ResponsiveSpacing(multiplier: 0.5, direction: Axis.horizontal),
                    ResponsiveText(
                      '${program.estimatedDuration} min',
                      baseFontSize: 12,
                      style: TextStyle(color: Colors.blueGrey[600]),
                    ),
                  ],
                ),
                StatusBadge(
                  text: program.difficulty,
                  color: difficultyColor,
                  size: StatusBadgeSize.small,
                  icon: Icons.fitness_center,
                ),
              ],
            ),
            ResponsiveSpacing(multiplier: 2),
            Row(
              children: [
                Expanded(
                  child: ResponsiveButton(
                    text: 'Details',
                    onPressed: () => _viewFullDetails(program),
                    baseHeight: 40,
                    backgroundColor: Colors.blueGrey[100],
                    foregroundColor: Colors.blueGrey[700],
                  ),
                ),
                ResponsiveSpacing(multiplier: 1, direction: Axis.horizontal),
                Expanded(
                  child: ResponsiveButton(
                    text: 'Start',
                    onPressed: () => _startWorkout(program),
                    baseHeight: 40,
                    backgroundColor: Colors.cyanAccent,
                    foregroundColor: Colors.black87,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTabletProgramCard(TrainingProgram program) {
    final difficultyColor = _getDifficultyColor(program.difficulty);

    return ResponsiveCard(
      elevation: 2,
      baseBorderRadius: 12,
      onTap: () => _showProgramDetails(program),
      child: Padding(
        padding: ResponsiveConfig.paddingAll(context, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: ResponsiveText(
                          program.name,
                          baseFontSize: 18,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.blueGrey[900],
                          ),
                        ),
                      ),
                      StatusBadge(
                        text: '${program.totalShots}',
                        color: Colors.cyanAccent.shade700,
                        size: StatusBadgeSize.small,
                      ),
                    ],
                  ),
                  ResponsiveSpacing(multiplier: 1),
                  Expanded(
                    child: ResponsiveText(
                      program.description ?? 'No description',
                      baseFontSize: 14,
                      style: TextStyle(color: Colors.blueGrey[700]),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  ResponsiveSpacing(multiplier: 1),
                  Row(
                    children: [
                      Icon(Icons.timer, size: ResponsiveConfig.iconSize(context, 16), color: Colors.blueGrey[400]),
                      ResponsiveSpacing(multiplier: 0.5, direction: Axis.horizontal),
                      ResponsiveText(
                        '${program.estimatedDuration} min',
                        baseFontSize: 12,
                        style: TextStyle(color: Colors.blueGrey[600]),
                      ),
                      ResponsiveSpacing(multiplier: 2, direction: Axis.horizontal),
                      StatusBadge(
                        text: program.difficulty,
                        color: difficultyColor,
                        size: StatusBadgeSize.small,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            ResponsiveSpacing(multiplier: 2),
            Row(
              children: [
                Expanded(
                  child: ResponsiveButton(
                    text: 'Details',
                    onPressed: () => _viewFullDetails(program),
                    baseHeight: 40,
                    backgroundColor: Colors.blueGrey[100],
                    foregroundColor: Colors.blueGrey[700],
                  ),
                ),
                ResponsiveSpacing(multiplier: 1, direction: Axis.horizontal),
                Expanded(
                  child: ResponsiveButton(
                    text: 'Start',
                    onPressed: () => _startWorkout(program),
                    baseHeight: 40,
                    backgroundColor: Colors.cyanAccent,
                    foregroundColor: Colors.black87,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
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

  void _viewFullDetails(TrainingProgram program) async {
    final appState = Provider.of<AppState>(context, listen: false);
    final navigator = Navigator.of(context);
    final scaffoldMessenger = ScaffoldMessenger.of(context);

    navigator.push(
      PageRouteBuilder(
        opaque: false,
        pageBuilder: (_, __, ___) => const Center(
          child: CircularProgressIndicator(),
        ),
      ),
    );

    try {
      final programDetails = await ApiServiceFactory.training.fetchTrainingProgramDetails(program.id!);

      final sequences = (programDetails['sequences'] as List<dynamic>)
          .map((seq) => ProgramSequence.fromJson(seq as Map<String, dynamic>))
          .toList();

      navigator.pushReplacement(
        MaterialPageRoute(
          builder: (context) => WorkoutDetailsScreen(
            program: program,
            sequences: sequences,
          ),
        ),
      );
    } catch (e) {
      navigator.pop();

      scaffoldMessenger.showSnackBar(
        SnackBar(content: Text('Failed to load program details: $e')),
      );
    }
  }

  void _showProgramDetails(TrainingProgram program) async {
    final appState = Provider.of<AppState>(context, listen: false);
    final navigator = Navigator.of(context);
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    final contextReference = context;

    navigator.push(
      PageRouteBuilder(
        opaque: false,
        pageBuilder: (_, __, ___) => const Center(
          child: CircularProgressIndicator(),
        ),
      ),
    );

    try {
      final programDetails = await ApiServiceFactory.training.fetchTrainingProgramDetails(program.id!);

      navigator.pop();

      final sequences = (programDetails['sequences'] as List<dynamic>)
          .map((seq) => ProgramSequence.fromJson(seq as Map<String, dynamic>))
          .toList();

      if (!mounted) return;

      showModalBottomSheet(
        context: contextReference,
        isScrollControlled: true,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(ResponsiveConfig.borderRadiusValue(contextReference, 20))),
        ),
        builder: (context) {
          return DraggableScrollableSheet(
            initialChildSize: 0.6,
            maxChildSize: 0.9,
            minChildSize: 0.5,
            expand: false,
            builder: (context, scrollController) {
              return _buildProgramDetailsSheet(
                program: program,
                sequences: sequences,
                scrollController: scrollController,
                parentContext: contextReference,
              );
            },
          );
        },
      );
    } catch (e) {
      navigator.pop();

      scaffoldMessenger.showSnackBar(
        SnackBar(content: Text('Failed to load program details: $e')),
      );
    }
  }

  Widget _buildProgramDetailsSheet({
    required TrainingProgram program,
    required List<ProgramSequence> sequences,
    required ScrollController scrollController,
    required BuildContext parentContext,
  }) {
    return Container(
      padding: ResponsiveConfig.paddingAll(parentContext, 16),
      child: ListView(
        controller: scrollController,
        children: [
          Center(
            child: Container(
              width: ResponsiveConfig.dimension(parentContext, 40),
              height: ResponsiveConfig.dimension(parentContext, 5),
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: ResponsiveConfig.borderRadius(parentContext, 10),
              ),
              margin: ResponsiveConfig.paddingSymmetric(parentContext, vertical: 8),
            ),
          ),

          ResponsiveText(
            program.name,
            baseFontSize: 24,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.blueGrey[900],
            ),
          ),
          ResponsiveSpacing(multiplier: 1),
          ResponsiveText(
            program.description ?? 'No description',
            baseFontSize: 16,
            style: TextStyle(color: Colors.blueGrey[700]),
          ),
          ResponsiveSpacing(multiplier: 2),

          Row(
            children: [
              _buildProgramInfoItem(Icons.timer, '${program.estimatedDuration} min'),
              ResponsiveSpacing(multiplier: 3, direction: Axis.horizontal),
              _buildProgramInfoItem(Icons.fitness_center, program.difficulty),
              ResponsiveSpacing(multiplier: 3, direction: Axis.horizontal),
              _buildProgramInfoItem(Icons.sports_hockey, '${program.totalShots} shots'),
            ],
          ),
          ResponsiveSpacing(multiplier: 3),

          ResponsiveText(
            'Sequences',
            baseFontSize: 20,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.blueGrey[900],
            ),
          ),
          ResponsiveSpacing(multiplier: 2),
          ...sequences.map((sequence) => _buildSequenceItem(sequence)),
          ResponsiveSpacing(multiplier: 4),

          Row(
            children: [
              Expanded(
                child: ResponsiveButton(
                  text: 'Full Details',
                  onPressed: () {
                    Navigator.pop(parentContext);
                    _viewFullDetails(program);
                  },
                  baseHeight: 48,
                  backgroundColor: Colors.blueGrey[100],
                  foregroundColor: Colors.blueGrey[700],
                ),
              ),
              ResponsiveSpacing(multiplier: 2, direction: Axis.horizontal),
              Expanded(
                child: ResponsiveButton(
                  text: 'Start Workout',
                  onPressed: () {
                    Navigator.pop(parentContext);
                    _startWorkout(program, sequences: sequences);
                  },
                  baseHeight: 48,
                  backgroundColor: Colors.cyanAccent,
                  foregroundColor: Colors.black87,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildProgramInfoItem(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: ResponsiveConfig.iconSize(context, 18), color: Colors.blueGrey[600]),
        ResponsiveSpacing(multiplier: 1, direction: Axis.horizontal),
        ResponsiveText(
          text,
          baseFontSize: 14,
          style: TextStyle(color: Colors.blueGrey[700]),
        ),
      ],
    );
  }

  Widget _buildSequenceItem(ProgramSequence sequence) {
    final targetZones = sequence.getTargetZonesList();
    
    return ResponsiveCard(
      margin: ResponsiveConfig.paddingSymmetric(context, vertical: 6),
      padding: ResponsiveConfig.paddingAll(context, 12),
      baseBorderRadius:8,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ResponsiveText(
                      'Sequence ${sequence.sequenceOrder}',
                      baseFontSize: 16,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.blueGrey[800],
                      ),
                    ),
                    ResponsiveSpacing(multiplier: 0.5),
                    ResponsiveText(
                      'Shot Type: ${sequence.shotType}',
                      baseFontSize: 14,
                      style: TextStyle(color: Colors.blueGrey[600]),
                    ),
                    if (sequence.description != null) ...[
                      ResponsiveSpacing(multiplier: 0.5),
                      ResponsiveText(
                        sequence.description!,
                        baseFontSize: 14,
                        style: TextStyle(color: Colors.blueGrey[600]),
                      ),
                    ],
                  ],
                ),
              ),
              StatusBadge(
                text: '${sequence.shotCount} shots',
                color: Colors.blue,
                size: StatusBadgeSize.small,
              ),
            ],
          ),
          ResponsiveSpacing(multiplier: 1),
          Row(
            children: [
              ResponsiveText(
                'Target Zones: ',
                baseFontSize: 12,
                style: TextStyle(color: Colors.blueGrey[700]),
              ),
              Wrap(
                spacing: ResponsiveConfig.spacing(context, 4),
                children: targetZones.map((zone) =>
                    StatusBadge(
                      text: zone,
                      color: Colors.cyanAccent.shade700,
                      size: StatusBadgeSize.small,
                    ),
                ).toList(),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _startWorkout(TrainingProgram program, {List<ProgramSequence>? sequences}) async {
    final appState = Provider.of<AppState>(context, listen: false);
    final navigator = Navigator.of(context);
    final scaffoldMessenger = ScaffoldMessenger.of(context);

    if (appState.selectedPlayer.isEmpty) {
      scaffoldMessenger.showSnackBar(
        const SnackBar(content: Text('Please select a player first')),
      );
      return;
    }

    try {
      if (sequences == null) {
        navigator.push(
          PageRouteBuilder(
            opaque: false,
            pageBuilder: (_, __, ___) => const Center(
              child: CircularProgressIndicator(),
            ),
          ),
        );

        final programDetails = await ApiServiceFactory.training.fetchTrainingProgramDetails(program.id!);

        sequences = (programDetails['sequences'] as List<dynamic>)
            .map((seq) => ProgramSequence.fromJson(seq as Map<String, dynamic>))
            .toList();

        navigator.pop();
      }

      appState.beginWorkout(program);

      navigator.pushNamed(
        '/workout-execution',
        arguments: {
          'program': program,
          'sequences': sequences,
        },
      );
    } catch (e) {
      if (sequences == null) {
        navigator.pop();
      }

      scaffoldMessenger.showSnackBar(
        SnackBar(content: Text('Failed to start workout: $e')),
      );
    }
  }
}