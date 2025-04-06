import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sae_mobile/viewmodels/restaurant_reviews_viewmodel.dart';

class RestaurantReviewsView extends StatelessWidget {
  final RestaurantReviewsViewModel viewModel;

  const RestaurantReviewsView({Key? key, required this.viewModel}) : super(key: key);

  static const Color _userCardColor = Color(0xFFFDF0C0);

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12.0),
      child: Container(
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(color: viewModel.goldColor, width: 2), // Changed to bottom border
          ),
        ),
        child: Text(
          title,
          style: GoogleFonts.raleway(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: viewModel.goldColor,
          ),
        ),
      ),
    );
  }

  Widget _buildReviewCard(Map<String, dynamic> review, bool isCurrentUser) {
    final user = review['utilisateur'];
    final String userName = '${user['prenomutilisateur']} ${user['nomutilisateur']}';
    final int rating = review['notecritique'];
    final String comment = review['commentairecritique'] ?? 'Aucun commentaire';
    final String date = review['datecritique'].toString().split(' ')[0];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (isCurrentUser)
          Padding(
            padding: const EdgeInsets.only(top: 2.0),
            child: Text(
              'Votre avis',
              style: GoogleFonts.raleway(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: viewModel.goldColor,
              ),
            ),
          ),
        Card(
          margin: const EdgeInsets.symmetric(vertical: 8.0),
          elevation: 2,
          color: isCurrentUser ? _userCardColor : Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      userName,
                      style: GoogleFonts.raleway(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: viewModel.darkBackgroundColor,
                      ),
                    ),
                    Text(
                      date,
                      style: GoogleFonts.raleway(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: List.generate(
                    5,
                    (index) => Icon(
                      index < rating ? Icons.star : Icons.star_border,
                      color: viewModel.goldColor,
                      size: 20,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  comment,
                  style: GoogleFonts.raleway(
                    fontSize: 14,
                    color: viewModel.darkBackgroundColor,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildSectionTitle('Critiques'),
            ElevatedButton(
              onPressed: () => viewModel.handleAddReview(context),
              style: ElevatedButton.styleFrom(backgroundColor: viewModel.goldColor),
              child: Text(
                viewModel.hasUserReviewed ? 'Modifier mon avis' : 'Ajouter avis',
                style: GoogleFonts.raleway(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        viewModel.sortedReviews.isNotEmpty
            ? Column(
                children: viewModel.sortedReviews.map((review) {
                  final bool isCurrentUser = viewModel.isCurrentUserReview(review);
                  return _buildReviewCard(review, isCurrentUser);
                }).toList(),
              )
            : Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: Text(
                  'Aucun avis pour le moment.',
                  style: GoogleFonts.raleway(
                    fontSize: 16,
                    color: viewModel.darkBackgroundColor,
                  ),
                ),
              ),
      ],
    );
  }
}