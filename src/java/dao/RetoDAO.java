package dao;

import conexion.ConexionDB;
import modelo.ElementoBase;
import modelo.Reto;
import java.sql.*;
import java.util.ArrayList;
import java.util.List;

/**
 * RetoDAO
 * Gestiona la persistencia de los retos de evaluación.
 */
public class RetoDAO {

    private final ElementoBaseDAO elementoDAO = new ElementoBaseDAO();

    private Connection getCon() {
        return ConexionDB.getInstancia().getConexion();
    }

    // ─── Insertar reto ────────────────────────────────────────────
    /**
     * Guarda un nuevo reto generado en la BD. (RF-111)
     * @return ID generado, o -1 si falla.
     */
    public int insertar(Reto reto) {
        String sql = "INSERT INTO reto "
                   + "(id_usuario, id_escenario, descripcion, temporizador, "
                   + " intentos, completado, id_elemento_objetivo) "
                   + "VALUES (?, ?, ?, ?, ?, ?, ?)";
        try {
            PreparedStatement ps = getCon().prepareStatement(
                    sql, Statement.RETURN_GENERATED_KEYS);
            ps.setInt(1, reto.getIdUsuario());
            ps.setInt(2, reto.getIdEscenario());
            ps.setString(3, reto.getDescripcion());
            ps.setInt(4, reto.getTemporizador());
            ps.setInt(5, reto.getIntentos());
            ps.setBoolean(6, reto.isCompletado());
            if (reto.getElementoObjetivo() != null) {
                ps.setInt(7, reto.getElementoObjetivo().getNumeroAtomico());
            } else {
                ps.setNull(7, Types.INTEGER);
            }
            ps.executeUpdate();
            ResultSet rs = ps.getGeneratedKeys();
            if (rs.next()) return rs.getInt(1);
        } catch (SQLException e) {
            System.err.println("RetoDAO.insertar: " + e.getMessage());
        }
        return -1;
    }

    // ─── Actualizar intentos y estado ─────────────────────────────
    /**
     * Actualiza los intentos usados y si fue completado. (RF-115)
     */
    public boolean actualizar(Reto reto) {
        String sql = "UPDATE reto SET intentos = ?, completado = ? "
                   + "WHERE id_reto = ?";
        try {
            PreparedStatement ps = getCon().prepareStatement(sql);
            ps.setInt(1, reto.getIntentos());
            ps.setBoolean(2, reto.isCompletado());
            ps.setInt(3, reto.getIdReto());
            return ps.executeUpdate() > 0;
        } catch (SQLException e) {
            System.err.println("RetoDAO.actualizar: " + e.getMessage());
        }
        return false;
    }

    // ─── Obtener retos por usuario y escenario ────────────────────
    /**
     * Lista todos los retos de un usuario en un escenario. (RF-117)
     */
    public List<Reto> obtenerPorUsuarioEscenario(int idUsuario, int idEscenario) {
        String sql = "SELECT id_reto, id_usuario, id_escenario, descripcion, "
                   + "temporizador, intentos, completado, id_elemento_objetivo "
                   + "FROM reto WHERE id_usuario = ? AND id_escenario = ? "
                   + "ORDER BY fecha_generacion DESC";
        List<Reto> lista = new ArrayList<>();
        try {
            PreparedStatement ps = getCon().prepareStatement(sql);
            ps.setInt(1, idUsuario);
            ps.setInt(2, idEscenario);
            ResultSet rs = ps.executeQuery();
            while (rs.next()) lista.add(mapear(rs));
        } catch (SQLException e) {
            System.err.println("RetoDAO.obtenerPorUsuarioEscenario: " + e.getMessage());
        }
        return lista;
    }

    // ─── Mapeo ────────────────────────────────────────────────────
    private Reto mapear(ResultSet rs) throws SQLException {
        Reto r = new Reto();
        r.setIdReto(rs.getInt("id_reto"));
        r.setIdUsuario(rs.getInt("id_usuario"));
        r.setIdEscenario(rs.getInt("id_escenario"));
        r.setDescripcion(rs.getString("descripcion"));
        r.setTemporizador(rs.getInt("temporizador"));
        r.setIntentos(rs.getInt("intentos"));
        r.setCompletado(rs.getBoolean("completado"));
        int idElemento = rs.getInt("id_elemento_objetivo");
        if (!rs.wasNull()) {
            r.setElementoObjetivo(elementoDAO.obtenerPorNumeroAtomico(idElemento));
        }
        return r;
    }
}

