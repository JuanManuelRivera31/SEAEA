package modelo;

/**
 * Elemento
 * Representa el átomo que el estudiante construye en el simulador.
 * Escenario 1: "Arma tu átomo"
 * Corresponde a la clase Elemento del diagrama de clases.
 *
 * Reglas de negocio:
 *  - Mínimo 0 partículas de cualquier tipo.
 *  - Número atómico Z = # protones.
 *  - Carga neta = protones - electrones.
 *  - Número másico A = protones + neutrones.
 *  - El elemento (ElementoBase) se actualiza al cambiar protones.
 */
public class Elemento {

    private int protones;
    private int neutrones;
    private int electrones;

    // ─── Constructores ────────────────────────────────────────────
    public Elemento() {
        this.protones   = 0;
        this.neutrones  = 0;
        this.electrones = 0;
    }

    public Elemento(int protones, int neutrones, int electrones) {
        this.protones   = protones;
        this.neutrones  = neutrones;
        this.electrones = electrones;
    }

    // ─── Incrementos (RF-102) ──────────────────────────────────────
    public void incrementarProtones() {
        if (protones < 118) protones++;   // límite tabla periódica
    }

    public void incrementarNeutrones() {
        neutrones++;
    }

    public void incrementarElectrones() {
        electrones++;
    }

    // ─── Decrementos (RF-102) ─────────────────────────────────────
    public void decrementarProtones() {
        if (protones > 0) protones--;
    }

    public void decrementarNeutrones() {
        if (neutrones > 0) neutrones--;
    }

    public void decrementarElectrones() {
        if (electrones > 0) electrones--;
    }

    // ─── Cálculos derivados ────────────────────────────────────────

    /**
     * Número atómico (Z) = número de protones. (RF-105)
     */
    public int getNumeroAtomico() {
        return protones;
    }

    /**
     * Número másico (A) = protones + neutrones. (RF-306, RF-406)
     */
    public int getNumeroMasico() {
        return protones + neutrones;
    }

    /**
     * Carga neta = protones - electrones. (RF-108)
     * Positiva → catión, Negativa → anión, 0 → neutro.
     */
    public int getCargaNeta() {
        return protones - electrones;
    }

    /**
     * Descripción textual del estado iónico del átomo. (RF-305)
     */
    public String getEstadoIonico() {
        int carga = getCargaNeta();
        if (carga == 0) return "Neutro";
        if (carga > 0)  return "Catión (+" + carga + ")";
        return "Anión (" + carga + ")";
    }

    /**
     * Reinicia todas las partículas a 0. (RF-122)
     */
    public void reiniciar() {
        protones   = 0;
        neutrones  = 0;
        electrones = 0;
    }

    // ─── Getters y Setters ─────────────────────────────────────────
    public int getProtones()   { return protones;   }
    public int getNeutrones()  { return neutrones;  }
    public int getElectrones() { return electrones; }

    public void setProtones(int protones) {
        this.protones = Math.max(0, Math.min(118, protones));
    }
    public void setNeutrones(int neutrones) {
        this.neutrones = Math.max(0, neutrones);
    }
    public void setElectrones(int electrones) {
        this.electrones = Math.max(0, electrones);
    }

    @Override
    public String toString() {
        return "Elemento{p=" + protones + ", n=" + neutrones
             + ", e=" + electrones + ", Z=" + getNumeroAtomico()
             + ", A=" + getNumeroMasico()
             + ", carga=" + getCargaNeta() + "}";
    }
}

