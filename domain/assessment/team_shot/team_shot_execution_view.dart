// lib/widgets/domain/assessment/team_shot/team_shot_execution_view.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hockey_shot_tracker/models/player.dart';
import 'package:hockey_shot_tracker/widgets/domain/assessment/common/player_navigation_bar.dart';
import 'package:hockey_shot_tracker/widgets/domain/assessment/common/assessment_progress_header.dart';
import 'package:hockey_shot_tracker/services/dialog_service.dart';
import 'package:hockey_shot_tracker/widgets/core/selection/grid_selector.dart';
import 'package:hockey_shot_tracker/widgets/core/selection/toggle_button_group.dart';
import 'package:hockey_shot_tracker/widgets/core/form/standard_text_field.dart';
import 'package:hockey_shot_tracker/responsive_system/index.dart';

// Constants for UI styling
const _primaryColor = Colors.cyanAccent;
const _successColor = Colors.green;
const _errorColor = Colors.red;
const _warningColor = Colors.orange;
const _sectionSpacing = 24.0;
const _widgetSpacing = 16.0;
const _smallSpacing = 8.0;

/// Team shot execution view with batch recording per player
/// Players take all their shots before moving to the next player
class TeamShotExecutionView extends StatefulWidget {
  final Map<String, dynamic> assessment;
  final List<Player> players;
  final Map<String, Map<int, List<Map<String, dynamic>>>> playerShotResults;
  final Function(String, int, Map<String, dynamic>) onAddResult;
  final VoidCallback onComplete;

  const TeamShotExecutionView({
    Key? key,
    required this.assessment,
    required this.players,
    required this.playerShotResults,
    required this.onAddResult,
    required this.onComplete,
  }) : super(key: key);

  @override
  _TeamShotExecutionViewState createState() => _TeamShotExecutionViewState();
}

class _TeamShotExecutionViewState extends State<TeamShotExecutionView> {
  int _currentGroup = 0;
  int _currentPlayerIndex = 0;     // Which player is currently shooting
  int _currentPlayerShot = 0;      // Current shot for this player (0-4)
  
  // Grid data: [playerId][shotNumber] = {zone, type, outcome, success, velocity, intended_direction}
  Map<String, Map<int, Map<String, dynamic>>> _gridData = {};

  // Enhanced directional targeting system
  String? _intendedDirection;
  List<String> _intendedZones = [];
  
  // Current shot type (can be changed per shot)
  String _currentShotType = 'Wrist Shot';

  @override
  void initState() {
    super.initState();
    _initializeGridData();
    _updateIntendedZoneForGroup();
    _updateShotTypeForGroup();
  }

  void _initializeGridData() {
    _gridData = {};
    for (var player in widget.players) {
      _gridData[player.id.toString()] = {};
    }
  }

  // Update intended zones and direction based on current group configuration
  void _updateIntendedZoneForGroup() {
    final groups = widget.assessment['groups'] as List?;
    if (groups != null && groups.isNotEmpty && _currentGroup < groups.length) {
      final group = groups[_currentGroup] as Map<String, dynamic>?;
      final targetZones = group?['targetZones'] as List<dynamic>? ?? 
                          group?['intendedZones'] as List<dynamic>? ?? [];
      final targetSide = group?['parameters']?['targetSide'] as String? ?? '';
      
      // Set the intended zones list
      _intendedZones = targetZones.map((z) => z.toString()).toList();
      
      // Set directional intent based on targetSide or derive from zones
      _intendedDirection = _getDirectionFromSideOrZones(targetSide, _intendedZones);
      
      debugPrint('TeamShotExecution: Set intended direction to $_intendedDirection for zones $_intendedZones');
    } else {
      _intendedDirection = null;
      _intendedZones = [];
    }
  }

  void _updateShotTypeForGroup() {
    final groups = widget.assessment['groups'] as List?;
    if (groups != null && groups.isNotEmpty && _currentGroup < groups.length) {
      final group = groups[_currentGroup] as Map<String, dynamic>?;
      _currentShotType = group?['defaultType'] as String? ?? 'Wrist Shot';
    }
  }

  // Helper method to determine direction from targetSide parameter or zone patterns
  String? _getDirectionFromSideOrZones(String targetSide, List<String> zones) {
    // First, try to use the targetSide parameter
    switch (targetSide.toLowerCase()) {
      case 'east':
      case 'right':
        return 'East';
      case 'west':
      case 'left':
        return 'West';
      case 'north':
      case 'high':
        return 'North';
      case 'south':
      case 'low':
        return 'South';
      case 'center':
        return 'Center';
    }
    
    // Fallback: derive direction from zone patterns
    final zoneSet = zones.toSet();
    if (zoneSet.containsAll({'3', '6', '9'})) return 'East';
    if (zoneSet.containsAll({'1', '4', '7'})) return 'West';
    if (zoneSet.containsAll({'1', '2', '3'})) return 'North';
    if (zoneSet.containsAll({'7', '8', '9'})) return 'South';
    if (zoneSet.containsAll({'2', '5', '8'})) return 'Center';
    
    return null; // Unknown pattern
  }

  // Get current player
  Player get _currentPlayer => widget.players[_currentPlayerIndex];

  // Get total shots per player
  int get _totalShotsPerPlayer {
    final groups = widget.assessment['groups'] as List?;
    if (groups != null && groups.isNotEmpty && _currentGroup < groups.length) {
      final group = groups[_currentGroup] as Map<String, dynamic>;
      return group['shots'] as int? ?? 5;
    }
    return 5;
  }

  @override
  Widget build(BuildContext context) {
    final groups = widget.assessment['groups'] as List?;
    
    if (groups == null || groups.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: ResponsiveText('Team Shot Assessment', baseFontSize: 18)),
        body: Center(
          child: ResponsiveText('No assessment groups found', baseFontSize: 16),
        ),
      );
    }

    final currentGroup = groups[_currentGroup] as Map<String, dynamic>;
    
    if (_totalShotsPerPlayer == 0) {
      return Scaffold(
        appBar: AppBar(title: ResponsiveText('Team Shot Assessment', baseFontSize: 18)),
        body: Center(
          child: ResponsiveText('No shots configured for this group', baseFontSize: 16),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: ResponsiveText('Team Shot Assessment', baseFontSize: 18),
        backgroundColor: _primaryColor,
        foregroundColor: Colors.white,
      ),
      body: AdaptiveLayout(
        builder: (deviceType, isLandscape) {
          switch (deviceType) {
            case DeviceType.mobile:
              return _buildMobileLayout(currentGroup, groups);
            case DeviceType.tablet:
              return _buildTabletLayout(currentGroup, groups);
            case DeviceType.desktop:
              return _buildDesktopLayout(currentGroup, groups);
          }
        },
      ),
    );
  }

  // Mobile Layout: Single player focus
  Widget _buildMobileLayout(Map<String, dynamic> currentGroup, List groups) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Assessment progress header
        AssessmentProgressHeader(
          groupTitle: _buildEnhancedGroupTitle(currentGroup),
          groupDescription: '${currentGroup['instructions'] ?? ''} • ${currentGroup['location'] ?? ''}',
          currentGroupIndex: _currentGroup,
          totalGroups: groups.length,
          currentItemIndex: _getCurrentOverallShotIndex(),
          totalItems: widget.players.length * _totalShotsPerPlayer,
          progressValue: _calculateOverallProgress(),
          bottomContent: _buildLocationInfo(currentGroup),
        ),
        
        // Current player header
        Container(
          padding: ResponsiveConfig.paddingAll(context, 16),
          color: Colors.blue[50],
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 20,
                    backgroundColor: Colors.blue[600],
                    child: ResponsiveText(
                      _currentPlayer.jerseyNumber?.toString() ?? '?',
                      baseFontSize: 16,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  ResponsiveSpacing(multiplier: 2, direction: Axis.horizontal),
                  Expanded(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ResponsiveText(
                          _currentPlayer.name,
                          baseFontSize: 18,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.blue[800],
                          ),
                        ),
                        ResponsiveText(
                          'Shot ${_currentPlayerShot + 1} of $_totalShotsPerPlayer',
                          baseFontSize: 14,
                          style: TextStyle(color: Colors.blue[600]),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: ResponsiveConfig.paddingSymmetric(context, horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.blue[600],
                      borderRadius: ResponsiveConfig.borderRadius(context, 12),
                    ),
                    child: ResponsiveText(
                      'Player ${_currentPlayerIndex + 1}/${widget.players.length}',
                      baseFontSize: 12,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              ResponsiveSpacing(multiplier: 1.5),
              LinearProgressIndicator(
                value: (_currentPlayerShot + 1) / _totalShotsPerPlayer,
                backgroundColor: Colors.blue[100],
                valueColor: AlwaysStoppedAnimation<Color>(Colors.blue[600]!),
              ),
            ],
          ),
        ),
        
        // Shot recording interface
        Expanded(
          child: _buildShotRecordingInterface(),
        ),
        
        // Navigation buttons
        _buildMobileNavigationButtons(),
      ],
    );
  }

  // Tablet Layout: Split view with player focus
  Widget _buildTabletLayout(Map<String, dynamic> currentGroup, List groups) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Assessment progress header
        AssessmentProgressHeader(
          groupTitle: _buildEnhancedGroupTitle(currentGroup),
          groupDescription: '${currentGroup['instructions'] ?? ''} • ${currentGroup['location'] ?? ''}',
          currentGroupIndex: _currentGroup,
          totalGroups: groups.length,
          currentItemIndex: _getCurrentOverallShotIndex(),
          totalItems: widget.players.length * _totalShotsPerPlayer,
          progressValue: _calculateOverallProgress(),
          bottomContent: _buildLocationInfo(currentGroup),
        ),
        
        // Main content split
        Expanded(
          child: Row(
            children: [
              // Left: Shot recording interface (60%)
              Expanded(
                flex: 6,
                child: _buildShotRecordingInterface(),
              ),
              
              // Right: Player queue and stats (40%)
              Container(
                width: ResponsiveConfig.dimension(context, 320),
                padding: ResponsiveConfig.paddingAll(context, 16),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  border: Border(
                    left: BorderSide(color: Colors.grey[300]!),
                  ),
                ),
                child: _buildPlayerQueueSidebar(),
              ),
            ],
          ),
        ),
        
        // Navigation buttons
        _buildNavigationButtons(),
      ],
    );
  }

  // Desktop Layout: Full interface with multiple panels
  Widget _buildDesktopLayout(Map<String, dynamic> currentGroup, List groups) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Assessment progress header
        AssessmentProgressHeader(
          groupTitle: _buildEnhancedGroupTitle(currentGroup),
          groupDescription: '${currentGroup['instructions'] ?? ''} • ${currentGroup['location'] ?? ''}',
          currentGroupIndex: _currentGroup,
          totalGroups: groups.length,
          currentItemIndex: _getCurrentOverallShotIndex(),
          totalItems: widget.players.length * _totalShotsPerPlayer,
          progressValue: _calculateOverallProgress(),
          bottomContent: _buildLocationInfo(currentGroup),
        ),
        
        // Main content with three panels
        Expanded(
          child: Row(
            children: [
              // Left: Player queue (25%)
              Container(
                width: ResponsiveConfig.dimension(context, 300),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  border: Border(
                    right: BorderSide(color: Colors.grey[300]!),
                  ),
                ),
                child: _buildDesktopPlayerQueue(),
              ),
              
              // Center: Shot recording interface (50%)
              Expanded(
                child: _buildShotRecordingInterface(),
              ),
              
              // Right: Analytics and history (25%)
              Container(
                width: ResponsiveConfig.dimension(context, 300),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  border: Border(
                    left: BorderSide(color: Colors.grey[300]!),
                  ),
                ),
                child: _buildAnalyticsSidebar(),
              ),
            ],
          ),
        ),
        
        // Enhanced navigation buttons
        _buildDesktopNavigationButtons(),
      ],
    );
  }

  // Main shot recording interface (used by all layouts)
  Widget _buildShotRecordingInterface() {
    return SingleChildScrollView(
      padding: ResponsiveConfig.paddingAll(context, 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Current player info card
          ResponsiveCard(
            padding: ResponsiveConfig.paddingAll(context, 16),
            backgroundColor: Colors.blue[50],
            child: Row(
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor: Colors.blue[600],
                  child: ResponsiveText(
                    _currentPlayer.jerseyNumber?.toString() ?? '?',
                    baseFontSize: 18,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                ResponsiveSpacing(multiplier: 2, direction: Axis.horizontal),
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ResponsiveText(
                        _currentPlayer.name,
                        baseFontSize: 20,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.blue[800],
                        ),
                      ),
                      ResponsiveText(
                        '${_currentPlayer.position ?? 'Unknown Position'}',
                        baseFontSize: 14,
                        style: TextStyle(color: Colors.blue[600]),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: ResponsiveConfig.paddingSymmetric(context, horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.blue[600],
                    borderRadius: ResponsiveConfig.borderRadius(context, 12),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      ResponsiveText(
                        'Shot ${_currentPlayerShot + 1}',
                        baseFontSize: 16,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      ResponsiveText(
                        'of $_totalShotsPerPlayer',
                        baseFontSize: 12,
                        style: const TextStyle(color: Colors.white70),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          ResponsiveSpacing(multiplier: 3),
          
          // Shot type selector
          _buildShotTypeSelector(),
          
          ResponsiveSpacing(multiplier: 3),
          
          // Zone selector (main interface)
          _buildSimpleZoneSelector(),
          
          ResponsiveSpacing(multiplier: 3),
          
          // Previous shots for this player
          _buildPlayerShotHistory(),
        ],
      ),
    );
  }

  // Simple shot type selector
  Widget _buildShotTypeSelector() {
    final shotTypes = ['Wrist Shot', 'Slap Shot', 'Snap Shot', 'Backhand', 'One-Timer'];
    
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ResponsiveText(
          'Shot Type',
          baseFontSize: 16,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.blueGrey[800],
          ),
        ),
        ResponsiveSpacing(multiplier: 1),
        ToggleButtonGroup(
          options: shotTypes,
          selectedOption: _currentShotType,
          onSelected: (type) => setState(() => _currentShotType = type),
          labelBuilder: (type) => type,
          colorMap: {for (var type in shotTypes) type: _primaryColor},
          borderRadius: ResponsiveConfig.borderRadius(context, 8),
        ),
      ],
    );
  }

  // Simplified zone selector - just click to record
  Widget _buildSimpleZoneSelector() {
    final netZones = List.generate(9, (index) => (index + 1).toString());
    const zoneLabels = {
      '1': 'Top Left',
      '2': 'Top Center',
      '3': 'Top Right',
      '4': 'Mid Left',
      '5': 'Mid Center',
      '6': 'Mid Right',
      '7': 'Bottom Left',
      '8': 'Bottom Center',
      '9': 'Bottom Right',
    };

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ResponsiveText(
          'Tap Zone to Record Shot',
          baseFontSize: 16,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.blueGrey[800],
          ),
        ),
        ResponsiveSpacing(multiplier: 1),

        // Instruction text
        Container(
          padding: ResponsiveConfig.paddingAll(context, 12),
          decoration: BoxDecoration(
            color: Colors.green[50],
            borderRadius: ResponsiveConfig.borderRadius(context, 8),
            border: Border.all(color: Colors.green[200]!),
          ),
          child: Row(
            children: [
              Icon(Icons.touch_app, color: Colors.green[700]),
              ResponsiveSpacing(multiplier: 1, direction: Axis.horizontal),
              Expanded(
                child: ResponsiveText(
                  'Simply tap where the shot went to record it instantly',
                  baseFontSize: 12,
                  style: TextStyle(color: Colors.green[800]),
                ),
              ),
            ],
          ),
        ),
        
        ResponsiveSpacing(multiplier: 2),

        // Net zones with miss buttons
        Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // "Miss High" button
              Container(
                margin: ResponsiveConfig.paddingSymmetric(context, vertical: 8),
                child: _buildMissButton(
                  'miss_high', 
                  'Miss High ⬆️', 
                  width: ResponsiveConfig.dimension(context, 200),
                  height: ResponsiveConfig.dimension(context, 50),
                ),
              ),

              // Main net grid with miss left/right
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Miss Left button
                  Container(
                    margin: ResponsiveConfig.paddingSymmetric(context, horizontal: 8),
                    child: _buildMissButton(
                      'miss_left', 
                      'Miss\nLeft\n⬅️',
                      width: ResponsiveConfig.dimension(context, 70),
                      height: ResponsiveConfig.dimension(context, 200),
                    ),
                  ),

                  // 3x3 Net zones
                  Container(
                    width: ResponsiveConfig.dimension(context, 200),
                    height: ResponsiveConfig.dimension(context, 200),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.black, width: 3),
                      borderRadius: ResponsiveConfig.borderRadius(context, 8),
                      color: Colors.grey[50],
                    ),
                    child: GridView.builder(
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 3,
                        mainAxisSpacing: 2,
                        crossAxisSpacing: 2,
                      ),
                      itemCount: netZones.length,
                      itemBuilder: (context, index) {
                        final zone = netZones[index];
                        final isIntended = _intendedZones.contains(zone);
                        
                        return GestureDetector(
                          onTap: () => _recordShotInZone(zone),
                          child: Container(
                            margin: ResponsiveConfig.paddingAll(context, 1),
                            decoration: BoxDecoration(
                              color: isIntended ? Colors.green[200] : Colors.white,
                              border: Border.all(
                                color: isIntended ? Colors.green[400]! : Colors.grey[400]!,
                                width: isIntended ? 2 : 1,
                              ),
                              borderRadius: ResponsiveConfig.borderRadius(context, 6),
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                ResponsiveText(
                                  zone,
                                  baseFontSize: 20,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black,
                                  ),
                                ),
                                ResponsiveText(
                                  zoneLabels[zone] ?? '',
                                  baseFontSize: 8,
                                  style: TextStyle(color: Colors.grey[600]),
                                  textAlign: TextAlign.center,
                                ),
                                if (isIntended)
                                  Container(
                                    margin: ResponsiveConfig.paddingSymmetric(context, vertical: 1),
                                    child: ResponsiveText(
                                      '🎯',
                                      baseFontSize: 10,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),

                  // Miss Right button
                  Container(
                    margin: ResponsiveConfig.paddingSymmetric(context, horizontal: 8),
                    child: _buildMissButton(
                      'miss_right', 
                      'Miss\nRight\n➡️',
                      width: ResponsiveConfig.dimension(context, 70),
                      height: ResponsiveConfig.dimension(context, 200),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  // Miss button builder
  Widget _buildMissButton(String missType, String label, {double width = 60, double height = 60}) {
    return GestureDetector(
      onTap: () => _recordShotInZone(missType),
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: Colors.red[100],
          border: Border.all(color: Colors.red[300]!, width: 2),
          borderRadius: ResponsiveConfig.borderRadius(context, 8),
        ),
        child: Center(
          child: ResponsiveText(
            label,
            baseFontSize: 12,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.red[800],
            ),
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }

  // Player shot history for current player
  Widget _buildPlayerShotHistory() {
    final playerId = _currentPlayer.id.toString();
    final playerShots = _gridData[playerId] ?? {};
    
    if (playerShots.isEmpty) {
      return Container();
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ResponsiveText(
          '${_currentPlayer.name}\'s Shots',
          baseFontSize: 16,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.blueGrey[800],
          ),
        ),
        ResponsiveSpacing(multiplier: 1),
        
        Container(
          height: ResponsiveConfig.dimension(context, 80),
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: _totalShotsPerPlayer,
            itemBuilder: (context, shotIndex) {
              final shotData = playerShots[shotIndex];
              final isCompleted = shotData != null;
              final isCurrent = shotIndex == _currentPlayerShot;
              
              return Container(
                width: ResponsiveConfig.dimension(context, 70),
                margin: ResponsiveConfig.paddingSymmetric(context, horizontal: 4),
                child: GestureDetector(
                  onTap: isCurrent || !isCompleted ? null : () {
                    setState(() {
                      _currentPlayerShot = shotIndex;
                    });
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      color: isCurrent 
                          ? Colors.blue[100]
                          : isCompleted 
                              ? (shotData!['success'] ? Colors.green[100] : Colors.red[100])
                              : Colors.grey[100],
                      border: Border.all(
                        color: isCurrent 
                            ? Colors.blue[600]!
                            : isCompleted 
                                ? (shotData!['success'] ? Colors.green : Colors.red)
                                : Colors.grey[400]!,
                        width: isCurrent ? 2 : 1,
                      ),
                      borderRadius: ResponsiveConfig.borderRadius(context, 8),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        ResponsiveText(
                          'Shot ${shotIndex + 1}',
                          baseFontSize: 10,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: isCurrent ? Colors.blue[800] : Colors.black,
                          ),
                        ),
                        if (isCompleted) ...[
                          ResponsiveSpacing(multiplier: 0.5),
                          ResponsiveText(
                            'Zone ${shotData!['zone']}',
                            baseFontSize: 9,
                            style: const TextStyle(color: Colors.black54),
                          ),
                          ResponsiveText(
                            shotData['outcome'] as String? ?? '',
                            baseFontSize: 8,
                            style: TextStyle(
                              color: _getOutcomeColor(shotData['outcome'] as String? ?? ''),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ] else if (isCurrent) ...[
                          ResponsiveSpacing(multiplier: 0.5),
                          Icon(
                            Icons.radio_button_checked,
                            color: Colors.blue[600],
                            size: ResponsiveConfig.iconSize(context, 16),
                          ),
                        ] else ...[
                          ResponsiveSpacing(multiplier: 0.5),
                          Icon(
                            Icons.circle_outlined,
                            color: Colors.grey[400],
                            size: ResponsiveConfig.iconSize(context, 16),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  // Player queue sidebar (tablet)
  Widget _buildPlayerQueueSidebar() {
    return SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ResponsiveText(
            'Player Queue',
            baseFontSize: 18,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.blueGrey[800],
            ),
          ),
          ResponsiveSpacing(multiplier: 2),
          
          ...widget.players.asMap().entries.map((entry) {
            final index = entry.key;
            final player = entry.value;
            final isCurrent = index == _currentPlayerIndex;
            final isCompleted = _isPlayerCompleted(player.id.toString());
            final shotsCompleted = _getPlayerShotsCompleted(player.id.toString());
            
            return Container(
              margin: ResponsiveConfig.paddingSymmetric(context, vertical: 4),
              padding: ResponsiveConfig.paddingAll(context, 12),
              decoration: BoxDecoration(
                color: isCurrent 
                    ? Colors.blue[50]
                    : isCompleted 
                        ? Colors.green[50]
                        : Colors.grey[50],
                border: Border.all(
                  color: isCurrent 
                      ? Colors.blue[300]!
                      : isCompleted 
                          ? Colors.green[300]!
                          : Colors.grey[300]!,
                  width: isCurrent ? 2 : 1,
                ),
                borderRadius: ResponsiveConfig.borderRadius(context, 8),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 16,
                        backgroundColor: isCurrent 
                            ? Colors.blue[600]
                            : isCompleted 
                                ? Colors.green[600]
                                : Colors.grey[600],
                        child: ResponsiveText(
                          player.jerseyNumber?.toString() ?? '?',
                          baseFontSize: 12,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
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
                              player.name,
                              baseFontSize: 14,
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            ResponsiveText(
                              player.position ?? 'Unknown',
                              baseFontSize: 10,
                              style: TextStyle(color: Colors.grey[600]),
                            ),
                          ],
                        ),
                      ),
                      if (isCurrent)
                        Container(
                          padding: ResponsiveConfig.paddingSymmetric(context, horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.blue[600],
                            borderRadius: ResponsiveConfig.borderRadius(context, 8),
                          ),
                          child: ResponsiveText(
                            'CURRENT',
                            baseFontSize: 8,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        )
                      else if (isCompleted)
                        Icon(
                          Icons.check_circle,
                          color: Colors.green[600],
                          size: ResponsiveConfig.iconSize(context, 20),
                        ),
                    ],
                  ),
                  ResponsiveSpacing(multiplier: 1),
                  LinearProgressIndicator(
                    value: shotsCompleted / _totalShotsPerPlayer,
                    backgroundColor: Colors.grey[200],
                    valueColor: AlwaysStoppedAnimation<Color>(
                      isCurrent 
                          ? Colors.blue[600]!
                          : isCompleted 
                              ? Colors.green[600]!
                              : Colors.grey[400]!,
                    ),
                  ),
                  ResponsiveSpacing(multiplier: 0.5),
                  ResponsiveText(
                    '$shotsCompleted/$_totalShotsPerPlayer shots',
                    baseFontSize: 10,
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                ],
              ),
            );
          }).toList(),
        ],
      ),
    );
  }

  // Desktop player queue
  Widget _buildDesktopPlayerQueue() {
    return SingleChildScrollView(
      padding: ResponsiveConfig.paddingAll(context, 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ResponsiveText(
            'Player Queue',
            baseFontSize: 18,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.blueGrey[800],
            ),
          ),
          ResponsiveSpacing(multiplier: 2),
          
          ...widget.players.asMap().entries.map((entry) {
            final index = entry.key;
            final player = entry.value;
            final isCurrent = index == _currentPlayerIndex;
            final isCompleted = _isPlayerCompleted(player.id.toString());
            final shotsCompleted = _getPlayerShotsCompleted(player.id.toString());
            
            return GestureDetector(
              onTap: isCompleted ? () => _jumpToPlayer(index) : null,
              child: Container(
                margin: ResponsiveConfig.paddingSymmetric(context, vertical: 6),
                padding: ResponsiveConfig.paddingAll(context, 12),
                decoration: BoxDecoration(
                  color: isCurrent 
                      ? Colors.blue[50]
                      : isCompleted 
                          ? Colors.green[50]
                          : Colors.grey[50],
                  border: Border.all(
                    color: isCurrent 
                        ? Colors.blue[300]!
                        : isCompleted 
                            ? Colors.green[300]!
                            : Colors.grey[300]!,
                    width: isCurrent ? 2 : 1,
                  ),
                  borderRadius: ResponsiveConfig.borderRadius(context, 8),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: ResponsiveConfig.dimension(context, 30),
                          height: ResponsiveConfig.dimension(context, 30),
                          decoration: BoxDecoration(
                            color: isCurrent 
                                ? Colors.blue[600]
                                : isCompleted 
                                    ? Colors.green[600]
                                    : Colors.grey[600],
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: ResponsiveText(
                              (index + 1).toString(),
                              baseFontSize: 12,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
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
                                player.name,
                                baseFontSize: 14,
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                              ResponsiveText(
                                '#${player.jerseyNumber ?? '?'} • ${player.position ?? 'Unknown'}',
                                baseFontSize: 10,
                                style: TextStyle(color: Colors.grey[600]),
                              ),
                            ],
                          ),
                        ),
                        if (isCurrent)
                          Container(
                            padding: ResponsiveConfig.paddingSymmetric(context, horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.blue[600],
                              borderRadius: ResponsiveConfig.borderRadius(context, 10),
                            ),
                            child: ResponsiveText(
                              'ACTIVE',
                              baseFontSize: 10,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          )
                        else if (isCompleted)
                          Icon(
                            Icons.check_circle,
                            color: Colors.green[600],
                            size: ResponsiveConfig.iconSize(context, 24),
                          ),
                      ],
                    ),
                    ResponsiveSpacing(multiplier: 1),
                    LinearProgressIndicator(
                      value: shotsCompleted / _totalShotsPerPlayer,
                      backgroundColor: Colors.grey[200],
                      valueColor: AlwaysStoppedAnimation<Color>(
                        isCurrent 
                            ? Colors.blue[600]!
                            : isCompleted 
                                ? Colors.green[600]!
                                : Colors.grey[400]!,
                      ),
                    ),
                    ResponsiveSpacing(multiplier: 0.5),
                    ResponsiveText(
                      '$shotsCompleted/$_totalShotsPerPlayer shots completed',
                      baseFontSize: 10,
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ],
      ),
    );
  }

  // Analytics sidebar
  Widget _buildAnalyticsSidebar() {
    return SingleChildScrollView(
      padding: ResponsiveConfig.paddingAll(context, 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ResponsiveText(
            'Live Stats',
            baseFontSize: 18,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.blueGrey[800],
            ),
          ),
          ResponsiveSpacing(multiplier: 2),
          
          _buildTeamStatsCard(),
          ResponsiveSpacing(multiplier: 2),
          _buildCurrentPlayerStats(),
          ResponsiveSpacing(multiplier: 2),
          _buildQuickActions(),
        ],
      ),
    );
  }

  Widget _buildTeamStatsCard() {
    final totalShots = _getTotalShotsRecorded();
    final totalPossible = _getCurrentOverallShotIndex() + 1;
    final completionRate = totalPossible > 0 ? totalShots / totalPossible : 0.0;
    
    return ResponsiveCard(
      padding: ResponsiveConfig.paddingAll(context, 12),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ResponsiveText(
            'Team Progress',
            baseFontSize: 14,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.blueGrey[800],
            ),
          ),
          ResponsiveSpacing(multiplier: 1.5),
          
          _buildStatRow('Players Completed', '${_getCompletedPlayersCount()}/${widget.players.length}'),
          _buildStatRow('Total Shots', '$totalShots/$totalPossible'),
          _buildStatRow('Completion Rate', '${(completionRate * 100).toStringAsFixed(1)}%'),
          
          ResponsiveSpacing(multiplier: 1),
          LinearProgressIndicator(
            value: completionRate,
            backgroundColor: Colors.grey[200],
            valueColor: AlwaysStoppedAnimation<Color>(Colors.blue[600]!),
          ),
        ],
      ),
    );
  }

  Widget _buildCurrentPlayerStats() {
    final playerId = _currentPlayer.id.toString();
    final playerShots = _gridData[playerId] ?? {};
    final completedShots = playerShots.length;
    final successfulShots = playerShots.values.where((shot) => shot['success'] == true).length;
    final successRate = completedShots > 0 ? successfulShots / completedShots : 0.0;
    
    return ResponsiveCard(
      padding: ResponsiveConfig.paddingAll(context, 12),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ResponsiveText(
            '${_currentPlayer.name} Stats',
            baseFontSize: 14,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.blueGrey[800],
            ),
          ),
          ResponsiveSpacing(multiplier: 1.5),
          
          _buildStatRow('Shots Completed', '$completedShots/$_totalShotsPerPlayer'),
          _buildStatRow('Success Rate', '${(successRate * 100).toStringAsFixed(1)}%'),
          _buildStatRow('Goals', '$successfulShots'),
          
          ResponsiveSpacing(multiplier: 1),
          LinearProgressIndicator(
            value: completedShots / _totalShotsPerPlayer,
            backgroundColor: Colors.grey[200],
            valueColor: AlwaysStoppedAnimation<Color>(Colors.green[600]!),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions() {
    return ResponsiveCard(
      padding: ResponsiveConfig.paddingAll(context, 12),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ResponsiveText(
            'Quick Actions',
            baseFontSize: 14,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.blueGrey[800],
            ),
          ),
          ResponsiveSpacing(multiplier: 1.5),
          
          ResponsiveButton(
            text: 'Skip Player',
            onPressed: _skipCurrentPlayer,
            baseHeight: 32,
            width: double.infinity,
            backgroundColor: Colors.orange[600],
            foregroundColor: Colors.white,
            icon: Icons.skip_next,
          ),
          ResponsiveSpacing(multiplier: 1),
          
          ResponsiveButton(
            text: 'Reset Player',
            onPressed: _resetCurrentPlayer,
            baseHeight: 32,
            width: double.infinity,
            backgroundColor: Colors.red[600],
            foregroundColor: Colors.white,
            icon: Icons.refresh,
          ),
        ],
      ),
    );
  }

  Widget _buildStatRow(String label, String value) {
    return Padding(
      padding: ResponsiveConfig.paddingSymmetric(context, vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          ResponsiveText(
            label,
            baseFontSize: 11,
            style: TextStyle(color: Colors.blueGrey[600]),
          ),
          ResponsiveText(
            value,
            baseFontSize: 11,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.blueGrey[800],
            ),
          ),
        ],
      ),
    );
  }

  // Navigation buttons for different layouts
  Widget _buildMobileNavigationButtons() {
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
      child: Row(
        children: [
          if (_canGoToPreviousShot())
            Expanded(
              child: ResponsiveButton(
                text: 'Previous',
                onPressed: _goToPreviousShot,
                baseHeight: 48,
                backgroundColor: Colors.blueGrey,
                foregroundColor: Colors.white,
                icon: Icons.arrow_back,
              ),
            ),
          
          if (_canGoToPreviousShot()) ResponsiveSpacing(multiplier: 2, direction: Axis.horizontal),
          
          Expanded(
            flex: 2,
            child: ResponsiveButton(
              text: _getNextButtonText(),
              onPressed: _canAdvance() ? _goToNextShot : null,
              baseHeight: 48,
              backgroundColor: _getNextButtonColor(),
              foregroundColor: Colors.white,
              icon: _getNextButtonIcon(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavigationButtons() {
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
      child: Row(
        children: [
          if (_canGoToPreviousShot())
            ResponsiveButton(
              text: 'Previous Shot',
              onPressed: _goToPreviousShot,
              baseHeight: 48,
              backgroundColor: Colors.blueGrey,
              foregroundColor: Colors.white,
              icon: Icons.arrow_back,
            ),
          
          const Spacer(),
          
          ResponsiveButton(
            text: _getNextButtonText(),
            onPressed: _canAdvance() ? _goToNextShot : null,
            baseHeight: 48,
            backgroundColor: _getNextButtonColor(),
            foregroundColor: Colors.white,
            icon: _getNextButtonIcon(),
          ),
        ],
      ),
    );
  }

  Widget _buildDesktopNavigationButtons() {
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
      child: Row(
        children: [
          ResponsiveButton(
            text: 'Bulk Entry',
            onPressed: _showBulkEntryDialog,
            baseHeight: 48,
            backgroundColor: Colors.purple[600],
            foregroundColor: Colors.white,
            icon: Icons.speed,
          ),
          
          ResponsiveSpacing(multiplier: 2, direction: Axis.horizontal),
          
          ResponsiveButton(
            text: 'Export Data',
            onPressed: _exportCurrentData,
            baseHeight: 48,
            backgroundColor: Colors.indigo[600],
            foregroundColor: Colors.white,
            icon: Icons.download,
          ),
          
          const Spacer(),
          
          if (_canGoToPreviousShot())
            ResponsiveButton(
              text: 'Previous Shot',
              onPressed: _goToPreviousShot,
              baseHeight: 48,
              backgroundColor: Colors.blueGrey,
              foregroundColor: Colors.white,
              icon: Icons.arrow_back,
            ),
          
          ResponsiveSpacing(multiplier: 2, direction: Axis.horizontal),
          
          SizedBox(
            width: ResponsiveConfig.dimension(context, 200),
            child: ResponsiveButton(
              text: _getNextButtonText(),
              onPressed: _canAdvance() ? _goToNextShot : null,
              baseHeight: 48,
              backgroundColor: _getNextButtonColor(),
              foregroundColor: Colors.white,
              icon: _getNextButtonIcon(),
            ),
          ),
        ],
      ),
    );
  }

  // Core action methods
  void _recordShotInZone(String zone) {
    final playerId = _currentPlayer.id.toString();
    final groups = widget.assessment['groups'] as List;
    final currentGroup = groups[_currentGroup] as Map<String, dynamic>;
    
    // Auto-determine outcome
    String outcome;
    if (zone.startsWith('miss_')) {
      outcome = 'Miss';
    } else {
      outcome = 'Goal'; // Assume goal for shots that hit the net
    }
    
    // Auto-determine success based on intended zones
    bool success;
    if (zone.startsWith('miss_')) {
      success = false;
    } else if (outcome != 'Goal') {
      success = false;
    } else {
      // For directional assessments, check if shot hit intended zones
      if (_intendedDirection != null && _intendedZones.isNotEmpty) {
        success = _intendedZones.contains(zone);
      } else {
        success = true;
      }
    }
    
    // Create shot data
    final shotData = {
      'zone': zone,
      'type': _currentShotType,
      'outcome': outcome,
      'success': success,
      'velocity': null, // Could add velocity input later
      'timestamp': DateTime.now().toIso8601String(),
      
      // Assessment tracking fields
      'source': 'team_assessment_batch',
      'assessment_id': widget.assessment['assessmentId']?.toString(),
      'group_index': _currentGroup,
      'group_id': currentGroup['id']?.toString() ?? _currentGroup.toString(),
      
      // Enhanced intended targeting
      'intended_direction': _intendedDirection,
      'intended_zone': zone.startsWith('miss_') ? null : zone,
    };
    
    // Update grid data
    _gridData[playerId] ??= {};
    _gridData[playerId]![_currentPlayerShot] = shotData;
    
    // Call the callback
    widget.onAddResult(playerId, _currentGroup, shotData);
    
    // Auto-advance
    _autoAdvance();
  }

  void _autoAdvance() {
    if (_currentPlayerShot < _totalShotsPerPlayer - 1) {
      // Next shot for same player
      setState(() {
        _currentPlayerShot++;
      });
    } else if (_currentPlayerIndex < widget.players.length - 1) {
      // Move to next player
      setState(() {
        _currentPlayerIndex++;
        _currentPlayerShot = 0;
      });
    } else {
      // All players completed - finish assessment
      _completeAssessment();
    }
  }

  void _goToPreviousShot() {
    if (_currentPlayerShot > 0) {
      setState(() {
        _currentPlayerShot--;
      });
    } else if (_currentPlayerIndex > 0) {
      setState(() {
        _currentPlayerIndex--;
        _currentPlayerShot = _totalShotsPerPlayer - 1;
      });
    }
  }

  void _goToNextShot() {
    _autoAdvance();
  }

  void _jumpToPlayer(int playerIndex) {
    if (playerIndex >= 0 && playerIndex < widget.players.length) {
      setState(() {
        _currentPlayerIndex = playerIndex;
        _currentPlayerShot = 0;
      });
    }
  }

  void _completeAssessment() {
    widget.onComplete();
  }

  // Helper methods
  String _buildEnhancedGroupTitle(Map<String, dynamic> currentGroup) {
    final intendedZones = currentGroup['intendedZones'] as List<dynamic>? ?? 
                          currentGroup['targetZones'] as List<dynamic>? ?? [];
    final groupTitle = currentGroup['name'] as String? ?? 
                       currentGroup['title'] as String? ?? 
                       'Group ${_currentGroup + 1}';
    final intendedZonesDisplay = currentGroup['intendedZonesDisplay']?.toString();
    
    return intendedZonesDisplay != null
        ? '$groupTitle (Target: $intendedZonesDisplay)'
        : intendedZones.isNotEmpty
            ? '$groupTitle (Target: ${intendedZones.join(', ')})'
            : groupTitle;
  }

  Widget _buildLocationInfo(Map<String, dynamic>? group) {
    final intendedZones = group?['intendedZones'] as List<dynamic>? ?? 
                          group?['targetZones'] as List<dynamic>? ?? [];
    final targetSide = group?['parameters']?['targetSide'] as String? ?? '';

    return Container(
      padding: ResponsiveConfig.paddingAll(context, 12),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: ResponsiveConfig.borderRadius(context, 8),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.location_on, color: Colors.blueGrey[700]),
              ResponsiveSpacing(multiplier: 1.5, direction: Axis.horizontal),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ResponsiveText(
                      'Shot Location:',
                      baseFontSize: 14,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.blueGrey[700],
                      ),
                    ),
                    ResponsiveText(
                      group?['location']?.toString() ?? 'Not specified',
                      baseFontSize: 14,
                      style: TextStyle(color: Colors.blueGrey[800]),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (intendedZones.isNotEmpty) ...[
            ResponsiveSpacing(multiplier: 1),
            Container(
              padding: ResponsiveConfig.paddingAll(context, 8),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: ResponsiveConfig.borderRadius(context, 6),
                border: Border.all(color: Colors.blue[200]!),
              ),
              child: Row(
                children: [
                  Icon(Icons.my_location, color: Colors.blue[700], size: ResponsiveConfig.iconSize(context, 16)),
                  ResponsiveSpacing(multiplier: 1, direction: Axis.horizontal),
                  Expanded(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ResponsiveText(
                          'Target Zones:',
                          baseFontSize: 12,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.blue[700],
                          ),
                        ),
                        ResponsiveText(
                          group?['intendedZonesDisplay']?.toString() ?? 
                          '${intendedZones.join(', ')} (${_getTargetDescription(targetSide)})',
                          baseFontSize: 12,
                          style: TextStyle(color: Colors.blue[800]),
                        ),
                      ],
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

  String _getTargetDescription(String targetSide) {
    switch (targetSide.toLowerCase()) {
      case 'right':
      case 'east':
        return 'Right side of net';
      case 'left':
      case 'west':
        return 'Left side of net';
      case 'center':
        return 'Center line';
      case 'high':
      case 'north':
        return 'Top shelf';
      case 'low':
      case 'south':
        return 'Bottom shelf';
      default:
        return 'Target area';
    }
  }

  Color _getOutcomeColor(String outcome) {
    switch (outcome) {
      case 'Goal':
        return Colors.green;
      case 'Save':
        return Colors.orange;
      case 'Miss':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  // Navigation helper methods
  bool _canGoToPreviousShot() {
    return _currentPlayerIndex > 0 || _currentPlayerShot > 0;
  }

  bool _canAdvance() {
    // We can always advance (even without recording) - allows skipping
    return true;
  }

  String _getNextButtonText() {
    if (_currentPlayerIndex >= widget.players.length - 1 && _currentPlayerShot >= _totalShotsPerPlayer - 1) {
      return 'Complete Assessment';
    } else if (_currentPlayerShot >= _totalShotsPerPlayer - 1) {
      return 'Next Player';
    } else {
      return 'Next Shot';
    }
  }

  Color _getNextButtonColor() {
    if (_currentPlayerIndex >= widget.players.length - 1 && _currentPlayerShot >= _totalShotsPerPlayer - 1) {
      return _successColor;
    } else {
      return _primaryColor;
    }
  }

  IconData _getNextButtonIcon() {
    if (_currentPlayerIndex >= widget.players.length - 1 && _currentPlayerShot >= _totalShotsPerPlayer - 1) {
      return Icons.check_circle;
    } else if (_currentPlayerShot >= _totalShotsPerPlayer - 1) {
      return Icons.person;
    } else {
      return Icons.arrow_forward;
    }
  }

  // Statistics helper methods
  int _getCurrentOverallShotIndex() {
    return (_currentPlayerIndex * _totalShotsPerPlayer) + _currentPlayerShot;
  }

  double _calculateOverallProgress() {
    final totalPossibleShots = widget.players.length * _totalShotsPerPlayer;
    final currentShot = _getCurrentOverallShotIndex() + 1;
    return currentShot / totalPossibleShots;
  }

  bool _isPlayerCompleted(String playerId) {
    final playerShots = _gridData[playerId] ?? {};
    return playerShots.length >= _totalShotsPerPlayer;
  }

  int _getPlayerShotsCompleted(String playerId) {
    final playerShots = _gridData[playerId] ?? {};
    return playerShots.length;
  }

  int _getTotalShotsRecorded() {
    int total = 0;
    for (var player in widget.players) {
      final playerId = player.id.toString();
      final playerShots = _gridData[playerId] ?? {};
      total += playerShots.length;
    }
    return total;
  }

  int _getCompletedPlayersCount() {
    int count = 0;
    for (var player in widget.players) {
      if (_isPlayerCompleted(player.id.toString())) {
        count++;
      }
    }
    return count;
  }

  // Quick action methods
  void _skipCurrentPlayer() {
    if (_currentPlayerIndex < widget.players.length - 1) {
      setState(() {
        _currentPlayerIndex++;
        _currentPlayerShot = 0;
      });
    } else {
      _completeAssessment();
    }
  }

  void _resetCurrentPlayer() {
    final playerId = _currentPlayer.id.toString();
    setState(() {
      _gridData[playerId] = {};
      _currentPlayerShot = 0;
    });
  }

  void _showBulkEntryDialog() {
    // Placeholder for bulk entry functionality
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: ResponsiveText('Bulk entry feature - Coming Soon', baseFontSize: 14),
      ),
    );
  }

  void _exportCurrentData() {
    // Placeholder for export functionality
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: ResponsiveText('Export feature - Coming Soon', baseFontSize: 14),
      ),
    );
  }
}