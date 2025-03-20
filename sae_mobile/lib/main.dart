import 'package:flutter/material.dart';
import 'home_screen.dart';
import 'restaurant.dart';


void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primaryColor: Color(0xFFFA8C3B), // Orange légère
        scaffoldBackgroundColor: Colors.white, // Fond blanc
        textTheme: TextTheme(
          bodyLarge: TextStyle(color: Colors.black),
          bodyMedium: TextStyle(color: Colors.grey[700]),
          titleLarge: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Color(0xFF3E3E3E),
          ),
          titleMedium: TextStyle(
            fontSize: 18,
            color: Colors.grey[600],
          ),
        ),
        cardColor: Colors.grey[50], // Carte avec un léger beige
        buttonTheme: ButtonThemeData(
          buttonColor: Color(0xFFFA8C3B), // Orange léger pour les boutons
          textTheme: ButtonTextTheme.primary,
        ),
      ),
      home: HomeScreen(),
    );
  }
}
