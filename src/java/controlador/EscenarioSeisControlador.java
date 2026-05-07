package controlador;
 
import logica.EscenarioSeisServicio;
import logica.EscenarioSeisServicio.*;
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
 
/**
 * EscenarioSeisControlador
 * ─────────────────────────────────────────────────────────────────────────
 * Controlador del Escenario 6 "Propiedades Periódicas de los Elementos".
 *
 * Responsabilidades ÚNICAS del controlador (MVC):
 *  1. Verificar sesión activa.
 *  2. Leer parámetros del request (acción, valores del formulario).
 *  3. Recuperar/crear el objeto Escenario de la sesión.
 *  4. Delegar TODO el procesamiento a EscenarioSeisServicio.
 *  5. Almacenar resultados en sesión/request (publicarDatos).
 *  6. Hacer forward al JSP o redirect según corresponda.
 *
 * El controlador NO contiene lógica de negocio.
 * El controlador NO importa ni usa DAOs directamente.
 *
 * NOTA: Sin @WebServlet porque web.xml tiene metadata-complete="true".
 *       El mapeo /escenario6 se declara en web.xml.
 */
public class EscenarioSeisControlador extends HttpServlet {
 
    // ── Único acceso a la capa lógica ─────────────────────────────────────
    private final EscenarioSeisServicio servicio = new EscenarioSeisServicio();
 
    // ── Claves de sesión (centralizadas para evitar typos) ────────────────
    private static final String SK_ESC      = "escenario6";
    private static final String SK_ELEM_A   = "elemA6";
    private static final String SK_ELEM_B   = "elemB6";
    private static final String SK_ELEM_AE  = "elemAEval6";
    private static final String SK_ELEM_BE  = "elemBEval6";
    private static final String SK_RETO     = "retoActual6";
    private static final String SK_RADIO    = "respRadio6";
    private static final String SK_IONIZ    = "respIoniz6";
    private static final String SK_ELECTR   = "respElectr6";
    private static final String SK_RESULT   = "resultSimul6";
 
    // ── Vista ─────────────────────────────────────────────────────────────
    private static final String JSP = "/escenario6/escenario6.jsp";
 
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
 
        Usuario  usuario   = (Usuario) sesion.getAttribute("usuario");
        Escenario escenario = obtenerOCrearEscenario(sesion);
 
        String accion = req.getParameter("accion");
        if (accion == null) accion = "cargar";
 
        // 2. Delegar acción al servicio
        switch (accion) {
            case "cargar":               accionCargar(escenario, usuario, req, sesion);            break;
            case "seleccionarElemento":  accionSeleccionarElemento(req, sesion);                   break;
            case "reiniciar":            accionReiniciar(escenario, sesion);                        break;
            case "comprobarSimulacion":  accionComprobarSimulacion(req, sesion);                    break;
            case "iniciarEval":          accionIniciarEval(escenario, usuario, req, sesion);        break;
            case "comprobar":            accionComprobar(escenario, usuario, req, sesion);          break;
            case "continuar":            accionContinuar(escenario, sesion, resp); return;
            case "finalizar":            accionFinalizar(escenario, sesion, req);                   break;
            case "volver":               accionVolver(escenario, sesion, resp); return;
            default:                     accionCargar(escenario, usuario, req, sesion);
        }
 
        // 3. Guardar escenario actualizado en sesión
        sesion.setAttribute(SK_ESC, escenario);
 
        // 4. Publicar todos los datos necesarios para el JSP
        publicarDatos(escenario, req, sesion);
 
        // 5. Forward al JSP
        req.getRequestDispatcher(JSP).forward(req, resp);
    }
 
    // ════════════════════════════════════════════════════════════════════════
    // ACCIONES — solo leen parámetros, llaman servicio, guardan en sesión/request
    // ════════════════════════════════════════════════════════════════════════
 
    /** Carga inicial: obtiene progreso y mensaje de bienvenida de la mascota. */
    private void accionCargar(Escenario escenario, Usuario usuario,
                               HttpServletRequest req, HttpSession sesion) {
        ResultadoCarga r = servicio.cargar(escenario, usuario);
        req.setAttribute("mensajeMascota", r.mensajeMascota);
        sesion.setAttribute(SK_ESC, escenario);
    }
 
    /** Toggle A/B: delega al servicio y actualiza sesión con los nuevos elementos. */
    // ── CASO DE USO 1: seleccionarElemento ──────────────────────────────
private void accionSeleccionarElemento(HttpServletRequest req, HttpSession sesion) {
    String zStr = req.getParameter("numeroAtomico");
    if (zStr == null) return;
    int z;
    try { z = Integer.parseInt(zStr); } catch (NumberFormatException e) { return; }

    // ── MEDICIÓN CAPA CONTROLADOR ─────────────────────
    long t0Controlador = System.currentTimeMillis();

    ElementoBase ebA = (ElementoBase) sesion.getAttribute(SK_ELEM_A);
    ElementoBase ebB = (ElementoBase) sesion.getAttribute(SK_ELEM_B);

    ResultadoSeleccion r = servicio.seleccionarElemento(z, ebA, ebB);

    long t1Controlador = System.currentTimeMillis();
    System.out.println("[TIEMPO][CU1-seleccionarElemento] Controlador: "
        + (t1Controlador - t0Controlador) + " ms");
    // ─────────────────────────────────────────────────

    if (r.nuevoA != null) sesion.setAttribute(SK_ELEM_A, r.nuevoA);
    else                   sesion.removeAttribute(SK_ELEM_A);
    if (r.nuevoB != null) sesion.setAttribute(SK_ELEM_B, r.nuevoB);
    else                   sesion.removeAttribute(SK_ELEM_B);
    if (r.limpiarRespuestas) limpiarRespuestas(sesion);
}
 
    /** Reinicio completo: limpia sesión y delega al servicio. */
    private void accionReiniciar(Escenario escenario, HttpSession sesion) {
        servicio.reiniciar(escenario);
        limpiarSeleccion(sesion);
        limpiarRespuestas(sesion);
        limpiarEvaluacion(sesion);
    }
 
    /** Comprobar en modo libre: delega al servicio y publica resultado. */
    private void accionComprobarSimulacion(HttpServletRequest req, HttpSession sesion) {
        ElementoBase ebA = (ElementoBase) sesion.getAttribute(SK_ELEM_A);
        ElementoBase ebB = (ElementoBase) sesion.getAttribute(SK_ELEM_B);
 
        String rRadio  = req.getParameter("respRadio");
        String rIoniz  = req.getParameter("respIoniz");
        String rElectr = req.getParameter("respElectr");
 
        // Guardar respuestas en sesión para repintar el JSP
        guardarRespuestas(sesion, rRadio, rIoniz, rElectr);
 
        ResultadoSimulacion r = servicio.comprobarSimulacion(ebA, ebB, rRadio, rIoniz, rElectr);
 
        sesion.setAttribute(SK_RESULT, r.bits);
        req.setAttribute("mensajeMascota",     r.mensajeMascota);
        req.setAttribute("resultadoSimulacion", true);
    }
 
    /** Inicia evaluación: activa modo y genera primer reto. */
    private void accionIniciarEval(Escenario escenario, Usuario usuario,
                                    HttpServletRequest req, HttpSession sesion) {
        servicio.iniciarEvaluacion(escenario);
        generarYPublicarReto(escenario, usuario, req, sesion);
    }
 
    /** Comprobar en modo evaluación: delega al servicio y actúa según resultado. */
    private void accionComprobar(Escenario escenario, Usuario usuario,
                                  HttpServletRequest req, HttpSession sesion) {
        Reto         retoActual = (Reto)         sesion.getAttribute(SK_RETO);
        ElementoBase ebA        = (ElementoBase) sesion.getAttribute(SK_ELEM_AE);
        ElementoBase ebB        = (ElementoBase) sesion.getAttribute(SK_ELEM_BE);
 
        String rRadio  = req.getParameter("respRadio");
        String rIoniz  = req.getParameter("respIoniz");
        String rElectr = req.getParameter("respElectr");
 
        guardarRespuestas(sesion, rRadio, rIoniz, rElectr);
 
        ResultadoComprobacion r = servicio.comprobar(
            escenario, retoActual, ebA, ebB, rRadio, rIoniz, rElectr, usuario);
 
        // Publicar resultado para el JSP
        sesion.setAttribute(SK_RESULT,  r.bitResultado);
        sesion.setAttribute(SK_RETO,    retoActual);
 
        req.setAttribute("resultadoCorrecto", r.correcto);
        req.setAttribute("intentosUsados",    r.intentoUsado);
        req.setAttribute("mensajeMascota",    r.mensajeMascota);
        req.setAttribute("habilitarContinuar", r.habilitarContinuar);
 
        if (r.habilitarContinuar) {
            // Porcentaje suficiente → botón continuar activo, no generar nuevo reto
        } else if (r.generarNuevoReto) {
            generarYPublicarReto(escenario, usuario, req, sesion);
        }
    }
 
    /** Continuar: si superó el umbral, marca escenario superado y redirige. */
    private void accionContinuar(Escenario escenario, HttpSession sesion,
                                  HttpServletResponse resp) throws IOException {
        if (servicio.puedeSuperar(escenario)) {
            servicio.superar(escenario);
            sesion.removeAttribute(SK_ESC);
            resp.sendRedirect("menu"); // ajusta si hay escenario siguiente
        } else {
            resp.sendRedirect("escenario6");
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
        resp.sendRedirect("menu");
    }
 
    // ════════════════════════════════════════════════════════════════════════
    // HELPERS DEL CONTROLADOR
    // ════════════════════════════════════════════════════════════════════════
 
    /**
     * Llama al servicio para generar un reto y publica los atributos en request/sesión.
     */
    private void generarYPublicarReto(Escenario escenario, Usuario usuario,
                                       HttpServletRequest req, HttpSession sesion) {
        ResultadoReto r = servicio.generarReto(usuario);
        if (r == null) return;
 
        escenario.setRetoActual(r.reto);
 
        sesion.setAttribute(SK_RETO,   r.reto);
        sesion.setAttribute(SK_ELEM_AE, r.ebA);
        sesion.setAttribute(SK_ELEM_BE, r.ebB);
        limpiarRespuestas(sesion);
        sesion.removeAttribute(SK_RESULT);
 
        req.setAttribute("nuevoReto",       true);
        req.setAttribute("retoActual",      r.reto);
        req.setAttribute("descripcionReto", r.reto.getDescripcion());
        req.setAttribute("temporizador",    r.reto.getTemporizador());
        req.setAttribute("intentosUsados",  0);
        req.setAttribute("retoId",          String.valueOf(r.reto.getIdReto()));
    }
 
    /**
     * Publica TODOS los datos que el JSP necesita como atributos de request.
     * Este es el único punto donde el controlador "habla" con el JSP.
     */
    private void publicarDatos(Escenario escenario, HttpServletRequest req,
                                HttpSession sesion) {
        // Porcentaje y modo
        int pct = Math.round(escenario.getProgreso().getPorcentajeAprendizaje());
        req.setAttribute("porcentaje",        pct);
        req.setAttribute("modoEvaluacion",    escenario.isModoEvaluacion());
        req.setAttribute("habilitarContinuar",
            escenario.getProgreso().getPorcentajeAprendizaje() >= EscenarioSeisServicio.MINIMO_APROBATORIO
            && escenario.isModoEvaluacion());
 
        // Tabla periódica completa para el JSP
        req.setAttribute("elementosPeriodica", servicio.obtenerElementos());
 
        // Elementos seleccionados según modo
        boolean modoEval = escenario.isModoEvaluacion();
        if (modoEval) {
            req.setAttribute("elemA", sesion.getAttribute(SK_ELEM_AE));
            req.setAttribute("elemB", sesion.getAttribute(SK_ELEM_BE));
        } else {
            req.setAttribute("elemA", sesion.getAttribute(SK_ELEM_A));
            req.setAttribute("elemB", sesion.getAttribute(SK_ELEM_B));
        }
 
        // Respuestas del usuario para repintar botones A/B seleccionados
        req.setAttribute("respRadio",  sesion.getAttribute(SK_RADIO));
        req.setAttribute("respIoniz",  sesion.getAttribute(SK_IONIZ));
        req.setAttribute("respElectr", sesion.getAttribute(SK_ELECTR));
 
        // Bits de resultado de simulación ("111", "010", etc.)
        req.setAttribute("resultSimul", sesion.getAttribute(SK_RESULT));
 
        // HUD del reto activo (si no fue ya publicado por la acción)
        Reto ra = (Reto) sesion.getAttribute(SK_RETO);
        if (ra != null && req.getAttribute("retoActual") == null) {
            req.setAttribute("retoActual",    ra);
            req.setAttribute("temporizador",  ra.getTemporizador());
            req.setAttribute("intentosUsados", ra.getIntentos());
            if (req.getAttribute("descripcionReto") == null)
                req.setAttribute("descripcionReto", ra.getDescripcion());
            req.setAttribute("retoId", String.valueOf(ra.getIdReto()));
        }
        if (req.getAttribute("retoId") == null)
            req.setAttribute("retoId", "");
    }
 
    // ── Helpers de limpieza de sesión ─────────────────────────────────────
 
    private void limpiarSeleccion(HttpSession sesion) {
        sesion.removeAttribute(SK_ELEM_A);
        sesion.removeAttribute(SK_ELEM_B);
    }
 
    private void limpiarRespuestas(HttpSession sesion) {
        sesion.removeAttribute(SK_RADIO);
        sesion.removeAttribute(SK_IONIZ);
        sesion.removeAttribute(SK_ELECTR);
        sesion.removeAttribute(SK_RESULT);
    }
 
    private void limpiarEvaluacion(HttpSession sesion) {
        sesion.removeAttribute(SK_RETO);
        sesion.removeAttribute(SK_ELEM_AE);
        sesion.removeAttribute(SK_ELEM_BE);
        limpiarRespuestas(sesion);
    }
 
    private void guardarRespuestas(HttpSession sesion, String r, String i, String e) {
        if (r != null) sesion.setAttribute(SK_RADIO,  r);
        if (i != null) sesion.setAttribute(SK_IONIZ,  i);
        if (e != null) sesion.setAttribute(SK_ELECTR, e);
    }
 
    // ── Obtener o crear el Escenario desde sesión ─────────────────────────
    private Escenario obtenerOCrearEscenario(HttpSession sesion) {
        Escenario esc = (Escenario) sesion.getAttribute(SK_ESC);
        if (esc == null)
            esc = new Escenario(EscenarioSeisServicio.ID_ESCENARIO,
                                "Propiedades Periódicas de los Elementos", 3);
        return esc;
    }
}