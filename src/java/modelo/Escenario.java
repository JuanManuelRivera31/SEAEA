package modelo;

import java.util.ArrayList;
import java.util.List;

/**
 * Escenario
 * Orquesta el simulador del Escenario 1 "Arma tu átomo".
 * Corresponde a la clase Escenario del diagrama de clases.
 *
 * Responsabilidades:
 *  - Gestionar el estado del simulador (exploración vs evaluación).
 *  - Coordinar el elemento activo, los retos y el progreso.
 *  - Exponer los métodos que el controlador invocará.
 */
public class Escenario {

    // ─── Atributos del diagrama ────────────────────────────────────
    private int    idEscenario;
    private String nombre;
    private boolean estado;           // true = activo
    private List<Reto> retos;
    private Elemento elemento;        // átomo construido por el estudiante
    private int    paginasTeoria;

    // ─── Estado interno ────────────────────────────────────────────
    private boolean modoEvaluacion;   // false=exploración, true=evaluación
    private Reto    retoActual;
    private ProgresoEscenario progreso;
    private ElementoBase elementoIdentificado;  // elemento según Z actual

    // ─── Constructores ────────────────────────────────────────────
    public Escenario() {
        this.elemento         = new Elemento();
        this.retos            = new ArrayList<>();
        this.progreso         = new ProgresoEscenario();
        this.estado           = true;
        this.modoEvaluacion   = false;
    }

    public Escenario(int idEscenario, String nombre, int paginasTeoria) {
        this();
        this.idEscenario   = idEscenario;
        this.nombre        = nombre;
        this.paginasTeoria = paginasTeoria;
    }

    // ─── Ciclo de vida del escenario ──────────────────────────────

    /**
     * Carga e inicializa el escenario. (CU-101 / RF-102..109)
     */
    public void cargarEscenario() {
        elemento.reiniciar();
        modoEvaluacion = false;
        retoActual     = null;
        // La carga de datos (tabla periódica, etc.) la hace el controlador/DAO
    }

    /**
     * Reinicia el simulador al estado inicial. (RF-122)
     * Si hay evaluación activa, la abandona y pierde el progreso.
     */
    public void reiniciarEscenario() {
        elemento.reiniciar();
        modoEvaluacion = false;
        retoActual     = null;
        progreso       = new ProgresoEscenario();
        retos.clear();
    }

    /**
     * Sale del escenario (botón Volver). (RF-123)
     */
    public void salirEscenario() {
        reiniciarEscenario();
    }

    /**
     * Avanza a la siguiente página de teoría. (navegación)
     */
    public void avanzarPagina() {
        // Lógica de navegación manejada en el controlador JSP
    }

    // ─── Guía de la mascota ───────────────────────────────────────

    /**
     * Devuelve el mensaje de guía de la mascota al iniciar. (RF-109)
     */
    public String guiaMascota() {
        return "¡Hola! Soy AmazonAtom. En este escenario puedes construir tu propio átomo "
             + "agregando o quitando protones, neutrones y electrones. "
             + "Observa cómo cambia el elemento y la carga neta. "
             + "Cuando estés listo, presiona 'Iniciar Reto' para evaluarte.";
    }

    // ─── Actualización del panel de conteo ───────────────────────

    /**
     * Actualiza el panel de conteo de partículas. (RF-103)
     * Devuelve resumen de partículas actuales.
     */
    public String actualizarPanelConteo() {
        return "Protones: "   + elemento.getProtones()
             + " | Neutrones: " + elemento.getNeutrones()
             + " | Electrones: " + elemento.getElectrones();
    }

    /**
     * Actualiza la carta del elemento periódico según Z. (RF-107)
     * El controlador provee el ElementoBase desde la BD.
     */
    public void actualizarCartaPeriodicaElemento(ElementoBase eb) {
        this.elementoIdentificado = eb;
    }

    /**
     * Actualiza el indicador de carga neta. (RF-108)
     */
    public int actualizarPanelCargaNeta() {
        return elemento.getCargaNeta();
    }

    /**
     * Actualiza la representación visual del átomo. (RF-104)
     * Devuelve un mapa de datos que el JSP/JS usará para redibujar.
     */
    public String actualizarAtomo() {
        return "p=" + elemento.getProtones()
             + ",n=" + elemento.getNeutrones()
             + ",e=" + elemento.getElectrones()
             + ",A=" + elemento.getNumeroMasico();
    }

    // ─── Módulo de evaluación ─────────────────────────────────────

    /**
     * Inicia el módulo de evaluación. (RF-110 / CU-103)
     */
    public void iniciarEvaluacion() {
        modoEvaluacion = true;
    }

    /**
     * Finaliza el módulo de evaluación. (RF-124 / CU-109)
     */
    public void superarEscenario() {
        modoEvaluacion = false;
        // El controlador redirige al siguiente escenario
    }

    // ─── Getters y Setters ─────────────────────────────────────────
    public int     getIdEscenario()    { return idEscenario;    }
    public String  getNombre()         { return nombre;         }
    public boolean isEstado()          { return estado;         }
    public List<Reto> getRetos()       { return retos;          }
    public Elemento getElemento()      { return elemento;       }
    public int     getPaginasTeoria()  { return paginasTeoria;  }
    public boolean isModoEvaluacion()  { return modoEvaluacion; }
    public Reto    getRetoActual()     { return retoActual;     }
    public ProgresoEscenario getProgreso() { return progreso;   }
    public ElementoBase getElementoIdentificado() { return elementoIdentificado; }

    public void setIdEscenario(int id)        { this.idEscenario   = id;     }
    public void setNombre(String nombre)      { this.nombre        = nombre; }
    public void setEstado(boolean estado)     { this.estado        = estado; }
    public void setElemento(Elemento e)       { this.elemento      = e;      }
    public void setPaginasTeoria(int p)       { this.paginasTeoria = p;      }
    public void setModoEvaluacion(boolean m)  { this.modoEvaluacion = m;     }
    public void setRetoActual(Reto r)         { this.retoActual    = r;      }
    public void setProgreso(ProgresoEscenario p) { this.progreso   = p;      }
}
