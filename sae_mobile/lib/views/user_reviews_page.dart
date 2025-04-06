import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:sae_mobile/viewmodels/user_reviews_viewmodel.dart';

class UserReviewsView extends StatefulWidget {
  const UserReviewsView({Key? key}) : super(key: key);

  @override
  _UserReviewsViewState createState() => _UserReviewsViewState();
}

class _UserReviewsViewState extends State<UserReviewsView> {
  late UserReviewsViewModel viewModel;

  @override
  void initState() {
    super.initState();
    viewModel = UserReviewsViewModel(
      onStateChanged: () => setState(() {}), // Callback to rebuild UI
    );
    viewModel.fetchUserReviews();
  }

  Widget _buildReviewCard(Map<String, dynamic> review, int index) {
    final String restaurantName = review['restaurant']['nomrestaurant'] ?? 'Restaurant inconnu';
    final int rating = review['notecritique'];
    final String comment = review['commentairecritique'] ?? 'Aucun commentaire';
    final String date = review['datecritique'].toString().split(' ')[0];
    final int restaurantId = review['idrestaurant'];
    final goldColor = Theme.of(context).primaryColor;

    return MouseRegion(
      onEnter: (_) => viewModel.setHovered(index, true),
      onExit: (_) => viewModel.setHovered(index, false),
      child: AnimatedContainer(
        duration: Duration(milliseconds: 200),
        transform: Matrix4.identity()..scale(viewModel.hoveredStates[index] ? 1.02 : 1.0),
        transformAlignment: Alignment.center,
        child: Card(
          elevation: viewModel.hoveredStates[index] ? 8 : 4,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          color: viewModel.hoveredStates[index] ? Colors.grey[100] : Colors.white,
          margin: EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
          child: InkWell(
            onTap: () => context.push('/restaurant-details', extra: {'restaurantId': restaurantId}),
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: goldColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(Icons.restaurant, color: goldColor, size: 30),
                  ),
                  SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(restaurantName,
                                style: TextStyle(
                                    fontFamily: 'Raleway', fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87)),
                            Text(date,
                                style: TextStyle(fontFamily: 'Raleway', fontSize: 12, color: Colors.grey)),
                          ],
                        ),
                        SizedBox(height: 4),
                        Row(
                          children: List.generate(5, (index) => Icon(
                                index < rating ? Icons.star : Icons.star_border,
                                color: goldColor,
                                size: 16,
                              )),
                        ),
                        SizedBox(height: 4),
                        Text(comment,
                            style: TextStyle(fontFamily: 'Raleway', fontSize: 14, color: Colors.black54),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis),
                      ],
                    ),
                  ),
                  Icon(Icons.chevron_right, color: Colors.grey),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final goldColor = Theme.of(context).primaryColor;

    return Scaffold(
      appBar: AppBar(
        title: Text('Mes Critiques',
            style: TextStyle(fontFamily: 'Raleway', fontWeight: FontWeight.bold, color: Colors.white)),
        backgroundColor: goldColor,
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => context.go('/home-authentified'),
        ),
      ),
      body: viewModel.isLoading
          ? Center(child: CircularProgressIndicator(color: goldColor))
          : viewModel.errorMessage != null
              ? Center(
                  child: Text(viewModel.errorMessage!,
                      style: TextStyle(fontFamily: 'Raleway', fontSize: 16, color: Colors.red)))
              : viewModel.reviews.isEmpty
                  ? Center(
                      child: Text('Aucune critique pour le moment.',
                          style: TextStyle(fontFamily: 'Raleway', fontSize: 16, color: Colors.black54)))
                  : ListView.builder(
                      itemCount: viewModel.reviews.length,
                      itemBuilder: (context, index) => _buildReviewCard(viewModel.reviews[index], index),
                    ),
    );
  }
}