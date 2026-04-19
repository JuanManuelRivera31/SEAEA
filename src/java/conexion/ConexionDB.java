package conexion;

import java.sql.Connection;
import java.sql.DriverManager;
import java.sql.SQLException;

/**
 * ConexionDB - Singleton robusto con reconexión automática.
 * Si MySQL no estaba activo al arrancar Tomcat, reintenta
 * la conexión cada vez que se llama getConexion().
 */
public class ConexionDB {

    private static ConexionDB instancia;
    private Connection conexion;

    // ── Ajusta estos valores según tu entorno ──────────────────
    private static final String URL      =
        "jdbc:mysql://localhost:3306/seaea_db" +
        "?useSSL=false&serverTimezone=UTC&useUnicode=true&characterEncoding=UTF-8";
    private static final String USUARIO  = "root";
    private static final String PASSWORD = "Acuario31.";
    // ──────────────────────────────────────────────────────────

    private ConexionDB() {
        conectar();
    }

    /** Intenta abrir la conexión con MySQL. */
    private void conectar() {
        try {
            Class.forName("com.mysql.cj.jdbc.Driver");
            conexion = DriverManager.getConnection(URL, USUARIO, PASSWORD);
            System.out.println("✅ Conexión exitosa a seaea_db");
        } catch (ClassNotFoundException e) {
            System.err.println("❌ Driver MySQL no encontrado: " + e.getMessage());
            conexion = null;
        } catch (SQLException e) {
            System.err.println("❌ Error conectando a MySQL: " + e.getMessage());
            System.err.println("   URL: " + URL);
            System.err.println("   Usuario: " + USUARIO);
            conexion = null;
        }
    }

    /** Obtiene la instancia única del Singleton. */
    public static synchronized ConexionDB getInstancia() {
        if (instancia == null) {
            instancia = new ConexionDB();
        }
        return instancia;
    }

    /**
     * Devuelve la conexión activa.
     * Si está null o cerrada, intenta reconectar automáticamente.
     */
    public Connection getConexion() {
        try {
            if (conexion == null || conexion.isClosed()) {
                System.out.println("⚠ Conexión perdida, reconectando...");
                conectar();
            }
        } catch (SQLException e) {
            System.err.println("❌ Error verificando conexión: " + e.getMessage());
            conectar();
        }
        return conexion;
    }

    /** Cierra la conexión de forma segura. */
    public void cerrar() {
        try {
            if (conexion != null && !conexion.isClosed()) {
                conexion.close();
                System.out.println("Conexión cerrada.");
            }
        } catch (SQLException e) {
            System.err.println("Error cerrando conexión: " + e.getMessage());
        } finally {
            conexion  = null;
            instancia = null;  // Permite reconexión desde cero
        }
    }
}

