// lib/widgets/core/timer/unified_timer.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hockey_shot_tracker/widgets/core/timer/unified_timer_controller.dart';
import 'package:hockey_shot_tracker/widgets/core/timer/time_formatter.dart';

/// Display style for the unified timer
enum TimerDisplayStyle {
  /// Compact display (small, minimal controls)
  compact,
  
  /// Standard display (medium size with basic controls)
  standard,
  
  /// Expanded display (large with full controls)
  expanded,
}

/// A unified timer widget that can be configured for different use cases
class UnifiedTimer extends StatefulWidget {
  /// Controller for the timer
  final UnifiedTimerController controller;
  
  /// Display style for the timer
  final TimerDisplayStyle displayStyle;
  
  /// Primary color for the timer
  final Color primaryColor;
  
  /// Show manual time entry field
  final bool allowManualEntry;
  
  /// Callback when time is recorded
  final Function(double)? onTimeRecorded;
  
  /// Custom format function for the timer display
  final String Function(Duration)? formatTime;

  const UnifiedTimer({
    Key? key,
    required this.controller,
    this.displayStyle = TimerDisplayStyle.standard,
    this.primaryColor = Colors.cyanAccent,
    this.allowManualEntry = false,
    this.onTimeRecorded,
    this.formatTime,
  }) : super(key: key);

  @override
  State<UnifiedTimer> createState() => _UnifiedTimerState();
}

class _UnifiedTimerState extends State<UnifiedTimer> {
  final TextEditingController _manualTimeController = TextEditingController();
  
  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_handleControllerUpdate);
  }
  
  @override
  void dispose() {
    widget.controller.removeListener(_handleControllerUpdate);
    _manualTimeController.dispose();
    super.dispose();
  }
  
  void _handleControllerUpdate() {
    if (mounted) {
      setState(() {});
    }
  }
  
  String _getFormattedTime() {
    final duration = widget.controller.elapsed;
    
    // Use custom format if provided
    if (widget.formatTime != null) {
      return widget.formatTime!(duration);
    }
    
    // Default format based on style
    switch (widget.displayStyle) {
      case TimerDisplayStyle.compact:
        return TimeFormatter.formatSSd(duration);
      case TimerDisplayStyle.standard:
        return TimeFormatter.formatMMSScc(duration);
      case TimerDisplayStyle.expanded:
        return TimeFormatter.formatMMSScc(duration);
      default:
        return TimeFormatter.formatMMSScc(duration);
    }
  }
  
  Widget _buildCompactTimer() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey[300]!),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(
            _getFormattedTime(),
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              fontFamily: 'monospace',
            ),
          ),
        ),
        const SizedBox(width: 8),
        IconButton(
          onPressed: () {
            if (widget.controller.isRunning) {
              widget.controller.stop();
              
              // Notify time recording if callback provided
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
            color: widget.controller.isRunning ? Colors.red : widget.primaryColor,
          ),
          iconSize: 20,
          padding: const EdgeInsets.all(4),
          constraints: const BoxConstraints(),
        ),
      ],
    );
  }
  
  Widget _buildStandardTimer() {
    return Row(
      children: [
        Expanded(
          child: Container(
            height: 48,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey[300]!),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Center(
              child: Text(
                _getFormattedTime(),
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'monospace',
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        ElevatedButton(
          onPressed: () {
            if (widget.controller.isRunning) {
              widget.controller.stop();
              
              // Notify time recording if callback provided
              if (widget.onTimeRecorded != null) {
                widget.onTimeRecorded!(widget.controller.elapsedSeconds);
              }
            } else {
              widget.controller.reset();
              widget.controller.start();
            }
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: widget.controller.isRunning ? Colors.red : widget.primaryColor,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            minimumSize: const Size(48, 48),
          ),
          child: Icon(
            widget.controller.isRunning ? Icons.stop : Icons.play_arrow,
          ),
        ),
      ],
    );
  }
  
  Widget _buildExpandedTimer() {
    return Column(
      children: [
        // Timer display
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey[300]!),
          ),
          child: Center(
            child: Text(
              _getFormattedTime(),
              style: const TextStyle(
                fontSize: 48,
                fontWeight: FontWeight.bold,
                fontFamily: 'monospace',
              ),
            ),
          ),
        ),
        
        const SizedBox(height: 16),
        
        // Timer controls
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Start/Stop button
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () {
                  if (widget.controller.isRunning) {
                    widget.controller.stop();
                    
                    // Notify time recording if callback provided
                    if (widget.onTimeRecorded != null) {
                      widget.onTimeRecorded!(widget.controller.elapsedSeconds);
                    }
                  } else {
                    widget.controller.reset();
                    widget.controller.start();
                  }
                },
                icon: Icon(widget.controller.isRunning ? Icons.stop : Icons.play_arrow),
                label: Text(widget.controller.isRunning ? 'Stop' : 'Start'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: widget.controller.isRunning ? Colors.red : widget.primaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),
            
            const SizedBox(width: 16),
            
            // Reset button
            ElevatedButton.icon(
              onPressed: widget.controller.isRunning 
                  ? null 
                  : () => widget.controller.reset(),
              icon: const Icon(Icons.refresh),
              label: const Text('Reset'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blueGrey,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
          ],
        ),
        
        // Manual time entry
        if (widget.allowManualEntry) ...[
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _manualTimeController,
                  decoration: const InputDecoration(
                    labelText: 'Manual Time (seconds)',
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                    hintText: 'Enter time in seconds (e.g., 5.67)',
                  ),
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: () {
                  final timeText = _manualTimeController.text;
                  if (timeText.isNotEmpty) {
                    final seconds = double.tryParse(timeText);
                    if (seconds != null) {
                      final duration = Duration(milliseconds: (seconds * 1000).round());
                      widget.controller.setTime(duration);
                      
                      // Notify time recording if callback provided
                      if (widget.onTimeRecorded != null) {
                        widget.onTimeRecorded!(seconds);
                      }
                    }
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: widget.primaryColor,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Set'),
              ),
            ],
          ),
        ],
      ],
    );
  }
  
  @override
  Widget build(BuildContext context) {
    switch (widget.displayStyle) {
      case TimerDisplayStyle.compact:
        return _buildCompactTimer();
      case TimerDisplayStyle.standard:
        return _buildStandardTimer();
      case TimerDisplayStyle.expanded:
        return _buildExpandedTimer();
      default:
        return _buildStandardTimer();
    }
  }
}