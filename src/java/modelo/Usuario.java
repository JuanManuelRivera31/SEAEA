package modelo;

/**
 * Usuario
 * Representa al estudiante autenticado en el sistema.
 * Corresponde a la clase Usuario del diagrama de clases.
 */
public class Usuario {

    private int    idUsuario;
    private String nombre;
    private String correo;
    private String contrasena;

    // ─── Constructores ────────────────────────────────────────────
    public Usuario() { }

    public Usuario(int idUsuario, String nombre, String correo, String contrasena) {
        this.idUsuario  = idUsuario;
        this.nombre     = nombre;
        this.correo     = correo;
        this.contrasena = contrasena;
    }

    // ─── Métodos de negocio ────────────────────────────────────────
    /** Inicia sesión: delegar al UsuarioDAO. */
    public boolean login(String correo, String contrasena) {
        return this.correo != null
            && this.correo.equals(correo)
            && this.contrasena != null
            && this.contrasena.equals(contrasena);
    }

    public void logout() {
        // La lógica de sesión HTTP se maneja en el controlador/servlet
    }

    // ─── Getters y Setters ─────────────────────────────────────────
    public int    getIdUsuario()  { return idUsuario;  }
    public String getNombre()     { return nombre;     }
    public String getCorreo()     { return correo;     }
    public String getContrasena() { return contrasena; }

    public void setIdUsuario(int idUsuario)      { this.idUsuario  = idUsuario;  }
    public void setNombre(String nombre)         { this.nombre     = nombre;     }
    public void setCorreo(String correo)         { this.correo     = correo;     }
    public void setContrasena(String contrasena) { this.contrasena = contrasena; }

    @Override
    public String toString() {
        return "Usuario{id=" + idUsuario + ", nombre=" + nombre + ", correo=" + correo + "}";
    }
}
