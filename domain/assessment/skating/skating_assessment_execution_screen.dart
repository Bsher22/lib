// Fixed lib/widgets/domain/assessment/skating/skating_assessment_execution_screen.dart
// Change: addTestToSession called with no args, but requires 1 positional. Added required parameters.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:hockey_shot_tracker/models/skating.dart';
import 'package:hockey_shot_tracker/providers/app_state.dart';
import 'package:hockey_shot_tracker/services/index.dart';
import 'package:hockey_shot_tracker/widgets/domain/assessment/common/assessment_progress_header.dart';
import 'package:hockey_shot_tracker/widgets/core/timer/index.dart';
import 'package:hockey_shot_tracker/services/dialog_service.dart';
import 'package:hockey_shot_tracker/services/infrastructure/api_service_factory.dart';
import 'package:hockey_shot_tracker/responsive_system/index.dart';

class SkatingAssessmentExecutionScreen extends StatefulWidget {
  final Map<String, dynamic> assessment;
  final Map<String, Map<String, dynamic>> testResults;
  final Function(String, Map<String, dynamic>) onAddResult;
  final VoidCallback onComplete;
  
  const SkatingAssessmentExecutionScreen({
    Key? key,
    required this.assessment,
    required this.testResults,
    required this.onAddResult,
    required this.onComplete,
  }) : super(key: key);

  @override
  State<SkatingAssessmentExecutionScreen> createState() => _SkatingAssessmentExecutionScreenState();
}

class _SkatingAssessmentExecutionScreenState extends State<SkatingAssessmentExecutionScreen> {
  int _currentGroup = 0;
  int _currentTest = 0;
  bool _isRecording = false;
  
  // Form controllers
  final TextEditingController _timeController = TextEditingController();
  final UnifiedTimerController _timerController = UnifiedTimerController();
  final TextEditingController _notesController = TextEditingController();
  
  // Session-based state management
  String? _sessionId;
  Map<String, double> _sessionTestTimes = {}; // Track all test times in session
  bool _sessionComplete = false;
  
  ApiService get _apiService {
    final appState = Provider.of<AppState>(context, listen: false);
    return appState.api;
  }

  @override
  void initState() {
    super.initState();
    _initializeSession();
    _debugAssessmentStructure();
  }

  void _initializeSession() {
    final appState = Provider.of<AppState>(context, listen: false);
    _sessionId = appState.getCurrentSkatingAssessmentId() ?? 
                 widget.assessment['assessmentId']?.toString() ?? 
                 widget.assessment['assessment_id']?.toString();
    
    print('=== SESSION INITIALIZATION ===');
    print('Session ID from AppState: ${appState.getCurrentSkatingAssessmentId()}');
    print('Session ID from widget: ${widget.assessment['assessmentId']}');
    print('Final session ID: $_sessionId');
    
    if (_sessionId == null || _sessionId!.isEmpty) {
      print('🚨 CRITICAL: No session ID available');
      // Generate emergency session ID
      _sessionId = DateTime.now().millisecondsSinceEpoch.toString();
      appState.setCurrentSkatingAssessmentId(_sessionId!);
      print('🚨 Generated emergency session ID: $_sessionId');
    }
    
    print('============================');
  }

  void _debugAssessmentStructure() {
    print('=== EXECUTION SCREEN DEBUG ===');
    final groups = widget.assessment['groups'] as List?;
    
    if (groups == null) {
      print('❌ No groups found!');
      return;
    }
    
    print('✅ Found ${groups.length} groups');
    print('Session ID: $_sessionId');
    
    int totalTestsExpected = 0;
    for (int i = 0; i < groups.length; i++) {
      final group = groups[i] as Map<String, dynamic>;
      final tests = group['tests'] as List?;
      
      if (tests != null) {
        totalTestsExpected += tests.length;
        print('Group $i: ${group['name']} (${tests.length} tests)');
      }
    }
    
    print('Total tests expected: $totalTestsExpected');
    print('============================');
  }
  
  @override
  void dispose() {
    _timeController.dispose();
    _notesController.dispose();
    _timerController.dispose();
    super.dispose();
  }

  Future<bool> _handleBackPress() async {
    if (_sessionTestTimes.isEmpty) {
      // No tests recorded yet, safe to exit
      final appState = Provider.of<AppState>(context, listen: false);
      appState.clearCurrentSkatingAssessmentId();
      return true;
    }

    final shouldExit = await DialogService.showConfirmation(
      context,
      title: 'Exit Assessment?',
      message: 'You have recorded ${_sessionTestTimes.length} test(s). Your progress has been saved to the session.\n\nExit anyway?',
      confirmLabel: 'Exit',
      cancelLabel: 'Stay',
    );
    
    if (shouldExit == true) {
      final appState = Provider.of<AppState>(context, listen: false);
      appState.clearCurrentSkatingAssessmentId();
      return true;
    }
    
    return false;
  }
  
  @override
  Widget build(BuildContext context) {
    final groups = widget.assessment['groups'] as List?;
    if (groups == null || groups.isEmpty) {
      return _buildErrorScreen('No assessment groups found');
    }

    // Verify assessment structure
    int totalTests = 0;
    for (var group in groups) {
      totalTests += ((group as Map<String, dynamic>)['tests'] as List).length;
    }
    
    if (totalTests == 0) {
      return _buildErrorScreen('No tests found in assessment');
    }
    
    // Bounds checking
    if (_currentGroup >= groups.length) {
      return _buildErrorScreen('Current group index out of bounds');
    }
    
    final currentGroup = groups[_currentGroup] as Map<String, dynamic>;
    final currentTests = currentGroup['tests'] as List?;
    
    if (currentTests == null || currentTests.isEmpty) {
      return _buildErrorScreen('No tests found in group: ${currentGroup['name']}');
    }
    
    if (_currentTest >= currentTests.length) {
      return _buildErrorScreen('Current test index out of bounds');
    }
    
    // Calculate progress
    final progressValue = totalTests > 0 ? _sessionTestTimes.length / totalTests : 0.0;

    return WillPopScope(
      onWillPop: _handleBackPress,
      child: AdaptiveLayout(
        builder: (deviceType, isLandscape) {
          switch (deviceType) {
            case DeviceType.mobile:
              return _buildMobileLayout(groups, currentGroup, currentTests, totalTests, progressValue);
            case DeviceType.tablet:
              return _buildTabletLayout(groups, currentGroup, currentTests, totalTests, progressValue);
            case DeviceType.desktop:
              return _buildDesktopLayout(groups, currentGroup, currentTests, totalTests, progressValue);
          }
        },
      ),
    );
  }

  // ✅ MOBILE LAYOUT: Vertical stack with collapsible sections
  Widget _buildMobileLayout(List groups, Map<String, dynamic> currentGroup, List currentTests, int totalTests, double progressValue) {
    return AdaptiveScaffold(
      title: widget.assessment['title'] ?? 'Skating Assessment',
      backgroundColor: Colors.blueGrey[900],
      actions: [_buildSessionIndicator()],
      body: Stack(
        children: [
          Column(
            children: [
              // Progress section
              AssessmentProgressHeader(
                groupTitle: currentGroup['name'] as String,
                groupDescription: currentGroup['description'] as String? ?? '',
                currentGroupIndex: _currentGroup,
                totalGroups: groups.length,
                currentItemIndex: _currentTest,
                totalItems: currentTests.length,
                progressValue: progressValue,
              ),
              
              // Test execution section
              Expanded(
                child: SingleChildScrollView(
                  padding: ResponsiveConfig.paddingAll(context, 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Session progress card
                      _buildSessionProgressCard(totalTests),
                      ResponsiveSpacing(multiplier: 2),
                      
                      // Current test info
                      _buildCurrentTestInfo(),
                      ResponsiveSpacing(multiplier: 3),
                      
                      // Timer section
                      _buildTimerSection(),
                      ResponsiveSpacing(multiplier: 3),
                      
                      // Manual time entry
                      _buildManualTimeEntry(),
                      ResponsiveSpacing(multiplier: 3),
                      
                      // Benchmarks
                      _buildBenchmarks(),
                      ResponsiveSpacing(multiplier: 3),
                      
                      // Notes
                      _buildNotesSection(),
                    ],
                  ),
                ),
              ),
              
              // Record test button
              _buildRecordButton(),
            ],
          ),
          
          // Loading overlay
          if (_isRecording) _buildLoadingOverlay(),
        ],
      ),
    );
  }

  // ✅ TABLET LAYOUT: Side-by-side with timer emphasis
  Widget _buildTabletLayout(List groups, Map<String, dynamic> currentGroup, List currentTests, int totalTests, double progressValue) {
    return AdaptiveScaffold(
      title: widget.assessment['title'] ?? 'Skating Assessment',
      backgroundColor: Colors.blueGrey[900],
      actions: [_buildSessionIndicator()],
      body: Stack(
        children: [
          Column(
            children: [
              // Progress section
              AssessmentProgressHeader(
                groupTitle: currentGroup['name'] as String,
                groupDescription: currentGroup['description'] as String? ?? '',
                currentGroupIndex: _currentGroup,
                totalGroups: groups.length,
                currentItemIndex: _currentTest,
                totalItems: currentTests.length,
                progressValue: progressValue,
              ),
              
              Expanded(
                child: Row(
                  children: [
                    // Main execution area
                    Expanded(
                      flex: 3,
                      child: SingleChildScrollView(
                        padding: ResponsiveConfig.paddingAll(context, 16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            _buildSessionProgressCard(totalTests),
                            ResponsiveSpacing(multiplier: 2),
                            _buildCurrentTestInfo(),
                            ResponsiveSpacing(multiplier: 3),
                            _buildManualTimeEntry(),
                            ResponsiveSpacing(multiplier: 3),
                            _buildNotesSection(),
                          ],
                        ),
                      ),
                    ),
                    
                    // Timer sidebar
                    Expanded(
                      flex: 2,
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.grey[50],
                          border: Border(left: BorderSide(color: Colors.grey[300]!)),
                        ),
                        child: SingleChildScrollView(
                          padding: ResponsiveConfig.paddingAll(context, 16),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              _buildTimerSection(),
                              ResponsiveSpacing(multiplier: 3),
                              _buildBenchmarks(),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              
              _buildRecordButton(),
            ],
          ),
          
          if (_isRecording) _buildLoadingOverlay(),
        ],
      ),
    );
  }

  // ✅ DESKTOP LAYOUT: Three-panel dashboard
  Widget _buildDesktopLayout(List groups, Map<String, dynamic> currentGroup, List currentTests, int totalTests, double progressValue) {
    return AdaptiveScaffold(
      title: widget.assessment['title'] ?? 'Skating Assessment',
      backgroundColor: Colors.blueGrey[900],
      actions: [_buildSessionIndicator()],
      body: Stack(
        children: [
          Column(
            children: [
              // Enhanced progress section for desktop
              _buildDesktopProgressHeader(currentGroup, groups, currentTests, totalTests, progressValue),
              
              Expanded(
                child: Row(
                  children: [
                    // Test information panel
                    Expanded(
                      flex: 2,
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.grey[50],
                          border: Border(right: BorderSide(color: Colors.grey[300]!)),
                        ),
                        child: SingleChildScrollView(
                          padding: ResponsiveConfig.paddingAll(context, 20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              _buildSessionProgressCard(totalTests),
                              ResponsiveSpacing(multiplier: 3),
                              _buildCurrentTestInfo(),
                              ResponsiveSpacing(multiplier: 3),
                              _buildBenchmarks(),
                            ],
                          ),
                        ),
                      ),
                    ),
                    
                    // Timer and input area
                    Expanded(
                      flex: 3,
                      child: SingleChildScrollView(
                        padding: ResponsiveConfig.paddingAll(context, 20),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            _buildEnhancedTimerSection(),
                            ResponsiveSpacing(multiplier: 4),
                            _buildManualTimeEntry(),
                            ResponsiveSpacing(multiplier: 4),
                            _buildNotesSection(),
                          ],
                        ),
                      ),
                    ),
                    
                    // Action sidebar
                    Container(
                      width: ResponsiveConfig.dimension(context, 280),
                      decoration: BoxDecoration(
                        color: Colors.blue[50],
                        border: Border(left: BorderSide(color: Colors.grey[300]!)),
                      ),
                      child: _buildDesktopActionSidebar(totalTests),
                    ),
                  ],
                ),
              ),
              
              _buildRecordButton(),
            ],
          ),
          
          if (_isRecording) _buildLoadingOverlay(),
        ],
      ),
    );
  }

  Widget _buildSessionIndicator() {
    return Padding(
      padding: ResponsiveConfig.paddingOnly(context, right: 16),
      child: Center(
        child: Container(
          padding: ResponsiveConfig.paddingSymmetric(context, horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.blue[100],
            borderRadius: BorderRadius.circular(8),
          ),
          child: ResponsiveText(
            'Session: ${_sessionId?.substring(_sessionId!.length - 6) ?? 'Unknown'}',
            baseFontSize: 12,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.blue[800],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDesktopProgressHeader(Map<String, dynamic> currentGroup, List groups, List currentTests, int totalTests, double progressValue) {
    return Container(
      padding: ResponsiveConfig.paddingAll(context, 20),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Colors.grey[300]!)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Icon(
                Icons.sports_hockey,
                size: ResponsiveConfig.iconSize(context, 32),
                color: Colors.cyanAccent[700],
              ),
              ResponsiveSpacing(multiplier: 2, direction: Axis.horizontal),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ResponsiveText(
                      currentGroup['name'] as String,
                      baseFontSize: 24,
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    ResponsiveText(
                      currentGroup['description'] as String? ?? '',
                      baseFontSize: 16,
                      style: TextStyle(color: Colors.blueGrey[600]),
                    ),
                  ],
                ),
              ),
              Container(
                padding: ResponsiveConfig.paddingSymmetric(context, horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.green[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: ResponsiveText(
                  'Group ${_currentGroup + 1} of ${groups.length}',
                  baseFontSize: 14,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.green[800],
                  ),
                ),
              ),
              ResponsiveSpacing(multiplier: 2, direction: Axis.horizontal),
              Container(
                padding: ResponsiveConfig.paddingSymmetric(context, horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.blue[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: ResponsiveText(
                  'Test ${_currentTest + 1} of ${currentTests.length}',
                  baseFontSize: 14,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.blue[800],
                  ),
                ),
              ),
            ],
          ),
          ResponsiveSpacing(multiplier: 2),
          
          // Enhanced progress bar
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  ResponsiveText(
                    'Overall Progress',
                    baseFontSize: 14,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.blueGrey[700],
                    ),
                  ),
                  Spacer(),
                  ResponsiveText(
                    '${_sessionTestTimes.length}/$totalTests tests completed',
                    baseFontSize: 14,
                    style: TextStyle(color: Colors.blueGrey[600]),
                  ),
                ],
              ),
              ResponsiveSpacing(multiplier: 1),
              LinearProgressIndicator(
                value: progressValue,
                backgroundColor: Colors.grey[200],
                valueColor: AlwaysStoppedAnimation<Color>(Colors.cyanAccent[700]!),
                minHeight: ResponsiveConfig.dimension(context, 8),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSessionProgressCard(int totalTests) {
    return ResponsiveCard(
      backgroundColor: Colors.green[50],
      borderColor: Colors.green[200],
      padding: ResponsiveConfig.paddingAll(context, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Icon(Icons.analytics, color: Colors.green[700], size: ResponsiveConfig.iconSize(context, 20)),
              ResponsiveSpacing(multiplier: 1, direction: Axis.horizontal),
              ResponsiveText(
                'Session Progress',
                baseFontSize: 16,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.green[800],
                ),
              ),
              Spacer(),
              Container(
                padding: ResponsiveConfig.paddingSymmetric(context, horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.green[100],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ResponsiveText(
                  '${_sessionTestTimes.length}/$totalTests',
                  baseFontSize: 14,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.green[800],
                  ),
                ),
              ),
            ],
          ),
          ResponsiveSpacing(multiplier: 1.5),
          
          // Progress bar
          LinearProgressIndicator(
            value: totalTests > 0 ? _sessionTestTimes.length / totalTests : 0.0,
            backgroundColor: Colors.green[200],
            valueColor: AlwaysStoppedAnimation<Color>(Colors.green[600]!),
            minHeight: ResponsiveConfig.dimension(context, 8),
          ),
          
          ResponsiveSpacing(multiplier: 1.5),
          
          // Session details
          Row(
            children: [
              Icon(Icons.badge, size: ResponsiveConfig.iconSize(context, 16), color: Colors.green[700]),
              ResponsiveSpacing(multiplier: 0.5, direction: Axis.horizontal),
              ResponsiveText(
                'Session ID: ${_sessionId?.substring(_sessionId!.length - 6) ?? 'Unknown'}',
                baseFontSize: 12,
                style: TextStyle(color: Colors.green[700]),
              ),
              ResponsiveSpacing(multiplier: 2, direction: Axis.horizontal),
              Icon(Icons.timer, size: ResponsiveConfig.iconSize(context, 16), color: Colors.green[700]),
              ResponsiveSpacing(multiplier: 0.5, direction: Axis.horizontal),
              ResponsiveText(
                'Tests Completed: ${_sessionTestTimes.length}',
                baseFontSize: 12,
                style: TextStyle(color: Colors.green[700]),
              ),
            ],
          ),
          
          // Show completed tests
          if (_sessionTestTimes.isNotEmpty) ...[
            ResponsiveSpacing(multiplier: 1),
            Wrap(
              spacing: ResponsiveConfig.spacing(context, 4),
              children: _sessionTestTimes.keys.map((testId) {
                return Container(
                  padding: ResponsiveConfig.paddingSymmetric(context, horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.green[100],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: ResponsiveText(
                    '${_getTestDisplayName(testId)}: ${_sessionTestTimes[testId]!.toStringAsFixed(2)}s',
                    baseFontSize: 10,
                    style: TextStyle(color: Colors.green[700]),
                  ),
                );
              }).toList(),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildErrorScreen(String message) {
    return AdaptiveScaffold(
      title: 'Error',
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error, size: ResponsiveConfig.iconSize(context, 64), color: Colors.red),
            ResponsiveSpacing(multiplier: 2),
            ResponsiveText(
              message,
              baseFontSize: 18,
              style: TextStyle(fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            ResponsiveSpacing(multiplier: 2),
            ResponsiveButton(
              text: 'Go Back',
              onPressed: () => Navigator.of(context).pop(),
              baseHeight: 48,
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildCurrentTestInfo() {
    final groups = widget.assessment['groups'] as List;
    final currentGroup = groups[_currentGroup] as Map<String, dynamic>;
    final tests = currentGroup['tests'] as List;
    final currentTestData = tests[_currentTest] as Map<String, dynamic>;
    
    return ResponsiveCard(
      padding: ResponsiveConfig.paddingAll(context, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          ResponsiveText(
            currentTestData['title'] as String? ?? 'Unknown Test',
            baseFontSize: 18,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.blueGrey[800],
            ),
          ),
          ResponsiveSpacing(multiplier: 1),
          ResponsiveText(
            currentTestData['description'] as String? ?? 'No description provided',
            baseFontSize: 14,
            style: TextStyle(color: Colors.blueGrey[600]),
          ),
          ResponsiveSpacing(multiplier: 1.5),
          Row(
            children: [
              Icon(Icons.category, size: ResponsiveConfig.iconSize(context, 16), color: Colors.blueGrey[700]),
              ResponsiveSpacing(multiplier: 1, direction: Axis.horizontal),
              ResponsiveText(
                'Category: ${currentTestData['category'] as String? ?? 'N/A'}',
                baseFontSize: 14,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.blueGrey[700],
                ),
              ),
              Spacer(),
              Icon(Icons.speed, size: ResponsiveConfig.iconSize(context, 16), color: Colors.blueGrey[700]),
              ResponsiveSpacing(multiplier: 1, direction: Axis.horizontal),
              ResponsiveText(
                'ID: ${currentTestData['id'] as String? ?? 'N/A'}',
                baseFontSize: 14,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.blueGrey[700],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ✅ PHASE 4 ENHANCED: Timing Controls Interface with Device Optimization
  Widget _buildTimerSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        ResponsiveText(
          'Test Timer',
          baseFontSize: 16,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.blueGrey[700],
          ),
        ),
        ResponsiveSpacing(multiplier: 1),
        UnifiedTimer(
          controller: _timerController,
          displayStyle: TimerDisplayStyle.expanded,
          primaryColor: Colors.cyanAccent[700]!,
          onTimeRecorded: (timeInSeconds) {
            setState(() {
              _timeController.text = timeInSeconds.toStringAsFixed(2);
            });
          },
        ),
      ],
    );
  }

  // ✅ PHASE 4 NEW: Enhanced desktop timer with larger precision controls
  Widget _buildEnhancedTimerSection() {
    return ResponsiveCard(
      padding: ResponsiveConfig.paddingAll(context, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Icon(
                Icons.timer,
                color: Colors.cyanAccent[700],
                size: ResponsiveConfig.iconSize(context, 24),
              ),
              ResponsiveSpacing(multiplier: 1.5, direction: Axis.horizontal),
              ResponsiveText(
                'Precision Timer',
                baseFontSize: 20,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.blueGrey[800],
                ),
              ),
            ],
          ),
          ResponsiveSpacing(multiplier: 3),
          
          // Enhanced timer display
          UnifiedTimer(
            controller: _timerController,
            displayStyle: TimerDisplayStyle.expanded,
            primaryColor: Colors.cyanAccent[700]!,
            onTimeRecorded: (timeInSeconds) {
              setState(() {
                _timeController.text = timeInSeconds.toStringAsFixed(2);
              });
            },
          ),
          
          ResponsiveSpacing(multiplier: 3),
          
          // Quick timing controls
          ResponsiveText(
            'Quick Actions',
            baseFontSize: 16,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.blueGrey[700],
            ),
          ),
          ResponsiveSpacing(multiplier: 1.5),
          
          Row(
            children: [
              Expanded(
                child: ResponsiveButton(
                  text: 'Start',
                  onPressed: () => _timerController.start(),
                  baseHeight: 56, // Enhanced for timing precision
                  backgroundColor: Colors.green[600],
                ),
              ),
              ResponsiveSpacing(multiplier: 1, direction: Axis.horizontal),
              Expanded(
                child: ResponsiveButton(
                  text: 'Stop',
                  onPressed: () => _timerController.stop(),
                  baseHeight: 56,
                  backgroundColor: Colors.red[600],
                ),
              ),
              ResponsiveSpacing(multiplier: 1, direction: Axis.horizontal),
              Expanded(
                child: ResponsiveButton(
                  text: 'Reset',
                  onPressed: () => _timerController.reset(),
                  baseHeight: 56,
                  backgroundColor: Colors.orange[600],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildManualTimeEntry() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        ResponsiveText(
          'Manual Time Entry (seconds)',
          baseFontSize: 16,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.blueGrey[700],
          ),
        ),
        ResponsiveSpacing(multiplier: 1),
        TextField(
          controller: _timeController,
          decoration: InputDecoration(
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            contentPadding: ResponsiveConfig.paddingSymmetric(context, horizontal: 12, vertical: 12),
            hintText: 'Enter time in seconds (e.g., 5.67)',
          ),
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
          ],
        ),
      ],
    );
  }

  Widget _buildNotesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        ResponsiveText(
          'Notes (Optional)',
          baseFontSize: 16,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.blueGrey[700],
          ),
        ),
        ResponsiveSpacing(multiplier: 1),
        TextField(
          controller: _notesController,
          decoration: InputDecoration(
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            contentPadding: ResponsiveConfig.paddingSymmetric(context, horizontal: 12, vertical: 12),
            hintText: 'Add notes about test performance...',
          ),
          maxLines: 3,
        ),
      ],
    );
  }

  Widget _buildDesktopActionSidebar(int totalTests) {
    return Column(
      children: [
        Container(
          padding: ResponsiveConfig.paddingAll(context, 20),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border(bottom: BorderSide(color: Colors.blue[200]!)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              ResponsiveText(
                'Test Actions',
                baseFontSize: 18,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.blueGrey[800],
                ),
              ),
              ResponsiveSpacing(multiplier: 2),
              
              SizedBox(
                width: double.infinity,
                child: ResponsiveButton(
                  text: 'Record Time',
                  onPressed: _isRecording ? null : _recordTest,
                  baseHeight: 56,
                  backgroundColor: Colors.cyanAccent[700],
                ),
              ),
              ResponsiveSpacing(multiplier: 1.5),
              SizedBox(
                width: double.infinity,
                child: ResponsiveButton(
                  text: 'Skip Test',
                  onPressed: _skipTest,
                  baseHeight: 48,
                  backgroundColor: Colors.orange[600],
                ),
              ),
            ],
          ),
        ),
        
        // Test navigation
        Container(
          padding: ResponsiveConfig.paddingAll(context, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              ResponsiveText(
                'Navigation',
                baseFontSize: 16,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.blueGrey[700],
                ),
              ),
              ResponsiveSpacing(multiplier: 1.5),
              
              if (_currentTest > 0 || _currentGroup > 0)
                SizedBox(
                  width: double.infinity,
                  child: ResponsiveButton(
                    text: 'Previous Test',
                    onPressed: _goToPreviousTest,
                    baseHeight: 40,
                    backgroundColor: Colors.grey[600],
                  ),
                ),
            ],
          ),
        ),
        
        Spacer(),
        
        // Session info
        Container(
          padding: ResponsiveConfig.paddingAll(context, 20),
          decoration: BoxDecoration(
            color: Colors.blue[100],
            border: Border(top: BorderSide(color: Colors.blue[300]!)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              ResponsiveText(
                'Session Info',
                baseFontSize: 14,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.blue[800],
                ),
              ),
              ResponsiveSpacing(multiplier: 1),
              ResponsiveText(
                'Tests: ${_sessionTestTimes.length}/$totalTests',
                baseFontSize: 12,
                style: TextStyle(color: Colors.blue[700]),
              ),
              ResponsiveText(
                'Session: ${_sessionId?.substring(_sessionId!.length - 6) ?? 'Unknown'}',
                baseFontSize: 12,
                style: TextStyle(color: Colors.blue[700]),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildRecordButton() {
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
        text: _isRecording ? 'Recording Test...' : 'Record Time',
        onPressed: _isRecording ? null : _recordTest,
        baseHeight: 56, // Enhanced for precision timing
        backgroundColor: _isRecording ? Colors.grey : Colors.cyanAccent[700],
        child: _isRecording
            ? Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: ResponsiveConfig.dimension(context, 20),
                    height: ResponsiveConfig.dimension(context, 20),
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  ),
                  ResponsiveSpacing(multiplier: 1.5, direction: Axis.horizontal),
                  ResponsiveText(
                    'Recording Test...',
                    baseFontSize: 16,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
              )
            : null,
      ),
    );
  }

  Widget _buildLoadingOverlay() {
    return Container(
      color: Colors.black.withOpacity(0.7),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(color: Colors.white),
            ResponsiveSpacing(multiplier: 2),
            ResponsiveText(
              'Adding Test to Session...',
              baseFontSize: 16,
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildBenchmarks() {
    final groups = widget.assessment['groups'] as List;
    final currentGroup = groups[_currentGroup] as Map<String, dynamic>;
    final tests = currentGroup['tests'] as List;
    final currentTestData = tests[_currentTest] as Map<String, dynamic>;
    
    var benchmarks = currentTestData['benchmarks'] as Map<String, dynamic>?;
    
    // Fallback benchmarks if none provided
    if (benchmarks == null || benchmarks.isEmpty) {
      final testId = currentTestData['id'] as String;
      final ageGroup = widget.assessment['ageGroup'] ?? widget.assessment['age_group'] ?? 'youth_15_18';
      benchmarks = _getFallbackBenchmarksForTest(testId, ageGroup);
    }
    
    if (benchmarks.isEmpty) {
      return _buildNoBenchmarksCard('Benchmarks will be applied during analysis');
    }
    
    return ResponsiveCard(
      padding: ResponsiveConfig.paddingAll(context, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Container(
                padding: ResponsiveConfig.paddingAll(context, 8),
                decoration: BoxDecoration(
                  color: Colors.blueGrey[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.speed,
                  color: Colors.blueGrey[700],
                  size: ResponsiveConfig.iconSize(context, 20),
                ),
              ),
              ResponsiveSpacing(multiplier: 1.5, direction: Axis.horizontal),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ResponsiveText(
                      'Performance Benchmarks',
                      baseFontSize: 16,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.blueGrey[800],
                      ),
                    ),
                    ResponsiveText(
                      'Target times for your age group',
                      baseFontSize: 12,
                      style: TextStyle(color: Colors.blueGrey[600]),
                    ),
                  ],
                ),
              ),
            ],
          ),
          ResponsiveSpacing(multiplier: 2),
          _buildBenchmarkRow(benchmarks),
        ],
      ),
    );
  }

  Widget _buildNoBenchmarksCard(String message) {
    return ResponsiveCard(
      padding: ResponsiveConfig.paddingAll(context, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Icon(Icons.info_outline, color: Colors.blue[700], size: ResponsiveConfig.iconSize(context, 20)),
              ResponsiveSpacing(multiplier: 1, direction: Axis.horizontal),
              ResponsiveText(
                'Performance Benchmarks',
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
              color: Colors.blue[50],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.blue[200]!),
            ),
            child: Row(
              children: [
                Icon(Icons.analytics, color: Colors.blue[700], size: ResponsiveConfig.iconSize(context, 16)),
                ResponsiveSpacing(multiplier: 1, direction: Axis.horizontal),
                Expanded(
                  child: ResponsiveText(
                    message,
                    baseFontSize: 14,
                    style: TextStyle(color: Colors.blue[700]),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBenchmarkRow(Map<String, dynamic> benchmarks) {
    final expectedLevels = ['Elite', 'Advanced', 'Developing', 'Beginner'];
    final orderedBenchmarks = <MapEntry<String, dynamic>>[];
    
    for (final level in expectedLevels) {
      final entry = benchmarks.entries.where((e) => e.key == level).firstOrNull;
      if (entry != null) {
        orderedBenchmarks.add(entry);
      }
    }
    
    if (orderedBenchmarks.isEmpty) {
      return Center(
        child: ResponsiveText(
          'No benchmark data available',
          baseFontSize: 14,
          style: TextStyle(color: Colors.grey),
        ),
      );
    }
    
    return AdaptiveLayout(
      builder: (deviceType, isLandscape) {
        if (deviceType == DeviceType.mobile) {
          return Wrap(
            spacing: ResponsiveConfig.spacing(context, 8),
            runSpacing: ResponsiveConfig.spacing(context, 8),
            children: orderedBenchmarks.map((entry) {
              final level = entry.key;
              final value = (entry.value as num).toDouble();
              final color = _getBenchmarkColor(level);
              
              return _buildBenchmarkItem(level, value, color);
            }).toList(),
          );
        } else {
          return Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: orderedBenchmarks.map((entry) {
              final level = entry.key;
              final value = (entry.value as num).toDouble();
              final color = _getBenchmarkColor(level);
              
              return Expanded(
                child: Padding(
                  padding: ResponsiveConfig.paddingSymmetric(context, horizontal: 4),
                  child: _buildBenchmarkItem(level, value, color),
                ),
              );
            }).toList(),
          );
        }
      },
    );
  }

  Widget _buildBenchmarkItem(String label, double value, Color color) {
    return Container(
      height: ResponsiveConfig.dimension(context, 70),
      padding: ResponsiveConfig.paddingSymmetric(context, horizontal: 8, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3), width: 1.5),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          ResponsiveText(
            '${value}s',
            baseFontSize: 16,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: color,
            ),
            textAlign: TextAlign.center,
          ),
          ResponsiveSpacing(multiplier: 0.5),
          ResponsiveText(
            label,
            baseFontSize: 11,
            style: TextStyle(
              color: color.withOpacity(0.8),
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Color _getBenchmarkColor(String level) {
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
        return Colors.blueGrey;
    }
  }

  Map<String, dynamic> _getFallbackBenchmarksForTest(String testId, String ageGroup) {
    const benchmarkData = {
      'youth_15_18': {
        'forward_speed_test': {'Elite': 4.2, 'Advanced': 4.5, 'Developing': 4.8, 'Beginner': 5.2},
        'backward_speed_test': {'Elite': 5.2, 'Advanced': 5.6, 'Developing': 6.0, 'Beginner': 6.5},
        'agility_test': {'Elite': 9.0, 'Advanced': 9.8, 'Developing': 10.6, 'Beginner': 11.8},
        'transitions_test': {'Elite': 4.2, 'Advanced': 4.6, 'Developing': 5.0, 'Beginner': 5.5},
        'crossovers_test': {'Elite': 7.8, 'Advanced': 8.5, 'Developing': 9.3, 'Beginner': 10.2},
        'stop_start_test': {'Elite': 2.3, 'Advanced': 2.5, 'Developing': 2.8, 'Beginner': 3.2},
      },
      'adult': {
        'forward_speed_test': {'Elite': 3.9, 'Advanced': 4.2, 'Developing': 4.5, 'Beginner': 4.9},
        'backward_speed_test': {'Elite': 4.8, 'Advanced': 5.2, 'Developing': 5.6, 'Beginner': 6.2},
        'agility_test': {'Elite': 8.3, 'Advanced': 9.0, 'Developing': 9.8, 'Beginner': 10.8},
        'transitions_test': {'Elite': 3.8, 'Advanced': 4.2, 'Developing': 4.6, 'Beginner': 5.2},
        'crossovers_test': {'Elite': 7.2, 'Advanced': 7.8, 'Developing': 8.5, 'Beginner': 9.4},
        'stop_start_test': {'Elite': 2.0, 'Advanced': 2.2, 'Developing': 2.5, 'Beginner': 2.9},
      },
    };
    
    return benchmarkData[ageGroup]?[testId] ?? {};
  }

  String _getTestDisplayName(String testId) {
    const testNames = {
      'forward_speed_test': 'Forward Speed',
      'backward_speed_test': 'Backward Speed',
      'agility_test': 'Agility',
      'transitions_test': 'Transitions',
      'crossovers_test': 'Crossovers',
      'stop_start_test': 'Stop & Start',
    };
    return testNames[testId] ?? testId.replaceAll('_', ' ').split(' ')
        .map((word) => word[0].toUpperCase() + word.substring(1)).join(' ');
  }
  
  // Session-based test recording
  Future<void> _recordTest() async {
    if (!await _validateInput()) return;

    setState(() => _isRecording = true);

    try {
      await _addTestToSession();
      await _updateUIAfterTest();
    } catch (e) {
      await _handleTestError(e);
    } finally {
      if (mounted) {
        setState(() => _isRecording = false);
      }
    }
  }

  Future<bool> _validateInput() async {
    if (_timeController.text.isEmpty) {
      await DialogService.showInformation(
        context,
        title: 'Missing Data',
        message: 'Please enter a time',
      );
      return false;
    }

    final time = double.tryParse(_timeController.text);
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

  Future<void> _addTestToSession() async {
    if (_sessionId == null) throw Exception('No session ID available');

    final time = double.parse(_timeController.text);
    final groups = widget.assessment['groups'] as List;
    final currentGroup = groups[_currentGroup] as Map<String, dynamic>;
    final tests = currentGroup['tests'] as List;
    final testId = (tests[_currentTest] as Map<String, dynamic>)['id'] as String;

    print('🚀 Adding test to session:');
    print('  Session ID: $_sessionId');
    print('  Test ID: $testId');
    print('  Time: ${time}s');

    // FIXED: Added required parameters to addTestToSession
    final sessionData = await _apiService.addTestToSession({
      'sessionId': _sessionId!,
      'testId': testId,
      'testType': 'skating_assessment',
      'playerId': widget.assessment['playerId'] ?? 0,
      'assessmentId': widget.assessment['assessmentId'] ?? _sessionId,
      'groupIndex': _currentGroup,
      'testIndex': _currentTest,
      'time': time,
      'notes': _notesController.text,
      'timestamp': DateTime.now().toIso8601String(),
      'status': 'completed',
      'category': currentGroup['name'] ?? 'skating',
      'testDetails': {
        'title': (tests[_currentTest] as Map<String, dynamic>)['title'] ?? 'Unknown Test',
        'description': (tests[_currentTest] as Map<String, dynamic>)['description'] ?? '',
        'category': (tests[_currentTest] as Map<String, dynamic>)['category'] ?? '',
      },
    });

    print('✅ Test added to session successfully');
    print('  Updated session status: ${sessionData['status']}');
    print('  Completed tests: ${sessionData['completed_tests']}');

    // Update local state
    _sessionTestTimes[testId] = time;
    
    // Update widget's test results for UI compatibility
    final result = {
      'testId': testId,
      'time': time,
      'timestamp': DateTime.now().toIso8601String(),
      'notes': _notesController.text,
      'assessmentId': _sessionId!,
    };
    
    widget.onAddResult(testId, result);

    // Check if session is complete
    _sessionComplete = sessionData['status'] == 'completed';
  }

  Future<void> _updateUIAfterTest() async {
    // Clear form
    setState(() {
      _timeController.clear();
      _notesController.clear();
      _timerController.reset();
    });

    // Show success feedback
    _showSuccessOverlay();

    // Brief pause
    await Future.delayed(const Duration(milliseconds: 1500));

    if (mounted) {
      _navigateToNextTest();
    }
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
          child: Container(
            padding: ResponsiveConfig.paddingSymmetric(context, horizontal: 24, vertical: 16),
            decoration: BoxDecoration(
              color: Colors.green[50],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.green, width: 2),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  spreadRadius: 1,
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.check_circle, color: Colors.green, size: ResponsiveConfig.iconSize(context, 28)),
                ResponsiveSpacing(multiplier: 1.5, direction: Axis.horizontal),
                ResponsiveText(
                  'Test Added to Session!',
                  baseFontSize: 16,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
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

  Future<void> _handleTestError(Object error) async {
    print('❌ Error recording test: $error');
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error recording test: $error'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }
  
  void _navigateToNextTest() {
    final groups = widget.assessment['groups'] as List;
    final currentGroup = groups[_currentGroup] as Map<String, dynamic>;
    final tests = currentGroup['tests'] as List;
    
    print('=== NAVIGATION ===');
    print('Current: Group $_currentGroup, Test $_currentTest');
    print('Session tests completed: ${_sessionTestTimes.length}');
    print('Session complete: $_sessionComplete');
    
    if (_currentTest < tests.length - 1) {
      // Move to next test in the same group
      setState(() {
        _currentTest++;
      });
      print('→ Moving to next test: $_currentTest');
    } else if (_currentGroup < groups.length - 1) {
      // Move to the first test of the next group
      setState(() {
        _currentGroup++;
        _currentTest = 0;
      });
      
      print('→ Moving to next group: $_currentGroup');
      
      DialogService.showInformation(
        context,
        title: 'Next Group',
        message: 'Moving to: ${(groups[_currentGroup] as Map<String, dynamic>)['name']}',
      );
    } else {
      // Assessment complete
      print('→ Session Complete!');
      _handleSessionCompleted();
    }
    print('=================');
  }

  void _skipTest() {
    DialogService.showConfirmation(
      context,
      title: 'Skip Test?',
      message: 'Are you sure you want to skip this test? You can come back to it later.',
      confirmLabel: 'Skip',
      cancelLabel: 'Cancel',
    ).then((confirmed) {
      if (confirmed == true) {
        _navigateToNextTest();
      }
    });
  }

  void _goToPreviousTest() {
    if (_currentTest > 0) {
      setState(() {
        _currentTest--;
      });
    } else if (_currentGroup > 0) {
      setState(() {
        _currentGroup--;
        final previousGroup = widget.assessment['groups'][_currentGroup] as Map<String, dynamic>;
        final previousTests = previousGroup['tests'] as List;
        _currentTest = previousTests.length - 1;
      });
    }
  }

  Future<void> _handleSessionCompleted() async {
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
              'Session Completed!',
              baseFontSize: 20,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.blueGrey[800],
              ),
            ),
            ResponsiveSpacing(multiplier: 1),
            ResponsiveText(
              'Session ID: ${_sessionId?.substring(_sessionId!.length - 6) ?? 'Unknown'}\n\nAll ${_sessionTestTimes.length} skating tests completed successfully.\n\nResults have been saved to your session.',
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

    // Clear session from AppState after completion
    if (mounted) {
      final appState = Provider.of<AppState>(context, listen: false);
      appState.clearCurrentSkatingAssessmentId();
      
      // Trigger completion callback
      widget.onComplete();
    }
  }
}