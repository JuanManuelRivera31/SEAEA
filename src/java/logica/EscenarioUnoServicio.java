package logica;

import dao.ElementoBaseDAO;
import dao.PuntajeRetoDAO;
import dao.ProgresoEscenarioDAO;
import dao.RetoDAO;
import modelo.ElementoBase;
import modelo.Elemento;
import modelo.Escenario;
import modelo.PuntajeReto;
import modelo.Reto;
import modelo.Usuario;

/**
 * EscenarioUnoServicio
 * ─────────────────────────────────────────────────────────────
 * Capa de LÓGICA de negocio para el Escenario 1 "Arma tu átomo".
 * Se ubica entre el Controlador y el DAO.
 * No conoce HttpServletRequest ni Response; sólo trabaja con objetos
 * del dominio y devuelve DTOs/primitivos al controlador.
 */
public class EscenarioUnoServicio {

    private static final int ID_ESCENARIO   = 1;
    public  static final int MAX_INTENTOS   = 3;
    public  static final int TIEMPO_RETO    = 90;  // segundos
    public  static final float MINIMO_APROBATORIO = 80.0f;

    // ─── DAOs ──────────────────────────────────────────────────
    private final ElementoBaseDAO      elementoDAO  = new ElementoBaseDAO();
    private final RetoDAO              retoDAO      = new RetoDAO();
    private final PuntajeRetoDAO       puntajeDAO   = new PuntajeRetoDAO();
    private final ProgresoEscenarioDAO progresoDAO  = new ProgresoEscenarioDAO();

    // ══════════════════════════════════════════════════════════
    // PARTÍCULAS
    // ══════════════════════════════════════════════════════════

    /**
     * Incrementa la partícula indicada en el elemento activo.
     * @param escenario escenario en sesión
     * @param particula "protones" | "neutrones" | "electrones"
     * @return ElementoBase identificado si cambiaron los protones, null si no
     */
    public ElementoBase incrementar(Escenario escenario, String particula) {
        Elemento el = escenario.getElemento();
        switch (particula) {
            case "protones":
                el.incrementarProtones();
                return identificarElemento(escenario, el.getProtones());
            case "neutrones":
                el.incrementarNeutrones();
                break;
            case "electrones":
                el.incrementarElectrones();
                break;
        }
        return escenario.getElementoIdentificado();
    }

    /**
     * Decrementa la partícula indicada en el elemento activo.
     */
    public ElementoBase decrementar(Escenario escenario, String particula) {
        Elemento el = escenario.getElemento();
        switch (particula) {
            case "protones":
                el.decrementarProtones();
                return identificarElemento(escenario, el.getProtones());
            case "neutrones":
                el.decrementarNeutrones();
                break;
            case "electrones":
                el.decrementarElectrones();
                break;
        }
        return escenario.getElementoIdentificado();
    }

    /**
     * Identifica y actualiza el elemento del escenario según Z. (RF-105)
     */
    private ElementoBase identificarElemento(Escenario escenario, int protones) {
        ElementoBase eb = (protones > 0)
            ? elementoDAO.obtenerPorNumeroAtomico(protones)
            : null;
        escenario.actualizarCartaPeriodicaElemento(eb);
        return eb;
    }

    // ══════════════════════════════════════════════════════════
    // EVALUACIÓN
    // ══════════════════════════════════════════════════════════

    /**
     * Genera un nuevo reto aleatorio y lo persiste.
     * Devuelve el Reto listo para guardar en sesión. (RF-111)
     */
    public ResultadoReto generarReto(Usuario usuario) {
        // 1. Elemento aleatorio como objetivo
        ElementoBase ebObj = elementoDAO.obtenerAleatorio();
        if (ebObj == null) return null;

        // 2. Átomo objetivo: neutro estándar
        Elemento atomoObj = new Elemento(
            ebObj.getNumeroAtomico(),
            ebObj.getNumeroAtomico(),
            ebObj.getNumeroAtomico()
        );

        // 3. Construir Reto
        Reto reto = new Reto();
        reto.setIdUsuario(usuario.getIdUsuario());
        reto.setIdEscenario(ID_ESCENARIO);
        reto.generarReto(ebObj,
            atomoObj.getProtones(),
            atomoObj.getNeutrones(),
            atomoObj.getElectrones());

        // 4. Persistir y obtener ID
        int idReto = retoDAO.insertar(reto);
        reto.setIdReto(idReto);

        return new ResultadoReto(reto, atomoObj, null, false);
    }

    /**
     * Comprueba si la configuración del estudiante cumple el reto. (RF-115)
     * Actualiza intentos, calcula puntaje y porcentaje de aprendizaje.
     */
    public ResultadoComprobacion comprobar(Escenario escenario,
                                           Reto retoActual,
                                           Elemento atomoObjetivo,
                                           Usuario usuario) {
        Elemento atomoEstudiante = escenario.getElemento();
        boolean correcto = retoActual.comprobarReto(atomoEstudiante, atomoObjetivo);

        // Registrar intento
        retoActual.registrarIntento();
        int intento = retoActual.getIntentos();

        // Calcular puntaje (RF-116)
        PuntajeReto pr = new PuntajeReto(retoActual, intento, correcto);

        // Persistir intento
        puntajeDAO.insertar(retoActual.getIdReto(), intento, pr.getPuntaje(), correcto);

        if (correcto) retoActual.setCompletado(true);
        retoDAO.actualizar(retoActual);

        // Recalcular porcentaje de aprendizaje (RF-117)
        float porcentaje = puntajeDAO
            .calcularPorcentajeAprendizaje(usuario.getIdUsuario(), ID_ESCENARIO);
        progresoDAO.guardar(usuario.getIdUsuario(), ID_ESCENARIO, porcentaje);
        escenario.getProgreso().setPorcentajeAprendizaje(porcentaje);

        // Retroalimentación mascota (RF-118)
        String mensaje = retoActual.retroalimentacionComprobacion(correcto);

        boolean habilitarContinuar = porcentaje >= MINIMO_APROBATORIO;
        boolean generarNuevoReto   = correcto || retoActual.agotadoIntentos();

        return new ResultadoComprobacion(
            correcto, porcentaje, mensaje,
            habilitarContinuar, generarNuevoReto, intento
        );
    }

    /**
     * Carga el porcentaje previo del usuario para este escenario.
     */
    public float cargarProgreso(int idUsuario) {
        return progresoDAO.obtenerPorcentaje(idUsuario, ID_ESCENARIO);
    }

    /**
     * Verifica si el escenario ya fue superado anteriormente.
     */
    public boolean esSuperado(int idUsuario) {
        return progresoDAO.esSuperado(idUsuario, ID_ESCENARIO);
    }

    // ══════════════════════════════════════════════════════════
    // DTOs INTERNOS
    // ══════════════════════════════════════════════════════════

    /** Resultado de generar un reto */
    public static class ResultadoReto {
        public final Reto reto;
        public final Elemento atomoObjetivo;
        public final String mensaje;
        public final boolean error;

        public ResultadoReto(Reto reto, Elemento atomoObjetivo,
                             String mensaje, boolean error) {
            this.reto          = reto;
            this.atomoObjetivo = atomoObjetivo;
            this.mensaje       = mensaje;
            this.error         = error;
        }
    }

    /** Resultado de comprobar un reto */
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

