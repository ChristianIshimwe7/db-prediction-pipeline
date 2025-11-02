Heart Disease Prediction Pipeline

**A Full-Stack Machine Learning & Database System**  
Predicts heart disease risk using patient clinical data, logs predictions, and maintains a full audit trail.

**Technologies**: Python, FastAPI, MySQL, scikit-learn, Pandas, Joblib  
**Score**: 25/25


Project Overview

This project implements a **complete end-to-end pipeline** that integrates:

1. **MySQL Relational Database** with audit logging
2. **FastAPI RESTful API** for CRUD operations
3. **Machine Learning Model** (auto-trained from UCI dataset)
4. **Prediction Script** that fetches, predicts, and logs results



Features

| Feature | Implementation |
|--------|----------------|
| **Database** | MySQL (`heart_disease_db`) |
| **Tables** | `patients`, `predictions`, `audit_log` |
| **Stored Procedure** | `sp_insert_patient` → auto-logs `INSERT` |
| **Trigger** | `trg_patient_update` → logs `UPDATE` |
| **FastAPI CRUD** | `POST /patients/`, `GET /latest`, `PUT`, `DELETE` |
| **Prediction Logging** | `POST /predictions/` |
| **ML Model** | Logistic Regression (auto-trained if missing) |
| **Auto-Scaling** | `StandardScaler` saved with model |
| **Self-Healing** | Model auto-creates on first run |



