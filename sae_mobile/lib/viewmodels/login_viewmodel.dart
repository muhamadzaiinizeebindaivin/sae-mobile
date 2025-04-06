import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import '../providers/supabase_provider.dart';

class LoginViewModel {
  final SupabaseProvider supabaseProvider;
  final VoidCallback onStateChanged;

  bool isLoading = false;
  bool obscurePassword = true;
  String? errorMessage;

  LoginViewModel({
    required this.supabaseProvider,
    required this.onStateChanged,
  });

  void togglePasswordVisibility() {
    obscurePassword = !obscurePassword;
    onStateChanged();
  }

  Future<void> signIn(BuildContext context, GlobalKey<FormBuilderState> formKey) async {
    if (!formKey.currentState!.saveAndValidate()) return;

    isLoading = true;
    errorMessage = null;
    onStateChanged();

    try {
      final formValue = formKey.currentState!.value;
      final response = await Supabase.instance.client.auth.signInWithPassword(
        email: formValue['email'].trim(),
        password: formValue['password'],
      );

      if (response.user != null) {
        context.push('/home-authentified');
      }
    } on AuthException catch (e) {
      switch (e.message) {
        case 'Invalid login credentials':
          errorMessage = 'Email ou mot de passe incorrect !';
          break;
        case 'Email not confirmed':
          errorMessage = 'Veuillez confirmer votre email avant de vous connecter !';
          break;
        default:
          errorMessage = 'Erreur de connexion : ${e.message}';
      }
      isLoading = false;
      onStateChanged();
    } catch (e) {
      errorMessage = 'Une erreur inattendue est survenue';
      isLoading = false;
      onStateChanged();
    }
  }
}