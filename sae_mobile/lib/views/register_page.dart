import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:form_builder_validators/form_builder_validators.dart';
import '../providers/supabase_provider.dart';

class RegisterPage extends StatefulWidget {
  final SupabaseProvider supabaseProvider;

  const RegisterPage({Key? key, required this.supabaseProvider}) : super(key: key);

  @override
  _RegisterPageState createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _formKey = GlobalKey<FormBuilderState>();
  DateTime? _selectedDate;
  String? _selectedSexe;
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  String? _errorMessage;

  final List<String> _sexeOptions = ['Homme', 'Femme'];

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

  Future<void> _register() async {
    if (!_formKey.currentState!.saveAndValidate()) return;
    if (_selectedDate == null) {
      setState(() {
        _errorMessage = 'Veuillez sélectionner votre date de naissance';
      });
      return;
    }
    if (_selectedSexe == null) {
      setState(() {
        _errorMessage = 'Veuillez sélectionner votre sexe';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final formValue = _formKey.currentState!.value;
      final authResponse = await Supabase.instance.client.auth.signUp(
        email: formValue['email'].trim(),
        password: formValue['password'],
      );

      if (authResponse.user != null) {
        await Supabase.instance.client.from('UTILISATEUR').insert({
          'nomUtilisateur': formValue['nom'].trim(),
          'prenomUtilisateur': formValue['prenom'].trim(),
          'sexeUtilisateur': _selectedSexe,
          'ddnUtilisateur': _selectedDate!.toIso8601String().split('T')[0],
          'telephoneUtilisateur': formValue['telephone'].trim(),
          'emailUtilisateur': formValue['email'].trim(),
          'mdpUtilisateur': formValue['password'],
        });

        if (mounted) {
          context.go('/login');
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Compte créé avec succès ! Veuillez vous connecter.'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        setState(() {
          _errorMessage = 'Erreur lors de la création du compte';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Erreur: ${e.toString()}';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final goldColor = Theme.of(context).primaryColor;

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
      body: SafeArea(
        child: Stack(
          children: [
            Positioned(
              top: 8,
              left: 8,
              child: IconButton(
                icon: Icon(
                  Icons.arrow_back,
                  color: goldColor,
                  size: 28,
                ),
                onPressed: () => context.go('/'),
              ),
            ),
            Center(
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
                  child: FormBuilder(
                    key: _formKey,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Icon(
                          Icons.app_registration_rounded,
                          size: 70,
                          color: goldColor,
                        ),
                        const SizedBox(height: 24),
                        Text(
                          'Créer un compte',
                          style: GoogleFonts.raleway(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: goldColor,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        if (_errorMessage != null)
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.red.shade50,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.red.shade200),
                            ),
                            child: Text(
                              _errorMessage!,
                              style: TextStyle(color: Colors.red.shade800),
                            ),
                          ),
                        const SizedBox(height: 24),
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
                                validator: FormBuilderValidators.required(
                                  errorText: 'Veuillez entrer votre nom',
                                ),
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
                                validator: FormBuilderValidators.required(
                                  errorText: 'Veuillez entrer votre prénom',
                                ),
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
                        FormBuilderTextField(
                          name: 'email',
                          keyboardType: TextInputType.emailAddress,
                          decoration: InputDecoration(
                            labelText: 'Email',
                            hintText: 'exemple@email.com',
                            prefixIcon: Icon(Icons.email, color: goldColor),
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
                                errorText: 'Veuillez entrer votre email'),
                            FormBuilderValidators.email(
                                errorText: 'Veuillez entrer un email valide'),
                          ]),
                        ),
                        const SizedBox(height: 16),
                        FormBuilderTextField(
                          name: 'password',
                          obscureText: _obscurePassword,
                          decoration: InputDecoration(
                            labelText: 'Mot de passe',
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
                          validator: FormBuilderValidators.compose([
                            FormBuilderValidators.required(
                                errorText: 'Veuillez entrer un mot de passe'),
                            FormBuilderValidators.minLength(6,
                                errorText:
                                    'Le mot de passe doit contenir au moins 6 caractères'),
                          ]),
                        ),
                        const SizedBox(height: 16),
                        FormBuilderTextField(
                          name: 'confirmPassword',
                          obscureText: _obscureConfirmPassword,
                          decoration: InputDecoration(
                            labelText: 'Confirmer le mot de passe',
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
                          validator: FormBuilderValidators.compose([
                            FormBuilderValidators.required(
                                errorText: 'Veuillez confirmer votre mot de passe'),
                            (value) {
                              if (value != _formKey.currentState?.fields['password']?.value) {
                                return 'Les mots de passe ne correspondent pas';
                              }
                              return null;
                            },
                          ]),
                        ),
                        const SizedBox(height: 24),
                        ElevatedButton(
                          onPressed: _isLoading ? null : _register,
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
                                  'S\'inscrire',
                                  style: GoogleFonts.raleway(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                        ),
                        const SizedBox(height: 24),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'Vous avez déjà un compte ?',
                              style: GoogleFonts.raleway(),
                            ),
                            TextButton(
                              onPressed: () => context.go('/login'),
                              child: Text(
                                'Se connecter',
                                style: GoogleFonts.raleway(
                                  fontWeight: FontWeight.bold,
                                  color: goldColor,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}