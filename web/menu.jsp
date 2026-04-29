<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="modelo.Usuario" %>
<%
    // Guard de sesión
    Usuario usuarioActual = (Usuario) session.getAttribute("usuario");
    if (usuarioActual == null) {
        response.sendRedirect(request.getContextPath() + "/login");
        return;
    }
    String nombreUsuario = usuarioActual.getNombre();
    if (nombreUsuario == null || nombreUsuario.trim().isEmpty()) nombreUsuario = "Estudiante";
    String inicial = nombreUsuario.substring(0, 1).toUpperCase();
%>
<!DOCTYPE html>
<html lang="es">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>SEAEA – Mapa de Escenarios</title>
    <link href="https://fonts.googleapis.com/css2?family=Baloo+2:wght@700;800;900&family=Nunito:wght@400;600;700;800;900&display=swap" rel="stylesheet">
    <style>
        :root {
            --bg:        #e8eaf0;
            --card-bg:   #ffffff;
            --green:     #3a7d44;
            --blue:      #4a90d9;
            --pink:      #e05c97;
            --yellow:    #f5a623;
            --gray-lt:   #f5f5f5;
            --teal:      #26a69a;
            --purple:    #7c5cbf;
            --text-dark: #2c2c3e;
            --text-mid:  #555568;
            --text-soft: #8888a0;
            --radius:    18px;
            --shadow:    0 4px 18px rgba(0,0,0,.10);
        }

        * { box-sizing: border-box; margin: 0; padding: 0; }

        body {
            font-family: 'Nunito', sans-serif;
            background: var(--bg);
            min-height: 100vh;
            color: var(--text-dark);
        }

        /* ══ HEADER ══ */
        header {
            background: #ffffff;
            box-shadow: 0 2px 16px rgba(0,0,0,.08);
            padding: 0 40px;
            height: 70px;
            display: flex;
            align-items: center;
            justify-content: space-between;
            position: sticky;
            top: 0;
            z-index: 200;
        }

        .logo-wrap { display: flex; flex-direction: column; line-height: 1; }
        .logo-text {
            font-family: 'Baloo 2', cursive;
            font-size: 2rem;
            font-weight: 900;
            background: linear-gradient(135deg, var(--green) 0%, var(--blue) 100%);
            -webkit-background-clip: text;
            -webkit-text-fill-color: transparent;
            background-clip: text;
            letter-spacing: -1px;
        }
        .logo-badge {
            font-size: .58rem;
            font-weight: 800;
            text-transform: uppercase;
            letter-spacing: .8px;
            color: var(--text-soft);
        }

        .user-info {
            display: flex;
            align-items: center;
            gap: 10px;
            font-size: .88rem;
            color: var(--text-mid);
        }
        .user-name { font-weight: 800; color: var(--text-dark); }
        .user-avatar {
            width: 40px; height: 40px;
            border-radius: 50%;
            background: linear-gradient(135deg, var(--green), var(--blue));
            display: flex; align-items: center; justify-content: center;
            color: #fff;
            font-weight: 900;
            font-size: 1.1rem;
            box-shadow: 0 2px 10px rgba(58,125,68,.35);
            flex-shrink: 0;
        }

        /* ══ BANNER MASCOTA ══ */
        .mascota-banner {
            background: linear-gradient(135deg, #1a3a2a 0%, #1e3a5f 100%);
            padding: 26px 40px;
            display: flex;
            align-items: center;
            gap: 24px;
            position: relative;
            overflow: hidden;
        }
        /* Burbujas decorativas de fondo */
        .mascota-banner::before {
            content: '';
            position: absolute;
            top: -50px; right: -50px;
            width: 200px; height: 200px;
            border-radius: 50%;
            background: rgba(74,144,217,.08);
            pointer-events: none;
        }
        .mascota-banner::after {
            content: '';
            position: absolute;
            bottom: -70px; left: 35%;
            width: 280px; height: 280px;
            border-radius: 50%;
            background: rgba(58,125,68,.07);
            pointer-events: none;
        }

        /* Partículas flotantes */
        .part {
            position: absolute;
            border-radius: 50%;
            opacity: .3;
            animation: flotar 5s ease-in-out infinite;
            pointer-events: none;
        }
        .part:nth-child(1){ width:11px;height:11px;background:var(--blue);  top:22%;right:12%;animation-delay:0s;   }
        .part:nth-child(2){ width:7px; height:7px; background:var(--pink);  top:55%;right:22%;animation-delay:1.5s; }
        .part:nth-child(3){ width:9px; height:9px; background:var(--yellow);top:28%;right:6%; animation-delay:3s;   }
        @keyframes flotar {
            0%,100%{ transform:translateY(0); }
            50%    { transform:translateY(-10px); }
        }

        /* Imagen de la mascota */
        .mascota-img-wrap {
            position: relative;
            flex-shrink: 0;
            cursor: pointer;
        }
        .mascota-img,
        .mascota-fallback {
            width: 88px; height: 88px;
            border-radius: 50%;
            border: 3px solid rgba(255,255,255,.22);
            box-shadow: 0 4px 22px rgba(0,0,0,.45);
            object-fit: cover;
            transition: transform .3s;
            display: block;
        }
        .mascota-fallback {
            background: linear-gradient(135deg,#2d6a4f,#1e3a5f);
            font-size: 2.8rem;
            display: none;
            align-items: center;
            justify-content: center;
        }
        .mascota-img-wrap:hover .mascota-img,
        .mascota-img-wrap:hover .mascota-fallback {
            transform: scale(1.09) rotate(-4deg);
        }

        /* Punto de estado activo */
        .mascota-dot {
            position: absolute;
            bottom: 5px; right: 5px;
            width: 14px; height: 14px;
            background: #4cdd7a;
            border-radius: 50%;
            border: 2px solid #1a3a2a;
            animation: pulse-dot 2.2s infinite;
        }
        @keyframes pulse-dot {
            0%,100%{ box-shadow: 0 0 0 0 rgba(76,221,122,.45); }
            50%    { box-shadow: 0 0 0 7px rgba(76,221,122,0); }
        }

        /* Tooltip sobre la mascota */
        .mascota-tooltip {
            position: absolute;
            bottom: calc(100% + 12px);
            left: 50%;
            transform: translateX(-50%) scale(.88);
            background: #ffffff;
            color: var(--text-dark);
            font-size: .8rem;
            font-weight: 800;
            padding: 8px 14px;
            border-radius: 10px;
            white-space: nowrap;
            box-shadow: 0 4px 18px rgba(0,0,0,.2);
            opacity: 0;
            pointer-events: none;
            transition: opacity .2s, transform .2s;
            z-index: 10;
        }
        .mascota-tooltip::after {
            content: '';
            position: absolute;
            top: 100%; left: 50%;
            transform: translateX(-50%);
            border: 6px solid transparent;
            border-top-color: #ffffff;
        }
        .mascota-img-wrap:hover .mascota-tooltip {
            opacity: 1;
            transform: translateX(-50%) scale(1);
        }

        /* Texto del banner */
        .mascota-texto { flex: 1; z-index: 1; }
        .mascota-nombre {
            font-family: 'Baloo 2', cursive;
            font-size: .95rem;
            font-weight: 800;
            color: #4cdd7a;
            letter-spacing: .5px;
            margin-bottom: 5px;
        }
        .mascota-mensaje {
            font-size: 1.05rem;
            font-weight: 700;
            color: #e8f4ff;
            line-height: 1.5;
            max-width: 580px;
        }
        .mascota-mensaje .hi  { color: #7dd3fc; }
        .mascota-mensaje .em  { color: #fde68a; }

        /* ══ MAIN ══ */
        main {
            max-width: 1160px;
            margin: 0 auto;
            padding: 40px 24px 80px;
        }
        .page-title {
            font-family: 'Baloo 2', cursive;
            font-size: 1.8rem;
            font-weight: 900;
            color: var(--text-dark);
            margin-bottom: 4px;
        }
        .page-subtitle {
            font-size: .95rem;
            color: var(--text-soft);
            margin-bottom: 36px;
        }

        /* ══ GRID ══ */
        .scenarios-grid {
            display: grid;
            grid-template-columns: repeat(auto-fill, minmax(320px, 1fr));
            gap: 28px;
        }

        /* ══ CARD ══ */
        .card {
            background: var(--card-bg);
            border-radius: var(--radius);
            box-shadow: var(--shadow);
            overflow: hidden;
            display: flex;
            flex-direction: column;
            transition: transform .2s, box-shadow .2s;
        }
        .card:hover {
            transform: translateY(-5px);
            box-shadow: 0 12px 36px rgba(0,0,0,.14);
        }
        .card-band { height: 8px; }
        .card-body {
            padding: 24px 24px 20px;
            flex: 1;
            display: flex;
            flex-direction: column;
            gap: 12px;
        }
        .card-num {
            font-size: .75rem;
            font-weight: 800;
            text-transform: uppercase;
            letter-spacing: 1px;
            color: var(--text-soft);
        }
        .card-title {
            font-family: 'Baloo 2', cursive;
            font-size: 1.28rem;
            font-weight: 800;
            color: var(--text-dark);
            line-height: 1.2;
            margin-top: 2px;
        }
        .card-topic {
            font-size: .82rem;
            color: var(--text-soft);
            font-weight: 600;
        }
        .card-illustration {
            background: var(--gray-lt);
            border-radius: 12px;
            height: 110px;
            display: flex;
            align-items: center;
            justify-content: center;
        }
        .card-objective-label { font-size: .8rem; font-weight: 800; color: var(--text-dark); }
        .card-objective-text  { font-size: .88rem; color: var(--text-mid); line-height: 1.55; }
        .card-footer {
            padding: 16px 24px 20px;
            border-top: 1px solid #f0f0f5;
            display: flex;
            align-items: center;
            justify-content: space-between;
        }
        .card-hint { font-size: .8rem; color: var(--text-soft); }

        .btn {
            border: none; cursor: pointer;
            border-radius: 50px;
            font-family: 'Nunito', sans-serif;
            font-weight: 800; font-size: .9rem;
            padding: 10px 26px;
            transition: filter .15s, transform .1s;
            text-decoration: none;
            display: inline-block;
        }
        .btn:hover  { filter: brightness(1.1); }
        .btn:active { transform: scale(.97); }
        .btn-green  { background: var(--green);  color: #fff; }
        .btn-blue   { background: var(--blue);   color: #fff; }
        .btn-pink   { background: var(--pink);   color: #fff; }
        .btn-yellow { background: var(--yellow); color: #fff; }
        .btn-teal   { background: var(--teal);   color: #fff; }
        .btn-purple { background: var(--purple); color: #fff; }

        svg.ilu { width:90px; height:90px; }
        .orb { fill:none; stroke:#c8d8e8; stroke-width:1.5; }
        .p   { fill:var(--blue); }
        .n   { fill:var(--yellow); }
        .e   { fill:var(--pink); }
        .nu  { fill:#ddeeff; stroke:#b0ccee; stroke-width:1.5; }
    </style>
</head>
<body>

<!-- ══ HEADER ══ -->
<header>
    <div class="logo-wrap">
        <span class="logo-text">SEAEA</span>
        <span class="logo-badge">Estructura Atómica · Amazonia</span>
    </div>
    <div class="user-info">
        <span>Hola, <span class="user-name"><%= nombreUsuario %></span></span>
        <div class="user-avatar"><%= inicial %></div>
    </div>
</header>

<!-- ══ BANNER MASCOTA ══ -->
<div class="mascota-banner">
    <div class="part"></div>
    <div class="part"></div>
    <div class="part"></div>

    <div class="mascota-img-wrap">
        <%-- Intenta cargar la imagen real; si no existe muestra el emoji --%>
        <img class="mascota-img"
             src="${pageContext.request.contextPath}/img/amazonatom.png"
             alt="Amazonatom"
             onerror="this.style.display='none';
                      document.getElementById('mfallback').style.display='flex';">
        <div id="mfallback" class="mascota-fallback">🦜</div>
        <div class="mascota-dot"></div>
        <div class="mascota-tooltip">¡Hola! Soy Amazonatom 👋</div>
    </div>

    <div class="mascota-texto">
        <div class="mascota-nombre">✦ Amazonatom</div>
        <div class="mascota-mensaje">
            ¡Hola, <span class="hi"><%= nombreUsuario %>!</span>
            Soy tu guía en el aprendizaje de la
            <span class="em">estructura atómica</span>.
            Elige un escenario y comencemos a explorar el fascinante universo de los átomos. 🧪⚛️
        </div>
    </div>
</div>

<!-- ══ MAIN ══ -->
<main>
    <p class="page-title">🗺️ Mapa de Escenarios</p>
    <p class="page-subtitle">Explora la estructura atómica paso a paso. Cada escenario desbloquea nuevos conceptos.</p>

    <div class="scenarios-grid">

        <!-- ESCENARIO 1 -->
        <div class="card">
            <div class="card-band" style="background:var(--green);"></div>
            <div class="card-body">
                <div>
                    <div class="card-num">Escenario 1</div>
                    <div class="card-title">Arma tu Átomo</div>
                    <div class="card-topic">Electrones, protones y neutrones</div>
                </div>
                <div class="card-illustration">
                    <svg class="ilu" viewBox="0 0 90 90" xmlns="http://www.w3.org/2000/svg">
                        <circle cx="45" cy="45" r="28" class="orb"/>
                        <circle cx="45" cy="45" r="16" class="orb"/>
                        <circle cx="45" cy="45" r="11" class="nu"/>
                        <circle cx="41" cy="43" r="4" class="p"/>
                        <circle cx="49" cy="43" r="4" class="p"/>
                        <circle cx="45" cy="49" r="4" class="n"/>
                        <circle cx="45" cy="17" r="4" class="e"/>
                        <circle cx="17" cy="45" r="4" class="e"/>
                        <circle cx="73" cy="45" r="4" class="e"/>
                    </svg>
                </div>
                <div>
                    <div class="card-objective-label">Objetivo</div>
                    <div class="card-objective-text">Construir átomos modificando protones, neutrones y electrones, visualizando la estructura nuclear y las capas electrónicas.</div>
                </div>
            </div>
            <div class="card-footer">
                <span class="card-hint">Disponible para jugar ahora</span>
                <a class="btn btn-green" href="${pageContext.request.contextPath}/escenario1">Entrar →</a>
            </div>
        </div>

        <!-- ESCENARIO 2 -->
        <div class="card">
            <div class="card-band" style="background:var(--blue);"></div>
            <div class="card-body">
                <div>
                    <div class="card-num">Escenario 2</div>
                    <div class="card-title">Núcleo y Número Atómico</div>
                    <div class="card-topic">Núcleo atómico y número atómico</div>
                </div>
                <div class="card-illustration">
                    <svg class="ilu" viewBox="0 0 90 90" xmlns="http://www.w3.org/2000/svg">
                        <circle cx="45" cy="45" r="22" class="nu" stroke-width="2"/>
                        <circle cx="38" cy="40" r="5" class="p"/>
                        <circle cx="52" cy="40" r="5" class="p"/>
                        <circle cx="45" cy="40" r="5" class="p"/>
                        <circle cx="38" cy="51" r="5" class="n"/>
                        <circle cx="52" cy="51" r="5" class="n"/>
                        <text x="45" y="80" text-anchor="middle" font-family="Nunito" font-size="11" fill="#4a90d9" font-weight="800">Z = protones</text>
                    </svg>
                </div>
                <div>
                    <div class="card-objective-label">Objetivo</div>
                    <div class="card-objective-text">Comprender el núcleo atómico y calcular el número atómico a partir de la cantidad de protones.</div>
                </div>
            </div>
            <div class="card-footer">
                <span class="card-hint">Disponible para jugar ahora</span>
                <a class="btn btn-blue" href="${pageContext.request.contextPath}/escenario2">Entrar →</a>
            </div>
        </div>

        <!-- ESCENARIO 3 -->
        <div class="card">
            <div class="card-band" style="background:var(--pink);"></div>
            <div class="card-body">
                <div>
                    <div class="card-num">Escenario 3</div>
                    <div class="card-title">Iones y Formación de Iones</div>
                    <div class="card-topic">Cationes y aniones</div>
                </div>
                <div class="card-illustration">
                    <svg class="ilu" viewBox="0 0 90 90" xmlns="http://www.w3.org/2000/svg">
                        <circle cx="45" cy="45" r="26" class="orb"/>
                        <circle cx="45" cy="45" r="14" class="nu"/>
                        <circle cx="41" cy="42" r="4" class="p"/>
                        <circle cx="49" cy="42" r="4" class="p"/>
                        <circle cx="45" cy="49" r="4" fill="#f5a623"/>
                        <circle cx="45" cy="19" r="4" class="e"/>
                        <circle cx="19" cy="45" r="4" class="e"/>
                        <text x="71" y="22" font-family="Nunito" font-size="14" fill="#e05c97" font-weight="900">+</text>
                        <text x="68" y="72" font-family="Nunito" font-size="14" fill="#4a90d9" font-weight="900">−</text>
                    </svg>
                </div>
                <div>
                    <div class="card-objective-label">Objetivo</div>
                    <div class="card-objective-text">Comprender cómo se forman iones cuando un átomo gana o pierde electrones, y cómo cambia su carga neta.</div>
                </div>
            </div>
            <div class="card-footer">
                <span class="card-hint">Disponible para jugar ahora</span>
                <a class="btn btn-pink" href="${pageContext.request.contextPath}/escenario3">Entrar →</a>
            </div>
        </div>

        <!-- ESCENARIO 4 -->
        <div class="card">
            <div class="card-band" style="background:var(--yellow);"></div>
            <div class="card-body">
                <div>
                    <div class="card-num">Escenario 4</div>
                    <div class="card-title">Configura tu Isótopo</div>
                    <div class="card-topic">Número másico, isótopos y abundancia isotópica</div>
                </div>
                <div class="card-illustration">
                    <svg class="ilu" viewBox="0 0 90 90" xmlns="http://www.w3.org/2000/svg">
                        <ellipse cx="28" cy="45" rx="18" ry="18" fill="#fff8e1" stroke="#f5a623" stroke-width="1.5"/>
                        <circle cx="24" cy="42" r="4" class="p"/>
                        <circle cx="32" cy="42" r="4" class="p"/>
                        <circle cx="28" cy="49" r="4" fill="#f5a623"/>
                        <text x="28" y="72" text-anchor="middle" font-family="Nunito" font-size="9" fill="#555" font-weight="700">He-3</text>
                        <ellipse cx="62" cy="45" rx="20" ry="20" fill="#fff8e1" stroke="#f5a623" stroke-width="1.5"/>
                        <circle cx="57" cy="41" r="4" class="p"/>
                        <circle cx="67" cy="41" r="4" class="p"/>
                        <circle cx="57" cy="49" r="4" fill="#f5a623"/>
                        <circle cx="67" cy="49" r="4" fill="#f5a623"/>
                        <text x="62" y="74" text-anchor="middle" font-family="Nunito" font-size="9" fill="#555" font-weight="700">He-4</text>
                    </svg>
                </div>
                <div>
                    <div class="card-objective-label">Objetivo</div>
                    <div class="card-objective-text">Diferenciar número atómico y número másico, y reconocer cómo surgen los isótopos al variar los neutrones.</div>
                </div>
            </div>
            <div class="card-footer">
                <span class="card-hint">Disponible para jugar ahora</span>
                <a class="btn btn-yellow" href="${pageContext.request.contextPath}/escenario4">Entrar →</a>
            </div>
        </div>

        <!-- ESCENARIO 5 -->
        <div class="card">
            <div class="card-band" style="background:var(--teal);"></div>
            <div class="card-body">
                <div>
                    <div class="card-num">Escenario 5</div>
                    <div class="card-title">Configuración Electrónica</div>
                    <div class="card-topic">Configuración electrónica y tabla periódica</div>
                </div>
                <div class="card-illustration">
                    <svg class="ilu" viewBox="0 0 90 90" xmlns="http://www.w3.org/2000/svg">
                        <rect x="10" y="72" width="70" height="8" rx="4" fill="#e0f2f1"/>
                        <rect x="10" y="72" width="42" height="8" rx="4" fill="#26a69a"/>
                        <text x="14" y="79" font-family="Nunito" font-size="8" fill="#fff" font-weight="700">1s² 2s² 2p⁶</text>
                        <circle cx="45" cy="38" r="24" class="orb" stroke="#26a69a"/>
                        <circle cx="45" cy="38" r="14" class="orb" stroke="#26a69a"/>
                        <circle cx="45" cy="38" r="8" fill="#e0f2f1" stroke="#26a69a" stroke-width="1.5"/>
                        <circle cx="45" cy="38" r="3" fill="#26a69a"/>
                        <circle cx="45" cy="14" r="3.5" fill="#26a69a" opacity=".9"/>
                        <circle cx="45" cy="62" r="3.5" fill="#26a69a" opacity=".9"/>
                        <circle cx="21" cy="38" r="3.5" fill="#e05c97"/>
                        <circle cx="69" cy="38" r="3.5" fill="#e05c97"/>
                    </svg>
                </div>
                <div>
                    <div class="card-objective-label">Objetivo</div>
                    <div class="card-objective-text">Construir la configuración electrónica por subniveles y orbitales, validando el orden correcto y la capacidad de cada orbital.</div>
                </div>
            </div>
            <div class="card-footer">
                <span class="card-hint">Disponible para jugar ahora</span>
                <a class="btn btn-teal" href="${pageContext.request.contextPath}/escenario5">Entrar →</a>
            </div>
        </div>

        <!-- ESCENARIO 6 -->
        <div class="card">
            <div class="card-band" style="background:var(--purple);"></div>
            <div class="card-body">
                <div>
                    <div class="card-num">Escenario 6</div>
                    <div class="card-title">Propiedades Periódicas</div>
                    <div class="card-topic">Propiedades periódicas de los elementos</div>
                </div>
                <div class="card-illustration">
                    <svg class="ilu" viewBox="0 0 90 90" xmlns="http://www.w3.org/2000/svg">
                        <rect x="8"  y="20" width="32" height="38" rx="8" fill="#ede7f6" stroke="#7c5cbf" stroke-width="1.5"/>
                        <text x="24" y="35" text-anchor="middle" font-family="Nunito" font-size="14" fill="#7c5cbf" font-weight="900">Na</text>
                        <text x="24" y="48" text-anchor="middle" font-family="Nunito" font-size="9" fill="#555" font-weight="700">Z=11</text>
                        <text x="24" y="58" text-anchor="middle" font-family="Nunito" font-size="8" fill="#888">Sodio</text>
                        <text x="45" y="42" text-anchor="middle" font-family="Nunito" font-size="16" fill="#7c5cbf" font-weight="900">vs</text>
                        <rect x="50" y="20" width="32" height="38" rx="8" fill="#ede7f6" stroke="#7c5cbf" stroke-width="1.5"/>
                        <text x="66" y="35" text-anchor="middle" font-family="Nunito" font-size="14" fill="#7c5cbf" font-weight="900">Cl</text>
                        <text x="66" y="48" text-anchor="middle" font-family="Nunito" font-size="9" fill="#555" font-weight="700">Z=17</text>
                        <text x="66" y="58" text-anchor="middle" font-family="Nunito" font-size="8" fill="#888">Cloro</text>
                        <text x="45" y="78" text-anchor="middle" font-family="Nunito" font-size="8" fill="#999" font-weight="600">Radio · Ionización · EN</text>
                    </svg>
                </div>
                <div>
                    <div class="card-objective-label">Objetivo</div>
                    <div class="card-objective-text">Comparar radio atómico, energía de ionización y electronegatividad entre dos elementos según las tendencias periódicas.</div>
                </div>
            </div>
            <div class="card-footer">
                <span class="card-hint">Disponible para jugar ahora</span>
                <a class="btn btn-purple" href="${pageContext.request.contextPath}/escenario6">Entrar →</a>
            </div>
        </div>

    </div>
</main>

</body>
</html>
