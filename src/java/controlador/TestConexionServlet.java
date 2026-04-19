package controlador;
 
import conexion.ConexionDB;
import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import java.io.IOException;
import java.io.PrintWriter;
import java.sql.Connection;    // ← java.sql, NO com.sun ni com.mysql
import java.sql.ResultSet;     // ← java.sql
import java.sql.Statement;     // ← java.sql, NO com.mysql.cj.xdevapi
 
/**
 * TestConexionServlet
 * Servlet de diagnóstico para verificar la conexión a la BD.
 * Acceder a: http://localhost:8080/SEAEA/testConexion
 * ⚠ Eliminar o proteger antes de producción.
 */
@WebServlet("/testConexion")
public class TestConexionServlet extends HttpServlet {
 
    @Override
    protected void doGet(HttpServletRequest req, HttpServletResponse resp)
            throws ServletException, IOException {
 
        resp.setContentType("text/html;charset=UTF-8");
        PrintWriter out = resp.getWriter();
 
        out.println("<!DOCTYPE html><html><head>");
        out.println("<meta charset='UTF-8'>");
        out.println("<title>Test Conexión – SEAEA</title>");
        out.println("<style>");
        out.println("body{font-family:monospace;padding:30px;background:#f0f4ff;}");
        out.println("h2{color:#2d3a5c;}");
        out.println(".ok{color:#2a7a44;font-weight:bold;}");
        out.println(".err{color:#d44f4f;font-weight:bold;}");
        out.println(".box{background:#fff;border:2px solid #c8d8f0;border-radius:12px;");
        out.println("     padding:20px;margin:10px 0;box-shadow:0 4px 12px rgba(0,0,0,.08);}");
        out.println("table{border-collapse:collapse;width:100%;}");
        out.println("td,th{border:1px solid #c8d8f0;padding:6px 12px;text-align:left;}");
        out.println("th{background:#eef4ff;}");
        out.println("</style></head><body>");
        out.println("<h2>🔬 SEAEA – Diagnóstico de Conexión a Base de Datos</h2>");
 
        // ── 1. Obtener conexión ──────────────────────────────────
        out.println("<div class='box'><b>1. Conexión al Singleton</b><br>");
 
        // java.sql.Connection — tipo correcto para JDBC
        Connection con = ConexionDB.getInstancia().getConexion();
 
        try {
            if (con != null && !con.isClosed()) {
                out.println("<span class='ok'>✅ Conexión obtenida correctamente.</span>");
            } else {
                out.println("<span class='err'>❌ La conexión es null o está cerrada.</span>");
                out.println("</div></body></html>");
                return;
            }
        } catch (Exception e) {
            out.println("<span class='err'>❌ Error al verificar conexión: "
                + e.getMessage() + "</span>");
            out.println("</div></body></html>");
            return;
        }
        out.println("</div>");
 
        // ── 2. Verificar tablas ──────────────────────────────────
        out.println("<div class='box'><b>2. Verificación de tablas</b><br><br>");
        String[] tablas = {
            "usuario", "elemento_base", "escenario",
            "reto", "puntaje_reto", "progreso_escenario"
        };
        for (String tabla : tablas) {
            try {
                // java.sql.Statement
                Statement st = con.createStatement();
                // java.sql.ResultSet
                ResultSet rs = st.executeQuery(
                    "SELECT COUNT(*) AS total FROM " + tabla);
                if (rs.next()) {
                    int total = rs.getInt("total");
                    out.println("<span class='ok'>✅ " + tabla
                        + "</span> → " + total + " registro(s)<br>");
                }
                rs.close();
                st.close();
            } catch (Exception e) {
                out.println("<span class='err'>❌ " + tabla
                    + " → " + e.getMessage() + "</span><br>");
            }
        }
        out.println("</div>");
 
        // ── 3. Primeros 5 elementos de la Tabla Periódica ───────
        out.println("<div class='box'><b>3. Primeros 5 elementos de la "
            + "Tabla Periódica</b><br><br>");
        try {
            Statement st = con.createStatement();
            ResultSet rs = st.executeQuery(
                "SELECT nombre, simbolo, numero_atomico, masa_atomica "
                + "FROM elemento_base ORDER BY numero_atomico LIMIT 5");
 
            out.println("<table><tr>"
                + "<th>Nombre</th><th>Símbolo</th>"
                + "<th>Z</th><th>Masa Atómica</th>"
                + "</tr>");
 
            while (rs.next()) {
                out.println("<tr>"
                    + "<td>" + rs.getString("nombre")       + "</td>"
                    + "<td><b>" + rs.getString("simbolo")   + "</b></td>"
                    + "<td>" + rs.getInt("numero_atomico")  + "</td>"
                    + "<td>" + rs.getFloat("masa_atomica")  + "</td>"
                    + "</tr>");
            }
            out.println("</table>");
            rs.close();
            st.close();
        } catch (Exception e) {
            out.println("<span class='err'>❌ " + e.getMessage() + "</span>");
        }
        out.println("</div>");
 
        // ── 4. Escenarios registrados ────────────────────────────
        out.println("<div class='box'><b>4. Escenarios registrados</b><br><br>");
        try {
            Statement st = con.createStatement();
            ResultSet rs = st.executeQuery(
                "SELECT numero_escenario, nombre "
                + "FROM escenario ORDER BY numero_escenario");
 
            out.println("<table><tr><th>#</th><th>Nombre</th></tr>");
            while (rs.next()) {
                out.println("<tr>"
                    + "<td>" + rs.getInt("numero_escenario") + "</td>"
                    + "<td>" + rs.getString("nombre")        + "</td>"
                    + "</tr>");
            }
            out.println("</table>");
            rs.close();
            st.close();
        } catch (Exception e) {
            out.println("<span class='err'>❌ " + e.getMessage() + "</span>");
        }
        out.println("</div>");
 
        // ── 5. Links de navegación ────────────────────────────────
        out.println("<div class='box'><b>5. Navegación rápida</b><br><br>");
        out.println("<a href='login.jsp'>→ Ir al Login</a> &nbsp;|&nbsp;");
        out.println("<a href='escenario1?accion=cargar'>"
            + "→ Ir directo al Escenario 1</a>");
        out.println("</div>");
 
        out.println("</body></html>");
    }
}
 