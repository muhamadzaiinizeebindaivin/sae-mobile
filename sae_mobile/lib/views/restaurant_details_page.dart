import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../providers/supabase_provider.dart';
import './restaurant_reviews.dart';
import '../viewmodels/restaurant_details_viewmodel.dart';

class RestaurantDetailsPage extends StatelessWidget {
  final SupabaseProvider supabaseProvider;
  final int restaurantId;

  const RestaurantDetailsPage({
    Key? key,
    required this.supabaseProvider,
    required this.restaurantId,
  }) : super(key: key);

  final Color goldColor = const Color(0xFFD4AF37);
  final Color darkBackgroundColor = const Color(0xFF1E1E1E);
  final Color softGrayColor = const Color(0xFFF5F5F5);

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

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => RestaurantDetailsViewModel(restaurantId: restaurantId),
      child: Consumer<RestaurantDetailsViewModel>(
        builder: (context, viewModel, child) {
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
                  icon: const Icon(Icons.arrow_back, color: Colors.white),
                  onPressed: () => context.pop(),
                ),
              ),
              body: viewModel.isLoading
                  ? Center(child: CircularProgressIndicator(color: goldColor))
                  : viewModel.restaurantDetails == null
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
                                        padding: const EdgeInsets.all(16),
                                        decoration: BoxDecoration(
                                          borderRadius: const BorderRadius.only(
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
                                              viewModel.restaurantDetails?['nomrestaurant'] ?? 'Sans nom',
                                              style: GoogleFonts.raleway(
                                                fontSize: 24,
                                                fontWeight: FontWeight.bold,
                                                color: Colors.white,
                                              ),
                                            ),
                                            Row(
                                              children: [
                                                Icon(Icons.star, color: goldColor, size: 18),
                                                const SizedBox(width: 4),
                                                Text(
                                                  viewModel.restaurantDetails?['notemoyenne'] != null &&
                                                          viewModel.restaurantDetails!['notemoyenne'] > 0
                                                      ? '${viewModel.restaurantDetails!['notemoyenne']}/5 (${viewModel.reviews.length} avis)'
                                                      : 'X/5',
                                                  style: GoogleFonts.raleway(
                                                    fontSize: 16,
                                                    color: Colors.white,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                _buildSectionTitle('Informations Générales'),
                                _buildInfoRow('Nom', viewModel.restaurantDetails?['nomrestaurant'] ?? 'Non spécifié'),
                                _buildInfoRow('Note moyenne',
                                    viewModel.restaurantDetails?['notemoyenne'] != null && viewModel.restaurantDetails!['notemoyenne'] > 0
                                        ? '${viewModel.restaurantDetails!['notemoyenne']}/5 (${viewModel.reviews.length} avis)'
                                        : 'X/5'),
                                _buildInfoRow('Marque', viewModel.restaurantDetails?['marquerestaurant'] ?? 'Non spécifié'),
                                _buildInfoRow('Gérant', viewModel.restaurantDetails?['gerantrestaurant'] ?? 'Non spécifié'),
                                _buildInfoRow('SIRET', viewModel.restaurantDetails?['siretrestaurant'] ?? 'Non spécifié'),
                                _buildInfoRow('Capacité',
                                    viewModel.restaurantDetails?['capaciterestaurant'] != null
                                        ? '${viewModel.restaurantDetails!['capaciterestaurant']} personnes'
                                        : 'Non spécifié'),
                                _buildSectionTitle('Cuisine'),
                                _buildInfoRow('Établissement', _formatRestaurantType(viewModel.restaurantDetails?['typerestaurant'])),
                                _buildInfoRow('Cuisine',
                                    viewModel.cuisines.isNotEmpty
                                        ? viewModel.cuisines.map((c) => _formatCuisineName(c['nomcuisine'])).join(', ')
                                        : 'Non spécifié'),
                                _buildInfoRow('Végétarien',
                                    viewModel.restaurantDetails?['vegetarienrestaurant'] == true ? 'Oui' : 'Non'),
                                _buildInfoRow('Vegan',
                                    viewModel.restaurantDetails?['veganrestaurant'] == true ? 'Oui' : 'Non'),
                                _buildSectionTitle('Localisation'),
                                _buildInfoRow('Pays', viewModel.locationDetails?['payslocalisation'] ?? 'Non spécifié'),
                                _buildInfoRow('Région', viewModel.locationDetails?['regionlocalisation'] ?? 'Non spécifié'),
                                _buildInfoRow('Ville', viewModel.locationDetails?['villelocalisation'] ?? 'Non spécifié'),
                                _buildInfoRow('Département', viewModel.locationDetails?['departementlocalisation'] ?? 'Non spécifié'),
                                _buildInfoRow('Adresse',
                                    viewModel.locationDetails?['adresselocalisation'] != null
                                        ? '${viewModel.locationDetails!['adresselocalisation']}, '
                                            '${viewModel.locationDetails!['codevillelocalisation'] ?? ''} '
                                            '${viewModel.locationDetails!['villelocalisation'] ?? ''}'
                                        : 'Non spécifié'),
                                _buildInfoRow('Téléphone', _formatPhoneNumber(viewModel.restaurantDetails?['telephonerestaurant'])),
                                _buildInfoRow('Coordonnées', viewModel.locationDetails?['coordonneeslocalisation'] ?? 'Non spécifié'),
                                _buildInfoRow('OpenStreetMap', viewModel.locationDetails?['cartelien'] ?? 'Non spécifié'),
                                _buildSectionTitle('Services'),
                                _buildInfoRow('Livraison',
                                    viewModel.restaurantDetails?['livraisonrestaurant'] == true ? 'Oui' : 'Non'),
                                _buildInfoRow('À emporter',
                                    viewModel.restaurantDetails?['emporterrestaurant'] == true ? 'Oui' : 'Non'),
                                _buildInfoRow('Drive',
                                    viewModel.restaurantDetails?['driverestaurant'] == true ? 'Oui' : 'Non'),
                                _buildInfoRow('Wi-Fi/Internet',
                                    viewModel.restaurantDetails?['internetrestaurant'] == true ? 'Oui' : 'Non'),
                                _buildInfoRow('Accès handicapé',
                                    viewModel.restaurantDetails?['handicaprestaurant'] == true ? 'Oui' : 'Non'),
                                _buildInfoRow('Espace fumeur',
                                    viewModel.restaurantDetails?['fumerrestaurant'] == true ? 'Oui' : 'Non'),
                                _buildSectionTitle('Liens Externes'),
                                _buildInfoRow('Site Web', viewModel.restaurantDetails?['sitewebrestaurant'] ?? 'Non spécifié'),
                                _buildInfoRow('Facebook', viewModel.restaurantDetails?['facebookrestaurant'] ?? 'Non spécifié'),
                                _buildInfoRow('Wikidata', viewModel.restaurantDetails?['wikidatalien'] ?? 'Non spécifié'),
                                _buildSectionTitle('Horaires d\'ouverture'),
                                viewModel.openingHours.isNotEmpty
                                    ? Column(
                                        children: viewModel.openingHours
                                            .map((opening) => _buildInfoRow(
                                                  _formatCuisineName(opening['ouverture']['jourouverture']),
                                                  opening['horaire'] ?? 'Non spécifié',
                                                ))
                                            .toList(),
                                      )
                                    : _buildInfoRow('Horaires', 'Non spécifié'),
                                RestaurantReviews(
                                  restaurantId: restaurantId,
                                  reviews: viewModel.reviews,
                                  hasUserReviewed: viewModel.hasUserReviewed,
                                  userReview: viewModel.userReview,
                                  onReviewUpdated: viewModel.fetchRestaurantDetails,
                                  goldColor: goldColor,
                                  darkBackgroundColor: darkBackgroundColor,
                                ),
                              ],
                            ),
                          ),
                        ),
            ),
          );
        },
      ),
    );
  }
}