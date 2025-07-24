// Create a new file: lib/utils/performance_monitor.dart
class PerformanceMonitor {
  static final Map<String, Stopwatch> _activeWatches = {};
  
  static void startTracking(String operationName) {
    _activeWatches[operationName] = Stopwatch()..start();
  }
  
  static void stopTracking(String operationName) {
    if (_activeWatches.containsKey(operationName)) {
      _activeWatches[operationName]!.stop();
      final duration = _activeWatches[operationName]!.elapsedMilliseconds;
      if (duration > 100) {
      }
      _activeWatches.remove(operationName);
    }
  }
  
  static Future<T> trackAsync<T>(String operationName, Future<T> Function() operation) async {
    startTracking(operationName);
    try {
      return await operation();
    } finally {
      stopTracking(operationName);
    }
  }
}