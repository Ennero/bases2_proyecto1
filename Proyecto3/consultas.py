try:
    import os
    from pymongo import MongoClient
    import certifi # <-- 1. Importar certifi
    from dotenv import load_dotenv

    load_dotenv()
except ImportError:
    raise ImportError("Falta una librería. Ejecuta: pip install pymongo certifi python-dotenv")

# 2. Obtener URI del entorno
uri = os.getenv("MONGO_URI", "mongodb://localhost:27017/mundiales")
client = MongoClient(uri, tlsCAFile=certifi.where())

db = client["mundiales"]

# ==========================================
# 1. RESUMEN DE MUNDIALES (vw_resumen_mundial)
# ==========================================
def resumen_mundiales():
    print("\n=== RESUMEN MUNDIALES ===")
    mundiales = db.mundial.find({}, {"anio":1, "sede":1, "equipos":1, "partidosJugados":1, "golesTotal":1}, sort=[("anio", 1)])
    num = 1
    for m in mundiales:
        promedio = round(m.get("golesTotal", 0) / m.get("partidosJugados", 1), 2)
        print(f"{num}. {m.get('anio')} | {m.get('sede')} | Equipos: {m.get('equipos')} | "
              f"Partidos: {m.get('partidosJugados')} | Goles: {m.get('golesTotal')} | Promedio: {promedio}")
        num += 1
# ==========================================
# 2. CAMPEONES POR AÑO (campeones)
# ==========================================
def campeones():
    print("\n=== CAMPEONES ===")
    mundiales = db.mundial.find({}, {"anio":1, "posicionFinals":1}, sort=[("anio", 1)])
    for m in mundiales:
        for pf in m.get("posicionFinals", []):
            if pf.get("posicion") == 1:
                # Buscar nombre de la selección
                sel = db.seleccion.find_one({"seleccionId": pf.get("seleccionId")}, {"nombre":1})
                nombre = sel.get("nombre") if sel else pf.get("seleccionId")
                print(f"{m.get('anio')} | Campeón: {nombre}")

# ==========================================
# 3. GOLES POR JUGADOR EN TODOS LOS MUNDIALES (goles_hechos_mundiales)
# ==========================================
def goles_hechos_mundiales(top=20):
    print(f"\n=== TOP {top} GOLEADORES HISTÓRICOS ===")
    result = db.partido.aggregate([
        { "$unwind": "$gols" },
        { "$match": { "gols.jugadorId": { "$ne": None } } },
        { "$group": { "_id": "$gols.jugadorId", "cantidad_goles": { "$sum": 1 } } },
        { "$sort": { "cantidad_goles": -1 } },
        { "$limit": top }
    ])
    for r in result:
        jugador = db.jugador.find_one({"jugadorId": r["_id"]}, {"nombre":1})
        nombre = jugador.get("nombre") if jugador else r["_id"]
        print(f"{nombre} | Goles: {r['cantidad_goles']}")

# ==========================================
# 4. TABLA DE GRUPOS POR AÑO (tabla_grupos)
# ==========================================
def tabla_grupos(anio):
    print(f"\n=== TABLA DE GRUPOS {anio} ===")
    mundial = db.mundial.find_one({"anio": anio}, {"grupos":1})
    if not mundial:
        print("Mundial no encontrado")
        return
    grupos = sorted(mundial.get("grupos", []), key=lambda x: (x.get("grupo",""), x.get("posicion", 0)))
    num = 0
    for g in grupos:
        sel = db.seleccion.find_one({"seleccionId": g.get("seleccionId")}, {"nombre":1})
        nombre = sel.get("nombre") if sel else g.get("seleccionId")
        num += 1
        print(f"{num}. Grupo {g.get('grupo')} | Pos {g.get('posicion')} | {nombre} | "
              f"Pts:{g.get('pts')} GF:{g.get('gf')} GC:{g.get('gc')} Dif:{g.get('dif')} | "
              f"Clasificó: {'Sí' if g.get('clasificado') else 'No'}")

# ==========================================
# 5. RENDIMIENTO POR SELECCIÓN (rendimiento_seleccion)
# ==========================================
def rendimiento_seleccion(nombre_pais=None):
    print(f"\n=== RENDIMIENTO SELECCIONES ===")
    pipeline = [
        { "$unwind": "$participacionMundials" },
        { "$match": { "participacionMundials.participo": True } },
        { "$group": {
            "_id": "$seleccionId",
            "mundiales_jugados": { "$sum": 1 },
            "partidos_ganados": { "$sum": "$participacionMundials.pg" },
            "goles_favor":      { "$sum": "$participacionMundials.gf" },
            "goles_contra":     { "$sum": "$participacionMundials.gc" }
        }},
        { "$sort": { "mundiales_jugados": -1 } }
    ]
    result = db.seleccion.aggregate(pipeline)
    num = 1
    for r in result:
        sel = db.seleccion.find_one({"seleccionId": r["_id"]}, {"nombre":1})
        nombre = sel.get("nombre") if sel else r["_id"]
        if nombre_pais and nombre_pais.lower() not in nombre.lower():
            continue
        print(f"{num}. {nombre} | Mundiales: {r['mundiales_jugados']} | "
              f"PG: {r['partidos_ganados']} | GF: {r['goles_favor']} | GC: {r['goles_contra']}")
        num += 1

# ==========================================
# 6. CANTIDAD DE VECES GANADO/SEGUNDO/TERCERO
# ==========================================
def podios():
    print("\n=== PODIOS HISTÓRICOS ===")
    pipeline = [
        { "$unwind": "$posicionFinals" },
        { "$group": {
            "_id": "$posicionFinals.seleccionId",
            "totalGanador":  { "$sum": { "$cond": [{ "$eq": ["$posicionFinals.posicion", 1] }, 1, 0] } },
            "totalSegundo":  { "$sum": { "$cond": [{ "$eq": ["$posicionFinals.posicion", 2] }, 1, 0] } },
            "totalTercero":  { "$sum": { "$cond": [{ "$eq": ["$posicionFinals.posicion", 3] }, 1, 0] } }
        }},
        { "$sort": { "totalGanador": -1 } },
    ]
    result = db.mundial.aggregate(pipeline)
    num = 1
    for r in result:
        sel = db.seleccion.find_one({"seleccionId": r["_id"]}, {"nombre":1})
        nombre = sel.get("nombre") if sel else r["_id"]
        print(f"{num}. {nombre} | 1:{r['totalGanador']} 2:{r['totalSegundo']} 3:{r['totalTercero']}")
        num += 1
# ==========================================
# EJECUTAR TODAS
# ==========================================
if __name__ == "__main__":
    resumen_mundiales()
    campeones()
    goles_hechos_mundiales(top=10)
    tabla_grupos(2022)
    rendimiento_seleccion()
    podios()