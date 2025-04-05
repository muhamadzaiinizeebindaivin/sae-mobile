import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
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
          .select('notecritique, commentairecritique, datecritique, restaurant(nomrestaurant)')
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

    return Card(
      margin: EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  restaurantName,
                  style: GoogleFonts.raleway(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                Text(
                  date,
                  style: GoogleFonts.raleway(
                    fontSize: 12,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
            SizedBox(height: 8),
            Row(
              children: List.generate(5, (index) {
                return Icon(
                  index < rating ? Icons.star : Icons.star_border,
                  color: Theme.of(context).primaryColor,
                  size: 20,
                );
              }),
            ),
            SizedBox(height: 8),
            Text(
              comment,
              style: GoogleFonts.raleway(
                fontSize: 14,
                color: Colors.black54,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final goldColor = Theme.of(context).primaryColor;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Mes Critiques',
          style: GoogleFonts.raleway(
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
                    style: GoogleFonts.raleway(fontSize: 16, color: Colors.red),
                  ),
                )
              : reviews.isEmpty
                  ? Center(
                      child: Text(
                        'Aucune critique pour le moment.',
                        style: GoogleFonts.raleway(
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