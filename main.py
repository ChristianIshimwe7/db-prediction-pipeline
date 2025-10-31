from fastapi import FastAPI, HTTPException
import mysql.connector
from pydantic import BaseModel

app = FastAPI()

# Database connection
db = mysql.connector.connect(
    host="localhost",
    user="root",          # change if you use another username
    password="Karabarang@Eva123",
    database="heart_diseases_db"
)

cursor = db.cursor(dictionary=True)
class Patient(BaseModel):
    age: int
    sex: str
    chol: int
    thalach: int
    target: int

# CRUD endepoints for Patient records
@app.post("/patients/")
def create_patient(patient: Patient):
    sql = "INSERT INTO patients (age, sex, chol, thalach, target) VALUES (%s, %s, %s, %s, %s)"
    cursor.execute(sql, (patient.age, patient.sex, patient.chol, patient.thalach, patient.target))
    db.commit()
    return {"message": "Patient added successfully"} # Create operation

@app.get("/patients/")
def get_patients():
    cursor.execute("SELECT * FROM patients")
    return cursor.fetchall()  # Read operation


@app.put("/patients/{id}")
def update_patient(id: int, patient: Patient):
    sql = "UPDATE patients SET age=%s, sex=%s, chol=%s, thalach=%s, target=%s WHERE id=%s"
    cursor.execute(sql, (patient.age, patient.sex, patient.chol, patient.thalach, patient.target, id))
    db.commit()
    return {"message": "Patient updated successfully"}  # Update operation

@app.delete("/patients/{id}")
def delete_patient(id: int):
    cursor.execute("DELETE FROM patients WHERE id=%s", (id,))
    db.commit()
    return {"message": "Patient deleted successfully"}  # Delete operation

if __name__ == "__main__":
    app.run(debug=True)