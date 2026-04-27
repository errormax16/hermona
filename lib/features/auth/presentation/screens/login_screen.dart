import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax/iconsax.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/common_widgets.dart';
import '../../data/services/auth_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey   = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passCtrl  = TextEditingController();
  final _auth      = AuthService();
  bool _obscure = true, _loading = false, _googleLoading = false;

  @override
  void dispose() { _emailCtrl.dispose(); _passCtrl.dispose(); super.dispose(); }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      await _auth.login(email: _emailCtrl.text.trim(), password: _passCtrl.text);
      if (mounted) context.go('/home');
    } catch (e) {
      _snack(e.toString().replaceAll('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _google() async {
    setState(() => _googleLoading = true);
    try {
      await _auth.signInWithGoogle();
      if (mounted) context.go('/home');
    } catch (e) {
      _snack('Connexion Google échouée');
    } finally {
      if (mounted) setState(() => _googleLoading = false);
    }
  }

  void _snack(String msg) => ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(msg), backgroundColor: AppColors.error,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ),
  );

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return Scaffold(
      body: Stack(children: [
        Positioned(top: -60, right: -60, child: _circle(220, AppTheme.primary.withOpacity(0.12))),
        Positioned(bottom: -40, left: -40, child: _circle(180, AppColors.secondary.withOpacity(0.10))),
        SafeArea(child: SingleChildScrollView(
          padding: const EdgeInsets.all(28),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            SizedBox(height: size.height * 0.05),

            // Logo
            Center(child: Column(children: [
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(color: AppTheme.primary.withOpacity(0.1), shape: BoxShape.circle),
                child: Icon(Iconsax.heart, size: 42, color: AppTheme.primary),
              ).animate().scale(duration: 600.ms, curve: Curves.elasticOut),
              const SizedBox(height: 14),
              Text('AcnéIA', style: Theme.of(context).textTheme.displayMedium)
                  .animate().fadeIn(delay: 100.ms),
              const SizedBox(height: 4),
              Text('Votre expert beauté intelligent', style: Theme.of(context).textTheme.bodySmall)
                  .animate().fadeIn(delay: 200.ms),
            ])),

            SizedBox(height: size.height * 0.05),

            Text('Connexion', style: Theme.of(context).textTheme.headlineLarge)
                .animate().fadeIn(delay: 300.ms).slideX(begin: -0.05),
            const SizedBox(height: 4),
            Text('Bienvenue ! Entrez vos identifiants.', style: Theme.of(context).textTheme.bodySmall)
                .animate().fadeIn(delay: 380.ms),
            const SizedBox(height: 28),

            Form(key: _formKey, child: Column(children: [
              TextFormField(
                controller: _emailCtrl,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(hintText: 'Email', prefixIcon: Icon(Iconsax.sms)),
                validator: (v) => (v == null || !v.contains('@')) ? 'Email invalide' : null,
              ).animate().fadeIn(delay: 420.ms).slideY(begin: 0.08),
              const SizedBox(height: 14),

              TextFormField(
                controller: _passCtrl,
                obscureText: _obscure,
                decoration: InputDecoration(
                  hintText: 'Mot de passe',
                  prefixIcon: const Icon(Iconsax.lock),
                  suffixIcon: IconButton(
                    icon: Icon(_obscure ? Iconsax.eye_slash : Iconsax.eye),
                    onPressed: () => setState(() => _obscure = !_obscure),
                  ),
                ),
                validator: (v) => (v == null || v.length < 6) ? 'Min. 6 caractères' : null,
              ).animate().fadeIn(delay: 480.ms).slideY(begin: 0.08),

              const SizedBox(height: 8),
              Align(alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () => _showForgotPassword(),
                  child: Text('Mot de passe oublié ?',
                    style: TextStyle(color: AppTheme.primary, fontSize: 13)),
                ),
              ),
              const SizedBox(height: 20),

              GradientButton(text: 'Se connecter', onPressed: _login, isLoading: _loading)
                  .animate().fadeIn(delay: 540.ms),
              const SizedBox(height: 18),

              Row(children: [
                Expanded(child: Divider(color: Theme.of(context).dividerTheme.color)),
                Padding(padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Text('ou', style: Theme.of(context).textTheme.bodySmall)),
                Expanded(child: Divider(color: Theme.of(context).dividerTheme.color)),
              ]).animate().fadeIn(delay: 580.ms),
              const SizedBox(height: 18),

              SizedBox(
                width: double.infinity, height: 56,
                child: OutlinedButton.icon(
                  onPressed: _googleLoading ? null : _google,
                  icon: _googleLoading
                      ? const SizedBox(width: 20, height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2))
                      : const Icon(Icons.g_mobiledata, size: 26),
                  label: const Text('Continuer avec Google'),
                ),
              ).animate().fadeIn(delay: 620.ms),
              const SizedBox(height: 28),

              Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                Text("Pas encore de compte ? ", style: Theme.of(context).textTheme.bodySmall),
                GestureDetector(
                  onTap: () => context.go('/register'),
                  child: Text('Créer un compte',
                    style: TextStyle(color: AppTheme.primary, fontWeight: FontWeight.w600, fontSize: 13)),
                ),
              ]).animate().fadeIn(delay: 660.ms),
            ])),
          ]),
        )),
      ]),
    );
  }

  Widget _circle(double size, Color color) =>
      Container(width: size, height: size,
          decoration: BoxDecoration(shape: BoxShape.circle, color: color));

  void _showForgotPassword() {
    final ctrl = TextEditingController();
    showDialog(context: context, builder: (ctx) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: const Text('Réinitialiser le mot de passe'),
      content: TextFormField(controller: ctrl,
        decoration: const InputDecoration(hintText: 'Votre email'),
        keyboardType: TextInputType.emailAddress),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Annuler')),
        ElevatedButton(
          onPressed: () async {
            if (ctrl.text.isNotEmpty) {
              await _auth.resetPassword(ctrl.text.trim());
              Navigator.pop(ctx);
              _snack('Email envoyé !');
            }
          },
          child: const Text('Envoyer'),
        ),
      ],
    ));
  }
}
