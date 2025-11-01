#Setting up Mongo database
from pymongo import MongoClient

client = MongoClient("mongodb://localhost:27017/")
db = client.heart_disease_db

# Collections mimic relational structure but denormalized where useful
patients = db.patients
predictions = db.predictions
audit = db.audit_log

# Example: Embedded prediction in patient (optional hybrid)
# Or keep separate for scalability