import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class FavorisViewModel extends ChangeNotifier {
  List<int> favoris = [];
  List<Map<String, dynamic>> favoriteCuisines = [];
  List<Map<String, dynamic>> filteredCuisines = [];
  Map<int, int> restaurantCount = {};
  bool isLoading = true;

  int currentPage = 0;
  final int itemsPerPage = 8;
  int totalPages = 0;

  final TextEditingController searchController = TextEditingController();

  FavorisViewModel() {
    searchController.addListener(_filterCuisines);
    _loadFavoris();
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  Future<void> _loadFavoris() async {
    isLoading = true;
    notifyListeners();
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null || user.email == null) {
        isLoading = false;
        favoris = [];
        favoriteCuisines = [];
        filteredCuisines = [];
        notifyListeners();
        return;
      }

      final userResponse = await Supabase.instance.client
          .from('utilisateur')
          .select('idutilisateur')
          .eq('emailutilisateur', user.email!)
          .single();

      int idUtilisateur = userResponse['idutilisateur'];

      final favResponse = await Supabase.instance.client
          .from('preferer')
          .select('idcuisine')
          .eq('idutilisateur', idUtilisateur);

      List<int> favorisIds =
          favResponse.map<int>((fav) => fav['idcuisine'] as int).toList();

      if (favorisIds.isEmpty) {
        favoris = [];
        favoriteCuisines = [];
        filteredCuisines = [];
        isLoading = false;
        notifyListeners();
        return;
      }

      final cuisineResponse = await Supabase.instance.client
          .from('cuisine')
          .select('*')
          .filter('idcuisine', 'in', favorisIds)
          .order('nomcuisine', ascending: true);

      List<Map<String, dynamic>> cuisinesList =
          List<Map<String, dynamic>>.from(cuisineResponse);

      final servirResponse = await Supabase.instance.client
          .from('servir')
          .select('idcuisine, idrestaurant')
          .filter('idcuisine', 'in', favorisIds);

      List<Map<String, dynamic>> servirList =
          List<Map<String, dynamic>>.from(servirResponse);

      Map<int, int> countMap = {};
      for (var servir in servirList) {
        int cuisineId = servir['idcuisine'];
        countMap[cuisineId] = (countMap[cuisineId] ?? 0) + 1;
      }

      favoris = favorisIds;
      favoriteCuisines = cuisinesList;
      filteredCuisines = cuisinesList;
      restaurantCount = countMap;
      isLoading = false;
      _updateTotalPages();
      notifyListeners();
    } catch (e) {
      print('Erreur lors du chargement des favoris: $e');
      isLoading = false;
      notifyListeners();
    }
  }

  void _filterCuisines() {
    final query = searchController.text.toLowerCase();

    if (query.isEmpty) {
      filteredCuisines = favoriteCuisines;
    } else {
      filteredCuisines = favoriteCuisines
          .where((cuisine) =>
              cuisine['nomcuisine'].toString().toLowerCase().startsWith(query))
          .toList();
    }
    currentPage = 0;
    _updateTotalPages();
    notifyListeners();
  }

  void _updateTotalPages() {
    totalPages = (filteredCuisines.length / itemsPerPage).ceil();
    if (totalPages == 0) totalPages = 1;
  }

  List<Map<String, dynamic>> getPaginatedCuisines() {
    final startIndex = currentPage * itemsPerPage;
    final endIndex = (startIndex + itemsPerPage) > filteredCuisines.length
        ? filteredCuisines.length
        : startIndex + itemsPerPage;

    if (startIndex >= filteredCuisines.length) {
      return [];
    }

    return filteredCuisines.sublist(startIndex, endIndex);
  }

  String formatCuisineName(String text) {
    if (text.isEmpty) return text;
    String formattedText = text.replaceAll('_', ' ').replaceAll('-', ' ');
    return formattedText[0].toUpperCase() + formattedText.substring(1).toLowerCase();
  }

  Future<void> toggleFavori(int cuisineId, BuildContext context) async {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null || user.email == null) return;

      final userResponse = await Supabase.instance.client
          .from('utilisateur')
          .select('idutilisateur')
          .eq('emailutilisateur', user.email!)
          .single();

      int idUtilisateur = userResponse['idutilisateur'];

      bool isFavori = favoris.contains(cuisineId);

      if (isFavori) {
        await Supabase.instance.client
            .from('preferer')
            .delete()
            .match({'idutilisateur': idUtilisateur, 'idcuisine': cuisineId});

        favoris.remove(cuisineId);
        favoriteCuisines.removeWhere((c) => c['idcuisine'] == cuisineId);
        _filterCuisines();

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Cuisine retirée des favoris'),
            backgroundColor: Colors.grey,
          ),
        );
      } else {
        await Supabase.instance.client.from('preferer').insert({
          'idutilisateur': idUtilisateur,
          'idcuisine': cuisineId,
          'dateprefere': DateTime.now().toIso8601String().split('T')[0],
        });

        await _loadFavoris(); // Recharger pour ajouter la nouvelle cuisine
      }
      notifyListeners();
    } catch (e) {
      print('Erreur lors de la modification des favoris: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur: Impossible de modifier les favoris'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void nextPage() {
    if (currentPage < totalPages - 1) {
      currentPage++;
      notifyListeners();
    }
  }

  void previousPage() {
    if (currentPage > 0) {
      currentPage--;
      notifyListeners();
    }
  }
}