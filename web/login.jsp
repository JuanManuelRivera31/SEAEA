<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%@ page import="modelo.Usuario" %>
<%
    // Si ya hay sesión activa, redirigir directamente al escenario 1
    Object usuarioSesion = session.getAttribute("usuario");
    if (usuarioSesion != null) {
        response.sendRedirect(request.getContextPath() + "/menu");
        return;
    }
    // Obtener mensaje de error si viene del controlador
    String errorLogin = (String) request.getAttribute("errorLogin");
    if (errorLogin == null) errorLogin = "";
%>
<!DOCTYPE html>
<html lang="es">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>SEAEA – Iniciar Sesión</title>
    <link href="https://fonts.googleapis.com/css2?family=Baloo+2:wght@700;800&family=Nunito:wght@400;600;700;800&display=swap" rel="stylesheet">
    <style>
        *, *::before, *::after { box-sizing: border-box; margin: 0; padding: 0; }
        body {
            background: #f0f4ff;
            font-family: 'Nunito', sans-serif;
            min-height: 100vh;
            display: flex;
            align-items: center;
            justify-content: center;
            padding: 16px;
        }
        .card {
            background: #fff;
            border: 3px solid #c8d8f0;
            border-radius: 24px;
            padding: 40px 44px;
            width: 100%;
            max-width: 420px;
            box-shadow: 0 8px 32px rgba(80,120,200,.13);
            text-align: center;
        }
        .mascota { font-size: 52px; margin-bottom: 12px; }
        .logo {
            font-family: 'Baloo 2', cursive;
            font-size: 42px;
            font-weight: 800;
            color: #2d3a5c;
            margin-bottom: 4px;
        }
        .subtitulo { font-size: 13px; color: #8899bb; margin-bottom: 32px; font-weight: 600; }
        .campo { margin-bottom: 16px; text-align: left; }
        label { display: block; font-size: 13px; font-weight: 700; color: #555; margin-bottom: 6px; }
        input[type="email"], input[type="password"] {
            width: 100%;
            padding: 11px 16px;
            border: 2px solid #c8d8f0;
            border-radius: 12px;
            font-family: 'Nunito', sans-serif;
            font-size: 15px;
            outline: none;
            transition: border-color .2s;
            color: #2d3a5c;
        }
        input:focus { border-color: #3b82f6; }
        .btn-login {
            width: 100%;
            padding: 13px;
            background: #3b82f6;
            color: #fff;
            border: none;
            border-radius: 14px;
            font-family: 'Nunito', sans-serif;
            font-size: 16px;
            font-weight: 800;
            cursor: pointer;
            margin-top: 8px;
            transition: background .2s;
            box-shadow: 0 4px 0 rgba(37,99,235,.35);
        }
        .btn-login:hover { background: #2563eb; }
        .error-msg {
            background: #fff0f0;
            border: 2px solid #f47575;
            border-radius: 10px;
            padding: 10px 14px;
            color: #d44f4f;
            font-size: 13px;
            font-weight: 700;
            margin-bottom: 16px;
        }
    </style>
</head>
<body>
<div class="card">
    <div class="mascota">🦁</div>
    <div class="logo">SEAEA</div>
    <div class="subtitulo">Software Educativo – Estructura Atómica</div>

    <%-- Mostrar error solo si existe --%>
    <% if (!errorLogin.isEmpty()) { %>
    <div class="error-msg">⚠ <%= errorLogin %></div>
    <% } %>

    <%-- action apunta directamente al servlet /login --%>
    <form method="post" action="login">
        <div class="campo">
            <label for="correo">Correo electrónico</label>
            <input type="email" id="correo" name="correo"
                   placeholder="tu@correo.com"
                   autocomplete="email" required>
        </div>
        <div class="campo">
            <label for="contrasena">Contraseña</label>
            <input type="password" id="contrasena" name="contrasena"
                   placeholder="••••••••"
                   autocomplete="current-password" required>
        </div>
        <button type="submit" class="btn-login">INGRESAR</button>
    </form>
</div>
</body>
</html>
