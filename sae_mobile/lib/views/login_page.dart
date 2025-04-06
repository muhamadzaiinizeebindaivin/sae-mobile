import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:form_builder_validators/form_builder_validators.dart';
import '../viewmodels/login_viewmodel.dart';
import '../providers/supabase_provider.dart';

class LoginView extends StatefulWidget {
  final SupabaseProvider supabaseProvider;

  const LoginView({
    Key? key,
    required this.supabaseProvider,
  }) : super(key: key);

  @override
  _LoginViewState createState() => _LoginViewState();
}

class _LoginViewState extends State<LoginView> {
  late LoginViewModel viewModel;
  final _formKey = GlobalKey<FormBuilderState>();

  @override
  void initState() {
    super.initState();
    viewModel = LoginViewModel(
      supabaseProvider: widget.supabaseProvider,
      onStateChanged: () => setState(() {}),
    );
  }

  @override
  Widget build(BuildContext context) {
    final goldColor = Theme.of(context).primaryColor;

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Text(
          'IUTables\'O',
          style: GoogleFonts.raleway(fontWeight: FontWeight.bold, color: Colors.white),
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
                icon: Icon(Icons.arrow_back, color: goldColor, size: 28),
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
                        Icon(Icons.login_rounded, size: 70, color: goldColor),
                        const SizedBox(height: 24),
                        Text(
                          'Connexion',
                          style: GoogleFonts.raleway(fontSize: 28, fontWeight: FontWeight.bold, color: goldColor),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        if (viewModel.errorMessage != null)
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.red.shade50,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.red.shade200),
                            ),
                            child: Center(
                              child: Text(
                                viewModel.errorMessage!,
                                style: TextStyle(color: Colors.red.shade800),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ),
                        const SizedBox(height: 24),
                        FormBuilderTextField(
                          name: 'email',
                          keyboardType: TextInputType.emailAddress,
                          decoration: _inputDecoration('Email', Icons.email, goldColor, hintText: 'exemple@email.com'),
                          validator: FormBuilderValidators.compose([
                            FormBuilderValidators.required(errorText: 'Veuillez entrer votre email'),
                            FormBuilderValidators.email(errorText: 'Veuillez entrer un email valide'),
                          ]),
                        ),
                        const SizedBox(height: 16),
                        FormBuilderTextField(
                          name: 'password',
                          obscureText: viewModel.obscurePassword,
                          decoration: _inputDecoration('Mot de passe', Icons.lock, goldColor).copyWith(
                            suffixIcon: IconButton(
                              icon: Icon(
                                viewModel.obscurePassword ? Icons.visibility : Icons.visibility_off,
                                color: goldColor,
                              ),
                              onPressed: viewModel.togglePasswordVisibility,
                            ),
                          ),
                          validator: FormBuilderValidators.compose([
                            FormBuilderValidators.required(errorText: 'Veuillez entrer votre mot de passe'),
                            FormBuilderValidators.minLength(6, errorText: 'Le mot de passe doit contenir au moins 6 caractères'),
                          ]),
                        ),
                        const SizedBox(height: 24),
                        ElevatedButton(
                          onPressed: viewModel.isLoading ? null : () => viewModel.signIn(context, _formKey),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: goldColor,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          child: viewModel.isLoading
                              ? CircularProgressIndicator(color: Colors.white)
                              : Text(
                                  'Se connecter',
                                  style: GoogleFonts.raleway(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                                ),
                        ),
                        const SizedBox(height: 24),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text('Vous n\'avez pas de compte ?', style: GoogleFonts.raleway()),
                            TextButton(
                              onPressed: () => context.push('/register'),
                              child: Text(
                                'S\'inscrire',
                                style: GoogleFonts.raleway(fontWeight: FontWeight.bold, color: goldColor),
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

  InputDecoration _inputDecoration(String label, IconData icon, Color goldColor, {String? hintText}) {
    return InputDecoration(
      labelText: label,
      hintText: hintText,
      prefixIcon: Icon(icon, color: goldColor),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: goldColor, width: 2),
      ),
    );
  }
}