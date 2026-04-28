<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%@ page import="modelo.ElementoBase, modelo.Reto" %>
<%
    int     protones      = request.getAttribute("protones")      != null ? (int)request.getAttribute("protones")      : 0;
    int     neutrones     = request.getAttribute("neutrones")     != null ? (int)request.getAttribute("neutrones")     : 0;
    int     masico        = request.getAttribute("numeroMasico")  != null ? (int)request.getAttribute("numeroMasico")  : 0;
    int     porcentaje    = request.getAttribute("porcentaje")    != null ? (int)request.getAttribute("porcentaje")    : 0;
    boolean modoEval      = Boolean.TRUE.equals(request.getAttribute("modoEvaluacion"));
    boolean habCont       = Boolean.TRUE.equals(request.getAttribute("habilitarContinuar"));

    ElementoBase eb   = (ElementoBase) request.getAttribute("elementoIdentificado");
    String simbolo    = (eb != null) ? eb.getSimbolo()  : "";
    String nombreElem = (eb != null) ? eb.getNombre()   : "";

    Reto   retoActual     = (Reto) request.getAttribute("retoActual");
    String descReto       = request.getAttribute("descripcionReto") != null
                            ? (String) request.getAttribute("descripcionReto") : "";
    int    intentosUsados = request.getAttribute("intentosUsados") != null
                            ? (int) request.getAttribute("intentosUsados") : 0;
    int    temporizador   = request.getAttribute("temporizador") != null
                            ? (int) request.getAttribute("temporizador") : 90;
    boolean nuevoReto     = Boolean.TRUE.equals(request.getAttribute("nuevoReto"));

    String  msgMasc       = request.getAttribute("mensajeMascota") != null
                            ? (String) request.getAttribute("mensajeMascota") : "";
    Object  rcObj         = request.getAttribute("resultadoCorrecto");
    boolean correcto      = rcObj != null && (boolean) rcObj;
    boolean tieneResult   = rcObj != null;
    boolean primeraCarga  = Boolean.TRUE.equals(request.getAttribute("primeraCarga"))
                            && !modoEval && !tieneResult && !nuevoReto;

    String retoId    = (retoActual != null) ? String.valueOf(retoActual.getIdReto()) : "";
    String descRetoJs = descReto.replace("\\","\\\\").replace("'","\\'")
                                .replace("\n","\\n").replace("\r","");
    String msgMascJs  = msgMasc.replace("\\","\\\\").replace("`","'")
                               .replace("\n","\\n").replace("\r","");
%>
<!DOCTYPE html>
<html lang="es">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<title>Número y Núcleo Atómico – SEAEA</title>
<link href="https://fonts.googleapis.com/css2?family=Baloo+2:wght@700;800;900&family=Nunito:wght@400;600;700;800&display=swap" rel="stylesheet">
<style>
:root {
    --bg: #dde4f5;
    --panel: #f4f7ff;
    --border: #c5d2ec;
    --blue: #4a86f5;
    --blue-d: #1e56d0;
    --blue-lt: #e0ecff;
    --yellow: #f5c540;
    --yellow-d: #b89000;
    --red: #f46a6a;
    --red-d: #c43a3a;
    --green: #4ec87a;
    --green-d: #2a8a4e;
    --proton-col: #4a86f5;
    --neutron-col: #f5c540;
    --ft: 'Baloo 2', cursive;
    --fb: 'Nunito', sans-serif;
}
*, *::before, *::after { box-sizing: border-box; margin: 0; padding: 0; }
body {
    background: var(--bg);
    font-family: var(--fb);
    min-height: 100vh;
    display: flex;
    align-items: center;
    justify-content: center;
    padding: 12px;
}

/* ══ WRAPPER PRINCIPAL ══ */
.sim {
    background: var(--panel);
    border: 3px solid var(--border);
    border-radius: 28px;
    box-shadow: 0 8px 32px rgba(40,70,160,.13);
    width: 100%;
    max-width: 1060px;
    padding: 14px 20px 16px;
    display: flex;
    flex-direction: column;
    gap: 12px;
}

/* ══ HEADER (3 columnas: título-izq | centro | título-der) ══ */
.header {
    display: grid;
    grid-template-columns: 1fr auto 1fr;
    align-items: center;
    gap: 10px;
}
.h-titulo-iz {
    font-family: var(--ft);
    font-size: 20px;
    font-weight: 900;
    color: var(--blue-d);
    letter-spacing: 1px;
    text-align: left;
    line-height: 1.1;
}
.h-titulo-der {
    font-family: var(--ft);
    font-size: 20px;
    font-weight: 900;
    color: #1a2848;
    letter-spacing: 1px;
    text-align: right;
    line-height: 1.1;
}
.h-centro {
    display: flex;
    flex-direction: column;
    align-items: center;
    gap: 6px;
}
.apz-row {
    display: flex;
    align-items: center;
    gap: 7px;
    white-space: nowrap;
}
.lbl-apz { font-size: 10px; font-weight: 800; color: #7a8cb0; letter-spacing: .8px; }
.pill-pct {
    background: #fde0e0;
    border: 2.5px solid var(--red);
    border-radius: 22px;
    padding: 1px 14px;
    font-size: 17px;
    font-weight: 900;
    color: var(--red-d);
    min-width: 60px;
    text-align: center;
    transition: all .4s;
}
.pill-pct.ok { background: #d2f5e2; border-color: var(--green); color: #1a6e38; }
.prog-track {
    width: 110px; height: 9px;
    background: #dde4f5;
    border-radius: 7px;
    overflow: hidden;
    border: 1.5px solid var(--border);
}
.prog-fill {
    height: 100%;
    border-radius: 7px;
    background: linear-gradient(90deg, #f46a6a 0%, #f5c540 50%, #4ec87a 100%);
    transition: width .7s ease;
}
.eval-row {
    display: flex;
    align-items: center;
    gap: 7px;
}
.eval-hud {
    display: flex;
    align-items: center;
    gap: 6px;
    background: #fff5f5;
    border: 2px solid #fca5a5;
    border-radius: 10px;
    padding: 3px 10px;
}
.hud-t { font-size: 16px; font-weight: 900; color: #ef4444; min-width: 36px; text-align: center; }
.hud-t.ok { color: var(--green-d); }
.hud-sep { width: 1px; height: 18px; background: #fca5a5; }
.hud-i { font-size: 10px; font-weight: 700; color: #666; white-space: nowrap; }
.btn-reto {
    background: var(--blue);
    color: #fff;
    border: none;
    border-radius: 10px;
    padding: 6px 13px;
    font-family: var(--fb);
    font-size: 11px;
    font-weight: 800;
    cursor: pointer;
    white-space: nowrap;
    box-shadow: 0 4px 0 var(--blue-d);
    transition: filter .15s, transform .1s;
}
.btn-reto:hover { filter: brightness(1.08); }
.btn-reto:active { transform: translateY(2px); box-shadow: 0 2px 0 var(--blue-d); }
.btn-reto.fin { background: #e53e3e; box-shadow: 0 4px 0 #a02020; }
.btn-q {
    width: 28px; height: 28px;
    background: #fde8e8;
    border: 2.5px solid #f4a0a0;
    border-radius: 50%;
    font-size: 13px;
    font-weight: 900;
    color: var(--red-d);
    cursor: pointer;
    display: flex;
    align-items: center;
    justify-content: center;
    transition: transform .2s;
}
.btn-q:hover { transform: scale(1.15); }
.btn-q.dis { opacity: .35; pointer-events: none; }

/* ══ CUERPO PRINCIPAL: 2 columnas ══ */
.body-grid {
    display: grid;
    grid-template-columns: 1fr 1fr;
    gap: 14px;
    align-items: start;
}

/* ── COLUMNA IZQUIERDA ── */
.col-left { display: flex; flex-direction: column; gap: 10px; }

/* Panel Z grande */
.z-hero {
    background: linear-gradient(135deg, #e8f0ff 0%, #d8e8ff 100%);
    border: 2px solid #b8d0f8;
    border-radius: 18px;
    padding: 14px 16px;
    text-align: center;
}
.z-hero-lbl {
    font-size: 10px;
    font-weight: 800;
    color: #7a8cb0;
    letter-spacing: 1px;
    text-transform: uppercase;
    margin-bottom: 4px;
}
.z-hero-val {
    font-family: var(--ft);
    font-size: 56px;
    font-weight: 900;
    color: var(--blue);
    line-height: 1;
}
.z-hero-sub {
    font-size: 11px;
    color: #555;
    font-weight: 600;
    margin-top: 3px;
}

/* Panel de conteo con puntos */
.cont-panel {
    background: #fff;
    border: 2px solid var(--border);
    border-radius: 14px;
    padding: 10px 14px;
    display: flex;
    flex-direction: column;
    gap: 7px;
}
.cont-fila {
    display: flex;
    align-items: center;
    gap: 8px;
}
.cont-icono {
    width: 14px;
    height: 14px;
    border-radius: 50%;
    flex-shrink: 0;
    border: 1.5px solid rgba(0,0,0,.12);
}
.ci-p  { background: var(--proton-col); }
.ci-n  { background: var(--neutron-col); }
.cont-lbl { font-size: 12px; font-weight: 700; color: #555; width: 80px; flex-shrink: 0; }
.dots-a { display: flex; flex-wrap: wrap; gap: 3px; flex: 1; min-height: 14px; align-items: center; }
.dot {
    width: 13px; height: 13px;
    border-radius: 50%;
    border: 1.5px solid rgba(0,0,0,.1);
    animation: popDot .18s ease;
}
@keyframes popDot { from { transform: scale(0); } to { transform: scale(1); } }
.d-p { background: var(--proton-col); }
.d-n { background: var(--neutron-col); }
.cont-num { font-size: 14px; font-weight: 800; min-width: 22px; text-align: right; }

/* Controles: 2 grupos (Protones | Neutrones) en fila */
.ctrl-area { display: grid; grid-template-columns: 1fr 1fr; gap: 10px; }
.ctrl-grupo {
    display: flex;
    flex-direction: column;
    align-items: center;
    gap: 0;
    background: #fff;
    border: 2px solid var(--border);
    border-radius: 18px;
    padding: 8px 10px;
    overflow: hidden;
}
.btn-oval {
    width: 100%;
    height: 40px;
    border-radius: 50px;
    border: none;
    font-size: 24px;
    font-weight: 900;
    color: #fff;
    cursor: pointer;
    display: flex;
    align-items: center;
    justify-content: center;
    transition: transform .12s, box-shadow .12s;
    position: relative;
    overflow: hidden;
}
.btn-oval::after {
    content: '';
    position: absolute;
    inset: 0;
    background: rgba(255,255,255,.18);
    opacity: 0;
    transition: opacity .12s;
}
.btn-oval:hover::after { opacity: 1; }
.btn-oval:active { transform: translateY(2px); }
.btn-oval.plus  { background: var(--green);  box-shadow: 0 5px 0 var(--green-d); }
.btn-oval.minus { background: var(--red);    box-shadow: 0 5px 0 var(--red-d); }
.btn-oval.plus:active  { box-shadow: 0 2px 0 var(--green-d); }
.btn-oval.minus:active { box-shadow: 0 2px 0 var(--red-d); }
.ctrl-etiqueta {
    font-size: 13px;
    font-weight: 800;
    color: #fff;
    padding: 6px 0;
    width: 100%;
    text-align: center;
    border-radius: 8px;
    margin: 4px 0;
}
.ce-p { background: var(--blue); }
.ce-n { background: var(--yellow-d); }

/* ── COLUMNA DERECHA ── */
.col-right { display: flex; flex-direction: column; gap: 10px; }

/* Carta del elemento — versión mockup */
.carta-elemento {
    background: #fff;
    border: 3px solid var(--border);
    border-radius: 18px;
    padding: 10px 14px;
    display: flex;
    align-items: center;
    gap: 12px;
    position: relative;
}
.carta-elemento.activa { border-color: var(--blue); background: var(--blue-lt); }
.c-lateral {
    display: flex;
    flex-direction: column;
    align-items: center;
    justify-content: space-between;
    gap: 6px;
    min-width: 36px;
}
.c-masico {
    font-family: var(--ft);
    font-size: 22px;
    font-weight: 900;
    color: #1a2848;
    line-height: 1;
}
.c-z-num {
    font-family: var(--ft);
    font-size: 22px;
    font-weight: 900;
    color: var(--blue);
    line-height: 1;
}
.c-centro {
    flex: 1;
    display: flex;
    flex-direction: column;
    align-items: center;
    justify-content: center;
    gap: 2px;
}
.c-sim {
    font-family: var(--ft);
    font-size: 48px;
    font-weight: 900;
    color: var(--blue);
    line-height: 1;
}
.c-sim.vacio { color: #c5d2ec; }
.c-nombre { font-size: 11px; font-weight: 700; color: #7a8cb0; text-align: center; }

/* Número másico banner */
.masico-banner {
    background: linear-gradient(135deg, var(--blue) 0%, #2563eb 100%);
    border-radius: 16px;
    padding: 12px 16px;
    display: flex;
    align-items: center;
    justify-content: space-between;
    color: #fff;
}
.mb-izq .mb-lbl { font-size: 10px; font-weight: 800; letter-spacing: 1px; opacity: .8; }
.mb-izq .mb-val { font-family: var(--ft); font-size: 46px; font-weight: 900; line-height: 1; }
.mb-formula { font-size: 12px; font-weight: 700; opacity: .75; text-align: right; line-height: 1.6; }

/* Núcleo SVG */
.nucleo-wrap {
    background: #fff;
    border: 2px solid var(--border);
    border-radius: 18px;
    display: flex;
    align-items: center;
    justify-content: center;
    padding: 8px;
    flex: 1;
}
.nucleo-svg { width: 100%; max-width: 280px; height: 220px; overflow: visible; }

/* ══ BOTONES INFERIORES ══ */
.acciones {
    display: flex;
    justify-content: center;
    gap: 10px;
    flex-wrap: wrap;
}
.btn-ac {
    padding: 11px 24px;
    border-radius: 50px;
    border: none;
    font-family: var(--fb);
    font-size: 13px;
    font-weight: 800;
    cursor: pointer;
    letter-spacing: .4px;
    color: #1a2848;
    transition: transform .12s, box-shadow .12s, filter .12s;
}
.btn-ac:hover { filter: brightness(1.07); }
.btn-ac:active { transform: translateY(2px); }
.btn-ac:disabled { opacity: .4; cursor: not-allowed; transform: none; filter: none; }
.ac-r { background: var(--yellow);  box-shadow: 0 5px 0 var(--yellow-d); }
.ac-c { background: var(--blue);    box-shadow: 0 5px 0 var(--blue-d);   color: #fff; }
.ac-v { background: var(--red);     box-shadow: 0 5px 0 var(--red-d);    color: #fff; }
.ac-k { background: var(--green);   box-shadow: 0 5px 0 var(--green-d); }
.ac-r:active { box-shadow: 0 2px 0 var(--yellow-d); }
.ac-c:active { box-shadow: 0 2px 0 var(--blue-d); }
.ac-v:active { box-shadow: 0 2px 0 var(--red-d); }
.ac-k:active { box-shadow: 0 2px 0 var(--green-d); }

/* ══ OVERLAY MASCOTA ══ */
.ov-bg {
    position: fixed; inset: 0;
    background: rgba(15,25,60,.52);
    backdrop-filter: blur(5px);
    z-index: 500;
    display: flex;
    align-items: center;
    justify-content: center;
    opacity: 0;
    pointer-events: none;
    transition: opacity .3s;
}
.ov-bg.vis { opacity: 1; pointer-events: all; }
.masc-card {
    background: #fff;
    border-radius: 26px;
    padding: 26px 34px 22px;
    max-width: 500px;
    width: 92%;
    box-shadow: 0 26px 70px rgba(0,0,0,.22);
    text-align: center;
    transform: scale(.84) translateY(20px);
    transition: transform .38s cubic-bezier(.34,1.56,.64,1);
}
.ov-bg.vis .masc-card { transform: scale(1) translateY(0); }
.m-ava-img {
    width: 90px; height: 90px;
    object-fit: contain;
    margin: 0 auto 10px;
    display: block;
    border-radius: 50%;
    background: #fff8e1;
    padding: 6px;
    box-shadow: 0 4px 16px rgba(74,134,245,.15);
}
.m-ava-img.sm { width: 66px; height: 66px; padding: 4px; }
.m-tit { font-family: var(--ft); font-size: 19px; font-weight: 800; color: #1a2848; margin-bottom: 10px; }
.m-pasos { display: flex; justify-content: center; gap: 7px; margin-bottom: 12px; }
.m-pt { width: 8px; height: 8px; border-radius: 50%; background: var(--border); transition: background .3s, transform .3s; }
.m-pt.act { background: var(--blue); transform: scale(1.4); }
.badge { display: inline-block; padding: 4px 16px; border-radius: 20px; font-size: 13px; font-weight: 800; margin-bottom: 10px; }
.b-ok   { background: #d2f5e2; color: #1a6e38; }
.b-err  { background: #fde0e0; color: var(--red-d); }
.b-warn { background: #fef3cd; color: #856404; }
.m-txt { font-size: 13px; color: #444; line-height: 1.7; margin-bottom: 16px; white-space: pre-line; text-align: left; }
.nuevo-reto-box {
    background: #f0f5ff;
    border: 2px solid var(--border);
    border-radius: 14px;
    padding: 10px 14px;
    margin-bottom: 14px;
    text-align: left;
}
.nuevo-reto-box .nr-tit { font-size: 10px; font-weight: 800; color: #7a8cb0; margin-bottom: 4px; letter-spacing: .5px; text-transform: uppercase; }
.nuevo-reto-box .nr-desc { font-size: 12px; font-weight: 600; color: #1a2848; line-height: 1.5; }
.m-btns { display: flex; gap: 10px; justify-content: center; }
.m-btn { padding: 10px 28px; border-radius: 50px; border: none; font-family: var(--fb); font-size: 14px; font-weight: 800; cursor: pointer; transition: filter .15s, transform .1s; }
.m-btn:active { transform: translateY(2px); }
.mb-p { background: var(--blue); color: #fff; box-shadow: 0 4px 0 var(--blue-d); }
.mb-p:hover { filter: brightness(1.08); }

/* ══ MODAL RETO ══ */
.mod-ov {
    position: fixed; inset: 0;
    background: rgba(15,25,60,.45);
    backdrop-filter: blur(4px);
    z-index: 400;
    display: flex;
    align-items: center;
    justify-content: center;
    opacity: 0;
    pointer-events: none;
    transition: opacity .28s;
}
.mod-ov.show { opacity: 1; pointer-events: all; }
.mod-card {
    background: #fff;
    border-radius: 22px;
    padding: 26px 30px;
    max-width: 460px;
    width: 92%;
    box-shadow: 0 20px 60px rgba(0,0,0,.2);
    transform: scale(.88);
    transition: transform .32s cubic-bezier(.34,1.56,.64,1);
    position: relative;
}
.mod-ov.show .mod-card { transform: scale(1); }
.mod-tit { font-family: var(--ft); font-size: 18px; font-weight: 800; color: #1a2848; margin-bottom: 8px; }
.mod-desc { font-size: 13px; color: #444; line-height: 1.6; margin-bottom: 12px; white-space: pre-line; }
.mod-meta { display: flex; gap: 10px; margin-bottom: 14px; }
.meta-ch { background: #edf2ff; border: 2px solid var(--border); border-radius: 10px; padding: 4px 10px; font-size: 11px; font-weight: 700; color: var(--blue-d); }
.mod-x { position: absolute; top: 12px; right: 14px; background: none; border: none; font-size: 18px; cursor: pointer; color: #bbb; }
.mod-x:hover { color: #ef4444; }

/* Indicador de retos mínimos */
.prog-retos {
    background: #edf2ff;
    border: 1.5px solid var(--border);
    border-radius: 10px;
    padding: 6px 12px;
    display: flex;
    align-items: center;
    gap: 8px;
    font-size: 11px;
    font-weight: 700;
    color: #7a8cb0;
}
.reto-dots { display: flex; gap: 4px; }
.reto-dot {
    width: 10px; height: 10px;
    border-radius: 50%;
    background: #dde4f5;
    border: 1.5px solid #c5d2ec;
    transition: background .3s;
}
.reto-dot.done { background: var(--green); border-color: var(--green-d); }
.reto-dot.fail { background: var(--red);   border-color: var(--red-d); }
</style>
</head>
<body>
<form id="frm" method="post" action="<%= request.getContextPath() %>/escenario2">
    <input type="hidden" name="accion"    id="hdnA" value="">
    <input type="hidden" name="particula" id="hdnP" value="">
</form>

<!-- ══ OVERLAY MASCOTA ══════════════════════════════════════════════════ -->
<div class="ov-bg" id="ovMasc">
  <div class="masc-card">
    <img id="mascImg" src="" alt="AmazonAtom" class="m-ava-img" onerror="this.style.display='none'">
    <div class="m-tit"   id="mTit"></div>
    <div class="m-pasos" id="mPasos"></div>
    <div class="badge"   id="mBadge" style="display:none"></div>
    <div class="m-txt"   id="mTxt"></div>
    <div class="nuevo-reto-box" id="mNuevoReto" style="display:none">
        <div class="nr-tit">📋 Nuevo reto generado</div>
        <div class="nr-desc" id="mNuevoRetoDesc"></div>
    </div>
    <div class="m-btns">
        <button class="m-btn mb-p" id="mBtnP" onclick="mascAccion()">Entendido</button>
    </div>
  </div>
</div>

<!-- ══ MODAL RETO ════════════════════════════════════════════════════════ -->
<div class="mod-ov" id="modReto">
  <div class="mod-card">
    <button class="mod-x" onclick="closeModal()">✕</button>
    <div class="mod-tit">⚛️ Tu reto actual</div>
    <div class="mod-desc" id="modDesc"><%= descReto.isEmpty() ? "Inicia la evaluación para ver tu reto." : descReto %></div>
    <div class="mod-meta">
        <div class="meta-ch">Intentos: <span id="modInt"><%= intentosUsados %></span>/<%= Reto.MAX_INTENTOS %></div>
        <div class="meta-ch">⏱ <span id="modTimer"><%= temporizador %>s</span></div>
    </div>
    <button class="btn-ac ac-c" style="width:100%;border-radius:12px"
            onclick="closeModal();enviar('comprobar','')">✓ Comprobar ahora</button>
  </div>
</div>

<!-- ══ SIMULADOR ════════════════════════════════════════════════════════ -->
<div class="sim">

  <!-- HEADER -->
  <div class="header">
    <div class="h-titulo-iz">NÚMERO<br>ATÓMICO</div>

    <div class="h-centro">
      <div class="apz-row">
        <span class="lbl-apz">APRENDIZAJE</span>
        <div class="pill-pct <%= porcentaje>=80?"ok":"" %>"><%= porcentaje %>%</div>
        <div class="prog-track"><div class="prog-fill" style="width:<%= porcentaje %>%"></div></div>
      </div>
      <div class="eval-row">
        <% if (modoEval) { %>
        <div class="eval-hud">
            <span class="hud-t" id="hudTimer"><%= temporizador %>s</span>
            <div class="hud-sep"></div>
            <span class="hud-i">Intentos: <span id="hudIntVal"><%= intentosUsados %></span>/<%= Reto.MAX_INTENTOS %></span>
        </div>
        <button class="btn-reto fin" onclick="enviar('finalizar','')">FINALIZAR EVAL</button>
        <% } else { %>
        <button class="btn-reto" onclick="enviar('iniciarEval','')">INICIAR EVALUACIÓN</button>
        <% } %>
        <button class="btn-q <%= retoId.isEmpty()?"dis":"" %>" id="btnQ" onclick="openModal()">?</button>
      </div>
      <!-- Indicador de retos (se actualiza por JS) -->
      <div class="prog-retos" id="progRetosWrap" style="<%= !modoEval?"display:none":"" %>">
        <span>Retos:</span>
        <div class="reto-dots" id="retoDots">
          <div class="reto-dot"></div>
          <div class="reto-dot"></div>
          <div class="reto-dot"></div>
        </div>
        <span id="retosTexto">0 / mín. 3</span>
      </div>
    </div>

    <div class="h-titulo-der">NÚCLEO<br>ATÓMICO</div>
  </div>

  <!-- CUERPO -->
  <div class="body-grid">

    <!-- ── COLUMNA IZQUIERDA ── -->
    <div class="col-left">

      <!-- Z grande -->
      <div class="z-hero">
        <div class="z-hero-lbl">NÚMERO ATÓMICO (Z)</div>
        <div class="z-hero-val" id="zHeroVal"><%= protones %></div>
        <div class="z-hero-sub">Z = nº de protones = identidad del elemento</div>
      </div>

      <!-- Panel de conteo con puntos -->
      <div class="cont-panel">
        <div class="cont-fila">
          <span class="cont-icono ci-p"></span>
          <span class="cont-lbl">Protones</span>
          <div class="dots-a" id="dotsP"></div>
          <strong class="cont-num" style="color:var(--proton-col)" id="nP"><%= protones %></strong>
        </div>
        <div class="cont-fila">
          <span class="cont-icono ci-n"></span>
          <span class="cont-lbl">Neutrones</span>
          <div class="dots-a" id="dotsN"></div>
          <strong class="cont-num" style="color:var(--yellow-d)" id="nN"><%= neutrones %></strong>
        </div>
      </div>

      <!-- Controles -->
      <div class="ctrl-area">
        <!-- Protones -->
        <div class="ctrl-grupo">
          <button class="btn-oval plus"  onclick="enviar('incrementar','protones')">+</button>
          <div    class="ctrl-etiqueta ce-p">Protones</div>
          <button class="btn-oval minus" onclick="enviar('decrementar','protones')">−</button>
        </div>
        <!-- Neutrones -->
        <div class="ctrl-grupo">
          <button class="btn-oval plus"  onclick="enviar('incrementar','neutrones')">+</button>
          <div    class="ctrl-etiqueta ce-n">Neutrones</div>
          <button class="btn-oval minus" onclick="enviar('decrementar','neutrones')">−</button>
        </div>
      </div>

    </div><!-- /col-left -->

    <!-- ── COLUMNA DERECHA ── -->
    <div class="col-right">

      <!-- Carta del elemento -->
      <div class="carta-elemento <%= (simbolo!=null&&!simbolo.isEmpty())?"activa":"" %>">
        <div class="c-lateral">
          <span class="c-masico" id="cMas"><%= masico %></span>
          <span class="c-z-num"  id="cZNum"><%= protones %></span>
        </div>
        <div class="c-centro">
          <span class="c-sim <%= (simbolo==null||simbolo.isEmpty())?"vacio":"" %>" id="cSim">
            <%= (simbolo==null||simbolo.isEmpty()) ? "?" : simbolo %>
          </span>
          <span class="c-nombre" id="cNom"><%= (nombreElem==null||nombreElem.isEmpty()) ? "Sin identificar" : nombreElem %></span>
        </div>
      </div>

      <!-- Banner número másico -->
      <div class="masico-banner">
        <div class="mb-izq">
          <div class="mb-lbl">NÚMERO MÁSICO (A)</div>
          <div class="mb-val" id="masicoVal"><%= masico %></div>
        </div>
        <div class="mb-formula">
          A = protones + neutrones<br>
          <span id="formCalc"><%= protones %> + <%= neutrones %> = <%= masico %></span>
        </div>
      </div>

      <!-- Núcleo SVG dinámico -->
      <div class="nucleo-wrap">
        <svg class="nucleo-svg" viewBox="0 0 280 220" id="nucleoSvg">
          <!-- Órbitas decorativas -->
          <ellipse cx="140" cy="110" rx="130" ry="44" fill="none" stroke="#c5d2ec"
                   stroke-width="1.5" stroke-dasharray="6 4" transform="rotate(-35 140 110)" opacity=".5"/>
          <ellipse cx="140" cy="110" rx="130" ry="44" fill="none" stroke="#c5d2ec"
                   stroke-width="1.5" stroke-dasharray="6 4" transform="rotate(35 140 110)" opacity=".5"/>
          <ellipse cx="140" cy="110" rx="130" ry="44" fill="none" stroke="#c5d2ec"
                   stroke-width="1.5" stroke-dasharray="6 4" transform="rotate(90 140 110)" opacity=".4"/>
          <!-- Partículas del núcleo (JS) -->
          <g id="nucleoG"></g>
          <!-- Badge Z -->
          <g id="zBadge" style="display:none">
            <rect id="zBadgeRect" x="110" y="88" width="60" height="44" rx="10" fill="#4a86f5" opacity=".93"/>
            <text x="140" y="105" text-anchor="middle" font-size="10" font-weight="800"
                  fill="rgba(255,255,255,.8)" font-family="Nunito,sans-serif">Z =</text>
            <text id="zBadgeVal" x="140" y="124" text-anchor="middle" font-size="22" font-weight="900"
                  fill="#fff" font-family="'Baloo 2',cursive">0</text>
          </g>
        </svg>
      </div>

    </div><!-- /col-right -->
  </div><!-- /body-grid -->

  <!-- BOTONES INFERIORES -->
  <div class="acciones">
    <button class="btn-ac ac-r" onclick="confirmarReiniciar()">REINICIAR</button>
    <button class="btn-ac ac-c" id="btnComp" <%= !modoEval?"disabled":"" %> onclick="enviar('comprobar','')">COMPROBAR</button>
    <button class="btn-ac ac-v" onclick="confirmarVolver()">VOLVER</button>
    <button class="btn-ac ac-k" id="btnCont" <%= !habCont?"disabled":"" %> onclick="enviar('continuar','')">CONTINUAR</button>
  </div>

</div><!-- /sim -->

<script>
const ST = {
    p:        <%=protones%>,
    n:        <%=neutrones%>,
    modoEval: <%=modoEval%>,
    tiempo:   <%=temporizador%>,
    intentos: <%=intentosUsados%>,
    maxInt:   <%=Reto.MAX_INTENTOS%>,
    retoId:   '<%=retoId%>',
    descReto: '<%=descRetoJs%>'
};

function enviar(a, p) {
    if (timerInvl) { clearInterval(timerInvl); timerInvl = null; }
    document.getElementById('hdnA').value = a;
    document.getElementById('hdnP').value = p;
    document.getElementById('frm').submit();
}
function confirmarReiniciar() { if (confirm('¿Reiniciar? Se perderá el progreso.')) enviar('reiniciar', ''); }
function confirmarVolver()    { if (confirm('¿Volver al menú? Se perderá el progreso.')) enviar('volver', ''); }

/* ── TIMER ── */
let timerSeg = null, timerInvl = null;
function iniciarTimer(segs) {
    if (timerInvl) { clearInterval(timerInvl); timerInvl = null; }
    timerSeg = segs;
    timerInvl = setInterval(() => {
        timerSeg--;
        sessionStorage.setItem('seaea2_timer', timerSeg);
        const txt = timerSeg > 0 ? timerSeg + 's' : '¡Tiempo!';
        const h = document.getElementById('hudTimer');
        const m = document.getElementById('modTimer');
        if (h) { h.textContent = txt; h.className = 'hud-t' + (timerSeg > 20 ? ' ok' : ''); }
        if (m) m.textContent = txt;
        if (timerSeg <= 0) {
            clearInterval(timerInvl); timerInvl = null;
            sessionStorage.removeItem('seaea2_timer');
            sessionStorage.removeItem('seaea2_retoId');
            setTimeout(() => enviar('comprobar', ''), 800);
        }
    }, 1000);
}

/* ── MODAL ── */
function openModal() {
    if (document.getElementById('btnQ').classList.contains('dis')) return;
    const saved = sessionStorage.getItem('seaea2_desc_' + ST.retoId);
    if (saved) document.getElementById('modDesc').textContent = saved;
    document.getElementById('modInt').textContent = ST.intentos;
    document.getElementById('modReto').classList.add('show');
}
function closeModal() { document.getElementById('modReto').classList.remove('show'); }

/* ── GUÍA MASCOTA ── */
const GUIA = [
    { t: '¡Bienvenido!', m: 'Hola, soy AmazonAtom 🦜\nEn este escenario estudiarás el NÚCLEO ATÓMICO\ny el NÚMERO ATÓMICO (Z).\n¡Empecemos!', btn: 'Siguiente →' },
    { t: 'El núcleo atómico', m: '⚛️ El núcleo es el centro del átomo.\nContiene dos tipos de partículas:\n🔵 Protones → carga positiva\n🟡 Neutrones → sin carga', btn: 'Siguiente →' },
    { t: 'El número atómico (Z)', m: '🔑 Z = número de protones.\nZ define la IDENTIDAD del elemento.\n→ Si cambias protones, cambias el elemento.\n→ Si cambias neutrones, el elemento NO cambia.', btn: 'Siguiente →' },
    { t: 'El número másico (A)', m: '📊 A = protones + neutrones\nA cambia cuando agregas o quitas\nprotones o neutrones del núcleo.', btn: 'Siguiente →' },
    { t: '¡Listo para evaluar!', m: '🏆 Presiona INICIAR EVALUACIÓN.\nTendrás 90 segundos y 3 intentos por reto.\nNecesitas acertar al menos 3 retos y alcanzar ≥ 80% para superar el escenario.', btn: '¡Entendido!' }
];

let paso = 0, mGuia = 'inicial', afterCb = null;
function abrirMasc(modo) { mGuia = modo; renderMasc(); document.getElementById('ovMasc').classList.add('vis'); }
function cerrarMasc() { document.getElementById('ovMasc').classList.remove('vis'); if (afterCb) { const f = afterCb; afterCb = null; f(); } }
function mascAccion() { if (mGuia === 'inicial') { if (paso < GUIA.length - 1) { paso++; renderMasc(); } else cerrarMasc(); } else cerrarMasc(); }
function renderMasc() {
    document.getElementById('mascImg').className = mGuia === 'inicial' ? 'm-ava-img' : 'm-ava-img sm';
    document.getElementById('mBadge').style.display = 'none';
    document.getElementById('mNuevoReto').style.display = 'none';
    if (mGuia === 'inicial') {
        const g = GUIA[paso];
        document.getElementById('mTit').textContent = g.t;
        document.getElementById('mTxt').textContent = g.m;
        document.getElementById('mBtnP').textContent = g.btn;
        const w = document.getElementById('mPasos'); w.innerHTML = '';
        GUIA.forEach((_, i) => { const d = document.createElement('div'); d.className = 'm-pt' + (i === paso ? ' act' : ''); w.appendChild(d); });
    }
}
function mostrarRetro(titulo, texto, estado, nuevoDesc, cb) {
    mGuia = 'retro'; afterCb = cb || null;
    document.getElementById('mTit').textContent = titulo;
    document.getElementById('mTxt').textContent = texto;
    document.getElementById('mBtnP').textContent = 'Entendido';
    document.getElementById('mPasos').innerHTML = '';
    document.getElementById('mascImg').className = 'm-ava-img sm';
    const badge = document.getElementById('mBadge');
    const map = { ok: ['badge b-ok','✅ ¡Correcto!'], err: ['badge b-err','❌ Incorrecto'], warn: ['badge b-warn','⏱ Intentos agotados'] };
    if (map[estado]) { badge.className = map[estado][0]; badge.textContent = map[estado][1]; badge.style.display = 'inline-block'; }
    if (nuevoDesc) { document.getElementById('mNuevoRetoDesc').textContent = nuevoDesc; document.getElementById('mNuevoReto').style.display = 'block'; }
    document.getElementById('ovMasc').classList.add('vis');
}

/* ── NÚCLEO SVG ── */
const NS = 'http://www.w3.org/2000/svg';
function hexLayout(total) {
    if (total === 0) return [];
    const pos = [{ x: 0, y: 0 }]; const D = 10 * 2.4; let ring = 1;
    while (pos.length < total) {
        const cnt = 6 * ring; const step = (2 * Math.PI) / cnt;
        for (let i = 0; i < cnt && pos.length < total; i++) {
            const a = step * i; pos.push({ x: D * ring * Math.cos(a), y: D * ring * Math.sin(a) });
        }
        ring++;
    }
    return pos;
}
function dibujarNucleo(p, n) {
    const g = document.getElementById('nucleoG'); g.innerHTML = '';
    const total = p + n;
    const zb = document.getElementById('zBadge');
    if (total > 0) { document.getElementById('zBadgeVal').textContent = p; zb.style.display = 'block'; }
    else { zb.style.display = 'none'; }
    if (total === 0) return;
    const arr = [...Array(p).fill('p'), ...Array(n).fill('n')];
    for (let i = arr.length - 1; i > 0; i--) { const j = Math.floor(Math.random() * (i + 1)); [arr[i], arr[j]] = [arr[j], arr[i]]; }
    hexLayout(total).forEach((pos, i) => {
        const c = document.createElementNS(NS, 'circle');
        c.setAttribute('cx', 140 + pos.x); c.setAttribute('cy', 110 + pos.y); c.setAttribute('r', 9);
        c.setAttribute('fill', arr[i] === 'p' ? '#4a86f5' : '#f5c540');
        c.setAttribute('stroke', 'rgba(0,0,0,.14)'); c.setAttribute('stroke-width', '1.8');
        g.appendChild(c);
    });
}
function renderDots(id, count, cls) {
    const el = document.getElementById(id); if (!el) return; el.innerHTML = '';
    for (let i = 0; i < Math.min(count, 18); i++) { const d = document.createElement('span'); d.className = 'dot ' + cls; el.appendChild(d); }
}

/* ── Indicador de retos completados ── */
function actualizarRetoDots() {
    const count = parseInt(sessionStorage.getItem('seaea2_retos_ok') || '0');
    const dots  = document.querySelectorAll('.reto-dot');
    const fails = parseInt(sessionStorage.getItem('seaea2_retos_fail') || '0');
    document.getElementById('retosTexto').textContent = count + ' / mín. 3';
    dots.forEach((d, i) => {
        d.classList.remove('done', 'fail');
        if (i < count) d.classList.add('done');
    });
}

/* ── INIT ── */
document.addEventListener('DOMContentLoaded', () => {
    dibujarNucleo(ST.p, ST.n);
    renderDots('dotsP', ST.p, 'd-p');
    renderDots('dotsN', ST.n, 'd-n');

    if (ST.modoEval && ST.retoId) {
        const storedId    = sessionStorage.getItem('seaea2_retoId');
        const storedTimer = parseInt(sessionStorage.getItem('seaea2_timer') || '0');
        if (storedId === ST.retoId && storedTimer > 0) {
            iniciarTimer(storedTimer);
        } else {
            sessionStorage.removeItem('seaea2_timer');
            sessionStorage.setItem('seaea2_retoId', ST.retoId);
            sessionStorage.setItem('seaea2_timer', ST.tiempo);
            iniciarTimer(ST.tiempo);
        }
    } else if (!ST.modoEval) {
        sessionStorage.removeItem('seaea2_retoId');
        sessionStorage.removeItem('seaea2_timer');
    }

    if (ST.retoId && ST.descReto) sessionStorage.setItem('seaea2_desc_' + ST.retoId, ST.descReto);
    if (ST.retoId) document.getElementById('btnQ').classList.remove('dis');

    if (ST.modoEval) {
        document.getElementById('progRetosWrap').style.display = 'flex';
        actualizarRetoDots();
    }

    /* ── Lógica mascota ── */
    <% if (tieneResult) { %>
    {
        const ok   = <%=correcto%>;
        const agot = <%=intentosUsados%> >= <%=Reto.MAX_INTENTOS%>;
        const msg  = '<%=msgMascJs%>';
        const nuDesc = '<%=nuevoReto ? descRetoJs : ""%>';

        if (ok) {
            // Sumar reto ok al contador local
            let cnt = parseInt(sessionStorage.getItem('seaea2_retos_ok') || '0');
            sessionStorage.setItem('seaea2_retos_ok', cnt + 1);
            actualizarRetoDots();
        }

        let titulo, estado;
        if (ok)         { titulo = '¡Reto superado! 🎉';    estado = 'ok';   }
        else if (agot)  { titulo = 'Intentos agotados 😔';  estado = 'warn'; }
        else            { titulo = 'Intento fallido';        estado = 'err';  }

        setTimeout(() => {
            mostrarRetro(titulo, msg, estado, nuDesc || null,
                <%=nuevoReto%> ? () => setTimeout(openModal, 350) : null);
        }, 300);
    }
    <% } else if (primeraCarga) { %>
    paso = 0; setTimeout(() => abrirMasc('inicial'), 350);
    <% } else if (nuevoReto && modoEval) { %>
    setTimeout(() => openModal(), 400);
    <% } %>

    // Limpiar contador al reiniciar (detectar salida de eval)
    <% if (!modoEval) { %>
    sessionStorage.removeItem('seaea2_retos_ok');
    sessionStorage.removeItem('seaea2_retos_fail');
    <% } %>
});
</script>
</body>
</html>
