package dao;

import conexion.ConexionDB;
import java.sql.*;
import java.util.ArrayList;
import java.util.List;

/**
 * PuntajeRetoDAO
 * Persiste y consulta los puntajes obtenidos en cada reto.
 */
public class PuntajeRetoDAO {

    private Connection getCon() {
        return ConexionDB.getInstancia().getConexion();
    }

    // ─── Insertar puntaje ─────────────────────────────────────────
    /**
     * Guarda el puntaje de un intento de reto. (RF-116 / CU-106)
     */
    public boolean insertar(int idReto, int intentoActual,
                            float puntaje, boolean completado) {
        String sql = "INSERT INTO puntaje_reto "
                   + "(id_reto, intento_actual, puntaje, completado) "
                   + "VALUES (?, ?, ?, ?)";
        try {
            PreparedStatement ps = getCon().prepareStatement(sql);
            ps.setInt(1, idReto);
            ps.setInt(2, intentoActual);
            ps.setFloat(3, puntaje);
            ps.setBoolean(4, completado);
            return ps.executeUpdate() > 0;
        } catch (SQLException e) {
            System.err.println("PuntajeRetoDAO.insertar: " + e.getMessage());
        }
        return false;
    }

    // ─── Obtener puntajes por usuario y escenario ─────────────────
    /**
     * Devuelve todos los puntajes de un usuario en un escenario.
     * Usado para calcular el porcentaje de aprendizaje. (RF-117)
     */
    public List<Float> obtenerPuntajesPorUsuarioEscenario(int idUsuario,
                                                           int idEscenario) {
        String sql = "SELECT pr.puntaje FROM puntaje_reto pr "
                   + "JOIN reto r ON pr.id_reto = r.id_reto "
                   + "WHERE r.id_usuario = ? AND r.id_escenario = ? "
                   + "ORDER BY pr.fecha_registro ASC";
        List<Float> puntajes = new ArrayList<>();
        try {
            PreparedStatement ps = getCon().prepareStatement(sql);
            ps.setInt(1, idUsuario);
            ps.setInt(2, idEscenario);
            ResultSet rs = ps.executeQuery();
            while (rs.next()) puntajes.add(rs.getFloat("puntaje"));
        } catch (SQLException e) {
            System.err.println("PuntajeRetoDAO.obtenerPuntajes: " + e.getMessage());
        }
        return puntajes;
    }

    // ─── Calcular porcentaje desde BD (Stored Procedure) ─────────
    /**
     * Llama al SP para calcular y persistir el porcentaje. (CU-106)
     * @return porcentaje calculado (0.0 - 100.0).
     */
    public float calcularPorcentajeAprendizaje(int idUsuario, int idEscenario) {
        String sql = "CALL sp_calcular_porcentaje_aprendizaje(?, ?, ?)";
        try {
            CallableStatement cs = getCon().prepareCall(sql);
            cs.setInt(1, idUsuario);
            cs.setInt(2, idEscenario);
            cs.registerOutParameter(3, Types.DECIMAL);
            cs.execute();
            return cs.getFloat(3);
        } catch (SQLException e) {
            System.err.println("PuntajeRetoDAO.calcularPorcentaje: " + e.getMessage());
        }
        return 0.0f;
    }
}
