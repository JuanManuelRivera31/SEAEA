package dao;

import conexion.ConexionDB;
import modelo.Usuario;
import java.sql.*;

/**
 * UsuarioDAO
 * Gestiona la autenticación y consulta de usuarios en la BD.
 */
public class UsuarioDAO {

    private Connection getCon() {
        return ConexionDB.getInstancia().getConexion();
    }

    // ─── Login ────────────────────────────────────────────────────
    /**
     * Verifica las credenciales del estudiante.
     * @return Usuario autenticado, o null si las credenciales son incorrectas.
     */
    public Usuario login(String correo, String contrasena) {
        String sql = "SELECT id_usuario, nombre, correo, contrasena "
                   + "FROM usuario WHERE correo = ? AND contrasena = ?";
        try {
            PreparedStatement ps = getCon().prepareStatement(sql);
            ps.setString(1, correo);
            ps.setString(2, contrasena);
            ResultSet rs = ps.executeQuery();
            if (rs.next()) return mapear(rs);
        } catch (SQLException e) {
            System.err.println("UsuarioDAO.login: " + e.getMessage());
        }
        return null;
    }

    // ─── Registrar usuario ────────────────────────────────────────
    public boolean registrar(Usuario usuario) {
        String sql = "INSERT INTO usuario (nombre, correo, contrasena) VALUES (?, ?, ?)";
        try {
            PreparedStatement ps = getCon().prepareStatement(sql);
            ps.setString(1, usuario.getNombre());
            ps.setString(2, usuario.getCorreo());
            ps.setString(3, usuario.getContrasena());
            return ps.executeUpdate() > 0;
        } catch (SQLException e) {
            System.err.println("UsuarioDAO.registrar: " + e.getMessage());
        }
        return false;
    }

    // ─── Obtener por ID ───────────────────────────────────────────
    public Usuario obtenerPorId(int idUsuario) {
        String sql = "SELECT id_usuario, nombre, correo, contrasena "
                   + "FROM usuario WHERE id_usuario = ?";
        try {
            PreparedStatement ps = getCon().prepareStatement(sql);
            ps.setInt(1, idUsuario);
            ResultSet rs = ps.executeQuery();
            if (rs.next()) return mapear(rs);
        } catch (SQLException e) {
            System.err.println("UsuarioDAO.obtenerPorId: " + e.getMessage());
        }
        return null;
    }

    // ─── Mapeo ────────────────────────────────────────────────────
    private Usuario mapear(ResultSet rs) throws SQLException {
        Usuario u = new Usuario();
        u.setIdUsuario(rs.getInt("id_usuario"));
        u.setNombre(rs.getString("nombre"));
        u.setCorreo(rs.getString("correo"));
        u.setContrasena(rs.getString("contrasena"));
        return u;
    }
}