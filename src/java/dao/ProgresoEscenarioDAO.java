package dao;

import conexion.ConexionDB;
import java.sql.*;

/**
 * ProgresoEscenarioDAO
 * Persiste y consulta el progreso de cada usuario por escenario.
 */
public class ProgresoEscenarioDAO {

    private Connection getCon() {
        return ConexionDB.getInstancia().getConexion();
    }

    // ─── Obtener porcentaje de aprendizaje ────────────────────────
    /**
     * Devuelve el porcentaje actual de un usuario en un escenario. (RF-117)
     */
    public float obtenerPorcentaje(int idUsuario, int idEscenario) {
        String sql = "SELECT porcentaje_aprendizaje FROM progreso_escenario "
                   + "WHERE id_usuario = ? AND id_escenario = ?";
        try {
            PreparedStatement ps = getCon().prepareStatement(sql);
            ps.setInt(1, idUsuario);
            ps.setInt(2, idEscenario);
            ResultSet rs = ps.executeQuery();
            if (rs.next()) return rs.getFloat("porcentaje_aprendizaje");
        } catch (SQLException e) {
            System.err.println("ProgresoEscenarioDAO.obtenerPorcentaje: " + e.getMessage());
        }
        return 0.0f;
    }

    // ─── Verificar si el escenario fue superado ───────────────────
    /**
     * Retorna true si el usuario ha superado el escenario (>= 80%). (RF-120)
     */
    public boolean esSuperado(int idUsuario, int idEscenario) {
        String sql = "SELECT escenario_superado FROM progreso_escenario "
                   + "WHERE id_usuario = ? AND id_escenario = ?";
        try {
            PreparedStatement ps = getCon().prepareStatement(sql);
            ps.setInt(1, idUsuario);
            ps.setInt(2, idEscenario);
            ResultSet rs = ps.executeQuery();
            if (rs.next()) return rs.getBoolean("escenario_superado");
        } catch (SQLException e) {
            System.err.println("ProgresoEscenarioDAO.esSuperado: " + e.getMessage());
        }
        return false;
    }

    // ─── Guardar / actualizar progreso (UPSERT) ───────────────────
    /**
     * Inserta o actualiza el progreso del usuario en el escenario. (RF-116)
     */
    public boolean guardar(int idUsuario, int idEscenario, float porcentaje) {
        String sql = "INSERT INTO progreso_escenario "
                   + "(id_usuario, id_escenario, porcentaje_aprendizaje, escenario_superado) "
                   + "VALUES (?, ?, ?, ?) "
                   + "ON DUPLICATE KEY UPDATE "
                   + "porcentaje_aprendizaje = VALUES(porcentaje_aprendizaje), "
                   + "escenario_superado     = VALUES(escenario_superado)";
        try {
            PreparedStatement ps = getCon().prepareStatement(sql);
            ps.setInt(1, idUsuario);
            ps.setInt(2, idEscenario);
            ps.setFloat(3, porcentaje);
            ps.setBoolean(4, porcentaje >= 80.0f);
            return ps.executeUpdate() > 0;
        } catch (SQLException e) {
            System.err.println("ProgresoEscenarioDAO.guardar: " + e.getMessage());
        }
        return false;
    }
}
