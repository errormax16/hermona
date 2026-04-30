import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../data/services/questionnaire_service.dart';
import '../../domain/entities/weekly_survey.dart';

class WeeklyQuestionnaireScreen extends StatefulWidget {
  final WeeklySurvey? initialSurvey;
  const WeeklyQuestionnaireScreen({super.key, this.initialSurvey});

  @override
  State<WeeklyQuestionnaireScreen> createState() => _WeeklyQuestionnaireScreenState();
}

class _WeeklyQuestionnaireScreenState extends State<WeeklyQuestionnaireScreen> {
  final _formKey = GlobalKey<FormState>();
  final _service = QuestionnaireService();
  final _picker = ImagePicker();

  bool loading = false;
  String? error;

  // Photos
  Map<String, String> photos = {};

  // Maquillage
  String makeupFrequency = '';
  String makeupType = '';
  String makeupRemoval = '';

  // Routine
  String cleansingFrequency = '';
  String routineFollowed = '';
  String spfThisWeek = '';

  bool autoCorrection = false;
  bool reminderSent = false;
  bool spfAlert = false;

  @override
  void initState() {
    super.initState();
    final s = widget.initialSurvey;
    if (s != null) {
      photos = Map.from(s.photos);
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

  Future<void> _pickImage(String key) async {
    final xFile = await _picker.pickImage(source: ImageSource.gallery);
    if (xFile != null) {
      setState(() {
        photos[key] = xFile.path;
      });
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    
    // Logique d'alerte et correction auto (invisible à l'utilisateur, mais flaggée)
    autoCorrection = cleansingFrequency == 'rarement';
    reminderSent = routineFollowed == 'Non';
    spfAlert = spfThisWeek == 'Jamais';

    setState(() { loading = true; error = null; });
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception('Utilisateur non connecté');
      
      final now = DateTime.now();
      final weekNumber = _weekOfYear(now);
      
      final survey = WeeklySurvey(
        id: '${user.uid}_${weekNumber}_${now.year}',
        userId: user.uid,
        weekNumber: weekNumber,
        year: now.year,
        photos: photos,
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
      
      // Afficher alertes si nécessaire
      if (mounted) {
        if (spfAlert) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('⚠️ Attention : Le SPF est essentiel chaque jour !')));
        }
        if (reminderSent) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('💡 Rappel bienveillant : Essayez de suivre votre routine pour de meilleurs résultats.')));
        }
        context.pop();
      }
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
    return Scaffold(
      appBar: AppBar(title: const Text('CHAQUE SEMAINE')),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(24),
                children: [
                  Text('📋 Questionnaire Hebdomadaire', style: Theme.of(context).textTheme.headlineSmall),
                  const SizedBox(height: 24),
                  
                  Text('📸 Photos visage', style: Theme.of(context).textTheme.titleLarge),
                  const Text('Comparaison avec la semaine précédente.', style: TextStyle(color: Colors.grey)),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildPhotoBox('Face', 'face'),
                      _buildPhotoBox('Profil Gauche', 'profil_gauche'),
                      _buildPhotoBox('Profil Droit', 'profil_droit'),
                    ],
                  ),
                  const SizedBox(height: 24),

                  Text('💄 Maquillage', style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: makeupFrequency.isEmpty ? null : makeupFrequency,
                    decoration: const InputDecoration(labelText: 'Fréquence semaine'),
                    items: ['tous les jours', '4-6j', '2-3j', '1j', 'jamais']
                        .map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                    onChanged: (v) => setState(() => makeupFrequency = v!),
                    validator: (v) => v == null ? 'Requis' : null,
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    value: makeupType.isEmpty ? null : makeupType,
                    decoration: const InputDecoration(labelText: 'Type'),
                    items: ['complet', 'modéré', 'léger', 'naturel', 'aucun']
                        .map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                    onChanged: (v) => setState(() => makeupType = v!),
                    validator: (v) => v == null ? 'Requis' : null,
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    value: makeupRemoval.isEmpty ? null : makeupRemoval,
                    decoration: const InputDecoration(labelText: 'Démaquillage'),
                    items: ['complet', 'simple', 'partiel', 'rarement']
                        .map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                    onChanged: (v) => setState(() => makeupRemoval = v!),
                    validator: (v) => v == null ? 'Requis' : null,
                  ),
                  
                  const SizedBox(height: 32),
                  Text('🧴 Routine de soin', style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: cleansingFrequency.isEmpty ? null : cleansingFrequency,
                    decoration: const InputDecoration(labelText: 'Fréquence nettoyage visage'),
                    items: ['2x/jour', '1x/jour', 'rarement']
                        .map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                    onChanged: (v) => setState(() => cleansingFrequency = v!),
                    validator: (v) => v == null ? 'Requis' : null,
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    value: routineFollowed.isEmpty ? null : routineFollowed,
                    decoration: const InputDecoration(labelText: 'As-tu suivi la routine recommandée ?'),
                    items: ['Oui', 'Partiellement', 'Non']
                        .map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                    onChanged: (v) => setState(() => routineFollowed = v!),
                    validator: (v) => v == null ? 'Requis' : null,
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    value: spfThisWeek.isEmpty ? null : spfThisWeek,
                    decoration: const InputDecoration(labelText: 'Protection solaire cette semaine ?'),
                    items: ['Tous les jours', 'Parfois', 'Jamais']
                        .map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                    onChanged: (v) => setState(() => spfThisWeek = v!),
                    validator: (v) => v == null ? 'Requis' : null,
                  ),
                  
                  const SizedBox(height: 32),
                  if (error != null)
                    Text(error!, style: const TextStyle(color: Colors.red)),
                  ElevatedButton(
                    onPressed: loading ? null : _save,
                    child: const Text('Enregistrer le bilan'),
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
    );
  }

  Widget _buildPhotoBox(String title, String key) {
    final path = photos[key];
    return GestureDetector(
      onTap: () => _pickImage(key),
      child: Column(
        children: [
          Container(
            width: 80, height: 80,
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey[400]!),
            ),
            child: path != null 
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.file(File(path), fit: BoxFit.cover))
                : const Icon(Icons.add_a_photo, color: Colors.grey),
          ),
          const SizedBox(height: 8),
          Text(title, style: const TextStyle(fontSize: 12)),
        ],
      ),
    );
  }
}
