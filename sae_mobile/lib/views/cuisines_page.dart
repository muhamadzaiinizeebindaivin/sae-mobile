import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../providers/supabase_provider.dart';

class CuisinesFavorisPage extends StatefulWidget {
  final SupabaseProvider supabaseProvider;

  const CuisinesFavorisPage({
    Key? key,
    required this.supabaseProvider,
  }) : super(key: key);

  @override
  _CuisinesFavorisPageState createState() => _CuisinesFavorisPageState();
}

class _CuisinesFavorisPageState extends State<CuisinesFavorisPage> {
  List<Map<String, dynamic>> allFavoriteCuisines = [];
  List<Map<String, dynamic>> filteredFavoriteCuisines = [];
  Map<int, int> restaurantCount = {};
  bool isLoading = true;

  int currentPage = 0;
  final int itemsPerPage = 8;
  int totalPages = 0;

  final TextEditingController searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadFavoriteCuisines();

    searchController.addListener(() {
      _filterFavoriteCuisines();
    });
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  Future<void> _loadFavoriteCuisines() async {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null || user.email == null) {
        setState(() {
          isLoading = false;
        });
        return;
      }

      // Récupérer l'id de l'utilisateur connecté
      final userResponse = await Supabase.instance.client
          .from('utilisateur')
          .select('idutilisateur')
          .eq('emailutilisateur', user.email!)
          .single();

      int idutilisateur = userResponse['idutilisateur'];

      // Récupérer les cuisines préférées de l'utilisateur
      final prefererResponse = await Supabase.instance.client
          .from('preferer')
          .select('idcuisine')
          .eq('idutilisateur', idutilisateur);

      List<int> favoriteCuisineIds = prefererResponse
          .map<int>((pref) => pref['idcuisine'] as int)
          .toList();

      if (favoriteCuisineIds.isEmpty) {
        setState(() {
          allFavoriteCuisines = [];
          filteredFavoriteCuisines = [];
          restaurantCount = {};
          isLoading = false;
          _updateTotalPages();
        });
        return;
      }

      // Récupérer les détails des cuisines favorites
      final cuisineResponse = await Supabase.instance.client
          .from('cuisine')
          .select('*')
          .inFilter('idcuisine', favoriteCuisineIds)
          .order('nomcuisine', ascending: true);

      List<Map<String, dynamic>> cuisinesList = List<Map<String, dynamic>>.from(cuisineResponse);

      // Compter les restaurants associés à chaque cuisine
      final servirResponse = await Supabase.instance.client
          .from('servir')
          .select('idcuisine, idrestaurant')
          .inFilter('idcuisine', favoriteCuisineIds);

      List<Map<String, dynamic>> servirList = List<Map<String, dynamic>>.from(servirResponse);

      Map<int, int> countMap = {};
      for (var servir in servirList) {
        int cuisineId = servir['idcuisine'];
        countMap[cuisineId] = (countMap[cuisineId] ?? 0) + 1;
      }

      setState(() {
        allFavoriteCuisines = cuisinesList;
        filteredFavoriteCuisines = cuisinesList;
        restaurantCount = countMap;
        isLoading = false;
        _updateTotalPages();
      });
    } catch (e) {
      print('Erreur lors du chargement des cuisines favorites: $e');
      setState(() {
        isLoading = false;
      });
    }
  }

  void _filterFavoriteCuisines() {
    final query = searchController.text.toLowerCase();

    setState(() {
      if (query.isEmpty) {
        filteredFavoriteCuisines = allFavoriteCuisines;
      } else {
        filteredFavoriteCuisines = allFavoriteCuisines
            .where((cuisine) =>
                cuisine['nomcuisine'].toString().toLowerCase().startsWith(query))
            .toList();
      }
      currentPage = 0;
      _updateTotalPages();
    });
  }

  void _updateTotalPages() {
    totalPages = (filteredFavoriteCuisines.length / itemsPerPage).ceil();
    if (totalPages == 0) totalPages = 1;
  }

  List<Map<String, dynamic>> _getPaginatedCuisines() {
    final startIndex = currentPage * itemsPerPage;
    final endIndex = (startIndex + itemsPerPage) > filteredFavoriteCuisines.length
        ? filteredFavoriteCuisines.length
        : startIndex + itemsPerPage;

    if (startIndex >= filteredFavoriteCuisines.length) {
      return [];
    }

    return filteredFavoriteCuisines.sublist(startIndex, endIndex);
  }

  String _formatCuisineName(String text) {
    if (text.isEmpty) return text;

    String formattedText = text.replaceAll('_', ' ').replaceAll('-', ' ');
    return formattedText[0].toUpperCase() + formattedText.substring(1).toLowerCase();
  }

  void _navigateToRestaurantsByCuisine(int cuisineId, String cuisineName) {
    context.go('/cuisine-details', extra: {
      'idcuisine': cuisineId,
      'cuisineName': cuisineName,
    });
  }

  Future<void> _removeFavoriteCuisine(int cuisineId) async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null || user.email == null) return;

    final userResponse = await Supabase.instance.client
        .from('utilisateur')
        .select('idutilisateur')
        .eq('emailutilisateur', user.email!)
        .single();

    int idutilisateur = userResponse['idutilisateur'];

    await Supabase.instance.client
        .from('preferer')
        .delete()
        .match({'idutilisateur': idutilisateur, 'idcuisine': cuisineId});

    _loadFavoriteCuisines();
  }

  @override
  Widget build(BuildContext context) {
    final goldColor = Color(0xFFD4AF37);
    final paginatedCuisines = _getPaginatedCuisines();

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Cuisines favorites',
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
                      hintText: 'Rechercher une cuisine favorite...',
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
                  child: filteredFavoriteCuisines.isEmpty
                      ? Center(
                          child: Text(
                            allFavoriteCuisines.isEmpty
                                ? 'Aucune cuisine favorite pour le moment !'
                                : 'Aucune cuisine favorite trouvée commençant par "${searchController.text}"',
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
                                    _navigateToRestaurantsByCuisine(
                                      cuisine['idcuisine'],
                                      cuisineName,
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
                if (!isLoading && filteredFavoriteCuisines.isNotEmpty)
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
  Future<void> _removeFavoriteCuisine(int idcuisine) async {
  final user = Supabase.instance.client.auth.currentUser;
  if (user == null || user.email == null) return;

  final userResponse = await Supabase.instance.client
      .from('utilisateur')
      .select('idutilisateur')
      .eq('emailutilisateur', user.email!)
      .single();

  int idutilisateur = userResponse['idutilisateur'];

  await Supabase.instance.client
      .from('preferer')
      .delete()
      .match({'idutilisateur': idutilisateur, 'idcuisine': idcuisine});

  _loadFavoriteCuisines();
}
}