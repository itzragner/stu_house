import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../models/property.dart';
import '../../services/database_service.dart';
import '../../config/themes.dart';
import '../common/property_details_screen.dart';

class MapScreen extends StatefulWidget {
  static const String routeName = '/map';

  const MapScreen({Key? key}) : super(key: key);

  @override
  _MapScreenState createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  final DatabaseService _databaseService = DatabaseService();
  GoogleMapController? _mapController;
  bool _isLoading = true;
  List<Property> _properties = [];
  Map<String, Marker> _markers = {};
  Property? _selectedProperty;

  // Position par défaut (à ajuster selon votre localisation principale)
  final CameraPosition _initialPosition = const CameraPosition(
    target: LatLng(48.8566, 2.3522), // Paris
    zoom: 12,
  );

  @override
  void initState() {
    super.initState();
    _loadProperties();
  }

  Future<void> _loadProperties() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Charger toutes les propriétés disponibles
      final properties = await _databaseService.searchProperties(
        availableOnly: true,
      );

      // Filtrer celles qui ont des coordonnées valides
      final validProperties = properties.where((p) =>
      p.latitude != null && p.longitude != null).toList();

      // Créer les marqueurs pour chaque propriété
      Map<String, Marker> markers = {};
      for (var property in validProperties) {
        markers[property.propertyId] = await _createMarker(property);
      }

      setState(() {
        _properties = validProperties;
        _markers = markers;
        _isLoading = false;
      });

      // Centrer la carte pour afficher tous les marqueurs si on en a
      if (validProperties.isNotEmpty) {
        _centerMapOnProperties(validProperties);
      }
    } catch (e) {
      print('Error loading properties for map: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<Marker> _createMarker(Property property) async {
    // Prix formaté pour l'affichage
    final priceString = '${property.price.toInt()}€';

    return Marker(
      markerId: MarkerId(property.propertyId),
      position: LatLng(property.latitude!, property.longitude!),
      infoWindow: InfoWindow(
        title: property.title,
        snippet: '${property.bedrooms} chambre(s) · $priceString/mois',
        onTap: () {
          // Naviguer vers l'écran de détail lors du tap sur l'info
          Navigator.pushNamed(
            context,
            PropertyDetailsScreen.routeName,
            arguments: property,
          );
        },
      ),
      onTap: () {
        // Afficher la carte de propriété en bas
        setState(() {
          _selectedProperty = property;
        });
      },
      icon: await _getMarkerIcon(priceString),
    );
  }

  // Méthode pour créer une icône de marqueur personnalisée avec le prix
  Future<BitmapDescriptor> _getMarkerIcon(String price) async {
    // Ici, on utilise une icône par défaut, mais dans une app réelle,
    // vous voudriez créer une icône personnalisée avec le prix affiché
    return BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed);
  }

  // Centrer la carte pour afficher toutes les propriétés
  void _centerMapOnProperties(List<Property> properties) {
    if (_mapController == null || properties.isEmpty) return;

    // Trouver les limites pour englober toutes les propriétés
    double minLat = 90, maxLat = -90, minLng = 180, maxLng = -180;

    for (var property in properties) {
      if (property.latitude! < minLat) minLat = property.latitude!;
      if (property.latitude! > maxLat) maxLat = property.latitude!;
      if (property.longitude! < minLng) minLng = property.longitude!;
      if (property.longitude! > maxLng) maxLng = property.longitude!;
    }

    // Ajouter un peu de marge
    double padding = 0.02;
    LatLngBounds bounds = LatLngBounds(
      southwest: LatLng(minLat - padding, minLng - padding),
      northeast: LatLng(maxLat + padding, maxLng + padding),
    );

    // Animer la caméra pour voir toutes les propriétés
    _mapController!.animateCamera(CameraUpdate.newLatLngBounds(bounds, 50));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // La carte Google Maps
          GoogleMap(
            mapType: MapType.normal,
            initialCameraPosition: _initialPosition,
            onMapCreated: (controller) {
              _mapController = controller;
              // Si on a déjà chargé des propriétés, on centre la carte
              if (_properties.isNotEmpty) {
                _centerMapOnProperties(_properties);
              }
            },
            markers: Set<Marker>.of(_markers.values),
            myLocationEnabled: true,
            myLocationButtonEnabled: false,
            zoomControlsEnabled: false,
            mapToolbarEnabled: false,
          ),

          // Bouton retour en arrière
          Positioned(
            top: 50,
            left: 16,
            child: SafeArea(
              child: CircleAvatar(
                backgroundColor: Colors.white,
                radius: 20,
                child: IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.black),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
            ),
          ),

          // Indicateur de chargement
          if (_isLoading)
            const Center(child: CircularProgressIndicator()),

          // Carte de propriété sélectionnée en bas
          if (_selectedProperty != null)
            Positioned(
              bottom: 16,
              left: 16,
              right: 16,
              child: _buildPropertyCard(_selectedProperty!),
            ),
        ],
      ),
      // Bouton pour recentrer la carte
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        child: const Icon(Icons.my_location),
        onPressed: () {
          // Demander la position actuelle et recentrer
          // Ici, on recentre simplement sur la position initiale
          _mapController?.animateCamera(
            CameraUpdate.newCameraPosition(_initialPosition),
          );
        },
      ),
    );
  }

  // Widget pour la carte de propriété en bas de l'écran
  Widget _buildPropertyCard(Property property) {
    return GestureDetector(
      onTap: () {
        // Naviguer vers l'écran de détails
        Navigator.pushNamed(
          context,
          PropertyDetailsScreen.routeName,
          arguments: property,
        );
      },
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              // Image
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: SizedBox(
                  width: 80,
                  height: 80,
                  child: property.imageUrls.isNotEmpty
                      ? Image.network(
                    property.imageUrls[0],
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        color: Colors.grey[300],
                        child: const Icon(Icons.home, size: 30),
                      );
                    },
                  )
                      : Container(
                    color: Colors.grey[300],
                    child: const Icon(Icons.home, size: 30),
                  ),
                ),
              ),

              const SizedBox(width: 12),

              // Informations sur la propriété
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      property.title,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      property.address,
                      style: TextStyle(
                        color: Colors.grey[700],
                        fontSize: 14,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${property.price.toInt()}€/mois',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),

              // Bouton pour fermer la carte
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () {
                  setState(() {
                    _selectedProperty = null;
                  });
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}