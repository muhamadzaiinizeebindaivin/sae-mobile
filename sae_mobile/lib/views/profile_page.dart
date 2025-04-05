import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:form_builder_validators/form_builder_validators.dart';
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
  final _formKey = GlobalKey<FormBuilderState>();
  bool _isLoading = false;
  bool _isEditing = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  String? _errorMessage;
  Map<String, dynamic>? _userData;
  DateTime? _selectedDate;
  String? _selectedSexe;
  
  final List<String> _sexeOptions = ['Homme', 'Femme'];

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
      if (currentUser != null) {
        final response = await Supabase.instance.client
            .from('utilisateur')
            .select('*')
            .eq('emailutilisateur', currentUser.email!)
            .single();
        
        setState(() {
          _userData = response;
          if (_userData != null && _userData!['ddnutilisateur'] != null) {
            _selectedDate = DateTime.parse(_userData!['ddnutilisateur']);
          }
          _selectedSexe = _userData?['sexeutilisateur'];
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Erreur lors de la récupération des données : $e';
      });
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

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime(2000),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
      locale: const Locale('fr', 'FR'),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: Theme.of(context).primaryColor,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _updateProfile() async {
    if (!_formKey.currentState!.saveAndValidate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final formValue = _formKey.currentState!.value;
      final currentUser = Supabase.instance.client.auth.currentUser;

      if (currentUser == null) {
        throw Exception("Utilisateur non connecté");
      }

      if (_selectedDate == null) {
        throw Exception('Veuillez sélectionner une date de naissance !');
      }

      if (_selectedSexe == null) {
        throw Exception('Veuillez sélectionner un sexe !');
      }

      final userId = _userData?['idutilisateur'];
      if (userId == null) {
        throw Exception('ID utilisateur non trouvé. Veuillez vous reconnecter.');
      }

      final updatedData = {
        'nomutilisateur': formValue['nom'].trim(),
        'prenomutilisateur': formValue['prenom'].trim(),
        'sexeutilisateur': _selectedSexe,
        'ddnutilisateur': _selectedDate!.toIso8601String().split('T')[0],
        'telephoneutilisateur': formValue['telephone'].trim(),
      };

      if (formValue['password'] != null && formValue['password'].toString().isNotEmpty) {
        updatedData['mdputilisateur'] = formValue['password'];

        await Supabase.instance.client.auth.updateUser(
          UserAttributes(
            password: formValue['password'],
          ),
        );
      }

      final response = await Supabase.instance.client
          .from('utilisateur')
          .update(updatedData)
          .eq('idutilisateur', userId)
          .select(); 

      if (response.isEmpty) {
        throw Exception('Aucune ligne mise à jour. Vérifiez l\'ID utilisateur ou les données.');
      }

      setState(() {
        _isEditing = false;
        _userData = response.first; 
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Center(
            child: Text(
              'Profil mis à jour avec succès',
              style: TextStyle(
                fontWeight: FontWeight.bold, 
                color: Colors.white,
              ),
            ),
          ),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 2),
          behavior: SnackBarBehavior.floating, 
          margin: EdgeInsets.only(
            bottom: MediaQuery.of(context).size.height - 100, 
            left: 20,
            right: 20,
          ),
        ),
      );

    } catch (e) {
      setState(() {
        _errorMessage = 'Erreur lors de la mise à jour du profil : $e';
      });
      print('Erreur lors de la mise à jour du profil : $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final goldColor = Theme.of(context).primaryColor;

    if (_isLoading && _userData == null) {
      return Scaffold(
        appBar: AppBar(
          title: Text(
            'Profil',
            style: GoogleFonts.raleway(
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          backgroundColor: goldColor,
          centerTitle: true,
          leading: IconButton(
            icon: Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => context.go('/home-authentified'),
          ),
        ),
        body: Center(
          child: CircularProgressIndicator(color: goldColor),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Profil',
          style: GoogleFonts.raleway(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: goldColor,
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => context.go('/home-authentified'),
        ),
        actions: [
          if (!_isEditing)
            IconButton(
              icon: Icon(Icons.edit, color: Colors.white),
              onPressed: () {
                setState(() {
                  _isEditing = true;
                });
              },
            ),
        ],
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
                  if (!_isEditing) _buildProfileView(goldColor),
                  if (_isEditing) _buildProfileEditForm(goldColor),
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
        currentIndex: 3, 
        selectedItemColor: goldColor,
        unselectedItemColor: Colors.grey,
        type: BottomNavigationBarType.fixed,
        onTap: (index) {
          switch (index) {
            case 0:
              context.go('/home-authentified');
              break;
            case 1:
              context.push('/favoris');
              break;
            case 2:
              context.push('/reviews');
              break;
            case 3:
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

  Widget _buildProfileEditForm(Color goldColor) {
    return FormBuilder(
      key: _formKey,
      initialValue: {
        'nom': _userData?['nomutilisateur'] ?? '',
        'prenom': _userData?['prenomutilisateur'] ?? '',
        'telephone': _userData?['telephoneutilisateur'] ?? '',
        'password': '',
        'confirmPassword': '',
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Modifier le profil',
            style: GoogleFonts.raleway(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: goldColor,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          
          if (_errorMessage != null)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.red.shade200),
              ),
              child: Center(
                child: Text(
                  _errorMessage!,
                  style: TextStyle(color: Colors.red.shade800),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          const SizedBox(height: 16),
          
          Row(
            children: [
              Expanded(
                child: FormBuilderTextField(
                  name: 'nom',
                  decoration: InputDecoration(
                    labelText: 'Nom',
                    prefixIcon: Icon(Icons.person, color: goldColor),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: goldColor, width: 2),
                    ),
                  ),
                  validator: FormBuilderValidators.compose([
                    FormBuilderValidators.required(
                      errorText: 'Veuillez entrer votre nom',
                    ),
                    FormBuilderValidators.match(
                      RegExp(r'^[a-zA-ZÀ-ÿ\s-]+$'),
                      errorText: 'Le nom ne doit contenir que des lettres',
                    ),
                  ]),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: FormBuilderTextField(
                  name: 'prenom',
                  decoration: InputDecoration(
                    labelText: 'Prénom',
                    prefixIcon: Icon(Icons.person_outline, color: goldColor),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: goldColor, width: 2),
                    ),
                  ),
                  validator: FormBuilderValidators.compose([
                    FormBuilderValidators.required(
                      errorText: 'Veuillez entrer votre prénom',
                    ),
                    FormBuilderValidators.match(
                      RegExp(r'^[a-zA-ZÀ-ÿ\s-]+$'),
                      errorText: 'Le prénom ne doit contenir que des lettres',
                    ),
                  ]),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          InkWell(
            onTap: () => _selectDate(context),
            child: InputDecorator(
              decoration: InputDecoration(
                labelText: 'Date de naissance',
                prefixIcon: Icon(Icons.calendar_today, color: goldColor),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: goldColor, width: 2),
                ),
              ),
              child: Text(
                _selectedDate == null
                    ? 'Sélectionner une date'
                    : DateFormat('dd/MM/yyyy').format(_selectedDate!),
              ),
            ),
          ),
          const SizedBox(height: 16),
          
          FormBuilderDropdown<String>(
            name: 'sexe',
            initialValue: _selectedSexe,
            decoration: InputDecoration(
              labelText: 'Sexe',
              prefixIcon: Icon(Icons.people, color: goldColor),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: goldColor, width: 2),
              ),
            ),
            items: _sexeOptions
                .map((value) => DropdownMenuItem(
                      value: value,
                      child: Text(value),
                    ))
                .toList(),
            onChanged: (newValue) {
              setState(() {
                _selectedSexe = newValue;
              });
            },
            validator: FormBuilderValidators.required(
              errorText: 'Veuillez sélectionner votre sexe',
            ),
          ),
          const SizedBox(height: 16),
          
          FormBuilderTextField(
            name: 'telephone',
            keyboardType: TextInputType.phone,
            decoration: InputDecoration(
              labelText: 'Téléphone',
              prefixIcon: Icon(Icons.phone, color: goldColor),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: goldColor, width: 2),
              ),
            ),
            validator: FormBuilderValidators.compose([
              FormBuilderValidators.required(
                  errorText: 'Veuillez entrer votre numéro de téléphone'),
              FormBuilderValidators.match(
                  RegExp(r'^(?:(?:\+|00)33|0)\s*[1-9](?:[\s.-]*\d{2}){4}$'),
                  errorText: 'Veuillez entrer un numéro de téléphone valide'),
            ]),
          ),
          const SizedBox(height: 16),
          
          InputDecorator(
            decoration: InputDecoration(
              labelText: 'Email',
              prefixIcon: Icon(Icons.email, color: goldColor),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey.shade400),
              ),
              filled: true,
              fillColor: Colors.grey.shade100,
            ),
            child: Text(
              _userData?['emailutilisateur'] ?? '',
              style: TextStyle(color: Colors.grey.shade700),
            ),
          ),
          const SizedBox(height: 16),
          
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Changer de mot de passe (optionnel)',
                  style: GoogleFonts.raleway(
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 16),
                
                FormBuilderTextField(
                  name: 'password',
                  obscureText: _obscurePassword,
                  decoration: InputDecoration(
                    labelText: 'Nouveau mot de passe',
                    prefixIcon: Icon(Icons.lock, color: goldColor),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword ? Icons.visibility : Icons.visibility_off,
                        color: goldColor,
                      ),
                      onPressed: () {
                        setState(() {
                          _obscurePassword = !_obscurePassword;
                        });
                      },
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: goldColor, width: 2),
                    ),
                  ),
                  validator: (value) {
                    if (value != null && value.isNotEmpty && value.length < 6) {
                      return 'Le mot de passe doit contenir au moins 6 caractères';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                
                FormBuilderTextField(
                  name: 'confirmPassword',
                  obscureText: _obscureConfirmPassword,
                  decoration: InputDecoration(
                    labelText: 'Confirmer le nouveau mot de passe',
                    prefixIcon: Icon(Icons.lock_outline, color: goldColor),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscureConfirmPassword
                            ? Icons.visibility
                            : Icons.visibility_off,
                        color: goldColor,
                      ),
                      onPressed: () {
                        setState(() {
                          _obscureConfirmPassword = !_obscureConfirmPassword;
                        });
                      },
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: goldColor, width: 2),
                    ),
                  ),
                  validator: (value) {
                    final password = _formKey.currentState?.fields['password']?.value;
                    if (password != null && password.toString().isNotEmpty && password != value) {
                      return 'Les mots de passe ne correspondent pas';
                    }
                    return null;
                  },
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 32),
          
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    setState(() {
                      _isEditing = false;
                      _errorMessage = null;
                    });
                  },
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: goldColor),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    'Annuler',
                    style: GoogleFonts.raleway(
                      color: goldColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _updateProfile,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: goldColor,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isLoading
                      ? CircularProgressIndicator(color: Colors.white)
                      : Text(
                          'Enregistrer',
                          style: GoogleFonts.raleway(
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}