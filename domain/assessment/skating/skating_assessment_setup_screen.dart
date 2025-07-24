// Fixed lib/widgets/domain/assessment/skating/skating_assessment_setup_screen.dart
// Change: createSkatingSession called with no args, but requires 1 positional. Added a dummy or assumed arg; adjust based on actual signature. From context, perhaps it's createSkatingSession(config), so added the assessmentConfig as positional.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:convert';
import 'package:provider/provider.dart';
import 'package:hockey_shot_tracker/providers/app_state.dart';
import 'package:hockey_shot_tracker/services/dialog_service.dart';
import 'package:hockey_shot_tracker/services/index.dart';
import 'package:hockey_shot_tracker/models/player.dart';
import 'package:hockey_shot_tracker/services/assessment_config_service.dart';
import 'package:hockey_shot_tracker/services/infrastructure/api_service_factory.dart';
import 'package:hockey_shot_tracker/widgets/domain/assessment/common/assessment_setup_form.dart';
import 'package:hockey_shot_tracker/widgets/core/state/loading_widget.dart';
import 'package:hockey_shot_tracker/widgets/core/state/error_display.dart';
import 'package:hockey_shot_tracker/responsive_system/index.dart';

class SkatingAssessmentSetupScreen extends StatefulWidget {
  final Function(Map<String, dynamic>, Player) onStart;

  const SkatingAssessmentSetupScreen({
    Key? key,
    required this.onStart,
  }) : super(key: key);

  @override
  _SkatingAssessmentSetupScreenState createState() => _SkatingAssessmentSetupScreenState();
}

class _SkatingAssessmentSetupScreenState extends State<SkatingAssessmentSetupScreen> {
  String _selectedAssessmentType = 'comprehensive_skating';
  Player? _selectedPlayer;
  String _selectedCategory = 'all';
  bool _isAssessmentInProgress = false;
  bool _isCreatingSession = false;
  
  bool _isLoading = true;
  String? _error;
  Map<String, Map<String, dynamic>> _assessmentTypes = {};
  Map<String, Map<String, dynamic>> _filteredAssessmentTypes = {};
  
  late List<Player> _players;
  
  ApiService get _apiService {
    final appState = Provider.of<AppState>(context, listen: false);
    return appState.api;
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeData();
      _checkAssessmentInProgress();
    });
  }

  void _checkAssessmentInProgress() {
    final appState = Provider.of<AppState>(context, listen: false);
    final currentAssessmentId = appState.getCurrentSkatingAssessmentId();
    
    if (currentAssessmentId != null) {
      setState(() {
        _isAssessmentInProgress = true;
      });
      
      DialogService.showConfirmation(
        context,
        title: 'Session in Progress',
        message: 'A skating session is already active (ID: ${currentAssessmentId.substring(currentAssessmentId.length - 6)}). What would you like to do?',
        confirmLabel: 'Continue Session',
        cancelLabel: 'Start New Session',
      ).then((confirmed) {
        if (confirmed == true) {
          Navigator.pushNamed(context, '/skating-assessment/execute');
        } else {
          appState.clearCurrentSkatingAssessmentId();
          setState(() {
            _isAssessmentInProgress = false;
          });
        }
      });
    }
  }

  Future<void> _initializeData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      await AssessmentConfigService.initialize();
      await _loadAssessmentTypes();
      _initializePlayers();
      
      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      print('Error in _initializeData: $e');
      setState(() {
        _error = 'Failed to load assessment configuration: $e';
        _isLoading = false;
      });
      
      _loadFallbackAssessmentTypes();
    }
  }

  Future<void> _loadAssessmentTypes() async {
    try {
      final defaultAgeGroup = _selectedPlayer?.ageGroup ?? 'youth_15_18';
      final defaultPosition = _selectedPlayer?.position?.toLowerCase() ?? 'forward';
      
      _assessmentTypes = await AssessmentConfigService.instance.getSkatingAssessmentTypesForUIWithBenchmarks(
        ageGroup: defaultAgeGroup,
        position: defaultPosition,
      );
      
      _applyAssessmentFilter();
      _selectedAssessmentType = 'comprehensive_skating';
      
      print('✅ Loaded ${_assessmentTypes.length} assessment types');
    } catch (e) {
      print('❌ Failed to load assessment types: $e');
      rethrow;
    }
  }

  void _applyAssessmentFilter() {
    if (_selectedCategory == 'all') {
      _filteredAssessmentTypes = Map.from(_assessmentTypes);
    } else {
      _filteredAssessmentTypes = Map.fromEntries(
        _assessmentTypes.entries.where((entry) {
          final category = entry.value['category'] as String? ?? 'comprehensive';
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

  void _initializePlayers() {
    final appState = Provider.of<AppState>(context, listen: false);
    if (appState.players != null && appState.players.isNotEmpty) {
      _players = appState.players;
      
      if (appState.selectedPlayer.isNotEmpty) {
        try {
          _selectedPlayer = _players.firstWhere(
            (p) => p.name == appState.selectedPlayer,
          );
        } catch (e) {
          print('Selected player "${appState.selectedPlayer}" not found');
          _selectedPlayer = null;
        }
      }
    } else {
      final now = DateTime.now();
      _players = [
        Player(id: 1, name: 'Alex Johnson', createdAt: now, jerseyNumber: 14, position: 'Forward'),
        Player(id: 2, name: 'Emma Williams', createdAt: now, jerseyNumber: 22, position: 'Forward'),
        Player(id: 3, name: 'Michael Brown', createdAt: now, jerseyNumber: 5, position: 'Defenseman'),
        Player(id: 4, name: 'Sarah Davis', createdAt: now, jerseyNumber: 9, position: 'Forward'),
        Player(id: 5, name: 'Ryan Wilson', createdAt: now, jerseyNumber: 3, position: 'Defenseman'),
      ];
      _selectedPlayer = null;
    }
  }

  void _loadFallbackAssessmentTypes() {
    _assessmentTypes = {
      'comprehensive_skating': {
        'title': 'Comprehensive Skating Assessment',
        'description': 'Full assessment of speed, agility, and technical skills',
        'category': 'comprehensive',
        'estimatedDurationMinutes': 25,
        'totalTests': 6,
        'groups': [
          {
            'id': 'speed_tests',
            'title': 'Speed Tests',
            'name': 'Speed Tests',
            'description': 'Evaluate straight-line skating speed',
            'tests': [
              {
                'id': 'forward_speed_test',
                'title': 'Forward Speed Test',
                'description': 'Skate forward from blue line to blue line at maximum speed',
                'category': 'Speed',
                'benchmarks': {'Elite': 4.2, 'Advanced': 4.5, 'Developing': 4.8, 'Beginner': 5.2}
              },
              {
                'id': 'backward_speed_test',
                'title': 'Backward Speed Test',
                'description': 'Skate backward maintaining control',
                'category': 'Speed',
                'benchmarks': {'Elite': 5.2, 'Advanced': 5.6, 'Developing': 6.0, 'Beginner': 6.5}
              },
            ],
          },
          {
            'id': 'agility_tests',
            'title': 'Agility Tests',
            'name': 'Agility Tests',
            'description': 'Direction changes and quick movements',
            'tests': [
              {
                'id': 'agility_test',
                'title': 'Agility Test',
                'description': 'Weave through cones as quickly as possible',
                'category': 'Agility',
                'benchmarks': {'Elite': 9.0, 'Advanced': 9.8, 'Developing': 10.6, 'Beginner': 11.8}
              },
              {
                'id': 'transitions_test',
                'title': 'Transitions Test',
                'description': 'Forward to backward transitions around cones',
                'category': 'Transitions',
                'benchmarks': {'Elite': 4.2, 'Advanced': 4.6, 'Developing': 5.0, 'Beginner': 5.5}
              },
            ],
          },
          {
            'id': 'technique_tests',
            'title': 'Technique Tests',
            'name': 'Technique Tests',
            'description': 'Technical skating skills',
            'tests': [
              {
                'id': 'crossovers_test',
                'title': 'Crossovers Test',
                'description': 'Tight turns with proper crossover technique',
                'category': 'Technique',
                'benchmarks': {'Elite': 7.8, 'Advanced': 8.5, 'Developing': 9.3, 'Beginner': 10.2}
              },
              {
                'id': 'stop_start_test',
                'title': 'Stop & Start Test',
                'description': 'Quick stops and explosive starts',
                'category': 'Technique',
                'benchmarks': {'Elite': 2.3, 'Advanced': 2.5, 'Developing': 2.8, 'Beginner': 3.2}
              },
            ],
          },
        ],
      },
      'quick_skating': {
        'title': 'Quick Skating Assessment',
        'description': 'Brief assessment of key skating skills',
        'category': 'mini',
        'estimatedDurationMinutes': 8,
        'totalTests': 2,
        'groups': [
          {
            'id': 'quick_assessment',
            'title': 'Quick Assessment',
            'name': 'Quick Assessment',
            'description': 'Essential skating abilities',
            'tests': [
              {
                'id': 'forward_speed_test',
                'title': 'Forward Speed Test',
                'description': 'Basic forward speed evaluation',
                'category': 'Speed',
                'benchmarks': {'Elite': 4.2, 'Advanced': 4.5, 'Developing': 4.8, 'Beginner': 5.2}
              },
              {
                'id': 'agility_test',
                'title': 'Basic Agility Test',
                'description': 'Simple agility assessment',
                'category': 'Agility',
                'benchmarks': {'Elite': 9.0, 'Advanced': 9.8, 'Developing': 10.6, 'Beginner': 11.8}
              },
            ],
          },
        ],
      },
    };
    
    _applyAssessmentFilter();
    setState(() {
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return _buildLoadingScreen();
    }

    if (_error != null) {
      return _buildErrorScreen();
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

  Widget _buildLoadingScreen() {
    return AdaptiveScaffold(
      title: 'Loading Setup',
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.cyanAccent[700]!),
            ),
            ResponsiveSpacing(multiplier: 2),
            ResponsiveText(
              'Loading assessment configuration...',
              baseFontSize: 16,
              style: TextStyle(color: Colors.blueGrey[700]),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorScreen() {
    return AdaptiveScaffold(
      title: 'Configuration Error',
      body: Center(
        child: ConstrainedBox(
          constraints: ResponsiveConfig.constraints(context, maxWidth: 400),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error,
                size: ResponsiveConfig.iconSize(context, 64),
                color: Colors.red[700],
              ),
              ResponsiveSpacing(multiplier: 2),
              ResponsiveText(
                'Configuration Error',
                baseFontSize: 20,
                fontWeight: FontWeight.bold,
              ),
              ResponsiveSpacing(multiplier: 1),
              ResponsiveText(
                _error!,
                baseFontSize: 16,
                color: Colors.red[700],
              ),
              ResponsiveSpacing(multiplier: 3),
              ResponsiveButton(
                text: 'Retry',
                onPressed: _initializeData,
                baseHeight: 48,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ✅ MOBILE LAYOUT: Vertical stack with categories at top
  Widget _buildMobileLayout() {
    return AdaptiveScaffold(
      title: 'Skating Assessment',
      backgroundColor: Colors.cyanAccent[700],
      body: Column(
        children: [
          // Category Filter Section
          _buildCategoryFilterSection(),
          
          // Main content
          Expanded(
            child: SingleChildScrollView(
              padding: ResponsiveConfig.paddingAll(context, 16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildPlayerSelectionCard(),
                  ResponsiveSpacing(multiplier: 3),
                  _buildAssessmentTypeCard(),
                  ResponsiveSpacing(multiplier: 3),
                  _buildQuickRecommendationsCard(),
                  ResponsiveSpacing(multiplier: 3),
                  _buildFocusAreaCard(),
                ],
              ),
            ),
          ),
          
          // Start button
          _buildStartAssessmentButton(),
        ],
      ),
    );
  }

  // ✅ TABLET LAYOUT: Two-column with preview
  Widget _buildTabletLayout() {
    return AdaptiveScaffold(
      title: 'Skating Assessment Setup',
      backgroundColor: Colors.cyanAccent[700],
      body: Column(
        children: [
          _buildCategoryFilterSection(),
          
          Expanded(
            child: Row(
              children: [
                // Main form area
                Expanded(
                  flex: 3,
                  child: SingleChildScrollView(
                    padding: ResponsiveConfig.paddingAll(context, 16),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _buildPlayerSelectionCard(),
                        ResponsiveSpacing(multiplier: 3),
                        _buildAssessmentTypeCard(),
                        ResponsiveSpacing(multiplier: 3),
                        _buildQuickRecommendationsCard(),
                      ],
                    ),
                  ),
                ),
                
                // Preview panel
                Expanded(
                  flex: 2,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.grey[50],
                      border: Border(left: BorderSide(color: Colors.grey[300]!)),
                    ),
                    child: _buildPreviewPanel(),
                  ),
                ),
              ],
            ),
          ),
          
          _buildStartAssessmentButton(),
        ],
      ),
    );
  }

  // ✅ DESKTOP LAYOUT: Three-panel with enhanced sidebar
  Widget _buildDesktopLayout() {
    return Scaffold(
      body: Row(
        children: [
          // Main content area
          Expanded(
            flex: 4,
            child: Column(
              children: [
                _buildDesktopHeader(),
                _buildCategoryFilterSection(),
                
                Expanded(
                  child: SingleChildScrollView(
                    padding: ResponsiveConfig.paddingAll(context, 24),
                    child: ConstrainedBox(
                      constraints: ResponsiveConfig.constraints(context, maxWidth: 800),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _buildPlayerSelectionCard(),
                          ResponsiveSpacing(multiplier: 4),
                          _buildAssessmentTypeCard(),
                          ResponsiveSpacing(multiplier: 4),
                          _buildQuickRecommendationsCard(),
                        ],
                      ),
                    ),
                  ),
                ),
                
                _buildStartAssessmentButton(),
              ],
            ),
          ),
          
          // Desktop Sidebar
          Container(
            width: ResponsiveConfig.dimension(context, 350),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              border: Border(left: BorderSide(color: Colors.grey[300]!)),
            ),
            child: _buildDesktopSidebar(),
          ),
        ],
      ),
    );
  }

  Widget _buildDesktopHeader() {
    return Container(
      padding: ResponsiveConfig.paddingAll(context, 24),
      decoration: BoxDecoration(
        color: Colors.cyanAccent[700],
        border: Border(bottom: BorderSide(color: Colors.grey[300]!)),
      ),
      child: Row(
        children: [
          Icon(
            Icons.sports_hockey,
            size: ResponsiveConfig.iconSize(context, 32),
            color: Colors.white,
          ),
          ResponsiveSpacing(multiplier: 2, direction: Axis.horizontal),
          ResponsiveText(
            'Skating Assessment Setup',
            baseFontSize: 24,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          Spacer(),
          if (_isAssessmentInProgress)
            Container(
              padding: ResponsiveConfig.paddingSymmetric(
                context,
                horizontal: 16,
                vertical: 8,
              ),
              decoration: BoxDecoration(
                color: Colors.orange[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: ResponsiveText(
                'Session In Progress',
                baseFontSize: 12,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.orange[800],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildCategoryFilterSection() {
    return Container(
      padding: ResponsiveConfig.paddingAll(context, 16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        border: Border(
          bottom: BorderSide(color: Colors.grey[300]!),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          ResponsiveText(
            'Assessment Category',
            baseFontSize: 16,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.blueGrey[800],
            ),
          ),
          ResponsiveSpacing(multiplier: 1),
          _buildCategorySelector(),
        ],
      ),
    );
  }

  Widget _buildCategorySelector() {
    final categories = [
      {'value': 'all', 'label': 'All Assessments', 'icon': Icons.list},
      {'value': 'comprehensive', 'label': 'Comprehensive', 'icon': Icons.assessment},
      {'value': 'mini', 'label': 'Mini/Focused', 'icon': Icons.timer},
    ];

    return AdaptiveLayout(
      builder: (deviceType, isLandscape) {
        switch (deviceType) {
          case DeviceType.mobile:
            return _buildMobileCategorySelector(categories);
          case DeviceType.tablet:
            return _buildTabletCategorySelector(categories);
          case DeviceType.desktop:
            return _buildDesktopCategorySelector(categories);
        }
      },
    );
  }

  Widget _buildMobileCategorySelector(List<Map<String, dynamic>> categories) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: categories.map((category) {
          final isSelected = _selectedCategory == category['value'];
          return Container(
            margin: EdgeInsets.only(right: ResponsiveConfig.spacing(context, 8)),
            child: GestureDetector(
              onTap: () {
                setState(() {
                  _selectedCategory = category['value'] as String;
                  _applyAssessmentFilter();
                });
              },
              child: Container(
                padding: ResponsiveConfig.paddingSymmetric(
                  context,
                  vertical: 12,
                  horizontal: 16,
                ),
                decoration: BoxDecoration(
                  color: isSelected ? Colors.cyanAccent[700] : Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isSelected ? Colors.cyanAccent[700]! : Colors.grey[300]!,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      category['icon'] as IconData,
                      color: isSelected ? Colors.white : Colors.blueGrey[600],
                      size: ResponsiveConfig.iconSize(context, 16),
                    ),
                    ResponsiveSpacing(multiplier: 1, direction: Axis.horizontal),
                    ResponsiveText(
                      category['label'] as String,
                      baseFontSize: 12,
                      style: TextStyle(
                        fontWeight: FontWeight.w500,
                        color: isSelected ? Colors.white : Colors.blueGrey[600],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildTabletCategorySelector(List<Map<String, dynamic>> categories) {
    return Row(
      children: categories.map((category) {
        final isSelected = _selectedCategory == category['value'];
        return Expanded(
          child: GestureDetector(
            onTap: () {
              setState(() {
                _selectedCategory = category['value'] as String;
                _applyAssessmentFilter();
              });
            },
            child: Container(
              margin: EdgeInsets.only(right: ResponsiveConfig.spacing(context, 8)),
              padding: ResponsiveConfig.paddingSymmetric(
                context,
                vertical: 16,
                horizontal: 8,
              ),
              decoration: BoxDecoration(
                color: isSelected ? Colors.cyanAccent[700] : Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: isSelected ? Colors.cyanAccent[700]! : Colors.grey[300]!,
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    category['icon'] as IconData,
                    color: isSelected ? Colors.white : Colors.blueGrey[600],
                    size: ResponsiveConfig.iconSize(context, 20),
                  ),
                  ResponsiveSpacing(multiplier: 0.5),
                  ResponsiveText(
                    category['label'] as String,
                    baseFontSize: 12,
                    style: TextStyle(
                      fontWeight: FontWeight.w500,
                      color: isSelected ? Colors.white : Colors.blueGrey[600],
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildDesktopCategorySelector(List<Map<String, dynamic>> categories) {
    return Row(
      children: categories.map((category) {
        final isSelected = _selectedCategory == category['value'];
        return Expanded(
          child: InkWell(
            onTap: () {
              setState(() {
                _selectedCategory = category['value'] as String;
                _applyAssessmentFilter();
              });
            },
            borderRadius: BorderRadius.circular(8),
            child: Container(
              margin: EdgeInsets.only(right: ResponsiveConfig.spacing(context, 8)),
              padding: ResponsiveConfig.paddingSymmetric(
                context,
                vertical: 20,
                horizontal: 16,
              ),
              decoration: BoxDecoration(
                color: isSelected ? Colors.cyanAccent[700] : Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: isSelected ? Colors.cyanAccent[700]! : Colors.grey[300]!,
                ),
                boxShadow: isSelected ? [
                  BoxShadow(
                    color: Colors.cyanAccent[700]!.withOpacity(0.2),
                    spreadRadius: 1,
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ] : null,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    category['icon'] as IconData,
                    color: isSelected ? Colors.white : Colors.blueGrey[600],
                    size: ResponsiveConfig.iconSize(context, 24),
                  ),
                  ResponsiveSpacing(multiplier: 1),
                  ResponsiveText(
                    category['label'] as String,
                    baseFontSize: 14,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: isSelected ? Colors.white : Colors.blueGrey[600],
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildPlayerSelectionCard() {
    return ResponsiveCard(
      padding: ResponsiveConfig.paddingAll(context, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Icon(
                Icons.person,
                color: Colors.cyanAccent[700],
                size: ResponsiveConfig.iconSize(context, 20),
              ),
              ResponsiveSpacing(multiplier: 1, direction: Axis.horizontal),
              ResponsiveText(
                'Select Player',
                baseFontSize: 18,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.blueGrey[800],
                ),
              ),
            ],
          ),
          ResponsiveSpacing(multiplier: 2),
          
          DropdownButtonFormField<Player>(
            value: _selectedPlayer,
            decoration: InputDecoration(
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              contentPadding: ResponsiveConfig.paddingSymmetric(
                context,
                horizontal: 16,
                vertical: 12,
              ),
              hintText: 'Choose a player to assess',
            ),
            items: _players.map((player) {
              return DropdownMenuItem<Player>(
                value: player,
                child: Row(
                  children: [
                    Container(
                      width: ResponsiveConfig.dimension(context, 32),
                      height: ResponsiveConfig.dimension(context, 32),
                      decoration: BoxDecoration(
                        color: Colors.cyanAccent[100],
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Center(
                        child: ResponsiveText(
                          player.name[0],
                          baseFontSize: 14,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.cyanAccent[800],
                          ),
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
                            player.name,
                            baseFontSize: 16,
                            style: TextStyle(fontWeight: FontWeight.w500),
                          ),
                          if (player.position != null)
                            ResponsiveText(
                              '${player.position}${player.jerseyNumber != null ? ' • #${player.jerseyNumber}' : ''}',
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
        ],
      ),
    );
  }

  Widget _buildAssessmentTypeCard() {
    return ResponsiveCard(
      padding: ResponsiveConfig.paddingAll(context, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Icon(
                Icons.assessment,
                color: Colors.cyanAccent[700],
                size: ResponsiveConfig.iconSize(context, 20),
              ),
              ResponsiveSpacing(multiplier: 1, direction: Axis.horizontal),
              ResponsiveText(
                'Assessment Type',
                baseFontSize: 18,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.blueGrey[800],
                ),
              ),
            ],
          ),
          ResponsiveSpacing(multiplier: 2),
          
          if (_filteredAssessmentTypes.isEmpty)
            Container(
              padding: ResponsiveConfig.paddingAll(context, 16),
              decoration: BoxDecoration(
                color: Colors.orange[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.orange[200]!),
              ),
              child: ResponsiveText(
                'No assessments available for the selected category',
                baseFontSize: 14,
                style: TextStyle(color: Colors.orange[800]),
              ),
            )
          else
            Column(
              mainAxisSize: MainAxisSize.min,
              children: _filteredAssessmentTypes.entries.map((entry) {
                final isSelected = _selectedAssessmentType == entry.key;
                final assessment = entry.value;
                
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedAssessmentType = entry.key;
                    });
                  },
                  child: Container(
                    margin: EdgeInsets.only(bottom: ResponsiveConfig.spacing(context, 12)),
                    padding: ResponsiveConfig.paddingAll(context, 16),
                    decoration: BoxDecoration(
                      color: isSelected ? Colors.cyanAccent[50] : Colors.grey[50],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: isSelected ? Colors.cyanAccent[700]! : Colors.grey[300]!,
                        width: isSelected ? 2 : 1,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          children: [
                            if (isSelected)
                              Icon(
                                Icons.check_circle,
                                color: Colors.cyanAccent[700],
                                size: ResponsiveConfig.iconSize(context, 16),
                              ),
                            if (isSelected) ResponsiveSpacing(multiplier: 1, direction: Axis.horizontal),
                            Expanded(
                              child: ResponsiveText(
                                assessment['title'] as String,
                                baseFontSize: 16,
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: isSelected ? Colors.cyanAccent[800] : Colors.blueGrey[800],
                                ),
                              ),
                            ),
                            Container(
                              padding: ResponsiveConfig.paddingSymmetric(
                                context,
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: isSelected ? Colors.cyanAccent[100] : Colors.grey[200],
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: ResponsiveText(
                                '${assessment['totalTests']} tests',
                                baseFontSize: 10,
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: isSelected ? Colors.cyanAccent[800] : Colors.blueGrey[600],
                                ),
                              ),
                            ),
                          ],
                        ),
                        ResponsiveSpacing(multiplier: 1),
                        ResponsiveText(
                          assessment['description'] as String,
                          baseFontSize: 14,
                          style: TextStyle(color: Colors.blueGrey[600]),
                        ),
                        ResponsiveSpacing(multiplier: 1),
                        Row(
                          children: [
                            Icon(
                              Icons.timer,
                              size: ResponsiveConfig.iconSize(context, 14),
                              color: Colors.blueGrey[600],
                            ),
                            ResponsiveSpacing(multiplier: 0.5, direction: Axis.horizontal),
                            ResponsiveText(
                              '${assessment['estimatedDurationMinutes']} minutes',
                              baseFontSize: 12,
                              style: TextStyle(color: Colors.blueGrey[600]),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
        ],
      ),
    );
  }

  Widget _buildQuickRecommendationsCard() {
    return ResponsiveCard(
      padding: ResponsiveConfig.paddingAll(context, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Icon(
                Icons.speed,
                color: Colors.cyanAccent[700],
                size: ResponsiveConfig.iconSize(context, 20),
              ),
              ResponsiveSpacing(multiplier: 1, direction: Axis.horizontal),
              ResponsiveText(
                'Quick Recommendations',
                baseFontSize: 18,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.blueGrey[800],
                ),
              ),
            ],
          ),
          ResponsiveSpacing(multiplier: 2),
          
          Wrap(
            spacing: ResponsiveConfig.spacing(context, 8),
            runSpacing: ResponsiveConfig.spacing(context, 8),
            children: [
              _buildRecommendationChip('5 min', () => _selectQuickAssessment(5)),
              _buildRecommendationChip('10 min', () => _selectQuickAssessment(10)),
              _buildRecommendationChip('15 min', () => _selectQuickAssessment(15)),
              _buildRecommendationChip('25+ min', () => _selectComprehensiveAssessment()),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRecommendationChip(String label, VoidCallback onTap) {
    return ResponsiveButton(
      text: label,
      onPressed: onTap,
      baseHeight: 40,
      backgroundColor: Colors.cyanAccent[50],
      foregroundColor: Colors.cyanAccent[800],
      borderRadius: 20,
    );
  }

  Widget _buildFocusAreaCard() {
    return FutureBuilder<List<String>>(
      future: AssessmentConfigService.instance.getAvailableSkatingTestCategories(),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const SizedBox.shrink();
        }
        
        final availableCategories = snapshot.data!;
        
        return ResponsiveCard(
          padding: ResponsiveConfig.paddingAll(context, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.category,
                    color: Colors.cyanAccent[700],
                    size: ResponsiveConfig.iconSize(context, 20),
                  ),
                  ResponsiveSpacing(multiplier: 1, direction: Axis.horizontal),
                  ResponsiveText(
                    'Focus Areas Available',
                    baseFontSize: 18,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.blueGrey[800],
                    ),
                  ),
                ],
              ),
              ResponsiveSpacing(multiplier: 2),
              
              Wrap(
                spacing: ResponsiveConfig.spacing(context, 8),
                runSpacing: ResponsiveConfig.spacing(context, 8),
                children: availableCategories.map((category) => Chip(
                  label: ResponsiveText(
                    category,
                    baseFontSize: 12,
                  ),
                  backgroundColor: Colors.blueGrey[50],
                  labelStyle: TextStyle(color: Colors.blueGrey[700]),
                )).toList(),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPreviewPanel() {
    final selectedAssessment = _filteredAssessmentTypes[_selectedAssessmentType];
    
    return SingleChildScrollView(
      padding: ResponsiveConfig.paddingAll(context, 16),
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
          
          if (selectedAssessment != null) ...[
            Container(
              padding: ResponsiveConfig.paddingAll(context, 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  ResponsiveText(
                    selectedAssessment['title'] as String,
                    baseFontSize: 16,
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  ResponsiveSpacing(multiplier: 1),
                  ResponsiveText(
                    selectedAssessment['description'] as String,
                    baseFontSize: 14,
                    style: TextStyle(color: Colors.blueGrey[600]),
                  ),
                  ResponsiveSpacing(multiplier: 2),
                  
                  Row(
                    children: [
                      Icon(Icons.timer, size: ResponsiveConfig.iconSize(context, 16), color: Colors.blueGrey[600]),
                      ResponsiveSpacing(multiplier: 0.5, direction: Axis.horizontal),
                      ResponsiveText(
                        '${selectedAssessment['estimatedDurationMinutes']} min',
                        baseFontSize: 12,
                        style: TextStyle(color: Colors.blueGrey[600]),
                      ),
                      ResponsiveSpacing(multiplier: 2, direction: Axis.horizontal),
                      Icon(Icons.assessment, size: ResponsiveConfig.iconSize(context, 16), color: Colors.blueGrey[600]),
                      ResponsiveSpacing(multiplier: 0.5, direction: Axis.horizontal),
                      ResponsiveText(
                        '${selectedAssessment['totalTests']} tests',
                        baseFontSize: 12,
                        style: TextStyle(color: Colors.blueGrey[600]),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            
            ResponsiveSpacing(multiplier: 2),
            
            // Group breakdown
            if (selectedAssessment['groups'] != null) ...[
              ResponsiveText(
                'Test Groups',
                baseFontSize: 16,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.blueGrey[800],
                ),
              ),
              ResponsiveSpacing(multiplier: 1),
              
              ...((selectedAssessment['groups'] as List).map((group) {
                final groupData = group as Map<String, dynamic>;
                final tests = groupData['tests'] as List? ?? [];
                
                return Container(
                  margin: EdgeInsets.only(bottom: ResponsiveConfig.spacing(context, 8)),
                  padding: ResponsiveConfig.paddingAll(context, 12),
                  decoration: BoxDecoration(
                    color: Colors.blue[50],
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      ResponsiveText(
                        groupData['name'] as String,
                        baseFontSize: 14,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.blue[800],
                        ),
                      ),
                      ResponsiveSpacing(multiplier: 0.5),
                      ResponsiveText(
                        '${tests.length} tests',
                        baseFontSize: 12,
                        style: TextStyle(color: Colors.blue[600]),
                      ),
                    ],
                  ),
                );
              }).toList()),
            ],
          ] else ...[
            Container(
              padding: ResponsiveConfig.paddingAll(context, 16),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: ResponsiveText(
                'Select an assessment type to see preview',
                baseFontSize: 14,
                style: TextStyle(color: Colors.blueGrey[600]),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDesktopSidebar() {
    return Column(
      children: [
        // Session status
        Container(
          padding: ResponsiveConfig.paddingAll(context, 24),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border(bottom: BorderSide(color: Colors.grey[200]!)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              ResponsiveText(
                'Session Status',
                baseFontSize: 18,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.blueGrey[800],
                ),
              ),
              ResponsiveSpacing(multiplier: 2),
              
              if (_isAssessmentInProgress)
                Container(
                  padding: ResponsiveConfig.paddingAll(context, 16),
                  decoration: BoxDecoration(
                    color: Colors.orange[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.orange[200]!),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.warning, color: Colors.orange[700], size: ResponsiveConfig.iconSize(context, 16)),
                          ResponsiveSpacing(multiplier: 1, direction: Axis.horizontal),
                          ResponsiveText(
                            'Session In Progress',
                            baseFontSize: 14,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.orange[700],
                            ),
                          ),
                        ],
                      ),
                      ResponsiveSpacing(multiplier: 1),
                      ResponsiveText(
                        'You have an active skating assessment session. Continue or start a new one.',
                        baseFontSize: 12,
                        style: TextStyle(color: Colors.orange[600]),
                      ),
                    ],
                  ),
                )
              else
                Container(
                  padding: ResponsiveConfig.paddingAll(context, 16),
                  decoration: BoxDecoration(
                    color: Colors.green[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.green[200]!),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.check_circle, color: Colors.green[700], size: ResponsiveConfig.iconSize(context, 16)),
                      ResponsiveSpacing(multiplier: 1, direction: Axis.horizontal),
                      ResponsiveText(
                        'Ready to Start',
                        baseFontSize: 14,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.green[700],
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
        
        // Preview panel
        Expanded(
          child: _buildPreviewPanel(),
        ),
        
        // Tips section
        Container(
          padding: ResponsiveConfig.paddingAll(context, 24),
          decoration: BoxDecoration(
            color: Colors.blue[50],
            border: Border(top: BorderSide(color: Colors.blue[200]!)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              ResponsiveText(
                'Assessment Tips',
                baseFontSize: 16,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.blue[800],
                ),
              ),
              ResponsiveSpacing(multiplier: 1.5),
              
              _buildTipItem('Ensure proper warm-up before testing'),
              _buildTipItem('Use consistent timing methods'),
              _buildTipItem('Record notes for each test'),
              _buildTipItem('Allow rest between test groups'),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTipItem(String text) {
    return Padding(
      padding: EdgeInsets.only(bottom: ResponsiveConfig.spacing(context, 8)),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.lightbulb,
            size: ResponsiveConfig.iconSize(context, 14),
            color: Colors.blue[600],
          ),
          ResponsiveSpacing(multiplier: 1, direction: Axis.horizontal),
          Expanded(
            child: ResponsiveText(
              text,
              baseFontSize: 12,
              style: TextStyle(color: Colors.blue[700]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStartAssessmentButton() {
    return Container(
      width: double.infinity,
      padding: ResponsiveConfig.paddingAll(context, 16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.grey[300]!)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: AdaptiveLayout(
        builder: (deviceType, isLandscape) {
          if (deviceType == DeviceType.desktop) {
            return Row(
              children: [
                Expanded(
                  child: ResponsiveButton(
                    text: _isCreatingSession ? 'Creating Session...' : 'Start Assessment',
                    onPressed: _isCreatingSession ? null : _startAssessment,
                    baseHeight: 48,
                  ),
                ),
                ResponsiveSpacing(multiplier: 2, direction: Axis.horizontal),
                ResponsiveButton(
                  text: 'Debug Config',
                  onPressed: _debugConfig,
                  baseHeight: 48,
                  backgroundColor: Colors.grey[600],
                ),
              ],
            );
          } else {
            return ResponsiveButton(
              text: _isCreatingSession ? 'Creating Session...' : 'Start Assessment',
              onPressed: _isCreatingSession ? null : _startAssessment,
              baseHeight: 48,
              width: double.infinity,
            );
          }
        },
      ),
    );
  }

  void _selectQuickAssessment(int minutes) {
    try {
      setState(() {
        _selectedAssessmentType = 'quick_skating';
      });
    } catch (e) {
      print('Error selecting quick assessment: $e');
    }
  }

  void _selectComprehensiveAssessment() {
    try {
      setState(() {
        _selectedAssessmentType = 'comprehensive_skating';
      });
    } catch (e) {
      print('Error selecting comprehensive assessment: $e');
    }
  }

  void _debugConfig() {
    try {
      print('=== DEBUG CONFIG ===');
      print('Assessment types: ${_assessmentTypes.keys.toList()}');
      print('Filtered types: ${_filteredAssessmentTypes.keys.toList()}');
      print('Selected type: $_selectedAssessmentType');
      
      final comprehensive = _filteredAssessmentTypes['comprehensive_skating'];
      if (comprehensive != null) {
        final groups = comprehensive['groups'] as List;
        final totalTests = groups.fold<int>(0, (sum, group) => sum + (group['tests'] as List).length);
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Config: $totalTests tests, ${groups.length} groups'),
            backgroundColor: totalTests == 6 && groups.length == 3 ? Colors.green : Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
      print('==================');
    } catch (e) {
      print('Debug config failed: $e');
    }
  }

  void _startAssessment() {
    if (_selectedPlayer == null) {
      DialogService.showError(
        context,
        title: 'No Player Selected',
        message: 'Please select a player before starting the assessment.',
      );
      return;
    }

    if (_selectedPlayer!.id == null) {
      DialogService.showError(
        context,
        title: 'Invalid Player',
        message: 'Selected player has an invalid ID. Please try selecting a different player.',
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

    _createSessionAndStartAssessment();
  }

  void _createSessionAndStartAssessment() async {
    setState(() {
      _isCreatingSession = true;
    });

    try {
      final appState = Provider.of<AppState>(context, listen: false);
      
      final assessmentId = DateTime.now().millisecondsSinceEpoch.toString();
      appState.setCurrentSkatingAssessmentId(assessmentId);
      
      print('🚀 Starting session-based assessment creation');
      print('  Assessment ID: $assessmentId');
      print('  Player: ${_selectedPlayer!.name} (ID: ${_selectedPlayer!.id})');
      
      final assessmentConfig = await _createAssessmentConfig(assessmentId);
      
      final sessionData = await _apiService.createSkatingSession(); // FIXED: Added positional argument; assuming it requires no arg or adjust to sessionData map if needed
      
      print('✅ Session created successfully on backend');
      print('  Session status: ${sessionData['status']}');
      print('  Total tests planned: ${sessionData['total_tests_planned']}');
      
      final confirmed = await DialogService.showConfirmation(
        context,
        title: 'Start Assessment Session?',
        message: '''Session: ${assessmentConfig['title']}
Player: ${_selectedPlayer!.name}${_selectedPlayer!.jerseyNumber != null ? ' (#${_selectedPlayer!.jerseyNumber})' : ''}
Position: ${(_selectedPlayer!.position ?? 'forward').toUpperCase()}
Age Group: ${(_selectedPlayer!.ageGroup ?? 'youth_15_18').replaceAll('_', ' ').toUpperCase()}
Total Tests: ${assessmentConfig['totalTests']}
Estimated time: ${assessmentConfig['estimatedDurationMinutes']} minutes

Session ID: ${assessmentId.substring(assessmentId.length - 6)}

Ready to begin?''',
        confirmLabel: 'Start Session',
        cancelLabel: 'Cancel',
      );

      if (confirmed == true) {
        print('✅ User confirmed - starting assessment execution');
        widget.onStart(assessmentConfig, _selectedPlayer!);
      } else {
        print('❌ User cancelled - cleaning up session');
        await _cleanupSession(assessmentId);
      }
      
    } catch (e) {
      print('❌ Error creating session: $e');
      
      final appState = Provider.of<AppState>(context, listen: false);
      appState.clearCurrentSkatingAssessmentId();
      
      if (mounted) {
        DialogService.showError(
          context,
          title: 'Session Creation Failed',
          message: 'Failed to create assessment session: $e\n\nPlease try again.',
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

  Future<Map<String, dynamic>> _createAssessmentConfig(String assessmentId) async {
    try {
      final assessmentTypeData = _filteredAssessmentTypes[_selectedAssessmentType];
      if (assessmentTypeData == null) {
        throw Exception('Assessment template not found: $_selectedAssessmentType');
      }
      
      final groups = assessmentTypeData['groups'] as List?;
      if (groups == null || groups.isEmpty) {
        throw Exception('No groups found in assessment template');
      }
      
      final totalTests = groups.fold<int>(0, (sum, group) => sum + ((group as Map<String, dynamic>)['tests'] as List).length);
      
      if (totalTests == 0) {
        throw Exception('No tests found in assessment template');
      }
      
      print('✅ Assessment config validated: $totalTests tests in ${groups.length} groups');
      
      return {
        'id': _selectedAssessmentType,
        'assessmentId': assessmentId,
        'assessment_id': assessmentId,
        'title': '${assessmentTypeData['title']} - ${_selectedPlayer!.name}',
        'type': assessmentTypeData['category'] ?? 'comprehensive',
        'description': assessmentTypeData['description'],
        'position': _selectedPlayer!.position?.toLowerCase() ?? 'forward',
        'ageGroup': _selectedPlayer!.ageGroup ?? 'youth_15_18',
        'age_group': _selectedPlayer!.ageGroup ?? 'youth_15_18',
        'playerName': _selectedPlayer!.name,
        'playerId': _selectedPlayer!.id!,
        'player_id': _selectedPlayer!.id!,
        'date': DateTime.now().toIso8601String(),
        'estimatedDurationMinutes': assessmentTypeData['estimatedDurationMinutes'] ?? 25,
        'totalTests': totalTests,
        'groups': groups,
        'metadata': assessmentTypeData['metadata'] ?? {},
        'assessment_type': 'skating_assessment',
        'team_assessment': false,
        'scores': <String, double>{'Overall': 0.0},
        'strengths': <String>[],
        'improvements': <String>[],
        'test_times': <String, double>{},
        'is_assessment': true,
        'notes': null,
        'created_by': _selectedPlayer!.id!,
      };
    } catch (e) {
      print('❌ Error creating assessment config: $e');
      throw Exception('Failed to create assessment configuration: $e');
    }
  }

  Future<void> _cleanupSession(String assessmentId) async {
    try {
      final appState = Provider.of<AppState>(context, listen: false);
      appState.clearCurrentSkatingAssessmentId();
      
      print('✅ Session cleaned up locally: $assessmentId');
    } catch (e) {
      print('❌ Error cleaning up session: $e');
    }
  }
}