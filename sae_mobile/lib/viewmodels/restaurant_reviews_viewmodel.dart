import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:google_fonts/google_fonts.dart';

class RestaurantReviewsViewModel {
  final int restaurantId;
  List<Map<String, dynamic>> reviews;
  final bool hasUserReviewed;
  final Map<String, dynamic>? userReview;
  final VoidCallback onReviewUpdated;
  final Color goldColor;
  final Color darkBackgroundColor;

  RestaurantReviewsViewModel({
    required this.restaurantId,
    required this.reviews,
    required this.hasUserReviewed,
    required this.userReview,
    required this.onReviewUpdated,
    required this.goldColor,
    required this.darkBackgroundColor,
  }) {
    _initializeSortedReviews();
  }

  List<Map<String, dynamic>> get sortedReviews => List.from(reviews);

  Future<int> _getUserId() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) throw Exception('Utilisateur non connecté');
    final response = await Supabase.instance.client
        .from('utilisateur')
        .select('idutilisateur')
        .eq('emailutilisateur', user.email!)
        .single();
    return response['idutilisateur'] as int;
  }

  void _showSnackBar(BuildContext context, String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 1),
        backgroundColor: isError ? Colors.red : null,
      ),
    );
  }

  void _initializeSortedReviews() {
    final user = Supabase.instance.client.auth.currentUser;
    if (user != null && reviews.isNotEmpty) {
      Future.microtask(() async {
        try {
          final currentUserId = await _getUserId();
          final userReviewIndex = reviews.indexWhere(
            (review) => review['utilisateur']['idutilisateur'] == (currentUserId ?? userReview?['utilisateur']?['idutilisateur']),
          );
          if (userReviewIndex != -1) {
            final userReviewItem = reviews.removeAt(userReviewIndex);
            reviews.insert(0, userReviewItem);
          }
        } catch (e) {
          // Pas d'action nécessaire ici
        }
      });
    }
  }

  bool isCurrentUserReview(Map<String, dynamic> review) {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return false;
    return review['utilisateur']['idutilisateur'] == (userReview?['utilisateur']?['idutilisateur']);
  }

  void handleAddReview(BuildContext context) {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) {
      _showSnackBar(context, 'Vous devez être connecté pour laisser un avis', isError: true);
      return;
    }
    _showReviewDialog(context);
  }

  void _showReviewDialog(BuildContext context) {
    final formKey = GlobalKey<FormBuilderState>();
    int rating = hasUserReviewed ? userReview!['notecritique'] : 0;
    final initialComment = hasUserReviewed ? userReview!['commentairecritique'] : '';

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        contentPadding: const EdgeInsets.all(16.0),
        content: SizedBox(
          width: double.maxFinite,
          height: MediaQuery.of(context).size.height * 0.5,
          child: SingleChildScrollView(
            child: FormBuilder(
              key: formKey,
              child: StatefulBuilder(
                builder: (dialogContext, setState) => Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(hasUserReviewed ? 'Modifier avis' : 'Laisser un avis',
                        style: GoogleFonts.raleway(
                            fontWeight: FontWeight.bold, fontSize: 18, color: darkBackgroundColor)),
                    const SizedBox(height: 16),
                    Text('Notez le restaurant', style: GoogleFonts.raleway(fontSize: 16)),
                    const SizedBox(height: 8),
                    FormBuilderField<int>(
                      name: 'rating',
                      initialValue: rating,
                      validator: (value) => value == null || value == 0 ? 'Veuillez sélectionner une note' : null,
                      builder: (field) => Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: List.generate(5, (index) => IconButton(
                                  icon: Icon(
                                    index < (field.value ?? 0) ? Icons.star : Icons.star_border,
                                    color: goldColor,
                                    size: 20,
                                  ),
                                  onPressed: () {
                                    setState(() {
                                      rating = index + 1;
                                      field.didChange(rating);
                                    });
                                  },
                                )),
                          ),
                          if (field.hasError)
                            Padding(
                              padding: const EdgeInsets.only(top: 4.0),
                              child: Text(field.errorText!, style: const TextStyle(color: Colors.red, fontSize: 12)),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    FormBuilderTextField(
                      name: 'comment',
                      initialValue: initialComment,
                      maxLines: 3,
                      decoration: InputDecoration(
                        labelText: 'Votre commentaire',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      validator: (value) => value == null || value.trim().isEmpty ? 'Veuillez entrer un commentaire' : null,
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        TextButton(
                          onPressed: () => Navigator.pop(dialogContext),
                          child: const Text('Annuler', style: TextStyle(color: Colors.grey)),
                        ),
                        if (hasUserReviewed)
                          TextButton(
                            onPressed: () async {
                              try {
                                final userId = await _getUserId();
                                await Supabase.instance.client
                                    .from('critiquer')
                                    .delete()
                                    .eq('idutilisateur', userId)
                                    .eq('idrestaurant', restaurantId);
                                Navigator.pop(dialogContext);
                                _showSnackBar(context, 'Avis supprimé avec succès !');
                                onReviewUpdated();
                              } catch (e) {
                                _showSnackBar(context, 'Erreur lors de la suppression : $e', isError: true);
                              }
                            },
                            child: const Text('Supprimer', style: TextStyle(color: Colors.red)),
                          ),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(backgroundColor: goldColor, minimumSize: const Size(100, 36)),
                          onPressed: () async {
                            if (formKey.currentState!.saveAndValidate()) {
                              final formData = formKey.currentState!.value;
                              final rating = formData['rating'] as int;
                              final comment = formData['comment'] as String;
                              try {
                                final userId = await _getUserId();
                                final operation = hasUserReviewed
                                    ? Supabase.instance.client.from('critiquer').update({
                                        'notecritique': rating,
                                        'commentairecritique': comment.trim(),
                                        'datecritique': DateTime.now().toIso8601String(),
                                      })
                                    : Supabase.instance.client.from('critiquer').insert({
                                        'idutilisateur': userId,
                                        'idrestaurant': restaurantId,
                                        'notecritique': rating,
                                        'commentairecritique': comment.trim(),
                                        'datecritique': DateTime.now().toIso8601String(),
                                      });
                                if (hasUserReviewed) {
                                  await operation.eq('idutilisateur', userId).eq('idrestaurant', restaurantId);
                                } else {
                                  await operation;
                                }
                                Navigator.pop(dialogContext);
                                _showSnackBar(context, hasUserReviewed ? 'Avis modifié !' : 'Avis soumis !');
                                onReviewUpdated();
                              } catch (e) {
                                _showSnackBar(context, 'Erreur : $e', isError: true);
                              }
                            } else {
                              setState(() {});
                            }
                          },
                          child: Text(hasUserReviewed ? 'Modifier' : 'Soumettre',
                              style: GoogleFonts.raleway(color: Colors.white)),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}