import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/property.dart';
import '../../models/review.dart';
import '../../services/database_service.dart';
import '../../services/auth_service.dart';
import '../../widgets/common/custom_button.dart';
import '../../config/themes.dart';

class AddReviewScreen extends StatefulWidget {
  static const String routeName = '/property/add-review';
  final Property property;

  const AddReviewScreen({
    Key? key,
    required this.property,
  }) : super(key: key);

  @override
  _AddReviewScreenState createState() => _AddReviewScreenState();
}

class _AddReviewScreenState extends State<AddReviewScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _commentController = TextEditingController();
  final DatabaseService _databaseService = DatabaseService();
  bool _isLoading = false;
  double _rating = 5.0;

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
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
          throw Exception('Vous devez être connecté pour laisser un avis');
        }

        // Récupérer l'étudiant pour le nom et la photo
        final student = await _databaseService.getStudent(userId);

        // Créer l'avis
        final review = Review(
          propertyId: widget.property.propertyId,
          studentId: userId,
          ownerId: widget.property.ownerId,
          rating: _rating,
          comment: _commentController.text.trim(),
          studentName: student.fullName,
          studentPhotoUrl: student.profilePictureUrl,
        );

        // Enregistrer l'avis dans Firebase
        await _databaseService.createReview(review);

        // Mettre à jour la note moyenne de la propriété
        await _databaseService.updatePropertyRating(widget.property.propertyId);

        if (!mounted) return;

        // Afficher un message de succès et revenir à l'écran précédent
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Votre avis a été publié')),
        );
        Navigator.pop(context, true); // true indique que l'avis a été ajouté
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: ${e.toString()}')),
        );
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
      appBar: AppBar(
        title: const Text('Ajouter un avis'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // En-tête avec informations sur la propriété
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: SizedBox(
                      width: 60,
                      height: 60,
                      child: widget.property.imageUrls.isNotEmpty
                          ? Image.network(
                        widget.property.imageUrls[0],
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
                  title: Text(
                    widget.property.title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                  subtitle: Text(
                    widget.property.address,
                    style: TextStyle(
                      color: Colors.grey[700],
                    ),
                  ),
                ),

                const SizedBox(height: 24),
                const Divider(),
                const SizedBox(height: 24),

                // Sélection de la note
                const Text(
                  'Quelle note donnez-vous à ce logement ?',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),

                // Affichage des étoiles
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
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: Icon(
                          index < _rating ? Icons.star : Icons.star_border,
                          color: index < _rating ? AppTheme.primaryColor : Colors.grey,
                          size: 40,
                        ),
                      ),
                    );
                  }),
                ),

                const SizedBox(height: 24),
                const Divider(),
                const SizedBox(height: 24),

                // Commentaire d'avis
                const Text(
                  'Partagez votre expérience avec ce logement',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _commentController,
                  decoration: const InputDecoration(
                    hintText: 'Qu\'avez-vous aimé ou moins aimé ?',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 5,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Veuillez partager votre expérience';
                    }
                    if (value.trim().length < 10) {
                      return 'Veuillez écrire un commentaire plus détaillé';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 32),

                // Bouton de soumission
                _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : CustomButton(
                  text: 'Publier mon avis',
                  onPressed: _submitReview,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}