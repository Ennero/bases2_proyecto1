from pymongo import MongoClient
import certifi

# Centralizamos la conexión aquí para no repetir código
uri = "mongodb+srv://grupo3:PR3_G3@cluster0.1weo2z1.mongodb.net/mundiales?appName=Cluster0"
client = MongoClient(uri, tlsCAFile=certifi.where())
db = client["mundiales"]