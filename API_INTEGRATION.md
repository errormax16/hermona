# 🔌 Intégration API – Guide de Remplacement Rapide

## Vue d'ensemble des 4 services à modifier

| Fichier | Endpoint | Statut |
|---------|----------|--------|
| `detection/data/services/detection_api_service.dart`         | `POST /detect`    | ✅ Mock actif |
| `recommendation/data/services/recommendation_api_service.dart` | `POST /recommend` | ✅ Mock actif |
| `prediction/data/services/prediction_api_service.dart`       | `POST /predict`   | ✅ Mock actif |
| `chat/data/services/chat_api_service.dart`                   | `POST /chat`      | ✅ Mock actif |

---

## Remplacement en 3 étapes (par service)

### Étape 1 – Décommenter le client Dio
```dart
// AVANT (commenté) :
// final Dio _dio;
// DetectionApiService() : _dio = Dio(BaseOptions(baseUrl: AppConstants.apiBaseUrl));

// APRÈS (actif) :
final Dio _dio;
DetectionApiService() : _dio = Dio(BaseOptions(
  baseUrl        : AppConstants.apiBaseUrl,
  connectTimeout : const Duration(seconds: 30),
  receiveTimeout : const Duration(seconds: 60),
));
```

### Étape 2 – Décommenter le bloc [API RÉELLE]
```dart
// Cherchez ce commentaire dans la méthode et décommentez le bloc :
// ════════════ [API RÉELLE] – Décommenter ce bloc ════════════
try {
  final response = await _dio.post('/detect', data: formData);
  return DetectionResult.fromJson(response.data!);
} on DioException catch (e) {
  throw ApiException(...);
}
```

### Étape 3 – Supprimer le bloc [MOCK – SUPPRIMER]
```dart
// Supprimez tout ce bloc :
// ════════════ [MOCK – SUPPRIMER] ════════════
await Future.delayed(const Duration(seconds: 3));
return DetectionResult( /* données fictives */ );
// ════════════════════════════════════════════
```

---

## Backend Python – Endpoints requis

```python
# FastAPI minimal example

from fastapi import FastAPI, UploadFile, File
from typing import List
import uuid

app = FastAPI()

@app.post("/detect")
async def detect(images: List[UploadFile] = File(...)):
    # Votre modèle ici
    return {
        "id"             : str(uuid.uuid4()),
        "severityScore"  : 65,
        "severityLevel"  : "moderate",  # normal | moderate | severe
        "classifications": [
            {
                "type"       : "Papule",   # Blackhead|Whitehead|Papule|Pustule|Nodule
                "percentage" : 0.60,
                "cause"      : "Inflammation bactérienne",
                "description": "Bosses rouges douloureuses"
            }
        ],
        "analyzedAt"     : "2024-01-15T10:30:00.000Z",
        "imageUrls"      : []
    }

@app.post("/recommend")
async def recommend(body: dict):
    # body = { "detection": {...}, "userId": "..." }
    return {
        "id"            : str(uuid.uuid4()),
        "detectionId"   : body["detection"]["id"],
        "morningRoutine": [
            { "step": "1", "product": "Nettoyant doux", "instruction": "...", "icon": "🧴" }
        ],
        "eveningRoutine": [ ... ],
        "dietTips"      : ["🥗 Conseil 1"],
        "duration"      : "8 semaines",
        "createdAt"     : "2024-01-15T10:30:00.000Z"
    }

@app.post("/predict")
async def predict(body: dict):
    # body = { "answers": { "stress": "high", ... } }
    return {
        "id"             : str(uuid.uuid4()),
        "riskScore"      : 0.68,          # 0.0 → 1.0
        "riskLevel"      : "medium",      # low | medium | high
        "trend"          : "stable",      # increasing | stable | decreasing
        "factors"        : ["Stress élevé"],
        "preventionTips" : ["🧘 Méditation"],
        "predictedAt"    : "2024-01-15T10:30:00.000Z"
    }

@app.post("/chat")
async def chat(body: dict):
    # body = { "history": [...], "message": "..." }
    return {
        "reply": "Votre réponse IA ici"
    }
```

---

## Tester la connexion

Ajoutez ce test rapide dans votre `main.dart` (temporaire) :
```dart
// Test de connexion API (supprimer après validation)
void _testApi() async {
  try {
    final dio = Dio(BaseOptions(baseUrl: AppConstants.apiBaseUrl));
    final res = await dio.get('/health');
    print('✅ API connectée : ${res.data}');
  } catch (e) {
    print('❌ API non joignable : $e');
  }
}
```

Votre backend doit exposer `GET /health` qui retourne `{ "status": "ok" }`.
