import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseProvider {
  final String url = 'https://heootpqulekvkzimsmhy.supabase.co'; 
  final String anonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imhlb290cHF1bGVrdmt6aW1zbWh5Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3Mzc5ODk3NjMsImV4cCI6MjA1MzU2NTc2M30.7Qct7_hx5NuxpFg3Se29JTG7lP1qGrpqYNGdDjzhazc'; // Remplacez par votre clé publique

  Future<bool> initialize() async {
    try {
      await Supabase.initialize(
        url: url,
        anonKey: anonKey,
      );
      return true; 
    } catch (e) {
      print('Erreur de connexion à Supabase : $e');
      return false; 
    }
  }
}
