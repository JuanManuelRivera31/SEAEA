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
    private float  radioAtomico;
    private float  energiaIonizacion;
    private float  electronegatividad;
    private int    periodo;
    private int    grupo;
    private String bloque;      // "s", "p", "d", "f"

    // ─── Constructores ────────────────────────────────────────────
    public ElementoBase() { }

    public ElementoBase(String nombre, String simbolo, int numeroAtomico, float masaAtomica, float radioAtomico, float energiaIonizacion, float electronegatividad, int periodo, int grupo, String bloque) {
        this.nombre        = nombre;
        this.simbolo       = simbolo;
        this.numeroAtomico = numeroAtomico;
        this.masaAtomica   = masaAtomica;
        this.radioAtomico = radioAtomico;
        this.energiaIonizacion = energiaIonizacion;
        this.electronegatividad = electronegatividad;
        this.periodo = periodo;
        this.grupo = grupo;
        this.bloque = bloque;
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
    
    
    public float  getRadioAtomico()            { return radioAtomico; }
    public void   setRadioAtomico(float v)     { this.radioAtomico = v; }
 
    public float  getEnergiaIonizacion()       { return energiaIonizacion; }
    public void   setEnergiaIonizacion(float v){ this.energiaIonizacion = v; }
 
    public float  getElectronegatividad()      { return electronegatividad; }
    public void   setElectronegatividad(float v){ this.electronegatividad = v; }
 
    public int    getPeriodo()                 { return periodo; }
    public void   setPeriodo(int v)            { this.periodo = v; }
 
    public int    getGrupo()                   { return grupo; }
    public void   setGrupo(int v)              { this.grupo = v; }
 
    public String getBloque()                  { return bloque; }
    public void   setBloque(String v)          { this.bloque = v; }

    @Override
    public String toString() {
        return simbolo + " (" + nombre + ", Z=" + numeroAtomico + ")";
    }
}