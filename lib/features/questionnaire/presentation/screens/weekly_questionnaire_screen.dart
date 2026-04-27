import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../core/theme/app_theme.dart';
import '../../data/services/questionnaire_service.dart';
import '../../domain/entities/weekly_survey.dart';
import 'package:intl/intl.dart';

class WeeklyQuestionnaireScreen extends StatefulWidget {
  final WeeklySurvey? initialSurvey;
  const WeeklyQuestionnaireScreen({super.key, this.initialSurvey});

  @override
  State<WeeklyQuestionnaireScreen> createState() => _WeeklyQuestionnaireScreenState();
}

class _WeeklyQuestionnaireScreenState extends State<WeeklyQuestionnaireScreen> {
  final _formKey = GlobalKey<FormState>();
  final _service = QuestionnaireService();

  // Champs du questionnaire
  String makeupFrequency = '';
  String makeupType = '';
  String makeupRemoval = '';
  String cleansingFrequency = '';
  String routineFollowed = '';
  String spfThisWeek = '';

  bool autoCorrection = false;
  bool reminderSent = false;
  bool spfAlert = false;

  bool loading = false;
  String? error;

  @override
  void initState() {
    super.initState();
    final s = widget.initialSurvey;
    if (s != null) {
      makeupFrequency = s.makeupFrequency;
      makeupType = s.makeupType;
      makeupRemoval = s.makeupRemoval;
      cleansingFrequency = s.cleansingFrequency;
      routineFollowed = s.routineFollowed;
      spfThisWeek = s.spfThisWeek;
      autoCorrection = s.autoCorrection;
      reminderSent = s.reminderSent;
      spfAlert = s.spfAlert;
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() { loading = true; error = null; });
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception('Utilisateur non connecté');
      final now = DateTime.now();
      final weekNumber = int.parse(_weekOfYear(now));
      final survey = WeeklySurvey(
        id: '${user.uid}_${weekNumber}_${now.year}',
        userId: user.uid,
        weekNumber: weekNumber,
        year: now.year,
        photos: {}, // À gérer selon ton flux photo
        makeupFrequency: makeupFrequency,
        makeupType: makeupType,
        makeupRemoval: makeupRemoval,
        cleansingFrequency: cleansingFrequency,
        routineFollowed: routineFollowed,
        spfThisWeek: spfThisWeek,
        autoCorrection: autoCorrection,
        reminderSent: reminderSent,
        spfAlert: spfAlert,
      );
      await _service.saveWeeklySurvey(survey);
      if (mounted) Navigator.pop(context, survey);
    } catch (e) {
      setState(() { error = e.toString(); });
    } finally {
      setState(() { loading = false; });
    }
  }

  int _weekOfYear(DateTime date) {
    final dayOfYear = int.parse(DateFormat("D").format(date));
    return ((dayOfYear - date.weekday + 10) / 7).floor();
    
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Questionnaire hebdomadaire')),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text('Maquillage', style: theme.textTheme.headlineMedium),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      value: makeupFrequency.isEmpty ? null : makeupFrequency,
                      decoration: const InputDecoration(labelText: 'Fréquence'),
                      items: [
                        'tous les jours','4-6j','2-3j','1j','jamais'
                      ].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                      onChanged: (v) => setState(() => makeupFrequency = v ?? ''),
                      validator: (v) => (v == null || v.isEmpty) ? 'Champ requis' : null,
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      value: makeupType.isEmpty ? null : makeupType,
                      decoration: const InputDecoration(labelText: 'Type'),
                      items: [
                        'complet','modéré','léger','naturel','aucun'
                      ].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                      onChanged: (v) => setState(() => makeupType = v ?? ''),
                      validator: (v) => (v == null || v.isEmpty) ? 'Champ requis' : null,
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      value: makeupRemoval.isEmpty ? null : makeupRemoval,
                      decoration: const InputDecoration(labelText: 'Démaquillage'),
                      items: [
                        'complet','simple','partiel','rarement'
                      ].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                      onChanged: (v) => setState(() => makeupRemoval = v ?? ''),
                      validator: (v) => (v == null || v.isEmpty) ? 'Champ requis' : null,
                    ),
                    const SizedBox(height: 24),
                    Text('Routine de soin', style: theme.textTheme.headlineMedium),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      value: cleansingFrequency.isEmpty ? null : cleansingFrequency,
                      decoration: const InputDecoration(labelText: 'Fréquence nettoyage visage'),
                      items: [
                        '2x/jour','1x/jour','rarement'
                      ].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                      onChanged: (v) => setState(() => cleansingFrequency = v ?? ''),
                      validator: (v) => (v == null || v.isEmpty) ? 'Champ requis' : null,
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      value: routineFollowed.isEmpty ? null : routineFollowed,
                      decoration: const InputDecoration(labelText: 'As-tu suivi la routine recommandée ?'),
                      items: [
                        'Oui','Partiellement','Non'
                      ].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                      onChanged: (v) => setState(() => routineFollowed = v ?? ''),
                      validator: (v) => (v == null || v.isEmpty) ? 'Champ requis' : null,
                    ),
                    const SizedBox(height: 24),
                    Text('Protection solaire', style: theme.textTheme.headlineMedium),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      value: spfThisWeek.isEmpty ? null : spfThisWeek,
                      decoration: const InputDecoration(labelText: 'Protection solaire cette semaine ?'),
                      items: [
                        'Tous les jours','Parfois','Jamais'
                      ].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                      onChanged: (v) => setState(() => spfThisWeek = v ?? ''),
                      validator: (v) => (v == null || v.isEmpty) ? 'Champ requis' : null,
                    ),
                    const SizedBox(height: 32),
                    if (error != null) ...[
                      Text(error!, style: const TextStyle(color: Colors.red)),
                      const SizedBox(height: 16),
                    ],
                    ElevatedButton(
                      onPressed: loading ? null : _save,
                      child: const Text('Enregistrer'),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
