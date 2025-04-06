import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../providers/supabase_provider.dart';
import '../viewmodels/cuisine_details_viewmodel.dart';

class CuisineDetailsPage extends StatelessWidget {
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
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => CuisineDetailsViewModel(
        cuisineId: cuisineId,
        searchController: TextEditingController(),
      )..loadData(),
      child: _CuisineDetailsPageContent(cuisineName: cuisineName),
    );
  }
}

class _CuisineDetailsPageContent extends StatelessWidget {
  final String cuisineName;
  
  const _CuisineDetailsPageContent({
    Key? key,
    required this.cuisineName,
  }) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    final goldColor = Color(0xFFD4AF37);
    final viewModel = Provider.of<CuisineDetailsViewModel>(context);
    final paginatedRestaurants = viewModel.getPaginatedRestaurants();
    
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Cuisine $cuisineName',
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
      body: viewModel.isLoading
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
                              cuisineName,
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
                                '${viewModel.filteredRestaurants.length} restaurant${viewModel.filteredRestaurants.length > 1 ? 's' : ''}',
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
                    controller: viewModel.searchController,
                    decoration: InputDecoration(
                      hintText: 'Rechercher un restaurant...',
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
                  child: viewModel.filteredRestaurants.isEmpty
                    ? Center(
                        child: Text(
                          viewModel.searchController.text.isNotEmpty
                            ? 'Aucun restaurant trouvé pour "${viewModel.searchController.text}"'
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
                            final restaurantType = viewModel.formatRestaurantType(restaurant['typerestaurant']?.toString() ?? '');
                            
                            return Card(
                              elevation: 4,
                              clipBehavior: Clip.antiAlias,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: InkWell(
                                onTap: () {
                                  context.push('/restaurant-details', extra: {
                                    'restaurantId': restaurant['idrestaurant']
                                  });
                                },
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
                
                if (!viewModel.isLoading && viewModel.filteredRestaurants.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        IconButton(
                          icon: Icon(Icons.arrow_back_ios),
                          color: viewModel.currentPage > 0 ? goldColor : Colors.grey,
                          onPressed: viewModel.currentPage > 0
                              ? () => viewModel.previousPage()
                              : null,
                        ),
                        SizedBox(width: 8),
                        Text(
                          '${viewModel.currentPage + 1} / ${viewModel.totalPages}',
                          style: GoogleFonts.raleway(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(width: 8),
                        IconButton(
                          icon: Icon(Icons.arrow_forward_ios),
                          color: viewModel.currentPage < viewModel.totalPages - 1 ? goldColor : Colors.grey,
                          onPressed: viewModel.currentPage < viewModel.totalPages - 1
                              ? () => viewModel.nextPage()
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