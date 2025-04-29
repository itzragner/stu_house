import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'config/routes.dart';
import 'config/themes.dart';
import 'screens/common/splash_screen.dart';
import 'screens/auth/login_screen.dart';
import 'services/auth_service.dart';

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'StuHous',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system,
      onGenerateRoute: AppRouter.onGenerateRoute,
      home: Consumer<AuthService>(
        builder: (context, auth, child) {
          // Show splash screen while checking authentication
          if (auth.status == AuthStatus.loading) {
            return const SplashScreen();
          }

          // Navigate to appropriate screen based on auth status
          if (auth.isAuthenticated) {
            return const SplashScreen(); // This will redirect to the appropriate home screen
          } else {
            return const LoginScreen();
          }
        },
      ),
    );
  }
}