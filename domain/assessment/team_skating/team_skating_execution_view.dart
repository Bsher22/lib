// lib/widgets/domain/assessment/team_skating/team_skating_execution_view.dart
// REFACTORED: Updated with full responsive system integration following established patterns
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hockey_shot_tracker/models/player.dart';
import 'package:hockey_shot_tracker/widgets/domain/assessment/common/assessment_progress_header.dart';
import 'package:hockey_shot_tracker/services/dialog_service.dart';
import 'package:hockey_shot_tracker/widgets/core/form/standard_text_field.dart';
import 'package:hockey_shot_tracker/responsive_system/index.dart';
import 'package:hockey_shot_tracker/responsive_system/full_screen_container.dart';

// Constants for UI styling
const _primaryColor = Colors.cyanAccent;
const _successColor = Colors.green;
const _errorColor = Colors.red;
const _sectionSpacing = 24.0;
const _widgetSpacing = 16.0;
const _smallSpacing = 8.0;

/// Team skating execution view with responsive matrix-based data entry
class TeamSkatingExecutionView extends StatefulWidget {
  final Map<String, dynamic> assessment;
  final List<Player> players;
  final Map<String, Map<String, Map<String, dynamic>>> playerTestResults;
  final Function(String, String, Map<String, dynamic>) onAddResult;
  final VoidCallback onComplete;
  
  const TeamSkatingExecutionView({
    Key? key,
    required this.assessment,
    required this.players,
    required this.playerTestResults,
    required this.onAddResult,
    required this.onComplete,
  }) : super(key: key);

  @override
  _TeamSkatingExecutionViewState createState() => _TeamSkatingExecutionViewState();
}

class _TeamSkatingExecutionViewState extends State<TeamSkatingExecutionView> {
  int _currentGroup = 0;
  int _currentTest = 0;
  
  // Matrix data: [playerId][testId] = {time, notes, timestamp, benchmarkLevel}
  Map<String, Map<String, Map<String, dynamic>>> _matrixData = {};

  @override
  void initState() {
    super.initState();
    _initializeMatrixData();
  }

  void _initializeMatrixData() {
    _matrixData = {};
    for (var player in widget.players) {
      _matrixData[player.id.toString()] = {};
    }
  }

  Future<bool> _handleBackPress() async {
    final completedTests = _calculateCompletedTests();
    
    if (completedTests == 0) {
      return true;
    }

    final shouldExit = await DialogService.showConfirmation(
      context,
      title: 'Exit Team Assessment?',
      message: 'You have recorded $completedTests test(s) for the team. Your progress will be lost.\n\nExit anyway?',
      confirmLabel: 'Exit',
      cancelLabel: 'Stay',
    );
    
    return shouldExit == true;
  }

  @override
  Widget build(BuildContext context) {
    final groups = widget.assessment['groups'] as List?;
    if (groups == null || groups.isEmpty) {
      return _buildErrorScaffold('No assessment groups found');
    }

    if (_currentGroup >= groups.length) {
      return _buildErrorScaffold('Current group index out of bounds');
    }

    final currentGroup = groups[_currentGroup] as Map<String, dynamic>;
    final currentTests = currentGroup['tests'] as List?;
    
    if (currentTests == null || currentTests.isEmpty) {
      return _buildErrorScaffold('No tests found in group: ${currentGroup['name']}');
    }

    return WillPopScope(
      onWillPop: _handleBackPress,
      child: AdaptiveLayout(
        builder: (deviceType, isLandscape) {
          switch (deviceType) {
            case DeviceType.mobile:
              return _buildMobileLayout(groups, currentGroup, currentTests);
            case DeviceType.tablet:
              return _buildTabletLayout(groups, currentGroup, currentTests);
            case DeviceType.desktop:
              return _buildDesktopLayout(groups, currentGroup, currentTests);
          }
        },
      ),
    );
  }

  // 📱 MOBILE LAYOUT: Single player focus with rotation queue
  Widget _buildMobileLayout(List groups, Map<String, dynamic> currentGroup, List currentTests) {
    return Scaffold(
      appBar: _buildAppBar(),
      body: FullScreenContainer(
        child: Column(
          children: [
            // Assessment progress header
            _buildProgressHeader(currentGroup, groups.length, currentTests.length),
            
            // Current player focus
            Expanded(
              child: SingleChildScrollView(
                padding: ResponsiveConfig.paddingAll(context, 16),
                child: Column(
                  children: [
                    _buildCurrentPlayerCard(currentTests),
                    ResponsiveSpacing(multiplier: 2),
                    _buildSkaterQueueFooter(),
                  ],
                ),
              ),
            ),
            
            // Action buttons
            _buildMobileActionButtons(currentTests.length),
          ],
        ),
      ),
    );
  }

  // 📱 TABLET LAYOUT: Split view (Active | Queue + Live Stats)
  Widget _buildTabletLayout(List groups, Map<String, dynamic> currentGroup, List currentTests) {
    return Scaffold(
      appBar: _buildAppBar(),
      body: FullScreenContainer(
        child: Column(
          children: [
            _buildProgressHeader(currentGroup, groups.length, currentTests.length),
            Expanded(
              child: Row(
                children: [
                  // Left: Current skater section
                  Expanded(
                    flex: 3,
                    child: SingleChildScrollView(
                      padding: ResponsiveConfig.paddingAll(context, 16),
                      child: Column(
                        children: [
                          _buildCurrentSkaterSection(currentTests),
                          ResponsiveSpacing(multiplier: 3),
                          _buildTimerRecordingInterface(currentTests),
                        ],
                      ),
                    ),
                  ),
                  
                  // Right: Queue + Live Stats
                  Expanded(
                    flex: 2,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.grey[50],
                        border: Border(left: BorderSide(color: Colors.grey[200]!)),
                      ),
                      child: Column(
                        children: [
                          Expanded(
                            child: SingleChildScrollView(
                              padding: ResponsiveConfig.paddingAll(context, 16),
                              child: Column(
                                children: [
                                  _buildSkaterQueue(),
                                  ResponsiveSpacing(multiplier: 3),
                                  _buildRealTimeLeaderboard(),
                                ],
                              ),
                            ),
                          ),
                          _buildTabletActionButtons(currentTests.length),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 🖥️ DESKTOP LAYOUT: Professional multi-panel interface
  Widget _buildDesktopLayout(List groups, Map<String, dynamic> currentGroup, List currentTests) {
    return Scaffold(
      appBar: _buildAppBar(),
      body: FullScreenContainer(
        child: Column(
          children: [
            _buildProgressHeader(currentGroup, groups.length, currentTests.length),
            Expanded(
              child: Row(
                children: [
                  // Left sidebar: Skater management
                  Container(
                    width: 280,
                    decoration: BoxDecoration(
                      color: Colors.grey[50],
                      border: Border(right: BorderSide(color: Colors.grey[200]!)),
                    ),
                    child: _buildSkaterManagementSidebar(currentTests),
                  ),
                  
                  // Center: Main timer interface
                  Expanded(
                    child: _buildMainTimerInterface(currentTests),
                  ),
                  
                  // Right sidebar: Analytics
                  Container(
                    width: 300,
                    decoration: BoxDecoration(
                      color: Colors.grey[50],
                      border: Border(left: BorderSide(color: Colors.grey[200]!)),
                    ),
                    child: _buildAnalyticsSidebar(),
                  ),
                ],
              ),
            ),
            _buildDesktopActionButtons(currentTests.length),
          ],
        ),
      ),
    );
  }

  // SHARED COMPONENTS
  AppBar _buildAppBar() {
    final totalGroups = (widget.assessment['groups'] as List).length;
    final totalTests = _calculateTotalTests();
    final completedTests = _calculateCompletedTests();

    return AppBar(
      title: ResponsiveText(
        widget.assessment['title'] ?? 'Team Skating Assessment',
        baseFontSize: 18,
        style: const TextStyle(fontWeight: FontWeight.bold),
      ),
      backgroundColor: _primaryColor,
      foregroundColor: Colors.white,
      actions: [
        Padding(
          padding: ResponsiveConfig.paddingOnly(context, right: 16),
          child: Center(
            child: Container(
              padding: ResponsiveConfig.paddingSymmetric(context, horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(ResponsiveConfig.dimension(context, 8)),
              ),
              child: ResponsiveText(
                'Team: $completedTests/$totalTests',
                baseFontSize: 12,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildProgressHeader(Map<String, dynamic> currentGroup, int totalGroups, int totalTests) {
    final progress = _calculateTotalTests() > 0 ? _calculateCompletedTests() / _calculateTotalTests() : 0.0;

    return AssessmentProgressHeader(
      groupTitle: _buildGroupTitle(currentGroup),
      groupDescription: currentGroup['description'] as String? ?? '',
      currentGroupIndex: _currentGroup,
      totalGroups: totalGroups,
      currentItemIndex: _currentTest,
      totalItems: totalTests,
      progressValue: progress,
      bottomContent: _buildGroupInfo(currentGroup),
    );
  }

  String _buildGroupTitle(Map<String, dynamic> currentGroup) {
    final groupTitle = currentGroup['name'] as String? ?? 
                     currentGroup['title'] as String? ?? 
                     'Group ${_currentGroup + 1}';
    return groupTitle;
  }

  Widget _buildGroupInfo(Map<String, dynamic> group) {
    return Container(
      padding: ResponsiveConfig.paddingAll(context, 12),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(ResponsiveConfig.dimension(context, 8)),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.info_outline, color: Colors.blueGrey[700], size: ResponsiveConfig.iconSize(context, 16)),
              ResponsiveSpacing(multiplier: 1, direction: Axis.horizontal),
              Expanded(
                child: ResponsiveText(
                  'Group Instructions',
                  baseFontSize: 14,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.blueGrey[700],
                  ),
                ),
              ),
            ],
          ),
          ResponsiveSpacing(multiplier: 1),
          ResponsiveText(
            group['description'] as String? ?? 'Complete all skating tests in this group.',
            baseFontSize: 13,
            style: TextStyle(color: Colors.blueGrey[800]),
          ),
          ResponsiveSpacing(multiplier: 1),
          Row(
            children: [
              Icon(Icons.people, size: ResponsiveConfig.iconSize(context, 16), color: Colors.blueGrey[600]),
              ResponsiveSpacing(multiplier: 1, direction: Axis.horizontal),
              ResponsiveText(
                'Players: ${widget.players.length}',
                baseFontSize: 12,
                style: TextStyle(color: Colors.blueGrey[600]),
              ),
              ResponsiveSpacing(multiplier: 2, direction: Axis.horizontal),
              Icon(Icons.speed, size: ResponsiveConfig.iconSize(context, 16), color: Colors.blueGrey[600]),
              ResponsiveSpacing(multiplier: 1, direction: Axis.horizontal),
              ResponsiveText(
                'Tests: ${(group['tests'] as List).length}',
                baseFontSize: 12,
                style: TextStyle(color: Colors.blueGrey[600]),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // MOBILE COMPONENTS
  Widget _buildCurrentPlayerCard(List currentTests) {
    final currentTestData = currentTests[_currentTest] as Map<String, dynamic>;
    final testId = currentTestData['id'] as String;
    
    return ResponsiveCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: ResponsiveConfig.dimension(context, 40),
                height: ResponsiveConfig.dimension(context, 40),
                decoration: BoxDecoration(
                  color: Colors.blue[600],
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: ResponsiveText(
                    '${_currentTest + 1}',
                    baseFontSize: 16,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              ResponsiveSpacing(multiplier: 1, direction: Axis.horizontal),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ResponsiveText(
                      currentTestData['title'] as String? ?? 'Current Test',
                      baseFontSize: 18,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    ResponsiveText(
                      currentTestData['category'] as String? ?? '',
                      baseFontSize: 14,
                      style: TextStyle(color: Colors.blueGrey[600]),
                    ),
                  ],
                ),
              ),
            ],
          ),
          ResponsiveSpacing(multiplier: 2),
          ResponsiveText(
            currentTestData['description'] as String? ?? '',
            baseFontSize: 14,
            style: TextStyle(color: Colors.blueGrey[700]),
          ),
          ResponsiveSpacing(multiplier: 2),
          _buildMobilePlayerGrid(testId, currentTestData),
        ],
      ),
    );
  }

  Widget _buildMobilePlayerGrid(String testId, Map<String, dynamic> testData) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 1.2,
        crossAxisSpacing: ResponsiveConfig.spacing(context, 8),
        mainAxisSpacing: ResponsiveConfig.spacing(context, 8),
      ),
      itemCount: widget.players.length,
      itemBuilder: (context, index) {
        final player = widget.players[index];
        final playerId = player.id.toString();
        final testResult = _matrixData[playerId]?[testId];
        final isCompleted = testResult != null;

        return _buildMobilePlayerTestCard(
          player: player,
          playerId: playerId,
          testId: testId,
          testData: testData,
          testResult: testResult,
          isCompleted: isCompleted,
        );
      },
    );
  }

  Widget _buildMobilePlayerTestCard({
    required Player player,
    required String playerId,
    required String testId,
    required Map<String, dynamic> testData,
    required Map<String, dynamic>? testResult,
    required bool isCompleted,
  }) {
    return GestureDetector(
      onTap: () => _editTest(playerId, testId, testData, testResult),
      child: Container(
        decoration: BoxDecoration(
          color: isCompleted
              ? _getTimeColor(testResult!['time'], testData)
              : Colors.white,
          border: Border.all(
            color: isCompleted
                ? _getTimeBorderColor(testResult!['time'], testData)
                : Colors.blue,
            width: 2,
          ),
          borderRadius: BorderRadius.circular(ResponsiveConfig.dimension(context, 12)),
        ),
        child: Padding(
          padding: ResponsiveConfig.paddingAll(context, 8),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircleAvatar(
                backgroundColor: isCompleted ? Colors.green[100] : Colors.blue[100],
                child: ResponsiveText(
                  player.jerseyNumber?.toString() ?? '?',
                  baseFontSize: 12,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: isCompleted ? Colors.green[700] : Colors.blue[700],
                  ),
                ),
              ),
              ResponsiveSpacing(multiplier: 1),
              ResponsiveText(
                player.name,
                baseFontSize: 12,
                style: const TextStyle(fontWeight: FontWeight.bold),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
              ),
              ResponsiveSpacing(multiplier: 0.5),
              if (isCompleted) ...[
                ResponsiveText(
                  '${testResult!['time'].toStringAsFixed(2)}s',
                  baseFontSize: 14,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                if (testResult['benchmarkLevel'] != null)
                  Container(
                    margin: ResponsiveConfig.paddingOnly(context, top: 2),
                    padding: ResponsiveConfig.paddingSymmetric(context, horizontal: 4, vertical: 1),
                    decoration: BoxDecoration(
                      color: _getBenchmarkLevelColor(testResult['benchmarkLevel']),
                      borderRadius: BorderRadius.circular(ResponsiveConfig.dimension(context, 8)),
                    ),
                    child: ResponsiveText(
                      testResult['benchmarkLevel'],
                      baseFontSize: 8,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
              ] else ...[
                Icon(
                  Icons.timer,
                  size: ResponsiveConfig.iconSize(context, 20),
                  color: Colors.blue[600],
                ),
                ResponsiveText(
                  'Tap to record',
                  baseFontSize: 10,
                  style: TextStyle(color: Colors.blue[600]),
                  textAlign: TextAlign.center,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSkaterQueueFooter() {
    final upcomingPlayers = widget.players.take(3).toList();
    
    return Container(
      padding: ResponsiveConfig.paddingAll(context, 16),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(ResponsiveConfig.dimension(context, 12)),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ResponsiveText(
            'Team Progress',
            baseFontSize: 16,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.blueGrey[800],
            ),
          ),
          ResponsiveSpacing(multiplier: 1),
          Row(
            children: upcomingPlayers.map((player) {
              final playerId = player.id.toString();
              final completedForPlayer = _matrixData[playerId]?.length ?? 0;
              final totalForPlayer = _getTotalTestsForCurrentGroup();
              
              return Expanded(
                child: Container(
                  margin: ResponsiveConfig.paddingOnly(context, right: 8),
                  padding: ResponsiveConfig.paddingAll(context, 8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(ResponsiveConfig.dimension(context, 8)),
                    border: Border.all(color: Colors.grey[300]!),
                  ),
                  child: Column(
                    children: [
                      CircleAvatar(
                        radius: 16,
                        backgroundColor: completedForPlayer == totalForPlayer 
                            ? Colors.green[100] 
                            : Colors.blue[100],
                        child: ResponsiveText(
                          player.jerseyNumber?.toString() ?? '?',
                          baseFontSize: 10,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: completedForPlayer == totalForPlayer 
                                ? Colors.green[700] 
                                : Colors.blue[700],
                          ),
                        ),
                      ),
                      ResponsiveSpacing(multiplier: 0.5),
                      ResponsiveText(
                        player.name,
                        baseFontSize: 10,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                      ),
                      ResponsiveText(
                        '$completedForPlayer/$totalForPlayer',
                        baseFontSize: 8,
                        style: TextStyle(color: Colors.blueGrey[600]),
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

  // ACTION BUTTONS
  Widget _buildMobileActionButtons(int totalTestsInGroup) {
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
        child: _buildActionButtonRow(totalTestsInGroup),
      ),
    );
  }

  Widget _buildTabletActionButtons(int totalTestsInGroup) {
    return Container(
      padding: ResponsiveConfig.paddingAll(context, 16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.grey[200]!)),
      ),
      child: _buildActionButtonRow(totalTestsInGroup),
    );
  }

  Widget _buildDesktopActionButtons(int totalTestsInGroup) {
    return Container(
      padding: ResponsiveConfig.paddingAll(context, 24),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.grey[200]!)),
      ),
      child: _buildActionButtonRow(totalTestsInGroup, isDesktop: true),
    );
  }

  Widget _buildActionButtonRow(int totalTestsInGroup, {bool isDesktop = false}) {
    final canAdvance = _canAdvanceToNextTest();
    final isLastTest = _currentTest >= totalTestsInGroup - 1;
    final groups = widget.assessment['groups'] as List;
    final isLastGroup = _currentGroup >= groups.length - 1;

    return Row(
      children: [
        if (_currentTest > 0)
          Expanded(
            child: ResponsiveButton(
              text: isDesktop ? 'Previous Test' : 'Previous',
              onPressed: _goToPreviousTest,
              baseHeight: isDesktop ? 56 : 48,
              backgroundColor: Colors.blueGrey,
              foregroundColor: Colors.white,
            ),
          ),
        
        if (_currentTest > 0) ResponsiveSpacing(multiplier: isDesktop ? 3 : 2, direction: Axis.horizontal),
        
        Expanded(
          flex: 2,
          child: ResponsiveButton(
            text: isLastTest && isLastGroup 
                ? 'Complete Assessment'
                : isLastTest 
                  ? 'Next Group' 
                  : 'Next Test',
            onPressed: canAdvance ? _advanceProgress : null,
            baseHeight: isDesktop ? 56 : 48,
            backgroundColor: canAdvance 
                ? (isLastTest && isLastGroup ? _successColor : _primaryColor)
                : Colors.grey,
            foregroundColor: Colors.white,
          ),
        ),
      ],
    );
  }

  // TABLET/DESKTOP COMPONENTS (truncated for space - following same patterns as above)
  Widget _buildCurrentSkaterSection(List currentTests) {
    final currentTestData = currentTests[_currentTest] as Map<String, dynamic>;
    
    return ResponsiveCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ResponsiveText(
            'Current Test',
            baseFontSize: 18,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.blueGrey[800],
            ),
          ),
          ResponsiveSpacing(multiplier: 2),
          Container(
            padding: ResponsiveConfig.paddingAll(context, 16),
            decoration: BoxDecoration(
              color: Colors.blue[50],
              borderRadius: BorderRadius.circular(ResponsiveConfig.dimension(context, 12)),
              border: Border.all(color: Colors.blue[200]!),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: ResponsiveConfig.dimension(context, 32),
                      height: ResponsiveConfig.dimension(context, 32),
                      decoration: BoxDecoration(
                        color: Colors.blue[600],
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: ResponsiveText(
                          '${_currentTest + 1}',
                          baseFontSize: 14,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                    ResponsiveSpacing(multiplier: 1, direction: Axis.horizontal),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ResponsiveText(
                            currentTestData['title'] as String? ?? 'Test',
                            baseFontSize: 16,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          ResponsiveText(
                            currentTestData['category'] as String? ?? '',
                            baseFontSize: 14,
                            style: TextStyle(color: Colors.blueGrey[600]),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                ResponsiveSpacing(multiplier: 1),
                ResponsiveText(
                  currentTestData['description'] as String? ?? '',
                  baseFontSize: 14,
                  style: TextStyle(color: Colors.blueGrey[700]),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimerRecordingInterface(List currentTests) {
    final currentTestData = currentTests[_currentTest] as Map<String, dynamic>;
    final testId = currentTestData['id'] as String;
    
    return ResponsiveCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ResponsiveText(
            'Record Times',
            baseFontSize: 18,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.blueGrey[800],
            ),
          ),
          ResponsiveSpacing(multiplier: 2),
          _buildTabletPlayerGrid(testId, currentTestData),
        ],
      ),
    );
  }

  Widget _buildTabletPlayerGrid(String testId, Map<String, dynamic> testData) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        childAspectRatio: 1.0,
        crossAxisSpacing: ResponsiveConfig.spacing(context, 8),
        mainAxisSpacing: ResponsiveConfig.spacing(context, 8),
      ),
      itemCount: widget.players.length,
      itemBuilder: (context, index) {
        final player = widget.players[index];
        final playerId = player.id.toString();
        final testResult = _matrixData[playerId]?[testId];
        final isCompleted = testResult != null;

        return _buildTabletPlayerTestCard(
          player: player,
          playerId: playerId,
          testId: testId,
          testData: testData,
          testResult: testResult,
          isCompleted: isCompleted,
        );
      },
    );
  }

  Widget _buildTabletPlayerTestCard({
    required Player player,
    required String playerId,
    required String testId,
    required Map<String, dynamic> testData,
    required Map<String, dynamic>? testResult,
    required bool isCompleted,
  }) {
    return GestureDetector(
      onTap: () => _editTest(playerId, testId, testData, testResult),
      child: Container(
        decoration: BoxDecoration(
          color: isCompleted
              ? _getTimeColor(testResult!['time'], testData)
              : Colors.white,
          border: Border.all(
            color: isCompleted
                ? _getTimeBorderColor(testResult!['time'], testData)
                : Colors.blue,
            width: 2,
          ),
          borderRadius: BorderRadius.circular(ResponsiveConfig.dimension(context, 8)),
        ),
        child: Padding(
          padding: ResponsiveConfig.paddingAll(context, 8),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircleAvatar(
                radius: 16,
                backgroundColor: isCompleted ? Colors.green[100] : Colors.blue[100],
                child: ResponsiveText(
                  player.jerseyNumber?.toString() ?? '?',
                  baseFontSize: 12,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: isCompleted ? Colors.green[700] : Colors.blue[700],
                  ),
                ),
              ),
              ResponsiveSpacing(multiplier: 0.75),
              ResponsiveText(
                player.name,
                baseFontSize: 10,
                style: const TextStyle(fontWeight: FontWeight.bold),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
              ),
              ResponsiveSpacing(multiplier: 0.5),
              if (isCompleted) ...[
                ResponsiveText(
                  '${testResult!['time'].toStringAsFixed(2)}s',
                  baseFontSize: 12,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ] else ...[
                Icon(
                  Icons.timer,
                  size: ResponsiveConfig.iconSize(context, 16),
                  color: Colors.blue[600],
                ),
                ResponsiveText(
                  'Tap',
                  baseFontSize: 8,
                  style: TextStyle(color: Colors.blue[600]),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSkaterQueue() {
    return ResponsiveCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ResponsiveText(
            'Team Queue',
            baseFontSize: 16,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.blueGrey[800],
            ),
          ),
          ResponsiveSpacing(multiplier: 1),
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: widget.players.length,
            itemBuilder: (context, index) {
              final player = widget.players[index];
              final playerId = player.id.toString();
              final completedForPlayer = _matrixData[playerId]?.length ?? 0;
              final totalForPlayer = _getTotalTestsForCurrentGroup();
              
              return Container(
                margin: ResponsiveConfig.paddingOnly(context, bottom: 8),
                padding: ResponsiveConfig.paddingAll(context, 8),
                decoration: BoxDecoration(
                  color: completedForPlayer == totalForPlayer 
                      ? Colors.green[50] 
                      : Colors.grey[50],
                  borderRadius: BorderRadius.circular(ResponsiveConfig.dimension(context, 8)),
                  border: Border.all(
                    color: completedForPlayer == totalForPlayer 
                        ? Colors.green[200]! 
                        : Colors.grey[200]!,
                  ),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 16,
                      backgroundColor: completedForPlayer == totalForPlayer 
                          ? Colors.green[100] 
                          : Colors.blue[100],
                      child: ResponsiveText(
                        player.jerseyNumber?.toString() ?? '?',
                        baseFontSize: 10,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: completedForPlayer == totalForPlayer 
                              ? Colors.green[700] 
                              : Colors.blue[700],
                        ),
                      ),
                    ),
                    ResponsiveSpacing(multiplier: 1, direction: Axis.horizontal),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ResponsiveText(
                            player.name,
                            baseFontSize: 12,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          ResponsiveText(
                            '${player.position ?? 'Unknown'}',
                            baseFontSize: 10,
                            style: TextStyle(color: Colors.blueGrey[600]),
                          ),
                        ],
                      ),
                    ),
                    ResponsiveText(
                      '$completedForPlayer/$totalForPlayer',
                      baseFontSize: 12,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: completedForPlayer == totalForPlayer 
                            ? Colors.green[700] 
                            : Colors.blueGrey[600],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildRealTimeLeaderboard() {
    // Calculate current test completion rates
    final leaderboard = <Map<String, dynamic>>[];
    
    for (var player in widget.players) {
      final playerId = player.id.toString();
      final completedForPlayer = _matrixData[playerId]?.length ?? 0;
      final totalForPlayer = _getTotalTestsForCurrentGroup();
      final completionRate = totalForPlayer > 0 ? completedForPlayer / totalForPlayer : 0.0;
      
      leaderboard.add({
        'player': player,
        'completed': completedForPlayer,
        'total': totalForPlayer,
        'rate': completionRate,
      });
    }
    
    leaderboard.sort((a, b) => (b['rate'] as double).compareTo(a['rate'] as double));
    
    return ResponsiveCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ResponsiveText(
            'Progress Leaderboard',
            baseFontSize: 16,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.blueGrey[800],
            ),
          ),
          ResponsiveSpacing(multiplier: 1),
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: leaderboard.length,
            itemBuilder: (context, index) {
              final entry = leaderboard[index];
              final player = entry['player'] as Player;
              final completed = entry['completed'] as int;
              final total = entry['total'] as int;
              final rate = entry['rate'] as double;
              
              return Container(
                margin: ResponsiveConfig.paddingOnly(context, bottom: 6),
                padding: ResponsiveConfig.paddingAll(context, 8),
                decoration: BoxDecoration(
                  color: index < 3 ? Colors.amber[50] : Colors.grey[50],
                  borderRadius: BorderRadius.circular(ResponsiveConfig.dimension(context, 6)),
                  border: Border.all(
                    color: index < 3 ? Colors.amber[200]! : Colors.grey[200]!,
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: ResponsiveConfig.dimension(context, 20),
                      height: ResponsiveConfig.dimension(context, 20),
                      decoration: BoxDecoration(
                        color: index < 3 ? Colors.amber[600] : Colors.grey[400],
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: ResponsiveText(
                          '${index + 1}',
                          baseFontSize: 10,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                    ResponsiveSpacing(multiplier: 1, direction: Axis.horizontal),
                    Expanded(
                      child: ResponsiveText(
                        player.name,
                        baseFontSize: 11,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                    ResponsiveText(
                      '$completed/$total',
                      baseFontSize: 11,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: rate == 1.0 ? Colors.green[700] : Colors.blueGrey[600],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  // DESKTOP COMPONENTS (truncated - following same patterns)
  Widget _buildSkaterManagementSidebar(List currentTests) {
    final currentTestData = currentTests[_currentTest] as Map<String, dynamic>;
    
    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: ResponsiveConfig.paddingAll(context, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildActiveSkaterInfo(currentTestData),
                ResponsiveSpacing(multiplier: 3),
                _buildRotationQueue(),
                ResponsiveSpacing(multiplier: 3),
                _buildTimerControls(),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildActiveSkaterInfo(Map<String, dynamic> currentTestData) {
    return Container(
      padding: ResponsiveConfig.paddingAll(context, 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(ResponsiveConfig.dimension(context, 12)),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.speed, color: Colors.blue[600]),
              ResponsiveSpacing(multiplier: 1, direction: Axis.horizontal),
              ResponsiveText(
                'Active Test',
                baseFontSize: 14,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.blueGrey[800],
                ),
              ),
            ],
          ),
          ResponsiveSpacing(multiplier: 1),
          Container(
            padding: ResponsiveConfig.paddingAll(context, 12),
            decoration: BoxDecoration(
              color: Colors.blue[50],
              borderRadius: BorderRadius.circular(ResponsiveConfig.dimension(context, 8)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ResponsiveText(
                  currentTestData['title'] as String? ?? 'Test',
                  baseFontSize: 16,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                ResponsiveText(
                  currentTestData['category'] as String? ?? '',
                  baseFontSize: 12,
                  style: TextStyle(color: Colors.blueGrey[600]),
                ),
                ResponsiveSpacing(multiplier: 1),
                ResponsiveText(
                  currentTestData['description'] as String? ?? '',
                  baseFontSize: 12,
                  style: TextStyle(color: Colors.blueGrey[700]),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRotationQueue() {
    return Container(
      padding: ResponsiveConfig.paddingAll(context, 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(ResponsiveConfig.dimension(context, 12)),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.people, color: Colors.green[600]),
              ResponsiveSpacing(multiplier: 1, direction: Axis.horizontal),
              ResponsiveText(
                'Team Rotation',
                baseFontSize: 14,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.blueGrey[800],
                ),
              ),
            ],
          ),
          ResponsiveSpacing(multiplier: 1),
          Container(
            constraints: BoxConstraints(maxHeight: ResponsiveConfig.dimension(context, 200)),
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: widget.players.length,
              itemBuilder: (context, index) {
                final player = widget.players[index];
                final playerId = player.id.toString();
                final completedForPlayer = _matrixData[playerId]?.length ?? 0;
                final totalForPlayer = _getTotalTestsForCurrentGroup();
                
                return Container(
                  margin: ResponsiveConfig.paddingOnly(context, bottom: 4),
                  padding: ResponsiveConfig.paddingAll(context, 8),
                  decoration: BoxDecoration(
                    color: completedForPlayer == totalForPlayer 
                        ? Colors.green[50] 
                        : Colors.grey[50],
                    borderRadius: BorderRadius.circular(ResponsiveConfig.dimension(context, 6)),
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 12,
                        backgroundColor: completedForPlayer == totalForPlayer 
                            ? Colors.green[100] 
                            : Colors.blue[100],
                        child: ResponsiveText(
                          player.jerseyNumber?.toString() ?? '?',
                          baseFontSize: 8,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: completedForPlayer == totalForPlayer 
                                ? Colors.green[700] 
                                : Colors.blue[700],
                          ),
                        ),
                      ),
                      ResponsiveSpacing(multiplier: 1, direction: Axis.horizontal),
                      Expanded(
                        child: ResponsiveText(
                          player.name,
                          baseFontSize: 11,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      ResponsiveText(
                        '$completedForPlayer/$totalForPlayer',
                        baseFontSize: 10,
                        style: TextStyle(color: Colors.blueGrey[600]),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimerControls() {
    return Container(
      padding: ResponsiveConfig.paddingAll(context, 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(ResponsiveConfig.dimension(context, 12)),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.timer, color: Colors.orange[600]),
              ResponsiveSpacing(multiplier: 1, direction: Axis.horizontal),
              ResponsiveText(
                'Quick Actions',
                baseFontSize: 14,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.blueGrey[800],
                ),
              ),
            ],
          ),
          ResponsiveSpacing(multiplier: 1),
          ResponsiveButton(
            text: 'Quick Timer',
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Quick timer feature coming soon!')),
              );
            },
            baseHeight: 48,
            width: double.infinity,
            backgroundColor: Colors.orange[600],
            foregroundColor: Colors.white,
          ),
          ResponsiveSpacing(multiplier: 1),
          ResponsiveButton(
            text: 'Bulk Actions',
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Bulk actions feature coming soon!')),
              );
            },
            baseHeight: 48,
            width: double.infinity,
            backgroundColor: Colors.purple[600],
            foregroundColor: Colors.white,
          ),
        ],
      ),
    );
  }

  Widget _buildMainTimerInterface(List currentTests) {
    final currentTestData = currentTests[_currentTest] as Map<String, dynamic>;
    final testId = currentTestData['id'] as String;
    
    return SingleChildScrollView(
      padding: ResponsiveConfig.paddingAll(context, 24),
      child: Column(
        children: [
          // Test header
          Container(
            width: double.infinity,
            padding: ResponsiveConfig.paddingAll(context, 24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.blue[600]!, Colors.blue[400]!],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(ResponsiveConfig.dimension(context, 16)),
            ),
            child: Column(
              children: [
                Container(
                  width: ResponsiveConfig.dimension(context, 60),
                  height: ResponsiveConfig.dimension(context, 60),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: ResponsiveText(
                      '${_currentTest + 1}',
                      baseFontSize: 24,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.blue[600],
                      ),
                    ),
                  ),
                ),
                ResponsiveSpacing(multiplier: 2),
                ResponsiveText(
                  currentTestData['title'] as String? ?? 'Test',
                  baseFontSize: 24,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                  textAlign: TextAlign.center,
                ),
                ResponsiveText(
                  currentTestData['category'] as String? ?? '',
                  baseFontSize: 16,
                  style: const TextStyle(color: Colors.white70),
                  textAlign: TextAlign.center,
                ),
                ResponsiveSpacing(multiplier: 1),
                ResponsiveText(
                  currentTestData['description'] as String? ?? '',
                  baseFontSize: 14,
                  style: const TextStyle(color: Colors.white70),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
          
          ResponsiveSpacing(multiplier: 3),
          
          // Player grid for desktop
          _buildDesktopPlayerGrid(testId, currentTestData),
        ],
      ),
    );
  }

  Widget _buildDesktopPlayerGrid(String testId, Map<String, dynamic> testData) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        childAspectRatio: 1.0,
        crossAxisSpacing: ResponsiveConfig.spacing(context, 16),
        mainAxisSpacing: ResponsiveConfig.spacing(context, 16),
      ),
      itemCount: widget.players.length,
      itemBuilder: (context, index) {
        final player = widget.players[index];
        final playerId = player.id.toString();
        final testResult = _matrixData[playerId]?[testId];
        final isCompleted = testResult != null;

        return _buildDesktopPlayerTestCard(
          player: player,
          playerId: playerId,
          testId: testId,
          testData: testData,
          testResult: testResult,
          isCompleted: isCompleted,
        );
      },
    );
  }

  Widget _buildDesktopPlayerTestCard({
    required Player player,
    required String playerId,
    required String testId,
    required Map<String, dynamic> testData,
    required Map<String, dynamic>? testResult,
    required bool isCompleted,
  }) {
    return GestureDetector(
      onTap: () => _editTest(playerId, testId, testData, testResult),
      child: Container(
        decoration: BoxDecoration(
          color: isCompleted
              ? _getTimeColor(testResult!['time'], testData)
              : Colors.white,
          border: Border.all(
            color: isCompleted
                ? _getTimeBorderColor(testResult!['time'], testData)
                : Colors.blue,
            width: 2,
          ),
          borderRadius: BorderRadius.circular(ResponsiveConfig.dimension(context, 12)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Padding(
          padding: ResponsiveConfig.paddingAll(context, 12),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: isCompleted ? Colors.green[100] : Colors.blue[100],
                child: ResponsiveText(
                  player.jerseyNumber?.toString() ?? '?',
                  baseFontSize: 14,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: isCompleted ? Colors.green[700] : Colors.blue[700],
                  ),
                ),
              ),
              ResponsiveSpacing(multiplier: 1),
              ResponsiveText(
                player.name,
                baseFontSize: 12,
                style: const TextStyle(fontWeight: FontWeight.bold),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
              ),
              ResponsiveSpacing(multiplier: 0.5),
              if (isCompleted) ...[
                ResponsiveText(
                  '${testResult!['time'].toStringAsFixed(2)}s',
                  baseFontSize: 16,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                if (testResult['benchmarkLevel'] != null)
                  Container(
                    margin: ResponsiveConfig.paddingOnly(context, top: 4),
                    padding: ResponsiveConfig.paddingSymmetric(context, horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: _getBenchmarkLevelColor(testResult['benchmarkLevel']),
                      borderRadius: BorderRadius.circular(ResponsiveConfig.dimension(context, 8)),
                    ),
                    child: ResponsiveText(
                      testResult['benchmarkLevel'],
                      baseFontSize: 10,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
              ] else ...[
                Icon(
                  Icons.timer,
                  size: ResponsiveConfig.iconSize(context, 24),
                  color: Colors.blue[600],
                ),
                ResponsiveSpacing(multiplier: 0.5),
                ResponsiveText(
                  'Click to record',
                  baseFontSize: 10,
                  style: TextStyle(color: Colors.blue[600]),
                  textAlign: TextAlign.center,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAnalyticsSidebar() {
    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: ResponsiveConfig.paddingAll(context, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildLiveLeaderboard(),
                ResponsiveSpacing(multiplier: 3),
                _buildTeamSpeedStats(),
                ResponsiveSpacing(multiplier: 3),
                _buildProgressTracking(),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLiveLeaderboard() {
    return Container(
      padding: ResponsiveConfig.paddingAll(context, 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(ResponsiveConfig.dimension(context, 12)),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.leaderboard, color: Colors.amber[600]),
              ResponsiveSpacing(multiplier: 1, direction: Axis.horizontal),
              ResponsiveText(
                'Live Leaderboard',
                baseFontSize: 14,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.blueGrey[800],
                ),
              ),
            ],
          ),
          ResponsiveSpacing(multiplier: 1),
          _buildRealTimeLeaderboard(),
        ],
      ),
    );
  }

  Widget _buildTeamSpeedStats() {
    // Calculate team speed statistics
    final allTimes = <double>[];
    for (var playerData in _matrixData.values) {
      for (var testData in playerData.values) {
        final time = testData['time'] as double?;
        if (time != null) {
          allTimes.add(time);
        }
      }
    }
    
    double avgTime = 0;
    double fastestTime = 0;
    double slowestTime = 0;
    
    if (allTimes.isNotEmpty) {
      allTimes.sort();
      avgTime = allTimes.reduce((a, b) => a + b) / allTimes.length;
      fastestTime = allTimes.first;
      slowestTime = allTimes.last;
    }
    
    return Container(
      padding: ResponsiveConfig.paddingAll(context, 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(ResponsiveConfig.dimension(context, 12)),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.analytics, color: Colors.blue[600]),
              ResponsiveSpacing(multiplier: 1, direction: Axis.horizontal),
              ResponsiveText(
                'Team Statistics',
                baseFontSize: 14,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.blueGrey[800],
                ),
              ),
            ],
          ),
          ResponsiveSpacing(multiplier: 1),
          _buildStatRow('Average Time', avgTime > 0 ? '${avgTime.toStringAsFixed(2)}s' : 'N/A'),
          _buildStatRow('Fastest Time', fastestTime > 0 ? '${fastestTime.toStringAsFixed(2)}s' : 'N/A'),
          _buildStatRow('Slowest Time', slowestTime > 0 ? '${slowestTime.toStringAsFixed(2)}s' : 'N/A'),
          _buildStatRow('Tests Completed', '${_calculateCompletedTests()}'),
          _buildStatRow('Completion Rate', '${((_calculateCompletedTests() / _calculateTotalTests()) * 100).toStringAsFixed(1)}%'),
        ],
      ),
    );
  }

  Widget _buildStatRow(String label, String value) {
    return Padding(
      padding: ResponsiveConfig.paddingOnly(context, bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          ResponsiveText(
            label,
            baseFontSize: 12,
            style: TextStyle(color: Colors.blueGrey[600]),
          ),
          ResponsiveText(
            value,
            baseFontSize: 12,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressTracking() {
    final groups = widget.assessment['groups'] as List;
    final currentGroup = groups[_currentGroup] as Map<String, dynamic>;
    final currentTests = currentGroup['tests'] as List;
    
    return Container(
      padding: ResponsiveConfig.paddingAll(context, 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(ResponsiveConfig.dimension(context, 12)),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.trending_up, color: Colors.green[600]),
              ResponsiveSpacing(multiplier: 1, direction: Axis.horizontal),
              ResponsiveText(
                'Progress Tracking',
                baseFontSize: 14,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.blueGrey[800],
                ),
              ),
            ],
          ),
          ResponsiveSpacing(multiplier: 1),
          
          ResponsiveText(
            'Group ${_currentGroup + 1} of ${groups.length}',
            baseFontSize: 14,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          ResponsiveSpacing(multiplier: 0.5),
          ResponsiveText(
            currentGroup['name'] as String? ?? 'Current Group',
            baseFontSize: 12,
            style: TextStyle(color: Colors.blueGrey[600]),
          ),
          ResponsiveSpacing(multiplier: 1),
          
          LinearProgressIndicator(
            value: (_currentTest + 1) / currentTests.length,
            backgroundColor: Colors.grey[200],
            valueColor: AlwaysStoppedAnimation<Color>(Colors.green[600]!),
            minHeight: ResponsiveConfig.dimension(context, 8),
            borderRadius: BorderRadius.circular(ResponsiveConfig.dimension(context, 4)),
          ),
          ResponsiveSpacing(multiplier: 1),
          
          ResponsiveText(
            'Test ${_currentTest + 1} of ${currentTests.length}',
            baseFontSize: 12,
            style: TextStyle(color: Colors.blueGrey[600]),
          ),
          
          ResponsiveSpacing(multiplier: 2),
          
          ResponsiveText(
            'Overall Progress',
            baseFontSize: 14,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          ResponsiveSpacing(multiplier: 1),
          
          LinearProgressIndicator(
            value: _calculateCompletedTests() / _calculateTotalTests(),
            backgroundColor: Colors.grey[200],
            valueColor: AlwaysStoppedAnimation<Color>(Colors.blue[600]!),
            minHeight: ResponsiveConfig.dimension(context, 8),
            borderRadius: BorderRadius.circular(ResponsiveConfig.dimension(context, 4)),
          ),
          ResponsiveSpacing(multiplier: 1),
          
          ResponsiveText(
            '${_calculateCompletedTests()} of ${_calculateTotalTests()} tests completed',
            baseFontSize: 12,
            style: TextStyle(color: Colors.blueGrey[600]),
          ),
        ],
      ),
    );
  }

  // HELPER WIDGETS AND METHODS
  Widget _buildErrorScaffold(String message) {
    return Scaffold(
      appBar: AppBar(title: ResponsiveText('Error', baseFontSize: 18)),
      body: FullScreenContainer(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error, size: ResponsiveConfig.iconSize(context, 64), color: Colors.red),
              ResponsiveSpacing(multiplier: 2),
              ResponsiveText(
                message,
                baseFontSize: 18,
                style: const TextStyle(fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  int _getTotalTestsForCurrentGroup() {
    final groups = widget.assessment['groups'] as List;
    if (_currentGroup < groups.length) {
      final currentGroup = groups[_currentGroup] as Map<String, dynamic>;
      final tests = currentGroup['tests'] as List? ?? [];
      return tests.length;
    }
    return 0;
  }

  // All the existing helper methods from the original implementation...
  Map<String, dynamic> _getFallbackBenchmarksForTest(String testId) {
    const benchmarkData = {
      'forward_speed_test': {'Elite': 4.2, 'Advanced': 4.5, 'Developing': 4.8, 'Beginner': 5.2},
      'backward_speed_test': {'Elite': 5.2, 'Advanced': 5.6, 'Developing': 6.0, 'Beginner': 6.5},
      'agility_test': {'Elite': 9.0, 'Advanced': 9.8, 'Developing': 10.6, 'Beginner': 11.8},
      'transitions_test': {'Elite': 4.2, 'Advanced': 4.6, 'Developing': 5.0, 'Beginner': 5.5},
      'crossovers_test': {'Elite': 7.8, 'Advanced': 8.5, 'Developing': 9.3, 'Beginner': 10.2},
      'stop_start_test': {'Elite': 2.3, 'Advanced': 2.5, 'Developing': 2.8, 'Beginner': 3.2},
    };
    
    final benchmarks = benchmarkData[testId] ?? {};
    debugPrint('Fallback benchmarks for $testId: $benchmarks');
    return benchmarks;
  }

  Color _getTimeColor(double time, Map<String, dynamic> testData) {
    Map<String, dynamic> benchmarks = testData['benchmarks'] as Map<String, dynamic>? ?? {};
    
    if (benchmarks.isEmpty) {
      final testId = testData['id'] as String?;
      if (testId != null) {
        benchmarks = _getFallbackBenchmarksForTest(testId);
      }
    }
    
    if (benchmarks.isEmpty) return Colors.blue[100]!;
    
    final eliteTime = benchmarks['Elite'] as double?;
    final advancedTime = benchmarks['Advanced'] as double?;
    final developingTime = benchmarks['Developing'] as double?;
    
    if (eliteTime != null && time <= eliteTime) return Colors.green[100]!;
    if (advancedTime != null && time <= advancedTime) return Colors.lightGreen[100]!;
    if (developingTime != null && time <= developingTime) return Colors.orange[100]!;
    return Colors.red[100]!;
  }

  Color _getTimeBorderColor(double time, Map<String, dynamic> testData) {
    Map<String, dynamic> benchmarks = testData['benchmarks'] as Map<String, dynamic>? ?? {};
    
    if (benchmarks.isEmpty) {
      final testId = testData['id'] as String?;
      if (testId != null) {
        benchmarks = _getFallbackBenchmarksForTest(testId);
      }
    }
    
    if (benchmarks.isEmpty) return Colors.blue;
    
    final eliteTime = benchmarks['Elite'] as double?;
    final advancedTime = benchmarks['Advanced'] as double?;
    final developingTime = benchmarks['Developing'] as double?;
    
    if (eliteTime != null && time <= eliteTime) return Colors.green;
    if (advancedTime != null && time <= advancedTime) return Colors.lightGreen;
    if (developingTime != null && time <= developingTime) return Colors.orange;
    return Colors.red;
  }

  Color _getBenchmarkLevelColor(String level) {
    switch (level.toLowerCase()) {
      case 'elite':
        return Colors.green;
      case 'advanced':
        return Colors.lightGreen;
      case 'developing':
        return Colors.orange;
      case 'beginner':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _getBenchmarkLevel(double time, Map<String, dynamic> testData) {
    Map<String, dynamic> benchmarks = testData['benchmarks'] as Map<String, dynamic>? ?? {};
    
    if (benchmarks.isEmpty) {
      final testId = testData['id'] as String?;
      if (testId != null) {
        benchmarks = _getFallbackBenchmarksForTest(testId);
      }
    }
    
    if (benchmarks.isEmpty) return '';
    
    final eliteTime = benchmarks['Elite'] as double?;
    final advancedTime = benchmarks['Advanced'] as double?;
    final developingTime = benchmarks['Developing'] as double?;
    final beginnerTime = benchmarks['Beginner'] as double?;
    
    if (eliteTime != null && time <= eliteTime) return 'Elite';
    if (advancedTime != null && time <= advancedTime) return 'Advanced';
    if (developingTime != null && time <= developingTime) return 'Developing';
    if (beginnerTime != null && time <= beginnerTime) return 'Beginner';
    return '';
  }

  void _editTest(String playerId, String testId, Map<String, dynamic> testData, Map<String, dynamic>? existingResult) {
    debugPrint('=== EDIT TEST DEBUG ===');
    debugPrint('Player ID: $playerId');
    debugPrint('Test ID: $testId');
    debugPrint('Test Data: $testData');
    debugPrint('Test Data Keys: ${testData.keys.toList()}');
    debugPrint('Benchmarks in testData: ${testData['benchmarks']}');
    debugPrint('======================');
    
    final timeController = TextEditingController(text: existingResult?['time']?.toString() ?? '');
    final notesController = TextEditingController(text: existingResult?['notes'] ?? '');
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: ResponsiveText('Record Test Time', baseFontSize: 18),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: ResponsiveConfig.paddingAll(context, 12),
                decoration: BoxDecoration(
                  color: _primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(ResponsiveConfig.dimension(context, 8)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.person, color: _primaryColor),
                        ResponsiveSpacing(multiplier: 1, direction: Axis.horizontal),
                        ResponsiveText(
                          widget.players.firstWhere((p) => p.id.toString() == playerId).name,
                          baseFontSize: 14,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.blueGrey[800],
                          ),
                        ),
                      ],
                    ),
                    ResponsiveSpacing(multiplier: 1),
                    Row(
                      children: [
                        Icon(Icons.speed, color: _primaryColor),
                        ResponsiveSpacing(multiplier: 1, direction: Axis.horizontal),
                        Expanded(
                          child: ResponsiveText(
                            testData['title'] as String? ?? 'Test',
                            baseFontSize: 14,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.blueGrey[800],
                            ),
                          ),
                        ),
                      ],
                    ),
                    ResponsiveSpacing(multiplier: 0.5),
                    ResponsiveText(
                      testData['description'] as String? ?? '',
                      baseFontSize: 12,
                      style: TextStyle(color: Colors.blueGrey[600]),
                    ),
                  ],
                ),
              ),
              
              ResponsiveSpacing(multiplier: 3),
              
              ResponsiveText(
                'Test Time (seconds)',
                baseFontSize: 14,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.blueGrey[700],
                ),
              ),
              ResponsiveSpacing(multiplier: 1),
              StandardTextField(
                controller: timeController,
                hintText: 'Enter time (e.g., 4.75)',
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
                ],
              ),
              
              ResponsiveSpacing(multiplier: 3),
              
              Builder(
                builder: (context) {
                  debugPrint('Building benchmarks display for test: ${testData['id']}');
                  return _buildBenchmarksDisplay(testData);
                }
              ),
              
              ResponsiveSpacing(multiplier: 3),
              
              ResponsiveText(
                'Notes (Optional)',
                baseFontSize: 14,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.blueGrey[700],
                ),
              ),
              ResponsiveSpacing(multiplier: 1),
              StandardTextField(
                controller: notesController,
                hintText: 'Add notes about performance...',
                maxLines: 3,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: ResponsiveText('Cancel', baseFontSize: 14),
          ),
          ResponsiveButton(
            text: 'Save Time',
            onPressed: () async {
              if (!await _validateTimeInput(timeController.text)) return;
              
              final time = double.parse(timeController.text);
              final benchmarkLevel = _getBenchmarkLevel(time, testData);
              
              final testResult = {
                'testId': testId,
                'time': time,
                'timestamp': DateTime.now().toIso8601String(),
                'notes': notesController.text,
                'playerId': playerId,
                'playerName': widget.players.firstWhere((p) => p.id.toString() == playerId).name,
                'benchmarkLevel': benchmarkLevel,
              };
              
              _matrixData[playerId] ??= {};
              _matrixData[playerId]![testId] = testResult;
              
              widget.onAddResult(playerId, testId, testResult);
              
              Navigator.of(context).pop();
              
              setState(() {});
            },
            baseHeight: 48,
            backgroundColor: _primaryColor,
            foregroundColor: Colors.white,
          ),
        ],
      ),
    );
  }

  Widget _buildBenchmarksDisplay(Map<String, dynamic> testData) {
    Map<String, dynamic> benchmarks = testData['benchmarks'] as Map<String, dynamic>? ?? {};
    
    if (benchmarks.isEmpty) {
      final testId = testData['id'] as String?;
      if (testId != null) {
        benchmarks = _getFallbackBenchmarksForTest(testId);
        debugPrint('Using fallback benchmarks for $testId: $benchmarks');
      }
    } else {
      debugPrint('Found benchmarks in test data: $benchmarks');
    }
    
    if (benchmarks.isEmpty) {
      return Container(
        padding: ResponsiveConfig.paddingAll(context, 12),
        decoration: BoxDecoration(
          color: Colors.blue[50],
          borderRadius: BorderRadius.circular(ResponsiveConfig.dimension(context, 8)),
          border: Border.all(color: Colors.blue[200]!),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ResponsiveText(
              'No benchmarks available for this test',
              baseFontSize: 12,
              style: TextStyle(
                color: Colors.blue[700],
                fontWeight: FontWeight.bold,
              ),
            ),
            ResponsiveSpacing(multiplier: 0.5),
            ResponsiveText(
              'Test ID: ${testData['id'] ?? 'Unknown'}',
              baseFontSize: 10,
              style: TextStyle(color: Colors.blue[600]),
            ),
          ],
        ),
      );
    }

    final expectedLevels = ['Elite', 'Advanced', 'Developing', 'Beginner'];
    final orderedBenchmarks = <MapEntry<String, dynamic>>[];
    
    for (final level in expectedLevels) {
      final entry = benchmarks.entries.where((e) => e.key == level).firstOrNull;
      if (entry != null) {
        orderedBenchmarks.add(entry);
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ResponsiveText(
          'Performance Benchmarks',
          baseFontSize: 14,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.blueGrey[700],
          ),
        ),
        ResponsiveSpacing(multiplier: 1),
        Container(
          padding: ResponsiveConfig.paddingAll(context, 12),
          decoration: BoxDecoration(
            color: Colors.grey[50],
            borderRadius: BorderRadius.circular(ResponsiveConfig.dimension(context, 8)),
            border: Border.all(color: Colors.grey[300]!),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: orderedBenchmarks.map((entry) {
              final level = entry.key;
              final time = (entry.value as num).toDouble();
              final color = _getBenchmarkLevelColor(level);
              
              return Expanded(
                child: Container(
                  margin: ResponsiveConfig.paddingSymmetric(context, horizontal: 2),
                  padding: ResponsiveConfig.paddingAll(context, 8),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(ResponsiveConfig.dimension(context, 6)),
                    border: Border.all(color: color.withOpacity(0.3)),
                  ),
                  child: Column(
                    children: [
                      ResponsiveText(
                        '${time}s',
                        baseFontSize: 12,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: color,
                        ),
                      ),
                      ResponsiveText(
                        level,
                        baseFontSize: 10,
                        style: TextStyle(color: color),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Future<bool> _validateTimeInput(String timeText) async {
    if (timeText.isEmpty) {
      await DialogService.showInformation(
        context,
        title: 'Missing Data',
        message: 'Please enter a time',
      );
      return false;
    }

    final time = double.tryParse(timeText);
    if (time == null || time <= 0) {
      await DialogService.showInformation(
        context,
        title: 'Invalid Data',
        message: 'Please enter a valid time in seconds',
      );
      return false;
    }

    return true;
  }

  bool _canAdvanceToNextTest() {
    final groups = widget.assessment['groups'] as List;
    final currentGroup = groups[_currentGroup] as Map<String, dynamic>;
    final currentTests = currentGroup['tests'] as List;
    final currentTestData = currentTests[_currentTest] as Map<String, dynamic>;
    final testId = currentTestData['id'] as String;
    
    for (var player in widget.players) {
      final playerId = player.id.toString();
      if (_matrixData[playerId]?[testId] == null) {
        return false;
      }
    }
    return true;
  }

  void _goToPreviousTest() {
    if (_currentTest > 0) {
      setState(() {
        _currentTest--;
      });
    }
  }

  void _advanceProgress() {
    final groups = widget.assessment['groups'] as List;
    final currentGroup = groups[_currentGroup] as Map<String, dynamic>;
    final currentTests = currentGroup['tests'] as List;
    final isLastTest = _currentTest >= currentTests.length - 1;
    final isLastGroup = _currentGroup >= groups.length - 1;

    if (isLastTest && isLastGroup) {
      _handleAssessmentCompleted();
    } else if (isLastTest) {
      setState(() {
        _currentGroup++;
        _currentTest = 0;
        _initializeMatrixData();
      });
      
      final nextGroup = groups[_currentGroup] as Map<String, dynamic>;
      DialogService.showCustom<void>(
        context,
        content: Padding(
          padding: ResponsiveConfig.paddingAll(context, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.arrow_forward_ios,
                color: Colors.blue,
                size: ResponsiveConfig.iconSize(context, 48),
              ),
              ResponsiveSpacing(multiplier: 2),
              ResponsiveText(
                'Group Complete!',
                baseFontSize: 18,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.blueGrey[800],
                ),
              ),
              ResponsiveSpacing(multiplier: 1),
              ResponsiveText(
                'Moving to: ${nextGroup['name']}',
                baseFontSize: 14,
                textAlign: TextAlign.center,
              ),
              ResponsiveSpacing(multiplier: 2),
              ResponsiveButton(
                text: 'Start Group',
                onPressed: () => Navigator.of(context).pop(),
                baseHeight: 48,
                backgroundColor: _primaryColor,
                foregroundColor: Colors.white,
              ),
            ],
          ),
        ),
      );
    } else {
      setState(() {
        _currentTest++;
      });
    }
  }

  Future<void> _handleAssessmentCompleted() async {
    if (!mounted) return;

    await DialogService.showCustom<void>(
      context,
      content: Padding(
        padding: ResponsiveConfig.paddingAll(context, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.emoji_events,
              color: Colors.amber,
              size: ResponsiveConfig.iconSize(context, 64),
            ),
            ResponsiveSpacing(multiplier: 2),
            ResponsiveText(
              'Team Assessment Complete!',
              baseFontSize: 20,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.blueGrey[800],
              ),
            ),
            ResponsiveSpacing(multiplier: 1),
            ResponsiveText(
              'All ${widget.players.length} players have completed their skating assessment.\n\nTotal tests recorded: ${_calculateCompletedTests()}',
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
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            ),
          ],
        ),
      ),
      barrierDismissible: false,
    );

    widget.onComplete();
  }
  
  int _calculateTotalTests() {
    int total = 0;
    final groups = widget.assessment['groups'] as List?;
    if (groups != null) {
      for (var group in groups) {
        total += ((group as Map<String, dynamic>)['tests'] as List).length * widget.players.length;
      }
    }
    return total;
  }
  
  int _calculateCompletedTests() {
    int total = 0;
    for (var results in widget.playerTestResults.values) {
      total += results.length;
    }
    return total;
  }
}