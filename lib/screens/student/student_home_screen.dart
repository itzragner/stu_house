import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/property.dart';
import '../../services/database_service.dart';
import '../../services/auth_service.dart';
import '../../widgets/common/custom_button.dart';
import '../../widgets/property/property_card.dart';
import '../../widgets/common/custom_search_bar.dart';
import '../../widgets/common/category_filter.dart';
import 'search_screen.dart';
import 'map_screen.dart';
import 'favorites_screen.dart';
import '../common/property_details_screen.dart';
import '../../models/student.dart';

class StudentHomeScreen extends StatefulWidget {
  static const String routeName = '/student/home';

  const StudentHomeScreen({Key? key}) : super(key: key);

  @override
  _StudentHomeScreenState createState() => _StudentHomeScreenState();
}

class _StudentHomeScreenState extends State<StudentHomeScreen> {
  final DatabaseService _databaseService = DatabaseService();
  List<Property> _properties = [];
  bool _isLoading = true;
  String _selectedCategory = 'Tous';
  int _currentTabIndex = 0;

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
      // Rechercher des propriétés sans filtres spécifiques initialement
      final properties = await _databaseService.searchProperties(
        availableOnly: true,
      );

      setState(() {
        _properties = properties;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading properties: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _filterProperties(String category) async {
    setState(() {
      _selectedCategory = category;
      _isLoading = true;
    });

    try {
      // Rechercher des propriétés par type (si nécessaire)
      PropertyType? filterType;
      if (category != 'Tous') {
        switch (category.toLowerCase()) {
          case 'appartement':
            filterType = PropertyType.apartment;
            break;
          case 'studio':
            filterType = PropertyType.studio;
            break;
          case 'chambre':
            filterType = PropertyType.singleRoom;
            break;
          case 'colocation':
            filterType = PropertyType.sharedRoom;
            break;
          case 'maison':
            filterType = PropertyType.house;
            break;
        }
      }

      final properties = await _databaseService.searchProperties(
        availableOnly: true,
        propertyType: filterType,
      );

      setState(() {
        _properties = properties;
        _isLoading = false;
      });
    } catch (e) {
      print('Error filtering properties: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _navigateToSearch() {
    Navigator.pushNamed(context, SearchScreen.routeName);
  }

  void _navigateToMap() {
    Navigator.pushNamed(context, MapScreen.routeName);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _buildCurrentTab(),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentTabIndex,
        onTap: (index) {
          setState(() {
            _currentTabIndex = index;
          });
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.search),
            label: 'Explorer',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.favorite_border),
            label: 'Favoris',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.article_outlined),
            label: 'Demandes',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.message_outlined),
            label: 'Messages',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            label: 'Profil',
          ),
        ],
      ),
    );
  }

  Widget _buildCurrentTab() {
    switch (_currentTabIndex) {
      case 0:
        return _buildExploreTab();
      case 1:
        return const FavoritesScreen();
      case 2:
        return _buildApplicationsTab();
      case 3:
        return _buildMessagesTab();
      case 4:
        return _buildProfileTab();
      default:
        return _buildExploreTab();
    }
  }

  Widget _buildExploreTab() {
    return SafeArea(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: CustomSearchBar(
              hint: 'Où étudier?',
              onTap: _navigateToSearch,
            ),
          ),
          CategoryFilter(
            categories: const [
              'Tous',
              'Appartement',
              'Studio',
              'Chambre',
              'Colocation',
              'Maison',
            ],
            selectedCategory: _selectedCategory,
            onCategorySelected: (category) {
              _filterProperties(category);
            },
          ),
          // Bouton pour basculer en vue carte
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: ElevatedButton.icon(
              onPressed: _navigateToMap,
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
          const SizedBox(height: 8),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _properties.isEmpty
                ? const Center(
              child: Text('Aucun logement disponible pour le moment.'),
            )
                : RefreshIndicator(
              onRefresh: _loadProperties,
              child: ListView.builder(
                padding: const EdgeInsets.only(top: 8),
                itemCount: _properties.length,
                itemBuilder: (context, index) {
                  final property = _properties[index];
                  return PropertyCard(
                    property: property,
                    onTap: () {
                      Navigator.pushNamed(
                        context,
                        PropertyDetailsScreen.routeName,
                        arguments: property,
                      ).then((_) {
                        // Refresh when returning from details
                        _loadProperties();
                      });
                    },
                    onFavoriteToggle: (isFavorite) async {
                      final authService = Provider.of<AuthService>(
                        context,
                        listen: false,
                      );
                      final userId = authService.userId;

                      if (userId != null) {
                        try {
                          if (isFavorite) {
                            await _databaseService.addFavoriteProperty(
                              userId,
                              property.propertyId,
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
                              property.propertyId,
                            );
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Retiré des favoris'),
                                duration: Duration(seconds: 2),
                              ),
                            );
                          }
                        } catch (e) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Erreur: ${e.toString()}'),
                              duration: const Duration(seconds: 2),
                            ),
                          );
                        }
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Connectez-vous pour ajouter des favoris'),
                            duration: Duration(seconds: 2),
                          ),
                        );
                      }
                    },
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildApplicationsTab() {
    // À implémenter : affichage des candidatures de l'étudiant
    return const Center(
      child: Text('Vos demandes de location apparaîtront ici'),
    );
  }

  Widget _buildMessagesTab() {
    // À implémenter : affichage des messages
    return const Center(
      child: Text('Vos messages apparaîtront ici'),
    );
  }

  Widget _buildProfileTab() {
    // Affichage du profil étudiant
    return FutureBuilder<String?>(
      future: _getUserId(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError || !snapshot.hasData) {
          return const Center(
            child: Text('Erreur lors du chargement du profil'),
          );
        } else {
          final userId = snapshot.data!;
          return FutureBuilder<Student>(
            future: _databaseService.getStudent(userId),
            builder: (context, studentSnapshot) {
              if (studentSnapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              } else if (studentSnapshot.hasError) {
                return Center(
                  child: Text('Erreur: ${studentSnapshot.error}'),
                );
              } else if (!studentSnapshot.hasData) {
                return const Center(
                  child: Text('Aucune donnée trouvée'),
                );
              } else {
                final student = studentSnapshot.data!;
                return SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      const SizedBox(height: 24),
                      CircleAvatar(
                        radius: 60,
                        backgroundColor: Colors.grey[300],
                        backgroundImage: student.profilePictureUrl != null
                            ? NetworkImage(student.profilePictureUrl!)
                            : null,
                        child: student.profilePictureUrl == null
                            ? const Icon(
                          Icons.person,
                          size: 60,
                          color: Colors.grey,
                        )
                            : null,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        student.fullName,
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        student.email,
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 32),
                      const Divider(),

                      // Université
                      ListTile(
                        leading: const Icon(Icons.school),
                        title: const Text('Université'),
                        subtitle: Text(student.universityName ?? 'Non spécifié'),
                      ),

                      // Numéro étudiant
                      ListTile(
                        leading: const Icon(Icons.badge),
                        title: const Text('Numéro étudiant'),
                        subtitle: Text(student.studentId ?? 'Non spécifié'),
                      ),

                      // Date de fin d'études
                      ListTile(
                        leading: const Icon(Icons.calendar_today),
                        title: const Text('Fin d\'études prévue'),
                        subtitle: Text(
                          student.endOfStudies != null
                              ? '${student.endOfStudies!.day}/${student.endOfStudies!.month}/${student.endOfStudies!.year}'
                              : 'Non spécifié',
                        ),
                      ),

                      const SizedBox(height: 16),
                      const Divider(),
                      const SizedBox(height: 16),

                      // Bouton de déconnexion
                      CustomButton(
                        text: 'Déconnexion',
                        onPressed: () async {
                          await Provider.of<AuthService>(
                            context,
                            listen: false,
                          ).signOut();

                          Navigator.pushReplacementNamed(
                            context,
                            '/login',
                          );
                        },
                        isOutlined: true,
                      ),
                    ],
                  ),
                );
              }
            },
          );
        }
      },
    );
  }

  Future<String?> _getUserId() async {
    final authService = Provider.of<AuthService>(context, listen: false);
    return authService.userId;
  }
}