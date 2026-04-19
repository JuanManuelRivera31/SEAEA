package modelo;

import java.util.ArrayList;
import java.util.List;

/**
 * ProgresoEscenario
 * Almacena y calcula el progreso del estudiante en un escenario.
 * Corresponde a la clase ProgresoEscenario del diagrama de clases.
 */
public class ProgresoEscenario {

    private float           porcentajeAprendizaje;
    private List<PuntajeReto> resultadosRetos;

    // ─── Constructores ────────────────────────────────────────────
    public ProgresoEscenario() {
        this.resultadosRetos      = new ArrayList<>();
        this.porcentajeAprendizaje = 0.0f;
    }

    // ─── Métodos de negocio ────────────────────────────────────────

    /**
     * Agrega el resultado de un reto a la lista. (RF-116)
     */
    public void agregarResultado(PuntajeReto puntajeReto) {
        resultadosRetos.add(puntajeReto);
        actualizarPorcentajeAprendizaje();
    }

    /**
     * Recalcula el porcentaje de aprendizaje con todos los retos registrados.
     * Fórmula: (R1*F1 + R2*F2 + ... + Rn*Fn) / n  (CU-106)
     */
    public void actualizarPorcentajeAprendizaje() {
        if (resultadosRetos.isEmpty()) {
            porcentajeAprendizaje = 0.0f;
            return;
        }
        float[] puntajes = new float[resultadosRetos.size()];
        for (int i = 0; i < resultadosRetos.size(); i++) {
            puntajes[i] = resultadosRetos.get(i).getPuntaje();
        }
        porcentajeAprendizaje = PuntajeReto.calcularPorcentajeAprendizaje(puntajes);
    }

    /**
     * Devuelve el porcentaje de aprendizaje actual. (RF-117)
     */
    public float calcularPorcentajeAprendizaje() {
        actualizarPorcentajeAprendizaje();
        return porcentajeAprendizaje;
    }

    /**
     * Muestra el porcentaje formateado (ej: "60%"). (RF-117)
     */
    public String mostrarPorcentajeAprendizaje() {
        return String.format("%.0f%%", porcentajeAprendizaje);
    }

    /**
     * ¿El escenario está superado (>= 80%)? (RF-120, RF-121)
     */
    public boolean esSuperado() {
        return PuntajeReto.superaMinimo(porcentajeAprendizaje);
    }

    // ─── Getters y Setters ─────────────────────────────────────────
    public float             getPorcentajeAprendizaje() { return porcentajeAprendizaje; }
    public List<PuntajeReto> getResultadosRetos()       { return resultadosRetos;       }

    public void setPorcentajeAprendizaje(float p)       { this.porcentajeAprendizaje = p; }
    public void setResultadosRetos(List<PuntajeReto> r) { this.resultadosRetos = r;       }
}
