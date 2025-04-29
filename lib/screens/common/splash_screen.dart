import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/auth_service.dart';
import '../auth/login_screen.dart';
import '../student/student_home_screen.dart';
import '../owner/owner_home_screen.dart';
import '../../config/themes.dart';

class SplashScreen extends StatefulWidget {
  static const String routeName = '/splash';

  const SplashScreen({super.key});

  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Interval(0.0, 0.5, curve: Curves.easeIn),
      ),
    );

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Interval(0.3, 1.0, curve: Curves.easeOutBack),
      ),
    );

    _animationController.forward();

    // Check authentication status after animations
    Future.delayed(const Duration(seconds: 2), () {
      _checkAuthAndNavigate();
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  // Check authentication status and navigate accordingly
  Future<void> _checkAuthAndNavigate() async {
    final authService = Provider.of<AuthService>(context, listen: false);

    // Wait for auth status to be determined (not loading)
    if (authService.status == AuthStatus.loading) {
      await Future.delayed(const Duration(milliseconds: 500));
      if (mounted) _checkAuthAndNavigate();
      return;
    }

    if (authService.isAuthenticated) {
      // User is already logged in, navigate to appropriate home screen
      if (authService.isStudent || authService.userType == 'guest') {
        if (mounted) {
          Navigator.of(context).pushReplacementNamed(StudentHomeScreen.routeName);
        }
      } else if (authService.isOwner) {
        if (mounted) {
          Navigator.of(context).pushReplacementNamed(OwnerHomeScreen.routeName);
        }
      } else {
        // Default to student home if type is unknown
        if (mounted) {
          Navigator.of(context).pushReplacementNamed(StudentHomeScreen.routeName);
        }
      }
    } else {
      // User is not logged in, navigate to login screen
      if (mounted) {
        Navigator.of(context).pushReplacementNamed(LoginScreen.routeName);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.primaryColor,
      body: Center(
        child: AnimatedBuilder(
          animation: _animationController,
          builder: (context, child) {
            return FadeTransition(
              opacity: _fadeAnimation,
              child: ScaleTransition(
                scale: _scaleAnimation,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // App logo
                    Icon(
                      Icons.home_work,
                      size: 100,
                      color: Colors.white,
                    ),
                    const SizedBox(height: 24),
                    // App name
                    Text(
                      'StuHous',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    // Slogan
                    Text(
                      'Find the perfect accommodation for your studies',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.8),
                        fontSize: 16,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 64),
                    // Loading indicator
                    SizedBox(
                      width: 40,
                      height: 40,
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        strokeWidth: 3,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}