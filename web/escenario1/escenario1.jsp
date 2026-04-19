<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%@ page import="modelo.ElementoBase, modelo.Reto" %>
<%
    int     protones    = request.getAttribute("protones")    != null ? (int)request.getAttribute("protones")    : 0;
    int     neutrones   = request.getAttribute("neutrones")   != null ? (int)request.getAttribute("neutrones")   : 0;
    int     electrones  = request.getAttribute("electrones")  != null ? (int)request.getAttribute("electrones")  : 0;
    int     masico      = request.getAttribute("numeroMasico") != null ? (int)request.getAttribute("numeroMasico"): 0;
    int     cargaNeta   = request.getAttribute("cargaNeta")   != null ? (int)request.getAttribute("cargaNeta")   : 0;
    int     porcentaje  = request.getAttribute("porcentaje")  != null ? (int)request.getAttribute("porcentaje")  : 0;
    boolean modoEval    = request.getAttribute("modoEvaluacion") != null && (boolean)request.getAttribute("modoEvaluacion");
    boolean habCont     = request.getAttribute("habilitarContinuar") != null && (boolean)request.getAttribute("habilitarContinuar");

    ElementoBase eb     = (ElementoBase) request.getAttribute("elementoIdentificado");
    String simbolo      = (eb != null) ? eb.getSimbolo()       : "";
    String nombreElem   = (eb != null) ? eb.getNombre()        : "";
    int    zA           = (eb != null) ? eb.getNumeroAtomico() : 0;

    Reto   retoActual      = (Reto)    request.getAttribute("retoActual");
    String descripcionReto = request.getAttribute("descripcionReto") != null ? (String)request.getAttribute("descripcionReto") : "";
    int    intentosUsados  = request.getAttribute("intentosUsados")  != null ? (int)request.getAttribute("intentosUsados")  : 0;
    int    temporizador    = request.getAttribute("temporizador")    != null ? (int)request.getAttribute("temporizador")    : 90;
    boolean nuevoReto      = request.getAttribute("nuevoReto") != null && (boolean)request.getAttribute("nuevoReto");

    String  mensajeMascota   = request.getAttribute("mensajeMascota") != null ? (String)request.getAttribute("mensajeMascota") : "";
    boolean mostrarMascota   = !mensajeMascota.isEmpty();
    boolean resultadoCorrecto = request.getAttribute("resultadoCorrecto") != null && (boolean)request.getAttribute("resultadoCorrecto");
%>
<!DOCTYPE html>
<html lang="es">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<title>Arma tu Átomo – SEAEA</title>
<link href="https://fonts.googleapis.com/css2?family=Baloo+2:wght@700;800;900&family=Nunito:wght@400;600;700;800&display=swap" rel="stylesheet">
<style>
:root {
    --bg:       #e8edf8;
    --panel:    #ffffff;
    --border:   #d0ddf0;
    --shadow:   0 6px 24px rgba(60,90,180,.12);
    --blue:     #4f8ef7;
    --blue-d:   #2563eb;
    --yellow:   #f6c94e;
    --yellow-d: #d4a017;
    --red:      #f47575;
    --red-d:    #d44f4f;
    --green:    #5ecb82;
    --green-d:  #3a9e5f;
    --proton:   #4f8ef7;
    --neutron:  #f6c94e;
    --electron: #f47db0;
    --title:    'Baloo 2', cursive;
    --body:     'Nunito', sans-serif;
}
*, *::before, *::after { box-sizing: border-box; margin: 0; padding: 0; }
body {
    background: var(--bg);
    font-family: var(--body);
    min-height: 100vh;
    display: flex;
    align-items: center;
    justify-content: center;
    padding: 12px;
}

/* ── WRAPPER PRINCIPAL ─────────────────────────────────── */
.wrapper {
    background: var(--panel);
    border: 2.5px solid var(--border);
    border-radius: 28px;
    box-shadow: var(--shadow);
    width: 100%;
    max-width: 1020px;
    padding: 18px 26px 20px;
    display: flex;
    flex-direction: column;
    gap: 14px;
}

/* ── TOP BAR ───────────────────────────────────────────── */
.top-bar {
    display: flex;
    align-items: center;
    gap: 12px;
}
.lbl-aprendizaje {
    font-size: 12px;
    font-weight: 800;
    color: #888;
    white-space: nowrap;
    letter-spacing: .5px;
}
.pill-porcentaje {
    background: #ffe0e0;
    border: 2.5px solid var(--red);
    border-radius: 20px;
    padding: 3px 16px;
    font-size: 20px;
    font-weight: 900;
    color: var(--red-d);
    min-width: 74px;
    text-align: center;
    transition: all .4s;
    flex-shrink: 0;
}
.pill-porcentaje.ok { background:#d4f5e2; border-color:var(--green); color:#1e6e3a; }

.progress-track {
    flex: 1;
    height: 12px;
    background: #e8edf8;
    border-radius: 8px;
    overflow: hidden;
    border: 1.5px solid var(--border);
}
.progress-fill {
    height: 100%;
    border-radius: 8px;
    background: linear-gradient(90deg, #f47575 0%, #f6c94e 50%, #5ecb82 100%);
    transition: width .7s ease;
}

.titulo {
    font-family: var(--title);
    font-size: 28px;
    font-weight: 900;
    color: #1e2d54;
    letter-spacing: 1px;
    text-align: center;
    flex: 0 0 auto;
    padding: 0 16px;
}

.btn-reto {
    background: var(--blue);
    color: #fff;
    border: none;
    border-radius: 14px;
    padding: 10px 20px;
    font-family: var(--body);
    font-size: 14px;
    font-weight: 800;
    cursor: pointer;
    white-space: nowrap;
    transition: background .2s, transform .1s;
    box-shadow: 0 4px 0 rgba(37,99,235,.3);
    flex-shrink: 0;
}
.btn-reto:hover  { background: var(--blue-d); }
.btn-reto:active { transform: translateY(2px); }
.btn-reto.fin    { background: #ef4444; box-shadow: 0 4px 0 rgba(180,20,20,.3); }
.btn-reto.fin:hover { background: #b91c1c; }

.btn-ayuda {
    background: none; border: none;
    font-size: 24px; font-weight: 900;
    color: var(--red-d); cursor: pointer;
    transition: transform .2s;
    flex-shrink: 0;
}
.btn-ayuda:hover { transform: scale(1.2); }
.btn-ayuda:disabled { opacity: .35; cursor: default; transform: none; }

/* ── ZONA CENTRAL: carta + controles + átomo ───────────── */
.zona-central {
    display: grid;
    grid-template-columns: 200px 1fr 300px;
    gap: 14px;
    align-items: start;
}

/* ─── CARTA ELEMENTO ──────────────────────────────────── */
.carta-elemento {
    background: #f0f5ff;
    border: 2.5px solid var(--border);
    border-radius: 18px;
    padding: 14px 12px 14px 14px;
    display: grid;
    grid-template-columns: 40px 1fr;
    grid-template-rows: auto auto auto;
    gap: 0;
    min-height: 130px;
    align-items: center;
}
.carta-left {
    display: flex;
    flex-direction: column;
    align-items: center;
    gap: 14px;
    padding-right: 6px;
    border-right: 2px solid var(--border);
    height: 100%;
    justify-content: space-between;
    padding-top: 4px;
    padding-bottom: 4px;
}
.carta-masico-val {
    font-size: 22px;
    font-weight: 900;
    color: #1e2d54;
    line-height: 1;
}
.carta-z-val {
    font-size: 22px;
    font-weight: 900;
    color: #1e2d54;
    line-height: 1;
}
.carta-right {
    display: flex;
    flex-direction: column;
    align-items: center;
    justify-content: center;
    padding-left: 10px;
    gap: 2px;
}
.carta-simbolo {
    font-family: var(--title);
    font-size: 46px;
    font-weight: 900;
    color: var(--blue);
    line-height: 1;
}
.carta-nombre {
    font-size: 11px;
    font-weight: 700;
    color: #7a8cb0;
    text-align: center;
    white-space: nowrap;
    overflow: hidden;
    text-overflow: ellipsis;
    max-width: 120px;
}
.carta-vacia .carta-simbolo { color: #bbc8e0; }

/* ─── COLUMNA CENTRAL: carga + contadores + controles ─── */
.col-centro {
    display: flex;
    flex-direction: column;
    gap: 12px;
}

/* Carga neta */
.carga-box {
    background: #f0f5ff;
    border: 2px solid var(--border);
    border-radius: 14px;
    padding: 10px 14px 8px;
}
.carga-scale-labels {
    display: flex;
    justify-content: space-between;
    font-size: 10px;
    color: #999;
    padding: 0 2px;
    margin-bottom: 3px;
}
.carga-track {
    position: relative;
    height: 28px;
    background: linear-gradient(to right, #f47575 0%, #fff 50%, #5ecb82 100%);
    border-radius: 8px;
    border: 1.5px solid var(--border);
    overflow: visible;
}
.carga-marker {
    position: absolute;
    top: -4px; bottom: -4px;
    width: 5px;
    background: #1e2d54;
    border-radius: 3px;
    left: 50%;
    transform: translateX(-50%);
    transition: left .4s cubic-bezier(.34,1.56,.64,1);
    box-shadow: 0 0 6px rgba(0,0,0,.25);
}
.carga-info {
    text-align: center;
    font-size: 13px;
    font-weight: 700;
    color: #444;
    margin-top: 7px;
}

/* Panel contador */
.contador-panel {
    background: #f0f5ff;
    border: 2px solid var(--border);
    border-radius: 14px;
    padding: 10px 14px;
    display: flex;
    flex-direction: column;
    gap: 7px;
}
.contador-fila {
    display: flex;
    align-items: center;
    gap: 10px;
}
.contador-lbl {
    font-size: 13px;
    font-weight: 700;
    color: #555;
    width: 78px;
    flex-shrink: 0;
}
.dots-wrap {
    display: flex;
    flex-wrap: wrap;
    gap: 3px;
    flex: 1;
    min-height: 18px;
}
.dot {
    width: 14px; height: 14px;
    border-radius: 50%;
    border: 1.5px solid rgba(0,0,0,.12);
    transition: transform .2s;
    animation: popIn .2s ease;
}
@keyframes popIn { from{transform:scale(0)} to{transform:scale(1)} }
.dot-p { background: var(--proton); }
.dot-n { background: var(--neutron); }
.dot-e { background: var(--electron); }
.contador-num {
    font-size: 16px;
    font-weight: 800;
    min-width: 26px;
    text-align: right;
}

/* ─── CONTROLES PARTÍCULAS ────────────────────────────── */
.controles-fila {
    display: flex;
    justify-content: center;
    gap: 20px;
}
.ctrl-grupo {
    display: flex;
    flex-direction: column;
    align-items: center;
    gap: 5px;
    width: 120px;
}
/* Botón oval rediseñado: más compacto, con ícono grande */
.btn-oval {
    width: 108px;
    height: 38px;
    border-radius: 50px;
    border: none;
    cursor: pointer;
    font-family: var(--body);
    font-size: 24px;
    font-weight: 900;
    color: #fff;
    display: flex;
    align-items: center;
    justify-content: center;
    transition: transform .12s, filter .12s, box-shadow .12s;
    user-select: none;
    position: relative;
    overflow: hidden;
}
.btn-oval::after {
    content: '';
    position: absolute;
    inset: 0;
    background: rgba(255,255,255,.15);
    opacity: 0;
    transition: opacity .15s;
    border-radius: inherit;
}
.btn-oval:hover::after { opacity: 1; }
.btn-oval:active { transform: translateY(2px) scale(.97); }
.btn-oval.plus {
    background: var(--green);
    box-shadow: 0 5px 0 var(--green-d);
}
.btn-oval.minus {
    background: var(--red);
    box-shadow: 0 5px 0 var(--red-d);
}
.btn-oval.plus:active  { box-shadow: 0 2px 0 var(--green-d); }
.btn-oval.minus:active { box-shadow: 0 2px 0 var(--red-d); }

.lbl-particula {
    width: 108px;
    height: 34px;
    border-radius: 50px;
    display: flex;
    align-items: center;
    justify-content: center;
    font-size: 13px;
    font-weight: 800;
    color: #fff;
    letter-spacing: .3px;
}
.lbl-p { background: var(--blue); }
.lbl-n { background: var(--yellow); color: #5a3c00; }
.lbl-e { background: var(--electron); }

/* ─── ÁTOMO SVG ──────────────────────────────────────── */
.atomo-wrap {
    display: flex;
    align-items: center;
    justify-content: center;
}
.atomo-svg {
    width: 280px;
    height: 280px;
    overflow: visible;
}

/* ─── BOTONES INFERIORES ─────────────────────────────── */
.acciones-fila {
    display: flex;
    justify-content: center;
    gap: 16px;
    margin-top: 2px;
}
.btn-accion {
    padding: 11px 30px;
    border-radius: 14px;
    border: none;
    font-family: var(--body);
    font-size: 14px;
    font-weight: 800;
    cursor: pointer;
    letter-spacing: .5px;
    transition: transform .12s, filter .12s;
    box-shadow: 0 4px 0 rgba(0,0,0,.14);
    color: #1e2d54;
}
.btn-accion:active { transform: translateY(2px); box-shadow: 0 2px 0 rgba(0,0,0,.14); }
.btn-accion:hover  { filter: brightness(1.07); }
.btn-accion:disabled { opacity: .4; cursor: not-allowed; transform: none; filter: none; }
.ba-reiniciar { background: var(--yellow); }
.ba-comprobar { background: var(--blue);   color: #fff; }
.ba-volver    { background: var(--red);    color: #fff; }
.ba-continuar { background: var(--green);  }

/* ─── OVERLAY MASCOTA (centro de pantalla) ───────────── */
.mascota-overlay {
    position: fixed;
    inset: 0;
    background: rgba(20,30,70,.45);
    backdrop-filter: blur(4px);
    z-index: 300;
    display: flex;
    align-items: center;
    justify-content: center;
    opacity: 0;
    pointer-events: none;
    transition: opacity .35s;
}
.mascota-overlay.visible {
    opacity: 1;
    pointer-events: all;
}
.mascota-card {
    background: #fff;
    border-radius: 26px;
    padding: 36px 40px;
    max-width: 520px;
    width: 90%;
    box-shadow: 0 24px 60px rgba(0,0,0,.22);
    text-align: center;
    transform: scale(.85) translateY(24px);
    transition: transform .38s cubic-bezier(.34,1.56,.64,1);
    position: relative;
}
.mascota-overlay.visible .mascota-card {
    transform: scale(1) translateY(0);
}
.mascota-avatar { font-size: 64px; margin-bottom: 12px; line-height: 1; }
.mascota-titulo {
    font-family: var(--title);
    font-size: 22px;
    font-weight: 800;
    color: #1e2d54;
    margin-bottom: 12px;
}
.mascota-texto {
    font-size: 15px;
    color: #444;
    line-height: 1.65;
    margin-bottom: 22px;
}

/* Indicador de pasos */
.mascota-pasos {
    display: flex;
    justify-content: center;
    gap: 8px;
    margin-bottom: 20px;
}
.paso-dot {
    width: 10px; height: 10px;
    border-radius: 50%;
    background: var(--border);
    transition: background .3s, transform .3s;
}
.paso-dot.activo {
    background: var(--blue);
    transform: scale(1.3);
}

.mascota-btn {
    background: var(--blue);
    color: #fff;
    border: none;
    border-radius: 14px;
    padding: 12px 32px;
    font-family: var(--body);
    font-size: 15px;
    font-weight: 800;
    cursor: pointer;
    transition: background .2s, transform .1s;
    box-shadow: 0 4px 0 rgba(37,99,235,.3);
}
.mascota-btn:hover  { background: var(--blue-d); }
.mascota-btn:active { transform: translateY(2px); }
.mascota-btn.cerrar-btn {
    background: #f0f4ff;
    color: var(--blue-d);
    box-shadow: none;
    border: 2px solid var(--border);
    margin-left: 10px;
}

/* Badge resultado */
.resultado-badge {
    display: inline-block;
    padding: 4px 14px;
    border-radius: 20px;
    font-size: 13px;
    font-weight: 800;
    margin-bottom: 12px;
}
.badge-ok  { background: #d4f5e2; color: #1e6e3a; }
.badge-err { background: #ffe0e0; color: var(--red-d); }

/* ─── MODAL RETO ─────────────────────────────────────── */
.modal-overlay {
    position: fixed;
    inset: 0;
    background: rgba(20,30,70,.45);
    backdrop-filter: blur(4px);
    z-index: 200;
    display: flex;
    align-items: center;
    justify-content: center;
    opacity: 0;
    pointer-events: none;
    transition: opacity .3s;
}
.modal-overlay.show { opacity: 1; pointer-events: all; }
.modal-card {
    background: #fff;
    border-radius: 22px;
    padding: 30px 34px;
    max-width: 460px;
    width: 90%;
    box-shadow: 0 20px 60px rgba(0,0,0,.2);
    transform: scale(.88);
    transition: transform .32s cubic-bezier(.34,1.56,.64,1);
    position: relative;
}
.modal-overlay.show .modal-card { transform: scale(1); }
.modal-titulo {
    font-family: var(--title);
    font-size: 20px; font-weight: 800; color: #1e2d54;
    margin-bottom: 10px;
}
.modal-desc { font-size: 14px; color: #444; line-height: 1.6; margin-bottom: 16px; }
.modal-meta { display: flex; gap: 14px; margin-bottom: 18px; }
.meta-chip {
    background: #f0f5ff;
    border: 2px solid var(--border);
    border-radius: 10px;
    padding: 5px 14px;
    font-size: 13px; font-weight: 700; color: var(--blue-d);
}
.timer { font-size: 24px; font-weight: 900; color: #ef4444; }
.timer.ok { color: var(--green-d); }
.modal-cerrar {
    position: absolute; top: 12px; right: 16px;
    background: none; border: none;
    font-size: 20px; cursor: pointer; color: #bbb;
}
.modal-cerrar:hover { color: #ef4444; }
</style>
</head>
<body>

<!-- Formulario oculto para enviar acciones -->
<form id="frmAccion" method="post" action="<%= request.getContextPath() %>/escenario1">
    <input type="hidden" name="accion"    id="hdnAccion"    value="">
    <input type="hidden" name="particula" id="hdnParticula" value="">
</form>

<!-- ══════════════════════════════════════════════════════
     OVERLAY MASCOTA (centro de pantalla)
     ══════════════════════════════════════════════════════ -->
<div class="mascota-overlay" id="mascotaOverlay">
    <div class="mascota-card">
        <div class="mascota-avatar">🦁</div>
        <div class="mascota-titulo" id="mascTitulo">¡Bienvenido a Arma tu Átomo!</div>

        <!-- Indicador de pasos (solo en guía inicial) -->
        <div class="mascota-pasos" id="mascPasos"></div>

        <div class="mascota-texto" id="mascTexto">Cargando...</div>

        <!-- Badge resultado (correcto/incorrecto) -->
        <div id="mascBadge" style="display:none"></div>

        <div>
            <button class="mascota-btn" id="mascBtnPrincipal" onclick="mascotaAccion()">Entendido</button>
            <button class="mascota-btn cerrar-btn" id="mascBtnCerrar" onclick="cerrarMascota()" style="display:none">Cerrar</button>
        </div>
    </div>
</div>

<!-- ══════════════════════════════════════════════════════
     MODAL RETO
     ══════════════════════════════════════════════════════ -->
<div class="modal-overlay" id="modalReto">
    <div class="modal-card">
        <button class="modal-cerrar" onclick="toggleModal()">✕</button>
        <div class="modal-titulo">🔬 Reto actual</div>
        <div class="modal-desc" id="modalDesc">
            <%= descripcionReto.isEmpty() ? "Inicia la evaluación para ver tu reto." : descripcionReto %>
        </div>
        <div class="modal-meta">
            <div class="meta-chip">Intentos: <span id="modalIntentos"><%= intentosUsados %></span>/<%= Reto.MAX_INTENTOS %></div>
            <div class="meta-chip">⏱ <span class="timer" id="timerDisp"><%= temporizador %>s</span></div>
        </div>
        <button class="btn-accion ba-comprobar" style="width:100%;border-radius:12px"
                onclick="toggleModal(); enviar('comprobar','')">✓ COMPROBAR</button>
    </div>
</div>

<!-- ══════════════════════════════════════════════════════
     PANEL PRINCIPAL
     ══════════════════════════════════════════════════════ -->
<div class="wrapper">

    <!-- TOP BAR -->
    <div class="top-bar">
        <span class="lbl-aprendizaje">APRENDIZAJE</span>
        <div class="pill-porcentaje <%= porcentaje >= 80 ? "ok" : "" %>" id="pillPct">
            <%= porcentaje %>%
        </div>
        <div class="progress-track" style="max-width:220px">
            <div class="progress-fill" id="progressFill" style="width:<%= porcentaje %>%"></div>
        </div>

        <div style="flex:1"></div>

        <span class="titulo">ARMA TU ÁTOMO</span>

        <div style="flex:1"></div>

        <% if (modoEval) { %>
        <button class="btn-reto fin" onclick="enviar('finalizar','')">FINALIZAR EVAL</button>
        <% } else { %>
        <button class="btn-reto" onclick="enviar('iniciarEval','')">INICIAR RETO</button>
        <% } %>

        <button class="btn-ayuda" id="btnAyuda"
                onclick="toggleModal()"
                <%= retoActual == null ? "disabled" : "" %>>?</button>
    </div>

    <!-- ZONA CENTRAL -->
    <div class="zona-central">

        <!-- CARTA ELEMENTO -->
        <div class="carta-elemento <%= simbolo.isEmpty() ? "carta-vacia" : "" %>">
            <div class="carta-left">
                <span class="carta-masico-val" id="cartaMasico"><%= masico %></span>
                <span class="carta-z-val"     id="cartaZ"><%= protones %></span>
            </div>
            <div class="carta-right">
                <span class="carta-simbolo" id="cartaSimbolo">
                    <%= simbolo.isEmpty() ? "?" : simbolo %>
                </span>
                <span class="carta-nombre" id="cartaNombre">
                    <%= nombreElem %>
                </span>
            </div>
        </div>

        <!-- COLUMNA CENTRAL -->
        <div class="col-centro">

            <!-- Carga neta -->
            <div class="carga-box">
                <div class="carga-scale-labels">
                    <span>-8</span><span>-6</span><span>-4</span><span>-2</span>
                    <span>0</span>
                    <span>+2</span><span>+4</span><span>+6</span><span>+8</span>
                </div>
                <div class="carga-track">
                    <div class="carga-marker" id="cargaMarker"
                         style="left:<%= 50 + (cargaNeta * 6.25) %>%"></div>
                </div>
                <div class="carga-info">
                    CARGA NETA: <strong id="cargaVal"><%= cargaNeta %></strong>
                    &nbsp;–&nbsp;
                    <span id="cargaDesc">
                        <%= cargaNeta == 0 ? "Neutro" : (cargaNeta > 0 ? "Catión (+" + cargaNeta + ")" : "Anión (" + cargaNeta + ")") %>
                    </span>
                </div>
            </div>

            <!-- Contadores -->
            <div class="contador-panel">
                <div class="contador-fila">
                    <span class="contador-lbl">Protones</span>
                    <div class="dots-wrap" id="dotsP"></div>
                    <strong class="contador-num" style="color:var(--proton)" id="numP"><%= protones %></strong>
                </div>
                <div class="contador-fila">
                    <span class="contador-lbl">Neutrones</span>
                    <div class="dots-wrap" id="dotsN"></div>
                    <strong class="contador-num" style="color:var(--yellow-d)" id="numN"><%= neutrones %></strong>
                </div>
                <div class="contador-fila">
                    <span class="contador-lbl">Electrones</span>
                    <div class="dots-wrap" id="dotsE"></div>
                    <strong class="contador-num" style="color:var(--electron)" id="numE"><%= electrones %></strong>
                </div>
            </div>

            <!-- Controles de partículas -->
            <div class="controles-fila">
                <div class="ctrl-grupo">
                    <button class="btn-oval plus"  onclick="enviar('incrementar','protones')">+</button>
                    <div    class="lbl-particula lbl-p">Protones</div>
                    <button class="btn-oval minus" onclick="enviar('decrementar','protones')">−</button>
                </div>
                <div class="ctrl-grupo">
                    <button class="btn-oval plus"  onclick="enviar('incrementar','neutrones')">+</button>
                    <div    class="lbl-particula lbl-n">Neutrones</div>
                    <button class="btn-oval minus" onclick="enviar('decrementar','neutrones')">−</button>
                </div>
                <div class="ctrl-grupo">
                    <button class="btn-oval plus"  onclick="enviar('incrementar','electrones')">+</button>
                    <div    class="lbl-particula lbl-e">Electrones</div>
                    <button class="btn-oval minus" onclick="enviar('decrementar','electrones')">−</button>
                </div>
            </div>
        </div>

        <!-- ÁTOMO SVG -->
        <div class="atomo-wrap">
            <svg class="atomo-svg" id="atomoSvg" viewBox="0 0 280 280">
                <!-- Órbitas -->
                <circle cx="140" cy="140" r="110" fill="none"
                        stroke="#d0ddf0" stroke-width="1.8" stroke-dasharray="6 4"/>
                <circle cx="140" cy="140" r="72" fill="none"
                        stroke="#d0ddf0" stroke-width="1.8" stroke-dasharray="6 4"/>
                <circle cx="140" cy="140" r="36" fill="none"
                        stroke="#c8d5ea" stroke-width="1.5" stroke-dasharray="4 4"/>
                <g id="nucleoG"></g>
                <g id="electronesG"></g>
            </svg>
        </div>
    </div>

    <!-- BOTONES INFERIORES -->
    <div class="acciones-fila">
        <button class="btn-accion ba-reiniciar" onclick="confirmarReiniciar()">REINICIAR</button>
        <button class="btn-accion ba-comprobar" id="btnComprobar"
                <%= !modoEval ? "disabled" : "" %>
                onclick="enviar('comprobar','')">COMPROBAR</button>
        <button class="btn-accion ba-volver"    onclick="confirmarVolver()">VOLVER</button>
        <button class="btn-accion ba-continuar" id="btnContinuar"
                <%= !habCont ? "disabled" : "" %>
                onclick="enviar('continuar','')">CONTINUAR</button>
    </div>

</div><!-- fin wrapper -->

<script>
// ── Estado inicial desde servidor ─────────────────────────
let protones   = <%= protones %>;
let neutrones  = <%= neutrones %>;
let electrones = <%= electrones %>;
let cargaNeta  = <%= cargaNeta %>;
let modoEval   = <%= modoEval %>;
let tiempoReto = <%= temporizador %>;
let timerIntvl = null;

// ── Envío ──────────────────────────────────────────────────
function enviar(accion, particula) {
    document.getElementById('hdnAccion').value    = accion;
    document.getElementById('hdnParticula').value = particula;
    document.getElementById('frmAccion').submit();
}
function confirmarReiniciar() {
    if (confirm('¿Reiniciar el simulador? Se perderá el progreso actual.'))
        enviar('reiniciar','');
}
function confirmarVolver() {
    if (confirm('¿Volver al menú? Se perderá el progreso del escenario.'))
        enviar('volver','');
}

// ── Modal reto ─────────────────────────────────────────────
function toggleModal() {
    const m = document.getElementById('modalReto');
    m.classList.toggle('show');
    if (m.classList.contains('show') && modoEval) iniciarTimer();
    else detenerTimer();
}

// ── Temporizador ───────────────────────────────────────────
function iniciarTimer() {
    detenerTimer();
    let t = tiempoReto;
    const el = document.getElementById('timerDisp');
    timerIntvl = setInterval(() => {
        t--;
        el.textContent = t + 's';
        el.className   = 'timer' + (t > 20 ? ' ok' : '');
        if (t <= 0) {
            detenerTimer();
            el.textContent = '¡Tiempo!';
            setTimeout(() => {
                document.getElementById('modalReto').classList.remove('show');
                enviar('comprobar','');
            }, 900);
        }
    }, 1000);
}
function detenerTimer() {
    if (timerIntvl) { clearInterval(timerIntvl); timerIntvl = null; }
}

// ── MASCOTA: guía paso a paso ──────────────────────────────
const GUIA_PASOS = [
    {
        titulo: '¡Bienvenido a Arma tu Átomo!',
        texto:  'Hola, soy AmazonAtom 🦁 Tu guía en este recorrido. En este simulador vas a construir átomos de verdad, igual que lo hace la naturaleza.',
        btn:    'Siguiente →'
    },
    {
        titulo: 'Las partículas subatómicas',
        texto:  '⚛️ Un átomo está formado por tres tipos de partículas:\n• Protones (azul) → carga positiva, determinan el elemento\n• Neutrones (amarillo) → sin carga, estabilizan el núcleo\n• Electrones (rosa) → carga negativa, orbitan el núcleo',
        btn:    'Siguiente →'
    },
    {
        titulo: 'Cómo usar los controles',
        texto:  '🟢 Usa el botón + para agregar una partícula\n🔴 Usa el botón − para quitar una partícula\n\nObserva cómo cambia el átomo en tiempo real al lado derecho.',
        btn:    'Siguiente →'
    },
    {
        titulo: 'El elemento y la carga neta',
        texto:  '🔬 El número de protones define el elemento (Z = protones).\n⚡ La carga neta = protones − electrones.\nSi son iguales → Neutro. Si hay más protones → Catión (+). Si hay más electrones → Anión (−).',
        btn:    'Siguiente →'
    },
    {
        titulo: '¡Hora de evaluarte!',
        texto:  '🏆 Cuando te sientas listo, presiona INICIAR RETO. El sistema te dará un átomo a construir con 90 segundos y 3 intentos.\n\n¡Buena suerte, científico!',
        btn:    '¡Empezar!'
    }
];

let pasoActual = 0;
let modoGuia   = false;

function mostrarGuiaInicial() {
    pasoActual = 0;
    modoGuia   = true;
    renderPaso();
    abrirMascota();
}

function renderPaso() {
    const paso = GUIA_PASOS[pasoActual];
    document.getElementById('mascTitulo').textContent = paso.titulo;
    // Convertir \n en <br>
    document.getElementById('mascTexto').innerHTML =
        paso.texto.replace(/\n/g, '<br>');
    document.getElementById('mascBtnPrincipal').textContent = paso.btn;
    document.getElementById('mascBtnCerrar').style.display = 'none';
    document.getElementById('mascBadge').style.display = 'none';

    // Puntos de progreso
    const wrap = document.getElementById('mascPasos');
    wrap.innerHTML = '';
    GUIA_PASOS.forEach((_, i) => {
        const d = document.createElement('div');
        d.className = 'paso-dot' + (i === pasoActual ? ' activo' : '');
        wrap.appendChild(d);
    });
}

function mascotaAccion() {
    if (modoGuia) {
        if (pasoActual < GUIA_PASOS.length - 1) {
            pasoActual++;
            renderPaso();
        } else {
            cerrarMascota();
        }
    } else {
        cerrarMascota();
    }
}

function mostrarMascotaMensaje(titulo, texto, correcto) {
    modoGuia = false;
    document.getElementById('mascTitulo').textContent = titulo;
    document.getElementById('mascTexto').innerHTML = texto.replace(/\n/g,'<br>');
    document.getElementById('mascPasos').innerHTML = '';
    document.getElementById('mascBtnPrincipal').textContent = 'Entendido';
    document.getElementById('mascBtnCerrar').style.display = 'none';

    const badge = document.getElementById('mascBadge');
    if (correcto === true) {
        badge.className = 'resultado-badge badge-ok';
        badge.textContent = '✅ ¡Correcto!';
        badge.style.display = 'inline-block';
    } else if (correcto === false) {
        badge.className = 'resultado-badge badge-err';
        badge.textContent = '❌ Incorrecto';
        badge.style.display = 'inline-block';
    } else {
        badge.style.display = 'none';
    }
    abrirMascota();
}

function abrirMascota() {
    document.getElementById('mascotaOverlay').classList.add('visible');
}
function cerrarMascota() {
    document.getElementById('mascotaOverlay').classList.remove('visible');
    modoGuia = false;
}

// ── ÁTOMO SVG ──────────────────────────────────────────────
const R_P = 9, R_N = 9, R_E = 9;   // mismo radio para las 3 partículas

function dibujarAtomo() {
    dibujarNucleo();
    dibujarElectrones();
}

function dibujarNucleo() {
    const g = document.getElementById('nucleoG');
    g.innerHTML = '';
    const total = protones + neutrones;
    if (total === 0) return;

    const partsArr = [];
    for (let i = 0; i < protones;  i++) partsArr.push('p');
    for (let i = 0; i < neutrones; i++) partsArr.push('n');
    // Mezclar
    for (let i = partsArr.length - 1; i > 0; i--) {
        const j = Math.floor(Math.random() * (i + 1));
        [partsArr[i], partsArr[j]] = [partsArr[j], partsArr[i]];
    }

    const cols   = Math.ceil(Math.sqrt(total));
    const gap    = Math.min(22, total <= 4 ? 22 : 18);
    const totalW = (cols - 1) * gap;
    const rows   = Math.ceil(total / cols);
    const totalH = (rows - 1) * gap;
    const startX = 140 - totalW / 2;
    const startY = 140 - totalH / 2;

    partsArr.forEach((tipo, idx) => {
        const col = idx % cols;
        const row = Math.floor(idx / cols);
        const x = startX + col * gap + (row % 2 === 0 ? 0 : gap * .35);
        const y = startY + row * gap;
        const c = document.createElementNS('http://www.w3.org/2000/svg','circle');
        c.setAttribute('cx', x);
        c.setAttribute('cy', y);
        c.setAttribute('r',  R_P);
        c.setAttribute('fill', tipo === 'p' ? '#4f8ef7' : '#f6c94e');
        c.setAttribute('stroke','rgba(0,0,0,.12)');
        c.setAttribute('stroke-width','1.5');
        c.style.animation = 'popIn .2s ease';
        g.appendChild(c);
    });
}

function dibujarElectrones() {
    const g = document.getElementById('electronesG');
    g.innerHTML = '';
    if (electrones === 0) return;

    const orbitas = [
        { r: 36,  max: 2  },
        { r: 72,  max: 8  },
        { r: 110, max: 18 }
    ];

    let eRest = electrones;
    orbitas.forEach(orb => {
        if (eRest <= 0) return;
        const enOrb = Math.min(eRest, orb.max);
        eRest -= enOrb;
        const step = (2 * Math.PI) / enOrb;
        for (let i = 0; i < enOrb; i++) {
            const ang = i * step - Math.PI / 2;
            const ex  = 140 + orb.r * Math.cos(ang);
            const ey  = 140 + orb.r * Math.sin(ang);
            const c = document.createElementNS('http://www.w3.org/2000/svg','circle');
            c.setAttribute('cx', ex);
            c.setAttribute('cy', ey);
            c.setAttribute('r',  R_E);
            c.setAttribute('fill','#f47db0');
            c.setAttribute('stroke','rgba(0,0,0,.12)');
            c.setAttribute('stroke-width','1.5');
            c.style.animation = 'popIn .25s ease';
            g.appendChild(c);
        }
    });
}

// ── Dots contadores ────────────────────────────────────────
function renderDots(id, count, cls) {
    const el = document.getElementById(id);
    if (!el) return;
    const actual = el.querySelectorAll('.dot').length;
    if (count > actual) {
        for (let i = actual; i < Math.min(count, 14); i++) {
            const d = document.createElement('span');
            d.className = 'dot ' + cls;
            el.appendChild(d);
        }
    } else {
        while (el.querySelectorAll('.dot').length > Math.min(count, 14))
            el.removeChild(el.lastChild);
    }
}

// ── Carga neta ─────────────────────────────────────────────
function actualizarCarga() {
    const cl = Math.max(-8, Math.min(8, cargaNeta));
    document.getElementById('cargaMarker').style.left = (50 + cl * 6.25) + '%';
    document.getElementById('cargaVal').textContent   = cargaNeta;
    document.getElementById('cargaDesc').textContent  =
        cargaNeta === 0 ? 'Neutro'
        : cargaNeta > 0 ? 'Catión (+' + cargaNeta + ')'
        : 'Anión (' + cargaNeta + ')';
}

// ── Init ───────────────────────────────────────────────────
document.addEventListener('DOMContentLoaded', () => {
    dibujarAtomo();
    renderDots('dotsP', protones,   'dot-p');
    renderDots('dotsN', neutrones,  'dot-n');
    renderDots('dotsE', electrones, 'dot-e');
    actualizarCarga();

    <% if (mostrarMascota) {
        boolean esPrimeraCarga = mensajeMascota.equals(
            new modelo.Escenario(1,"",3).guiaMascota()
        );
    %>
    // Mostrar guía paso a paso en la primera carga
    setTimeout(() => {
        <% if (esPrimeraCarga) { %>
        mostrarGuiaInicial();
        <% } else { %>
        mostrarMascotaMensaje(
            '<%= resultadoCorrecto ? "¡Correcto!" : "AmazonAtom dice..." %>',
            '<%= mensajeMascota.replace("'","\\'").replace("\n"," ") %>',
            <%= resultadoCorrecto ? "true" : (request.getAttribute("resultadoCorrecto") != null ? "false" : "null") %>
        );
        <% } %>
    }, 300);
    <% } %>

    <% if (nuevoReto) { %>
    setTimeout(() => toggleModal(), 700);
    <% } %>
});
</script>
</body>
</html>
