import os
import json
import uuid
import logging
import base64
from typing import List, Optional
from datetime import datetime

from fastapi import FastAPI, UploadFile, File, HTTPException, Request
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel
import joblib
import pandas as pd
import numpy as np
from groq import Groq
from dotenv import load_dotenv

import cv2
from PIL import Image, UnidentifiedImageError
from io import BytesIO

from app.model import get_model

# Charger les variables d'environnement depuis le dossier app/
env_path = os.path.join(os.path.dirname(__file__), '.env')
load_dotenv(env_path)

# Configuration Logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger("HermonaBackend")

app = FastAPI(title="Hermona AI Backend - Flutter Edition")

# CORS pour Flutter (Web, iOS, Android)
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# --- CONFIGURATION IA GROQ ---
GROQ_API_KEY = os.getenv("GROQ_API_KEY")
client = None
if GROQ_API_KEY and GROQ_API_KEY != "your_key_here":
    client = Groq(api_key=GROQ_API_KEY)
    logger.info("✅ Client Groq initialisé avec succès.")
else:
    logger.warning("⚠️ GROQ_API_KEY non configurée. Mode démo activé.")

# --- CHARGEMENT DES MODÈLES ---
# Modèle Tabulaire (Prédiction Risque)
MODEL_PATH = "model/modele_hermona_5000_20260415_221830 (1).pkl" # Modèle de Machine Learning
pkl_model = None
try:
    if os.path.exists(MODEL_PATH):
        pkl_model = joblib.load(MODEL_PATH)
        logger.info(f"✅ Modèle tabulaire chargé : {MODEL_PATH}")
    else:
        logger.warning(f"⚠️ Fichier modèle {MODEL_PATH} introuvable.")
except Exception as e:
    logger.error(f"❌ Erreur chargement modèle tabulaire : {e}")

# Modèle YOLO (Détection Acné)
yolo_model = get_model()

# --- MODELS DE DONNÉES (Pydantic) ---
class ChatMessage(BaseModel):
    role: str
    content: str

class ChatPayload(BaseModel):
    message: str
    history: Optional[List[dict]] = []
    profile: Optional[dict] = None
    prediction: Optional[dict] = None
    daily: Optional[dict] = None
    hormonal: Optional[dict] = None

# --- CONSTANTES ACNE ---
ACNE_DATA = {
    'Blackhead': {
        'cause': "Pores obstrués par excès de sébum oxydé au contact de l'air",
        'description': "Points noirs visibles, principalement sur le nez et le front",
    },
    'Whitehead': {
        'cause': "Pores totalement fermés piégeant sébum et cellules mortes",
        'description': "Petits boutons blancs sous la peau, sans contact avec l'air",
    },
    'Papule': {
        'cause': "Inflammation due aux bactéries P. acnes dans les pores",
        'description': "Bosses rouges et douloureuses sans pus visible",
    },
    'Pustule': {
        'cause': "Infection bactérienne avec accumulation de pus dans le follicule",
        'description': "Boutons avec centre blanc/jaune entouré de peau rouge",
    },
    'Nodule': {
        'cause': "Infection profonde touchant les couches inférieures de la peau",
        'description': "Grosses bosses dures et douloureuses sous la peau",
    },
}

# --- FONCTIONS UTILITAIRES ---
def get_face_crops(image_np):
    gray = cv2.cvtColor(image_np, cv2.COLOR_RGB2GRAY)
    cascade_path = cv2.data.haarcascades + 'haarcascade_frontalface_default.xml'
    face_cascade = cv2.CascadeClassifier(cascade_path)
    faces = face_cascade.detectMultiScale(gray, scaleFactor=1.1, minNeighbors=5, minSize=(100, 100))
    
    if len(faces) == 0:
        return [("Visage", image_np)]
        
    faces = sorted(faces, key=lambda f: f[2]*f[3], reverse=True)
    x, y, w, h = faces[0]
    
    crops = []
    img_h, img_w = image_np.shape[:2]
    
    # 1. Front
    y1, y2 = max(0, y - int(h * 0.1)), min(img_h, y + int(h * 0.35))
    x1, x2 = max(0, x - int(w * 0.1)), min(img_w, x + w + int(w * 0.1))
    if y2 > y1 and x2 > x1:
        crops.append(("Front", image_np[y1:y2, x1:x2]))
        
    # 2. Joue Droite
    y1, y2 = max(0, y + int(h * 0.3)), min(img_h, y + int(h * 0.8))
    x1, x2 = max(0, x - int(w * 0.1)), min(img_w, x + int(w * 0.5))
    if y2 > y1 and x2 > x1:
        crops.append(("Joue Droite", image_np[y1:y2, x1:x2]))
        
    # 3. Joue Gauche
    y1, y2 = max(0, y + int(h * 0.3)), min(img_h, y + int(h * 0.8))
    x1, x2 = max(0, x + int(w * 0.5)), min(img_w, x + w + int(w * 0.1))
    if y2 > y1 and x2 > x1:
        crops.append(("Joue Gauche", image_np[y1:y2, x1:x2]))
        
    # 4. Menton
    y1, y2 = max(0, y + int(h * 0.7)), min(img_h, y + int(h * 1.15))
    x1, x2 = max(0, x + int(w * 0.2)), min(img_w, x + int(w * 0.8))
    if y2 > y1 and x2 > x1:
        crops.append(("Menton", image_np[y1:y2, x1:x2]))
        
    return crops

# --- ENDPOINTS ---

@app.get("/health")
async def health():
    return {
        "status": "ok",
        "groq_ready": client is not None,
        "pkl_model_loaded": pkl_model is not None,
        "yolo_model_loaded": yolo_model is not None,
        "timestamp": datetime.now().isoformat()
    }

@app.post("/chat")
async def chat(payload: ChatPayload):
    if not client:
        return {"response": "Désolée, le service de chat est en mode démo car la clé API est manquante. 🌸"}

    try:
        profile = payload.profile or {}
        system_prompt = f"""Tu es AcnéIA, une assistante experte en acné hormonale.
        Contexte de l'utilisatrice :
        - Âge : {profile.get('age', 'non spécifié')}
        - SOPK/PCOS : {profile.get('pcos', 'non spécifié')}
        - Type de peau : {profile.get('type_peau', 'non spécifié')}
        
        Réponds de manière empathique, scientifique mais accessible. Utilise des emojis 🌸."""

        messages = [{"role": "system", "content": system_prompt}]
        for msg in payload.history:
            messages.append({"role": msg.get("role", "user"), "content": msg.get("content", "")})
        
        messages.append({"role": "user", "content": payload.message})

        completion = client.chat.completions.create(
            model="llama-3.3-70b-versatile",
            messages=messages,
            temperature=0.7,
            max_tokens=1024,
        )

        return {"response": completion.choices[0].message.content}
    except Exception as e:
        logger.error(f"Erreur Chat: {e}")
        raise HTTPException(status_code=500, detail=str(e))

@app.post("/transcribe")
async def transcribe(file: UploadFile = File(...)):
    if not client:
        raise HTTPException(status_code=400, detail="Groq non configuré.")
    
    try:
        temp_path = f"temp_{uuid.uuid4()}_{file.filename}"
        with open(temp_path, "wb") as buffer:
            content = await file.read()
            buffer.write(content)

        with open(temp_path, "rb") as audio_file:
            transcription = client.audio.transcriptions.create(
                model="whisper-large-v3",
                file=audio_file,
                language="fr"
            )

        os.remove(temp_path)
        return {"text": transcription.text}
    except Exception as e:
        logger.error(f"Erreur Transcription: {e}")
        return {"text": "", "error": str(e)}

@app.post("/predict")
async def predict(body: dict):
    answers = body.get('answers', {})
    
    # Valeurs par défaut basiques (moyennes) pour les 40 colonnes attendues
    data = {
        'age': 25, 'pcos': 0, 'stress': 5, 'sommeil': 7, 'alimentation_impact': 0.5, 
        'LH': 5.0, 'estradiol': 50.0, 'progesterone': 10.0, 'testosterone': 0.5, 
        'jour_cycle': 14, 'soleil_heures': 1.0, 'protection_solaire': 1, 
        'allergies': 0, 'antecedents_familiaux': 0, 'maquillage': 1, 
        'hydratation_verres': 6, 'fumeur': 0, 'cigarettes': 0, 'imc': 22.0, 
        'alcool_jamais': 1, 'alcool_occasionnel': 0, 'alcool_r\xe9gulier': 0, 
        'type_peau_acn\xe9ique': 0, 'type_peau_d\xe9shydrat\xe9e': 0, 
        'type_peau_grasse': 0, 'type_peau_mixte': 1, 'type_peau_normale': 0, 
        'type_peau_seche': 0, 'type_peau_sensible': 0, 
        'sport_1-2x/semaine': 1, 'sport_3-4x/semaine': 0, 'sport_jamais': 0, 
        'lavage_1x/jour': 0, 'lavage_2x/jour': 1, 'lavage_3x/jour': 0, 'lavage_parfois': 0, 
        'phase_folliculaire': 1, 'phase_luteale': 0, 'phase_menstruelle': 0, 'phase_ovulatoire': 0
    }
    
    factors = []
    
    # Ajustement des features selon les réponses du Flutter
    if answers.get('hormonal_cycle') == 'pre_menstrual':
        data['phase_folliculaire'] = 0
        data['phase_luteale'] = 1
        data['jour_cycle'] = 24
        factors.append('Période prémenstruelle (pic hormonal)')
    elif answers.get('hormonal_cycle') == 'menstrual':
        data['phase_folliculaire'] = 0
        data['phase_menstruelle'] = 1
        data['jour_cycle'] = 2
        factors.append('Période menstruelle')
        
    if answers.get('diet') == 'bad':
        data['alimentation_impact'] = 1.0
        factors.append('Alimentation pro-inflammatoire')
        
    stress_val = answers.get('stress', 'medium')
    if stress_val == 'very_high':
        data['stress'] = 10
        factors.append('Stress très élevé')
    elif stress_val == 'high':
        data['stress'] = 8
        factors.append('Niveau de stress élevé')
        
    sleep_val = answers.get('sleep', 'good')
    if sleep_val in ['poor', 'very_poor']:
        data['sommeil'] = 4
        factors.append('Manque de sommeil')
        
    if answers.get('temperature') == 'hot_humid':
        factors.append('Chaleur et humidité')
        
    if answers.get('skincare') in ['none', 'sometimes']:
        data['lavage_2x/jour'] = 0
        data['lavage_parfois'] = 1
        factors.append('Routine de soins irrégulière')

    risk_score = 0.30
    
    if pkl_model:
        try:
            # Créer un DataFrame avec une seule ligne, en respectant l'ordre exact attendu
            df = pd.DataFrame([data])
            # Le modèle renvoie des probabilités [prob_0, prob_1]
            prob = pkl_model.predict_proba(df)[0][1]
            risk_score = float(prob)
        except Exception as e:
            logger.error(f"Erreur prédiction modèle: {e}")
            pass
            
    # Détermination du niveau et de la tendance
    level = "low"
    if risk_score >= 0.65:
        level = "high"
    elif risk_score >= 0.35:
        level = "medium"
        
    trend = "stable"
    if risk_score > 0.60:
        trend = "increasing"
    elif risk_score < 0.35:
        trend = "decreasing"

    tips = [
        "🧘 10 min de méditation / jour pour réguler le cortisol",
        "💤 7-9h de sommeil pour la régénération cellulaire",
        "🌊 Nettoyez le visage après chaque transpiration"
    ]
    
    if not factors:
        factors.append('Aucun facteur de risque majeur identifié')

    return {
        "id": f"pred_{uuid.uuid4().hex[:8]}",
        "riskScore": round(risk_score, 2),
        "riskLevel": level,
        "trend": trend,
        "factors": factors,
        "preventionTips": tips,
        "predictedAt": datetime.now().isoformat() + "Z"
    }

@app.post("/detect")
async def detect(files: List[UploadFile] = File(...)):
    counts = {'Blackhead': 0, 'Whitehead': 0, 'Papule': 0, 'Pustule': 0, 'Nodule': 0}
    total_detections = 0
    imageUrls = []

    for file in files:
        contents = await file.read()
        try:
            image = Image.open(BytesIO(contents)).convert("RGB")
        except UnidentifiedImageError:
            continue
        except Exception:
            continue

        image_np = np.array(image)
        crops = get_face_crops(image_np)

        for name, crop_img in crops:
            results = yolo_model(crop_img)[0]

            if results.boxes is not None:
                for box in results.boxes:
                    cls_idx = int(box.cls[0])
                    cls_name = yolo_model.names[cls_idx].capitalize()
                    if cls_name in counts:
                        counts[cls_name] += 1
                        total_detections += 1

            annotated_frame = results.plot() 
            cv2.rectangle(annotated_frame, (0, 0), (280, 40), (0, 0, 0), -1)
            cv2.putText(annotated_frame, name, (10, 30), cv2.FONT_HERSHEY_SIMPLEX, 1, (255, 255, 255), 2, cv2.LINE_AA)

            annotated_image = Image.fromarray(annotated_frame[..., ::-1])
            buffered = BytesIO()
            annotated_image.save(buffered, format="JPEG", quality=85)
            img_str = base64.b64encode(buffered.getvalue()).decode("utf-8")
            imageUrls.append(f"data:image/jpeg;base64,{img_str}")

    score = 10 + (counts['Blackhead'] + counts['Whitehead']) * 2 + (counts['Papule'] + counts['Pustule']) * 5 + counts['Nodule'] * 10
    if total_detections == 0:
        score = 0
    score = min(score, 100)

    level = "normal"
    if score >= 65:
        level = "severe"
    elif score >= 30:
        level = "moderate"

    classifications = []
    if total_detections > 0:
        for t, c in counts.items():
            if c > 0:
                pct = c / total_detections
                classifications.append({
                    "type": t,
                    "percentage": round(pct, 2),
                    "cause": ACNE_DATA[t]['cause'],
                    "description": ACNE_DATA[t]['description']
                })
    elif score > 0:
         classifications = []

    return {
        "id": f"real_{uuid.uuid4().hex[:8]}",
        "severityScore": int(score),
        "severityLevel": level,
        "classifications": classifications,
        "analyzedAt": datetime.datetime.now().isoformat() + "Z",
        "imageUrls": imageUrls
    }

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8000)