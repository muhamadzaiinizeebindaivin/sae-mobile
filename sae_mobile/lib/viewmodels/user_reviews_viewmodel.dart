import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class UserReviewsViewModel {
  List<Map<String, dynamic>> reviews = [];
  bool isLoading = true;
  String? errorMessage;
  List<bool> hoveredStates = [];
  final VoidCallback onStateChanged;

  UserReviewsViewModel({required this.onStateChanged});

  Future<void> fetchUserReviews() async {
    isLoading = true;
    errorMessage = null;
    onStateChanged();

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

      reviews = List<Map<String, dynamic>>.from(reviewsResponse);
      hoveredStates = List.generate(reviews.length, (_) => false);
      isLoading = false;
      onStateChanged();
    } catch (e) {
      errorMessage = 'Erreur lors de la récupération des critiques : $e';
      isLoading = false;
      onStateChanged();
      print('Erreur lors de la récupération des critiques : $e');
    }
  }

  void setHovered(int index, bool isHovered) {
    hoveredStates[index] = isHovered;
    onStateChanged();
  }
}