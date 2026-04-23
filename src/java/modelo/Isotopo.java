package modelo;

/**
 * Isotopo
 * Representa un isótopo de un elemento químico.
 * Mapea la tabla: isotopo (id_isotopo, id_elemento, numero_masico,
 *   numero_neutrones, masa_isotopica, abundancia, es_estable,
 *   nombre_isotopo, notacion)
 */
public class Isotopo {

    private int    idIsotopo;
    private int    idElemento;
    private int    numeroMasico;
    private int    numeroNeutrones;
    private double masaIsotopica;
    private double abundancia;
    private boolean esEstable;
    private String nombreIsotopo;   // ej. "Helio-5"
    private String notacion;        // ej. "He-5"

    public Isotopo() {}

    public Isotopo(int idIsotopo, int idElemento, int numeroMasico,
                   int numeroNeutrones, double masaIsotopica,
                   double abundancia, boolean esEstable,
                   String nombreIsotopo, String notacion) {
        this.idIsotopo       = idIsotopo;
        this.idElemento      = idElemento;
        this.numeroMasico    = numeroMasico;
        this.numeroNeutrones = numeroNeutrones;
        this.masaIsotopica   = masaIsotopica;
        this.abundancia      = abundancia;
        this.esEstable       = esEstable;
        this.nombreIsotopo   = nombreIsotopo;
        this.notacion        = notacion;
    }

    // ── getters / setters ────────────────────────────────────────────────────

    public int getIdIsotopo()           { return idIsotopo; }
    public void setIdIsotopo(int v)     { this.idIsotopo = v; }

    public int getIdElemento()          { return idElemento; }
    public void setIdElemento(int v)    { this.idElemento = v; }

    public int getNumeroMasico()        { return numeroMasico; }
    public void setNumeroMasico(int v)  { this.numeroMasico = v; }

    public int getNumeroNeutrones()     { return numeroNeutrones; }
    public void setNumeroNeutrones(int v){ this.numeroNeutrones = v; }

    public double getMasaIsotopica()        { return masaIsotopica; }
    public void   setMasaIsotopica(double v){ this.masaIsotopica = v; }

    public double getAbundancia()           { return abundancia; }
    public void   setAbundancia(double v)   { this.abundancia = v; }

    public boolean isEstable()          { return esEstable; }
    public void    setEstable(boolean v){ this.esEstable = v; }

    public String getNombreIsotopo()        { return nombreIsotopo; }
    public void   setNombreIsotopo(String v){ this.nombreIsotopo = v; }

    public String getNotacion()         { return notacion; }
    public void   setNotacion(String v) { this.notacion = v; }

    /**
     * Nombre legible para pantalla: "Helio-5"
     * Si nombre_isotopo ya viene de BD, lo devuelve directo.
     */
    public String getNombreDisplay() {
        return (nombreIsotopo != null && !nombreIsotopo.isEmpty())
               ? nombreIsotopo : notacion;
    }
}
