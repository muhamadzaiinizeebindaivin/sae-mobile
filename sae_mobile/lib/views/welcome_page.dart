import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

class WelcomePage extends StatelessWidget {
  
  const WelcomePage({
    Key? key
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
      ),
      body: Center(  
        child: Container(
          constraints: BoxConstraints(maxWidth: 600),  
          child: SafeArea(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Center(  
                      child: Icon(
                        Icons.restaurant_rounded,
                        size: 100,
                        color: goldColor,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Center(  
                      child: Text(
                        'IUTables\'O',
                        style: GoogleFonts.raleway(
                          fontSize: 36,
                          fontWeight: FontWeight.bold,
                          color: goldColor,
                        ),
                        textAlign: TextAlign.center,  
                      ),
                    ),
                    const SizedBox(height: 10),
                    Center(  
                      child: Text(
                        'Découvrez les meilleurs restaurants d\'Orléans',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.raleway(
                          fontSize: 18,
                          color: Colors.black87,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    const SizedBox(height: 40),
                    Center(  
                      child: Container(
                        width: double.infinity, 
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.grey.withOpacity(0.3),
                              spreadRadius: 1,
                              blurRadius: 5,
                              offset: const Offset(0, 3),
                            ),
                          ],
                          border: Border.all(color: goldColor.withOpacity(0.3), width: 1),
                        ),
                        child: Text(
                          'Rejoigniez notre communauté et trouvez les restaurants qui vous correspondent !',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.raleway(
                            fontSize: 16,
                            height: 1.5,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 40),
                    Center( 
                      child: ElevatedButton(
                        onPressed: () {
                          context.push('/register');
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: goldColor,
                          minimumSize: const Size(double.infinity, 55),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 3,
                        ),
                        child: Text(
                          'S\'inscrire',
                          style: GoogleFonts.raleway(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Center(  
                      child: OutlinedButton(
                        onPressed: () {
                          context.push('/login');
                        },
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size(double.infinity, 55),
                          side: BorderSide(color: goldColor, width: 2),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(
                          'Se connecter',
                          style: GoogleFonts.raleway(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: goldColor,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    
                    Center(  
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,  
                        children: [
                          Expanded(
                            child: Divider(
                              color: Colors.grey.withOpacity(0.5),
                              thickness: 1,
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16.0),
                            child: Text(
                              'OU',
                              style: GoogleFonts.raleway(
                                color: Colors.grey,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          Expanded(
                            child: Divider(
                              color: Colors.grey.withOpacity(0.5),
                              thickness: 1,
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    const SizedBox(height: 24),
                    
                    Center(  
                      child: Container(
                        width: double.infinity,  
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          color: Colors.white,
                          border: Border.all(color: goldColor, width: 1),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.grey.withOpacity(0.2),
                              spreadRadius: 1,
                              blurRadius: 3,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            borderRadius: BorderRadius.circular(12),
                            onTap: () {
                              context.push('/home');
                            },
                            child: Container(
                              padding: EdgeInsets.symmetric(vertical: 15, horizontal: 10),
                              width: double.infinity,
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,  
                                children: [
                                  Icon(
                                    Icons.remove_red_eye_outlined,
                                    color: goldColor,
                                    size: 22,
                                  ),
                                  SizedBox(width: 10),
                                  Text(
                                    'Explorer sans compte',
                                    style: GoogleFonts.raleway(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: goldColor,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    
                    const SizedBox(height: 30),
                    
                    Center(  
                      child: Text(
                        'Fonctionnalités réservées aux membres :',
                        style: GoogleFonts.raleway(
                          fontWeight: FontWeight.bold,
                          color: goldColor,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Center(  
                      child: Wrap(  
                        alignment: WrapAlignment.center,  
                        spacing: 16, 
                        runSpacing: 16, 
                        children: [
                          _buildFeatureItem(Icons.star, 'Noter', goldColor),
                          _buildFeatureItem(Icons.favorite, 'Aimer', goldColor),
                          _buildFeatureItem(Icons.comment, 'Commenter', goldColor),
                          _buildFeatureItem(Icons.camera_alt, 'Photos', goldColor),
                          _buildFeatureItem(Icons.menu_book, 'Préférences', goldColor),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFeatureItem(IconData icon, String text, Color color) {
    return Column(
      mainAxisSize: MainAxisSize.min,  
      mainAxisAlignment: MainAxisAlignment.center, 
      crossAxisAlignment: CrossAxisAlignment.center, 
      children: [
        Icon(icon, color: color),
        const SizedBox(height: 4),
        Text(
          text,
          style: GoogleFonts.raleway(fontSize: 12),
          textAlign: TextAlign.center, 
        ),
      ],
    );
  }
}