// ============================================================================
// File: lib/responsive_system/responsive_app.dart (COMPLETE FIXED VERSION)
// ============================================================================
import 'package:flutter/material.dart';
import 'responsive_widgets.dart';
import 'full_screen_container.dart';

class ResponsiveApp extends StatelessWidget {
  final String title;
  final ThemeData theme;
  final ThemeData darkTheme;
  final Widget? home; // ✅ Made optional since we might use initialRoute instead
  final Map<String, WidgetBuilder> routes;
  final RouteFactory? onGenerateRoute;
  final GlobalKey<NavigatorState>? navigatorKey;
  final String? initialRoute; // ✅ ADDED: Support for initialRoute
  final ThemeMode? themeMode;
  final Locale? locale;
  final Iterable<LocalizationsDelegate<dynamic>>? localizationsDelegates;
  final Iterable<Locale>? supportedLocales;
  final bool debugShowCheckedModeBanner;

  const ResponsiveApp({
    super.key,
    required this.title,
    required this.theme,
    required this.darkTheme,
    this.home, // ✅ Made optional
    required this.routes,
    this.onGenerateRoute,
    this.navigatorKey,
    this.initialRoute, // ✅ ADDED: Optional initialRoute parameter
    this.themeMode,
    this.locale,
    this.localizationsDelegates,
    this.supportedLocales,
    this.debugShowCheckedModeBanner = true,
  });

  @override
  Widget build(BuildContext context) {
    // ✅ UPDATED: Handle both home and initialRoute scenarios
    final bool hasInitialRoute = initialRoute != null;
    final bool hasRootRoute = routes.containsKey('/');
    final processedRoutes = Map<String, WidgetBuilder>.from(routes);
    
    // Remove root route from processed routes to handle it separately
    if (hasRootRoute) {
      processedRoutes.remove('/');
    }
    
    return MaterialApp(
      navigatorKey: navigatorKey,
      title: title,
      theme: theme,
      darkTheme: darkTheme,
      themeMode: themeMode,
      locale: locale,
      localizationsDelegates: localizationsDelegates,
      supportedLocales: supportedLocales ?? const <Locale>[Locale('en', 'US')],
      debugShowCheckedModeBanner: debugShowCheckedModeBanner,
      
      // ✅ UPDATED: Proper handling of home vs initialRoute
      home: hasInitialRoute 
        ? null 
        : (hasRootRoute 
          ? null 
          : (home != null ? _wrapWithFullScreen(home!) : null)),
      
      initialRoute: hasInitialRoute 
        ? initialRoute 
        : (hasRootRoute ? '/' : null),
      
      // ✅ UPDATED: Enhanced route handling with full screen wrapping
      routes: {
        if (hasRootRoute)
          '/': (context) => _wrapWithFullScreen(routes['/']!(context)),
        ...processedRoutes.map((key, builder) => MapEntry(
          key,
          (context) => _wrapWithFullScreen(builder(context)),
        )),
      },
      
      // ✅ UPDATED: Enhanced onGenerateRoute with proper wrapping
      onGenerateRoute: onGenerateRoute != null 
        ? (settings) {
            final route = onGenerateRoute!(settings);
            if (route != null) {
              // If the route is a MaterialPageRoute, wrap its builder
              if (route is MaterialPageRoute) {
                return MaterialPageRoute(
                  settings: settings,
                  builder: (context) => _wrapWithFullScreen(route.builder(context)),
                );
              }
              // For other route types, return as-is (they should handle their own wrapping)
              return route;
            }
            return null;
          }
        : null,
    );
  }

  /// Wrap widgets with full screen container for proper coverage
  Widget _wrapWithFullScreen(Widget child) {
    return FullScreenContainer(
      backgroundColor: Colors.white,
      child: child,
    );
  }
}