import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../providers/supabase_provider.dart';

class FavorisCuisinePage extends StatefulWidget {
  final SupabaseProvider supabaseProvider;
  
  const FavorisCuisinePage({
    Key? key,
    required this.supabaseProvider,
  }) : super(key: key);

  @override
  _FavorisCuisinePageState createState() => _FavorisCuisinePageState();
}

class _FavorisCuisinePageState extends State<FavorisCuisinePagee> {
  List<Map<String, dynamic>> allFavoris = [];
  List<Map<String, dynamic>> filteredFavoris = [];
  bool isLoading = true;
  
  int currentPage = 0;
  final int itemsPerPage = 8;
  int totalPages = 0;
  
  final TextEditingController searchController = TextEditingController();
  
  @override
  void initState() {
    super.initState();
    _loadFavoris();
    
    searchController.addListener(() {
      _filterFavoris();
    });
  }
  
  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }
  
  Future<void> _loadFavoris() async {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      
      if (user == null) {
        setState(() {
          isLoading = false;
        });
        return;
      }
      
      final response = await Supabase.instance.client
          .from('favoris')
          .select('*, restaurant:idrestaurant(*)')
          .eq('iduser', user.id);
      
      List<Map<String, dynamic>> favorisList = List<Map<String, dynamic>>.from(response);
      
      setState(() {
        allFavoris = favorisList;
        filteredFavoris = favorisList;
        isLoading = false;
        _updateTotalPages();
      });
    } catch (e) {
      print('Erreur lors du chargement des favoris: $e');
      setState(() {
        isLoading = false;
      });
    }
  }

  void _filterFavoris() {
    final query = searchController.text.toLowerCase();
    
    setState(() {
      if (query.isEmpty) {
        filteredFavoris = allFavoris;
      } else {
        filteredFavoris = allFavoris
            .where((favori) => 
                favori['restaurant']['nomrestaurant'].toString().toLowerCase().startsWith(query))
            .toList();
      }
      currentPage = 0;
      _updateTotalPages();
    });
  }
  
  void _updateTotalPages() {
    totalPages = (filteredFavoris.length / itemsPerPage).ceil();
    if (totalPages == 0) totalPages = 1;
  }
  
  List<Map<String, dynamic>> _getPaginatedFavoris() {
    final startIndex = currentPage * itemsPerPage;
    final endIndex = (startIndex + itemsPerPage) > filteredFavoris.length
        ? filteredFavoris.length
        : startIndex + itemsPerPage;
    
    if (startIndex >= filteredFavoris.length) {
      return [];
    }
    
    return filteredFavoris.sublist(startIndex, endIndex);
  }

  void _navigateToRestaurantDetails(int restaurantId) {
    context.go('/restaurant-details', extra: {
      'restaurantId': restaurantId,
    });
  }
  
  Future<void> _removeFavorite(int favorisId) async {
    try {
      await Supabase.instance.client
          .from('favoris')
          .delete()
          .eq('idfavoris', favorisId);
          
      _loadFavoris();
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Restaurant retiré des favoris'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      print('Erreur lors de la suppression du favori: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur lors de la suppression du favori'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final goldColor = Color(0xFFD4AF37);
    final paginatedFavoris = _getPaginatedFavoris();
    
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Mes Restaurants Favoris',
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
                  child: TextField(
                    controller: searchController,
                    decoration: InputDecoration(
                      hintText: 'Rechercher un restaurant favori...',
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
                  child: filteredFavoris.isEmpty
                    ? Center(
                        child: Text(
                          searchController.text.isEmpty
                            ? 'Vous n\'avez pas encore de restaurants favoris'
                            : 'Aucun restaurant favori trouvé commençant par "${searchController.text}"',
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
                          itemCount: paginatedFavoris.length,
                          itemBuilder: (context, index) {
                            final favori = paginatedFavoris[index];
                            final restaurant = favori['restaurant'];
                            final restaurantName = restaurant['nomrestaurant'] ?? 'Sans nom';
                            
                            return Card(
                              elevation: 4,
                              clipBehavior: Clip.antiAlias,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Stack(
                                children: [
                                  InkWell(
                                    onTap: () {
                                      _navigateToRestaurantDetails(restaurant['idrestaurant']);
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
                                                'assets/images/restaurant.webp',
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
                                                  restaurantName,
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
                                                  child: restaurant['note'] != null
                                                    ? Row(
                                                        mainAxisSize: MainAxisSize.min,
                                                        children: [
                                                          Icon(
                                                            Icons.star,
                                                            color: goldColor,
                                                            size: 16,
                                                          ),
                                                          SizedBox(width: 4),
                                                          Text(
                                                            '${restaurant['note'].toStringAsFixed(1)}',
                                                            style: GoogleFonts.raleway(
                                                              fontSize: 12,
                                                              fontWeight: FontWeight.w500,
                                                              color: goldColor,
                                                            ),
                                                          ),
                                                        ],
                                                      )
                                                    : Text(
                                                        'Non noté',
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
                                  Positioned(
                                    top: 8,
                                    right: 8,
                                    child: Container(
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        shape: BoxShape.circle,
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.black.withOpacity(0.1),
                                            spreadRadius: 1,
                                            blurRadius: 3,
                                          ),
                                        ],
                                      ),
                                      child: IconButton(
                                        icon: Icon(
                                          Icons.favorite,
                                          color: Colors.red,
                                        ),
                                        onPressed: () {
                                          showDialog(
                                            context: context,
                                            builder: (context) => AlertDialog(
                                              title: Text('Retirer des favoris'),
                                              content: Text('Voulez-vous retirer ce restaurant de vos favoris?'),
                                              actions: [
                                                TextButton(
                                                  onPressed: () => Navigator.pop(context),
                                                  child: Text('Annuler'),
                                                ),
                                                TextButton(
                                                  onPressed: () {
                                                    Navigator.pop(context);
                                                    _removeFavorite(favori['idfavoris']);
                                                  },
                                                  child: Text('Confirmer'),
                                                  style: TextButton.styleFrom(
                                                    foregroundColor: Colors.red,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          );
                                        },
                                        iconSize: 20,
                                        padding: EdgeInsets.all(8),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                ),
                
                if (!isLoading && filteredFavoris.isNotEmpty)
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