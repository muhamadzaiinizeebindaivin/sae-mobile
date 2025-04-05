import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../providers/supabase_provider.dart';
import '../viewmodel/restaurants_viewmodel.dart';

class RestaurantsPage extends StatelessWidget {
  final SupabaseProvider supabaseProvider;

  RestaurantsPage({Key? key, required this.supabaseProvider}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => RestaurantsViewModel(),
      child: Consumer<RestaurantsViewModel>(
        builder: (context, viewModel, child) {
          final goldColor = Color(0xFFD4AF37);
          final paginatedData = viewModel.getPaginatedData();

          return Scaffold(
            appBar: AppBar(
              title: Text('Restaurants', style: GoogleFonts.raleway(fontWeight: FontWeight.bold, color: Colors.white)),
              backgroundColor: goldColor,
              centerTitle: true,
              leading: IconButton(
                icon: Icon(Icons.arrow_back, color: Colors.white),
                onPressed: () => context.pop(),
              ),
            ),
            body: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: TextField(
                    controller: viewModel.searchController,
                    decoration: InputDecoration(
                      hintText: 'Rechercher un restaurant...',
                      hintStyle: GoogleFonts.raleway(),
                      prefixIcon: Icon(Icons.search, color: goldColor),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: goldColor),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: goldColor, width: 2),
                      ),
                      suffixIcon: viewModel.searchController.text.isNotEmpty
                          ? IconButton(
                              icon: Icon(Icons.clear),
                              onPressed: () {
                                viewModel.searchController.clear();
                              },
                            )
                          : null,
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Row(
                    children: [
                      Expanded(
                        child: Container(
                          margin: EdgeInsets.only(bottom: 16.0, right: 8.0),
                          decoration: BoxDecoration(
                            border: Border.all(color: goldColor),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              isExpanded: true,
                              value: viewModel.selectedType,
                              hint: Text('Établissement', style: GoogleFonts.raleway()),
                              borderRadius: BorderRadius.circular(12),
                              padding: EdgeInsets.symmetric(horizontal: 16.0),
                              onChanged: viewModel.setSelectedType,
                              items: [
                                DropdownMenuItem<String>(value: null, child: Text('Établissement', style: GoogleFonts.raleway())),
                                ...viewModel.restaurantTypes.map((type) => DropdownMenuItem<String>(
                                      value: type,
                                      child: Text(viewModel.formatRestaurantType(type), style: GoogleFonts.raleway()),
                                    )),
                              ],
                            ),
                          ),
                        ),
                      ),
                      Expanded(
                        child: Container(
                          margin: EdgeInsets.only(bottom: 16.0, left: 8.0),
                          decoration: BoxDecoration(
                            border: Border.all(color: goldColor),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<int>(
                              isExpanded: true,
                              value: viewModel.selectedCuisineId,
                              hint: Text('Cuisine', style: GoogleFonts.raleway()),
                              borderRadius: BorderRadius.circular(12),
                              padding: EdgeInsets.symmetric(horizontal: 16.0),
                              onChanged: viewModel.setSelectedCuisineId,
                              items: [
                                DropdownMenuItem<int>(value: null, child: Text('Cuisine', style: GoogleFonts.raleway())),
                                ...viewModel.allCuisines.map((cuisine) => DropdownMenuItem<int>(
                                      value: cuisine['idcuisine'],
                                      child: Text(viewModel.formatCuisineName(cuisine['nomcuisine'] ?? ''), style: GoogleFonts.raleway()),
                                    )),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Filtres additionnels', style: GoogleFonts.raleway(fontWeight: FontWeight.bold)),
                      SizedBox(height: 8),
                      Wrap(
                        spacing: 8.0,
                        runSpacing: 8.0,
                        children: [
                          _buildFilterChip('Végétarien', viewModel.isVegetarian, (value) => viewModel.setFilter('vegetarian', value), goldColor),
                          _buildFilterChip('Vegan', viewModel.isVegan, (value) => viewModel.setFilter('vegan', value), goldColor),
                          _buildFilterChip('Livraison', viewModel.hasDelivery, (value) => viewModel.setFilter('delivery', value), goldColor),
                          _buildFilterChip('À emporter', viewModel.hasTakeaway, (value) => viewModel.setFilter('takeaway', value), goldColor),
                          _buildFilterChip('Drive', viewModel.hasDrive, (value) => viewModel.setFilter('drive', value), goldColor),
                          _buildFilterChip('Internet', viewModel.hasInternet, (value) => viewModel.setFilter('internet', value), goldColor),
                          _buildFilterChip('Accès handicapé', viewModel.isHandicapAccessible, (value) => viewModel.setFilter('handicap', value), goldColor),
                          _buildFilterChip('Fumeur', viewModel.allowsSmoking, (value) => viewModel.setFilter('smoking', value), goldColor),
                        ],
                      ),
                    ],
                  ),
                ),
                if (viewModel.selectedType != null ||
                    viewModel.selectedCuisineId != null ||
                    viewModel.isVegetarian != null ||
                    viewModel.isVegan != null ||
                    viewModel.hasDelivery != null ||
                    viewModel.hasTakeaway != null ||
                    viewModel.hasDrive != null ||
                    viewModel.hasInternet != null ||
                    viewModel.isHandicapAccessible != null ||
                    viewModel.allowsSmoking != null)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Container(
                      width: double.infinity,
                      margin: EdgeInsets.only(bottom: 16.0),
                      child: Wrap(
                        spacing: 8.0,
                        runSpacing: 8.0,
                        children: [
                          Text('Filtres actifs : ', style: GoogleFonts.raleway(fontWeight: FontWeight.bold)),
                          if (viewModel.selectedType != null)
                            Chip(
                              label: Text(viewModel.formatRestaurantType(viewModel.selectedType), style: GoogleFonts.raleway(fontSize: 12)),
                              deleteIcon: Icon(Icons.close, size: 16),
                              onDeleted: () => viewModel.setSelectedType(null),
                              backgroundColor: goldColor.withOpacity(0.2),
                            ),
                          if (viewModel.selectedCuisineId != null)
                            Chip(
                              label: Text(viewModel.selectedCuisineName ?? '', style: GoogleFonts.raleway(fontSize: 12)),
                              deleteIcon: Icon(Icons.close, size: 16),
                              onDeleted: () => viewModel.setSelectedCuisineId(null),
                              backgroundColor: goldColor.withOpacity(0.2),
                            ),
                          if (viewModel.isVegetarian != null)
                            Chip(
                              label: Text('Végétarien : ${viewModel.isVegetarian! ? 'Oui' : 'Non'}', style: GoogleFonts.raleway(fontSize: 12)),
                              deleteIcon: Icon(Icons.close, size: 16),
                              onDeleted: () => viewModel.setFilter('vegetarian', null),
                              backgroundColor: goldColor.withOpacity(0.2),
                            ),
                          // Ajouter les autres filtres actifs de manière similaire
                        ],
                      ),
                    ),
                  ),
                Expanded(
                  child: viewModel.isLoading
                      ? Center(child: CircularProgressIndicator(color: goldColor))
                      : viewModel.filteredRestaurants.isEmpty
                          ? Center(child: Text('Aucun restaurant trouvé !', style: GoogleFonts.raleway(fontSize: 18)))
                          : Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16.0),
                              child: ListView.builder(
                                itemCount: paginatedData.length,
                                itemBuilder: (context, index) {
                                  final restaurant = paginatedData[index];
                                  final restaurantId = restaurant['idrestaurant'];
                                  final isFavori = viewModel.favoris.contains(restaurantId);
                                  final cuisineNames = (viewModel.restaurantCuisines[restaurantId] ?? [])
                                      .map((id) => viewModel.cuisinesById[id])
                                      .where((cuisine) => cuisine != null)
                                      .map((cuisine) => viewModel.formatCuisineName(cuisine!['nomcuisine'] ?? ''))
                                      .toList();

                                  return Card(
                                    margin: EdgeInsets.only(bottom: 16.0),
                                    elevation: 4,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                    child: InkWell(
                                      borderRadius: BorderRadius.circular(12),
                                      onTap: () => context.push('/restaurant-details', extra: {'restaurantId': restaurantId}),
                                      child: SizedBox(
                                        height: 130,
                                        child: Row(
                                          children: [
                                            Container(
                                              width: 115,
                                              height: 130,
                                              child: ClipRRect(
                                                borderRadius: BorderRadius.only(
                                                  topLeft: Radius.circular(12),
                                                  bottomLeft: Radius.circular(12),
                                                ),
                                                child: Image.asset('assets/images/restaurant.jpg', fit: BoxFit.cover),
                                              ),
                                            ),
                                            Expanded(
                                              child: Padding(
                                                padding: const EdgeInsets.all(12.0),
                                                child: Column(
                                                  crossAxisAlignment: CrossAxisAlignment.start,
                                                  children: [
                                                    Row(
                                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                      children: [
                                                        Expanded(
                                                          child: Text(
                                                            restaurant['nomrestaurant'] ?? 'Sans nom',
                                                            style: GoogleFonts.raleway(fontSize: 16, fontWeight: FontWeight.bold),
                                                            maxLines: 1,
                                                            overflow: TextOverflow.ellipsis,
                                                          ),
                                                        ),
                                                        if (viewModel.isUserLoggedIn)
                                                          IconButton(
                                                            icon: Icon(
                                                              isFavori ? Icons.favorite : Icons.favorite_border,
                                                              color: isFavori ? Colors.red : Colors.grey,
                                                            ),
                                                            onPressed: () => viewModel.toggleFavori(restaurantId, context),
                                                          ),
                                                      ],
                                                    ),
                                                    SizedBox(height: 6),
                                                    Text(
                                                      viewModel.formatRestaurantType(restaurant['typerestaurant']),
                                                      style: GoogleFonts.raleway(fontSize: 14),
                                                    ),
                                                    if (cuisineNames.isNotEmpty) ...[
                                                      SizedBox(height: 6),
                                                      SingleChildScrollView(
                                                        scrollDirection: Axis.horizontal,
                                                        child: Wrap(
                                                          spacing: 4,
                                                          children: cuisineNames
                                                              .map((name) => Container(
                                                                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                                                    decoration: BoxDecoration(
                                                                      color: goldColor.withOpacity(0.1),
                                                                      borderRadius: BorderRadius.circular(8),
                                                                      border: Border.all(color: goldColor.withOpacity(0.3)),
                                                                    ),
                                                                    child: Text(name, style: GoogleFonts.raleway(fontSize: 12)),
                                                                  ))
                                                              .toList(),
                                                        ),
                                                      ),
                                                    ],
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
                ),
                if (!viewModel.isLoading && viewModel.filteredRestaurants.isNotEmpty)
                  Container(
                    padding: EdgeInsets.symmetric(vertical: 10),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        IconButton(
                          icon: Icon(Icons.arrow_back_ios, size: 18),
                          onPressed: viewModel.currentPage > 0 ? viewModel.previousPage : null,
                          color: viewModel.currentPage > 0 ? goldColor : Colors.grey,
                        ),
                        Text('${viewModel.currentPage + 1} / ${viewModel.totalPages}', style: GoogleFonts.raleway(fontWeight: FontWeight.bold, fontSize: 16)),
                        IconButton(
                          icon: Icon(Icons.arrow_forward_ios, size: 18),
                          onPressed: viewModel.currentPage < viewModel.totalPages - 1 ? viewModel.nextPage : null,
                          color: viewModel.currentPage < viewModel.totalPages - 1 ? goldColor : Colors.grey,
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

  Widget _buildFilterChip(String label, bool? value, Function(bool?) onChanged, Color goldColor) {
    return FilterChip(
      label: Text(label, style: GoogleFonts.raleway(fontSize: 12, color: value == true ? Colors.white : Colors.black87)),
      selected: value == true,
      selectedColor: goldColor,
      backgroundColor: value == false ? goldColor.withOpacity(0.2) : Colors.grey.shade200,
      checkmarkColor: Colors.white,
      onSelected: onChanged,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    );
  }
}