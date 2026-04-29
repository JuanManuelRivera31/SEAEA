<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%@ page import="modelo.ElementoBase, modelo.Reto" %>
<%
    int     protones   = request.getAttribute("protones")     != null ? (int)request.getAttribute("protones")     : 0;
    int     neutrones  = request.getAttribute("neutrones")    != null ? (int)request.getAttribute("neutrones")    : 0;
    int     masico     = request.getAttribute("numeroMasico") != null ? (int)request.getAttribute("numeroMasico") : 0;
    int     porcentaje = request.getAttribute("porcentaje")   != null ? (int)request.getAttribute("porcentaje")   : 0;
    boolean modoEval   = Boolean.TRUE.equals(request.getAttribute("modoEvaluacion"));
    boolean habCont    = Boolean.TRUE.equals(request.getAttribute("habilitarContinuar"));

    ElementoBase eb   = (ElementoBase) request.getAttribute("elementoIdentificado");
    String simbolo    = (eb != null) ? eb.getSimbolo() : "";
    String nombreElem = (eb != null) ? eb.getNombre()  : "";
    boolean hayElem   = eb != null;

    Reto   retoActual     = (Reto) request.getAttribute("retoActual");
    String descReto       = request.getAttribute("descripcionReto") != null ? (String)request.getAttribute("descripcionReto") : "";
    int    intentosUsados = request.getAttribute("intentosUsados")  != null ? (int)request.getAttribute("intentosUsados")    : 0;
    int    temporizador   = request.getAttribute("temporizador")    != null ? (int)request.getAttribute("temporizador")      : 90;
    boolean nuevoReto     = Boolean.TRUE.equals(request.getAttribute("nuevoReto"));

    String msgMasc    = request.getAttribute("mensajeMascota") != null ? (String)request.getAttribute("mensajeMascota") : "";
    Object rcObj      = request.getAttribute("resultadoCorrecto");
    boolean correcto  = rcObj != null && (boolean)rcObj;
    boolean tieneResult  = rcObj != null;
    boolean primeraCarga = Boolean.TRUE.equals(request.getAttribute("primeraCarga")) && !modoEval && !tieneResult && !nuevoReto;

    String retoId     = (retoActual != null) ? String.valueOf(retoActual.getIdReto()) : "";
    String descRetoJs = descReto.replace("\\","\\\\").replace("'","\\'").replace("\n","\\n").replace("\r","");
    String msgMascJs  = msgMasc.replace("\\","\\\\").replace("`","'").replace("\n","\\n").replace("\r","");
%>
<!DOCTYPE html>
<html lang="es">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<title>Número y Núcleo Atómico – SEAEA</title>
<link href="https://fonts.googleapis.com/css2?family=Baloo+2:wght@700;800;900&family=Nunito:wght@400;600;700;800&display=swap" rel="stylesheet">
<style>
:root{
    --bg:#dde4f5; --panel:#f4f7ff; --border:#c5d2ec;
    --blue:#4a86f5; --blue-d:#1e56d0; --blue-lt:#e0ecff;
    --yellow:#f5c540; --yellow-d:#b89000;
    --red:#f46a6a; --red-d:#c43a3a;
    --green:#4ec87a; --green-d:#2a8a4e;
    --ft:'Baloo 2',cursive; --fb:'Nunito',sans-serif;
}
*,*::before,*::after{box-sizing:border-box;margin:0;padding:0}
body{background:var(--bg);font-family:var(--fb);min-height:100vh;
     display:flex;align-items:center;justify-content:center;padding:12px}

/* ══ WRAPPER ══ */
.sim{background:var(--panel);border:3px solid var(--border);border-radius:28px;
     box-shadow:0 8px 32px rgba(40,70,160,.13);width:100%;max-width:1060px;
     padding:14px 22px 18px;display:flex;flex-direction:column;gap:12px}

/* ══ BARRA SUPERIOR: 3 columnas ══ */
.top-bar{display:grid;grid-template-columns:1fr auto 1fr;align-items:center;gap:10px}
.ttl-iz{font-family:var(--ft);font-size:22px;font-weight:900;color:var(--blue-d);letter-spacing:1px;line-height:1.15}
.ttl-der{font-family:var(--ft);font-size:22px;font-weight:900;color:#1a2848;letter-spacing:1px;line-height:1.15;text-align:right}
.top-centro{display:flex;flex-direction:column;align-items:center;gap:6px}
.pct-row{display:flex;align-items:center;gap:7px}
.lbl-apz{font-size:10px;font-weight:800;color:#7a8cb0;letter-spacing:.8px;white-space:nowrap}
.pill-pct{background:#fde0e0;border:2.5px solid var(--red);border-radius:22px;
    padding:2px 14px;font-size:17px;font-weight:900;color:var(--red-d);
    min-width:58px;text-align:center;transition:all .4s}
.pill-pct.ok{background:#d2f5e2;border-color:var(--green);color:#1a6e38}
.prog-track{width:100px;height:9px;background:#dde4f5;border-radius:7px;overflow:hidden;border:1.5px solid var(--border)}
.prog-fill{height:100%;border-radius:7px;background:linear-gradient(90deg,#f46a6a 0%,#f5c540 50%,#4ec87a 100%);transition:width .7s ease}
.eval-row{display:flex;align-items:center;gap:7px}
.eval-hud{display:flex;align-items:center;gap:6px;background:#fff5f5;border:2px solid #fca5a5;border-radius:10px;padding:3px 10px}
.hud-t{font-size:16px;font-weight:900;color:#ef4444;min-width:34px;text-align:center}
.hud-t.ok{color:var(--green-d)}
.hud-sep{width:1px;height:18px;background:#fca5a5}
.hud-i{font-size:10px;font-weight:700;color:#666;white-space:nowrap}
.btn-reto{background:var(--blue);color:#fff;border:none;border-radius:10px;
    padding:7px 14px;font-family:var(--fb);font-size:11px;font-weight:800;
    cursor:pointer;white-space:nowrap;box-shadow:0 4px 0 var(--blue-d);transition:filter .15s,transform .1s}
.btn-reto:hover{filter:brightness(1.08)}
.btn-reto:active{transform:translateY(2px);box-shadow:0 2px 0 var(--blue-d)}
.btn-reto.fin{background:#e53e3e;box-shadow:0 4px 0 #a02020}
.btn-q{width:28px;height:28px;background:#fde8e8;border:2.5px solid #f4a0a0;
    border-radius:50%;font-size:13px;font-weight:900;color:var(--red-d);cursor:pointer;
    display:flex;align-items:center;justify-content:center;transition:transform .2s}
.btn-q:hover{transform:scale(1.15)}
.btn-q.dis{opacity:.35;pointer-events:none}
.retos-ind{display:flex;align-items:center;gap:6px;background:#edf2ff;
    border:1.5px solid var(--border);border-radius:10px;padding:4px 10px;
    font-size:11px;font-weight:700;color:#7a8cb0}
.reto-dots{display:flex;gap:4px}
.reto-dot{width:10px;height:10px;border-radius:50%;background:#dde4f5;border:1.5px solid #c5d2ec;transition:background .3s}
.reto-dot.done{background:var(--green);border-color:var(--green-d)}

/* ══ GRID: 2 columnas ══ */
.body-grid{display:grid;grid-template-columns:1fr 1fr;gap:16px;align-items:start}

/* ────────────────────────────
   COLUMNA IZQUIERDA
   1. Badge Z
   2. Controles +/−
   3. Panel conteo
   4. Banner másico
   ──────────────────────────── */
.col-left{display:flex;flex-direction:column;gap:10px}

/* 1. Badge Z */
.z-card{background:linear-gradient(135deg,#eaf0ff,#d4e4ff);border:2px solid #b8d0f8;
    border-radius:18px;padding:12px 18px;display:flex;align-items:center;justify-content:space-between}
.z-card-info{display:flex;flex-direction:column}
.z-card-lbl{font-size:10px;font-weight:800;color:#5a78b0;letter-spacing:.8px;text-transform:uppercase;margin-bottom:2px}
.z-card-sub{font-size:11px;font-weight:600;color:#7a98c8;margin-top:3px}
.z-card-val{font-family:var(--ft);font-size:58px;font-weight:900;color:var(--blue);line-height:1}

/* 2. Controles */
.ctrl-area{display:grid;grid-template-columns:1fr 1fr;gap:10px}
.ctrl-grupo{display:flex;flex-direction:column;align-items:stretch;gap:0;
    background:#fff;border:2px solid var(--border);border-radius:20px;padding:8px 10px}
.btn-oval{width:100%;height:42px;border-radius:50px;border:none;font-size:26px;
    font-weight:900;color:#fff;cursor:pointer;display:flex;align-items:center;
    justify-content:center;transition:transform .12s,box-shadow .12s;position:relative;overflow:hidden}
.btn-oval::after{content:'';position:absolute;inset:0;background:rgba(255,255,255,.18);opacity:0;transition:opacity .12s}
.btn-oval:hover::after{opacity:1}
.btn-oval:active{transform:translateY(2px)}
.btn-oval.plus {background:var(--green);box-shadow:0 5px 0 var(--green-d)}
.btn-oval.minus{background:var(--red);  box-shadow:0 5px 0 var(--red-d)}
.btn-oval.plus:active {box-shadow:0 2px 0 var(--green-d)}
.btn-oval.minus:active{box-shadow:0 2px 0 var(--red-d)}
.ctrl-etiq{font-size:13px;font-weight:800;color:#fff;text-align:center;
    border-radius:8px;padding:6px 0;margin:5px 0}
.ce-p{background:var(--blue)}
.ce-n{background:var(--yellow-d)}

/* 3. Panel conteo */
.cont-panel{background:#fff;border:2px solid var(--border);border-radius:14px;padding:10px 14px;
    display:flex;flex-direction:column;gap:8px}
.cont-fila{display:flex;align-items:center;gap:8px}
.cont-circ{width:14px;height:14px;border-radius:50%;flex-shrink:0;border:1.5px solid rgba(0,0,0,.12)}
.cc-p{background:var(--blue)}
.cc-n{background:var(--yellow)}
.cont-lbl{font-size:12px;font-weight:700;color:#555;width:78px;flex-shrink:0}
.dots-wrap{display:flex;flex-wrap:wrap;gap:3px;flex:1;min-height:14px;align-items:center}
.dot{width:13px;height:13px;border-radius:50%;border:1.5px solid rgba(0,0,0,.1);animation:popDot .18s ease}
@keyframes popDot{from{transform:scale(0)}to{transform:scale(1)}}
.d-p{background:var(--blue)}
.d-n{background:var(--yellow)}
.cont-num{font-size:14px;font-weight:800;min-width:22px;text-align:right}

/* 4. Banner másico */
.masico-banner{background:linear-gradient(135deg,var(--blue),#2563eb);border-radius:14px;
    padding:11px 16px;display:flex;align-items:center;justify-content:space-between;color:#fff}
.mb-lbl{font-size:10px;font-weight:800;letter-spacing:1px;opacity:.8;margin-bottom:2px}
.mb-val{font-family:var(--ft);font-size:38px;font-weight:900;line-height:1}
.mb-formula{font-size:11px;font-weight:700;opacity:.75;text-align:right;line-height:1.7}

/* ────────────────────────────
   COLUMNA DERECHA
   1. Átomo grande (sin badge Z)
   2. Carta elemento
   ──────────────────────────── */
.col-right{display:flex;flex-direction:column;gap:10px}

/* 1. Átomo */
.atomo-wrap{background:#fff;border:2px solid var(--border);border-radius:18px;
    display:flex;align-items:center;justify-content:center;padding:10px;min-height:270px}
.atomo-svg{width:100%;max-width:320px;height:260px;overflow:visible}

/* 2. Carta elemento */
.carta-elem{background:#edf2ff;border:2.5px solid var(--border);border-radius:18px;
    padding:12px 18px;display:flex;align-items:center;gap:14px;transition:all .3s}
.carta-elem.activa{border-color:var(--blue);background:var(--blue-lt);box-shadow:0 0 0 3px rgba(74,134,245,.18)}
.carta-lateral{display:flex;flex-direction:column;align-items:center;gap:4px;min-width:38px}
.carta-masico{font-family:var(--ft);font-size:22px;font-weight:900;color:#1a2848;line-height:1}
.carta-z     {font-family:var(--ft);font-size:22px;font-weight:900;color:var(--blue);line-height:1}
.carta-centro{flex:1;display:flex;flex-direction:column;align-items:center;gap:3px}
.carta-sim{font-family:var(--ft);font-size:56px;font-weight:900;color:var(--blue);line-height:1}
.carta-sim.vacio{color:#c5d2ec}
.carta-nombre{font-size:12px;font-weight:700;color:#7a8cb0;text-align:center}

/* ══ BOTONES INFERIORES ══ */
.acciones{display:flex;justify-content:center;gap:10px;flex-wrap:wrap;margin-top:2px}
.btn-ac{padding:11px 26px;border-radius:50px;border:none;font-family:var(--fb);
    font-size:13px;font-weight:800;cursor:pointer;letter-spacing:.4px;color:#1a2848;
    transition:transform .12s,box-shadow .12s,filter .12s}
.btn-ac:hover{filter:brightness(1.07)}
.btn-ac:active{transform:translateY(2px)}
.btn-ac:disabled{opacity:.4;cursor:not-allowed;transform:none;filter:none}
.ac-r{background:var(--yellow);box-shadow:0 5px 0 var(--yellow-d)}
.ac-c{background:var(--blue);  box-shadow:0 5px 0 var(--blue-d);color:#fff}
.ac-v{background:var(--red);   box-shadow:0 5px 0 var(--red-d); color:#fff}
.ac-k{background:var(--green); box-shadow:0 5px 0 var(--green-d)}
.ac-r:active{box-shadow:0 2px 0 var(--yellow-d)}
.ac-c:active{box-shadow:0 2px 0 var(--blue-d)}
.ac-v:active{box-shadow:0 2px 0 var(--red-d)}
.ac-k:active{box-shadow:0 2px 0 var(--green-d)}

/* ══ OVERLAY MASCOTA ══ */
.ov-bg{position:fixed;inset:0;background:rgba(15,25,60,.52);backdrop-filter:blur(5px);
    z-index:500;display:flex;align-items:center;justify-content:center;
    opacity:0;pointer-events:none;transition:opacity .3s}
.ov-bg.vis{opacity:1;pointer-events:all}
.masc-card{background:#fff;border-radius:26px;padding:26px 34px 22px;max-width:500px;
    width:92%;box-shadow:0 26px 70px rgba(0,0,0,.22);text-align:center;
    transform:scale(.84) translateY(20px);transition:transform .38s cubic-bezier(.34,1.56,.64,1)}
.ov-bg.vis .masc-card{transform:scale(1) translateY(0)}
.m-ava-img{width:90px;height:90px;object-fit:contain;margin:0 auto 10px;display:block;
    border-radius:50%;background:#fff8e1;padding:6px;box-shadow:0 4px 16px rgba(74,134,245,.15)}
.m-ava-img.sm{width:66px;height:66px;padding:4px}
.m-tit{font-family:var(--ft);font-size:19px;font-weight:800;color:#1a2848;margin-bottom:10px}
.m-pasos{display:flex;justify-content:center;gap:7px;margin-bottom:12px}
.m-pt{width:8px;height:8px;border-radius:50%;background:var(--border);transition:background .3s,transform .3s}
.m-pt.act{background:var(--blue);transform:scale(1.4)}
.badge{display:inline-block;padding:4px 16px;border-radius:20px;font-size:13px;font-weight:800;margin-bottom:10px}
.b-ok  {background:#d2f5e2;color:#1a6e38}
.b-err {background:#fde0e0;color:var(--red-d)}
.b-warn{background:#fef3cd;color:#856404}
.m-txt{font-size:13px;color:#444;line-height:1.7;margin-bottom:16px;white-space:pre-line;text-align:left}
.nuevo-reto-box{background:#f0f5ff;border:2px solid var(--border);border-radius:14px;
    padding:10px 14px;margin-bottom:14px;text-align:left}
.nuevo-reto-box .nr-tit{font-size:10px;font-weight:800;color:#7a8cb0;margin-bottom:4px;letter-spacing:.5px;text-transform:uppercase}
.nuevo-reto-box .nr-desc{font-size:12px;font-weight:600;color:#1a2848;line-height:1.5}
.m-btns{display:flex;gap:10px;justify-content:center}
.m-btn{padding:10px 28px;border-radius:50px;border:none;font-family:var(--fb);font-size:14px;
    font-weight:800;cursor:pointer;transition:filter .15s,transform .1s}
.m-btn:active{transform:translateY(2px)}
.mb-p{background:var(--blue);color:#fff;box-shadow:0 4px 0 var(--blue-d)}
.mb-p:hover{filter:brightness(1.08)}

/* ══ MODAL RETO ══ */
.mod-ov{position:fixed;inset:0;background:rgba(15,25,60,.45);backdrop-filter:blur(4px);
    z-index:400;display:flex;align-items:center;justify-content:center;
    opacity:0;pointer-events:none;transition:opacity .28s}
.mod-ov.show{opacity:1;pointer-events:all}
.mod-card{background:#fff;border-radius:22px;padding:26px 30px;max-width:460px;width:92%;
    box-shadow:0 20px 60px rgba(0,0,0,.2);transform:scale(.88);
    transition:transform .32s cubic-bezier(.34,1.56,.64,1);position:relative}
.mod-ov.show .mod-card{transform:scale(1)}
.mod-tit{font-family:var(--ft);font-size:18px;font-weight:800;color:#1a2848;margin-bottom:8px}
.mod-desc{font-size:13px;color:#444;line-height:1.6;margin-bottom:12px;white-space:pre-line}
.mod-meta{display:flex;gap:10px;margin-bottom:14px}
.meta-ch{background:#edf2ff;border:2px solid var(--border);border-radius:10px;padding:4px 10px;font-size:11px;font-weight:700;color:var(--blue-d)}
.mod-x{position:absolute;top:12px;right:14px;background:none;border:none;font-size:18px;cursor:pointer;color:#bbb}
.mod-x:hover{color:#ef4444}
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

  <!-- BARRA SUPERIOR -->
  <div class="top-bar">
    <div class="ttl-iz">NÚMERO<br>ATÓMICO</div>

    <div class="top-centro">
      <div class="pct-row">
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
      <% if (modoEval) { %>
      <div class="retos-ind">
        <span>Retos acertados:</span>
        <div class="reto-dots">
          <div class="reto-dot" id="rd0"></div>
          <div class="reto-dot" id="rd1"></div>
          <div class="reto-dot" id="rd2"></div>
        </div>
        <span id="retosTexto">0 / mín. 3</span>
      </div>
      <% } %>
    </div>

    <div class="ttl-der">NÚCLEO<br>ATÓMICO</div>
  </div>

  <!-- GRID PRINCIPAL -->
  <div class="body-grid">

    <!-- ══ COLUMNA IZQUIERDA ══ -->
    <div class="col-left">

      <!-- 1. Badge Z grande -->
      <div class="z-card">
        <div class="z-card-info">
          <div class="z-card-lbl">Número Atómico (Z)</div>
          <div class="z-card-sub">Z = nº protones = identidad del elemento</div>
        </div>
        <div class="z-card-val" id="zVal"><%= protones %></div>
      </div>

      <!-- 2. Controles (arriba, como en el mockup) -->
      <div class="ctrl-area">
        <div class="ctrl-grupo">
          <button class="btn-oval plus"  onclick="enviar('incrementar','protones')">+</button>
          <div    class="ctrl-etiq ce-p">Protones</div>
          <button class="btn-oval minus" onclick="enviar('decrementar','protones')">−</button>
        </div>
        <div class="ctrl-grupo">
          <button class="btn-oval plus"  onclick="enviar('incrementar','neutrones')">+</button>
          <div    class="ctrl-etiq ce-n">Neutrones</div>
          <button class="btn-oval minus" onclick="enviar('decrementar','neutrones')">−</button>
        </div>
      </div>

      <!-- 3. Panel conteo (debajo de controles) -->
      <div class="cont-panel">
        <div class="cont-fila">
          <span class="cont-circ cc-p"></span>
          <span class="cont-lbl">Protones</span>
          <div class="dots-wrap" id="dotsP"></div>
          <strong class="cont-num" style="color:var(--blue)"    id="nP"><%= protones %></strong>
        </div>
        <div class="cont-fila">
          <span class="cont-circ cc-n"></span>
          <span class="cont-lbl">Neutrones</span>
          <div class="dots-wrap" id="dotsN"></div>
          <strong class="cont-num" style="color:var(--yellow-d)" id="nN"><%= neutrones %></strong>
        </div>
      </div>

      <!-- 4. Banner número másico -->
      <div class="masico-banner">
        <div>
          <div class="mb-lbl">NÚMERO MÁSICO (A)</div>
          <div class="mb-val" id="masicoVal"><%= masico %></div>
        </div>
        <div class="mb-formula">
          A = protones + neutrones<br>
          <span id="formCalc"><%= protones %> + <%= neutrones %> = <%= masico %></span>
        </div>
      </div>

    </div><!-- /col-left -->

    <!-- ══ COLUMNA DERECHA ══ -->
    <div class="col-right">

      <!-- 1. Átomo grande SIN badge Z en el núcleo -->
      <div class="atomo-wrap">
        <svg class="atomo-svg" viewBox="0 0 320 260" id="nucleoSvg">
          <!-- Órbitas -->
          <ellipse cx="160" cy="130" rx="150" ry="52" fill="none" stroke="#c5d2ec"
                   stroke-width="2" stroke-dasharray="7 5" transform="rotate(-35 160 130)" opacity=".55"/>
          <ellipse cx="160" cy="130" rx="150" ry="52" fill="none" stroke="#c5d2ec"
                   stroke-width="2" stroke-dasharray="7 5" transform="rotate(35 160 130)" opacity=".55"/>
          <ellipse cx="160" cy="130" rx="150" ry="52" fill="none" stroke="#c5d2ec"
                   stroke-width="2" stroke-dasharray="7 5" transform="rotate(90 160 130)" opacity=".45"/>
          <!-- Electrones decorativos en órbita -->
          <circle cx="310" cy="130" r="6" fill="#90b4f0" opacity=".75"/>
          <circle cx="10"  cy="130" r="6" fill="#90b4f0" opacity=".75"/>
          <circle cx="200" cy="15"  r="6" fill="#90b4f0" opacity=".75"/>
          <circle cx="120" cy="245" r="6" fill="#90b4f0" opacity=".75"/>
          <circle cx="275" cy="48"  r="6" fill="#90b4f0" opacity=".75"/>
          <circle cx="45"  cy="212" r="6" fill="#90b4f0" opacity=".75"/>
          <!-- Núcleo dinámico (JS) -->
          <g id="nucleoG"></g>
        </svg>
      </div>

      <!-- 2. Carta del elemento (debajo del átomo) -->
      <div class="carta-elem <%= hayElem?"activa":"" %>">
        <div class="carta-lateral">
          <span class="carta-masico" id="cMas"><%= masico > 0 ? masico : "" %></span>
          <span class="carta-z"      id="cZ"  ><%= protones > 0 ? protones : "" %></span>
        </div>
        <div class="carta-centro">
          <span class="carta-sim <%= !hayElem?"vacio":"" %>" id="cSim"><%= hayElem ? simbolo : "?" %></span>
          <span class="carta-nombre" id="cNom"><%= hayElem ? nombreElem : "Sin identificar" %></span>
        </div>
      </div>

    </div><!-- /col-right -->
  </div><!-- /body-grid -->

  <!-- BOTONES INFERIORES -->
  <div class="acciones">
    <button class="btn-ac ac-r" onclick="confirmarReiniciar()">REINICIAR</button>
    <button class="btn-ac ac-c" id="btnComp" <%= !modoEval?"disabled":"" %>
            onclick="enviar('comprobar','')">COMPROBAR</button>
    <button class="btn-ac ac-v" onclick="confirmarVolver()">VOLVER</button>
    <button class="btn-ac ac-k" id="btnCont" <%= !habCont?"disabled":"" %>
            onclick="enviar('continuar','')">CONTINUAR</button>
  </div>

</div><!-- /sim -->

<script>
const ST={
    p:       <%=protones%>, n:<%=neutrones%>,
    modoEval:<%=modoEval%>,
    tiempo:  <%=temporizador%>, intentos:<%=intentosUsados%>,
    maxInt:  <%=Reto.MAX_INTENTOS%>,
    retoId:  '<%=retoId%>', descReto:'<%=descRetoJs%>'
};

function enviar(a,p){
    if(timerInvl){clearInterval(timerInvl);timerInvl=null;}
    document.getElementById('hdnA').value=a;
    document.getElementById('hdnP').value=p;
    document.getElementById('frm').submit();
}
function confirmarReiniciar(){if(confirm('¿Reiniciar? Se perderá el progreso.'))enviar('reiniciar','')}
function confirmarVolver()   {if(confirm('¿Volver al menú? Se perderá el progreso.'))enviar('volver','')}

/* Timer */
let timerSeg=null,timerInvl=null;
function iniciarTimer(s){
    if(timerInvl){clearInterval(timerInvl);timerInvl=null;}
    timerSeg=s;
    timerInvl=setInterval(()=>{
        timerSeg--;
        sessionStorage.setItem('seaea2_timer',timerSeg);
        const txt=timerSeg>0?timerSeg+'s':'¡Tiempo!';
        const h=document.getElementById('hudTimer');
        const m=document.getElementById('modTimer');
        if(h){h.textContent=txt;h.className='hud-t'+(timerSeg>20?' ok':'')}
        if(m)m.textContent=txt;
        if(timerSeg<=0){
            clearInterval(timerInvl);timerInvl=null;
            sessionStorage.removeItem('seaea2_timer');
            sessionStorage.removeItem('seaea2_retoId');
            setTimeout(()=>enviar('comprobar',''),800);
        }
    },1000);
}

/* Modal */
function openModal(){
    if(document.getElementById('btnQ').classList.contains('dis'))return;
    const s=sessionStorage.getItem('seaea2_desc_'+ST.retoId);
    if(s)document.getElementById('modDesc').textContent=s;
    document.getElementById('modInt').textContent=ST.intentos;
    document.getElementById('modReto').classList.add('show');
}
function closeModal(){document.getElementById('modReto').classList.remove('show')}

/* Guía mascota */
const GUIA=[
    {t:'¡Bienvenido!',m:'Hola, soy AmazonAtom 🦜\nEn este escenario estudiarás el NÚCLEO ATÓMICO\ny el NÚMERO ATÓMICO (Z).\n¡Empecemos!',btn:'Siguiente →'},
    {t:'El núcleo atómico',m:'⚛️ El núcleo es el centro del átomo.\nContiene dos tipos de partículas:\n🔵 Protones → carga positiva\n🟡 Neutrones → sin carga',btn:'Siguiente →'},
    {t:'El número atómico (Z)',m:'🔑 Z = número de protones.\nZ define la IDENTIDAD del elemento.\n→ Cambias protones = cambias el elemento.\n→ Cambias neutrones = el elemento NO cambia.',btn:'Siguiente →'},
    {t:'El número másico (A)',m:'📊 A = protones + neutrones\nA cambia cuando agregas o quitas\nprotones o neutrones del núcleo.',btn:'Siguiente →'},
    {t:'¡Listo para evaluar!',m:'🏆 Presiona INICIAR EVALUACIÓN.\nTendrás 90 s y 3 intentos por reto.\nDebes acertar ≥ 3 retos y alcanzar ≥ 80% para superar el escenario.',btn:'¡Entendido!'}
];
let paso=0,mGuia='inicial',afterCb=null;
function abrirMasc(m){mGuia=m;renderMasc();document.getElementById('ovMasc').classList.add('vis')}
function cerrarMasc(){document.getElementById('ovMasc').classList.remove('vis');if(afterCb){const f=afterCb;afterCb=null;f()}}
function mascAccion(){if(mGuia==='inicial'){if(paso<GUIA.length-1){paso++;renderMasc()}else cerrarMasc()}else cerrarMasc()}
function renderMasc(){
    document.getElementById('mascImg').className=mGuia==='inicial'?'m-ava-img':'m-ava-img sm';
    document.getElementById('mBadge').style.display='none';
    document.getElementById('mNuevoReto').style.display='none';
    if(mGuia==='inicial'){
        const g=GUIA[paso];
        document.getElementById('mTit').textContent=g.t;
        document.getElementById('mTxt').textContent=g.m;
        document.getElementById('mBtnP').textContent=g.btn;
        const w=document.getElementById('mPasos');w.innerHTML='';
        GUIA.forEach((_,i)=>{const d=document.createElement('div');d.className='m-pt'+(i===paso?' act':'');w.appendChild(d)});
    }
}
function mostrarRetro(titulo,texto,estado,nuevoDesc,cb){
    mGuia='retro';afterCb=cb||null;
    document.getElementById('mTit').textContent=titulo;
    document.getElementById('mTxt').textContent=texto;
    document.getElementById('mBtnP').textContent='Entendido';
    document.getElementById('mPasos').innerHTML='';
    document.getElementById('mascImg').className='m-ava-img sm';
    const badge=document.getElementById('mBadge');
    const map={ok:['badge b-ok','✅ ¡Correcto!'],err:['badge b-err','❌ Incorrecto'],warn:['badge b-warn','⏱ Intentos agotados']};
    if(map[estado]){badge.className=map[estado][0];badge.textContent=map[estado][1];badge.style.display='inline-block'}
    if(nuevoDesc){document.getElementById('mNuevoRetoDesc').textContent=nuevoDesc;document.getElementById('mNuevoReto').style.display='block'}
    document.getElementById('ovMasc').classList.add('vis');
}

/* Núcleo SVG (sin badge Z) */
const NS='http://www.w3.org/2000/svg';
function hexLayout(total){
    if(total===0)return[];
    const pos=[{x:0,y:0}];const D=11*2.3;let ring=1;
    while(pos.length<total){
        const cnt=6*ring;const step=(2*Math.PI)/cnt;
        for(let i=0;i<cnt&&pos.length<total;i++){
            const a=step*i;pos.push({x:D*ring*Math.cos(a),y:D*ring*Math.sin(a)});
        }
        ring++;
    }
    return pos;
}
function dibujarNucleo(p,n){
    const g=document.getElementById('nucleoG');g.innerHTML='';
    const total=p+n;if(total===0)return;
    const arr=[...Array(p).fill('p'),...Array(n).fill('n')];
    for(let i=arr.length-1;i>0;i--){const j=Math.floor(Math.random()*(i+1));[arr[i],arr[j]]=[arr[j],arr[i]]}
    hexLayout(total).forEach((pos,i)=>{
        const c=document.createElementNS(NS,'circle');
        c.setAttribute('cx',160+pos.x);c.setAttribute('cy',130+pos.y);c.setAttribute('r',10);
        c.setAttribute('fill',arr[i]==='p'?'#4a86f5':'#f5c540');
        c.setAttribute('stroke','rgba(0,0,0,.15)');c.setAttribute('stroke-width','1.8');
        g.appendChild(c);
    });
}

/* Puntos de conteo */
function renderDots(id,count,cls){
    const el=document.getElementById(id);if(!el)return;el.innerHTML='';
    for(let i=0;i<Math.min(count,18);i++){const d=document.createElement('span');d.className='dot '+cls;el.appendChild(d)}
}

/* Indicador retos */
function actualizarRetoDots(){
    const ok=parseInt(sessionStorage.getItem('seaea2_retos_ok')||'0');
    for(let i=0;i<3;i++){const d=document.getElementById('rd'+i);if(d)d.classList.toggle('done',i<ok)}
    const t=document.getElementById('retosTexto');if(t)t.textContent=ok+' / mín. 3';
}

/* INIT */
document.addEventListener('DOMContentLoaded',()=>{
    dibujarNucleo(ST.p,ST.n);
    renderDots('dotsP',ST.p,'d-p');
    renderDots('dotsN',ST.n,'d-n');

    if(ST.modoEval&&ST.retoId){
        const sid=sessionStorage.getItem('seaea2_retoId');
        const stm=parseInt(sessionStorage.getItem('seaea2_timer')||'0');
        if(sid===ST.retoId&&stm>0){iniciarTimer(stm)}
        else{
            sessionStorage.removeItem('seaea2_timer');
            sessionStorage.setItem('seaea2_retoId',ST.retoId);
            sessionStorage.setItem('seaea2_timer',ST.tiempo);
            iniciarTimer(ST.tiempo);
        }
        actualizarRetoDots();
    }else if(!ST.modoEval){
        sessionStorage.removeItem('seaea2_retoId');
        sessionStorage.removeItem('seaea2_timer');
        sessionStorage.removeItem('seaea2_retos_ok');
    }
    if(ST.retoId&&ST.descReto)sessionStorage.setItem('seaea2_desc_'+ST.retoId,ST.descReto);
    if(ST.retoId)document.getElementById('btnQ').classList.remove('dis');

    <%if(tieneResult){%>
    {
        const ok=<%=correcto%>;
        const agot=<%=intentosUsados%>>=<%=Reto.MAX_INTENTOS%>;
        const msg='<%=msgMascJs%>';
        const nuDesc='<%=nuevoReto?descRetoJs:""%>';
        if(ok){
            let cnt=parseInt(sessionStorage.getItem('seaea2_retos_ok')||'0');
            sessionStorage.setItem('seaea2_retos_ok',cnt+1);
            actualizarRetoDots();
        }
        let titulo,estado;
        if(ok){titulo='¡Reto superado! 🎉';estado='ok'}
        else if(agot){titulo='Intentos agotados 😔';estado='warn'}
        else{titulo='Intento fallido';estado='err'}
        setTimeout(()=>{
            mostrarRetro(titulo,msg,estado,nuDesc||null,
                <%=nuevoReto%>?()=>setTimeout(openModal,350):null);
        },300);
    }
    <%}else if(primeraCarga){%>
    paso=0;setTimeout(()=>abrirMasc('inicial'),350);
    <%}else if(nuevoReto&&modoEval){%>
    setTimeout(()=>openModal(),400);
    <%}%>
});
</script>
</body>
</html>
