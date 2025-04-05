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

  const RegisterPage({
    Key? key, 
    required this.supabaseProvider
  }) : super(key: key);

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

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final formValue = _formKey.currentState!.value;
      final email = formValue['email'].trim();
      final password = formValue['password'];

      final emailCheck = await Supabase.instance.client
          .from('utilisateur')
          .select('emailutilisateur')
          .eq('emailutilisateur', email)
          .maybeSingle();

      if (emailCheck != null) {
        throw Exception('Cet email est déjà utilisé !');
      }

      if (_selectedDate == null) {
        throw Exception('Veuillez sélectionner une date de naissance !');
      }

      if (_selectedSexe == null) {
        throw Exception('Veuillez sélectionner un sexe !');
      }

      final authResponse = await Supabase.instance.client.auth.signUp(
        email: email,
        password: password,
        data: {
          'nomutilisateur': formValue['nom'].trim(),
          'prenomutilisateur': formValue['prenom'].trim(),
          'sexeutilisateur': _selectedSexe,
          'ddnutilisateur': _selectedDate!.toIso8601String().split('T')[0],
          'telephoneutilisateur': formValue['telephone'].trim(),
        },
      );

      if (authResponse.user != null) {
        final userData = {
          'nomutilisateur': formValue['nom'].trim(),
          'prenomutilisateur': formValue['prenom'].trim(),
          'sexeutilisateur': _selectedSexe,
          'ddnutilisateur': _selectedDate!.toIso8601String().split('T')[0],
          'telephoneutilisateur': formValue['telephone'].trim(),
          'emailutilisateur': email,
          'mdputilisateur': password,
        };

        await Supabase.instance.client.from('utilisateur').insert(userData);

        if (mounted) {
          context.push('/login');
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Center(
                child: Text(
                  'Compte créé avec succès ! Veuillez vous connecter !',
                  style: TextStyle(fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
              ),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    } on AuthException catch (e) {
      setState(() {
        switch (e.message) {
          case 'Weak password':
            _errorMessage = 'Le mot de passe est trop faible !';
            break;
          case 'User already registered':
            _errorMessage = 'Cet email est déjà enregistré !';
            break;
          default:
            _errorMessage = 'Erreur d\'inscription : ${e.message}';
        }
      });
    } on PostgrestException catch (e) {
      setState(() {
        _errorMessage = 'Erreur de base de données : ${e.message}';
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString().contains('existe déjà')
            ? 'Cet email est déjà utilisé !'
            : 'Une erreur est survenue lors de l\'inscription !';
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
                onPressed: () => context.pop(),
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
                            child: Center(
                              child: Text(
                                _errorMessage!,
                                style: TextStyle(color: Colors.red.shade800),
                                textAlign: TextAlign.center,
                              ),
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
                              errorText: _selectedDate == null
                                  ? null
                                  : _selectedDate!.isAfter(DateTime.now().subtract(const Duration(days: 13 * 365)))
                                      ? 'Vous devez avoir au moins 13 ans'
                                      : null,
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
                            hintText: 'ex: 0612345678',
                          ),
                          validator: FormBuilderValidators.compose([
                            FormBuilderValidators.required(
                                errorText: 'Veuillez entrer votre numéro de téléphone'),
                            FormBuilderValidators.match(
                              RegExp(r'^(0|\+33)[1-9]\d{8}$'),
                              errorText: 'Numéro invalide (ex: 0612345678 ou +33612345678)',
                            ),
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
                                errorText: 'Veuillez entrer un email valide')
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
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Veuillez entrer un mot de passe';
                            }

                            List<String> errors = [];

                            if (value.length < 8) {
                              errors.add('Minimum 8 caractères');
                            }
                            if (!RegExp(r'[A-Z]').hasMatch(value)) {
                              errors.add('Au moins une majuscule');
                            }
                            if (!RegExp(r'[a-z]').hasMatch(value)) {
                              errors.add('Au moins une minuscule');
                            }
                            if (!RegExp(r'\d').hasMatch(value)) {
                              errors.add('Au moins un chiffre');
                            }
                            if (!RegExp(r'[!@#$%^&*]').hasMatch(value)) {
                              errors.add('Au moins un caractère spécial (!@#\$%^&*)');
                            }
                            if (errors.isNotEmpty) {
                              return errors.join('\n');
                            }
                            return null;
                          },
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
                              if (value !=
                                  _formKey.currentState?.fields['password']?.value) {
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
                              onPressed: () => context.push('/login'),
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