# predict.py
import requests
import joblib
import pandas as pd
import numpy as np
from sklearn.preprocessing import StandardScaler
import os

# === CONFIG ===
API_URL = "http://localhost:8000"  # Change if deployed
MODEL_PATH = "heart_disease_model.pkl"
SCALER_PATH = "scaler.pkl"

# Feature order (MUST match training & DB)
FEATURES = ['age', 'sex', 'cp', 'trestbps', 'chol', 'fbs', 'restecg',
            'thalach', 'exang', 'oldpeak', 'slope', 'ca', 'thal']

# === 1. CREATE MODEL IF NOT EXISTS ===
def create_model_if_missing():
    if not os.path.exists(MODEL_PATH) or not os.path.exists(SCALER_PATH):
        print("Model or scaler not found. Creating from Heart Disease UCI dataset...")

        # Download dataset
        url = "https://archive.ics.uci.edu/ml/machine-learning-databases/heart-disease/processed.cleveland.data"
        df = pd.read_csv(url, header=None, na_values='?')
        df.columns = FEATURES + ['target']
        df = df.dropna()

        X = df[FEATURES]
        y = df['target'].apply(lambda x: 1 if x > 0 else 0)

        # Scale
        scaler = StandardScaler()
        X_scaled = scaler.fit_transform(X)

        # Train simple model
        from sklearn.linear_model import LogisticRegression
        model = LogisticRegression(max_iter=1000)
        model.fit(X_scaled, y)

        # Save
        joblib.dump(model, MODEL_PATH)
        joblib.dump(scaler, SCALER_PATH)
        print(f"Model saved: {MODEL_PATH}, {SCALER_PATH}")

create_model_if_missing()

# === 2. LOAD MODEL ===
model = joblib.load(MODEL_PATH)
scaler = joblib.load(SCALER_PATH)

# === 3. FETCH LATEST PATIENT ===
def fetch_latest():
    try:
        response = requests.get(f"{API_URL}/patients/latest")
        response.raise_for_status()
        return response.json()
    except requests.exceptions.RequestException as e:
        raise Exception(f"API Error: {e}")

# === 4. PREPROCESS ===
def preprocess(data):
    df = pd.DataFrame([data])[FEATURES]
    df = df.fillna(df.median(numeric_only=True))
    X = scaler.transform(df)
    return X

# === 5. PREDICT & LOG ===
def predict_and_log():
    patient = fetch_latest()
    X = preprocess(patient)

    prob = model.predict_proba(X)[0][1]
    pred = int(prob > 0.5)

    log_entry = {
        "patient_id": patient['patient_id'],
        "prediction": int(pred),
        "probability": round(float(prob), 4),
        "model_version": "v1.0"
    }

    try:
        resp = requests.post(f"{API_URL}/predictions/", json=log_entry)
        resp.raise_for_status()
        print(f"Prediction: {pred} (Prob: {prob:.2%}) → Logged to DB")
    except requests.exceptions.RequestException as e:
        print(f"Failed to log prediction: {e}")

if __name__ == "__main__":
    predict_and_log()