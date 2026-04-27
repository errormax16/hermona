import 'package:flutter/material.dart';
import '../../domain/entities/user_profile.dart';

class ProfileQuestionnaireScreen extends StatelessWidget {
  final UserProfile? initialProfile;
  final void Function(UserProfile) onSave;
  const ProfileQuestionnaireScreen({super.key, this.initialProfile, required this.onSave});

  @override
  Widget build(BuildContext context) {
    // TODO: Remplacer par un vrai formulaire adapté à tes couleurs et à la structure UserProfile
    return Scaffold(
      appBar: AppBar(title: const Text('Profil — Onboarding')),
      body: Center(
        child: Text('Formulaire de création/modification du profil à implémenter'),
      ),
    );
  }
}
