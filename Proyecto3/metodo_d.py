from conexion import db

def info_por_pais(nombre_pais, filtro_anio=None, filtro_etapa=None):
    print(f"\n{'='*60}")
    print(f"   🌍 EXPEDIENTE DE SELECCIÓN: {nombre_pais.upper()}")
    print(f"{'='*60}")

    # Búsqueda de selección ignorando mayúsculas/minúsculas
    seleccion = db.seleccion.find_one({"nombre": {"$regex": f"^{nombre_pais}$", "$options": "i"}})
    if not seleccion:
        print("❌ Selección no encontrada en la base de datos.")
        return
        
    sel_id = seleccion.get("seleccionId")
    
    # --- HISTORIAL COMO SEDE ---
    sedes = db.mundial.find({"sede": {"$regex": f"^{nombre_pais}$", "$options": "i"}}, {"anio": 1, "_id": 0})
    anios_sede = [s.get("anio") for s in sedes]
    print(f"🏟️ Ha sido país sede en: {', '.join(map(str, anios_sede)) if anios_sede else 'Nunca'}")

    # --- ESTADÍSTICAS GLOBALES ---
    participaciones = seleccion.get('participacionMundials', [])
    if filtro_anio:
        participaciones = [p for p in participaciones if p.get('anio') == filtro_anio]

    print(f"\n[ 📈 RENDIMIENTO HISTÓRICO ({len([p for p in participaciones if p.get('participo')])} mundiales jugados) ]")
    for part in participaciones:
        if part.get('participo'):
            print(f"🏆 Año {part.get('anio')} -> PJ: {part.get('pj')} | PG: {part.get('pg')} | PE: {part.get('pe')} | PP: {part.get('pp')} | GF: {part.get('gf')} | GC: {part.get('gc')}")

    # --- HISTORIAL DE PARTIDOS (Con Filtros Opcionales) ---
    query_partidos = {
        "$or": [
            {"localSeleccionId": sel_id},
            {"visitanteSeleccionId": sel_id}
        ]
    }
    if filtro_anio:
        query_partidos["anio"] = filtro_anio
    if filtro_etapa:
        query_partidos["etapa"] = {"$regex": f"^{filtro_etapa}$", "$options": "i"}

    partidos = list(db.partido.find(query_partidos).sort([("anio", 1), ("partidoId", 1)]))

    print(f"\n[ ⚽ HISTORIAL DE PARTIDOS ({len(partidos)} registrados) ]")
    for p in partidos:
        es_local = p['localSeleccionId'] == sel_id
        rival_id = p['visitanteSeleccionId'] if es_local else p['localSeleccionId']
        
        rival = db.seleccion.find_one({"seleccionId": rival_id}, {"nombre": 1})
        nom_rival = rival['nombre'] if rival else f"ID {rival_id}"
        
        goles_propios = p['golesLocal'] if es_local else p['golesVisitante']
        goles_rival = p['golesVisitante'] if es_local else p['golesLocal']
        
        # Determinar si ganó, perdió o empató visualmente
        resultado_simbolo = "✅ G" if goles_propios > goles_rival else "❌ P" if goles_propios < goles_rival else "➖ E"
        
        print(f"📅 {p.get('anio')} - {p.get('fecha')} [{p.get('etapa').ljust(10)}]: {resultado_simbolo} | vs {nom_rival.ljust(15)} ({goles_propios} - {goles_rival})")