import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class CuisineDetailsViewModel extends ChangeNotifier {
  final int cuisineId;
  final TextEditingController searchController;
  
  List<Map<String, dynamic>> restaurants = [];
  List<Map<String, dynamic>> allRestaurants = [];
  List<Map<String, dynamic>> allCuisines = [];
  Map<int, List<int>> restaurantCuisines = {};
  Map<int, Map<String, dynamic>> cuisinesById = {};
  List<String> restaurantTypes = [];
  
  bool _isLoading = true;
  bool get isLoading => _isLoading;
  set isLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }
  
  int _currentPage = 0;
  int get currentPage => _currentPage;
  set currentPage(int value) {
    _currentPage = value;
    notifyListeners();
  }
  
  final int itemsPerPage = 8;
  int _totalPages = 0;
  int get totalPages => _totalPages;
  
  List<Map<String, dynamic>> _filteredRestaurants = [];
  List<Map<String, dynamic>> get filteredRestaurants => _filteredRestaurants;
  
  CuisineDetailsViewModel({
    required this.cuisineId,
    required this.searchController,
  }) {
    searchController.addListener(() {
      filterRestaurants();
    });
  }
  
  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }
  
  String formatRestaurantType(String type) {
    if (type.isEmpty) return 'Non spécifié';
    
    String formatted = type.replaceAll(RegExp(r'[-_]'), ' ');
    
    return formatted[0].toUpperCase() + formatted.substring(1);
  }
  
  Future<void> loadData() async {
    isLoading = true;
    
    try {
      final restaurantResponse = await Supabase.instance.client
          .from('restaurant')
          .select('*')
          .order('nomrestaurant', ascending: true);
      List<Map<String, dynamic>> restaurantsList = List<Map<String, dynamic>>.from(restaurantResponse);
      
      final cuisineResponse = await Supabase.instance.client
          .from('cuisine')
          .select('*')
          .order('nomcuisine', ascending: true);
      List<Map<String, dynamic>> cuisinesList = List<Map<String, dynamic>>.from(cuisineResponse);
      
      final servirResponse = await Supabase.instance.client
          .from('servir')
          .select('idrestaurant, idcuisine');
      List<Map<String, dynamic>> servirList = List<Map<String, dynamic>>.from(servirResponse);
      
      Map<int, Map<String, dynamic>> cuisinesMap = {};
      for (var cuisine in cuisinesList) {
        cuisinesMap[cuisine['idcuisine']] = cuisine;
      }
      
      Map<int, List<int>> restaurantCuisinesMap = {};
      for (var servir in servirList) {
        int restaurantId = servir['idrestaurant'];
        int cuisineId = servir['idcuisine'];
        if (!restaurantCuisinesMap.containsKey(restaurantId)) {
          restaurantCuisinesMap[restaurantId] = [];
        }
        restaurantCuisinesMap[restaurantId]!.add(cuisineId);
      }
      
      List<Map<String, dynamic>> cuisineRestaurants = restaurantsList
          .where((restaurant) {
            final int restaurantId = restaurant['idrestaurant'];
            return restaurantCuisinesMap.containsKey(restaurantId) &&
                   restaurantCuisinesMap[restaurantId]!.contains(cuisineId);
          })
          .toList();
      
      allRestaurants = restaurantsList;
      allCuisines = cuisinesList;
      restaurantCuisines = restaurantCuisinesMap;
      cuisinesById = cuisinesMap;
      restaurants = cuisineRestaurants;
      _filteredRestaurants = cuisineRestaurants;
      
      updateTotalPages();
      isLoading = false;
    } catch (e) {
      print('Erreur lors du chargement des données: $e');
      isLoading = false;
    }
  }
  
  void filterRestaurants() {
    final query = searchController.text.toLowerCase();
    
    if (query.isEmpty) {
      _filteredRestaurants = restaurants;
    } else {
      _filteredRestaurants = restaurants
          .where((restaurant) => 
              restaurant['nomrestaurant'].toString().toLowerCase().startsWith(query))
          .toList();
    }
    _currentPage = 0;
    updateTotalPages();
    notifyListeners();
  }
  
  void updateTotalPages() {
    _totalPages = (_filteredRestaurants.length / itemsPerPage).ceil();
    if (_totalPages == 0) _totalPages = 1;
  }
  
  List<Map<String, dynamic>> getPaginatedRestaurants() {
    final startIndex = _currentPage * itemsPerPage;
    final endIndex = (startIndex + itemsPerPage) > _filteredRestaurants.length
        ? _filteredRestaurants.length
        : startIndex + itemsPerPage;
    
    if (startIndex >= _filteredRestaurants.length) {
      return [];
    }
    
    return _filteredRestaurants.sublist(startIndex, endIndex);
  }
  
  void nextPage() {
    if (_currentPage < _totalPages - 1) {
      _currentPage++;
      notifyListeners();
    }
  }
  
  void previousPage() {
    if (_currentPage > 0) {
      _currentPage--;
      notifyListeners();
    }
  }
}