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
  List<int> favoris = [];
  List<Map<String, dynamic>> allCuisines = [];
  List<Map<String, dynamic>> filteredCuisines = [];
  Map<int, int> restaurantCount = {};
  bool isLoading = true;
  bool isUserLoggedIn = false;
  
  int currentPage = 0;
  final int itemsPerPage = 8;
  int totalPages = 0;
  
  final TextEditingController searchController = TextEditingController();
  String activeFilter = 'Tous';
  
  @override
  void initState() {
    super.initState();
    _checkUserLoginStatus();
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
        if (activeFilter == 'Tous') {
          filteredCuisines = allCuisines;
        } else if (activeFilter == 'Favoris') {
          filteredCuisines = allCuisines
              .where((cuisine) => favoris.contains(cuisine['idcuisine']))
              .toList();
        } else if (activeFilter == 'Non favoris') {
          filteredCuisines = allCuisines
              .where((cuisine) => !favoris.contains(cuisine['idcuisine']))
              .toList();
        }
      } else {
        filteredCuisines = allCuisines
            .where((cuisine) => 
                cuisine['nomcuisine'].toString().toLowerCase().startsWith(query))
            .toList();
        if (activeFilter == 'Favoris') {
          filteredCuisines = filteredCuisines
              .where((cuisine) => favoris.contains(cuisine['idcuisine']))
              .toList();
        } else if (activeFilter == 'Non favoris') {
          filteredCuisines = filteredCuisines
              .where((cuisine) => !favoris.contains(cuisine['idcuisine']))
              .toList();
        }
      }
      currentPage = 0;
      _updateTotalPages();
    });
  }

  Future<void> _checkUserLoginStatus() async {
    final user = Supabase.instance.client.auth.currentUser;
    setState(() {
      isUserLoggedIn = user != null && user.email != null;
    });
    
    if (isUserLoggedIn) {
      try {
        final userResponse = await Supabase.instance.client
            .from('utilisateur')
            .select('idutilisateur')
            .eq('emailutilisateur', user!.email!)
            .single();
        
        final favorisResponse = await Supabase.instance.client
            .from('preferer')
            .select('idcuisine')
            .eq('idutilisateur', userResponse['idutilisateur']);
        
        setState(() {
          favoris = favorisResponse.map((f) => f['idcuisine'] as int).toList();
        });
      } catch (e) {
        print('Erreur lors du chargement des favoris: $e');
      }
    }
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
    context.push('/cuisine-details', extra: {
      'cuisineId': cuisineId,
      'cuisineName': cuisineName,
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
          onPressed: () => context.pop(),
        ),
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator(color: goldColor))
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      TextField(
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
                      if (isUserLoggedIn) ...[
                        SizedBox(height: 10),
                        Row(
                          children: [
                            Expanded(
                              child: ElevatedButton(
                                onPressed: () {
                                  setState(() {
                                    filteredCuisines = allCuisines;
                                    currentPage = 0;
                                    _updateTotalPages();
                                    activeFilter = 'Tous';
                                  });
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: activeFilter == 'Tous' ? goldColor : Colors.white,
                                  foregroundColor: activeFilter == 'Tous' ? Colors.white : goldColor,
                                  padding: EdgeInsets.symmetric(vertical: 10),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    side: activeFilter != 'Tous' 
                                        ? BorderSide(color: goldColor) 
                                        : BorderSide.none,
                                  ),
                                ),
                                child: Text(
                                  'Tous',
                                  style: GoogleFonts.raleway(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                            SizedBox(width: 8),
                            Expanded(
                              child: ElevatedButton(
                                onPressed: () {
                                  setState(() {
                                    filteredCuisines = allCuisines
                                        .where((cuisine) => favoris.contains(cuisine['idcuisine']))
                                        .toList();
                                    currentPage = 0;
                                    _updateTotalPages();
                                    activeFilter = 'Favoris';
                                  });
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: activeFilter == 'Favoris' ? goldColor : Colors.white,
                                  foregroundColor: activeFilter == 'Favoris' ? Colors.white : goldColor,
                                  padding: EdgeInsets.symmetric(vertical: 10),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    side: activeFilter != 'Favoris' 
                                        ? BorderSide(color: goldColor) 
                                        : BorderSide.none,
                                  ),
                                ),
                                child: Text(
                                  'Favoris',
                                  style: GoogleFonts.raleway(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                            SizedBox(width: 8),
                            Expanded(
                              child: ElevatedButton(
                                onPressed: () {
                                  setState(() {
                                    filteredCuisines = allCuisines
                                        .where((cuisine) => !favoris.contains(cuisine['idcuisine']))
                                        .toList();
                                    currentPage = 0;
                                    _updateTotalPages();
                                    activeFilter = 'Non favoris';
                                  });
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: activeFilter == 'Non favoris' ? goldColor : Colors.white,
                                  foregroundColor: activeFilter == 'Non favoris' ? Colors.white : goldColor,
                                  padding: EdgeInsets.symmetric(vertical: 10),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    side: activeFilter != 'Non favoris' 
                                        ? BorderSide(color: goldColor) 
                                        : BorderSide.none,
                                  ),
                                ),
                                child: Text(
                                  'Non favoris',
                                  style: GoogleFonts.raleway(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
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
                            childAspectRatio: 0.8,
                            crossAxisSpacing: 16,
                            mainAxisSpacing: 16,
                          ),
                          itemCount: paginatedCuisines.length,
                          itemBuilder: (context, index) {
                            final cuisine = paginatedCuisines[index];
                            final nbRestaurants = restaurantCount[cuisine['idcuisine']] ?? 0;
                            final cuisineName = _formatCuisineName(cuisine['nomcuisine'] ?? 'Sans nom');
                            final cuisineId = cuisine['idcuisine'];
                            final isFavori = favoris.contains(cuisineId);

                            return Card(
                              elevation: 4,
                              clipBehavior: Clip.antiAlias,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: InkWell(
                                onTap: () {
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
                                            SizedBox(height: 10),
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
                                            if (isUserLoggedIn) 
                                              IconButton(
                                                icon: Icon(
                                                  isFavori ? Icons.favorite : Icons.favorite_border,
                                                  color: isFavori ? Colors.red : Colors.grey,
                                                ),
                                                onPressed: () => _toggleFavori(cuisineId),
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

  Future<void> _toggleFavori(int cuisineId) async {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null || user.email == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Vous devez être connecté pour ajouter des favoris',
              textAlign: TextAlign.center, 
              style: GoogleFonts.raleway(
                fontWeight: FontWeight.bold, 
              ),
            ),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
      
      final userResponse = await Supabase.instance.client
          .from('utilisateur')
          .select('idutilisateur')
          .eq('emailutilisateur', user.email!)
          .single();
      
      int idUtilisateur = userResponse['idutilisateur'];
      
      setState(() {
        if (favoris.contains(cuisineId)) {
          favoris.remove(cuisineId);
        } else {
          favoris.add(cuisineId);
        }
      });

      if (!favoris.contains(cuisineId)) {
        await Supabase.instance.client
            .from('preferer')
            .delete()
            .match({'idutilisateur': idUtilisateur, 'idcuisine': cuisineId});
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Cuisine retiré des favoris',
              textAlign: TextAlign.center, 
              style: GoogleFonts.raleway(
                fontWeight: FontWeight.bold, 
              ),
            ),
            backgroundColor: Colors.grey,
          ),
        );
      } else {
        await Supabase.instance.client.from('preferer').insert({
          'dateprefere': DateTime.now().toIso8601String().split('T')[0],
          'idutilisateur': idUtilisateur,
          'idcuisine': cuisineId,
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Cuisine ajouté aux favoris',
              textAlign: TextAlign.center, 
              style: GoogleFonts.raleway(
                fontWeight: FontWeight.bold, 
              ),
            ),
            backgroundColor: Color(0xFFD4AF37),
          ),
        );
      }
      
      _filterCuisines();
    } catch (e) {
      setState(() {
        if (favoris.contains(cuisineId)) {
          favoris.remove(cuisineId);
        } else {
          favoris.add(cuisineId);
        }
      });
      
      print('Erreur lors de la modification des favoris: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur : Impossible de modifier les favoris',
            textAlign: TextAlign.center,
            style: GoogleFonts.raleway(
              fontWeight: FontWeight.bold, 
            ),
          ),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}