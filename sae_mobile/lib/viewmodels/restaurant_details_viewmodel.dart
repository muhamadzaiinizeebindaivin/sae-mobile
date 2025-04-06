import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class RestaurantDetailsViewModel extends ChangeNotifier {
  final int restaurantId;
  Map<String, dynamic>? _restaurantDetails;
  Map<String, dynamic>? _locationDetails;
  List<Map<String, dynamic>> _cuisines = [];
  List<Map<String, dynamic>> _openingHours = [];
  List<Map<String, dynamic>> _reviews = [];
  bool _isLoading = true;
  bool _hasUserReviewed = false;
  Map<String, dynamic>? _userReview;

  RestaurantDetailsViewModel({required this.restaurantId}) {
    fetchRestaurantDetails();
  }

  // Getters
  Map<String, dynamic>? get restaurantDetails => _restaurantDetails;
  Map<String, dynamic>? get locationDetails => _locationDetails;
  List<Map<String, dynamic>> get cuisines => _cuisines;
  List<Map<String, dynamic>> get openingHours => _openingHours;
  List<Map<String, dynamic>> get reviews => _reviews;
  bool get isLoading => _isLoading;
  bool get hasUserReviewed => _hasUserReviewed;
  Map<String, dynamic>? get userReview => _userReview;

  Future<void> fetchRestaurantDetails() async {
    _isLoading = true;
    notifyListeners();

    try {
      final restaurantResponse = await Supabase.instance.client
          .from('restaurant')
          .select('*, localisation(*)')
          .eq('idrestaurant', restaurantId)
          .maybeSingle();

      if (restaurantResponse == null) {
        throw Exception('Aucun restaurant trouvé pour l\'ID $restaurantId');
      }

      final cuisinesResponse = await Supabase.instance.client
          .from('servir')
          .select('cuisine(idcuisine, nomcuisine)')
          .eq('idrestaurant', restaurantId);

      final openingResponse = await Supabase.instance.client
          .from('proposer')
          .select('ouverture(jourouverture), horaire')
          .eq('idrestaurant', restaurantId);

      final reviewsResponse = await Supabase.instance.client
          .from('critiquer')
          .select('notecritique, commentairecritique, datecritique, utilisateur(nomutilisateur, prenomutilisateur, idutilisateur)')
          .eq('idrestaurant', restaurantId)
          .order('datecritique', ascending: false);

      final reviewsList = List<Map<String, dynamic>>.from(reviewsResponse);
      double averageRating = 0;
      if (reviewsList.isNotEmpty) {
        double totalRating = 0;
        int ratingCount = 0;
        for (var review in reviewsList) {
          if (review['notecritique'] != null) {
            totalRating += review['notecritique'];
            ratingCount++;
          }
        }
        if (ratingCount > 0) {
          averageRating = totalRating / ratingCount;
        }
      }
      averageRating = (averageRating * 10).round() / 10;

      final updatedRestaurantDetails = Map<String, dynamic>.from(restaurantResponse);
      updatedRestaurantDetails['notemoyenne'] = averageRating;

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

      _restaurantDetails = updatedRestaurantDetails;
      _locationDetails = _restaurantDetails?['localisation'];
      _cuisines = List<Map<String, dynamic>>.from(cuisinesResponse.map((item) => item['cuisine']));
      _openingHours = List<Map<String, dynamic>>.from(openingResponse);
      _reviews = reviewsList;
      _isLoading = false;

      if (userId != null) {
        _userReview = reviewsList.firstWhere(
          (review) => review['utilisateur']['idutilisateur'] == userId,
          orElse: () => <String, dynamic>{},
        );
        _hasUserReviewed = _userReview!.isNotEmpty;
      }
    } catch (e) {
      print('Erreur lors du chargement des détails du restaurant: $e');
      _isLoading = false;
      _restaurantDetails = null;
    }
    notifyListeners();
  }
}