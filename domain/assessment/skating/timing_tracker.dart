// widgets/assessment/skating/timing_tracker.dart
// PHASE 3 UPDATE: Full Responsive Design Implementation

import 'package:flutter/material.dart';
import 'dart:async';
import 'package:hockey_shot_tracker/responsive_system/index.dart';

class TimingTrackerController {
  bool _isRunning = false;
  bool _wasUsed = false;
  final Stopwatch _stopwatch = Stopwatch();
  final List<VoidCallback> _listeners = [];
  
  Timer? _timer;
  
  bool get isRunning => _isRunning;
  bool get isUsed => _wasUsed;
  Duration get elapsed => _stopwatch.elapsed;
  double get elapsedSeconds => _stopwatch.elapsedMilliseconds / 1000.0;
  
  void start() {
    if (!_isRunning) {
      _isRunning = true;
      _wasUsed = true;
      _stopwatch.start();
      _startTimer();
      _notifyListeners();
    }
  }
  
  void stop() {
    if (_isRunning) {
      _isRunning = false;
      _stopwatch.stop();
      _stopTimer();
      _notifyListeners();
    }
  }
  
  void reset() {
    _isRunning = false;
    _wasUsed = false;
    _stopwatch.reset();
    _stopTimer();
    _notifyListeners();
  }
  
  void addListener(VoidCallback listener) {
    _listeners.add(listener);
  }
  
  void removeListener(VoidCallback listener) {
    _listeners.remove(listener);
  }
  
  void _notifyListeners() {
    for (var listener in _listeners) {
      listener();
    }
  }
  
  void _startTimer() {
    _timer = Timer.periodic(const Duration(milliseconds: 10), (_) {
      _notifyListeners();
    });
  }
  
  void _stopTimer() {
    _timer?.cancel();
    _timer = null;
  }
  
  void dispose() {
    _stopTimer();
    _listeners.clear();
  }
}

class TimingTracker extends StatefulWidget {
  final TimingTrackerController controller;
  final Function(double)? onTimeRecorded;
  
  const TimingTracker({
    Key? key,
    required this.controller,
    this.onTimeRecorded,
  }) : super(key: key);

  @override
  _TimingTrackerState createState() => _TimingTrackerState();
}

class _TimingTrackerState extends State<TimingTracker> {
  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_handleControllerUpdate);
  }
  
  @override
  void dispose() {
    widget.controller.removeListener(_handleControllerUpdate);
    super.dispose();
  }
  
  void _handleControllerUpdate() {
    setState(() {});
  }
  
  String _formatTime(Duration duration) {
    final milliseconds = duration.inMilliseconds;
    final seconds = (milliseconds / 1000).floor();
    final minutes = (seconds / 60).floor();

    final secondsDisplay = (seconds % 60).toString().padLeft(2, '0');
    final minutesDisplay = minutes.toString().padLeft(2, '0');
    final millisecondsDisplay = ((milliseconds % 1000) ~/ 10).toString().padLeft(2, '0');

    return "$minutesDisplay:$secondsDisplay.$millisecondsDisplay";
  }
  
  @override
  Widget build(BuildContext context) {
    return ResponsiveWrapper(
      child: AdaptiveLayout(
        builder: (deviceType, isLandscape) {
          switch (deviceType) {
            case DeviceType.mobile:
              return _buildMobileLayout(context);
            case DeviceType.tablet:
              return _buildTabletLayout(context);
            case DeviceType.desktop:
              return _buildDesktopLayout(context);
          }
        },
      ),
    );
  }

  // ✅ MOBILE LAYOUT: Compact vertical layout
  Widget _buildMobileLayout(BuildContext context) {
    return Column(
      children: [
        // Timer display
        _buildTimerDisplay(
          context,
          height: ResponsiveSystem.getDeviceType(context) == DeviceType.mobile ? 120 : 140,
          fontSize: ResponsiveSystem.getDeviceType(context) == DeviceType.mobile ? 36 : 42,
        ),
        
        SizedBox(height: ResponsiveConfig.spacing(context, 16)),
        
        // Compact button layout
        _buildMobileControls(context),
      ],
    );
  }

  // ✅ TABLET LAYOUT: Balanced layout with larger display
  Widget _buildTabletLayout(BuildContext context) {
    return Column(
      children: [
        // Enhanced timer display
        _buildTimerDisplay(
          context,
          height: 140,
          fontSize: 42,
        ),
        
        SizedBox(height: ResponsiveConfig.spacing(context, 16)),
        
        // Enhanced controls
        _buildTabletControls(context),
      ],
    );
  }

  // ✅ DESKTOP LAYOUT: Professional layout with status indicators
  Widget _buildDesktopLayout(BuildContext context) {
    return Column(
      children: [
        // Professional timer display with status
        _buildEnhancedTimerDisplay(context),
        
        SizedBox(height: ResponsiveConfig.spacing(context, 24)),
        
        // Professional controls with shortcuts
        _buildDesktopControls(context),
        
        SizedBox(height: ResponsiveConfig.spacing(context, 16)),
        
        // Additional features for desktop
        _buildDesktopExtras(context),
      ],
    );
  }

  Widget _buildTimerDisplay(BuildContext context, {required double height, required double fontSize}) {
    final deviceType = ResponsiveSystem.getDeviceType(context);
    
    return Container(
      width: double.infinity,
      height: height,
      padding: ResponsiveConfig.paddingAll(context, 16),
      decoration: BoxDecoration(
        color: widget.controller.isRunning ? Colors.green[50] : Colors.grey[100],
        borderRadius: ResponsiveConfig.borderRadius(context, 12),
        border: Border.all(
          color: widget.controller.isRunning ? Colors.green[300]! : Colors.grey[300]!,
          width: 2,
        ),
        boxShadow: widget.controller.isRunning ? [
          BoxShadow(
            color: Colors.green.withOpacity(0.2),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ] : null,
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ResponsiveText(
              widget.controller.isRunning
                  ? _formatTime(widget.controller.elapsed)
                  : widget.controller.elapsed.inMilliseconds > 0
                      ? _formatTime(widget.controller.elapsed)
                      : '00:00.00',
              baseFontSize: fontSize,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontFamily: 'monospace',
                color: widget.controller.isRunning ? Colors.green[800] : Colors.blueGrey[800],
              ),
            ),
            if (deviceType == DeviceType.tablet || deviceType == DeviceType.desktop) ...[
              SizedBox(height: ResponsiveConfig.spacing(context, 8)),
              ResponsiveText(
                widget.controller.isRunning ? 'Recording...' : 
                widget.controller.elapsed.inMilliseconds > 0 ? 'Stopped' : 'Ready',
                baseFontSize: 14,
                style: TextStyle(
                  color: widget.controller.isRunning ? Colors.green[700] : Colors.blueGrey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildEnhancedTimerDisplay(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: ResponsiveConfig.paddingAll(context, 24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: widget.controller.isRunning
              ? [Colors.green[50]!, Colors.green[100]!]
              : [Colors.grey[50]!, Colors.grey[100]!],
        ),
        borderRadius: ResponsiveConfig.borderRadius(context, 16),
        border: Border.all(
          color: widget.controller.isRunning ? Colors.green[300]! : Colors.grey[300]!,
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: widget.controller.isRunning 
                ? Colors.green.withOpacity(0.2)
                : Colors.black.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Status indicator
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: ResponsiveConfig.dimension(context, 12),
                height: ResponsiveConfig.dimension(context, 12),
                decoration: BoxDecoration(
                  color: widget.controller.isRunning ? Colors.green : 
                          widget.controller.elapsed.inMilliseconds > 0 ? Colors.orange : Colors.grey,
                  borderRadius: ResponsiveConfig.borderRadius(context, 6),
                ),
              ),
              SizedBox(width: ResponsiveConfig.spacing(context, 8)),
              ResponsiveText(
                widget.controller.isRunning ? 'RECORDING' : 
                widget.controller.elapsed.inMilliseconds > 0 ? 'STOPPED' : 'READY',
                baseFontSize: 12,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: widget.controller.isRunning ? Colors.green[700] : 
                         widget.controller.elapsed.inMilliseconds > 0 ? Colors.orange[700] : Colors.grey[700],
                  letterSpacing: 1.2,
                ),
              ),
            ],
          ),
          
          SizedBox(height: ResponsiveConfig.spacing(context, 16)),
          
          // Main timer display
          ResponsiveText(
            widget.controller.isRunning
                ? _formatTime(widget.controller.elapsed)
                : widget.controller.elapsed.inMilliseconds > 0
                    ? _formatTime(widget.controller.elapsed)
                    : '00:00.00',
            baseFontSize: 56,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontFamily: 'monospace',
              color: widget.controller.isRunning ? Colors.green[800] : Colors.blueGrey[800],
            ),
          ),
          
          SizedBox(height: ResponsiveConfig.spacing(context, 8)),
          
          // Time format indicator
          ResponsiveText(
            'MM:SS.MS',
            baseFontSize: 12,
            style: TextStyle(
              color: Colors.blueGrey[500],
              fontWeight: FontWeight.w500,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMobileControls(BuildContext context) {
    return Row(
      children: [
        // Start/Stop button
        Expanded(
          child: ResponsiveButton(
            text: widget.controller.isRunning ? 'Stop' : 'Start',
            baseHeight: 48,
            backgroundColor: widget.controller.isRunning ? Colors.red : Colors.green,
            foregroundColor: Colors.white,
            onPressed: () {
              if (widget.controller.isRunning) {
                widget.controller.stop();
                
                if (widget.onTimeRecorded != null) {
                  widget.onTimeRecorded!(widget.controller.elapsedSeconds);
                }
              } else {
                widget.controller.reset();
                widget.controller.start();
              }
            },
          ),
        ),
        
        SizedBox(width: ResponsiveConfig.spacing(context, 16)),
        
        // Reset button
        ResponsiveButton(
          text: 'Reset',
          baseHeight: 48,
          backgroundColor: Colors.blueGrey,
          foregroundColor: Colors.white,
          onPressed: widget.controller.isRunning ? null : () => widget.controller.reset(),
        ),
      ],
    );
  }

  Widget _buildTabletControls(BuildContext context) {
    return Row(
      children: [
        // Start/Stop button
        Expanded(
          flex: 3,
          child: ElevatedButton.icon(
            onPressed: () {
              if (widget.controller.isRunning) {
                widget.controller.stop();
                
                if (widget.onTimeRecorded != null) {
                  widget.onTimeRecorded!(widget.controller.elapsedSeconds);
                }
              } else {
                widget.controller.reset();
                widget.controller.start();
              }
            },
            icon: Icon(widget.controller.isRunning ? Icons.stop : Icons.play_arrow),
            label: ResponsiveText(
              widget.controller.isRunning ? 'Stop Timer' : 'Start Timer',
              baseFontSize: 16,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: widget.controller.isRunning ? Colors.red[600] : Colors.green[600],
              foregroundColor: Colors.white,
              padding: ResponsiveConfig.paddingSymmetric(context, vertical: 16, horizontal: 24),
              shape: RoundedRectangleBorder(
                borderRadius: ResponsiveConfig.borderRadius(context, 12),
              ),
            ),
          ),
        ),
        
        SizedBox(width: ResponsiveConfig.spacing(context, 16)),
        
        // Reset button
        Expanded(
          flex: 1,
          child: ElevatedButton.icon(
            onPressed: widget.controller.isRunning 
                ? null 
                : () => widget.controller.reset(),
            icon: const Icon(Icons.refresh),
            label: ResponsiveText(
              'Reset',
              baseFontSize: 14,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blueGrey[600],
              foregroundColor: Colors.white,
              padding: ResponsiveConfig.paddingSymmetric(context, vertical: 16, horizontal: 16),
              shape: RoundedRectangleBorder(
                borderRadius: ResponsiveConfig.borderRadius(context, 12),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDesktopControls(BuildContext context) {
    return Row(
      children: [
        // Start/Stop button with enhanced styling
        Expanded(
          flex: 2,
          child: Container(
            height: ResponsiveConfig.dimension(context, 60),
            child: ElevatedButton.icon(
              onPressed: () {
                if (widget.controller.isRunning) {
                  widget.controller.stop();
                  
                  if (widget.onTimeRecorded != null) {
                    widget.onTimeRecorded!(widget.controller.elapsedSeconds);
                  }
                } else {
                  widget.controller.reset();
                  widget.controller.start();
                }
              },
              icon: Icon(
                widget.controller.isRunning ? Icons.stop : Icons.play_arrow,
                size: ResponsiveConfig.iconSize(context, 24),
              ),
              label: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ResponsiveText(
                    widget.controller.isRunning ? 'Stop Timer' : 'Start Timer',
                    baseFontSize: 16,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  ResponsiveText(
                    widget.controller.isRunning ? 'Space or Click' : 'Space or Click',
                    baseFontSize: 10,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.8),
                    ),
                  ),
                ],
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: widget.controller.isRunning ? Colors.red[600] : Colors.green[600],
                foregroundColor: Colors.white,
                padding: ResponsiveConfig.paddingSymmetric(context, horizontal: 32),
                shape: RoundedRectangleBorder(
                  borderRadius: ResponsiveConfig.borderRadius(context, 12),
                ),
                elevation: 4,
              ),
            ),
          ),
        ),
        
        SizedBox(width: ResponsiveConfig.spacing(context, 16)),
        
        // Reset button
        Expanded(
          flex: 1,
          child: Container(
            height: ResponsiveConfig.dimension(context, 60),
            child: ElevatedButton.icon(
              onPressed: widget.controller.isRunning 
                  ? null 
                  : () => widget.controller.reset(),
              icon: Icon(Icons.refresh, size: ResponsiveConfig.iconSize(context, 20)),
              label: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ResponsiveText(
                    'Reset',
                    baseFontSize: 14,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  ResponsiveText(
                    'R Key',
                    baseFontSize: 10,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.8),
                    ),
                  ),
                ],
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blueGrey[600],
                foregroundColor: Colors.white,
                padding: ResponsiveConfig.paddingSymmetric(context, horizontal: 24),
                shape: RoundedRectangleBorder(
                  borderRadius: ResponsiveConfig.borderRadius(context, 12),
                ),
                elevation: 2,
              ),
            ),
          ),
        ),
        
        SizedBox(width: ResponsiveConfig.spacing(context, 16)),
        
        // Quick actions
        Expanded(
          flex: 1,
          child: Container(
            height: ResponsiveConfig.dimension(context, 60),
            child: ElevatedButton.icon(
              onPressed: widget.controller.elapsed.inMilliseconds > 0
                  ? () {
                      if (widget.onTimeRecorded != null) {
                        widget.onTimeRecorded!(widget.controller.elapsedSeconds);
                      }
                    }
                  : null,
              icon: Icon(Icons.save, size: ResponsiveConfig.iconSize(context, 20)),
              label: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ResponsiveText(
                    'Record',
                    baseFontSize: 14,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  ResponsiveText(
                    'Enter',
                    baseFontSize: 10,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.8),
                    ),
                  ),
                ],
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue[600],
                foregroundColor: Colors.white,
                padding: ResponsiveConfig.paddingSymmetric(context, horizontal: 24),
                shape: RoundedRectangleBorder(
                  borderRadius: ResponsiveConfig.borderRadius(context, 12),
                ),
                elevation: 2,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDesktopExtras(BuildContext context) {
    return Row(
      children: [
        // Performance metrics
        Expanded(
          child: ResponsiveCard(
            padding: ResponsiveConfig.paddingAll(context, 16),
            backgroundColor: Colors.blue[50],
            child: Column(
              children: [
                ResponsiveText(
                  'Timer Precision',
                  baseFontSize: 12,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.blue[800],
                  ),
                ),
                SizedBox(height: ResponsiveConfig.spacing(context, 4)),
                ResponsiveText(
                  '±0.01 seconds',
                  baseFontSize: 11,
                  style: TextStyle(
                    color: Colors.blue[700],
                  ),
                ),
              ],
            ),
          ),
        ),
        
        SizedBox(width: ResponsiveConfig.spacing(context, 16)),
        
        // Session info
        Expanded(
          child: ResponsiveCard(
            padding: ResponsiveConfig.paddingAll(context, 16),
            backgroundColor: Colors.green[50],
            child: Column(
              children: [
                ResponsiveText(
                  'Times Recorded',
                  baseFontSize: 12,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.green[800],
                  ),
                ),
                SizedBox(height: ResponsiveConfig.spacing(context, 4)),
                ResponsiveText(
                  widget.controller.isUsed ? '1' : '0',
                  baseFontSize: 11,
                  style: TextStyle(
                    color: Colors.green[700],
                  ),
                ),
              ],
            ),
          ),
        ),
        
        SizedBox(width: ResponsiveConfig.spacing(context, 16)),
        
        // Best practice tip
        Expanded(
          flex: 2,
          child: ResponsiveCard(
            padding: ResponsiveConfig.paddingAll(context, 16),
            backgroundColor: Colors.amber[50],
            child: Row(
              children: [
                Icon(
                  Icons.lightbulb,
                  color: Colors.amber[700],
                  size: ResponsiveConfig.iconSize(context, 16),
                ),
                SizedBox(width: ResponsiveConfig.spacing(context, 8)),
                Expanded(
                  child: ResponsiveText(
                    'Start timing when player begins movement',
                    baseFontSize: 11,
                    style: TextStyle(
                      color: Colors.amber[800],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}