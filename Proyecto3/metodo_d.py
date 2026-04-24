from conexion import db

def info_por_pais(nombre_pais, filtro_anio=None, filtro_etapa=None):
    print(f"\n{'='*60}")
    print(f"   🌍 EXPEDIENTE DE SELECCIÓN: {nombre_pais.upper()}")
    print(f"{'='*60}")

    # Búsqueda ignorando mayúsculas/minúsculas
    seleccion = db.seleccion.find_one(
        {"nombre": {"$regex": f"^{nombre_pais}$", "$options": "i"}}
    )
    if not seleccion:
        print("❌ Selección no encontrada en la base de datos.")
        return

    sel_id = seleccion.get("seleccionId")

    # ─────────────────────────────────────────────
    # 1. HISTORIAL COMO SEDE
    # ─────────────────────────────────────────────
    sedes      = db.mundial.find({"sede": {"$regex": nombre_pais, "$options": "i"}}, {"anio": 1, "_id": 0})
    anios_sede = [s.get("anio") for s in sedes]
    print(f"\n🏟️  Sede del mundial : {', '.join(map(str, anios_sede)) if anios_sede else 'Nunca'}")

    # ─────────────────────────────────────────────
    # 2. RESUMEN ACUMULADO HISTÓRICO
    # ─────────────────────────────────────────────
    participaciones = seleccion.get('participacionMundials', [])
    if filtro_anio:
        participaciones = [p for p in participaciones if p.get('anio') == filtro_anio]

    solo_jugados = [p for p in participaciones if p.get('participo')]

    total_pj = sum(p.get('pj', 0) for p in solo_jugados)
    total_pg = sum(p.get('pg', 0) for p in solo_jugados)
    total_pe = sum(p.get('pe', 0) for p in solo_jugados)
    total_pp = sum(p.get('pp', 0) for p in solo_jugados)
    total_gf = sum(p.get('gf', 0) for p in solo_jugados)
    total_gc = sum(p.get('gc', 0) for p in solo_jugados)

    # Mejor resultado: la participacion con menor numero de posicion
    mejor = None
    for p in solo_jugados:
        pos = p.get('posicion')
        if pos and (mejor is None or pos < mejor.get('posicion', 999)):
            mejor = p

    print(f"\n[ 📊 RESUMEN HISTÓRICO ACUMULADO ]")
    print(f"🌍 Mundiales jugados : {len(solo_jugados)}")
    print(f"⚽ Partidos          : {total_pj} jugados | {total_pg} ganados | {total_pe} empatados | {total_pp} perdidos")
    print(f"🥅 Goles             : {total_gf} a favor | {total_gc} en contra | dif: {total_gf - total_gc:+d}")
    if mejor:
        print(f"🏆 Mejor resultado   : Posición {mejor.get('posicion')} en {mejor.get('anio')} ({mejor.get('etapa', '')})")

    # ─────────────────────────────────────────────
    # 3. RENDIMIENTO POR EDICIÓN
    # ─────────────────────────────────────────────
    print(f"\n[ 📈 RENDIMIENTO POR EDICIÓN ]")
    print(f"  {'Año':<6} {'Etapa alcanzada':<25} {'PJ':<4} {'PG':<4} {'PE':<4} {'PP':<4} {'GF':<4} {'GC':<4} {'Pos'}")
    print(f"  {'-'*70}")
    for part in sorted(solo_jugados, key=lambda x: x.get('anio', 0)):
        etapa = (part.get('etapa') or 'N/D')[:24]
        pos   = part.get('posicion', '-')
        print(f"  {str(part.get('anio')):<6} {etapa:<25} {str(part.get('pj','')):<4} {str(part.get('pg','')):<4} "
            f"{str(part.get('pe','')):<4} {str(part.get('pp','')):<4} {str(part.get('gf','')):<4} "
            f"{str(part.get('gc','')):<4} {pos}")

    # ─────────────────────────────────────────────
    # 4. INFORMACIÓN DE GRUPOS POR EDICIÓN
    # ─────────────────────────────────────────────
    anios_participados = [p.get('anio') for p in solo_jugados]
    query_mundiales    = {"anio": {"$in": anios_participados}, "grupos.seleccionId": sel_id}
    if filtro_anio:
        query_mundiales["anio"] = filtro_anio

    mundiales_con_grupos = list(db.mundial.find(query_mundiales, {"anio": 1, "grupos": 1, "_id": 0}))

    if mundiales_con_grupos:
        print(f"\n[ 📋 DESEMPEÑO EN FASE DE GRUPOS ]")
        print(f"  {'Año':<6} {'Grupo':<7} {'Pos':<4} {'PJ':<4} {'PG':<4} {'PE':<4} {'PP':<4} {'GF':<4} {'GC':<4} {'Pts':<4} {'Clasif.'}")
        print(f"  {'-'*70}")
        for m in sorted(mundiales_con_grupos, key=lambda x: x.get('anio', 0)):
            for g in m.get('grupos', []):
                if g.get('seleccionId') == sel_id:
                    clasif = "✅ Sí" if g.get('clasificado') else "❌ No"
                    print(f"  {str(m.get('anio')):<6} {str(g.get('grupo','')):<7} {str(g.get('posicion','')):<4} "
                        f"{str(g.get('pj','')):<4} {str(g.get('pg','')):<4} {str(g.get('pe','')):<4} "
                        f"{str(g.get('pp','')):<4} {str(g.get('gf','')):<4} {str(g.get('gc','')):<4} "
                        f"{str(g.get('pts','')):<4} {clasif}")

    # ─────────────────────────────────────────────
    # 5. GOLEADORES HISTÓRICOS DEL PAÍS (top 5)
    # ─────────────────────────────────────────────
    pipeline_goles = [
        { "$unwind": "$gols" },
        { "$match": {
            "gols.seleccionId": sel_id,
            "gols.jugadorId":   {"$ne": None},
            "gols.esAutogol":   {"$ne": True}
        }},
        { "$group": {
            "_id":          "$gols.jugadorId",
            "total_goles":  {"$sum": 1},
            "anios":        {"$addToSet": "$anio"}
        }},
        { "$sort": {"total_goles": -1} },
        { "$limit": 5 }
    ]
    goleadores = list(db.partido.aggregate(pipeline_goles))

    if goleadores:
        print(f"\n[ 🥇 TOP GOLEADORES HISTÓRICOS ]")
        for i, g in enumerate(goleadores, 1):
            jug = db.jugador.find_one({"jugadorId": g['_id']}, {"nombre": 1})
            nom = jug['nombre'] if jug else f"ID {g['_id']}"
            anios_str = ', '.join(str(a) for a in sorted(g.get('anios', [])))
            print(f"  {i}. {nom.ljust(22)} — {g['total_goles']} goles  (mundiales: {anios_str})")

    # ─────────────────────────────────────────────
    # 6. HISTORIAL DE PARTIDOS (con filtros opcionales)
    # ─────────────────────────────────────────────
    query_partidos = {
        "$or": [
            {"localSeleccionId":    sel_id},
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
        es_local  = p['localSeleccionId'] == sel_id
        rival_id  = p['visitanteSeleccionId'] if es_local else p['localSeleccionId']

        rival     = db.seleccion.find_one({"seleccionId": rival_id}, {"nombre": 1})
        nom_rival = rival['nombre'] if rival else f"ID {rival_id}"

        goles_propios = p['golesLocal']    if es_local else p['golesVisitante']
        goles_rival   = p['golesVisitante'] if es_local else p['golesLocal']

        # Resultado considerando penales
        if p.get('definicionPenales'):
            pl = p.get('penalesLocal', 0)
            pv = p.get('penalesVisitante', 0)
            gano_local = pl > pv
            gano_yo    = gano_local if es_local else not gano_local
            simbolo    = f"✅ G (pen)" if gano_yo else f"❌ P (pen)"
        elif goles_propios > goles_rival:
            simbolo = "✅ G"
        elif goles_propios < goles_rival:
            simbolo = "❌ P"
        else:
            simbolo = "➖ E"

        etapa = (p.get('etapa') or '').ljust(18)
        cond  = "🏠 Local" if es_local else "✈️  Visita"
        print(f"📅 {p.get('anio')} {p.get('fecha',''):<14} [{etapa}] {cond} | {simbolo} | "
            f"vs {nom_rival.ljust(18)} ({goles_propios}-{goles_rival})")