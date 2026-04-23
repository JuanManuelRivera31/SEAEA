package modelo;

/**
 * ElementoBase
 * Representa un elemento de la Tabla Periódica.
 * Corresponde a la clase ElementoBase del diagrama de clases.
 */
public class ElementoBase {

    private String nombre;
    private String simbolo;
    private int    numeroAtomico;   // Z = # protones
    private float  masaAtomica;

    // ─── Constructores ────────────────────────────────────────────
    public ElementoBase() { }

    public ElementoBase(String nombre, String simbolo, int numeroAtomico, float masaAtomica) {
        this.nombre        = nombre;
        this.simbolo       = simbolo;
        this.numeroAtomico = numeroAtomico;
        this.masaAtomica   = masaAtomica;
    }

    // ─── Getters y Setters ─────────────────────────────────────────
//    public int getIdElemento() { return idElemento; }
//    public void setIdElemento(int idElemento) { this.idElemento = idElemento; }
    public String getNombre()       { return nombre;        }
    public String getSimbolo()      { return simbolo;       }
    public int    getNumeroAtomico(){ return numeroAtomico;  }
    public float  getMasaAtomica()  { return masaAtomica;   }

    public void setNombre(String nombre)              { this.nombre        = nombre;        }
    public void setSimbolo(String simbolo)            { this.simbolo       = simbolo;       }
    public void setNumeroAtomico(int numeroAtomico)   { this.numeroAtomico = numeroAtomico;  }
    public void setMasaAtomica(float masaAtomica)     { this.masaAtomica   = masaAtomica;   }

    @Override
    public String toString() {
        return simbolo + " (" + nombre + ", Z=" + numeroAtomico + ")";
    }
}