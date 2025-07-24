// widgets/assessment/shot/quick_release_timer.dart
import 'package:flutter/material.dart';
import 'dart:async';

class StopwatchController {
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

class QuickReleaseTimer extends StatefulWidget {
  final StopwatchController controller;
  
  const QuickReleaseTimer({
    Key? key,
    required this.controller,
  }) : super(key: key);

  @override
  _QuickReleaseTimerState createState() => _QuickReleaseTimerState();
}

class _QuickReleaseTimerState extends State<QuickReleaseTimer> {
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
    final minutesDisplay = (seconds / 60).floor().toString().padLeft(2, '0');
    final secondsDisplay = (seconds % 60).toString().padLeft(2, '0');
    final millisecondsDisplay = ((milliseconds % 1000) ~/ 10).toString().padLeft(2, '0');
    
    return "$minutesDisplay:$secondsDisplay.$millisecondsDisplay";
  }
  
  @override
  Widget build(BuildContext context) {
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
                widget.controller.isRunning
                    ? _formatTime(widget.controller.elapsed)
                    : widget.controller.elapsed.inMilliseconds > 0
                        ? _formatTime(widget.controller.elapsed)
                        : '00:00.00',
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
            } else {
              widget.controller.reset();
              widget.controller.start();
            }
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: widget.controller.isRunning
                ? Colors.red
                : Colors.green,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            minimumSize: const Size(48, 48),
          ),
          child: Icon(
            widget.controller.isRunning ? Icons.stop : Icons.play_arrow,
            color: Colors.white,
          ),
        ),
      ],
    );
  }
}