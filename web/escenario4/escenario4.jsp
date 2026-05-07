<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%@ page import="modelo.ElementoBase, modelo.Reto, modelo.Isotopo, java.util.List" %>
<%
    int     porcentaje = request.getAttribute("porcentaje")     != null ? (int)request.getAttribute("porcentaje")     : 0;
    boolean modoEval   = Boolean.TRUE.equals(request.getAttribute("modoEvaluacion"));
    boolean habCont    = Boolean.TRUE.equals(request.getAttribute("habilitarContinuar"));

    ElementoBase ebSel      = (ElementoBase) request.getAttribute("elementoSeleccionado");
    boolean      hayElem    = ebSel != null;
    int    zSel     = request.getAttribute("zSeleccionado")      != null ? (int)request.getAttribute("zSeleccionado")      : 0;
    int    protones = hayElem ? ebSel.getNumeroAtomico() : 0;
    String simSel   = hayElem ? ebSel.getSimbolo()       : "";
    String nomSel   = hayElem ? ebSel.getNombre()        : "";

    int nAct = request.getAttribute("neutronesActuales") != null ? (int)request.getAttribute("neutronesActuales") : 0;

    String nomIsoAct  = request.getAttribute("nombreIsotopoActual") != null ? (String)request.getAttribute("nombreIsotopoActual")  : "—";
    String estabAct   = request.getAttribute("estabilidadActual")   != null ? (String)request.getAttribute("estabilidadActual")    : "—";
    double abundAct   = request.getAttribute("abundanciaActual")    != null ? (double)request.getAttribute("abundanciaActual")     : 0.0;
    double masaIsoAct = request.getAttribute("masaIsotopicaActual") != null ? (double)request.getAttribute("masaIsotopicaActual")  : 0.0;
    int    numMasicoAct = request.getAttribute("numeroMasicoActual") != null ? (int)request.getAttribute("numeroMasicoActual")     : 0;

    Reto   retoActual     = (Reto)    request.getAttribute("retoActual");
    String descReto       = request.getAttribute("descripcionReto") != null ? (String)request.getAttribute("descripcionReto") : "";
    int    intentosUsados = request.getAttribute("intentosUsados")  != null ? (int)request.getAttribute("intentosUsados")    : 0;
    int    temporizador   = request.getAttribute("temporizador")    != null ? (int)request.getAttribute("temporizador")      : 90;
    boolean nuevoReto     = Boolean.TRUE.equals(request.getAttribute("nuevoReto"));
    String  retoId        = request.getAttribute("retoId") != null  ? (String)request.getAttribute("retoId")                : "";

    Isotopo      isoObj            = (Isotopo)      request.getAttribute("isotopoObjetivo");
    ElementoBase ebReto            = (ElementoBase) request.getAttribute("ebReto");
    String       nomIsoObj         = request.getAttribute("nomIsotopoObjetivo")  != null ? (String)request.getAttribute("nomIsotopoObjetivo")  : "";
    int          neutronesObjetivo = request.getAttribute("neutronesObjetivo")   != null ? (int)request.getAttribute("neutronesObjetivo")      : 0;
    boolean      hayObjetivo       = isoObj != null && modoEval;

    String  msgMasc     = request.getAttribute("mensajeMascota")  != null ? (String)request.getAttribute("mensajeMascota") : "";
    Object  rcObj       = request.getAttribute("resultadoCorrecto");
    boolean correcto    = rcObj != null && (boolean)rcObj;
    boolean tieneResult = rcObj != null;
    boolean primeraCarga = !modoEval && !tieneResult && !nuevoReto && request.getAttribute("mensajeMascota") != null;

    @SuppressWarnings("unchecked")
    List<ElementoBase> elemPeriodica = (List<ElementoBase>)request.getAttribute("elementosPeriodica");

    String descRetoJs = descReto.replace("\\","\\\\").replace("'","\\'").replace("\n","\\n").replace("\r","");
    String msgMascJs  = msgMasc.replace("\\","\\\\").replace("`","'").replace("\n","\\n").replace("\r","");

    String abundStr = abundAct > 0 ? String.format("%.4f%%", abundAct) : (hayElem ? "No registrada" : "—");
    String masaStr  = masaIsoAct > 0 ? String.format("%.5f u", masaIsoAct)
                      : (hayElem ? String.format("%.5f u",(double)ebSel.getMasaAtomica()) : "—");
    int aActual = hayElem ? (protones + nAct) : 0;

    boolean estable = hayElem && "ESTABLE".equals(estabAct);
%>
<!DOCTYPE html>
<html lang="es">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<title>Configura tu Isótopo – SEAEA</title>
<link href="https://fonts.googleapis.com/css2?family=Baloo+2:wght@700;800;900&family=Nunito:wght@400;600;700;800&display=swap" rel="stylesheet">
<style>
:root{
    --bg:#dde4f5; --panel:#f4f7ff; --border:#c5d2ec;
    --blue:#4a86f5; --blue-d:#1e56d0;
    --yellow:#f5c540; --yellow-d:#c49000;
    --red:#f46a6a; --red-d:#c43a3a;
    --green:#4ec87a; --green-d:#2a8a4e;
    --pink:#f470b0;
    --teal:#2ec4b6; --teal-d:#1a8a80;
    --ft:'Baloo 2',cursive; --fb:'Nunito',sans-serif;
}
*,*::before,*::after{box-sizing:border-box;margin:0;padding:0}
body{background:var(--bg);font-family:var(--fb);min-height:100vh;
    display:flex;align-items:flex-start;justify-content:center;padding:10px}

/* ══ CONTENEDOR PRINCIPAL ══ */
.sim{background:var(--panel);border:3px solid var(--border);border-radius:28px;
    box-shadow:0 8px 32px rgba(40,70,160,.12);width:100%;max-width:1160px;
    padding:14px 22px 20px;display:flex;flex-direction:column;gap:12px}

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
    background:linear-gradient(90deg,#f46a6a 0%,#f5c540 50%,#4ec87a 100%);transition:width .7s}
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

/* ══ GRID PRINCIPAL  3 columnas ══ */
.body-grid{display:grid;grid-template-columns:230px 1fr 260px;gap:14px;align-items:start}

/* ══════════════ COL IZQUIERDA ══════════════ */
.col-left{display:flex;flex-direction:column;gap:10px}

/* Carta del elemento */
.carta-elem{background:#edf2ff;border:2.5px solid var(--border);border-radius:18px;
    padding:14px 12px;display:flex;flex-direction:column;align-items:center;gap:6px}
.ce-head{display:flex;align-items:center;gap:10px;width:100%}
.ce-nums{display:flex;flex-direction:column;align-items:center;
    padding-right:10px;border-right:2px solid var(--border);min-width:38px}
.ce-mas,.ce-z{font-size:22px;font-weight:900;color:#1a2848;line-height:1.1}
.ce-sim{font-family:var(--ft);font-size:52px;font-weight:900;color:var(--blue);
    line-height:1;flex:1;text-align:center}
.ce-sim.vacio{color:#b8c8e8}
.ce-nom{font-size:12px;font-weight:700;color:#7a8cb0;text-align:center;width:100%}

/* Panel info isótopo */
.iso-info{background:#edf2ff;border:2px solid var(--border);border-radius:14px;
    padding:10px 14px;display:flex;flex-direction:column;gap:6px}
.iso-row{display:flex;justify-content:space-between;align-items:center}
.iso-lbl{font-size:10px;font-weight:800;color:#7a8cb0;text-transform:uppercase;letter-spacing:.4px}
.iso-val{font-size:13px;font-weight:900;color:#1a2848;
    background:#fff;border:1.5px solid var(--border);border-radius:8px;
    padding:2px 10px;min-width:80px;text-align:center}
.iso-val.estable  {background:#d2f5e2;border-color:var(--green);color:#1a6e38}
.iso-val.inestable{background:#fde0e0;border-color:var(--red);color:var(--red-d)}

/* Conteo con puntos */
.cont-panel{background:#fff;border:2px solid var(--border);border-radius:12px;
    padding:10px 14px;display:flex;flex-direction:column;gap:5px}
.cont-fila{display:flex;align-items:center;gap:6px}
.cont-lbl{font-size:11px;font-weight:700;color:#555;width:70px;flex-shrink:0}
.dots-a{display:flex;flex-wrap:wrap;gap:3px;flex:1;min-height:14px}
.dot{width:11px;height:11px;border-radius:50%;border:1.5px solid rgba(0,0,0,.1)}
.dot.d-p{background:var(--blue)}
.dot.d-n{background:var(--yellow)}
.dot.d-e{background:var(--pink)}
.cont-num{font-size:14px;font-weight:800;min-width:20px;text-align:right}

/* ══════════════ COL CENTRAL ══════════════ */
.col-center{display:flex;flex-direction:column;align-items:center;gap:12px}

/* Nombre isótopo */
.iso-nombre{font-family:var(--ft);font-size:28px;font-weight:900;
    color:#1a2848;letter-spacing:2px;text-align:center;
    background:#edf2ff;border:2.5px solid var(--border);border-radius:14px;
    padding:8px 20px;width:100%;transition:all .3s}
.iso-nombre.activo{color:var(--blue);border-color:var(--blue);background:#e8f0ff}

/* ════ BALANZA ════ */
.balanza-wrap{width:100%;position:relative;height:220px;display:flex;
    align-items:flex-end;justify-content:center}

/* Fulcro y base */
.bal-base{position:absolute;bottom:0;left:50%;transform:translateX(-50%);
    width:90px;height:12px;background:#8faad8;border-radius:6px}
.bal-fulcro{position:absolute;bottom:12px;left:50%;transform:translateX(-50%);
    width:12px;height:55px;background:linear-gradient(180deg,#8faad8,#5070b0);
    border-radius:0 0 3px 3px}
/* Brazo */
.bal-brazo{position:absolute;bottom:67px;left:50%;
    width:300px;height:8px;
    background:linear-gradient(90deg,#c5d2ec,#7a9cd8,#c5d2ec);
    border-radius:4px;transform:translateX(-50%) rotate(0deg);
    transform-origin:center center;transition:transform .5s ease;
    box-shadow:0 2px 6px rgba(40,70,160,.2)}

/* Platos */
.bal-plato{position:absolute;bottom:80px;display:flex;flex-direction:column;align-items:center}
.bal-plato.izq{left:10px}
.bal-plato.der{right:10px}
.bal-cuerda{width:2px;height:44px;background:#8faad8}
.bal-disco{width:110px;height:12px;background:linear-gradient(180deg,#b8ccf0,#8faad8);
    border-radius:50%;box-shadow:0 3px 8px rgba(40,70,160,.15)}
.bal-etiq{font-size:10px;font-weight:800;color:#7a8cb0;text-transform:uppercase;
    letter-spacing:.4px;margin-top:3px;text-align:center}

/* Contenedor núcleo en balanza */
.nucleo-wrap{width:100px;height:80px;display:flex;align-items:center;justify-content:center;
    margin-bottom:2px}

/* Contenedor neutrones (izquierda) */
.neutrones-lado{width:100px;height:80px;display:flex;flex-direction:column;
    align-items:center;justify-content:center;gap:4px;margin-bottom:2px}
.neutrones-btn-wrap{display:flex;gap:6px;align-items:center}
.btn-np{width:34px;height:34px;border-radius:50%;border:none;
    font-size:22px;font-weight:900;color:#fff;cursor:pointer;
    display:flex;align-items:center;justify-content:center;
    transition:transform .12s,box-shadow .1s;user-select:none;line-height:1}
.btn-np.plus {background:var(--green);box-shadow:0 4px 0 var(--green-d)}
.btn-np.minus{background:var(--red);  box-shadow:0 4px 0 var(--red-d)}
.btn-np.plus:active {transform:translateY(2px);box-shadow:0 2px 0 var(--green-d)}
.btn-np.minus:active{transform:translateY(2px);box-shadow:0 2px 0 var(--red-d)}
.btn-np:disabled{opacity:.4;cursor:not-allowed;transform:none}
.neutrones-count{font-family:var(--ft);font-size:28px;font-weight:900;color:#1a2848}
.neutrones-etiq{background:var(--yellow);color:#5a3800;border-radius:20px;
    padding:2px 10px;font-size:10px;font-weight:800;box-shadow:0 2px 0 var(--yellow-d)}

/* Estabilidad y abundancia */
.estab-abund{display:flex;gap:10px;width:100%}
.estab-box,.abund-box{flex:1;border-radius:14px;padding:10px;text-align:center;
    border:2px solid var(--border)}
.estab-box.estable  {background:#d2f5e2;border-color:var(--green)}
.estab-box.inestable{background:#fde0e0;border-color:var(--red)}
.estab-box.vacio    {background:#f8faff}
.estab-lbl,.abund-lbl{font-size:9px;font-weight:800;color:#7a8cb0;
    text-transform:uppercase;letter-spacing:.4px;margin-bottom:2px}
.estab-val{font-family:var(--ft);font-size:16px;font-weight:900;color:#1a2848}
.estab-val.estable  {color:var(--green-d)}
.estab-val.inestable{color:var(--red-d)}
.abund-box{background:linear-gradient(135deg,#f0f5ff,#e8f5ee)}
.abund-val{font-family:var(--ft);font-size:20px;font-weight:900;color:var(--green-d)}
.abund-val.cero{color:#aab8d0;font-size:14px;font-weight:700}

/* ══════════════ COL DERECHA ══════════════ */
.col-right{display:flex;flex-direction:column;gap:10px}

/* Tabla periódica */
.tabla-tit{font-size:10px;font-weight:800;color:#7a8cb0;
    letter-spacing:.8px;text-transform:uppercase;text-align:center}
.tabla-wrap{background:#edf2ff;border:2px solid var(--border);border-radius:12px;
    padding:6px 7px}
.tabla-grid{display:grid;grid-template-columns:repeat(18,1fr);gap:2px}
.ec{aspect-ratio:1;border-radius:4px;border:1.5px solid var(--border);
    background:#f0f4ff;cursor:pointer;
    display:flex;flex-direction:column;align-items:center;justify-content:center;
    transition:all .13s;min-width:0}
.ec:hover{transform:scale(1.18);z-index:5;
    box-shadow:0 3px 10px rgba(74,134,245,.35);background:#d0e0ff;border-color:var(--blue)}
.ec.vacia{background:transparent;border-color:transparent;cursor:default;pointer-events:none}
.ec.sel{background:var(--blue)!important;border-color:var(--blue-d)!important;
    box-shadow:0 0 0 2px rgba(74,134,245,.5)}
.ec.sel .ec-sim,.ec.sel .ec-z{color:#fff!important}
.ec-z  {font-size:5.5px;font-weight:800;color:#9aa8c8;line-height:1}
.ec-sim{font-size:8.5px;font-weight:900;color:#1a2848;line-height:1.1}
/* Bloques */
.ec.blk-s {background:#d2f5e2;border-color:#2a8a4e}.ec.blk-s  .ec-sim{color:#1a4a2e}
.ec.blk-p {background:#edf2ff;border-color:#c5d2ec}
.ec.blk-d {background:#fef9e7;border-color:#f5c540}.ec.blk-d  .ec-sim{color:#6a4800}
.ec.noble {background:#f3e5ff;border-color:#9b5de5}.ec.noble  .ec-sim{color:#5a1a9a}

/* Carta objetivo */
.obj-box{background:#edf2ff;border:2.5px solid var(--teal);border-radius:16px;padding:12px 14px}
.obj-box.vacio{border-style:dashed;border-color:var(--border);background:#f8faff}
.obj-tit{font-size:10px;font-weight:800;color:var(--teal-d);
    letter-spacing:.5px;text-transform:uppercase;text-align:center;margin-bottom:6px}
.obj-iso-nom{font-family:var(--ft);font-size:18px;font-weight:900;
    color:#1a2848;text-align:center;margin-bottom:6px}
.obj-row{display:flex;justify-content:space-between;align-items:center;
    background:#fff;border-radius:8px;padding:3px 8px;margin-bottom:4px}
.obj-row:last-child{margin-bottom:0}
.obj-lbl{font-size:9px;font-weight:800;color:#7a8cb0;text-transform:uppercase}
.obj-val{font-size:11px;font-weight:900;color:#1a2848}
.obj-placeholder{text-align:center;padding:12px;color:#aab8d0;font-size:11px;font-weight:700}

/* ── BOTONES INFERIORES ── */
.acciones{display:flex;justify-content:center;gap:10px;flex-wrap:wrap}
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
.ac-r:active,.ac-c:active,.ac-v:active,.ac-k:active{transform:translateY(2px)}

/* ── OVERLAY MASCOTA ── */
.ov-bg{position:fixed;inset:0;background:rgba(15,25,60,.52);backdrop-filter:blur(5px);
    z-index:500;display:flex;align-items:center;justify-content:center;
    opacity:0;pointer-events:none;transition:opacity .3s}
.ov-bg.vis{opacity:1;pointer-events:all}
.masc-card{background:#fff;border-radius:26px;padding:26px 36px 22px;
    max-width:500px;width:92%;box-shadow:0 26px 70px rgba(0,0,0,.22);text-align:center;
    transform:scale(.84) translateY(20px);transition:transform .38s cubic-bezier(.34,1.56,.64,1)}
.ov-bg.vis .masc-card{transform:scale(1) translateY(0)}
.m-ava-img{width:80px;height:80px;object-fit:contain;margin:0 auto 10px;display:block;
    border-radius:50%;background:#f0f5ff;padding:5px;box-shadow:0 4px 16px rgba(74,134,245,.2)}
.m-ava-img.sm{width:58px;height:58px;padding:3px}
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
<form id="frm" method="post" action="<%= request.getContextPath() %>/escenario4">
    <input type="hidden" name="accion"        id="hdnA" value="">
    <input type="hidden" name="numeroAtomico" id="hdnZ" value="">
</form>

<!-- OVERLAY MASCOTA -->
<div class="ov-bg" id="ovMasc">
  <div class="masc-card">
    <img id="mascImg" src="${pageContext.request.contextPath}/img/amazonatom.png"
         alt="Amazonatom" class="m-ava-img" onerror="this.style.display='none'">
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

<!-- ══ SIMULADOR ══ -->
<div class="sim">

  <!-- TOP BAR -->
  <div class="top">
    <span class="lbl-apz">APRENDIZAJE</span>
    <div class="pill-pct <%= porcentaje>=80?"ok":"" %>"><%= porcentaje %>%</div>
    <div class="prog-track"><div class="prog-fill" style="width:<%= porcentaje %>%"></div></div>
    <span class="titulo">CONFIGURA TU ISÓTOPO</span>
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

  <!-- GRID PRINCIPAL -->
  <div class="body-grid">

    <!-- ═══ COL IZQUIERDA ═══ -->
    <div class="col-left">

      <!-- Carta elemento -->
      <div class="carta-elem">
        <div class="ce-head">
          <div class="ce-nums">
            <span class="ce-mas" id="ceMas"><%= hayElem ? aActual : 0 %></span>
            <span class="ce-z"   id="ceZ"><%= protones %></span>
          </div>
          <span class="ce-sim <%= simSel.isEmpty()?"vacio":"" %>" id="ceSim">
            <%= simSel.isEmpty() ? "?" : simSel %>
          </span>
        </div>
        <span class="ce-nom"><%= nomSel.isEmpty() ? "Selecciona un elemento →" : nomSel %></span>
      </div>

      <!-- Info isótopo -->
      <div class="iso-info">
        <div class="iso-row">
          <span class="iso-lbl">Número de masa</span>
          <span class="iso-val" id="isoA"><%= hayElem ? aActual : "—" %></span>
        </div>
        <div class="iso-row">
          <span class="iso-lbl">Masa atómica</span>
          <span class="iso-val" id="isoMasa"><%= hayElem ? masaStr : "—" %></span>
        </div>
      </div>

      <!-- Conteo partículas -->
      <div class="cont-panel">
        <div class="cont-fila">
          <span class="cont-lbl">Protones</span>
          <div class="dots-a" id="dotsP"></div>
          <strong class="cont-num" style="color:var(--blue)" id="nPLabel"><%= protones %></strong>
        </div>
        <div class="cont-fila">
          <span class="cont-lbl">Neutrones</span>
          <div class="dots-a" id="dotsN"></div>
          <strong class="cont-num" style="color:var(--yellow-d)" id="nNLabel"><%= nAct %></strong>
        </div>
        <div class="cont-fila">
          <span class="cont-lbl">Electrones</span>
          <div class="dots-a" id="dotsE"></div>
          <strong class="cont-num" style="color:var(--pink)" id="nELabel"><%= protones %></strong>
        </div>
      </div>

    </div><!-- /col-left -->

    <!-- ═══ COL CENTRAL ═══ -->
    <div class="col-center">

      <!-- Nombre del isótopo -->
      <div class="iso-nombre <%= hayElem?"activo":"" %>" id="isoNombre">
        <%= hayElem ? nomIsoAct : "← Selecciona un elemento" %>
      </div>

      <!-- BALANZA -->
      <div class="balanza-wrap">
        <div class="bal-brazo" id="balBrazo"></div>
        <div class="bal-fulcro"></div>
        <div class="bal-base"></div>

        <!-- Plato izquierdo: neutrones + controles -->
        <div class="bal-plato izq" id="platoIzq">
          <div class="neutrones-lado">
            <span class="neutrones-etiq">⚛ Neutrones</span>
            <span class="neutrones-count" id="nCount"><%= nAct %></span>
            <div class="neutrones-btn-wrap">
              <button class="btn-np minus" id="btnMenos"
                      <%= !hayElem?"disabled":"" %>
                      onclick="enviar('decrementarNeutrones')">−</button>
              <button class="btn-np plus"  id="btnMas"
                      <%= !hayElem?"disabled":"" %>
                      onclick="enviar('incrementarNeutrones')">+</button>
            </div>
          </div>
          <div class="bal-cuerda"></div>
          <div class="bal-disco"></div>
          <div class="bal-etiq">neutrones</div>
        </div>

        <!-- Plato derecho: núcleo SVG -->
        <div class="bal-plato der" id="platoDer">
          <div class="nucleo-wrap">
            <svg id="nucleoSVG" viewBox="0 0 100 100" width="100" height="80">
              <g id="nucleoG"></g>
            </svg>
          </div>
          <div class="bal-cuerda"></div>
          <div class="bal-disco"></div>
          <div class="bal-etiq">núcleo</div>
        </div>
      </div><!-- /balanza -->

      <!-- Estabilidad y abundancia -->
      <div class="estab-abund" style="width:100%">
        <div class="estab-box <%= hayElem?(estable?"estable":"inestable"):"vacio" %>">
          <div class="estab-lbl">Estabilidad</div>
          <div class="estab-val <%= hayElem?(estable?"estable":"inestable"):"" %>">
            <%= hayElem ? estabAct : "—" %>
          </div>
        </div>
        <div class="abund-box">
          <div class="abund-lbl">Abundancia natural</div>
          <div class="abund-val <%= abundAct > 0 ? "" : "cero" %>">
            <%= abundAct > 0 ? abundStr : (hayElem ? "No registrada" : "—") %>
          </div>
        </div>
      </div>

    </div><!-- /col-center -->

    <!-- ═══ COL DERECHA ═══ -->
    <div class="col-right">

      <!-- Tabla periódica -->
      <div class="tabla-tit">Tabla Periódica — Selecciona el elemento</div>
      <div class="tabla-wrap">
        <div class="tabla-grid">
          <%
            java.util.Map<Integer,ElementoBase> zMap = new java.util.HashMap<>();
            if (elemPeriodica != null) {
                for (ElementoBase e : elemPeriodica) zMap.put(e.getNumeroAtomico(), e);
            }

            // Posiciones en el grid 18×4 (Z=1..36)
            int[] gPos = new int[37];
            gPos[1]=0;  gPos[2]=17;
            gPos[3]=18; gPos[4]=19;
            gPos[5]=30; gPos[6]=31; gPos[7]=32; gPos[8]=33; gPos[9]=34; gPos[10]=35;
            gPos[11]=36; gPos[12]=37;
            gPos[13]=48; gPos[14]=49; gPos[15]=50; gPos[16]=51; gPos[17]=52; gPos[18]=53;
            gPos[19]=54; gPos[20]=55;
            gPos[21]=56; gPos[22]=57; gPos[23]=58; gPos[24]=59; gPos[25]=60;
            gPos[26]=61; gPos[27]=62; gPos[28]=63; gPos[29]=64; gPos[30]=65;
            gPos[31]=66; gPos[32]=67; gPos[33]=68; gPos[34]=69; gPos[35]=70; gPos[36]=71;

            java.util.Map<Integer,Integer> posToZ = new java.util.HashMap<>();
            for (int z2=1;z2<=36;z2++) posToZ.put(gPos[z2],z2);

            java.util.Set<Integer> sBlk    = new java.util.HashSet<>(java.util.Arrays.asList(1,2,3,4,11,12,19,20));
            java.util.Set<Integer> dBlk    = new java.util.HashSet<>(java.util.Arrays.asList(21,22,23,24,25,26,27,28,29,30));
            java.util.Set<Integer> nobleZ  = new java.util.HashSet<>(java.util.Arrays.asList(2,10,18,36));

            for (int cell=0; cell<72; cell++) {
                Integer zCell = posToZ.get(cell);
                if (zCell == null) {
          %>
              <div class="ec vacia"></div>
          <%
                } else {
                    ElementoBase eCell = zMap.get(zCell);
                    String blkCls = nobleZ.contains(zCell) ? "noble"
                                  : sBlk.contains(zCell)   ? "blk-s"
                                  : dBlk.contains(zCell)   ? "blk-d"
                                  :                          "blk-p";
                    String selCls = (zCell == zSel) ? " sel" : "";
                    String simbol = (eCell != null) ? eCell.getSimbolo() : "?";
          %>
              <div class="ec <%= blkCls %><%= selCls %>"
                   title="<%= eCell!=null ? eCell.getNombre() : "Z="+zCell %> (Z=<%= zCell %>)"
                   onclick="selEl(<%= zCell %>)">
                <span class="ec-z"><%= zCell %></span>
                <span class="ec-sim"><%= simbol %></span>
              </div>
          <%
                }
            }
          %>
        </div>
      </div>

      <!-- Carta objetivo -->
      <div class="obj-box <%= hayObjetivo?"":"vacio" %>">
        <% if (hayObjetivo) { %>
        <div class="obj-tit">🎯 Isótopo objetivo</div>
        <div class="obj-iso-nom"><%= nomIsoObj %></div>
        <div class="obj-row">
          <span class="obj-lbl">Elemento</span>
          <span class="obj-val"><%= ebReto!=null ? ebReto.getNombre()+" (Z="+ebReto.getNumeroAtomico()+")" : "—" %></span>
        </div>
        <div class="obj-row">
          <span class="obj-lbl">Neutrones objetivo</span>
          <span class="obj-val"><%= neutronesObjetivo %></span>
        </div>
        <div class="obj-row">
          <span class="obj-lbl">Número másico</span>
          <span class="obj-val"><%= isoObj != null ? isoObj.getNumeroMasico() : "—" %></span>
        </div>
        <% } else { %>
        <div class="obj-placeholder">
          <%= modoEval ? "Generando reto…" : "Inicia la evaluación para ver el isótopo objetivo" %>
        </div>
        <% } %>
      </div>

    </div><!-- /col-right -->

  </div><!-- /body-grid -->

  <!-- BOTONES -->
  <div class="acciones">
    <button class="btn-ac ac-r" onclick="confirmarReiniciar()">REINICIAR</button>
    <button class="btn-ac ac-c" id="btnComp" <%= !modoEval?"disabled":"" %> onclick="enviar('comprobar')">COMPROBAR</button>
    <button class="btn-ac ac-v" onclick="confirmarVolver()">VOLVER</button>
    <button class="btn-ac ac-k" id="btnCont" <%= !habCont?"disabled":"" %> onclick="enviar('continuar')">CONTINUAR</button>
  </div>

</div><!-- /sim -->

<script>
const ST = {
    p:       <%=protones%>,
    n:       <%=nAct%>,
    modoEval:<%=modoEval%>,
    tiempo:  <%=temporizador%>,
    intentos:<%=intentosUsados%>,
    maxInt:  <%=Reto.MAX_INTENTOS%>,
    retoId:  '<%=retoId%>',
    descReto:'<%=descRetoJs%>',
    hayElem: <%=hayElem%>
};

function enviar(a){ document.getElementById('hdnA').value=a; document.getElementById('frm').submit(); }
function selEl(z){
    document.getElementById('hdnA').value='seleccionarElemento';
    document.getElementById('hdnZ').value=z;
    document.getElementById('frm').submit();
}
function confirmarReiniciar(){ if(confirm('¿Reiniciar? Se perderá el progreso.')) enviar('reiniciar'); }
function confirmarVolver()   { if(confirm('¿Volver al menú?')) enviar('volver'); }

/* ── TIMER ── */
let timerSeg=null, timerInvl=null;
function actualizarHUD(s){
    const txt=s>0?s+'s':'¡Tiempo!';
    const h=document.getElementById('hudTimer');
    const m=document.getElementById('modTimer');
    if(h){h.textContent=txt; h.className='hud-t'+(s>20?' ok':'');}
    if(m) m.textContent=txt;
}
function iniciarTimer(segs){
    if(timerInvl) clearInterval(timerInvl);
    timerSeg=segs; actualizarHUD(timerSeg);
    timerInvl=setInterval(()=>{
        timerSeg--;
        sessionStorage.setItem('seaea4_timer',timerSeg);
        actualizarHUD(timerSeg);
        if(timerSeg<=0){
            clearInterval(timerInvl); timerInvl=null;
            sessionStorage.removeItem('seaea4_timer');
            sessionStorage.removeItem('seaea4_retoId');
            setTimeout(()=>enviar('comprobar'),800);
        }
    },1000);
}

/* ── MODAL ── */
function openModal(){
    if(document.getElementById('btnQ').classList.contains('dis')) return;
    const s=sessionStorage.getItem('seaea4_desc_'+ST.retoId);
    if(s) document.getElementById('modDesc').textContent=s;
    document.getElementById('modInt').textContent=ST.intentos;
    document.getElementById('modReto').classList.add('show');
}
function closeModal(){ document.getElementById('modReto').classList.remove('show'); }

/* ── MASCOTA ── */
const GUIA=[
    {t:'¡Bienvenido a Configura tu Isótopo!',
     m:'Hola, soy Amazonatom 🦜\nEn este escenario explorarás los ISÓTOPOS.\n¡Son átomos del mismo elemento con diferente número de neutrones!', btn:'Siguiente →'},
    {t:'¿Qué son los isótopos?',
     m:'⚛️ Los isótopos tienen el mismo Z (protones) pero distinto A (número másico).\n\nEjemplo:\n• Helio-3 → 2 protones, 1 neutrón\n• Helio-4 → 2 protones, 2 neutrones\n\nNomenclatura: Elemento-A → Helio-4', btn:'Siguiente →'},
    {t:'Cómo usar este escenario',
     m:'1️⃣ Selecciona un elemento de la tabla periódica.\n2️⃣ Los protones y electrones se fijan automáticamente al valor Z.\n3️⃣ Solo tú controlas los NEUTRONES con los botones + y −.\n4️⃣ El isótopo, su estabilidad y abundancia se actualizan en tiempo real.', btn:'Siguiente →'},
    {t:'Estabilidad y abundancia',
     m:'🟢 ESTABLE: el núcleo no se desintegra.\n🔴 INESTABLE: el núcleo es radiactivo.\n\n📊 La abundancia isotópica indica el porcentaje en que ese isótopo aparece de forma natural en la Tierra.', btn:'Siguiente →'},
    {t:'¡Listo para evaluarte!',
     m:'🏆 Presiona INICIAR EVALUACIÓN.\nEl sistema te pedirá un isótopo específico.\nSelecciona el elemento correcto y ajusta los neutrones al valor indicado.\nNecesitas ≥ 80% para superar el escenario.', btn:'¡Entendido!'}
];
let paso=0, mGuia='inicial', afterCb=null;
function abrirMasc(modo){ mGuia=modo; renderMasc(); document.getElementById('ovMasc').classList.add('vis'); }
function cerrarMasc(){
    document.getElementById('ovMasc').classList.remove('vis');
    if(afterCb){ const f=afterCb; afterCb=null; f(); }
}
function mascAccion(){
    if(mGuia==='inicial'){ if(paso<GUIA.length-1){ paso++; renderMasc(); } else cerrarMasc(); }
    else cerrarMasc();
}
function renderMasc(){
    document.getElementById('mascImg').className = mGuia==='inicial'?'m-ava-img':'m-ava-img sm';
    document.getElementById('mBadge').style.display='none';
    document.getElementById('mNuevoReto').style.display='none';
    if(mGuia==='inicial'){
        const g=GUIA[paso];
        document.getElementById('mTit').textContent=g.t;
        document.getElementById('mTxt').textContent=g.m;
        document.getElementById('mBtnP').textContent=g.btn;
        const w=document.getElementById('mPasos'); w.innerHTML='';
        GUIA.forEach((_,i)=>{
            const d=document.createElement('div');
            d.className='m-pt'+(i===paso?' act':'');
            w.appendChild(d);
        });
    }
}
function mostrarRetro(titulo, texto, estado, nuevoDesc, cb){
    mGuia='retro'; afterCb=cb||null;
    document.getElementById('mTit').textContent=titulo;
    document.getElementById('mTxt').textContent=texto;
    document.getElementById('mBtnP').textContent='Entendido';
    document.getElementById('mPasos').innerHTML='';
    document.getElementById('mascImg').className='m-ava-img sm';
    const badge=document.getElementById('mBadge');
    if(estado==='ok') { badge.className='badge b-ok';  badge.textContent='✅ ¡Correcto!';        badge.style.display='inline-block'; }
    if(estado==='err'){ badge.className='badge b-err'; badge.textContent='❌ Incorrecto';         badge.style.display='inline-block'; }
    if(estado==='warn'){badge.className='badge b-warn';badge.textContent='⏱ Intentos agotados'; badge.style.display='inline-block'; }
    if(nuevoDesc){
        document.getElementById('mNuevoRetoDesc').textContent=nuevoDesc;
        document.getElementById('mNuevoReto').style.display='block';
    }
    document.getElementById('ovMasc').classList.add('vis');
}

/* ── NÚCLEO SVG ── */
const NS='http://www.w3.org/2000/svg';
const R=6;
function hexLayout(total){
    if(!total) return [];
    const pos=[{x:0,y:0}]; const D=R*2.4; let ring=1;
    while(pos.length<total){
        const cnt=6*ring; const step=(2*Math.PI)/cnt;
        for(let i=0;i<cnt&&pos.length<total;i++){
            const a=step*i;
            pos.push({x:D*ring*Math.cos(a), y:D*ring*Math.sin(a)});
        }
        ring++;
    }
    return pos;
}
function dibujarNucleo(p, n){
    const g=document.getElementById('nucleoG'); g.innerHTML='';
    const total=p+n; if(!total) return;
    const arr=[...Array(p).fill('p'),...Array(n).fill('n')];
    for(let i=arr.length-1;i>0;i--){ const j=Math.floor(Math.random()*(i+1)); [arr[i],arr[j]]=[arr[j],arr[i]]; }
    hexLayout(total).forEach((pos,i)=>{
        const c=document.createElementNS(NS,'circle');
        c.setAttribute('cx', 50+pos.x); c.setAttribute('cy', 40+pos.y); c.setAttribute('r', R);
        c.setAttribute('fill', arr[i]==='p'?'#4a86f5':'#f5c540');
        c.setAttribute('stroke','rgba(0,0,0,.12)'); c.setAttribute('stroke-width','1.5');
        g.appendChild(c);
    });
    // Inclinar balanza según diferencia masa / carga
    const diff=Math.max(-8, Math.min(8, n-p));
    document.getElementById('balBrazo').style.transform=
        `translateX(-50%) rotate(${diff*1.8}deg)`;
}
function renderDots(id, count, cls){
    const el=document.getElementById(id); if(!el) return; el.innerHTML='';
    for(let i=0;i<Math.min(count,15);i++){
        const d=document.createElement('span');
        d.className='dot '+cls;
        el.appendChild(d);
    }
}

/* ── INIT ── */
document.addEventListener('DOMContentLoaded',()=>{
    dibujarNucleo(ST.p, ST.n);
    renderDots('dotsP', ST.p, 'd-p');
    renderDots('dotsN', ST.n, 'd-n');
    renderDots('dotsE', ST.p, 'd-e');

    if(ST.modoEval && ST.retoId){
        const sId=sessionStorage.getItem('seaea4_retoId');
        const sT=parseInt(sessionStorage.getItem('seaea4_timer')||'0');
        if(sId===ST.retoId && sT>0){ iniciarTimer(sT); }
        else{
            sessionStorage.setItem('seaea4_retoId', ST.retoId);
            sessionStorage.setItem('seaea4_timer',  ST.tiempo);
            iniciarTimer(ST.tiempo);
        }
    }
    if(ST.retoId && ST.descReto)
        sessionStorage.setItem('seaea4_desc_'+ST.retoId, ST.descReto);
    if(ST.retoId) document.getElementById('btnQ').classList.remove('dis');

    <% if (tieneResult) { %>
    {
        const ok   = <%=correcto%>;
        const agot = <%=intentosUsados%> >= <%=Reto.MAX_INTENTOS%>;
        const msg  = '<%=msgMascJs%>';
        const nuDesc='<%=nuevoReto ? descRetoJs : ""%>';
        let titulo, estado;
        if(ok)       { titulo='¡Reto superado! 🎉'; estado='ok';   }
        else if(agot){ titulo='Intentos agotados 😔'; estado='warn'; }
        else         { titulo='Intento fallido';      estado='err';  }
        setTimeout(()=>{
            mostrarRetro(titulo, msg, estado, nuDesc||null,
                <%=nuevoReto%> ? ()=>setTimeout(openModal,350) : null);
        }, 300);
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
