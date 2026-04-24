<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%@ page import="modelo.ElementoBase, modelo.Reto" %>
<%
    // ── Datos del átomo ──────────────────────────────────────────────────────
    int     protones      = request.getAttribute("protones")      != null ? (int)request.getAttribute("protones")      : 0;
    int     neutrones     = request.getAttribute("neutrones")     != null ? (int)request.getAttribute("neutrones")     : 0;
    int     electrones    = request.getAttribute("electrones")    != null ? (int)request.getAttribute("electrones")    : 0;
    int     masico        = request.getAttribute("numeroMasico")  != null ? (int)request.getAttribute("numeroMasico")  : 0;
    int     cargaNeta     = request.getAttribute("cargaNeta")     != null ? (int)request.getAttribute("cargaNeta")     : 0;
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

    // Primera carga: no hay resultado, no hay modo eval, no hay nuevo reto
    boolean primeraCarga  = !modoEval && !tieneResult && !nuevoReto && msgMasc.contains("guiaMascota") == false
                            && request.getAttribute("mensajeMascota") != null
                            && !((String)request.getAttribute("mensajeMascota")).isEmpty()
                            && !modoEval;
    // Simplificado: primeraCarga = llegamos aquí desde "cargar" (no hay modo eval ni resultado)
    primeraCarga = !modoEval && !tieneResult && !nuevoReto
                   && request.getAttribute("mensajeMascota") != null;

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
<title>Arma tu Átomo – SEAEA</title>
<link href="https://fonts.googleapis.com/css2?family=Baloo+2:wght@700;800;900&family=Nunito:wght@400;600;700;800&display=swap" rel="stylesheet">
<style>
:root{
    --bg:#dde4f5;--panel:#f4f7ff;--border:#c5d2ec;
    --blue:#4a86f5;--blue-d:#1e56d0;
    --yellow:#f5c540;--yellow-d:#b89000;
    --red:#f46a6a;--red-d:#c43a3a;
    --green:#4ec87a;--green-d:#2a8a4e;
    --proton:#4a86f5;--neutron:#f5c540;--electron:#f470b0;
    --ft:'Baloo 2',cursive;--fb:'Nunito',sans-serif;
}
*,*::before,*::after{box-sizing:border-box;margin:0;padding:0}
body{background:var(--bg);font-family:var(--fb);min-height:100vh;
    display:flex;align-items:center;justify-content:center;padding:10px}

/* ── WRAPPER ── */
.sim{background:var(--panel);border:3px solid var(--border);border-radius:28px;
    box-shadow:0 8px 32px rgba(40,70,160,.12);width:100%;max-width:980px;
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
.titulo{flex:1;text-align:center;font-family:var(--ft);font-size:28px;font-weight:900;
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

/* ── GRID CENTRAL ── */
.body-grid{display:grid;grid-template-columns:1fr 360px;gap:12px;align-items:start}
.col-left{display:flex;flex-direction:column;gap:10px}

/* Carta elemento */
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

/* ── CONTROLES mejorados ── */
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

/* Columna derecha */
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
.atomo-svg{width:310px;height:310px;overflow:visible}

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

/* Imagen real de la mascota */
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

/* Caja de nuevo reto dentro de retroalimentación */
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
</style>
</head>
<body>
<form id="frm" method="post" action="<%= request.getContextPath() %>/escenario1">
    <input type="hidden" name="accion"    id="hdnA" value="">
    <input type="hidden" name="particula" id="hdnP" value="">
</form>

<!-- ══ OVERLAY MASCOTA ════════════════════════════════════════════════════ -->
<div class="ov-bg" id="ovMasc">
  <div class="masc-card">
    <img id="mascImg" src="data:image/png;base64,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w66dZqKYxTXMf1aj+bbQb926D+A9qp+bbQb926D+A9q3DCYUdhb+GFu/ar8yfq1D82eg37t0H8B7U/NnoN+7dB/Ae1beidhb+GPod/1X5k/Vp/5s9Bv3boP4D2p+bPQb926D+A9q29E7C38MfRE6/VfmT9WMsej1jsrCy02miogd/AQNYXffgZPrWVVAqq+MOeuuquc1Tl5REVlBQrvaLZdqfi9zoKash/Zmia4A84yFNXpVqpiea1NVVM5pnDUT3NtCHOLvo3QDP+wvJ7m2g4/+G6D2a3AIVn2Nvo6e/aj45+rT/wA22g/7t0H8Cr+bbQf926D2a21FPYW+ie/6j45+rUfzbaD/ALt0H8Cr+bXQf926D2a21E7C30J1+o+Ofq1L822hH7t0Hs1Jt+gmh9BUCem0dt7JRtD+BBLTzgnOPUtkROyojlClWt1Exjfn6gxuCIhK05OeZ3hERSgREQEREBERAREQEREBERAREQEREBERAREQEREBERAREQEREBERBGkdPHWRluXxSDVcP2DyHtUkKoUaiMzJH08wLy0gtk/aB5/OFAkIiKQREQW6uDh49USPjIOQ5p2gryyYwwsFY6NrydUFu5xUheZI2St1JGhzTvBUAqhRyySnp9WmZwuPqte/k5gSvVLNw0WvwckZzgteMEFBdREUgiIgIiICIvL5GMcxrnBpecNB35QelZqamKnc1shOs44DGjLifMF4fJVmfUjiEcbT4UjjnP3Af1V5sLGzOm1W8K79bG1QLclI2WqE0j3ODdrIz9Vp5/OVfCqFVB5REUgiK1V1DKaEyv28jWje48wQeKioc2oigjaHPcdY53Bo3n+akDavELXajZJY2slc3bjk8y9oCIiAiIgIiICIiDX754zZ6AfEVGUm++NGegHxFRl00eFhV4pSrH4zd6A/Es+sBY/GbvQH4ln1jc8TWBERUWEREBERAREQEREBERAREQEREBERAREQEREBERAREQEREBERAREQEREBERAREQEREBERAREQEREBERAREQEREBERAREQEREBERAREQEREBERAREQEREBERBUK3Mx0kL2MkMbnDAcN4VwKqgR6N87oiKhmrIw6pxuPnCvKzWxOlY3UlfG9py1w3Z845Qq07pOCAqODZLyhp2H7kF1ERSCIiAvMsbJYzHI0Oad4K9IgsQ07IMiN0hadzXOLmj7sqkJrmzNZK2B0X7Tcg9SlFAoEOaqlikLeJVDxyObqkH+auT1HAuDeBmkyM5jbrBSCvIUiy6Z/ANkZTyuJ/VIAd68pBLUSROJgMD8ZYHuB1vvwpCoQoEeBlUJC+oljII+qxuwde1eoaSmildKyIa7jkuO0/zV9EHlERSCIiAiIdjScE45gg8zSNiidI/6rRkqzSumni4SaPgsnLBjaByZ8680jp5g5841GOHgxn6w858/mUwKB5REUgiIgIiICIiAiIg1+++NGegHxFRlJvnjNnoB8RUZdNHhYVeKUqx+M3egPxLPrAWPxm70B+JZ9Y3PE1gREVFhERAREQEREBERAREQEREBERAREQEREBERAREQEREBERAREQEREBERAREQEREBERAREQEREBERAREQEREBERAREQEREBERAREQEREBERAREQEREBERAREQEREFXKxU07J2gPyC05a5uxzTzgqQhUZQivqG0wjbUSDLjjXxgZ8/MpCo8NeCx7Q5h3g8qjyNkgiYKWNjmsGCzcSPMe1SJKLxC/XjDix7Cd7XDBC9okREQEREBERAREQEREBERARUe5rGlzjgAZKs01Q6ocSyCRsWPBkcMFx8w3486C7wjNfgw9pkIyG524VilgmbMaiok1nkYaxp8Bo/qfOvdLTRQA6gJc76z3bXO+8q8gIiICIiAiIgIiICIiAiIg1++eM2egHxFRlJvvjRnoB8RUZdNHhYVeKUqx+M3egPxLPrAWPxm70B+JZ9Y3PE1gREVFhERAREQEREBERAREQEREBERAREQEREBERAREQEREBERAREQEREBERAREQEREBERAREQEREBERAREQEREBERAREQEREBERAREQEREBERAREQEREBERAREQEREBERAREQW6iCKoaGytyAcgjeD5irbWTU9MREXVLgdge7Bx9+FIXpQI1NUOkDxLBJA5gy4PGz1HcVfYWvaHMcHNO4gqrgCMHcrMNJTxSOkjiaxzht1RgdW5BewmFFbDVNlzxvWYXZLHxgbOYEL3NJVMdiKmbKOfhcf0QX8JhWZppY4muFO57ifCa0jDetG1DjT8KaeVrv2NhP4oL2EwrNNO6Vxa6mljwM5djH8ircUtVJIBJSCJnKTKCR6gglYTCiStrTKRFPHHHyDg9Z/8AM4VyopWVGrwpkwP1Q84P34Qep52QtBfn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" alt="AmazonAtom" class="m-ava-img">
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

  <div class="top">
    <span class="lbl-apz">APRENDIZAJE</span>
    <div class="pill-pct <%= porcentaje>=80?"ok":"" %>"><%= porcentaje %>%</div>
    <div class="prog-track"><div class="prog-fill" style="width:<%= porcentaje %>%"></div></div>
    <span class="titulo">ARMA TU ÁTOMO</span>
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

  <div class="body-grid">

    <!-- COLUMNA IZQUIERDA -->
    <div class="col-left">
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

      <div class="cont-panel">
        <div class="cont-fila">
          <span class="cont-lbl">Protones</span>
          <div class="dots-a" id="dotsP"></div>
          <strong class="cont-num" style="color:var(--proton)"    id="nP"><%= protones %></strong>
        </div>
        <div class="cont-fila">
          <span class="cont-lbl">Neutrones</span>
          <div class="dots-a" id="dotsN"></div>
          <strong class="cont-num" style="color:var(--yellow-d)"  id="nN"><%= neutrones %></strong>
        </div>
        <div class="cont-fila">
          <span class="cont-lbl">Electrones</span>
          <div class="dots-a" id="dotsE"></div>
          <strong class="cont-num" style="color:var(--electron)"  id="nE"><%= electrones %></strong>
        </div>
      </div>

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

    <!-- COLUMNA DERECHA -->
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
          <circle cx="155" cy="155" r="138" fill="none" stroke="#c5d2ec" stroke-width="1.7" stroke-dasharray="7 4"/>
          <circle cx="155" cy="155" r="94"  fill="none" stroke="#c5d2ec" stroke-width="1.7" stroke-dasharray="7 4"/>
          <circle cx="155" cy="155" r="50"  fill="none" stroke="#beccde" stroke-width="1.4" stroke-dasharray="5 4"/>
          <g id="nucleoG"></g>
          <g id="electronG"></g>
        </svg>
      </div>
    </div>
  </div>

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
    e:        <%=electrones%>,
    carga:    <%=cargaNeta%>,
    modoEval: <%=modoEval%>,
    tiempo:   <%=temporizador%>,
    intentos: <%=intentosUsados%>,
    maxInt:   <%=Reto.MAX_INTENTOS%>,
    retoId:   '<%=retoId%>',
    descReto: '<%=descRetoJs%>'
};

function enviar(a,p){document.getElementById('hdnA').value=a;document.getElementById('hdnP').value=p;document.getElementById('frm').submit()}
function confirmarReiniciar(){if(confirm('¿Reiniciar? Se perderá el progreso.'))enviar('reiniciar','')}
function confirmarVolver(){if(confirm('¿Volver al menú? Se perderá el progreso.'))enviar('volver','')}

/* ── TIMER ── */
let timerSeg=null,timerInvl=null;
function iniciarTimer(segs){
    if(timerInvl)clearInterval(timerInvl);
    timerSeg=segs;
    timerInvl=setInterval(()=>{
        timerSeg--;
        sessionStorage.setItem('seaea_timer',timerSeg);
        const txt=timerSeg>0?timerSeg+'s':'¡Tiempo!';
        const h=document.getElementById('hudTimer');
        const m=document.getElementById('modTimer');
        if(h){h.textContent=txt;h.className='hud-t'+(timerSeg>20?' ok':'')}
        if(m)m.textContent=txt;
        if(timerSeg<=0){
            clearInterval(timerInvl);timerInvl=null;
            sessionStorage.removeItem('seaea_timer');
            sessionStorage.removeItem('seaea_retoId');
            setTimeout(()=>enviar('comprobar',''),800);
        }
    },1000);
}

/* ── MODAL RETO ── */
function openModal(){
    if(document.getElementById('btnQ').classList.contains('dis'))return;
    const saved=sessionStorage.getItem('seaea_desc_'+ST.retoId);
    if(saved)document.getElementById('modDesc').textContent=saved;
    document.getElementById('modInt').textContent=ST.intentos;
    document.getElementById('modReto').classList.add('show');
}
function closeModal(){document.getElementById('modReto').classList.remove('show')}

/* ── MASCOTA ── */
const GUIA=[
    {t:'¡Bienvenido a Arma tu Átomo!',
     m:'Hola, soy AmazonAtom 🦁\nEn este simulador construirás átomos como la naturaleza.\n¡Empecemos!',btn:'Siguiente →'},
    {t:'Las partículas subatómicas',
     m:'⚛️ Tres tipos de partículas:\n🔵 Protones → carga positiva, definen el elemento (Z)\n🟡 Neutrones → sin carga, estabilizan el núcleo\n🩷 Electrones → carga negativa, orbitan el núcleo',btn:'Siguiente →'},
    {t:'Cómo usar los controles',
     m:'🟢 Botón + → agrega una partícula\n🔴 Botón − → quita una partícula\n\nEl átomo se actualiza en tiempo real.',btn:'Siguiente →'},
    {t:'Carga neta y la barra',
     m:'⚡ Carga neta = protones − electrones\n• Iguales → Neutro\n• Más protones → Catión (+)\n• Más electrones → Anión (−)',btn:'Siguiente →'},
    {t:'¡Listo para evaluarte!',
     m:'🏆 Presiona INICIAR EVALUACIÓN.\nRetos de 90 segundos con 3 intentos cada uno.\nNecesitas ≥ 80% para superar el escenario.',btn:'¡Entendido!'}
];

let paso=0,mGuia='inicial',afterCb=null;

function abrirMasc(modo){
    mGuia=modo;renderMasc();
    document.getElementById('ovMasc').classList.add('vis');
}
function cerrarMasc(){
    document.getElementById('ovMasc').classList.remove('vis');
    if(afterCb){const f=afterCb;afterCb=null;f()}
}
function mascAccion(){
    if(mGuia==='inicial'){if(paso<GUIA.length-1){paso++;renderMasc()}else cerrarMasc()}
    else cerrarMasc();
}
function renderMasc(){
    // Ajustar tamaño de imagen según modo
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

/**
 * Muestra retroalimentación con badge correcto/incorrecto,
 * mensaje específico y opcionalmente la descripción del nuevo reto.
 */
function mostrarRetro(titulo,texto,estado,nuevoDesc,cb){
    mGuia='retro';afterCb=cb||null;
    document.getElementById('mTit').textContent=titulo;
    document.getElementById('mTxt').textContent=texto;
    document.getElementById('mBtnP').textContent='Entendido';
    document.getElementById('mPasos').innerHTML='';
    // Ajustar imagen pequeña para retroalimentación
    document.getElementById('mascImg').className='m-ava-img sm';

    const badge=document.getElementById('mBadge');
    if(estado==='ok') {badge.className='badge b-ok'; badge.textContent='✅ ¡Correcto!'; badge.style.display='inline-block'}
    if(estado==='err'){badge.className='badge b-err';badge.textContent='❌ Incorrecto'; badge.style.display='inline-block'}
    if(estado==='warn'){badge.className='badge b-warn';badge.textContent='⏱ Intentos agotados';badge.style.display='inline-block'}

    if(nuevoDesc){
        document.getElementById('mNuevoRetoDesc').textContent=nuevoDesc;
        document.getElementById('mNuevoReto').style.display='block';
    }
    document.getElementById('ovMasc').classList.add('vis');
}

/* ── ÁTOMO ── */
const R=8,NS='http://www.w3.org/2000/svg';
function hexLayout(total){
    if(total===0)return[];
    const pos=[{x:0,y:0}];const D=R*2.6;let ring=1;
    while(pos.length<total){
        const cnt=6*ring;const step=(2*Math.PI)/cnt;
        for(let i=0;i<cnt&&pos.length<total;i++){const a=step*i;pos.push({x:D*ring*Math.cos(a),y:D*ring*Math.sin(a)})}
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
        c.setAttribute('cx',155+pos.x);c.setAttribute('cy',155+pos.y);c.setAttribute('r',R);
        c.setAttribute('fill',arr[i]==='p'?'#4a86f5':'#f5c540');
        c.setAttribute('stroke','rgba(0,0,0,.12)');c.setAttribute('stroke-width','1.5');
        g.appendChild(c);
    });
}
function dibujarElectrones(e){
    const g=document.getElementById('electronG');g.innerHTML='';if(e===0)return;
    const orbs=[{r:50,max:2},{r:94,max:8},{r:138,max:18}];let rest=e;
    orbs.forEach(o=>{
        if(rest<=0)return;const en=Math.min(rest,o.max);rest-=en;const step=(2*Math.PI)/en;
        for(let i=0;i<en;i++){
            const a=step*i-Math.PI/2;const c=document.createElementNS(NS,'circle');
            c.setAttribute('cx',155+o.r*Math.cos(a));c.setAttribute('cy',155+o.r*Math.sin(a));
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
    dibujarElectrones(ST.e);
    renderDots('dotsP',ST.p,'d-p');
    renderDots('dotsN',ST.n,'d-n');
    renderDots('dotsE',ST.e,'d-e');
    document.getElementById('cMk').style.left=(50+Math.max(-8,Math.min(8,ST.carga))*6.25)+'%';

    /* Timer */
    if(ST.modoEval && ST.retoId){
        const storedId=sessionStorage.getItem('seaea_retoId');
        const storedTimer=parseInt(sessionStorage.getItem('seaea_timer')||'0');
        if(storedId===ST.retoId && storedTimer>0){
            iniciarTimer(storedTimer);
        } else {
            sessionStorage.setItem('seaea_retoId',ST.retoId);
            sessionStorage.setItem('seaea_timer',ST.tiempo);
            iniciarTimer(ST.tiempo);
        }
    }

    /* Guardar descripción del reto */
    if(ST.retoId && ST.descReto){
        sessionStorage.setItem('seaea_desc_'+ST.retoId, ST.descReto);
    }

    /* Habilitar botón ? */
    if(ST.retoId) document.getElementById('btnQ').classList.remove('dis');

    /* ── LÓGICA DE MASCOTA ── */
    <% if (tieneResult) { %>
    {
        const ok     = <%=correcto%>;
        const agot   = <%=intentosUsados%> >= <%=Reto.MAX_INTENTOS%>;
        const msg    = '<%=msgMascJs%>';
        const nuDesc = '<%=nuevoReto ? descRetoJs : ""%>';

        let titulo, texto, estado;
        if(ok){
            titulo = '¡Reto superado! 🎉';
            texto  = msg;
            estado = 'ok';
        } else if(agot){
            titulo = 'Intentos agotados 😔';
            texto  = msg;
            estado = 'warn';
        } else {
            titulo = 'Intento fallido';
            texto  = msg;
            estado = 'err';
        }

        setTimeout(()=>{
            mostrarRetro(titulo, texto, estado,
                nuDesc || null,
                <%=nuevoReto%> ? ()=>setTimeout(openModal,350) : null
            );
        },300);
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

