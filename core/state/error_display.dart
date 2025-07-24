// lib/widgets/common/state/error_display.dart
import 'package:flutter/material.dart';

/// A reusable error display widget that shows an error message
/// with optional retry action and customizable appearance.
class ErrorDisplay extends StatelessWidget {
  /// The error message to display
  final String message;
  
  /// Optional more detailed error information
  final String? details;
  
  /// Optional callback function to retry the action
  final VoidCallback? onRetry;
  
  /// Optional callback function for an alternative action
  final VoidCallback? onAlternativeAction;
  
  /// Optional label for the alternative action button
  final String? alternativeActionLabel;
  
  /// Icon to display above the error message
  final IconData icon;
  
  /// Color of the icon
  final Color iconColor;
  
  /// Size of the icon
  final double iconSize;
  
  /// Style for the main error message
  final TextStyle? messageStyle;
  
  /// Style for the error details
  final TextStyle? detailsStyle;
  
  /// Background color of the retry button
  final Color? retryButtonColor;
  
  /// Whether to show the error in a card
  final bool showCard;

  const ErrorDisplay({
    Key? key,
    required this.message,
    this.details,
    this.onRetry,
    this.onAlternativeAction,
    this.alternativeActionLabel,
    this.icon = Icons.error_outline,
    this.iconColor = Colors.red,
    this.iconSize = 64.0,
    this.messageStyle,
    this.detailsStyle,
    this.retryButtonColor,
    this.showCard = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final errorContent = Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          icon,
          size: iconSize,
          color: iconColor,
        ),
        const SizedBox(height: 16),
        Text(
          message,
          style: messageStyle ?? 
            TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.blueGrey[800],
            ),
          textAlign: TextAlign.center,
        ),
        if (details != null) ...[
          const SizedBox(height: 8),
          Text(
            details!,
            style: detailsStyle ?? 
              TextStyle(
                fontSize: 16,
                color: Colors.blueGrey[600],
              ),
            textAlign: TextAlign.center,
          ),
        ],
        if (onRetry != null) ...[
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh),
            label: const Text('Try Again'),
            style: ElevatedButton.styleFrom(
              backgroundColor: retryButtonColor ?? Colors.cyanAccent,
              foregroundColor: Colors.black87,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
        if (onAlternativeAction != null && alternativeActionLabel != null) ...[
          const SizedBox(height: 12),
          TextButton(
            onPressed: onAlternativeAction,
            child: Text(alternativeActionLabel!),
          ),
        ],
      ],
    );

    if (showCard) {
      return Card(
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        margin: const EdgeInsets.all(16),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: errorContent,
        ),
      );
    } else {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: errorContent,
        ),
      );
    }
  }
  
  /// Creates a network error display with predefined settings
  static Widget network({
    String message = 'Network Error',
    String? details = 'Unable to connect to the server. Please check your internet connection and try again.',
    VoidCallback? onRetry,
    bool showCard = false,
  }) {
    return ErrorDisplay(
      message: message,
      details: details,
      onRetry: onRetry,
      icon: Icons.wifi_off,
      iconColor: Colors.orange,
      showCard: showCard,
    );
  }
  
  /// Creates a not found error display with predefined settings
  static Widget notFound({
    String message = 'Not Found',
    String? details = 'The requested resource could not be found.',
    VoidCallback? onRetry,
    VoidCallback? onGoBack,
    bool showCard = false,
  }) {
    return ErrorDisplay(
      message: message,
      details: details,
      onRetry: onRetry,
      onAlternativeAction: onGoBack,
      alternativeActionLabel: 'Go Back',
      icon: Icons.search_off,
      iconColor: Colors.blueGrey,
      showCard: showCard,
    );
  }
  
  /// Creates a permission error display with predefined settings
  static Widget permission({
    String message = 'Permission Denied',
    String? details = 'You do not have permission to access this feature.',
    VoidCallback? onGoBack,
    bool showCard = false,
  }) {
    return ErrorDisplay(
      message: message,
      details: details,
      onAlternativeAction: onGoBack,
      alternativeActionLabel: 'Go Back',
      icon: Icons.no_accounts,
      iconColor: Colors.red,
      showCard: showCard,
    );
  }
}