import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:form_builder_validators/form_builder_validators.dart';
import 'package:sae_mobile/viewmodels/register_viewmodel.dart';
import '../providers/supabase_provider.dart';

class RegisterView extends StatefulWidget {
  final SupabaseProvider supabaseProvider;

  const RegisterView({
    Key? key,
    required this.supabaseProvider,
  }) : super(key: key);

  @override
  _RegisterViewState createState() => _RegisterViewState();
}

class _RegisterViewState extends State<RegisterView> {
  late RegisterViewModel viewModel;
  final _formKey = GlobalKey<FormBuilderState>();

  @override
  void initState() {
    super.initState();
    viewModel = RegisterViewModel(
      supabaseProvider: widget.supabaseProvider,
      onStateChanged: () => setState(() {}), // Callback to rebuild UI
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
                        Icon(Icons.app_registration_rounded, size: 70, color: goldColor),
                        const SizedBox(height: 24),
                        Text(
                          'Créer un compte',
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
                        Row(
                          children: [
                            Expanded(
                              child: FormBuilderTextField(
                                name: 'nom',
                                decoration: _inputDecoration('Nom', Icons.person, goldColor),
                                validator: _nameValidator(),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: FormBuilderTextField(
                                name: 'prenom',
                                decoration: _inputDecoration('Prénom', Icons.person_outline, goldColor),
                                validator: _nameValidator(),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        InkWell(
                          onTap: () => viewModel.selectDate(context),
                          child: InputDecorator(
                            decoration: _inputDecoration('Date de naissance', Icons.calendar_today, goldColor).copyWith(
                              errorText: viewModel.selectedDate == null
                                  ? null
                                  : viewModel.selectedDate!.isAfter(DateTime.now().subtract(const Duration(days: 13 * 365)))
                                      ? 'Vous devez avoir au moins 13 ans'
                                      : null,
                            ),
                            child: Text(
                              viewModel.selectedDate == null
                                  ? 'Sélectionner une date'
                                  : DateFormat('dd/MM/yyyy').format(viewModel.selectedDate!),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        FormBuilderDropdown<String>(
                          name: 'sexe',
                          decoration: _inputDecoration('Sexe', Icons.people, goldColor),
                          items: viewModel.sexeOptions
                              .map((value) => DropdownMenuItem(value: value, child: Text(value)))
                              .toList(),
                          onChanged: (newValue) => viewModel.setSexe(newValue),
                          validator: FormBuilderValidators.required(errorText: 'Veuillez sélectionner votre sexe'),
                        ),
                        const SizedBox(height: 16),
                        FormBuilderTextField(
                          name: 'telephone',
                          keyboardType: TextInputType.phone,
                          decoration: _inputDecoration('Téléphone', Icons.phone, goldColor, hintText: 'ex: 0612345678'),
                          validator: FormBuilderValidators.compose([
                            FormBuilderValidators.required(errorText: 'Veuillez entrer votre numéro de téléphone'),
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
                          validator: viewModel.passwordValidator,
                        ),
                        const SizedBox(height: 16),
                        FormBuilderTextField(
                          name: 'confirmPassword',
                          obscureText: viewModel.obscureConfirmPassword,
                          decoration: _inputDecoration('Confirmer le mot de passe', Icons.lock_outline, goldColor).copyWith(
                            suffixIcon: IconButton(
                              icon: Icon(
                                viewModel.obscureConfirmPassword ? Icons.visibility : Icons.visibility_off,
                                color: goldColor,
                              ),
                              onPressed: viewModel.toggleConfirmPasswordVisibility,
                            ),
                          ),
                          validator: FormBuilderValidators.compose([
                            FormBuilderValidators.required(errorText: 'Veuillez confirmer votre mot de passe'),
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
                          onPressed: viewModel.isLoading ? null : () => viewModel.register(context, _formKey),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: goldColor,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          child: viewModel.isLoading
                              ? CircularProgressIndicator(color: Colors.white)
                              : Text(
                                  'S\'inscrire',
                                  style: GoogleFonts.raleway(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                                ),
                        ),
                        const SizedBox(height: 24),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text('Vous avez déjà un compte ?', style: GoogleFonts.raleway()),
                            TextButton(
                              onPressed: () => context.push('/login'),
                              child: Text(
                                'Se connecter',
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

  FormFieldValidator<String> _nameValidator() {
    return FormBuilderValidators.compose([
      FormBuilderValidators.required(errorText: 'Veuillez entrer votre nom/prénom'),
      FormBuilderValidators.match(
        RegExp(r'^[a-zA-ZÀ-ÿ\s-]+$'),
        errorText: 'Ce champ ne doit contenir que des lettres',
      ),
    ]);
  }
}