import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax/iconsax.dart';
import '../../../../core/theme/app_theme.dart';

class TermsScreen extends StatelessWidget {
  const TermsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Conditions d\'utilisation'),
        leading: IconButton(icon: const Icon(Icons.close), onPressed: () => context.pop()),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(16)),
            child: Row(children: [
              Icon(Iconsax.shield_tick, color: AppTheme.primary, size: 28),
              const SizedBox(width: 12),
              Expanded(child: Text('AcnéIA – Conditions Générales',
                style: Theme.of(context).textTheme.headlineMedium)),
            ]),
          ),
          const SizedBox(height: 24),
          _s(context, '1. Objet', 'AcnéIA est une application d\'aide à la détection d\'acné et de recommandation de soins. Elle ne remplace en aucun cas un avis médical professionnel.'),
          _s(context, '2. Données personnelles', 'Vos images sont collectées uniquement pour l\'analyse IA, stockées de manière sécurisée et ne sont jamais partagées avec des tiers sans votre consentement.'),
          _s(context, '3. Intelligence Artificielle', 'Les résultats fournis par l\'IA sont indicatifs. Pour tout problème dermatologique sérieux, consultez un médecin ou dermatologue.'),
          _s(context, '4. Forum anonyme', 'Le forum est anonyme. Vous êtes responsable des contenus publiés. Tout contenu inapproprié peut être signalé et supprimé.'),
          _s(context, '5. Messagerie privée', 'La messagerie est anonyme. Ne partagez jamais vos informations personnelles (nom, adresse, téléphone).'),
          _s(context, '6. Signalements', 'Tout contenu signalé 3 fois est automatiquement masqué en attente de modération.'),
          _s(context, '7. Modifications', 'Nous nous réservons le droit de modifier ces conditions à tout moment avec notification préalable.'),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.info.withOpacity(0.1),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.info.withOpacity(0.3))),
            child: Text(
              '⚕️ AcnéIA ne fournit pas de diagnostics médicaux. Consultez toujours un professionnel de santé pour des problèmes dermatologiques.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.info)),
          ),
          const SizedBox(height: 40),
        ]),
      ),
    );
  }

  Widget _s(BuildContext ctx, String title, String content) => Padding(
    padding: const EdgeInsets.only(bottom: 18),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(title, style: Theme.of(ctx).textTheme.headlineMedium),
      const SizedBox(height: 6),
      Text(content, style: Theme.of(ctx).textTheme.bodyMedium?.copyWith(height: 1.6)),
    ]),
  );
}
