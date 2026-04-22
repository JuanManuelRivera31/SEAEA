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
 * EscenarioTresServicio
 * ─────────────────────────────────────────────────────────────────────────
 * Capa de LÓGICA de negocio para el Escenario 3 "Configura tu Átomo Objetivo".
 *
 * Diferencia clave respecto al Escenario 1:
 *   La comprobación evalúa ÚNICAMENTE:
 *     • Número atómico Z  (protones del estudiante == protones del objetivo)
 *     • Número másico A   (protones+neutrones del estudiante == A del objetivo)
 *   Los electrones NO se evalúan.
 *
 * El átomo objetivo se construye usando:
 *     Z = numero_atomico del ElementoBase
 *     A = round(masa_atomica) del ElementoBase
 *     N = A - Z
 */
public class EscenarioTresServicio {

    private static final int   ID_ESCENARIO        = 3;
    public  static final int   MAX_INTENTOS        = 3;
    public  static final int   TIEMPO_RETO         = 90;   // segundos
    public  static final float MINIMO_APROBATORIO  = 80.0f;

    // ─── DAOs ──────────────────────────────────────────────────────────────
    private final ElementoBaseDAO      elementoDAO  = new ElementoBaseDAO();
    private final RetoDAO              retoDAO      = new RetoDAO();
    private final PuntajeRetoDAO       puntajeDAO   = new PuntajeRetoDAO();
    private final ProgresoEscenarioDAO progresoDAO  = new ProgresoEscenarioDAO();

    // ══════════════════════════════════════════════════════════════════════
    // PARTÍCULAS
    // ══════════════════════════════════════════════════════════════════════

    /**
     * Incrementa la partícula indicada en el elemento activo.
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

    private ElementoBase identificarElemento(Escenario escenario, int protones) {
        ElementoBase eb = (protones > 0)
            ? elementoDAO.obtenerPorNumeroAtomico(protones)
            : null;
        escenario.actualizarCartaPeriodicaElemento(eb);
        return eb;
    }

    // ══════════════════════════════════════════════════════════════════════
    // EVALUACIÓN
    // ══════════════════════════════════════════════════════════════════════

    /**
     * Genera un nuevo reto aleatorio usando un elemento de la tabla periódica.
     * El objetivo se define por Z (número atómico) y A (número másico = round(masa)).
     */
    public ResultadoReto generarReto(Usuario usuario) {
        ElementoBase ebObj = elementoDAO.obtenerAleatorio();
        if (ebObj == null) return null;

        int z = ebObj.getNumeroAtomico();
        int a = (int) Math.round(ebObj.getMasaAtomica());
        int n = a - z;
        if (n < 0) n = z; // fallback

        // Átomo objetivo: electrones = z (neutro) pero no se evalúan
        Elemento atomoObj = new Elemento(z, n, z);

        Reto reto = new Reto();
        reto.setIdUsuario(usuario.getIdUsuario());
        reto.setIdEscenario(ID_ESCENARIO);
        reto.generarReto(ebObj, z, n, z);

        int idReto = retoDAO.insertar(reto);
        reto.setIdReto(idReto);

        return new ResultadoReto(reto, atomoObj, null, false);
    }

    /**
     * Comprueba si la configuración del estudiante cumple el reto del Escenario 3.
     * Criterio: Z y A correctos (electrones ignorados).
     */
    public ResultadoComprobacion comprobar(Escenario escenario,
                                           Reto retoActual,
                                           Elemento atomoObjetivo,
                                           Usuario usuario) {
        Elemento est = escenario.getElemento();

        boolean correcto = (est.getProtones()     == atomoObjetivo.getProtones()) &&
                           (est.getNumeroMasico() == atomoObjetivo.getNumeroMasico());

        retoActual.registrarIntento();
        int intento = retoActual.getIntentos();

        PuntajeReto pr = new PuntajeReto(retoActual, intento, correcto);
        puntajeDAO.insertar(retoActual.getIdReto(), intento, pr.getPuntaje(), correcto);

        if (correcto) retoActual.setCompletado(true);
        retoDAO.actualizar(retoActual);

        float porcentaje = puntajeDAO
            .calcularPorcentajeAprendizaje(usuario.getIdUsuario(), ID_ESCENARIO);
        progresoDAO.guardar(usuario.getIdUsuario(), ID_ESCENARIO, porcentaje);
        escenario.getProgreso().setPorcentajeAprendizaje(porcentaje);

        // Mensaje de retroalimentación con pistas
        String mensaje;
        if (correcto) {
            ElementoBase eb = retoActual.getElementoObjetivo();
            String nom = eb != null ? eb.getNombre() + " (" + eb.getSimbolo() + ")" : "el elemento";
            mensaje = "¡Correcto! Configuraste " + nom
                    + " con Z=" + atomoObjetivo.getProtones()
                    + " y A=" + atomoObjetivo.getNumeroMasico()
                    + " en el intento " + intento + ".";
        } else {
            boolean zOk = est.getProtones()     == atomoObjetivo.getProtones();
            boolean aOk = est.getNumeroMasico() == atomoObjetivo.getNumeroMasico();
            if (!zOk && !aOk) {
                mensaje = "Tanto Z como A son incorrectos. Revisa protones y neutrones.";
            } else if (!zOk) {
                mensaje = "El número atómico Z (protones) no es correcto.";
            } else {
                mensaje = "El número másico A (protones + neutrones) no es correcto. Revisa los neutrones.";
            }
        }

        boolean habilitarContinuar = porcentaje >= MINIMO_APROBATORIO;
        boolean generarNuevoReto   = correcto || retoActual.agotadoIntentos();

        return new ResultadoComprobacion(
            correcto, porcentaje, mensaje,
            habilitarContinuar, generarNuevoReto, intento
        );
    }

    /** Carga el porcentaje previo del usuario para este escenario. */
    public float cargarProgreso(int idUsuario) {
        return progresoDAO.obtenerPorcentaje(idUsuario, ID_ESCENARIO);
    }

    /** Verifica si el escenario ya fue superado anteriormente. */
    public boolean esSuperado(int idUsuario) {
        return progresoDAO.esSuperado(idUsuario, ID_ESCENARIO);
    }

    // ══════════════════════════════════════════════════════════════════════
    // DTOs INTERNOS
    // ══════════════════════════════════════════════════════════════════════

    /** Resultado de generar un reto */
    public static class ResultadoReto {
        public final Reto     reto;
        public final Elemento atomoObjetivo;
        public final String   mensaje;
        public final boolean  error;

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

