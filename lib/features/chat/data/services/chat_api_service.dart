import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';
// import 'package:dio/dio.dart';

import '../../domain/entities/chat_message.dart';
import '../../../../core/constants/app_constants.dart';
// import '../../../../core/errors/app_exception.dart';

// ─────────────────────────────────────────────────────────────────────────────
// DATA – Implémentation du ChatRepository
//
// ✅ MOCK ACTIF  – réponses contextuelles pré-définies
// 🔌 API RÉELLE  – commentée, endpoint : POST /chat
//
// Pour passer à l'API réelle (ex: LLM Python / LangChain) :
//   1. Décommentez Dio + ApiException
//   2. Décommentez le bloc [API RÉELLE] dans getResponse()
//   3. Supprimez le bloc [MOCK – À SUPPRIMER]
// ─────────────────────────────────────────────────────────────────────────────
class ChatApiService implements ChatRepository {

  // final Dio _dio;
  // ChatApiService()
  //     : _dio = Dio(BaseOptions(baseUrl: AppConstants.apiBaseUrl));

  final FirebaseFirestore _db  = FirebaseFirestore.instance;
  final _uuid                  = const Uuid();

  // ─────────────────────────────────────────────────────────────────────────
  @override
  Future<String> getResponse({
    required List<ChatMessage> history,
    required String userMessage,
  }) async {

    // ════════════════════════════════════════════════════════════════════════
    // [API RÉELLE] – POST /chat
    // ════════════════════════════════════════════════════════════════════════
    // try {
    //   final response = await _dio.post<Map<String, dynamic>>(
    //     '/chat',
    //     data: {
    //       'history': history.map((m) => m.toJson()).toList(),
    //       'message': userMessage,
    //     },
    //   );
    //   return response.data!['reply'] as String;
    // } on DioException catch (e) {
    //   throw ApiException(
    //     e.response?.data?['detail'] ?? 'Erreur du chat IA',
    //     statusCode: e.response?.statusCode,
    //   );
    // }
    // ════════════════════════════════════════════════════════════════════════

    // ════════════════════════════════════════════════════════════════════════
    // [MOCK – À SUPPRIMER] – Réponses contextuelles
    // ════════════════════════════════════════════════════════════════════════
    await Future.delayed(const Duration(milliseconds: 1400));

    final msg = userMessage.toLowerCase();

    if (msg.contains('bonjour') || msg.contains('salut') || msg.contains('hello')) {
      return 'Bonjour ! 🌸 Je suis votre assistante beauté AcnéIA.\n\nJe peux vous aider sur :\n• **Les types d\'acné** et leurs causes\n• **Les routines de soins** personnalisées\n• **L\'alimentation** anti-acné\n• **La prévention** des poussées\n\nQue souhaitez-vous savoir ? ✨';
    }
    if (msg.contains('blackhead') || msg.contains('point noir')) {
      return '**Points noirs (Blackheads)** 🔍\n\nIls se forment quand le sébum accumule dans un pore *ouvert* et s\'oxyde.\n\n**Traitement :**\n• Acide salicylique 1-2% (nettoie en profondeur)\n• Niacinamide 10% (régule le sébum)\n• Patchs pore 1× / semaine maximum\n• ❌ Ne jamais presser (risque cicatrice)\n\nVoulez-vous un conseil sur un produit précis ? 💕';
    }
    if (msg.contains('routine') || msg.contains('soin')) {
      return '**Routine anti-acné essentielle** ✨\n\n**☀️ Matin :**\n1. Nettoyant doux sans savon\n2. Tonique sans alcool\n3. Sérum niacinamide 10%\n4. Hydratant léger non-comédogène\n5. SPF 30+ minéral\n\n**🌙 Soir :**\n1. Double nettoyage (huile → gel)\n2. Tonique BHA/AHA (3× / sem.)\n3. Traitement ciblé (rétinoïde ou bha)\n4. Crème barrière réparatrice\n\nSouhaitez-vous plus de détails sur une étape ? 🌿';
    }
    if (msg.contains('aliment') || msg.contains('manger') || msg.contains('diet') || msg.contains('nourriture')) {
      return '**Alimentation & Acné** 🥗\n\n**À privilégier :**\n• Légumes à feuilles vertes (zinc, magnésium)\n• Poissons gras (oméga-3 anti-inflammatoires)\n• Fruits rouges (antioxydants)\n• Probiotiques (microbiome cutané)\n\n**À réduire :**\n• Sucres raffinés (pic insuline → acné)\n• Produits laitiers (hormones bovines)\n• Fast-food et ultra-transformés\n\nAvez-vous remarqué des aliments déclencheurs chez vous ? 🌿';
    }
    if (msg.contains('stress')) {
      return '**Stress & Acné** 🧘\n\nLe stress stimule le cortisol qui active les glandes sébacées → plus de sébum → plus d\'acné.\n\n**Solutions :**\n• Méditation 10 min / jour (app Petit Bambou)\n• Yoga ou marche rapide 30 min\n• Respiration 4-7-8 avant de dormir\n• Journaling pour vider les pensées\n\nLe stress est souvent sous-estimé dans l\'acné ! 💆‍♀️';
    }
    if (msg.contains('hormonal') || msg.contains('règle') || msg.contains('cycle')) {
      return '**Acné Hormonale** 🌸\n\nTypiquement autour du menton et de la mâchoire, avant les règles.\n\n**Approche :**\n• Suivez votre cycle (app Clue ou Flo)\n• Renforcez la routine J20-J28\n• Zinc (50mg) et vitamine B6 peuvent aider\n• Consultez un gynéco pour contraceptif adapté\n\nL\'acné hormonale répond bien à un traitement ciblé ! 💕';
    }

    return 'Bonne question ! 🌷\n\nPour vous conseiller au mieux, pourriez-vous préciser :\n\n1. **Type de peau :** grasse, mixte ou sèche ?\n2. **Durée :** depuis combien de temps ?\n3. **Zone :** front, joues, menton, ou tout le visage ?\n\nAvec ces informations, mon conseil sera beaucoup plus précis ! 💝';
    // ════════════════════════════════════════════════════════════════════════
  }

  // ─────────────────────────────────────────────────────────────────────────
  @override
  Future<List<ChatMessage>> loadHistory(String userId) async {
    final snap = await _db
        .collection(AppConstants.colChatHistory)
        .where('userId', isEqualTo: userId)
        .orderBy('timestamp')
        .limit(60)
        .get();
    return snap.docs.map((d) => ChatMessage.fromJson(d.data())).toList();
  }

  @override
  Future<void> saveMessage(ChatMessage msg, String userId) async {
    await _db
        .collection(AppConstants.colChatHistory)
        .doc(msg.id)
        .set({...msg.toJson(), 'userId': userId});
  }

  @override
  Future<void> clearHistory(String userId) async {
    final snap = await _db
        .collection(AppConstants.colChatHistory)
        .where('userId', isEqualTo: userId)
        .get();
    final batch = _db.batch();
    for (final doc in snap.docs) { batch.delete(doc.reference); }
    await batch.commit();
  }
}
