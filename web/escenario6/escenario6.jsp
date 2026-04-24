<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%@ page import="modelo.ElementoBase, modelo.Reto, java.util.List" %>
<%
    // ── Porcentaje y modo ────────────────────────────────────────────────────
    int     porcentaje = request.getAttribute("porcentaje")     != null ? (int)request.getAttribute("porcentaje")     : 0;
    boolean modoEval   = Boolean.TRUE.equals(request.getAttribute("modoEvaluacion"));
    boolean habCont    = Boolean.TRUE.equals(request.getAttribute("habilitarContinuar"));

    // ── Elementos A y B ──────────────────────────────────────────────────────
    ElementoBase ebA = (ElementoBase) request.getAttribute("elemA");
    ElementoBase ebB = (ElementoBase) request.getAttribute("elemB");
    boolean hayA = ebA != null;
    boolean hayB = ebB != null;

    // ── Respuestas del usuario ───────────────────────────────────────────────
    String respRadio  = request.getAttribute("respRadio")  != null ? (String)request.getAttribute("respRadio")  : "";
    String respIoniz  = request.getAttribute("respIoniz")  != null ? (String)request.getAttribute("respIoniz")  : "";
    String respElectr = request.getAttribute("respElectr") != null ? (String)request.getAttribute("respElectr") : "";

    // ── Resultado simulación: "okRadio okIoniz okElectr" ─────────────────────
    String resultSimul = request.getAttribute("resultSimul") != null
                         ? (String)request.getAttribute("resultSimul") : "";
    boolean hayResult  = !resultSimul.isEmpty();
    boolean resRadio   = hayResult && resultSimul.charAt(0) == '1';
    boolean resIoniz   = hayResult && resultSimul.charAt(1) == '1';
    boolean resElectr  = hayResult && resultSimul.charAt(2) == '1';

    // ── Reto ─────────────────────────────────────────────────────────────────
    Reto   retoActual     = (Reto) request.getAttribute("retoActual");
    String descReto       = request.getAttribute("descripcionReto") != null
                            ? (String)request.getAttribute("descripcionReto") : "";
    int    intentosUsados = request.getAttribute("intentosUsados") != null
                            ? (int)request.getAttribute("intentosUsados")    : 0;
    int    temporizador   = request.getAttribute("temporizador")   != null
                            ? (int)request.getAttribute("temporizador")      : 90;
    boolean nuevoReto     = Boolean.TRUE.equals(request.getAttribute("nuevoReto"));
    String  retoId        = request.getAttribute("retoId") != null
                            ? (String)request.getAttribute("retoId")         : "";

    // ── Mascota / resultado ──────────────────────────────────────────────────
    String  msgMasc     = request.getAttribute("mensajeMascota") != null
                          ? (String)request.getAttribute("mensajeMascota") : "";
    Object  rcObj       = request.getAttribute("resultadoCorrecto");
    boolean correcto    = rcObj != null && (boolean)rcObj;
    boolean tieneResult = rcObj != null;
    boolean primeraCarga = !modoEval && !tieneResult && !nuevoReto
                           && request.getAttribute("mensajeMascota") != null;

    // ── Lista elementos ──────────────────────────────────────────────────────
    @SuppressWarnings("unchecked")
    List<ElementoBase> elementos = (List<ElementoBase>)request.getAttribute("elementosPeriodica");

    // ── Helpers ──────────────────────────────────────────────────────────────
    String descRetoJs = descReto.replace("\\","\\\\").replace("'","\\'")
                                .replace("\n","\\n").replace("\r","");
    String msgMascJs  = msgMasc.replace("\\","\\\\").replace("`","'")
                               .replace("\n","\\n").replace("\r","");

    int zA = hayA ? ebA.getNumeroAtomico() : 0;
    int zB = hayB ? ebB.getNumeroAtomico() : 0;
%>

<%! 
    // Método helper para formatear valores de propiedades
    public String fmtVal(double v) {
        return v > 0 ? String.format("%.2f", v) : "N/D";
    }
%>

<!DOCTYPE html>
<html lang="es">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<title>Propiedades Periódicas – SEAEA</title>
<link href="https://fonts.googleapis.com/css2?family=Baloo+2:wght@700;800;900&family=Nunito:wght@400;600;700;800&display=swap" rel="stylesheet">
<style>
:root{
    --bg:#dde4f5;--panel:#f4f7ff;--border:#c5d2ec;
    --blue:#4a86f5;--blue-d:#1e56d0;
    --yellow:#f5c540;--yellow-d:#b89000;
    --red:#f46a6a;--red-d:#c43a3a;
    --green:#4ec87a;--green-d:#2a8a4e;
    --orange:#ff8c42;--orange-d:#cc6010;
    --purple:#9b5de5;--purple-d:#6a35b0;
    --teal:#2ec4b6;--teal-d:#1a8a80;
    --ft:'Baloo 2',cursive;--fb:'Nunito',sans-serif;
    /* Bloques */
    --s-bg:#d2f5e2;--s-br:#2a8a4e;
    --p-bg:#dbeafe;--p-br:#3b82f6;
    --d-bg:#fef3c7;--d-br:#d97706;
    --f-bg:#fde8ff;--f-br:#a855f7;
    --noble-bg:#fde0e0;--noble-br:#c43a3a;
}
*,*::before,*::after{box-sizing:border-box;margin:0;padding:0}
body{background:var(--bg);font-family:var(--fb);min-height:100vh;
    display:flex;align-items:flex-start;justify-content:center;padding:10px}

.sim{background:var(--panel);border:3px solid var(--border);border-radius:28px;
    box-shadow:0 8px 32px rgba(40,70,160,.12);width:100%;max-width:1200px;
    padding:14px 22px 18px;display:flex;flex-direction:column;gap:10px}

/* ── TOP BAR ── */
.top{display:flex;align-items:center;gap:8px;flex-wrap:wrap}
.lbl-apz{font-size:11px;font-weight:800;color:#7a8cb0;letter-spacing:.8px;white-space:nowrap}
.pill-pct{background:#fde0e0;border:2.5px solid var(--red);border-radius:22px;
    padding:2px 14px;font-size:18px;font-weight:900;color:var(--red-d);
    min-width:64px;text-align:center;flex-shrink:0}
.pill-pct.ok{background:#d2f5e2;border-color:var(--green);color:#1a6e38}
.prog-track{width:120px;height:11px;background:#dde4f5;border-radius:7px;overflow:hidden;
    border:1.5px solid var(--border);flex-shrink:0}
.prog-fill{height:100%;border-radius:7px;
    background:linear-gradient(90deg,#f46a6a 0%,#f5c540 50%,#4ec87a 100%);transition:width .7s ease}
.titulo{flex:1;text-align:center;font-family:var(--ft);font-size:19px;font-weight:900;
    color:#1a2848;letter-spacing:1.5px}
.eval-hud{display:flex;align-items:center;gap:6px;background:#fff5f5;
    border:2px solid #fca5a5;border-radius:12px;padding:3px 10px;flex-shrink:0}
.hud-t{font-size:18px;font-weight:900;color:#ef4444;min-width:38px;text-align:center}
.hud-t.ok{color:var(--green-d)}
.hud-sep{width:1px;height:20px;background:#fca5a5}
.hud-i{font-size:10px;font-weight:700;color:#666;white-space:nowrap}
.btn-reto{background:var(--blue);color:#fff;border:none;border-radius:12px;
    padding:7px 14px;font-family:var(--fb);font-size:12px;font-weight:800;
    cursor:pointer;white-space:nowrap;flex-shrink:0;box-shadow:0 4px 0 var(--blue-d);
    transition:filter .15s,transform .1s}
.btn-reto:hover{filter:brightness(1.08)}
.btn-reto:active{transform:translateY(2px)}
.btn-reto.fin{background:#e53e3e;box-shadow:0 4px 0 #a02020}
.btn-q{width:30px;height:30px;background:#fde8e8;border:2.5px solid #f4a0a0;
    border-radius:50%;font-size:14px;font-weight:900;color:var(--red-d);cursor:pointer;
    display:flex;align-items:center;justify-content:center;transition:transform .2s;flex-shrink:0}
.btn-q:hover{transform:scale(1.15)}
.btn-q.dis{opacity:.35;pointer-events:none}

/* ══ GRID PRINCIPAL ══════════════════════════════════════════════════════════
   [col-izq: leyenda + tabla periódica completa]
   [col-der: carta seleccionados + comparaciones]
*/
.body-grid{display:grid;grid-template-columns:1fr 340px;gap:12px;align-items:start}
.col-left{display:flex;flex-direction:column;gap:8px}
.col-right{display:flex;flex-direction:column;gap:8px}

/* ── LEYENDA ── */
.leyenda{display:flex;flex-wrap:wrap;gap:5px 10px;
    background:#edf2ff;border:1.5px solid var(--border);border-radius:10px;padding:7px 10px}
.ley-item{display:flex;align-items:center;gap:4px;font-size:10px;font-weight:700;color:#555}
.ley-dot{width:12px;height:12px;border-radius:3px;flex-shrink:0;border:1px solid rgba(0,0,0,.15)}

/* ── INSTRUCCIÓN ── */
.instruc{background:#edf2ff;border:2px solid var(--border);border-radius:10px;
    padding:7px 12px;font-size:12px;font-weight:700;color:#1a2848;text-align:center}
.instruc span{color:var(--blue)}

/* ══ TABLA PERIÓDICA ═══════════════════════════════════════════════════════ */
.tabla-wrap{background:#edf2ff;border:2px solid var(--border);border-radius:14px;padding:8px 10px}
.tabla-periodica{display:grid;grid-template-columns:repeat(18,1fr);gap:2px;width:100%}
.elem-cell{
    aspect-ratio:1;border-radius:4px;border:1.5px solid var(--border);
    background:#f0f4ff;cursor:pointer;
    display:flex;flex-direction:column;align-items:center;justify-content:center;
    transition:all .13s;position:relative;min-width:0;
}
.elem-cell:hover{transform:scale(1.18);z-index:5;
    box-shadow:0 3px 10px rgba(74,134,245,.35)}
.elem-cell.vacia{background:transparent;border-color:transparent;
    cursor:default;pointer-events:none}
.elem-cell.sel-a{background:#4a86f5!important;border-color:#1e56d0!important;
    box-shadow:0 0 0 2px rgba(74,134,245,.6)}
.elem-cell.sel-b{background:#f46a6a!important;border-color:#c43a3a!important;
    box-shadow:0 0 0 2px rgba(244,106,106,.6)}
.elem-cell.sel-a .ec-sim,.elem-cell.sel-a .ec-z{color:#fff!important}
.elem-cell.sel-b .ec-sim,.elem-cell.sel-b .ec-z{color:#fff!important}
.ec-z  {font-size:5.5px;font-weight:800;color:#9aa8c8;line-height:1}
.ec-sim{font-size:8.5px;font-weight:900;color:#1a2848;line-height:1}
/* Colores bloque */
.bl-s  {background:var(--s-bg);border-color:var(--s-br)}
.bl-s   .ec-sim{color:#1a4a2e}
.bl-p  {background:var(--p-bg);border-color:var(--p-br)}
.bl-p   .ec-sim{color:#1e3a8a}
.bl-d  {background:var(--d-bg);border-color:var(--d-br)}
.bl-d   .ec-sim{color:#78350f}
.bl-f  {background:var(--f-bg);border-color:var(--f-br)}
.bl-f   .ec-sim{color:#6b21a8}
.bl-noble{background:var(--noble-bg);border-color:var(--noble-br)}
.bl-noble .ec-sim{color:var(--red-d)}
/* Fila separadora lantánidos/actínidos */
.tabla-sep{height:4px}

/* ══ COL DERECHA ════════════════════════════════════════════════════════════ */

/* Cartas A y B */
.cartas-ab{display:grid;grid-template-columns:1fr 1fr;gap:8px}
.carta-ab{border-radius:16px;padding:10px;text-align:center;
    border:2.5px solid var(--border);background:#edf2ff;transition:all .3s}
.carta-ab.a-activa{border-color:var(--blue);background:#e0ecff;
    box-shadow:0 0 0 3px rgba(74,134,245,.2)}
.carta-ab.b-activa{border-color:var(--red);background:#fde8e8;
    box-shadow:0 0 0 3px rgba(244,106,106,.2)}
.carta-ab.vacia{background:#f8faff;border-style:dashed}
.cab-lbl{font-size:11px;font-weight:900;letter-spacing:1px;
    margin-bottom:4px;text-transform:uppercase}
.cab-lbl.a{color:var(--blue-d)}.cab-lbl.b{color:var(--red-d)}
.cab-sim{font-family:var(--ft);font-size:40px;font-weight:900;line-height:1}
.cab-sim.a{color:var(--blue)}.cab-sim.b{color:var(--red)}
.cab-sim.vacio{color:#c5d2ec}
.cab-nom{font-size:10px;font-weight:700;color:#7a8cb0;margin-top:2px}
.cab-z  {font-size:10px;font-weight:800;color:#aab8d0}

/* Propiedades de las cartas */
.prop-mini{margin-top:6px;display:flex;flex-direction:column;gap:3px}
.pm-row{display:flex;justify-content:space-between;align-items:center;
    background:#fff;border-radius:6px;padding:2px 6px}
.pm-lbl{font-size:9px;font-weight:800;color:#9aa8c8;text-transform:uppercase}
.pm-val{font-size:10px;font-weight:900;color:#1a2848}

/* ── COMPARACIONES ── */
.comp-titulo{font-size:11px;font-weight:800;color:#7a8cb0;
    letter-spacing:.8px;text-transform:uppercase;text-align:center}

.comp-fila{
    display:flex;align-items:center;gap:8px;
    background:#fff;border:2px solid var(--border);border-radius:14px;
    padding:10px 12px;transition:border-color .3s;
}
.comp-fila.ok  {border-color:var(--green); background:#f0fdf4}
.comp-fila.err {border-color:var(--red);   background:#fff5f5}
.comp-icon{font-size:20px;flex-shrink:0;width:28px;text-align:center}
.comp-lbl{flex:1;font-size:12px;font-weight:800;color:#1a2848}
.comp-resultado{font-size:12px;font-weight:900;flex-shrink:0}
.comp-resultado.ok {color:var(--green-d)}
.comp-resultado.err{color:var(--red-d)}

/* Botones A/B de comparación */
.ab-btns{display:flex;gap:6px;flex-shrink:0}
.btn-ab{
    width:36px;height:36px;border-radius:10px;border:none;
    font-family:var(--ft);font-size:16px;font-weight:900;cursor:pointer;
    transition:all .12s;
}
.btn-ab.a{background:#e0ecff;color:var(--blue-d);border:2px solid var(--blue)}
.btn-ab.b{background:#fde8e8;color:var(--red-d); border:2px solid var(--red)}
.btn-ab.sel{transform:scale(1.1);box-shadow:0 3px 8px rgba(0,0,0,.2)}
.btn-ab.a.sel{background:var(--blue);color:#fff}
.btn-ab.b.sel{background:var(--red); color:#fff}
.btn-ab:disabled{opacity:.35;cursor:not-allowed;transform:none}

/* Indicador resultado comparación */
.ind-result{width:26px;height:26px;border-radius:50%;display:flex;align-items:center;
    justify-content:center;font-size:14px;flex-shrink:0;font-weight:900}
.ind-ok {background:#d2f5e2;color:var(--green-d)}
.ind-err{background:#fde0e0;color:var(--red-d)}
.ind-neu{background:#edf2ff;color:#aab8d0}

/* ── BOTONES INFERIORES ── */
.acciones{display:flex;justify-content:center;gap:10px;margin-top:4px;flex-wrap:wrap}
.btn-ac{padding:11px 24px;border-radius:14px;border:none;font-family:var(--fb);
    font-size:13px;font-weight:800;cursor:pointer;letter-spacing:.4px;
    color:#1a2848;transition:transform .12s,box-shadow .12s,filter .12s}
.btn-ac:hover{filter:brightness(1.07)}
.btn-ac:active{transform:translateY(2px)}
.btn-ac:disabled{opacity:.4;cursor:not-allowed;transform:none;filter:none}
.ac-r{background:var(--yellow);box-shadow:0 4px 0 var(--yellow-d)}
.ac-c{background:var(--blue);  box-shadow:0 4px 0 var(--blue-d);color:#fff}
.ac-v{background:var(--red);   box-shadow:0 4px 0 var(--red-d); color:#fff}
.ac-k{background:var(--green); box-shadow:0 4px 0 var(--green-d)}
.ac-r:active{box-shadow:0 2px 0 var(--yellow-d)}
.ac-c:active{box-shadow:0 2px 0 var(--blue-d)}
.ac-v:active{box-shadow:0 2px 0 var(--red-d)}
.ac-k:active{box-shadow:0 2px 0 var(--green-d)}

/* ── OVERLAY MASCOTA ── */
.ov-bg{position:fixed;inset:0;background:rgba(15,25,60,.52);backdrop-filter:blur(5px);
    z-index:500;display:flex;align-items:center;justify-content:center;
    opacity:0;pointer-events:none;transition:opacity .3s}
.ov-bg.vis{opacity:1;pointer-events:all}
.masc-card{background:#fff;border-radius:26px;padding:28px 36px 24px;
    max-width:520px;width:92%;box-shadow:0 26px 70px rgba(0,0,0,.22);text-align:center;
    transform:scale(.84) translateY(20px);
    transition:transform .38s cubic-bezier(.34,1.56,.64,1)}
.ov-bg.vis .masc-card{transform:scale(1) translateY(0)}
.m-ava-img{width:80px;height:80px;object-fit:contain;margin:0 auto 10px;display:block;
    border-radius:50%;background:#f0f5ff;padding:5px;
    box-shadow:0 4px 16px rgba(74,134,245,.2)}
.m-ava-img.sm{width:58px;height:58px;padding:4px}
.m-tit{font-family:var(--ft);font-size:19px;font-weight:800;color:#1a2848;margin-bottom:10px}
.m-pasos{display:flex;justify-content:center;gap:6px;margin-bottom:12px}
.m-pt{width:8px;height:8px;border-radius:50%;background:var(--border);transition:background .3s,transform .3s}
.m-pt.act{background:var(--blue);transform:scale(1.4)}
.badge{display:inline-block;padding:4px 16px;border-radius:20px;font-size:13px;font-weight:800;margin-bottom:10px}
.b-ok {background:#d2f5e2;color:#1a6e38}
.b-err{background:#fde0e0;color:var(--red-d)}
.b-warn{background:#fef3cd;color:#856404}
.m-txt{font-size:13px;color:#444;line-height:1.7;margin-bottom:16px;white-space:pre-line;text-align:left}
.nuevo-reto-box{background:#f0f5ff;border:2px solid var(--border);border-radius:14px;
    padding:10px 14px;margin-bottom:14px;text-align:left}
.nuevo-reto-box .nr-tit{font-size:10px;font-weight:800;color:#7a8cb0;
    margin-bottom:4px;letter-spacing:.5px;text-transform:uppercase}
.nuevo-reto-box .nr-desc{font-size:12px;font-weight:600;color:#1a2848;line-height:1.5}
.m-btns{display:flex;gap:10px;justify-content:center}
.m-btn{padding:10px 28px;border-radius:12px;border:none;font-family:var(--fb);
    font-size:14px;font-weight:800;cursor:pointer;transition:filter .15s,transform .1s}
.m-btn:active{transform:translateY(2px)}
.mb-p{background:var(--blue);color:#fff;box-shadow:0 4px 0 var(--blue-d)}
.mb-p:hover{filter:brightness(1.08)}

/* Modal reto */
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
.meta-ch{background:#edf2ff;border:2px solid var(--border);border-radius:10px;
    padding:4px 10px;font-size:11px;font-weight:700;color:var(--blue-d)}
.mod-x{position:absolute;top:12px;right:14px;background:none;border:none;
    font-size:18px;cursor:pointer;color:#bbb}
.mod-x:hover{color:#ef4444}
</style>
</head>
<body>
<form id="frm" method="post" action="<%= request.getContextPath() %>/escenario6">
    <input type="hidden" name="accion"        id="hdnA"    value="">
    <input type="hidden" name="numeroAtomico" id="hdnZ"    value="">
    <input type="hidden" name="respRadio"     id="hdnRad"  value="<%= respRadio %>">
    <input type="hidden" name="respIoniz"     id="hdnIon"  value="<%= respIoniz %>">
    <input type="hidden" name="respElectr"    id="hdnElec" value="<%= respElectr %>">
</form>

<!-- ══ OVERLAY MASCOTA ════════════════════════════════════════════════════ -->
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

<!-- ══ MODAL RETO ═════════════════════════════════════════════════════════ -->
<div class="mod-ov" id="modReto">
  <div class="mod-card">
    <button class="mod-x" onclick="closeModal()">✕</button>
    <div class="mod-tit">🔬 Tu reto actual</div>
    <div class="mod-desc" id="modDesc"><%= descReto.isEmpty() ? "Inicia la evaluación para ver tu reto." : descReto %></div>
    <div class="mod-meta">
        <div class="meta-ch">Intentos: <span id="modInt"><%= intentosUsados %></span>/<%= Reto.MAX_INTENTOS %></div>
        <div class="meta-ch">⏱ <span id="modTimer"><%= temporizador %>s</span></div>
    </div>
    <button class="btn-ac ac-c" style="width:100%;border-radius:12px"
            onclick="closeModal();comprobar()">✓ Comprobar ahora</button>
  </div>
</div>

<!-- ══ SIMULADOR ══════════════════════════════════════════════════════════ -->
<div class="sim">

  <!-- TOP BAR -->
  <div class="top">
    <span class="lbl-apz">APRENDIZAJE</span>
    <div class="pill-pct <%= porcentaje>=80?"ok":"" %>"><%= porcentaje %>%</div>
    <div class="prog-track"><div class="prog-fill" style="width:<%= porcentaje %>%"></div></div>
    <span class="titulo">PROPIEDADES PERIÓDICAS DE LOS ELEMENTOS</span>
    <% if (modoEval) { %>
    <div class="eval-hud">
        <span class="hud-t" id="hudTimer"><%= temporizador %>s</span>
        <div class="hud-sep"></div>
        <span class="hud-i" id="hudInt">Intentos: <%= intentosUsados %>/<%= Reto.MAX_INTENTOS %></span>
    </div>
    <button class="btn-reto fin" onclick="enviar('finalizar')">FINALIZAR EVAL</button>
    <% } else { %>
    <button class="btn-reto" onclick="enviar('iniciarEval')">INICIAR EVALUACIÓN</button>
    <% } %>
    <button class="btn-q <%= retoId.isEmpty()?"dis":"" %>" id="btnQ" onclick="openModal()">?</button>
  </div>

  <!-- GRID CENTRAL -->
  <div class="body-grid">

    <!-- ── COLUMNA IZQUIERDA ── -->
    <div class="col-left">

      <!-- Instrucción -->
      <div class="instruc">
        <% if (!modoEval) { %>
          <span>①</span> Selecciona el <b>elemento A</b> y luego el <b>elemento B</b> de la tabla periódica
        <% } else { %>
          Modo evaluación activo — compara las propiedades de los elementos <b>A</b> y <b>B</b>
        <% } %>
      </div>

      <!-- Leyenda -->
      <div class="leyenda">
        <div class="ley-item"><span class="ley-dot" style="background:var(--s-bg);border-color:var(--s-br)"></span>Metales Alcalinos/Alcalinotérreos</div>
        <div class="ley-item"><span class="ley-dot" style="background:var(--p-bg);border-color:var(--p-br)"></span>No metales / Semimetales</div>
        <div class="ley-item"><span class="ley-dot" style="background:var(--d-bg);border-color:var(--d-br)"></span>Metales de Transición</div>
        <div class="ley-item"><span class="ley-dot" style="background:var(--f-bg);border-color:var(--f-br)"></span>Lantánidos / Actínidos</div>
        <div class="ley-item"><span class="ley-dot" style="background:var(--noble-bg);border-color:var(--noble-br)"></span>Gases Nobles</div>
        <div class="ley-item"><span class="ley-dot" style="background:var(--blue);border-color:var(--blue-d)"></span>Elemento A</div>
        <div class="ley-item"><span class="ley-dot" style="background:var(--red);border-color:var(--red-d)"></span>Elemento B</div>
      </div>

      <!-- Tabla periódica completa -->
      <div class="tabla-wrap">
        <div class="tabla-periodica" id="tablaPer">
          <%
            // ── Mapa Z → posición en el grid de 18 columnas ────────────────
            // Usamos un arreglo de 7 filas × 18 columnas + 2 filas para f-block
            // Celdas totales período 1-7: 7*18 = 126 posiciones
            // + separador (18 celdas) + La (57-71) y Ac (89-103)
            //
            // Mapeamos sólo los elementos que existen en la BD (hasta 36 ≈ Kr)

            java.util.Map<Integer,ElementoBase> zMap = new java.util.HashMap<>();
            if (elementos != null) {
                for (ElementoBase e : elementos) zMap.put(e.getNumeroAtomico(), e);
            }

            // Función helper para obtener clase de bloque por Z
            // s-block: grupos 1,2  p-block: grupos 13-18  d-block: 3-12  f-block: La/Ac series
            // Gases nobles: 2,10,18,36,54,86,118
            java.util.Set<Integer> nobles = new java.util.HashSet<>(java.util.Arrays.asList(2,10,18,36,54,86,118));
            java.util.Set<Integer> sBlock = new java.util.HashSet<>(java.util.Arrays.asList(
                1,3,4,11,12,19,20,37,38,55,56,87,88));
            java.util.Set<Integer> dBlock = new java.util.HashSet<>(java.util.Arrays.asList(
                21,22,23,24,25,26,27,28,29,30,
                39,40,41,42,43,44,45,46,47,48,
                72,73,74,75,76,77,78,79,80,
                104,105,106,107,108,109,110,111,112));

            // Posiciones del grid para cada Z
            // columna (1-18), fila (1-7)
            // Formato: z → [col, fila]
            int[][] posiciones = new int[120][2]; // z → [col-1, fila-1]
            // Período 1
            posiciones[1]  = new int[]{0,0}; // H col1
            posiciones[2]  = new int[]{17,0}; // He col18
            // Período 2
            posiciones[3]  = new int[]{0,1};  posiciones[4]  = new int[]{1,1};
            posiciones[5]  = new int[]{12,1}; posiciones[6]  = new int[]{13,1};
            posiciones[7]  = new int[]{14,1}; posiciones[8]  = new int[]{15,1};
            posiciones[9]  = new int[]{16,1}; posiciones[10] = new int[]{17,1};
            // Período 3
            posiciones[11] = new int[]{0,2};  posiciones[12] = new int[]{1,2};
            posiciones[13] = new int[]{12,2}; posiciones[14] = new int[]{13,2};
            posiciones[15] = new int[]{14,2}; posiciones[16] = new int[]{15,2};
            posiciones[17] = new int[]{16,2}; posiciones[18] = new int[]{17,2};
            // Período 4
            posiciones[19] = new int[]{0,3};  posiciones[20] = new int[]{1,3};
            posiciones[21] = new int[]{2,3};  posiciones[22] = new int[]{3,3};
            posiciones[23] = new int[]{4,3};  posiciones[24] = new int[]{5,3};
            posiciones[25] = new int[]{6,3};  posiciones[26] = new int[]{7,3};
            posiciones[27] = new int[]{8,3};  posiciones[28] = new int[]{9,3};
            posiciones[29] = new int[]{10,3}; posiciones[30] = new int[]{11,3};
            posiciones[31] = new int[]{12,3}; posiciones[32] = new int[]{13,3};
            posiciones[33] = new int[]{14,3}; posiciones[34] = new int[]{15,3};
            posiciones[35] = new int[]{16,3}; posiciones[36] = new int[]{17,3};

            // Construir grid 4 filas × 18 cols (solo hasta período 4 = Z≤36)
            // (Si la BD tiene más elementos, las filas 5-7 se agregan igual)
            int filas = 4; // con BD de 36 elementos
            if (zMap.containsKey(37)) filas = 5;
            if (zMap.containsKey(55)) filas = 6;
            if (zMap.containsKey(87)) filas = 7;

            // Renderizar celda por celda
            for (int fila = 0; fila < filas; fila++) {
                for (int col = 0; col < 18; col++) {
                    // Buscar qué elemento va aquí
                    ElementoBase eCell = null;
                    for (int z2 = 1; z2 < posiciones.length; z2++) {
                        if (posiciones[z2] != null
                            && posiciones[z2][0] == col
                            && posiciones[z2][1] == fila
                            && zMap.containsKey(z2)) {
                            eCell = zMap.get(z2);
                            break;
                        }
                    }

                    if (eCell == null) {
          %>
              <div class="elem-cell vacia"></div>
          <%
                    } else {
                        int z2    = eCell.getNumeroAtomico();
                        String blk = nobles.contains(z2) ? "bl-noble"
                                   : sBlock.contains(z2) ? "bl-s"
                                   : dBlock.contains(z2) ? "bl-d"
                                   : "bl-p";
                        String selCls = (z2 == zA) ? " sel-a"
                                      : (z2 == zB) ? " sel-b" : "";
                        // En modo eval no se puede hacer clic en la tabla
                        String onclick = modoEval ? ""
                            : "onclick=\"selElem(" + z2 + ")\"";
          %>
              <div class="elem-cell <%= blk %><%= selCls %>"
                   title="<%= eCell.getNombre() %> (Z=<%= z2 %>)"
                   <%= onclick %>>
                <span class="ec-z"><%= z2 %></span>
                <span class="ec-sim"><%= eCell.getSimbolo() %></span>
              </div>
          <%
                    }
                }
            }
          %>
        </div>
      </div>

    </div><!-- /col-left -->

    <!-- ── COLUMNA DERECHA ── -->
    <div class="col-right">

      <!-- Cartas A y B -->
      <div class="cartas-ab">
        <!-- Carta A -->
        <div class="carta-ab <%= hayA?"a-activa":"vacia" %>">
          <div class="cab-lbl a">ELEMENTO A</div>
          <% if (hayA) { %>
          <div class="cab-sim a"><%= ebA.getSimbolo() %></div>
          <div class="cab-nom"><%= ebA.getNombre() %></div>
          <div class="cab-z">Z = <%= ebA.getNumeroAtomico() %></div>
          <div class="prop-mini">
            <div class="pm-row">
              <span class="pm-lbl">Radio</span>
              <span class="pm-val"><%= ebA.getRadioAtomico() > 0 ? String.format("%.0f pm", ebA.getRadioAtomico()) : "N/D" %></span>
            </div>
            <div class="pm-row">
              <span class="pm-lbl">Ion.</span>
              <span class="pm-val"><%= ebA.getEnergiaIonizacion() > 0 ? String.format("%.0f kJ/mol", ebA.getEnergiaIonizacion()) : "N/D" %></span>
            </div>
            <div class="pm-row">
              <span class="pm-lbl">Electr.</span>
              <span class="pm-val"><%= ebA.getElectronegatividad() > 0 ? String.format("%.2f", ebA.getElectronegatividad()) : "N/D" %></span>
            </div>
          </div>
          <% } else { %>
          <div class="cab-sim vacio">?</div>
          <div class="cab-nom">Sin seleccionar</div>
          <% } %>
        </div>
        <!-- Carta B -->
        <div class="carta-ab <%= hayB?"b-activa":"vacia" %>">
          <div class="cab-lbl b">ELEMENTO B</div>
          <% if (hayB) { %>
          <div class="cab-sim b"><%= ebB.getSimbolo() %></div>
          <div class="cab-nom"><%= ebB.getNombre() %></div>
          <div class="cab-z">Z = <%= ebB.getNumeroAtomico() %></div>
          <div class="prop-mini">
            <div class="pm-row">
              <span class="pm-lbl">Radio</span>
              <span class="pm-val"><%= ebB.getRadioAtomico() > 0 ? String.format("%.0f pm", ebB.getRadioAtomico()) : "N/D" %></span>
            </div>
            <div class="pm-row">
              <span class="pm-lbl">Ion.</span>
              <span class="pm-val"><%= ebB.getEnergiaIonizacion() > 0 ? String.format("%.0f kJ/mol", ebB.getEnergiaIonizacion()) : "N/D" %></span>
            </div>
            <div class="pm-row">
              <span class="pm-lbl">Electr.</span>
              <span class="pm-val"><%= ebB.getElectronegatividad() > 0 ? String.format("%.2f", ebB.getElectronegatividad()) : "N/D" %></span>
            </div>
          </div>
          <% } else { %>
          <div class="cab-sim vacio">?</div>
          <div class="cab-nom">Sin seleccionar</div>
          <% } %>
        </div>
      </div>

      <!-- Comparaciones -->
      <div class="comp-titulo">② Indica cuál tiene más:</div>

      <%-- Radio Atómico --%>
      <div class="comp-fila <%= hayResult?(resRadio?"ok":"err"):"" %>">
        <span class="comp-icon">📏</span>
        <span class="comp-lbl">RADIO ATÓMICO</span>
        <% if (hayResult && !modoEval) { %>
          <span class="ind-result <%= resRadio?"ind-ok":"ind-err" %>"><%= resRadio?"✓":"✗" %></span>
        <% } %>
        <div class="ab-btns">
          <button class="btn-ab a <%= respRadio.equals("A")?"sel":"" %>"
                  <%= (!hayA||!hayB)?"disabled":"" %>
                  onclick="elegir('radio','A')">A</button>
          <button class="btn-ab b <%= respRadio.equals("B")?"sel":"" %>"
                  <%= (!hayA||!hayB)?"disabled":"" %>
                  onclick="elegir('radio','B')">B</button>
        </div>
      </div>

      <%-- Energía de ionización --%>
      <div class="comp-fila <%= hayResult?(resIoniz?"ok":"err"):"" %>">
        <span class="comp-icon">⚡</span>
        <span class="comp-lbl">ENERGÍA DE IONIZACIÓN</span>
        <% if (hayResult && !modoEval) { %>
          <span class="ind-result <%= resIoniz?"ind-ok":"ind-err" %>"><%= resIoniz?"✓":"✗" %></span>
        <% } %>
        <div class="ab-btns">
          <button class="btn-ab a <%= respIoniz.equals("A")?"sel":"" %>"
                  <%= (!hayA||!hayB)?"disabled":"" %>
                  onclick="elegir('ioniz','A')">A</button>
          <button class="btn-ab b <%= respIoniz.equals("B")?"sel":"" %>"
                  <%= (!hayA||!hayB)?"disabled":"" %>
                  onclick="elegir('ioniz','B')">B</button>
        </div>
      </div>

      <%-- Electronegatividad --%>
      <div class="comp-fila <%= hayResult?(resElectr?"ok":"err"):"" %>">
        <span class="comp-icon">🔗</span>
        <span class="comp-lbl">ELECTRONEGATIVIDAD</span>
        <% if (hayResult && !modoEval) { %>
          <span class="ind-result <%= resElectr?"ind-ok":"ind-err" %>"><%= resElectr?"✓":"✗" %></span>
        <% } %>
        <div class="ab-btns">
          <button class="btn-ab a <%= respElectr.equals("A")?"sel":"" %>"
                  <%= (!hayA||!hayB)?"disabled":"" %>
                  onclick="elegir('electr','A')">A</button>
          <button class="btn-ab b <%= respElectr.equals("B")?"sel":"" %>"
                  <%= (!hayA||!hayB)?"disabled":"" %>
                  onclick="elegir('electr','B')">B</button>
        </div>
      </div>

    </div><!-- /col-right -->

  </div><!-- /body-grid -->

  <!-- BOTONES INFERIORES -->
  <div class="acciones">
    <button class="btn-ac ac-r" onclick="confirmarReiniciar()">REINICIAR</button>
    <button class="btn-ac ac-c" id="btnComp"
            <%= (!hayA||!hayB)?"disabled":"" %>
            onclick="comprobar()">COMPROBAR</button>
    <button class="btn-ac ac-v" onclick="confirmarVolver()">VOLVER</button>
    <button class="btn-ac ac-k" id="btnCont"
            <%= !habCont?"disabled":"" %>
            onclick="enviar('continuar')">CONTINUAR</button>
  </div>

</div><!-- /sim -->

<script>
const ST = {
    modoEval: <%=modoEval%>,
    tiempo:   <%=temporizador%>,
    intentos: <%=intentosUsados%>,
    maxInt:   <%=Reto.MAX_INTENTOS%>,
    retoId:   '<%=retoId%>',
    descReto: '<%=descRetoJs%>',
    hayA:     <%=hayA%>,
    hayB:     <%=hayB%>,
    zA:       <%=zA%>,
    zB:       <%=zB%>
};

// Estado local de respuestas (se sincronizan con hidden inputs)
const resp = {
    radio:  '<%=respRadio%>',
    ioniz:  '<%=respIoniz%>',
    electr: '<%=respElectr%>'
};

function enviar(accion) {
    document.getElementById('hdnA').value   = accion;
    document.getElementById('hdnRad').value  = resp.radio;
    document.getElementById('hdnIon').value  = resp.ioniz;
    document.getElementById('hdnElec').value = resp.electr;
    document.getElementById('frm').submit();
}

function selElem(z) {
    document.getElementById('hdnA').value  = 'seleccionarElemento';
    document.getElementById('hdnZ').value  = z;
    document.getElementById('frm').submit();
}

function elegir(prop, val) {
    resp[prop] = val;
    // Actualizar visual botones
    actualizarBotones();
}

function actualizarBotones() {
    ['radio','ioniz','electr'].forEach(prop => {
        const v = resp[prop];
        const sufijo = prop === 'radio' ? 'Rad' : prop === 'ioniz' ? 'Ion' : 'Elec';
        // no podemos tocar el DOM directamente desde atributos JSP,
        // actualizamos clases manualmente
        document.querySelectorAll('[data-prop="' + prop + '"]').forEach(btn => {
            btn.classList.toggle('sel', btn.dataset.val === v);
        });
    });
}

function comprobar() {
    const accion = ST.modoEval ? 'comprobar' : 'comprobarSimulacion';
    enviar(accion);
}

function confirmarReiniciar() {
    if(confirm('¿Reiniciar? Se perderá el progreso.')) enviar('reiniciar');
}
function confirmarVolver() {
    if(confirm('¿Volver al menú? Se perderá el progreso.')) enviar('volver');
}

/* ── TIMER ── */
let timerSeg=null, timerInvl=null;
function iniciarTimer(segs) {
    if(timerInvl) clearInterval(timerInvl);
    timerSeg = segs;
    timerInvl = setInterval(()=>{
        timerSeg--;
        sessionStorage.setItem('seaea6_timer', timerSeg);
        const txt = timerSeg > 0 ? timerSeg+'s' : '¡Tiempo!';
        const h = document.getElementById('hudTimer');
        const m = document.getElementById('modTimer');
        if(h){ h.textContent=txt; h.className='hud-t'+(timerSeg>20?' ok':'') }
        if(m) m.textContent = txt;
        if(timerSeg <= 0){
            clearInterval(timerInvl); timerInvl=null;
            sessionStorage.removeItem('seaea6_timer');
            sessionStorage.removeItem('seaea6_retoId');
            setTimeout(()=>comprobar(), 800);
        }
    }, 1000);
}

/* ── MODAL ── */
function openModal() {
    if(document.getElementById('btnQ').classList.contains('dis')) return;
    const saved = sessionStorage.getItem('seaea6_desc_'+ST.retoId);
    if(saved) document.getElementById('modDesc').textContent = saved;
    document.getElementById('modInt').textContent = ST.intentos;
    document.getElementById('modReto').classList.add('show');
}
function closeModal() { document.getElementById('modReto').classList.remove('show'); }

/* ── MASCOTA ── */
const GUIA = [
    {t:'¡Bienvenido a Propiedades Periódicas!',
     m:'Hola, soy AmazonAtom 🦁\nEn este escenario compararás tres propiedades periódicas clave entre dos elementos de la tabla periódica:\n📏 Radio atómico\n⚡ Energía de ionización\n🔗 Electronegatividad', btn:'Siguiente →'},
    {t:'¿Qué es el Radio Atómico?',
     m:'📏 El radio atómico mide el tamaño del átomo.\n\n🔽 Aumenta al BAJAR en un grupo (más capas electrónicas).\n🔼 Disminuye al ir a la DERECHA en un período (más protones atraen los electrones).', btn:'Siguiente →'},
    {t:'Energía de Ionización',
     m:'⚡ Es la energía necesaria para arrancar un electrón.\n\n🔽 Disminuye al BAJAR en un grupo (electrones más lejos).\n🔼 Aumenta al ir a la DERECHA en un período (mayor atracción nuclear).', btn:'Siguiente →'},
    {t:'Electronegatividad',
     m:'🔗 Capacidad de un átomo para atraer electrones en un enlace.\n\n🔽 Disminuye al BAJAR en un grupo.\n🔼 Aumenta al ir a la DERECHA en un período.\n🏆 El flúor (F) es el más electronegativo.', btn:'Siguiente →'},
    {t:'¡Cómo usar este escenario!',
     m:'1️⃣ Selecciona el ELEMENTO A (primer clic) y el ELEMENTO B (segundo clic).\n2️⃣ Para cada propiedad, elige cuál elemento tiene el MAYOR valor.\n3️⃣ Presiona COMPROBAR para verificar.\n\n🏆 En evaluación debes acertar las 3 propiedades para superar un reto.', btn:'¡Entendido!'}
];

let paso=0, mGuia='inicial', afterCb=null;
function abrirMasc(modo){ mGuia=modo; renderMasc(); document.getElementById('ovMasc').classList.add('vis') }
function cerrarMasc(){
    document.getElementById('ovMasc').classList.remove('vis');
    if(afterCb){ const f=afterCb; afterCb=null; f() }
}
function mascAccion(){
    if(mGuia==='inicial'){ if(paso<GUIA.length-1){ paso++; renderMasc() } else cerrarMasc() }
    else cerrarMasc();
}
function renderMasc(){
    document.getElementById('mascImg').className = mGuia==='inicial' ? 'm-ava-img' : 'm-ava-img sm';
    document.getElementById('mBadge').style.display    = 'none';
    document.getElementById('mNuevoReto').style.display= 'none';
    if(mGuia==='inicial'){
        const g = GUIA[paso];
        document.getElementById('mTit').textContent  = g.t;
        document.getElementById('mTxt').textContent  = g.m;
        document.getElementById('mBtnP').textContent = g.btn;
        const w = document.getElementById('mPasos'); w.innerHTML='';
        GUIA.forEach((_,i)=>{ const d=document.createElement('div'); d.className='m-pt'+(i===paso?' act':''); w.appendChild(d) });
    }
}
function mostrarRetro(titulo, texto, estado, nuevoDesc, cb){
    mGuia='retro'; afterCb=cb||null;
    document.getElementById('mTit').textContent  = titulo;
    document.getElementById('mTxt').textContent  = texto;
    document.getElementById('mBtnP').textContent = 'Entendido';
    document.getElementById('mPasos').innerHTML  = '';
    document.getElementById('mascImg').className = 'm-ava-img sm';
    const badge = document.getElementById('mBadge');
    if(estado==='ok')  { badge.className='badge b-ok';  badge.textContent='✅ ¡Correcto!';        badge.style.display='inline-block' }
    if(estado==='err') { badge.className='badge b-err'; badge.textContent='❌ Incorrecto';         badge.style.display='inline-block' }
    if(estado==='warn'){ badge.className='badge b-warn';badge.textContent='⏱ Intentos agotados'; badge.style.display='inline-block' }
    if(estado==='sim') { badge.className='badge b-ok';  badge.textContent='🔍 Resultado';         badge.style.display='inline-block' }
    if(nuevoDesc){
        document.getElementById('mNuevoRetoDesc').textContent = nuevoDesc;
        document.getElementById('mNuevoReto').style.display   = 'block';
    }
    document.getElementById('ovMasc').classList.add('vis');
}

/* ── Botones A/B con data-attr para actualización visual ── */
document.addEventListener('DOMContentLoaded',()=>{
    // Añadir data-prop y data-val a botones A/B
    document.querySelectorAll('.btn-ab').forEach(btn => {
        const text = btn.textContent.trim();
        // La prop la obtenemos del padre .comp-fila
        const fila  = btn.closest('.comp-fila');
        const icono = fila ? fila.querySelector('.comp-icon').textContent : '';
        const prop  = icono.includes('📏') ? 'radio'
                    : icono.includes('⚡') ? 'ioniz'
                    : 'electr';
        btn.dataset.prop = prop;
        btn.dataset.val  = text;
    });

    // Timer
    if(ST.modoEval && ST.retoId){
        const storedId    = sessionStorage.getItem('seaea6_retoId');
        const storedTimer = parseInt(sessionStorage.getItem('seaea6_timer')||'0');
        if(storedId===ST.retoId && storedTimer>0){
            iniciarTimer(storedTimer);
        } else {
            sessionStorage.setItem('seaea6_retoId', ST.retoId);
            sessionStorage.setItem('seaea6_timer',  ST.tiempo);
            iniciarTimer(ST.tiempo);
        }
    }
    if(ST.retoId && ST.descReto)
        sessionStorage.setItem('seaea6_desc_'+ST.retoId, ST.descReto);
    if(ST.retoId) document.getElementById('btnQ').classList.remove('dis');

    /* ── Lógica mascota ── */
    <% if (tieneResult) { %>
    {
        const ok    = <%=correcto%>;
        const agot  = <%=intentosUsados%> >= <%=Reto.MAX_INTENTOS%>;
        const msg   = '<%=msgMascJs%>';
        const nuDesc= '<%=nuevoReto ? descRetoJs : ""%>';
        let titulo, estado;
        if(ok)       { titulo='¡Reto superado! 🎉';   estado='ok'   }
        else if(agot){ titulo='Intentos agotados 😔';  estado='warn' }
        else         { titulo='Intento fallido';        estado='err'  }
        setTimeout(()=>{
            mostrarRetro(titulo, msg, estado, nuDesc||null,
                <%=nuevoReto%> ? ()=>setTimeout(openModal,350) : null);
        }, 300);
    }
    <% } else if (Boolean.TRUE.equals(request.getAttribute("resultadoSimulacion"))) { %>
    {
        const msg = '<%=msgMascJs%>';
        setTimeout(()=>mostrarRetro('Resultado de la comparación', msg, 'sim', null, null), 300);
    }
    <% } else if (primeraCarga) { %>
    paso=0; setTimeout(()=>abrirMasc('inicial'), 350);
    <% } else if (nuevoReto && modoEval) { %>
    setTimeout(()=>openModal(), 400);
    <% } %>
});
</script>
</body>
</html>
