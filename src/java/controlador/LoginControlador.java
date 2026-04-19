package controlador;

import dao.UsuarioDAO;
import modelo.Usuario;
import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import jakarta.servlet.http.HttpSession;
import java.io.IOException;

/**
 * LoginControlador
 * Maneja GET /login  → muestra login.jsp
 * Maneja POST /login → valida credenciales y redirige
 */
@WebServlet("/login")
public class LoginControlador extends HttpServlet {

    private final UsuarioDAO usuarioDAO = new UsuarioDAO();

    // ─── GET: mostrar formulario ──────────────────────────────────
    @Override
    protected void doGet(HttpServletRequest req, HttpServletResponse resp)
            throws ServletException, IOException {
        // Si ya tiene sesión, ir directo al escenario 1
        HttpSession sesion = req.getSession(false);
        if (sesion != null && sesion.getAttribute("usuario") != null) {
            resp.sendRedirect(req.getContextPath() + "/escenario1?accion=cargar");
            return;
        }
        req.getRequestDispatcher("/login.jsp").forward(req, resp);
    }

    // ─── POST: procesar credenciales ──────────────────────────────
    @Override
    protected void doPost(HttpServletRequest req, HttpServletResponse resp)
            throws ServletException, IOException {

        req.setCharacterEncoding("UTF-8");

        String correo     = req.getParameter("correo");
        String contrasena = req.getParameter("contrasena");

        // Validación de campos vacíos
        if (correo == null || correo.trim().isEmpty()
                || contrasena == null || contrasena.trim().isEmpty()) {
            req.setAttribute("errorLogin", "Por favor completa todos los campos.");
            req.getRequestDispatcher("/login.jsp").forward(req, resp);
            return;
        }

        try {
            // Consultar usuario en BD
            Usuario usuario = usuarioDAO.login(correo.trim(), contrasena.trim());

            if (usuario != null) {
                // ✅ Credenciales correctas → crear sesión
                HttpSession sesion = req.getSession(true);
                sesion.setAttribute("usuario", usuario);
                sesion.setMaxInactiveInterval(60 * 60); // 1 hora
                // Redirigir al Escenario 1
                resp.sendRedirect(req.getContextPath() + "/escenario1?accion=cargar");
            } else {
                // ❌ Credenciales incorrectas
                req.setAttribute("errorLogin", "Correo o contraseña incorrectos.");
                req.getRequestDispatcher("/login.jsp").forward(req, resp);
            }

        } catch (Exception e) {
            // Error de BD u otro error inesperado
            System.err.println("LoginControlador.doPost ERROR: " + e.getMessage());
            e.printStackTrace();
            req.setAttribute("errorLogin",
                "Error del sistema: " + e.getMessage()
                + " — Verifica que la base de datos esté activa.");
            req.getRequestDispatcher("/login.jsp").forward(req, resp);
        }
    }
}

