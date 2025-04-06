import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import '../providers/supabase_provider.dart';

class RegisterViewModel {
  final SupabaseProvider supabaseProvider;
  final VoidCallback onStateChanged;

  DateTime? selectedDate;
  String? selectedSexe;
  bool isLoading = false;
  bool obscurePassword = true;
  bool obscureConfirmPassword = true;
  String? errorMessage;

  final List<String> sexeOptions = ['Homme', 'Femme'];

  RegisterViewModel({
    required this.supabaseProvider,
    required this.onStateChanged,
  });

  Future<void> selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: selectedDate ?? DateTime(2000),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
      locale: const Locale('fr', 'FR'),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(primary: Theme.of(context).primaryColor),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != selectedDate) {
      selectedDate = picked;
      onStateChanged();
    }
  }

  void setSexe(String? newValue) {
    selectedSexe = newValue;
    onStateChanged();
  }

  void togglePasswordVisibility() {
    obscurePassword = !obscurePassword;
    onStateChanged();
  }

  void toggleConfirmPasswordVisibility() {
    obscureConfirmPassword = !obscureConfirmPassword;
    onStateChanged();
  }

  FormFieldValidator<String> passwordValidator = (value) {
    if (value == null || value.isEmpty) {
      return 'Veuillez entrer un mot de passe';
    }
    List<String> errors = [];
    if (value.length < 8) errors.add('Minimum 8 caractères');
    if (!RegExp(r'[A-Z]').hasMatch(value)) errors.add('Au moins une majuscule');
    if (!RegExp(r'[a-z]').hasMatch(value)) errors.add('Au moins une minuscule');
    if (!RegExp(r'\d').hasMatch(value)) errors.add('Au moins un chiffre');
    if (!RegExp(r'[!@#$%^&*]').hasMatch(value)) errors.add('Au moins un caractère spécial (!@#\$%^&*)');
    return errors.isEmpty ? null : errors.join('\n');
  };

  Future<void> register(BuildContext context, GlobalKey<FormBuilderState> formKey) async {
    if (!formKey.currentState!.saveAndValidate()) return;

    isLoading = true;
    errorMessage = null;
    onStateChanged();

    try {
      final formValue = formKey.currentState!.value;
      final email = formValue['email'].trim();
      final password = formValue['password'];

      final emailCheck = await Supabase.instance.client
          .from('utilisateur')
          .select('emailutilisateur')
          .eq('emailutilisateur', email)
          .maybeSingle();

      if (emailCheck != null) {
        errorMessage = 'Ce compte existe déjà ! Veuillez utiliser un autre email !';
        isLoading = false;
        onStateChanged();
        return;
      }

      if (selectedDate == null) {
        throw Exception('Veuillez sélectionner une date de naissance !');
      }

      if (selectedSexe == null) {
        throw Exception('Veuillez sélectionner un sexe !');
      }

      final authResponse = await Supabase.instance.client.auth.signUp(
        email: email,
        password: password,
        data: {
          'nomutilisateur': formValue['nom'].trim(),
          'prenomutilisateur': formValue['prenom'].trim(),
          'sexeutilisateur': selectedSexe,
          'ddnutilisateur': selectedDate!.toIso8601String().split('T')[0],
          'telephoneutilisateur': formValue['telephone'].trim(),
        },
      );

      if (authResponse.user != null) {
        final userData = {
          'nomutilisateur': formValue['nom'].trim(),
          'prenomutilisateur': formValue['prenom'].trim(),
          'sexeutilisateur': selectedSexe,
          'ddnutilisateur': selectedDate!.toIso8601String().split('T')[0],
          'telephoneutilisateur': formValue['telephone'].trim(),
          'emailutilisateur': email,
          'mdputilisateur': password,
        };

        await Supabase.instance.client.from('utilisateur').insert(userData);

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
    } on AuthException catch (e) {
      switch (e.message) {
        case 'Weak password':
          errorMessage = 'Le mot de passe est trop faible !';
          break;
        case 'User already registered':
          errorMessage = 'Ce compte existe déjà ! Veuillez utiliser un autre email ou vous connecter.';
          break;
        default:
          errorMessage = 'Erreur d\'inscription : ${e.message}';
      }
      isLoading = false;
      onStateChanged();
    } on PostgrestException catch (e) {
      errorMessage = e.message.contains('duplicate key')
          ? 'Ce compte existe déjà ! Veuillez utiliser un autre email ou vous connecter.'
          : 'Erreur de base de données : ${e.message}';
      isLoading = false;
      onStateChanged();
    } catch (e) {
      errorMessage = e.toString().contains('existe déjà') || e.toString().contains('duplicate')
          ? 'Ce compte existe déjà ! Veuillez utiliser un autre email ou vous connecter.'
          : 'Une erreur est survenue lors de l\'inscription !';
      isLoading = false;
      onStateChanged();
    }
  }
}