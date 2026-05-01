import pickle
import pandas as pd

MODEL_PATH = r"C:\Users\asus\OneDrive\Desktop\PFE\prediction\model\modele_hermona_5000_20260415_221830 (1).pkl"

def inspect():
    try:
        with open(MODEL_PATH, 'rb') as f:
            model = pickle.load(f)
        
        print("--- Model Information ---")
        print(f"Type: {type(model)}")
        
        # Scikit-learn feature names
        for attr in ['feature_names_in_', 'feature_names', 'feature_importances_']:
            if hasattr(model, attr):
                val = getattr(model, attr)
                if attr == 'feature_importances_':
                    print(f"Has feature importances (Count: {len(val)})")
                else:
                    print(f"{attr}: {list(val)}")

        # If it's a Pipeline
        if hasattr(model, 'steps'):
            print("Steps:", [step[0] for step in model.steps])
            for name, step in model.steps:
                if hasattr(step, 'feature_names_in_'):
                    print(f"Step '{name}' features:", list(step.feature_names_in_))

        # Check if it's a XGBoost or LightGBM model
        if hasattr(model, 'feature_name'):
            print("XGB/LGB Features:", model.feature_name())

    except Exception as e:
        print(f"Error: {e}")

if __name__ == "__main__":
    inspect()