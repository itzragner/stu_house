import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/property.dart';
import '../../services/database_service.dart';
import '../../services/auth_service.dart';
import '../../widgets/property/property_card.dart';
import '../common/property_details_screen.dart';

class FavoritesScreen extends StatefulWidget {
  static const String routeName = '/favorites';

  const FavoritesScreen({Key? key}) : super(key: key);

  @override
  _FavoritesScreenState createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen> {
  final DatabaseService _databaseService = DatabaseService();
  bool _isLoading = true;
  List<Property> _favorites = [];

  @override
  void initState() {
    super.initState();
    _loadFavorites();
  }

  Future<void> _loadFavorites() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      final userId = authService.userId;

      if (userId != null) {
        final favorites = await _databaseService.getFavoriteProperties(userId);
        setState(() {
          _favorites = favorites;
          _isLoading = false;
        });
      } else {
        setState(() {
          _favorites = [];
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading favorites: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mes Favoris'),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _favorites.isEmpty
          ? _buildEmptyState()
          : _buildFavoritesList(),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.favorite_border,
            size: 80,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          const Text(
            'Aucun favori pour le moment',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Ajoutez des logements à vos favoris\npour les retrouver ici',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.grey,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFavoritesList() {
    return RefreshIndicator(
      onRefresh: _loadFavorites,
      child: ListView.builder(
        padding: const EdgeInsets.all(8),
        itemCount: _favorites.length,
        itemBuilder: (context, index) {
          final property = _favorites[index];
          return PropertyCard(
            property: property,
            onTap: () {
              Navigator.pushNamed(
                context,
                PropertyDetailsScreen.routeName,
                arguments: property,
              ).then((_) => _loadFavorites()); // Reload after returning
            },
            onFavoriteToggle: (isFavorite) async {
              final authService = Provider.of<AuthService>(context, listen: false);
              final userId = authService.userId;

              if (userId != null) {
                if (!isFavorite) {
                  await _databaseService.removeFavoriteProperty(
                    userId,
                    property.propertyId,
                  );
                  // Refresh the list after removing
                  _loadFavorites();
                }
              }
            },
            isFavorite: true, // Always true since we're in the favorites screen
          );
        },
      ),
    );
  }
}