import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:hockey_shot_tracker/providers/app_state.dart';
import 'package:hockey_shot_tracker/responsive_system/index.dart';
import 'package:hockey_shot_tracker/services/infrastructure/api_service_factory.dart';
import 'dart:async';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _animation;
  Timer? _navigationTimer;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );
    _animation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    );
    
    _animationController.forward();
    
    // Use addPostFrameCallback to ensure widget tree is built before navigation
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeApp();
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    _navigationTimer?.cancel();
    super.dispose();
  }

  Future<void> _initializeApp() async {
    try {
      // Small delay for animation to start
      await Future.delayed(const Duration(milliseconds: 500));
      
      if (!mounted) return;
      
      // Add a minimum splash duration for UX
      _navigationTimer = Timer(const Duration(seconds: 2), () {
        if (mounted) {
          _checkAuthAndNavigate();
        }
      });
      
    } catch (e) {
      print('Error initializing app: $e');
      if (mounted) {
        _navigateToLogin();
      }
    }
  }

  Future<void> _checkAuthAndNavigate() async {
    try {
      if (!mounted) return;
      
      final appState = Provider.of<AppState>(context, listen: false);
      
      print('🔍 Checking authentication status...');
      
      // Check if user is authenticated with valid tokens
      if (ApiServiceFactory.auth.isAuthenticated()) {
        final currentUser = appState.getCurrentUser();
        if (currentUser != null) {
          print('✅ User authenticated: ${currentUser['username']} (${currentUser['role']})');
          _navigateToHome();
          return;
        }
      }
      
      print('❌ No valid authentication found');
      _navigateToLogin();
      
    } catch (e) {
      print('Error checking auth status: $e');
      _navigateToLogin();
    }
  }

  void _navigateToHome() {
    if (!mounted) return;
    
    try {
      Navigator.of(context).pushReplacementNamed('/home');
    } catch (e) {
      print('Error navigating to home: $e');
      _navigateToLogin();
    }
  }

  void _navigateToLogin() {
    if (!mounted) return;
    
    try {
      Navigator.of(context).pushReplacementNamed('/login');
    } catch (e) {
      print('Error navigating to login: $e');
      // Fallback - try to navigate using Navigator.pushReplacementNamed
      Navigator.pushReplacementNamed(context, '/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blueGrey[900],
      body: SafeArea(
        child: AdaptiveLayout(
          builder: (deviceType, isLandscape) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  ScaleTransition(
                    scale: _animation,
                    child: Container(
                      width: ResponsiveConfig.dimension(context, 120),
                      height: ResponsiveConfig.dimension(context, 120),
                      decoration: BoxDecoration(
                        // Optional: add a subtle glow effect that complements your logo's red accents
                        boxShadow: [
                          BoxShadow(
                            color: Colors.red.withOpacity(0.3),
                            blurRadius: 15,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: Image.asset(
                        'assets/images/hire_hockey_logo.png',
                        fit: BoxFit.contain,
                        // Fallback to hockey icon if logo fails to load
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            width: ResponsiveConfig.dimension(context, 120),
                            height: ResponsiveConfig.dimension(context, 120),
                            decoration: const BoxDecoration(
                              color: Colors.cyanAccent,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.sports_hockey,
                              size: ResponsiveConfig.dimension(context, 72),
                              color: Colors.blueGrey[900],
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  ResponsiveSpacing(multiplier: 3),
                  FadeTransition(
                    opacity: _animation,
                    child: ResponsiveText(
                      'HIRE Hockey',
                      baseFontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  ResponsiveSpacing(multiplier: 2),
                  FadeTransition(
                    opacity: _animation,
                    child: ResponsiveText(
                      'Shot Tracking & Analytics',
                      baseFontSize: 16,
                      color: Colors.grey[300],
                    ),
                  ),
                  ResponsiveSpacing(multiplier: 6),
                  const CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.cyanAccent),
                  ),
                  ResponsiveSpacing(multiplier: 2),
                  FadeTransition(
                    opacity: _animation,
                    child: ResponsiveText(
                      'Initializing...',
                      baseFontSize: 14,
                      color: Colors.grey[400],
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}