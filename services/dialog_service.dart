// lib/services/dialog_service.dart
import 'package:flutter/material.dart';
import 'package:hockey_shot_tracker/widgets/core/dialog/standard_dialogs.dart';

/// A service that provides centralized dialog management.
/// 
/// This service allows showing dialogs in a consistent manner across the app,
/// without having to duplicate the dialog creation and management code.
class DialogService {
  /// Shows a standard confirmation dialog with customizable title, message, and button labels.
  /// 
  /// Returns `true` if confirmed, `false` if cancelled, and `null` if dismissed.
  static Future<bool?> showConfirmation(
    BuildContext context, {
    required String title,
    required String message,
    String confirmLabel = 'Yes',
    String cancelLabel = 'No',
    bool isDestructive = false,
  }) async {
    return await showDialog<bool>(
      context: context,
      builder: (context) => StandardDialogs.confirmation(
        title: title,
        message: message,
        confirmLabel: confirmLabel,
        cancelLabel: cancelLabel,
        isDestructive: isDestructive,
      ),
    );
  }

  /// Shows a standard information dialog with customizable title, message, and button label.
  static Future<void> showInformation(
    BuildContext context, {
    required String title,
    required String message,
    String buttonLabel = 'OK',
  }) async {
    return await showDialog<void>(
      context: context,
      builder: (context) => StandardDialogs.information(
        title: title,
        message: message,
        buttonLabel: buttonLabel,
      ),
    );
  }

  /// Shows a standard error dialog with customizable title, message, and button label.
  static Future<void> showError(
    BuildContext context, {
    required String title,
    required String message,
    String buttonLabel = 'OK',
    VoidCallback? onRetry,
  }) async {
    return await showDialog<void>(
      context: context,
      builder: (context) => StandardDialogs.error(
        title: title,
        message: message,
        buttonLabel: buttonLabel,
        onRetry: onRetry,
      ),
    );
  }

  /// Shows a standard success dialog with customizable title, message, and button label.
  static Future<void> showSuccess(
    BuildContext context, {
    required String title,
    required String message,
    String buttonLabel = 'OK',
  }) async {
    return await showDialog<void>(
      context: context,
      builder: (context) => StandardDialogs.success(
        title: title,
        message: message,
        buttonLabel: buttonLabel,
      ),
    );
  }

  /// Shows a dialog with custom content.
  static Future<T?> showCustom<T>(
    BuildContext context, {
    required Widget content,
    bool barrierDismissible = true,
    BorderRadius? borderRadius,
  }) async {
    return await showDialog<T>(
      context: context,
      barrierDismissible: barrierDismissible,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: borderRadius ?? BorderRadius.circular(16),
        ),
        child: content,
      ),
    );
  }

  /// Shows a bottom sheet dialog.
  static Future<T?> showBottomSheet<T>(
    BuildContext context, {
    required Widget content,
    bool isDismissible = true,
    bool enableDrag = true,
    BorderRadius? borderRadius,
  }) async {
    return await showModalBottomSheet<T>(
      context: context,
      isDismissible: isDismissible,
      enableDrag: enableDrag,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: borderRadius ?? const BorderRadius.vertical(
            top: Radius.circular(16),
          ),
        ),
        child: content,
      ),
    );
  }

  /// Shows a loading dialog. Use [hideLoading] to dismiss it.
  static Future<void> showLoading(
    BuildContext context, {
    String message = 'Loading...',
    Color? color,
  }) async {
    return await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) => StandardDialogs.loading(
        message: message,
        color: color,
      ),
    );
  }

  /// Hides any currently displayed dialog.
  static void hideLoading(BuildContext context) {
    Navigator.of(context, rootNavigator: true).pop();
  }

  /// Shows an unsaved changes confirmation dialog.
  static Future<bool?> showUnsavedChanges(BuildContext context) async {
    return await showDialog<bool>(
      context: context,
      builder: (context) => StandardDialogs.unsavedChanges(),
    );
  }

  /// Shows a selection dialog with a list of options.
  static Future<T?> showSelection<T>(
    BuildContext context, {
    required String title,
    required List<T> options,
    required Widget Function(BuildContext, T) itemBuilder,
    String? message,
    String cancelLabel = 'Cancel',
  }) async {
    return await showDialog<T>(
      context: context,
      builder: (context) => StandardDialogs.selection<T>(
        title: title,
        options: options,
        itemBuilder: itemBuilder,
        message: message,
        cancelLabel: cancelLabel,
      ),
    );
  }
}