// FILE: features/forum/presentation/screens/create_post_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax/iconsax.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/common_widgets.dart';
import '../../data/services/forum_service.dart';

class CreatePostScreen extends StatefulWidget {
  const CreatePostScreen({super.key});
  @override State<CreatePostScreen> createState() => _CreatePostScreenState();
}
class _CreatePostScreenState extends State<CreatePostScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleCtrl = TextEditingController(), _contentCtrl = TextEditingController();
  String _cat = AppConstants.forumCategories.first;
  bool _loading = false;
  final _svc = ForumService();

  @override void dispose() { _titleCtrl.dispose(); _contentCtrl.dispose(); super.dispose(); }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      final id = await _svc.createPost(title: _titleCtrl.text.trim(), content: _contentCtrl.text.trim(), category: _cat);
      if (mounted) context.go('/forum/$id');
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erreur: $e'), backgroundColor: AppColors.error));
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Nouveau post')),
      body: SingleChildScrollView(padding: const EdgeInsets.all(20), child: Form(key: _formKey, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: AppColors.info.withOpacity(0.08), borderRadius: BorderRadius.circular(14), border: Border.all(color: AppColors.info.withOpacity(0.25))),
          child: Row(children: [Icon(Iconsax.shield_tick, color: AppColors.info, size: 18), const SizedBox(width: 10),
            Expanded(child: Text('Post anonyme. Ne partagez pas d\'infos personnelles.', style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.info)))])).animate().fadeIn(),
        const SizedBox(height: 22),
        Text('Catégorie', style: Theme.of(context).textTheme.labelLarge),
        const SizedBox(height: 8),
        Wrap(spacing: 8, runSpacing: 8, children: AppConstants.forumCategories.map((c) {
          final sel = _cat == c;
          return GestureDetector(onTap: () => setState(() => _cat = c),
            child: AnimatedContainer(duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(color: sel ? AppTheme.primary : AppTheme.primary.withOpacity(0.08), borderRadius: BorderRadius.circular(50)),
              child: Text(c, style: TextStyle(color: sel ? Colors.white : AppTheme.primary, fontSize: 12, fontWeight: FontWeight.w600))));
        }).toList()).animate().fadeIn(delay: 100.ms),
        const SizedBox(height: 22),
        Text('Titre *', style: Theme.of(context).textTheme.labelLarge),
        const SizedBox(height: 8),
        TextFormField(controller: _titleCtrl,
          decoration: const InputDecoration(hintText: 'Titre de votre question...'),
          validator: (v) => (v == null || v.trim().length < 5) ? 'Min. 5 caractères' : null,
          maxLength: 100).animate().fadeIn(delay: 200.ms),
        const SizedBox(height: 14),
        Text('Contenu *', style: Theme.of(context).textTheme.labelLarge),
        const SizedBox(height: 8),
        TextFormField(controller: _contentCtrl, maxLines: 8, minLines: 5,
          decoration: const InputDecoration(hintText: 'Décrivez votre question...', alignLabelWithHint: true),
          validator: (v) => (v == null || v.trim().length < 20) ? 'Min. 20 caractères' : null,
          maxLength: 2000).animate().fadeIn(delay: 280.ms),
        const SizedBox(height: 28),
        GradientButton(text: 'Publier anonymement 🌸', icon: Iconsax.send_1, onPressed: _submit, isLoading: _loading)
            .animate().fadeIn(delay: 360.ms),
        const SizedBox(height: 40),
      ]))),
    );
  }
}
