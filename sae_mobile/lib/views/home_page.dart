import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/supabase_provider.dart';

class HomePage extends StatelessWidget {
  final SupabaseProvider supabaseProvider;
  
  const HomePage({
    Key? key, 
    required this.supabaseProvider,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final goldColor = Color(0xFFD4AF37);
    
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'IUTables\'O',
          style: GoogleFonts.raleway(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: goldColor,
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => context.go('/'),
        ),
      ),
      body: SafeArea(
        child: Center(
          child: LayoutBuilder(
            builder: (context, constraints) {
              return Container(
                constraints: BoxConstraints(maxWidth: 600),
                margin: EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(top: 30),
                      child: Column(
                        children: [
                          Text(
                            'Explorer IUTables\'O',
                            style: GoogleFonts.raleway(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: goldColor,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          SizedBox(height: 10),
                          Text(
                            'Découvrez les restaurants et cuisines d\'Orléans',
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
                      padding: const EdgeInsets.symmetric(vertical: 40),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _buildNavigationCard(
                            context,
                            title: 'Restaurants',
                            description: 'Parcourir tous les restaurants d\'Orléans',
                            icon: Icons.restaurant,
                            color: goldColor,
                            onTap: () => context.go('/restaurants'),
                          ),
                          SizedBox(height: 20),
                          _buildNavigationCard(
                            context,
                            title: 'Types de cuisine',
                            description: 'Explorer les différentes cuisines',
                            icon: Icons.dinner_dining,
                            color: goldColor,
                            onTap: () => context.go('/cuisines'),
                          ),
                        ],
                      ),
                    ),
                    
                    Spacer(),
                    
                    Padding(
                      padding: const EdgeInsets.only(bottom: 24),
                      child: Container(
                        width: double.infinity,
                        padding: EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.grey.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.info_outline,
                              color: goldColor,
                              size: 30,
                            ),
                            SizedBox(height: 10),
                            Text(
                              'Mode visiteur',
                              style: GoogleFonts.raleway(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: goldColor,
                              ),
                            ),
                            SizedBox(height: 8),
                            Text(
                              'Vous naviguez en tant que visiteur. Pour laisser des avis, aimer des restaurants ou enregistrer vos préférences, veuillez vous connecter.',
                              textAlign: TextAlign.center,
                              style: GoogleFonts.raleway(
                                fontSize: 14,
                                color: Colors.black87,
                              ),
                            ),
                            SizedBox(height: 16),
                            SizedBox(
                              width: 150,
                              child: OutlinedButton(
                                onPressed: () => context.go('/login'),
                                style: OutlinedButton.styleFrom(
                                  side: BorderSide(color: goldColor),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                                child: Text(
                                  'Se connecter',
                                  style: GoogleFonts.raleway(
                                    color: goldColor,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }
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