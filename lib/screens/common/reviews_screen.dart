import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../models/review.dart';
import '../../models/property.dart';
import '../../services/auth_service.dart';
import '../../services/database_service.dart';
import '../../config/themes.dart';
import '../student/add_review_screen.dart';

class ReviewsScreen extends StatefulWidget {
  static const String routeName = '/property/reviews';
  final Property property;

  const ReviewsScreen({
    super.key,
    required this.property,
  });

  @override
  _ReviewsScreenState createState() => _ReviewsScreenState();
}

class _ReviewsScreenState extends State<ReviewsScreen> {
  final DatabaseService _databaseService = DatabaseService();
  bool _isLoading = true;
  List<Review> _reviews = [];
  double _averageRating = 0.0;
  Map<int, int> _ratingDistribution = {5: 0, 4: 0, 3: 0, 2: 0, 1: 0};

  @override
  void initState() {
    super.initState();
    _loadReviews();
  }

  Future<void> _loadReviews() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Get reviews with robust method
      final reviews = await _databaseService.getReviewsByPropertyRobust(widget.property.propertyId);

      // Calculate average rating manually
      double averageRating = 0.0;
      if (reviews.isNotEmpty) {
        double totalRating = 0.0;
        for (var review in reviews) {
          totalRating += review.rating;
        }
        averageRating = totalRating / reviews.length;
      }

      // Calculate rating distribution
      Map<int, int> distribution = {5: 0, 4: 0, 3: 0, 2: 0, 1: 0};
      for (var review in reviews) {
        int rating = review.rating.round();
        if (distribution.containsKey(rating)) {
          distribution[rating] = distribution[rating]! + 1;
        }
      }

      setState(() {
        _reviews = reviews;
        _ratingDistribution = distribution;
        _averageRating = averageRating;
        _isLoading = false;
      });

      print('Reviews loaded: ${reviews.length}, Average rating: $averageRating');
    } catch (e) {
      print('Error loading reviews: $e');
      setState(() {
        _reviews = [];
        _ratingDistribution = {5: 0, 4: 0, 3: 0, 2: 0, 1: 0};
        _averageRating = 0.0;
        _isLoading = false;
      });

      // Show error message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error loading reviews: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Reviews'),
        centerTitle: true,
        actions: [
          // Add a refresh button
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _isLoading ? null : _loadReviews,
            tooltip: 'Refresh reviews',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
        onRefresh: _loadReviews,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header with average rating
                Row(
                  children: [
                    const Icon(Icons.star, color: Colors.amber, size: 30),
                    const SizedBox(width: 8),
                    Text(
                      _averageRating.toStringAsFixed(2),
                      style: const TextStyle(
                        fontSize: 30,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      ' · ${_reviews.length} ${_reviews.length == 1 ? 'review' : 'reviews'}',
                      style: TextStyle(
                        fontSize: 20,
                        color: Colors.grey[700],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Rating distribution
                if (_reviews.isNotEmpty) ...[
                  _buildRatingBar(5),
                  const SizedBox(height: 8),
                  _buildRatingBar(4),
                  const SizedBox(height: 8),
                  _buildRatingBar(3),
                  const SizedBox(height: 8),
                  _buildRatingBar(2),
                  const SizedBox(height: 8),
                  _buildRatingBar(1),

                  const SizedBox(height: 24),
                  const Divider(),
                  const SizedBox(height: 24),
                ],

                // Reviews list or empty state
                _reviews.isEmpty
                    ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.rate_review_outlined,
                        size: 80,
                        color: Colors.grey[400],
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'No reviews yet',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Be the first to review this property',
                        style: TextStyle(color: Colors.grey),
                      ),
                      const SizedBox(height: 24),
                      if (Provider.of<AuthService>(context).isStudent)
                        ElevatedButton.icon(
                          onPressed: () {
                            Navigator.pushNamed(
                              context,
                              AddReviewScreen.routeName,
                              arguments: widget.property,
                            ).then((_) => _loadReviews());
                          },
                          icon: const Icon(Icons.rate_review),
                          label: const Text('Write a review'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primaryColor,
                          ),
                        ),
                    ],
                  ),
                )
                    : ListView.separated(
                  physics: const NeverScrollableScrollPhysics(),
                  shrinkWrap: true,
                  itemCount: _reviews.length,
                  separatorBuilder: (context, index) => const Divider(height: 40),
                  itemBuilder: (context, index) {
                    final review = _reviews[index];
                    return _buildReviewItem(review);
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRatingBar(int rating) {
    int count = _ratingDistribution[rating] ?? 0;
    double percentage = _reviews.isEmpty ? 0 : count / _reviews.length;

    return Row(
      children: [
        SizedBox(
          width: 25,
          child: Text(
            '$rating',
            style: const TextStyle(fontSize: 16),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: percentage,
              backgroundColor: Colors.grey[300],
              valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryColor),
              minHeight: 8,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildReviewItem(Review review) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // En-tête de l'avis avec photo et nom
        Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
              ),
              clipBehavior: Clip.antiAlias,
              child: review.studentPhotoUrl != null
                  ? Image.network(
                review.studentPhotoUrl!,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    color: Colors.grey[300],
                    child: const Icon(Icons.person, size: 24),
                  );
                },
              )
                  : Container(
                color: Colors.grey[300],
                child: const Icon(Icons.person, size: 24),
              ),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  review.studentName ?? 'Student',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                Text(
                  DateFormat('MMMM yyyy', 'en_US').format(review.reviewDate),
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 12),

        // Note en étoiles
        Row(
          children: List.generate(5, (index) {
            return Icon(
              index < review.rating ? Icons.star : Icons.star_border,
              color: index < review.rating ? AppTheme.primaryColor : Colors.grey,
              size: 18,
            );
          }),
        ),
        const SizedBox(height: 8),

        // Commentaire
        Text(
          review.comment,
          style: const TextStyle(
            fontSize: 16,
            height: 1.5,
          ),
        ),
      ],
    );
  }
}

