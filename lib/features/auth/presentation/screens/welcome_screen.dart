import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/common_widgets.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppTheme.primary.withOpacity(0.1),
              Theme.of(context).scaffoldBackgroundColor,
            ],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32.0, vertical: 24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Spacer(),
                
                // Icon / Logo
                Container(
                  padding: const EdgeInsets.all(28),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.primary.withOpacity(0.2),
                        blurRadius: 30,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: const Text('🌸', style: TextStyle(fontSize: 64)),
                ).animate().scale(duration: 800.ms, curve: Curves.elasticOut),
                
                const SizedBox(height: 48),
                
                Text(
                  'Bienvenue sur\nAcnéIA',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.displayLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    height: 1.2,
                  ),
                ).animate().fadeIn(delay: 600.ms).slideY(begin: 0.2, duration: 800.ms, curve: Curves.easeOut),
                
                const SizedBox(height: 24),
                
                // Description
                Text(
                  'AcnéIA vous accompagne dans votre parcours beauté. Analysez votre peau et recevez des recommandations personnalisées !',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    height: 1.5,
                    color: Colors.grey[600],
                  ),
                ).animate().fadeIn(delay: 1500.ms, duration: 800.ms),
                
                const Spacer(),
                
                // Actions
                Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    GradientButton(
                      text: 'Se connecter',
                      onPressed: () => context.push('/login'),
                    ),
                    const SizedBox(height: 16),
                    OutlinedButton(
                      onPressed: () => context.push('/register'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        side: BorderSide(color: AppTheme.primary, width: 2),
                      ),
                      child: Text(
                        'Créer un compte',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.primary,
                        ),
                      ),
                    ),
                  ],
                ).animate().fadeIn(delay: 3000.ms, duration: 800.ms).slideY(begin: 0.2, duration: 800.ms, curve: Curves.easeOut),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
