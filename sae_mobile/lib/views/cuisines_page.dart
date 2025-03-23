import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../providers/supabase_provider.dart';

class CuisinesPage extends StatefulWidget {
  final SupabaseProvider supabaseProvider;
  
  const CuisinesPage({
    Key? key,
    required this.supabaseProvider,
  }) : super(key: key);

  @override
  _CuisinesPageState createState() => _CuisinesPageState();
}

class _CuisinesPageState extends State<CuisinesPage> {
  List<Map<String, dynamic>> allCuisines = [];
  List<Map<String, dynamic>> filteredCuisines = [];
  Map<int, int> restaurantCount = {};
  bool isLoading = true;
  
  int currentPage = 0;
  final int itemsPerPage = 8;
  int totalPages = 0;
  
  final TextEditingController searchController = TextEditingController();
  
  @override
  void initState() {
    super.initState();
    _loadCuisines();
    
    searchController.addListener(() {
      _filterCuisines();
    });
  }
  
  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }
  
  Future<void> _loadCuisines() async {
    try {
      final response = await Supabase.instance.client
          .from('cuisine')
          .select('*')
          .order('nomcuisine', ascending: true);
      
      List<Map<String, dynamic>> cuisinesList = List<Map<String, dynamic>>.from(response);
      
      final servirResponse = await Supabase.instance.client
          .from('servir')
          .select('idcuisine, idrestaurant');
      
      List<Map<String, dynamic>> servirList = List<Map<String, dynamic>>.from(servirResponse);
      
      Map<int, int> countMap = {};
      for (var servir in servirList) {
        int cuisineId = servir['idcuisine'];
        countMap[cuisineId] = (countMap[cuisineId] ?? 0) + 1;
      }
      
      setState(() {
        allCuisines = cuisinesList;
        filteredCuisines = cuisinesList;
        restaurantCount = countMap;
        isLoading = false;
        _updateTotalPages();
      });
    } catch (e) {
      print('Erreur lors du chargement des cuisines: $e');
      setState(() {
        isLoading = false;
      });
    }
  }

  void _filterCuisines() {
    final query = searchController.text.toLowerCase();
    
    setState(() {
      if (query.isEmpty) {
        filteredCuisines = allCuisines;
      } else {
        filteredCuisines = allCuisines
            .where((cuisine) => 
                cuisine['nomcuisine'].toString().toLowerCase().startsWith(query))
            .toList();
      }
      currentPage = 0;
      _updateTotalPages();
    });
  }
  
  void _updateTotalPages() {
    totalPages = (filteredCuisines.length / itemsPerPage).ceil();
    if (totalPages == 0) totalPages = 1;
  }
  
  List<Map<String, dynamic>> _getPaginatedCuisines() {
    final startIndex = currentPage * itemsPerPage;
    final endIndex = (startIndex + itemsPerPage) > filteredCuisines.length
        ? filteredCuisines.length
        : startIndex + itemsPerPage;
    
    if (startIndex >= filteredCuisines.length) {
      return [];
    }
    
    return filteredCuisines.sublist(startIndex, endIndex);
  }

  String _formatCuisineName(String text) {
    if (text.isEmpty) return text;
    
    String formattedText = text.replaceAll('_', ' ').replaceAll('-', ' ');
    
    return formattedText[0].toUpperCase() + formattedText.substring(1).toLowerCase();
  }

  void _navigateToRestaurantsByCuisine(int cuisineId, String cuisineName) {
    // Naviguer vers une page de restaurants filtrée par cuisine
    context.go('/restaurants', extra: {
      'cuisineId': cuisineId,
      'cuisineName': cuisineName,
      'filterByCuisine': true
    });
  }

  @override
  Widget build(BuildContext context) {
    final goldColor = Color(0xFFD4AF37);
    final paginatedCuisines = _getPaginatedCuisines();
    
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Types de cuisine',
          style: GoogleFonts.raleway(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: goldColor,
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => context.go('/home'),
        ),
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator(color: goldColor))
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: TextField(
                    controller: searchController,
                    decoration: InputDecoration(
                      hintText: 'Rechercher un type de cuisine...',
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
                  child: filteredCuisines.isEmpty
                    ? Center(
                        child: Text(
                          'Aucun type de cuisine trouvé commençant par "${searchController.text}"',
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
                            childAspectRatio: 1.0,
                            crossAxisSpacing: 16,
                            mainAxisSpacing: 16,
                          ),
                          itemCount: paginatedCuisines.length,
                          itemBuilder: (context, index) {
                            final cuisine = paginatedCuisines[index];
                            final nbRestaurants = restaurantCount[cuisine['idcuisine']] ?? 0;
                            final cuisineName = _formatCuisineName(cuisine['nomcuisine'] ?? 'Sans nom');
                            
                            return Card(
                              elevation: 4,
                              clipBehavior: Clip.antiAlias,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: InkWell(
                                onTap: () {
                                  // Ajouter la navigation vers les restaurants de cette cuisine
                                  _navigateToRestaurantsByCuisine(
                                    cuisine['idcuisine'],
                                    cuisineName
                                  );
                                },
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.stretch,
                                  children: [
                                    Expanded(
                                      flex: 1,
                                      child: Container(
                                        decoration: BoxDecoration(
                                          color: goldColor.withOpacity(0.1),
                                        ),
                                        child: Center(
                                          child: Image.asset(
                                            'assets/images/cuisine.webp',
                                            fit: BoxFit.cover,
                                            height: double.infinity,
                                            width: double.infinity,
                                          ),
                                        ),
                                      ),
                                    ),
                                    Expanded(
                                      flex: 1,
                                      child: Padding(
                                        padding: const EdgeInsets.all(8.0),
                                        child: Column(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            Text(
                                              cuisineName,
                                              style: GoogleFonts.raleway(
                                                fontSize: 16,
                                                fontWeight: FontWeight.bold,
                                              ),
                                              textAlign: TextAlign.center,
                                              overflow: TextOverflow.ellipsis,
                                              maxLines: 1,
                                            ),
                                            SizedBox(height: 8),
                                            Container(
                                              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                                              decoration: BoxDecoration(
                                                color: goldColor.withOpacity(0.1),
                                                borderRadius: BorderRadius.circular(12),
                                              ),
                                              child: Text(
                                                '$nbRestaurants restaurant${nbRestaurants > 1 ? 's' : ''}',
                                                style: GoogleFonts.raleway(
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.w500,
                                                  color: goldColor,
                                                ),
                                              ),
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
                
                if (!isLoading && filteredCuisines.isNotEmpty)
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