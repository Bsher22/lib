import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:hockey_shot_tracker/providers/app_state.dart';
import 'package:hockey_shot_tracker/models/player.dart';
import 'package:hockey_shot_tracker/models/assessment_config.dart';
import 'package:hockey_shot_tracker/services/assessment_config_service.dart';
import 'package:hockey_shot_tracker/widgets/domain/assessment/common/assessment_setup_form.dart';
import 'package:hockey_shot_tracker/services/dialog_service.dart';
import 'package:hockey_shot_tracker/services/navigation_service.dart';
import 'package:hockey_shot_tracker/services/infrastructure/api_service_factory.dart';
import 'package:hockey_shot_tracker/responsive_system/index.dart';

class ShotAssessmentSetupScreen extends StatefulWidget {
  final Function(BuildContext, Map<String, dynamic>) onStart;

  const ShotAssessmentSetupScreen({
    Key? key,
    required this.onStart,
  }) : super(key: key);

  @override
  _ShotAssessmentSetupScreenState createState() => _ShotAssessmentSetupScreenState();
}

class _ShotAssessmentSetupScreenState extends State<ShotAssessmentSetupScreen> {
  String _selectedAssessmentType = '';
  Player? _selectedPlayer;
  String _selectedCategory = 'all';
  bool _isLoadingPlayers = false;
  bool _isLoadingTemplates = false;
  bool _isAssessmentInProgress = false;
  List<Player> _players = [];
  List<Player> _filteredPlayers = []; // ✅ NEW: For player search
  String _playerSearchQuery = ''; // ✅ NEW: Search query
  List<AssessmentTemplate> _assessmentTemplates = [];
  Map<String, Map<String, dynamic>> _assessmentTypesForUI = {};
  Map<String, Map<String, dynamic>> _filteredAssessmentTypes = {};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializePlayers();
      _loadAssessmentTemplates();
      _checkAssessmentInProgress();
    });
  }

  Future<void> _loadAssessmentTemplates() async {
    setState(() {
      _isLoadingTemplates = true;
    });

    try {
      print('ShotAssessmentSetupScreen: Loading assessment templates...');
      final configService = AssessmentConfigService.instance;
      
      _assessmentTemplates = await configService.getTemplates();
      print('ShotAssessmentSetupScreen: Loaded ${_assessmentTemplates.length} templates');

      _assessmentTypesForUI = await configService.getAssessmentTypesForUI();
      print('ShotAssessmentSetupScreen: Converted ${_assessmentTypesForUI.length} templates for UI');

      _applyAssessmentFilter();

      if (_filteredAssessmentTypes.isNotEmpty && _selectedAssessmentType.isEmpty) {
        _selectedAssessmentType = _filteredAssessmentTypes.keys.first;
        print('ShotAssessmentSetupScreen: Set default assessment type: $_selectedAssessmentType');
      }

      setState(() {
        _isLoadingTemplates = false;
      });
    } catch (e) {
      print('ShotAssessmentSetupScreen: Error loading templates: $e');
      
      _assessmentTypesForUI = _getDefaultAssessmentTypes();
      _applyAssessmentFilter();
      if (_filteredAssessmentTypes.isNotEmpty) {
        _selectedAssessmentType = _filteredAssessmentTypes.keys.first;
      }
      
      setState(() {
        _isLoadingTemplates = false;
      });
    }
  }

  void _applyAssessmentFilter() {
    if (_selectedCategory == 'all') {
      _filteredAssessmentTypes = Map.from(_assessmentTypesForUI);
    } else {
      _filteredAssessmentTypes = Map.fromEntries(
        _assessmentTypesForUI.entries.where((entry) {
          final category = entry.value['category'] as String? ?? 'standard';
          return category == _selectedCategory;
        }),
      );
    }

    if (!_filteredAssessmentTypes.containsKey(_selectedAssessmentType)) {
      _selectedAssessmentType = _filteredAssessmentTypes.isNotEmpty 
          ? _filteredAssessmentTypes.keys.first 
          : '';
    }
  }

  Future<void> _initializePlayers() async {
    final appState = Provider.of<AppState>(context, listen: false);

    if (appState.players.isNotEmpty) {
      _setPlayers(appState);
      return;
    }

    setState(() {
      _isLoadingPlayers = true;
    });

    try {
      await appState.loadPlayers(context: context);

      if (!mounted) return;

      if (appState.players.isNotEmpty) {
        _setPlayers(appState);
      } else {
        await DialogService.showError(
          context,
          title: 'No Players Found',
          message: 'No players found in database. Please add players to the app before starting an assessment.',
        );
        if (mounted) {
          Navigator.of(context).pop();
        }
      }
    } catch (e) {
      if (!mounted) return;

      if (!ApiServiceFactory.auth.isAuthenticated()) {
        print('initializePlayers: Not authenticated, navigating to login');
        NavigationService().pushNamedAndRemoveUntil('/login');
      } else {
        await DialogService.showError(
          context,
          title: 'Error Loading Players',
          message: 'Failed to load players from database: $e',
        );
        if (mounted) {
          Navigator.of(context).pop();
        }
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingPlayers = false;
        });
      }
    }
  }

  void _setPlayers(AppState appState) {
    _players = appState.players;
    _filteredPlayers = _players; // ✅ NEW: Initialize filtered list

    if (appState.selectedPlayer.isNotEmpty) {
      try {
        _selectedPlayer = _players.firstWhere(
          (p) => p.name == appState.selectedPlayer,
        );
      } catch (e) {
        print('ShotAssessmentSetupScreen: Selected player "${appState.selectedPlayer}" not found in loaded players');
        _selectedPlayer = null;
      }
    }

    if (_selectedPlayer == null) {
      print('ShotAssessmentSetupScreen: No player pre-selected, waiting for user selection');
    }

    setState(() {});
  }

  // ✅ NEW: Filter players based on search query
  void _filterPlayers(String query) {
    setState(() {
      _playerSearchQuery = query;
      if (query.isEmpty) {
        _filteredPlayers = _players;
      } else {
        _filteredPlayers = _players.where((player) {
          final nameLower = player.name.toLowerCase();
          final positionLower = player.position.toLowerCase();
          final queryLower = query.toLowerCase();
          return nameLower.contains(queryLower) || positionLower.contains(queryLower);
        }).toList();
      }
    });
  }

  void _checkAssessmentInProgress() {
    final appState = Provider.of<AppState>(context, listen: false);
    final currentAssessmentId = appState.getCurrentAssessmentId();
    
    if (currentAssessmentId != null) {
      setState(() {
        _isAssessmentInProgress = true;
      });
      
      DialogService.showConfirmation(
        context,
        title: 'Assessment in Progress',
        message: 'An assessment is already in progress (ID: ${currentAssessmentId.substring(currentAssessmentId.length - 6)}). Do you want to continue it or start a new one?',
        confirmLabel: 'Continue',
        cancelLabel: 'Start New',
      ).then((confirmed) {
        if (confirmed == true) {
          Navigator.pushNamed(context, '/assessment/execute');
        } else {
          appState.clearCurrentAssessmentId();
          setState(() {
            _isAssessmentInProgress = false;
          });
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // ✅ FIXED: Parent already provides constraints and scrolling - just return content
    return _buildContent();
  }

  Widget _buildContent() {
    if (_isLoadingPlayers || _isLoadingTemplates) {
      return _buildLoadingState();
    }

    if (_players.isEmpty) {
      return _buildNoPlayersState();
    }

    if (_assessmentTypesForUI.isEmpty) {
      return _buildNoTemplatesState();
    }

    // ✅ FIXED: Simplified Column layout with better spacing control
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildCategoryFilter(),
        ResponsiveSpacing(multiplier: 2), // Reduced spacing
        _buildPlayerSelection(),
        ResponsiveSpacing(multiplier: 2), // Reduced spacing
        _buildAssessmentTypeSelection(),
        ResponsiveSpacing(multiplier: 3), // Reduced spacing
        _buildStartButton(),
        ResponsiveSpacing(multiplier: 2), // Bottom padding
      ],
    );
  }

  Widget _buildLoadingState() {
    return Container(
      padding: ResponsiveConfig.paddingAll(context, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CircularProgressIndicator(color: Colors.cyanAccent),
          ResponsiveSpacing(multiplier: 2),
          ResponsiveText(
            'Loading assessment configurations...',
            baseFontSize: 16,
            style: TextStyle(color: Colors.blueGrey),
          ),
        ],
      ),
    );
  }

  Widget _buildNoPlayersState() {
    return Container(
      padding: ResponsiveConfig.paddingAll(context, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
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
    );
  }

  Widget _buildNoTemplatesState() {
    return Container(
      padding: ResponsiveConfig.paddingAll(context, 32),
      child: Center(
        child: ResponsiveText(
          'No assessment templates available',
          baseFontSize: 18,
          style: TextStyle(color: Colors.red),
        ),
      ),
    );
  }

  Widget _buildCategoryFilter() {
    return ResponsiveCard(
      padding: ResponsiveConfig.paddingAll(context, 20), // Reduced padding
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ResponsiveText(
            'Assessment Category',
            baseFontSize: 18, // Reduced font size
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.blueGrey[800],
            ),
          ),
          ResponsiveSpacing(multiplier: 1.5), // Reduced spacing
          _buildCategoryButtons(),
        ],
      ),
    );
  }

  Widget _buildCategoryButtons() {
    final categories = [
      {'value': 'all', 'label': 'All Assessments', 'icon': Icons.list},
      {'value': 'comprehensive', 'label': 'Comprehensive', 'icon': Icons.assessment},
      {'value': 'mini', 'label': 'Mini/Focused', 'icon': Icons.timer},
    ];

    // ✅ FIXED: Compact horizontal layout for categories
    return Wrap(
      spacing: ResponsiveConfig.spacing(context, 1),
      runSpacing: ResponsiveConfig.spacing(context, 0.5),
      children: categories.map((category) {
        final isSelected = _selectedCategory == category['value'];
        return ResponsiveButton(
          text: category['label'] as String,
          onPressed: () {
            setState(() {
              _selectedCategory = category['value'] as String;
              _applyAssessmentFilter();
            });
          },
          baseHeight: 40, // Reduced height
          backgroundColor: isSelected ? Colors.cyanAccent : Colors.grey[200],
          foregroundColor: isSelected ? Colors.black87 : Colors.blueGrey[700],
          prefix: Icon(
            category['icon'] as IconData,
            size: 16, // Reduced icon size
            color: isSelected ? Colors.black87 : Colors.blueGrey[700],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildPlayerSelection() {
    return ResponsiveCard(
      padding: ResponsiveConfig.paddingAll(context, 20), // Reduced padding
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ResponsiveText(
            'Select Player',
            baseFontSize: 18, // Reduced font size
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.blueGrey[800],
            ),
          ),
          ResponsiveSpacing(multiplier: 1.5), // Reduced spacing
          
          // ✅ NEW: Search field for players (only show if many players)
          if (_players.length > 10) ...[
            TextFormField(
              decoration: InputDecoration(
                hintText: 'Search players by name or position...',
                prefixIcon: Icon(Icons.search, size: 20),
                border: OutlineInputBorder(
                  borderRadius: ResponsiveConfig.borderRadius(context, 8),
                ),
                contentPadding: ResponsiveConfig.paddingSymmetric(
                  context, 
                  horizontal: 12, 
                  vertical: 8
                ),
              ),
              style: TextStyle(fontSize: 14),
              onChanged: _filterPlayers,
            ),
            ResponsiveSpacing(multiplier: 1),
            if (_filteredPlayers.isEmpty)
              Container(
                padding: ResponsiveConfig.paddingAll(context, 12),
                decoration: BoxDecoration(
                  color: Colors.orange[50],
                  borderRadius: ResponsiveConfig.borderRadius(context, 8),
                  border: Border.all(color: Colors.orange[200]!),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.orange[600], size: 18),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'No players found matching "$_playerSearchQuery"',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.orange[700],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
          ],
          
          // ✅ SIMPLE FIX: Standard height dropdown with single-line display
          DropdownButtonFormField<Player>(
            decoration: InputDecoration(
              border: OutlineInputBorder(
                borderRadius: ResponsiveConfig.borderRadius(context, 12),
              ),
              contentPadding: ResponsiveConfig.paddingSymmetric(
                context, 
                horizontal: 16, 
                vertical: 12
              ),
            ),
            value: _selectedPlayer,
            hint: Text( // ✅ FIXED: Use regular Text instead of ResponsiveText
              _players.length > 10 
                ? 'Choose from ${_filteredPlayers.length} players'
                : 'Choose a player',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
            ),
            menuMaxHeight: MediaQuery.of(context).size.height * 0.4,
            isExpanded: true,
            // ✅ CRITICAL FIX: Simplified selected item display to prevent overflow
            selectedItemBuilder: (BuildContext context) {
              return _filteredPlayers.map<Widget>((Player player) {
                return Container(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    '${player.name}${player.position.isNotEmpty ? ' (${player.position})' : ''}',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.black87,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                );
              }).toList();
            },
            items: _filteredPlayers.map((player) {
              return DropdownMenuItem<Player>(
                value: player,
                child: Container(
                  height: 50,
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 14,
                        backgroundColor: Colors.blue[100],
                        child: Icon(
                          Icons.person, 
                          size: 16,
                          color: Colors.blue[600]
                        ),
                      ),
                      SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              player.name, 
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            if (player.position.isNotEmpty)
                              Text(
                                player.position, 
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[600],
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
            onChanged: (player) {
              setState(() {
                _selectedPlayer = player;
                if (player != null) {
                  Provider.of<AppState>(context, listen: false).setSelectedPlayer(
                    player.name,
                    loadShots: false,
                    loadSkatings: false,
                  );
                }
              });
            },
          ),
          if (_selectedPlayer != null) ...[
            ResponsiveSpacing(multiplier: 1.5), // Reduced spacing
            Container(
              padding: ResponsiveConfig.paddingAll(context, 10), // Reduced padding
              decoration: BoxDecoration(
                color: Colors.green[50],
                borderRadius: ResponsiveConfig.borderRadius(context, 8),
                border: Border.all(color: Colors.green[200]!),
              ),
              child: Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.green[600], size: 18), // Reduced size
                  ResponsiveSpacing(multiplier: 1, direction: Axis.horizontal),
                  Expanded( // ✅ CRITICAL: Prevents overflow in confirmation text
                    child: ResponsiveText(
                      'Player selected: ${_selectedPlayer!.name}',
                      baseFontSize: 13, // Reduced font size
                      style: TextStyle(
                        color: Colors.green[700], 
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildAssessmentTypeSelection() {
    return ResponsiveCard(
      padding: ResponsiveConfig.paddingAll(context, 20), // Reduced padding
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ResponsiveText(
            'Select Assessment Type',
            baseFontSize: 18, // Reduced font size
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.blueGrey[800],
            ),
          ),
          ResponsiveSpacing(multiplier: 1.5), // Reduced spacing
          
          // ✅ FIXED: Limit height and make scrollable if needed
          ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.4, // Limit to 40% of screen height
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: _filteredAssessmentTypes.entries.map((entry) {
                  return _buildAssessmentTypeCard(entry.key, entry.value);
                }).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAssessmentTypeCard(String type, Map<String, dynamic> info) {
    final isSelected = _selectedAssessmentType == type;
    
    return Container(
      margin: ResponsiveConfig.paddingSymmetric(context, vertical: 4), // Reduced margin
      child: InkWell(
        onTap: () {
          setState(() {
            _selectedAssessmentType = type;
          });
        },
        child: Container(
          padding: ResponsiveConfig.paddingAll(context, 14), // Reduced padding
          decoration: BoxDecoration(
            color: isSelected ? Colors.blue[50] : Colors.grey[50],
            borderRadius: ResponsiveConfig.borderRadius(context, 12),
            border: Border.all(
              color: isSelected ? Colors.blue[300]! : Colors.grey[300]!,
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Radio<String>(
                    value: type,
                    groupValue: _selectedAssessmentType,
                    onChanged: (value) {
                      setState(() {
                        _selectedAssessmentType = value!;
                      });
                    },
                    activeColor: Colors.blue[600],
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap, // ✅ FIXED: Reduce tap target size
                  ),
                  ResponsiveSpacing(multiplier: 1, direction: Axis.horizontal),
                  Expanded( // ✅ FIXED: Added Expanded to prevent overflow
                    child: ResponsiveText(
                      info['title'] as String,
                      baseFontSize: 15, // Reduced font size
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.blueGrey[800],
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              Padding(
                padding: ResponsiveConfig.paddingSymmetric(context, horizontal: 40), // Reduced padding
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ResponsiveText(
                      info['description'] as String,
                      baseFontSize: 13, // Reduced font size
                      style: TextStyle(color: Colors.blueGrey[600]),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                    ResponsiveSpacing(multiplier: 0.8), // Reduced spacing
                    Wrap(
                      spacing: 6, // Reduced spacing
                      children: [
                        _buildInfoChip(
                          '${info['estimatedDuration'] ?? 20} min',
                          Icons.schedule,
                          Colors.orange,
                        ),
                        _buildInfoChip(
                          '${info['totalShots'] ?? 0} shots',
                          Icons.sports_hockey,
                          Colors.blue,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoChip(String label, IconData icon, MaterialColor color) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 6, vertical: 3), // Reduced padding
      decoration: BoxDecoration(
        color: color[100],
        borderRadius: BorderRadius.circular(14), // Reduced radius
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color[700]), // Reduced size
          SizedBox(width: 3), // Reduced spacing
          Text(
            label,
            style: TextStyle(
              fontSize: 11, // Reduced font size
              color: color[700],
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStartButton() {
    return ResponsiveButton(
      text: 'Start Assessment',
      onPressed: _startAssessment,
      baseHeight: 50, // Slightly reduced height
      width: double.infinity,
      backgroundColor: Colors.cyanAccent,
      foregroundColor: Colors.black87,
      prefix: Icon(
        Icons.play_arrow, 
        color: Colors.black87, 
        size: 22, // Reduced size
      ),
      style: TextStyle(
        fontSize: 16, // Reduced font size
        fontWeight: FontWeight.bold,
      ),
    );
  }

  Map<String, Map<String, dynamic>> _getDefaultAssessmentTypes() {
    return {
      'accuracy_precision_100': {
        'title': 'Accuracy Precision Test (30 min)',
        'description': 'Comprehensive 100-shot directional accuracy assessment with intended zone targeting',
        'category': 'comprehensive',
        'estimatedDuration': 30,
        'totalShots': 100,
        'groups': [
          {
            'id': '0',
            'title': 'Right Side Precision',
            'shots': 25,
            'defaultType': 'Wrist Shot',
            'location': 'Slot',
            'instructions': 'Target the right side of the net. Aim specifically for zones 3, 6, or 9.',
            'allowedShotTypes': ['Wrist Shot', 'Snap Shot'],
            'targetZones': ['3', '6', '9'],
          },
          {
            'id': '1',
            'title': 'Left Side Precision',
            'shots': 25,
            'defaultType': 'Wrist Shot',
            'location': 'Slot',
            'instructions': 'Target the left side of the net. Aim specifically for zones 1, 4, or 7.',
            'allowedShotTypes': ['Wrist Shot', 'Snap Shot'],
            'targetZones': ['1', '4', '7'],
          },
          {
            'id': '2',
            'title': 'Center Line Targeting',
            'shots': 25,
            'defaultType': 'Wrist Shot',
            'location': 'Slot',
            'instructions': 'Target the center line of the net. Aim specifically for zones 2, 5, or 8.',
            'allowedShotTypes': ['Wrist Shot', 'Snap Shot'],
            'targetZones': ['2', '5', '8'],
          },
          {
            'id': '3',
            'title': 'High Corner Precision',
            'shots': 25,
            'defaultType': 'Wrist Shot',
            'location': 'Slot',
            'instructions': 'Target the top shelf of the net. Aim specifically for zones 1, 2, or 3.',
            'allowedShotTypes': ['Wrist Shot', 'Snap Shot'],
            'targetZones': ['1', '2', '3'],
          },
        ],
      },
      'right_side_precision_mini': {
        'title': 'Right Side Precision (Mini)',
        'description': 'Focused 25-shot assessment targeting right side accuracy and consistency',
        'category': 'mini',
        'estimatedDuration': 8,
        'totalShots': 25,
        'groups': [
          {
            'id': '0',
            'title': 'Right Side Precision',
            'shots': 25,
            'defaultType': 'Wrist Shot',
            'location': 'Slot',
            'instructions': 'Target the right side of the net. Aim specifically for zones 3, 6, or 9.',
            'allowedShotTypes': ['Wrist Shot', 'Snap Shot'],
            'targetZones': ['3', '6', '9'],
          },
        ],
      },
    };
  }

  void _startAssessment() {
    if (_selectedPlayer == null) {
      DialogService.showError(
        context,
        title: 'No Player Selected',
        message: 'Please select a player from the dropdown before starting the assessment.',
      );
      return;
    }

    if (_selectedPlayer!.id == null) {
      DialogService.showError(
        context,
        title: 'Invalid Player',
        message: 'The selected player has an invalid ID. Please try selecting a different player or contact support.',
      );
      return;
    }

    if (_selectedAssessmentType.isEmpty || !_filteredAssessmentTypes.containsKey(_selectedAssessmentType)) {
      DialogService.showError(
        context,
        title: 'No Assessment Type Selected',
        message: 'Please select an assessment type before starting.',
      );
      return;
    }

    final appState = Provider.of<AppState>(context, listen: false);
    final assessmentTypeData = _filteredAssessmentTypes[_selectedAssessmentType]!;

    final existingAssessmentId = appState.getCurrentAssessmentId();
    final assessmentId = existingAssessmentId ?? DateTime.now().millisecondsSinceEpoch.toString();

    final groups = assessmentTypeData['groups'] as List<dynamic>;
    final totalShots = groups.fold<int>(0, (sum, group) => sum + (group['shots'] as int? ?? 0));

    final position = _selectedPlayer!.position?.toLowerCase() ?? 'forward';
    final ageGroup = _selectedPlayer!.ageGroup ?? 'youth_15_18';

    final assessment = {
      'title': assessmentTypeData['title'],
      'type': _selectedAssessmentType,
      'description': assessmentTypeData['description'],
      'position': position,
      'ageGroup': ageGroup,
      'playerName': _selectedPlayer!.name,
      'playerId': _selectedPlayer!.id,
      'timestamp': DateTime.now().toIso8601String(),
      'assessmentId': assessmentId,
      'groups': assessmentTypeData['groups'],
      'totalShots': totalShots,
      'category': assessmentTypeData['category'] ?? 'standard',
      'estimatedDuration': assessmentTypeData['estimatedDuration'] ?? 20,
    };

    print('ShotAssessmentSetupScreen: Creating assessment with ID: $assessmentId');
    print('ShotAssessmentSetupScreen: Assessment type: $_selectedAssessmentType');
    print('ShotAssessmentSetupScreen: Selected player: ${_selectedPlayer!.name} (ID: ${_selectedPlayer!.id})');
    print('ShotAssessmentSetupScreen: Position from player: $position, Age group from player: $ageGroup');

    DialogService.showConfirmation(
      context,
      title: 'Start Assessment?',
      message: '''Assessment: ${assessment['title']}
Player: ${_selectedPlayer!.name}${_selectedPlayer!.jerseyNumber != null ? ' (#${_selectedPlayer!.jerseyNumber})' : ''}
Position: ${position.toUpperCase()}
Age Group: ${ageGroup.replaceAll('_', ' ').toUpperCase()}
Total Shots: $totalShots
Estimated time: ${assessment['estimatedDuration']} minutes

Assessment ID: ${assessmentId.substring(assessmentId.length - 6)}

Ready to begin?''',
      confirmLabel: 'Start Assessment',
      cancelLabel: 'Cancel',
    ).then((confirmed) {
      if (confirmed == true) {
        print('ShotAssessmentSetupScreen: Starting assessment for player: ${_selectedPlayer!.name} (ID: ${_selectedPlayer!.id})');
        print('ShotAssessmentSetupScreen: Assessment ID: $assessmentId');
        
        appState.setCurrentAssessmentId(assessmentId);
        appState.setSelectedPlayer(_selectedPlayer!.name, loadShots: false, loadSkatings: false);
        
        widget.onStart(context, assessment);
      }
    });
  }
}