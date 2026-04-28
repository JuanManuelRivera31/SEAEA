<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%@ page import="modelo.ElementoBase, modelo.Reto, java.util.*, controlador.EscenarioCincoControlador" %>
<%
    // ── Estado general ───────────────────────────────────────────────────────
    int     porcentaje = request.getAttribute("porcentaje")     != null ? (int)request.getAttribute("porcentaje")     : 0;
    boolean modoEval   = Boolean.TRUE.equals(request.getAttribute("modoEvaluacion"));
    boolean habCont    = Boolean.TRUE.equals(request.getAttribute("habilitarContinuar"));

    // ── Elemento activo ──────────────────────────────────────────────────────
    ElementoBase ebAct    = (ElementoBase) request.getAttribute("elemActual");
    boolean      hayElem  = ebAct != null;
    int          zSel     = request.getAttribute("zSeleccionado") != null ? (int)request.getAttribute("zSeleccionado") : 0;
    int          eColocados = request.getAttribute("electronesColocados") != null ? (int)request.getAttribute("electronesColocados") : 0;
    String       notacion   = request.getAttribute("notacionCorrecta")   != null ? (String)request.getAttribute("notacionCorrecta") : "";

    // ── Configuración del usuario ─────────────────────────────────────────────
    @SuppressWarnings("unchecked")
    Map<String, int[]> configUser = (Map<String,int[]>) request.getAttribute("configUsuario");
    if (configUser == null) configUser = new LinkedHashMap<>();

    // ── Configuración correcta ───────────────────────────────────────────────
    @SuppressWarnings("unchecked")
    Map<String, Integer> configCorrecta = (Map<String, Integer>) request.getAttribute("configCorrecta");
    if (configCorrecta == null) configCorrecta = new LinkedHashMap<>();

    // ── Resultado ────────────────────────────────────────────────────────────
    String resultado = request.getAttribute("resultadoConfig") != null ? (String)request.getAttribute("resultadoConfig") : "";

    // ── Reto ─────────────────────────────────────────────────────────────────
    Reto   retoActual     = (Reto) request.getAttribute("retoActual");
    String descReto       = request.getAttribute("descripcionReto") != null ? (String)request.getAttribute("descripcionReto") : "";
    int    intentosUsados = request.getAttribute("intentosUsados")  != null ? (int)request.getAttribute("intentosUsados") : 0;
    int    temporizador   = request.getAttribute("temporizador")    != null ? (int)request.getAttribute("temporizador")    : 90;
    boolean nuevoReto     = Boolean.TRUE.equals(request.getAttribute("nuevoReto"));
    String  retoId        = request.getAttribute("retoId") != null ? (String)request.getAttribute("retoId") : "";

    // ── Mascota ──────────────────────────────────────────────────────────────
    String  msgMasc     = request.getAttribute("mensajeMascota") != null ? (String)request.getAttribute("mensajeMascota") : "";
    Object  rcObj       = request.getAttribute("resultadoCorrecto");
    boolean correcto    = rcObj != null && (boolean)rcObj;
    boolean tieneResult = rcObj != null;
    boolean primeraCarga = !modoEval && !tieneResult && !nuevoReto
                           && request.getAttribute("mensajeMascota") != null;

    // ── Lista elementos ──────────────────────────────────────────────────────
    @SuppressWarnings("unchecked")
    List<ElementoBase> elemList = (List<ElementoBase>) request.getAttribute("elementosPeriodica");

    // ── Helpers ──────────────────────────────────────────────────────────────
    String descRetoJs = descReto.replace("\\","\\\\").replace("'","\\'").replace("\n","\\n").replace("\r","");
    String msgMascJs  = msgMasc.replace("\\","\\\\").replace("`","'").replace("\n","\\n").replace("\r","");

    // Subniveles a mostrar (sólo s y p en orden)
    String[] SUBS = {"1s","2s","2p","3s","3p","4s","4p","5s","5p","6s","6p","7s","7p"};
    Map<String,Integer> CAP = new LinkedHashMap<>();
    CAP.put("1s",2);CAP.put("2s",2);CAP.put("2p",6);CAP.put("3s",2);CAP.put("3p",6);
    CAP.put("4s",2);CAP.put("4p",6);CAP.put("5s",2);CAP.put("5p",6);
    CAP.put("6s",2);CAP.put("6p",6);CAP.put("7s",2);CAP.put("7p",6);

    // Estado de cada celda: 0=vacío, 1=↑, 2=↑↓
    // Determinar qué subniveles son relevantes para el elemento actual
    Set<String> subsRelevantes = new HashSet<>(configCorrecta.keySet());

    // Helper: build mapa Z→ElementoBase
    Map<Integer,ElementoBase> zMap = new LinkedHashMap<>();
    if (elemList != null) for (ElementoBase e : elemList) zMap.put(e.getNumeroAtomico(), e);

    // Nobles y bloques para la tabla
    Set<Integer> nobles = new HashSet<>(Arrays.asList(2,10,18,36));
    Set<Integer> sBlockZ = new HashSet<>(Arrays.asList(1,3,4,11,12,19,20,37,38,55,56,87,88));
%>
<!DOCTYPE html>
<html lang="es">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<title>Configuración Electrónica – SEAEA</title>
<link href="https://fonts.googleapis.com/css2?family=Baloo+2:wght@700;800;900&family=Nunito:wght@400;600;700;800&display=swap" rel="stylesheet">
<style>
:root{
    --bg:#dde4f5;--panel:#f4f7ff;--border:#c5d2ec;
    --blue:#4a86f5;--blue-d:#1e56d0;
    --yellow:#f5c540;--yellow-d:#b89000;
    --red:#f46a6a;--red-d:#c43a3a;
    --green:#4ec87a;--green-d:#2a8a4e;
    --purple:#9b5de5;--purple-d:#6a35b0;
    --teal:#2ec4b6;
    --s-bg:#d2f5e2;--s-br:#2a8a4e;
    --p-bg:#dbeafe;--p-br:#3b82f6;
    --noble-bg:#fde0e0;--noble-br:#c43a3a;
    --ft:'Baloo 2',cursive;--fb:'Nunito',sans-serif;
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
.titulo{flex:1;text-align:center;font-family:var(--ft);font-size:20px;font-weight:900;
    color:#1a2848;letter-spacing:2px}
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

/* ══ GRID PRINCIPAL ══════════════════════════════════════════════════════════ */
.body-grid{display:grid;grid-template-columns:1fr 320px;gap:12px;align-items:start}
.col-left{display:flex;flex-direction:column;gap:8px}
.col-right{display:flex;flex-direction:column;gap:8px}

/* ── TABLA PERIÓDICA ── */
.tabla-titulo{font-size:11px;font-weight:800;color:#7a8cb0;
    letter-spacing:.8px;text-align:center;text-transform:uppercase;margin-bottom:3px}
.tabla-wrap{background:#edf2ff;border:2px solid var(--border);border-radius:12px;padding:7px 8px}
.tabla-periodica{display:grid;grid-template-columns:repeat(18,1fr);gap:2px}
.elem-cell{aspect-ratio:1;border-radius:4px;border:1.5px solid var(--border);
    background:#f0f4ff;cursor:pointer;
    display:flex;flex-direction:column;align-items:center;justify-content:center;
    transition:all .13s;min-width:0}
.elem-cell:hover{transform:scale(1.18);z-index:5;box-shadow:0 3px 10px rgba(74,134,245,.35)}
.elem-cell.vacia{background:transparent;border-color:transparent;cursor:default;pointer-events:none}
.elem-cell.seleccionado{background:var(--blue)!important;border-color:var(--blue-d)!important;
    box-shadow:0 0 0 2px rgba(74,134,245,.6)}
.elem-cell.seleccionado .ec-sim,.elem-cell.seleccionado .ec-z{color:#fff!important}
.ec-z  {font-size:5.5px;font-weight:800;color:#9aa8c8;line-height:1}
.ec-sim{font-size:8.5px;font-weight:900;color:#1a2848;line-height:1}
.bl-s     {background:var(--s-bg);   border-color:var(--s-br)}
.bl-s      .ec-sim{color:#1a4a2e}
.bl-p     {background:var(--p-bg);   border-color:var(--p-br)}
.bl-p      .ec-sim{color:#1e3a8a}
.bl-noble {background:var(--noble-bg);border-color:var(--noble-br)}
.bl-noble  .ec-sim{color:var(--red-d)}

/* ── PANEL DE CONFIGURACIÓN (columna izquierda inferior) ── */
.config-panel{background:#edf2ff;border:2px solid var(--border);border-radius:16px;padding:12px 14px}
.config-titulo{font-size:11px;font-weight:800;color:#7a8cb0;
    letter-spacing:.8px;text-transform:uppercase;text-align:center;margin-bottom:8px}

/* Columnas de subniveles */
.sub-grid{display:flex;gap:10px;flex-wrap:wrap;justify-content:center}
.sub-col{display:flex;flex-direction:column;gap:4px}
.sub-col-titulo{font-size:10px;font-weight:800;color:#9aa8c8;
    text-align:center;letter-spacing:.5px;margin-bottom:2px}

.sub-fila{display:flex;align-items:center;gap:5px}
.sub-lbl{font-size:11px;font-weight:900;color:#1a2848;
    width:26px;text-align:right;flex-shrink:0;font-family:var(--ft)}
.sub-lbl.vacia{color:#c5d2ec}
.sub-celdas{display:flex;gap:3px;flex-wrap:wrap}

/* Celda de electrón */
.e-celda{
    width:26px;height:32px;
    border:2px dashed #b0bfd8;border-radius:6px;
    background:#f8faff;
    display:flex;align-items:center;justify-content:center;
    font-size:16px;font-weight:900;
    cursor:pointer;transition:all .15s;
    user-select:none;line-height:1;
    color:transparent;
    flex-direction:column;gap:0;
}
.e-celda:hover{border-color:var(--blue);background:#e0ecff;transform:scale(1.08)}
.e-celda.vacia{cursor:default;pointer-events:none;opacity:.4}
.e-celda.up{color:var(--blue);border-color:var(--blue);background:#e0ecff;border-style:solid}
.e-celda.updown{color:var(--red-d);border-color:var(--red);background:#fde8e8;border-style:solid}
.e-celda.updown::before{content:'↑';font-size:10px;color:var(--blue);line-height:1}
.e-celda.updown::after {content:'↓';font-size:10px;color:var(--red-d);line-height:1}
.e-celda.up::before   {content:'↑';font-size:14px;color:var(--blue);line-height:1}
.e-celda.up::after    {content:'';font-size:0}
/* Estado correcto/incorrecto */
.e-celda.ok-c {border-color:var(--green)!important;background:#d2f5e2!important}
.e-celda.err-c{border-color:var(--red)!important;  background:#fde0e0!important}

/* ══ COL DERECHA ════════════════════════════════════════════════════════════ */

/* Carta del elemento */
.elem-carta{background:#edf2ff;border:2.5px solid var(--border);border-radius:18px;
    padding:14px;text-align:center;transition:all .3s}
.elem-carta.activa{border-color:var(--purple);background:#f5eeff;
    box-shadow:0 0 0 3px rgba(155,93,229,.15)}
.ec-titulo{font-family:var(--ft);font-size:22px;font-weight:900;color:#1a2848;margin-bottom:6px}
.ec-num{display:flex;align-items:stretch;gap:10px;justify-content:center;margin-bottom:8px}
.ec-nums-col{display:flex;flex-direction:column;align-items:center;justify-content:space-between;
    border-right:2px solid var(--border);padding-right:10px;min-width:32px}
.ec-masico,.ec-z{font-size:20px;font-weight:900;color:#1a2848;line-height:1}
.ec-simbolo{font-family:var(--ft);font-size:52px;font-weight:900;color:var(--purple);line-height:1}
.ec-simbolo.vacio{color:#b8c8e8}
.ec-nombre{font-size:12px;font-weight:700;color:#7a8cb0}

/* Notación de configuración actual */
.notac-box{background:#fff;border:2px solid var(--border);border-radius:12px;
    padding:10px 14px;text-align:center;min-height:42px;transition:all .3s}
.notac-box.ok {border-color:var(--green);background:#d2f5e2}
.notac-box.err{border-color:var(--red);  background:#fde0e0}
.notac-txt{font-family:var(--ft);font-size:16px;font-weight:800;color:var(--purple);
    word-break:break-all;line-height:1.4}
.notac-txt.ok {color:var(--green-d)}
.notac-txt.err{color:var(--red-d)}
.notac-estado{font-size:12px;font-weight:800;margin-top:4px}
.notac-estado.ok {color:var(--green-d)}
.notac-estado.err{color:var(--red-d)}

/* Contadores */
.info-rows{display:flex;flex-direction:column;gap:5px;margin-top:6px}
.info-row{display:flex;justify-content:space-between;align-items:center;
    background:#fff;border-radius:8px;padding:4px 10px}
.ir-lbl{font-size:11px;font-weight:800;color:#7a8cb0;text-transform:uppercase}
.ir-val{font-size:14px;font-weight:900;color:#1a2848}

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
    transform:scale(.84) translateY(20px);transition:transform .38s cubic-bezier(.34,1.56,.64,1)}
.ov-bg.vis .masc-card{transform:scale(1) translateY(0)}
.m-ava-img{width:80px;height:80px;object-fit:contain;margin:0 auto 10px;display:block;
    border-radius:50%;background:#f0f5ff;padding:5px;box-shadow:0 4px 16px rgba(74,134,245,.2)}
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
.mod-desc{font-size:12px;color:#444;line-height:1.6;margin-bottom:12px;white-space:pre-line}
.mod-meta{display:flex;gap:10px;margin-bottom:14px}
.meta-ch{background:#edf2ff;border:2px solid var(--border);border-radius:10px;
    padding:4px 10px;font-size:11px;font-weight:700;color:var(--blue-d)}
.mod-x{position:absolute;top:12px;right:14px;background:none;border:none;
    font-size:18px;cursor:pointer;color:#bbb}
.mod-x:hover{color:#ef4444}
</style>
</head>
<body>
<form id="frm" method="post" action="<%= request.getContextPath() %>/escenario5">
    <input type="hidden" name="accion"        id="hdnA"    value="">
    <input type="hidden" name="numeroAtomico" id="hdnZ"    value="">
    <input type="hidden" name="subnivel"      id="hdnSub"  value="">
    <input type="hidden" name="celda"         id="hdnCelda" value="">
</form>

<!-- OVERLAY MASCOTA -->
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

<!-- MODAL RETO -->
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
            onclick="closeModal();enviar('comprobar')">✓ Comprobar ahora</button>
  </div>
</div>

<!-- ══ SIMULADOR ══════════════════════════════════════════════════════════ -->
<div class="sim">

  <!-- TOP BAR -->
  <div class="top">
    <span class="lbl-apz">APRENDIZAJE</span>
    <div class="pill-pct <%= porcentaje>=80?"ok":"" %>"><%= porcentaje %>%</div>
    <div class="prog-track"><div class="prog-fill" style="width:<%= porcentaje %>%"></div></div>
    <span class="titulo">CONFIGURACIÓN ELECTRÓNICA</span>
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

      <!-- Tabla periódica (elementos s y p) -->
      <div>
        <div class="tabla-titulo">
          <% if (!modoEval) { %>
            Selecciona el elemento y escribe su configuración
          <% } else { %>
            Modo evaluación — configura el elemento del reto
          <% } %>
        </div>
        <div class="tabla-wrap">
          <div class="tabla-periodica">
            <%
              // Posiciones en el grid 18 cols x 4 filas (solo bloques s y p)
              // Usamos Map Z -> int[]{col, fila} para evitar sintaxis inválida en JSP
              java.util.Map<Integer,int[]> pos5 = new java.util.HashMap<>();
              pos5.put(1,  new int[]{0,0});  pos5.put(2,  new int[]{17,0});
              pos5.put(3,  new int[]{0,1});  pos5.put(4,  new int[]{1,1});
              pos5.put(5,  new int[]{12,1}); pos5.put(6,  new int[]{13,1});
              pos5.put(7,  new int[]{14,1}); pos5.put(8,  new int[]{15,1});
              pos5.put(9,  new int[]{16,1}); pos5.put(10, new int[]{17,1});
              pos5.put(11, new int[]{0,2});  pos5.put(12, new int[]{1,2});
              pos5.put(13, new int[]{12,2}); pos5.put(14, new int[]{13,2});
              pos5.put(15, new int[]{14,2}); pos5.put(16, new int[]{15,2});
              pos5.put(17, new int[]{16,2}); pos5.put(18, new int[]{17,2});
              pos5.put(19, new int[]{0,3});  pos5.put(20, new int[]{1,3});
              pos5.put(31, new int[]{12,3}); pos5.put(32, new int[]{13,3});
              pos5.put(33, new int[]{14,3}); pos5.put(34, new int[]{15,3});
              pos5.put(35, new int[]{16,3}); pos5.put(36, new int[]{17,3});

              int filas5 = 4;
              for (int fila5=0;fila5<filas5;fila5++) {
                for (int col5=0;col5<18;col5++) {
                  ElementoBase eC=null;
                  for (java.util.Map.Entry<Integer,int[]> ep : pos5.entrySet()) {
                    int[] rc = ep.getValue();
                    if (rc[0]==col5 && rc[1]==fila5 && zMap.containsKey(ep.getKey())){
                      eC=zMap.get(ep.getKey());break;
                    }
                  }
                  if (eC==null) { %><div class="elem-cell vacia"></div><% }
                  else {
                    int zz2=eC.getNumeroAtomico();
                    String blk5=nobles.contains(zz2)?"bl-noble":sBlockZ.contains(zz2)?"bl-s":"bl-p";
                    String selCls5=(zz2==zSel)?" seleccionado":"";
                    String oc5=modoEval?"":"onclick=\"selElem("+zz2+")\"";
            %>
              <div class="elem-cell <%=blk5%><%=selCls5%>"
                   title="<%=eC.getNombre()%> (Z=<%=zz2%>)" <%=oc5%>>
                <span class="ec-z"><%=zz2%></span>
                <span class="ec-sim"><%=eC.getSimbolo()%></span>
              </div>
            <% }} } %>
          </div>
        </div>
      </div>

      <!-- Panel de configuración electrónica -->
      <div class="config-panel">
        <div class="config-titulo">⚛ Diagrama de configuración electrónica</div>
        <div class="sub-grid">
          <%
            // Agrupar subniveles en columna "s" y columna "p"
            String[] subsS = {"1s","2s","3s","4s","5s","6s","7s"};
            String[] subsP = {"2p","3p","4p","5p","6p","7p"};
          %>
          <!-- Columna s -->
          <div class="sub-col">
            <div class="sub-col-titulo">Subnivel s</div>
            <%
              // Mostrar en orden descendente (7s abajo, 1s arriba visualmente invertido)
              for (int si = subsS.length-1; si >= 0; si--) {
                String sub = subsS[si];
                int capSub = CAP.get(sub);
                int numCeldas = capSub / 2;
                int[] estadoCeldas = configUser.get(sub);
                if (estadoCeldas == null) estadoCeldas = new int[numCeldas];
                // Determinar si este subnivel es relevante
                boolean relevante = !hayElem || configCorrecta.containsKey(sub);
                int eCorrectos = configCorrecta.getOrDefault(sub, 0);
                int eUsuario = 0;
                for (int ec : estadoCeldas) eUsuario += (ec==1?1:ec==2?2:0);
            %>
            <div class="sub-fila">
              <span class="sub-lbl <%= !relevante?"vacia":"" %>"><%= sub %></span>
              <div class="sub-celdas">
                <% for (int ci = 0; ci < numCeldas; ci++) {
                    int estado = estadoCeldas[ci];
                    String clsEstado = estado==0?"":estado==1?"up":"updown";
                    // Clase de corrección
                    String clsCorr = "";
                    if (!resultado.isEmpty() && relevante && hayElem) {
                        clsCorr = eUsuario==eCorrectos ? " ok-c" : " err-c";
                    }
                    String clsVacia = !relevante ? " vacia" : "";
                    String onclickCelda = relevante
                        ? "onclick=\"clickCelda('"+sub+"',"+ci+")\""
                        : "";
                %>
                <div class="e-celda <%= clsEstado+clsCorr+clsVacia %>"
                     title="<%= sub %> celda <%= ci+1 %>"
                     <%= onclickCelda %>></div>
                <% } %>
              </div>
            </div>
            <% } %>
          </div>

          <!-- Columna p -->
          <div class="sub-col">
            <div class="sub-col-titulo">Subnivel p</div>
            <%
              for (int si = subsP.length-1; si >= 0; si--) {
                String sub = subsP[si];
                int capSub = CAP.get(sub);
                int numCeldas = capSub / 2; // p tiene 3 celdas
                int[] estadoCeldas = configUser.get(sub);
                if (estadoCeldas == null) estadoCeldas = new int[numCeldas];
                boolean relevante = !hayElem || configCorrecta.containsKey(sub);
                int eCorrectos = configCorrecta.getOrDefault(sub, 0);
                int eUsuario = 0;
                for (int ec : estadoCeldas) eUsuario += (ec==1?1:ec==2?2:0);
            %>
            <div class="sub-fila">
              <span class="sub-lbl <%= !relevante?"vacia":"" %>"><%= sub %></span>
              <div class="sub-celdas">
                <% for (int ci = 0; ci < numCeldas; ci++) {
                    int estado = estadoCeldas[ci];
                    String clsEstado = estado==0?"":estado==1?"up":"updown";
                    String clsCorr = "";
                    if (!resultado.isEmpty() && relevante && hayElem) {
                        clsCorr = eUsuario==eCorrectos ? " ok-c" : " err-c";
                    }
                    String clsVacia = !relevante ? " vacia" : "";
                    String onclickCelda = relevante
                        ? "onclick=\"clickCelda('"+sub+"',"+ci+")\""
                        : "";
                %>
                <div class="e-celda <%= clsEstado+clsCorr+clsVacia %>"
                     title="<%= sub %> celda <%= ci+1 %>"
                     <%= onclickCelda %>></div>
                <% } %>
              </div>
            </div>
            <% } %>
          </div>
        </div>
      </div>

    </div><!-- /col-left -->

    <!-- ── COLUMNA DERECHA ── -->
    <div class="col-right">

      <!-- Carta del elemento -->
      <div class="elem-carta <%= hayElem?"activa":"" %>">
        <% if (hayElem) { %>
        <div class="ec-titulo"><%= ebAct.getNumeroAtomico() %> — <%= ebAct.getNombre() %></div>
        <div class="ec-num">
          <div class="ec-nums-col">
            <span class="ec-masico"><%= ebAct.getNumeroAtomico() %></span>
            <span class="ec-z"><%= ebAct.getNumeroAtomico() %></span>
          </div>
          <div>
            <div class="ec-simbolo"><%= ebAct.getSimbolo() %></div>
            <div class="ec-nombre"><%= ebAct.getNombre() %></div>
          </div>
        </div>
        <% } else { %>
        <div class="ec-titulo">Selecciona un elemento</div>
        <div class="ec-simbolo vacio" style="font-size:52px;text-align:center">?</div>
        <% } %>
      </div>

      <!-- Notación de configuración actual -->
      <div class="notac-box <%= resultado.equals("ok")?"ok":resultado.equals("err")?"err":"" %>">
        <% if (eColocados > 0) { %>
        <div class="notac-txt <%= resultado.equals("ok")?"ok":resultado.equals("err")?"err":"" %>" id="notacTxt">
          <%
            // Construir notación desde la config del usuario
            StringBuilder sbNotac = new StringBuilder();
            String[] subsOrden5 = {"1s","2s","2p","3s","3p","4s","4p","5s","5p","6s","6p","7s","7p"};
            String[] superIdxArr = {"⁰","¹","²","³","⁴","⁵","⁶"};
            for (String subN : subsOrden5) {
                int[] celdN = configUser.get(subN);
                if (celdN == null) continue;
                int eN = 0;
                for (int ec : celdN) eN += (ec==1?1:ec==2?2:0);
                if (eN > 0) {
                    String supN = eN < superIdxArr.length ? superIdxArr[eN] : String.valueOf(eN);
                    sbNotac.append(subN).append(supN).append(" ");
                }
            }
            String notacUsuario = sbNotac.toString().trim().isEmpty() ? "—" : sbNotac.toString().trim();
          %>
          <%= notacUsuario %>
        </div>
        <% if (!resultado.isEmpty()) { %>
        <div class="notac-estado <%= resultado.equals("ok")?"ok":"err" %>">
          <%= resultado.equals("ok") ? "✅ CONFIGURACIÓN CORRECTA" : "❌ CONFIGURACIÓN INCORRECTA" %>
        </div>
        <% } %>
        <% } else { %>
        <div class="notac-txt" style="color:#b8c8e8">Aún no has colocado electrones</div>
        <% } %>
      </div>

      <!-- Información -->
      <div class="info-rows">
        <div class="info-row">
          <span class="ir-lbl">Electrones colocados:</span>
          <span class="ir-val" id="eCount"><%= eColocados %></span>
        </div>
        <% if (hayElem) { %>
        <div class="info-row">
          <span class="ir-lbl">Total esperado:</span>
          <span class="ir-val"><%= ebAct.getNumeroAtomico() %></span>
        </div>
        <% } %>
      </div>

      <!-- Configuración correcta (solo después de comprobar) -->
      <% if (!resultado.isEmpty() && hayElem) { %>
      <div style="background:#f0f5ff;border:2px solid var(--border);border-radius:12px;padding:10px 12px">
        <div style="font-size:10px;font-weight:800;color:#7a8cb0;letter-spacing:.5px;text-transform:uppercase;margin-bottom:4px">Configuración correcta</div>
        <div style="font-family:var(--ft);font-size:14px;font-weight:800;color:var(--green-d)"><%= notacion %></div>
      </div>
      <% } %>

    </div><!-- /col-right -->

  </div><!-- /body-grid -->

  <!-- BOTONES INFERIORES -->
  <div class="acciones">
    <button class="btn-ac ac-r" onclick="confirmarReiniciar()">REINICIAR</button>
    <button class="btn-ac ac-c" id="btnComp"
            <%= !hayElem?"disabled":"" %>
            onclick="enviar('comprobar')">COMPROBAR</button>
    <button class="btn-ac ac-v" onclick="confirmarVolver()">VOLVER</button>
    <button class="btn-ac ac-k" id="btnCont"
            <%= !habCont?"disabled":"" %>
            onclick="enviar('continuar')">CONTINUAR</button>
  </div>

</div><!-- /sim -->

<script>
const ST = {
    modoEval: <%=modoEval%>,
    hayElem:  <%=hayElem%>,
    tiempo:   <%=temporizador%>,
    intentos: <%=intentosUsados%>,
    maxInt:   <%=Reto.MAX_INTENTOS%>,
    retoId:   '<%=retoId%>',
    descReto: '<%=descRetoJs%>'
};

function enviar(accion){
    document.getElementById('hdnA').value = accion;
    document.getElementById('frm').submit();
}
function selElem(z){
    document.getElementById('hdnA').value = 'seleccionarElemento';
    document.getElementById('hdnZ').value = z;
    document.getElementById('frm').submit();
}
function clickCelda(sub, celda){
    document.getElementById('hdnA').value     = 'clickCelda';
    document.getElementById('hdnSub').value   = sub;
    document.getElementById('hdnCelda').value = celda;
    document.getElementById('frm').submit();
}
function confirmarReiniciar(){ if(confirm('¿Reiniciar? Se perderá el progreso.')) enviar('reiniciar') }
function confirmarVolver()   { if(confirm('¿Volver al menú? Se perderá el progreso.')) enviar('volver') }

/* ── TIMER ── */
let timerSeg=null,timerInvl=null;

function actualizarHUD(segs){
    const txt=segs>0?segs+'s':'¡Tiempo!';
    const h=document.getElementById('hudTimer');
    const m=document.getElementById('modTimer');
    if(h){h.textContent=txt;h.className='hud-t'+(segs>20?' ok':'')}
    if(m) m.textContent=txt;
}

function iniciarTimer(segs){
    if(timerInvl) clearInterval(timerInvl);
    timerSeg=segs;
    // Actualizar HUD de inmediato: evita el parpadeo visible en 90s al recargar
    actualizarHUD(timerSeg);
    timerInvl=setInterval(()=>{
        timerSeg--;
        sessionStorage.setItem('seaea5_timer',timerSeg);
        actualizarHUD(timerSeg);
        if(timerSeg<=0){
            clearInterval(timerInvl);timerInvl=null;
            sessionStorage.removeItem('seaea5_timer');
            sessionStorage.removeItem('seaea5_retoId');
            setTimeout(()=>enviar('comprobar'),800);
        }
    },1000);
}

function openModal(){
    if(document.getElementById('btnQ').classList.contains('dis')) return;
    const saved=sessionStorage.getItem('seaea5_desc_'+ST.retoId);
    if(saved) document.getElementById('modDesc').textContent=saved;
    document.getElementById('modInt').textContent=ST.intentos;
    document.getElementById('modReto').classList.add('show');
}
function closeModal(){ document.getElementById('modReto').classList.remove('show') }

/* ── MASCOTA ── */
const GUIA=[
    {t:'¡Bienvenido a Configuración Electrónica!',
     m:'Hola, soy AmazonAtom 🦁\nEn este escenario aprenderás a escribir la configuración electrónica de los elementos usando el principio de Aufbau y la regla de Hund.',btn:'Siguiente →'},
    {t:'¿Qué es la configuración electrónica?',
     m:'⚛️ Es la distribución de los electrones en los distintos subniveles de energía.\n\nOrden de llenado (Aufbau):\n1s → 2s → 2p → 3s → 3p → 4s → 4p → 5s → 5p...',btn:'Siguiente →'},
    {t:'Capacidad de los subniveles',
     m:'📌 Cada celda del diagrama representa un orbital:\n\n• Subnivel s: 1 orbital (máx. 2e⁻)\n• Subnivel p: 3 orbitales (máx. 6e⁻)\n\n🔼 Primer clic → ↑ (electrón solo)\n🔽 Segundo clic → ↓ (par de electrones)\n✖️ Tercer clic → vaciar la celda',btn:'Siguiente →'},
    {t:'Regla de Hund',
     m:'📏 Regla de Hund: en un subnivel con varios orbitales (ej. 2p), primero se llena uno por orbital con spin ↑ antes de emparejar.\n\nEjemplo correcto 2p con 3e⁻:\n[↑][ ↑][↑]\nNO: [↑↓][↑][ ]',btn:'Siguiente →'},
    {t:'¡Cómo usar el simulador!',
     m:'1️⃣ Selecciona un elemento de la tabla periódica.\n2️⃣ Haz clic en las celdas del diagrama para agregar electrones.\n3️⃣ Presiona COMPROBAR para verificar tu configuración.\n\n🏆 En evaluación debes completar la configuración correctamente para superar los retos.',btn:'¡Entendido!'}
];

let paso=0,mGuia='inicial',afterCb=null;
function abrirMasc(modo){mGuia=modo;renderMasc();document.getElementById('ovMasc').classList.add('vis')}
function cerrarMasc(){
    document.getElementById('ovMasc').classList.remove('vis');
    if(afterCb){const f=afterCb;afterCb=null;f()}
}
function mascAccion(){
    if(mGuia==='inicial'){if(paso<GUIA.length-1){paso++;renderMasc()}else cerrarMasc()}
    else cerrarMasc();
}
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
    if(estado==='ok')  {badge.className='badge b-ok';  badge.textContent='✅ ¡Correcto!';        badge.style.display='inline-block'}
    if(estado==='err') {badge.className='badge b-err'; badge.textContent='❌ Incorrecto';         badge.style.display='inline-block'}
    if(estado==='warn'){badge.className='badge b-warn';badge.textContent='⏱ Intentos agotados';  badge.style.display='inline-block'}
    if(nuevoDesc){
        document.getElementById('mNuevoRetoDesc').textContent=nuevoDesc;
        document.getElementById('mNuevoReto').style.display='block';
    }
    document.getElementById('ovMasc').classList.add('vis');
}

document.addEventListener('DOMContentLoaded',()=>{
    if(ST.modoEval&&ST.retoId){
        const sid=sessionStorage.getItem('seaea5_retoId');
        const st=parseInt(sessionStorage.getItem('seaea5_timer')||'0');
        if(sid===ST.retoId&&st>0){iniciarTimer(st)}
        else{
            sessionStorage.setItem('seaea5_retoId',ST.retoId);
            sessionStorage.setItem('seaea5_timer',ST.tiempo);
            iniciarTimer(ST.tiempo);
        }
    }
    if(ST.retoId&&ST.descReto)
        sessionStorage.setItem('seaea5_desc_'+ST.retoId,ST.descReto);
    if(ST.retoId) document.getElementById('btnQ').classList.remove('dis');

    <% if (tieneResult) { %>
    {
        const ok   = <%=correcto%>;
        const agot = <%=intentosUsados%>>=<%=Reto.MAX_INTENTOS%>;
        const msg  = '<%=msgMascJs%>';
        const nuDesc='<%=nuevoReto?descRetoJs:""%>';
        let titulo,estado;
        if(ok)       {titulo='¡Reto superado! 🎉';   estado='ok'}
        else if(agot){titulo='Intentos agotados 😔';  estado='warn'}
        else         {titulo='Configuración incorrecta';estado='err'}
        setTimeout(()=>{
            mostrarRetro(titulo,msg,estado,nuDesc||null,
                <%=nuevoReto%>?()=>setTimeout(openModal,350):null);
        },300);
    }
    <% } else if (!resultado.isEmpty() && !modoEval) { %>
    {
        const msg='<%=msgMascJs%>';
        const ok='<%=resultado%>'==='ok';
        setTimeout(()=>mostrarRetro(
            ok?'Configuración correcta ✅':'Revisa tu configuración ❌',
            msg, ok?'ok':'err', null, null),300);
    }
    <% } else if (primeraCarga) { %>
    paso=0; setTimeout(()=>abrirMasc('inicial'),350);
    <% } else if (nuevoReto&&modoEval) { %>
    setTimeout(()=>openModal(),400);
    <% } %>
});
</script>
</body>
</html>
