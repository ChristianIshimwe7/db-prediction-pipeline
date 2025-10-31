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