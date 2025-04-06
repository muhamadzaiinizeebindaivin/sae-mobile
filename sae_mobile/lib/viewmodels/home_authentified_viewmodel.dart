import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class HomeAuthentifiedViewModel extends ChangeNotifier {
  final SupabaseClient supabaseClient;
  String? _userName;
  int _selectedIndex = 0;

  String? get userName => _userName;
  int get selectedIndex => _selectedIndex;

  HomeAuthentifiedViewModel({required this.supabaseClient}) {
    fetchUserDetails();
  }

  Future<void> fetchUserDetails() async {
    final currentUser = supabaseClient.auth.currentUser;
    if (currentUser != null) {
      try {
        final response = await supabaseClient
            .from('utilisateur')
            .select('nomutilisateur, prenomutilisateur')
            .eq('emailutilisateur', currentUser.email!)
            .single();

        _userName = '${response['prenomutilisateur']} ${response['nomutilisateur']}';
        notifyListeners();
      } catch (e) {
        print('Erreur de récupération des détails utilisateur : $e');
      }
    }
  }

  Future<void> logout() async {
    try {
      await supabaseClient.auth.signOut();
    } catch (e) {
      throw Exception('Erreur de déconnexion : $e');
    }
  }

  void setSelectedIndex(int index) {
    _selectedIndex = index;
    notifyListeners();
  }
}