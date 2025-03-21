import 'package:flutter/material.dart';
import 'provider/supabase_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final supabaseProvider = SupabaseProvider();
  final isConnected = await supabaseProvider.initialize();

  runApp(MyApp(isConnected: isConnected));
}

class MyApp extends StatelessWidget {
  final bool isConnected;

  MyApp({required this.isConnected});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Test Connexion Supabase',
      home: HomePage(isConnected: isConnected),
    );
  }
}

class HomePage extends StatelessWidget {
  final bool isConnected;

  HomePage({required this.isConnected});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Test Connexion Supabase')),
      body: Center(
        child: Text(
          isConnected ? "Connexion réussie à Supabase !" : "Erreur de connexion à Supabase.",
          style: TextStyle(fontSize: 20),
        ),
      ),
    );
  }
}
