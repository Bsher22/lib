// lib/widgets/core/timer/unified_timer_controller.dart
import 'dart:async';
import 'package:flutter/foundation.dart';

/// A unified controller for timer functionality across the app
class UnifiedTimerController extends ChangeNotifier {
  // Timer state
  bool _isRunning = false;
  bool _wasUsed = false;
  final Stopwatch _stopwatch = Stopwatch();
  final List<VoidCallback> _listeners = [];

  // Text controller value
  String _textValue = '';

  // Configuration
  final int _updateInterval; // in milliseconds
  final bool _countDown;
  final Duration _countDownDuration;

  // Timer
  Timer? _timer;

  // Getters
  bool get isRunning => _isRunning;
  bool get isUsed => _wasUsed;
  Duration get elapsed => _stopwatch.elapsed;
  double get elapsedSeconds => _stopwatch.elapsedMilliseconds / 1000.0;

  // Get text value for compatibility with TextEditingController pattern
  String get text => _textValue;

  // Set text value for compatibility with TextEditingController pattern
  set text(String value) {
    _textValue = value;
    notifyListeners();
  }

  // For countdown timer
  Duration get remaining => _countDown
      ? _countDownDuration - _stopwatch.elapsed
      : Duration.zero;
  double get remainingSeconds => _countDown
      ? ((_countDownDuration.inMilliseconds - _stopwatch.elapsedMilliseconds) / 1000.0).clamp(0.0, double.infinity)
      : 0.0;
  bool get isComplete => _countDown && _stopwatch.elapsed >= _countDownDuration;

  /// Creates a unified timer controller
  ///
  /// [updateInterval] - How frequently to update listeners (in milliseconds)
  /// [countDown] - Whether this is a countdown timer
  /// [countDownDuration] - Duration for countdown (only used if countDown is true)
  UnifiedTimerController({
    int updateInterval = 10,
    bool countDown = false,
    Duration countDownDuration = const Duration(minutes: 1),
  })  : _updateInterval = updateInterval,
        _countDown = countDown,
        _countDownDuration = countDownDuration;

  /// Starts the timer
  void start() {
    if (!_isRunning) {
      _isRunning = true;
      _wasUsed = true;
      _stopwatch.start();
      _startTimer();
      _notifyListeners();
    }
  }

  /// Stops the timer
  void stop() {
    if (_isRunning) {
      _isRunning = false;
      _stopwatch.stop();
      _stopTimer();

      // Update text value with current elapsed time
      _textValue = elapsedSeconds.toStringAsFixed(2);

      _notifyListeners();
    }
  }

  /// Resets the timer to zero
  void reset() {
    _isRunning = false;
    _wasUsed = false;
    _stopwatch.reset();
    _stopTimer();

    // Clear text value
    _textValue = '';

    _notifyListeners();
  }

  /// Sets the timer to a specific value (useful for manual time entry)
  void setTime(Duration time) {
    _stopwatch.reset();
    _stopwatch.stop();

    // Add the time
    if (time.inMilliseconds > 0) {
      _stopwatch.start();
      // Small delay to ensure proper elapsed time
      Future.delayed(time, () {
        _stopwatch.stop();
        _wasUsed = true;

        // Update text value
        _textValue = elapsedSeconds.toStringAsFixed(2);

        _notifyListeners();
      });
    } else {
      _textValue = '0.00';
      _notifyListeners();
    }
  }

  /// Add a listener to receive timer updates
  void addListener(VoidCallback listener) {
    _listeners.add(listener);
  }

  /// Remove a listener
  void removeListener(VoidCallback listener) {
    _listeners.remove(listener);
  }

  /// Notify all listeners of a state change
  void _notifyListeners() {
    for (var listener in _listeners) {
      listener();
    }
    notifyListeners();
  }

  /// Start the internal timer for updates
  void _startTimer() {
    _timer = Timer.periodic(Duration(milliseconds: _updateInterval), (_) {
      _notifyListeners();

      // Auto-stop for countdown timer
      if (_countDown && isComplete && _isRunning) {
        stop();
      }
    });
  }

  /// Stop the internal timer
  void _stopTimer() {
    _timer?.cancel();
    _timer = null;
  }

  /// Clean up resources
  @override
  void dispose() {
    _stopTimer();
    _listeners.clear();
    super.dispose();
  }
}