// Update lib/screens/student/add_review_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/property.dart';
import '../../models/review.dart';
import '../../models/student.dart';
import '../../services/database_service.dart';
import '../../services/auth_service.dart';
import '../../widgets/common/custom_button.dart';
import '../../config/themes.dart';

class AddReviewScreen extends StatefulWidget {
  static const String routeName = '/property/add-review';
  final Property property;

  const AddReviewScreen({Key? key, required this.property}) : super(key: key);

  @override
  _AddReviewScreenState createState() => _AddReviewScreenState();
}

class _AddReviewScreenState extends State<AddReviewScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _commentController = TextEditingController();
  final DatabaseService _databaseService = DatabaseService();
  bool _isLoading = false;
  double _rating = 5.0;
  bool _isFavorite = false;

  @override
  void initState() {
    super.initState();
    _checkIfFavorite();
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
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
          _isFavorite = student.favoritePropertyIds.contains(
            widget.property.propertyId,
          );
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

      // Show error message
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  Future<void> _submitReview() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      try {
        final authService = Provider.of<AuthService>(context, listen: false);
        final userId = authService.userId;

        if (userId == null) {
          throw Exception('You must be logged in to leave a review');
        }

        print('Starting review submission process');

        // Check if property is in favorites
        if (!_isFavorite) {
          print('Property not in favorites, adding...');
          try {
            // Add to favorites first
            await _databaseService.addFavoriteProperty(userId, widget.property.propertyId);
            _isFavorite = true;
            print('Property added to favorites successfully');
          } catch (e) {
            print('Error adding property to favorites: $e');
            // Continue anyway
          }
        }

        // Get student data for the review
        print('Getting student data...');
        Student? student;
        try {
          student = await _databaseService.getStudent(userId);
          print('Retrieved student: ${student.fullName}');
        } catch (e) {
          print('Error getting student: $e');
          // We'll continue with minimal data
        }

        // Create the review
        print('Creating review object...');
        final review = Review(
          propertyId: widget.property.propertyId,
          studentId: userId,
          ownerId: widget.property.ownerId,
          rating: _rating,
          comment: _commentController.text.trim(),
          studentName: student?.fullName,
          studentPhotoUrl: student?.profilePictureUrl,
        );

        print('Submitting review: ${review.reviewId}');

        // Try our safe method first (handles permissions issues)
        try {
          await _databaseService.createReviewSafe(review);
          print('Review submitted successfully with safe method');
        } catch (safeError) {
          print('Safe method failed: $safeError');

          // Try the simpler fallback as last resort
          try {
            await _databaseService.createReview(review);
            print('Review saved with basic fallback method');
          } catch (basicError) {
            print('Basic fallback also failed: $basicError');
            throw Exception('Could not save review after multiple attempts');
          }
        }

        if (!mounted) return;

        // Show success message and go back
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Your review has been posted'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true); // true indicates that review was added
      } catch (e) {
        print('Final error in _submitReview: $e');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error submitting review: ${e.toString()}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } finally {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Add a Review'), centerTitle: true),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Property info
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: SizedBox(
                              width: 60,
                              height: 60,
                              child:
                                  widget.property.imageUrls.isNotEmpty
                                      ? Image.network(
                                        widget.property.imageUrls[0],
                                        fit: BoxFit.cover,
                                        errorBuilder: (
                                          context,
                                          error,
                                          stackTrace,
                                        ) {
                                          return Container(
                                            color: Colors.grey[300],
                                            child: const Icon(
                                              Icons.home,
                                              size: 30,
                                            ),
                                          );
                                        },
                                      )
                                      : Container(
                                        color: Colors.grey[300],
                                        child: const Icon(Icons.home, size: 30),
                                      ),
                            ),
                          ),
                          title: Text(
                            widget.property.title,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                            ),
                          ),
                          subtitle: Text(
                            widget.property.address,
                            style: TextStyle(color: Colors.grey[700]),
                          ),
                        ),

                        const SizedBox(height: 24),
                        const Divider(),
                        const SizedBox(height: 24),

                        // Favorite check
                        if (!_isFavorite)
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: AppTheme.primaryColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.info, color: AppTheme.primaryColor),
                                const SizedBox(width: 12),
                                const Expanded(
                                  child: Text(
                                    'This property will be added to your favorites when you submit your review.',
                                    style: TextStyle(fontSize: 14),
                                  ),
                                ),
                              ],
                            ),
                          ),

                        const SizedBox(height: 24),

                        // Rating section
                        const Text(
                          'How would you rate this property?',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Star rating
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: List.generate(5, (index) {
                            return GestureDetector(
                              onTap: () {
                                setState(() {
                                  _rating = index + 1.0;
                                });
                              },
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 4,
                                ),
                                child: Icon(
                                  index < _rating
                                      ? Icons.star
                                      : Icons.star_border,
                                  color:
                                      index < _rating
                                          ? AppTheme.primaryColor
                                          : Colors.grey,
                                  size: 40,
                                ),
                              ),
                            );
                          }),
                        ),
                        const SizedBox(height: 8),
                        Center(
                          child: Text(
                            _getRatingDescription(_rating),
                            style: TextStyle(
                              color: Colors.grey[700],
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ),

                        const SizedBox(height: 24),
                        const Divider(),
                        const SizedBox(height: 24),

                        // Review text
                        const Text(
                          'Write your review',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _commentController,
                          decoration: const InputDecoration(
                            hintText:
                                'Share your experience with this property...',
                            border: OutlineInputBorder(),
                          ),
                          maxLines: 5,
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Please write your review';
                            }
                            if (value.trim().length < 10) {
                              return 'Please write a more detailed review';
                            }
                            return null;
                          },
                        ),

                        const SizedBox(height: 32),

                        // Submit button
                        CustomButton(
                          text: 'Submit Review',
                          onPressed: _submitReview,
                          isLoading: _isLoading,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
    );
  }

  String _getRatingDescription(double rating) {
    if (rating >= 5) return 'Excellent';
    if (rating >= 4) return 'Very Good';
    if (rating >= 3) return 'Good';
    if (rating >= 2) return 'Fair';
    return 'Poor';
  }
}
