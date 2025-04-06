import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import '../providers/supabase_provider.dart';

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
  bool _isLoading = false;
  Map<String, dynamic>? _userData;
  DateTime? _selectedDate;
  
  @override
  void initState() {
    super.initState();
    _fetchUserData();
  }

  Future<void> _fetchUserData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final currentUser = Supabase.instance.client.auth.currentUser;
      if (currentUser == null || currentUser.email == null) {
        throw Exception("Utilisateur non connecté ou email manquant");
      }

      final response = await Supabase.instance.client
          .from('utilisateur')
          .select('*')
          .eq('emailutilisateur', currentUser.email!)
          .single()
          .catchError((error) {
            throw Exception("Aucun utilisateur trouvé avec cet email : $error");
          });

      setState(() {
        _userData = response;
        _selectedDate = _userData?['ddnutilisateur'] != null ? DateTime.parse(_userData!['ddnutilisateur']) : null;
      });
    } catch (e) {
      print('Erreur lors de la récupération des données utilisateur : $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<Map<String, int>> _fetchUserStats() async {
    final currentUser = Supabase.instance.client.auth.currentUser;
    if (currentUser == null) return {'reviews': 0, 'favorites': 0};

    try {
      final reviewsResponse = await Supabase.instance.client
          .from('critiquer')
          .select('idrestaurant')
          .eq('idutilisateur', _userData!['idutilisateur'])
          .count();

      final favoritesResponse = await Supabase.instance.client
          .from('aimer')
          .select('idrestaurant')
          .eq('idutilisateur', _userData!['idutilisateur'])
          .count();

      return {
        'reviews': reviewsResponse.count,
        'favorites': favoritesResponse.count,
      };
    } catch (e) {
      print('Erreur lors de la récupération des statistiques : $e');
      return {'reviews': 0, 'favorites': 0};
    }
  }

  @override
  Widget build(BuildContext context) {
    final goldColor = Theme.of(context).primaryColor;

    if (_isLoading && _userData == null) {
      return Scaffold(
        appBar: AppBar(
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
        ),
        body: Center(
          child: CircularProgressIndicator(color: goldColor),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
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
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                children: [
                  Container(
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
                  ),
                  const SizedBox(height: 24),
                  _buildProfileView(goldColor),
                ],
              ),
            ),
          ),
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
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
      ),
    );
  }

  Widget _buildProfileView(Color goldColor) {
    return FutureBuilder<Map<String, int>>(
      future: _fetchUserStats(),
      builder: (context, snapshot) {
        int reviewsCount = snapshot.data?['reviews'] ?? 0;
        int favoritesCount = snapshot.data?['favorites'] ?? 0;

        return Column(
          children: [
            Text(
              '${_userData?['prenomutilisateur'] ?? ''} ${_userData?['nomutilisateur'] ?? ''}',
              style: GoogleFonts.raleway(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: goldColor,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              _userData?['emailutilisateur'] ?? '',
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
                _buildInfoItem(icon: Icons.calendar_today, title: 'Date de naissance', value: _selectedDate != null ? DateFormat('dd/MM/yyyy').format(_selectedDate!) : 'Non spécifiée'),
                _buildInfoItem(icon: Icons.people, title: 'Sexe', value: _userData?['sexeutilisateur'] ?? 'Non spécifié'),
                _buildInfoItem(icon: Icons.phone, title: 'Téléphone', value: _userData?['telephoneutilisateur'] ?? 'Non spécifié'),
              ],
            ),
            const SizedBox(height: 32),
            _buildInfoSection(
              title: 'Statistiques',
              children: [
                _buildInfoItem(icon: Icons.star, title: 'Avis publiés', value: reviewsCount.toString()),
                _buildInfoItem(icon: Icons.favorite, title: 'Restaurants favoris', value: favoritesCount.toString()),
                _buildInfoItem(icon: Icons.calendar_today, title: 'Membre depuis', value: _userData != null ? DateFormat('dd/MM/yyyy').format(DateTime.parse(_userData!['dateinscriptionutilisateur'] ?? DateTime.now().toIso8601String())) : 'Récemment'),
              ],
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: () async {
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
      },
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
}