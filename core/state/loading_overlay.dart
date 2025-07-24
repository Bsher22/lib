// lib/widgets/common/state/loading_overlay.dart
import 'package:flutter/material.dart';

/// A reusable loading overlay widget that shows a centered loading indicator
/// with optional message and customizable appearance.
class LoadingOverlay extends StatelessWidget {
  /// Whether the loading overlay is visible
  final bool isLoading;
  
  /// Optional message to display below the loading indicator
  final String? message;
  
  /// The widget to display when not loading
  final Widget child;
  
  /// Color of the loading indicator
  final Color? color;
  
  /// Color of the overlay background
  final Color? backgroundColor;
  
  /// Whether to show the loading indicator on the whole screen or just as a widget
  final bool fullScreen;
  
  /// Size of the loading indicator
  final double size;
  
  /// Text style for the message
  final TextStyle? textStyle;

  const LoadingOverlay({
    Key? key,
    required this.isLoading,
    required this.child,
    this.message,
    this.color,
    this.backgroundColor,
    this.fullScreen = false,
    this.size = 36.0,
    this.textStyle,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // If not loading, just show the child
    if (!isLoading) {
      return child;
    }

    // Create loading indicator
    final loadingIndicator = Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: size,
          height: size,
          child: CircularProgressIndicator(
            color: color ?? Colors.cyanAccent,
            strokeWidth: size / 10,
          ),
        ),
        if (message != null) ...[
          const SizedBox(height: 16),
          Text(
            message!,
            style: textStyle ?? 
              TextStyle(
                fontSize: 16,
                color: Colors.white,
                fontWeight: FontWeight.w500,
              ),
            textAlign: TextAlign.center,
          ),
        ],
      ],
    );

    // For full screen loading
    if (fullScreen) {
      return Stack(
        children: [
          // The main content behind the overlay
          child,
          
          // The overlay
          Positioned.fill(
            child: Container(
              color: backgroundColor ?? Colors.black.withOpacity(0.5),
              child: Center(
                child: loadingIndicator,
              ),
            ),
          ),
        ],
      );
    } 
    // For inline loading (replacing the child)
    else {
      return Container(
        padding: const EdgeInsets.all(16),
        color: backgroundColor,
        child: Center(
          child: loadingIndicator,
        ),
      );
    }
  }
  
  /// Create a simple loading indicator without a child widget
  /// Useful for initial loading states
  static Widget simple({
    String? message,
    Color? color,
    Color? backgroundColor,
    double size = 36.0,
    TextStyle? textStyle,
  }) {
    return LoadingOverlay(
      isLoading: true,
      child: Container(),
      message: message,
      color: color,
      backgroundColor: backgroundColor,
      size: size,
      textStyle: textStyle,
    );
  }
}