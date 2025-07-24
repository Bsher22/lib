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
import 'package:hockey_shot_tracker/services/infrastructure/api_service_factory.dart';
import 'package:hockey_shot_tracker/widgets/domain/assessment/common/assessment_type_selector.dart';
import 'package:hockey_shot_tracker/widgets/domain/team/team_selector_widget.dart';
import 'package:hockey_shot_tracker/widgets/core/state/index.dart';
import 'package:hockey_shot_tracker/services/dialog_service.dart';
import 'package:hockey_shot_tracker/responsive_system/index.dart';

class TeamShotSetupView extends StatefulWidget {
  final Function(Map<String, dynamic>, List<Player>) onStart; // Updated to pass assessment object

  const TeamShotSetupView({
    Key? key,
    required this.onStart,
  }) : super(key: key);

  @override
  _TeamShotSetupViewState createState() => _TeamShotSetupViewState();
}

class _TeamShotSetupViewState extends State<TeamShotSetupView> {
  String _selectedAssessmentType = 'Comprehensive';
  String _selectedCategory = 'all'; // New filter for assessment categories
  Team? _selectedTeam;
  String _filterPosition = 'all';
  List<Player> _selectedPlayers = [];

  // Database-loaded data
  List<Team> _teams = [];
  List<Player> _allPlayers = []; // All players in the system
  List<Player> _availablePlayers = []; // Filtered players for selection
  Map<String, Map<String, dynamic>> _shotAssessmentTypes = {}; // Loaded from JSON
  
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
        _loadShotAssessments(), // Use shot file pattern
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
      
      // Strategy 1: Use the correct API method name
      try {
        teams = await ApiServiceFactory.team.fetchTeams();
        print('✓ Loaded teams using fetchTeams()');
      } catch (e) {
        print('Warning: fetchTeams() failed: $e');
        
        // Strategy 2: Use appState if already loaded
        if (appState.teams.isNotEmpty) {
          teams = appState.teams;
          print('✓ Using teams from appState cache');
        } else {
          // Strategy 3: Create empty list
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
      
      // Strategy 1: Use the correct API method name
      try {
        players = await ApiServiceFactory.player.fetchPlayers();
        print('✓ Loaded players using fetchPlayers()');
      } catch (e) {
        print('Warning: fetchPlayers() failed: $e');
        
        // Strategy 2: Use appState if already loaded
        if (appState.players.isNotEmpty) {
          players = appState.players;
          print('✓ Using players from appState cache');
        } else {
          // Strategy 3: Create empty list
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
      
      // Load templates from configuration service
      _assessmentTemplates = await _configService.getTemplates();
      print('TeamShotSetupView: Loaded ${_assessmentTemplates.length} templates');

      // Convert templates to UI format like shot files
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
      
      // Fallback to default templates like shot files
      _shotAssessmentTypes = _getDefaultAssessmentTypes();
      
      setState(() {
        _isLoadingAssessments = false;
      });
      
      // Show error but don't fail completely
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Warning: Using default assessment templates due to loading error'),
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
            'name': 'Right Side Precision', // Ensure both title and name
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
        // Show all players if no team selected
        _availablePlayers = List.from(_allPlayers);
      } else {
        // Show players from selected team + players without teams
        _availablePlayers = _allPlayers.where((player) {
          // Include players from the selected team OR players with no team
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

    return context.responsive<Widget>(
      mobile: _buildMobileLayout(),
      tablet: _buildTabletLayout(),
      desktop: _buildDesktopLayout(),
    );
  }

  // Mobile Layout: Single column scrollable
  Widget _buildMobileLayout() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Category Filter
          _buildSectionHeader('Assessment Category'),
          const SizedBox(height: 12),
          _buildCategorySelector(),
          
          const SizedBox(height: 24),
          
          // Assessment Type Selection
          _buildSectionHeader('Select Assessment Type'),
          const SizedBox(height: 12),
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
          
          const SizedBox(height: 24),
          
          // Team Selection
          _buildSectionHeader('Select Team (Optional)'),
          const SizedBox(height: 8),
          Text(
            'Choose a team to filter players, or select "No Team" to include all players',
            style: TextStyle(
              fontSize: 14,
              color: Colors.blueGrey[600],
              fontStyle: FontStyle.italic,
            ),
          ),
          const SizedBox(height: 12),
          _buildTeamSelector(),
          
          const SizedBox(height: 24),
          
          // Position Filter
          _buildSectionHeader('Filter by Position'),
          const SizedBox(height: 12),
          _buildPositionSelector(),
          
          const SizedBox(height: 24),
          
          // Player Selection
          _buildSectionHeader('Select Players'),
          const SizedBox(height: 12),
          _buildPlayerSelectionList(),
          
          const SizedBox(height: 24),
          
          // Assessment Preview (Simplified for mobile)
          _buildMobileAssessmentPreview(),
          
          const SizedBox(height: 24),
          
          // Start Button
          _buildStartButton(),
        ],
      ),
    );
  }

  // Tablet Layout: Two-column (Configuration | Preview)
  Widget _buildTabletLayout() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Left Column: Configuration (60%)
          Expanded(
            flex: 6,
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Category Filter
                  _buildSectionHeader('Assessment Category'),
                  const SizedBox(height: 12),
                  _buildCategorySelector(),
                  
                  const SizedBox(height: 24),
                  
                  // Assessment Type Selection
                  _buildSectionHeader('Select Assessment Type'),
                  const SizedBox(height: 12),
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
                  
                  const SizedBox(height: 24),
                  
                  // Team & Player Selection
                  _buildTabletTeamPlayerSection(),
                ],
              ),
            ),
          ),
          
          const SizedBox(width: 24),
          
          // Right Column: Preview & Actions (40%)
          Expanded(
            flex: 4,
            child: SingleChildScrollView(
              child: Column(
                children: [
                  _buildAssessmentPreview(),
                  const SizedBox(height: 24),
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
      padding: const EdgeInsets.all(16.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Left Sidebar: Quick Setup (20%)
          Container(
            width: 280,
            child: SingleChildScrollView(
              child: _buildDesktopQuickSetup(),
            ),
          ),
          
          const SizedBox(width: 24),
          
          // Main Content: Configuration (50%)
          Expanded(
            flex: 5,
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Assessment Configuration
                  _buildDesktopAssessmentConfig(),
                  
                  const SizedBox(height: 32),
                  
                  // Team & Player Management
                  _buildDesktopTeamPlayerConfig(),
                ],
              ),
            ),
          ),
          
          const SizedBox(width: 24),
          
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
      children: [
        _buildQuickSetupCard(),
        const SizedBox(height: 16),
        _buildRecentAssessmentsCard(),
        const SizedBox(height: 16),
        _buildQuickTemplatesCard(),
      ],
    );
  }

  Widget _buildQuickSetupCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.flash_on, color: Colors.orange[600]),
                const SizedBox(width: 8),
                Text(
                  'Quick Setup',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.blueGrey[800],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            
            ListTile(
              dense: true,
              leading: Icon(Icons.speed, color: Colors.green[600]),
              title: const Text('Quick Assessment'),
              subtitle: const Text('Basic 25-shot test'),
              onTap: () => _setQuickAssessment('quick'),
            ),
            
            ListTile(
              dense: true,
              leading: Icon(Icons.assessment, color: Colors.blue[600]),
              title: const Text('Comprehensive'),
              subtitle: const Text('Full 100-shot analysis'),
              onTap: () => _setQuickAssessment('comprehensive'),
            ),
            
            ListTile(
              dense: true,
              leading: Icon(Icons.center_focus_strong, color: Colors.purple[600]),
              title: const Text('Mini Assessment'),
              subtitle: const Text('Focused skill test'),
              onTap: () => _setQuickAssessment('mini'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentAssessmentsCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.history, color: Colors.grey[600]),
                const SizedBox(width: 8),
                Text(
                  'Recent Settings',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.blueGrey[800],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'Recent assessment configurations will appear here',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                  fontStyle: FontStyle.italic,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickTemplatesCard() {
    final quickTemplates = [
      {'name': 'Beginner Team', 'category': 'mini', 'players': 6},
      {'name': 'Advanced Team', 'category': 'comprehensive', 'players': 12},
      {'name': 'Skill Development', 'category': 'quick', 'players': 8},
    ];

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.description_outlined, color: Colors.teal[600]),
                const SizedBox(width: 8),
                Text(
                  'Quick Templates',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.blueGrey[800],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            
            ...quickTemplates.map((template) {
              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  dense: true,
                  title: Text(
                    template['name'] as String,
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                  ),
                  subtitle: Text(
                    '${template['category']} • ${template['players']} players',
                    style: TextStyle(fontSize: 10, color: Colors.grey[600]),
                  ),
                  onTap: () => _applyTemplate(template),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                ),
              );
            }).toList(),
          ],
        ),
      ),
    );
  }

  // Desktop assessment configuration
  Widget _buildDesktopAssessmentConfig() {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.assessment, color: Colors.blue[700]),
                const SizedBox(width: 12),
                Text(
                  'Assessment Configuration',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.blueGrey[800],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            
            // Category Filter
            Text(
              'Assessment Category',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.blueGrey[700],
              ),
            ),
            const SizedBox(height: 12),
            _buildCategorySelector(),
            
            const SizedBox(height: 24),
            
            // Assessment Type
            Text(
              'Assessment Type',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.blueGrey[700],
              ),
            ),
            const SizedBox(height: 12),
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
      ),
    );
  }

  // Desktop team & player configuration
  Widget _buildDesktopTeamPlayerConfig() {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.groups, color: Colors.green[700]),
                const SizedBox(width: 12),
                Text(
                  'Team & Player Selection',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.blueGrey[800],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            
            // Team Selection
            Text(
              'Team Selection (Optional)',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.blueGrey[700],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Choose a team to filter players, or select "No Team" to include all players',
              style: TextStyle(
                fontSize: 14,
                color: Colors.blueGrey[600],
                fontStyle: FontStyle.italic,
              ),
            ),
            const SizedBox(height: 12),
            _buildTeamSelector(),
            
            const SizedBox(height: 24),
            
            // Position Filter
            Text(
              'Position Filter',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.blueGrey[700],
              ),
            ),
            const SizedBox(height: 12),
            _buildPositionSelector(),
            
            const SizedBox(height: 24),
            
            // Player Selection
            Text(
              'Player Selection',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.blueGrey[700],
              ),
            ),
            const SizedBox(height: 12),
            _buildPlayerSelectionList(),
          ],
        ),
      ),
    );
  }

  // Desktop preview sidebar
  Widget _buildDesktopPreviewSidebar() {
    return Column(
      children: [
        _buildAssessmentPreview(),
        const SizedBox(height: 16),
        _buildAdvancedOptionsCard(),
        const SizedBox(height: 16),
        _buildStartButton(),
      ],
    );
  }

  Widget _buildAdvancedOptionsCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.settings, color: Colors.purple[600]),
                const SizedBox(width: 8),
                Text(
                  'Advanced Options',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.blueGrey[800],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            
            CheckboxListTile(
              dense: true,
              title: const Text('Video Recording'),
              subtitle: const Text('Record assessment for analysis'),
              value: false,
              onChanged: (value) {
                // Placeholder for video recording option
              },
            ),
            
            CheckboxListTile(
              dense: true,
              title: const Text('Real-time Analytics'),
              subtitle: const Text('Show live performance metrics'),
              value: true,
              onChanged: (value) {
                // Placeholder for real-time analytics option
              },
            ),
            
            CheckboxListTile(
              dense: true,
              title: const Text('Auto-save Results'),
              subtitle: const Text('Automatically save to database'),
              value: true,
              onChanged: (value) {
                // Placeholder for auto-save option
              },
            ),
          ],
        ),
      ),
    );
  }

  // Tablet team & player section
  Widget _buildTabletTeamPlayerSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Team Selection
        _buildSectionHeader('Select Team (Optional)'),
        const SizedBox(height: 8),
        Text(
          'Choose a team to filter players',
          style: TextStyle(
            fontSize: 14,
            color: Colors.blueGrey[600],
            fontStyle: FontStyle.italic,
          ),
        ),
        const SizedBox(height: 12),
        _buildTeamSelector(),
        
        const SizedBox(height: 24),
        
        // Position Filter & Player Selection in columns
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Position Filter (30%)
            Expanded(
              flex: 3,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionHeader('Position Filter'),
                  const SizedBox(height: 12),
                  _buildPositionSelector(),
                ],
              ),
            ),
          ],
        ),
        
        const SizedBox(height: 24),
        
        // Player Selection
        _buildSectionHeader('Select Players'),
        const SizedBox(height: 12),
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
          const SizedBox(height: 16),
          Text(
            'Loading ${loadingItems.join(', ')}...',
            style: TextStyle(
              fontSize: 16,
              color: Colors.blueGrey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Please wait while we prepare your assessment options',
            style: TextStyle(
              fontSize: 14,
              color: Colors.blueGrey[500],
            ),
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
            size: 64,
            color: Colors.red[300],
          ),
          const SizedBox(height: 16),
          const Text(
            'Error Loading Data',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _loadError ?? 'Unknown error occurred',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: _loadDataFromDatabase,
            icon: const Icon(Icons.refresh),
            label: const Text('Retry'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  // Custom team selector that includes "No Team" option
  Widget _buildTeamSelector() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(8),
      ),
      child: DropdownButton<Team?>(
        value: _selectedTeam,
        isExpanded: true,
        underline: Container(),
        hint: const Text('Select a team (optional)'),
        items: [
          // "No Team" option
          const DropdownMenuItem<Team?>(
            value: null,
            child: Row(
              children: [
                Icon(Icons.people_outline, color: Colors.grey),
                SizedBox(width: 8),
                Text('No Team - Show All Players'),
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
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          team.name,
                          style: const TextStyle(fontWeight: FontWeight.w500),
                        ),
                        Text(
                          '${team.division ?? 'Unknown'} • $teamPlayerCount players',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
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
            _selectedPlayers.clear(); // Clear selections when team changes
          });
          _updateAvailablePlayers();
        },
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: TextStyle(
        fontSize: context.isMobile ? 16 : 18,
        fontWeight: FontWeight.bold,
        color: Colors.blueGrey[800],
      ),
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
      spacing: 8,
      runSpacing: 8,
      children: categories.map((category) {
        final isSelected = _selectedCategory == category['value'];
        return GestureDetector(
          onTap: () {
            setState(() {
              _selectedCategory = category['value'] as String;
              // Reset selection if current type not in filtered results
              final filtered = getFilteredAssessmentTypes();
              if (!filtered.containsKey(_selectedAssessmentType) && filtered.isNotEmpty) {
                _selectedAssessmentType = filtered.keys.first;
              }
            });
          },
          child: Container(
            padding: EdgeInsets.symmetric(
              vertical: context.isMobile ? 6 : 8, 
              horizontal: context.isMobile ? 10 : 12
            ),
            decoration: BoxDecoration(
              color: isSelected ? (category['color'] as Color) : Colors.white,
              borderRadius: BorderRadius.circular(20),
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
                  size: context.isMobile ? 14 : 16,
                ),
                const SizedBox(width: 6),
                Text(
                  category['label'] as String,
                  style: TextStyle(
                    fontSize: context.isMobile ? 11 : 12,
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
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(8),
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
                Text(position.capitalize()),
                Text(
                  '($count)',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 12,
                  ),
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
        children: [
          EmptyStateDisplay(
            title: title,
            icon: Icons.person_off,
            showCard: true,
          ),
          if (subtitle.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
                fontStyle: FontStyle.italic,
              ),
              textAlign: TextAlign.center,
            ),
          ],
          if (_allPlayers.isEmpty) ...[
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () {
                // Navigate to add player screen
                Navigator.pushNamed(context, '/players/add');
              },
              icon: const Icon(Icons.person_add),
              label: const Text('Add Players'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ],
      );
    }

    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(7),
                topRight: Radius.circular(7),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  flex: 1,
                  child: Text(
                    '#',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.blueGrey[800],
                    ),
                  ),
                ),
                Expanded(
                  flex: 3,
                  child: Text(
                    'Player',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.blueGrey[800],
                    ),
                  ),
                ),
                if (!context.isMobile) ...[
                  Expanded(
                    flex: 2,
                    child: Text(
                      'Position',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.blueGrey[800],
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: Text(
                      'Team',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.blueGrey[800],
                      ),
                    ),
                  ),
                ],
                const SizedBox(width: 8),
                Checkbox(
                  value: _isAllPlayersSelected(_availablePlayers),
                  onChanged: (value) => _toggleAllPlayers(value, _availablePlayers),
                  activeColor: Colors.cyanAccent[700],
                ),
              ],
            ),
          ),
          
          // Player List
          ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: context.isMobile ? 300 : 400,
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
                  child: ListTile(
                    dense: true,
                    leading: CircleAvatar(
                      radius: 16,
                      backgroundColor: isSelected ? Colors.cyanAccent[700] : Colors.grey[300],
                      child: Text(
                        player.jerseyNumber?.toString() ?? '?',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                          color: isSelected ? Colors.white : Colors.grey[700],
                        ),
                      ),
                    ),
                    title: context.isMobile 
                      ? Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              player.name,
                              style: TextStyle(
                                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                              ),
                            ),
                            Text(
                              '${player.position ?? 'Unknown'} • ${playerTeam?.name ?? 'No Team'}',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        )
                      : Row(
                          children: [
                            Expanded(
                              flex: 3,
                              child: Text(
                                player.name,
                                style: TextStyle(
                                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                ),
                              ),
                            ),
                            Expanded(
                              flex: 2,
                              child: Text(
                                player.position ?? 'Unknown',
                                style: TextStyle(fontSize: 14),
                              ),
                            ),
                            Expanded(
                              flex: 2,
                              child: Text(
                                playerTeam?.name ?? 'No Team',
                                style: TextStyle(
                                  fontSize: 12,
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
          ),
          
          // Footer
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(7),
                bottomRight: Radius.circular(7),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${_selectedPlayers.length} players selected',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.blueGrey[700],
                  ),
                ),
                Row(
                  children: [
                    TextButton(
                      onPressed: _selectedPlayers.isNotEmpty ? _clearPlayerSelection : null,
                      child: const Text('Clear All'),
                    ),
                    const SizedBox(width: 8),
                    TextButton(
                      onPressed: _availablePlayers.isNotEmpty ? () => _selectAllPlayers(_availablePlayers) : null,
                      child: const Text('Select All'),
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

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.preview, color: Colors.blue[600]),
                const SizedBox(width: 8),
                Text(
                  'Assessment Summary',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.blueGrey[800],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            
            _buildPreviewInfoRow('Type', assessmentData['title'] as String? ?? 'Unknown'),
            _buildPreviewInfoRow('Players', '${_selectedPlayers.length}'),
            _buildPreviewInfoRow('Total Shots', '${totalShots * _selectedPlayers.length}'),
            _buildPreviewInfoRow('Est. Time', assessmentData['estimatedTime'] as String? ?? 'Unknown'),
          ],
        ),
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
      padding: EdgeInsets.all(context.isMobile ? 16 : 20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.blueGrey[50]!, categoryColor.withOpacity(0.1)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: categoryColor.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.preview, color: categoryColor),
              const SizedBox(width: 12),
              Text(
                'Assessment Preview',
                style: TextStyle(
                  fontSize: context.isMobile ? 16 : 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.blueGrey[800],
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: categoryColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  category.toUpperCase(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          // Assessment Info
          _buildPreviewInfoRow('Type', assessmentData['title'] as String? ?? 'Unknown'),
          _buildPreviewInfoRow('Estimated Time', assessmentData['estimatedTime'] as String? ?? 'Unknown'),
          _buildPreviewInfoRow('Team', _selectedTeam?.name ?? 'Multiple/No Team'),
          _buildPreviewInfoRow('Selected Players', '${_selectedPlayers.length}'),
          _buildPreviewInfoRow('Shots per Player', '$totalShots'),
          _buildPreviewInfoRow('Total Shots', '${totalShots * _selectedPlayers.length}'),
          
          const SizedBox(height: 16),
          
          Text(
            assessmentData['description'] as String? ?? 'No description available',
            style: TextStyle(
              fontSize: context.isMobile ? 12 : 14,
              color: Colors.blueGrey[600],
              fontStyle: FontStyle.italic,
            ),
          ),
          
          if (!context.isMobile) ...[
            const SizedBox(height: 20),
            
            Text(
              'Assessment Groups:',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.blueGrey[700],
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 12),
            
            Column(
              children: [
                for (int i = 0; i < groups.length; i++)
                  Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.8),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: categoryColor.withOpacity(0.3)),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 28,
                          height: 28,
                          decoration: BoxDecoration(
                            color: categoryColor,
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: Text(
                              '${i + 1}',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                groups[i]['title'] as String? ?? 
                                groups[i]['name'] as String? ?? 
                                'Untitled Group',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${groups[i]['shots'] as int? ?? 0} shots • ${groups[i]['location'] as String? ?? 'Location TBD'}',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.blueGrey[600],
                                ),
                              ),
                              // Show target zones if available
                              if (groups[i]['intendedZones'] != null || groups[i]['targetZones'] != null)
                                Text(
                                  'Target: ${(groups[i]['intendedZones'] ?? groups[i]['targetZones'] as List).join(', ')}',
                                  style: TextStyle(
                                    fontSize: 10,
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
        ],
      ),
    );
  }

  Widget _buildPreviewInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontWeight: FontWeight.w500,
              color: Colors.blueGrey[700],
            ),
          ),
          Text(
            value,
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

    return SizedBox(
      width: double.infinity,
      height: context.isMobile ? 48 : 56,
      child: ElevatedButton(
        onPressed: canStart ? _startAssessment : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: canStart ? Colors.cyanAccent[700] : Colors.grey[400],
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: canStart ? 4 : 0,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              canStart ? Icons.play_arrow : Icons.block,
              size: context.isMobile ? 20 : 24,
            ),
            SizedBox(width: context.isMobile ? 8 : 12),
            Flexible(
              child: Text(
                canStart 
                  ? context.isMobile
                    ? 'Start Assessment'
                    : 'Start Team Assessment (${totalShots * _selectedPlayers.length} total shots)'
                  : 'Please select players',
                style: TextStyle(
                  fontSize: context.isMobile ? 14 : 16,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
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
    // Enhanced validation with better error messages like shot files
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
      'teamId': _selectedTeam?.id ?? -1, // Use -1 for mixed/no team
      
      // Use 'timestamp' instead of 'date' to match shot files
      'timestamp': DateTime.now().toIso8601String(),
      'assessmentId': assessmentId,
      'groups': assessmentTypeData['groups'], // This now includes all JSON fields
      'playerCount': _selectedPlayers.length,
      'totalShots': assessmentTypeData['totalShots'] ?? totalShots,
      'metadata': assessmentTypeData['metadata'] ?? {},
      'version': assessmentTypeData['version'] ?? '1.0.0',
      'configVersion': '2.0.0', // Match JSON config version
    };
    
    // Debug print to verify structure
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
        
        // Set the assessment ID in AppState before starting like shot files
        appState.setCurrentAssessmentId(assessmentId);
        
        // Pass the complete assessment object and players list
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
      // Could also pre-select a certain number of players based on template
    });
  }
}

extension StringExtension on String {
  String capitalize() {
    return "${this[0].toUpperCase()}${substring(1).toLowerCase()}";
  }
}