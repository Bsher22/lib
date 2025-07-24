// lib/widgets/domain/assessment/team_skating/team_skating_setup_view.dart
// PHASE 4: Updated for full responsiveness following established patterns
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:hockey_shot_tracker/providers/app_state.dart';
import 'package:hockey_shot_tracker/models/player.dart';
import 'package:hockey_shot_tracker/models/team.dart';
import 'package:hockey_shot_tracker/services/assessment_config_service.dart';
import 'package:hockey_shot_tracker/services/infrastructure/api_service_factory.dart';
import 'package:hockey_shot_tracker/services/dialog_service.dart';
import 'package:hockey_shot_tracker/widgets/domain/assessment/common/assessment_type_selector.dart';
import 'package:hockey_shot_tracker/widgets/core/state/loading_widget.dart';
import 'package:hockey_shot_tracker/widgets/core/state/error_display.dart';
import 'package:hockey_shot_tracker/widgets/core/state/empty_state_display.dart';
import 'package:hockey_shot_tracker/responsive_system/index.dart';

class TeamSkatingSetupView extends StatefulWidget {
  final Function(String, String, List<Player>) onStart;

  const TeamSkatingSetupView({
    Key? key,
    required this.onStart,
  }) : super(key: key);

  @override
  _TeamSkatingSetupViewState createState() => _TeamSkatingSetupViewState();
}

class _TeamSkatingSetupViewState extends State<TeamSkatingSetupView> {
  String _selectedAssessmentType = 'comprehensive_skating';
  String _selectedCategory = 'all';
  Team? _selectedTeam;
  String _filterPosition = 'all';
  String _selectedAgeGroup = 'youth_15_18';
  List<Player> _selectedPlayers = [];

  // Data management
  List<Team> _teams = [];
  List<Player> _allPlayers = [];
  List<Player> _availablePlayers = [];
  Map<String, Map<String, dynamic>> _assessmentTypes = {};

  // Loading states
  bool _isLoadingTeams = true;
  bool _isLoadingPlayers = true;
  bool _isLoadingAssessments = true;
  bool _isCreatingSession = false;
  String? _loadError;

  late AssessmentConfigService _configService;

  @override
  void initState() {
    super.initState();
    _configService = AssessmentConfigService.instance;
    _loadDataFromDatabase();
  }

  Future<void> _loadDataFromDatabase() async {
    try {
      setState(() {
        _isLoadingTeams = true;
        _isLoadingPlayers = true;
        _isLoadingAssessments = true;
        _loadError = null;
      });

      final appState = Provider.of<AppState>(context, listen: false);

      await Future.wait([
        _loadTeamsWithFallback(appState),
        _loadPlayersWithFallback(appState),
        _loadSkatingAssessments(),
      ]);

      print('✓ Loaded ${_teams.length} teams, ${_allPlayers.length} players, and ${_assessmentTypes.length} assessment types');
      
      if (_teams.isNotEmpty && _selectedTeam == null) {
        setState(() {
          _selectedTeam = _teams.first;
        });
        _updateAvailablePlayers();
      }

      if (_assessmentTypes.isNotEmpty && !_assessmentTypes.containsKey(_selectedAssessmentType)) {
        final filteredTypes = getFilteredAssessmentTypes();
        if (filteredTypes.isNotEmpty) {
          setState(() {
            _selectedAssessmentType = filteredTypes.keys.first;
          });
        }
      }

    } catch (e) {
      print('Error loading data: $e');
      setState(() {
        _loadError = e.toString();
        _isLoadingTeams = false;
        _isLoadingPlayers = false;
        _isLoadingAssessments = false;
      });
    }
  }

  Future<void> _loadTeamsWithFallback(AppState appState) async {
    try {
      List<Team> teams = [];
      
      try {
        teams = await ApiServiceFactory.team.fetchTeams();
        print('✓ Loaded teams using fetchTeams()');
      } catch (e) {
        print('Warning: fetchTeams() failed: $e');
        
        if (appState.teams.isNotEmpty) {
          teams = appState.teams;
          print('✓ Using teams from appState cache');
        } else {
          print('Warning: No teams available, using empty list');
          teams = [];
        }
      }
      
      setState(() {
        _teams = teams;
        _isLoadingTeams = false;
      });
      
    } catch (e) {
      print('Error in team loading fallback: $e');
      setState(() {
        _teams = [];
        _isLoadingTeams = false;
      });
    }
  }

  Future<void> _loadPlayersWithFallback(AppState appState) async {
    try {
      List<Player> players = [];
      
      try {
        players = await ApiServiceFactory.player.fetchPlayers();
        print('✓ Loaded players using fetchPlayers()');
      } catch (e) {
        print('Warning: fetchPlayers() failed: $e');
        
        if (appState.players.isNotEmpty) {
          players = appState.players;
          print('✓ Using players from appState cache');
        } else {
          print('Warning: No players available, using empty list');
          players = [];
        }
      }
      
      setState(() {
        _allPlayers = players;
        _isLoadingPlayers = false;
      });
      
      _updateAvailablePlayers();
      
    } catch (e) {
      print('Error in player loading fallback: $e');
      setState(() {
        _allPlayers = [];
        _isLoadingPlayers = false;
      });
    }
  }

  Future<void> _loadSkatingAssessments() async {
    try {
      print('TeamSkatingSetupView: Loading skating assessment types...');
      
      _assessmentTypes = await AssessmentConfigService.instance.getSkatingAssessmentTypesForUIWithBenchmarks(
        ageGroup: _selectedAgeGroup,
        position: 'forward',
      );
      
      final filteredTypes = <String, Map<String, dynamic>>{};
      for (var entry in _assessmentTypes.entries) {
        final category = entry.value['category'] as String? ?? '';
        if (category != 'mini') {
          filteredTypes[entry.key] = entry.value;
        }
      }
      _assessmentTypes = filteredTypes;
      
      if (_assessmentTypes.containsKey('comprehensive_skating')) {
        _selectedAssessmentType = 'comprehensive_skating';
      } else if (_assessmentTypes.isNotEmpty) {
        _selectedAssessmentType = _assessmentTypes.keys.first;
      }
      
      setState(() {
        _isLoadingAssessments = false;
      });
      
      print('✓ Loaded ${_assessmentTypes.length} skating assessment types');
      
    } catch (e) {
      print('Error loading skating assessments: $e');
      
      _assessmentTypes = _getDefaultSkatingTypes();
      
      setState(() {
        _isLoadingAssessments = false;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: ResponsiveText('Warning: Using default skating assessment templates due to loading error', baseFontSize: 14),
            backgroundColor: Colors.orange,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  Map<String, Map<String, dynamic>> _getDefaultSkatingTypes() {
    return {
      'comprehensive_skating': {
        'title': 'Comprehensive Team Skating Assessment',
        'description': 'Complete evaluation of all skating abilities for the entire team',
        'category': 'comprehensive',
        'estimatedDurationMinutes': 45,
        'totalTests': 6,
        'groups': [
          {
            'id': 'speed_tests',
            'title': 'Speed Tests',
            'name': 'Speed Tests',
            'description': 'Forward and backward speed evaluation',
            'tests': [
              {
                'id': 'forward_speed_test',
                'title': 'Forward Speed Test',
                'category': 'Speed',
                'description': 'Skate forward from blue line to blue line at maximum speed',
                'benchmarks': {'Elite': 4.2, 'Advanced': 4.5, 'Developing': 4.8, 'Beginner': 5.2}
              },
              {
                'id': 'backward_speed_test',
                'title': 'Backward Speed Test',
                'category': 'Speed',
                'description': 'Skate backward maintaining control',
                'benchmarks': {'Elite': 5.2, 'Advanced': 5.6, 'Developing': 6.0, 'Beginner': 6.5}
              },
            ]
          },
        ]
      },
    };
  }

  Map<String, Map<String, dynamic>> getFilteredAssessmentTypes() {
    if (_selectedCategory == 'all' || _assessmentTypes.isEmpty) {
      return _assessmentTypes;
    }
    
    return Map.fromEntries(
      _assessmentTypes.entries.where((entry) {
        final category = entry.value['category'] as String? ?? 'comprehensive';
        return category == _selectedCategory;
      }),
    );
  }

  void _updateAvailablePlayers() {
    setState(() {
      if (_selectedTeam == null) {
        _availablePlayers = List.from(_allPlayers);
      } else {
        _availablePlayers = _allPlayers.where((player) {
          return player.teamId == _selectedTeam!.id || player.teamId == null;
        }).toList();
      }

      if (_filterPosition != 'all') {
        _availablePlayers = _availablePlayers.where((player) {
          return player.position?.toLowerCase().contains(_filterPosition.toLowerCase()) ?? false;
        }).toList();
      }

      _selectedPlayers = _selectedPlayers.where((selectedPlayer) {
        return _availablePlayers.any((available) => available.id == selectedPlayer.id);
      }).toList();
    });

    print('Updated available players: ${_availablePlayers.length} (team: ${_selectedTeam?.name ?? 'None'}, position: $_filterPosition)');
  }

  @override
  Widget build(BuildContext context) {
    if (_loadError != null) {
      return _buildErrorState();
    }

    if (_isLoadingTeams || _isLoadingPlayers || _isLoadingAssessments) {
      return _buildLoadingState();
    }

    return AdaptiveLayout(
      builder: (deviceType, isLandscape) {
        switch (deviceType) {
          case DeviceType.mobile:
            return _buildMobileLayout();
          case DeviceType.tablet:
            return _buildTabletLayout();
          case DeviceType.desktop:
            return _buildDesktopLayout();
        }
      },
    );
  }

  // 📱 MOBILE LAYOUT: Sequential team configuration
  Widget _buildMobileLayout() {
    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: ResponsiveConfig.paddingAll(context, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildTeamSelectionCard(),
                ResponsiveSpacing(multiplier: 2),
                _buildTestConfigCard(),
                ResponsiveSpacing(multiplier: 2),
                _buildPlayerFilterCard(),
                ResponsiveSpacing(multiplier: 2),
                _buildQuickPreviewCard(),
              ],
            ),
          ),
        ),
        _buildStartTeamAssessmentButton(),
      ],
    );
  }

  // 📱 TABLET LAYOUT: Two-column (Config | Preview)
  Widget _buildTabletLayout() {
    return Row(
      children: [
        Expanded(
          flex: 3,
          child: SingleChildScrollView(
            padding: ResponsiveConfig.paddingAll(context, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildTeamSelectionSection(),
                ResponsiveSpacing(multiplier: 3),
                _buildTestConfiguration(),
                ResponsiveSpacing(multiplier: 3),
                _buildPlayerFiltering(),
                ResponsiveSpacing(multiplier: 12), // Space for start button
              ],
            ),
          ),
        ),
        Expanded(
          flex: 2,
          child: Container(
            padding: ResponsiveConfig.paddingAll(context, 16),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              border: Border(
                left: BorderSide(color: Colors.grey[200]!),
              ),
            ),
            child: Column(
              children: [
                Expanded(child: _buildEnhancedPreview()),
                _buildTabletStartButton(),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // 🖥️ DESKTOP LAYOUT: Three-section with advanced features
  Widget _buildDesktopLayout() {
    return Row(
      children: [
        Expanded(
          flex: 4,
          child: SingleChildScrollView(
            padding: ResponsiveConfig.paddingAll(context, 24),
            child: _buildMainConfiguration(),
          ),
        ),
        Container(
          width: 350,
          decoration: BoxDecoration(
            color: Colors.grey[50],
            border: Border(
              left: BorderSide(color: Colors.grey[200]!),
            ),
          ),
          child: _buildDesktopSidebar(),
        ),
      ],
    );
  }

  // MOBILE COMPONENTS
  Widget _buildTeamSelectionCard() {
    return ResponsiveCard(
      padding: ResponsiveConfig.paddingAll(context, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Icon(Icons.groups, color: Colors.blue[600]),
              ResponsiveSpacing(multiplier: 1, direction: Axis.horizontal),
              ResponsiveText(
                'Team Selection',
                baseFontSize: 18,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.blueGrey[800],
                ),
              ),
            ],
          ),
          ResponsiveSpacing(multiplier: 2),
          _buildTeamSelector(),
        ],
      ),
    );
  }

  Widget _buildTestConfigCard() {
    return ResponsiveCard(
      padding: ResponsiveConfig.paddingAll(context, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Icon(Icons.assessment, color: Colors.orange[600]),
              ResponsiveSpacing(multiplier: 1, direction: Axis.horizontal),
              ResponsiveText(
                'Assessment Configuration',
                baseFontSize: 18,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.blueGrey[800],
                ),
              ),
            ],
          ),
          ResponsiveSpacing(multiplier: 2),
          _buildCategorySelector(),
          ResponsiveSpacing(multiplier: 2),
          AssessmentTypeSelector.forSkatingAssessment(
            selectedType: _selectedAssessmentType,
            onTypeSelected: (type) {
              setState(() {
                _selectedAssessmentType = type;
              });
            },
            assessmentTypes: getFilteredAssessmentTypes(),
            displayStyle: 'compact',
          ),
          ResponsiveSpacing(multiplier: 2),
          _buildAssessmentSettings(),
        ],
      ),
    );
  }

  Widget _buildPlayerFilterCard() {
    return ResponsiveCard(
      padding: ResponsiveConfig.paddingAll(context, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Icon(Icons.filter_list, color: Colors.purple[600]),
              ResponsiveSpacing(multiplier: 1, direction: Axis.horizontal),
              ResponsiveText(
                'Player Selection',
                baseFontSize: 18,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.blueGrey[800],
                ),
              ),
            ],
          ),
          ResponsiveSpacing(multiplier: 2),
          _buildPositionSelector(),
          ResponsiveSpacing(multiplier: 2),
          _buildPlayerSelectionList(),
        ],
      ),
    );
  }

  Widget _buildQuickPreviewCard() {
    return ResponsiveCard(
      backgroundColor: Colors.blue[50],
      padding: ResponsiveConfig.paddingAll(context, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Icon(Icons.preview, color: Colors.blue[600]),
              ResponsiveSpacing(multiplier: 1, direction: Axis.horizontal),
              ResponsiveText(
                'Assessment Preview',
                baseFontSize: 18,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.blue[800],
                ),
              ),
            ],
          ),
          ResponsiveSpacing(multiplier: 2),
          _buildQuickPreview(),
        ],
      ),
    );
  }

  // TABLET COMPONENTS
  Widget _buildTeamSelectionSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildSectionHeader('Team Selection'),
        ResponsiveSpacing(multiplier: 2),
        _buildTeamSelector(),
        ResponsiveSpacing(multiplier: 1),
        ResponsiveText(
          'Choose a team to filter players, or select "No Team" to include all players',
          baseFontSize: 13,
          style: TextStyle(
            color: Colors.blueGrey[600],
            fontStyle: FontStyle.italic,
          ),
        ),
      ],
    );
  }

  Widget _buildTestConfiguration() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildSectionHeader('Assessment Configuration'),
        ResponsiveSpacing(multiplier: 2),
        _buildCategorySelector(),
        ResponsiveSpacing(multiplier: 2),
        AssessmentTypeSelector.forSkatingAssessment(
          selectedType: _selectedAssessmentType,
          onTypeSelected: (type) {
            setState(() {
              _selectedAssessmentType = type;
            });
          },
          assessmentTypes: getFilteredAssessmentTypes(),
          displayStyle: 'card',
        ),
        ResponsiveSpacing(multiplier: 2),
        _buildAssessmentSettings(),
      ],
    );
  }

  Widget _buildPlayerFiltering() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildSectionHeader('Player Selection'),
        ResponsiveSpacing(multiplier: 2),
        _buildPositionSelector(),
        ResponsiveSpacing(multiplier: 2),
        _buildPlayerSelectionList(),
      ],
    );
  }

  Widget _buildEnhancedPreview() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          ResponsiveText(
            'Assessment Preview',
            baseFontSize: 18,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.blueGrey[800],
            ),
          ),
          ResponsiveSpacing(multiplier: 2),
          _buildAssessmentPreview(),
          ResponsiveSpacing(multiplier: 2),
          if (_selectedPlayers.isNotEmpty) _buildTimeEstimate(),
        ],
      ),
    );
  }

  // DESKTOP COMPONENTS
  Widget _buildMainConfiguration() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        ResponsiveText(
          'Team Skating Assessment Setup',
          baseFontSize: 24,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.blueGrey[800],
          ),
        ),
        ResponsiveSpacing(multiplier: 3),
        
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 2,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildSectionHeader('Team & Assessment Configuration'),
                  ResponsiveSpacing(multiplier: 2),
                  _buildTeamSelector(),
                  ResponsiveSpacing(multiplier: 3),
                  _buildCategorySelector(),
                  ResponsiveSpacing(multiplier: 2),
                  AssessmentTypeSelector.forSkatingAssessment(
                    selectedType: _selectedAssessmentType,
                    onTypeSelected: (type) {
                      setState(() {
                        _selectedAssessmentType = type;
                      });
                    },
                    assessmentTypes: getFilteredAssessmentTypes(),
                    displayStyle: 'card',
                  ),
                  ResponsiveSpacing(multiplier: 3),
                  _buildAssessmentSettings(),
                ],
              ),
            ),
            ResponsiveSpacing(multiplier: 3, direction: Axis.horizontal),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildSectionHeader('Player Selection'),
                  ResponsiveSpacing(multiplier: 2),
                  _buildPositionSelector(),
                  ResponsiveSpacing(multiplier: 2),
                  _buildPlayerSelectionList(),
                ],
              ),
            ),
          ],
        ),
        
        ResponsiveSpacing(multiplier: 4),
        _buildDesktopStartButton(),
      ],
    );
  }

  Widget _buildDesktopSidebar() {
    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: ResponsiveConfig.paddingAll(context, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildTeamRosterPanel(),
                ResponsiveSpacing(multiplier: 3),
                _buildTestTemplates(),
                ResponsiveSpacing(multiplier: 3),
                _buildSkatingTips(),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTeamRosterPanel() {
    return Container(
      padding: ResponsiveConfig.paddingAll(context, 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: ResponsiveConfig.borderRadius(context, 12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Icon(Icons.people, color: Colors.blue[600], size: ResponsiveConfig.iconSize(context, 20)),
              ResponsiveSpacing(multiplier: 1, direction: Axis.horizontal),
              ResponsiveText(
                'Team Roster',
                baseFontSize: 16,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.blueGrey[800],
                ),
              ),
            ],
          ),
          ResponsiveSpacing(multiplier: 1.5),
          
          if (_selectedTeam != null) ...[
            Container(
              padding: ResponsiveConfig.paddingAll(context, 12),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: ResponsiveConfig.borderRadius(context, 8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  ResponsiveText(
                    _selectedTeam!.name,
                    baseFontSize: 16,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  ResponsiveText(
                    _selectedTeam!.division ?? 'Unknown Division',
                    baseFontSize: 12,
                    style: TextStyle(color: Colors.blueGrey[600]),
                  ),
                  ResponsiveSpacing(multiplier: 1),
                  ResponsiveText(
                    '${_availablePlayers.length} players available',
                    baseFontSize: 14,
                    style: TextStyle(
                      color: Colors.blueGrey[700],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            ResponsiveSpacing(multiplier: 1.5),
          ],
          
          ResponsiveText(
            'Selected: ${_selectedPlayers.length} players',
            baseFontSize: 14,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.green[700],
            ),
          ),
          if (_selectedPlayers.isNotEmpty) ...[
            ResponsiveSpacing(multiplier: 1),
            Container(
              constraints: BoxConstraints(maxHeight: ResponsiveConfig.dimension(context, 150)),
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: _selectedPlayers.length,
                itemBuilder: (context, index) {
                  final player = _selectedPlayers[index];
                  return Padding(
                    padding: ResponsiveConfig.paddingSymmetric(context, vertical: 2),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: ResponsiveConfig.dimension(context, 12),
                          backgroundColor: Colors.green[100],
                          child: ResponsiveText(
                            player.jerseyNumber?.toString() ?? '?',
                            baseFontSize: 10,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.green[700],
                            ),
                          ),
                        ),
                        ResponsiveSpacing(multiplier: 1, direction: Axis.horizontal),
                        Expanded(
                          child: ResponsiveText(
                            player.name,
                            baseFontSize: 12,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTestTemplates() {
    return Container(
      padding: ResponsiveConfig.paddingAll(context, 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: ResponsiveConfig.borderRadius(context, 12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Icon(Icons.speed, color: Colors.orange[600], size: ResponsiveConfig.iconSize(context, 20)),
              ResponsiveSpacing(multiplier: 1, direction: Axis.horizontal),
              ResponsiveText(
                'Quick Templates',
                baseFontSize: 16,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.blueGrey[800],
                ),
              ),
            ],
          ),
          ResponsiveSpacing(multiplier: 1.5),
          
          _buildQuickTemplate(
            'Speed Focus',
            'Forward & backward speed tests',
            Colors.blue,
            () => _applyQuickTemplate('speed'),
          ),
          ResponsiveSpacing(multiplier: 1),
          _buildQuickTemplate(
            'Agility Focus',
            'Agility & transition tests',
            Colors.purple,
            () => _applyQuickTemplate('agility'),
          ),
          ResponsiveSpacing(multiplier: 1),
          _buildQuickTemplate(
            'Full Assessment',
            'Complete skating evaluation',
            Colors.green,
            () => _applyQuickTemplate('comprehensive'),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickTemplate(String title, String description, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: ResponsiveConfig.paddingAll(context, 8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: ResponsiveConfig.borderRadius(context, 8),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            ResponsiveText(
              title,
              baseFontSize: 12,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            ResponsiveText(
              description,
              baseFontSize: 10,
              style: TextStyle(color: color.withOpacity(0.8)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSkatingTips() {
    return Container(
      padding: ResponsiveConfig.paddingAll(context, 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: ResponsiveConfig.borderRadius(context, 12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Icon(Icons.lightbulb, color: Colors.amber[600], size: ResponsiveConfig.iconSize(context, 20)),
              ResponsiveSpacing(multiplier: 1, direction: Axis.horizontal),
              ResponsiveText(
                'Team Assessment Tips',
                baseFontSize: 16,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.blueGrey[800],
                ),
              ),
            ],
          ),
          ResponsiveSpacing(multiplier: 1.5),
          
          _buildTip('Warm up players thoroughly before testing'),
          _buildTip('Allow adequate rest between tests'),
          _buildTip('Test players in consistent ice conditions'),
          _buildTip('Consider grouping by skill level for efficiency'),
          _buildTip('Use consistent timing methods across all players'),
        ],
      ),
    );
  }

  Widget _buildTip(String tip) {
    return Padding(
      padding: ResponsiveConfig.paddingSymmetric(context, vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: ResponsiveConfig.dimension(context, 4),
            height: ResponsiveConfig.dimension(context, 4),
            margin: ResponsiveConfig.paddingSymmetric(context, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.amber[600],
              shape: BoxShape.circle,
            ),
          ),
          ResponsiveSpacing(multiplier: 1, direction: Axis.horizontal),
          Expanded(
            child: ResponsiveText(
              tip,
              baseFontSize: 11,
              style: TextStyle(color: Colors.blueGrey[700]),
            ),
          ),
        ],
      ),
    );
  }

  // SHARED COMPONENTS (used across layouts)
  Widget _buildLoadingState() {
    final List<String> loadingItems = [];
    if (_isLoadingTeams) loadingItems.add('teams');
    if (_isLoadingPlayers) loadingItems.add('players');
    if (_isLoadingAssessments) loadingItems.add('assessments');

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          const CircularProgressIndicator(),
          ResponsiveSpacing(multiplier: 2),
          ResponsiveText(
            'Loading ${loadingItems.join(', ')}...',
            baseFontSize: 16,
            style: TextStyle(color: Colors.blueGrey[600]),
          ),
          ResponsiveSpacing(multiplier: 1),
          ResponsiveText(
            'Please wait while we prepare your skating assessment options',
            baseFontSize: 14,
            style: TextStyle(color: Colors.blueGrey[500]),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.error_outline,
            size: ResponsiveConfig.iconSize(context, 64),
            color: Colors.red[300],
          ),
          ResponsiveSpacing(multiplier: 2),
          ResponsiveText(
            'Error Loading Data',
            baseFontSize: 20,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          ResponsiveSpacing(multiplier: 1),
          ResponsiveText(
            _loadError ?? 'Unknown error occurred',
            baseFontSize: 14,
            style: TextStyle(color: Colors.grey[600]),
            textAlign: TextAlign.center,
          ),
          ResponsiveSpacing(multiplier: 2),
          ResponsiveButton(
            text: 'Retry',
            onPressed: _loadDataFromDatabase,
            baseHeight: 48,
            backgroundColor: Colors.blue,
            foregroundColor: Colors.white,
            icon: Icons.refresh,
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return ResponsiveText(
      title,
      baseFontSize: 18,
      style: TextStyle(
        fontWeight: FontWeight.bold,
        color: Colors.blueGrey[800],
      ),
    );
  }

  Widget _buildCategorySelector() {
    final categories = [
      {'value': 'all', 'label': 'All', 'icon': Icons.list, 'color': Colors.blueGrey},
      {'value': 'comprehensive', 'label': 'Comprehensive', 'icon': Icons.assessment, 'color': Colors.blue},
      {'value': 'focused', 'label': 'Focused', 'icon': Icons.center_focus_strong, 'color': Colors.orange},
    ];

    return Wrap(
      spacing: ResponsiveConfig.spacing(context, 8),
      runSpacing: ResponsiveConfig.spacing(context, 8),
      children: categories.map((category) {
        final isSelected = _selectedCategory == category['value'];
        return GestureDetector(
          onTap: () {
            setState(() {
              _selectedCategory = category['value'] as String;
              final filtered = getFilteredAssessmentTypes();
              if (!filtered.containsKey(_selectedAssessmentType) && filtered.isNotEmpty) {
                _selectedAssessmentType = filtered.keys.first;
              }
            });
          },
          child: Container(
            padding: ResponsiveConfig.paddingSymmetric(context, vertical: 8, horizontal: 12),
            decoration: BoxDecoration(
              color: isSelected ? (category['color'] as Color) : Colors.white,
              borderRadius: ResponsiveConfig.borderRadius(context, 20),
              border: Border.all(
                color: isSelected ? (category['color'] as Color) : Colors.grey[300]!,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  category['icon'] as IconData,
                  color: isSelected ? Colors.white : (category['color'] as Color),
                  size: ResponsiveConfig.iconSize(context, 16),
                ),
                ResponsiveSpacing(multiplier: 0.75, direction: Axis.horizontal),
                ResponsiveText(
                  category['label'] as String,
                  baseFontSize: 12,
                  style: TextStyle(
                    fontWeight: FontWeight.w500,
                    color: isSelected ? Colors.white : (category['color'] as Color),
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildTeamSelector() {
    return Container(
      padding: ResponsiveConfig.paddingSymmetric(context, horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: ResponsiveConfig.borderRadius(context, 8),
      ),
      child: DropdownButton<Team?>(
        value: _selectedTeam,
        isExpanded: true,
        underline: Container(),
        hint: ResponsiveText('Select a team (optional)', baseFontSize: 14),
        items: [
          DropdownMenuItem<Team?>(
            value: null,
            child: Row(
              children: [
                Icon(Icons.people_outline, color: Colors.grey),
                ResponsiveSpacing(multiplier: 1, direction: Axis.horizontal),
                ResponsiveText('No Team - Show All Players', baseFontSize: 14),
              ],
            ),
          ),
          ..._teams.map((team) {
            final teamPlayerCount = _allPlayers.where((p) => p.teamId == team.id).length;
            return DropdownMenuItem<Team?>(
              value: team,
              child: Row(
                children: [
                  Icon(Icons.groups, color: Colors.blue[600]),
                  ResponsiveSpacing(multiplier: 1, direction: Axis.horizontal),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        ResponsiveText(
                          team.name,
                          baseFontSize: 14,
                          style: const TextStyle(fontWeight: FontWeight.w500),
                        ),
                        ResponsiveText(
                          '${team.division ?? 'Unknown'} • $teamPlayerCount players',
                          baseFontSize: 12,
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ],
        onChanged: (Team? team) {
          setState(() {
            _selectedTeam = team;
            _selectedPlayers.clear();
          });
          _updateAvailablePlayers();
        },
      ),
    );
  }

  Widget _buildPositionSelector() {
    final positions = ['all', 'Forward', 'Defenseman', 'Goalie'];
    return Container(
      padding: ResponsiveConfig.paddingSymmetric(context, horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: ResponsiveConfig.borderRadius(context, 8),
      ),
      child: DropdownButton<String>(
        value: _filterPosition,
        isExpanded: true,
        underline: Container(),
        items: positions.map((position) {
          final count = position == 'all' 
              ? _availablePlayers.length
              : _availablePlayers.where((p) => p.position?.toLowerCase().contains(position.toLowerCase()) ?? false).length;
          
          return DropdownMenuItem<String>(
            value: position,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                ResponsiveText(position.capitalize(), baseFontSize: 14),
                ResponsiveText(
                  '($count)',
                  baseFontSize: 12,
                  style: TextStyle(color: Colors.grey[600]),
                ),
              ],
            ),
          );
        }).toList(),
        onChanged: (value) {
          setState(() {
            _filterPosition = value!;
          });
          _updateAvailablePlayers();
        },
      ),
    );
  }

  Widget _buildPlayerSelectionList() {
    if (_availablePlayers.isEmpty) {
      String title;
      String subtitle;
      
      if (_allPlayers.isEmpty) {
        title = 'No players found in database';
        subtitle = 'Please add players to the system first';
      } else if (_selectedTeam != null) {
        title = 'No players found for this team and position';
        subtitle = 'Try selecting "No Team" or change position filter';
      } else {
        title = 'No players match the current filters';
        subtitle = 'Try adjusting your position filter';
      }

      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          EmptyStateDisplay(
            title: title,
            icon: Icons.person_off,
            showCard: true,
          ),
          if (subtitle.isNotEmpty) ...[
            ResponsiveSpacing(multiplier: 1),
            ResponsiveText(
              subtitle,
              baseFontSize: 14,
              style: TextStyle(
                color: Colors.grey[600],
                fontStyle: FontStyle.italic,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ],
      );
    }

    return ResponsiveCard(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: ResponsiveConfig.paddingSymmetric(context, horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(ResponsiveConfig.borderRadiusValue(context, 7)),
                topRight: Radius.circular(ResponsiveConfig.borderRadiusValue(context, 7)),
              ),
            ),
            child: Row(
              children: [
                Expanded(flex: 1, child: ResponsiveText('#', baseFontSize: 14, style: const TextStyle(fontWeight: FontWeight.bold))),
                Expanded(flex: 3, child: ResponsiveText('Player', baseFontSize: 14, style: const TextStyle(fontWeight: FontWeight.bold))),
                Expanded(flex: 2, child: ResponsiveText('Position', baseFontSize: 14, style: const TextStyle(fontWeight: FontWeight.bold))),
                Expanded(flex: 2, child: ResponsiveText('Team', baseFontSize: 14, style: const TextStyle(fontWeight: FontWeight.bold))),
                ResponsiveSpacing(multiplier: 1, direction: Axis.horizontal),
                Checkbox(
                  value: _isAllPlayersSelected(_availablePlayers),
                  onChanged: (value) => _toggleAllPlayers(value, _availablePlayers),
                  activeColor: Colors.cyanAccent[700],
                ),
              ],
            ),
          ),

          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _availablePlayers.length,
            itemBuilder: (context, index) {
              final player = _availablePlayers[index];
              final isSelected = _isPlayerSelected(player);
              final playerTeam = player.teamId != null 
                  ? _teams.firstWhere((t) => t.id == player.teamId, orElse: () => Team(id: -1, name: 'Unknown Team'))
                  : null;

              return Container(
                decoration: BoxDecoration(
                  border: Border(top: BorderSide(color: Colors.grey[300]!)),
                  color: index % 2 == 0 ? Colors.white : Colors.grey[50],
                ),
                child: ListTile(
                  dense: true,
                  leading: CircleAvatar(
                    radius: ResponsiveConfig.dimension(context, 16),
                    backgroundColor: isSelected ? Colors.cyanAccent[700] : Colors.grey[300],
                    child: ResponsiveText(
                      player.jerseyNumber?.toString() ?? '?',
                      baseFontSize: 12,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: isSelected ? Colors.white : Colors.grey[700],
                      ),
                    ),
                  ),
                  title: Row(
                    children: [
                      Expanded(
                        flex: 3,
                        child: ResponsiveText(
                          player.name,
                          baseFontSize: 14,
                          style: TextStyle(
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          ),
                        ),
                      ),
                      Expanded(
                        flex: 2,
                        child: ResponsiveText(
                          player.position ?? 'Unknown',
                          baseFontSize: 14,
                        ),
                      ),
                      Expanded(
                        flex: 2,
                        child: ResponsiveText(
                          playerTeam?.name ?? 'No Team',
                          baseFontSize: 12,
                          style: TextStyle(
                            color: playerTeam == null ? Colors.grey[600] : Colors.blueGrey[600],
                            fontStyle: playerTeam == null ? FontStyle.italic : FontStyle.normal,
                          ),
                        ),
                      ),
                    ],
                  ),
                  trailing: Checkbox(
                    value: isSelected,
                    onChanged: (value) => _togglePlayerSelection(player),
                    activeColor: Colors.cyanAccent[700],
                  ),
                  onTap: () => _togglePlayerSelection(player),
                ),
              );
            },
          ),

          Container(
            padding: ResponsiveConfig.paddingSymmetric(context, horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(ResponsiveConfig.borderRadiusValue(context, 7)),
                bottomRight: Radius.circular(ResponsiveConfig.borderRadiusValue(context, 7)),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                ResponsiveText(
                  '${_selectedPlayers.length} players selected',
                  baseFontSize: 14,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.blueGrey[700],
                  ),
                ),
                Row(
                  children: [
                    TextButton(
                      onPressed: _selectedPlayers.isNotEmpty ? _clearPlayerSelection : null,
                      child: ResponsiveText('Clear All', baseFontSize: 14),
                    ),
                    ResponsiveSpacing(multiplier: 1, direction: Axis.horizontal),
                    TextButton(
                      onPressed: _availablePlayers.isNotEmpty ? () => _selectAllPlayers(_availablePlayers) : null,
                      child: ResponsiveText('Select All', baseFontSize: 14),
                    ),
                  ],
                ),
              ],
            ),
          ),

          if (_selectedPlayers.isNotEmpty) ...[
            ResponsiveSpacing(multiplier: 1),
            _buildTimeEstimate(),
          ],
        ],
      ),
    );
  }

  Widget _buildTimeEstimate() {
    if (_assessmentTypes.containsKey(_selectedAssessmentType)) {
      final template = _assessmentTypes[_selectedAssessmentType]!;
      final testsPerPlayer = template['totalTests'] as int? ?? 0;
      final totalTests = testsPerPlayer * _selectedPlayers.length;
      final estimatedMinutes = (totalTests * 2.5).ceil();
      final hours = estimatedMinutes ~/ 60;
      final minutes = estimatedMinutes % 60;
      
      String timeString = '';
      if (hours > 0) {
        timeString += '${hours}h ';
      }
      if (minutes > 0) {
        timeString += '${minutes}m';
      }
      
      return Container(
        padding: ResponsiveConfig.paddingAll(context, 8),
        decoration: BoxDecoration(
          color: Colors.blue[50],
          borderRadius: ResponsiveConfig.borderRadius(context, 8),
          border: Border.all(color: Colors.blue[200]!),
        ),
        child: Row(
          children: [
            Icon(Icons.schedule, size: ResponsiveConfig.iconSize(context, 16), color: Colors.blue[700]),
            ResponsiveSpacing(multiplier: 1, direction: Axis.horizontal),
            Expanded(
              child: ResponsiveText(
                'Estimated time: $timeString ($totalTests total tests)',
                baseFontSize: 12,
                style: TextStyle(
                  color: Colors.blue[700],
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      );
    }
    return const SizedBox.shrink();
  }

  Widget _buildAssessmentSettings() {
    return ResponsiveCard(
      padding: ResponsiveConfig.paddingAll(context, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          ResponsiveText(
            'Assessment Settings',
            baseFontSize: 16,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.blueGrey[800],
            ),
          ),
          ResponsiveSpacing(multiplier: 2),
          DropdownButtonFormField<String>(
            value: _selectedAgeGroup,
            decoration: InputDecoration(
              labelText: 'Age Group',
              border: OutlineInputBorder(
                borderRadius: ResponsiveConfig.borderRadius(context, 8),
              ),
              contentPadding: ResponsiveConfig.paddingSymmetric(context, horizontal: 12, vertical: 8),
            ),
            items: ['youth_8_10', 'youth_11_14', 'youth_15_18', 'adult'].map((ageGroup) => 
              DropdownMenuItem(
                value: ageGroup, 
                child: ResponsiveText(_formatAgeGroup(ageGroup), baseFontSize: 14)
              )
            ).toList(),
            onChanged: (value) {
              setState(() {
                _selectedAgeGroup = value!;
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildAssessmentPreview() {
    final assessmentData = _assessmentTypes[_selectedAssessmentType];
    if (assessmentData == null) return const SizedBox.shrink();

    final groups = assessmentData['groups'] as List? ?? [];
    int totalTestsPerPlayer = 0;
    for (var group in groups) {
      totalTestsPerPlayer += ((group as Map<String, dynamic>)['tests'] as List? ?? []).length;
    }

    final totalTeamTests = totalTestsPerPlayer * _selectedPlayers.length;

    return Container(
      padding: ResponsiveConfig.paddingAll(context, 16),
      decoration: BoxDecoration(
        color: Colors.blueGrey[50],
        borderRadius: ResponsiveConfig.borderRadius(context, 12),
        border: Border.all(color: Colors.blueGrey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          ResponsiveText(
            'Assessment Preview',
            baseFontSize: 16,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.blueGrey[800],
            ),
          ),
          ResponsiveSpacing(multiplier: 1),
          ResponsiveText(
            assessmentData['description'] as String? ?? '',
            baseFontSize: 14,
            style: TextStyle(color: Colors.blueGrey[600]),
          ),
          ResponsiveSpacing(multiplier: 2),
          
          Row(
            children: [
              Expanded(
                child: _buildPreviewStat('Players', _selectedPlayers.length.toString(), Icons.people),
              ),
              Expanded(
                child: _buildPreviewStat('Tests/Player', totalTestsPerPlayer.toString(), Icons.assignment),
              ),
              Expanded(
                child: _buildPreviewStat('Total Tests', totalTeamTests.toString(), Icons.quiz),
              ),
            ],
          ),
          
          ResponsiveSpacing(multiplier: 2),
          ResponsiveText(
            'Test Groups:',
            baseFontSize: 14,
            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blueGrey[700]),
          ),
          ResponsiveSpacing(multiplier: 1),
          ...groups.asMap().entries.map((entry) {
            final i = entry.key;
            final group = entry.value as Map<String, dynamic>;
            final groupTests = (group['tests'] as List? ?? []).length;
            return Padding(
              padding: ResponsiveConfig.paddingSymmetric(context, vertical: 4),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: ResponsiveConfig.dimension(context, 24),
                    height: ResponsiveConfig.dimension(context, 24),
                    decoration: const BoxDecoration(
                      color: Colors.cyanAccent,
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: ResponsiveText(
                        '${i + 1}',
                        baseFontSize: 12,
                        style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black),
                      ),
                    ),
                  ),
                  ResponsiveSpacing(multiplier: 1.5, direction: Axis.horizontal),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        ResponsiveText(
                          group['name'] as String? ?? group['title'] as String? ?? '',
                          baseFontSize: 14,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        ResponsiveText(
                          '$groupTests tests × ${_selectedPlayers.length} players = ${groupTests * _selectedPlayers.length} total',
                          baseFontSize: 12,
                          style: TextStyle(color: Colors.blueGrey[600]),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ],
      ),
    );
  }

  Widget _buildQuickPreview() {
    final assessmentData = _assessmentTypes[_selectedAssessmentType];
    if (assessmentData == null) {
      return ResponsiveText(
        'Select an assessment type to see preview',
        baseFontSize: 14,
        style: TextStyle(
          fontStyle: FontStyle.italic,
          color: Colors.grey[600],
        ),
      );
    }

    final testsPerPlayer = assessmentData['totalTests'] as int? ?? 0;
    final totalTests = testsPerPlayer * _selectedPlayers.length;
    final estimatedMinutes = assessmentData['estimatedDurationMinutes'] as int? ?? 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        ResponsiveText(
          assessmentData['title'] as String? ?? 'Assessment',
          baseFontSize: 16,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        ResponsiveSpacing(multiplier: 1),
        ResponsiveText(
          assessmentData['description'] as String? ?? '',
          baseFontSize: 14,
          style: TextStyle(color: Colors.blueGrey[600]),
        ),
        ResponsiveSpacing(multiplier: 1.5),
        Row(
          children: [
            Icon(Icons.people, size: ResponsiveConfig.iconSize(context, 16), color: Colors.blue[600]),
            ResponsiveSpacing(multiplier: 0.75, direction: Axis.horizontal),
            ResponsiveText('${_selectedPlayers.length} players', baseFontSize: 14),
            ResponsiveSpacing(multiplier: 2, direction: Axis.horizontal),
            Icon(Icons.quiz, size: ResponsiveConfig.iconSize(context, 16), color: Colors.blue[600]),
            ResponsiveSpacing(multiplier: 0.75, direction: Axis.horizontal),
            ResponsiveText('$totalTests total tests', baseFontSize: 14),
          ],
        ),
        if (estimatedMinutes > 0) ...[
          ResponsiveSpacing(multiplier: 1),
          Row(
            children: [
              Icon(Icons.schedule, size: ResponsiveConfig.iconSize(context, 16), color: Colors.blue[600]),
              ResponsiveSpacing(multiplier: 0.75, direction: Axis.horizontal),
              ResponsiveText('~${estimatedMinutes}min estimated', baseFontSize: 14),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildPreviewStat(String label, String value, IconData icon) {
    return Container(
      padding: ResponsiveConfig.paddingAll(context, 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: ResponsiveConfig.borderRadius(context, 8),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.cyanAccent[700], size: ResponsiveConfig.iconSize(context, 20)),
          ResponsiveSpacing(multiplier: 0.5),
          ResponsiveText(
            value,
            baseFontSize: 18,
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

  // RESPONSIVE START BUTTONS
  Widget _buildStartTeamAssessmentButton() {
    return Container(
      padding: ResponsiveConfig.paddingAll(context, 16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: SizedBox(
          width: double.infinity,
          child: ResponsiveButton(
            text: _isCreatingSession ? 'Creating Team Session...' : 'Start Team Assessment',
            onPressed: (_selectedPlayers.isEmpty || _isCreatingSession) ? null : _startAssessment,
            baseHeight: 48,
            backgroundColor: _isCreatingSession ? Colors.grey : Colors.cyanAccent[700],
            foregroundColor: Colors.white,
            borderRadius: ResponsiveConfig.borderRadiusValue(context, 12),
            child: _isCreatingSession
                ? Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(
                        width: ResponsiveConfig.dimension(context, 20),
                        height: ResponsiveConfig.dimension(context, 20),
                        child: const CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      ),
                      ResponsiveSpacing(multiplier: 1.5, direction: Axis.horizontal),
                      ResponsiveText(
                        'Creating Team Session...',
                        baseFontSize: 16,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ],
                  )
                : null,
          ),
        ),
      ),
    );
  }

  Widget _buildTabletStartButton() {
    return Padding(
      padding: ResponsiveConfig.paddingSymmetric(context, vertical: 16),
      child: SizedBox(
        width: double.infinity,
        child: ResponsiveButton(
          text: _isCreatingSession ? 'Creating...' : 'Start Assessment',
          onPressed: (_selectedPlayers.isEmpty || _isCreatingSession) ? null : _startAssessment,
          baseHeight: 48,
          backgroundColor: _isCreatingSession ? Colors.grey : Colors.cyanAccent[700],
          foregroundColor: Colors.white,
          borderRadius: ResponsiveConfig.borderRadiusValue(context, 12),
          child: _isCreatingSession
              ? Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: ResponsiveConfig.dimension(context, 16),
                      height: ResponsiveConfig.dimension(context, 16),
                      child: const CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    ),
                    ResponsiveSpacing(multiplier: 1, direction: Axis.horizontal),
                    ResponsiveText('Creating...', baseFontSize: 14),
                  ],
                )
              : null,
        ),
      ),
    );
  }

  Widget _buildDesktopStartButton() {
    return Row(
      children: [
        Expanded(
          child: ResponsiveButton(
            text: _isCreatingSession ? 'Creating Team Session...' : 'Start Team Assessment',
            onPressed: (_selectedPlayers.isEmpty || _isCreatingSession) ? null : _startAssessment,
            baseHeight: 56,
            backgroundColor: _isCreatingSession ? Colors.grey : Colors.cyanAccent[700],
            foregroundColor: Colors.white,
            borderRadius: ResponsiveConfig.borderRadiusValue(context, 12),
            child: _isCreatingSession
                ? Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(
                        width: ResponsiveConfig.dimension(context, 20),
                        height: ResponsiveConfig.dimension(context, 20),
                        child: const CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      ),
                      ResponsiveSpacing(multiplier: 1.5, direction: Axis.horizontal),
                      ResponsiveText(
                        'Creating Team Session...',
                        baseFontSize: 18,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ],
                  )
                : null,
          ),
        ),
        ResponsiveSpacing(multiplier: 2, direction: Axis.horizontal),
        ResponsiveButton(
          text: '',
          onPressed: _debugConfig,
          baseHeight: 56,
          width: ResponsiveConfig.dimension(context, 56),
          backgroundColor: Colors.blue[600],
          foregroundColor: Colors.white,
          borderRadius: ResponsiveConfig.borderRadiusValue(context, 12),
          icon: Icons.bug_report,
        ),
      ],
    );
  }

  // HELPER METHODS
  String _formatAgeGroup(String ageGroup) {
    switch (ageGroup) {
      case 'youth_8_10': return 'Youth 8-10';
      case 'youth_11_14': return 'Youth 11-14';
      case 'youth_15_18': return 'Youth 15-18';
      case 'adult': return 'Adult';
      default: return ageGroup.replaceAll('_', ' ').toUpperCase();
    }
  }

  bool _isAllPlayersSelected(List<Player> players) {
    if (players.isEmpty) return false;
    return players.every((player) => _isPlayerSelected(player));
  }

  void _toggleAllPlayers(bool? value, List<Player> players) {
    if (value == true) {
      setState(() {
        for (var player in players) {
          if (!_isPlayerSelected(player)) {
            _selectedPlayers.add(player);
          }
        }
      });
    } else {
      setState(() {
        _selectedPlayers.removeWhere(
          (selectedPlayer) => players.any((player) => player.id == selectedPlayer.id),
        );
      });
    }
  }

  void _selectAllPlayers(List<Player> players) {
    setState(() {
      _selectedPlayers.clear();
      _selectedPlayers.addAll(players);
    });
  }

  bool _isPlayerSelected(Player player) {
    return _selectedPlayers.any((p) => p.id == player.id);
  }

  void _togglePlayerSelection(Player player) {
    setState(() {
      if (_isPlayerSelected(player)) {
        _selectedPlayers.removeWhere((p) => p.id == player.id);
      } else {
        _selectedPlayers.add(player);
      }
    });
  }

  void _clearPlayerSelection() {
    setState(() {
      _selectedPlayers = [];
    });
  }

  void _applyQuickTemplate(String templateType) {
    setState(() {
      switch (templateType) {
        case 'speed':
          _selectedCategory = 'focused';
          if (_assessmentTypes.containsKey('focused_skating')) {
            _selectedAssessmentType = 'focused_skating';
          }
          break;
        case 'agility':
          _selectedCategory = 'focused';
          if (_assessmentTypes.containsKey('focused_skating')) {
            _selectedAssessmentType = 'focused_skating';
          }
          break;
        case 'comprehensive':
          _selectedCategory = 'comprehensive';
          if (_assessmentTypes.containsKey('comprehensive_skating')) {
            _selectedAssessmentType = 'comprehensive_skating';
          }
          break;
      }
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: ResponsiveText('Applied $templateType template', baseFontSize: 14),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _debugConfig() {
    try {
      print('=== TEAM DEBUG CONFIG ===');
      print('Assessment types: ${_assessmentTypes.keys.toList()}');
      print('Selected type: $_selectedAssessmentType');
      print('Selected team: ${_selectedTeam?.name}');
      print('Selected players: ${_selectedPlayers.length}');
      
      final template = _assessmentTypes[_selectedAssessmentType];
      if (template != null) {
        final groups = template['groups'] as List;
        final totalTests = groups.fold<int>(0, (sum, group) => sum + (group['tests'] as List).length);
        final totalTeamTests = totalTests * _selectedPlayers.length;
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: ResponsiveText('Config: $totalTests tests/player × ${_selectedPlayers.length} players = $totalTeamTests total tests', baseFontSize: 14),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 4),
          ),
        );
      }
      print('========================');
    } catch (e) {
      print('Debug config failed: $e');
    }
  }

  void _startAssessment() async {
    if (_selectedTeam == null && _selectedPlayers.isEmpty) {
      DialogService.showError(
        context,
        title: 'No Team or Players Selected',
        message: 'Please select a team or individual players before starting the assessment.',
      );
      return;
    }

    if (_selectedPlayers.isEmpty) {
      DialogService.showError(
        context,
        title: 'No Players Selected',
        message: 'Please select at least one player before starting the assessment.',
      );
      return;
    }

    if (_selectedAssessmentType.isEmpty) {
      DialogService.showError(
        context,
        title: 'No Assessment Type Selected',
        message: 'Please select an assessment type before starting.',
      );
      return;
    }

    final template = _assessmentTypes[_selectedAssessmentType];
    if (template == null) {
      DialogService.showError(
        context,
        title: 'Invalid Assessment Type',
        message: 'The selected assessment type could not be loaded.',
      );
      return;
    }

    final testsPerPlayer = template['totalTests'] as int? ?? 0;
    final totalTests = testsPerPlayer * _selectedPlayers.length;
    final estimatedMinutes = (totalTests * 2.5).ceil();

    final confirmed = await DialogService.showConfirmation(
      context,
      title: 'Start Team Assessment?',
      message: '''Assessment: ${template['title']}
Team: ${_selectedTeam?.name ?? 'Mixed Team'}
Players: ${_selectedPlayers.length} selected
Tests per player: $testsPerPlayer
Total tests: $totalTests
Estimated time: ${estimatedMinutes ~/ 60}h ${estimatedMinutes % 60}m

Age Group: ${_formatAgeGroup(_selectedAgeGroup)}

Ready to begin?''',
      confirmLabel: 'Start Assessment',
      cancelLabel: 'Cancel',
    );

    if (confirmed == true) {
      _createSessionAndStartAssessment();
    }
  }

  void _createSessionAndStartAssessment() async {
    setState(() {
      _isCreatingSession = true;
    });

    try {
      print('🚀 Starting team assessment session creation');
      print('  Team: ${_selectedTeam?.name ?? 'Mixed Team'}');
      print('  Players: ${_selectedPlayers.length}');
      print('  Assessment type: $_selectedAssessmentType');
      
      final assessmentTitle = '${_assessmentTypes[_selectedAssessmentType]!['title']} - ${_selectedTeam?.name ?? 'Mixed Team'}';
      
      print('✅ Team assessment configured successfully');
      
      widget.onStart(
        _selectedAssessmentType,
        _selectedTeam?.name ?? 'Mixed Team',
        _selectedPlayers,
      );
      
    } catch (e) {
      print('❌ Error creating team session: $e');
      
      if (mounted) {
        DialogService.showError(
          context,
          title: 'Session Creation Failed',
          message: 'Failed to create team assessment session: $e\n\nPlease try again.',
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isCreatingSession = false;
        });
      }
    }
  }
}

extension StringExtension on String {
  String capitalize() {
    return "${this[0].toUpperCase()}${substring(1).toLowerCase()}";
  }
}