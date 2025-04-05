import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../providers/supabase_provider.dart';

class FavorisPage extends StatefulWidget {
  final SupabaseProvider supabaseProvider;
  FavorisPage({
    Key? key,
    required this.supabaseProvider,
  }) : super(key: key);

  @override
  _FavorisPageState createState() => _FavorisPageState();
}

class _FavorisPageState extends State<FavorisPage> {
  List<int> favoris = [];
  List<Map<String, dynamic>> favoriteRestaurants = [];
  List<Map<String, dynamic>> filteredRestaurants = [];
  List<Map<String, dynamic>> allCuisines = [];
  Map<int, List<int>> restaurantCuisines = {};
  Map<int, Map<String, dynamic>> cuisinesById = {};
  List<String> restaurantTypes = [];
  String? selectedType;
  int? selectedCuisineId;
  bool isLoading = true;
  int itemsPerPage = 30;
  int currentPage = 0;
  int totalPages = 0;
  final TextEditingController _searchController = TextEditingController();
  String searchQuery = '';
  
  bool? isVegetarian;
  bool? isVegan;
  bool? hasDelivery;
  bool? hasTakeaway;
  bool? hasDrive;
  bool? hasInternet;
  bool? isHandicapAccessible;
  bool? allowsSmoking;

  @override
  void initState() {
    super.initState();
    _loadFavoris();
    _searchController.addListener(() {
      _applyFilters();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadFavoris() async {
    setState(() {
      isLoading = true;
    });
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null || user.email == null) {
        setState(() {
          isLoading = false;
        });
        return;
      }
      
      final userResponse = await Supabase.instance.client
          .from('utilisateur')
          .select('idutilisateur')
          .eq('emailutilisateur', user.email!)
          .single();
      
      int idUtilisateur = userResponse['idutilisateur'];
      
      final favResponse = await Supabase.instance.client
          .from('aimer')
          .select('idrestaurant')
          .eq('idutilisateur', idUtilisateur);

      List<int> favorisIds = favResponse.map<int>((fav) => fav['idrestaurant'] as int).toList();
      
      if (favorisIds.isEmpty) {
        setState(() {
          favoris = [];
          favoriteRestaurants = [];
          filteredRestaurants = [];
          isLoading = false;
        });
        return;
      }

      final restaurantResponse = await Supabase.instance.client
        .from('restaurant')
        .select('*')
        .filter('idrestaurant', 'in', favorisIds)
        .order('nomrestaurant', ascending: true);
      List<Map<String, dynamic>> restaurantsList = List<Map<String, dynamic>>.from(restaurantResponse);

      final cuisineResponse = await Supabase.instance.client
        .from('cuisine')
        .select('*')
        .order('nomcuisine', ascending: true);
      List<Map<String, dynamic>> cuisinesList = List<Map<String, dynamic>>.from(cuisineResponse);

      final servirResponse = await Supabase.instance.client
        .from('servir')
        .select('idrestaurant, idcuisine')
        .filter('idrestaurant', 'in', favorisIds);
      List<Map<String, dynamic>> servirList = List<Map<String, dynamic>>.from(servirResponse);

      Map<int, Map<String, dynamic>> cuisinesMap = {};
      for (var cuisine in cuisinesList) {
        cuisinesMap[cuisine['idcuisine']] = cuisine;
      }

      Map<int, List<int>> restaurantCuisinesMap = {};
      for (var servir in servirList) {
        int restaurantId = servir['idrestaurant'];
        int cuisineId = servir['idcuisine'];
        if (!restaurantCuisinesMap.containsKey(restaurantId)) {
          restaurantCuisinesMap[restaurantId] = [];
        }
        restaurantCuisinesMap[restaurantId]!.add(cuisineId);
      }

      Set<String> typesSet = {};
      for (var restaurant in restaurantsList) {
        final type = restaurant['typerestaurant']?.toString() ?? '';
        if (type.isNotEmpty) {
          typesSet.add(type);
        }
      }

      setState(() {
        favoris = favorisIds;
        favoriteRestaurants = restaurantsList;
        allCuisines = cuisinesList;
        restaurantCuisines = restaurantCuisinesMap;
        cuisinesById = cuisinesMap;
        restaurantTypes = typesSet.toList()..sort();
        _applyFilters();
        isLoading = false;
      });
    } catch (e) {
      print('Erreur lors du chargement des favoris: $e');
      setState(() {
        isLoading = false;
      });
    }
  }

  void _applyFilters() {
    setState(() {
      searchQuery = _searchController.text;
      filteredRestaurants = favoriteRestaurants.where((restaurant) {
        final name = restaurant['nomrestaurant']?.toString().toLowerCase() ?? '';
        final type = restaurant['typerestaurant']?.toString() ?? '';
        final restaurantId = restaurant['idrestaurant'];
        
        bool matchesSearch = true;
        if (searchQuery.isNotEmpty) {
          matchesSearch = name.startsWith(searchQuery.toLowerCase());
        }
        
        bool matchesType = true;
        if (selectedType != null && selectedType!.isNotEmpty) {
          matchesType = type == selectedType;
        }
        
        bool matchesCuisine = true;
        if (selectedCuisineId != null) {
          List<int> cuisineIds = restaurantCuisines[restaurantId] ?? [];
          matchesCuisine = cuisineIds.contains(selectedCuisineId);
        }
        
        bool matchesVegetarian = true;
        if (isVegetarian != null) {
          matchesVegetarian = restaurant['vegetarienrestaurant'] == isVegetarian;
        }
        
        bool matchesVegan = true;
        if (isVegan != null) {
          matchesVegan = restaurant['veganrestaurant'] == isVegan;
        }
        
        bool matchesDelivery = true;
        if (hasDelivery != null) {
          matchesDelivery = restaurant['livraisonrestaurant'] == hasDelivery;
        }
        
        bool matchesTakeaway = true;
        if (hasTakeaway != null) {
          matchesTakeaway = restaurant['emporterrestaurant'] == hasTakeaway;
        }
        
        bool matchesDrive = true;
        if (hasDrive != null) {
          matchesDrive = restaurant['driverestaurant'] == hasDrive;
        }

        bool matchesInternet = true;
        if (hasInternet != null) {
          matchesInternet = restaurant['internetrestaurant'] == hasInternet;
        }

        bool matchesHandicap = true;
        if (isHandicapAccessible != null) {
          matchesHandicap = restaurant['handicaprestaurant'] == isHandicapAccessible;
        }

        bool matchesSmoking = true;
        if (allowsSmoking != null) {
          matchesSmoking = restaurant['fumerrestaurant'] == allowsSmoking;
        }

        return matchesSearch && matchesType && matchesCuisine && 
               matchesVegetarian && matchesVegan && 
               matchesDelivery && matchesTakeaway && matchesDrive &&
               matchesInternet && matchesHandicap && matchesSmoking;
      }).toList();
      
      currentPage = 0;
      totalPages = (filteredRestaurants.length / itemsPerPage).ceil();
      if (totalPages == 0) totalPages = 1;
    });
  }

  List<Map<String, dynamic>> _getPaginatedData() {
    if (filteredRestaurants.isEmpty) return [];
    final startIndex = currentPage * itemsPerPage;
    final endIndex = (currentPage + 1) * itemsPerPage;
    if (startIndex >= filteredRestaurants.length) return [];
    return filteredRestaurants.sublist(
      startIndex,
      endIndex > filteredRestaurants.length ? filteredRestaurants.length : endIndex
    );
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

  String _formatCuisineName(String text) {
    if (text.isEmpty) return text;
    String formattedText = text.replaceAll('_', ' ').replaceAll('-', ' ');
    return formattedText[0].toUpperCase() + formattedText.substring(1).toLowerCase();
  }

  String? get selectedCuisineName {
    if (selectedCuisineId == null) return null;
    final cuisine = cuisinesById[selectedCuisineId];
    if (cuisine == null) return null;
    return _formatCuisineName(cuisine['nomcuisine'] ?? 'Sans nom');
  }
  
  Future<void> _toggleFavori(int restaurantId) async {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null || user.email == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Vous devez être connecté pour gérer vos favoris',
              textAlign: TextAlign.center,
              style: GoogleFonts.raleway(fontWeight: FontWeight.bold),
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
      bool isFavorite = favoris.contains(restaurantId);

      if (isFavorite) {
        final deleteResponse = await Supabase.instance.client
            .from('aimer')
            .delete()
            .match({'idutilisateur': idUtilisateur, 'idrestaurant': restaurantId})
            .select()
            .maybeSingle();

        if (deleteResponse != null) {
          setState(() {
            favoris.remove(restaurantId);
            favoriteRestaurants.removeWhere((r) => r['idrestaurant'] == restaurantId);
            _applyFilters();
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Restaurant retiré des favoris',
                textAlign: TextAlign.center,
                style: GoogleFonts.raleway(fontWeight: FontWeight.bold),
              ),
              backgroundColor: Colors.grey,
            ),
          );
        }
      } else {
        final existingFavori = await Supabase.instance.client
            .from('aimer')
            .select()
            .eq('idutilisateur', idUtilisateur)
            .eq('idrestaurant', restaurantId)
            .maybeSingle();

        if (existingFavori == null) {
          await Supabase.instance.client.from('aimer').insert({
            'idutilisateur': idUtilisateur,
            'idrestaurant': restaurantId,
            'dateaime': DateTime.now().toIso8601String().split('T')[0],
          });

          await _loadFavoris();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Restaurant ajouté aux favoris',
                textAlign: TextAlign.center,
                style: GoogleFonts.raleway(fontWeight: FontWeight.bold),
              ),
              backgroundColor: Color(0xFFD4AF37),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Ce restaurant est déjà dans vos favoris',
                textAlign: TextAlign.center,
                style: GoogleFonts.raleway(fontWeight: FontWeight.bold),
              ),
              backgroundColor: Colors.orange,
            ),
          );
        }
      }
    } catch (e) {
      print('Erreur lors de la modification des favoris: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur: Impossible de modifier les favoris',
            textAlign: TextAlign.center,
            style: GoogleFonts.raleway(fontWeight: FontWeight.bold),
          ),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Widget _buildFilterChip({
    required String label,
    required bool? value,
    required Function(bool?) onChanged,
    required Color goldColor,
  }) {
    return FilterChip(
      label: Text(
        label,
        style: GoogleFonts.raleway(
          fontSize: 12,
          color: value == true ? Colors.white : Colors.black87,
        ),
      ),
      selected: value == true,
      selectedColor: goldColor,
      backgroundColor: value == false ? goldColor.withOpacity(0.2) : Colors.grey.shade200,
      checkmarkColor: Colors.white,
      onSelected: (selected) {
        onChanged(selected ? true : (value == null ? false : null));
      },
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final goldColor = Color(0xFFD4AF37);
    final paginatedData = _getPaginatedData();

    return Scaffold(
      appBar: AppBar(
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
          onPressed: () {
            if (Navigator.canPop(context)) {
              Navigator.pop(context);
            } else {
              context.go('/home');
            }
          },
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Rechercher un restaurant favori...',
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
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          _applyFilters();
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
                      child: ButtonTheme(
                        alignedDropdown: true,
                        child: DropdownButton<String>(
                          isExpanded: true,
                          value: selectedType,
                          hint: Text(
                            'Établissement',
                            style: GoogleFonts.raleway(),
                            overflow: TextOverflow.ellipsis,
                          ),
                          borderRadius: BorderRadius.circular(12),
                          padding: EdgeInsets.symmetric(horizontal: 16.0),
                          onChanged: (String? newValue) {
                            setState(() {
                              selectedType = newValue;
                              _applyFilters();
                            });
                          },
                          items: [
                            DropdownMenuItem<String>(
                              value: null,
                              child: Text(
                                'Établissement',
                                style: GoogleFonts.raleway(),
                              ),
                            ),
                            ...restaurantTypes.map((String type) {
                              return DropdownMenuItem<String>(
                                value: type,
                                child: Text(
                                  _formatRestaurantType(type),
                                  style: GoogleFonts.raleway(),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              );
                            }).toList(),
                          ],
                        ),
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
                      child: ButtonTheme(
                        alignedDropdown: true,
                        child: DropdownButton<int>(
                          isExpanded: true,
                          value: selectedCuisineId,
                          hint: Text(
                            'Cuisine',
                            style: GoogleFonts.raleway(),
                            overflow: TextOverflow.ellipsis,
                          ),
                          borderRadius: BorderRadius.circular(12),
                          padding: EdgeInsets.symmetric(horizontal: 16.0),
                          onChanged: (int? newValue) {
                            setState(() {
                              selectedCuisineId = newValue;
                              _applyFilters();
                            });
                          },
                          items: [
                            DropdownMenuItem<int>(
                              value: null,
                              child: Text(
                                'Cuisine',
                                style: GoogleFonts.raleway(),
                              ),
                            ),
                            ...allCuisines.map((cuisine) {
                              return DropdownMenuItem<int>(
                                value: cuisine['idcuisine'],
                                child: Text(
                                  _formatCuisineName(cuisine['nomcuisine'] ?? ''),
                                  style: GoogleFonts.raleway(),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              );
                            }).toList(),
                          ],
                        ),
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
                Text(
                  'Filtres additionnels',
                  style: GoogleFonts.raleway(fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 8),
                Wrap(
                  spacing: 8.0,
                  runSpacing: 8.0,
                  children: [
                    _buildFilterChip(
                      label: 'Végétarien',
                      value: isVegetarian,
                      onChanged: (value) {
                        setState(() {
                          isVegetarian = value;
                          _applyFilters();
                        });
                      },
                      goldColor: goldColor,
                    ),
                    _buildFilterChip(
                      label: 'Vegan',
                      value: isVegan,
                      onChanged: (value) {
                        setState(() {
                          isVegan = value;
                          _applyFilters();
                        });
                      },
                      goldColor: goldColor,
                    ),
                    _buildFilterChip(
                      label: 'Livraison',
                      value: hasDelivery,
                      onChanged: (value) {
                        setState(() {
                          hasDelivery = value;
                          _applyFilters();
                        });
                      },
                      goldColor: goldColor,
                    ),
                    _buildFilterChip(
                      label: 'À emporter',
                      value: hasTakeaway,
                      onChanged: (value) {
                        setState(() {
                          hasTakeaway = value;
                          _applyFilters();
                        });
                      },
                      goldColor: goldColor,
                    ),
                    _buildFilterChip(
                      label: 'Drive',
                      value: hasDrive,
                      onChanged: (value) {
                        setState(() {
                          hasDrive = value;
                          _applyFilters();
                        });
                      },
                      goldColor: goldColor,
                    ),
                    _buildFilterChip(
                      label: 'Internet',
                      value: hasInternet,
                      onChanged: (value) {
                        setState(() {
                          hasInternet = value;
                          _applyFilters();
                        });
                      },
                      goldColor: goldColor,
                    ),
                    _buildFilterChip(
                      label: 'Accès handicapé',
                      value: isHandicapAccessible,
                      onChanged: (value) {
                        setState(() {
                          isHandicapAccessible = value;
                          _applyFilters();
                        });
                      },
                      goldColor: goldColor,
                    ),
                    _buildFilterChip(
                      label: 'Fumeur',
                      value: allowsSmoking,
                      onChanged: (value) {
                        setState(() {
                          allowsSmoking = value;
                          _applyFilters();
                        });
                      },
                      goldColor: goldColor,
                    ),
                  ],
                ),
              ],
            ),
          ),
          if (selectedType != null || selectedCuisineId != null || 
              isVegetarian != null || isVegan != null || 
              hasDelivery != null || hasTakeaway != null || hasDrive != null ||
              hasInternet != null || isHandicapAccessible != null || allowsSmoking != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Container(
                width: double.infinity,
                margin: EdgeInsets.only(bottom: 16.0),
                child: Wrap(
                  spacing: 8.0,
                  runSpacing: 8.0,
                  children: [
                    Text(
                      'Filtres actifs : ',
                      style: GoogleFonts.raleway(fontWeight: FontWeight.bold),
                    ),
                    if (selectedType != null)
                      Chip(
                        label: Text(_formatRestaurantType(selectedType),
                          style: GoogleFonts.raleway(fontSize: 12),
                        ),
                        deleteIcon: Icon(Icons.close, size: 16),
                        onDeleted: () {
                          setState(() {
                            selectedType = null;
                            _applyFilters();
                          });
                        },
                        backgroundColor: goldColor.withOpacity(0.2),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    if (selectedCuisineId != null)
                      Chip(
                        label: Text(selectedCuisineName ?? '',
                          style: GoogleFonts.raleway(fontSize: 12),
                        ),
                        deleteIcon: Icon(Icons.close, size: 16),
                        onDeleted: () {
                          setState(() {
                            selectedCuisineId = null;
                            _applyFilters();
                          });
                        },
                        backgroundColor: goldColor.withOpacity(0.2),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    if (isVegetarian != null)
                      Chip(
                        label: Text(
                          'Végétarien : ${isVegetarian! ? 'Oui' : 'Non'}',
                          style: GoogleFonts.raleway(fontSize: 12),
                        ),
                        deleteIcon: Icon(Icons.close, size: 16),
                        onDeleted: () {
                          setState(() {
                            isVegetarian = null;
                            _applyFilters();
                          });
                        },
                        backgroundColor: goldColor.withOpacity(0.2),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    if (isVegan != null)
                      Chip(
                        label: Text(
                          'Vegan : ${isVegan! ? 'Oui' : 'Non'}',
                          style: GoogleFonts.raleway(fontSize: 12),
                        ),
                        deleteIcon: Icon(Icons.close, size: 16),
                        onDeleted: () {
                          setState(() {
                            isVegan = null;
                            _applyFilters();
                          });
                        },
                        backgroundColor: goldColor.withOpacity(0.2),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    if (hasDelivery != null)
                      Chip(
                        label: Text(
                          'Livraison : ${hasDelivery! ? 'Oui' : 'Non'}',
                          style: GoogleFonts.raleway(fontSize: 12),
                        ),
                        deleteIcon: Icon(Icons.close, size: 16),
                        onDeleted: () {
                          setState(() {
                            hasDelivery = null;
                            _applyFilters();
                          });
                        },
                        backgroundColor: goldColor.withOpacity(0.2),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    if (hasTakeaway != null)
                      Chip(
                        label: Text(
                          'À emporter : ${hasTakeaway! ? 'Oui' : 'Non'}',
                          style: GoogleFonts.raleway(fontSize: 12),
                        ),
                        deleteIcon: Icon(Icons.close, size: 16),
                        onDeleted: () {
                          setState(() {
                            hasTakeaway = null;
                            _applyFilters();
                          });
                        },
                        backgroundColor: goldColor.withOpacity(0.2),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    if (hasDrive != null)
                      Chip(
                        label: Text(
                          'Drive : ${hasDrive! ? 'Oui' : 'Non'}',
                          style: GoogleFonts.raleway(fontSize: 12),
                        ),
                        deleteIcon: Icon(Icons.close, size: 16),
                        onDeleted: () {
                          setState(() {
                            hasDrive = null;
                            _applyFilters();
                          });
                        },
                        backgroundColor: goldColor.withOpacity(0.2),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    if (hasInternet != null)
                      Chip(
                        label: Text(
                          'Internet : ${hasInternet! ? 'Oui' : 'Non'}',
                          style: GoogleFonts.raleway(fontSize: 12),
                        ),
                        deleteIcon: Icon(Icons.close, size: 16),
                        onDeleted: () {
                          setState(() {
                            hasInternet = null;
                            _applyFilters();
                          });
                        },
                        backgroundColor: goldColor.withOpacity(0.2),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    if (isHandicapAccessible != null)
                      Chip(
                        label: Text(
                          'Accès handicapé : ${isHandicapAccessible! ? 'Oui' : 'Non'}',
                          style: GoogleFonts.raleway(fontSize: 12),
                        ),
                        deleteIcon: Icon(Icons.close, size: 16),
                        onDeleted: () {
                          setState(() {
                            isHandicapAccessible = null;
                            _applyFilters();
                          });
                        },
                        backgroundColor: goldColor.withOpacity(0.2),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    if (allowsSmoking != null)
                      Chip(
                        label: Text(
                          'Fumeur : ${allowsSmoking! ? 'Oui' : 'Non'}',
                          style: GoogleFonts.raleway(fontSize: 12),
                        ),
                        deleteIcon: Icon(Icons.close, size: 16),
                        onDeleted: () {
                          setState(() {
                            allowsSmoking = null;
                            _applyFilters();
                          });
                        },
                        backgroundColor: goldColor.withOpacity(0.2),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          Expanded(
            child: isLoading
                ? Center(child: CircularProgressIndicator(color: goldColor))
                : filteredRestaurants.isEmpty
                    ? Center(
                        child: Text(
                          'Aucun restaurant favori trouvé !',
                          style: GoogleFonts.raleway(
                            fontSize: 18,
                            color: Colors.black87,
                          ),
                        ),
                      )
                    : Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0),
                        child: ListView.builder(
                          itemCount: paginatedData.length,
                          itemBuilder: (context, index) {
                            final restaurant = paginatedData[index];
                            final restaurantId = restaurant['idrestaurant'];
                            final restaurantType = _formatRestaurantType(restaurant['typerestaurant']);

                            List<int> cuisineIds = restaurantCuisines[restaurantId] ?? [];
                            List<String> cuisineNames = cuisineIds
                                .map((id) => cuisinesById[id])
                                .where((cuisine) => cuisine != null)
                                .map((cuisine) => _formatCuisineName(cuisine!['nomcuisine'] ?? ''))
                                .toList();

                            return Card(
                              margin: EdgeInsets.only(bottom: 16.0),
                              elevation: 4,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: InkWell(
                                borderRadius: BorderRadius.circular(12),
                                onTap: () {
                                  context.push('/restaurant-details', extra: {
                                    'restaurantId': restaurantId
                                  });
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
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Row(
                                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                children: [
                                                  Expanded(
                                                    child: Text(
                                                      restaurant['nomrestaurant'] ?? 'Sans nom',
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
                                                      favoris.contains(restaurantId)
                                                          ? Icons.favorite
                                                          : Icons.favorite_border,
                                                      color: favoris.contains(restaurantId)
                                                          ? Colors.red
                                                          : Colors.grey,
                                                    ),
                                                    onPressed: () => _toggleFavori(restaurantId),
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
                                              if (cuisineNames.isNotEmpty) ...[
                                                SizedBox(height: 6),
                                                SingleChildScrollView(
                                                  scrollDirection: Axis.horizontal,
                                                  child: Wrap(
                                                    spacing: 4,
                                                    runSpacing: 4,
                                                    children: cuisineNames.map((name) => Container(
                                                      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                                      decoration: BoxDecoration(
                                                        color: goldColor.withOpacity(0.1),
                                                        borderRadius: BorderRadius.circular(8),
                                                        border: Border.all(color: goldColor.withOpacity(0.3)),
                                                      ),
                                                      child: Text(
                                                        name,
                                                        style: GoogleFonts.raleway(
                                                          fontSize: 12,
                                                          color: Colors.black87,
                                                        ),
                                                      ),
                                                    )).toList(),
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
          if (!isLoading && filteredRestaurants.isNotEmpty)
            Container(
              padding: EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 4,
                    offset: Offset(0, -2),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    icon: Icon(Icons.arrow_back_ios, size: 18),
                    onPressed: currentPage > 0
                        ? () {
                            setState(() {
                              currentPage--;
                            });
                          }
                        : null,
                    color: currentPage > 0 ? goldColor : Colors.grey,
                  ),
                  Text(
                    '${currentPage + 1} / $totalPages',
                    style: GoogleFonts.raleway(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.arrow_forward_ios, size: 18),
                    onPressed: currentPage < totalPages - 1
                        ? () {
                            setState(() {
                              currentPage++;
                            });
                          }
                        : null,
                    color: currentPage < totalPages - 1 ? goldColor : Colors.grey,
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
  
  Widget buildInfoTag(String label, IconData icon, Color goldColor) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: goldColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: goldColor.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: goldColor),
          SizedBox(width: 2),
          Text(
            label,
            style: GoogleFonts.raleway(
              fontSize: 10,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }
}