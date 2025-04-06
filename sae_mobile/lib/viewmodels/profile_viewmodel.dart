import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import '../providers/supabase_provider.dart';

class ProfileViewModel extends ChangeNotifier {
  final SupabaseProvider supabaseProvider;
  
  bool isLoading = false;
  Map<String, dynamic>? userData;
  DateTime? selectedDate;
  Map<String, int> userStats = {'reviews': 0, 'favorites': 0};

  ProfileViewModel({required this.supabaseProvider});

  Future<void> fetchUserData() async {
    isLoading = true;
    notifyListeners();

    try {
      final currentUser = Supabase.instance.client.auth.currentUser;
      if (currentUser == null || currentUser.email == null) {
        throw Exception("Utilisateur non connecté ou email manquant");
      }

      final response = await Supabase.instance.client
          .from('utilisateur')
          .select('*')
          .eq('emailutilisateur', currentUser.email!)
          .single()
          .catchError((error) {
            throw Exception("Aucun utilisateur trouvé avec cet email : $error");
          });

      userData = response;
      selectedDate = userData?['ddnutilisateur'] != null 
          ? DateTime.parse(userData!['ddnutilisateur']) 
          : null;
      
      // Fetch stats right away
      await fetchUserStats();
    } catch (e) {
      print('Erreur lors de la récupération des données utilisateur : $e');
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchUserStats() async {
    if (userData == null) return;
    
    final currentUser = Supabase.instance.client.auth.currentUser;
    if (currentUser == null) {
      userStats = {'reviews': 0, 'favorites': 0};
      notifyListeners();
      return;
    }

    try {
      final reviewsResponse = await Supabase.instance.client
          .from('critiquer')
          .select('idrestaurant')
          .eq('idutilisateur', userData!['idutilisateur'])
          .count();

      final favoritesResponse = await Supabase.instance.client
          .from('aimer')
          .select('idrestaurant')
          .eq('idutilisateur', userData!['idutilisateur'])
          .count();

      userStats = {
        'reviews': reviewsResponse.count,
        'favorites': favoritesResponse.count,
      };
      notifyListeners();
    } catch (e) {
      print('Erreur lors de la récupération des statistiques : $e');
      userStats = {'reviews': 0, 'favorites': 0};
      notifyListeners();
    }
  }
  
  String getFormattedBirthDate() {
    return selectedDate != null 
        ? DateFormat('dd/MM/yyyy').format(selectedDate!) 
        : 'Non spécifiée';
  }
  
  String getMemberSinceDate() {
    return userData != null 
        ? DateFormat('dd/MM/yyyy').format(DateTime.parse(userData!['dateinscriptionutilisateur'] ?? DateTime.now().toIso8601String())) 
        : 'Récemment';
  }
  
  Future<void> signOut() async {
    await Supabase.instance.client.auth.signOut();
  }
}