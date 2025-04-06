import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../providers/supabase_provider.dart';
import '../viewmodel/favoris_viewmodel.dart';

class FavorisCuisinesPage extends StatelessWidget {
  final SupabaseProvider supabaseProvider;

  const FavorisCuisinesPage({
    Key? key,
    required this.supabaseProvider,
  }) : super(key: key);

  void _navigateToRestaurantsByCuisine(BuildContext context, int cuisineId, String cuisineName) {
    context.go('/cuisine-details', extra: {
      'cuisineId': cuisineId,
      'cuisineName': cuisineName,
    });
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => FavorisViewModel(),
      child: Consumer<FavorisViewModel>(
        builder: (context, viewModel, child) {
          final goldColor = Color(0xFFD4AF37);
          final paginatedCuisines = viewModel.getPaginatedCuisines();

          return Scaffold(
            appBar: AppBar(
              title: Text(
                'Mes Cuisines Favorites',
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
            body: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: TextField(
                    controller: viewModel.searchController,
                    decoration: InputDecoration(
                      hintText: 'Rechercher une cuisine favorite...',
                      prefixIcon: Icon(Icons.search, color: goldColor),
                      suffixIcon: viewModel.searchController.text.isNotEmpty
                          ? IconButton(
                              icon: Icon(Icons.clear),
                              onPressed: () {
                                viewModel.searchController.clear();
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
                  child: viewModel.isLoading
                      ? Center(child: CircularProgressIndicator(color: goldColor))
                      : viewModel.filteredCuisines.isEmpty
                          ? Center(
                              child: Text(
                                'Aucune cuisine favorite trouvée !',
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
                                  final nbRestaurants = viewModel.restaurantCount[cuisine['idcuisine']] ?? 0;
                                  final cuisineName = viewModel.formatCuisineName(cuisine['nomcuisine'] ?? 'Sans nom');
                                  final isFavori = viewModel.favoris.contains(cuisine['idcuisine']);

                                  return Card(
                                    elevation: 4,
                                    clipBehavior: Clip.antiAlias,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: InkWell(
                                      onTap: () {
                                        _navigateToRestaurantsByCuisine(
                                          context,
                                          cuisine['idcuisine'],
                                          cuisineName,
                                        );
                                      },
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.stretch,
                                        children: [
                                          Expanded(
                                            flex: 1,
                                            child: Stack(
                                              children: [
                                                Container(
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
                                                Positioned(
                                                  top: 8,
                                                  right: 8,
                                                  child: IconButton(
                                                    icon: Icon(
                                                      isFavori ? Icons.favorite : Icons.favorite_border,
                                                      color: isFavori ? Colors.red : Colors.grey,
                                                    ),
                                                    onPressed: () => viewModel.toggleFavori(cuisine['idcuisine'], context),
                                                  ),
                                                ),
                                              ],
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
                if (!viewModel.isLoading && viewModel.filteredCuisines.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        IconButton(
                          icon: Icon(Icons.arrow_back_ios),
                          color: viewModel.currentPage > 0 ? goldColor : Colors.grey,
                          onPressed: viewModel.currentPage > 0 ? viewModel.previousPage : null,
                        ),
                        SizedBox(width: 8),
                        Text(
                          '${viewModel.currentPage + 1} / $totalPages',
                          style: GoogleFonts.raleway(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(width: 8),
                        IconButton(
                          icon: Icon(Icons.arrow_forward_ios),
                          color: viewModel.currentPage < viewModel.totalPages - 1 ? goldColor : Colors.grey,
                          onPressed: viewModel.currentPage < viewModel.totalPages - 1 ? viewModel.nextPage : null,
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}