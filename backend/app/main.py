from fastapi import FastAPI, UploadFile, File, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from typing import List
import numpy as np
from PIL import Image, UnidentifiedImageError
from io import BytesIO
import uuid
import datetime

from app.model import get_model

app = FastAPI()

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

model = get_model()

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

@app.get("/")
def read_root():
    return {"status": "ok", "message": "Backend is running!"}

import cv2

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
        
    # 2. Joue Droite (de l'image)
    y1, y2 = max(0, y + int(h * 0.3)), min(img_h, y + int(h * 0.8))
    x1, x2 = max(0, x - int(w * 0.1)), min(img_w, x + int(w * 0.5))
    if y2 > y1 and x2 > x1:
        crops.append(("Joue Droite", image_np[y1:y2, x1:x2]))
        
    # 3. Joue Gauche (de l'image)
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

@app.post("/predict")
async def predict(files: List[UploadFile] = File(...)):
    import base64
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
            results = model(crop_img)[0]

            if results.boxes is not None:
                for box in results.boxes:
                    cls_idx = int(box.cls[0])
                    cls_name = model.names[cls_idx].capitalize()
                    if cls_name in counts:
                        counts[cls_name] += 1
                        total_detections += 1

            # Generate annotated image
            annotated_frame = results.plot() # Returns BGR numpy array
            
            # Ajouter le titre sur l'image
            cv2.rectangle(annotated_frame, (0, 0), (280, 40), (0, 0, 0), -1)
            cv2.putText(annotated_frame, name, (10, 30), cv2.FONT_HERSHEY_SIMPLEX, 1, (255, 255, 255), 2, cv2.LINE_AA)

            annotated_image = Image.fromarray(annotated_frame[..., ::-1]) # Convert BGR to RGB
            buffered = BytesIO()
            annotated_image.save(buffered, format="JPEG", quality=85)
            img_str = base64.b64encode(buffered.getvalue()).decode("utf-8")
            imageUrls.append(f"data:image/jpeg;base64,{img_str}")

    # Calcul du score de sévérité basé sur les détections
    score = 10 + (counts['Blackhead'] + counts['Whitehead']) * 2 + (counts['Papule'] + counts['Pustule']) * 5 + counts['Nodule'] * 10
    if total_detections == 0:
        score = 0
    score = min(score, 100)

    # Détermination du niveau de sévérité
    level = "normal"
    if score >= 65:
        level = "severe"
    elif score >= 30:
        level = "moderate"

    # Construction des classifications
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