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
  List<Map<String, dynamic>> cuisines = [];
  Map<int, int> restaurantCount = {};
  bool isLoading = true;
  
  @override
  void initState() {
    super.initState();
    _loadCuisines();
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
        cuisines = cuisinesList;
        restaurantCount = countMap;
        isLoading = false;
      });
    } catch (e) {
      print('Erreur lors du chargement des cuisines: $e');
      setState(() {
        isLoading = false;
      });
    }
  }

  String _capitalizeFirstLetter(String text) {
    if (text.isEmpty) return text;
    return text[0].toUpperCase() + text.substring(1).toLowerCase();
  }

  @override
  Widget build(BuildContext context) {
    final goldColor = Color(0xFFD4AF37);
    
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
          : cuisines.isEmpty
              ? Center(
                  child: Text(
                    'Aucun type de cuisine trouvé',
                    style: GoogleFonts.raleway(
                      fontSize: 18,
                      color: Colors.black87,
                    ),
                  ),
                )
              : Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: GridView.builder(
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      childAspectRatio: 1.0,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                    ),
                    itemCount: cuisines.length,
                    itemBuilder: (context, index) {
                      final cuisine = cuisines[index];
                      final nbRestaurants = restaurantCount[cuisine['idcuisine']] ?? 0;
                      final cuisineName = _capitalizeFirstLetter(cuisine['nomcuisine'] ?? 'Sans nom');
                      
                      return Card(
                        elevation: 4,
                        clipBehavior: Clip.antiAlias,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: InkWell(
                          onTap: () {
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
    );
  }
}