import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:go_router/go_router.dart';
import '../../data/services/questionnaire_service.dart';
import '../../domain/entities/daily_survey.dart';

class DailyQuestionnaireScreen extends StatefulWidget {
  final DailySurvey? initialSurvey;
  const DailyQuestionnaireScreen({super.key, this.initialSurvey});

  @override
  State<DailyQuestionnaireScreen> createState() => _DailyQuestionnaireScreenState();
}

class _DailyQuestionnaireScreenState extends State<DailyQuestionnaireScreen> {
  final _service = QuestionnaireService();
  bool loading = false;
  String? error;

  // Form
  double stress = 5;
  double sleepDuration = 7;
  double sleepQuality = 5;
  int hydration = 4;
  List<String> food = [];
  List<String> symptoms = [];
  bool spfUsed = false;

  final List<String> foodOptions = ['sucre', 'laitages', 'fast-food', 'fruits', 'équilibrée'];
  final List<String> symptomsOptions = ['crampes', 'ballonnements', 'sautes d\'humeur', 'fatigue', 'seins sensibles', 'maux de tête'];

  @override
  void initState() {
    super.initState();
    if (widget.initialSurvey != null) {
      final s = widget.initialSurvey!;
      stress = s.stress.toDouble();
      sleepDuration = s.sleepDuration;
      sleepQuality = s.sleepQuality.toDouble();
      hydration = s.hydration;
      food = List.from(s.food);
      symptoms = List.from(s.symptoms);
    }
  }

  Future<void> _save() async {
    setState(() { loading = true; error = null; });
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception('Utilisateur non connecté');

      // Récupérer le profil pour le cycle menstruel
      final profile = await _service.fetchUserProfile(user.uid);
      
      int cycleDay = 0;
      String cyclePhase = 'inconnue';
      
      if (profile != null) {
        cycleDay = DateTime.now().difference(profile.lastPeriodsDate).inDays + 1;
        // Approximation simple des phases (basée sur un cycle moyen de 28j)
        if (cycleDay <= 5) {
          cyclePhase = 'menstruelle';
        } else if (cycleDay <= 13) {
          cyclePhase = 'folliculaire';
        } else if (cycleDay <= 15) {
          cyclePhase = 'ovulatoire';
        } else {
          cyclePhase = 'lutéale';
        }
      }

      // Calcul heuristique du score (0-100)
      int score = 70; // Base
      if (sleepDuration > 7) score += 10;
      if (hydration > 6) score += 10;
      if (spfUsed) score += 10;
      if (stress > 7) score -= 15;
      if (food.contains('sucre')) score -= 10;
      if (food.contains('laitages')) score -= 10;
      if (food.contains('fast-food')) score -= 15;
      if (food.contains('fruits')) score += 5;
      if (food.contains('équilibrée')) score += 10;
      score = score.clamp(0, 100);

      final survey = DailySurvey(
        id: '${user.uid}_${DateTime.now().toIso8601String().split('T')[0]}',
        userId: user.uid,
        date: DateTime.now(),
        stress: stress.toInt(),
        sleepDuration: sleepDuration,
        sleepQuality: sleepQuality.toInt(),
        hydration: hydration,
        food: food,
        symptoms: symptoms,
        cycleDay: cycleDay,
        cyclePhase: cyclePhase,
        lifestyleScore: score,
      );

      await _service.saveDailySurvey(survey);
      if (mounted) context.pop();
    } catch (e) {
      setState(() { error = e.toString(); });
    } finally {
      setState(() { loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('CHAQUE JOUR')),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(24),
              children: [
                Text('📋 Questionnaire Quotidien', style: Theme.of(context).textTheme.headlineSmall),
                const SizedBox(height: 24),
                
                Text('Stress (1-10) : ${stress.toInt()}'),
                Slider(
                  value: stress, min: 1, max: 10, divisions: 9,
                  onChanged: (v) => setState(() => stress = v),
                ),
                const SizedBox(height: 16),
                
                Text('Sommeil - Durée (heures) : ${sleepDuration.toStringAsFixed(1)}h'),
                Slider(
                  value: sleepDuration, min: 0, max: 14, divisions: 28,
                  onChanged: (v) => setState(() => sleepDuration = v),
                ),
                Text('Sommeil - Qualité (1-10) : ${sleepQuality.toInt()}'),
                Slider(
                  value: sleepQuality, min: 1, max: 10, divisions: 9,
                  onChanged: (v) => setState(() => sleepQuality = v),
                ),
                const SizedBox(height: 16),
                
                Text('Hydratation (verres d\'eau) : $hydration'),
                Slider(
                  value: hydration.toDouble(), min: 0, max: 15, divisions: 15,
                  onChanged: (v) => setState(() => hydration = v.toInt()),
                ),
                const SizedBox(height: 16),
                
                SwitchListTile(
                  title: const Text('SPF appliqué aujourd\'hui ?'),
                  value: spfUsed,
                  onChanged: (v) => setState(() => spfUsed = v),
                ),
                const SizedBox(height: 16),
                
                const Text('Alimentation :'),
                Wrap(
                  spacing: 8,
                  children: foodOptions.map((e) => FilterChip(
                    label: Text(e),
                    selected: food.contains(e),
                    onSelected: (val) => setState(() {
                      val ? food.add(e) : food.remove(e);
                    }),
                  )).toList(),
                ),
                const SizedBox(height: 16),
                
                const Text('Symptômes du jour :'),
                Wrap(
                  spacing: 8,
                  children: symptomsOptions.map((e) => FilterChip(
                    label: Text(e),
                    selected: symptoms.contains(e),
                    onSelected: (val) => setState(() {
                      val ? symptoms.add(e) : symptoms.remove(e);
                    }),
                  )).toList(),
                ),
                const SizedBox(height: 32),
                
                if (error != null)
                  Text(error!, style: const TextStyle(color: Colors.red)),
                
                ElevatedButton(
                  onPressed: loading ? null : _save,
                  child: const Text('Enregistrer'),
                ),
              ],
            ),
    );
  }
}
