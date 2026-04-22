<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%@ page import="modelo.ElementoBase, modelo.Reto" %>
<%
    // ── Datos del átomo del estudiante ───────────────────────────────────────
    int     protones      = request.getAttribute("protones")      != null ? (int)request.getAttribute("protones")      : 0;
    int     neutrones     = request.getAttribute("neutrones")     != null ? (int)request.getAttribute("neutrones")     : 0;
    int     electrones    = request.getAttribute("electrones")    != null ? (int)request.getAttribute("electrones")    : 0;
    int     masico        = request.getAttribute("numeroMasico")  != null ? (int)request.getAttribute("numeroMasico")  : 0;
    int     cargaNeta     = request.getAttribute("cargaNeta")     != null ? (int)request.getAttribute("cargaNeta")     : 0;
    int     porcentaje    = request.getAttribute("porcentaje")    != null ? (int)request.getAttribute("porcentaje")    : 0;
    boolean modoEval      = Boolean.TRUE.equals(request.getAttribute("modoEvaluacion"));
    boolean habCont       = Boolean.TRUE.equals(request.getAttribute("habilitarContinuar"));

    // ── Elemento identificado (columna izquierda) ────────────────────────────
    ElementoBase eb   = (ElementoBase) request.getAttribute("elementoIdentificado");
    String simbolo    = (eb != null) ? eb.getSimbolo() : "";
    String nombreElem = (eb != null) ? eb.getNombre()  : "";

    // ── Reto / evaluación ────────────────────────────────────────────────────
    Reto   retoActual     = (Reto) request.getAttribute("retoActual");
    String descReto       = request.getAttribute("descripcionReto") != null
                            ? (String) request.getAttribute("descripcionReto") : "";
    int    intentosUsados = request.getAttribute("intentosUsados") != null
                            ? (int) request.getAttribute("intentosUsados") : 0;
    int    temporizador   = request.getAttribute("temporizador") != null
                            ? (int) request.getAttribute("temporizador") : 90;
    boolean nuevoReto     = Boolean.TRUE.equals(request.getAttribute("nuevoReto"));

    // ── Mascota / resultado ──────────────────────────────────────────────────
    String  msgMasc       = request.getAttribute("mensajeMascota") != null
                            ? (String) request.getAttribute("mensajeMascota") : "";
    Object  rcObj         = request.getAttribute("resultadoCorrecto");
    boolean correcto      = rcObj != null && (boolean) rcObj;
    boolean tieneResult   = rcObj != null;

    boolean primeraCarga  = !modoEval && !tieneResult && !nuevoReto
                            && request.getAttribute("mensajeMascota") != null;

    // ── Datos del ÁTOMO OBJETIVO ─────────────────────────────────────────────
    int    objProtones  = request.getAttribute("objProtones")  != null ? (int)request.getAttribute("objProtones")  : 0;
    int    objNeutrones = request.getAttribute("objNeutrones") != null ? (int)request.getAttribute("objNeutrones") : 0;
    int    objMasico    = request.getAttribute("objMasico")    != null ? (int)request.getAttribute("objMasico")    : 0;
    String objSimbolo   = request.getAttribute("objSimbolo")   != null ? (String)request.getAttribute("objSimbolo") : "";
    String objNombre    = request.getAttribute("objNombre")    != null ? (String)request.getAttribute("objNombre")  : "";
    boolean hayObjetivo = !objSimbolo.isEmpty() && modoEval;

    // Estabilidad del átomo objetivo (Z == N → estable)
    String estabilidad = "ESTABLE";
    if (hayObjetivo) {
        estabilidad = (objProtones == objNeutrones) ? "ESTABLE" : "INESTABLE";
    }

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
<title>Configura tu Átomo Objetivo – SEAEA</title>
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
    display:flex;align-items:center;justify-content:center;padding:10px}

/* ── WRAPPER ── */
.sim{background:var(--panel);border:3px solid var(--border);border-radius:28px;
    box-shadow:0 8px 32px rgba(40,70,160,.12);width:100%;max-width:1060px;
    padding:14px 22px 18px;display:flex;flex-direction:column;gap:10px}

/* ── TOP BAR ── */
.top{display:flex;align-items:center;gap:10px}
.lbl-apz{font-size:11px;font-weight:800;color:#7a8cb0;letter-spacing:.8px;white-space:nowrap}
.pill-pct{background:#fde0e0;border:2.5px solid var(--red);border-radius:22px;
    padding:2px 14px;font-size:19px;font-weight:900;color:var(--red-d);
    min-width:68px;text-align:center;transition:all .4s;flex-shrink:0}
.pill-pct.ok{background:#d2f5e2;border-color:var(--green);color:#1a6e38}
.prog-track{width:140px;height:11px;background:#dde4f5;border-radius:7px;overflow:hidden;
    border:1.5px solid var(--border);flex-shrink:0}
.prog-fill{height:100%;border-radius:7px;
    background:linear-gradient(90deg,#f46a6a 0%,#f5c540 50%,#4ec87a 100%);transition:width .7s ease}
.titulo{flex:1;text-align:center;font-family:var(--ft);font-size:24px;font-weight:900;
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
.btn-reto:active{transform:translateY(2px);box-shadow:0 2px 0 var(--blue-d)}
.btn-reto.fin{background:#e53e3e;box-shadow:0 4px 0 #a02020}
.btn-q{width:32px;height:32px;background:#fde8e8;border:2.5px solid #f4a0a0;
    border-radius:50%;font-size:15px;font-weight:900;color:var(--red-d);cursor:pointer;
    display:flex;align-items:center;justify-content:center;transition:transform .2s;flex-shrink:0}
.btn-q:hover{transform:scale(1.15)}
.btn-q.dis{opacity:.35;pointer-events:none}

/* ══ GRID CENTRAL ══════════════════════════════════════════════════════════
   3 columnas: [izquierda: carta+conteo+controles] [centro: objetivo] [derecha: carga+átomo]
*/
.body-grid{
    display:grid;
    grid-template-columns:1fr 220px 320px;
    gap:12px;
    align-items:start
}
.col-left{display:flex;flex-direction:column;gap:10px}

/* ── Carta elemento identificado ── */
.carta{background:#edf2ff;border:2.5px solid var(--border);border-radius:18px;
    padding:14px 12px;display:flex;align-items:stretch;align-self:flex-start;min-width:160px}
.c-nums{display:flex;flex-direction:column;align-items:center;justify-content:space-between;
    padding:4px 10px 4px 4px;border-right:2px solid var(--border);min-width:44px}
.c-mas,.c-z{font-size:24px;font-weight:900;color:#1a2848;line-height:1}
.c-info{flex:1;display:flex;flex-direction:column;align-items:center;justify-content:center;
    padding:0 8px;gap:3px}
.c-sim{font-family:var(--ft);font-size:48px;font-weight:900;color:var(--blue);line-height:1;transition:all .3s}
.c-sim.vacio{color:#b8c8e8}
.c-nom{font-size:11px;font-weight:700;color:#7a8cb0;text-align:center;
    max-width:110px;white-space:nowrap;overflow:hidden;text-overflow:ellipsis}

/* Panel conteo */
.cont-panel{background:#edf2ff;border:2px solid var(--border);border-radius:14px;
    padding:10px 14px;display:flex;flex-direction:column;gap:7px}
.cont-fila{display:flex;align-items:center;gap:8px}
.cont-lbl{font-size:13px;font-weight:700;color:#555;width:80px;flex-shrink:0}
.dots-a{display:flex;flex-wrap:wrap;gap:3px;flex:1;min-height:16px}
.dot{width:14px;height:14px;border-radius:50%;border:1.5px solid rgba(0,0,0,.1);animation:pop .18s ease}
@keyframes pop{from{transform:scale(0)}to{transform:scale(1)}}
.d-p{background:var(--proton)}.d-n{background:var(--neutron)}.d-e{background:var(--electron)}
.cont-num{font-size:15px;font-weight:800;min-width:24px;text-align:right}

/* Controles */
.ctrl-f{display:flex;justify-content:space-between;gap:10px;width:100%}
.ctrl-g{display:flex;flex-direction:column;align-items:center;gap:7px;flex:1;min-width:0}
.btn-ov{width:100%;height:46px;border-radius:50px;border:none;
    font-size:28px;font-weight:900;color:#fff;cursor:pointer;
    display:flex;align-items:center;justify-content:center;
    transition:transform .12s,box-shadow .12s;position:relative;overflow:hidden;user-select:none}
.btn-ov::after{content:'';position:absolute;inset:0;background:rgba(255,255,255,.18);
    opacity:0;transition:opacity .12s;border-radius:inherit}
.btn-ov:hover::after{opacity:1}
.btn-ov:active{transform:translateY(3px)}
.btn-ov.plus {background:var(--green);box-shadow:0 6px 0 var(--green-d)}
.btn-ov.minus{background:var(--red);  box-shadow:0 6px 0 var(--red-d)}
.btn-ov.plus:active {box-shadow:0 2px 0 var(--green-d)}
.btn-ov.minus:active{box-shadow:0 2px 0 var(--red-d)}
.lbl-ov{width:100%;height:36px;border-radius:50px;display:flex;align-items:center;
    justify-content:center;font-size:13px;font-weight:800;color:#fff}
.l-p{background:var(--blue)}.l-n{background:var(--yellow);color:#4a3000}.l-e{background:var(--electron)}

/* ══ COLUMNA CENTRAL: ÁTOMO OBJETIVO ══════════════════════════════════════ */
.col-center{display:flex;flex-direction:column;gap:10px}

.obj-titulo{
    background:var(--teal);
    color:#fff;
    font-family:var(--ft);
    font-size:14px;
    font-weight:900;
    letter-spacing:1px;
    text-align:center;
    border-radius:12px;
    padding:8px 10px;
    box-shadow:0 4px 0 var(--teal-d);
}

/* Carta objetivo grande */
.obj-card{
    background:#edf2ff;
    border:2.5px solid var(--teal);
    border-radius:18px;
    padding:14px 12px;
    display:flex;
    align-items:stretch;
    position:relative;
}
.obj-card.vacia{border-style:dashed;border-color:var(--border);background:#f8faff}
.obj-c-nums{
    display:flex;flex-direction:column;align-items:center;
    justify-content:space-between;
    padding:4px 10px 4px 4px;
    border-right:2px solid var(--border);min-width:44px
}
.obj-c-mas,.obj-c-z{font-size:24px;font-weight:900;color:#1a2848;line-height:1}
.obj-c-info{
    flex:1;display:flex;flex-direction:column;align-items:center;
    justify-content:center;padding:0 8px;gap:3px
}
.obj-c-sim{
    font-family:var(--ft);font-size:52px;font-weight:900;
    color:var(--teal);line-height:1;transition:all .3s
}
.obj-c-sim.vacio{color:#b8c8e8}
.obj-c-nom{font-size:11px;font-weight:700;color:#7a8cb0;text-align:center;
    max-width:120px;white-space:nowrap;overflow:hidden;text-overflow:ellipsis}

/* Recuadros de info objetivo */
.obj-info-grid{display:flex;flex-direction:column;gap:6px}
.obj-info-row{
    display:flex;align-items:center;justify-content:space-between;
    background:#fff;border:1.5px solid var(--border);
    border-radius:10px;padding:6px 12px;
}
.obj-info-lbl{font-size:11px;font-weight:800;color:#7a8cb0;letter-spacing:.5px;text-transform:uppercase}
.obj-info-val{
    font-size:15px;font-weight:900;color:#1a2848;
    background:#edf2ff;border:1.5px solid var(--border);
    border-radius:8px;padding:2px 12px;min-width:70px;text-align:center;
}
.obj-info-val.estable{color:var(--green-d);background:#d2f5e2;border-color:var(--green)}
.obj-info-val.inestable{color:var(--red-d);background:#fde0e0;border-color:var(--red)}

/* Placeholder sin reto */
.obj-placeholder{
    display:flex;flex-direction:column;align-items:center;justify-content:center;
    gap:8px;padding:20px 10px;text-align:center;
}
.obj-placeholder span{font-size:32px}
.obj-placeholder p{font-size:12px;color:#aab8d0;font-weight:700;line-height:1.4}

/* ══ COLUMNA DERECHA ══════════════════════════════════════════════════════ */
.col-right{display:flex;flex-direction:column;gap:10px}

/* Carga neta */
.carga-box{background:#edf2ff;border:2px solid var(--border);border-radius:14px;padding:10px 14px 8px}
.carga-nums{display:flex;justify-content:space-between;font-size:10px;color:#9aa8c8;padding:0 2px;margin-bottom:4px}
.carga-track{position:relative;height:28px;
    background:linear-gradient(to right,#f46a6a 0%,#fff 50%,#4ec87a 100%);
    border-radius:8px;border:1.5px solid var(--border);overflow:visible}
.carga-mk{position:absolute;top:-5px;bottom:-5px;width:5px;background:#1a2848;border-radius:3px;
    left:50%;transform:translateX(-50%);transition:left .45s cubic-bezier(.34,1.56,.64,1);
    box-shadow:0 1px 6px rgba(0,0,0,.3)}
.carga-lbl{text-align:center;font-size:12px;font-weight:700;color:#555;margin-top:7px}

/* Átomo */
.atomo-w{display:flex;align-items:center;justify-content:center}
.atomo-svg{width:280px;height:280px;overflow:visible}

/* ── BOTONES INFERIORES ── */
.acciones{display:flex;justify-content:center;gap:12px;margin-top:2px}
.btn-ac{padding:11px 26px;border-radius:14px;border:none;font-family:var(--fb);
    font-size:14px;font-weight:800;cursor:pointer;letter-spacing:.4px;
    color:#1a2848;transition:transform .12s,box-shadow .12s,filter .12s}
.btn-ac:hover{filter:brightness(1.07)}
.btn-ac:active{transform:translateY(2px)}
.btn-ac:disabled{opacity:.4;cursor:not-allowed;transform:none;filter:none}
.ac-r{background:var(--yellow);box-shadow:0 4px 0 var(--yellow-d)}
.ac-c{background:var(--blue);  box-shadow:0 4px 0 var(--blue-d);  color:#fff}
.ac-v{background:var(--red);   box-shadow:0 4px 0 var(--red-d);   color:#fff}
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
    max-width:500px;width:92%;box-shadow:0 26px 70px rgba(0,0,0,.22);text-align:center;
    transform:scale(.84) translateY(20px);
    transition:transform .38s cubic-bezier(.34,1.56,.64,1)}
.ov-bg.vis .masc-card{transform:scale(1) translateY(0)}

.m-ava-img{width:90px;height:90px;object-fit:contain;margin:0 auto 10px;display:block;
    border-radius:50%;background:#f0f5ff;padding:6px;
    box-shadow:0 4px 16px rgba(74,134,245,.2)}
.m-ava-img.sm{width:64px;height:64px;padding:4px}

.m-tit{font-family:var(--ft);font-size:20px;font-weight:800;color:#1a2848;margin-bottom:10px}
.m-pasos{display:flex;justify-content:center;gap:7px;margin-bottom:14px}
.m-pt{width:8px;height:8px;border-radius:50%;background:var(--border);transition:background .3s,transform .3s}
.m-pt.act{background:var(--blue);transform:scale(1.4)}
.badge{display:inline-block;padding:4px 16px;border-radius:20px;font-size:13px;font-weight:800;margin-bottom:10px}
.b-ok {background:#d2f5e2;color:#1a6e38}
.b-err{background:#fde0e0;color:var(--red-d)}
.b-warn{background:#fef3cd;color:#856404}
.m-txt{font-size:14px;color:#444;line-height:1.7;margin-bottom:16px;white-space:pre-line}

.nuevo-reto-box{background:#f0f5ff;border:2px solid var(--border);border-radius:14px;
    padding:12px 16px;margin-bottom:16px;text-align:left}
.nuevo-reto-box .nr-tit{font-size:11px;font-weight:800;color:#7a8cb0;
    margin-bottom:5px;letter-spacing:.5px;text-transform:uppercase}
.nuevo-reto-box .nr-desc{font-size:13px;font-weight:600;color:#1a2848;line-height:1.5}

.m-btns{display:flex;gap:10px;justify-content:center}
.m-btn{padding:10px 28px;border-radius:12px;border:none;font-family:var(--fb);
    font-size:14px;font-weight:800;cursor:pointer;transition:filter .15s,transform .1s}
.m-btn:active{transform:translateY(2px)}
.mb-p{background:var(--blue);color:#fff;box-shadow:0 4px 0 var(--blue-d)}
.mb-p:hover{filter:brightness(1.08)}

/* ── MODAL RETO ── */
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
.mod-x{position:absolute;top:12px;right:14px;background:none;border:none;
    font-size:18px;cursor:pointer;color:#bbb}
.mod-x:hover{color:#ef4444}

/* Animación pulso en la carta objetivo cuando hay reto activo */
@keyframes pulsoBorde {
    0%,100%{box-shadow:0 0 0 0 rgba(46,196,182,.35)}
    50%{box-shadow:0 0 0 8px rgba(46,196,182,0)}
}
.obj-card.activo{animation:pulsoBorde 2s ease-in-out infinite}
</style>
</head>
<body>
<form id="frm" method="post" action="<%= request.getContextPath() %>/escenario3">
    <input type="hidden" name="accion"    id="hdnA" value="">
    <input type="hidden" name="particula" id="hdnP" value="">
</form>

<!-- ══ OVERLAY MASCOTA ════════════════════════════════════════════════════ -->
<div class="ov-bg" id="ovMasc">
  <div class="masc-card">
    <img id="mascImg"
         src="data:image/png;base64,/9j/4AAQSkZJRgABAQAAAQABAAD/4gHYSUNDX1BST0ZJTEUAAQEAAAHIAAAAAAQwAABtbnRyUkdCIFhZWiAH4AABAAEAAAAAAABhY3NwAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAQAA9tYAAQAAAADTLQAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAlkZXNjAAAA8AAAACRyWFlaAAABFAAAABRnWFlaAAABKAAAABRiWFlaAAABPAAAABR3dHB0AAABUAAAABRyVFJDAAABZAAAAChnVFJDAAABZAAAAChiVFJDAAABZAAAAChjcHJ0AAABjAAAADxtbHVjAAAAAAAAAAEAAAAMZW5VUwAAAAgAAAAcAHMAUgBHAEJYWVogAAAAAAAAb6IAADj1AAADkFhZWiAAAAAAAABimQAAt4UAABjaWFlaIAAAAAAAACSgAAAPhAAAts9YWVogAAAAAAAA9tYAAQAAAADTLXBhcmEAAAAAAAQAAAACZmYAAPKnAAANWQAAE9AAAApbAAAAAAAAAABtbHVjAAAAAAAAAAEAAAAMZW5VUwAAACAAAAAcAEcAbwBvAGcAbABlACAASQBuAGMALgAgADIAMAAxADb/2wBDAAUDBAQEAwUEBAQFBQUGBwwIBwcHBw8LCwkMEQ8SEhEPERETFhwXExQaFRERGCEYGh0dHx8fExciJCIeJBweHx7/wAARCAHwA3kDASIAAhEBAxEB/8QAHAABAAEFAQEAAAAAAAAAAAAAAAQBAwUGBwII/8QAVBAAAQMDAAQHDAUJAwkGBAcAAQACAwQFEQYSITETFEFRU1RhcXOBlLLSBxUiMjNSVZGhsbHBFhciQkNEYmSCkqLR4fAkNGOEo8PxJiU2ZYQl/9oADAMBAAIRAxEAPwD6aXuipHXB5AeWU+4uG9/mCsYidPLHA3PhuwTzDlWxxRsijDGDAGwALsqnDDm80lJBTM1IImM/wBoDwj95V8NwqhFlld5REUpEREBERAREQEREBERARERMiIiAiIgIiICIiAiIgIiICIiAiIgIiICIiAiIgIiICIiAiIgIiICIiAiIgIiICIiAiIgIiICIiAiIgIiICIiAiIgIiICIiAiIgIiICIiAiIgIiICIiAiIgIiIgIiICIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiAiIgIiICIiAiIgIiIgIiICIiAiIgIiICIiAiIgIiICIiAiIgIiICIiAiIgIiICIiAiIgIiICIiAiJlAREQEREBERAREQEREBERAREQEREBERAREQEREBERAREQEREBERAREQEREBERAREQEREBERAREQERER//Z"
         alt="AmazonAtom" class="m-ava-img">
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
            onclick="closeModal();enviar('comprobar','')">✓ Comprobar ahora</button>
  </div>
</div>

<!-- ══ SIMULADOR ══════════════════════════════════════════════════════════ -->
<div class="sim">

  <!-- TOP BAR -->
  <div class="top">
    <span class="lbl-apz">APRENDIZAJE</span>
    <div class="pill-pct <%= porcentaje>=80?"ok":"" %>"><%= porcentaje %>%</div>
    <div class="prog-track"><div class="prog-fill" style="width:<%= porcentaje %>%"></div></div>
    <span class="titulo">CONFIGURAR ÁTOMO OBJETIVO</span>
    <% if (modoEval) { %>
    <div class="eval-hud">
        <span class="hud-t" id="hudTimer"><%= temporizador %>s</span>
        <div class="hud-sep"></div>
        <span class="hud-i" id="hudInt">Intentos: <%= intentosUsados %>/<%= Reto.MAX_INTENTOS %></span>
    </div>
    <button class="btn-reto fin" onclick="enviar('finalizar','')">FINALIZAR EVAL</button>
    <% } else { %>
    <button class="btn-reto" onclick="enviar('iniciarEval','')">INICIAR EVALUACIÓN</button>
    <% } %>
    <button class="btn-q <%= retoId.isEmpty()?"dis":"" %>" id="btnQ" onclick="openModal()">?</button>
  </div>

  <!-- GRID CENTRAL (3 columnas) -->
  <div class="body-grid">

    <!-- ── COLUMNA IZQUIERDA: Átomo del estudiante ── -->
    <div class="col-left">

      <!-- Carta del elemento identificado -->
      <div class="carta">
        <div class="c-nums">
          <span class="c-mas" id="cMas"><%= masico %></span>
          <span class="c-z"   id="cZ"><%= protones %></span>
        </div>
        <div class="c-info">
          <span class="c-sim <%= simbolo.isEmpty()?"vacio":"" %>" id="cSim"><%= simbolo.isEmpty()?"?":simbolo %></span>
          <span class="c-nom" id="cNom"><%= nombreElem %></span>
        </div>
      </div>

      <!-- Conteo de partículas -->
      <div class="cont-panel">
        <div class="cont-fila">
          <span class="cont-lbl">Protones</span>
          <div class="dots-a" id="dotsP"></div>
          <strong class="cont-num" style="color:var(--proton)"   id="nP"><%= protones %></strong>
        </div>
        <div class="cont-fila">
          <span class="cont-lbl">Neutrones</span>
          <div class="dots-a" id="dotsN"></div>
          <strong class="cont-num" style="color:var(--yellow-d)" id="nN"><%= neutrones %></strong>
        </div>
        <div class="cont-fila">
          <span class="cont-lbl">Electrones</span>
          <div class="dots-a" id="dotsE"></div>
          <strong class="cont-num" style="color:var(--electron)" id="nE"><%= electrones %></strong>
        </div>
      </div>

      <!-- Controles + / - -->
      <div class="ctrl-f">
        <div class="ctrl-g">
          <button class="btn-ov plus"  onclick="enviar('incrementar','protones')">+</button>
          <div    class="lbl-ov l-p">Protones</div>
          <button class="btn-ov minus" onclick="enviar('decrementar','protones')">−</button>
        </div>
        <div class="ctrl-g">
          <button class="btn-ov plus"  onclick="enviar('incrementar','neutrones')">+</button>
          <div    class="lbl-ov l-n">Neutrones</div>
          <button class="btn-ov minus" onclick="enviar('decrementar','neutrones')">−</button>
        </div>
        <div class="ctrl-g">
          <button class="btn-ov plus"  onclick="enviar('incrementar','electrones')">+</button>
          <div    class="lbl-ov l-e">Electrones</div>
          <button class="btn-ov minus" onclick="enviar('decrementar','electrones')">−</button>
        </div>
      </div>
    </div>

    <!-- ── COLUMNA CENTRAL: Átomo objetivo ── -->
    <div class="col-center">
      <div class="obj-titulo">🎯 ÁTOMO OBJETIVO</div>

      <!-- Carta del elemento objetivo -->
      <div class="obj-card <%= hayObjetivo?"activo":"vacia" %>">
        <% if (hayObjetivo) { %>
        <div class="obj-c-nums">
          <span class="obj-c-mas"><%= objMasico %></span>
          <span class="obj-c-z"><%= objProtones %></span>
        </div>
        <div class="obj-c-info">
          <span class="obj-c-sim"><%= objSimbolo %></span>
          <span class="obj-c-nom"><%= objNombre %></span>
        </div>
        <% } else { %>
        <div class="obj-placeholder">
          <span>⚛️</span>
          <p>Inicia la evaluación para ver el átomo objetivo</p>
        </div>
        <% } %>
      </div>

      <!-- Información del objetivo -->
      <div class="obj-info-grid">
        <div class="obj-info-row">
          <span class="obj-info-lbl">NEUTRO/ION:</span>
          <span class="obj-info-val">NEUTRO</span>
        </div>
        <div class="obj-info-row">
          <span class="obj-info-lbl">ESTABILIDAD:</span>
          <span class="obj-info-val <%= hayObjetivo?(estabilidad.equals("ESTABLE")?"estable":"inestable"):"" %>">
            <%= hayObjetivo ? estabilidad : "—" %>
          </span>
        </div>
        <div class="obj-info-row">
          <span class="obj-info-lbl">NÚM. MÁSICO:</span>
          <span class="obj-info-val"><%= hayObjetivo ? String.valueOf(objMasico) : "—" %></span>
        </div>
      </div>
    </div>

    <!-- ── COLUMNA DERECHA: Carga neta + Átomo visual ── -->
    <div class="col-right">
      <div class="carga-box">
        <div class="carga-nums">
          <span>-8</span><span>-6</span><span>-4</span><span>-2</span>
          <span>0</span><span>+2</span><span>+4</span><span>+6</span><span>+8</span>
        </div>
        <div class="carga-track">
          <div class="carga-mk" id="cMk" style="left:<%= 50+cargaNeta*6.25 %>%"></div>
        </div>
        <div class="carga-lbl">
          CARGA NETA:&nbsp;<strong id="cVal"><%= cargaNeta %></strong>&nbsp;–&nbsp;
          <span id="cDesc"><%= cargaNeta==0?"Neutro":(cargaNeta>0?"Catión (+"+cargaNeta+")":"Anión ("+cargaNeta+")") %></span>
        </div>
      </div>
      <div class="atomo-w">
        <svg class="atomo-svg" viewBox="0 0 310 310">
          <circle cx="155" cy="155" r="130" fill="none" stroke="#c5d2ec" stroke-width="1.7" stroke-dasharray="7 4"/>
          <circle cx="155" cy="155" r="88"  fill="none" stroke="#c5d2ec" stroke-width="1.7" stroke-dasharray="7 4"/>
          <circle cx="155" cy="155" r="46"  fill="none" stroke="#beccde" stroke-width="1.4" stroke-dasharray="5 4"/>
          <g id="nucleoG"></g>
          <g id="electronG"></g>
        </svg>
      </div>
    </div>

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
    e:        <%=electrones%>,
    carga:    <%=cargaNeta%>,
    modoEval: <%=modoEval%>,
    tiempo:   <%=temporizador%>,
    intentos: <%=intentosUsados%>,
    maxInt:   <%=Reto.MAX_INTENTOS%>,
    retoId:   '<%=retoId%>',
    descReto: '<%=descRetoJs%>',
    // Objetivo
    objP:     <%=objProtones%>,
    objN:     <%=objNeutrones%>,
    objA:     <%=objMasico%>,
    objSim:   '<%=objSimbolo%>',
    objNom:   '<%=objNombre%>'
};

function enviar(a,p){
    document.getElementById('hdnA').value=a;
    document.getElementById('hdnP').value=p;
    document.getElementById('frm').submit();
}
function confirmarReiniciar(){if(confirm('¿Reiniciar? Se perderá el progreso.'))enviar('reiniciar','')}
function confirmarVolver(){if(confirm('¿Volver al menú? Se perderá el progreso.'))enviar('volver','')}

/* ── TIMER ── */
let timerSeg=null, timerInvl=null;
function iniciarTimer(segs){
    if(timerInvl) clearInterval(timerInvl);
    timerSeg = segs;
    timerInvl = setInterval(()=>{
        timerSeg--;
        sessionStorage.setItem('seaea3_timer', timerSeg);
        const txt = timerSeg > 0 ? timerSeg+'s' : '¡Tiempo!';
        const h = document.getElementById('hudTimer');
        const m = document.getElementById('modTimer');
        if(h){ h.textContent=txt; h.className='hud-t'+(timerSeg>20?' ok':'') }
        if(m) m.textContent = txt;
        if(timerSeg <= 0){
            clearInterval(timerInvl); timerInvl=null;
            sessionStorage.removeItem('seaea3_timer');
            sessionStorage.removeItem('seaea3_retoId');
            setTimeout(()=>enviar('comprobar',''), 800);
        }
    }, 1000);
}

/* ── MODAL RETO ── */
function openModal(){
    if(document.getElementById('btnQ').classList.contains('dis')) return;
    const saved = sessionStorage.getItem('seaea3_desc_'+ST.retoId);
    if(saved) document.getElementById('modDesc').textContent = saved;
    document.getElementById('modInt').textContent = ST.intentos;
    document.getElementById('modReto').classList.add('show');
}
function closeModal(){ document.getElementById('modReto').classList.remove('show') }

/* ── MASCOTA ── */
const GUIA = [
    {t:'¡Bienvenido a Configurar Átomo Objetivo!',
     m:'Hola, soy AmazonAtom 🦁\nEn este escenario el sistema genera un elemento de la tabla periódica y tú debes configurar el átomo hasta igualar su número atómico (Z) y su número másico (A).\n¡Empecemos!', btn:'Siguiente →'},
    {t:'¿Qué debes igualar?',
     m:'🔵 Protones → definen el número atómico Z.\n🟡 Neutrones → junto con los protones forman el número másico A.\n\nA = Z + N   →   N = A – Z\n\n⚠️ Los electrones NO se evalúan en este escenario.', btn:'Siguiente →'},
    {t:'El átomo objetivo',
     m:'📋 En la columna central verás:\n• El símbolo y nombre del elemento.\n• Su número atómico Z.\n• Su número másico A.\n• Si es estable o inestable.\n\nTu misión: igualar Z y A con tus controles.', btn:'Siguiente →'},
    {t:'Estabilidad del núcleo',
     m:'⚗️ Un átomo es ESTABLE cuando Z ≈ N (protones ≈ neutrones).\nSi N es muy diferente de Z el átomo es INESTABLE.\nEsto te da una pista para ajustar los neutrones.', btn:'Siguiente →'},
    {t:'¡Listo para evaluarte!',
     m:'🏆 Presiona INICIAR EVALUACIÓN.\nCada reto dura 90 segundos, tienes 3 intentos.\nNecesitas ≥ 80 % para superar el escenario.', btn:'¡Entendido!'}
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
    const img = document.getElementById('mascImg');
    img.className = mGuia==='inicial' ? 'm-ava-img' : 'm-ava-img sm';
    document.getElementById('mBadge').style.display = 'none';
    document.getElementById('mNuevoReto').style.display = 'none';
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
    if(estado==='ok')  { badge.className='badge b-ok';  badge.textContent='✅ ¡Correcto!';          badge.style.display='inline-block' }
    if(estado==='err') { badge.className='badge b-err'; badge.textContent='❌ Incorrecto';           badge.style.display='inline-block' }
    if(estado==='warn'){ badge.className='badge b-warn';badge.textContent='⏱ Intentos agotados';   badge.style.display='inline-block' }
    if(nuevoDesc){
        document.getElementById('mNuevoRetoDesc').textContent = nuevoDesc;
        document.getElementById('mNuevoReto').style.display   = 'block';
    }
    document.getElementById('ovMasc').classList.add('vis');
}

/* ── ÁTOMO VISUAL ── */
const R=8, NS='http://www.w3.org/2000/svg';
function hexLayout(total){
    if(total===0) return [];
    const pos=[{x:0,y:0}]; const D=R*2.6; let ring=1;
    while(pos.length<total){
        const cnt=6*ring; const step=(2*Math.PI)/cnt;
        for(let i=0;i<cnt&&pos.length<total;i++){ const a=step*i; pos.push({x:D*ring*Math.cos(a),y:D*ring*Math.sin(a)}) }
        ring++;
    }
    return pos;
}
function dibujarNucleo(p,n){
    const g=document.getElementById('nucleoG'); g.innerHTML='';
    const total=p+n; if(total===0) return;
    const arr=[...Array(p).fill('p'),...Array(n).fill('n')];
    for(let i=arr.length-1;i>0;i--){ const j=Math.floor(Math.random()*(i+1)); [arr[i],arr[j]]=[arr[j],arr[i]] }
    hexLayout(total).forEach((pos,i)=>{
        const c=document.createElementNS(NS,'circle');
        c.setAttribute('cx',155+pos.x); c.setAttribute('cy',155+pos.y); c.setAttribute('r',R);
        c.setAttribute('fill',arr[i]==='p'?'#4a86f5':'#f5c540');
        c.setAttribute('stroke','rgba(0,0,0,.12)'); c.setAttribute('stroke-width','1.5');
        g.appendChild(c);
    });
}
function dibujarElectrones(e){
    const g=document.getElementById('electronG'); g.innerHTML=''; if(e===0) return;
    const orbs=[{r:46,max:2},{r:88,max:8},{r:130,max:18}]; let rest=e;
    orbs.forEach(o=>{
        if(rest<=0) return; const en=Math.min(rest,o.max); rest-=en; const step=(2*Math.PI)/en;
        for(let i=0;i<en;i++){
            const a=step*i-Math.PI/2;
            const c=document.createElementNS(NS,'circle');
            c.setAttribute('cx',155+o.r*Math.cos(a)); c.setAttribute('cy',155+o.r*Math.sin(a));
            c.setAttribute('r',R); c.setAttribute('fill','#f470b0');
            c.setAttribute('stroke','rgba(0,0,0,.12)'); c.setAttribute('stroke-width','1.5');
            g.appendChild(c);
        }
    });
}
function renderDots(id,count,cls){
    const el=document.getElementById(id); if(!el) return; el.innerHTML='';
    for(let i=0;i<Math.min(count,15);i++){ const d=document.createElement('span'); d.className='dot '+cls; el.appendChild(d) }
}

/* ── INIT ── */
document.addEventListener('DOMContentLoaded',()=>{
    dibujarNucleo(ST.p, ST.n);
    dibujarElectrones(ST.e);
    renderDots('dotsP', ST.p, 'd-p');
    renderDots('dotsN', ST.n, 'd-n');
    renderDots('dotsE', ST.e, 'd-e');
    document.getElementById('cMk').style.left = (50 + Math.max(-8, Math.min(8, ST.carga))*6.25) + '%';

    /* Timer */
    if(ST.modoEval && ST.retoId){
        const storedId    = sessionStorage.getItem('seaea3_retoId');
        const storedTimer = parseInt(sessionStorage.getItem('seaea3_timer')||'0');
        if(storedId===ST.retoId && storedTimer>0){
            iniciarTimer(storedTimer);
        } else {
            sessionStorage.setItem('seaea3_retoId', ST.retoId);
            sessionStorage.setItem('seaea3_timer',  ST.tiempo);
            iniciarTimer(ST.tiempo);
        }
    }

    /* Guardar descripción */
    if(ST.retoId && ST.descReto){
        sessionStorage.setItem('seaea3_desc_'+ST.retoId, ST.descReto);
    }

    /* Habilitar botón ? */
    if(ST.retoId) document.getElementById('btnQ').classList.remove('dis');

    /* ── LÓGICA DE MASCOTA ── */
    <% if (tieneResult) { %>
    {
        const ok    = <%=correcto%>;
        const agot  = <%=intentosUsados%> >= <%=Reto.MAX_INTENTOS%>;
        const msg   = '<%=msgMascJs%>';
        const nuDesc= '<%=nuevoReto ? descRetoJs : ""%>';
        let titulo, texto, estado;
        if(ok)       { titulo='¡Reto superado! 🎉';    texto=msg; estado='ok' }
        else if(agot){ titulo='Intentos agotados 😔';  texto=msg; estado='warn' }
        else         { titulo='Intento fallido';        texto=msg; estado='err' }
        setTimeout(()=>{
            mostrarRetro(titulo, texto, estado,
                nuDesc || null,
                <%=nuevoReto%> ? ()=>setTimeout(openModal,350) : null
            );
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

