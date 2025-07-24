// lib/widgets/core/timer/time_formatter.dart

/// Utility class for formatting time in various ways
class TimeFormatter {
  /// Format as MM:SS.cc (minutes, seconds, centiseconds)
  static String formatMMSScc(Duration duration) {
    final milliseconds = duration.inMilliseconds;
    final seconds = (milliseconds / 1000).floor();
    final minutes = (seconds / 60).floor();
    
    final minutesDisplay = minutes.toString().padLeft(2, '0');
    final secondsDisplay = (seconds % 60).toString().padLeft(2, '0');
    final centisecondsDisplay = ((milliseconds % 1000) ~/ 10).toString().padLeft(2, '0');
    
    return "$minutesDisplay:$secondsDisplay.$centisecondsDisplay";
  }
  
  /// Format as MM:SS (minutes, seconds)
  static String formatMMSS(Duration duration) {
    final seconds = duration.inSeconds;
    final minutes = (seconds / 60).floor();
    
    final minutesDisplay = minutes.toString().padLeft(2, '0');
    final secondsDisplay = (seconds % 60).toString().padLeft(2, '0');
    
    return "$minutesDisplay:$secondsDisplay";
  }
  
  /// Format as SS.d (seconds with one decimal)
  static String formatSSd(Duration duration) {
    final seconds = duration.inMilliseconds / 1000;
    return seconds.toStringAsFixed(1);
  }
  
  /// Format as human-readable time (e.g., "2m 35s")
  static String formatHumanReadable(Duration duration) {
    final seconds = duration.inSeconds;
    final minutes = (seconds / 60).floor();
    
    if (minutes > 0) {
      final remainingSeconds = seconds % 60;
      return "${minutes}m ${remainingSeconds}s";
    } else {
      return "${seconds}s";
    }
  }
}