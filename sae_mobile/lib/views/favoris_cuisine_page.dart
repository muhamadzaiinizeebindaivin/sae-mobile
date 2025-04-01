import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../providers/supabase_provider.dart';

class CuisiniersPage extends StatefulWidget {
  final SupabaseProvider supabaseProvider;

  const CuisiniersPage({
    Key? key,
    required this.supabaseProvider,
  }) : super(key: key);

  @override
  _CuisiniersPageState createState() => _CuisiniersPageState();
}

class _CuisiniersPageState extends State<CuisiniersPage> {
  List<Map<String, dynamic>> allCuisiniers = [];
  List<Map<String, dynamic>> filteredCuisiniers = [];
  Map<int, int> restaurantCount = {};
  bool isLoading = true;

  int currentPage = 0;
  final int itemsPerPage = 8;
  int totalPages = 0;

  final TextEditingController searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadCuisiniers();

    searchController.addListener(() {
      _filterCuisiniers();
    });
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  Future<void> _loadCuisiniers() async {
    try {
      final response = await Supabase.instance.client
          .from('cuisinier')
          .select('*')
          .order('nomcuisinier', ascending: true);

      List<Map<String, dynamic>> cuisiniersList = List<Map<String, dynamic>>.from(response);

      final travaillerResponse = await Supabase.instance.client
          .from('travailler')
          .select('idcuisinier, idrestaurant');

      List<Map<String, dynamic>> travaillerList = List<Map<String, dynamic>>.from(travaillerResponse);

      Map<int, int> countMap = {};
      for (var travailler in travaillerList) {
        int cuisinierId = travailler['idcuisinier'];
        countMap[cuisinierId] = (countMap[cuisinierId] ?? 0) + 1;
      }

      setState(() {
        allCuisiniers = cuisiniersList;
        filteredCuisiniers = cuisiniersList;
        restaurantCount = countMap;
        isLoading = false;
        _updateTotalPages();
      });
    } catch (e) {
      print('Erreur lors du chargement des cuisiniers: $e');
      setState(() {
        isLoading = false;
      });
    }
  }

  void _filterCuisiniers() {
    final query = searchController.text.toLowerCase();

    setState(() {
      if (query.isEmpty) {
        filteredCuisiniers = allCuisiniers;
      } else {
        filteredCuisiniers = allCuisiniers
            .where((cuisinier) =>
                cuisinier['nomcuisinier'].toString().toLowerCase().startsWith(query))
            .toList();
      }
      currentPage = 0;
      _updateTotalPages();
    });
  }

  void _updateTotalPages() {
    totalPages = (filteredCuisiniers.length / itemsPerPage).ceil();
    if (totalPages == 0) totalPages = 1;
  }

  List<Map<String, dynamic>> _getPaginatedCuisiniers() {
    final startIndex = currentPage * itemsPerPage;
    final endIndex = (startIndex + itemsPerPage) > filteredCuisiniers.length
        ? filteredCuisiniers.length
        : startIndex + itemsPerPage;

    if (startIndex >= filteredCuisiniers.length) {
      return [];
    }

    return filteredCuisiniers.sublist(startIndex, endIndex);
  }

  String _formatCuisinierName(String text) {
    if (text.isEmpty) return text;

    String formattedText = text.replaceAll('_', ' ').replaceAll('-', ' ');
    return formattedText[0].toUpperCase() + formattedText.substring(1).toLowerCase();
  }

  void _navigateToRestaurantsByCuisinier(int cuisinierId, String cuisinierName) {
    context.go('/cuisinier-details', extra: {
      'cuisinierId': cuisinierId,
      'cuisinierName': cuisinierName,
    });
  }

  @override
  Widget build(BuildContext context) {
    final goldColor = Color(0xFFD4AF37);
    final paginatedCuisiniers = _getPaginatedCuisiniers();

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Cuisiniers',
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
                      hintText: 'Rechercher un cuisinier...',
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
                  child: filteredCuisiniers.isEmpty
                      ? Center(
                          child: Text(
                            'Aucun cuisinier trouvé commençant par "${searchController.text}"',
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
                            itemCount: paginatedCuisiniers.length,
                            itemBuilder: (context, index) {
                              final cuisinier = paginatedCuisiniers[index];
                              final nbRestaurants = restaurantCount[cuisinier['idcuisinier']] ?? 0;
                              final cuisinierName = _formatCuisinierName(
                                  cuisinier['nomcuisinier'] ?? 'Sans nom');

                              return Card(
                                elevation: 4,
                                clipBehavior: Clip.antiAlias,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: InkWell(
                                  onTap: () {
                                    _navigateToRestaurantsByCuisinier(
                                      cuisinier['idcuisinier'],
                                      cuisinierName,
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
                                              'assets/images/cuisinier.jpg', // Image par défaut pour cuisinier
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
                                                cuisinierName,
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
                if (!isLoading && filteredCuisiniers.isNotEmpty)
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