// lib/viewmodels/favoris_viewmodel.dart
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class FavorisViewModel extends ChangeNotifier {
  List<Map<String, dynamic>> favorisRestaurants = [];
  bool isLoading = false;
  String? errorMessage;

  Future<void> loadFavoris() async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null || user.email == null) {
        throw Exception('Utilisateur non connecté');
      }

      final userResponse = await Supabase.instance.client
          .from('utilisateur')
          .select('idutilisateur')
          .eq('emailutilisateur', user.email!)
          .single();

      int idUtilisateur = userResponse['idutilisateur'];

      final favorisResponse = await Supabase.instance.client
          .from('aimer')
          .select('idrestaurant')
          .eq('idutilisateur', idUtilisateur);

      List<int> favorisIds =
          favorisResponse.map<int>((fav) => fav['idrestaurant'] as int).toList();

      if (favorisIds.isNotEmpty) {
        final restaurantsResponse = await Supabase.instance.client
            .from('restaurant')
            .select('*')
            .inFilter('idrestaurant', favorisIds)
            .order('nomrestaurant', ascending: true);

        favorisRestaurants =
            List<Map<String, dynamic>>.from(restaurantsResponse);
      } else {
        favorisRestaurants = [];
      }
    } catch (e) {
      errorMessage = 'Erreur lors du chargement des favoris : $e';
      print(errorMessage);
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> toggleFavori(int restaurantId, BuildContext context) async {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null || user.email == null) {
        throw Exception('Utilisateur non connecté');
      }

      final userResponse = await Supabase.instance.client
          .from('utilisateur')
          .select('idutilisateur')
          .eq('emailutilisateur', user.email!)
          .single();

      int idUtilisateur = userResponse['idutilisateur'];
      bool isFavori = favorisRestaurants
          .any((restaurant) => restaurant['idrestaurant'] == restaurantId);

      if (isFavori) {
        await Supabase.instance.client
            .from('aimer')
            .delete()
            .match({'idutilisateur': idUtilisateur, 'idrestaurant': restaurantId});

        favorisRestaurants.removeWhere(
            (restaurant) => restaurant['idrestaurant'] == restaurantId);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Restaurant retiré des favoris'),
            backgroundColor: Colors.grey,
          ),
        );
      } else {
        await Supabase.instance.client.from('aimer').insert({
          'idutilisateur': idUtilisateur,
          'idrestaurant': restaurantId,
          'dateaime': DateTime.now().toIso8601String().split('T')[0],
        });

        final restaurantResponse = await Supabase.instance.client
            .from('restaurant')
            .select('*')
            .eq('idrestaurant', restaurantId)
            .single();

        favorisRestaurants.add(restaurantResponse);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Restaurant ajouté aux favoris'),
            backgroundColor: Color(0xFFD4AF37),
          ),
        );
      }
      notifyListeners();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur: Impossible de modifier les favoris'),
          backgroundColor: Colors.red,
        ),
      );
      print('Erreur lors de la modification des favoris : $e');
    }
  }
}