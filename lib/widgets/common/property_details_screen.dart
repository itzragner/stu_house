import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/property.dart';
import '../../services/database_service.dart';
import '../../services/auth_service.dart';
import '../../widgets/common/custom_button.dart';
import '../../config/themes.dart';

class PropertyDetailsScreen extends StatefulWidget {
  static const String routeName = '/property/details';
  final Property property;

  const PropertyDetailsScreen({
    super.key,
    required this.property,
  });
  @override
  _PropertyDetailsScreenState createState() => _PropertyDetailsScreenState();
}

class _PropertyDetailsScreenState extends State<PropertyDetailsScreen> {
  final DatabaseService _databaseService = DatabaseService();
  bool _isFavorite = false;
  bool _isLoading = true;
  int _currentImageIndex = 0;
  final PageController _pageController = PageController();
  bool _favoriteChanged = false; // Track if favorite was changed

  @override
  void initState() {
    super.initState();
    _checkIfFavorite();
  }

  Future<void> _checkIfFavorite() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      final userId = authService.userId;

      if (userId != null) {
        final student = await _databaseService.getStudent(userId);
        setState(() {
          _isFavorite =
              student.favoritePropertyIds.contains(widget.property.propertyId);
          _isLoading = false;
        });
      } else {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error checking favorite status: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _toggleFavorite() async {
    final bool oldStatus = _isFavorite;

    setState(() {
      _isFavorite = !_isFavorite;
      _favoriteChanged = true; // Mark that we changed favorite status
    });

    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      final userId = authService.userId;

      if (userId != null) {
        if (_isFavorite) {
          await _databaseService.addFavoriteProperty(
            userId,
            widget.property.propertyId,
          );
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Ajouté aux favoris'),
              duration: Duration(seconds: 2),
            ),
          );
        } else {
          await _databaseService.removeFavoriteProperty(
            userId,
            widget.property.propertyId,
          );
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Retiré des favoris'),
              duration: Duration(seconds: 2),
            ),
          );
        }
      } else {
        // Revert if not logged in
        setState(() {
          _isFavorite = oldStatus;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Connectez-vous pour ajouter des favoris'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      // Revert on error
      setState(() {
        _isFavorite = oldStatus;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur: ${e.toString()}'),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      // When navigating back, pass the favoriteChanged status
      onWillPop: () async {
        Navigator.pop(context, _favoriteChanged);
        return false;
      },
      child: Scaffold(
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : CustomScrollView(
          slivers: [
            // En-tête avec carrousel d'images
            SliverAppBar(
              expandedHeight: 300,
              pinned: true,
              flexibleSpace: FlexibleSpaceBar(
                background: Stack(
                  children: [
                    // Carrousel d'images
                    PageView.builder(
                      controller: _pageController,
                      itemCount: widget.property.imageUrls.isNotEmpty
                          ? widget.property.imageUrls.length
                          : 1,
                      onPageChanged: (index) {
                        setState(() {
                          _currentImageIndex = index;
                        });
                      },
                      itemBuilder: (context, index) {
                        return Image.network(
                          widget.property.imageUrls.isNotEmpty
                              ? widget.property.imageUrls[index]
                              : 'https://via.placeholder.com/800x500?text=No+Image',
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              color: Colors.grey[300],
                              child: const Center(
                                child: Icon(Icons.image_not_supported, size: 50),
                              ),
                            );
                          },
                        );
                      },
                    ),
                    // Indicateurs de page
                    if (widget.property.imageUrls.length > 1)
                      Positioned(
                        bottom: 16,
                        left: 0,
                        right: 0,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: List.generate(
                            widget.property.imageUrls.length,
                                (index) =>
                                Container(
                                  width: 8,
                                  height: 8,
                                  margin: const EdgeInsets.symmetric(
                                      horizontal: 4),
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: index == _currentImageIndex
                                        ? Colors.white
                                        : Colors.white.withOpacity(0.5),
                                  ),
                                ),
                          ),
                        ),
                      ),
                    // Bouton Favoris
                    Positioned(
                      top: 16,
                      right: 16,
                      child: GestureDetector(
                        onTap: _toggleFavorite,
                        child: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Icon(
                            _isFavorite ? Icons.favorite : Icons.favorite_border,
                            color: _isFavorite ? AppTheme.primaryColor : Colors
                                .grey,
                            size: 24,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              leading: Container(
                margin: const EdgeInsets.only(left: 8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: IconButton(
                  icon: const Icon(Icons.arrow_back),
                  onPressed: () {
                    Navigator.pop(context, _favoriteChanged);
                  },
                ),
              ),
              actions: [
                Container(
                  margin: const EdgeInsets.only(right: 8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.share),
                    onPressed: () {
                      // Partager la propriété
                    },
                  ),
                ),
              ],
            ),

            // Contenu
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Titre et note
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            widget.property.title,
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        Row(
                          children: [
                            const Icon(Icons.star, size: 20),
                            const SizedBox(width: 4),
                            Text(
                              '${widget.property.rating ?? 4.5}',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),

                    // Adresse
                    Text(
                      widget.property.address,
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey[700],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Divider
                    const Divider(),
                    const SizedBox(height: 16),

                    // Informations sur le logement
                    Text(
                      'Accommodation offered by',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey[700],
                      ),
                    ),
                    const SizedBox(height: 12),

                    Row(
                      children: [
                        Container(
                          width: 50,
                          height: 50,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(25),
                          ),
                          clipBehavior: Clip.antiAlias,
                          child: Image.network(
                            'https://via.placeholder.com/50x50',
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                color: Colors.grey[300],
                                child: const Icon(Icons.person, size: 30),
                              );
                            },
                          ),
                        ),
                        const SizedBox(width: 16),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Owner',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Member since 2023',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),
                    const Divider(),
                    const SizedBox(height: 16),

                    // Caractéristiques du logement
                    const Text(
                      'Property features',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Grille de caractéristiques
                    Row(
                      children: [
                        Expanded(
                          child: _buildFeatureItem(
                            Icons.hotel,
                            '${widget.property.bedrooms} rooms${widget.property
                                .bedrooms > 1 ? 's' : ''}',
                          ),
                        ),
                        Expanded(
                          child: _buildFeatureItem(
                            Icons.bathtub,
                            '${widget.property.bathrooms} bathroom${widget.property
                                .bathrooms > 1 ? 's' : ''} de bain',
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: _buildFeatureItem(
                            Icons.square_foot,
                            '${widget.property.area} m²',
                          ),
                        ),
                        Expanded(
                          child: _buildFeatureItem(
                            Icons.location_on,
                            'Ideal location',
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),
                    const Divider(),
                    const SizedBox(height: 16),

                    // Description
                    const Text(
                      'About this property',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      widget.property.description,
                      style: const TextStyle(
                        fontSize: 16,
                        height: 1.5,
                      ),
                    ),

                    const SizedBox(height: 16),
                    const Divider(),
                    const SizedBox(height: 16),

                    // Équipements
                    const Text(
                      'Amenities',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Liste des équipements
                    ...widget.property.amenities.map((amenity) =>
                        Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: Row(
                            children: [
                              Icon(
                                _getAmenityIcon(amenity),
                                size: 22,
                                color: Colors.grey[800],
                              ),
                              const SizedBox(width: 12),
                              Text(
                                amenity,
                                style: const TextStyle(fontSize: 16),
                              ),
                            ],
                          ),
                        )).toList(),

                    const SizedBox(height: 100),
                    // Espace pour le bouton fixe en bas
                  ],
                ),
              ),
            ),
          ],
        ),
        bottomSheet: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, -5),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${widget.property.price} €',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Text(
                    'per month',
                    style: TextStyle(
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
              SizedBox(
                width: 200,
                child: CustomButton(
                  text: 'Apply',
                  onPressed: () {
                    // Naviguer vers l'écran de candidature
                    // Navigator.pushNamed(
                    //   context,
                    //   ApplicationScreen.routeName,
                    //   arguments: widget.property,
                    // );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFeatureItem(IconData icon, String text) {
    return Column(
      children: [
        Icon(
          icon,
          size: 28,
          color: Colors.grey[800],
        ),
        const SizedBox(height: 8),
        Text(
          text,
          style: const TextStyle(fontSize: 14),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  IconData _getAmenityIcon(String amenity) {
    final amenityLower = amenity.toLowerCase();
    if (amenityLower.contains('wifi')) return Icons.wifi;
    if (amenityLower.contains('kitchen')) return Icons.kitchen;
    if (amenityLower.contains('Washing machine')) return Icons.local_laundry_service;
    if (amenityLower.contains('TV') || amenityLower.contains('tv'))
      return Icons.tv;
    if (amenityLower.contains('parking')) return Icons.local_parking;
    if (amenityLower.contains('Air conditioning')) return Icons.ac_unit;
    if (amenityLower.contains('Heating')) return Icons.whatshot;
    if (amenityLower.contains('balcony')) return Icons.balcony;
    // Par défaut
    return Icons.check;
  }
}