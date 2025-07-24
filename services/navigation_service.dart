import 'package:flutter/material.dart';

class NavigationService {
  static final NavigationService _instance = NavigationService._internal();
  factory NavigationService() {
    print('NavigationService: Accessing singleton instance: $_instance');
    return _instance;
  }

  NavigationService._internal();

  final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  Future<dynamic>? navigateTo(String routeName, {Object? arguments}) async {
    return _navigate(() async {
      print('NavigationService: Navigating to $routeName with arguments: $arguments');
      return navigatorKey.currentState?.pushNamed(routeName, arguments: arguments);
    });
  }

  // ADD THIS METHOD - This is what's missing!
  Future<dynamic>? pushNamed(String routeName, {Object? arguments}) async {
    return navigateTo(routeName, arguments: arguments);
  }

  Future<dynamic>? pushNamedAndRemoveUntil(String routeName, {Object? arguments}) async {
    return _navigate(() async {
      print('NavigationService: Navigating to $routeName and removing until with arguments: $arguments');
      return navigatorKey.currentState?.pushNamedAndRemoveUntil(
        routeName,
        (Route<dynamic> route) => false,
        arguments: arguments,
      );
    });
  }

  void pop() {
    print('NavigationService: Popping route');
    final navigatorState = navigatorKey.currentState;
    if (navigatorState == null || navigatorKey.currentContext == null) {
      print('NavigationService: Navigator state or context is null at ${DateTime.now()}');
      return;
    }
    navigatorState.pop();
  }

  Future<dynamic>? _navigate(Future<dynamic> Function() navigationFn) async {
    const maxRetries = 5;
    for (int retry = 0; retry < maxRetries; retry++) {
      if (navigatorKey.currentState != null && navigatorKey.currentContext != null) {
        try {
          return await navigationFn();
        } catch (e) {
          print('NavigationService: Navigation error: $e');
          rethrow;
        }
      }
      print('NavigationService: Navigator not ready, retrying (${retry + 1}/$maxRetries) at ${DateTime.now()}');
      await Future.delayed(const Duration(milliseconds: 100));
    }
    print('NavigationService: Failed to navigate after $maxRetries retries at ${DateTime.now()}');
    return null;
  }
}