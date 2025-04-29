import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/property.dart';
import '../../models/owner.dart';
import '../../services/database_service.dart';
import '../../services/auth_service.dart';
import '../../widgets/common/custom_button.dart';
import 'add_property_screen.dart';
import '../common/property_details_screen.dart';
import '../../models/application.dart';
import '../../config/themes.dart';

class OwnerHomeScreen extends StatefulWidget {
  static const String routeName = '/owner/home';

  const OwnerHomeScreen({Key? key}) : super(key: key);

  @override
  _OwnerHomeScreenState createState() => _OwnerHomeScreenState();
}

class _OwnerHomeScreenState extends State<OwnerHomeScreen> {
  final DatabaseService _databaseService = DatabaseService();
  int _currentTabIndex = 0;

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
            icon: Icon(Icons.home),
            label: 'My Properties',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.article_outlined),
            label: 'Requests',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.message_outlined),
            label: 'Messages',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            label: 'Profile',
          ),
        ],
      ),
      // Button to add a new property
      floatingActionButton: _currentTabIndex == 0
          ? FloatingActionButton(
        onPressed: () async {
          final result = await Navigator.pushNamed(context, AddPropertyScreen.routeName);
          if (result == true) {
            // Refresh the properties list if a new property was added
            setState(() {});
          }
        },
        backgroundColor: AppTheme.primaryColor,
        child: const Icon(Icons.add),
      )
          : null,
    );
  }

  Widget _buildCurrentTab() {
    switch (_currentTabIndex) {
      case 0:
        return _buildPropertiesTab();
      case 1:
        return _buildApplicationsTab();
      case 2:
        return _buildMessagesTab();
      case 3:
        return _buildProfileTab();
      default:
        return _buildPropertiesTab();
    }
  }

  Widget _buildPropertiesTab() {
    return SafeArea(
      child: FutureBuilder<List<Property>>(
        future: _loadOwnerProperties(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(
              child: Text('Error: ${snapshot.error}'),
            );
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.home_work,
                      size: 80,
                      color: Colors.grey[400],
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'No properties yet',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Start by adding your first property',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.grey,
                      ),
                    ),
                    const SizedBox(height: 32),
                    CustomButton(
                      text: 'Add a property',
                      onPressed: () {
                        Navigator.pushNamed(context, AddPropertyScreen.routeName)
                            .then((_) => setState(() {})); // Refresh on return
                      },
                      icon: Icons.add,
                    ),
                  ],
                ),
              ),
            );
          } else {
            final properties = snapshot.data!;
            return CustomScrollView(
              slivers: [
                // Header
                SliverAppBar(
                  title: const Text('My Properties'),
                  centerTitle: true,
                  floating: true,
                  snap: true,
                ),
                // Properties list
                SliverPadding(
                  padding: const EdgeInsets.all(16),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                          (context, index) {
                        final property = properties[index];
                        return _buildPropertyCard(property);
                      },
                      childCount: properties.length,
                    ),
                  ),
                ),
              ],
            );
          }
        },
      ),
    );
  }

  Widget _buildPropertyCard(Property property) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      elevation: 2,
      child: InkWell(
        onTap: () {
          Navigator.pushNamed(
            context,
            PropertyDetailsScreen.routeName,
            arguments: property,
          ).then((_) => setState(() {})); // Refresh on return
        },
        borderRadius: BorderRadius.circular(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Property image
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
              child: AspectRatio(
                aspectRatio: 16 / 9,
                child: property.imageUrls.isNotEmpty
                    ? Image.network(
                  property.imageUrls[0],
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      color: Colors.grey[300],
                      child: const Center(
                        child: Icon(Icons.image_not_supported, size: 50),
                      ),
                    );
                  },
                )
                    : Container(
                  color: Colors.grey[300],
                  child: const Center(
                    child: Icon(Icons.home, size: 50),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title and status
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          property.title,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: property.isAvailable
                              ? Colors.green.withOpacity(0.1)
                              : Colors.red.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          property.isAvailable ? 'Available' : 'Unavailable',
                          style: TextStyle(
                            color: property.isAvailable
                                ? Colors.green[800]
                                : Colors.red[800],
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  // Address
                  Text(
                    property.address,
                    style: TextStyle(
                      color: Colors.grey[600],
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  // Features
                  Row(
                    children: [
                      Icon(Icons.euro, size: 16, color: Colors.grey[600]),
                      const SizedBox(width: 4),
                      Text(
                        '${property.price.toInt()} / month',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.grey[700],
                        ),
                      ),
                      const SizedBox(width: 16),
                      Icon(Icons.bed, size: 16, color: Colors.grey[600]),
                      const SizedBox(width: 4),
                      Text(
                        '${property.bedrooms}',
                        style: TextStyle(
                          color: Colors.grey[700],
                        ),
                      ),
                      const SizedBox(width: 16),
                      Icon(Icons.bathtub, size: 16, color: Colors.grey[600]),
                      const SizedBox(width: 4),
                      Text(
                        '${property.bathrooms}',
                        style: TextStyle(
                          color: Colors.grey[700],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // Actions
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildActionButton(
                        icon: Icons.edit,
                        label: 'Edit',
                        onTap: () {
                          // Navigate to edit screen
                          // Will implement in a future update
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Edit functionality coming soon')),
                          );
                        },
                      ),
                      _buildActionButton(
                        icon: property.isAvailable
                            ? Icons.visibility_off
                            : Icons.visibility,
                        label: property.isAvailable
                            ? 'Hide'
                            : 'Publish',
                        onTap: () {
                          _togglePropertyAvailability(property);
                        },
                      ),
                      _buildActionButton(
                        icon: Icons.delete,
                        label: 'Delete',
                        color: Colors.red,
                        onTap: () {
                          _showDeleteConfirmation(property);
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    Color? color,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 8,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: color ?? Colors.grey[700],
              size: 18,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: color ?? Colors.grey[700],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showDeleteConfirmation(Property property) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete this property?'),
        content: const Text(
            'This action cannot be undone. All associated applications will also be deleted.'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _deleteProperty(property.propertyId);
            },
            child: const Text(
              'Delete',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteProperty(String propertyId) async {
    try {
      await _databaseService.deleteProperty(propertyId);
      // Refresh the screen
      setState(() {});

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Property deleted successfully'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error deleting property: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _togglePropertyAvailability(Property property) async {
    try {
      // Update property availability
      Property updatedProperty = property.copyWith(
        isAvailable: !property.isAvailable,
      );

      await _databaseService.updateProperty(updatedProperty);

      // Refresh the screen
      setState(() {});

      // Show success notification
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            updatedProperty.isAvailable
                ? 'Your property is now visible'
                : 'Your property is now hidden',
          ),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error updating property: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Widget _buildApplicationsTab() {
    return FutureBuilder<List<RentalApplication>>(
      future: _loadOwnerApplications(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          return Center(
            child: Text('Error: ${snapshot.error}'),
          );
        } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.article_outlined,
                  size: 80,
                  color: Colors.grey[400],
                ),
                const SizedBox(height: 16),
                const Text(
                  'No applications yet',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Rental applications will appear here',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          );
        } else {
          // Display rental applications
          return Center(
            child: Text('${snapshot.data!.length} applications received'),
          );
        }
      },
    );
  }

  Widget _buildMessagesTab() {
    // Message tab implementation
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.message_outlined,
            size: 80,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          const Text(
            'No messages yet',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Your messages will appear here',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.grey,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileTab() {
    // Owner profile tab
    return FutureBuilder<String?>(
      future: _getUserId(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError || !snapshot.hasData) {
          return const Center(
            child: Text('Error loading profile'),
          );
        } else {
          final userId = snapshot.data!;
          return FutureBuilder<Owner>(
            future: _databaseService.getOwner(userId),
            builder: (context, ownerSnapshot) {
              if (ownerSnapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              } else if (ownerSnapshot.hasError) {
                return Center(
                  child: Text('Error: ${ownerSnapshot.error}'),
                );
              } else if (!ownerSnapshot.hasData) {
                return const Center(
                  child: Text('No data found'),
                );
              } else {
                final owner = ownerSnapshot.data!;
                return SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      const SizedBox(height: 24),
                      Stack(
                        children: [
                          CircleAvatar(
                            radius: 60,
                            backgroundColor: Colors.grey[300],
                            backgroundImage: owner.profilePictureUrl != null
                                ? NetworkImage(owner.profilePictureUrl!)
                                : null,
                            child: owner.profilePictureUrl == null
                                ? const Icon(
                              Icons.person,
                              size: 60,
                              color: Colors.grey,
                            )
                                : null,
                          ),
                          if (owner.isVerifiedOwner)
                            Positioned(
                              bottom: 0,
                              right: 0,
                              child: Container(
                                padding: const EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                  color: Colors.blue,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: Colors.white,
                                    width: 2,
                                  ),
                                ),
                                child: const Icon(
                                  Icons.verified,
                                  color: Colors.white,
                                  size: 20,
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        owner.fullName,
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        owner.email,
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey[600],
                        ),
                      ),
                      if (owner.rating > 0)
                        Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(
                                Icons.star,
                                color: Colors.amber,
                                size: 18,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '${owner.rating.toStringAsFixed(1)} / 5.0',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      const SizedBox(height: 32),
                      const Divider(),

                      // Verification status
                      ListTile(
                        leading: Icon(
                          owner.isVerifiedOwner
                              ? Icons.verified
                              : Icons.pending,
                          color: owner.isVerifiedOwner
                              ? Colors.blue
                              : Colors.amber,
                        ),
                        title: const Text('Verification status'),
                        subtitle: Text(
                          owner.isVerifiedOwner
                              ? 'Verified owner'
                              : 'Verification pending',
                        ),
                        trailing: owner.isVerifiedOwner
                            ? null
                            : TextButton(
                          onPressed: () {
                            // Navigate to verification screen
                            Navigator.pushNamed(
                              context,
                              '/owner/profile-setup',
                            ).then((_) => setState(() {}));
                          },
                          child: const Text('Complete'),
                        ),
                      ),

                      // Property count
                      FutureBuilder<List<Property>>(
                        future: _loadOwnerProperties(),
                        builder: (context, snapshot) {
                          int propertyCount = snapshot.hasData
                              ? snapshot.data!.length
                              : 0;
                          return ListTile(
                            leading: const Icon(Icons.home_work),
                            title: const Text('Properties'),
                            subtitle: Text('$propertyCount property${propertyCount > 1 || propertyCount == 0 ? 'ies' : 'y'}'),
                          );
                        },
                      ),

                      // Phone
                      ListTile(
                        leading: const Icon(Icons.phone),
                        title: const Text('Phone'),
                        subtitle: Text(owner.phoneNumber),
                      ),

                      const SizedBox(height: 16),
                      const Divider(),
                      const SizedBox(height: 16),

                      // Logout button
                      CustomButton(
                        text: 'Log out',
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

  Future<List<Property>> _loadOwnerProperties() async {
    final authService = Provider.of<AuthService>(context, listen: false);
    final userId = authService.userId;

    if (userId == null) {
      return [];
    }

    return await _databaseService.getPropertiesByOwner(userId);
  }

  Future<List<RentalApplication>> _loadOwnerApplications() async {
    final authService = Provider.of<AuthService>(context, listen: false);
    final userId = authService.userId;

    if (userId == null) {
      return [];
    }

    return await _databaseService.getApplicationsByOwner(userId);
  }
}