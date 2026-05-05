package logica;

import dao.ElementoBaseDAO;
import dao.IsotopoDAO;
import dao.PuntajeRetoDAO;
import dao.ProgresoEscenarioDAO;
import dao.RetoDAO;
import modelo.ElementoBase;
import modelo.Elemento;
import modelo.Escenario;
import modelo.Isotopo;
import modelo.PuntajeReto;
import modelo.Reto;
import modelo.Usuario;

/**
 * EscenarioCuatroServicio
 * ─────────────────────────────────────────────────────────────────────────
 * Capa de LÓGICA de negocio para el Escenario 4 "Configura tu Isótopo".
 *
 * Responsabilidades:
 *  - Validar que el elemento seleccionado sea de los primeros 18 (Z ≤ 18).
 *  - Manejar la modificación de neutrones (con límites).
 *  - Calcular el isótopo actual dado Z + número de neutrones.
 *  - Generar retos (elemento aleatorio Z ≤ 18 + isótopo aleatorio).
 *  - Comprobar si la configuración del estudiante coincide con el reto.
 *  - Calcular y persistir el porcentaje de aprendizaje.
 */
public class EscenarioCuatroServicio {

    private static final int   ID_ESCENARIO       = 4;
    private static final int   MAX_Z              = 18;
    private static final int   MAX_NEUTRONES      = 30;
    public  static final float MINIMO_APROBATORIO = 80.0f;

    private final ElementoBaseDAO      elementoDAO = new ElementoBaseDAO();
    private final IsotopoDAO           isotopoDAO  = new IsotopoDAO();
    private final RetoDAO              retoDAO     = new RetoDAO();
    private final PuntajeRetoDAO       puntajeDAO  = new PuntajeRetoDAO();
    private final ProgresoEscenarioDAO progresoDAO = new ProgresoEscenarioDAO();

    // ══════════════════════════════════════════════════════════════════════
    // SELECCIÓN DE ELEMENTO
    // ══════════════════════════════════════════════════════════════════════

    /**
     * Valida y devuelve el ElementoBase para el Z dado.
     * Retorna null si Z > MAX_Z o no existe en la BD.
     */
    public ElementoBase seleccionarElemento(int z) {
        if (z < 1 || z > MAX_Z) return null;
        return elementoDAO.obtenerPorNumeroAtomico(z);
    }

    // ══════════════════════════════════════════════════════════════════════
    // NEUTRONES
    // ══════════════════════════════════════════════════════════════════════

    /**
     * Incrementa neutrones respetando el límite máximo.
     */
    public int incrementarNeutrones(int actual) {
        return Math.min(actual + 1, MAX_NEUTRONES);
    }

    /**
     * Decrementa neutrones sin bajar de 0.
     */
    public int decrementarNeutrones(int actual) {
        return Math.max(actual - 1, 0);
    }

    // ══════════════════════════════════════════════════════════════════════
    // ISÓTOPO ACTUAL
    // ══════════════════════════════════════════════════════════════════════

    /**
     * Calcula el isótopo que corresponde a (Z, neutrones).
     * Puede devolver null si no existe en la BD (isótopo sin registro).
     */
    public Isotopo calcularIsotopoActual(int z, int neutrones) {
        return isotopoDAO.obtenerPorNeutrones(z, neutrones);
    }

    /**
     * Construye el nombre del isótopo aunque no esté en la BD.
     * Ej: z=2, neutrones=3 → "Helio-5"
     */
    public String nombreIsotopo(ElementoBase eb, int neutrones) {
        int a = eb.getNumeroAtomico() + neutrones;
        return eb.getNombre() + "-" + a;
    }

    // ══════════════════════════════════════════════════════════════════════
    // EVALUACIÓN
    // ══════════════════════════════════════════════════════════════════════

    /**
     * Genera un reto: elemento aleatorio Z ≤ MAX_Z + isótopo aleatorio.
     * Retorna null si no hay datos disponibles.
     */
    public ResultadoReto generarReto(Usuario usuario) {
        ElementoBase eb = null;
        for (int i = 0; i < 20; i++) {
            ElementoBase candidato = elementoDAO.obtenerAleatorio();
            if (candidato != null && candidato.getNumeroAtomico() <= MAX_Z) {
                eb = candidato;
                break;
            }
        }
        if (eb == null) return null;

        int z = eb.getNumeroAtomico();
        Isotopo isoObj = isotopoDAO.obtenerAleatorio(z);
        if (isoObj == null) return null;

        Elemento atomoObj = new Elemento(z, isoObj.getNumeroNeutrones(), z);

        Reto reto = new Reto();
        reto.setIdUsuario(usuario.getIdUsuario());
        reto.setIdEscenario(ID_ESCENARIO);
        reto.generarReto(eb, atomoObj.getProtones(),
                         atomoObj.getNeutrones(), atomoObj.getElectrones());
        reto.setDescripcion(
            "Configura el isótopo " + isoObj.getNombreDisplay()
            + ". Selecciona " + eb.getNombre()
            + " (Z=" + z + ") y ajusta neutrones a "
            + isoObj.getNumeroNeutrones() + ".");

        int idReto = retoDAO.insertar(reto);
        reto.setIdReto(idReto);

        return new ResultadoReto(reto, eb, isoObj, null, false);
    }

    /**
     * Comprueba si la configuración del estudiante cumple el reto.
     * Verifica: mismo elemento Z y número de neutrones correcto.
     */
    public ResultadoComprobacion comprobar(Escenario escenario,
                                           Reto retoActual,
                                           Isotopo isotopoObjetivo,
                                           ElementoBase ebReto,
                                           ElementoBase ebActual,
                                           int neutronesActuales,
                                           Usuario usuario) {
        int zReto   = (ebReto   != null) ? ebReto.getNumeroAtomico()   : -1;
        int zActual = (ebActual != null) ? ebActual.getNumeroAtomico() : -2;

        boolean elementoCorrecto   = (zActual == zReto);
        boolean neutronesCorrectos = (neutronesActuales == isotopoObjetivo.getNumeroNeutrones());
        boolean correcto           = elementoCorrecto && neutronesCorrectos;

        retoActual.registrarIntento();
        int intento = retoActual.getIntentos();

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
            String nomIso = isotopoObjetivo.getNombreDisplay();
            String abund  = isotopoObjetivo.getAbundancia() > 0
                ? String.format("%.4f%%", isotopoObjetivo.getAbundancia()) : "trazas";
            mensaje = "¡Excelente! Configuraste correctamente el isótopo "
                + nomIso + " en el intento " + intento + ".\n"
                + "Neutrones: " + isotopoObjetivo.getNumeroNeutrones()
                + " · Número másico: " + isotopoObjetivo.getNumeroMasico()
                + "\nAbundancia natural: " + abund
                + "\nRecuerda: A = Z + N";
        } else {
            if (!elementoCorrecto) {
                String nomEsperado = (ebReto != null) ? ebReto.getNombre() : "el elemento del reto";
                mensaje = "El elemento seleccionado no es correcto. Selecciona: " + nomEsperado + ".";
            } else {
                int diff = neutronesActuales - isotopoObjetivo.getNumeroNeutrones();
                mensaje = diff > 0
                    ? "Tienes demasiados neutrones. Quita " + diff + "."
                    : "Faltan " + Math.abs(diff) + " neutrones. Agrega más.";
            }
        }

        boolean habilitarContinuar = porcentaje >= MINIMO_APROBATORIO;
        boolean generarNuevoReto   = correcto || retoActual.agotadoIntentos();

        return new ResultadoComprobacion(
            correcto, porcentaje, mensaje,
            habilitarContinuar, generarNuevoReto, intento);
    }

    /** Carga el porcentaje previo. */
    public float cargarProgreso(int idUsuario) {
        return progresoDAO.obtenerPorcentaje(idUsuario, ID_ESCENARIO);
    }

    // ══════════════════════════════════════════════════════════════════════
    // DTOs
    // ══════════════════════════════════════════════════════════════════════

    public static class ResultadoReto {
        public final Reto        reto;
        public final ElementoBase elementoBase;
        public final Isotopo     isotopo;
        public final String      mensaje;
        public final boolean     error;

        public ResultadoReto(Reto reto, ElementoBase elementoBase,
                             Isotopo isotopo, String mensaje, boolean error) {
            this.reto         = reto;
            this.elementoBase = elementoBase;
            this.isotopo      = isotopo;
            this.mensaje      = mensaje;
            this.error        = error;
        }
    }

    public static class ResultadoComprobacion {
        public final boolean correcto;
        public final float   porcentaje;
        public final String  mensajeMascota;
        public final boolean habilitarContinuar;
        public final boolean generarNuevoReto;
        public final int     intentoUsado;

        public ResultadoComprobacion(boolean correcto, float porcentaje,
                                     String mensajeMascota,
                                     boolean habilitarContinuar,
                                     boolean generarNuevoReto,
                                     int intentoUsado) {
            this.correcto           = correcto;
            this.porcentaje         = porcentaje;
            this.mensajeMascota     = mensajeMascota;
            this.habilitarContinuar = habilitarContinuar;
            this.generarNuevoReto   = generarNuevoReto;
            this.intentoUsado       = intentoUsado;
        }
    }
}