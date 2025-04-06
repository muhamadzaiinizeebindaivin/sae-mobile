import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../providers/supabase_provider.dart';
import '../viewmodels/home_authentified_viewmodel.dart';

class HomeAuthentifiedPage extends StatelessWidget {
  final SupabaseProvider supabaseProvider;

  const HomeAuthentifiedPage({
    Key? key,
    required this.supabaseProvider,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final goldColor = Theme.of(context).primaryColor;

    return ChangeNotifierProvider(
      create: (_) => HomeAuthentifiedViewModel(
        supabaseClient: Supabase.instance.client
      ),
      child: Scaffold(
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
            Consumer<HomeAuthentifiedViewModel>(
              builder: (context, viewModel, _) => IconButton(
                icon: Icon(Icons.logout, color: Colors.white),
                onPressed: () async {
                  try {
                    await viewModel.logout();
                    context.go('/');
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('$e'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                },
              ),
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
                    child: Consumer<HomeAuthentifiedViewModel>(
                      builder: (context, viewModel, _) => Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(top: 30),
                            child: Column(
                              children: [
                                Text(
                                  'Bienvenue${viewModel.userName != null ? ', ${viewModel.userName}' : ''}',
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
                                  title: 'Favoris',
                                  description: 'Consultez vos restaurants favoris',
                                  icon: Icons.favorite,
                                  color: goldColor,
                                  onTap: () => context.push('/favoris'),
                                ),
                                SizedBox(height: 20),
                                _buildNavigationCard(
                                  context,
                                  title: 'Critiques',
                                  description: 'Vos avis et commentaires',
                                  icon: Icons.rate_review,
                                  color: goldColor,
                                  onTap: () => context.push('/user-reviews'),
                                ),
                                SizedBox(height: 20),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        bottomNavigationBar: Consumer<HomeAuthentifiedViewModel>(
          builder: (context, viewModel, _) => BottomNavigationBar(
            items: const <BottomNavigationBarItem>[
              BottomNavigationBarItem(
                icon: Icon(Icons.home),
                label: 'Accueil',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.person),
                label: 'Profil',
              ),
            ],
            currentIndex: viewModel.selectedIndex,
            selectedItemColor: goldColor,
            unselectedItemColor: Colors.grey,
            onTap: (index) {
              viewModel.setSelectedIndex(index);
              if (index == 1) {
                context.push('/profile');
              }
            },
          ),
        ),
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
}