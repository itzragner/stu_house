import 'package:flutter/material.dart';
import '../../models/property.dart';
import '../../config/themes.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../services/auth_service.dart';
import '../../services/database_service.dart';

class PropertyCard extends StatefulWidget {
  final Property property;
  final VoidCallback onTap;
  final Function(bool isFavorite) onFavoriteToggle;
  final bool isFavorite;

  const PropertyCard({
    Key? key,
    required this.property,
    required this.onTap,
    required this.onFavoriteToggle,
    this.isFavorite = false,
  }) : super(key: key);

  @override
  _PropertyCardState createState() => _PropertyCardState();
}

class _PropertyCardState extends State<PropertyCard> {
  late bool _isFavorite;
  bool _isCheckingFavorite = true;
  final currencyFormat = NumberFormat.currency(
    locale: 'fr_FR',
    symbol: 'DT',
    decimalDigits: 0,
  );
  final DatabaseService _databaseService = DatabaseService();

  @override
  void initState() {
    super.initState();
    _isFavorite = widget.isFavorite;
    _checkIfFavorite();
  }

  Future<void> _checkIfFavorite() async {
    // Only check if not already set as favorite from parent
    if (!widget.isFavorite) {
      setState(() {
        _isCheckingFavorite = true;
      });

      try {
        final authService = Provider.of<AuthService>(context, listen: false);
        final userId = authService.userId;

        if (userId != null) {
          final student = await _databaseService.getStudent(userId);
          setState(() {
            _isFavorite = student.favoritePropertyIds.contains(widget.property.propertyId);
            _isCheckingFavorite = false;
          });
        } else {
          setState(() {
            _isCheckingFavorite = false;
          });
        }
      } catch (e) {
        print('Error checking favorite status: $e');
        setState(() {
          _isCheckingFavorite = false;
        });
      }
    } else {
      setState(() {
        _isCheckingFavorite = false;
      });
    }
  }

  void _toggleFavorite() async {
    // Toggle state immediately for better UX
    setState(() {
      _isFavorite = !_isFavorite;
    });

    // Notify parent
    widget.onFavoriteToggle(_isFavorite);

    // Update database directly for redundancy
    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      final userId = authService.userId;

      if (userId != null) {
        if (_isFavorite) {
          await _databaseService.addFavoriteProperty(userId, widget.property.propertyId);
        } else {
          await _databaseService.removeFavoriteProperty(userId, widget.property.propertyId);
        }
      }
    } catch (e) {
      print('Error toggling favorite: $e');
      // Revert UI state if database operation failed
      setState(() {
        _isFavorite = !_isFavorite;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Utiliser une image de substitution si aucune image n'est disponible
    String imageUrl = widget.property.imageUrls.isNotEmpty
        ? widget.property.imageUrls[0]
        : 'https://via.placeholder.com/400x300?text=No+Image';

    return GestureDetector(
      onTap: widget.onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image et bouton favoris
            Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                  child: AspectRatio(
                    aspectRatio: 16 / 9,
                    child: Image.network(
                      imageUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          color: Colors.grey[300],
                          child: const Center(
                            child: Icon(Icons.image_not_supported, size: 50),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                Positioned(
                  top: 12,
                  right: 12,
                  child: GestureDetector(
                    onTap: _isCheckingFavorite ? null : _toggleFavorite,
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
                      child: _isCheckingFavorite
                          ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryColor),
                        ),
                      )
                          : Icon(
                        _isFavorite ? Icons.favorite : Icons.favorite_border,
                        color: _isFavorite ? AppTheme.primaryColor : Colors.grey,
                        size: 24,
                      ),
                    ),
                  ),
                ),
                // Ajout de l'indicateur de note comme sur Airbnb
                if (widget.property.rating != null)
                  Positioned(
                    top: 12,
                    left: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.7),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.star,
                            color: Colors.white,
                            size: 16,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            widget.property.rating.toString(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                // Photo de profil du propriétaire (comme sur la capture d'écran)
                Positioned(
                  bottom: -20,
                  left: 16,
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.white, width: 2),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(18),
                      child: Image.network(
                        'https://via.placeholder.com/40x40',
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            color: Colors.grey[300],
                            child: const Icon(Icons.person, size: 24),
                          );
                        },
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Informations sur la propriété
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          '${widget.property.address}',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Row(
                        children: [
                          const Icon(
                            Icons.star,
                            color: Colors.black,
                            size: 16,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            widget.property.rating?.toString() ?? '4.5',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Logement de ${widget.property.type.displayName}',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    widget.property.availableFrom != null
                        ? 'Disponible du ${DateFormat('d MMM').format(widget.property.availableFrom!)} au ${DateFormat('d MMM').format(widget.property.availableTo ?? DateTime.now().add(const Duration(days: 365)))}'
                        : 'Disponible',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${currencyFormat.format(widget.property.price)} / mois',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}