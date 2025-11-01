from fastapi import FastAPI, HTTPException
from pydantic import BaseModel
from typing import Optional
import psycopg2
from psycopg2.extras import RealDictCursor

app = FastAPI(title="Heart Disease Prediction API")

# DB Connection
def get_db():
    conn = psycopg2.connect(
        host="localhost",
        user="root",
        password="xxxxxxx",
        database="heart_diseases_db"
    )
    return conn

# Pydantic Models
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

# CREATE
@app.post("/patients/", response_model=PatientOut)
def create_patient(patient: PatientIn):
    conn = get_db()
    cur = conn.cursor(cursor_factory=RealDictCursor)
    try:
        cur.callproc('sp_insert_patient', [
            patient.age, patient.sex, patient.cp, patient.trestbps,
            patient.chol, patient.fbs, patient.restecg, patient.thalach,
            patient.exang, patient.oldpeak, patient.slope, patient.ca, patient.thal
        ])
        result = cur.fetchone()
        conn.commit()
        return {**patient.dict(), "patient_id": result['patient_id'], "created_at": result['created_at']}
    except Exception as e:
        raise HTTPException(400, str(e))
    finally:
        cur.close()
        conn.close()

# READ (Latest)
@app.get("/patients/latest")
def get_latest_patient():
    conn = get_db()
    cur = conn.cursor(cursor_factory=RealDictCursor)
    cur.execute("""
        SELECT * FROM patients
        ORDER BY created_at DESC LIMIT 1
    """)
    patient = cur.fetchone()
    cur.close(); conn.close()
    if not patient:
        raise HTTPException(404, "No patients found")
    return patient

# UPDATE
@app.put("/patients/{patient_id}")
def update_patient(patient_id: int, patient: PatientIn):
    conn = get_db()
    cur = conn.cursor()
    cur.execute("""
        UPDATE patients SET age=%s, sex=%s, cp=%s, trestbps=%s, chol=%s,
        fbs=%s, restecg=%s, thalach=%s, exang=%s, oldpeak=%s, slope=%s, ca=%s, thal=%s
        WHERE patient_id=%s
    """, (patient.age, patient.sex, patient.cp, patient.trestbps, patient.chol,
          patient.fbs, patient.restecg, patient.thalach, patient.exang, patient.oldpeak,
          patient.slope, patient.ca, patient.thal, patient_id))
    conn.commit()
    if cur.rowcount == 0:
        raise HTTPException(404, "Patient not found")
    return {"message": "Updated"}

# DELETE
@app.delete("/patients/{patient_id}")
def delete_patient(patient_id: int):
    conn = get_db()
    cur = conn.cursor()
    cur.execute("DELETE FROM patients WHERE patient_id=%s", (patient_id,))
    conn.commit()
    if cur.rowcount == 0:
        raise HTTPException(404, "Patient not found")
    return {"message": "Deleted"}