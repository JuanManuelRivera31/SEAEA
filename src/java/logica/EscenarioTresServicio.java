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
 * Capa de LÓGICA de negocio para el Escenario 3 "Configura tu Átomo Objetivo".
 *
 * POSICIÓN EN LA ARQUITECTURA MVC:
 *   Controlador → EscenarioTresServicio → DAO → ConexionDB → BD
 *                                       ← modelo.*
 *
 * El servicio es el ÚNICO que conoce los DAOs.
 * El controlador SOLO habla con este servicio a través de los DTOs.
 *
 * Regla de comprobación Escenario 3:
 *   Se valida Z (protones) y A (número másico). Los electrones NO se evalúan.
 */
public class EscenarioTresServicio {

    private static final int   ID_ESCENARIO       = 3;
    public  static final float MINIMO_APROBATORIO = 80.0f;

    // DAOs: solo la capa lógica los conoce
    private final ElementoBaseDAO      elementoDAO = new ElementoBaseDAO();
    private final RetoDAO              retoDAO     = new RetoDAO();
    private final PuntajeRetoDAO       puntajeDAO  = new PuntajeRetoDAO();
    private final ProgresoEscenarioDAO progresoDAO = new ProgresoEscenarioDAO();

    // ── PARTÍCULAS ──────────────────────────────────────────────────────────

    public ElementoBase incrementar(Escenario escenario, String particula) {
        Elemento el = escenario.getElemento();
        switch (particula) {
            case "protones":
                el.incrementarProtones();
                return identificarElemento(escenario, el.getProtones());
            case "neutrones":  el.incrementarNeutrones();  break;
            case "electrones": el.incrementarElectrones(); break;
        }
        return escenario.getElementoIdentificado();
    }

    public ElementoBase decrementar(Escenario escenario, String particula) {
        Elemento el = escenario.getElemento();
        switch (particula) {
            case "protones":
                el.decrementarProtones();
                return identificarElemento(escenario, el.getProtones());
            case "neutrones":  el.decrementarNeutrones();  break;
            case "electrones": el.decrementarElectrones(); break;
        }
        return escenario.getElementoIdentificado();
    }

    private ElementoBase identificarElemento(Escenario escenario, int protones) {
        ElementoBase eb = protones > 0
            ? elementoDAO.obtenerPorNumeroAtomico(protones) : null;
        escenario.actualizarCartaPeriodicaElemento(eb);
        return eb;
    }

    // ── PROGRESO ────────────────────────────────────────────────────────────

    public float cargarProgreso(int idUsuario) {
        return progresoDAO.obtenerPorcentaje(idUsuario, ID_ESCENARIO);
    }

    // ── GENERACIÓN DE RETO ──────────────────────────────────────────────────

    /**
     * Genera un reto aleatorio:
     * 1. Obtiene ElementoBase aleatorio de BD.
     * 2. Calcula Z, A = round(masaAtomica), N = A - Z.
     * 3. Crea y persiste el Reto en BD.
     * 4. Devuelve ResultadoReto con reto y átomo objetivo.
     */
    public ResultadoReto generarReto(Usuario usuario) {
        ElementoBase ebObj = elementoDAO.obtenerAleatorio();
        if (ebObj == null) return null;

        int z = ebObj.getNumeroAtomico();
        int a = (int) Math.round(ebObj.getMasaAtomica());
        int n = Math.max(0, a - z);

        Elemento atomoObjetivo = new Elemento(z, n, z);

        Reto reto = new Reto();
        reto.setIdUsuario(usuario.getIdUsuario());
        reto.setIdEscenario(ID_ESCENARIO);
        reto.generarReto(ebObj, z, n, z);

        int idReto = retoDAO.insertar(reto);
        reto.setIdReto(idReto);

        return new ResultadoReto(reto, atomoObjetivo, null, false);
    }

    // ── COMPROBACIÓN ────────────────────────────────────────────────────────

    /**
     * Comprueba Z y A del estudiante contra el objetivo.
     * Registra intento, persiste puntaje y porcentaje en BD.
     */
    public ResultadoComprobacion comprobar(Escenario escenario,
                                           Reto retoActual,
                                           Elemento atomoObjetivo,
                                           Usuario usuario) {
        Elemento est = escenario.getElemento();

        boolean zCorrecta = est.getProtones()     == atomoObjetivo.getProtones();
        boolean aCorrecta = est.getNumeroMasico() == atomoObjetivo.getNumeroMasico();
        boolean correcto  = zCorrecta && aCorrecta;

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

        String mensaje = construirMensaje(correcto, zCorrecta, aCorrecta,
                retoActual, atomoObjetivo, intento);

        boolean habilitarContinuar = porcentaje >= MINIMO_APROBATORIO;
        boolean generarNuevoReto   = correcto || retoActual.agotadoIntentos();

        return new ResultadoComprobacion(correcto, porcentaje, mensaje,
                habilitarContinuar, generarNuevoReto, intento);
    }

    private String construirMensaje(boolean correcto, boolean zCorrecta,
                                     boolean aCorrecta, Reto reto,
                                     Elemento objetivo, int intento) {
        if (correcto) {
            ElementoBase eb = reto.getElementoObjetivo();
            String nom = eb != null
                ? eb.getNombre() + " (" + eb.getSimbolo() + ")" : "el elemento";
            return "¡Lo lograste! Configuraste correctamente el átomo de "
                + nom + " en el intento " + intento + ".\n"
                + "Z = " + objetivo.getProtones()
                + " · A = " + objetivo.getNumeroMasico()
                + " · N = " + objetivo.getNeutrones() + ".\n"
                + "Recuerda: A = Z + N";
        }
        if (reto.agotadoIntentos()) {
            return "Agotaste los 3 intentos. ¡No te rindas!\n"
                + "He generado un nuevo reto para continuar aprendiendo.";
        }
        int restantes = Reto.MAX_INTENTOS - intento;
        String pista;
        if (!zCorrecta && !aCorrecta) {
            pista = "Tanto Z (protones) como A (número másico) son incorrectos.";
        } else if (!zCorrecta) {
            pista = "El número atómico Z (protones) no es correcto.";
        } else {
            pista = "El número másico A no es correcto. Revisa los neutrones (A = Z + N).";
        }
        return "Configuración incorrecta. " + pista
            + "\nTe quedan " + restantes + " intento(s).";
    }

    // ── DTOs ────────────────────────────────────────────────────────────────

    public static class ResultadoReto {
        public final Reto     reto;
        public final Elemento atomoObjetivo;
        public final String   mensaje;
        public final boolean  error;
        public ResultadoReto(Reto r, Elemento a, String m, boolean e) {
            reto=r; atomoObjetivo=a; mensaje=m; error=e;
        }
    }

    public static class ResultadoComprobacion {
        public final boolean correcto;
        public final float   porcentaje;
        public final String  mensajeMascota;
        public final boolean habilitarContinuar;
        public final boolean generarNuevoReto;
        public final int     intentoUsado;
        public ResultadoComprobacion(boolean c, float p, String m,
                                     boolean hc, boolean gnr, int iu) {
            correcto=c; porcentaje=p; mensajeMascota=m;
            habilitarContinuar=hc; generarNuevoReto=gnr; intentoUsado=iu;
        }
    }
}
