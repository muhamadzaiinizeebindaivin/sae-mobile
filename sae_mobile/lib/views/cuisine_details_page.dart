import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../providers/supabase_provider.dart';

class CuisineDetailsPage extends StatefulWidget {
  final SupabaseProvider supabaseProvider;
  final int cuisineId;
  final String cuisineName;
  
  const CuisineDetailsPage({
    Key? key,
    required this.supabaseProvider,
    required this.cuisineId,
    required this.cuisineName,
  }) : super(key: key);

  @override
  _CuisineDetailsPageState createState() => _CuisineDetailsPageState();
}

class _CuisineDetailsPageState extends State<CuisineDetailsPage> {
  List<Map<String, dynamic>> restaurants = [];
  List<Map<String, dynamic>> allRestaurants = [];
  List<Map<String, dynamic>> allCuisines = [];
  Map<int, List<int>> restaurantCuisines = {};
  Map<int, Map<String, dynamic>> cuisinesById = {};
  List<String> restaurantTypes = [];
  bool isLoading = true;
  
  int currentPage = 0;
  final int itemsPerPage = 8;
  int totalPages = 0;
  
  final TextEditingController searchController = TextEditingController();
  List<Map<String, dynamic>> filteredRestaurants = [];
  
  @override
  void initState() {
    super.initState();
    _loadData();
    
    searchController.addListener(() {
      _filterRestaurants();
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
  
  Future<void> _loadData() async {
    setState(() {
      isLoading = true;
    });
    
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
                   restaurantCuisinesMap[restaurantId]!.contains(widget.cuisineId);
          })
          .toList();
      
      setState(() {
        allRestaurants = restaurantsList;
        allCuisines = cuisinesList;
        restaurantCuisines = restaurantCuisinesMap;
        cuisinesById = cuisinesMap;
        restaurants = cuisineRestaurants;
        filteredRestaurants = cuisineRestaurants;
        isLoading = false;
        _updateTotalPages();
      });
    } catch (e) {
      print('Erreur lors du chargement des données: $e');
      setState(() {
        isLoading = false;
      });
    }
  }
  
  void _filterRestaurants() {
    final query = searchController.text.toLowerCase();
    
    setState(() {
      if (query.isEmpty) {
        filteredRestaurants = restaurants;
      } else {
        filteredRestaurants = restaurants
            .where((restaurant) => 
                restaurant['nomrestaurant'].toString().toLowerCase().startsWith(query))
            .toList();
      }
      currentPage = 0;
      _updateTotalPages();
    });
  }
  
  void _updateTotalPages() {
    totalPages = (filteredRestaurants.length / itemsPerPage).ceil();
    if (totalPages == 0) totalPages = 1;
  }
  
  List<Map<String, dynamic>> _getPaginatedRestaurants() {
    final startIndex = currentPage * itemsPerPage;
    final endIndex = (startIndex + itemsPerPage) > filteredRestaurants.length
        ? filteredRestaurants.length
        : startIndex + itemsPerPage;
    
    if (startIndex >= filteredRestaurants.length) {
      return [];
    }
    
    return filteredRestaurants.sublist(startIndex, endIndex);
  }
  
  @override
  Widget build(BuildContext context) {
    final goldColor = Color(0xFFD4AF37);
    final paginatedRestaurants = _getPaginatedRestaurants();
    
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Cuisine ${widget.cuisineName}',
          style: GoogleFonts.raleway(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: goldColor,
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => context.go('/cuisines'),
        ),
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator(color: goldColor))
          : Column(
              children: [
                Container(
                  height: 120,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: goldColor.withOpacity(0.1),
                  ),
                  child: Stack(
                    children: [
                      Positioned.fill(
                        child: Opacity(
                          opacity: 0.7,
                          child: Image.asset(
                            'assets/images/cuisine.webp',
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                      Positioned.fill(
                        child: Container(
                          color: Colors.black.withOpacity(0.3),
                        ),
                      ),
                      Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              widget.cuisineName,
                              style: GoogleFonts.raleway(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            SizedBox(height: 8),
                            Container(
                              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                              decoration: BoxDecoration(
                                color: goldColor,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                '${filteredRestaurants.length} restaurant${filteredRestaurants.length > 1 ? 's' : ''}',
                                style: GoogleFonts.raleway(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: TextField(
                    controller: searchController,
                    decoration: InputDecoration(
                      hintText: 'Rechercher un restaurant...',
                      prefixIcon: Icon(Icons.search, color: goldColor),
                      suffixIcon: searchController.text.isNotEmpty
                          ? IconButton(
                              icon: Icon(Icons.clear),
                              onPressed: () {
                                searchController.clear();
                              },
                            )
                          : null,
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: goldColor.withOpacity(0.5)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: goldColor),
                      ),
                    ),
                  ),
                ),
                
                Expanded(
                  child: filteredRestaurants.isEmpty
                    ? Center(
                        child: Text(
                          searchController.text.isNotEmpty
                            ? 'Aucun restaurant trouvé pour "${searchController.text}"'
                            : 'Aucun restaurant proposant cette cuisine',
                          style: GoogleFonts.raleway(
                            fontSize: 18,
                            color: Colors.black87,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      )
                    : Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0),
                        child: GridView.builder(
                          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            childAspectRatio: 0.85,
                            crossAxisSpacing: 16,
                            mainAxisSpacing: 16,
                          ),
                          itemCount: paginatedRestaurants.length,
                          itemBuilder: (context, index) {
                            final restaurant = paginatedRestaurants[index];
                            final restaurantName = restaurant['nomrestaurant'] ?? 'Sans nom';
                            final restaurantType = formatRestaurantType(restaurant['typerestaurant']?.toString() ?? '');
                            
                            return Card(
                              elevation: 4,
                              clipBehavior: Clip.antiAlias,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: InkWell(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.stretch,
                                  children: [
                                    Expanded(
                                      flex: 2,
                                      child: Image.asset(
                                        'assets/images/restaurant.jpg',
                                        fit: BoxFit.cover,
                                      ),
                                    ),
                                    Expanded(
                                      flex: 1,
                                      child: Padding(
                                        padding: const EdgeInsets.all(8.0),
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            Text(
                                              restaurantName,
                                              style: GoogleFonts.raleway(
                                                fontSize: 16,
                                                fontWeight: FontWeight.bold,
                                              ),
                                              overflow: TextOverflow.ellipsis,
                                              maxLines: 1,
                                            ),
                                            SizedBox(height: 4),
                                            Row(
                                              children: [
                                                Icon(Icons.store, size: 16, color: goldColor),
                                                SizedBox(width: 4),
                                                Expanded(
                                                  child: Text(
                                                    restaurantType,
                                                    style: GoogleFonts.raleway(
                                                      fontSize: 12,
                                                      color: Colors.black54,
                                                    ),
                                                    overflow: TextOverflow.ellipsis,
                                                    maxLines: 1,
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
                              ),
                            );
                          },
                        ),
                      ),
                ),
                
                if (!isLoading && filteredRestaurants.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        IconButton(
                          icon: Icon(Icons.arrow_back_ios),
                          color: currentPage > 0 ? goldColor : Colors.grey,
                          onPressed: currentPage > 0
                              ? () {
                                  setState(() {
                                    currentPage--;
                                  });
                                }
                              : null,
                        ),
                        SizedBox(width: 8),
                        Text(
                          '${currentPage + 1} / $totalPages',
                          style: GoogleFonts.raleway(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(width: 8),
                        IconButton(
                          icon: Icon(Icons.arrow_forward_ios),
                          color: currentPage < totalPages - 1 ? goldColor : Colors.grey,
                          onPressed: currentPage < totalPages - 1
                              ? () {
                                  setState(() {
                                    currentPage++;
                                  });
                                }
                              : null,
                        ),
                      ],
                    ),
                  ),
              ],
            ),
    );
  }
}