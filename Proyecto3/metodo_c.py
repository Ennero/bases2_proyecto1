from conexion import db

def info_mundial_por_anio(anio_buscado, filtro_grupo=None, filtro_pais=None, filtro_fecha=None):
    print(f"\n{'='*60}")
    print(f"   🏆 REPORTE DETALLADO: MUNDIAL {anio_buscado}")
    print(f"{'='*60}")

    # 1. Buscar el mundial y hacer JOIN con sus partidos
    pipeline = [
        { "$match": { "anio": anio_buscado } },
        {
            "$lookup": {
                "from": "partido",
                "localField": "anio",
                "foreignField": "anio",
                "as": "partidos"
            }
        }
    ]
    
    resultados = list(db.mundial.aggregate(pipeline))
    if not resultados:
        print(f"❌ No se encontró información para el año {anio_buscado}.")
        return

    mundial = resultados[0]
    
    # --- INFORMACIÓN GENERAL ---
    print("\n[ 📊 INFORMACIÓN GENERAL ]")
    print(f"📍 Sede: {mundial.get('sede')} | 👥 Equipos: {mundial.get('equipos')} | ⚽ Goles: {mundial.get('golesTotal')}")
    
    # --- PODIO ---
    podio = sorted([p for p in mundial.get('posicionFinals', []) if p.get('posicion') in [1,2,3]], key=lambda x: x['posicion'])
    if podio:
        print("\n[ 🥇 PODIO DEL MUNDIAL ]")
        for p in podio:
            sel = db.seleccion.find_one({"seleccionId": p['seleccionId']}, {"nombre": 1})
            nombre = sel['nombre'] if sel else f"ID {p['seleccionId']}"
            pos_icon = "🥇 Campeón" if p['posicion'] == 1 else "🥈 Subcampeón" if p['posicion'] == 2 else "🥉 Tercer Lugar"
            print(f"{pos_icon}: {nombre}")

    # --- FASE DE GRUPOS (Con Filtro Opcional) ---
    grupos = mundial.get('grupos', [])
    if filtro_grupo:
        grupos = [g for g in grupos if g.get('grupo', '').upper() == filtro_grupo.upper()]
    
    if grupos:
        print("\n[ 📋 FASE DE GRUPOS ]")
        for g in sorted(grupos, key=lambda x: (x.get('grupo',''), x.get('posicion',0))):
            sel = db.seleccion.find_one({"seleccionId": g['seleccionId']}, {"nombre": 1})
            nombre = sel['nombre'] if sel else f"ID {g['seleccionId']}"
            print(f"Grupo {g.get('grupo')} - Pos {g.get('posicion')}: {nombre.ljust(15)} (Pts: {g.get('pts')}, Dif: {g.get('dif')})")

    # --- PARTIDOS (Con Filtros Opcionales) ---
    partidos = mundial.get('partidos', [])
    pais_id_filtro = None
    
    # Si se filtró por país, buscamos su ID primero ignorando mayúsculas/minúsculas
    if filtro_pais:
        sel = db.seleccion.find_one({"nombre": {"$regex": f"^{filtro_pais}$", "$options": "i"}})
        if sel:
            pais_id_filtro = sel.get('seleccionId')
        else:
            print(f"\n⚠️ El país '{filtro_pais}' no existe o no participó.")

    partidos_filtrados = []
    for p in partidos:
        if filtro_fecha and filtro_fecha not in p.get('fecha', ''):
            continue
        if pais_id_filtro and (p.get('localSeleccionId') != pais_id_filtro and p.get('visitanteSeleccionId') != pais_id_filtro):
            continue
        partidos_filtrados.append(p)

    print(f"\n[ 🏟️ PARTIDOS JUGADOS ({len(partidos_filtrados)}) ]")
    for p in partidos_filtrados:
        local = db.seleccion.find_one({"seleccionId": p['localSeleccionId']}, {"nombre": 1})
        visit = db.seleccion.find_one({"seleccionId": p['visitanteSeleccionId']}, {"nombre": 1})
        nom_local = local['nombre'] if local else p['localSeleccionId']
        nom_visit = visit['nombre'] if visit else p['visitanteSeleccionId']
        
        print(f"🗓️  {p.get('fecha')} | [{p.get('etapa').ljust(10)}] {nom_local} ({p.get('golesLocal')}) vs ({p.get('golesVisitante')}) {nom_visit}")