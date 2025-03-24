import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'providers/supabase_provider.dart';
import 'views/welcome_page.dart';
import 'views/login_page.dart';
import 'views/register_page.dart';
import 'views/home_page.dart';
import 'views/restaurants_page.dart';
import 'views/cuisines_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final supabaseProvider = SupabaseProvider();
  final isConnected = await supabaseProvider.initialize();
  runApp(MyApp(isConnected: isConnected, supabaseProvider: supabaseProvider));
}

class MyApp extends StatelessWidget {
  final bool isConnected;
  final SupabaseProvider supabaseProvider;
  
  MyApp({required this.isConnected, required this.supabaseProvider});

  @override
  Widget build(BuildContext context) {
    final goldColor = Color(0xFFD4AF37);
    final router = GoRouter(
      initialLocation: '/',
      routes: [
        GoRoute(
          path: '/',
          builder: (context, state) => WelcomePage(),
        ),
        GoRoute(
          path: '/login',
          builder: (context, state) => LoginPage(supabaseProvider: supabaseProvider),
        ),
        GoRoute(
          path: '/register',
          builder: (context, state) => RegisterPage(supabaseProvider: supabaseProvider),
        ),
        GoRoute(
          path: '/home',
          builder: (context, state) => HomePage(supabaseProvider: supabaseProvider),
        ),
        GoRoute(
          path: '/restaurants',
          builder: (context, state) => RestaurantsPage(supabaseProvider: supabaseProvider),
        ),
        GoRoute(
          path: '/cuisines',
          builder: (context, state) => CuisinesPage(supabaseProvider: supabaseProvider),
        ),
      ],
    );

    return MaterialApp.router(
      title: 'IUTables\'O',
      theme: ThemeData(
        primaryColor: goldColor,
        colorScheme: ColorScheme.fromSeed(
          seedColor: goldColor,
          primary: goldColor,
        ),
        fontFamily: 'Raleway',
        visualDensity: VisualDensity.adaptivePlatformDensity,
        useMaterial3: true,
      ),
      routerConfig: router,
      debugShowCheckedModeBanner: false,
    );
  }
}