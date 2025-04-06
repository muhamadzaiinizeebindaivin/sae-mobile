import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class RestaurantsViewModel extends ChangeNotifier {
  List<int> favoris = [];
  List<Map<String, dynamic>> allRestaurants = [];
  List<Map<String, dynamic>> filteredRestaurants = [];
  List<Map<String, dynamic>> allCuisines = [];
  Map<int, List<int>> restaurantCuisines = {};
  Map<int, Map<String, dynamic>> cuisinesById = {};
  List<String> restaurantTypes = [];
  String? selectedType;
  int? selectedCuisineId;
  bool isLoading = true;
  int itemsPerPage = 30;
  int currentPage = 0;
  int totalPages = 0;
  String searchQuery = '';
  bool isUserLoggedIn = false;

  bool? isVegetarian;
  bool? isVegan;
  bool? hasDelivery;
  bool? hasTakeaway;
  bool? hasDrive;
  bool? hasInternet;
  bool? isHandicapAccessible;
  bool? allowsSmoking;

  final TextEditingController searchController = TextEditingController();

  RestaurantsViewModel() {
    searchController.addListener(_applyFilters);
    _checkUserLoginStatus();
    _loadData();
    _loadFavoris();
  }

  Future<void> _loadData() async {
    isLoading = true;
    notifyListeners();
    try {
      final restaurantResponse = await Supabase.instance.client
          .from('restaurant')
          .select('*')
          .order('nomrestaurant', ascending: true);
      allRestaurants = List<Map<String, dynamic>>.from(restaurantResponse);

      final cuisineResponse = await Supabase.instance.client
          .from('cuisine')
          .select('*')
          .order('nomcuisine', ascending: true);
      allCuisines = List<Map<String, dynamic>>.from(cuisineResponse);

      final servirResponse = await Supabase.instance.client
          .from('servir')
          .select('idrestaurant, idcuisine');
      List<Map<String, dynamic>> servirList =
          List<Map<String, dynamic>>.from(servirResponse);

      cuisinesById = {
        for (var cuisine in allCuisines) cuisine['idcuisine']: cuisine
      };

      restaurantCuisines = {};
      for (var servir in servirList) {
        int restaurantId = servir['idrestaurant'];
        int cuisineId = servir['idcuisine'];
        restaurantCuisines
            .putIfAbsent(restaurantId, () => [])
            .add(cuisineId);
      }

      restaurantTypes = allRestaurants
          .map((r) => r['typerestaurant']?.toString() ?? '')
          .where((type) => type.isNotEmpty)
          .toSet()
          .toList()
        ..sort();

      _applyFilters();
      isLoading = false;
      notifyListeners();
    } catch (e) {
      print('Erreur lors du chargement des données: $e');
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _checkUserLoginStatus() async {
    final user = Supabase.instance.client.auth.currentUser;
    isUserLoggedIn = user != null && user.email != null;
    notifyListeners();
  }

  Future<void> _loadFavoris() async {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null || user.email == null) return;

      final userResponse = await Supabase.instance.client
          .from('utilisateur')
          .select('idutilisateur')
          .eq('emailutilisateur', user.email!)
          .single();

      int idUtilisateur = userResponse['idutilisateur'];

      final response = await Supabase.instance.client
          .from('aimer')
          .select('idrestaurant')
          .eq('idutilisateur', idUtilisateur);

      favoris = response.map<int>((fav) => fav['idrestaurant'] as int).toList();
      notifyListeners();
    } catch (e) {
      print('Erreur lors du chargement des favoris: $e');
    }
  }

  Future<void> toggleFavori(int restaurantId, BuildContext context) async {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null || user.email == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Vous devez être connecté pour ajouter des favoris')),
        );
        return;
      }

      final userResponse = await Supabase.instance.client
          .from('utilisateur')
          .select('idutilisateur')
          .eq('emailutilisateur', user.email!)
          .single();

      int idUtilisateur = userResponse['idutilisateur'];

      if (favoris.contains(restaurantId)) {
        favoris.remove(restaurantId);
        await Supabase.instance.client
            .from('aimer')
            .delete()
            .match({'idutilisateur': idUtilisateur, 'idrestaurant': restaurantId});
      } else {
        favoris.add(restaurantId);
        await Supabase.instance.client.from('aimer').insert({
          'idutilisateur': idUtilisateur,
          'idrestaurant': restaurantId,
          'dateaime': DateTime.now().toIso8601String().split('T')[0]
        });
      }
      notifyListeners();
    } catch (e) {
      print('Erreur lors de la modification des favoris: $e');
    }
  }

  void _applyFilters() {
    searchQuery = searchController.text;
    filteredRestaurants = allRestaurants.where((restaurant) {
      final name = restaurant['nomrestaurant']?.toString().toLowerCase() ?? '';
      final type = restaurant['typerestaurant']?.toString() ?? '';
      final restaurantId = restaurant['idrestaurant'];

      bool matchesSearch = searchQuery.isEmpty || name.startsWith(searchQuery.toLowerCase());
      bool matchesType = selectedType == null || type == selectedType;
      bool matchesCuisine = selectedCuisineId == null ||
          (restaurantCuisines[restaurantId]?.contains(selectedCuisineId) ?? false);

      bool matchesVegetarian = isVegetarian == null || restaurant['vegetarienrestaurant'] == isVegetarian;
      bool matchesVegan = isVegan == null || restaurant['veganrestaurant'] == isVegan;
      bool matchesDelivery = hasDelivery == null || restaurant['livraisonrestaurant'] == hasDelivery;
      bool matchesTakeaway = hasTakeaway == null || restaurant['emporterrestaurant'] == hasTakeaway;
      bool matchesDrive = hasDrive == null || restaurant['driverestaurant'] == hasDrive;
      bool matchesInternet = hasInternet == null || restaurant['internetrestaurant'] == hasInternet;
      bool matchesHandicap = isHandicapAccessible == null || restaurant['handicaprestaurant'] == isHandicapAccessible;
      bool matchesSmoking = allowsSmoking == null || restaurant['fumerrestaurant'] == allowsSmoking;

      return matchesSearch &&
          matchesType &&
          matchesCuisine &&
          matchesVegetarian &&
          matchesVegan &&
          matchesDelivery &&
          matchesTakeaway &&
          matchesDrive &&
          matchesInternet &&
          matchesHandicap &&
          matchesSmoking;
    }).toList();

    currentPage = 0;
    totalPages = (filteredRestaurants.length / itemsPerPage).ceil();
    if (totalPages == 0) totalPages = 1;
    notifyListeners();
  }

  List<Map<String, dynamic>> getPaginatedData() {
    if (filteredRestaurants.isEmpty) return [];
    final startIndex = currentPage * itemsPerPage;
    final endIndex = (currentPage + 1) * itemsPerPage;
    if (startIndex >= filteredRestaurants.length) return [];
    return filteredRestaurants.sublist(
      startIndex,
      endIndex > filteredRestaurants.length ? filteredRestaurants.length : endIndex,
    );
  }

  void setFilter(String filter, bool? value) {
    switch (filter) {
      case 'vegetarian':
        isVegetarian = value;
        break;
      case 'vegan':
        isVegan = value;
        break;
      case 'delivery':
        hasDelivery = value;
        break;
      case 'takeaway':
        hasTakeaway = value;
        break;
      case 'drive':
        hasDrive = value;
        break;
      case 'internet':
        hasInternet = value;
        break;
      case 'handicap':
        isHandicapAccessible = value;
        break;
      case 'smoking':
        allowsSmoking = value;
        break;
    }
    _applyFilters();
  }

  void setSelectedType(String? value) {
    selectedType = value;
    _applyFilters();
  }

  void setSelectedCuisineId(int? value) {
    selectedCuisineId = value;
    _applyFilters();
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

  String formatRestaurantType(String? type) {
    if (type == null || type.isEmpty) return 'Standard';
    String formattedType = type.replaceAll('-', ' ').replaceAll('_', ' ').replaceAll('cafe', 'café');
    return formattedType.split(' ').map((word) => word.isEmpty ? word : (word[0].toUpperCase() + word.substring(1).toLowerCase())).join(' ');
  }

  String formatCuisineName(String text) {
    if (text.isEmpty) return text;
    String formattedText = text.replaceAll('_', ' ').replaceAll('-', ' ');
    return formattedText[0].toUpperCase() + formattedText.substring(1).toLowerCase();
  }

  String? get selectedCuisineName {
    if (selectedCuisineId == null) return null;
    final cuisine = cuisinesById[selectedCuisineId];
    return cuisine != null ? formatCuisineName(cuisine['nomcuisine'] ?? 'Sans nom') : null;
  }
}