from conexion import db

def info_mundial_por_anio(anio_buscado, filtro_grupo=None, filtro_pais=None, filtro_fecha=None):
    print(f"\n{'='*60}")
    print(f"   🏆 REPORTE DETALLADO: MUNDIAL {anio_buscado}")
    print(f"{'='*60}")

    # Buscar el mundial y hacer JOIN con sus partidos
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

    # ─────────────────────────────────────────────
    # 1. INFORMACIÓN GENERAL
    # ─────────────────────────────────────────────
    partidos_jugados = mundial.get('partidosJugados', len(mundial.get('partidos', [])))
    goles_total      = mundial.get('golesTotal', 0)
    promedio         = round(goles_total / partidos_jugados, 2) if partidos_jugados > 0 else 0

    print("\n[ 📊 INFORMACIÓN GENERAL ]")
    print(f"📍 Sede            : {mundial.get('sede')}")
    print(f"👥 Equipos         : {mundial.get('equipos')}")
    print(f"🏟️  Partidos jugados: {partidos_jugados}")
    print(f"⚽ Goles totales   : {goles_total}")
    print(f"📈 Promedio goles  : {promedio} por partido")

    # ─────────────────────────────────────────────
    # 2. PODIO
    # ─────────────────────────────────────────────
    podio = sorted(
        [p for p in mundial.get('posicionFinals', []) if p.get('posicion') in [1, 2, 3, 4]],
        key=lambda x: x['posicion']
    )
    if podio:
        print("\n[ 🥇 PODIO DEL MUNDIAL ]")
        iconos = {1: "🥇 Campeón    ", 2: "🥈 Subcampeón ", 3: "🥉 Tercer Lugar", 4: "4️⃣  Cuarto Lugar"}
        for p in podio:
            sel   = db.seleccion.find_one({"seleccionId": p['seleccionId']}, {"nombre": 1})
            nombre = sel['nombre'] if sel else f"ID {p['seleccionId']}"
            # Usando comillas simples para los diccionarios y el fallback
            print(f"{iconos.get(p['posicion'], 'Pos ' + str(p['posicion']))}: {nombre}")

    # ─────────────────────────────────────────────
    # 3. PREMIOS
    # ─────────────────────────────────────────────
    premios_jugador   = mundial.get('premioJugadors', [])
    premios_seleccion = mundial.get('premioSelecions', [])

    if premios_jugador or premios_seleccion:
        print("\n[ 🏅 PREMIOS DEL TORNEO ]")
        for pr in premios_jugador:
            jug = db.jugador.find_one({"jugadorId": pr.get('jugadorId')}, {"nombre": 1})
            nom_jug = jug['nombre'] if jug else f"ID {pr.get('jugadorId')}"
            sel = db.seleccion.find_one({"seleccionId": pr.get('seleccionId')}, {"nombre": 1})
            nom_sel = sel['nombre'] if sel else ""
            print(f"🏅 {pr.get('premio')}: {nom_jug} ({nom_sel})")
        for pr in premios_seleccion:
            sel = db.seleccion.find_one({"seleccionId": pr.get('seleccionId')}, {"nombre": 1})
            nom_sel = sel['nombre'] if sel else f"ID {pr.get('seleccionId')}"
            print(f"🏅 {pr.get('premio')}: {nom_sel}")

    # ─────────────────────────────────────────────
    # 5. FASE DE GRUPOS (con filtro opcional)
    # ─────────────────────────────────────────────
    grupos = mundial.get('grupos', [])
    if filtro_grupo:
        grupos = [g for g in grupos if g.get('grupo', '').upper() == filtro_grupo.upper()]

    if grupos:
        print("\n[ 📋 FASE DE GRUPOS ]")
        grupo_actual = None
        for g in sorted(grupos, key=lambda x: (x.get('grupo', ''), x.get('posicion', 0))):
            if g.get('grupo') != grupo_actual:
                grupo_actual = g.get('grupo')
                print(f"\n  Grupo {grupo_actual}")
                print(f"  {'Pos':<4} {'Selección':<20} {'PJ':<4} {'PG':<4} {'PE':<4} {'PP':<4} {'GF':<4} {'GC':<4} {'Dif':<5} {'Pts':<4} {'Clasif.'}")
                print(f"  {'-'*75}")
            sel    = db.seleccion.find_one({"seleccionId": g['seleccionId']}, {"nombre": 1})
            nombre = sel['nombre'] if sel else f"ID {g['seleccionId']}"
            clasif = "✅ Sí" if g.get('clasificado') else "❌ No"
            print(f"  {str(g.get('posicion')):<4} {nombre:<20} {str(g.get('pj','')):<4} {str(g.get('pg','')):<4} "
                f"{str(g.get('pe','')):<4} {str(g.get('pp','')):<4} {str(g.get('gf','')):<4} "
                f"{str(g.get('gc','')):<4} {str(g.get('dif','')):<5} {str(g.get('pts','')):<4} {clasif}")

    # ─────────────────────────────────────────────
    # 6. PARTIDOS (con filtros opcionales)
    # ─────────────────────────────────────────────
    partidos      = mundial.get('partidos', [])
    pais_id_filtro = None

    if filtro_pais:
        sel = db.seleccion.find_one({"nombre": {"$regex": f"^{filtro_pais}$", "$options": "i"}})
        if sel:
            pais_id_filtro = sel.get('seleccionId')
        else:
            print(f"\n⚠️ El país '{filtro_pais}' no existe o no participó en este mundial.")

    partidos_filtrados = []
    for p in partidos:
        if filtro_fecha and filtro_fecha not in p.get('fecha', ''):
            continue
        if pais_id_filtro and (p.get('localSeleccionId') != pais_id_filtro and
                            p.get('visitanteSeleccionId') != pais_id_filtro):
            continue
        partidos_filtrados.append(p)

    print(f"\n[ 🏟️ PARTIDOS JUGADOS ({len(partidos_filtrados)}) ]")
    for p in partidos_filtrados:
        local = db.seleccion.find_one({"seleccionId": p['localSeleccionId']},  {"nombre": 1})
        visit = db.seleccion.find_one({"seleccionId": p['visitanteSeleccionId']}, {"nombre": 1})
        nom_local = local['nombre'] if local else str(p['localSeleccionId'])
        nom_visit = visit['nombre'] if visit else str(p['visitanteSeleccionId'])

        gl = p.get('golesLocal', 0)
        gv = p.get('golesVisitante', 0)

        # Calcular ganador considerando penales
        if p.get('definicionPenales'):
            pl = p.get('penalesLocal', 0)
            pv = p.get('penalesVisitante', 0)
            ganador = f"⚡ Penales ({pl}-{pv})"
            if pl > pv:
                resultado = f"✅ {nom_local}"
            else:
                resultado = f"✅ {nom_visit}"
        elif gl > gv:
            resultado = f"✅ {nom_local}"
        elif gv > gl:
            resultado = f"✅ {nom_visit}"
        else:
            resultado = "➖ Empate"

        etapa = (p.get('etapa') or '').ljust(18)
        print(f"🗓️  {p.get('fecha')} | [{etapa}] {nom_local} ({gl}) vs ({gv}) {nom_visit}  →  {resultado}")