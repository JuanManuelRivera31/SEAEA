package logica;

import dao.ElementoBaseDAO;
import dao.IsotopoDAO;
import dao.ProgresoEscenarioDAO;
import dao.PuntajeRetoDAO;
import dao.RetoDAO;
import modelo.ElementoBase;
import modelo.Elemento;
import modelo.Escenario;
import modelo.Isotopo;
import modelo.PuntajeReto;
import modelo.Reto;
import modelo.Usuario;

import java.util.ArrayList;
import java.util.Collections;
import java.util.List;

/**
 * EscenarioCuatroServicio
 * ─────────────────────────────────────────────────────────────────────────
 * Capa de LÓGICA de negocio para el Escenario 4 "Configura tu Isótopo".
 *
 * Flujo MVC:
 *   JSP → Controlador → EscenarioCuatroServicio → DAOs / Modelo → BD
 *                     ←                         ←               ←
 *
 * Este servicio es el ÚNICO que toca DAOs y ejecuta lógica de negocio.
 */
public class EscenarioCuatroServicio {

    // ── Constantes ────────────────────────────────────────────────────────
    public static final int   ID_ESCENARIO       = 4;
    public static final int   MAX_Z              = 36; // hasta período 4 (incluye bloque d)
    public static final int   MAX_Z_EVAL         = 18; // para retos: primeros 3 períodos
    public static final int   MAX_NEUTRONES      = 30;
    public static final float MINIMO_APROBATORIO = 80.0f;

    // ── DAOs ─────────────────────────────────────────────────────────────
    private final ElementoBaseDAO      elementoDAO = new ElementoBaseDAO();
    private final IsotopoDAO           isotopoDAO  = new IsotopoDAO();
    private final RetoDAO              retoDAO     = new RetoDAO();
    private final PuntajeRetoDAO       puntajeDAO  = new PuntajeRetoDAO();
    private final ProgresoEscenarioDAO progresoDAO = new ProgresoEscenarioDAO();

    // ══════════════════════════════════════════════════════════════════════
    // CARGA INICIAL
    // ══════════════════════════════════════════════════════════════════════

    /**
     * Carga el escenario: establece el porcentaje previo y genera
     * el mensaje de bienvenida de la mascota.
     */
    public ResultadoCarga cargar(Escenario escenario, Usuario usuario) {
        escenario.cargarEscenario();
        float pct = progresoDAO.obtenerPorcentaje(usuario.getIdUsuario(), ID_ESCENARIO);
        escenario.getProgreso().setPorcentajeAprendizaje(pct);
        String mensaje = escenario.guiaMascota();
        return new ResultadoCarga(pct, mensaje);
    }

    /**
     * Retorna la lista de elementos filtrada hasta MAX_Z,
     * para mostrar en la tabla periódica del JSP.
     */
    public List<ElementoBase> obtenerElementosParaTabla() {
        List<ElementoBase> todos    = elementoDAO.obtenerTodos();
        List<ElementoBase> filtrada = new ArrayList<>();
        for (ElementoBase e : todos) {
            if (e.getNumeroAtomico() <= MAX_Z) filtrada.add(e);
        }
        return filtrada;
    }

    // ══════════════════════════════════════════════════════════════════════
    // SELECCIÓN DE ELEMENTO
    // ══════════════════════════════════════════════════════════════════════

    /**
     * Valida y devuelve el ElementoBase para el Z dado.
     * Solo admite elementos hasta MAX_Z.
     * Retorna null si Z > MAX_Z o no existe en la BD.
     */
    public ElementoBase seleccionarElemento(int z) {
        if (z < 1 || z > MAX_Z) return null;
        return elementoDAO.obtenerPorNumeroAtomico(z);
    }

    // ══════════════════════════════════════════════════════════════════════
    // NEUTRONES
    // ══════════════════════════════════════════════════════════════════════

    /** Incrementa neutrones sin superar MAX_NEUTRONES. */
    public int incrementarNeutrones(int actual) {
        return Math.min(actual + 1, MAX_NEUTRONES);
    }

    /** Decrementa neutrones sin bajar de 0. */
    public int decrementarNeutrones(int actual) {
        return Math.max(actual - 1, 0);
    }

    // ══════════════════════════════════════════════════════════════════════
    // ISÓTOPO ACTUAL
    // ══════════════════════════════════════════════════════════════════════

    /**
     * Consulta el isótopo que corresponde a (Z, neutrones).
     * Puede devolver null si no existe en BD.
     */
    public Isotopo calcularIsotopoActual(int z, int neutrones) {
        return isotopoDAO.obtenerPorNeutrones(z, neutrones);
    }

    /**
     * Construye el nombre del isótopo en formato Elemento-A.
     * Ej: z=2, neutrones=3 → "Helio-5"
     */
    public String nombreIsotopo(ElementoBase eb, int neutrones) {
        int a = eb.getNumeroAtomico() + neutrones;
        return eb.getNombre() + "-" + a;
    }

    /**
     * Construye el ResultadoIsotopo con todos los datos del isótopo actual
     * para que el controlador los publique al JSP.
     */
    public ResultadoIsotopo calcularDatosIsotopo(ElementoBase eb, int neutrones) {
        int z    = eb.getNumeroAtomico();
        int a    = z + neutrones;
        Isotopo iso = isotopoDAO.obtenerPorNeutrones(z, neutrones);

        String nombre     = eb.getNombre() + "-" + a;
        String estabilidad;
        double abundancia;
        double masa;

        if (iso != null) {
            estabilidad = iso.isEstable() ? "ESTABLE" : "INESTABLE";
            abundancia  = iso.getAbundancia();
            masa        = iso.getMasaIsotopica() > 0
                          ? iso.getMasaIsotopica()
                          : (double) eb.getMasaAtomica();
        } else {
            estabilidad = "INESTABLE";
            abundancia  = 0.0;
            masa        = (double) eb.getMasaAtomica();
        }

        return new ResultadoIsotopo(iso, nombre, estabilidad, abundancia, masa, a);
    }

    // ══════════════════════════════════════════════════════════════════════
    // EVALUACIÓN
    // ══════════════════════════════════════════════════════════════════════

    /**
     * Activa el modo evaluación en el escenario.
     */
    public void iniciarEvaluacion(Escenario escenario) {
        escenario.iniciarEvaluacion();
    }

    /**
     * Genera un reto: elemento aleatorio con Z ≤ MAX_Z_EVAL + isótopo aleatorio.
     *
     * CORRECCIÓN DEL BUG "Cargando reto":
     * En vez de usar obtenerAleatorio() en loop (que puede retornar muchas veces
     * Z > 18 si la BD tiene muchos elementos), se obtiene TODOS los elementos,
     * se filtran los válidos y se elige uno al azar.
     *
     * @return ResultadoReto con reto+elemento+isótopo; null si no hay datos.
     */
    public ResultadoReto generarReto(Usuario usuario) {
        // Obtener todos los elementos con Z ≤ MAX_Z_EVAL (garantizado)
        List<ElementoBase> todos    = elementoDAO.obtenerTodos();
        List<ElementoBase> validos  = new ArrayList<>();
        for (ElementoBase e : todos) {
            if (e.getNumeroAtomico() <= MAX_Z_EVAL) validos.add(e);
        }
        if (validos.isEmpty()) return null;

        // Elegir uno al azar
        Collections.shuffle(validos);
        ElementoBase eb = validos.get(0);
        int z           = eb.getNumeroAtomico();

        // Obtener isótopo aleatorio para ese elemento
        Isotopo isoObj = isotopoDAO.obtenerAleatorio(z);
        if (isoObj == null) {
            // Intentar con otros elementos si el primero no tiene isótopos en BD
            for (int i = 1; i < validos.size(); i++) {
                eb     = validos.get(i);
                z      = eb.getNumeroAtomico();
                isoObj = isotopoDAO.obtenerAleatorio(z);
                if (isoObj != null) break;
            }
        }
        if (isoObj == null) return null;

        Elemento atomoObj = new Elemento(z, isoObj.getNumeroNeutrones(), z);

        Reto reto = new Reto();
        reto.setIdUsuario(usuario.getIdUsuario());
        reto.setIdEscenario(ID_ESCENARIO);
        reto.generarReto(eb, atomoObj.getProtones(),
                         atomoObj.getNeutrones(), atomoObj.getElectrones());
        reto.setDescripcion(
            "Configura el isótopo " + isoObj.getNombreDisplay()
            + ".\nSelecciona " + eb.getNombre()
            + " (Z=" + z + ") y ajusta los neutrones a "
            + isoObj.getNumeroNeutrones() + ".\n"
            + "Número másico objetivo: A = " + isoObj.getNumeroMasico());

        int idReto = retoDAO.insertar(reto);
        reto.setIdReto(idReto);

        return new ResultadoReto(reto, eb, isoObj, null, false);
    }

    /**
     * Comprueba si la configuración del estudiante cumple el reto.
     * Verifica: mismo elemento (por Z) Y neutrones exactos.
     * Persiste puntaje y progreso.
     */
    public ResultadoComprobacion comprobar(Escenario escenario,
                                            Reto retoActual,
                                            Isotopo isotopoObjetivo,
                                            ElementoBase ebReto,
                                            ElementoBase ebActual,
                                            int neutronesActuales,
                                            Usuario usuario) {
        if (retoActual == null || isotopoObjetivo == null) {
            return new ResultadoComprobacion(
                false, escenario.getProgreso().getPorcentajeAprendizaje(),
                "No hay un reto activo. Presiona 'Iniciar Evaluación'.",
                false, false, 0);
        }

        int zReto   = (ebReto   != null) ? ebReto.getNumeroAtomico()   : -1;
        int zActual = (ebActual != null) ? ebActual.getNumeroAtomico() : -2;

        boolean elementoCorrecto   = (zActual == zReto);
        boolean neutronesCorrectos = (neutronesActuales == isotopoObjetivo.getNumeroNeutrones());
        boolean correcto           = elementoCorrecto && neutronesCorrectos;

        retoActual.registrarIntento();
        int intento = retoActual.getIntentos();

        // Persistir
        PuntajeReto pr = new PuntajeReto(retoActual, intento, correcto);
        puntajeDAO.insertar(retoActual.getIdReto(), intento, pr.getPuntaje(), correcto);
        if (correcto) retoActual.setCompletado(true);
        retoDAO.actualizar(retoActual);

        float porcentaje = puntajeDAO.calcularPorcentajeAprendizaje(
                usuario.getIdUsuario(), ID_ESCENARIO);
        progresoDAO.guardar(usuario.getIdUsuario(), ID_ESCENARIO, porcentaje);
        escenario.getProgreso().setPorcentajeAprendizaje(porcentaje);

        // Mensaje de retroalimentación
        String mensaje;
        if (correcto) {
            String abund = isotopoObjetivo.getAbundancia() > 0
                ? String.format("%.4f%%", isotopoObjetivo.getAbundancia()) : "trazas";
            mensaje = "¡Excelente! Configuraste correctamente el isótopo "
                + isotopoObjetivo.getNombreDisplay() + " en el intento " + intento + ".\n"
                + "Neutrones: " + isotopoObjetivo.getNumeroNeutrones()
                + " · Número másico: " + isotopoObjetivo.getNumeroMasico()
                + "\nAbundancia natural: " + abund
                + "\nRecuerda: A = Z + N";
        } else if (retoActual.agotadoIntentos()) {
            mensaje = "Agotaste los 3 intentos.\n"
                + "El isótopo objetivo era: " + isotopoObjetivo.getNombreDisplay()
                + " (" + ebReto.getNombre() + ", Z=" + zReto
                + ", N=" + isotopoObjetivo.getNumeroNeutrones() + ")\n"
                + "He generado un nuevo reto.";
        } else {
            int restantes = Reto.MAX_INTENTOS - intento;
            if (!elementoCorrecto) {
                String nomEsperado = (ebReto != null) ? ebReto.getNombre() : "el elemento del reto";
                mensaje = "El elemento no es correcto. Selecciona: " + nomEsperado
                    + ".\nTe quedan " + restantes + " intento(s).";
            } else {
                int diff = neutronesActuales - isotopoObjetivo.getNumeroNeutrones();
                mensaje = (diff > 0
                    ? "Tienes demasiados neutrones. Quita " + diff + "."
                    : "Faltan " + Math.abs(diff) + " neutrones. Agrega más.")
                    + "\nTe quedan " + restantes + " intento(s).";
            }
        }

        boolean habilitarContinuar = porcentaje >= MINIMO_APROBATORIO;
        boolean generarNuevoReto   = correcto || retoActual.agotadoIntentos();

        return new ResultadoComprobacion(
            correcto, porcentaje, mensaje,
            habilitarContinuar, generarNuevoReto, intento);
    }

    /**
     * Finaliza la evaluación y retorna el mensaje de cierre.
     */
    public String finalizar(Escenario escenario) {
        escenario.setModoEvaluacion(false);
        float pct = escenario.getProgreso().getPorcentajeAprendizaje();
        return "Evaluación finalizada. Tu porcentaje: " + Math.round(pct) + "%. "
             + (pct >= MINIMO_APROBATORIO
                ? "¡Superaste el escenario!"
                : "Sigue practicando para alcanzar el 80%.");
    }

    /** Verifica si el porcentaje alcanza el mínimo para continuar. */
    public boolean puedeSuperar(Escenario escenario) {
        return escenario.getProgreso().getPorcentajeAprendizaje() >= MINIMO_APROBATORIO;
    }

    /** Marca el escenario como superado. */
    public void superar(Escenario escenario) { escenario.superarEscenario(); }

    /** Prepara la salida del escenario. */
    public void salir(Escenario escenario) { escenario.salirEscenario(); }

    /** Reinicia el estado del escenario. */
    public void reiniciar(Escenario escenario) { escenario.reiniciarEscenario(); }

    // ══════════════════════════════════════════════════════════════════════
    // DTOs DE RETORNO
    // ══════════════════════════════════════════════════════════════════════

    public static class ResultadoCarga {
        public final float  porcentaje;
        public final String mensajeMascota;
        public ResultadoCarga(float p, String m) { porcentaje = p; mensajeMascota = m; }
    }

    /** Datos calculados del isótopo actual (para el panel izquierdo del JSP). */
    public static class ResultadoIsotopo {
        public final Isotopo isotopo;      // puede ser null si no está en BD
        public final String  nombre;       // ej. "Helio-4"
        public final String  estabilidad;  // "ESTABLE" | "INESTABLE"
        public final double  abundancia;   // 0.0 si no registrada
        public final double  masa;         // masa isotópica o atómica
        public final int     numeroMasico; // A = Z + N
        public ResultadoIsotopo(Isotopo iso, String nombre, String estabilidad,
                                double abundancia, double masa, int a) {
            isotopo      = iso;
            this.nombre  = nombre;
            this.estabilidad = estabilidad;
            this.abundancia  = abundancia;
            this.masa        = masa;
            numeroMasico = a;
        }
    }

    public static class ResultadoReto {
        public final Reto         reto;
        public final ElementoBase elementoBase;
        public final Isotopo      isotopo;
        public final String       mensaje;
        public final boolean      error;
        public ResultadoReto(Reto r, ElementoBase eb, Isotopo iso, String msg, boolean err) {
            reto = r; elementoBase = eb; isotopo = iso; mensaje = msg; error = err;
        }
    }

    public static class ResultadoComprobacion {
        public final boolean correcto;
        public final float   porcentaje;
        public final String  mensajeMascota;
        public final boolean habilitarContinuar;
        public final boolean generarNuevoReto;
        public final int     intentoUsado;
        public ResultadoComprobacion(boolean c, float p, String m, boolean hc, boolean gn, int i) {
            correcto = c; porcentaje = p; mensajeMascota = m;
            habilitarContinuar = hc; generarNuevoReto = gn; intentoUsado = i;
        }
    }
}