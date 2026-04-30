import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../data/services/questionnaire_service.dart';
import '../../domain/entities/user_profile.dart';

class ProfileQuestionnaireScreen extends StatefulWidget {
  final UserProfile? initialProfile;
  const ProfileQuestionnaireScreen({super.key, this.initialProfile});

  @override
  State<ProfileQuestionnaireScreen> createState() => _ProfileQuestionnaireScreenState();
}

class _ProfileQuestionnaireScreenState extends State<ProfileQuestionnaireScreen> {
  final _formKey = GlobalKey<FormState>();
  final _service = QuestionnaireService();
  final _picker = ImagePicker();

  bool loading = false;
  String? error;

  // Champs
  final TextEditingController _firstNameCtrl = TextEditingController();
  final TextEditingController _ageCtrl = TextEditingController(text: '18');
  final TextEditingController _imcCtrl = TextEditingController(text: '22.0');
  final TextEditingController _cigCtrl = TextEditingController(text: '0');

  bool sopk = false;
  bool acneFamilyHistory = false;
  bool smoker = false;
  String alcohol = 'jamais';
  String skinType = 'normale';
  List<String> cosmeticAllergies = [];
  String hormonalTreatment = 'aucun';
  String acneTreatment = 'aucun';
  List<String> skincareRoutine = [];
  
  DateTime lastPeriodsDate = DateTime.now();
  int lastCycle1 = 28;
  int lastCycle2 = 28;
  int lastCycle3 = 28;

  Map<String, String> initialPhotos = {};

  final List<String> alcoholOptions = ['jamais', 'occasionnel', 'régulier'];
  final List<String> skinTypeOptions = ['grasse', 'mixte', 'sèche', 'sensible', 'normale', 'acnéique'];
  final List<String> allergiesOptions = ['parfums', 'conservateurs', 'alcool cosmétique', 'nickel', 'filtres solaires', 'rétinol'];
  final List<String> hormonalOptions = ['pilule', 'implant', 'stérilet', 'aucun'];
  final List<String> acneTreatOptions = ['antibiotiques', 'isotrétinoïne', 'crème ordonnance', 'aucun'];
  final List<String> routineOptions = ['nettoyant', 'hydratant', 'sérum', 'exfoliant', 'masque'];

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null && widget.initialProfile == null) {
      final p = await _service.fetchUserProfile(user.uid);
      if (p != null) _populate(p);
    } else if (widget.initialProfile != null) {
      _populate(widget.initialProfile!);
    }
  }

  void _populate(UserProfile p) {
    setState(() {
      _firstNameCtrl.text = p.firstName;
      _ageCtrl.text = p.age.toString();
      _imcCtrl.text = p.imc.toString();
      _cigCtrl.text = p.cigarettesPerDay.toString();
      sopk = p.sopk;
      acneFamilyHistory = p.acneFamilyHistory;
      smoker = p.smoker;
      alcohol = p.alcohol.isNotEmpty ? p.alcohol : 'jamais';
      skinType = p.skinType.isNotEmpty ? p.skinType : 'normale';
      cosmeticAllergies = List<String>.from(p.cosmeticAllergies);
      hormonalTreatment = p.hormonalTreatment.isNotEmpty ? p.hormonalTreatment : 'aucun';
      acneTreatment = p.acneTreatment.isNotEmpty ? p.acneTreatment : 'aucun';
      skincareRoutine = List<String>.from(p.skincareRoutine);
      lastPeriodsDate = p.lastPeriodsDate;
      if (p.lastCyclesDuration.length >= 3) {
        lastCycle1 = p.lastCyclesDuration[0];
        lastCycle2 = p.lastCyclesDuration[1];
        lastCycle3 = p.lastCyclesDuration[2];
      }
      initialPhotos = Map<String, String>.from(p.initialPhotos);
    });
  }

  Future<void> _pickImage(String key) async {
    final xFile = await _picker.pickImage(source: ImageSource.gallery);
    if (xFile != null) {
      setState(() {
        initialPhotos[key] = xFile.path;
      });
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: lastPeriodsDate,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (picked != null && picked != lastPeriodsDate) {
      setState(() {
        lastPeriodsDate = picked;
      });
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() { loading = true; error = null; });
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception('Utilisateur non connecté');
      
      final profile = UserProfile(
        id: user.uid,
        firstName: _firstNameCtrl.text.trim(),
        age: int.tryParse(_ageCtrl.text) ?? 18,
        imc: double.tryParse(_imcCtrl.text) ?? 22.0,
        sopk: sopk,
        acneFamilyHistory: acneFamilyHistory,
        smoker: smoker,
        cigarettesPerDay: smoker ? (int.tryParse(_cigCtrl.text) ?? 0) : 0,
        alcohol: alcohol,
        skinType: skinType,
        cosmeticAllergies: cosmeticAllergies,
        hormonalTreatment: hormonalTreatment,
        acneTreatment: acneTreatment,
        skincareRoutine: skincareRoutine,
        lastPeriodsDate: lastPeriodsDate,
        lastCyclesDuration: [lastCycle1, lastCycle2, lastCycle3],
        initialPhotos: initialPhotos,
      );
      
      await _service.saveUserProfile(profile);
      if (mounted) context.go('/home'); // Retour à l'accueil
    } catch (e) {
      setState(() { error = e.toString(); });
    } finally {
      setState(() { loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('ONBOARDING')),
      body: loading 
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(24),
                children: [
                  Text('📋 Profil permanent', style: Theme.of(context).textTheme.headlineSmall),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _firstNameCtrl,
                    decoration: const InputDecoration(labelText: 'Prénom'),
                    validator: (v) => v!.isEmpty ? 'Requis' : null,
                  ),
                  const SizedBox(height: 16),
                  Row(children: [
                    Expanded(child: TextFormField(
                      controller: _ageCtrl,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'Âge'),
                    )),
                    const SizedBox(width: 16),
                    Expanded(child: TextFormField(
                      controller: _imcCtrl,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'IMC'),
                    )),
                  ]),
                  const SizedBox(height: 16),
                  SwitchListTile(
                    title: const Text('SOPK'),
                    value: sopk,
                    onChanged: (v) => setState(() => sopk = v),
                  ),
                  SwitchListTile(
                    title: const Text('Antécédents familiaux acné'),
                    value: acneFamilyHistory,
                    onChanged: (v) => setState(() => acneFamilyHistory = v),
                  ),
                  SwitchListTile(
                    title: const Text('Fumeur'),
                    value: smoker,
                    onChanged: (v) => setState(() => smoker = v),
                  ),
                  if (smoker)
                    TextFormField(
                      controller: _cigCtrl,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'Cigarettes / jour'),
                    ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    value: alcoholOptions.contains(alcohol) ? alcohol : null,
                    decoration: const InputDecoration(labelText: 'Alcool'),
                    items: alcoholOptions.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                    onChanged: (v) => setState(() => alcohol = v!),
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    value: skinTypeOptions.contains(skinType) ? skinType : null,
                    decoration: const InputDecoration(labelText: 'Type de peau'),
                    items: skinTypeOptions.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                    onChanged: (v) => setState(() => skinType = v!),
                  ),
                  const SizedBox(height: 16),
                  const Text('Allergies cosmétiques :'),
                  Wrap(
                    spacing: 8,
                    children: allergiesOptions.map((e) => FilterChip(
                      label: Text(e),
                      selected: cosmeticAllergies.contains(e),
                      onSelected: (val) => setState(() {
                        val ? cosmeticAllergies.add(e) : cosmeticAllergies.remove(e);
                      }),
                    )).toList(),
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    value: hormonalOptions.contains(hormonalTreatment) ? hormonalTreatment : null,
                    decoration: const InputDecoration(labelText: 'Traitement hormonal actuel'),
                    items: hormonalOptions.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                    onChanged: (v) => setState(() => hormonalTreatment = v!),
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    value: acneTreatOptions.contains(acneTreatment) ? acneTreatment : null,
                    decoration: const InputDecoration(labelText: 'Traitement médical acné actuel'),
                    items: acneTreatOptions.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                    onChanged: (v) => setState(() => acneTreatment = v!),
                  ),
                  const SizedBox(height: 16),
                  const Text('Routine skincare actuelle :'),
                  Wrap(
                    spacing: 8,
                    children: routineOptions.map((e) => FilterChip(
                      label: Text(e),
                      selected: skincareRoutine.contains(e),
                      onSelected: (val) => setState(() {
                        val ? skincareRoutine.add(e) : skincareRoutine.remove(e);
                      }),
                    )).toList(),
                  ),
                  
                  const Divider(height: 48),
                  Text('🌸 Cycle menstruel', style: Theme.of(context).textTheme.headlineSmall),
                  const SizedBox(height: 16),
                  ListTile(
                    title: const Text('Date dernières règles'),
                    subtitle: Text(DateFormat('dd/MM/yyyy').format(lastPeriodsDate)),
                    trailing: const Icon(Icons.calendar_today),
                    onTap: () => _selectDate(context),
                  ),
                  const SizedBox(height: 16),
                  const Text('Durée 3 derniers cycles (jours)'),
                  Row(children: [
                    Expanded(child: TextFormField(
                      initialValue: lastCycle1.toString(),
                      keyboardType: TextInputType.number,
                      onChanged: (v) => lastCycle1 = int.tryParse(v) ?? 28,
                    )),
                    const SizedBox(width: 8),
                    Expanded(child: TextFormField(
                      initialValue: lastCycle2.toString(),
                      keyboardType: TextInputType.number,
                      onChanged: (v) => lastCycle2 = int.tryParse(v) ?? 28,
                    )),
                    const SizedBox(width: 8),
                    Expanded(child: TextFormField(
                      initialValue: lastCycle3.toString(),
                      keyboardType: TextInputType.number,
                      onChanged: (v) => lastCycle3 = int.tryParse(v) ?? 28,
                    )),
                  ]),

                  const Divider(height: 48),
                  Text('📸 Photos initiales', style: Theme.of(context).textTheme.headlineSmall),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildPhotoBox('Face', 'face'),
                      _buildPhotoBox('Profil Gauche', 'profil_gauche'),
                      _buildPhotoBox('Profil Droit', 'profil_droit'),
                    ],
                  ),

                  const SizedBox(height: 32),
                  if (error != null)
                    Text(error!, style: const TextStyle(color: Colors.red)),
                  ElevatedButton(
                    onPressed: loading ? null : _save,
                    child: const Text('Enregistrer le profil'),
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
    );
  }

  Widget _buildPhotoBox(String title, String key) {
    final path = initialPhotos[key];
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
