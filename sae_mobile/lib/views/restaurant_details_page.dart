import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../providers/supabase_provider.dart';

class RestaurantDetailsPage extends StatefulWidget {
  final SupabaseProvider supabaseProvider;
  final int restaurantId;

  const RestaurantDetailsPage({
    Key? key,
    required this.supabaseProvider,
    required this.restaurantId,
  }) : super(key: key);

  @override
  _RestaurantDetailsPageState createState() => _RestaurantDetailsPageState();
}

class _RestaurantDetailsPageState extends State<RestaurantDetailsPage> {
  Map<String, dynamic>? restaurantDetails;
  Map<String, dynamic>? locationDetails;
  List<Map<String, dynamic>> cuisines = [];
  List<Map<String, dynamic>> openingHours = [];
  List<Map<String, dynamic>> reviews = [];
  bool isLoading = true;
  bool hasUserReviewed = false;
  Map<String, dynamic>? userReview;

  final Color goldColor = Color(0xFFD4AF37);
  final Color darkBackgroundColor = Color(0xFF1E1E1E);
  final Color softGrayColor = Color(0xFFF5F5F5);

  @override
  void initState() {
    super.initState();
    _fetchRestaurantDetails();
  }

  Future<void> _fetchRestaurantDetails() async {
    setState(() {
      isLoading = true;
    });

    try {
      final restaurantResponse = await Supabase.instance.client
          .from('restaurant')
          .select('*, localisation(*)')
          .eq('idrestaurant', widget.restaurantId)
          .maybeSingle();

      if (restaurantResponse == null) {
        throw Exception('Aucun restaurant trouvé pour l\'ID ${widget.restaurantId}');
      }

      final cuisinesResponse = await Supabase.instance.client
          .from('servir')
          .select('cuisine(idcuisine, nomcuisine)')
          .eq('idrestaurant', widget.restaurantId);

      final openingResponse = await Supabase.instance.client
          .from('proposer')
          .select('ouverture(jourouverture), horaire')
          .eq('idrestaurant', widget.restaurantId);

      final reviewsResponse = await Supabase.instance.client
          .from('critiquer')
          .select('notecritique, commentairecritique, datecritique, utilisateur(nomutilisateur, prenomutilisateur, idutilisateur)')
          .eq('idrestaurant', widget.restaurantId)
          .order('datecritique', ascending: false);

      final user = Supabase.instance.client.auth.currentUser;
      int? userId;
      if (user != null) {
        final userResponse = await Supabase.instance.client
            .from('utilisateur')
            .select('idutilisateur')
            .eq('emailutilisateur', user.email!)
            .single();
        userId = userResponse['idutilisateur'];
      }

      final reviewsList = List<Map<String, dynamic>>.from(reviewsResponse);
      setState(() {
        restaurantDetails = restaurantResponse;
        locationDetails = restaurantDetails?['localisation'];
        cuisines = List<Map<String, dynamic>>.from(cuisinesResponse.map((item) => item['cuisine']));
        openingHours = List<Map<String, dynamic>>.from(openingResponse);
        reviews = reviewsList;
        isLoading = false;

        if (userId != null) {
          userReview = reviewsList.firstWhere(
            (review) => review['utilisateur']['idutilisateur'] == userId,
            orElse: () => <String, dynamic>{},
          );
          hasUserReviewed = userReview!.isNotEmpty;
        }
      });
    } catch (e) {
      print('Erreur lors du chargement des détails du restaurant: $e');
      setState(() {
        isLoading = false;
        restaurantDetails = null;
      });
    }
  }

  String _formatPhoneNumber(String? phoneNumber) {
    if (phoneNumber == null || phoneNumber.isEmpty) return 'Non spécifié';
    String cleanNumber = phoneNumber.replaceAll(RegExp(r'\D'), '');
    if (cleanNumber.length != 11) return phoneNumber;
    return '+${cleanNumber.substring(0, 2)} '
        '${cleanNumber.substring(2, 3)} '
        '${cleanNumber.substring(3, 5)} '
        '${cleanNumber.substring(5, 7)} '
        '${cleanNumber.substring(7, 9)} '
        '${cleanNumber.substring(9)}';
  }

  String _formatRestaurantType(String? type) {
    if (type == null || type.isEmpty) return 'Non spécifié';
    String formattedType = type.replaceAll('-', ' ').replaceAll('_', ' ');
    formattedType = formattedType.replaceAll('cafe', 'café');
    List<String> words = formattedType.split(' ');
    words = words.map((word) {
      if (word.isEmpty) return word;
      return word[0].toUpperCase() + word.substring(1).toLowerCase();
    }).toList();
    return words.join(' ');
  }

  String _formatCuisineName(String text) {
    if (text.isEmpty) return 'Non spécifié';
    String formattedText = text.replaceAll('_', ' ').replaceAll('-', ' ');
    return formattedText[0].toUpperCase() + formattedText.substring(1).toLowerCase();
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12.0),
      child: Container(
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(color: goldColor, width: 2),
          ),
        ),
        child: Text(
          title,
          style: GoogleFonts.raleway(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: goldColor,
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: softGrayColor,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 2,
              child: Text(
                label,
                style: GoogleFonts.raleway(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: darkBackgroundColor,
                ),
              ),
            ),
            Expanded(
              flex: 3,
              child: Text(
                value,
                style: GoogleFonts.raleway(
                  fontSize: 15,
                  color: darkBackgroundColor,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReviewCard(Map<String, dynamic> review) {
    final user = review['utilisateur'];
    final String userName = '${user['prenomutilisateur']} ${user['nomutilisateur']}';
    final int rating = review['notecritique'];
    final String comment = review['commentairecritique'] ?? 'Aucun commentaire';
    final String date = review['datecritique'].toString().split(' ')[0];

    return Card(
      margin: EdgeInsets.symmetric(vertical: 8.0),
      elevation: 2,
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
                    color: darkBackgroundColor,
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
                  color: goldColor,
                  size: 20,
                );
              }),
            ),
            SizedBox(height: 8),
            Text(
              comment,
              style: GoogleFonts.raleway(
                fontSize: 14,
                color: darkBackgroundColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showReviewDialog() {
    final TextEditingController commentController = TextEditingController(
      text: hasUserReviewed ? userReview!['commentairecritique'] : '',
    );
    int rating = hasUserReviewed ? userReview!['notecritique'] : 0;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text(
                hasUserReviewed ? 'Modifier avis' : 'Laisser un avis',
                style: GoogleFonts.raleway(
                  fontWeight: FontWeight.bold,
                  color: darkBackgroundColor,
                ),
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Notez le restaurant',
                      style: GoogleFonts.raleway(fontSize: 16),
                    ),
                    SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(5, (index) {
                        return IconButton(
                          icon: Icon(
                            index < rating ? Icons.star : Icons.star_border,
                            color: goldColor,
                          ),
                          onPressed: () {
                            setDialogState(() {
                              rating = index + 1;
                            });
                          },
                        );
                      }),
                    ),
                    SizedBox(height: 16),
                    TextField(
                      controller: commentController,
                      maxLines: 3,
                      decoration: InputDecoration(
                        labelText: 'Votre commentaire',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text('Annuler', style: TextStyle(color: Colors.grey)),
                ),
                if (hasUserReviewed)
                  TextButton(
                    onPressed: () async {
                      try {
                        final user = Supabase.instance.client.auth.currentUser;
                        if (user == null) throw Exception('Utilisateur non connecté');

                        final userResponse = await Supabase.instance.client
                            .from('utilisateur')
                            .select('idutilisateur')
                            .eq('emailutilisateur', user.email!)
                            .single();

                        int userId = userResponse['idutilisateur'];

                        await Supabase.instance.client
                            .from('critiquer')
                            .delete()
                            .eq('idutilisateur', userId)
                            .eq('idrestaurant', widget.restaurantId);

                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Avis supprimé avec succès !'),
                            duration: Duration(seconds: 1),
                            ),
                        );
                        await _fetchRestaurantDetails();
                      } catch (e) {
                        print('Erreur lors de la suppression : $e');
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Erreur lors de la suppression : $e'), 
                            duration: Duration(seconds: 1),
                            ),
                        );
                      }
                    },
                    child: Text(
                      'Supprimer',
                      style: TextStyle(color: Colors.red),
                    ),
                  ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: goldColor,
                  ),
                  onPressed: () async {
                    if (rating == 0) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Veuillez sélectionner une note'),
                          duration: Duration(seconds: 1),
                          ),
                      );
                      return;
                    }
                    if (commentController.text.trim().isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Veuillez entrer un commentaire'),
                          duration: Duration(seconds: 1),
                        ),
                        
                      );
                      return;
                    }

                    try {
                      final user = Supabase.instance.client.auth.currentUser;
                      if (user == null) throw Exception('Utilisateur non connecté');

                      final userResponse = await Supabase.instance.client
                          .from('utilisateur')
                          .select('idutilisateur')
                          .eq('emailutilisateur', user.email!)
                          .single();

                      int userId = userResponse['idutilisateur'];

                      if (hasUserReviewed) {
                        await Supabase.instance.client
                            .from('critiquer')
                            .update({
                              'notecritique': rating,
                              'commentairecritique': commentController.text.trim(),
                              'datecritique': DateTime.now().toIso8601String(),
                            })
                            .eq('idutilisateur', userId)
                            .eq('idrestaurant', widget.restaurantId);
                            print("success");
                            print(userId);
                            print(widget.restaurantId);
                      } else {
                        await Supabase.instance.client.from('critiquer').insert({
                          'idutilisateur': userId,
                          'idrestaurant': widget.restaurantId,
                          'notecritique': rating,
                          'commentairecritique': commentController.text.trim(),
                          'datecritique': DateTime.now().toIso8601String(),
                        });
                      }

                      // Only pop and refresh if the operation succeeds
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            hasUserReviewed
                                ? 'Avis modifié avec succès !'
                                : 'Avis soumis avec succès !',
                          ),
                          duration: Duration(seconds: 1),
                        ),
                      );
                      await _fetchRestaurantDetails();
                    } catch (e) {
                      print('Erreur lors de la soumission : $e');
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Erreur lors de la soumission : $e'),
                          duration: Duration(seconds: 1),
                          ),
                      );
                    }
                  },
                  child: Text(
                    hasUserReviewed ? 'Modifier' : 'Soumettre',
                    style: GoogleFonts.raleway(color: Colors.white),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        context.pop();
        return false;
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          elevation: 0,
          title: Text(
            'Détails du Restaurant',
            style: GoogleFonts.raleway(
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          backgroundColor: goldColor,
          centerTitle: true,
          leading: IconButton(
            icon: Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => context.pop(),
          ),
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () {
            final user = Supabase.instance.client.auth.currentUser;
            if (user == null) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Vous devez être connecté pour laisser un avis'),
                  duration: Duration(seconds: 1),
                ),
              );
              return;
            }
            _showReviewDialog();
          },
          backgroundColor: goldColor,
          icon: Icon(Icons.rate_review, color: Colors.white),
          label: Text(
            hasUserReviewed ? 'Modifier avis' : 'Ajouter avis',
            style: GoogleFonts.raleway(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        body: isLoading
            ? Center(child: CircularProgressIndicator(color: goldColor))
            : restaurantDetails == null
                ? Center(
                    child: Text(
                      'Restaurant non trouvé',
                      style: GoogleFonts.raleway(fontSize: 18),
                    ),
                  )
                : SingleChildScrollView(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Stack(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(15),
                                child: Image.asset(
                                  'assets/images/restaurant.jpg',
                                  width: double.infinity,
                                  height: 250,
                                  fit: BoxFit.cover,
                                ),
                              ),
                              Positioned(
                                bottom: 0,
                                left: 0,
                                right: 0,
                                child: Container(
                                  padding: EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.only(
                                      bottomLeft: Radius.circular(15),
                                      bottomRight: Radius.circular(15),
                                    ),
                                    gradient: LinearGradient(
                                      begin: Alignment.bottomCenter,
                                      end: Alignment.topCenter,
                                      colors: [
                                        Colors.black.withOpacity(0.7),
                                        Colors.transparent,
                                      ],
                                    ),
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        restaurantDetails?['nomrestaurant'] ?? 'Sans nom',
                                        style: GoogleFonts.raleway(
                                          fontSize: 24,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                          _buildSectionTitle('Informations Générales'),
                          _buildInfoRow('Nom', restaurantDetails?['nomrestaurant'] ?? 'Non spécifié'),
                          _buildInfoRow('Étoiles',
                              (restaurantDetails?['etoilerestaurant'] != null
                                  ? '${restaurantDetails!['etoilerestaurant']}/5'
                                  : 'Non spécifié')),
                          _buildInfoRow('Marque', restaurantDetails?['marquerestaurant'] ?? 'Non spécifié'),
                          _buildInfoRow('Gérant', restaurantDetails?['gerantrestaurant'] ?? 'Non spécifié'),
                          _buildInfoRow('SIRET', restaurantDetails?['siretrestaurant'] ?? 'Non spécifié'),
                          _buildInfoRow('Capacité',
                              (restaurantDetails?['capaciterestaurant'] != null
                                  ? '${restaurantDetails!['capaciterestaurant']} personnes'
                                  : 'Non spécifié')),
                          _buildSectionTitle('Cuisine'),
                          _buildInfoRow('Établissement', _formatRestaurantType(restaurantDetails?['typerestaurant'])),
                          _buildInfoRow('Cuisine',
                              cuisines.isNotEmpty
                                  ? cuisines.map((c) => _formatCuisineName(c['nomcuisine'])).join(', ')
                                  : 'Non spécifié'),
                          _buildInfoRow('Végétarien',
                              restaurantDetails?['vegetarienrestaurant'] == true ? 'Oui' : 'Non'),
                          _buildInfoRow('Vegan',
                              restaurantDetails?['veganrestaurant'] == true ? 'Oui' : 'Non'),
                          _buildSectionTitle('Localisation'),
                          _buildInfoRow('Pays', locationDetails?['payslocalisation'] ?? 'Non spécifié'),
                          _buildInfoRow('Région', locationDetails?['regionlocalisation'] ?? 'Non spécifié'),
                          _buildInfoRow('Ville', locationDetails?['villelocalisation'] ?? 'Non spécifié'),
                          _buildInfoRow('Département', locationDetails?['departementlocalisation'] ?? 'Non spécifié'),
                          _buildInfoRow('Adresse',
                              locationDetails?['adresselocalisation'] != null
                                  ? '${locationDetails!['adresselocalisation']}, '
                                      '${locationDetails!['codevillelocalisation'] ?? ''} '
                                      '${locationDetails!['villelocalisation'] ?? ''}'
                                  : 'Non spécifié'),
                          _buildInfoRow('Téléphone', _formatPhoneNumber(restaurantDetails?['telephonerestaurant'])),
                          _buildInfoRow('Coordonnées', locationDetails?['coordonneeslocalisation'] ?? 'Non spécifié'),
                          _buildInfoRow('OpenStreetMap', locationDetails?['cartelien'] ?? 'Non spécifié'),
                          _buildSectionTitle('Services'),
                          _buildInfoRow('Livraison',
                              restaurantDetails?['livraisonrestaurant'] == true ? 'Oui' : 'Non'),
                          _buildInfoRow('À emporter',
                              restaurantDetails?['emporterrestaurant'] == true ? 'Oui' : 'Non'),
                          _buildInfoRow('Drive',
                              restaurantDetails?['driverestaurant'] == true ? 'Oui' : 'Non'),
                          _buildInfoRow('Wi-Fi/Internet',
                              restaurantDetails?['internetrestaurant'] == true ? 'Oui' : 'Non'),
                          _buildInfoRow('Accès handicapé',
                              restaurantDetails?['handicaprestaurant'] == true ? 'Oui' : 'Non'),
                          _buildInfoRow('Espace fumeur',
                              restaurantDetails?['fumerrestaurant'] == true ? 'Oui' : 'Non'),
                          _buildSectionTitle('Liens Externes'),
                          _buildInfoRow('Site Web', restaurantDetails?['sitewebrestaurant'] ?? 'Non spécifié'),
                          _buildInfoRow('Facebook', restaurantDetails?['facebookrestaurant'] ?? 'Non spécifié'),
                          _buildInfoRow('Wikidata', restaurantDetails?['wikidatalien'] ?? 'Non spécifié'),
                          _buildSectionTitle('Horaires d\'ouverture'),
                          openingHours.isNotEmpty
                              ? Column(
                                  children: openingHours
                                      .map((opening) => _buildInfoRow(
                                            _formatCuisineName(opening['ouverture']['jourouverture']),
                                            opening['horaire'] ?? 'Non spécifié',
                                          ))
                                      .toList(),
                                )
                              : _buildInfoRow('Horaires', 'Non spécifié'),
                          _buildSectionTitle('Critiques'),
                          reviews.isNotEmpty
                              ? Column(
                                  children: reviews.map((review) => _buildReviewCard(review)).toList(),
                                )
                              : Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                                  child: Text(
                                    'Aucun avis pour le moment.',
                                    style: GoogleFonts.raleway(
                                      fontSize: 16,
                                      color: darkBackgroundColor,
                                    ),
                                  ),
                                ),
                        ],
                      ),
                    ),
                  ),
      ),
    );
  }
}