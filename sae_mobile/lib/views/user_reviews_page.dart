import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class UserReviewsPage extends StatefulWidget {
  const UserReviewsPage({Key? key}) : super(key: key);

  @override
  _UserReviewsPageState createState() => _UserReviewsPageState();
}

class _UserReviewsPageState extends State<UserReviewsPage> {
  List<Map<String, dynamic>> reviews = [];
  bool isLoading = true;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchUserReviews();
  }

  Future<void> _fetchUserReviews() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      final currentUser = Supabase.instance.client.auth.currentUser;
      if (currentUser == null) {
        throw Exception('Utilisateur non connecté');
      }

      final userResponse = await Supabase.instance.client
          .from('utilisateur')
          .select('idutilisateur')
          .eq('emailutilisateur', currentUser.email!)
          .single();

      int userId = userResponse['idutilisateur'];

      final reviewsResponse = await Supabase.instance.client
          .from('critiquer')
          .select('idrestaurant, notecritique, commentairecritique, datecritique, restaurant(nomrestaurant)')
          .eq('idutilisateur', userId)
          .order('datecritique', ascending: false);

      setState(() {
        reviews = List<Map<String, dynamic>>.from(reviewsResponse);
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        errorMessage = 'Erreur lors de la récupération des critiques : $e';
        isLoading = false;
      });
      print('Erreur lors de la récupération des critiques : $e');
    }
  }

  Widget _buildReviewCard(Map<String, dynamic> review) {
    final String restaurantName = review['restaurant']['nomrestaurant'] ?? 'Restaurant inconnu';
    final int rating = review['notecritique'];
    final String comment = review['commentairecritique'] ?? 'Aucun commentaire';
    final String date = review['datecritique'].toString().split(' ')[0];
    final int restaurantId = review['idrestaurant'];
    final goldColor = Theme.of(context).primaryColor; // Use the same goldColor as HomePage

    return StatefulBuilder(
      builder: (context, setState) {
        bool isHovered = false;

        return MouseRegion(
          onEnter: (_) {
            setState(() {
              isHovered = true;
            });
          },
          onExit: (_) {
            setState(() {
              isHovered = false;
            });
          },
          child: AnimatedContainer(
            duration: Duration(milliseconds: 200),
            transform: Matrix4.identity()..scale(isHovered ? 1.02 : 1.0),
            transformAlignment: Alignment.center,
            child: Card(
              elevation: isHovered ? 8 : 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              color: isHovered ? Colors.grey[100] : Colors.white,
              margin: EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
              child: InkWell(
                onTap: () {
                  context.push('/restaurant-details', extra: {'restaurantId': restaurantId});
                },
                borderRadius: BorderRadius.circular(12),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    children: [
                      // Icon on the left with goldColor
                      Container(
                        padding: EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: goldColor.withOpacity(0.1), // Match HomePage
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          Icons.restaurant,
                          color: goldColor, // Match HomePage
                          size: 30,
                        ),
                      ),
                      SizedBox(width: 16),
                      // Middle section with restaurant name, rating, and comment
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  restaurantName,
                                  style: TextStyle(
                                    fontFamily: 'Raleway',
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black87,
                                  ),
                                ),
                                Text(
                                  date,
                                  style: TextStyle(
                                    fontFamily: 'Raleway',
                                    fontSize: 12,
                                    color: Colors.grey,
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: 4),
                            Row(
                              children: List.generate(5, (index) {
                                return Icon(
                                  index < rating ? Icons.star : Icons.star_border,
                                  color: goldColor, // Match the star color with goldColor
                                  size: 16,
                                );
                              }),
                            ),
                            SizedBox(height: 4),
                            Text(
                              comment,
                              style: TextStyle(
                                fontFamily: 'Raleway',
                                fontSize: 14,
                                color: Colors.black54,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      // Chevron on the right
                      Icon(
                        Icons.chevron_right,
                        color: Colors.grey,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final goldColor = Theme.of(context).primaryColor;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Mes Critiques',
          style: TextStyle(
            fontFamily: 'Raleway',
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: goldColor,
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => context.go('/home-authentified'),
        ),
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator(color: goldColor))
          : errorMessage != null
              ? Center(
                  child: Text(
                    errorMessage!,
                    style: TextStyle(
                      fontFamily: 'Raleway',
                      fontSize: 16,
                      color: Colors.red,
                    ),
                  ),
                )
              : reviews.isEmpty
                  ? Center(
                      child: Text(
                        'Aucune critique pour le moment.',
                        style: TextStyle(
                          fontFamily: 'Raleway',
                          fontSize: 16,
                          color: Colors.black54,
                        ),
                      ),
                    )
                  : ListView.builder(
                      itemCount: reviews.length,
                      itemBuilder: (context, index) {
                        return _buildReviewCard(reviews[index]);
                      },
                    ),
    );
  }
}