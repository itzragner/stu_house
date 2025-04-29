import 'package:flutter/material.dart';
import '../../config/themes.dart';
import '../../models/property.dart';
import '../../services/database_service.dart';
import '../../widgets/property/property_card.dart';
import '../../widgets/common/custom_search_bar.dart';
import 'filter_screen.dart';
import 'map_screen.dart';

class SearchScreen extends StatefulWidget {
  static const String routeName = '/search';

  // Paramètres de recherche initiaux (optionnels)
  final String? query;
  final FilterResult? initialFilters;

  const SearchScreen({
    Key? key,
    this.query,
    this.initialFilters,
  }) : super(key: key);

  @override
  _SearchScreenState createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final DatabaseService _databaseService = DatabaseService();
  final TextEditingController _searchController = TextEditingController();
  bool _isLoading = false;
  List<Property> _searchResults = [];
  FilterResult? _currentFilters;

  @override
  void initState() {
    super.initState();

    // Initialiser avec les valeurs fournies
    if (widget.query != null) {
      _searchController.text = widget.query!;
    }
    _currentFilters = widget.initialFilters;

    // Effectuer la recherche initiale
    _performSearch();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _performSearch() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Construire les paramètres de recherche à partir du texte et des filtres
      Map<String, dynamic> searchParams = {
        'availableOnly': true,
      };

      // Ajouter les filtres s'ils existent
      if (_currentFilters != null) {
        searchParams['minPrice'] = _currentFilters!.minPrice;
        searchParams['maxPrice'] = _currentFilters!.maxPrice;
        searchParams['minBedrooms'] = _currentFilters!.minBedrooms;
        searchParams['maxBedrooms'] = _currentFilters!.maxBedrooms;
        searchParams['propertyType'] = _currentFilters!.propertyType;
      }

      // Effectuer la recherche avec le service de base de données
      final properties = await _databaseService.searchProperties(
        minPrice: searchParams['minPrice'],
        maxPrice: searchParams['maxPrice'],
        minBedrooms: searchParams['minBedrooms'],
        maxBedrooms: searchParams['maxBedrooms'],
        propertyType: searchParams['propertyType'],
        availableOnly: searchParams['availableOnly'],
      );

      // Filtrer par le texte de recherche si non vide
      List<Property> filteredResults = properties;
      if (_searchController.text.isNotEmpty) {
        final searchText = _searchController.text.toLowerCase();
        filteredResults = properties.where((property) {
          return property.title.toLowerCase().contains(searchText) ||
              property.address.toLowerCase().contains(searchText) ||
              property.description.toLowerCase().contains(searchText);
        }).toList();
      }

      setState(() {
        _searchResults = filteredResults;
        _isLoading = false;
      });
    } catch (e) {
      print('Error searching properties: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _openFilters() async {
    final result = await Navigator.push<FilterResult>(
      context,
      MaterialPageRoute(
        builder: (context) => FilterScreen(
          minPrice: _currentFilters?.minPrice,
          maxPrice: _currentFilters?.maxPrice,
          minBedrooms: _currentFilters?.minBedrooms,
          maxBedrooms: _currentFilters?.maxBedrooms,
          propertyType: _currentFilters?.propertyType,
        ),
      ),
    );

    if (result != null) {
      setState(() {
        _currentFilters = result;
      });
      _performSearch();
    }
  }

  void _openMap() {
    Navigator.pushNamed(context, MapScreen.routeName);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Recherche'),
        centerTitle: true,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Rechercher une localisation...',
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(30),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: Colors.grey[200],
                      contentPadding: const EdgeInsets.symmetric(
                        vertical: 0,
                        horizontal: 16,
                      ),
                    ),
                    onSubmitted: (_) => _performSearch(),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.tune),
                    onPressed: _openFilters,
                    tooltip: 'Filtres',
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      body: Column(
        children: [
          // Barre d'information de filtres (si des filtres sont actifs)
          if (_currentFilters != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              color: Colors.grey[100],
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      _buildFilterDescription(),
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[700],
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      setState(() {
                        _currentFilters = null;
                      });
                      _performSearch();
                    },
                    child: const Text('Effacer'),
                    style: TextButton.styleFrom(
                      foregroundColor: AppTheme.primaryColor,
                    ),
                  ),
                ],
              ),
            ),

          // Bouton pour basculer en vue carte
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: ElevatedButton.icon(
              onPressed: _openMap,
              icon: const Icon(Icons.map),
              label: const Text('Voir la carte'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: Colors.black,
                elevation: 1,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                  side: BorderSide(color: Colors.grey[300]!),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              ),
            ),
          ),

          // Résultats de recherche
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _searchResults.isEmpty
                ? const Center(
              child: Text('Aucun logement ne correspond à votre recherche'),
            )
                : ListView.builder(
              padding: const EdgeInsets.only(top: 8),
              itemCount: _searchResults.length,
              itemBuilder: (context, index) {
                final property = _searchResults[index];
                return PropertyCard(
                  property: property,
                  onTap: () {
                    // Navigator.pushNamed(
                    //   context,
                    //   PropertyDetailsScreen.routeName,
                    //   arguments: property,
                    // );
                  },
                  onFavoriteToggle: (isFavorite) {
                    // Gérer l'ajout/suppression des favoris
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // Construire une description textuelle des filtres actifs
  String _buildFilterDescription() {
    if (_currentFilters == null) return '';

    List<String> descriptions = [];

    // Prix
    if (_currentFilters!.minPrice > 0 || _currentFilters!.maxPrice < 2000) {
      descriptions.add('${_currentFilters!.minPrice.toInt()}€ - ${_currentFilters!.maxPrice.toInt()}€');
    }

    // Chambres
    if (_currentFilters!.minBedrooms > 0 || _currentFilters!.maxBedrooms < 5) {
      descriptions.add('${_currentFilters!.minBedrooms} - ${_currentFilters!.maxBedrooms} chambres');
    }

    // Type de propriété
    if (_currentFilters!.propertyType != null) {
      descriptions.add(_currentFilters!.propertyType!.displayName);
    }

    return descriptions.join(' · ');
  }
}