import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../providers/supabase_provider.dart';
import '../viewmodels/favoris_viewmodel.dart';

class FavorisPage extends StatefulWidget {
  final SupabaseProvider supabaseProvider;

  const FavorisPage({
    Key? key,
    required this.supabaseProvider,
  }) : super(key: key);

  @override
  _FavorisPageState createState() => _FavorisPageState();
}

class _FavorisPageState extends State<FavorisPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<FavorisViewModel>().loadFavoris();
    });
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

    return Consumer<FavorisViewModel>(
      builder: (context, viewModel, child) {
        return Scaffold(
          appBar: PreferredSize(
            preferredSize: Size.fromHeight(kToolbarHeight),
            child: Container(
              margin: EdgeInsets.only(bottom: 10.0), // Ajout du margin bottom
              child: AppBar(
                title: Text(
                  'Mes Favoris',
                  style: GoogleFonts.raleway(
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                backgroundColor: goldColor,
                centerTitle: true,
                leading: IconButton(
                  icon: Icon(Icons.arrow_back, color: Colors.white),
                  onPressed: () => context.go('/home-authentified'),
                ),
              ),
            ),
          ),
          body: viewModel.isLoading
              ? Center(child: CircularProgressIndicator(color: goldColor))
              : viewModel.favorisRestaurants.isEmpty
                  ? Center(
                      child: Text(
                        'Aucun restaurant favori pour le moment !',
                        style: GoogleFonts.raleway(
                          fontSize: 18,
                          color: Colors.black87,
                        ),
                      ),
                    )
                  : Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: ListView.builder(
                        itemCount: viewModel.favorisRestaurants.length,
                        itemBuilder: (context, index) {
                          final restaurant = viewModel.favorisRestaurants[index];
                          final restaurantType =
                              _formatRestaurantType(restaurant['typerestaurant']);
                          final restaurantId = restaurant['idrestaurant'];

                          return Card(
                            margin: EdgeInsets.only(bottom: 16.0),
                            elevation: 4,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: InkWell(
                              borderRadius: BorderRadius.circular(12),
                              onTap: () {
                                context.push('/restaurant-details',
                                    extra: {'restaurantId': restaurantId});
                              },
                              child: SizedBox(
                                height: 130,
                                child: Row(
                                  children: [
                                    Container(
                                      width: 115,
                                      height: 130,
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
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.spaceBetween,
                                              children: [
                                                Expanded(
                                                  child: Text(
                                                    restaurant['nomrestaurant'] ??
                                                        'Sans nom',
                                                    style: GoogleFonts.raleway(
                                                      fontSize: 16,
                                                      fontWeight: FontWeight.bold,
                                                    ),
                                                    maxLines: 1,
                                                    overflow: TextOverflow.ellipsis,
                                                  ),
                                                ),
                                                IconButton(
                                                  icon: Icon(
                                                    Icons.favorite,
                                                    color: Colors.red,
                                                  ),
                                                  onPressed: () => viewModel
                                                      .toggleFavori(restaurantId, context),
                                                ),
                                              ],
                                            ),
                                            SizedBox(height: 6),
                                            Text(
                                              restaurantType,
                                              style: GoogleFonts.raleway(
                                                fontSize: 14,
                                                color: Colors.black87,
                                              ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
          bottomNavigationBar: BottomNavigationBar(
            items: const <BottomNavigationBarItem>[
              BottomNavigationBarItem(
                icon: Icon(Icons.home),
                label: 'Accueil',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.favorite),
                label: 'Favoris',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.rate_review),
                label: 'Critiques',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.person),
                label: 'Profil',
              ),
            ],
            currentIndex: 1,
            selectedItemColor: goldColor,
            unselectedItemColor: Colors.grey,
            type: BottomNavigationBarType.fixed,
            onTap: (index) {
              switch (index) {
                case 0:
                  context.go('/home-authentified');
                  break;
                case 1:
                  break;
                case 2:
                  context.push('/user-reviews');
                  break;
                case 3:
                  context.push('/profile');
                  break;
              }
            },
          ),
        );
      },
    );
  }
}