package dao;

import conexion.ConexionDB;
import modelo.Isotopo;

import java.sql.*;
import java.util.ArrayList;
import java.util.List;

/**
 * IsotopoDAO
 * Acceso a datos para la tabla isotopo.
 *
 * ElementoBase no expone id_elemento, sólo numeroAtomico.
 * Todos los métodos reciben int numeroAtomico y hacen un JOIN interno
 * para localizar los isótopos correctos.
 */
public class IsotopoDAO {

    private Connection getCon() {
        return ConexionDB.getInstancia().getConexion();
    }

    // ── Isótopos de un elemento (por número atómico Z) ────────────────────
    public List<Isotopo> obtenerPorNumeroAtomico(int numeroAtomico) {
        List<Isotopo> lista = new ArrayList<>();
        String sql = "SELECT i.* FROM isotopo i "
                   + "JOIN elemento_base e ON i.id_elemento = e.id_elemento "
                   + "WHERE e.numero_atomico = ? ORDER BY i.numero_masico";
        try {
            PreparedStatement ps = getCon().prepareStatement(sql);
            ps.setInt(1, numeroAtomico);
            ResultSet rs = ps.executeQuery();
            while (rs.next()) lista.add(mapear(rs));
        } catch (SQLException e) {
            System.err.println("IsotopoDAO.obtenerPorNumeroAtomico: " + e.getMessage());
        }
        return lista;
    }

    // ── Isótopo aleatorio de un elemento (por número atómico Z) ──────────
    public Isotopo obtenerAleatorio(int numeroAtomico) {
        String sql = "SELECT i.* FROM isotopo i "
                   + "JOIN elemento_base e ON i.id_elemento = e.id_elemento "
                   + "WHERE e.numero_atomico = ? ORDER BY RAND() LIMIT 1";
        try {
            PreparedStatement ps = getCon().prepareStatement(sql);
            ps.setInt(1, numeroAtomico);
            ResultSet rs = ps.executeQuery();
            if (rs.next()) return mapear(rs);
        } catch (SQLException e) {
            System.err.println("IsotopoDAO.obtenerAleatorio: " + e.getMessage());
        }
        return null;
    }

    // ── Isótopo por Z + número de neutrones ───────────────────────────────
    public Isotopo obtenerPorNeutrones(int numeroAtomico, int neutrones) {
        String sql = "SELECT i.* FROM isotopo i "
                   + "JOIN elemento_base e ON i.id_elemento = e.id_elemento "
                   + "WHERE e.numero_atomico = ? AND i.numero_neutrones = ? LIMIT 1";
        try {
            PreparedStatement ps = getCon().prepareStatement(sql);
            ps.setInt(1, numeroAtomico);
            ps.setInt(2, neutrones);
            ResultSet rs = ps.executeQuery();
            if (rs.next()) return mapear(rs);
        } catch (SQLException e) {
            System.err.println("IsotopoDAO.obtenerPorNeutrones: " + e.getMessage());
        }
        return null;
    }

    // ── Isótopo más abundante de un elemento ──────────────────────────────
    public Isotopo obtenerMasAbundante(int numeroAtomico) {
        String sql = "SELECT i.* FROM isotopo i "
                   + "JOIN elemento_base e ON i.id_elemento = e.id_elemento "
                   + "WHERE e.numero_atomico = ? ORDER BY i.abundancia DESC LIMIT 1";
        try {
            PreparedStatement ps = getCon().prepareStatement(sql);
            ps.setInt(1, numeroAtomico);
            ResultSet rs = ps.executeQuery();
            if (rs.next()) return mapear(rs);
        } catch (SQLException e) {
            System.err.println("IsotopoDAO.obtenerMasAbundante: " + e.getMessage());
        }
        return null;
    }

    // ── Por id_isotopo directo ─────────────────────────────────────────────
    public Isotopo obtenerPorId(int idIsotopo) {
        String sql = "SELECT * FROM isotopo WHERE id_isotopo = ?";
        try {
            PreparedStatement ps = getCon().prepareStatement(sql);
            ps.setInt(1, idIsotopo);
            ResultSet rs = ps.executeQuery();
            if (rs.next()) return mapear(rs);
        } catch (SQLException e) {
            System.err.println("IsotopoDAO.obtenerPorId: " + e.getMessage());
        }
        return null;
    }

    // ── Mapper ────────────────────────────────────────────────────────────
    private Isotopo mapear(ResultSet rs) throws SQLException {
        Isotopo i = new Isotopo();
        i.setIdIsotopo(rs.getInt("id_isotopo"));
        i.setIdElemento(rs.getInt("id_elemento"));
        i.setNumeroMasico(rs.getInt("numero_masico"));
        i.setNumeroNeutrones(rs.getInt("numero_neutrones"));
        i.setMasaIsotopica(rs.getDouble("masa_isotopica"));
        i.setAbundancia(rs.getDouble("abundancia"));
        i.setEstable(rs.getBoolean("es_estable"));
        i.setNombreIsotopo(rs.getString("nombre_isotopo"));
        i.setNotacion(rs.getString("notacion"));
        return i;
    }
}
