import 'package:flutter/material.dart';
import '../../models/property.dart';
import '../../config/themes.dart';
import '../../widgets/common/custom_button.dart';

class FilterScreen extends StatefulWidget {
  static const String routeName = '/filters';

  // Paramètres de filtrage actuels
  final double? minPrice;
  final double? maxPrice;
  final int? minBedrooms;
  final int? maxBedrooms;
  final PropertyType? propertyType;

  const FilterScreen({
    Key? key,
    this.minPrice,
    this.maxPrice,
    this.minBedrooms,
    this.maxBedrooms,
    this.propertyType,
  }) : super(key: key);

  @override
  _FilterScreenState createState() => _FilterScreenState();
}

class _FilterScreenState extends State<FilterScreen> {
  // Valeurs des filtres
  double _minPrice = 0;
  double _maxPrice = 2000;
  RangeValues _priceRange = const RangeValues(0, 2000);
  int _minBedrooms = 0;
  int _maxBedrooms = 5;
  PropertyType? _selectedPropertyType;

  // Liste des types de propriétés pour le filtrage
  final List<PropertyTypeOption> _propertyTypes = [
    PropertyTypeOption(type: null, label: 'Tous les types'),
    PropertyTypeOption(type: PropertyType.apartment, label: 'Appartement'),
    PropertyTypeOption(type: PropertyType.studio, label: 'Studio'),
    PropertyTypeOption(type: PropertyType.house, label: 'Maison'),
    PropertyTypeOption(type: PropertyType.sharedRoom, label: 'Chambre partagée'),
    PropertyTypeOption(type: PropertyType.singleRoom, label: 'Chambre privée'),
    PropertyTypeOption(type: PropertyType.dormitory, label: 'Résidence universitaire'),
  ];

  @override
  void initState() {
    super.initState();

    // Initialiser les valeurs à partir des filtres actuels
    if (widget.minPrice != null) _minPrice = widget.minPrice!;
    if (widget.maxPrice != null) _maxPrice = widget.maxPrice!;
    _priceRange = RangeValues(_minPrice, _maxPrice);

    if (widget.minBedrooms != null) _minBedrooms = widget.minBedrooms!;
    if (widget.maxBedrooms != null) _maxBedrooms = widget.maxBedrooms!;

    _selectedPropertyType = widget.propertyType;
  }

  void _applyFilters() {
    // Retourner les filtres sélectionnés
    Navigator.pop(
      context,
      FilterResult(
        minPrice: _minPrice,
        maxPrice: _maxPrice,
        minBedrooms: _minBedrooms,
        maxBedrooms: _maxBedrooms,
        propertyType: _selectedPropertyType,
      ),
    );
  }

  void _resetFilters() {
    setState(() {
      _minPrice = 0;
      _maxPrice = 2000;
      _priceRange = const RangeValues(0, 2000);
      _minBedrooms = 0;
      _maxBedrooms = 5;
      _selectedPropertyType = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Filtres'),
        centerTitle: true,
        actions: [
          TextButton(
            onPressed: _resetFilters,
            child: const Text('Réinitialiser'),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Filtre de prix
              const Text(
                'Fourchette de prix',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Prix mensuel entre ${_priceRange.start.toInt()}€ et ${_priceRange.end.toInt()}€',
                style: TextStyle(
                  color: Colors.grey[700],
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 8),
              RangeSlider(
                values: _priceRange,
                min: 0,
                max: 2000,
                divisions: 40, // 50€ par division
                labels: RangeLabels(
                  '${_priceRange.start.toInt()}€',
                  '${_priceRange.end.toInt()}€',
                ),
                onChanged: (values) {
                  setState(() {
                    _priceRange = values;
                    _minPrice = values.start;
                    _maxPrice = values.end;
                  });
                },
                activeColor: AppTheme.primaryColor,
                inactiveColor: Colors.grey[300],
              ),

              const Divider(height: 32),

              // Filtre de nombre de chambres
              const Text(
                'Nombre de chambres',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),

              // Sélecteur de chambres (min)
              Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Minimum',
                      style: TextStyle(fontSize: 16),
                    ),
                  ),
                  Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.remove),
                          onPressed: _minBedrooms > 0
                              ? () {
                            setState(() {
                              _minBedrooms--;
                            });
                          }
                              : null,
                        ),
                        Text(
                          '$_minBedrooms',
                          style: const TextStyle(fontSize: 16),
                        ),
                        IconButton(
                          icon: const Icon(Icons.add),
                          onPressed: _minBedrooms < _maxBedrooms
                              ? () {
                            setState(() {
                              _minBedrooms++;
                            });
                          }
                              : null,
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Sélecteur de chambres (max)
              Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Maximum',
                      style: TextStyle(fontSize: 16),
                    ),
                  ),
                  Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.remove),
                          onPressed: _maxBedrooms > _minBedrooms
                              ? () {
                            setState(() {
                              _maxBedrooms--;
                            });
                          }
                              : null,
                        ),
                        Text(
                          '$_maxBedrooms',
                          style: const TextStyle(fontSize: 16),
                        ),
                        IconButton(
                          icon: const Icon(Icons.add),
                          onPressed: _maxBedrooms < 5
                              ? () {
                            setState(() {
                              _maxBedrooms++;
                            });
                          }
                              : null,
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const Divider(height: 32),

              // Filtre de type de propriété
              const Text(
                'Type de logement',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),

              // Liste des types de propriétés
              ..._propertyTypes.map((option) => RadioListTile<PropertyType?>(
                title: Text(option.label),
                value: option.type,
                groupValue: _selectedPropertyType,
                activeColor: AppTheme.primaryColor,
                onChanged: (value) {
                  setState(() {
                    _selectedPropertyType = value;
                  });
                },
              )),

              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: CustomButton(
            text: 'Afficher les résultats',
            onPressed: _applyFilters,
          ),
        ),
      ),
    );
  }
}

// Classe pour structurer les options de type de propriété
class PropertyTypeOption {
  final PropertyType? type;
  final String label;

  PropertyTypeOption({
    required this.type,
    required this.label,
  });
}

// Classe pour stocker les résultats des filtres
class FilterResult {
  final double minPrice;
  final double maxPrice;
  final int minBedrooms;
  final int maxBedrooms;
  final PropertyType? propertyType;

  FilterResult({
    required this.minPrice,
    required this.maxPrice,
    required this.minBedrooms,
    required this.maxBedrooms,
    this.propertyType,
  });
}

