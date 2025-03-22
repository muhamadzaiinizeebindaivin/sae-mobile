import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../providers/supabase_provider.dart';

class RestaurantsPage extends StatefulWidget {
  final SupabaseProvider supabaseProvider;
  
  const RestaurantsPage({
    Key? key,
    required this.supabaseProvider,
  }) : super(key: key);

  @override
  _RestaurantsPageState createState() => _RestaurantsPageState();
}

class _RestaurantsPageState extends State<RestaurantsPage> {
  List<Map<String, dynamic>> restaurants = [];
  bool isLoading = true;
  
  @override
  void initState() {
    super.initState();
    _loadRestaurants();
  }
  
  Future<void> _loadRestaurants() async {
    try {
      final response = await Supabase.instance.client
          .from('restaurant')
          .select('*')
          .order('nomrestaurant', ascending: true);
      
      List<Map<String, dynamic>> restaurantsList = List<Map<String, dynamic>>.from(response);
      
      setState(() {
        restaurants = restaurantsList;
        isLoading = false;
      });
    } catch (e) {
      print('Erreur lors du chargement des restaurants: $e');
      setState(() {
        isLoading = false;
      });
    }
  }

  String _formatRestaurantType(String? type) {
    if (type == null || type.isEmpty) return 'Standard';
    
    String formattedType = type.replaceAll('-', ' ').replaceAll('_', ' ');
    
    formattedType = formattedType.replaceAll('cafe', 'café');
    
    List<String> words = formattedType.split(' ');
    words = words.map((word) {
      if (word.isEmpty) return word;
      return word[0].toUpperCase() + word.substring(1).toLowerCase();
    }).toList();
    
    return words.join(' ');
  }

  @override
  Widget build(BuildContext context) {
    final goldColor = Color(0xFFD4AF37);
    
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Restaurants',
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
          : restaurants.isEmpty
              ? Center(
                  child: Text(
                    'Aucun restaurant trouvé',
                    style: GoogleFonts.raleway(
                      fontSize: 18,
                      color: Colors.black87,
                    ),
                  ),
                )
              : Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: ListView.builder(
                    itemCount: restaurants.length,
                    itemBuilder: (context, index) {
                      final restaurant = restaurants[index];
                      final restaurantType = _formatRestaurantType(restaurant['typerestaurant']);
                      
                      return Card(
                        margin: EdgeInsets.only(bottom: 16.0),
                        elevation: 4,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: InkWell(
                          onTap: () {
                          },
                          borderRadius: BorderRadius.circular(12),
                          child: Row(
                            children: [
                              Container(
                                width: 100,
                                height: 100,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.only(
                                    topLeft: Radius.circular(12),
                                    bottomLeft: Radius.circular(12),
                                  ),
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.only(
                                    topLeft: Radius.circular(12),
                                    bottomLeft: Radius.circular(12),
                                  ),
                                  child: Image.asset(
                                    'assets/images/restaurant.jpg',
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              ),
                              Expanded(
                                child: Padding(
                                  padding: const EdgeInsets.all(12.0),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        restaurant['nomrestaurant'] ?? 'Sans nom',
                                        style: GoogleFonts.raleway(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      SizedBox(height: 6),
                                      Text(
                                        restaurantType,
                                        style: GoogleFonts.raleway(
                                          fontSize: 14,
                                          color: Colors.black87,
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