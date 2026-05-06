package controlador;

import logica.EscenarioCincoServicio;
import logica.EscenarioCincoServicio.*;
import modelo.ElementoBase;
import modelo.Escenario;
import modelo.Reto;
import modelo.Usuario;

import jakarta.servlet.ServletException;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import jakarta.servlet.http.HttpSession;
import java.io.IOException;
import java.util.LinkedHashMap;
import java.util.Map;

/**
 * EscenarioCincoControlador
 * ─────────────────────────────────────────────────────────────────────────
 * Controlador del Escenario 5 "Configuración Electrónica".
 *
 * Responsabilidades ÚNICAS (MVC):
 *  1. Verificar sesión activa.
 *  2. Leer parámetros del request (acción, subnivel, celda, Z).
 *  3. Recuperar/crear el Escenario desde sesión.
 *  4. Delegar TODO el procesamiento a EscenarioCincoServicio.
 *  5. Almacenar resultados en sesión/request (publicarDatos).
 *  6. Forward al JSP o redirect según corresponda.
 *
 * El controlador NO contiene lógica de negocio.
 * El controlador NO importa ni usa DAOs directamente.
 *
 * NOTA: Sin @WebServlet porque web.xml tiene metadata-complete="true".
 */
public class EscenarioCincoControlador extends HttpServlet {

    // ── Único acceso a la capa lógica ─────────────────────────────────────
    private final EscenarioCincoServicio servicio = new EscenarioCincoServicio();

    // ── Claves de sesión ─────────────────────────────────────────────────
    private static final String SK_ESC        = "escenario5";
    private static final String SK_ELEM_SELEC = "elemSelec5";
    private static final String SK_ELEM_EVAL  = "elemEval5";
    private static final String SK_CONFIG     = "configUsuario5";
    private static final String SK_RESULTADO  = "resultadoConfig5";
    private static final String SK_RETO       = "retoActual5";

    // ── Vista ─────────────────────────────────────────────────────────────
    private static final String JSP = "/escenario5/escenario5.jsp";

    @Override
    protected void doGet(HttpServletRequest req, HttpServletResponse resp)
            throws ServletException, IOException { procesar(req, resp); }

    @Override
    protected void doPost(HttpServletRequest req, HttpServletResponse resp)
            throws ServletException, IOException { procesar(req, resp); }

    // ════════════════════════════════════════════════════════════════════════
    // DISPATCHER CENTRAL
    // ════════════════════════════════════════════════════════════════════════

    private void procesar(HttpServletRequest req, HttpServletResponse resp)
            throws ServletException, IOException {

        // 1. Verificar sesión
        HttpSession sesion = req.getSession(false);
        if (sesion == null || sesion.getAttribute("usuario") == null) {
            resp.sendRedirect(req.getContextPath() + "/login");
            return;
        }

        Usuario   usuario   = (Usuario)   sesion.getAttribute("usuario");
        Escenario escenario = obtenerOCrearEscenario(sesion);

        String accion = req.getParameter("accion");
        if (accion == null) accion = "cargar";

        // 2. Delegar al servicio según acción
        switch (accion) {
            case "cargar":              accionCargar(escenario, usuario, req, sesion);       break;
            case "seleccionarElemento": accionSeleccionarElemento(req, sesion);               break;
            case "clickCelda":          accionClickCelda(req, sesion);                        break;
            case "reiniciar":           accionReiniciar(escenario, sesion);                   break;
            case "comprobar":           accionComprobar(escenario, usuario, req, sesion);     break;
            case "iniciarEval":         accionIniciarEval(escenario, usuario, req, sesion);   break;
            case "continuar":           accionContinuar(escenario, sesion, resp); return;
            case "finalizar":           accionFinalizar(escenario, sesion, req);              break;
            case "volver":              accionVolver(escenario, sesion, resp); return;
            default:                    accionCargar(escenario, usuario, req, sesion);
        }

        // 3. Guardar escenario actualizado
        sesion.setAttribute(SK_ESC, escenario);

        // 4. Publicar atributos para el JSP
        publicarDatos(escenario, req, sesion);

        // 5. Forward al JSP
        req.getRequestDispatcher(JSP).forward(req, resp);
    }

    // ════════════════════════════════════════════════════════════════════════
    // ACCIONES
    // ════════════════════════════════════════════════════════════════════════

    /** Carga inicial: progreso + mensaje de bienvenida de la mascota. */
    private void accionCargar(Escenario escenario, Usuario usuario,
                               HttpServletRequest req, HttpSession sesion) {
        ResultadoCarga r = servicio.cargar(escenario, usuario);
        req.setAttribute("mensajeMascota", r.mensajeMascota);
        sesion.setAttribute(SK_ESC, escenario);
    }

    /**
     * Seleccionar elemento: valida bloque s/p y actualiza sesión.
     * Si el elemento no es válido, pone mensaje de error.
     */
    private void accionSeleccionarElemento(HttpServletRequest req, HttpSession sesion) {
        String zStr = req.getParameter("numeroAtomico");
        if (zStr == null) return;
        int z;
        try { z = Integer.parseInt(zStr); } catch (NumberFormatException e) { return; }

        ElementoBase eb = servicio.seleccionarElemento(z);
        if (eb == null) {
            // Elemento de bloque d/f o no encontrado
            String bloque = servicio.obtenerBloqueElemento(z);
            req.setAttribute("mensajeMascota",
                "Este elemento es de bloque " + bloque
                + ". En este escenario solo se trabaja con elementos de bloque s y p.");
            return;
        }

        sesion.setAttribute(SK_ELEM_SELEC, eb);
        // Limpiar configuración anterior al cambiar de elemento
        sesion.removeAttribute(SK_CONFIG);
        sesion.removeAttribute(SK_RESULTADO);
    }

    /**
     * Click en celda del diagrama: cicla el estado 0→1→2→0.
     * Delega al servicio y persiste el mapa actualizado en sesión.
     */
    @SuppressWarnings("unchecked")
    private void accionClickCelda(HttpServletRequest req, HttpSession sesion) {
        String subnivel  = req.getParameter("subnivel");
        String celdaStr  = req.getParameter("celda");
        if (subnivel == null || celdaStr == null) return;
        int celda;
        try { celda = Integer.parseInt(celdaStr); } catch (NumberFormatException e) { return; }

        Map<String, int[]> config = (Map<String, int[]>) sesion.getAttribute(SK_CONFIG);
        if (config == null) config = new LinkedHashMap<>();

        // El servicio actualiza el mapa y lo retorna
        config = servicio.ciclarCelda(config, subnivel, celda);

        sesion.setAttribute(SK_CONFIG,    config);
        sesion.removeAttribute(SK_RESULTADO); // limpiar resultado anterior al modificar
    }

    /** Reiniciar: limpia estado completo. */
    private void accionReiniciar(Escenario escenario, HttpSession sesion) {
        servicio.reiniciar(escenario);
        sesion.removeAttribute(SK_ELEM_SELEC);
        sesion.removeAttribute(SK_CONFIG);
        sesion.removeAttribute(SK_RESULTADO);
        sesion.removeAttribute(SK_RETO);
        sesion.removeAttribute(SK_ELEM_EVAL);
    }

    /**
     * Comprobar: delega al servicio según modo (simulación o evaluación).
     * El servicio retorna el DTO con todo el resultado; el controlador
     * lo publica como atributos de request/sesión.
     */
    @SuppressWarnings("unchecked")
    private void accionComprobar(Escenario escenario, Usuario usuario,
                                  HttpServletRequest req, HttpSession sesion) {
        boolean modoEval = escenario.isModoEvaluacion();
        Map<String, int[]> config = (Map<String, int[]>) sesion.getAttribute(SK_CONFIG);

        if (modoEval) {
            // ── Modo evaluación ───────────────────────────────────────────
            Reto         retoActual = (Reto)         sesion.getAttribute(SK_RETO);
            ElementoBase eb         = (ElementoBase) sesion.getAttribute(SK_ELEM_EVAL);

            ResultadoComprobacion r = servicio.comprobar(
                escenario, retoActual, eb, config, usuario);

            // Publicar resultado
            sesion.setAttribute(SK_RETO, retoActual);
            sesion.setAttribute(SK_RESULTADO, r.correcto ? "ok" : "err");

            req.setAttribute("resultadoCorrecto",  r.correcto);
            req.setAttribute("intentosUsados",     r.intentoUsado);
            req.setAttribute("mensajeMascota",     r.mensajeMascota);
            req.setAttribute("habilitarContinuar", r.habilitarContinuar);

            if (r.habilitarContinuar) {
                // Porcentaje suficiente → no generar nuevo reto
            } else if (r.generarNuevoReto) {
                generarYPublicarReto(escenario, usuario, req, sesion);
            }

        } else {
            // ── Modo simulación ───────────────────────────────────────────
            ElementoBase eb = (ElementoBase) sesion.getAttribute(SK_ELEM_SELEC);

            ResultadoSimulacion r = servicio.comprobarSimulacion(eb, config);

            sesion.setAttribute(SK_RESULTADO, r.estadoConfig);
            req.setAttribute("mensajeMascota", r.mensajeMascota);
        }
    }

    /** Iniciar evaluación: activa modo y genera primer reto. */
    private void accionIniciarEval(Escenario escenario, Usuario usuario,
                                    HttpServletRequest req, HttpSession sesion) {
        servicio.iniciarEvaluacion(escenario);
        generarYPublicarReto(escenario, usuario, req, sesion);
    }

    /** Continuar: si superó el umbral → marca superado → redirige al siguiente escenario. */
    private void accionContinuar(Escenario escenario, HttpSession sesion,
                                  HttpServletResponse resp) throws IOException {
        if (servicio.puedeSuperar(escenario)) {
            servicio.superar(escenario);
            sesion.removeAttribute(SK_ESC);
            resp.sendRedirect("escenario6"); // progresión correcta
        } else {
            resp.sendRedirect("escenario5");
        }
    }

    /** Finalizar evaluación: desactiva modo eval y limpia estado. */
    private void accionFinalizar(Escenario escenario, HttpSession sesion,
                                  HttpServletRequest req) {
        String mensaje = servicio.finalizar(escenario);
        limpiarEvaluacion(sesion);
        req.setAttribute("mensajeMascota", mensaje);
    }

    /** Volver: sale del escenario y redirige al menú. */
    private void accionVolver(Escenario escenario, HttpSession sesion,
                               HttpServletResponse resp) throws IOException {
        servicio.salir(escenario);
        sesion.removeAttribute(SK_ESC);
        resp.sendRedirect("menu"); // corregido: era "login.jsp"
    }

    // ════════════════════════════════════════════════════════════════════════
    // HELPERS DEL CONTROLADOR
    // ════════════════════════════════════════════════════════════════════════

    /**
     * Llama al servicio para generar un reto y publica los atributos
     * en request/sesión para que el JSP los reciba.
     */
    private void generarYPublicarReto(Escenario escenario, Usuario usuario,
                                       HttpServletRequest req, HttpSession sesion) {
        ResultadoReto r = servicio.generarReto(usuario);
        if (r == null) return;

        escenario.setRetoActual(r.reto);

        sesion.setAttribute(SK_RETO,      r.reto);
        sesion.setAttribute(SK_ELEM_EVAL, r.elementoBase);
        sesion.removeAttribute(SK_CONFIG);
        sesion.removeAttribute(SK_RESULTADO);

        req.setAttribute("nuevoReto",       true);
        req.setAttribute("retoActual",      r.reto);
        req.setAttribute("descripcionReto", r.reto.getDescripcion());
        req.setAttribute("temporizador",    r.reto.getTemporizador());
        req.setAttribute("intentosUsados",  0);
        req.setAttribute("retoId",          String.valueOf(r.reto.getIdReto()));
    }

    /**
     * Publica TODOS los datos que el JSP necesita como atributos de request.
     * Único punto de comunicación controlador → JSP.
     */
    @SuppressWarnings("unchecked")
    private void publicarDatos(Escenario escenario, HttpServletRequest req,
                                HttpSession sesion) {
        // Porcentaje y modo
        int pct = Math.round(escenario.getProgreso().getPorcentajeAprendizaje());
        req.setAttribute("porcentaje",        pct);
        req.setAttribute("modoEvaluacion",    escenario.isModoEvaluacion());
        req.setAttribute("habilitarContinuar",
            escenario.getProgreso().getPorcentajeAprendizaje() >= EscenarioCincoServicio.MINIMO_APROBATORIO
            && escenario.isModoEvaluacion());

        // Lista de elementos (solo s y p) para la tabla periódica
        req.setAttribute("elementosPeriodica", servicio.obtenerElementosSP());

        // Elemento activo según modo
        boolean modoEval = escenario.isModoEvaluacion();
        ElementoBase ebActual = modoEval
            ? (ElementoBase) sesion.getAttribute(SK_ELEM_EVAL)
            : (ElementoBase) sesion.getAttribute(SK_ELEM_SELEC);
        req.setAttribute("elemActual", ebActual);

        // Z seleccionado para marcar la celda en la tabla
        int zSelec = (ebActual != null) ? ebActual.getNumeroAtomico() : 0;
        req.setAttribute("zSeleccionado", zSelec);

        // Configuración actual del usuario
        Map<String, int[]> config = (Map<String, int[]>) sesion.getAttribute(SK_CONFIG);
        if (config == null) config = new LinkedHashMap<>();
        req.setAttribute("configUsuario", config);

        // Total de electrones colocados (lo calcula el servicio)
        req.setAttribute("electronesColocados", servicio.contarElectrones(config));

        // Configuración correcta y notación (si hay elemento seleccionado)
        if (ebActual != null) {
            Map<String, Integer> correcta =
                EscenarioCincoServicio.calcularConfiguracion(ebActual.getNumeroAtomico());
            req.setAttribute("configCorrecta",  correcta);
            req.setAttribute("notacionCorrecta",
                EscenarioCincoServicio.construirNotacion(correcta));
        }

        // Resultado de la última comprobación ("ok" / "err" / null)
        req.setAttribute("resultadoConfig", sesion.getAttribute(SK_RESULTADO));

        // HUD del reto activo (si no fue ya publicado por la acción)
        Reto ra = (Reto) sesion.getAttribute(SK_RETO);
        if (ra != null && req.getAttribute("retoActual") == null) {
            req.setAttribute("retoActual",     ra);
            req.setAttribute("temporizador",   ra.getTemporizador());
            req.setAttribute("intentosUsados", ra.getIntentos());
            if (req.getAttribute("descripcionReto") == null)
                req.setAttribute("descripcionReto", ra.getDescripcion());
            req.setAttribute("retoId", String.valueOf(ra.getIdReto()));
        }
        if (req.getAttribute("retoId") == null)
            req.setAttribute("retoId", "");
    }

    // ── Limpieza de sesión ────────────────────────────────────────────────

    private void limpiarEvaluacion(HttpSession sesion) {
        sesion.removeAttribute(SK_RETO);
        sesion.removeAttribute(SK_ELEM_EVAL);
        sesion.removeAttribute(SK_CONFIG);
        sesion.removeAttribute(SK_RESULTADO);
    }

    // ── Obtener o crear el Escenario desde sesión ─────────────────────────
    private Escenario obtenerOCrearEscenario(HttpSession sesion) {
        Escenario esc = (Escenario) sesion.getAttribute(SK_ESC);
        if (esc == null)
            esc = new Escenario(EscenarioCincoServicio.ID_ESCENARIO,
                                "Configuración Electrónica", 3);
        return esc;
    }
}