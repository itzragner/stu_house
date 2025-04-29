// lib/config/routes.dart
import 'package:flutter/material.dart';
import '../screens/common/splash_screen.dart';
import '../screens/auth/login_screen.dart';
import '../screens/auth/register_screen.dart';
import '../screens/auth/forgot_password_screen.dart';
import '../screens/student/student_home_screen.dart';
import '../screens/student/student_profile_setup_screen.dart';
import '../screens/owner/owner_home_screen.dart';
import '../screens/owner/owner_profile_setup_screen.dart';
import '../screens/owner/add_property_screen.dart';
import '../screens/common/property_details_screen.dart';
import '../screens/student/map_screen.dart';
import '../screens/student/filter_screen.dart';
import '../screens/student/search_screen.dart';
import '../screens/student/favorites_screen.dart';
import '../screens/common/reviews_screen.dart';
import '../screens/student/add_review_screen.dart';
import '../models/property.dart';

class AppRouter {
  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case SplashScreen.routeName:
        return MaterialPageRoute(builder: (_) => const SplashScreen());

      case LoginScreen.routeName:
        return MaterialPageRoute(builder: (_) => const LoginScreen());

      case RegisterScreen.routeName:
        return MaterialPageRoute(builder: (_) => const RegisterScreen());

      case ForgotPasswordScreen.routeName:
        return MaterialPageRoute(builder: (_) => const ForgotPasswordScreen());

      case StudentHomeScreen.routeName:
        return MaterialPageRoute(builder: (_) => const StudentHomeScreen());

      case OwnerHomeScreen.routeName:
        return MaterialPageRoute(builder: (_) => const OwnerHomeScreen());

      case AddPropertyScreen.routeName:
        return MaterialPageRoute(builder: (_) => const AddPropertyScreen());

      case StudentProfileSetupScreen.routeName:
        return MaterialPageRoute(builder: (_) => const StudentProfileSetupScreen());

      case OwnerProfileSetupScreen.routeName:
        return MaterialPageRoute(builder: (_) => const OwnerProfileSetupScreen());

      case PropertyDetailsScreen.routeName:
        final property = settings.arguments as Property;
        return MaterialPageRoute(
          builder: (_) => PropertyDetailsScreen(property: property),
        );

      case MapScreen.routeName:
        return MaterialPageRoute(builder: (_) => const MapScreen());

      case FavoritesScreen.routeName:
        return MaterialPageRoute(builder: (_) => const FavoritesScreen());

      case FilterScreen.routeName:
      // Optionnel: passage des filtres existants
        if (settings.arguments != null) {
          final FilterResult filters = settings.arguments as FilterResult;
          return MaterialPageRoute(
            builder: (_) => FilterScreen(
              minPrice: filters.minPrice,
              maxPrice: filters.maxPrice,
              minBedrooms: filters.minBedrooms,
              maxBedrooms: filters.maxBedrooms,
              propertyType: filters.propertyType,
            ),
          );
        }
        return MaterialPageRoute(builder: (_) => const FilterScreen());

      case SearchScreen.routeName:
        return MaterialPageRoute(builder: (_) => const SearchScreen());

      case ReviewsScreen.routeName:
        final property = settings.arguments as Property;
        return MaterialPageRoute(
          builder: (_) => ReviewsScreen(property: property),
        );

      case AddReviewScreen.routeName:
        final property = settings.arguments as Property;
        return MaterialPageRoute(
          builder: (_) => AddReviewScreen(property: property),
        );

      default:
      // Si la route n'existe pas, retourner une page d'erreur
        return MaterialPageRoute(
          builder: (_) => Scaffold(
            appBar: AppBar(title: const Text('Error')),
            body: const Center(
              child: Text('Route not found'),
            ),
          ),
        );
    }
  }
}