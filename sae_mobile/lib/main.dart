import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart'; 
import 'package:go_router/go_router.dart';
import 'package:sae_mobile/views/favoris_cuisine.dart';
import 'providers/supabase_provider.dart';
import 'views/welcome_page.dart';
import 'views/login_page.dart';
import 'views/register_page.dart';
import 'views/home_page.dart';
import 'views/restaurants_page.dart';
import 'views/cuisines_page.dart';
import 'views/cuisine_details_page.dart';
import 'views/restaurant_details_page.dart';
import 'views/home_authentified_page.dart';
import 'views/favoris_page.dart';
import 'views/favoris_cuisine.dart';
import 'views/profile_page.dart';


void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final supabaseProvider = SupabaseProvider();
  final isConnected = await supabaseProvider.initialize();
  runApp(MyApp(isConnected: isConnected, supabaseProvider: supabaseProvider));
}

class MyApp extends StatelessWidget {
  final bool isConnected;
  final SupabaseProvider supabaseProvider;
  
  MyApp({required this.isConnected, required this.supabaseProvider, super.key});

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
        GoRoute(
          path: '/favoris',
          builder: (context, state) => FavorisPage(supabaseProvider: supabaseProvider),
        ),
        GoRoute(
          path: '/favorisCuisine',
          builder: (context, state) => FavorisCuisinesPage(supabaseProvider: supabaseProvider),
        ),
        GoRoute(
          path: '/cuisine-details',
          builder: (context, state) {
            final Map<String, dynamic> extras = state.extra as Map<String, dynamic>;
            return CuisineDetailsPage(
              supabaseProvider: supabaseProvider,
              cuisineId: extras['cuisineId'],
              cuisineName: extras['cuisineName'],
            );
          },
        ),
        GoRoute(
          path: '/restaurant-details',
          builder: (context, state) {
            final Map<String, dynamic> extras = state.extra as Map<String, dynamic>;
            return RestaurantDetailsPage(
              supabaseProvider: supabaseProvider,
              restaurantId: extras['restaurantId'],
            );
          },
        ),
        GoRoute(
          path: '/home-authentified',
          builder: (context, state) => HomeAuthentifiedPage(supabaseProvider: supabaseProvider), // Add this route
        ),
        GoRoute(
          path: '/profile',
          builder: (context, state) => ProfilePage(supabaseProvider: supabaseProvider),
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
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('en', ''),
        Locale('fr', 'FR'),
      ],
    );
  }
}