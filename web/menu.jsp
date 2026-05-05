<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="modelo.Usuario" %>
<%
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
            --navy:      #1e3a5f;
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

        /* ══════════════════════════════
           HEADER
        ══════════════════════════════ */
        header {
            background: #ffffff;
            box-shadow: 0 2px 16px rgba(0,0,0,.08);
            padding: 0 32px;
            height: 70px;
            display: flex;
            align-items: center;
            justify-content: space-between;
            position: sticky;
            top: 0;
            z-index: 200;
            gap: 16px;
        }

        /* Logo */
        .logo-wrap { display: flex; flex-direction: column; line-height: 1; flex-shrink: 0; }
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
            font-size: .57rem;
            font-weight: 800;
            text-transform: uppercase;
            letter-spacing: .7px;
            color: var(--text-soft);
        }

        /* Botones del header */
        .header-actions {
            display: flex;
            align-items: center;
            gap: 10px;
            flex-shrink: 0;
        }

        .hbtn {
            border: none;
            cursor: pointer;
            border-radius: 50px;
            font-family: 'Nunito', sans-serif;
            font-weight: 700;
            font-size: .82rem;
            padding: 8px 18px;
            transition: filter .15s, transform .1s;
            text-decoration: none;
            display: inline-flex;
            align-items: center;
            gap: 6px;
            white-space: nowrap;
        }
        .hbtn:hover  { filter: brightness(1.08); transform: translateY(-1px); }
        .hbtn:active { transform: scale(.97); }

        .hbtn-help   { background: var(--navy);  color: #fff; }
        .hbtn-about  { background: var(--gray-lt); color: var(--text-dark); border: 1.5px solid #dde; }
        .hbtn-logout { background: #fff0f0; color: #c0392b; border: 1.5px solid #f5c6c6; }

        /* Usuario */
        .user-info {
            display: flex;
            align-items: center;
            gap: 8px;
            font-size: .85rem;
            color: var(--text-mid);
            flex-shrink: 0;
        }
        .user-name { font-weight: 800; color: var(--text-dark); }
        .user-avatar {
            width: 38px; height: 38px;
            border-radius: 50%;
            background: linear-gradient(135deg, var(--green), var(--blue));
            display: flex; align-items: center; justify-content: center;
            color: #fff;
            font-weight: 900;
            font-size: 1rem;
            box-shadow: 0 2px 10px rgba(58,125,68,.3);
            flex-shrink: 0;
        }

        /* ══════════════════════════════
           BANNER MASCOTA
        ══════════════════════════════ */
        .mascota-banner {
            background: linear-gradient(135deg, #1a3a2a 0%, #1e3a5f 100%);
            padding: 26px 40px;
            display: flex;
            align-items: center;
            gap: 24px;
            position: relative;
            overflow: hidden;
        }
        .mascota-banner::before {
            content:''; position:absolute; top:-50px; right:-50px;
            width:200px; height:200px; border-radius:50%;
            background:rgba(74,144,217,.08); pointer-events:none;
        }
        .mascota-banner::after {
            content:''; position:absolute; bottom:-70px; left:35%;
            width:280px; height:280px; border-radius:50%;
            background:rgba(58,125,68,.07); pointer-events:none;
        }
        .part { position:absolute; border-radius:50%; opacity:.3; animation:flotar 5s ease-in-out infinite; pointer-events:none; }
        .part:nth-child(1){ width:11px;height:11px;background:var(--blue);  top:22%;right:12%;animation-delay:0s;   }
        .part:nth-child(2){ width:7px; height:7px; background:var(--pink);  top:55%;right:22%;animation-delay:1.5s; }
        .part:nth-child(3){ width:9px; height:9px; background:var(--yellow);top:28%;right:6%; animation-delay:3s;   }
        @keyframes flotar { 0%,100%{transform:translateY(0);} 50%{transform:translateY(-10px);} }

        .mascota-img-wrap { position:relative; flex-shrink:0; cursor:pointer; }
        .mascota-img, .mascota-fallback {
            width:88px; height:88px; border-radius:50%;
            border:3px solid rgba(255,255,255,.22);
            box-shadow:0 4px 22px rgba(0,0,0,.45);
            object-fit:cover; transition:transform .3s; display:block;
        }
        .mascota-fallback {
            background:linear-gradient(135deg,#2d6a4f,#1e3a5f);
            font-size:2.8rem; display:none; align-items:center; justify-content:center;
        }
        .mascota-img-wrap:hover .mascota-img,
        .mascota-img-wrap:hover .mascota-fallback { transform:scale(1.09) rotate(-4deg); }
        .mascota-dot {
            position:absolute; bottom:5px; right:5px;
            width:14px; height:14px; background:#4cdd7a;
            border-radius:50%; border:2px solid #1a3a2a;
            animation:pulse-dot 2.2s infinite;
        }
        @keyframes pulse-dot {
            0%,100%{box-shadow:0 0 0 0 rgba(76,221,122,.45);}
            50%    {box-shadow:0 0 0 7px rgba(76,221,122,0);}
        }
        .mascota-tooltip {
            position:absolute; bottom:calc(100% + 12px); left:50%;
            transform:translateX(-50%) scale(.88);
            background:#fff; color:var(--text-dark);
            font-size:.8rem; font-weight:800; padding:8px 14px;
            border-radius:10px; white-space:nowrap;
            box-shadow:0 4px 18px rgba(0,0,0,.2);
            opacity:0; pointer-events:none;
            transition:opacity .2s, transform .2s; z-index:10;
        }
        .mascota-tooltip::after {
            content:''; position:absolute; top:100%; left:50%;
            transform:translateX(-50%); border:6px solid transparent;
            border-top-color:#fff;
        }
        .mascota-img-wrap:hover .mascota-tooltip { opacity:1; transform:translateX(-50%) scale(1); }

        .mascota-texto { flex:1; z-index:1; }
        .mascota-nombre {
            font-family:'Baloo 2',cursive; font-size:.95rem; font-weight:800;
            color:#4cdd7a; letter-spacing:.5px; margin-bottom:5px;
        }
        .mascota-mensaje {
            font-size:1.05rem; font-weight:700; color:#e8f4ff; line-height:1.5; max-width:580px;
        }
        .mascota-mensaje .hi { color:#7dd3fc; }
        .mascota-mensaje .em { color:#fde68a; }

        /* ══════════════════════════════
           MAIN / CARDS
        ══════════════════════════════ */
        main { max-width:1160px; margin:0 auto; padding:40px 24px 80px; }
        .page-title { font-family:'Baloo 2',cursive; font-size:1.8rem; font-weight:900; color:var(--text-dark); margin-bottom:4px; }
        .page-subtitle { font-size:.95rem; color:var(--text-soft); margin-bottom:36px; }

        .scenarios-grid { display:grid; grid-template-columns:repeat(auto-fill,minmax(320px,1fr)); gap:28px; }

        .card {
            background:var(--card-bg); border-radius:var(--radius);
            box-shadow:var(--shadow); overflow:hidden;
            display:flex; flex-direction:column;
            transition:transform .2s, box-shadow .2s;
        }
        .card:hover { transform:translateY(-5px); box-shadow:0 12px 36px rgba(0,0,0,.14); }
        .card-band { height:8px; }
        .card-body { padding:24px 24px 20px; flex:1; display:flex; flex-direction:column; gap:12px; }
        .card-num  { font-size:.75rem; font-weight:800; text-transform:uppercase; letter-spacing:1px; color:var(--text-soft); }
        .card-title { font-family:'Baloo 2',cursive; font-size:1.28rem; font-weight:800; color:var(--text-dark); line-height:1.2; margin-top:2px; }
        .card-topic { font-size:.82rem; color:var(--text-soft); font-weight:600; }
        .card-illustration { background:var(--gray-lt); border-radius:12px; height:110px; display:flex; align-items:center; justify-content:center; }
        .card-objective-label { font-size:.8rem; font-weight:800; color:var(--text-dark); }
        .card-objective-text  { font-size:.88rem; color:var(--text-mid); line-height:1.55; }
        .card-footer { padding:16px 24px 20px; border-top:1px solid #f0f0f5; display:flex; align-items:center; justify-content:space-between; }
        .card-hint { font-size:.8rem; color:var(--text-soft); }

        .btn { border:none; cursor:pointer; border-radius:50px; font-family:'Nunito',sans-serif; font-weight:800; font-size:.9rem; padding:10px 26px; transition:filter .15s,transform .1s; text-decoration:none; display:inline-block; }
        .btn:hover  { filter:brightness(1.1); }
        .btn:active { transform:scale(.97); }
        .btn-green  { background:var(--green);  color:#fff; }
        .btn-blue   { background:var(--blue);   color:#fff; }
        .btn-pink   { background:var(--pink);   color:#fff; }
        .btn-yellow { background:var(--yellow); color:#fff; }
        .btn-teal   { background:var(--teal);   color:#fff; }
        .btn-purple { background:var(--purple); color:#fff; }

        svg.ilu { width:90px; height:90px; }
        .orb { fill:none; stroke:#c8d8e8; stroke-width:1.5; }
        .p   { fill:var(--blue); }
        .n   { fill:var(--yellow); }
        .e   { fill:var(--pink); }
        .nu  { fill:#ddeeff; stroke:#b0ccee; stroke-width:1.5; }

        /* ══════════════════════════════
           MODALES (Ayuda y Acerca de)
        ══════════════════════════════ */
        .modal-overlay {
            display: none;
            position: fixed; inset: 0;
            background: rgba(20,30,50,.55);
            backdrop-filter: blur(3px);
            z-index: 1000;
            align-items: center;
            justify-content: center;
            padding: 20px;
        }
        .modal-overlay.open { display: flex; animation: fadeIn .2s; }
        @keyframes fadeIn { from{opacity:0;} to{opacity:1;} }

        .modal {
            background: #fff;
            border-radius: 20px;
            box-shadow: 0 20px 60px rgba(0,0,0,.25);
            width: 100%;
            max-width: 760px;
            max-height: 88vh;
            display: flex;
            flex-direction: column;
            animation: slideUp .25s ease;
            overflow: hidden;
        }
        @keyframes slideUp { from{transform:translateY(30px);opacity:0;} to{transform:translateY(0);opacity:1;} }

        /* Modal header */
        .modal-head {
            background: linear-gradient(135deg, var(--navy) 0%, #2d5a8e 100%);
            padding: 20px 28px;
            display: flex;
            align-items: center;
            justify-content: space-between;
            flex-shrink: 0;
        }
        .modal-head-title {
            font-family: 'Baloo 2', cursive;
            font-size: 1.25rem;
            font-weight: 900;
            color: #fff;
            display: flex;
            align-items: center;
            gap: 10px;
        }
        .modal-close {
            background: rgba(255,255,255,.15);
            border: none; cursor: pointer;
            color: #fff; border-radius: 50%;
            width: 34px; height: 34px;
            font-size: 1.1rem; font-weight: 900;
            display: flex; align-items: center; justify-content: center;
            transition: background .15s;
        }
        .modal-close:hover { background: rgba(255,255,255,.3); }

        /* Tabs */
        .modal-tabs {
            display: flex;
            border-bottom: 2px solid #eef0f5;
            background: #f8f9fc;
            flex-shrink: 0;
            overflow-x: auto;
        }
        .tab-btn {
            border: none; background: none; cursor: pointer;
            font-family: 'Nunito', sans-serif;
            font-size: .82rem; font-weight: 700;
            color: var(--text-soft);
            padding: 14px 20px;
            display: flex; align-items: center; gap: 7px;
            border-bottom: 3px solid transparent;
            margin-bottom: -2px;
            transition: color .15s, border-color .15s;
            white-space: nowrap;
        }
        .tab-btn:hover { color: var(--navy); }
        .tab-btn.active { color: var(--navy); border-bottom-color: var(--blue); font-weight: 800; }

        /* Modal body */
        .modal-body {
            padding: 28px;
            overflow-y: auto;
            flex: 1;
        }

        /* Tab panels */
        .tab-panel { display: none; }
        .tab-panel.active { display: block; animation: fadeIn .2s; }

        /* ── Cómo jugar ── */
        .how-steps { display: flex; flex-direction: column; gap: 16px; }
        .how-step {
            display: flex; gap: 16px; align-items: flex-start;
            background: #f8f9fc; border-radius: 14px; padding: 16px 18px;
        }
        .step-num {
            width: 36px; height: 36px; border-radius: 50%;
            background: linear-gradient(135deg, var(--green), var(--blue));
            color: #fff; font-weight: 900; font-size: 1rem;
            display: flex; align-items: center; justify-content: center;
            flex-shrink: 0;
        }
        .step-text strong { display: block; font-size: .95rem; color: var(--text-dark); margin-bottom: 3px; }
        .step-text span   { font-size: .85rem; color: var(--text-mid); line-height: 1.5; }

        /* ── Escenarios ── */
        .escenario-list { display: flex; flex-direction: column; gap: 12px; }
        .escenario-item {
            border-radius: 12px; overflow: hidden;
            border: 1.5px solid #eef0f5;
        }
        .escenario-head {
            display: flex; align-items: center; gap: 12px;
            padding: 13px 18px; cursor: pointer;
            transition: background .15s;
        }
        .escenario-head:hover { background: #f4f6fb; }
        .esc-dot {
            width: 12px; height: 12px; border-radius: 50%; flex-shrink: 0;
        }
        .esc-num  { font-size: .75rem; font-weight: 800; color: var(--text-soft); text-transform: uppercase; letter-spacing: .8px; }
        .esc-name { font-family: 'Baloo 2', cursive; font-size: 1rem; font-weight: 800; color: var(--text-dark); flex: 1; }
        .esc-arrow { font-size: .8rem; color: var(--text-soft); transition: transform .2s; }
        .escenario-item.open .esc-arrow { transform: rotate(180deg); }
        .escenario-body {
            display: none; padding: 0 18px 14px;
            font-size: .87rem; color: var(--text-mid); line-height: 1.6;
            border-top: 1px solid #eef0f5;
        }
        .escenario-body .obj-label { font-weight: 800; color: var(--text-dark); margin: 10px 0 4px; font-size: .82rem; text-transform: uppercase; letter-spacing: .5px; }
        .escenario-item.open .escenario-body { display: block; animation: fadeIn .15s; }

        /* ── FAQ ── */
        .faq-list { display: flex; flex-direction: column; gap: 10px; }
        .faq-item {
            border-radius: 12px; overflow: hidden;
            border: 1.5px solid #eef0f5;
        }
        .faq-q {
            display: flex; align-items: center; gap: 10px;
            padding: 14px 18px; cursor: pointer;
            background: #f8f9fc; transition: background .15s;
        }
        .faq-q:hover { background: #eef2fa; }
        .faq-icon { color: var(--blue); font-weight: 900; font-size: 1rem; flex-shrink: 0; }
        .faq-q-text { flex: 1; font-size: .9rem; font-weight: 700; color: var(--text-dark); }
        .faq-arrow { font-size: .75rem; color: var(--text-soft); transition: transform .2s; }
        .faq-item.open .faq-arrow { transform: rotate(180deg); }
        .faq-a {
            display: none; padding: 14px 18px;
            font-size: .87rem; color: var(--text-mid); line-height: 1.6;
            border-top: 1px solid #eef0f5;
        }
        .faq-item.open .faq-a { display: block; animation: fadeIn .15s; }

        /* ── Puntaje ── */
        .score-cards { display: grid; grid-template-columns: 1fr 1fr; gap: 14px; margin-bottom: 20px; }
        .score-card {
            background: linear-gradient(135deg, #f0f4ff, #e8f0ff);
            border-radius: 14px; padding: 18px 20px;
            border: 1.5px solid #dce8ff;
        }
        .score-card-icon { font-size: 1.8rem; margin-bottom: 8px; }
        .score-card-title { font-size: .78rem; font-weight: 800; color: var(--text-soft); text-transform: uppercase; letter-spacing: .6px; margin-bottom: 4px; }
        .score-card-val { font-family: 'Baloo 2', cursive; font-size: 1.6rem; font-weight: 900; color: var(--navy); }
        .score-card-desc { font-size: .8rem; color: var(--text-mid); margin-top: 4px; }
        .score-note { background: #fffbe6; border: 1.5px solid #ffe082; border-radius: 12px; padding: 14px 18px; font-size: .87rem; color: #7a5800; line-height: 1.6; }
        .score-note strong { display: block; margin-bottom: 4px; }

        /* ══════════════════════════════
           MODAL ACERCA DE
        ══════════════════════════════ */
        .about-modal .modal { max-width: 520px; }
        .about-body { padding: 32px 28px; }
        .about-logo { font-family:'Baloo 2',cursive; font-size:2.8rem; font-weight:900; background:linear-gradient(135deg,var(--green),var(--blue)); -webkit-background-clip:text; -webkit-text-fill-color:transparent; background-clip:text; text-align:center; margin-bottom:4px; }
        .about-subtitle { text-align:center; font-size:.88rem; color:var(--text-soft); font-weight:700; margin-bottom:24px; }
        .about-row { display:flex; gap:10px; margin-bottom:10px; align-items:flex-start; }
        .about-label { font-size:.78rem; font-weight:800; text-transform:uppercase; letter-spacing:.6px; color:var(--text-soft); min-width:110px; padding-top:1px; }
        .about-val { font-size:.9rem; color:var(--text-dark); font-weight:600; line-height:1.5; }
        .about-divider { border:none; border-top:1px solid #eef0f5; margin:18px 0; }
        .about-tech { display:flex; flex-wrap:wrap; gap:8px; }
        .tech-tag { background:var(--gray-lt); border:1.5px solid #dde; border-radius:20px; padding:5px 14px; font-size:.8rem; font-weight:700; color:var(--text-mid); }
    </style>
</head>
<body>

<!-- ══════════════════════════════
     HEADER
══════════════════════════════ -->
<header>
    <div class="logo-wrap">
        <span class="logo-text">SEAEA</span>
        <span class="logo-badge">Estructura Atómica · Amazonia</span>
    </div>

    <div class="header-actions">
        <!-- Ayuda -->
        <button class="hbtn hbtn-help" onclick="openModal('helpModal')">
            ❓ Centro de Ayuda
        </button>
        <!-- Acerca de -->
        <button class="hbtn hbtn-about" onclick="openModal('aboutModal')">
            ℹ️ Acerca de
        </button>
        <!-- Cerrar sesión -->
        <a class="hbtn hbtn-logout" href="${pageContext.request.contextPath}/logout">
            🚪 Cerrar sesión
        </a>
    </div>

    <div class="user-info">
        <span>Hola, <span class="user-name"><%= nombreUsuario %></span></span>
        <div class="user-avatar"><%= inicial %></div>
    </div>
</header>

<!-- ══════════════════════════════
     BANNER MASCOTA
══════════════════════════════ -->
<div class="mascota-banner">
    <div class="part"></div><div class="part"></div><div class="part"></div>
    <div class="mascota-img-wrap">
        <img class="mascota-img"
             src="${pageContext.request.contextPath}/img/amazonatom.png"
             alt="Amazonatom"
             onerror="this.style.display='none'; document.getElementById('mfallback').style.display='flex';">
        <div id="mfallback" class="mascota-fallback">🦜</div>
        <div class="mascota-dot"></div>
        <div class="mascota-tooltip">¡Hola! Soy Amazonatom 👋</div>
    </div>
    <div class="mascota-texto">
        <div class="mascota-nombre">✦ Amazonatom</div>
        <div class="mascota-mensaje">
            ¡Hola, <span class="hi"><%= nombreUsuario %>!</span>
            Soy tu guía en el aprendizaje de la <span class="em">estructura atómica</span>.
            Elige un escenario y comencemos a explorar el fascinante universo de los átomos. 🧪⚛️
        </div>
    </div>
</div>

<!-- ══════════════════════════════
     MAIN – CARDS
══════════════════════════════ -->
<main>
    <p class="page-title">🗺️ Mapa de Escenarios</p>
    <p class="page-subtitle">Explora la estructura atómica paso a paso. Cada escenario desbloquea nuevos conceptos.</p>

    <div class="scenarios-grid">

        <!-- E1 -->
        <div class="card">
            <div class="card-band" style="background:var(--green);"></div>
            <div class="card-body">
                <div><div class="card-num">Escenario 1</div><div class="card-title">Arma tu Átomo</div><div class="card-topic">Electrones, protones y neutrones</div></div>
                <div class="card-illustration">
                    <svg class="ilu" viewBox="0 0 90 90"><circle cx="45" cy="45" r="28" class="orb"/><circle cx="45" cy="45" r="16" class="orb"/><circle cx="45" cy="45" r="11" class="nu"/><circle cx="41" cy="43" r="4" class="p"/><circle cx="49" cy="43" r="4" class="p"/><circle cx="45" cy="49" r="4" class="n"/><circle cx="45" cy="17" r="4" class="e"/><circle cx="17" cy="45" r="4" class="e"/><circle cx="73" cy="45" r="4" class="e"/></svg>
                </div>
                <div><div class="card-objective-label">Objetivo</div><div class="card-objective-text">Construir átomos modificando protones, neutrones y electrones, visualizando la estructura nuclear y las capas electrónicas.</div></div>
            </div>
            <div class="card-footer"><span class="card-hint">Disponible ahora</span><a class="btn btn-green" href="${pageContext.request.contextPath}/escenario1">Entrar →</a></div>
        </div>

        <!-- E2 -->
        <div class="card">
            <div class="card-band" style="background:var(--blue);"></div>
            <div class="card-body">
                <div><div class="card-num">Escenario 2</div><div class="card-title">Núcleo y Número Atómico</div><div class="card-topic">Núcleo atómico y número atómico</div></div>
                <div class="card-illustration">
                    <svg class="ilu" viewBox="0 0 90 90"><circle cx="45" cy="45" r="22" class="nu" stroke-width="2"/><circle cx="38" cy="40" r="5" class="p"/><circle cx="52" cy="40" r="5" class="p"/><circle cx="45" cy="40" r="5" class="p"/><circle cx="38" cy="51" r="5" class="n"/><circle cx="52" cy="51" r="5" class="n"/><text x="45" y="80" text-anchor="middle" font-family="Nunito" font-size="11" fill="#4a90d9" font-weight="800">Z = protones</text></svg>
                </div>
                <div><div class="card-objective-label">Objetivo</div><div class="card-objective-text">Comprender el núcleo atómico y calcular el número atómico a partir de la cantidad de protones.</div></div>
            </div>
            <div class="card-footer"><span class="card-hint">Disponible ahora</span><a class="btn btn-blue" href="${pageContext.request.contextPath}/escenario2">Entrar →</a></div>
        </div>

        <!-- E3 -->
        <div class="card">
            <div class="card-band" style="background:var(--pink);"></div>
            <div class="card-body">
                <div><div class="card-num">Escenario 3</div><div class="card-title">Iones y Formación de Iones</div><div class="card-topic">Cationes y aniones</div></div>
                <div class="card-illustration">
                    <svg class="ilu" viewBox="0 0 90 90"><circle cx="45" cy="45" r="26" class="orb"/><circle cx="45" cy="45" r="14" class="nu"/><circle cx="41" cy="42" r="4" class="p"/><circle cx="49" cy="42" r="4" class="p"/><circle cx="45" cy="49" r="4" fill="#f5a623"/><circle cx="45" cy="19" r="4" class="e"/><circle cx="19" cy="45" r="4" class="e"/><text x="71" y="22" font-family="Nunito" font-size="14" fill="#e05c97" font-weight="900">+</text><text x="68" y="72" font-family="Nunito" font-size="14" fill="#4a90d9" font-weight="900">−</text></svg>
                </div>
                <div><div class="card-objective-label">Objetivo</div><div class="card-objective-text">Comprender cómo se forman iones cuando un átomo gana o pierde electrones, y cómo cambia su carga neta.</div></div>
            </div>
            <div class="card-footer"><span class="card-hint">Disponible ahora</span><a class="btn btn-pink" href="${pageContext.request.contextPath}/escenario3">Entrar →</a></div>
        </div>

        <!-- E4 -->
        <div class="card">
            <div class="card-band" style="background:var(--yellow);"></div>
            <div class="card-body">
                <div><div class="card-num">Escenario 4</div><div class="card-title">Configura tu Isótopo</div><div class="card-topic">Número másico, isótopos y abundancia isotópica</div></div>
                <div class="card-illustration">
                    <svg class="ilu" viewBox="0 0 90 90"><ellipse cx="28" cy="45" rx="18" ry="18" fill="#fff8e1" stroke="#f5a623" stroke-width="1.5"/><circle cx="24" cy="42" r="4" class="p"/><circle cx="32" cy="42" r="4" class="p"/><circle cx="28" cy="49" r="4" fill="#f5a623"/><text x="28" y="72" text-anchor="middle" font-family="Nunito" font-size="9" fill="#555" font-weight="700">He-3</text><ellipse cx="62" cy="45" rx="20" ry="20" fill="#fff8e1" stroke="#f5a623" stroke-width="1.5"/><circle cx="57" cy="41" r="4" class="p"/><circle cx="67" cy="41" r="4" class="p"/><circle cx="57" cy="49" r="4" fill="#f5a623"/><circle cx="67" cy="49" r="4" fill="#f5a623"/><text x="62" y="74" text-anchor="middle" font-family="Nunito" font-size="9" fill="#555" font-weight="700">He-4</text></svg>
                </div>
                <div><div class="card-objective-label">Objetivo</div><div class="card-objective-text">Diferenciar número atómico y número másico, y reconocer cómo surgen los isótopos al variar los neutrones.</div></div>
            </div>
            <div class="card-footer"><span class="card-hint">Disponible ahora</span><a class="btn btn-yellow" href="${pageContext.request.contextPath}/escenario4">Entrar →</a></div>
        </div>

        <!-- E5 -->
        <div class="card">
            <div class="card-band" style="background:var(--teal);"></div>
            <div class="card-body">
                <div><div class="card-num">Escenario 5</div><div class="card-title">Configuración Electrónica</div><div class="card-topic">Configuración electrónica y tabla periódica</div></div>
                <div class="card-illustration">
                    <svg class="ilu" viewBox="0 0 90 90"><rect x="10" y="72" width="70" height="8" rx="4" fill="#e0f2f1"/><rect x="10" y="72" width="42" height="8" rx="4" fill="#26a69a"/><text x="14" y="79" font-family="Nunito" font-size="8" fill="#fff" font-weight="700">1s² 2s² 2p⁶</text><circle cx="45" cy="38" r="24" class="orb" stroke="#26a69a"/><circle cx="45" cy="38" r="14" class="orb" stroke="#26a69a"/><circle cx="45" cy="38" r="8" fill="#e0f2f1" stroke="#26a69a" stroke-width="1.5"/><circle cx="45" cy="38" r="3" fill="#26a69a"/><circle cx="45" cy="14" r="3.5" fill="#26a69a" opacity=".9"/><circle cx="45" cy="62" r="3.5" fill="#26a69a" opacity=".9"/><circle cx="21" cy="38" r="3.5" fill="#e05c97"/><circle cx="69" cy="38" r="3.5" fill="#e05c97"/></svg>
                </div>
                <div><div class="card-objective-label">Objetivo</div><div class="card-objective-text">Construir la configuración electrónica por subniveles y orbitales, validando el orden correcto y la capacidad de cada orbital.</div></div>
            </div>
            <div class="card-footer"><span class="card-hint">Disponible ahora</span><a class="btn btn-teal" href="${pageContext.request.contextPath}/escenario5">Entrar →</a></div>
        </div>

        <!-- E6 -->
        <div class="card">
            <div class="card-band" style="background:var(--purple);"></div>
            <div class="card-body">
                <div><div class="card-num">Escenario 6</div><div class="card-title">Propiedades Periódicas</div><div class="card-topic">Propiedades periódicas de los elementos</div></div>
                <div class="card-illustration">
                    <svg class="ilu" viewBox="0 0 90 90"><rect x="8" y="20" width="32" height="38" rx="8" fill="#ede7f6" stroke="#7c5cbf" stroke-width="1.5"/><text x="24" y="35" text-anchor="middle" font-family="Nunito" font-size="14" fill="#7c5cbf" font-weight="900">Na</text><text x="24" y="48" text-anchor="middle" font-family="Nunito" font-size="9" fill="#555" font-weight="700">Z=11</text><text x="24" y="58" text-anchor="middle" font-family="Nunito" font-size="8" fill="#888">Sodio</text><text x="45" y="42" text-anchor="middle" font-family="Nunito" font-size="16" fill="#7c5cbf" font-weight="900">vs</text><rect x="50" y="20" width="32" height="38" rx="8" fill="#ede7f6" stroke="#7c5cbf" stroke-width="1.5"/><text x="66" y="35" text-anchor="middle" font-family="Nunito" font-size="14" fill="#7c5cbf" font-weight="900">Cl</text><text x="66" y="48" text-anchor="middle" font-family="Nunito" font-size="9" fill="#555" font-weight="700">Z=17</text><text x="66" y="58" text-anchor="middle" font-family="Nunito" font-size="8" fill="#888">Cloro</text><text x="45" y="78" text-anchor="middle" font-family="Nunito" font-size="8" fill="#999" font-weight="600">Radio · Ionización · EN</text></svg>
                </div>
                <div><div class="card-objective-label">Objetivo</div><div class="card-objective-text">Comparar radio atómico, energía de ionización y electronegatividad entre dos elementos según las tendencias periódicas.</div></div>
            </div>
            <div class="card-footer"><span class="card-hint">Disponible ahora</span><a class="btn btn-purple" href="${pageContext.request.contextPath}/escenario6">Entrar →</a></div>
        </div>

    </div>
</main>


<!-- ══════════════════════════════
     MODAL: CENTRO DE AYUDA
══════════════════════════════ -->
<div class="modal-overlay" id="helpModal" onclick="closeOnOverlay(event,'helpModal')">
    <div class="modal">

        <div class="modal-head">
            <div class="modal-head-title">❓ Centro de Ayuda — SEAEA</div>
            <button class="modal-close" onclick="closeModal('helpModal')">✕</button>
        </div>

        <div class="modal-tabs">
            <button class="tab-btn active" onclick="switchTab('tab-jugar','helpModal')" data-tab="tab-jugar">🎮 Cómo jugar</button>
            <button class="tab-btn"        onclick="switchTab('tab-escenarios','helpModal')" data-tab="tab-escenarios">🗺️ Escenarios</button>
            <button class="tab-btn"        onclick="switchTab('tab-faq','helpModal')" data-tab="tab-faq">💬 Preguntas frecuentes</button>
            <button class="tab-btn"        onclick="switchTab('tab-puntaje','helpModal')" data-tab="tab-puntaje">⭐ Puntaje</button>
        </div>

        <div class="modal-body">

            <!-- TAB: CÓMO JUGAR -->
            <div class="tab-panel active" id="tab-jugar">
                <div class="how-steps">
                    <div class="how-step">
                        <div class="step-num">1</div>
                        <div class="step-text">
                            <strong>Elige un escenario</strong>
                            <span>En el mapa principal verás los 6 escenarios disponibles. Cada uno aborda un subtema de la estructura atómica. Comienza por el Escenario 1 si es tu primera vez.</span>
                        </div>
                    </div>
                    <div class="how-step">
                        <div class="step-num">2</div>
                        <div class="step-text">
                            <strong>Aprende con la simulación</strong>
                            <span>Dentro de cada escenario encontrarás una zona de aprendizaje interactivo donde puedes manipular partículas subatómicas, visualizar átomos y explorar conceptos de forma visual.</span>
                        </div>
                    </div>
                    <div class="how-step">
                        <div class="step-num">3</div>
                        <div class="step-text">
                            <strong>Inicia la evaluación</strong>
                            <span>Cuando te sientas listo, presiona el botón <strong>"Iniciar Evaluación"</strong>. Se generarán retos aleatorios donde deberás construir átomos, isótopos o configuraciones correctas.</span>
                        </div>
                    </div>
                    <div class="how-step">
                        <div class="step-num">4</div>
                        <div class="step-text">
                            <strong>Responde y recibe retroalimentación</strong>
                            <span>Ajusta los controles según el reto planteado y presiona <strong>"Comprobar"</strong>. Amazonatom te indicará si tu respuesta es correcta y te explicará los errores si los hay.</span>
                        </div>
                    </div>
                    <div class="how-step">
                        <div class="step-num">5</div>
                        <div class="step-text">
                            <strong>Avanza al siguiente escenario</strong>
                            <span>Al completar la evaluación, tu progreso quedará registrado y podrás continuar con el siguiente escenario. El sistema es progresivo: cada escenario construye sobre el anterior.</span>
                        </div>
                    </div>
                </div>
            </div>

            <!-- TAB: ESCENARIOS -->
            <div class="tab-panel" id="tab-escenarios">
                <div class="escenario-list">

                    <div class="escenario-item" id="esc1">
                        <div class="escenario-head" onclick="toggleEsc('esc1')">
                            <div class="esc-dot" style="background:var(--green);"></div>
                            <span class="esc-num">E1</span>
                            <span class="esc-name">Arma tu Átomo</span>
                            <span class="esc-arrow">▼</span>
                        </div>
                        <div class="escenario-body">
                            <div class="obj-label">Temática</div>
                            Electrones, protones y neutrones — la base de la estructura atómica.
                            <div class="obj-label">Objetivo</div>
                            Construir átomos modificando el número de protones, neutrones y electrones. Visualizar la estructura nuclear y la distribución de las capas electrónicas, entendiendo cómo afectan a la carga neta del átomo.
                            <div class="obj-label">¿Qué aprenderás?</div>
                            Diferencia entre partículas subatómicas, cómo se ubican en el núcleo o en las órbitas, y cómo los cambios en su número definen la identidad y carga del átomo.
                        </div>
                    </div>

                    <div class="escenario-item" id="esc2">
                        <div class="escenario-head" onclick="toggleEsc('esc2')">
                            <div class="esc-dot" style="background:var(--blue);"></div>
                            <span class="esc-num">E2</span>
                            <span class="esc-name">Núcleo y Número Atómico</span>
                            <span class="esc-arrow">▼</span>
                        </div>
                        <div class="escenario-body">
                            <div class="obj-label">Temática</div>
                            El núcleo atómico y el número atómico (Z).
                            <div class="obj-label">Objetivo</div>
                            Comprender la composición del núcleo atómico y calcular el número atómico a partir de la cantidad de protones presentes en él.
                            <div class="obj-label">¿Qué aprenderás?</div>
                            Por qué el número atómico define el elemento químico, qué rol juegan los neutrones en la estabilidad nuclear, y cómo leer la notación estándar de un elemento.
                        </div>
                    </div>

                    <div class="escenario-item" id="esc3">
                        <div class="escenario-head" onclick="toggleEsc('esc3')">
                            <div class="esc-dot" style="background:var(--pink);"></div>
                            <span class="esc-num">E3</span>
                            <span class="esc-name">Iones y Formación de Iones</span>
                            <span class="esc-arrow">▼</span>
                        </div>
                        <div class="escenario-body">
                            <div class="obj-label">Temática</div>
                            Iones, cationes y aniones.
                            <div class="obj-label">Objetivo</div>
                            Comprender cómo se forman los iones cuando un átomo gana o pierde electrones, y cómo este proceso altera la carga neta del átomo.
                            <div class="obj-label">¿Qué aprenderás?</div>
                            La diferencia entre catión (carga positiva, pérdida de electrones) y anión (carga negativa, ganancia de electrones), y cómo calcular la carga neta resultante.
                        </div>
                    </div>

                    <div class="escenario-item" id="esc4">
                        <div class="escenario-head" onclick="toggleEsc('esc4')">
                            <div class="esc-dot" style="background:var(--yellow);"></div>
                            <span class="esc-num">E4</span>
                            <span class="esc-name">Configura tu Isótopo</span>
                            <span class="esc-arrow">▼</span>
                        </div>
                        <div class="escenario-body">
                            <div class="obj-label">Temática</div>
                            Número másico, isótopos y abundancia isotópica.
                            <div class="obj-label">Objetivo</div>
                            Diferenciar el número atómico del número másico, y reconocer cómo surgen los isótopos al variar la cantidad de neutrones manteniendo constante el número de protones.
                            <div class="obj-label">¿Qué aprenderás?</div>
                            Qué son los isótopos, cómo calcular el número másico (A = Z + N), y qué significa la abundancia isotópica de un elemento.
                        </div>
                    </div>

                    <div class="escenario-item" id="esc5">
                        <div class="escenario-head" onclick="toggleEsc('esc5')">
                            <div class="esc-dot" style="background:var(--teal);"></div>
                            <span class="esc-num">E5</span>
                            <span class="esc-name">Configuración Electrónica</span>
                            <span class="esc-arrow">▼</span>
                        </div>
                        <div class="escenario-body">
                            <div class="obj-label">Temática</div>
                            La configuración electrónica y la tabla periódica.
                            <div class="obj-label">Objetivo</div>
                            Construir la configuración electrónica por subniveles y orbitales, validando el orden correcto de llenado y la capacidad máxima de cada orbital.
                            <div class="obj-label">¿Qué aprenderás?</div>
                            El principio de Aufbau, la regla de Hund, el principio de exclusión de Pauli, y cómo relacionar la configuración electrónica con la posición del elemento en la tabla periódica.
                        </div>
                    </div>

                    <div class="escenario-item" id="esc6">
                        <div class="escenario-head" onclick="toggleEsc('esc6')">
                            <div class="esc-dot" style="background:var(--purple);"></div>
                            <span class="esc-num">E6</span>
                            <span class="esc-name">Propiedades Periódicas</span>
                            <span class="esc-arrow">▼</span>
                        </div>
                        <div class="escenario-body">
                            <div class="obj-label">Temática</div>
                            Propiedades periódicas de los elementos.
                            <div class="obj-label">Objetivo</div>
                            Comparar radio atómico, energía de ionización y electronegatividad entre elementos seleccionados, identificando las tendencias en la tabla periódica.
                            <div class="obj-label">¿Qué aprenderás?</div>
                            Cómo varían las propiedades periódicas a lo largo de un período y un grupo, y por qué estas tendencias son consecuencia de la estructura electrónica del átomo.
                        </div>
                    </div>

                </div>
            </div>

            <!-- TAB: FAQ -->
            <div class="tab-panel" id="tab-faq">
                <div class="faq-list">

                    <div class="faq-item" id="faq1">
                        <div class="faq-q" onclick="toggleFaq('faq1')">
                            <span class="faq-icon">?</span>
                            <span class="faq-q-text">¿Por qué no puedo hacer clic en "Comprobar"?</span>
                            <span class="faq-arrow">▼</span>
                        </div>
                        <div class="faq-a">El botón <strong>Comprobar</strong> se activa únicamente cuando has realizado algún ajuste en el simulador (agregado o quitado partículas). Asegúrate de modificar al menos un valor antes de intentar comprobar tu respuesta.</div>
                    </div>

                    <div class="faq-item" id="faq2">
                        <div class="faq-q" onclick="toggleFaq('faq2')">
                            <span class="faq-icon">?</span>
                            <span class="faq-q-text">¿Cómo funciona el sistema de progreso?</span>
                            <span class="faq-arrow">▼</span>
                        </div>
                        <div class="faq-a">SEAEA registra tu avance en cada escenario. La barra de <strong>Aprendizaje</strong> en la parte superior de cada escenario refleja tu porcentaje de progreso. Al completar todos los retos de un escenario, este queda marcado como completado.</div>
                    </div>

                    <div class="faq-item" id="faq3">
                        <div class="faq-q" onclick="toggleFaq('faq3')">
                            <span class="faq-icon">?</span>
                            <span class="faq-q-text">¿Puedo reiniciar un escenario?</span>
                            <span class="faq-arrow">▼</span>
                        </div>
                        <div class="faq-a">Sí. Dentro de cada escenario encontrarás el botón <strong>"Reiniciar"</strong> que restablece los valores del simulador al estado inicial del reto actual. Esto no borra tu progreso general en el escenario.</div>
                    </div>

                    <div class="faq-item" id="faq4">
                        <div class="faq-q" onclick="toggleFaq('faq4')">
                            <span class="faq-icon">?</span>
                            <span class="faq-q-text">¿Qué significan los colores de las partículas?</span>
                            <span class="faq-arrow">▼</span>
                        </div>
                        <div class="faq-a">En todos los escenarios se usa la misma convención: <strong style="color:var(--blue)">Azul → Protones</strong>, <strong style="color:var(--yellow)">Amarillo/Naranja → Neutrones</strong> y <strong style="color:var(--pink)">Rosa → Electrones</strong>. Esta codificación es consistente en todas las simulaciones.</div>
                    </div>

                    <div class="faq-item" id="faq5">
                        <div class="faq-q" onclick="toggleFaq('faq5')">
                            <span class="faq-icon">?</span>
                            <span class="faq-q-text">¿Qué hago si la página muestra un error?</span>
                            <span class="faq-arrow">▼</span>
                        </div>
                        <div class="faq-a">1. Verifica que <strong>Apache Tomcat</strong> esté en ejecución en NetBeans. 2. Verifica que <strong>MySQL</strong> esté activo y la base de datos SEAEA esté creada. 3. Puedes acceder a <code>/SEAEA/testConexion</code> para diagnosticar el estado de la conexión a la base de datos.</div>
                    </div>

                    <div class="faq-item" id="faq6">
                        <div class="faq-q" onclick="toggleFaq('faq6')">
                            <span class="faq-icon">?</span>
                            <span class="faq-q-text">¿Los escenarios tienen algún orden obligatorio?</span>
                            <span class="faq-arrow">▼</span>
                        </div>
                        <div class="faq-a">SEAEA está diseñado de forma <strong>progresiva</strong>: cada escenario construye conocimiento sobre el anterior. Se recomienda completarlos en orden (del 1 al 6) para una mejor comprensión. En el futuro, los escenarios se irán desbloqueando conforme superes cada etapa.</div>
                    </div>

                    <div class="faq-item" id="faq7">
                        <div class="faq-q" onclick="toggleFaq('faq7')">
                            <span class="faq-icon">?</span>
                            <span class="faq-q-text">¿Quién es Amazonatom?</span>
                            <span class="faq-arrow">▼</span>
                        </div>
                        <div class="faq-a"><strong>Amazonatom</strong> es la mascota virtual de SEAEA. Es tu guía y compañero de aprendizaje en todos los escenarios. Te brindará retroalimentación, explicaciones y mensajes de ánimo a lo largo de tu recorrido por la estructura atómica.</div>
                    </div>

                </div>
            </div>

            <!-- TAB: PUNTAJE -->
            <div class="tab-panel" id="tab-puntaje">
                <div class="score-cards">
                    <div class="score-card">
                        <div class="score-card-icon">✅</div>
                        <div class="score-card-title">Respuesta correcta</div>
                        <div class="score-card-val">+2 pts</div>
                        <div class="score-card-desc">Por cada reto resuelto correctamente</div>
                    </div>
                    <div class="score-card">
                        <div class="score-card-icon">❌</div>
                        <div class="score-card-title">Respuesta incorrecta</div>
                        <div class="score-card-val">0 pts</div>
                        <div class="score-card-desc">Sin penalización — puedes intentarlo de nuevo</div>
                    </div>
                    <div class="score-card">
                        <div class="score-card-icon">⭐</div>
                        <div class="score-card-title">Calificación final</div>
                        <div class="score-card-val">1–3 ⭐</div>
                        <div class="score-card-desc">Según el porcentaje de aciertos al finalizar</div>
                    </div>
                    <div class="score-card">
                        <div class="score-card-icon">📊</div>
                        <div class="score-card-title">Progreso</div>
                        <div class="score-card-val">%</div>
                        <div class="score-card-desc">Visible en la barra superior de cada escenario</div>
                    </div>
                </div>
                <div class="score-note">
                    <strong>⭐ ¿Cómo se calculan las estrellas?</strong>
                    Al finalizar un escenario recibirás entre 1 y 3 estrellas según tu porcentaje de aciertos:
                    <strong>⭐ 1 estrella</strong> — menos del 60% · <strong>⭐⭐ 2 estrellas</strong> — entre 60% y 89% · <strong>⭐⭐⭐ 3 estrellas</strong> — 90% o más.
                    El puntaje máximo por escenario depende del número de retos disponibles (ej: 10 retos = 20 pts máximos).
                </div>
            </div>

        </div><!-- /modal-body -->
    </div><!-- /modal -->
</div>


<!-- ══════════════════════════════
     MODAL: ACERCA DE
══════════════════════════════ -->
<div class="modal-overlay about-modal" id="aboutModal" onclick="closeOnOverlay(event,'aboutModal')">
    <div class="modal">
        <div class="modal-head">
            <div class="modal-head-title">ℹ️ Acerca de SEAEA</div>
            <button class="modal-close" onclick="closeModal('aboutModal')">✕</button>
        </div>
        <div class="modal-body about-body">
            <div class="about-logo">SEAEA</div>
            <div class="about-subtitle">Software Educativo para el Aprendizaje de la Estructura Atómica</div>

            <div class="about-row">
                <span class="about-label">Versión</span>
                <span class="about-val">3er Corte — 2026</span>
            </div>
            <div class="about-row">
                <span class="about-label">Autor</span>
                <span class="about-val">Juan Manuel Rivera Ramírez</span>
            </div>
            <div class="about-row">
                <span class="about-label">Supervisor</span>
                <span class="about-val">Edwin Eduardo Millán Rojas</span>
            </div>
            <div class="about-row">
                <span class="about-label">Institución</span>
                <span class="about-val">Universidad de la Amazonia — Facultad de Ingeniería, Programa Ingeniería de Sistemas</span>
            </div>
            <div class="about-row">
                <span class="about-label">Curso</span>
                <span class="about-val">Ingeniería de Software III</span>
            </div>
            <div class="about-row">
                <span class="about-label">Ciudad</span>
                <span class="about-val">Florencia, Caquetá — Colombia</span>
            </div>
            <div class="about-row">
                <span class="about-label">Mascota</span>
                <span class="about-val">Amazonatom 🦜⚛️</span>
            </div>

            <hr class="about-divider">

            <div class="about-row" style="margin-bottom:10px;">
                <span class="about-label">Propósito</span>
                <span class="about-val">Facilitar el aprendizaje progresivo de la estructura atómica mediante visualización interactiva, práctica guiada y retroalimentación inmediata, dirigido a estudiantes de Fundamentos de Química I.</span>
            </div>

            <hr class="about-divider">

            <div style="margin-bottom:10px; font-size:.78rem; font-weight:800; text-transform:uppercase; letter-spacing:.6px; color:var(--text-soft);">Stack tecnológico</div>
            <div class="about-tech">
                <span class="tech-tag">Java</span>
                <span class="tech-tag">Jakarta EE</span>
                <span class="tech-tag">Apache Tomcat</span>
                <span class="tech-tag">MySQL</span>
                <span class="tech-tag">JSP</span>
                <span class="tech-tag">NetBeans IDE</span>
                <span class="tech-tag">HTML5 / CSS3</span>
                <span class="tech-tag">MVC</span>
            </div>
        </div>
    </div>
</div>


<!-- ══════════════════════════════
     JAVASCRIPT
══════════════════════════════ -->
<script>
    // ── Modales ──────────────────────────────────────
    function openModal(id) {
        document.getElementById(id).classList.add('open');
        document.body.style.overflow = 'hidden';
    }
    function closeModal(id) {
        document.getElementById(id).classList.remove('open');
        document.body.style.overflow = '';
    }
    function closeOnOverlay(e, id) {
        if (e.target === document.getElementById(id)) closeModal(id);
    }
    document.addEventListener('keydown', e => {
        if (e.key === 'Escape') {
            closeModal('helpModal');
            closeModal('aboutModal');
        }
    });

    // ── Tabs del modal de ayuda ───────────────────────
    function switchTab(tabId, modalId) {
        const modal = document.getElementById(modalId);
        modal.querySelectorAll('.tab-panel').forEach(p => p.classList.remove('active'));
        modal.querySelectorAll('.tab-btn').forEach(b => b.classList.remove('active'));
        document.getElementById(tabId).classList.add('active');
        modal.querySelector('[data-tab="' + tabId + '"]').classList.add('active');
    }

    // ── Acordeón de escenarios ────────────────────────
    function toggleEsc(id) {
        const el = document.getElementById(id);
        el.classList.toggle('open');
    }

    // ── Acordeón de FAQ ───────────────────────────────
    function toggleFaq(id) {
        const el = document.getElementById(id);
        el.classList.toggle('open');
    }
</script>

</body>
</html>
