<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%@ page import="modelo.Usuario" %>
<%
    Object usuarioSesion = session.getAttribute("usuario");
    if (usuarioSesion != null) {
        response.sendRedirect(request.getContextPath() + "/menu");
        return;
    }
    String errorLogin = (String) request.getAttribute("errorLogin");
    if (errorLogin == null) errorLogin = "";
    String msgExito = (String) request.getAttribute("msgExito");
    if (msgExito == null) msgExito = "";
%>
<!DOCTYPE html>
<html lang="es">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>SEAEA – Iniciar Sesión</title>
    <link href="https://fonts.googleapis.com/css2?family=Baloo+2:wght@700;800;900&family=Nunito:wght@400;600;700;800;900&display=swap" rel="stylesheet">
    <style>
        :root {
            --green:  #3a7d44;
            --blue:   #4a90d9;
            --pink:   #e05c97;
            --yellow: #f5a623;
            --navy:   #1e3a5f;
            --bg:     #e8eaf0;
        }
        *, *::before, *::after { box-sizing: border-box; margin: 0; padding: 0; }

        body {
            font-family: 'Nunito', sans-serif;
            min-height: 100vh;
            display: flex;
            background: var(--bg);
            overflow: hidden;
        }

        /* ── Panel izquierdo decorativo ── */
        .side-panel {
            width: 420px;
            flex-shrink: 0;
            background: linear-gradient(160deg, #1a3a2a 0%, #1e3a5f 55%, #2d1b5e 100%);
            display: flex;
            flex-direction: column;
            align-items: center;
            justify-content: center;
            padding: 48px 40px;
            position: relative;
            overflow: hidden;
        }
        /* Burbujas decorativas */
        .side-panel::before {
            content: '';
            position: absolute; top: -80px; right: -80px;
            width: 300px; height: 300px; border-radius: 50%;
            background: rgba(74,144,217,.1);
        }
        .side-panel::after {
            content: '';
            position: absolute; bottom: -100px; left: -60px;
            width: 350px; height: 350px; border-radius: 50%;
            background: rgba(58,125,68,.1);
        }
        /* Partículas flotantes */
        .sp { position:absolute; border-radius:50%; animation: spFloat 7s ease-in-out infinite; }
        .sp1{ width:14px;height:14px;background:var(--blue); opacity:.35; top:18%;left:12%; animation-delay:0s;   }
        .sp2{ width:9px; height:9px; background:var(--pink); opacity:.3;  top:65%;left:78%; animation-delay:2s;   }
        .sp3{ width:11px;height:11px;background:var(--yellow);opacity:.3; top:42%;left:85%; animation-delay:4s;   }
        .sp4{ width:7px; height:7px; background:#4cdd7a;     opacity:.35; top:80%;left:20%; animation-delay:1s;   }
        .sp5{ width:10px;height:10px;background:var(--pink); opacity:.25; top:28%;left:60%; animation-delay:3s;   }
        @keyframes spFloat {
            0%,100%{ transform:translateY(0) scale(1); }
            50%    { transform:translateY(-14px) scale(1.1); }
        }

        /* Átomo SVG decorativo */
        .atom-deco { margin-bottom: 28px; z-index:1; animation: atomSpin 18s linear infinite; }
        @keyframes atomSpin { from{transform:rotate(0deg);} to{transform:rotate(360deg);} }

        .side-logo {
            font-family: 'Baloo 2', cursive;
            font-size: 3.2rem; font-weight: 900;
            background: linear-gradient(135deg, #4cdd7a, #7dd3fc);
            -webkit-background-clip: text; -webkit-text-fill-color: transparent;
            background-clip: text;
            letter-spacing: -1px; z-index:1; margin-bottom: 6px;
        }
        .side-subtitle {
            font-size: .88rem; font-weight: 700;
            color: rgba(255,255,255,.55);
            text-align: center; line-height: 1.5;
            z-index:1; margin-bottom: 36px;
        }

        /* Chips de escenarios */
        .side-chips { display:flex; flex-wrap:wrap; gap:8px; justify-content:center; z-index:1; }
        .chip {
            background: rgba(255,255,255,.1);
            border: 1px solid rgba(255,255,255,.18);
            color: rgba(255,255,255,.75);
            font-size: .73rem; font-weight: 700;
            padding: 5px 12px; border-radius: 20px;
            backdrop-filter: blur(4px);
        }

        .side-mascota { font-size: 3rem; z-index:1; margin-bottom: 16px; }

        /* ── Panel derecho (formulario) ── */
        .form-panel {
            flex: 1;
            display: flex;
            align-items: center;
            justify-content: center;
            padding: 40px 32px;
            overflow-y: auto;
        }

        .form-card {
            background: #fff;
            border-radius: 24px;
            padding: 44px 44px 36px;
            width: 100%;
            max-width: 420px;
            box-shadow: 0 8px 40px rgba(30,58,95,.12);
        }

        .form-header { text-align: center; margin-bottom: 28px; }
        .form-title {
            font-family: 'Baloo 2', cursive;
            font-size: 1.7rem; font-weight: 900;
            color: var(--navy); margin-bottom: 4px;
        }
        .form-subtitle { font-size: .85rem; color: #8899bb; font-weight: 600; }

        .campo { margin-bottom: 18px; }
        label { display:block; font-size:.82rem; font-weight:800; color:#4a5568; margin-bottom:7px; letter-spacing:.3px; }

        .input-wrap { position: relative; }
        .input-icon {
            position: absolute; left: 14px; top: 50%; transform: translateY(-50%);
            font-size: 1rem; pointer-events: none;
        }
        input[type="email"], input[type="password"], input[type="text"] {
            width: 100%;
            padding: 12px 16px 12px 40px;
            border: 2px solid #dde6f4;
            border-radius: 12px;
            font-family: 'Nunito', sans-serif;
            font-size: 14px; color: #2d3a5c;
            outline: none;
            transition: border-color .2s, box-shadow .2s;
            background: #f8faff;
        }
        input:focus {
            border-color: var(--blue);
            box-shadow: 0 0 0 3px rgba(74,144,217,.15);
            background: #fff;
        }

        .btn-main {
            width: 100%; padding: 13px;
            background: linear-gradient(135deg, var(--green), var(--blue));
            color: #fff; border: none; border-radius: 14px;
            font-family: 'Nunito', sans-serif;
            font-size: 15px; font-weight: 900;
            cursor: pointer; margin-top: 6px;
            transition: filter .2s, transform .1s;
            box-shadow: 0 4px 16px rgba(74,144,217,.3);
            letter-spacing: .5px;
        }
        .btn-main:hover  { filter: brightness(1.07); }
        .btn-main:active { transform: scale(.98); }

        .error-msg {
            background: #fff0f0; border: 2px solid #f47575;
            border-radius: 10px; padding: 11px 14px;
            color: #c0392b; font-size: .85rem; font-weight: 700;
            margin-bottom: 18px; display:flex; gap:8px; align-items:flex-start;
        }
        .success-msg {
            background: #f0fff4; border: 2px solid #6fcf97;
            border-radius: 10px; padding: 11px 14px;
            color: #1a6b35; font-size: .85rem; font-weight: 700;
            margin-bottom: 18px; display:flex; gap:8px; align-items:flex-start;
        }

        .divider {
            display: flex; align-items: center; gap: 12px;
            margin: 20px 0; color: #b0b8cc; font-size: .8rem; font-weight: 700;
        }
        .divider::before, .divider::after {
            content:''; flex:1; height:1px; background:#e8ecf4;
        }

        .form-footer {
            text-align: center; margin-top: 20px;
            font-size: .85rem; color: #7788aa; font-weight: 600;
        }
        .form-footer a, .link-btn {
            color: var(--blue); font-weight: 800; text-decoration: none;
            background: none; border: none; cursor: pointer;
            font-family: 'Nunito', sans-serif; font-size: .85rem;
            transition: color .15s;
        }
        .form-footer a:hover, .link-btn:hover { color: var(--green); text-decoration: underline; }

        .forgot-row {
            text-align: right; margin-top: -10px; margin-bottom: 16px;
        }

        /* Badge "próximamente" */
        .badge-soon {
            display: inline-block;
            background: #fff8e1; color: #b07800;
            border: 1px solid #ffe082;
            font-size: .65rem; font-weight: 800;
            padding: 2px 7px; border-radius: 10px;
            vertical-align: middle; margin-left: 4px;
            text-transform: uppercase; letter-spacing: .5px;
        }

        /* Responsivo */
        @media (max-width: 780px) {
            .side-panel { display: none; }
            body { overflow-y: auto; }
        }
    </style>
</head>
<body>

<!-- ── Panel izquierdo ── -->
<div class="side-panel">
    <div class="sp sp1"></div><div class="sp sp2"></div><div class="sp sp3"></div>
    <div class="sp sp4"></div><div class="sp sp5"></div>

    <!-- Átomo animado -->
    <svg class="atom-deco" width="110" height="110" viewBox="0 0 110 110" xmlns="http://www.w3.org/2000/svg">
        <ellipse cx="55" cy="55" rx="48" ry="18" fill="none" stroke="rgba(74,144,217,.5)" stroke-width="2"/>
        <ellipse cx="55" cy="55" rx="48" ry="18" fill="none" stroke="rgba(76,221,122,.4)" stroke-width="2" transform="rotate(60 55 55)"/>
        <ellipse cx="55" cy="55" rx="48" ry="18" fill="none" stroke="rgba(224,92,151,.4)" stroke-width="2" transform="rotate(120 55 55)"/>
        <circle cx="55" cy="55" r="10" fill="#ddeeff" stroke="rgba(74,144,217,.6)" stroke-width="2"/>
        <circle cx="55" cy="55" r="5" fill="#4a90d9" opacity=".8"/>
        <circle cx="55" cy="7"  r="5" fill="#4cdd7a"/>
        <circle cx="97" cy="79" r="4" fill="#e05c97"/>
        <circle cx="13" cy="79" r="4" fill="#f5a623"/>
    </svg>

    <div class="side-logo">SEAEA</div>
    <div class="side-subtitle">Software Educativo para el<br>Aprendizaje de la Estructura Atómica</div>

    <div class="side-chips">
        <span class="chip">⚛️ Arma tu Átomo</span>
        <span class="chip">🔬 Número Atómico</span>
        <span class="chip">⚡ Iones</span>
        <span class="chip">🧬 Isótopos</span>
        <span class="chip">🔋 Config. Electrónica</span>
        <span class="chip">📊 Propiedades Periódicas</span>
    </div>
</div>

<!-- ── Panel derecho (formulario) ── -->
<div class="form-panel">
    <div class="form-card">
        <div class="form-header">
            <div style="font-size:2.6rem; margin-bottom:10px;">🦜</div>
            <div class="form-title">¡Bienvenido!</div>
            <div class="form-subtitle">Inicia sesión para continuar tu aprendizaje</div>
        </div>

        <%-- Mensaje de error --%>
        <% if (!errorLogin.isEmpty()) { %>
        <div class="error-msg">⚠️ <%= errorLogin %></div>
        <% } %>

        <%-- Mensaje de éxito (ej: cuenta creada) --%>
        <% if (!msgExito.isEmpty()) { %>
        <div class="success-msg">✅ <%= msgExito %></div>
        <% } %>

        <form method="post" action="login">
            <div class="campo">
                <label for="correo">Correo electrónico</label>
                <div class="input-wrap">
                    <span class="input-icon">📧</span>
                    <input type="email" id="correo" name="correo"
                           placeholder="tu@uniamazonia.edu.co"
                           autocomplete="email" required>
                </div>
            </div>
            <div class="campo">
                <label for="contrasena">Contraseña</label>
                <div class="input-wrap">
                    <span class="input-icon">🔒</span>
                    <input type="password" id="contrasena" name="contrasena"
                           placeholder="••••••••"
                           autocomplete="current-password" required>
                </div>
            </div>

            <div class="forgot-row">
                <span style="font-size:.82rem; color:#8899bb; font-weight:600;">
                    ¿Olvidaste tu contraseña?
                    <span class="badge-soon">Próximamente</span>
                </span>
            </div>

            <button type="submit" class="btn-main">INGRESAR →</button>
        </form>

        <div class="divider">o</div>

        <div class="form-footer">
            ¿No tienes una cuenta?
            <a href="${pageContext.request.contextPath}/registro">Crear cuenta</a>
        </div>

        <div class="form-footer" style="margin-top:10px; font-size:.75rem; color:#aab; font-weight:600;">
            Universidad de la Amazonia · Ingeniería de Sistemas
        </div>
    </div>
</div>

</body>
</html>
