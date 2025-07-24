import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'dart:convert';
import 'package:hockey_shot_tracker/providers/app_state.dart';
import 'package:hockey_shot_tracker/models/shot.dart';
import 'package:hockey_shot_tracker/models/player.dart';
import 'package:hockey_shot_tracker/models/team.dart';
import 'package:hockey_shot_tracker/models/assessment_config.dart';
import 'package:hockey_shot_tracker/services/assessment_config_service.dart';
import 'package:hockey_shot_tracker/widgets/domain/assessment/common/assessment_type_selector.dart';
import 'package:hockey_shot_tracker/widgets/domain/team/team_selector_widget.dart';
import 'package:hockey_shot_tracker/widgets/core/state/index.dart';
import 'package:hockey_shot_tracker/services/dialog_service.dart';
import 'package:hockey_shot_tracker/responsive_system/index.dart';

class TeamShotSetupView extends StatefulWidget {
  final Function(Map<String, dynamic>, List<Player>) onStart;

  const TeamShotSetupView({
    Key? key,
    required this.onStart,
  }) : super(key: key);

  @override
  _TeamShotSetupViewState createState() => _TeamShotSetupViewState();
}

class _TeamShotSetupViewState extends State<TeamShotSetupView> {
  String _selectedAssessmentType = 'Comprehensive';
  String _selectedCategory = 'all';
  Team? _selectedTeam;
  String _filterPosition = 'all';
  List<Player> _selectedPlayers = [];

  // Database-loaded data
  List<Team> _teams = [];
  List<Player> _allPlayers = [];
  List<Player> _availablePlayers = [];
  Map<String, Map<String, dynamic>> _shotAssessmentTypes = {};
  
  // Loading states
  bool _isLoadingTeams = true;
  bool _isLoadingPlayers = true;
  bool _isLoadingAssessments = true;
  String? _loadError;

  // Use AssessmentConfigService like shot files
  late AssessmentConfigService _configService;
  List<AssessmentTemplate> _assessmentTemplates = [];

  @override
  void initState() {
    super.initState();
    _configService = AssessmentConfigService.instance;
    _loadDataFromDatabase();
  }

  // Load data from database with shot file patterns
  Future<void> _loadDataFromDatabase() async {
    try {
      setState(() {
        _isLoadingTeams = true;
        _isLoadingPlayers = true;
        _isLoadingAssessments = true;
        _loadError = null;
      });

      final appState = Provider.of<AppState>(context, listen: false);

      // Load teams, players, and assessments with error recovery
      await Future.wait([
        _loadTeamsWithFallback(appState),
        _loadPlayersWithFallback(appState),
        _loadShotAssessments(),
      ]);

      print('✓ Loaded ${_teams.length} teams, ${_allPlayers.length} players, and ${_shotAssessmentTypes.length} assessment types');
      
      // Auto-select first team if available
      if (_teams.isNotEmpty && _selectedTeam == null) {
        setState(() {
          _selectedTeam = _teams.first;
        });
        _updateAvailablePlayers();
      }

      // Auto-select first assessment type if available
      if (_shotAssessmentTypes.isNotEmpty && !_shotAssessmentTypes.containsKey(_selectedAssessmentType)) {
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
        teams = await appState.api.fetchTeams();
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
        players = await appState.api.fetchPlayers();
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

  // Load shot assessments using AssessmentConfigService like shot files
  Future<void> _loadShotAssessments() async {
    try {
      print('TeamShotSetupView: Loading assessment templates...');
      
      _assessmentTemplates = await _configService.getTemplates();
      print('TeamShotSetupView: Loaded ${_assessmentTemplates.length} templates');

      _shotAssessmentTypes = await _configService.getAssessmentTypesForUI();
      print('TeamShotSetupView: Converted ${_shotAssessmentTypes.length} templates for UI');

      setState(() {
        _isLoadingAssessments = false;
      });
      
      print('✓ Loaded ${_shotAssessmentTypes.length} shot assessment types from configuration service');
      
      // Debug: Print loaded assessment types
      for (final entry in _shotAssessmentTypes.entries) {
        final groups = entry.value['groups'] as List;
        print('  - ${entry.key}: ${groups.length} groups, ${entry.value['totalShots']} total shots');
      }
      
    } catch (e) {
      print('Error loading shot assessments: $e');
      
      _shotAssessmentTypes = _getDefaultAssessmentTypes();
      
      setState(() {
        _isLoadingAssessments = false;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: ResponsiveText('Warning: Using default assessment templates due to loading error', baseFontSize: 14),
            backgroundColor: Colors.orange,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  // Default assessment types that match shot file structure
  Map<String, Map<String, dynamic>> _getDefaultAssessmentTypes() {
    return {
      'accuracy_precision_100': {
        'title': 'Team Accuracy Precision Test (30 min)',
        'description': 'Comprehensive 100-shot directional accuracy assessment with intended zone targeting for teams',
        'category': 'comprehensive',
        'estimatedTime': '30 minutes',
        'estimatedDurationMinutes': 30,
        'totalShots': 100,
        'groups': [
          {
            'id': '0',
            'title': 'Right Side Precision',
            'name': 'Right Side Precision',
            'shots': 25,
            'defaultType': 'Wrist Shot',
            'location': 'Slot',
            'instructions': 'Target the right side of the net. Aim specifically for zones 3, 6, or 9.',
            'allowedShotTypes': ['Wrist Shot', 'Snap Shot'],
            'targetZones': ['3', '6', '9'],
            'intendedZones': ['3', '6', '9'],
            'parameters': {'targetSide': 'east'},
          },
          {
            'id': '1',
            'title': 'Left Side Precision',
            'name': 'Left Side Precision',
            'shots': 25,
            'defaultType': 'Wrist Shot',
            'location': 'Slot',
            'instructions': 'Target the left side of the net. Aim specifically for zones 1, 4, or 7.',
            'allowedShotTypes': ['Wrist Shot', 'Snap Shot'],
            'targetZones': ['1', '4', '7'],
            'intendedZones': ['1', '4', '7'],
            'parameters': {'targetSide': 'west'},
          },
          {
            'id': '2',
            'title': 'Center Line Targeting',
            'name': 'Center Line Targeting',
            'shots': 25,
            'defaultType': 'Wrist Shot',
            'location': 'Slot',
            'instructions': 'Target the center line of the net. Aim specifically for zones 2, 5, or 8.',
            'allowedShotTypes': ['Wrist Shot', 'Snap Shot'],
            'targetZones': ['2', '5', '8'],
            'intendedZones': ['2', '5', '8'],
            'parameters': {'targetSide': 'center'},
          },
          {
            'id': '3',
            'title': 'High Corner Precision',
            'name': 'High Corner Precision',
            'shots': 25,
            'defaultType': 'Wrist Shot',
            'location': 'Slot',
            'instructions': 'Target the top shelf of the net. Aim specifically for zones 1, 2, or 3.',
            'allowedShotTypes': ['Wrist Shot', 'Snap Shot'],
            'targetZones': ['1', '2', '3'],
            'intendedZones': ['1', '2', '3'],
            'parameters': {'targetSide': 'north'},
          },
        ],
        'metadata': {
          'version': '2.0.0',
          'category': 'comprehensive',
          'difficulty': 'intermediate',
        },
      },
      'right_side_precision_mini': {
        'title': 'Team Right Side Precision (Mini)',
        'description': 'Focused 25-shot assessment targeting right side accuracy and consistency for teams',
        'category': 'mini',
        'estimatedTime': '8 minutes',
        'estimatedDurationMinutes': 8,
        'totalShots': 25,
        'groups': [
          {
            'id': '0',
            'title': 'Right Side Precision',
            'name': 'Right Side Precision',
            'shots': 25,
            'defaultType': 'Wrist Shot',
            'location': 'Slot',
            'instructions': 'Target the right side of the net. Aim specifically for zones 3, 6, or 9.',
            'allowedShotTypes': ['Wrist Shot', 'Snap Shot'],
            'targetZones': ['3', '6', '9'],
            'intendedZones': ['3', '6', '9'],
            'parameters': {'targetSide': 'east'},
          },
        ],
        'metadata': {
          'version': '2.0.0',
          'category': 'mini',
          'difficulty': 'beginner',
        },
      },
    };
  }

  // Get filtered assessment types based on selected category
  Map<String, Map<String, dynamic>> getFilteredAssessmentTypes() {
    if (_selectedCategory == 'all' || _shotAssessmentTypes.isEmpty) {
      return _shotAssessmentTypes;
    }
    
    return Map.fromEntries(
      _shotAssessmentTypes.entries.where((entry) {
        final category = entry.value['category'] as String? ?? 'comprehensive';
        return category == _selectedCategory;
      }),
    );
  }

  // Update available players based on team selection and filters
  void _updateAvailablePlayers() {
    setState(() {
      if (_selectedTeam == null) {
        _availablePlayers = List.from(_allPlayers);
      } else {
        _availablePlayers = _allPlayers.where((player) {
          return player.teamId == _selectedTeam!.id || player.teamId == null;
        }).toList();
      }

      // Apply position filter
      if (_filterPosition != 'all') {
        _availablePlayers = _availablePlayers.where((player) {
          return player.position?.toLowerCase().contains(_filterPosition.toLowerCase()) ?? false;
        }).toList();
      }

      // Clear selections that are no longer available
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

  // Mobile Layout: Single column scrollable
  Widget _buildMobileLayout() {
    return SingleChildScrollView(
      padding: ResponsiveConfig.paddingAll(context, 16),
      child: ConstrainedBox(
        constraints: ResponsiveConfig.constraints(context, maxWidth: null),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Category Filter
            _buildSectionHeader('Assessment Category'),
            ResponsiveSpacing(multiplier: 1.5),
            _buildCategorySelector(),
            
            ResponsiveSpacing(multiplier: 3),
            
            // Assessment Type Selection
            _buildSectionHeader('Select Assessment Type'),
            ResponsiveSpacing(multiplier: 1.5),
            AssessmentTypeSelector.forShotAssessment(
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
            
            // Team Selection
            _buildSectionHeader('Select Team (Optional)'),
            ResponsiveSpacing(multiplier: 1),
            ResponsiveText(
              'Choose a team to filter players, or select "No Team" to include all players',
              baseFontSize: 14,
              style: TextStyle(
                color: Colors.blueGrey[600],
                fontStyle: FontStyle.italic,
              ),
            ),
            ResponsiveSpacing(multiplier: 1.5),
            _buildTeamSelector(),
            
            ResponsiveSpacing(multiplier: 3),
            
            // Position Filter
            _buildSectionHeader('Filter by Position'),
            ResponsiveSpacing(multiplier: 1.5),
            _buildPositionSelector(),
            
            ResponsiveSpacing(multiplier: 3),
            
            // Player Selection
            _buildSectionHeader('Select Players'),
            ResponsiveSpacing(multiplier: 1.5),
            _buildPlayerSelectionList(),
            
            ResponsiveSpacing(multiplier: 3),
            
            // Assessment Preview (Simplified for mobile)
            _buildMobileAssessmentPreview(),
            
            ResponsiveSpacing(multiplier: 3),
            
            // Start Button
            _buildStartButton(),
          ],
        ),
      ),
    );
  }

  // Tablet Layout: Two-column (Configuration | Preview)
  Widget _buildTabletLayout() {
    return Padding(
      padding: ResponsiveConfig.paddingAll(context, 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Left Column: Configuration (60%)
          Expanded(
            flex: 6,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Category Filter
                  _buildSectionHeader('Assessment Category'),
                  ResponsiveSpacing(multiplier: 1.5),
                  _buildCategorySelector(),
                  
                  ResponsiveSpacing(multiplier: 3),
                  
                  // Assessment Type Selection
                  _buildSectionHeader('Select Assessment Type'),
                  ResponsiveSpacing(multiplier: 1.5),
                  AssessmentTypeSelector.forShotAssessment(
                    selectedType: _selectedAssessmentType,
                    onTypeSelected: (type) {
                      setState(() {
                        _selectedAssessmentType = type;
                      });
                    },
                    assessmentTypes: getFilteredAssessmentTypes(),
                    displayStyle: 'list',
                  ),
                  
                  ResponsiveSpacing(multiplier: 3),
                  
                  // Team & Player Selection
                  _buildTabletTeamPlayerSection(),
                ],
              ),
            ),
          ),
          
          ResponsiveSpacing(multiplier: 3, direction: Axis.horizontal),
          
          // Right Column: Preview & Actions (40%)
          Expanded(
            flex: 4,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildAssessmentPreview(),
                  ResponsiveSpacing(multiplier: 3),
                  _buildStartButton(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Desktop Layout: Three-section with enhanced sidebar
  Widget _buildDesktopLayout() {
    return Padding(
      padding: ResponsiveConfig.paddingAll(context, 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Left Sidebar: Quick Setup (22%)
          Container(
            width: 280,
            child: SingleChildScrollView(
              child: _buildDesktopQuickSetup(),
            ),
          ),
          
          ResponsiveSpacing(multiplier: 3, direction: Axis.horizontal),
          
          // Main Content: Configuration (50%)
          Expanded(
            flex: 5,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Assessment Configuration
                  _buildDesktopAssessmentConfig(),
                  
                  ResponsiveSpacing(multiplier: 4),
                  
                  // Team & Player Management
                  _buildDesktopTeamPlayerConfig(),
                ],
              ),
            ),
          ),
          
          ResponsiveSpacing(multiplier: 3, direction: Axis.horizontal),
          
          // Right Sidebar: Preview & Advanced (30%)
          Container(
            width: 320,
            child: SingleChildScrollView(
              child: _buildDesktopPreviewSidebar(),
            ),
          ),
        ],
      ),
    );
  }

  // Desktop quick setup sidebar
  Widget _buildDesktopQuickSetup() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildQuickSetupCard(),
        ResponsiveSpacing(multiplier: 2),
        _buildRecentAssessmentsCard(),
        ResponsiveSpacing(multiplier: 2),
        _buildQuickTemplatesCard(),
      ],
    );
  }

  Widget _buildQuickSetupCard() {
    return ResponsiveCard(
      padding: ResponsiveConfig.paddingAll(context, 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.flash_on, color: Colors.orange[600]),
              ResponsiveSpacing(multiplier: 1, direction: Axis.horizontal),
              ResponsiveText(
                'Quick Setup',
                baseFontSize: 16,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.blueGrey[800],
                ),
              ),
            ],
          ),
          ResponsiveSpacing(multiplier: 1.5),
          
          ListTile(
            dense: true,
            leading: Icon(Icons.speed, color: Colors.green[600]),
            title: ResponsiveText('Quick Assessment', baseFontSize: 14),
            subtitle: ResponsiveText('Basic 25-shot test', baseFontSize: 12),
            onTap: () => _setQuickAssessment('quick'),
          ),
          
          ListTile(
            dense: true,
            leading: Icon(Icons.assessment, color: Colors.blue[600]),
            title: ResponsiveText('Comprehensive', baseFontSize: 14),
            subtitle: ResponsiveText('Full 100-shot analysis', baseFontSize: 12),
            onTap: () => _setQuickAssessment('comprehensive'),
          ),
          
          ListTile(
            dense: true,
            leading: Icon(Icons.center_focus_strong, color: Colors.purple[600]),
            title: ResponsiveText('Mini Assessment', baseFontSize: 14),
            subtitle: ResponsiveText('Focused skill test', baseFontSize: 12),
            onTap: () => _setQuickAssessment('mini'),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentAssessmentsCard() {
    return ResponsiveCard(
      padding: ResponsiveConfig.paddingAll(context, 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.history, color: Colors.grey[600]),
              ResponsiveSpacing(multiplier: 1, direction: Axis.horizontal),
              ResponsiveText(
                'Recent Settings',
                baseFontSize: 16,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.blueGrey[800],
                ),
              ),
            ],
          ),
          ResponsiveSpacing(multiplier: 1.5),
          
          Container(
            padding: ResponsiveConfig.paddingAll(context, 12),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: ResponsiveConfig.borderRadius(context, 8),
            ),
            child: ResponsiveText(
              'Recent assessment configurations will appear here',
              baseFontSize: 12,
              style: TextStyle(
                color: Colors.grey[600],
                fontStyle: FontStyle.italic,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickTemplatesCard() {
    final quickTemplates = [
      {'name': 'Beginner Team', 'category': 'mini', 'players': 6},
      {'name': 'Advanced Team', 'category': 'comprehensive', 'players': 12},
      {'name': 'Skill Development', 'category': 'quick', 'players': 8},
    ];

    return ResponsiveCard(
      padding: ResponsiveConfig.paddingAll(context, 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.description_outlined, color: Colors.teal[600]),
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
          
          ...quickTemplates.map((template) {
            return Container(
              margin: ResponsiveConfig.paddingSymmetric(context, vertical: 4),
              child: ListTile(
                dense: true,
                title: ResponsiveText(
                  template['name'] as String,
                  baseFontSize: 12,
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
                subtitle: ResponsiveText(
                  '${template['category']} • ${template['players']} players',
                  baseFontSize: 10,
                  style: TextStyle(color: Colors.grey[600]),
                ),
                onTap: () => _applyTemplate(template),
                contentPadding: ResponsiveConfig.paddingSymmetric(context, horizontal: 8, vertical: 2),
              ),
            );
          }).toList(),
        ],
      ),
    );
  }

  // Desktop assessment configuration
  Widget _buildDesktopAssessmentConfig() {
    return ResponsiveCard(
      padding: ResponsiveConfig.paddingAll(context, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.assessment, color: Colors.blue[700]),
              ResponsiveSpacing(multiplier: 1.5, direction: Axis.horizontal),
              ResponsiveText(
                'Assessment Configuration',
                baseFontSize: 20,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.blueGrey[800],
                ),
              ),
            ],
          ),
          ResponsiveSpacing(multiplier: 3),
          
          // Category Filter
          ResponsiveText(
            'Assessment Category',
            baseFontSize: 16,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.blueGrey[700],
            ),
          ),
          ResponsiveSpacing(multiplier: 1.5),
          _buildCategorySelector(),
          
          ResponsiveSpacing(multiplier: 3),
          
          // Assessment Type
          ResponsiveText(
            'Assessment Type',
            baseFontSize: 16,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.blueGrey[700],
            ),
          ),
          ResponsiveSpacing(multiplier: 1.5),
          AssessmentTypeSelector.forShotAssessment(
            selectedType: _selectedAssessmentType,
            onTypeSelected: (type) {
              setState(() {
                _selectedAssessmentType = type;
              });
            },
            assessmentTypes: getFilteredAssessmentTypes(),
            displayStyle: 'grid',
          ),
        ],
      ),
    );
  }

  // Desktop team & player configuration
  Widget _buildDesktopTeamPlayerConfig() {
    return ResponsiveCard(
      padding: ResponsiveConfig.paddingAll(context, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.groups, color: Colors.green[700]),
              ResponsiveSpacing(multiplier: 1.5, direction: Axis.horizontal),
              ResponsiveText(
                'Team & Player Selection',
                baseFontSize: 20,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.blueGrey[800],
                ),
              ),
            ],
          ),
          ResponsiveSpacing(multiplier: 3),
          
          // Team Selection
          ResponsiveText(
            'Team Selection (Optional)',
            baseFontSize: 16,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.blueGrey[700],
            ),
          ),
          ResponsiveSpacing(multiplier: 1),
          ResponsiveText(
            'Choose a team to filter players, or select "No Team" to include all players',
            baseFontSize: 14,
            style: TextStyle(
              color: Colors.blueGrey[600],
              fontStyle: FontStyle.italic,
            ),
          ),
          ResponsiveSpacing(multiplier: 1.5),
          _buildTeamSelector(),
          
          ResponsiveSpacing(multiplier: 3),
          
          // Position Filter
          ResponsiveText(
            'Position Filter',
            baseFontSize: 16,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.blueGrey[700],
            ),
          ),
          ResponsiveSpacing(multiplier: 1.5),
          _buildPositionSelector(),
          
          ResponsiveSpacing(multiplier: 3),
          
          // Player Selection
          ResponsiveText(
            'Player Selection',
            baseFontSize: 16,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.blueGrey[700],
            ),
          ),
          ResponsiveSpacing(multiplier: 1.5),
          _buildPlayerSelectionList(),
        ],
      ),
    );
  }

  // Desktop preview sidebar
  Widget _buildDesktopPreviewSidebar() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildAssessmentPreview(),
        ResponsiveSpacing(multiplier: 2),
        _buildAdvancedOptionsCard(),
        ResponsiveSpacing(multiplier: 2),
        _buildStartButton(),
      ],
    );
  }

  Widget _buildAdvancedOptionsCard() {
    return ResponsiveCard(
      padding: ResponsiveConfig.paddingAll(context, 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.settings, color: Colors.purple[600]),
              ResponsiveSpacing(multiplier: 1, direction: Axis.horizontal),
              ResponsiveText(
                'Advanced Options',
                baseFontSize: 16,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.blueGrey[800],
                ),
              ),
            ],
          ),
          ResponsiveSpacing(multiplier: 1.5),
          
          CheckboxListTile(
            dense: true,
            title: ResponsiveText('Video Recording', baseFontSize: 14),
            subtitle: ResponsiveText('Record assessment for analysis', baseFontSize: 12),
            value: false,
            onChanged: (value) {
              // Placeholder for video recording option
            },
          ),
          
          CheckboxListTile(
            dense: true,
            title: ResponsiveText('Real-time Analytics', baseFontSize: 14),
            subtitle: ResponsiveText('Show live performance metrics', baseFontSize: 12),
            value: true,
            onChanged: (value) {
              // Placeholder for real-time analytics option
            },
          ),
          
          CheckboxListTile(
            dense: true,
            title: ResponsiveText('Auto-save Results', baseFontSize: 14),
            subtitle: ResponsiveText('Automatically save to database', baseFontSize: 12),
            value: true,
            onChanged: (value) {
              // Placeholder for auto-save option
            },
          ),
        ],
      ),
    );
  }

  // Tablet team & player section
  Widget _buildTabletTeamPlayerSection() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Team Selection
        _buildSectionHeader('Select Team (Optional)'),
        ResponsiveSpacing(multiplier: 1),
        ResponsiveText(
          'Choose a team to filter players',
          baseFontSize: 14,
          style: TextStyle(
            color: Colors.blueGrey[600],
            fontStyle: FontStyle.italic,
          ),
        ),
        ResponsiveSpacing(multiplier: 1.5),
        _buildTeamSelector(),
        
        ResponsiveSpacing(multiplier: 3),
        
        // Position Filter & Player Selection in columns
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Position Filter (30%)
            Expanded(
              flex: 3,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionHeader('Position Filter'),
                  ResponsiveSpacing(multiplier: 1.5),
                  _buildPositionSelector(),
                ],
              ),
            ),
          ],
        ),
        
        ResponsiveSpacing(multiplier: 3),
        
        // Player Selection
        _buildSectionHeader('Select Players'),
        ResponsiveSpacing(multiplier: 1.5),
        _buildPlayerSelectionList(),
      ],
    );
  }

  Widget _buildLoadingState() {
    final List<String> loadingItems = [];
    if (_isLoadingTeams) loadingItems.add('teams');
    if (_isLoadingPlayers) loadingItems.add('players');
    if (_isLoadingAssessments) loadingItems.add('assessments');

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
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
            'Please wait while we prepare your assessment options',
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

  // Custom team selector that includes "No Team" option
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
          // "No Team" option
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
          // Team options
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

  Widget _buildSectionHeader(String title) {
    return AdaptiveLayout(
      builder: (deviceType, isLandscape) {
        final fontSize = deviceType.responsive<double>(
          mobile: 16,
          tablet: 18,
          desktop: 18,
        );
        
        return ResponsiveText(
          title,
          baseFontSize: fontSize,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.blueGrey[800],
          ),
        );
      },
    );
  }

  Widget _buildCategorySelector() {
    final categories = [
      {'value': 'all', 'label': 'All', 'icon': Icons.list, 'color': Colors.blueGrey},
      {'value': 'comprehensive', 'label': 'Comprehensive', 'icon': Icons.assessment, 'color': Colors.blue},
      {'value': 'quick', 'label': 'Quick', 'icon': Icons.timer, 'color': Colors.green},
      {'value': 'mini', 'label': 'Mini/Focused', 'icon': Icons.center_focus_strong, 'color': Colors.orange},
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
            padding: ResponsiveConfig.paddingSymmetric(
              context, 
              vertical: 6, 
              horizontal: 10
            ),
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
                  size: ResponsiveConfig.iconSize(context, 14),
                ),
                ResponsiveSpacing(multiplier: 0.75, direction: Axis.horizontal),
                ResponsiveText(
                  category['label'] as String,
                  baseFontSize: 11,
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
          if (_allPlayers.isEmpty) ...[
            ResponsiveSpacing(multiplier: 2),
            ResponsiveButton(
              text: 'Add Players',
              onPressed: () {
                Navigator.pushNamed(context, '/players/add');
              },
              baseHeight: 48,
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
              icon: Icons.person_add,
            ),
          ],
        ],
      );
    }

    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: ResponsiveConfig.borderRadius(context, 8),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header
          Container(
            padding: ResponsiveConfig.paddingSymmetric(context, horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(ResponsiveConfig.dimension(context, 7)),
                topRight: Radius.circular(ResponsiveConfig.dimension(context, 7)),
              ),
            ),
            child: AdaptiveLayout(
              builder: (deviceType, isLandscape) {
                if (deviceType == DeviceType.mobile) {
                  return Row(
                    children: [
                      Expanded(
                        child: ResponsiveText(
                          'Players',
                          baseFontSize: 14,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.blueGrey[800],
                          ),
                        ),
                      ),
                      ResponsiveSpacing(multiplier: 1, direction: Axis.horizontal),
                      Checkbox(
                        value: _isAllPlayersSelected(_availablePlayers),
                        onChanged: (value) => _toggleAllPlayers(value, _availablePlayers),
                        activeColor: Colors.cyanAccent[700],
                      ),
                    ],
                  );
                } else {
                  return Row(
                    children: [
                      Expanded(
                        flex: 1,
                        child: ResponsiveText(
                          '#',
                          baseFontSize: 14,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.blueGrey[800],
                          ),
                        ),
                      ),
                      Expanded(
                        flex: 3,
                        child: ResponsiveText(
                          'Player',
                          baseFontSize: 14,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.blueGrey[800],
                          ),
                        ),
                      ),
                      Expanded(
                        flex: 2,
                        child: ResponsiveText(
                          'Position',
                          baseFontSize: 14,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.blueGrey[800],
                          ),
                        ),
                      ),
                      Expanded(
                        flex: 2,
                        child: ResponsiveText(
                          'Team',
                          baseFontSize: 14,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.blueGrey[800],
                          ),
                        ),
                      ),
                      ResponsiveSpacing(multiplier: 1, direction: Axis.horizontal),
                      Checkbox(
                        value: _isAllPlayersSelected(_availablePlayers),
                        onChanged: (value) => _toggleAllPlayers(value, _availablePlayers),
                        activeColor: Colors.cyanAccent[700],
                      ),
                    ],
                  );
                }
              },
            ),
          ),
          
          // Player List
          ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: ResponsiveConfig.dimension(context, 300),
            ),
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: _availablePlayers.length,
              itemBuilder: (context, index) {
                final player = _availablePlayers[index];
                final isSelected = _isPlayerSelected(player);
                final playerTeam = player.teamId != null 
                    ? _teams.firstWhere((t) => t.id == player.teamId, orElse: () => Team(id: -1, name: 'Unknown Team'))
                    : null;
                
                return Container(
                  decoration: BoxDecoration(
                    border: Border(
                      top: BorderSide(color: Colors.grey[300]!),
                    ),
                    color: index % 2 == 0 ? Colors.white : Colors.grey[50],
                  ),
                  child: AdaptiveLayout(
                    builder: (deviceType, isLandscape) {
                      if (deviceType == DeviceType.mobile) {
                        return ListTile(
                          dense: true,
                          leading: CircleAvatar(
                            radius: 16,
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
                          title: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              ResponsiveText(
                                player.name,
                                baseFontSize: 14,
                                style: TextStyle(
                                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                ),
                              ),
                              ResponsiveText(
                                '${player.position ?? 'Unknown'} • ${playerTeam?.name ?? 'No Team'}',
                                baseFontSize: 12,
                                style: TextStyle(color: Colors.grey[600]),
                              ),
                            ],
                          ),
                          trailing: Checkbox(
                            value: isSelected,
                            onChanged: (value) => _togglePlayerSelection(player),
                            activeColor: Colors.cyanAccent[700],
                          ),
                          onTap: () => _togglePlayerSelection(player),
                        );
                      } else {
                        return ListTile(
                          dense: true,
                          leading: CircleAvatar(
                            radius: 16,
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
                        );
                      }
                    },
                  ),
                );
              },
            ),
          ),
          
          // Footer
          Container(
            padding: ResponsiveConfig.paddingSymmetric(context, horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(ResponsiveConfig.dimension(context, 7)),
                bottomRight: Radius.circular(ResponsiveConfig.dimension(context, 7)),
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
                      child: ResponsiveText('Clear All', baseFontSize: 12),
                    ),
                    ResponsiveSpacing(multiplier: 1, direction: Axis.horizontal),
                    TextButton(
                      onPressed: _availablePlayers.isNotEmpty ? () => _selectAllPlayers(_availablePlayers) : null,
                      child: ResponsiveText('Select All', baseFontSize: 12),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Mobile assessment preview (simplified)
  Widget _buildMobileAssessmentPreview() {
    final filteredTypes = getFilteredAssessmentTypes();
    if (!filteredTypes.containsKey(_selectedAssessmentType)) {
      return Container();
    }
    
    final assessmentData = filteredTypes[_selectedAssessmentType] ?? {};
    final groups = assessmentData['groups'] as List? ?? [];
    int totalShots = 0;
    for (var group in groups) {
      totalShots += group['shots'] as int? ?? 0;
    }

    return ResponsiveCard(
      padding: ResponsiveConfig.paddingAll(context, 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.preview, color: Colors.blue[600]),
              ResponsiveSpacing(multiplier: 1, direction: Axis.horizontal),
              ResponsiveText(
                'Assessment Summary',
                baseFontSize: 16,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.blueGrey[800],
                ),
              ),
            ],
          ),
          ResponsiveSpacing(multiplier: 1.5),
          
          _buildPreviewInfoRow('Type', assessmentData['title'] as String? ?? 'Unknown'),
          _buildPreviewInfoRow('Players', '${_selectedPlayers.length}'),
          _buildPreviewInfoRow('Total Shots', '${totalShots * _selectedPlayers.length}'),
          _buildPreviewInfoRow('Est. Time', assessmentData['estimatedTime'] as String? ?? 'Unknown'),
        ],
      ),
    );
  }

  Widget _buildAssessmentPreview() {
    final filteredTypes = getFilteredAssessmentTypes();
    if (!filteredTypes.containsKey(_selectedAssessmentType)) {
      return Container();
    }
    
    final assessmentData = filteredTypes[_selectedAssessmentType] ?? {};
    final groups = assessmentData['groups'] as List? ?? [];
    int totalShots = 0;
    for (var group in groups) {
      totalShots += group['shots'] as int? ?? 0;
    }

    // Get category color
    final category = assessmentData['category'] as String? ?? 'comprehensive';
    Color categoryColor = Colors.blueGrey;
    switch (category) {
      case 'comprehensive':
        categoryColor = Colors.blue;
        break;
      case 'quick':
        categoryColor = Colors.green;
        break;
      case 'mini':
        categoryColor = Colors.orange;
        break;
    }

    return Container(
      padding: ResponsiveConfig.paddingAll(context, 20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.blueGrey[50]!, categoryColor.withOpacity(0.1)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: ResponsiveConfig.borderRadius(context, 12),
        border: Border.all(color: categoryColor.withOpacity(0.3)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.preview, color: categoryColor),
              ResponsiveSpacing(multiplier: 1.5, direction: Axis.horizontal),
              ResponsiveText(
                'Assessment Preview',
                baseFontSize: 18,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.blueGrey[800],
                ),
              ),
              const Spacer(),
              Container(
                padding: ResponsiveConfig.paddingSymmetric(context, horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: categoryColor,
                  borderRadius: ResponsiveConfig.borderRadius(context, 12),
                ),
                child: ResponsiveText(
                  category.toUpperCase(),
                  baseFontSize: 10,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          ResponsiveSpacing(multiplier: 2),
          
          // Assessment Info
          _buildPreviewInfoRow('Type', assessmentData['title'] as String? ?? 'Unknown'),
          _buildPreviewInfoRow('Estimated Time', assessmentData['estimatedTime'] as String? ?? 'Unknown'),
          _buildPreviewInfoRow('Team', _selectedTeam?.name ?? 'Multiple/No Team'),
          _buildPreviewInfoRow('Selected Players', '${_selectedPlayers.length}'),
          _buildPreviewInfoRow('Shots per Player', '$totalShots'),
          _buildPreviewInfoRow('Total Shots', '${totalShots * _selectedPlayers.length}'),
          
          ResponsiveSpacing(multiplier: 2),
          
          ResponsiveText(
            assessmentData['description'] as String? ?? 'No description available',
            baseFontSize: 14,
            style: TextStyle(
              color: Colors.blueGrey[600],
              fontStyle: FontStyle.italic,
            ),
          ),
          
          // Show groups on tablet/desktop
          AdaptiveLayout(
            builder: (deviceType, isLandscape) {
              if (deviceType == DeviceType.mobile) {
                return Container();
              }
              
              return Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ResponsiveSpacing(multiplier: 2.5),
                  
                  ResponsiveText(
                    'Assessment Groups:',
                    baseFontSize: 16,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.blueGrey[700],
                    ),
                  ),
                  ResponsiveSpacing(multiplier: 1.5),
                  
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      for (int i = 0; i < groups.length; i++)
                        Container(
                          margin: ResponsiveConfig.paddingSymmetric(context, vertical: 6),
                          padding: ResponsiveConfig.paddingAll(context, 12),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.8),
                            borderRadius: ResponsiveConfig.borderRadius(context, 8),
                            border: Border.all(color: categoryColor.withOpacity(0.3)),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                width: ResponsiveConfig.dimension(context, 28),
                                height: ResponsiveConfig.dimension(context, 28),
                                decoration: BoxDecoration(
                                  color: categoryColor,
                                  shape: BoxShape.circle,
                                ),
                                child: Center(
                                  child: ResponsiveText(
                                    '${i + 1}',
                                    baseFontSize: 12,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ),
                              ResponsiveSpacing(multiplier: 1.5, direction: Axis.horizontal),
                              Expanded(
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    ResponsiveText(
                                      groups[i]['title'] as String? ?? 
                                      groups[i]['name'] as String? ?? 
                                      'Untitled Group',
                                      baseFontSize: 14,
                                      style: const TextStyle(fontWeight: FontWeight.bold),
                                    ),
                                    ResponsiveSpacing(multiplier: 0.5),
                                    ResponsiveText(
                                      '${groups[i]['shots'] as int? ?? 0} shots • ${groups[i]['location'] as String? ?? 'Location TBD'}',
                                      baseFontSize: 12,
                                      style: TextStyle(color: Colors.blueGrey[600]),
                                    ),
                                    // Show target zones if available
                                    if (groups[i]['intendedZones'] != null || groups[i]['targetZones'] != null)
                                      ResponsiveText(
                                        'Target: ${(groups[i]['intendedZones'] ?? groups[i]['targetZones'] as List).join(', ')}',
                                        baseFontSize: 10,
                                        style: TextStyle(
                                          color: Colors.green[600],
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildPreviewInfoRow(String label, String value) {
    return Padding(
      padding: ResponsiveConfig.paddingSymmetric(context, vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          ResponsiveText(
            label,
            baseFontSize: 14,
            style: TextStyle(
              fontWeight: FontWeight.w500,
              color: Colors.blueGrey[700],
            ),
          ),
          ResponsiveText(
            value,
            baseFontSize: 14,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.blueGrey[800],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStartButton() {
    final canStart = _selectedPlayers.isNotEmpty;
    final filteredTypes = getFilteredAssessmentTypes();
    
    if (!filteredTypes.containsKey(_selectedAssessmentType)) {
      return Container();
    }
    
    final assessmentData = filteredTypes[_selectedAssessmentType] ?? {};
    final groups = assessmentData['groups'] as List? ?? [];
    int totalShots = 0;
    for (var group in groups) {
      totalShots += group['shots'] as int? ?? 0;
    }

    return AdaptiveLayout(
      builder: (deviceType, isLandscape) {
        final buttonHeight = deviceType.responsive<double>(
          mobile: 48,
          tablet: 56,
          desktop: 56,
        );
        
        final fontSize = deviceType.responsive<double>(
          mobile: 14,
          tablet: 16,
          desktop: 16,
        );
        
        final iconSize = deviceType.responsive<double>(
          mobile: 20,
          tablet: 24,
          desktop: 24,
        );

        return ResponsiveButton(
          text: canStart 
            ? (deviceType == DeviceType.mobile
              ? 'Start Assessment'
              : 'Start Team Assessment (${totalShots * _selectedPlayers.length} total shots)')
            : 'Please select players',
          onPressed: canStart ? _startAssessment : null,
          baseHeight: buttonHeight,
          width: double.infinity,
          backgroundColor: canStart ? Colors.cyanAccent[700] : Colors.grey[400],
          foregroundColor: Colors.white,
          icon: canStart ? Icons.play_arrow : Icons.block,
          style: TextStyle(
            fontSize: fontSize,
            fontWeight: FontWeight.bold,
          ),
        );
      },
    );
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
            (selectedPlayer) => players.any((player) => player.id == selectedPlayer.id));
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

  // Enhanced validation and assessment creation like shot files
  void _startAssessment() {
    if (_selectedPlayers.isEmpty) {
      DialogService.showError(
        context,
        title: 'No Players Selected',
        message: 'Please select players from the list before starting the team assessment.',
      );
      return;
    }

    // Validate that all players have valid IDs
    for (var player in _selectedPlayers) {
      if (player.id == null) {
        DialogService.showError(
          context,
          title: 'Invalid Player Data',
          message: 'Player "${player.name}" has an invalid ID. Please refresh the player list or contact support.',
        );
        return;
      }
    }

    if (_selectedAssessmentType.isEmpty || !getFilteredAssessmentTypes().containsKey(_selectedAssessmentType)) {
      DialogService.showError(
        context,
        title: 'No Assessment Type Selected',
        message: 'Please select an assessment type before starting.',
      );
      return;
    }

    final appState = Provider.of<AppState>(context, listen: false);
    final assessmentTypeData = getFilteredAssessmentTypes()[_selectedAssessmentType]!;

    // Generate assessment ID and track it like shot files
    final existingAssessmentId = appState.getCurrentAssessmentId();
    final assessmentId = existingAssessmentId ?? DateTime.now().millisecondsSinceEpoch.toString();

    // Calculate total shots for the assessment
    final groups = assessmentTypeData['groups'] as List<dynamic>;
    final totalShots = groups.fold<int>(0, (sum, group) => sum + (group['shots'] as int? ?? 0));

    // Create the assessment object with proper structure like shot files
    final assessment = {
      'type': _selectedAssessmentType,
      'id': assessmentTypeData['id'] ?? _selectedAssessmentType,
      'title': assessmentTypeData['title'],
      'description': assessmentTypeData['description'],
      'category': assessmentTypeData['category'],
      'estimatedTime': assessmentTypeData['estimatedTime'],
      'estimatedDurationMinutes': assessmentTypeData['estimatedDurationMinutes'],
      'teamName': _selectedTeam?.name ?? 'Mixed Team',
      'teamId': _selectedTeam?.id ?? -1,
      
      'timestamp': DateTime.now().toIso8601String(),
      'assessmentId': assessmentId,
      'groups': assessmentTypeData['groups'],
      'playerCount': _selectedPlayers.length,
      'totalShots': assessmentTypeData['totalShots'] ?? totalShots,
      'metadata': assessmentTypeData['metadata'] ?? {},
      'version': assessmentTypeData['version'] ?? '1.0.0',
      'configVersion': '2.0.0',
    };
    
    print('Starting team assessment with data: $assessment');
    print('Assessment ID: ${assessment['assessmentId']}');
    print('Groups count: ${(assessment['groups'] as List).length}');
    print('Total shots: ${assessment['totalShots']}');
    print('Selected players: ${_selectedPlayers.map((p) => '${p.name} (#${p.jerseyNumber}) - ${p.teamId != null ? _teams.firstWhere((t) => t.id == p.teamId, orElse: () => Team(id: -1, name: 'Unknown')).name : 'No Team'}').join(', ')}');
    
    // Verify groups have required structure
    final groupList = assessment['groups'] as List;
    for (int i = 0; i < groupList.length; i++) {
      final group = groupList[i] as Map<String, dynamic>;
      print('  Group $i: ${group['title'] ?? group['name']} - ${group['shots']} shots, target zones: ${group['intendedZones'] ?? group['targetZones']}');
    }
    
    // Enhanced confirmation dialog like shot files
    DialogService.showConfirmation(
      context,
      title: 'Start Team Assessment?',
      message: '''Assessment: ${assessment['title']}
Team: ${assessment['teamName']}
Players: ${_selectedPlayers.length}
Total Shots: ${totalShots * _selectedPlayers.length} (${totalShots} per player)
Estimated time: ${assessment['estimatedTime']}

Assessment ID: ${assessmentId.substring(assessmentId.length - 6)}

Ready to begin?''',
      confirmLabel: 'Start Assessment',
      cancelLabel: 'Cancel',
    ).then((confirmed) {
      if (confirmed == true) {
        print('TeamShotSetupView: Starting team assessment');
        print('TeamShotSetupView: Assessment ID: $assessmentId');
        
        appState.setCurrentAssessmentId(assessmentId);
        
        widget.onStart(assessment, _selectedPlayers);
      }
    });
  }

  // Desktop-only helper methods
  void _setQuickAssessment(String category) {
    setState(() {
      _selectedCategory = category;
      final filtered = getFilteredAssessmentTypes();
      if (filtered.isNotEmpty) {
        _selectedAssessmentType = filtered.keys.first;
      }
    });
  }

  void _applyTemplate(Map<String, dynamic> template) {
    setState(() {
      _selectedCategory = template['category'] as String;
      final filtered = getFilteredAssessmentTypes();
      if (filtered.isNotEmpty) {
        _selectedAssessmentType = filtered.keys.first;
      }
    });
  }
}

extension StringExtension on String {
  String capitalize() {
    return "${this[0].toUpperCase()}${substring(1).toLowerCase()}";
  }
}