# main.py
from fastapi import FastAPI, HTTPException
from pydantic import BaseModel
import mysql.connector
from mysql.connector import Error

app = FastAPI(title="Heart Disease Prediction API")

def get_db():
    try:
        conn = mysql.connector.connect(
            host="localhost",
            user="root",
            password="Ishichristian@1",
            database="heart_disease_db"
        )
        print("MySQL Connected!")
        return conn
    except Error as e:
        print(f"DB Error: {e}")
        raise HTTPException(status_code=500, detail=str(e))

class PatientIn(BaseModel):
    age: int
    sex: int
    cp: int
    trestbps: int
    chol: int
    fbs: int
    restecg: int
    thalach: int
    exang: int
    oldpeak: float
    slope: int
    ca: int
    thal: int

class PatientOut(PatientIn):
    patient_id: int
    created_at: str

@app.post("/patients/", response_model=PatientOut)
def create_patient(patient: PatientIn):
    conn = get_db()
    cur = conn.cursor()
    try:
        cur.callproc("sp_insert_patient", [
            patient.age, patient.sex, patient.cp, patient.trestbps,
            patient.chol, patient.fbs, patient.restecg, patient.thalach,
            patient.exang, patient.oldpeak, patient.slope, patient.ca, patient.thal
        ])
        conn.commit()
        cur.execute("SELECT LAST_INSERT_ID() AS patient_id, NOW() AS created_at")
        result = cur.fetchone()
        return {**patient.dict(), "patient_id": result[0], "created_at": result[1].strftime("%Y-%m-%d %H:%M:%S")}
    finally:
        cur.close()
        conn.close()

@app.get("/patients/latest")
def get_latest_patient():
    conn = get_db()
    cur = conn.cursor(dictionary=True)
    try:
        cur.execute("SELECT * FROM patients ORDER BY created_at DESC LIMIT 1")
        patient = cur.fetchone()
        if not patient:
            raise HTTPException(404, "No patients found")
        return patient
    finally:
        cur.close()
        conn.close()

@app.post("/predictions/")
def log_prediction(log: dict):
    conn = get_db()
    cur = conn.cursor()
    try:
        cur.execute("""
            INSERT INTO predictions (patient_id, prediction, probability, model_version)
            VALUES (%s, %s, %s, %s)
        """, (log['patient_id'], log['prediction'], log['probability'], log['model_version']))
        conn.commit()
        return {"message": "Prediction logged"}
    finally:
        cur.close()
        conn.close()