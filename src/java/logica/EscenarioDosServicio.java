package logica;
 
import dao.*;
import modelo.*;
 
/**
 * EscenarioDosServicio — Capa de lógica del Escenario 2
 * "Número y Núcleo Atómico"
 *
 * Responsabilidades:
 *  - Reglas de negocio: ponderación de porcentaje, validación de retos.
 *  - Coordinación de DAOs (ElementoBaseDAO, RetoDAO, PuntajeRetoDAO, ProgresoEscenarioDAO).
 *  - Generación y comprobación de retos.
 *
 * El Controlador SOLO llama a este servicio y publica resultados en request/sesión.
 */
public class EscenarioDosServicio {
 
    // ── DAOs ─────────────────────────────────────────────────────────────────
    private final ElementoBaseDAO      elementoDAO = new ElementoBaseDAO();
    private final RetoDAO              retoDAO     = new RetoDAO();
    private final PuntajeRetoDAO       puntajeDAO  = new PuntajeRetoDAO();
    private final ProgresoEscenarioDAO progresoDAO = new ProgresoEscenarioDAO();
 
    // ── Constantes de ponderación ────────────────────────────────────────────
    public static final float PCT_ACIERTO_1   =  20f;
    public static final float PCT_ACIERTO_2   =  13f;
    public static final float PCT_ACIERTO_3   =   7f;
    public static final float PCT_FALLO       =  -5f;
    public static final float PCT_AGOTADO     = -10f;
    public static final int   RETOS_MIN       =   3;
    public static final float PCT_MINIMO_CONT =  80f;
 
    private static final int ID_ESCENARIO = 2;
 
    // ════════════════════════════════════════════════════════════════════════
    //  RESULTADO DE COMPROBAR — DTO interno para devolver al controlador
    // ════════════════════════════════════════════════════════════════════════
    public static class ResultadoComprobar {
        public boolean correcto;
        public int     intento;
        public float   nuevoPct;
        public boolean agotado;
        public boolean nuevoRetoGenerado;
        public Reto    nuevoReto;
        public String  mensajeMascota;
        public String  descripcionNuevoReto;
        public boolean puedeContar;
    }
 
    // ════════════════════════════════════════════════════════════════════════
    //  MÉTODOS PÚBLICOS
    // ════════════════════════════════════════════════════════════════════════
 
    /**
     * Inicializa los contadores de sesión de evaluación:
     * porcentaje = 0, retosOk = 0.
     */
    public void iniciarEvaluacion(Escenario escenario) {
        escenario.iniciarEvaluacion();
    }
 
    /**
     * Genera un nuevo Reto aleatorio para el Escenario 2.
     * Crea el objeto Reto con intentos = 0, lo persiste en BD y lo devuelve.
     *
     * @param idUsuario ID del usuario en sesión
     * @return Reto recién creado (con idReto asignado) o null si no hay elementos
     */
    public Reto generarNuevoReto(int idUsuario) {
        ElementoBase ebObjetivo = elementoDAO.obtenerAleatorio();
        if (ebObjetivo == null) return null;
 
        int protonObjetivo  = ebObjetivo.getNumeroAtomico();
        int neutronObjetivo = ebObjetivo.getNumeroAtomico(); // núcleo estable: Z == N
 
        Reto reto = new Reto();
        reto.setIdUsuario(idUsuario);
        reto.setIdEscenario(ID_ESCENARIO);
        reto.generarReto(ebObjetivo, protonObjetivo, neutronObjetivo, 0);
        reto.setDescripcion(
            "Construye el núcleo del elemento " + ebObjetivo.getNombre()
            + " (" + ebObjetivo.getSimbolo() + ").\n\n"
            + "Necesitas:\n"
            + "🔵 " + protonObjetivo  + " protón(es)\n"
            + "🟡 " + neutronObjetivo + " neutrón(es)\n\n"
            + "Recuerda: Z = " + protonObjetivo
            + " define el elemento. A = " + (protonObjetivo + neutronObjetivo) + ".");
 
        int idReto = retoDAO.insertar(reto);
        reto.setIdReto(idReto);
        return reto;
    }
 
    /**
     * Devuelve el Elemento objetivo que corresponde al Reto generado.
     * Para el Escenario 2: protones = Z, neutrones = Z, electrones = 0.
     */
    public Elemento crearElementoObjetivo(Reto reto) {
        ElementoBase eb = reto.getElementoObjetivo();
        if (eb == null) return null;
        int z = eb.getNumeroAtomico();
        return new Elemento(z, z, 0);
    }
 
    /**
     * Comprueba si el átomo del estudiante coincide con el objetivo del reto.
     * Registra el intento, actualiza puntaje en BD, calcula porcentaje
     * y genera un nuevo reto si corresponde.
     *
     * @param escenario    estado actual del escenario
     * @param retoActual   reto en curso (con sus intentos propios)
     * @param retoObjetivo elemento que el estudiante debe replicar
     * @param pctActual    porcentaje acumulado en sesión antes de esta comprobación
     * @param retosOkActual retos acertados acumulados antes de esta comprobación
     * @param idUsuario    ID del usuario
     * @return ResultadoComprobar con todos los datos que el controlador necesita
     */
    public ResultadoComprobar comprobar(Escenario escenario,
                                        Reto retoActual,
                                        Elemento retoObjetivo,
                                        float pctActual,
                                        int retosOkActual,
                                        int idUsuario) {
 
        ResultadoComprobar res = new ResultadoComprobar();
 
        // Validar: si ya agotó intentos en este reto, generar uno nuevo
        if (retoActual.agotadoIntentos()) {
            res.nuevoRetoGenerado = true;
            res.nuevoReto = generarNuevoReto(idUsuario);
            if (res.nuevoReto != null) {
                res.descripcionNuevoReto = res.nuevoReto.getDescripcion();
            }
            res.nuevoPct  = pctActual;
            res.puedeContar = pctActual >= PCT_MINIMO_CONT && retosOkActual >= RETOS_MIN;
            res.mensajeMascota = "";
            return res;
        }
 
        // ── Comprobar ────────────────────────────────────────────────────────
        Elemento atomoEst = escenario.getElemento();
        res.correcto = atomoEst.getProtones()  == retoObjetivo.getProtones()
                    && atomoEst.getNeutrones() == retoObjetivo.getNeutrones();
 
        retoActual.registrarIntento();
        res.intento = retoActual.getIntentos();
        res.agotado = retoActual.agotadoIntentos();
 
        if (res.correcto) {
            // ── ACIERTO ──────────────────────────────────────────────────
            retoActual.setCompletado(true);
            retoDAO.actualizar(retoActual);
 
            double puntajeBD = res.intento == 1 ? 100.0 : res.intento == 2 ? 70.0 : 40.0;
            puntajeDAO.insertar(retoActual.getIdReto(), res.intento, (float) puntajeBD, true);
 
            float delta = res.intento == 1 ? PCT_ACIERTO_1
                        : res.intento == 2 ? PCT_ACIERTO_2 : PCT_ACIERTO_3;
            res.nuevoPct = clamp(pctActual + delta);
            progresoDAO.guardar(idUsuario, ID_ESCENARIO, res.nuevoPct);
 
            int retosOkNuevo = retosOkActual + 1;
            res.puedeContar  = retosOkNuevo >= RETOS_MIN && res.nuevoPct >= PCT_MINIMO_CONT;
 
            String nomElem = retoActual.getElementoObjetivo() != null
                           ? retoActual.getElementoObjetivo().getNombre() : "el elemento";
            String simb    = retoActual.getElementoObjetivo() != null
                           ? " (" + retoActual.getElementoObjetivo().getSimbolo() + ")" : "";
 
            res.mensajeMascota =
                "¡Correcto! Construiste el núcleo de " + nomElem + simb
                + " en el intento " + res.intento + ".\n\n"
                + "📈 +" + (int) delta + "% de aprendizaje. "
                + "Porcentaje actual: " + (int) res.nuevoPct + "%\n\n"
                + "Recuerda: Z = protones define el elemento. A = protones + neutrones.";
 
            if (!res.puedeContar) {
                res.nuevoRetoGenerado    = true;
                res.nuevoReto            = generarNuevoReto(idUsuario);
                if (res.nuevoReto != null)
                    res.descripcionNuevoReto = res.nuevoReto.getDescripcion();
            }
 
        } else {
            // ── FALLO ────────────────────────────────────────────────────
            puntajeDAO.insertar(retoActual.getIdReto(), res.intento, 0f, false);
 
            if (res.agotado) {
                // Reto agotado
                retoDAO.actualizar(retoActual);
                res.nuevoPct = clamp(pctActual + PCT_AGOTADO);
                progresoDAO.guardar(idUsuario, ID_ESCENARIO, res.nuevoPct);
 
                res.mensajeMascota =
                    "Se agotaron los 3 intentos para este reto.\n\n"
                    + "📉 " + (int) PCT_AGOTADO + "% de aprendizaje. "
                    + "Porcentaje actual: " + (int) res.nuevoPct + "%\n\n"
                    + "El reto pedía: " + retoObjetivo.getProtones()
                    + " protón(es) y " + retoObjetivo.getNeutrones()
                    + " neutrón(es).\n¡Sigue practicando!";
 
                res.nuevoRetoGenerado    = true;
                res.nuevoReto            = generarNuevoReto(idUsuario);
                if (res.nuevoReto != null)
                    res.descripcionNuevoReto = res.nuevoReto.getDescripcion();
 
            } else {
                // Intento fallido, quedan más
                res.nuevoPct = clamp(pctActual + PCT_FALLO);
                int restantes = Reto.MAX_INTENTOS - res.intento;
                res.mensajeMascota =
                    "Esa configuración no es correcta.\n\n"
                    + "📉 " + (int) PCT_FALLO + "% de aprendizaje. "
                    + "Porcentaje actual: " + (int) res.nuevoPct + "%\n\n"
                    + "Recuerda: el reto pide un número específico de protones y neutrones.\n"
                    + "Te quedan " + restantes + " intento(s).";
            }
 
            res.puedeContar = res.nuevoPct >= PCT_MINIMO_CONT
                           && retosOkActual >= RETOS_MIN;
        }
 
        return res;
    }
 
    /**
     * Obtiene el elemento de la BD por número atómico.
     * Usado cuando el controlador necesita identificar el elemento actual.
     */
    public ElementoBase obtenerElementoPorZ(int z) {
        if (z <= 0) return null;
        return elementoDAO.obtenerPorNumeroAtomico(z);
    }
 
    /**
     * Guarda el progreso en BD (llamado al finalizar evaluación).
     */
    public void guardarProgreso(int idUsuario, float porcentaje) {
        progresoDAO.guardar(idUsuario, ID_ESCENARIO, porcentaje);
    }
 
    // ── Helper ───────────────────────────────────────────────────────────────
    private float clamp(float v) {
        return Math.max(0f, Math.min(100f, v));
    }
}