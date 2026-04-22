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
    String simbolo    = (eb != null) ? eb.getSimbolo() : "";
    String nombreElem = (eb != null) ? eb.getNombre()  : "";

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
:root{
    --bg:#dde4f5;--panel:#f4f7ff;--border:#c5d2ec;
    --blue:#4a86f5;--blue-d:#1e56d0;
    --yellow:#f5c540;--yellow-d:#b89000;
    --red:#f46a6a;--red-d:#c43a3a;
    --green:#4ec87a;--green-d:#2a8a4e;
    --proton:#4a86f5;--neutron:#f5c540;
    --ft:'Baloo 2',cursive;--fb:'Nunito',sans-serif;
}
*,*::before,*::after{box-sizing:border-box;margin:0;padding:0}
body{background:var(--bg);font-family:var(--fb);min-height:100vh;
    display:flex;align-items:center;justify-content:center;padding:10px}

/* ── WRAPPER ── */
.sim{background:var(--panel);border:3px solid var(--border);border-radius:28px;
    box-shadow:0 8px 32px rgba(40,70,160,.12);width:100%;max-width:1000px;
    padding:14px 22px 18px;display:flex;flex-direction:column;gap:10px}

/* ── TOP BAR ── */
.top{display:flex;align-items:center;gap:10px}
.lbl-apz{font-size:11px;font-weight:800;color:#7a8cb0;letter-spacing:.8px;white-space:nowrap}
.pill-pct{background:#fde0e0;border:2.5px solid var(--red);border-radius:22px;
    padding:2px 14px;font-size:19px;font-weight:900;color:var(--red-d);
    min-width:68px;text-align:center;flex-shrink:0;transition:all .4s}
.pill-pct.ok{background:#d2f5e2;border-color:var(--green);color:#1a6e38}
.prog-track{width:140px;height:11px;background:#dde4f5;border-radius:7px;overflow:hidden;
    border:1.5px solid var(--border);flex-shrink:0}
.prog-fill{height:100%;border-radius:7px;
    background:linear-gradient(90deg,#f46a6a 0%,#f5c540 50%,#4ec87a 100%);transition:width .7s ease}
.titulo{flex:1;text-align:center;font-family:var(--ft);font-size:26px;font-weight:900;
    color:#1a2848;letter-spacing:1.5px}
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

/* ── GRID: 2 columnas ── */
.body-grid{display:grid;grid-template-columns:320px 1fr;gap:16px;align-items:start}
.col-left{display:flex;flex-direction:column;gap:10px}

/* ── CARTA ELEMENTO ── */
.carta{background:#edf2ff;border:2.5px solid var(--border);border-radius:18px;
    padding:16px 14px;display:flex;align-items:stretch}
.c-nums{display:flex;flex-direction:column;align-items:center;justify-content:space-between;
    padding:4px 10px 4px 4px;border-right:2px solid var(--border);min-width:48px}
.c-mas,.c-z{font-size:26px;font-weight:900;color:#1a2848;line-height:1}
.c-info{flex:1;display:flex;flex-direction:column;align-items:center;justify-content:center;
    padding:0 10px;gap:4px}
.c-sim{font-family:var(--ft);font-size:52px;font-weight:900;color:var(--blue);line-height:1}
.c-sim.vacio{color:#b8c8e8}
.c-nom{font-size:12px;font-weight:700;color:#7a8cb0;text-align:center}

/* ── PANEL Z ── */
.z-panel{background:#edf2ff;border:2px solid var(--border);border-radius:14px;padding:14px}
.z-label{font-size:11px;font-weight:800;color:#7a8cb0;letter-spacing:.8px;margin-bottom:8px}
.z-value{font-family:var(--ft);font-size:48px;font-weight:900;color:var(--blue);
    text-align:center;line-height:1}
.z-desc{font-size:12px;color:#555;text-align:center;margin-top:4px;font-weight:600}

/* ── PANEL CONTEO ── */
.cont-panel{background:#edf2ff;border:2px solid var(--border);border-radius:14px;
    padding:10px 14px;display:flex;flex-direction:column;gap:8px}
.cont-fila{display:flex;align-items:center;gap:8px}
.cont-lbl{font-size:13px;font-weight:700;color:#555;width:85px;flex-shrink:0}
.dots-a{display:flex;flex-wrap:wrap;gap:3px;flex:1;min-height:16px}
.dot{width:14px;height:14px;border-radius:50%;border:1.5px solid rgba(0,0,0,.1);animation:pop .18s ease}
@keyframes pop{from{transform:scale(0)}to{transform:scale(1)}}
.d-p{background:var(--proton)}.d-n{background:var(--neutron)}
.cont-num{font-size:15px;font-weight:800;min-width:24px;text-align:right}

/* ── CONTROLES ── */
.ctrl-f{display:flex;gap:16px;width:100%}
.ctrl-g{display:flex;flex-direction:column;align-items:center;gap:7px;flex:1}
.btn-ov{width:100%;height:46px;border-radius:50px;border:none;
    font-size:28px;font-weight:900;color:#fff;cursor:pointer;
    display:flex;align-items:center;justify-content:center;
    transition:transform .12s,box-shadow .12s;position:relative;overflow:hidden}
.btn-ov::after{content:'';position:absolute;inset:0;background:rgba(255,255,255,.18);
    opacity:0;transition:opacity .12s}
.btn-ov:hover::after{opacity:1}
.btn-ov:active{transform:translateY(3px)}
.btn-ov.plus {background:var(--green);box-shadow:0 6px 0 var(--green-d)}
.btn-ov.minus{background:var(--red);  box-shadow:0 6px 0 var(--red-d)}
.btn-ov.plus:active {box-shadow:0 2px 0 var(--green-d)}
.btn-ov.minus:active{box-shadow:0 2px 0 var(--red-d)}
.lbl-ov{width:100%;height:36px;border-radius:50px;display:flex;align-items:center;
    justify-content:center;font-size:14px;font-weight:800;color:#fff}
.l-p{background:var(--blue)}.l-n{background:var(--yellow);color:#4a3000}

/* ── COLUMNA DERECHA: núcleo grande ── */
.col-right{display:flex;flex-direction:column;gap:10px}

/* Número másico banner */
.masico-banner{background:linear-gradient(135deg,var(--blue) 0%,#2563eb 100%);
    border-radius:18px;padding:16px 20px;display:flex;align-items:center;
    justify-content:space-between;color:#fff}
.mb-label{font-size:12px;font-weight:800;letter-spacing:1px;opacity:.8}
.mb-formula{font-size:13px;font-weight:700;opacity:.75;text-align:right}
.mb-value{font-family:var(--ft);font-size:52px;font-weight:900;line-height:1}

/* Átomo/Núcleo grande */
.nucleo-w{display:flex;align-items:center;justify-content:center}
.nucleo-svg{width:340px;height:340px;overflow:visible}

/* ── BOTONES INFERIORES ── */
.acciones{display:flex;justify-content:center;gap:12px;margin-top:2px}
.btn-ac{padding:11px 26px;border-radius:14px;border:none;font-family:var(--fb);
    font-size:14px;font-weight:800;cursor:pointer;color:#1a2848;
    transition:transform .12s,box-shadow .12s,filter .12s}
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
.masc-card{background:#fff;border-radius:26px;padding:26px 36px 22px;
    max-width:500px;width:92%;box-shadow:0 26px 70px rgba(0,0,0,.22);text-align:center;
    transform:scale(.84) translateY(20px);
    transition:transform .38s cubic-bezier(.34,1.56,.64,1)}
.ov-bg.vis .masc-card{transform:scale(1) translateY(0)}
.m-ava-img{width:100px;height:100px;object-fit:contain;margin:0 auto 10px;display:block;
    border-radius:50%;background:#fff8e1;padding:6px;
    box-shadow:0 4px 16px rgba(74,134,245,.15)}
.m-ava-img.sm{width:72px;height:72px;padding:4px}
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

/* Badge Z dentro del simulador */
.badge-z{display:inline-flex;align-items:center;gap:6px;background:linear-gradient(135deg,var(--blue),#2563eb);
    color:#fff;border-radius:12px;padding:6px 14px;font-size:13px;font-weight:800}
</style>
</head>
<body>
<form id="frm" method="post" action="<%= request.getContextPath() %>/escenario2">
    <input type="hidden" name="accion"    id="hdnA" value="">
    <input type="hidden" name="particula" id="hdnP" value="">
</form>

<!-- ══ OVERLAY MASCOTA ════════════════════════════════════════════════════ -->
<div class="ov-bg" id="ovMasc">
  <div class="masc-card">
    <img id="mascImg" src="data:image/png;base64,/9j/4AAQSkZJRgABAQAAAQABAAD/4gHYSUNDX1BST0ZJTEUAAQEAAAHIAAAAAAQwAABtbnRyUkdCIFhZWiAH4AABAAEAAAAAAABhY3NwAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAQAA9tYAAQAAAADTLQAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAlkZXNjAAAA8AAAACRyWFlaAAABFAAAABRnWFlaAAABKAAAABRiWFlaAAABPAAAABR3dHB0AAABUAAAABRyVFJDAAABZAAAAChnVFJDAAABZAAAAChiVFJDAAABZAAAAChjcHJ0AAABjAAAADxtbHVjAAAAAAAAAAEAAAAMZW5VUwAAAAgAAAAcAHMAUgBHAEJYWVogAAAAAAAAb6IAADj1AAADkFhZWiAAAAAAAABimQAAt4UAABjaWFlaIAAAAAAAACSgAAAPhAAAts9YWVogAAAAAAAA9tYAAQAAAADTLXBhcmEAAAAAAAQAAAACZmYAAPKnAAANWQAAE9AAAApbAAAAAAAAAABtbHVjAAAAAAAAAAEAAAAMZW5VUwAAACAAAAAcAEcAbwBvAGcAbABlACAASQBuAGMALgAgADIAMAAxADb/2wBDAAUDBAQEAwUEBAQFBQUGBwwIBwcHBw8LCwkMEQ8SEhEPERETFhwXExQaFRERGCEYGh0dHx8fExciJCIeJBweHx7/2wBDAQUFBQcGBw4ICA4eFBEUHh4eHh4eHh4eHh4eHh4eHh4eHh4eHh4eHh4eHh4eHh4eHh4eHh4eHh4eHh4eHh4eHh7/wAARCAJUAkwDASIAAhEBAxEB/8QAHQABAAICAwEBAAAAAAAAAAAAAAYHBQgBAwQCCf/EAE8QAAEDAwEFBQUGAwUFBgQHAQEAAgMEBREGBxIhMUETIlFhcQgUMoGRFSNCUqGxYnLBFiQzgtFDkqLh8CU0RFOy8Rdjc4NFVIWTlKPCw//EABsBAQACAwEBAAAAAAAAAAAAAAAEBQIDBgcB/8QAPxEAAQMCAwQJAwQBAwMDBQAAAQACAwQRBSExEkFRYQYTInGBkaGx8DLB0RQj4fFCFTNSByRicoKSFjVDotL/2gAMAwEAAhEDEQA/ANMkRERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERERctG84DIGfFTG97Lte2emZVVmmK91M9m+yenYJ43NIyDvMJ4HPVQ5vxevBbh7PpNR/2Qst201dIX0NRRxvdRVhc6JrwN17Wkd6PiDyyP4VRY5ikuHNY9gFiSDe/hmNN+7yUWpnMNiFp6+N7HFrmODmnBBHEHwXBBBwRgrbzVendJa4lay+2f8As9qNx3IavDd2Z/TD29yYfwuDXqH3zYSzUekYLvYHwW/UMLn01dQveewnljcWkscc7hcMOAPA73RRKfpVSuA68FhOXEd9xqOfmsWVjDrktckXqutvrbXcJ7fcKaWlqqd5jlikbuuY4cwQvKuna4OFxopiIsve9PXK0262XKqgIo7pAZ6SYcWvaHFrh5EEcR6LELFj2vF2m4XwEHRERFmvqIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiLZj2XdRtuOlarTckpFVbZDPE3PxwPPH/dfn5OC1nWZ0ZqS6aUv9PerRMIqiEkEOGWvaeDmO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IiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiL//Z" alt="AmazonAtom" class="m-ava-img">
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

<!-- ══ SIMULADOR ══════════════════════════════════════════════════════════ -->
<div class="sim">

  <!-- TOP BAR -->
  <div class="top">
    <span class="lbl-apz">APRENDIZAJE</span>
    <div class="pill-pct <%= porcentaje>=80?"ok":"" %>"><%= porcentaje %>%</div>
    <div class="prog-track"><div class="prog-fill" style="width:<%= porcentaje %>%"></div></div>
    <span class="titulo">NÚMERO Y NÚCLEO ATÓMICO</span>
    <% if (modoEval) { %>
    <div class="eval-hud">
        <span class="hud-t" id="hudTimer"><%= temporizador %>s</span>
        <div class="hud-sep"></div>
        <span class="hud-i" id="hudInt">Intentos: <span id="hudIntVal"><%= intentosUsados %></span>/<%= Reto.MAX_INTENTOS %></span>
    </div>
    <button class="btn-reto fin" onclick="enviar('finalizar','')">FINALIZAR EVAL</button>
    <% } else { %>
    <button class="btn-reto" onclick="enviar('iniciarEval','')">INICIAR EVALUACIÓN</button>
    <% } %>
    <button class="btn-q <%= retoId.isEmpty()?"dis":"" %>" id="btnQ" onclick="openModal()">?</button>
  </div>

  <!-- GRID CENTRAL -->
  <div class="body-grid">

    <!-- COLUMNA IZQUIERDA -->
    <div class="col-left">

      <!-- Carta del elemento -->
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

      <!-- Panel Z (número atómico) -->
      <div class="z-panel">
        <div class="z-label">NÚMERO ATÓMICO (Z)</div>
        <div class="z-value" id="zValue"><%= protones %></div>
        <div class="z-desc">Z = número de protones = identidad del elemento</div>
      </div>

      <!-- Panel conteo -->
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
      </div>

      <!-- Controles: solo protones y neutrones -->
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
      </div>
    </div>

    <!-- COLUMNA DERECHA: banner másico + núcleo grande -->
    <div class="col-right">

      <!-- Banner número másico -->
      <div class="masico-banner">
        <div>
          <div class="mb-label">NÚMERO MÁSICO (A)</div>
          <div class="mb-value" id="masicoVal"><%= masico %></div>
        </div>
        <div class="mb-formula">A = protones + neutrones<br><span id="formCalc"><%= protones %> + <%= neutrones %> = <%= masico %></span></div>
      </div>

      <!-- Núcleo SVG grande -->
      <div class="nucleo-w">
        <svg class="nucleo-svg" viewBox="0 0 340 340">
          <!-- Orbitas de electrones (solo decorativas, difuminadas) -->
          <ellipse cx="170" cy="170" rx="160" ry="55" fill="none" stroke="#c5d2ec"
                   stroke-width="1.5" stroke-dasharray="6 4" transform="rotate(-30 170 170)" opacity=".5"/>
          <ellipse cx="170" cy="170" rx="160" ry="55" fill="none" stroke="#c5d2ec"
                   stroke-width="1.5" stroke-dasharray="6 4" transform="rotate(30 170 170)" opacity=".5"/>
          <ellipse cx="170" cy="170" rx="160" ry="55" fill="none" stroke="#c5d2ec"
                   stroke-width="1.5" stroke-dasharray="6 4" transform="rotate(90 170 170)" opacity=".5"/>
          <!-- Núcleo se dibuja con JS -->
          <g id="nucleoG"></g>
          <!-- Badge Z encima del núcleo -->
          <g id="zBadge" style="display:none">
            <rect id="zBadgeRect" x="130" y="145" width="80" height="50" rx="12"
                  fill="#4a86f5" opacity=".92"/>
            <text id="zBadgeText" x="170" y="163" text-anchor="middle"
                  font-size="11" font-weight="800" fill="rgba(255,255,255,.8)"
                  font-family="Nunito,sans-serif">Z =</text>
            <text id="zBadgeVal" x="170" y="186" text-anchor="middle"
                  font-size="26" font-weight="900" fill="#fff"
                  font-family="'Baloo 2',cursive">0</text>
          </g>
        </svg>
      </div>
    </div>
  </div>

  <!-- BOTONES INFERIORES -->
  <div class="acciones">
    <button class="btn-ac ac-r" onclick="confirmarReiniciar()">REINICIAR</button>
    <button class="btn-ac ac-c" id="btnComp" <%= !modoEval?"disabled":"" %> onclick="enviar('comprobar','')">COMPROBAR</button>
    <button class="btn-ac ac-v" onclick="confirmarVolver()">VOLVER</button>
    <button class="btn-ac ac-k" id="btnCont" <%= !habCont?"disabled":"" %> onclick="enviar('continuar','')">CONTINUAR</button>
  </div>
</div>
<script>
const ST={
    p:        <%=protones%>,
    n:        <%=neutrones%>,
    modoEval: <%=modoEval%>,
    tiempo:   <%=temporizador%>,
    intentos: <%=intentosUsados%>,
    maxInt:   <%=Reto.MAX_INTENTOS%>,
    retoId:   '<%=retoId%>',
    descReto: '<%=descRetoJs%>'
};

function enviar(a,p){
    // CORRECCIÓN: limpiar timer al navegar (evita que siga corriendo)
    if(timerInvl){clearInterval(timerInvl);timerInvl=null;}
    document.getElementById('hdnA').value=a;
    document.getElementById('hdnP').value=p;
    document.getElementById('frm').submit();
}
function confirmarReiniciar(){if(confirm('¿Reiniciar? Se perderá el progreso.'))enviar('reiniciar','')}
function confirmarVolver(){if(confirm('¿Volver al menú? Se perderá el progreso.'))enviar('volver','')}

/* ── TIMER ──────────────────────────────────────────────────────────────── */
let timerSeg=null, timerInvl=null;

function iniciarTimer(segs){
    if(timerInvl){clearInterval(timerInvl);timerInvl=null;}
    timerSeg=segs;
    timerInvl=setInterval(()=>{
        timerSeg--;
        sessionStorage.setItem('seaea2_timer', timerSeg);
        const txt = timerSeg>0 ? timerSeg+'s' : '¡Tiempo!';
        const h = document.getElementById('hudTimer');
        const m = document.getElementById('modTimer');
        if(h){h.textContent=txt; h.className='hud-t'+(timerSeg>20?' ok':'')}
        if(m) m.textContent=txt;
        if(timerSeg<=0){
            clearInterval(timerInvl); timerInvl=null;
            // CORRECCIÓN: limpiar sessionStorage del reto
            sessionStorage.removeItem('seaea2_timer');
            sessionStorage.removeItem('seaea2_retoId');
            setTimeout(()=>enviar('comprobar',''), 800);
        }
    }, 1000);
}

/* ── MODAL RETO ── */
function openModal(){
    if(document.getElementById('btnQ').classList.contains('dis'))return;
    const saved = sessionStorage.getItem('seaea2_desc_'+ST.retoId);
    if(saved) document.getElementById('modDesc').textContent=saved;
    document.getElementById('modInt').textContent=ST.intentos;
    document.getElementById('modReto').classList.add('show');
}
function closeModal(){document.getElementById('modReto').classList.remove('show')}

/* ── GUÍA INICIAL (5 pasos) ── */
const GUIA=[
    {t:'¡Bienvenido!',
     m:'Hola, soy AmazonAtom 🦜\nEn este escenario estudiarás el NÚCLEO ATÓMICO\ny el NÚMERO ATÓMICO (Z).\n¡Empecemos!',btn:'Siguiente →'},
    {t:'El núcleo atómico',
     m:'⚛️ El núcleo es el centro del átomo.\nContiene dos tipos de partículas:\n🔵 Protones → carga positiva\n🟡 Neutrones → sin carga',btn:'Siguiente →'},
    {t:'El número atómico (Z)',
     m:'🔑 Z = número de protones.\nZ define la IDENTIDAD del elemento.\n→ Si cambias protones, cambias el elemento.\n→ Si cambias neutrones, el elemento NO cambia.',btn:'Siguiente →'},
    {t:'El número másico (A)',
     m:'📊 A = protones + neutrones\nA cambia cuando agregas o quitas\nprotones o neutrones del núcleo.',btn:'Siguiente →'},
    {t:'¡Listo para evaluar!',
     m:'🏆 Presiona INICIAR EVALUACIÓN.\nTendrás 90 segundos y 3 intentos por reto.\nNecesitas ≥ 80% para superar el escenario.',btn:'¡Entendido!'}
];

let paso=0, mGuia='inicial', afterCb=null;

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
    const img=document.getElementById('mascImg');
    img.className=mGuia==='inicial'?'m-ava-img':'m-ava-img sm';
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
    if(estado==='ok')  {badge.className='badge b-ok'; badge.textContent='✅ ¡Correcto!';badge.style.display='inline-block'}
    if(estado==='err') {badge.className='badge b-err';badge.textContent='❌ Incorrecto';badge.style.display='inline-block'}
    if(estado==='warn'){badge.className='badge b-warn';badge.textContent='⏱ Intentos agotados';badge.style.display='inline-block'}
    if(nuevoDesc){
        document.getElementById('mNuevoRetoDesc').textContent=nuevoDesc;
        document.getElementById('mNuevoReto').style.display='block';
    }
    document.getElementById('ovMasc').classList.add('vis');
}

/* ── NÚCLEO SVG ── */
const R=9, NS='http://www.w3.org/2000/svg';
function hexLayout(total){
    if(total===0)return[];
    const pos=[{x:0,y:0}];const D=R*2.5;let ring=1;
    while(pos.length<total){
        const cnt=6*ring;const step=(2*Math.PI)/cnt;
        for(let i=0;i<cnt&&pos.length<total;i++){
            const a=step*i;pos.push({x:D*ring*Math.cos(a),y:D*ring*Math.sin(a)})
        }
        ring++;
    }
    return pos;
}
function dibujarNucleo(p,n){
    const g=document.getElementById('nucleoG');g.innerHTML='';
    const total=p+n;
    // Badge Z
    const zb=document.getElementById('zBadge');
    if(total>0){
        document.getElementById('zBadgeVal').textContent=p;
        zb.style.display='block';
    } else {
        zb.style.display='none';
    }
    if(total===0)return;
    const arr=[...Array(p).fill('p'),...Array(n).fill('n')];
    for(let i=arr.length-1;i>0;i--){const j=Math.floor(Math.random()*(i+1));[arr[i],arr[j]]=[arr[j],arr[i]]}
    hexLayout(total).forEach((pos,i)=>{
        const c=document.createElementNS(NS,'circle');
        c.setAttribute('cx',170+pos.x);c.setAttribute('cy',170+pos.y);c.setAttribute('r',R);
        c.setAttribute('fill',arr[i]==='p'?'#4a86f5':'#f5c540');
        c.setAttribute('stroke','rgba(0,0,0,.14)');c.setAttribute('stroke-width','1.8');
        g.appendChild(c);
    });
}
function renderDots(id,count,cls){
    const el=document.getElementById(id);if(!el)return;el.innerHTML='';
    for(let i=0;i<Math.min(count,18);i++){const d=document.createElement('span');d.className='dot '+cls;el.appendChild(d)}
}

/* ── INIT ── */
document.addEventListener('DOMContentLoaded',()=>{
    dibujarNucleo(ST.p, ST.n);
    renderDots('dotsP', ST.p, 'd-p');
    renderDots('dotsN', ST.n, 'd-n');

    /* CORRECCIÓN Timer: limpia el estado del reto ANTERIOR al cargar página nueva */
    if(ST.modoEval && ST.retoId){
        const storedId    = sessionStorage.getItem('seaea2_retoId');
        const storedTimer = parseInt(sessionStorage.getItem('seaea2_timer')||'0');

        if(storedId === ST.retoId && storedTimer > 0){
            // Mismo reto: reanudar
            iniciarTimer(storedTimer);
        } else {
            // CORRECCIÓN: nuevo reto → limpiar estado viejo y empezar timer fresco
            sessionStorage.removeItem('seaea2_timer');
            sessionStorage.setItem('seaea2_retoId', ST.retoId);
            sessionStorage.setItem('seaea2_timer',  ST.tiempo);
            iniciarTimer(ST.tiempo);
        }
    } else if(!ST.modoEval){
        // Fuera de evaluación: limpiar todo
        sessionStorage.removeItem('seaea2_retoId');
        sessionStorage.removeItem('seaea2_timer');
    }

    /* Guardar descripción del reto */
    if(ST.retoId && ST.descReto){
        sessionStorage.setItem('seaea2_desc_'+ST.retoId, ST.descReto);
    }

    /* Habilitar ? */
    if(ST.retoId) document.getElementById('btnQ').classList.remove('dis');

    /* ── Lógica mascota ── */
    <%if(tieneResult){%>
    {
        const ok   = <%=correcto%>;
        const agot = <%=intentosUsados%> >= <%=Reto.MAX_INTENTOS%>;
        const msg  = '<%=msgMascJs%>';
        const nuDesc = '<%=nuevoReto ? descRetoJs : ""%>';
        let titulo,texto,estado;
        if(ok){titulo='¡Reto superado! 🎉';texto=msg;estado='ok';}
        else if(agot){titulo='Intentos agotados 😔';texto=msg;estado='warn';}
        else{titulo='Intento fallido';texto=msg;estado='err';}
        setTimeout(()=>{
            mostrarRetro(titulo,texto,estado,
                nuDesc||null,
                <%=nuevoReto%> ? ()=>setTimeout(openModal,350) : null
            );
        },300);
    }
    <%}else if(primeraCarga){%>
    paso=0;setTimeout(()=>abrirMasc('inicial'),350);
    <%}else if(nuevoReto && modoEval){%>
    setTimeout(()=>openModal(),400);
    <%}%>
});
</script>
</body>
</html>
