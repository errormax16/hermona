# 🌸 AcnéIA – Guide Complet de Configuration A → Z

---

## 📁 Architecture du Projet

```
acneia/
├── lib/
│   ├── main.dart                          # Entrée + gestion thème
│   ├── core/
│   │   ├── constants/app_constants.dart   # Toutes les constantes
│   │   ├── errors/app_exception.dart      # Exceptions typées
│   │   ├── router/app_router.dart         # Navigation go_router
│   │   ├── theme/app_theme.dart           # Design system
│   │   └── widgets/
│   │       ├── common_widgets.dart        # Widgets réutilisables
│   │       └── main_scaffold.dart         # Bottom navigation
│   └── features/
│       ├── auth/
│       │   ├── data/services/auth_service.dart         # Firebase Auth
│       │   ├── domain/entities/user_entity.dart
│       │   └── presentation/screens/
│       ├── home/presentation/screens/home_screen.dart
│       ├── detection/
│       │   ├── data/services/detection_api_service.dart   ← ✅ MOCK / 🔌 API
│       │   ├── domain/entities/detection_result.dart
│       │   └── presentation/screens/detection_result_screen.dart
│       ├── recommendation/
│       │   ├── data/services/recommendation_api_service.dart ← ✅ MOCK / 🔌 API
│       │   └── ...
│       ├── chat/
│       │   ├── data/services/chat_api_service.dart       ← ✅ MOCK / 🔌 API
│       │   └── ...
│       ├── prediction/
│       │   ├── data/services/prediction_api_service.dart ← ✅ MOCK / 🔌 API
│       │   └── ...
│       ├── profile/     → profile_screen, history_screen
│       ├── forum/       → forum_screen, forum_detail_screen, create_post_screen
│       └── messaging/   → conversations_screen, chat_private_screen
└── services/firebase/
    ├── forum_service.dart
    └── messaging_service.dart
```

---

## 🔥 ÉTAPE 1 – Configuration Firebase

### 1.1 Créer le projet
1. → https://console.firebase.google.com → **Ajouter un projet**
2. Nom : `acneia-prod` → Désactiver Analytics si non nécessaire → **Créer**

### 1.2 Authentication
1. **Authentication** → **Commencer** → onglet **Sign-in method**
2. Activer : ✅ **Email/Mot de passe** + ✅ **Google**
3. Pour Google : renseignez votre email de support

### 1.3 Firestore Database
1. **Firestore Database** → **Créer** → Mode **Production**
2. Région : `europe-west3` (Frankfurt)

### 1.4 Règles Firestore – copier-coller
```js
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {

    match /users/{uid} {
      allow read, write: if request.auth.uid == uid;
    }

    match /detections/{id} {
      allow read, write: if request.auth != null
        && resource.data.userId == request.auth.uid;
      allow create: if request.auth != null
        && request.resource.data.userId == request.auth.uid;
    }

    match /recommendations/{id} {
      allow read, write: if request.auth != null
        && resource.data.userId == request.auth.uid;
      allow create: if request.auth != null;
    }

    match /predictions/{id} {
      allow read, write: if request.auth != null
        && resource.data.userId == request.auth.uid;
      allow create: if request.auth != null;
    }

    match /chat_history/{id} {
      allow read, write: if request.auth != null
        && resource.data.userId == request.auth.uid;
      allow create: if request.auth != null;
    }

    match /forum_posts/{id} {
      allow read: if request.auth != null && resource.data.visible == true;
      allow create: if request.auth != null;
      allow update: if request.auth != null && (
        resource.data.authorId == request.auth.uid ||
        request.resource.data.diff(resource.data).affectedKeys()
          .hasOnly(['likesCount','repliesCount','reportsCount','visible'])
      );
    }

    match /forum_replies/{id} {
      allow read: if request.auth != null && resource.data.visible == true;
      allow create: if request.auth != null;
      allow update: if request.auth != null && (
        resource.data.authorId == request.auth.uid ||
        request.resource.data.diff(resource.data).affectedKeys()
          .hasOnly(['likesCount','reportsCount','visible'])
      );
    }

    match /likes/{id} {
      allow read, write: if request.auth != null;
    }

    match /reports/{id} {
      allow create: if request.auth != null;
      allow read: if false;
    }

    match /conversations/{id} {
      allow read, update: if request.auth != null
        && request.auth.uid in resource.data.participants;
      allow create: if request.auth != null;
    }

    match /messages/{id} {
      allow read: if request.auth != null;
      allow create: if request.auth != null;
      allow update: if request.auth != null
        && resource.data.senderId == request.auth.uid;
    }
  }
}
```

### 1.5 Index Firestore requis
Allez dans **Firestore → Index** et créez les index composites suivants :

| Collection        | Champ 1                     | Champ 2                      |
|-------------------|-----------------------------|------------------------------|
| detections        | userId ASC                  | analyzedAt DESC              |
| recommendations   | userId ASC                  | createdAt DESC               |
| predictions       | userId ASC                  | predictedAt DESC             |
| chat_history      | userId ASC                  | timestamp ASC                |
| forum_posts       | visible ASC                 | createdAt DESC               |
| forum_posts       | visible ASC, category ASC   | createdAt DESC               |
| forum_posts       | visible ASC                 | likesCount DESC              |
| forum_posts       | visible ASC, category ASC   | likesCount DESC              |
| forum_replies     | postId ASC, visible ASC     | createdAt ASC                |
| conversations     | participants ARRAY_CONTAINS | lastMessageAt DESC           |
| messages          | conversationId ASC, visible | createdAt ASC                |

### 1.6 Intégration Android
1. Firebase Console → **Paramètres** ⚙️ → **Vos applications** → **Ajouter Android**
2. Nom de package : `com.yourcompany.acneia`
3. Télécharger `google-services.json`
4. Remplacer `android/app/google-services.json` dans le projet

### 1.7 Intégration iOS
1. Firebase Console → **Ajouter iOS**
2. Bundle ID : `com.yourcompany.acneia`
3. Télécharger `GoogleService-Info.plist`
4. Ouvrir Xcode → glisser le fichier dans `Runner/`

---

## ☁️ ÉTAPE 2 – Configuration Appwrite (Stockage images)

### 2.1 Créer le projet
1. → https://cloud.appwrite.io → **Create project**
2. Nom : `acneia-storage` → Notez le **Project ID**

### 2.2 Créer le Bucket
1. **Storage** → **Create Bucket**
2. Nom : `acne-images`
3. **Permissions** :
   - Create : `Users`
   - Read   : `Users`
   - Delete : `Users`
4. Extensions autorisées : `jpg, jpeg, png, webp`
5. Taille max fichier : `10MB`
6. Notez le **Bucket ID**

### 2.3 Configurer les constantes
Dans `lib/core/constants/app_constants.dart` :
```dart
static const String appwriteEndpoint  = 'https://cloud.appwrite.io/v1';
static const String appwriteProjectId = 'VOTRE_PROJECT_ID';   // ← ici
static const String appwriteBucketId  = 'VOTRE_BUCKET_ID';    // ← ici
```

---

## 🤖 ÉTAPE 3 – Intégration du Backend Python (API Réelle)

### Pattern de remplacement (même pour tous les services)

Chaque service data suit ce pattern exact :

```dart
Future<DetectionResult> analyzeImages(List<File> images) async {

  // ════════════ [API RÉELLE] – Décommenter ce bloc ════════════
  // try {
  //   final formData = FormData();
  //   for (int i = 0; i < images.length; i++) {
  //     formData.files.add(MapEntry('images',
  //       await MultipartFile.fromFile(images[i].path, filename: 'img_$i.jpg')));
  //   }
  //   final response = await _dio.post<Map<String,dynamic>>('/detect', data: formData);
  //   return DetectionResult.fromJson(response.data!);
  // } on DioException catch (e) {
  //   throw ApiException(e.response?.data?['detail'] ?? 'Erreur', statusCode: e.response?.statusCode);
  // }
  // ════════════════════════════════════════════════════════════

  // ════════════ [MOCK – SUPPRIMER] ════════════
  await Future.delayed(const Duration(seconds: 3));
  return DetectionResult( /* données simulées */ );
  // ════════════════════════════════════════════
}
```

### 3.1 Checklist de remplacement pour chaque endpoint

**POST /detect** → `detection_api_service.dart`
1. Décommentez `final Dio _dio` et le constructeur
2. Décommentez le bloc `[API RÉELLE]` dans `analyzeImages()`
3. Supprimez le bloc `[MOCK – SUPPRIMER]`

**POST /recommend** → `recommendation_api_service.dart`
1. Décommentez `_dio`
2. Décommentez le bloc `[API RÉELLE]` dans `getRecommendations()`
3. Supprimez le bloc `[MOCK – SUPPRIMER]`

**POST /predict** → `prediction_api_service.dart`
1. Décommentez `_dio`
2. Décommentez le bloc `[API RÉELLE]` dans `predict()`
3. Supprimez le bloc `[MOCK – SUPPRIMER]`

**POST /chat** → `chat_api_service.dart`
1. Décommentez `_dio`
2. Décommentez le bloc `[API RÉELLE]` dans `getResponse()`
3. Supprimez le bloc `[MOCK – SUPPRIMER]`

### 3.2 Format de réponse attendu par le frontend

#### POST /detect → `DetectionResult`
```json
{
  "id": "unique_string",
  "severityScore": 72,
  "severityLevel": "moderate",
  "classifications": [
    {
      "type": "Papule",
      "percentage": 0.45,
      "cause": "Inflammation due aux bactéries P. acnes",
      "description": "Bosses rouges et douloureuses sans pus visible"
    }
  ],
  "analyzedAt": "2024-01-15T10:30:00.000Z",
  "imageUrls": ["https://..."]
}
```
> `severityLevel` : `"normal"` | `"moderate"` | `"severe"`
> `type` : `"Blackhead"` | `"Whitehead"` | `"Papule"` | `"Pustule"` | `"Nodule"`

#### POST /recommend → `RecommendationResult`
```json
{
  "id": "unique_string",
  "detectionId": "ref_to_detection",
  "morningRoutine": [
    { "step": "1", "product": "Nettoyant doux", "instruction": "...", "icon": "🧴" }
  ],
  "eveningRoutine": [ ... ],
  "dietTips": ["🥗 Conseil 1", "💦 Conseil 2"],
  "duration": "8 semaines",
  "createdAt": "2024-01-15T10:30:00.000Z"
}
```

#### POST /predict → `PredictionResult`
```json
{
  "id": "unique_string",
  "riskScore": 0.68,
  "riskLevel": "medium",
  "trend": "stable",
  "factors": ["Stress élevé", "Alimentation pro-inflammatoire"],
  "preventionTips": ["🧘 Méditation 10 min/jour"],
  "predictedAt": "2024-01-15T10:30:00.000Z"
}
```
> `riskLevel` : `"low"` | `"medium"` | `"high"`
> `trend` : `"increasing"` | `"stable"` | `"decreasing"`

#### POST /chat → `{ "reply": "string" }`
```json
{
  "reply": "Votre réponse de l'IA ici..."
}
```

### 3.3 Configurer l'URL du backend

Dans `lib/core/constants/app_constants.dart` :
```dart
// Développement local :
static const String apiBaseUrl = 'http://localhost:8000';

// Production (votre serveur) :
static const String apiBaseUrl = 'https://api.votre-domaine.com';

// Pour tester sur appareil Android physique (émulateur) :
static const String apiBaseUrl = 'http://10.0.2.2:8000';
```

### 3.4 Ajouter les imports Dio

Dans chaque service, décommentez en haut du fichier :
```dart
import 'package:dio/dio.dart';
import '../../../../core/errors/app_exception.dart';
```

Et dans les services de détection :
```dart
// Pour l'upload multipart
import 'package:http_parser/http_parser.dart';
```

Ajoutez dans `pubspec.yaml` si absent :
```yaml
http_parser: ^4.0.2
```

---

## 🚀 ÉTAPE 4 – Lancer l'application

### Prérequis
```bash
flutter --version   # >= 3.1.0
```

### Installation & premier lancement
```bash
cd acneia
flutter pub get
flutter run
```

### Android (release)
```bash
flutter build apk --release
# ou pour Google Play :
flutter build appbundle --release
```

### iOS (release)
```bash
flutter build ios --release
# Ouvrir Xcode → Product → Archive → Distribute
```

---

## ✅ Checklist pré-production

- [ ] `google-services.json` remplacé par le vrai fichier
- [ ] `GoogleService-Info.plist` ajouté dans Xcode
- [ ] Règles Firestore déployées
- [ ] Index Firestore créés
- [ ] `appwriteProjectId` et `appwriteBucketId` configurés
- [ ] `apiBaseUrl` pointant vers votre backend déployé
- [ ] Blocs `[API RÉELLE]` décommentés dans les 4 services
- [ ] Blocs `[MOCK – SUPPRIMER]` supprimés
- [ ] Icône de l'app créée (1024×1024 PNG)
- [ ] Splash screen configuré
- [ ] Test complet Android + iOS

---

## 🎨 Personnalisation rapide

### Changer la couleur par défaut
Dans `lib/core/theme/app_theme.dart` ligne 1 :
```dart
static Color _primary = AppColors.primary;
// Remplacez AppColors.primary par n'importe quelle Color(0xFFxxxxxx)
```

### Ajouter un type d'acné
Dans `detection_api_service.dart`, ajoutez à `_acneData` :
```dart
'NouveauType': {
  'cause': '...',
  'description': '...',
},
```

### Ajouter une catégorie forum
Dans `app_constants.dart` :
```dart
static const List<String> forumCategories = [
  'Général', ..., 'Votre nouvelle catégorie',
];
```
