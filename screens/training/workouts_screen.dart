import 'package:flutter/material.dart';
import 'package:hockey_shot_tracker/responsive_system/index.dart';
import 'package:provider/provider.dart';
import 'package:hockey_shot_tracker/providers/app_state.dart';
import 'package:hockey_shot_tracker/models/shot.dart';
import 'package:hockey_shot_tracker/widgets/domain/training/workout_card.dart';

final Map<String, Map<String, dynamic>> trainingPrograms = {
  'Basic Shooting': {
    'duration': '30 min',
    'description': 'Perfect your fundamental shooting skills',
    'drills': [
      {'count': 10, 'type': 'Wrist', 'zones': ['1', '2']},
      {'count': 10, 'type': 'Snap', 'zones': ['3', '4']},
    ],
  },
  'Quick Release': {
    'duration': '45 min',
    'description': 'Focus on rapid shot execution from various positions',
    'drills': [
      {'count': 15, 'type': 'Wrist', 'zones': ['1', '3']},
      {'count': 15, 'type': 'Snap', 'zones': ['2', '4']},
    ],
  },
  // Add more programs as needed
};

class WorkoutsScreen extends StatefulWidget {
  const WorkoutsScreen({super.key});

  @override
  State<WorkoutsScreen> createState() => _WorkoutsScreenState();
}

class _WorkoutsScreenState extends State<WorkoutsScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  String _formatDrill(Map<String, dynamic> drill) {
    final count = drill['count'] as int;
    final type = drill['type'] as String;
    final zones = (drill['zones'] as List<dynamic>).join(', ');
    return '$count $type shots in zones $zones';
  }

  List<Map<String, String>> _getFilteredWorkouts(String query) {
    return trainingPrograms.entries
        .where((entry) =>
            entry.key.toLowerCase().contains(query.toLowerCase()) ||
            (entry.value['description'] as String)
                .toLowerCase()
                .contains(query.toLowerCase()))
        .map((entry) {
          final drills = (entry.value['drills'] as List<Map<String, dynamic>>)
              .map(_formatDrill)
              .join(', ');
          return {
            'name': entry.key,
            'duration': entry.value['duration'] as String,
            'description': entry.value['description'] as String,
            'drills': drills,
          };
        })
        .toList()
        .cast<Map<String, String>>();
  }

  Future<List<Widget>> _getRecommendedWorkouts() async {
    final appState = Provider.of<AppState>(context, listen: false);
    final widgets = <Widget>[];

    try {
      // Get recommendations from AppState - this returns List<Map<String, dynamic>>
      final recommendations = await appState.getRecommendations();

      // Process the list of recommendations
      if (recommendations.isNotEmpty) {
        // Separate programs and improvement areas
        final programs = recommendations.where((rec) => rec['type'] == 'program').toList();
        final improvements = recommendations.where((rec) => rec['type'] == 'improvement').toList();

        // Add recommended programs section
        if (programs.isNotEmpty) {
          widgets.add(
            Padding(
              padding: ResponsiveConfig.paddingSymmetric(context, vertical: 8),
              child: ResponsiveText(
                'Recommended Programs',
                baseFontSize: 20,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.blueGrey[800],
                ),
              ),
            ),
          );

          for (var program in programs) {
            final name = program['title'] as String? ?? program['name'] as String? ?? 'Unnamed Program';
            final description = program['description'] as String? ?? 'General training program';
            
            // Create a workout map that matches the expected format for WorkoutCard
            final workout = {
              'name': name,
              'description': description,
              'duration': program['duration'] as String? ?? '30 min',
              'drills': program['drills'] as String? ?? '',
            };

            widgets.add(
              WorkoutCard(
                workout: workout,
                onSelect: () {
                  // Navigate to workout details or add the workout
                  _addWorkout(name);
                },
              ),
            );
          }
        }

        // Add areas for improvement section
        if (improvements.isNotEmpty) {
          widgets.add(
            Padding(
              padding: ResponsiveConfig.paddingSymmetric(context, vertical: 12),
              child: ResponsiveText(
                'Areas for Improvement',
                baseFontSize: 20,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.blueGrey[800],
                ),
              ),
            ),
          );

          for (var area in improvements) {
            final title = area['title'] as String? ?? area['focus'] as String? ?? 'Unknown';
            final description = area['description'] as String? ?? area['reason'] as String? ?? '';

            widgets.add(
              ResponsiveCard(
                margin: ResponsiveConfig.paddingSymmetric(context, vertical: 6),
                child: ListTile(
                  title: ResponsiveText(title, baseFontSize: 16),
                  subtitle: description.isNotEmpty ? ResponsiveText(description, baseFontSize: 14) : null,
                  leading: Icon(Icons.fitness_center, color: Colors.blueGrey),
                ),
              ),
            );
          }
        }

        // If no specific types found, treat all as general recommendations
        if (programs.isEmpty && improvements.isEmpty && recommendations.isNotEmpty) {
          widgets.add(
            Padding(
              padding: ResponsiveConfig.paddingSymmetric(context, vertical: 8),
              child: ResponsiveText(
                'Recommended for You',
                baseFontSize: 20,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.blueGrey[800],
                ),
              ),
            ),
          );

          for (var recommendation in recommendations) {
            final title = recommendation['title'] as String? ?? 
                        recommendation['name'] as String? ?? 
                        'Training Recommendation';
            final description = recommendation['description'] as String? ?? '';

            widgets.add(
              ResponsiveCard(
                margin: ResponsiveConfig.paddingSymmetric(context, vertical: 6),
                child: ListTile(
                  title: ResponsiveText(title, baseFontSize: 16),
                  subtitle: description.isNotEmpty ? ResponsiveText(description, baseFontSize: 14) : null,
                  leading: Icon(Icons.star, color: Colors.orange),
                  onTap: () {
                    // Add this recommendation as a workout
                    _addWorkout(title);
                  },
                ),
              ),
            );
          }
        }
      } else {
        // No recommendations available
        widgets.add(
          ResponsiveCard(
            margin: ResponsiveConfig.paddingSymmetric(context, vertical: 16),
            child: Padding(
              padding: ResponsiveConfig.paddingAll(context, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  ResponsiveText(
                    'No recommendations yet',
                    baseFontSize: 18,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.blueGrey[800],
                    ),
                  ),
                  ResponsiveSpacing(multiplier: 1),
                  ResponsiveText(
                    'Complete some assessments to get personalized training recommendations.',
                    baseFontSize: 14,
                    style: TextStyle(color: Colors.blueGrey[600]),
                  ),
                ],
              ),
            ),
          ),
        );
      }
    } catch (e) {
      print('Error loading recommendations: $e');
      // Add a fallback widget when recommendations fail to load
      widgets.add(
        ResponsiveCard(
          margin: ResponsiveConfig.paddingSymmetric(context, vertical: 16),
          child: Padding(
            padding: ResponsiveConfig.paddingAll(context, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                ResponsiveText(
                  'Recommendations unavailable',
                  baseFontSize: 18,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.blueGrey[800],
                  ),
                ),
                ResponsiveSpacing(multiplier: 1),
                ResponsiveText(
                  'Unable to load personalized recommendations at this time. Please try again later.',
                  baseFontSize: 14,
                  style: TextStyle(color: Colors.blueGrey[600]),
                ),
              ],
            ),
          ),
        ),
      );
    }

    // Return the list of widgets
    return widgets;
  }

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    final filteredWorkouts = _getFilteredWorkouts(_searchController.text);

    return AdaptiveScaffold(
      title: 'Workouts',
      backgroundColor: Colors.grey[100],
      body: AdaptiveLayout(
        builder: (deviceType, isLandscape) {
          return ConstrainedBox(
            constraints: ResponsiveConfig.constraints(
              context,
              maxWidth: deviceType == DeviceType.desktop ? 1400 : null,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildSearchHeader(deviceType, isLandscape),
                Expanded(
                  child: SingleChildScrollView(
                    padding: ResponsiveConfig.paddingSymmetric(context, horizontal: 16, vertical: 8),
                    child: _buildWorkoutContent(deviceType, isLandscape, filteredWorkouts),
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
      padding: ResponsiveConfig.paddingSymmetric(context, horizontal: 16, vertical: 8),
      color: Colors.white,
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          labelText: 'Search Workouts',
          border: OutlineInputBorder(
            borderRadius: ResponsiveConfig.borderRadius(context, 12),
            borderSide: BorderSide(color: Colors.blueGrey[400]!),
          ),
          prefixIcon: Icon(Icons.search, color: Colors.blueGrey[600]),
          filled: true,
          fillColor: Colors.white,
          hintStyle: TextStyle(color: Colors.blueGrey[400]),
          contentPadding: ResponsiveConfig.paddingSymmetric(
            context,
            horizontal: 16,
            vertical: 12,
          ),
        ),
        style: TextStyle(
          color: Colors.blueGrey[900],
          fontSize: ResponsiveConfig.fontSize(context, 16),
        ),
        onChanged: (value) => setState(() {}),
      ),
    );
  }

  Widget _buildWorkoutContent(DeviceType deviceType, bool isLandscape, List<Map<String, String>> filteredWorkouts) {
    return AdaptiveLayout(
      builder: (deviceType, isLandscape) {
        switch (deviceType) {
          case DeviceType.mobile:
            return _buildMobileLayout(filteredWorkouts);
          case DeviceType.tablet:
            return _buildTabletLayout(filteredWorkouts, isLandscape);
          case DeviceType.desktop:
            return _buildDesktopLayout(filteredWorkouts);
        }
      },
    );
  }

  Widget _buildMobileLayout(List<Map<String, String>> filteredWorkouts) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        ResponsiveText(
          'Recommended',
          baseFontSize: 22,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.blueGrey[900],
          ),
        ),
        ResponsiveSpacing(multiplier: 1.5),
        // Use FutureBuilder to handle the async _getRecommendedWorkouts
        FutureBuilder<List<Widget>>(
          future: _getRecommendedWorkouts(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            } else if (snapshot.hasError) {
              return Padding(
                padding: ResponsiveConfig.paddingAll(context, 8),
                child: ResponsiveText(
                  'Error loading recommendations: ${snapshot.error}',
                  baseFontSize: 14,
                  style: TextStyle(
                    color: Colors.red[600],
                    fontStyle: FontStyle.italic,
                  ),
                ),
              );
            } else if (snapshot.hasData && snapshot.data!.isNotEmpty) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: snapshot.data!,
              );
            } else {
              return Padding(
                padding: ResponsiveConfig.paddingAll(context, 8),
                child: ResponsiveText(
                  'No recommendations yet.',
                  baseFontSize: 14,
                  style: TextStyle(
                    color: Colors.blueGrey[600],
                    fontStyle: FontStyle.italic,
                  ),
                ),
              );
            }
          },
        ),
        ResponsiveSpacing(multiplier: 2.5),
        ResponsiveText(
          'All Workouts',
          baseFontSize: 22,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.blueGrey[900],
          ),
        ),
        ResponsiveSpacing(multiplier: 1.5),
        // Replace the ListView.builder with a Column of workout cards
        Column(
          mainAxisSize: MainAxisSize.min,
          children: filteredWorkouts.map((workout) {
            return WorkoutCard(
              workout: workout,
              onSelect: () {
                _addWorkout(workout['name']!);
              },
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildTabletLayout(List<Map<String, String>> filteredWorkouts, bool isLandscape) {
    if (!isLandscape) {
      return _buildMobileLayout(filteredWorkouts);
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 7,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              ResponsiveText(
                'Recommended',
                baseFontSize: 22,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.blueGrey[900],
                ),
              ),
              ResponsiveSpacing(multiplier: 1.5),
              FutureBuilder<List<Widget>>(
                future: _getRecommendedWorkouts(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  } else if (snapshot.hasError) {
                    return Padding(
                      padding: ResponsiveConfig.paddingAll(context, 8),
                      child: ResponsiveText(
                        'Error loading recommendations: ${snapshot.error}',
                        baseFontSize: 14,
                        style: TextStyle(
                          color: Colors.red[600],
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    );
                  } else if (snapshot.hasData && snapshot.data!.isNotEmpty) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: snapshot.data!,
                    );
                  } else {
                    return Padding(
                      padding: ResponsiveConfig.paddingAll(context, 8),
                      child: ResponsiveText(
                        'No recommendations yet.',
                        baseFontSize: 14,
                        style: TextStyle(
                          color: Colors.blueGrey[600],
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    );
                  }
                },
              ),
              ResponsiveSpacing(multiplier: 2.5),
              ResponsiveText(
                'All Workouts',
                baseFontSize: 22,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.blueGrey[900],
                ),
              ),
              ResponsiveSpacing(multiplier: 1.5),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: filteredWorkouts.map((workout) {
                  return WorkoutCard(
                    workout: workout,
                    onSelect: () {
                      _addWorkout(workout['name']!);
                    },
                  );
                }).toList(),
              ),
            ],
          ),
        ),
        ResponsiveSpacing(multiplier: 2, direction: Axis.horizontal),
        Container(
          width: 280,
          child: _buildTabletSidebar(),
        ),
      ],
    );
  }

  Widget _buildDesktopLayout(List<Map<String, String>> filteredWorkouts) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 7,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              ResponsiveText(
                'Recommended',
                baseFontSize: 22,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.blueGrey[900],
                ),
              ),
              ResponsiveSpacing(multiplier: 1.5),
              FutureBuilder<List<Widget>>(
                future: _getRecommendedWorkouts(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  } else if (snapshot.hasError) {
                    return Padding(
                      padding: ResponsiveConfig.paddingAll(context, 8),
                      child: ResponsiveText(
                        'Error loading recommendations: ${snapshot.error}',
                        baseFontSize: 14,
                        style: TextStyle(
                          color: Colors.red[600],
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    );
                  } else if (snapshot.hasData && snapshot.data!.isNotEmpty) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: snapshot.data!,
                    );
                  } else {
                    return Padding(
                      padding: ResponsiveConfig.paddingAll(context, 8),
                      child: ResponsiveText(
                        'No recommendations yet.',
                        baseFontSize: 14,
                        style: TextStyle(
                          color: Colors.blueGrey[600],
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    );
                  }
                },
              ),
              ResponsiveSpacing(multiplier: 2.5),
              ResponsiveText(
                'All Workouts',
                baseFontSize: 22,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.blueGrey[900],
                ),
              ),
              ResponsiveSpacing(multiplier: 1.5),
              // Desktop: Grid layout for workout cards
              Wrap(
                spacing: ResponsiveConfig.spacing(context, 16),
                runSpacing: ResponsiveConfig.spacing(context, 16),
                children: filteredWorkouts.map((workout) {
                  return SizedBox(
                    width: (MediaQuery.of(context).size.width * 0.7 - 32) / 2,
                    child: WorkoutCard(
                      workout: workout,
                      onSelect: () {
                        _addWorkout(workout['name']!);
                      },
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
        ),
        ResponsiveSpacing(multiplier: 2, direction: Axis.horizontal),
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

  Widget _buildTabletSidebar() {
    return ResponsiveCard(
      padding: ResponsiveConfig.paddingAll(context, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
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
          ResponsiveButton(
            text: 'Training Programs',
            onPressed: () => Navigator.pushNamed(context, '/training-programs'),
            baseHeight: 48,
            width: double.infinity,
            backgroundColor: Colors.cyanAccent,
            foregroundColor: Colors.black87,
            icon: Icons.fitness_center,
          ),
          ResponsiveSpacing(multiplier: 2),
          ResponsiveButton(
            text: 'Player Assessment',
            onPressed: () => Navigator.pushNamed(context, '/shot-assessment'),
            baseHeight: 48,
            width: double.infinity,
            backgroundColor: Colors.blueGrey[700],
            foregroundColor: Colors.white,
            icon: Icons.assessment,
          ),
        ],
      ),
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
          _buildStatsCard('Available Workouts', trainingPrograms.length.toString()),
          ResponsiveSpacing(multiplier: 2),
          _buildStatsCard('Filtered Results', _getFilteredWorkouts(_searchController.text).length.toString()),
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
            text: 'Training Programs',
            onPressed: () => Navigator.pushNamed(context, '/training-programs'),
            baseHeight: 48,
            width: double.infinity,
            backgroundColor: Colors.cyanAccent,
            foregroundColor: Colors.black87,
            icon: Icons.fitness_center,
          ),
          ResponsiveSpacing(multiplier: 2),
          ResponsiveButton(
            text: 'Player Assessment',
            onPressed: () => Navigator.pushNamed(context, '/shot-assessment'),
            baseHeight: 48,
            width: double.infinity,
            backgroundColor: Colors.blueGrey[700],
            foregroundColor: Colors.white,
            icon: Icons.assessment,
          ),
          ResponsiveSpacing(multiplier: 2),
          ResponsiveButton(
            text: 'View Analytics',
            onPressed: () => Navigator.pushNamed(context, '/shot-analysis'),
            baseHeight: 48,
            width: double.infinity,
            backgroundColor: Colors.orange[700],
            foregroundColor: Colors.white,
            icon: Icons.analytics,
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

  void _addWorkout(String workoutName) {
    final appState = Provider.of<AppState>(context, listen: false);
    appState.addWorkout(workoutName);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: ResponsiveText(
          'Added $workoutName',
          baseFontSize: 16,
          style: const TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.blueGrey[800],
      ),
    );
  }
}