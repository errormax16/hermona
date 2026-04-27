import 'package:flutter/material.dart';
import '../../domain/entities/daily_survey.dart';

class DailyQuestionnaireScreen extends StatelessWidget {
  final DailySurvey? initialSurvey;
  final void Function(DailySurvey) onSave;
  const DailyQuestionnaireScreen({super.key, this.initialSurvey, required this.onSave});

  @override
  Widget build(BuildContext context) {
    // TODO: Remplacer par un vrai formulaire adapté à tes couleurs et à la structure DailySurvey
    return Scaffold(
      appBar: AppBar(title: const Text('Questionnaire quotidien')),
      body: Center(
        child: Text('Formulaire quotidien à implémenter'),
      ),
    );
  }
}
