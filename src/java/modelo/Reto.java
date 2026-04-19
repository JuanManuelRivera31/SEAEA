package modelo;

import java.sql.Time;

/**
 * Reto
 * Representa un reto de evaluación generado para un escenario.
 * Corresponde a la clase Reto del diagrama de clases.
 *
 * Reglas de negocio:
 *  - Máximo 3 intentos (RF-111).
 *  - Temporizador de 90 segundos por defecto (RF-111).
 *  - El reto se genera aleatoriamente al iniciar evaluación (RF-111).
 */
public class Reto {

    private int    idReto;
    private int    idUsuario;
    private int    idEscenario;
    private String descripcion;
    private int    temporizador;   // en segundos
    private int    intentos;       // intentos ya usados
    private boolean completado;

    // Para escenarios 3, 4, 5: elemento objetivo
    private ElementoBase elementoObjetivo;

    // Constantes de negocio
    public static final int MAX_INTENTOS   = 3;
    public static final int TIEMPO_DEFAULT = 90;  // segundos

    // ─── Constructores ────────────────────────────────────────────
    public Reto() {
        this.temporizador = TIEMPO_DEFAULT;
        this.intentos     = 0;
        this.completado   = false;
    }

    public Reto(int idReto, int idUsuario, int idEscenario, String descripcion) {
        this();
        this.idReto      = idReto;
        this.idUsuario   = idUsuario;
        this.idEscenario = idEscenario;
        this.descripcion = descripcion;
    }

    // ─── Métodos de negocio ────────────────────────────────────────

    /**
     * Genera la descripción del reto para el Escenario 1.
     * El texto describe el átomo que el estudiante debe construir.
     * @param elementoObjetivo Elemento aleatorio a construir.
     * @param protones   # protones requeridos
     * @param neutrones  # neutrones requeridos
     * @param electrones # electrones requeridos
     */
    public void generarReto(ElementoBase elementoObjetivo,
                            int protones, int neutrones, int electrones) {
        this.elementoObjetivo = elementoObjetivo;
        this.descripcion = "Construye un átomo de " + elementoObjetivo.getNombre()
            + " (" + elementoObjetivo.getSimbolo() + ") con "
            + protones + " protón(es), "
            + neutrones + " neutrón(es) y "
            + electrones + " electrón(es).";
        this.intentos   = 0;
        this.completado = false;
    }

    /**
     * Comprueba si la configuración del estudiante cumple el reto. (RF-115)
     * @param atomoEstudiante Elemento configurado por el estudiante.
     * @param retoObjetivo    Elemento que se debe alcanzar.
     * @return true si es correcto.
     */
    public boolean comprobarReto(Elemento atomoEstudiante, Elemento retoObjetivo) {
        return atomoEstudiante.getProtones()   == retoObjetivo.getProtones()
            && atomoEstudiante.getNeutrones()  == retoObjetivo.getNeutrones()
            && atomoEstudiante.getElectrones() == retoObjetivo.getElectrones();
    }

    /**
     * Muestra la consigna del reto. (RF-112)
     */
    public String mostrarReto() {
        return descripcion
            + "\nTiempo: " + temporizador + " segundos"
            + "\nIntentos restantes: " + (MAX_INTENTOS - intentos);
    }

    /**
     * Retroalimentación después de cada comprobación. (RF-118)
     */
    public String retroalimentacionComprobacion(boolean correcto) {
        if (correcto) {
            return "¡Excelente! Has construido correctamente el átomo de "
                + (elementoObjetivo != null ? elementoObjetivo.getNombre() : "")
                + ". Recuerda que el número atómico (Z) es igual al número de protones.";
        } else {
            int restantes = MAX_INTENTOS - intentos;
            if (restantes > 0) {
                return "Incorrecto. Revisa las cantidades de partículas. "
                    + "Te quedan " + restantes + " intento(s).";
            } else {
                return "Has agotado todos los intentos. Se generará un nuevo reto.";
            }
        }
    }

    /**
     * Registra un intento. Devuelve true si aún quedan intentos.
     */
    public boolean registrarIntento() {
        intentos++;
        return intentos < MAX_INTENTOS;
    }

    /** ¿Se han agotado todos los intentos? */
    public boolean agotadoIntentos() {
        return intentos >= MAX_INTENTOS;
    }

    // ─── Getters y Setters ─────────────────────────────────────────
    public int     getIdReto()          { return idReto;          }
    public int     getIdUsuario()       { return idUsuario;       }
    public int     getIdEscenario()     { return idEscenario;     }
    public String  getDescripcion()     { return descripcion;     }
    public int     getTemporizador()    { return temporizador;    }
    public int     getIntentos()        { return intentos;        }
    public boolean isCompletado()       { return completado;      }
    public ElementoBase getElementoObjetivo() { return elementoObjetivo; }

    public void setIdReto(int idReto)              { this.idReto       = idReto;       }
    public void setIdUsuario(int idUsuario)        { this.idUsuario    = idUsuario;    }
    public void setIdEscenario(int idEscenario)    { this.idEscenario  = idEscenario;  }
    public void setDescripcion(String descripcion) { this.descripcion  = descripcion;  }
    public void setTemporizador(int temporizador)  { this.temporizador = temporizador; }
    public void setIntentos(int intentos)          { this.intentos     = intentos;     }
    public void setCompletado(boolean completado)  { this.completado   = completado;   }
    public void setElementoObjetivo(ElementoBase e){ this.elementoObjetivo = e;        }
}
