import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax/iconsax.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/common_widgets.dart';
import '../../data/services/auth_service.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});
  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey      = GlobalKey<FormState>();
  final _firstCtrl    = TextEditingController();
  final _lastCtrl     = TextEditingController();
  final _emailCtrl    = TextEditingController();
  final _passCtrl     = TextEditingController();
  final _confirmCtrl  = TextEditingController();
  final _auth         = AuthService();
  bool _obscure = true, _obscureC = true, _terms = false, _loading = false;

  @override
  void dispose() {
    _firstCtrl.dispose(); _lastCtrl.dispose();
    _emailCtrl.dispose(); _passCtrl.dispose(); _confirmCtrl.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;
    if (!_terms) { _snack('Veuillez accepter les conditions d\'utilisation'); return; }
    setState(() => _loading = true);
    try {
      await _auth.register(
        email: _emailCtrl.text.trim(), password: _passCtrl.text,
        firstName: _firstCtrl.text.trim(), lastName: _lastCtrl.text.trim(),
      );
      if (mounted) context.go('/home');
    } catch (e) {
      _snack(e.toString().replaceAll('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _snack(String m) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(
    content: Text(m), backgroundColor: AppColors.error, behavior: SnackBarBehavior.floating,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
  ));

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(children: [
        Positioned(top: -80, left: -80,
            child: Container(width: 240, height: 240,
                decoration: BoxDecoration(shape: BoxShape.circle,
                    color: AppColors.secondary.withOpacity(0.10)))),
        SafeArea(child: SingleChildScrollView(
          padding: const EdgeInsets.all(28),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            GestureDetector(
              onTap: () => context.go('/login'),
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppTheme.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12)),
                child: Icon(Icons.arrow_back_ios_new, size: 18, color: AppTheme.primary),
              ),
            ),
            const SizedBox(height: 24),
            Text('Créer un compte', style: Theme.of(context).textTheme.displaySmall)
                .animate().fadeIn(delay: 100.ms).slideX(begin: -0.05),
            const SizedBox(height: 4),
            Text('Rejoignez notre communauté beauté 🌸', style: Theme.of(context).textTheme.bodySmall)
                .animate().fadeIn(delay: 180.ms),
            const SizedBox(height: 28),

            Form(key: _formKey, child: Column(children: [
              // Prénom + Nom
              Row(children: [
                Expanded(child: TextFormField(
                  controller: _firstCtrl,
                  decoration: const InputDecoration(hintText: 'Prénom', prefixIcon: Icon(Iconsax.user)),
                  validator: (v) => (v == null || v.isEmpty) ? 'Requis' : null,
                )),
                const SizedBox(width: 12),
                Expanded(child: TextFormField(
                  controller: _lastCtrl,
                  decoration: const InputDecoration(hintText: 'Nom', prefixIcon: Icon(Iconsax.user)),
                  validator: (v) => (v == null || v.isEmpty) ? 'Requis' : null,
                )),
              ]).animate().fadeIn(delay: 240.ms).slideY(begin: 0.08),
              const SizedBox(height: 14),

              TextFormField(
                controller: _emailCtrl,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(hintText: 'Email', prefixIcon: Icon(Iconsax.sms)),
                validator: (v) => (v == null || !v.contains('@')) ? 'Email invalide' : null,
              ).animate().fadeIn(delay: 300.ms).slideY(begin: 0.08),
              const SizedBox(height: 14),

              TextFormField(
                controller: _passCtrl,
                obscureText: _obscure,
                decoration: InputDecoration(
                  hintText: 'Mot de passe', prefixIcon: const Icon(Iconsax.lock),
                  suffixIcon: IconButton(
                    icon: Icon(_obscure ? Iconsax.eye_slash : Iconsax.eye),
                    onPressed: () => setState(() => _obscure = !_obscure)),
                ),
                validator: (v) => (v == null || v.length < 6) ? 'Min. 6 caractères' : null,
              ).animate().fadeIn(delay: 360.ms).slideY(begin: 0.08),
              const SizedBox(height: 14),

              TextFormField(
                controller: _confirmCtrl,
                obscureText: _obscureC,
                decoration: InputDecoration(
                  hintText: 'Confirmer le mot de passe', prefixIcon: const Icon(Iconsax.lock_1),
                  suffixIcon: IconButton(
                    icon: Icon(_obscureC ? Iconsax.eye_slash : Iconsax.eye),
                    onPressed: () => setState(() => _obscureC = !_obscureC)),
                ),
                validator: (v) => v != _passCtrl.text ? 'Les mots de passe ne correspondent pas' : null,
              ).animate().fadeIn(delay: 420.ms).slideY(begin: 0.08),
              const SizedBox(height: 16),

              // Terms checkbox
              Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Checkbox(
                  value: _terms, activeColor: AppTheme.primary,
                  onChanged: (v) => setState(() => _terms = v ?? false),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                ),
                Expanded(child: Padding(
                  padding: const EdgeInsets.only(top: 10),
                  child: RichText(text: TextSpan(
                    style: Theme.of(context).textTheme.bodySmall,
                    children: [
                      const TextSpan(text: 'J\'accepte les '),
                      TextSpan(
                        text: 'conditions d\'utilisation',
                        style: TextStyle(color: AppTheme.primary, fontWeight: FontWeight.w600),
                        recognizer: TapGestureRecognizer()..onTap = () => context.push('/terms'),
                      ),
                    ],
                  )),
                )),
              ]).animate().fadeIn(delay: 460.ms),
              const SizedBox(height: 24),

              GradientButton(text: 'S\'inscrire', onPressed: _register, isLoading: _loading)
                  .animate().fadeIn(delay: 500.ms),
              const SizedBox(height: 20),

              Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                Text('Déjà un compte ? ', style: Theme.of(context).textTheme.bodySmall),
                GestureDetector(
                  onTap: () => context.go('/login'),
                  child: Text('Se connecter',
                    style: TextStyle(color: AppTheme.primary, fontWeight: FontWeight.w600, fontSize: 13)),
                ),
              ]).animate().fadeIn(delay: 540.ms),
            ])),
          ]),
        )),
      ]),
    );
  }
}
