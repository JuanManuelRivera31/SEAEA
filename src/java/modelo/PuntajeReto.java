package modelo;

/**
 * PuntajeReto
 * Calcula y almacena el puntaje obtenido en un reto según el intento.
 * Corresponde a la clase PuntajeReto del diagrama de clases.
 *
 * Fórmula del Factor de Intento (CU-106):
 *   Intento 1 → multiplicador 1.0 (100%)
 *   Intento 2 → multiplicador 0.7  (70%)
 *   Intento 3 → multiplicador 0.4  (40%)
 *   Sin acierto → factor 0
 *
 * Porcentaje de aprendizaje = (R1*F1 + R2*F2 + R3*F3) / 3
 */
public class PuntajeReto {

    private Reto   reto;
    private int    intentoActual;   // 1, 2 o 3
    private float  puntaje;         // 0.0 a 100.0
    private boolean completado;

    // Factores de intento según CU-106
    public static final float FACTOR_INTENTO_1 = 1.0f;
    public static final float FACTOR_INTENTO_2 = 0.7f;
    public static final float FACTOR_INTENTO_3 = 0.4f;
    public static final float PUNTAJE_BASE      = 100.0f;

    // ─── Constructores ────────────────────────────────────────────
    public PuntajeReto() { }

    public PuntajeReto(Reto reto, int intentoActual, boolean completado) {
        this.reto          = reto;
        this.intentoActual = intentoActual;
        this.completado    = completado;
        this.puntaje       = calcularPuntaje(completado, intentoActual);
    }

    // ─── Cálculo de puntaje ────────────────────────────────────────

    /**
     * Calcula el puntaje según el intento en que se acertó. (RF-116)
     * Si no se completó, el puntaje es 0.
     */
    public float calcularPuntaje(boolean acertado, int intento) {
        if (!acertado) return 0.0f;
        switch (intento) {
            case 1: return PUNTAJE_BASE * FACTOR_INTENTO_1;  // 100.0
            case 2: return PUNTAJE_BASE * FACTOR_INTENTO_2;  //  70.0
            case 3: return PUNTAJE_BASE * FACTOR_INTENTO_3;  //  40.0
            default: return 0.0f;
        }
    }

    /**
     * Calcula el porcentaje de aprendizaje acumulado de hasta 3 retos.
     * Si un reto no fue acertado su puntaje es 0. (CU-106)
     *
     * @param puntajes Array con el puntaje de cada reto (máx 3 elementos).
     * @return Porcentaje de aprendizaje (0.0 - 100.0).
     */
    public static float calcularPorcentajeAprendizaje(float[] puntajes) {
        if (puntajes == null || puntajes.length == 0) return 0.0f;
        float suma = 0;
        for (float p : puntajes) suma += p;
        return suma / puntajes.length;
    }

    /**
     * Indica si el porcentaje supera el mínimo aprobatorio (80%). (RF-120)
     */
    public static boolean superaMinimo(float porcentaje) {
        return porcentaje >= 80.0f;
    }

    // ─── Getters y Setters ─────────────────────────────────────────
    public Reto    getReto()         { return reto;         }
    public int     getIntentoActual(){ return intentoActual;}
    public float   getPuntaje()      { return puntaje;      }
    public boolean isCompletado()    { return completado;   }

    public void setReto(Reto reto)               { this.reto          = reto;          }
    public void setIntentoActual(int i)          { this.intentoActual = i;             }
    public void setPuntaje(float puntaje)        { this.puntaje       = puntaje;       }
    public void setCompletado(boolean completado){ this.completado    = completado;    }

    @Override
    public String toString() {
        return "PuntajeReto{intento=" + intentoActual
             + ", puntaje=" + puntaje + ", completado=" + completado + "}";
    }
}
