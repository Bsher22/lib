// lib/widgets/dialogs/standard_dialogs.dart
import 'package:flutter/material.dart';

/// A collection of standardized dialog templates for consistent UI across the app.
class StandardDialogs {
  /// Creates a confirmation dialog with Yes/No buttons.
  static AlertDialog confirmation({
    required String title,
    required String message,
    String confirmLabel = 'Yes',
    String cancelLabel = 'No',
    bool isDestructive = false,
  }) {
    return AlertDialog(
      title: Text(
        title,
        style: const TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 18,
        ),
      ),
      content: Text(message),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(_getContext()).pop(false),
          child: Text(
            cancelLabel,
            style: TextStyle(
              color: Colors.blueGrey[700],
            ),
          ),
        ),
        TextButton(
          onPressed: () => Navigator.of(_getContext()).pop(true),
          style: TextButton.styleFrom(
            foregroundColor: isDestructive ? Colors.red : Colors.cyanAccent[700],
          ),
          child: Text(confirmLabel),
        ),
      ],
    );
  }

  /// Creates an information dialog with a single OK button.
  static AlertDialog information({
    required String title,
    required String message,
    String buttonLabel = 'OK',
  }) {
    return AlertDialog(
      title: Text(
        title,
        style: const TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 18,
        ),
      ),
      content: Text(message),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(_getContext()).pop(),
          style: TextButton.styleFrom(
            foregroundColor: Colors.cyanAccent[700],
          ),
          child: Text(buttonLabel),
        ),
      ],
    );
  }

  /// Creates an error dialog with an error icon and single OK button.
  static AlertDialog error({
    required String title,
    required String message,
    String buttonLabel = 'OK',
    VoidCallback? onRetry,
  }) {
    return AlertDialog(
      title: Row(
        children: [
          Icon(
            Icons.error_outline,
            color: Colors.red[700],
          ),
          const SizedBox(width: 8),
          Text(
            title,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 18,
              color: Colors.red[700],
            ),
          ),
        ],
      ),
      content: Text(message),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      actions: [
        if (onRetry != null)
          TextButton(
            onPressed: () {
              Navigator.of(_getContext()).pop();
              onRetry();
            },
            style: TextButton.styleFrom(
              foregroundColor: Colors.blue[700],
            ),
            child: const Text('Retry'),
          ),
        TextButton(
          onPressed: () => Navigator.of(_getContext()).pop(),
          style: TextButton.styleFrom(
            foregroundColor: Colors.blueGrey[700],
          ),
          child: Text(buttonLabel),
        ),
      ],
    );
  }

  /// Creates a success dialog with a success icon and single OK button.
  static AlertDialog success({
    required String title,
    required String message,
    String buttonLabel = 'OK',
  }) {
    return AlertDialog(
      title: Row(
        children: [
          Icon(
            Icons.check_circle_outline,
            color: Colors.green[700],
          ),
          const SizedBox(width: 8),
          Text(
            title,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 18,
              color: Colors.green[700],
            ),
          ),
        ],
      ),
      content: Text(message),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(_getContext()).pop(),
          style: TextButton.styleFrom(
            foregroundColor: Colors.green[700],
          ),
          child: Text(buttonLabel),
        ),
      ],
    );
  }

  /// Creates a loading dialog with a progress indicator.
  static AlertDialog loading({
    String message = 'Loading...',
    Color? color,
  }) {
    return AlertDialog(
      content: Row(
        children: [
          SizedBox(
            width: 32,
            height: 32,
            child: CircularProgressIndicator(
              strokeWidth: 3,
              valueColor: AlwaysStoppedAnimation<Color>(
                color ?? Colors.cyanAccent[700]!,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(message),
          ),
        ],
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
    );
  }

  /// Creates an unsaved changes confirmation dialog.
  static AlertDialog unsavedChanges() {
    return confirmation(
      title: 'Discard Changes?',
      message: 'You have unsaved changes that will be lost if you leave this screen.',
      confirmLabel: 'Discard',
      cancelLabel: 'Stay',
      isDestructive: true,
    );
  }

  /// Creates a selection dialog with a list of options.
  static AlertDialog selection<T>({
    required String title,
    required List<T> options,
    required Widget Function(BuildContext, T) itemBuilder,
    String? message,
    String cancelLabel = 'Cancel',
  }) {
    return AlertDialog(
      title: Text(
        title,
        style: const TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 18,
        ),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (message != null) ...[
            Text(message),
            const SizedBox(height: 16),
          ],
          ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: 300,
              maxWidth: 300,
              minWidth: 200,
            ),
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: options.length,
              itemBuilder: (context, index) {
                final item = options[index];
                return InkWell(
                  onTap: () => Navigator.of(context).pop(item),
                  borderRadius: BorderRadius.circular(8),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      vertical: 8,
                      horizontal: 4,
                    ),
                    child: itemBuilder(context, item),
                  ),
                );
              },
            ),
          ),
        ],
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(_getContext()).pop(),
          style: TextButton.styleFrom(
            foregroundColor: Colors.blueGrey[700],
          ),
          child: Text(cancelLabel),
        ),
      ],
    );
  }

  /// Helper method to get the current context if available.
  ///
  /// This is a workaround for the "No context provided" error that happens
  /// when trying to get Navigator.of(context) outside of a build method.
  static BuildContext _getContext() {
    // This will throw an error if not called from within a build method.
    // User needs to provide their own context in that case.
    return WidgetsBinding.instance.focusManager.primaryFocus!.context!;
  }
}