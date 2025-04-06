import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../providers/supabase_provider.dart';
import '../viewmodels/profile_viewmodel.dart';

class ProfilePage extends StatefulWidget {
  final SupabaseProvider supabaseProvider;
  
  const ProfilePage({
    Key? key,
    required this.supabaseProvider,
  }) : super(key: key);

  @override
  _ProfilePageState createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  late ProfileViewModel _viewModel;
  
  @override
  void initState() {
    super.initState();
    _viewModel = ProfileViewModel(supabaseProvider: widget.supabaseProvider);
    _viewModel.fetchUserData();
  }

  @override
  Widget build(BuildContext context) {
    final goldColor = Theme.of(context).primaryColor;

    return ChangeNotifierProvider.value(
      value: _viewModel,
      child: Consumer<ProfileViewModel>(
        builder: (context, viewModel, _) {
          if (viewModel.isLoading && viewModel.userData == null) {
            return Scaffold(
              appBar: _buildAppBar(goldColor),
              body: Center(
                child: CircularProgressIndicator(color: goldColor),
              ),
            );
          }

          return Scaffold(
            appBar: _buildAppBar(goldColor),
            body: SafeArea(
              child: Center(
                child: SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      children: [
                        _buildProfileImage(goldColor),
                        const SizedBox(height: 24),
                        _buildProfileView(viewModel, goldColor),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            bottomNavigationBar: _buildBottomNavBar(goldColor, context),
          );
        },
      ),
    );
  }

  AppBar _buildAppBar(Color goldColor) {
    return AppBar(
      automaticallyImplyLeading: false,
      title: Text(
        'Profil',
        style: GoogleFonts.raleway(
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
      backgroundColor: goldColor,
      centerTitle: true,
    );
  }

  Widget _buildProfileImage(Color goldColor) {
    return Container(
      width: 120,
      height: 120,
      decoration: BoxDecoration(
        color: goldColor.withOpacity(0.1),
        shape: BoxShape.circle,
        border: Border.all(color: goldColor, width: 2),
      ),
      child: Icon(
        Icons.person,
        size: 80,
        color: goldColor,
      ),
    );
  }

  Widget _buildProfileView(ProfileViewModel viewModel, Color goldColor) {
    return Column(
      children: [
        Text(
          '${viewModel.userData?['prenomutilisateur'] ?? ''} ${viewModel.userData?['nomutilisateur'] ?? ''}',
          style: GoogleFonts.raleway(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: goldColor,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(
          viewModel.userData?['emailutilisateur'] ?? '',
          style: GoogleFonts.raleway(
            fontSize: 16,
            color: Colors.grey[600],
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 32),
        _buildInfoSection(
          title: 'Informations personnelles',
          children: [
            _buildInfoItem(icon: Icons.calendar_today, title: 'Date de naissance', value: viewModel.getFormattedBirthDate()),
            _buildInfoItem(icon: Icons.people, title: 'Sexe', value: viewModel.userData?['sexeutilisateur'] ?? 'Non spécifié'),
            _buildInfoItem(icon: Icons.phone, title: 'Téléphone', value: viewModel.userData?['telephoneutilisateur'] ?? 'Non spécifié'),
          ],
        ),
        const SizedBox(height: 32),
        _buildInfoSection(
          title: 'Statistiques',
          children: [
            _buildInfoItem(icon: Icons.star, title: 'Avis publiés', value: viewModel.userStats['reviews'].toString()),
            _buildInfoItem(icon: Icons.favorite, title: 'Restaurants favoris', value: viewModel.userStats['favorites'].toString()),
            _buildInfoItem(icon: Icons.calendar_today, title: 'Membre depuis', value: viewModel.getMemberSinceDate()),
          ],
        ),
        const SizedBox(height: 32),
        ElevatedButton.icon(
          onPressed: () async {
            try {
              await viewModel.signOut();
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
          },
          icon: Icon(Icons.logout, color: Colors.white),
          label: Text(
            'Se déconnecter',
            style: GoogleFonts.raleway(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: goldColor,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInfoSection({required String title, required List<Widget> children}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.raleway(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }

  Widget _buildInfoItem({required IconData icon, required String title, required String value}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(
            icon,
            color: Theme.of(context).primaryColor,
            size: 20,
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: GoogleFonts.raleway(
                  color: Colors.grey[600],
                  fontSize: 12,
                ),
              ),
              Text(
                value,
                style: GoogleFonts.raleway(
                  fontWeight: FontWeight.w500,
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
  
  Widget _buildBottomNavBar(Color goldColor, BuildContext context) {
    return BottomNavigationBar(
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
      currentIndex: 1,  
      selectedItemColor: goldColor,
      unselectedItemColor: Colors.grey,
      onTap: (index) {
        switch (index) {
          case 0:
            context.go('/home-authentified');
            break;
          case 1:
            break;
        }
      },
    );
  }
}