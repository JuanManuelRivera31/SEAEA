<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%@ page import="modelo.ElementoBase, modelo.Reto, modelo.Isotopo, java.util.List" %>
<%
    int     porcentaje = request.getAttribute("porcentaje")     != null ? (int)request.getAttribute("porcentaje")     : 0;
    boolean modoEval   = Boolean.TRUE.equals(request.getAttribute("modoEvaluacion"));
    boolean habCont    = Boolean.TRUE.equals(request.getAttribute("habilitarContinuar"));

    ElementoBase ebSel      = (ElementoBase) request.getAttribute("elementoSeleccionado");
    boolean      hayElemento = ebSel != null;
    int    zSel     = request.getAttribute("zSeleccionado") != null ? (int)request.getAttribute("zSeleccionado") : 0;
    int    protones = hayElemento ? ebSel.getNumeroAtomico() : 0;
    String simSel   = hayElemento ? ebSel.getSimbolo()       : "";
    String nomSel   = hayElemento ? ebSel.getNombre()        : "";

    int nAct = request.getAttribute("neutronesActuales") != null ? (int)request.getAttribute("neutronesActuales") : 0;

    String nomIsoAct    = request.getAttribute("nombreIsotopoActual") != null ? (String)request.getAttribute("nombreIsotopoActual")  : "—";
    String estabAct     = request.getAttribute("estabilidadActual")   != null ? (String)request.getAttribute("estabilidadActual")    : "—";
    double abundAct     = request.getAttribute("abundanciaActual")    != null ? (double)request.getAttribute("abundanciaActual")     : 0.0;
    double masaIsoAct   = request.getAttribute("masaIsotopicaActual") != null ? (double)request.getAttribute("masaIsotopicaActual")  : 0.0;
    int    numMasicoAct = request.getAttribute("numeroMasicoActual")  != null ? (int)request.getAttribute("numeroMasicoActual")      : 0;

    Reto   retoActual     = (Reto) request.getAttribute("retoActual");
    String descReto       = request.getAttribute("descripcionReto") != null ? (String)request.getAttribute("descripcionReto") : "";
    int    intentosUsados = request.getAttribute("intentosUsados")  != null ? (int)request.getAttribute("intentosUsados")    : 0;
    int    temporizador   = request.getAttribute("temporizador")    != null ? (int)request.getAttribute("temporizador")      : 90;
    boolean nuevoReto     = Boolean.TRUE.equals(request.getAttribute("nuevoReto"));
    String  retoId        = request.getAttribute("retoId") != null  ? (String)request.getAttribute("retoId")         : "";

    Isotopo      isoObj            = (Isotopo)     request.getAttribute("isotopoObjetivo");
    ElementoBase ebReto            = (ElementoBase)request.getAttribute("ebReto");
    String       nomIsoObj         = request.getAttribute("nomIsotopoObjetivo") != null ? (String)request.getAttribute("nomIsotopoObjetivo") : "";
    int          neutronesObjetivo = request.getAttribute("neutronesObjetivo")  != null ? (int)request.getAttribute("neutronesObjetivo")    : 0;
    boolean      hayObjetivo       = isoObj != null && modoEval;

    String  msgMasc     = request.getAttribute("mensajeMascota")   != null ? (String)request.getAttribute("mensajeMascota") : "";
    Object  rcObj       = request.getAttribute("resultadoCorrecto");
    boolean correcto    = rcObj != null && (boolean)rcObj;
    boolean tieneResult = rcObj != null;
    boolean primeraCarga = !modoEval && !tieneResult && !nuevoReto && request.getAttribute("mensajeMascota") != null;

    @SuppressWarnings("unchecked")
    List<ElementoBase> elemPeriodica = (List<ElementoBase>)request.getAttribute("elementosPeriodica");

    String descRetoJs = descReto.replace("\\","\\\\").replace("'","\\'").replace("\n","\\n").replace("\r","");
    String msgMascJs  = msgMasc.replace("\\","\\\\").replace("`","'").replace("\n","\\n").replace("\r","");

    String abundStr = abundAct > 0 ? String.format("%.4f%%", abundAct) : (hayElemento ? "No registrada" : "—");
    String masaStr  = masaIsoAct > 0 ? String.format("%.5f u", masaIsoAct) : (hayElemento ? String.format("%.5f u",(double)ebSel.getMasaAtomica()) : "—");
    int    aActual  = hayElemento ? (protones + nAct) : 0;
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
    --bg:#dde4f5;--panel:#f4f7ff;--border:#c5d2ec;
    --blue:#4a86f5;--blue-d:#1e56d0;
    --yellow:#f5c540;--yellow-d:#b89000;
    --red:#f46a6a;--red-d:#c43a3a;
    --green:#4ec87a;--green-d:#2a8a4e;
    --proton:#4a86f5;--neutron:#f5c540;--electron:#f470b0;
    --teal:#2ec4b6;--teal-d:#1a8a80;
    --ft:'Baloo 2',cursive;--fb:'Nunito',sans-serif;
}
*,*::before,*::after{box-sizing:border-box;margin:0;padding:0}
body{background:var(--bg);font-family:var(--fb);min-height:100vh;
    display:flex;align-items:flex-start;justify-content:center;padding:10px}

.sim{background:var(--panel);border:3px solid var(--border);border-radius:28px;
    box-shadow:0 8px 32px rgba(40,70,160,.12);width:100%;max-width:1160px;
    padding:14px 22px 18px;display:flex;flex-direction:column;gap:10px}

/* ── TOP BAR ── */
.top{display:flex;align-items:center;gap:10px;flex-wrap:wrap}
.lbl-apz{font-size:11px;font-weight:800;color:#7a8cb0;letter-spacing:.8px;white-space:nowrap}
.pill-pct{background:#fde0e0;border:2.5px solid var(--red);border-radius:22px;
    padding:2px 14px;font-size:19px;font-weight:900;color:var(--red-d);
    min-width:68px;text-align:center;flex-shrink:0}
.pill-pct.ok{background:#d2f5e2;border-color:var(--green);color:#1a6e38}
.prog-track{width:130px;height:11px;background:#dde4f5;border-radius:7px;overflow:hidden;
    border:1.5px solid var(--border);flex-shrink:0}
.prog-fill{height:100%;border-radius:7px;
    background:linear-gradient(90deg,#f46a6a 0%,#f5c540 50%,#4ec87a 100%);transition:width .7s ease}
.titulo{flex:1;text-align:center;font-family:var(--ft);font-size:22px;font-weight:900;
    color:#1a2848;letter-spacing:2px}
.eval-hud{display:flex;align-items:center;gap:8px;background:#fff5f5;
    border:2px solid #fca5a5;border-radius:12px;padding:4px 12px;flex-shrink:0}
.hud-t{font-size:20px;font-weight:900;color:#ef4444;min-width:42px;text-align:center}
.hud-t.ok{color:var(--green-d)}
.hud-sep{width:1px;height:24px;background:#fca5a5}
.hud-i{font-size:11px;font-weight:700;color:#666;white-space:nowrap}
.btn-reto{background:var(--blue);color:#fff;border:none;border-radius:12px;
    padding:8px 16px;font-family:var(--fb);font-size:13px;font-weight:800;
    cursor:pointer;white-space:nowrap;flex-shrink:0;box-shadow:0 4px 0 var(--blue-d);
    transition:filter .15s,transform .1s}
.btn-reto:hover{filter:brightness(1.08)}
.btn-reto:active{transform:translateY(2px)}
.btn-reto.fin{background:#e53e3e;box-shadow:0 4px 0 #a02020}
.btn-q{width:32px;height:32px;background:#fde8e8;border:2.5px solid #f4a0a0;
    border-radius:50%;font-size:15px;font-weight:900;color:var(--red-d);cursor:pointer;
    display:flex;align-items:center;justify-content:center;transition:transform .2s;flex-shrink:0}
.btn-q:hover{transform:scale(1.15)}
.btn-q.dis{opacity:.35;pointer-events:none}

/* ── GRID PRINCIPAL: izquierda | centro | derecha ── */
.body-grid{display:grid;grid-template-columns:260px 1fr 300px;gap:14px;align-items:start}

/* ═══════════════ COL IZQUIERDA ═══════════════ */
.col-left{display:flex;flex-direction:column;gap:10px}

/* Carta elemento */
.carta-elem{background:#edf2ff;border:2.5px solid var(--border);border-radius:18px;
    padding:14px 12px;display:flex;flex-direction:column;align-items:center;gap:6px}
.carta-elem .ce-head{display:flex;align-items:center;gap:10px;width:100%}
.ce-nums{display:flex;flex-direction:column;align-items:center;
    padding-right:10px;border-right:2px solid var(--border);min-width:38px}
.ce-mas,.ce-z{font-size:22px;font-weight:900;color:#1a2848;line-height:1.1}
.ce-sim{font-family:var(--ft);font-size:52px;font-weight:900;color:var(--blue);line-height:1;
    flex:1;text-align:center}
.ce-sim.vacio{color:#b8c8e8}
.ce-nom{font-size:12px;font-weight:700;color:#7a8cb0;text-align:center;width:100%}

/* Panel isótopo info */
.iso-panel{background:#edf2ff;border:2px solid var(--border);border-radius:14px;padding:10px 14px}
.iso-panel-tit{font-family:var(--ft);font-size:18px;font-weight:900;color:var(--blue);
    text-align:center;margin-bottom:8px;letter-spacing:1px}
.iso-row{display:flex;justify-content:space-between;align-items:center;
    padding:4px 0;border-bottom:1px solid #e0e8f8}
.iso-row:last-child{border-bottom:none}
.iso-lbl{font-size:11px;font-weight:800;color:#7a8cb0;text-transform:uppercase;letter-spacing:.4px}
.iso-val{font-size:14px;font-weight:900;color:#1a2848;
    background:#fff;border:1.5px solid var(--border);border-radius:8px;
    padding:2px 12px;min-width:80px;text-align:center}
.iso-val.estable  {background:#d2f5e2;border-color:var(--green);color:#1a6e38}
.iso-val.inestable{background:#fde0e0;border-color:var(--red);color:var(--red-d)}

/* Panel conteo puntos */
.cont-panel{background:#edf2ff;border:2px solid var(--border);border-radius:14px;
    padding:10px 14px;display:flex;flex-direction:column;gap:6px}
.cont-fila{display:flex;align-items:center;gap:8px}
.cont-lbl{font-size:12px;font-weight:700;color:#555;width:72px;flex-shrink:0}
.dots-a{display:flex;flex-wrap:wrap;gap:3px;flex:1;min-height:14px}
.dot{width:12px;height:12px;border-radius:50%;border:1.5px solid rgba(0,0,0,.1);animation:pop .18s ease}
@keyframes pop{from{transform:scale(0)}to{transform:scale(1)}}
.d-p{background:var(--proton)}.d-n{background:var(--neutron)}.d-e{background:var(--electron)}
.cont-num{font-size:14px;font-weight:800;min-width:22px;text-align:right}

/* ═══════════════ COL CENTRAL ═══════════════ */
.col-center{display:flex;flex-direction:column;align-items:center;gap:12px}

/* Nombre isótopo grande */
.iso-nombre-grande{font-family:var(--ft);font-size:32px;font-weight:900;color:#1a2848;
    text-align:center;letter-spacing:3px;
    background:#edf2ff;border:2.5px solid var(--border);border-radius:14px;
    padding:8px 20px;width:100%;transition:all .3s}
.iso-nombre-grande.activo{color:var(--blue);border-color:var(--blue);
    background:#e8f0ff;box-shadow:0 0 0 3px rgba(74,134,245,.15)}

/* Balanza visual */
.balanza-wrap{display:flex;align-items:flex-end;justify-content:center;gap:0;width:100%;position:relative;height:220px}
.balanza-brazo{position:absolute;top:50px;left:50%;transform:translateX(-50%);
    width:260px;height:8px;background:linear-gradient(90deg,#c5d2ec,#8faad8,#c5d2ec);
    border-radius:4px;transform-origin:center center;transition:transform .4s ease;
    box-shadow:0 2px 6px rgba(40,70,160,.2)}
.balanza-fulcro{position:absolute;top:54px;left:50%;transform:translateX(-50%);
    width:16px;height:60px;background:linear-gradient(180deg,#8faad8,#5070b0);
    border-radius:0 0 4px 4px}
.balanza-base{position:absolute;bottom:0;left:50%;transform:translateX(-50%);
    width:100px;height:14px;background:#8faad8;border-radius:7px}
/* Platos */
.plato{position:absolute;bottom:80px;display:flex;flex-direction:column;align-items:center;gap:6px}
.plato-izq{left:20px}
.plato-der{right:20px}
.plato-cuerda{width:2px;height:50px;background:#8faad8;margin:0 auto}
.plato-disco{width:100px;height:14px;background:linear-gradient(180deg,#b0c8f0,#8faad8);
    border-radius:50%;box-shadow:0 3px 8px rgba(40,70,160,.2)}
.plato-etiq{font-size:11px;font-weight:800;color:#7a8cb0;text-transform:uppercase;
    letter-spacing:.5px;margin-top:4px}
/* Núcleo en la balanza */
.nucleo-balanza{width:90px;height:90px;position:relative;margin-bottom:4px}
.nucleo-balanza svg{width:100%;height:100%;overflow:visible}

/* Controles neutrones */
.neutron-ctrl{display:flex;align-items:center;justify-content:center;gap:16px;
    background:#edf2ff;border:2px solid var(--border);border-radius:16px;
    padding:12px 20px;width:100%}
.btn-n{width:52px;height:52px;border-radius:50%;border:none;
    font-size:30px;font-weight:900;color:#fff;cursor:pointer;
    display:flex;align-items:center;justify-content:center;
    transition:transform .12s,box-shadow .12s;user-select:none}
.btn-n.plus {background:var(--green);box-shadow:0 6px 0 var(--green-d)}
.btn-n.minus{background:var(--red);  box-shadow:0 6px 0 var(--red-d)}
.btn-n.plus:active {transform:translateY(3px);box-shadow:0 2px 0 var(--green-d)}
.btn-n.minus:active{transform:translateY(3px);box-shadow:0 2px 0 var(--red-d)}
.btn-n:disabled{opacity:.4;cursor:not-allowed;transform:none}
.neutron-lbl-ctrl{background:var(--neutron);color:#4a3000;border-radius:50px;
    padding:6px 18px;font-size:12px;font-weight:800;white-space:nowrap;
    box-shadow:0 3px 0 var(--yellow-d)}
.neutron-count-big{font-family:var(--ft);font-size:36px;font-weight:900;
    color:#1a2848;min-width:50px;text-align:center}

/* ═══════════════ COL DERECHA ═══════════════ */
.col-right{display:flex;flex-direction:column;gap:10px}

/* Tabla periódica */
.tabla-tit{font-size:11px;font-weight:800;color:#7a8cb0;letter-spacing:.8px;
    text-transform:uppercase;text-align:center;margin-bottom:4px}
.tabla-grid{display:grid;grid-template-columns:repeat(18,1fr);gap:2px}
.ec{aspect-ratio:1;border-radius:4px;border:1.5px solid var(--border);
    background:#edf2ff;cursor:pointer;
    display:flex;flex-direction:column;align-items:center;justify-content:center;
    transition:all .15s;position:relative}
.ec:hover{background:#d0e0ff;border-color:var(--blue);transform:scale(1.18);z-index:2;
    box-shadow:0 2px 8px rgba(74,134,245,.3)}
.ec.sel{background:var(--blue);border-color:var(--blue-d);
    box-shadow:0 0 0 2px rgba(74,134,245,.5)}
.ec.sel .ec-sim,.ec.sel .ec-z{color:#fff}
.ec.vacia{background:transparent;border-color:transparent;cursor:default;pointer-events:none}
.ec-z  {font-size:5.5px;font-weight:800;color:#9aa8c8;line-height:1}
.ec-sim{font-size:8.5px;font-weight:900;color:#1a2848;line-height:1.1}
/* Bloques */
.ec.blk-s {background:#d2f5e2;border-color:#2a8a4e}.ec.blk-s  .ec-sim{color:#1a4a2e}
.ec.blk-p {background:#edf2ff;border-color:#c5d2ec}
.ec.blk-d {background:#fef9e7;border-color:#f5c540}.ec.blk-d  .ec-sim{color:#6a4800}
.ec.blk-f {background:#fde0e0;border-color:var(--red)}.ec.blk-f  .ec-sim{color:var(--red-d)}
.ec.noble {background:#f3e5ff;border-color:#9b5de5}.ec.noble  .ec-sim{color:#5a1a9a}

/* Carta objetivo */
.obj-box{background:#edf2ff;border:2.5px solid var(--teal);border-radius:18px;padding:12px 14px}
.obj-box.vacio{border-style:dashed;border-color:var(--border);background:#f8faff}
.obj-tit{font-size:11px;font-weight:800;color:var(--teal-d);letter-spacing:.5px;
    text-transform:uppercase;text-align:center;margin-bottom:6px}
.obj-iso-nom{font-family:var(--ft);font-size:20px;font-weight:900;color:#1a2848;text-align:center;margin-bottom:6px}
.obj-row{display:flex;justify-content:space-between;align-items:center;
    background:#fff;border-radius:8px;padding:3px 10px;margin-bottom:4px}
.obj-row:last-child{margin-bottom:0}
.obj-lbl{font-size:10px;font-weight:800;color:#7a8cb0;text-transform:uppercase}
.obj-val{font-size:12px;font-weight:900;color:#1a2848}
.obj-placeholder{text-align:center;padding:14px;color:#aab8d0;font-size:12px;font-weight:700}

/* Abundancia */
.abund-box{background:linear-gradient(135deg,#f0f5ff,#e8f5ee);
    border:2px solid var(--border);border-radius:14px;padding:12px 16px;text-align:center}
.abund-lbl{font-size:11px;font-weight:800;color:#7a8cb0;
    letter-spacing:.5px;text-transform:uppercase;margin-bottom:4px}
.abund-val{font-size:26px;font-weight:900;color:var(--green-d);font-family:var(--ft)}
.abund-val.cero{color:#aab8d0;font-size:16px}

/* ── BOTONES ── */
.acciones{display:flex;justify-content:center;gap:12px;margin-top:2px;flex-wrap:wrap}
.btn-ac{padding:11px 26px;border-radius:14px;border:none;font-family:var(--fb);
    font-size:14px;font-weight:800;cursor:pointer;letter-spacing:.4px;
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
.masc-card{background:#fff;border-radius:26px;padding:26px 36px 22px;
    max-width:500px;width:92%;box-shadow:0 26px 70px rgba(0,0,0,.22);text-align:center;
    transform:scale(.84) translateY(20px);
    transition:transform .38s cubic-bezier(.34,1.56,.64,1)}
.ov-bg.vis .masc-card{transform:scale(1) translateY(0)}
.m-ava-img{width:90px;height:90px;object-fit:contain;margin:0 auto 10px;display:block;
    border-radius:50%;background:#fff8e1;padding:6px;box-shadow:0 4px 16px rgba(74,134,245,.15)}
.m-ava-img.sm{width:64px;height:64px;padding:4px}
.m-tit{font-family:var(--ft);font-size:20px;font-weight:800;color:#1a2848;margin-bottom:10px}
.m-pasos{display:flex;justify-content:center;gap:7px;margin-bottom:14px}
.m-pt{width:8px;height:8px;border-radius:50%;background:var(--border);transition:background .3s,transform .3s}
.m-pt.act{background:var(--blue);transform:scale(1.4)}
.badge{display:inline-block;padding:4px 16px;border-radius:20px;font-size:13px;font-weight:800;margin-bottom:10px}
.b-ok{background:#d2f5e2;color:#1a6e38}.b-err{background:#fde0e0;color:var(--red-d)}.b-warn{background:#fef3cd;color:#856404}
.m-txt{font-size:14px;color:#444;line-height:1.7;margin-bottom:16px;white-space:pre-line}
.nuevo-reto-box{background:#f0f5ff;border:2px solid var(--border);border-radius:14px;
    padding:12px 16px;margin-bottom:16px;text-align:left}
.nuevo-reto-box .nr-tit{font-size:11px;font-weight:800;color:#7a8cb0;margin-bottom:5px;letter-spacing:.5px;text-transform:uppercase}
.nuevo-reto-box .nr-desc{font-size:13px;font-weight:600;color:#1a2848;line-height:1.5}
.m-btns{display:flex;gap:10px;justify-content:center}
.m-btn{padding:10px 28px;border-radius:12px;border:none;font-family:var(--fb);font-size:14px;font-weight:800;cursor:pointer;transition:filter .15s,transform .1s}
.m-btn:active{transform:translateY(2px)}
.mb-p{background:var(--blue);color:#fff;box-shadow:0 4px 0 var(--blue-d)}
.mb-p:hover{filter:brightness(1.08)}

/* Modal reto */
.mod-ov{position:fixed;inset:0;background:rgba(15,25,60,.45);backdrop-filter:blur(4px);
    z-index:400;display:flex;align-items:center;justify-content:center;
    opacity:0;pointer-events:none;transition:opacity .28s}
.mod-ov.show{opacity:1;pointer-events:all}
.mod-card{background:#fff;border-radius:22px;padding:28px 32px;max-width:460px;width:92%;
    box-shadow:0 20px 60px rgba(0,0,0,.2);transform:scale(.88);
    transition:transform .32s cubic-bezier(.34,1.56,.64,1);position:relative}
.mod-ov.show .mod-card{transform:scale(1)}
.mod-tit{font-family:var(--ft);font-size:19px;font-weight:800;color:#1a2848;margin-bottom:8px}
.mod-desc{font-size:14px;color:#444;line-height:1.6;margin-bottom:14px}
.mod-meta{display:flex;gap:12px;margin-bottom:16px}
.meta-ch{background:#edf2ff;border:2px solid var(--border);border-radius:10px;
    padding:5px 12px;font-size:12px;font-weight:700;color:var(--blue-d)}
.mod-x{position:absolute;top:12px;right:14px;background:none;border:none;font-size:18px;cursor:pointer;color:#bbb}
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
    <img id="mascImg" src="data:image/png;base64,/9j/4AAQSkZJRgABAQAAAQABAAD/4gHYSUNDX1BST0ZJTEUAAQEAAAHIAAAAAAQwAABtbnRyUkdCIFhZWiAH4AABAAEAAAAAAABhY3NwAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAQAA9tYAAQAAAADTLQAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAlkZXNjAAAA8AAAACRyWFlaAAABFAAAABRnWFlaAAABKAAAABRiWFlaAAABPAAAABR3dHB0AAABUAAAABRyVFJDAAABZAAAAChnVFJDAAABZAAAAChiVFJDAAABZAAAAChjcHJ0AAABjAAAADxtbHVjAAAAAAAAAAEAAAAMZW5VUwAAAAgAAAAcAHMAUgBHAEJYWVogAAAAAAAAb6IAADj1AAADkFhZWiAAAAAAAABimQAAt4UAABjaWFlaIAAAAAAAACSgAAAPhAAAts9YWVogAAAAAAAA9tYAAQAAAADTLXBhcmEAAAAAAAQAAAACZmYAAPKnAAANWQAAE9AAAApbAAAAAAAAAABtbHVjAAAAAAAAAAEAAAAMZW5VUwAAACAAAAAcAEcAbwBvAGcAbABlACAASQBuAGMALgAgADIAMAAxADb/2wBDAAUDBAQEAwUEBAQFBQUGBwwIBwcHBw8LCwkMEQ8SEhEPERETFhwXExQaFRERGCEYGh0dHx8fExciJCIeJBweHx7/2wBDAQUFBQcGBw4ICA4eFBEUHh4eHh4eHh4eHh4eHh4eHh4eHh4eHh4eHh4eHh4eHh4eHh4eHh4eHh4eHh4eHh4eHh7/wAARCADIAMgDASIAAhEBAxEB/8QAHAABAAEFAQEAAAAAAAAAAAAAAAUCAwQGBwEI/8QAShAAAQMCBAMEBgcGBAQHAAAAAQACAwQRBRIhMUETUWEGInGBFDKRobHB0fAHFSNCUmJyFiQzQ4LhU2NkkvElNDVEc3SissL/xAAaAQEAAgMBAAAAAAAAAAAAAAAAAwQBAgUG/8QAKREAAgIBBAEDBAMBAAAAAAAAAAECAxEEEiExBRNBUWEiMnGB8BT/2gAMAwEAAhEDEQA/APqpERAEREAREQBERAEREAREQBERAEREAREQBERAEREAREQBERAEREAREQBERAEREAREQBERAEREAREQBERAEREAREQBERAEREAREQBERAEREAREQBERAEREAREQBERAEREAREQBERAEREAREQBERAEREAREQBERAEREAREQBERAEREAREQBERAEREAREQBERAEREAREQBERAEREAREQBERAEREAREQBERAEREAREQBERAEREAREQBERAFrniTXRrDuqhkqaqKnjGaWZwY0dSVWv5t8OsLPOT4BOT+l/JTqJbsNuFpGtKr2r9i0TU7ipJGGSR+VoHMnZcv4jcWpqxkmH4S8x05ujnnH60jk5v8Ac5z6+S5vT8OcYxOUPxCqfMwH9nBmij9kbufXUqWjw6jgcHNgjJHMsa4/W2c+VZIqK5+P8HFqeNxp6YQfHaZJIAoqp7KWJ7Yxv2kp+HO3M5dfVqsy4G1jq3BiJ+bZHEfu5QWD22b7FRj8MiEYj2bGM+VrbD0VmxiPsaKMAfMIy36LljvzL+3+FBXOX3R1zDa9tfSQzjZ7TZzdvZQTVVxLBf4BuG8yDjc2Ng9v8+yrIKOVzW79QN1lqFNFNTNnhBc5+t+gUFyqfAqiVsXHsrY3tBDmPc3/CVzPhVxPnw6oFLUuLqR7stieYP6y/XHkNNvC9JVXpqaWrfSOc5kcxIDz09OqsOEgumY5r8pAIVUJ6Vxla+7VBbA8lpcJGWJHXTZTVHFRRQPmme1jGi5JK5tSy4uK0OYKOte2V9Q0Z3xbWPLXVd6LaxVKHqF8HN+Hfig/H6gQzuEdXGy8jAbCQDm9p7tFmqvxetiyiKjnka4fFWtLQ64JBBG4OxB9FJ4rG5xa5hbp1Ubh9O6SdxbICbaELi1GpNybV+MYtP8AXcnieMfAtLcqkZIJIiMwJaQd7+HJZsKnbPAx7Dex9V1pRsqpW5HxZnMcLOYXA2dfn5fkuv8A4TcWqcKxCSjqJHmkqiGub8rJOjh9fFawq1Sl7kbzFG7Fc+I9EREAREQBERAEREAREQBERAFhcSlMVHO8HItjcb92VmrRxL+La37J6FVqfEPRLYrnhlzpW1dHUsmheDZ7DoQRyI5EdVYPCzi1Jh+ITGeqfRsqGtaajIX9m23xOA5m19OqxayvVZRxmjpJaecHIXFwMbge5Gw9/JdEowFWqZwJo7i33LfQLUXnHCLzLi5xyb9m5+I17aSmE8kEFNrK5uRjRo1oG56fzuVzKv4rU9NKKCilqX3sfgxjQ75juR/PkpPHaM1lbHExjGtgzSODXgtjFiM0hHLQNb6/Svky4FVVeLywYY6WkEjn3khZq53MBZE07kb6m26uaaSiuXwZFKtUlxF8I2VXFKulqnNioIBJE2YhrpZXAuLXXGwsLWC59QYtiULqWAVkklS9wsHOY18tieUbDYaA6kk9Vt0FBFQ0kNJEXmOMWBO7vM+pW0cNoa6KGN1RxVbUwS0DqmXJLVRFr7ufG0ixaT/wDOiqJabjy8i4JadWf2fZxNVxVlDHTzNiZMyRkrWvYXMJB5EEWI5HIpq1VTcI2OmqHuDKSKomhIYwRSS5s1hKzQXJIG5UlJRU5ma+KYyMjqJAA8kntXh4vq7Ni09rJvCMoqhkfxJX27RkDiASAcoIIAHMW/kK0LpMVyMv25VzqrMb5N7WF1scbgfNv8msFRNT0tRl7Q1bwGPsJHDaztB08b38Fmkp59ppXktijbq+ViGs11v4KSlhqKmjhlhnjlZFG5rmPaGv0ds7bTuUkVe+u1ub/AHBL3vGV0jBJbYnWwJ8Nez7lXIKmKnzSCJxGUxuy5rbMvmtyBI68tdVWiq5Z/wBpFG3cSHUHl4fT6LBXRNnbK9lS4k2a8GUAlwvsbHW1j69SpIXPaS6R2Y/CwDTxKpU8xNLJIwy2ALi2MHMSb2bfpbmfBdIoXQz0MckzHRzPYHOY8atcRqD5LFdv2JJqXLJF75XGOHLo2ME3I36cpVuGKORs5lfGHxPeWh0YFnGx3PPmPQLlJUupqyKCyN4kH+ZWiG+V7WqFJJJO5oeCxsJIIDhbXvPgT+gXFqOJU+FO7ZVFVsS2JREJCCP+7mPJSK53w1x19HjTKd7smSqaYpI+mYdW+12vXcLoi1F8nXrq9OrTU1z3CIiuLYEREAREQBERAEREAREQBWpxH+KavvfoVdlqjiL8U1fe/QqtT4l6JbFdFSxaKFmWW7QNQCdAV3g2sLqLiYA3M1xvY7+/3K2VjB6KKoLYmyMF84Gaw6noeir5xjEr3SfZKqDFqalqJ6aBrgHAEyNa0B5DtAdSBsdM23rsvAo3OwmqNXI6J9XIfgi2yxhjGgBw0cTfW2guvPFb20raaF7BGTOX5Wyua0ADYhu2vVVjKmWYloqJhrmjD/E32rg+lqJ+zxZ7YQ5lJCI3nKFVhqGfETv4LFPb3Lq3dPv2Xp8E1c1VQU9RJDFBJIwOdHEbxg9bctFhFiZKkZqwGTLO3fTsubaOYPiAfW3RXzNFhFUVHxEFVlJz7nzXH3F3wJGucwNbrZo0Gy5/SzyzVEsknxTiXQh2sZGh01Nmjz0CsZI62XEqh1dUurJJIWfHJEx7SCACALXY0bW1sNFYpZI3Ump7PK1pjcCbWe0HUHpZdXFVSwupVrKS8OFmaaLVFUP7R1O5rjLKSQDlIDho0bbbHbkr1LJDM+eWqnkLchYyQtyNGXkBYLpWCGkD6xzXOcGW7Xc8rg7Lk1IXSVLQ6Zr5Xm7mOzNJGl7N0NjbRjB4A7qKpJtN4KVShKHCxhZi7JUNmpVmhkPbzECPLbMN8uovyvbn6Kmi7M0dCZZXNaWOJuALuOUAn2LG8BzmPa8CwIOhJI31BsdeSmB9vR5szWRf6jXauHS4On7rkX6aSrJ07kfEqkmIppA9oa05nlugBN9CSdgDpfquePmGR3wYZG0tPivE4H21trbfW2i55hVKuaoCmGT5YLAYGjuSTqCPM66bqRQ3e7OALxG4DLkAPOTl2IJHPQ6DkFkbNXl9+SbpxkrS7jqjfXJGw7hxLiNobnvbLY7f75LlaB8stXT0lPPFFJa7JJy/I0cz09yt6VxkaxhqGue5ri8h7zk11JIJF7WB2PeFR8rqQZi3KXWbEQ2PNlfbkAbn0G2/grG7ckWp8o6z7rrZ+yq+9+hV2WqeIPxXV3+7+hV2C6TpFz1vFFhw7bLwcVsXA7qVD3N1TMIIJ8VuKIgCIiAIiIAiIgCIiAIiIAiIgNE8Q6Ny43XNNLGQ0SZi1zhYOB3A8bLY1hfP4KDiJGGV0cgBa4am17HW3huPXqs+NVyvkr9Kl2M+pu7SbFxG2UpJdqWPJvY35aae5d+iqKp0YdWMjgLiS0gC51+cLm3PVanNVxMjGaV55fLfYcgvNVVzqipipcjXPeDlJ2JHMnyAH0XVU6RvCFtx6s1Bkjdh9E+SQGIvc19mAnKT46W5rPiU01RVOilqXNjc4RhsYLSHHlq8C+g+mvReZqRr3vbvG4kFxH3nEkgX89PEHkVkdEGCQy5i8yatbrfwFxr4Ws9r6rRhBzW6XL7+FuRW2nJU4SbTb2dNw6hbFURTUzobAAOijdGMrRqSC3W4vrqN+a9tDFHJNMJspeZS6IRNkAbobHNGMuvK5ub7Lk2FVNRQ4hSSNpczM7XGJ5LGiNwJJHLfQeXit84VtqM9S2qqYXSN+KyN2WS9rlt+h00vm26q1tWuXwqhKXYLDFBG6Z7Y3PDgLF59g04vbry8Vj7MsgkfJHT5LDIXOAOlz5EeQG6qnEKV9fVvraWIzNc5kYAfG1p8XW62A2/Rlsp/h7i0GIw2pZ26gOi1JA8bqijDVW7KHpBl7O2VrXkDN0sRzB1BsVieJHMvlMb2te0EjqHE7EjkAfZbiXYv4nAFjGtLnW7QBxO3cbW8uqqsFW4PbDIyOORgLiXCwa7TQnpe9h4BWXQy1KSnF+HNi3LjdopJJHtaJJY2NeXPJaw21F9LC9/LfnV37NQl0UUj6h8kjGD43M5G+7bnU+3RUH00Ic+Ixt7Zt7tka4gkaXsbWPLpZfDi17KiWR4dlLG5WhrGggg+AGoF9v5yrU5OP7v8Akt1KFRzW6LwyrpH0k5D4xLYgvvmPKxvbXl+Cp1nxzKlwJiAcQHRkFziBuO9r+vTlbXU7A9jQCXPfpcBtwQSCRz+7kvU1JFIGuhIL2PGYMLhYN59DcXHoeVlY1FxT+JzwsSjJ/SzBFI+3xMMRlhY25DTtpfXvWW2VkM9QHAOaH3Y1suUOINrk5tTt1AO6x0gn7KrZllY8vlB+Kz7MIJ0v7jdeW1MUzSGSF0bgS1x5F3I6WFxex5HYpxjUJT5it82pzU3xLWt1cAIiDppudyDrzA9bqhk1Dqh9xHJkDHPLmyMLi52u41Gv38lcpJoW1VNIGayzPJeAdBbW47xa2mv7lSaqZ9LDKGvgZ8oaxmfLzPwhs47a31C6TRNKV59+/fHYmVGUo4YR2zjdRVtNEIfh6aSEiNwbZ4J0Gmutx+6qMUElLgMcFQ+OVwqRNG9mbLmsW7OZfmR9Vur1UlJhjIEIlluTfJmBOoAHK1rcz0Ox5rXYLnYAYWvkyBrQb5bkbgeRXl8dWh6iNO2HtfJV5YkjCJZbX0LS7yPMLotcrQQCIiAIiIAiIgCIiAIiIAiIgCIiAKk4i/FNX3v0Ku6oOIvxTV979CqtTi9Et4quimjTN/OwZDlN7E6X5b8lkzXabKK01nNmkcZHEWAsS4nzPT/AEWsMqNM7qkEFt7HofdXJQzN/hfCRpvbW3XQ/wCiqlFK3oRt7s34rKJYWiVjstjza7Y7mwBaFtNVJFPBURFmcMIBIuLt10cLi26ztoGsexzJWtja9xdGXi+Tpv5rFT6SsBIm01JA3BYFSqaZe6tQ0rY6hzJmOa8kjKMwNiLEHrr6BYMLi6ojYGXz2c2N3wjXWw1N9OmvRZHvqamNzoYYGDKRlzPcbi21tPJZMJdVxMkbLSCUvdcPjflLdLa3B1+7VVVCq4bJNVrdlE/DFPTVdPA2B0cjC6MNdnZIb84Ghu3bfzVOqw6cswekigipmua3LIXuDjub6H/SoMCMtXiJhpmz1MhLTHCGkMc5zcxLeRI111W6VHDDtXNqqmpFY1jBFT0oGVgsBqSBzIzXO2msH2vNkpVHZRhNM3DsEmrZqaaXtO0c17WxPjfGGgjMHEuv3bW0I/Moa3C8No8UpSaF7wXDLNC9jJQeYaTe9vMkLfEzqpuHRtkikjgYS2SXKXNHQ2abO7t9xf0XMGxiGvDGPlha4PJAcQHDTcFRrPVWuXuX9L9fq0xY6yoqs9DRSwMlnLWCOR80kgkDb/ETsNL6g6X5HnfYCBqJZ5HuikIfmDhcFxGlz35a+R1XE8bqpaeiaykp4JhJD2TmlzS0vj1zMIOxFiSN75SeWvYKXEDiUFCZHVkE1VTMaIqaYiOPUHQ6HS/PW50vpZFGqo1cVtzPLc7x4+1x3HJ49M7cVqcJhEuFzVBfBKYxHHmLmk6b+EllW8h8WnZHEIpHPDYnPvmN2m9wDcgi+t+u3JY4aU01TBLG2Rxikvme7RjbgW0Gw0+iqXRtpaueRlVK+oiBkfq5wa4gDY+F/UX6qqm6kvEZrPiXtcW8oN+VJVynspvK+eLkPKQ3JNgS7TuNr6AjmFWfK+EEkBzHBoGnTKQHe4Bl8t/VdIquXJGSSVCCpzNEEkBhe2IJe4OdI3KDfYZyNtLnbZZ4H0wpXxyEu0jLZS3LkDQQTa58bFWIw6SNsYkLjHbKC0EtGp0vbQc7crLFV1Ude5rCWiRgMgLhYt10OWxHLn5qeXLNv5cArlOm0l97UtQMfM6UiJjdGNbGGEA6AkHl/pWTLVeKmDi7SJrHMsGBzS0khuocdQTbfkT4LJC0GYSFzAyMMjcx4LnBoF9vLXY+K+wyNgL3ENFwGODySW3sLk+ehA7ltWoxW+/mOBOpHJ2/XivLPjqHyNLXBrdCHC4vbQtvzvy10W+qoMJlqY62SmhrZHxNDI6pjXnLr3bbrO4IH4bqpkqnTs7OaolqSHMdHYkZiTrr4Zf0CpU44W+fAlprCwNaGOYMmgjbqLm+vUj9lRqHsNHVh73NcWWa6Ml1s23Jvse9TMsVOzLGWt5BgDQ5ze82GUW/9dApCF7pWNmDIy0lhc43LTrtfUjQaX3V5aS0UPPJtnY6blK6O2dCIiCIiAIiIAiIgCIiAIiIAiIgCIiAKg4i/FNX3v0K6mCrqH0NZFVR6vjdcX5Hkf5qs5VKnLEXuiOdCNSLhJXT3RXE0ZlY5m55C3KRqdwrjGvWGKlFYVuUOdpuBra3IdFjjJq6mSmYRDEDczOpJtsOQ5W8iquL/B3GZapXJqMkscbWyguLiSLFovc9brnuJ4jLJIaOBrY2MHaOcPmDRqSfDT68lgbj0VyWqWNkQklMrM19jy0Ni5e4Ac7LDi+JT3FLSwmKIaOAGUPHID7T1PksbJvGi73OPiDcYTiVFU1YqKl7oZJGRtcJJAAdwTpz+9b3ZVGl7CYVrQ1jHhwDiXggXI1A5bLk1TMx9E+0zS+NtmWsRuSbXPLc+C2hwxiqPjpJXPIBLGy3b/2tbLKUFKTi9tvr3LmoqXmTGmYWNjFm9b77E+9Y44IGCaRkzVbIyCJHFzBmF7W3PUagb9feqeGJlKwgvMjnAaS7tHqf4VFr2FttmPaNrON9fqrqMcSUW/VJJW1BZFbSRrs5y31F/v1spYJmBmVh0DgDrzbpfl+fNdVjbSmONm5BFhrqz2IVVtJFTxUscmXO42LbAfN1JHW+v1Cuqp0Fxu7OaU8bmO+1yRtJkJLWkh1hlyXNvFVaSWGOJuXM8sDCy5Y/MQdRuLH8K4RR1Ec7RJzJf2g0yHKTsPAEeKztLwYQHgCxaHZjfpqfqPqs9Kbls5VW0q4eMlUB9JKDJm1BG2mT6rJ2FPFLExrzHMJWlzXC72gbhw33K+Y6z2OTMbGxc13TayxGnMKO6aeGNpmhzNLy65k2JHU+IGly4ZbJqeUytRIqKvgJxKZlbNhlm5Y42F0cRe4gtYXCwBvzIFrq/HW4dLJWFkT5Wua6KBoa82AIH9x9Nfr0VpzaeqdKJ5TA+PJJGxoIAIIBHd6KGWvYwCLNLG5j28jcnTe1rX9vALEqkZqUd9LHPjHbHJBp2xucPq7TXV2VwBJOguLb2XM28OIxuhlfXVErIHFsiWZXOJBH+9h13/UKSmrNbIxGZ2h52bYHcaHXoRfmoaioD3tLyJGFvN4c1wHO3LdanKilKnW6bJlKjFRWPiCOJkT3FjSwStyuIG3MX6feqtHM2lZJAXuJhf2VruDSS3Q3FufkFWhc0ZAJPtBzg22TKTvsb2NlT7XspBHmjmEjJWlpdc5m9e7fQbHkFpvD4w9ryWMj1JfYEi45b87kW94VN8ZHKScV3R7b4YHjRmSNjbvFjZh10Gw2G+vPTdUavEjTUzxHHJSyvLgBFCXxMGttBpYEX8x4LXz6l4liLmOe8B73HK24JvfT35EKOCdlTFEIop3tZG8NAbZzS4BzQ7XUWBFzfbT9VFVJHHJxe3sJlCm0pJYbLXGVsMjD8QaO8fQ8luVJhNRHVQF9RI2Bz7uzlxjDuWpvl/RjwXTMPooQ6mkqn1NRLE0mIuflADhmPQ3P3jkuXcKMOxFnD+nrZZnyUbpXPeXuBaJSdG3PLNl6eFu9dMsPLEJb3M9NSh62qb/lH6DIiKlXiIiAIiIAiIgCIiAIiIAiIgCIiAIiIAiIgCIiAIiIAiIgCIiAIiIAiIgCIiAIiIAiIgCIiAIiIAiIgCIiAIiIAiIgCIiAIiIAiIgCIiAIiIAiIgCIiAIiIAiIgCIiAIiIAiIgCIiAIiIAiIgCIiAIiIAiIgCIiAIiIAiIgCIiAIiIAiIgCIiAIiIAiIgCIiAIiIAiIgCIiAIiIAiIgCIiAIiIAiIgCIiAIiIAiIgCIiAIiIAiIgCIiAIiIAiIgCIiAIiIAiIgCIiAIiIAiIgCIiAIiIAiIgCIiAIiIAiIgCIiAIiIAiIgCIiAIiIAiIgCIiAIiIAiIgCIiAIiIAiIgCIiAIiIAiIgCIiAIiIAiIgCIiAIiIAiIgCIiAIiIAiIgCIiAIiIAiIgCIiAIiIAiIgCIiAIiIAiIgCIiAIiIAiIgCIiAIiIAiIgCIiAIiIAiIgCIiAIiIAiIgCIiAIiIAiIgCIiAIiIAiIgCIiAIiIAiIgCIiAIiIAiIgCIiAIiIAiIgCIiAIiIAiIgCIiAIiIAiIgCIiAIiIAiIgCIiAIiIAiIgCIiAIiIAiIgCIiAIiIAiIgCIiAIiIAiIgCIiAIiIAiIgCIiAIiIAiIgCIiAIiIAiIgCIiAIiIAiIgCIiAIiIAiIgCIiAIiIAiIgCIiAIiIAiIgCIiAIiIAiIgCIiAIiIAiIgCIiAIiIAiIgCIiAIiIAiIgCIiAIiIAiIgCIiAIiIAiIgCIiAIiIAiIgCIiAIiIAiIgCIiAIiIAiIgCIiAIiIAiIgCIiAIiIAiIgCIiAIiIAiIgCIiAIiIAiIgCIiAIiID/2Q==" alt="mascota" class="m-ava-img">
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
    <button class="btn-ac ac-c" style="width:100%;border-radius:12px" onclick="closeModal();enviar('comprobar')">✓ Comprobar ahora</button>
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
            <span class="ce-mas" id="ceMas"><%= hayElemento ? aActual : 0 %></span>
            <span class="ce-z"   id="ceZ"><%= protones %></span>
          </div>
          <span class="ce-sim <%= simSel.isEmpty()?"vacio":"" %>" id="ceSim"><%= simSel.isEmpty()?"?":simSel %></span>
        </div>
        <span class="ce-nom" id="ceNom"><%= nomSel.isEmpty() ? "Selecciona un elemento →" : nomSel %></span>
      </div>

      <!-- Info isótopo -->
      <div class="iso-panel">
        <div class="iso-panel-tit" id="isoNombrePan"><%= hayElemento ? nomIsoAct : "— Isótopo —" %></div>
        <div class="iso-row">
          <span class="iso-lbl">Número de masa</span>
          <span class="iso-val" id="isoA"><%= hayElemento ? aActual : "—" %></span>
        </div>
        <div class="iso-row">
          <span class="iso-lbl">Masa atómica</span>
          <span class="iso-val" id="isoMasa"><%= hayElemento ? masaStr : "—" %></span>
        </div>
        <div class="iso-row">
          <span class="iso-lbl">Estabilidad</span>
          <span class="iso-val <%= hayElemento?(estabAct.equals("ESTABLE")?"estable":"inestable"):"" %>" id="isoEstab">
            <%= hayElemento ? estabAct : "—" %>
          </span>
        </div>
      </div>

      <!-- Conteo partículas -->
      <div class="cont-panel">
        <div class="cont-fila">
          <span class="cont-lbl">Protones</span>
          <div class="dots-a" id="dotsP"></div>
          <strong class="cont-num" style="color:var(--proton)"   id="nP"><%= protones %></strong>
        </div>
        <div class="cont-fila">
          <span class="cont-lbl">Neutrones</span>
          <div class="dots-a" id="dotsN"></div>
          <strong class="cont-num" style="color:var(--yellow-d)" id="nN"><%= nAct %></strong>
        </div>
        <div class="cont-fila">
          <span class="cont-lbl">Electrones</span>
          <div class="dots-a" id="dotsE"></div>
          <strong class="cont-num" style="color:var(--electron)" id="nE"><%= protones %></strong>
        </div>
      </div>

    </div><!-- /col-left -->

    <!-- ═══ COL CENTRAL ═══ -->
    <div class="col-center">

      <!-- Nombre isótopo grande -->
      <div class="iso-nombre-grande <%= hayElemento?"activo":"" %>" id="isoNomGrande">
        <%= hayElemento ? nomIsoAct : "← Selecciona un elemento" %>
      </div>

      <!-- BALANZA VISUAL -->
      <div class="balanza-wrap" id="balanzaWrap">
        <!-- Brazo de la balanza (se inclina según diferencia) -->
        <div class="balanza-brazo" id="balanzaBrazo"></div>
        <!-- Fulcro -->
        <div class="balanza-fulcro"></div>
        <!-- Base -->
        <div class="balanza-base"></div>

        <!-- Plato izquierdo: núcleo SVG -->
        <div class="plato plato-izq" id="platoIzq">
          <div class="nucleo-balanza">
            <svg id="nucleoSVG" viewBox="0 0 90 90"><g id="nucleoG"></g></svg>
          </div>
          <div class="plato-cuerda"></div>
          <div class="plato-disco"></div>
          <div class="plato-etiq">núcleo</div>
        </div>

        <!-- Plato derecho: electrones -->
        <div class="plato plato-der" id="platoDer">
          <div style="width:90px;height:90px;display:flex;align-items:center;justify-content:center;">
            <svg id="electronSVG" viewBox="0 0 90 90" width="90" height="90"><g id="electronG"></g></svg>
          </div>
          <div class="plato-cuerda"></div>
          <div class="plato-disco"></div>
          <div class="plato-etiq">electrones</div>
        </div>
      </div><!-- /balanza -->

      <!-- Abundancia debajo de balanza -->
      <div class="abund-box" style="width:100%">
        <div class="abund-lbl">Abundancia en la naturaleza</div>
        <div class="abund-val <%= abundAct > 0 ? "" : "cero" %>" id="abundVal">
          <%= abundAct > 0 ? abundStr : (hayElemento ? "No registrada" : "—") %>
        </div>
      </div>

      <!-- Controles neutrones -->
      <div class="neutron-ctrl">
        <button class="btn-n minus" id="btnMenos" <%= !hayElemento?"disabled":"" %> onclick="enviar('decrementarNeutrones')">−</button>
        <div class="neutron-lbl-ctrl">⚛ Neutrones</div>
        <span class="neutron-count-big" id="nCount"><%= nAct %></span>
        <button class="btn-n plus"  id="btnMas"   <%= !hayElemento?"disabled":"" %> onclick="enviar('incrementarNeutrones')">+</button>
      </div>

    </div><!-- /col-center -->

    <!-- ═══ COL DERECHA ═══ -->
    <div class="col-right">

      <!-- Tabla periódica expandida (Z 1-36) -->
      <div class="tabla-tit">Tabla Periódica — Selecciona el elemento</div>
      <div class="tabla-grid">
        <%
          // Grid 18 cols × 4 filas completo con bloques s, p, d
          // Posiciones: valor = posición en grid (1-based, fila*18+col)
          java.util.Map<Integer,ElementoBase> zMap = new java.util.HashMap<>();
          if (elemPeriodica != null) {
              for (ElementoBase e : elemPeriodica) zMap.put(e.getNumeroAtomico(), e);
          }
          // pos[z] = celda en grid (0-based index en array de 72 = 4 filas × 18 cols)
          int[] gridPos = new int[37]; // índice = Z
          gridPos[1]=0; gridPos[2]=17;
          gridPos[3]=18; gridPos[4]=19;
          gridPos[5]=30; gridPos[6]=31; gridPos[7]=32; gridPos[8]=33; gridPos[9]=34; gridPos[10]=35;
          gridPos[11]=36; gridPos[12]=37;
          gridPos[13]=48; gridPos[14]=49; gridPos[15]=50; gridPos[16]=51; gridPos[17]=52; gridPos[18]=53;
          gridPos[19]=54; gridPos[20]=55;
          // elementos d período 4: Z 21-30 → columnas 3-12 de fila 4 → posiciones 56-65
          gridPos[21]=56; gridPos[22]=57; gridPos[23]=58; gridPos[24]=59; gridPos[25]=60;
          gridPos[26]=61; gridPos[27]=62; gridPos[28]=63; gridPos[29]=64; gridPos[30]=65;
          gridPos[31]=66; gridPos[32]=67; gridPos[33]=68; gridPos[34]=69; gridPos[35]=70; gridPos[36]=71;

          // Construir mapa inverso posición → Z
          java.util.Map<Integer,Integer> posToZ = new java.util.HashMap<>();
          for (int z2=1;z2<=36;z2++) posToZ.put(gridPos[z2], z2);

          // bloques
          java.util.Set<Integer> sBlk = new java.util.HashSet<>(java.util.Arrays.asList(1,2,3,4,11,12,19,20));
          java.util.Set<Integer> dBlk = new java.util.HashSet<>(java.util.Arrays.asList(21,22,23,24,25,26,27,28,29,30));
          java.util.Set<Integer> nobleZ = new java.util.HashSet<>(java.util.Arrays.asList(2,10,18,36));

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
                  String simbol = (eCell!=null) ? eCell.getSimbolo() : "?";
        %>
            <div class="ec <%= blkCls %><%= selCls %>"
                 title="<%= eCell!=null?eCell.getNombre():"Z="+zCell %> (Z=<%= zCell %>)"
                 onclick="selEl(<%= zCell %>)">
              <span class="ec-z"><%= zCell %></span>
              <span class="ec-sim"><%= simbol %></span>
            </div>
        <%
              }
          }
        %>
      </div><!-- /tabla -->

      <!-- Isótopo objetivo -->
      <div class="obj-box <%= hayObjetivo?"":"vacio" %>">
        <% if (hayObjetivo) { %>
        <div class="obj-tit">🎯 Isótopo objetivo</div>
        <div class="obj-iso-nom"><%= nomIsoObj %></div>
        <div class="obj-row">
          <span class="obj-lbl">Elemento</span>
          <span class="obj-val"><%= ebReto!=null?ebReto.getNombre()+" (Z="+ebReto.getNumeroAtomico()+")":"—" %></span>
        </div>
        <div class="obj-row">
          <span class="obj-lbl">Neutrones objetivo</span>
          <span class="obj-val"><%= neutronesObjetivo %></span>
        </div>
        <div class="obj-row">
          <span class="obj-lbl">Número másico</span>
          <span class="obj-val"><%= isoObj.getNumeroMasico() %></span>
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
const ST={
    p:       <%=protones%>,
    n:       <%=nAct%>,
    modoEval:<%=modoEval%>,
    tiempo:  <%=temporizador%>,
    intentos:<%=intentosUsados%>,
    maxInt:  <%=Reto.MAX_INTENTOS%>,
    retoId:  '<%=retoId%>',
    descReto:'<%=descRetoJs%>',
    hayElem: <%=hayElemento%>
};

function enviar(a){document.getElementById('hdnA').value=a;document.getElementById('frm').submit()}
function selEl(z){document.getElementById('hdnA').value='seleccionarElemento';document.getElementById('hdnZ').value=z;document.getElementById('frm').submit()}
function confirmarReiniciar(){if(confirm('¿Reiniciar? Se perderá el progreso.'))enviar('reiniciar')}
function confirmarVolver()   {if(confirm('¿Volver al menú?'))enviar('volver')}

/* ── TIMER ── */
let timerSeg=null,timerInvl=null;
function actualizarHUD(s){
    const txt=s>0?s+'s':'¡Tiempo!';
    const h=document.getElementById('hudTimer');
    const m=document.getElementById('modTimer');
    if(h){h.textContent=txt;h.className='hud-t'+(s>20?' ok':'')}
    if(m) m.textContent=txt;
}
function iniciarTimer(segs){
    if(timerInvl)clearInterval(timerInvl);
    timerSeg=segs;
    actualizarHUD(timerSeg);
    timerInvl=setInterval(()=>{
        timerSeg--;
        sessionStorage.setItem('seaea4_timer',timerSeg);
        actualizarHUD(timerSeg);
        if(timerSeg<=0){
            clearInterval(timerInvl);timerInvl=null;
            sessionStorage.removeItem('seaea4_timer');
            sessionStorage.removeItem('seaea4_retoId');
            setTimeout(()=>enviar('comprobar'),800);
        }
    },1000);
}

/* ── MODAL ── */
function openModal(){
    if(document.getElementById('btnQ').classList.contains('dis'))return;
    const s=sessionStorage.getItem('seaea4_desc_'+ST.retoId);
    if(s)document.getElementById('modDesc').textContent=s;
    document.getElementById('modInt').textContent=ST.intentos;
    document.getElementById('modReto').classList.add('show');
}
function closeModal(){document.getElementById('modReto').classList.remove('show')}

/* ── MASCOTA ── */
const GUIA=[
    {t:'¡Bienvenido a Configura tu Isótopo!',m:'Hola, soy AmazonAtom 🦁\nEn este escenario explorarás los ISÓTOPOS.\n¡Son átomos del mismo elemento con diferente número de neutrones!',btn:'Siguiente →'},
    {t:'¿Qué son los isótopos?',m:'⚛️ Isótopos: mismo Z (protones), distinto A (número másico).\n\nEjemplo: Helio-3 (2p, 1n) y Helio-4 (2p, 2n).\nNombre: Elemento-A → Helio-4',btn:'Siguiente →'},
    {t:'Cómo usar este escenario',m:'1️⃣ Selecciona un elemento de la tabla periódica.\n2️⃣ Protones y electrones se fijan automáticamente.\n3️⃣ Solo modifica los NEUTRONES con + y −.\n4️⃣ El isótopo, masa y abundancia se actualizan en tiempo real.',btn:'Siguiente →'},
    {t:'Estabilidad y abundancia',m:'🟢 ESTABLE: el núcleo no se desintegra.\n🔴 INESTABLE: el núcleo es radiactivo.\n\n📊 La abundancia indica el porcentaje natural de ese isótopo.',btn:'Siguiente →'},
    {t:'¡Listo para evaluarte!',m:'🏆 Presiona INICIAR EVALUACIÓN.\nSelecciona el elemento correcto y ajusta los neutrones al valor pedido.\nNecesitas ≥ 80% para superar el escenario.',btn:'¡Entendido!'}
];
let paso=0,mGuia='inicial',afterCb=null;
function abrirMasc(modo){mGuia=modo;renderMasc();document.getElementById('ovMasc').classList.add('vis')}
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
    if(estado==='ok') {badge.className='badge b-ok'; badge.textContent='✅ ¡Correcto!';        badge.style.display='inline-block'}
    if(estado==='err'){badge.className='badge b-err';badge.textContent='❌ Incorrecto';         badge.style.display='inline-block'}
    if(estado==='warn'){badge.className='badge b-warn';badge.textContent='⏱ Intentos agotados';badge.style.display='inline-block'}
    if(nuevoDesc){document.getElementById('mNuevoRetoDesc').textContent=nuevoDesc;document.getElementById('mNuevoReto').style.display='block'}
    document.getElementById('ovMasc').classList.add('vis');
}

/* ── NÚCLEO Y ELECTRONES SVG ── */
const NS='http://www.w3.org/2000/svg';
const R=6;
function hexLayout(total){
    if(!total)return[];
    const pos=[{x:0,y:0}];const D=R*2.4;let ring=1;
    while(pos.length<total){
        const cnt=6*ring;const step=(2*Math.PI)/cnt;
        for(let i=0;i<cnt&&pos.length<total;i++){const a=step*i;pos.push({x:D*ring*Math.cos(a),y:D*ring*Math.sin(a)})}
        ring++;
    }
    return pos;
}
function dibujarNucleo(p,n){
    const g=document.getElementById('nucleoG');g.innerHTML='';
    const total=p+n;if(!total)return;
    const arr=[...Array(p).fill('p'),...Array(n).fill('n')];
    for(let i=arr.length-1;i>0;i--){const j=Math.floor(Math.random()*(i+1));[arr[i],arr[j]]=[arr[j],arr[i]]}
    hexLayout(total).forEach((pos,i)=>{
        const c=document.createElementNS(NS,'circle');
        c.setAttribute('cx',45+pos.x);c.setAttribute('cy',45+pos.y);c.setAttribute('r',R);
        c.setAttribute('fill',arr[i]==='p'?'#4a86f5':'#f5c540');
        c.setAttribute('stroke','rgba(0,0,0,.12)');c.setAttribute('stroke-width','1.5');
        g.appendChild(c);
    });
    // inclinar balanza
    const diff=Math.max(-8,Math.min(8,(p+n)-p));
    document.getElementById('balanzaBrazo').style.transform=`translateX(-50%) rotate(${diff*2}deg)`;
}
function dibujarElectrones(e){
    const g=document.getElementById('electronG');g.innerHTML='';if(!e)return;
    const orbs=[{r:18,max:2},{r:32,max:8},{r:42,max:18}];let rest=e;
    orbs.forEach(o=>{
        if(rest<=0)return;const en=Math.min(rest,o.max);rest-=en;const step=(2*Math.PI)/en;
        for(let i=0;i<en;i++){
            const a=step*i-Math.PI/2;
            const c=document.createElementNS(NS,'circle');
            c.setAttribute('cx',45+o.r*Math.cos(a));c.setAttribute('cy',45+o.r*Math.sin(a));
            c.setAttribute('r',R);c.setAttribute('fill','#f470b0');
            c.setAttribute('stroke','rgba(0,0,0,.12)');c.setAttribute('stroke-width','1.5');
            g.appendChild(c);
        }
    });
}
function renderDots(id,count,cls){
    const el=document.getElementById(id);if(!el)return;el.innerHTML='';
    for(let i=0;i<Math.min(count,15);i++){const d=document.createElement('span');d.className='dot '+cls;el.appendChild(d)}
}

/* ── INIT ── */
document.addEventListener('DOMContentLoaded',()=>{
    dibujarNucleo(ST.p,ST.n);
    dibujarElectrones(ST.p);
    renderDots('dotsP',ST.p,'d-p');
    renderDots('dotsN',ST.n,'d-n');
    renderDots('dotsE',ST.p,'d-e');

    if(ST.modoEval&&ST.retoId){
        const sId=sessionStorage.getItem('seaea4_retoId');
        const sT=parseInt(sessionStorage.getItem('seaea4_timer')||'0');
        if(sId===ST.retoId&&sT>0){iniciarTimer(sT)}
        else{sessionStorage.setItem('seaea4_retoId',ST.retoId);sessionStorage.setItem('seaea4_timer',ST.tiempo);iniciarTimer(ST.tiempo)}
    }
    if(ST.retoId&&ST.descReto)sessionStorage.setItem('seaea4_desc_'+ST.retoId,ST.descReto);
    if(ST.retoId)document.getElementById('btnQ').classList.remove('dis');

    <% if (tieneResult) { %>
    {
        const ok   =<%=correcto%>;
        const agot =<%=intentosUsados%>>=<%=Reto.MAX_INTENTOS%>;
        const msg  ='<%=msgMascJs%>';
        const nuDesc='<%=nuevoReto?descRetoJs:""%>';
        let titulo,estado;
        if(ok){titulo='¡Reto superado! 🎉';estado='ok'}
        else if(agot){titulo='Intentos agotados 😔';estado='warn'}
        else{titulo='Intento fallido';estado='err'}
        setTimeout(()=>mostrarRetro(titulo,msg,estado,nuDesc||null,<%=nuevoReto%>?()=>setTimeout(openModal,350):null),300);
    }
    <% } else if (primeraCarga) { %>
    paso=0;setTimeout(()=>abrirMasc('inicial'),350);
    <% } else if (nuevoReto && modoEval) { %>
    setTimeout(()=>openModal(),400);
    <% } %>
});
</script>
</body>
</html>
