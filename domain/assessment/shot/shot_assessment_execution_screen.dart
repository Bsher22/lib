import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:hockey_shot_tracker/models/shot.dart';
import 'package:hockey_shot_tracker/models/assessment_config.dart';
import 'package:hockey_shot_tracker/providers/app_state.dart';
import 'package:hockey_shot_tracker/services/dialog_service.dart';
import 'package:hockey_shot_tracker/services/database_service.dart';
import 'package:hockey_shot_tracker/widgets/core/form/standard_text_field.dart';
import 'package:hockey_shot_tracker/widgets/core/selection/filter_chip_group.dart';
import 'package:hockey_shot_tracker/widgets/core/selection/grid_selector.dart';
import 'package:hockey_shot_tracker/widgets/core/selection/toggle_button_group.dart';
import 'package:hockey_shot_tracker/widgets/core/state/index.dart';
import 'package:hockey_shot_tracker/widgets/core/timer/index.dart';
import 'package:hockey_shot_tracker/widgets/core/state/loading_overlay.dart';
import 'package:hockey_shot_tracker/widgets/domain/assessment/common/assessment_progress_header.dart';
import 'package:hockey_shot_tracker/responsive_system/index.dart';

// Constants for UI styling
const _primaryColor = Colors.cyanAccent;
const _successColor = Colors.green;
const _errorColor = Colors.red;
const _warningColor = Colors.orange;

class ShotAssessmentExecutionScreen extends StatefulWidget {
  final Map<String, dynamic> assessment;
  final Map<int, List<Shot>> shotResults;
  final void Function(int, Shot) onAddShot;
  final VoidCallback onComplete;

  const ShotAssessmentExecutionScreen({
    super.key,
    required this.assessment,
    required this.shotResults,
    required this.onAddShot,
    required this.onComplete,
  });

  @override
  State<ShotAssessmentExecutionScreen> createState() => _ShotAssessmentExecutionScreenState();
}

class _ShotAssessmentExecutionScreenState extends State<ShotAssessmentExecutionScreen> {
  int _currentGroup = 0;
  int _currentShot = 0;
  int _localShotCount = 0;
  bool _isRecording = false;
  String _selectedZone = '';
  String _selectedShotType = '';
  String _selectedOutcome = 'Goal';
  
  // Directional targeting system
  String? _intendedDirection;
  List<String> _intendedZones = [];

  final TextEditingController _powerController = TextEditingController();
  final UnifiedTimerController _timerController = UnifiedTimerController();

  @override
  void initState() {
    super.initState();
    _initializeShotType();
    _localShotCount = widget.shotResults[_currentGroup]?.length ?? 0;
    _updateIntendedZoneForGroup();
  }

  void _initializeShotType() {
    final groups = widget.assessment['groups'] as List<dynamic>? ?? [];
    if (groups.isNotEmpty) {
      final defaultType = (groups[_currentGroup] as Map<String, dynamic>?)?['defaultType'] as String?;
      if (defaultType != null && defaultType.isNotEmpty) {
        _selectedShotType = defaultType;
      }
    }
  }

  void _updateIntendedZoneForGroup() {
    final groups = widget.assessment['groups'] as List<dynamic>? ?? [];
    if (groups.isNotEmpty && _currentGroup < groups.length) {
      final group = groups[_currentGroup] as Map<String, dynamic>?;
      final targetZones = group?['targetZones'] as List<dynamic>? ?? [];
      final targetSide = group?['parameters']?['targetSide'] as String? ?? '';
      
      _intendedZones = targetZones.map((z) => z.toString()).toList();
      _intendedDirection = _getDirectionFromSideOrZones(targetSide, _intendedZones);
      
      debugPrint('ShotExecution: Set intended direction to $_intendedDirection for zones $_intendedZones');
    } else {
      _intendedDirection = null;
      _intendedZones = [];
    }
  }

  String? _getDirectionFromSideOrZones(String targetSide, List<String> zones) {
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
    
    final zoneSet = zones.toSet();
    if (zoneSet.containsAll({'3', '6', '9'})) return 'East';
    if (zoneSet.containsAll({'1', '4', '7'})) return 'West';
    if (zoneSet.containsAll({'1', '2', '3'})) return 'North';
    if (zoneSet.containsAll({'7', '8', '9'})) return 'South';
    if (zoneSet.containsAll({'2', '5', '8'})) return 'Center';
    
    return null;
  }

  @override
  void dispose() {
    _powerController.dispose();
    _timerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) async {
        if (didPop) return;
        final shouldPop = await _handleBackPress();
        if (shouldPop && mounted) {
          Navigator.of(context).pop();
        }
      },
      child: AdaptiveScaffold(
        title: 'Shot Assessment Execution',
        backgroundColor: Colors.grey[100],
        body: LoadingOverlay(
          isLoading: _isRecording,
          message: 'Recording shot...',
          color: _primaryColor,
          backgroundColor: Colors.black.withOpacity(0.7),
          child: AdaptiveLayout(
            builder: (deviceType, isLandscape) {
              return Column(
                children: [
                  _buildProgressHeader(),
                  Expanded(child: _buildShotDataForm(deviceType, isLandscape)),
                  _buildRecordButton(deviceType),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Future<bool> _handleBackPress() async {
    final shouldPop = await DialogService.showConfirmation(
      context,
      title: 'Exit Assessment?',
      message: 'You have unsaved shots. Exit anyway?',
      confirmLabel: 'Exit',
      cancelLabel: 'Stay',
    );
    if (shouldPop == true) {
      Provider.of<AppState>(context, listen: false).clearCurrentAssessmentId();
    }
    return shouldPop ?? false;
  }

  Widget _buildProgressHeader() {
    final group = widget.assessment['groups'][_currentGroup] as Map<String, dynamic>?;
    final totalShots = (widget.assessment['groups'] as List<Map<String, dynamic>>?)?.fold<int>(
          0,
          (int sum, Map<String, dynamic> g) => sum + (g['shots'] as int? ?? 0),
        ) ??
        0;
    final recordedShots = widget.shotResults.entries.fold<int>(
      0,
      (int sum, MapEntry<int, List<Shot>> entry) => sum + entry.value.length,
    );

    final intendedZones = group?['intendedZones'] as List<dynamic>? ?? [];
    final groupTitle = group?['title']?.toString() ?? 'Group ${_currentGroup + 1}';
    final intendedZonesDisplay = group?['intendedZonesDisplay']?.toString();
    final enhancedTitle = intendedZonesDisplay != null
        ? '$groupTitle (Target: $intendedZonesDisplay)'
        : intendedZones.isNotEmpty
            ? '$groupTitle (Target: ${intendedZones.join(', ')})'
            : groupTitle;

    return AssessmentProgressHeader(
      groupTitle: enhancedTitle,
      groupDescription: group?['instructions']?.toString() ?? '',
      currentGroupIndex: _currentGroup,
      totalGroups: (widget.assessment['groups'] as List<dynamic>?)?.length ?? 0,
      currentItemIndex: _localShotCount,
      totalItems: group?['shots'] as int? ?? 0,
      progressValue: totalShots > 0 ? recordedShots / totalShots : 0.0,
      bottomContent: _buildLocationInfo(group),
    );
  }

  Widget _buildLocationInfo(Map<String, dynamic>? group) {
    final intendedZones = group?['intendedZones'] as List<dynamic>? ?? [];
    final targetSide = group?['parameters']?['targetSide'] as String? ?? '';

    return ResponsiveCard(
      padding: ResponsiveConfig.paddingAll(context, 12),
      margin: ResponsiveConfig.paddingSymmetric(context, horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.location_on, color: Colors.blueGrey[700]),
              ResponsiveSpacing(multiplier: 1.5, direction: Axis.horizontal),
              Expanded(
                child: Column(
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
            ResponsiveCard(
              padding: ResponsiveConfig.paddingAll(context, 8),
              child: Row(
                children: [
                  Icon(Icons.my_location, color: Colors.blue[700], size: ResponsiveConfig.iconSize(context, 16)),
                  ResponsiveSpacing(multiplier: 1, direction: Axis.horizontal),
                  Expanded(
                    child: Column(
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
                          group?['intendedZonesDisplay']?.toString() ?? '${intendedZones.join(', ')} (${_getTargetDescription(targetSide)})',
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
    switch (targetSide) {
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

  void _showIntendedZoneSelector() {
    final group = widget.assessment['groups'][_currentGroup] as Map<String, dynamic>?;
    final allTargetZones = group?['targetZones'] as List<dynamic>? ?? 
                          ['1', '2', '3', '4', '5', '6', '7', '8', '9'];
    
    showDialog(
      context: context,
      builder: (context) => AdaptiveLayout(
        builder: (deviceType, isLandscape) {
          return AlertDialog(
            title: ResponsiveText('Select Your Target Direction', baseFontSize: 18),
            content: SizedBox(
              width: deviceType.responsive<double>(
                mobile: 300,
                tablet: 400,
                desktop: 500,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ..._buildDirectionButtons(),
                  ResponsiveSpacing(multiplier: 2),
                  ResponsiveText('Or select individual zones:', baseFontSize: 14, style: const TextStyle(fontWeight: FontWeight.bold)),
                  ResponsiveSpacing(multiplier: 1),
                  SizedBox(
                    width: deviceType.responsive<double>(
                      mobile: 200,
                      tablet: 250,
                      desktop: 300,
                    ),
                    child: GridView.builder(
                      shrinkWrap: true,
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 3,
                        mainAxisSpacing: 8,
                        crossAxisSpacing: 8,
                      ),
                      itemCount: allTargetZones.length,
                      itemBuilder: (context, index) {
                        final zone = allTargetZones[index].toString();
                        final isSelected = _intendedZones.contains(zone);
                        
                        return GestureDetector(
                          onTap: () {
                            setState(() {
                              _intendedZones = [zone];
                              _intendedDirection = 'Zone $zone';
                            });
                            Navigator.pop(context);
                          },
                          child: Container(
                            decoration: BoxDecoration(
                              color: isSelected ? Colors.green[600] : Colors.white,
                              border: Border.all(
                                color: isSelected ? Colors.green[600]! : Colors.grey[400]!,
                                width: 2,
                              ),
                              borderRadius: ResponsiveConfig.borderRadius(context, 8),
                            ),
                            child: Center(
                              child: ResponsiveText(
                                zone,
                                baseFontSize: 18,
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: isSelected ? Colors.white : Colors.black,
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: ResponsiveText('Cancel', baseFontSize: 14),
              ),
            ],
          );
        },
      ),
    );
  }

  List<Widget> _buildDirectionButtons() {
    final directions = [
      {'name': 'North', 'zones': ['1', '2', '3'], 'icon': Icons.keyboard_arrow_up},
      {'name': 'South', 'zones': ['7', '8', '9'], 'icon': Icons.keyboard_arrow_down},
      {'name': 'East', 'zones': ['3', '6', '9'], 'icon': Icons.keyboard_arrow_right},
      {'name': 'West', 'zones': ['1', '4', '7'], 'icon': Icons.keyboard_arrow_left},
      {'name': 'Center', 'zones': ['2', '5', '8'], 'icon': Icons.center_focus_strong},
    ];

    return directions.map((direction) {
      final isSelected = _intendedDirection == direction['name'];
      
      return Container(
        margin: ResponsiveConfig.paddingSymmetric(context, vertical: 2),
        child: ResponsiveButton(
          text: '${direction['name']} (${(direction['zones'] as List<String>).join(', ')})',
          onPressed: () {
            setState(() {
              _intendedDirection = direction['name'] as String;
              _intendedZones = (direction['zones'] as List<String>).toList();
            });
            Navigator.pop(context);
          },
          baseHeight: 40,
          width: double.infinity,
          backgroundColor: isSelected ? Colors.green[600] : Colors.white,
          foregroundColor: isSelected ? Colors.white : Colors.black,
          prefix: Icon(direction['icon'] as IconData, color: isSelected ? Colors.white : Colors.black),
        ),
      );
    }).toList();
  }

  Widget _buildShotDataForm(DeviceType deviceType, bool isLandscape) {
    return SingleChildScrollView(
      padding: ResponsiveConfig.paddingAll(context, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ResponsiveText(
            'Shot Data',
            baseFontSize: 18,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.blueGrey[800],
            ),
          ),
          ResponsiveSpacing(multiplier: 1),
          
          // Responsive layout based on device type
          if (deviceType == DeviceType.mobile && !isLandscape)
            _buildMobileLayout()
          else if (deviceType == DeviceType.tablet)
            _buildTabletLayout()
          else
            _buildDesktopLayout(),
          
          ResponsiveSpacing(multiplier: 3),
          _buildOutcomeSelector(),
        ],
      ),
    );
  }

  Widget _buildMobileLayout() {
    return Column(
      children: [
        _buildZoneSelector(),
        ResponsiveSpacing(multiplier: 2),
        Row(
          children: [
            Expanded(child: _buildShotTypeSelector()),
            ResponsiveSpacing(multiplier: 1, direction: Axis.horizontal),
            Expanded(child: _buildTargetDirectionColumn()),
          ],
        ),
        ResponsiveSpacing(multiplier: 2),
        _buildPowerAndTimerColumn(),
      ],
    );
  }

  Widget _buildTabletLayout() {
    return Column(
      children: [
        _buildZoneSelector(),
        ResponsiveSpacing(multiplier: 2),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: _buildShotTypeSelector()),
            ResponsiveSpacing(multiplier: 2, direction: Axis.horizontal),
            Expanded(child: _buildTargetDirectionColumn()),
            ResponsiveSpacing(multiplier: 2, direction: Axis.horizontal),
            Expanded(child: _buildPowerAndTimerColumn()),
          ],
        ),
      ],
    );
  }

  Widget _buildDesktopLayout() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 1,
          child: Column(
            children: [
              _buildShotTypeSelector(),
              ResponsiveSpacing(multiplier: 2),
              _buildPowerAndTimerColumn(),
            ],
          ),
        ),
        ResponsiveSpacing(multiplier: 2, direction: Axis.horizontal),
        Expanded(
          flex: 2,
          child: _buildZoneSelector(),
        ),
        ResponsiveSpacing(multiplier: 2, direction: Axis.horizontal),
        Expanded(
          flex: 1,
          child: _buildTargetDirectionColumn(),
        ),
      ],
    );
  }

  Widget _buildShotTypeSelector() {
    const shotTypes = ['Wrist Shot', 'Slap Shot', 'Snap Shot', 'Backhand', 'One-Timer'];
    return ResponsiveCard(
      padding: ResponsiveConfig.paddingAll(context, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ResponsiveText(
            'Shot Type',
            baseFontSize: 14,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.blueGrey[700],
            ),
          ),
          ResponsiveSpacing(multiplier: 1),
          ...shotTypes.map((shotType) {
            final isSelected = _selectedShotType == shotType;
            return Container(
              margin: ResponsiveConfig.paddingSymmetric(context, vertical: 3),
              child: ResponsiveButton(
                text: shotType,
                onPressed: () {
                  setState(() {
                    _selectedShotType = isSelected ? '' : shotType;
                  });
                },
                baseHeight: 36,
                width: double.infinity,
                backgroundColor: isSelected ? _primaryColor : Colors.white,
                foregroundColor: isSelected ? Colors.black87 : Colors.blueGrey[700],
              ),
            );
          }).toList(),
        ],
      ),
    );
  }

  Widget _buildZoneSelector() {
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

    return ResponsiveCard(
      padding: ResponsiveConfig.paddingAll(context, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ResponsiveText(
            'Shot Location',
            baseFontSize: 14,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.blueGrey[700],
            ),
          ),
          ResponsiveSpacing(multiplier: 1),

          Center(
            child: Column(
              children: [
                _buildMissButton(
                  'miss_high', 
                  'Miss High', 
                  Icons.keyboard_arrow_up,
                  width: ResponsiveConfig.dimension(context, 154),
                  height: ResponsiveConfig.dimension(context, 50),
                ),
                ResponsiveSpacing(multiplier: 1),

                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildMissButton(
                      'miss_left', 
                      'Miss\nLeft', 
                      Icons.keyboard_arrow_left,
                      width: ResponsiveConfig.dimension(context, 50),
                      height: ResponsiveConfig.dimension(context, 154),
                    ),
                    ResponsiveSpacing(multiplier: 0.75, direction: Axis.horizontal),
                    _buildNetZoneGrid(netZones, zoneLabels),
                    ResponsiveSpacing(multiplier: 0.75, direction: Axis.horizontal),
                    _buildMissButton(
                      'miss_right', 
                      'Miss\nRight', 
                      Icons.keyboard_arrow_right,
                      width: ResponsiveConfig.dimension(context, 50),
                      height: ResponsiveConfig.dimension(context, 154),
                    ),
                  ],
                ),
              ],
            ),
          ),

          ResponsiveSpacing(multiplier: 1),

          if (_selectedZone.isNotEmpty)
            Center(
              child: ResponsiveCard(
                padding: ResponsiveConfig.paddingSymmetric(context, horizontal: 6, vertical: 3),
                child: Column(
                  children: [
                    ResponsiveText(
                      _getSelectionDisplayText(),
                      baseFontSize: 10,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: _getSelectionColor(),
                      ),
                    ),
                    if (_intendedDirection != null && !_selectedZone.startsWith('miss_'))
                      ResponsiveText(
                        _intendedZones.contains(_selectedZone)
                          ? '🎯 Perfect!' 
                          : '📍 Off target',
                        baseFontSize: 9,
                        style: TextStyle(
                          color: _intendedZones.contains(_selectedZone) ? Colors.green[700] : Colors.orange[700],
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildNetZoneGrid(List<String> netZones, Map<String, String> zoneLabels) {
    return Container(
      width: ResponsiveConfig.dimension(context, 154),
      height: ResponsiveConfig.dimension(context, 154),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.black, width: 2),
        borderRadius: ResponsiveConfig.borderRadius(context, 6),
        color: Colors.grey[50],
      ),
      child: GridView.builder(
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          mainAxisSpacing: ResponsiveConfig.spacing(context, 1),
          crossAxisSpacing: ResponsiveConfig.spacing(context, 1),
        ),
        itemCount: netZones.length,
        itemBuilder: (context, index) {
          final zone = netZones[index];
          final isSelected = _selectedZone == zone;
          final isIntended = _intendedZones.contains(zone);
          
          return GestureDetector(
            onTap: () => setState(() {
              _selectedZone = zone;
              if (_selectedOutcome == 'Miss') {
                _selectedOutcome = 'Goal';
              }
            }),
            child: Container(
              margin: ResponsiveConfig.paddingAll(context, 0.5),
              decoration: BoxDecoration(
                color: isSelected 
                    ? _primaryColor[700]
                    : isIntended 
                        ? Colors.green[200]
                        : Colors.white,
                border: Border.all(
                  color: isSelected 
                      ? _primaryColor[700]!
                      : isIntended
                          ? Colors.green[400]!
                          : Colors.grey[400]!,
                  width: isSelected ? 2 : (isIntended ? 1.5 : 1),
                ),
                borderRadius: ResponsiveConfig.borderRadius(context, 4),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ResponsiveText(
                    zone,
                    baseFontSize: 14,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: isSelected ? Colors.white : Colors.black,
                    ),
                  ),
                  ResponsiveText(
                    zoneLabels[zone] ?? '',
                    baseFontSize: 6,
                    style: TextStyle(
                      color: isSelected ? Colors.white70 : Colors.grey[600],
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildTargetDirectionColumn() {
    return ResponsiveCard(
      padding: ResponsiveConfig.paddingAll(context, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ResponsiveText(
            'Your Target',
            baseFontSize: 14,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.green[700],
            ),
          ),
          ResponsiveSpacing(multiplier: 1),
          
          if (_intendedDirection != null) ...[
            Container(
              width: double.infinity,
              padding: ResponsiveConfig.paddingAll(context, 8),
              decoration: BoxDecoration(
                color: Colors.green[50],
                borderRadius: ResponsiveConfig.borderRadius(context, 6),
                border: Border.all(color: Colors.green[200]!),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.center_focus_strong, color: Colors.green[700], size: ResponsiveConfig.iconSize(context, 16)),
                      ResponsiveSpacing(multiplier: 0.5, direction: Axis.horizontal),
                      Expanded(
                        child: ResponsiveText(
                          _intendedDirection!,
                          baseFontSize: 14,
                          style: TextStyle(
                            color: Colors.green[800],
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  ResponsiveSpacing(multiplier: 0.5),
                  ResponsiveText(
                    'Zones: ${_intendedZones.join(', ')}',
                    baseFontSize: 11,
                    style: TextStyle(color: Colors.green[700]),
                  ),
                  ResponsiveSpacing(multiplier: 0.75),
                  GestureDetector(
                    onTap: _showIntendedZoneSelector,
                    child: Container(
                      width: double.infinity,
                      padding: ResponsiveConfig.paddingSymmetric(context, horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.green[200],
                        borderRadius: ResponsiveConfig.borderRadius(context, 4),
                      ),
                      child: ResponsiveText(
                        'Change Target',
                        baseFontSize: 11,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.green[800],
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ] else ...[
            Container(
              width: double.infinity,
              padding: ResponsiveConfig.paddingAll(context, 12),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: ResponsiveConfig.borderRadius(context, 6),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: Column(
                children: [
                  Icon(Icons.my_location, color: Colors.grey[400], size: ResponsiveConfig.iconSize(context, 24)),
                  ResponsiveSpacing(multiplier: 0.5),
                  ResponsiveText(
                    'No target set',
                    baseFontSize: 11,
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                  ResponsiveSpacing(multiplier: 0.75),
                  GestureDetector(
                    onTap: _showIntendedZoneSelector,
                    child: Container(
                      width: double.infinity,
                      padding: ResponsiveConfig.paddingSymmetric(context, horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.blue[200],
                        borderRadius: ResponsiveConfig.borderRadius(context, 4),
                      ),
                      child: ResponsiveText(
                        'Set Target',
                        baseFontSize: 11,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.blue[800],
                        ),
                        textAlign: TextAlign.center,
                      ),
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

  Widget _buildPowerAndTimerColumn() {
    return ResponsiveCard(
      padding: ResponsiveConfig.paddingAll(context, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ResponsiveText(
            'Shot Power',
            baseFontSize: 14,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.blueGrey[700],
            ),
          ),
          ResponsiveSpacing(multiplier: 1),
          StandardTextField(
            controller: _powerController,
            hintText: 'mph',
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,1}'))],
          ),
          
          ResponsiveSpacing(multiplier: 2),
          
          ResponsiveText(
            'Quick Release',
            baseFontSize: 14,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.blueGrey[700],
            ),
          ),
          ResponsiveSpacing(multiplier: 1),
          UnifiedTimer(
            controller: _timerController,
            displayStyle: TimerDisplayStyle.compact,
            primaryColor: _successColor,
          ),
        ],
      ),
    );
  }

  Widget _buildMissButton(
    String missType, 
    String label, 
    IconData icon, {
    double width = 60,
    double height = 60,
  }) {
    final isSelected = _selectedZone == missType;

    return GestureDetector(
      onTap: () => setState(() {
        _selectedZone = missType;
        _selectedOutcome = 'Miss';
      }),
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: isSelected ? _errorColor.withOpacity(0.2) : Colors.grey[100],
          border: Border.all(
            color: isSelected ? _errorColor : Colors.grey[400]!,
            width: isSelected ? 2 : 1,
          ),
          borderRadius: ResponsiveConfig.borderRadius(context, 8),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: isSelected ? _errorColor : Colors.grey[600],
              size: ResponsiveConfig.iconSize(context, 20),
            ),
            ResponsiveSpacing(multiplier: 0.25),
            ResponsiveText(
              label,
              baseFontSize: 10,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: isSelected ? _errorColor : Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getSelectionColor() {
    if (_selectedZone.startsWith('miss_')) {
      return _errorColor;
    }
    if (_intendedZones.contains(_selectedZone)) {
      return Colors.green[600]!;
    }
    return _primaryColor;
  }

  String _getSelectionDisplayText() {
    switch (_selectedZone) {
      case 'miss_left':
        return 'Shot Missed Left';
      case 'miss_high':
        return 'Shot Missed High';
      case 'miss_right':
        return 'Shot Missed Right';
      default:
        return 'Zone $_selectedZone Selected';
    }
  }

  Widget _buildOutcomeSelector() {
    final outcomeOptions = _selectedZone.startsWith('miss_')
        ? ['Miss']
        : ['Goal', 'Save'];

    const outcomeColors = {
      'Goal': _successColor,
      'Miss': _errorColor,
      'Save': _warningColor,
    };

    if (!outcomeOptions.contains(_selectedOutcome)) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        setState(() {
          _selectedOutcome = outcomeOptions.first;
        });
      });
    }

    return ResponsiveCard(
      padding: ResponsiveConfig.paddingAll(context, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ResponsiveText(
            'Shot Outcome',
            baseFontSize: 14,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.blueGrey[700],
            ),
          ),
          ResponsiveSpacing(multiplier: 1),
          ToggleButtonGroup(
            options: outcomeOptions,
            selectedOption: _selectedOutcome,
            onSelected: (outcome) => setState(() => _selectedOutcome = outcome),
            labelBuilder: (type) => type,
            colorMap: outcomeColors,
            borderRadius: ResponsiveConfig.borderRadius(context, 8),
          ),

          ResponsiveSpacing(multiplier: 0.5),
          ResponsiveText(
            _selectedZone.startsWith('miss_')
                ? 'Shot missed the net entirely'
                : 'Shot hit the net - was it a goal or save?',
            baseFontSize: 12,
            style: TextStyle(
              color: Colors.grey[600],
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecordButton(DeviceType deviceType) {
    return Container(
      width: double.infinity,
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
      child: ResponsiveButton(
        text: 'Record Shot',
        onPressed: _recordShot,
        baseHeight: 56,
        width: double.infinity,
        backgroundColor: _primaryColor[700],
        foregroundColor: Colors.white,
        prefix: Icon(Icons.sports_hockey, color: Colors.white),
        style: TextStyle(
          fontSize: ResponsiveConfig.fontSize(context, 16),
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  // ✅ FIX: Fixed shot recording and saving methods
  Future<void> _recordShot() async {
    if (!await _validateInput()) return;

    setState(() => _isRecording = true);

    try {
      final shotData = await _createShotData();
      await _saveShot(shotData);
      setState(() => _localShotCount++);
      await _updateUI(shotData);
    } catch (e) {
      await _handleError(e);
    } finally {
      setState(() => _isRecording = false);
    }
  }

  Future<bool> _validateInput() async {
    if (!mounted) return false;

    if (_selectedZone.isEmpty) {
      await DialogService.showInformation(context, title: 'Missing Data', message: 'Please select a target zone');
      return false;
    }
    if (_selectedShotType.isEmpty) {
      await DialogService.showInformation(context, title: 'Missing Data', message: 'Please select a shot type');
      return false;
    }
    return true;
  }

  Future<Map<String, dynamic>> _createShotData() async {
    final appState = Provider.of<AppState>(context, listen: false);
    if (appState.selectedPlayer.isEmpty) throw Exception('No player selected');

    final player = appState.players.firstWhere(
      (p) => p.name == appState.selectedPlayer,
      orElse: () => throw Exception('Selected player not found'),
    );

    if (player.id == null) throw Exception('Player ID is null');

    final assessmentId = appState.getCurrentAssessmentId() ?? widget.assessment['assessmentId']?.toString();
    if (assessmentId == null) throw Exception('Assessment ID is missing');

    debugPrint('Recording shot - Player ID: ${player.id}, Assessment ID: $assessmentId, Group: $_currentGroup');

    final group = widget.assessment['groups'][_currentGroup] as Map<String, dynamic>?;

    bool success;
    if (_selectedZone.startsWith('miss_')) {
      success = false;
    } else if (_selectedOutcome != 'Goal') {
      success = false;
    } else {
      if (_intendedDirection != null && _intendedZones.isNotEmpty) {
        success = _intendedZones.contains(_selectedZone);
        debugPrint('Directional assessment: $_intendedDirection, Target zones: $_intendedZones, Shot zone: $_selectedZone, Success: $success');
      } else {
        success = true;
      }
    }

    final shotData = {
      'player_id': player.id!,
      'zone': _selectedZone,
      'type': _selectedShotType,
      'success': success,
      'outcome': _selectedOutcome,
      'timestamp': DateTime.now().toIso8601String(),
      'source': 'assessment',
      'assessment_id': assessmentId,
      
      'group_index': _currentGroup,
      'group_id': group?['id']?.toString() ?? _currentGroup.toString(),
      'intended_zone': _intendedZones.isNotEmpty ? _intendedZones.join(',') : '',
      'intended_direction': _intendedDirection ?? '',
      'session_notes': 'Shot Assessment - Group ${_currentGroup + 1}: ${group?['title']?.toString() ?? "Assessment"}',
      
      if (_powerController.text.isNotEmpty) 'power': double.tryParse(_powerController.text),
      if (_timerController.isUsed) 'quick_release': _timerController.elapsedSeconds,
    };

    debugPrint('Shot data to be sent: $shotData');
    return shotData;
  }

  // ✅ FIX: Fixed _saveShot method with proper Shot object creation
  Future<void> _saveShot(Map<String, dynamic> shotData) async {
    final appState = Provider.of<AppState>(context, listen: false);

    // ✅ FIX: Create Shot object from the data
    final shot = Shot(
      id: DateTime.now().millisecondsSinceEpoch,
      playerId: shotData['player_id'] as int,
      zone: _selectedZone,
      type: _selectedShotType,
      success: shotData['success'] as bool,
      outcome: _selectedOutcome,
      timestamp: DateTime.now(),
      power: shotData['power'] as double?,
      quickRelease: shotData['quick_release'] as double?,
      source: 'assessment',
      assessmentId: shotData['assessment_id'] as String,
      sessionNotes: shotData['session_notes'] as String?,
      groupIndex: shotData['group_index'] as int?,
      groupId: shotData['group_id'] as String?,
      intendedZone: shotData['intended_zone'] as String?,
      intendedDirection: shotData['intended_direction'] as String?,
    );

    bool savedToBackend = false;
    try {
      // ✅ FIX: Pass the Shot object directly to addShot
      await appState.addShot(shot);
      savedToBackend = true;
      debugPrint('✓ Shot saved to backend and appState successfully');
    } catch (e) {
      debugPrint('✗ Failed to save shot to backend: $e');
    }

    try {
      await LocalDatabaseService.instance.insertShot(shot);
      debugPrint('✓ Shot saved locally');
    } catch (localError) {
      debugPrint('✗ Failed to save shot locally: $localError');
    }

    widget.onAddShot(_currentGroup, shot);

    if (!savedToBackend) {
      if (!appState.shots.any((s) => s.id == shot.id)) {
        appState.shots.insert(0, shot);
        appState.notifyListeners();
      }
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Shot saved locally - will sync when connection is restored'),
            backgroundColor: Colors.blue,
            duration: Duration(seconds: 2),
          ),
        );
      }
    }
  }

  Future<void> _updateUI(Map<String, dynamic> shotData) async {
    final totalShotsInGroup = (widget.assessment['groups'][_currentGroup] as Map<String, dynamic>?)?['shots'] as int? ?? 0;
    debugPrint('Current group: $_currentGroup, local shots: $_localShotCount, total needed: $totalShotsInGroup');

    setState(() {
      _selectedZone = '';
      _powerController.clear();
      _timerController.reset();
      _selectedOutcome = 'Goal';
    });

    if (_localShotCount < totalShotsInGroup) {
      await _handleShotRecorded();
    } else if (_currentGroup < ((widget.assessment['groups'] as List<dynamic>?)?.length ?? 0) - 1) {
      await _handleGroupCompleted();
    } else {
      await _handleAssessmentCompleted(shotData['assessment_id'] as String);
    }
  }

  Future<void> _handleShotRecorded() async {
    _showSuccessOverlay();
    await Future.delayed(const Duration(milliseconds: 1500));
    debugPrint('Shot recorded, continuing to next shot');
  }

  void _showSuccessOverlay() {
    if (!mounted) return;

    final overlay = Overlay.of(context);
    late OverlayEntry overlayEntry;

    overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        top: MediaQuery.of(context).size.height * 0.4,
        left: MediaQuery.of(context).size.width * 0.2,
        right: MediaQuery.of(context).size.width * 0.2,
        child: Material(
          color: Colors.transparent,
          child: ResponsiveCard(
            padding: ResponsiveConfig.paddingSymmetric(context, horizontal: 24, vertical: 16),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.check_circle, color: _successColor, size: ResponsiveConfig.iconSize(context, 28)),
                ResponsiveSpacing(multiplier: 1.5, direction: Axis.horizontal),
                ResponsiveText(
                  'Shot Recorded!',
                  baseFontSize: 16,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: _successColor,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    overlay.insert(overlayEntry);
    Future.delayed(const Duration(milliseconds: 1400), () {
      if (overlayEntry.mounted) {
        overlayEntry.remove();
      }
    });
  }

  Future<void> _handleGroupCompleted() async {
    setState(() {
      _currentGroup++;
      _currentShot = 0;
      _localShotCount = widget.shotResults[_currentGroup]?.length ?? 0;
      final defaultType = (widget.assessment['groups'] as List<dynamic>?)?[_currentGroup]['defaultType'] as String?;
      _selectedShotType = defaultType ?? '';
      
      _updateIntendedZoneForGroup();
    });

    if (!mounted) return;

    final nextGroup = widget.assessment['groups'][_currentGroup] as Map<String, dynamic>?;
    await DialogService.showCustom<void>(
      context,
      content: SingleChildScrollView(
        padding: ResponsiveConfig.paddingAll(context, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.arrow_forward_ios, color: Colors.blue, size: ResponsiveConfig.iconSize(context, 40)),
            ResponsiveSpacing(multiplier: 0.75),
            ResponsiveText(
              'Group Completed!',
              baseFontSize: 18,
              style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blueGrey[800]),
            ),
            ResponsiveSpacing(multiplier: 1),
            ResponsiveText(
              'Moving to next group: ${nextGroup?['title']?.toString() ?? "Group ${_currentGroup + 1}"}',
              baseFontSize: 14,
              textAlign: TextAlign.center,
            ),
            ResponsiveSpacing(multiplier: 0.5),
            ResponsiveText(
              'Location: ${nextGroup?['location']?.toString() ?? 'Not specified'}',
              baseFontSize: 14,
              style: TextStyle(color: Colors.blueGrey[600], fontWeight: FontWeight.bold),
            ),
            if (_intendedDirection != null) ...[
              ResponsiveSpacing(multiplier: 1),
              ResponsiveCard(
                padding: ResponsiveConfig.paddingAll(context, 8),
                child: ResponsiveText(
                  'New target direction: $_intendedDirection (${_intendedZones.join(', ')})',
                  baseFontSize: 12,
                  style: TextStyle(
                    color: Colors.green[800],
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
            ResponsiveSpacing(multiplier: 2),
            ResponsiveButton(
              text: 'Start Group',
              onPressed: () {
                if (mounted) {
                  Navigator.of(context).pop();
                }
              },
              baseHeight: 48,
              backgroundColor: _primaryColor[700],
              foregroundColor: Colors.white,
              prefix: Icon(Icons.play_arrow, color: Colors.white),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleAssessmentCompleted(String assessmentId) async {
    if (!mounted) return;

    await DialogService.showCustom<void>(
      context,
      content: SingleChildScrollView(
        padding: ResponsiveConfig.paddingAll(context, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.emoji_events, color: Colors.blue, size: ResponsiveConfig.iconSize(context, 64)),
            ResponsiveSpacing(multiplier: 1),
            ResponsiveText(
              'Assessment Completed!',
              baseFontSize: 20,
              style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blueGrey[800]),
            ),
            ResponsiveSpacing(multiplier: 0.5),
            ResponsiveText(
              'Assessment ID: $assessmentId\nAll shots recorded with directional tracking.',
              baseFontSize: 14,
              textAlign: TextAlign.center,
            ),
            ResponsiveSpacing(multiplier: 3),
            ResponsiveButton(
              text: 'View Results',
              onPressed: () {
                Navigator.of(context).pop();
              },
              baseHeight: 48,
              backgroundColor: _successColor,
              foregroundColor: Colors.white,
              prefix: Icon(Icons.analytics, color: Colors.white),
            ),
          ],
        ),
      ),
    );

    if (!mounted) return;

    final appState = Provider.of<AppState>(context, listen: false);
    appState.clearCurrentAssessmentId();

    widget.onComplete();
  }

  Future<void> _handleError(Object error) async {
    debugPrint('Error in _recordShot: $error');
    String errorMessage = 'Error recording shot';
    if (error.toString().contains('DioException')) {
      errorMessage = 'Failed to save shot to server. Shot recorded locally.';
    }
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $errorMessage'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }
}