package controlador;
 
import jakarta.servlet.ServletException;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import jakarta.servlet.http.HttpSession;
import java.io.IOException;
 
/**
 * MenuControlador
 * Maneja GET /menu → valida sesión y muestra menu.jsp
 */
public class MenuControlador extends HttpServlet {
 
    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
 
        HttpSession sesion = request.getSession(false);
 
        // Sin sesión activa → redirigir al login
        if (sesion == null || sesion.getAttribute("usuario") == null) {
            response.sendRedirect(request.getContextPath() + "/login");
            return;
        }
 
        // Sesión válida → mostrar menú
        request.getRequestDispatcher("/menu.jsp").forward(request, response);
    }
}