import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../providers/supabase_provider.dart';

class HomeAuthentifiedPage extends StatefulWidget {
  final SupabaseProvider supabaseProvider;
  
  const HomeAuthentifiedPage({
    Key? key, 
    required this.supabaseProvider,
  }) : super(key: key);

  @override
  _HomeAuthentifiedPageState createState() => _HomeAuthentifiedPageState();
}

class _HomeAuthentifiedPageState extends State<HomeAuthentifiedPage> {
  String? _userName;
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    _fetchUserDetails();
  }

  Future<void> _fetchUserDetails() async {
    final currentUser = Supabase.instance.client.auth.currentUser;
    if (currentUser != null) {
      try {
        final response = await Supabase.instance.client
            .from('utilisateur')
            .select('nomutilisateur, prenomutilisateur')
            .eq('emailutilisateur', currentUser.email!)
            .single();

        setState(() {
          _userName = '${response['prenomutilisateur']} ${response['nomutilisateur']}';
        });
      } catch (e) {
        print('Erreur de récupération des détails utilisateur : $e');
      }
    }
  }

  void _logout() async {
    try {
      await Supabase.instance.client.auth.signOut();
      if (mounted) {
        context.go('/');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur de déconnexion : $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
    
    switch (index) {
      case 0:
        break;
      case 1:
        context.push('/favoris');
        break;
      case 2:
        context.push('/user-reviews');
        break;
      case 3:
        context.push('/profile');
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final goldColor = Theme.of(context).primaryColor;
    
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false, 
        title: Text(
          'IUTables\'O',
          style: GoogleFonts.raleway(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: goldColor,
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(Icons.logout, color: Colors.white),
            onPressed: _logout,
          ),
        ],
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return Center(
              child: Container(
                constraints: BoxConstraints(maxWidth: 600),
                margin: EdgeInsets.symmetric(horizontal: 16),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center, 
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(top: 30),
                        child: Column(
                          children: [
                            Text(
                              'Bienvenue${_userName != null ? ', $_userName' : ''}',
                              style: GoogleFonts.raleway(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: goldColor,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            SizedBox(height: 10),
                            Text(
                              'Explorez les restaurants et cuisines d\'Orléans',
                              style: GoogleFonts.raleway(
                                fontSize: 16,
                                color: Colors.black87,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                      
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 20),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.asset(
                            'assets/images/restaurant.jpg',
                            width: double.infinity,
                            height: 200,
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                      
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 20),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            _buildNavigationCard(
                              context,
                              title: 'Restaurants',
                              description: 'Parcourir tous les restaurants d\'Orléans',
                              icon: Icons.restaurant,
                              color: goldColor,
                              onTap: () => context.push('/restaurants'),
                            ),
                            SizedBox(height: 20),
                            _buildNavigationCard(
                              context,
                              title: 'Types de cuisine',
                              description: 'Explorer les différentes cuisines',
                              icon: Icons.dinner_dining,
                              color: goldColor,
                              onTap: () => context.push('/cuisines'),
                            ),
                            SizedBox(height: 20),
                            _buildNavigationCard(
                              context,
                              title: 'Fav resto',
                              description: 'Fav resto',
                              icon: Icons.dinner_dining,
                              color: goldColor,
                              onTap: () => context.push('/favoris'),
                            ),

                            SizedBox(height: 20),
                          ],
                        ),
                      ),
                      
                      Padding(
                        padding: const EdgeInsets.only(top: 20, bottom: 10),
                        child: Text(
                          'À la une',
                          style: GoogleFonts.raleway(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: goldColor,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      
                      Padding(
                        padding: const EdgeInsets.only(bottom: 30),
                        child: Row(
                          children: [
                            Expanded(
                              child: _buildFeaturedCard(
                                context,
                                title: 'Mieux notés',
                                icon: Icons.star,
                                color: goldColor,
                                onTap: () => context.push('/top-rated'),
                              ),
                            ),
                            SizedBox(width: 12),
                            Expanded(
                              child: _buildFeaturedCard(
                                context,
                                title: 'À proximité',
                                icon: Icons.near_me,
                                color: goldColor,
                                onTap: () => context.push('/nearby'),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Accueil',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.favorite),
            label: 'Favoris',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.rate_review),
            label: 'Critiques',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profil',
          ),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: goldColor,
        unselectedItemColor: Colors.grey,
        type: BottomNavigationBarType.fixed,
        onTap: _onItemTapped,
      ),
    );
  }

  Widget _buildNavigationCard(
    BuildContext context, {
    required String title,
    required String description,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  color: color,
                  size: 30,
                ),
              ),
              SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.raleway(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      description,
                      style: GoogleFonts.raleway(
                        fontSize: 14,
                        color: Colors.black54,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right,
                color: Colors.grey,
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildFeaturedCard(
    BuildContext context, {
    required String title,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  color: color,
                  size: 30,
                ),
              ),
              SizedBox(height: 12),
              Text(
                title,
                style: GoogleFonts.raleway(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}