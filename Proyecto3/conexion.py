import os
from pymongo import MongoClient
import certifi
from dotenv import load_dotenv

load_dotenv()

# Centralizamos la conexión aquí para no repetir código
# Las variables de entorno deben estar en un archivo .env 
uri = os.getenv("MONGO_URI", "mongodb://localhost:27017/mundiales")
client = MongoClient(uri, tlsCAFile=certifi.where())
db = client["mundiales"]