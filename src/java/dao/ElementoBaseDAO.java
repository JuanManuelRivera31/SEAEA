package dao;

import conexion.ConexionDB;
import modelo.ElementoBase;
import java.sql.*;
import java.util.ArrayList;
import java.util.List;

/**
 * ElementoBaseDAO Gestiona el acceso a la tabla elemento_base en la base de
 * datos.
 */
public class ElementoBaseDAO {

    // ─── Obtener la conexión del Singleton ────────────────────────
    private Connection getCon() {
        return ConexionDB.getInstancia().getConexion();
    }

    // ─── Obtener elemento por número atómico (Z) ─────────────────
    /**
     * Busca un elemento por su número atómico (Z = # protones). (RF-105)
     */
    public ElementoBase obtenerPorNumeroAtomico(int numeroAtomico) {
        String sql = "SELECT nombre, simbolo, numero_atomico, masa_atomica "
                + "FROM elemento_base WHERE numero_atomico = ?";
        try {
            PreparedStatement ps = getCon().prepareStatement(sql);
            ps.setInt(1, numeroAtomico);
            ResultSet rs = ps.executeQuery();
            if (rs.next()) {
                return mapear(rs);
            }
        } catch (SQLException e) {
            System.err.println("ElementoBaseDAO.obtenerPorNumeroAtomico: " + e.getMessage());
        }
        return null;
    }

    // ─── Obtener todos los elementos ──────────────────────────────
    /**
     * Devuelve todos los elementos ordenados por número atómico.
     */
    public List<ElementoBase> obtenerTodos() {
        String sql = "SELECT nombre, simbolo, numero_atomico, masa_atomica "
                + "FROM elemento_base ORDER BY numero_atomico";
        List<ElementoBase> lista = new ArrayList<>();
        try {
            PreparedStatement ps = getCon().prepareStatement(sql);
            ResultSet rs = ps.executeQuery();
            while (rs.next()) {
                lista.add(mapear(rs));
            }
        } catch (SQLException e) {
            System.err.println("ElementoBaseDAO.obtenerTodos: " + e.getMessage());
        }
        return lista;
    }

    // ─── Obtener elemento aleatorio ───────────────────────────────
    /**
     * Devuelve un elemento aleatorio para generar el reto. (RF-111)
     */
    public ElementoBase obtenerAleatorio() {
        String sql = "SELECT nombre, simbolo, numero_atomico, masa_atomica "
                + "FROM elemento_base ORDER BY RAND() LIMIT 1";
        try {
            PreparedStatement ps = getCon().prepareStatement(sql);
            ResultSet rs = ps.executeQuery();
            if (rs.next()) {
                return mapear(rs);
            }
        } catch (SQLException e) {
            System.err.println("ElementoBaseDAO.obtenerAleatorio: " + e.getMessage());
        }
        return null;
    }
    // ─── Método de mapeo ──────────────────────────────────────────

    private ElementoBase mapear(ResultSet rs) throws SQLException {
        ElementoBase eb = new ElementoBase();
        eb.setNombre(rs.getString("nombre"));
        eb.setSimbolo(rs.getString("simbolo"));
        eb.setNumeroAtomico(rs.getInt("numero_atomico"));
        eb.setMasaAtomica(rs.getFloat("masa_atomica"));
        return eb;
    }
}

// Obtener por ID
//    public ElementoBase obtenerPorId(int idElemento) {
//        String sql = "SELECT id_elemento, nombre, simbolo, numero_atomico, masa_atomica "
//                + "FROM elemento_base WHERE id_elemento = ?";
//        try {
//            PreparedStatement ps = getCon().prepareStatement(sql);
//            ps.setInt(1, idElemento);
//            ResultSet rs = ps.executeQuery();
//            if (rs.next()) {
//                return mapear(rs);
//            }
//        } catch (SQLException e) {
//            System.err.println("ElementoBaseDAO.obtenerPorId: " + e.getMessage());
//        }
//        return null;
//    }
//
//// Modificar método mapear para incluir idElemento
//    private ElementoBase mapear(ResultSet rs) throws SQLException {
//        ElementoBase eb = new ElementoBase();
//        eb.setNumeroAtomico(rs.getInt("id_elemento"));   // NUEVO
//        eb.setNombre(rs.getString("nombre"));
//        eb.setSimbolo(rs.getString("simbolo"));
//        eb.setNumeroAtomico(rs.getInt("numero_atomico"));
//        eb.setMasaAtomica(rs.getFloat("masa_atomica"));
//        return eb;
//    }

