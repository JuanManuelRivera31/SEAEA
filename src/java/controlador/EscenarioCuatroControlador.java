package controlador;

import logica.EscenarioCuatroServicio;
import logica.EscenarioCuatroServicio.*;
import modelo.ElementoBase;
import modelo.Escenario;
import modelo.Isotopo;
import modelo.Reto;
import modelo.Usuario;

import jakarta.servlet.ServletException;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import jakarta.servlet.http.HttpSession;
import java.io.IOException;

/**
 * EscenarioCuatroControlador
 * ─────────────────────────────────────────────────────────────────────────
 * Controlador del Escenario 4 "Configura tu Isótopo".
 *
 * Responsabilidades ÚNICAS (MVC):
 *  1. Verificar sesión activa.
 *  2. Leer parámetros del request.
 *  3. Recuperar/crear el Escenario desde sesión.
 *  4. Delegar TODO el procesamiento a EscenarioCuatroServicio.
 *  5. Publicar atributos para el JSP (publicarDatos).
 *  6. Forward al JSP o redirect.
 *
 * NO contiene lógica de negocio. NO importa ni usa DAOs directamente.
 * NOTA: Sin @WebServlet — mapeo en web.xml (metadata-complete="true").
 */
public class EscenarioCuatroControlador extends HttpServlet {

    private final EscenarioCuatroServicio servicio = new EscenarioCuatroServicio();

    // ── Claves de sesión ─────────────────────────────────────────────────
    private static final String SK_ESC      = "escenario4";
    private static final String SK_EB_SEL   = "elementoSeleccionado4";
    private static final String SK_Z_SEL    = "zSeleccionado4";
    private static final String SK_NEUTRONES= "neutrones4";
    private static final String SK_RETO     = "retoActual4";
    private static final String SK_ISO_OBJ  = "isotopoObjetivo4";
    private static final String SK_EB_RETO  = "elementoReto4";
    private static final String SK_Z_RETO   = "zReto4";

    private static final String JSP = "/escenario4/escenario4.jsp";

    @Override
    protected void doGet(HttpServletRequest req, HttpServletResponse resp)
            throws ServletException, IOException { procesar(req, resp); }

    @Override
    protected void doPost(HttpServletRequest req, HttpServletResponse resp)
            throws ServletException, IOException { procesar(req, resp); }

    // ════════════════════════════════════════════════════════════════════════
    // DISPATCHER
    // ════════════════════════════════════════════════════════════════════════

    private void procesar(HttpServletRequest req, HttpServletResponse resp)
            throws ServletException, IOException {

        HttpSession sesion = req.getSession(false);
        if (sesion == null || sesion.getAttribute("usuario") == null) {
            resp.sendRedirect(req.getContextPath() + "/login"); // corregido
            return;
        }

        Usuario   usuario   = (Usuario)   sesion.getAttribute("usuario");
        Escenario escenario = obtenerOCrearEscenario(sesion);

        String accion = req.getParameter("accion");
        if (accion == null) accion = "cargar";

        switch (accion) {
            case "cargar":                accionCargar(escenario, usuario, req, sesion);       break;
            case "seleccionarElemento":   accionSeleccionarElemento(req, sesion);               break;
            case "incrementarNeutrones":  accionModificarNeutrones(escenario, sesion, req, +1); break;
            case "decrementarNeutrones":  accionModificarNeutrones(escenario, sesion, req, -1); break;
            case "reiniciar":             accionReiniciar(escenario, sesion);                   break;
            case "iniciarEval":           accionIniciarEval(escenario, usuario, req, sesion);   break;
            case "comprobar":             accionComprobar(escenario, usuario, req, sesion);     break;
            case "continuar":             accionContinuar(escenario, sesion, resp); return;
            case "finalizar":             accionFinalizar(escenario, sesion, req);              break;
            case "volver":                accionVolver(escenario, sesion, resp); return;
            default:                      accionCargar(escenario, usuario, req, sesion);
        }

        sesion.setAttribute(SK_ESC, escenario);
        publicarDatos(escenario, req, sesion);
        req.getRequestDispatcher(JSP).forward(req, resp);
    }

    // ════════════════════════════════════════════════════════════════════════
    // ACCIONES
    // ════════════════════════════════════════════════════════════════════════

    private void accionCargar(Escenario escenario, Usuario usuario,
                               HttpServletRequest req, HttpSession sesion) {
        ResultadoCarga r = servicio.cargar(escenario, usuario);
        req.setAttribute("mensajeMascota", r.mensajeMascota);
        sesion.setAttribute(SK_ESC, escenario);
    }

    private void accionSeleccionarElemento(HttpServletRequest req, HttpSession sesion) {
        String zStr = req.getParameter("numeroAtomico");
        if (zStr == null) return;
        int z;
        try { z = Integer.parseInt(zStr); } catch (NumberFormatException e) { return; }

        ElementoBase eb = servicio.seleccionarElemento(z);
        if (eb == null) {
            req.setAttribute("mensajeMascota",
                "Elemento Z=" + z + " no disponible para este escenario.");
            return;
        }

        sesion.setAttribute(SK_EB_SEL,   eb);
        sesion.setAttribute(SK_Z_SEL,    z);
        sesion.setAttribute(SK_NEUTRONES, 0);

        // Publicar isótopo inicial (neutrones=0)
        publicarIsotopoActual(eb, 0, req, sesion);
    }

    private void accionModificarNeutrones(Escenario escenario, HttpSession sesion,
                                           HttpServletRequest req, int delta) {
        ElementoBase eb = (ElementoBase) sesion.getAttribute(SK_EB_SEL);
        if (eb == null) {
            req.setAttribute("mensajeMascota",
                "Primero selecciona un elemento de la tabla periódica.");
            return;
        }

        Integer nActual = (Integer) sesion.getAttribute(SK_NEUTRONES);
        if (nActual == null) nActual = 0;

        int nuevo = delta > 0
            ? servicio.incrementarNeutrones(nActual)
            : servicio.decrementarNeutrones(nActual);

        sesion.setAttribute(SK_NEUTRONES, nuevo);
        publicarIsotopoActual(eb, nuevo, req, sesion);
    }

    private void accionReiniciar(Escenario escenario, HttpSession sesion) {
        servicio.reiniciar(escenario);
        sesion.removeAttribute(SK_EB_SEL);
        sesion.removeAttribute(SK_Z_SEL);
        sesion.removeAttribute(SK_NEUTRONES);
        sesion.removeAttribute(SK_RETO);
        sesion.removeAttribute(SK_ISO_OBJ);
        sesion.removeAttribute(SK_EB_RETO);
        sesion.removeAttribute(SK_Z_RETO);
    }

    private void accionIniciarEval(Escenario escenario, Usuario usuario,
                                    HttpServletRequest req, HttpSession sesion) {
        servicio.iniciarEvaluacion(escenario);
        generarYPublicarReto(escenario, usuario, req, sesion);
    }

    private void accionComprobar(Escenario escenario, Usuario usuario,
                                  HttpServletRequest req, HttpSession sesion) {
        Reto         retoActual = (Reto)         sesion.getAttribute(SK_RETO);
        Isotopo      isoObj     = (Isotopo)      sesion.getAttribute(SK_ISO_OBJ);
        ElementoBase ebReto     = (ElementoBase) sesion.getAttribute(SK_EB_RETO);
        ElementoBase ebActual   = (ElementoBase) sesion.getAttribute(SK_EB_SEL);
        Integer nActual         = (Integer)      sesion.getAttribute(SK_NEUTRONES);
        if (nActual == null) nActual = 0;

        ResultadoComprobacion r = servicio.comprobar(
            escenario, retoActual, isoObj, ebReto, ebActual, nActual, usuario);

        sesion.setAttribute(SK_RETO, retoActual);

        req.setAttribute("resultadoCorrecto",  r.correcto);
        req.setAttribute("intentosUsados",     r.intentoUsado);
        req.setAttribute("mensajeMascota",     r.mensajeMascota);
        req.setAttribute("habilitarContinuar", r.habilitarContinuar);

        if (r.habilitarContinuar) {
            // nada adicional
        } else if (r.generarNuevoReto) {
            generarYPublicarReto(escenario, usuario, req, sesion);
        }

        // Re-publicar isótopo actual si hay elemento seleccionado
        if (ebActual != null) {
            publicarIsotopoActual(ebActual, nActual, req, sesion);
        }
    }

    private void accionContinuar(Escenario escenario, HttpSession sesion,
                                  HttpServletResponse resp) throws IOException {
        if (servicio.puedeSuperar(escenario)) {
            servicio.superar(escenario);
            sesion.removeAttribute(SK_ESC);
            resp.sendRedirect("escenario5");
        } else {
            resp.sendRedirect("escenario4");
        }
    }

    private void accionFinalizar(Escenario escenario, HttpSession sesion,
                                  HttpServletRequest req) {
        String mensaje = servicio.finalizar(escenario);
        limpiarEvaluacion(sesion);
        req.setAttribute("mensajeMascota", mensaje);
    }

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
     * en request/sesión.
     */
    private void generarYPublicarReto(Escenario escenario, Usuario usuario,
                                       HttpServletRequest req, HttpSession sesion) {
        ResultadoReto r = servicio.generarReto(usuario);
        if (r == null) {
            req.setAttribute("mensajeMascota",
                "No se pudo generar un reto. Verifica que haya isótopos en la base de datos.");
            return;
        }

        escenario.setRetoActual(r.reto);

        sesion.setAttribute(SK_RETO,     r.reto);
        sesion.setAttribute(SK_ISO_OBJ,  r.isotopo);
        sesion.setAttribute(SK_EB_RETO,  r.elementoBase);
        sesion.setAttribute(SK_Z_RETO,   r.elementoBase.getNumeroAtomico());

        req.setAttribute("nuevoReto",       true);
        req.setAttribute("retoActual",      r.reto);
        req.setAttribute("descripcionReto", r.reto.getDescripcion());
        req.setAttribute("temporizador",    r.reto.getTemporizador());
        req.setAttribute("intentosUsados",  0);
        req.setAttribute("retoId",          String.valueOf(r.reto.getIdReto()));

        // Publicar isótopo objetivo para la carta en JSP
        req.setAttribute("isotopoObjetivo",   r.isotopo);
        req.setAttribute("ebReto",            r.elementoBase);
        req.setAttribute("nomIsotopoObjetivo", r.isotopo.getNombreDisplay());
        req.setAttribute("neutronesObjetivo",  r.isotopo.getNumeroNeutrones());
    }

    /**
     * Calcula y publica los datos del isótopo actual al JSP.
     * Delega al servicio; el controlador solo copia los campos al request.
     */
    private void publicarIsotopoActual(ElementoBase eb, int neutrones,
                                        HttpServletRequest req, HttpSession sesion) {
        ResultadoIsotopo r = servicio.calcularDatosIsotopo(eb, neutrones);
        req.setAttribute("nombreIsotopoActual",  r.nombre);
        req.setAttribute("estabilidadActual",    r.estabilidad);
        req.setAttribute("abundanciaActual",     r.abundancia);
        req.setAttribute("masaIsotopicaActual",  r.masa);
        req.setAttribute("numeroMasicoActual",   r.numeroMasico);
        req.setAttribute("neutronesActuales",    neutrones);
        sesion.setAttribute(SK_NEUTRONES, neutrones);
    }

    /**
     * Publica TODOS los datos que el JSP necesita como atributos de request.
     */
    private void publicarDatos(Escenario escenario, HttpServletRequest req,
                                HttpSession sesion) {
        // Porcentaje y modo
        int pct = Math.round(escenario.getProgreso().getPorcentajeAprendizaje());
        req.setAttribute("porcentaje",        pct);
        req.setAttribute("modoEvaluacion",    escenario.isModoEvaluacion());
        req.setAttribute("habilitarContinuar",
            escenario.getProgreso().getPorcentajeAprendizaje() >= EscenarioCuatroServicio.MINIMO_APROBATORIO
            && escenario.isModoEvaluacion());

        // Tabla periódica (Z ≤ MAX_Z)
        req.setAttribute("elementosPeriodica", servicio.obtenerElementosParaTabla());

        // Elemento seleccionado
        ElementoBase ebSel = (ElementoBase) sesion.getAttribute(SK_EB_SEL);
        req.setAttribute("elementoSeleccionado", ebSel);
        Integer zSel = (Integer) sesion.getAttribute(SK_Z_SEL);
        req.setAttribute("zSeleccionado", zSel != null ? zSel : 0);

        // Neutrones actuales
        Integer nAct = (Integer) sesion.getAttribute(SK_NEUTRONES);
        if (nAct == null) nAct = 0;
        req.setAttribute("neutronesActuales", nAct);

        // Info isótopo actual (si no fue ya publicada por la acción)
        if (ebSel != null && req.getAttribute("nombreIsotopoActual") == null) {
            publicarIsotopoActual(ebSel, nAct, req, sesion);
        }

        // HUD del reto activo
        Reto ra = (Reto) sesion.getAttribute(SK_RETO);
        if (ra != null && req.getAttribute("retoActual") == null) {
            req.setAttribute("retoActual",     ra);
            req.setAttribute("temporizador",   ra.getTemporizador());
            req.setAttribute("intentosUsados", ra.getIntentos());
            if (req.getAttribute("descripcionReto") == null)
                req.setAttribute("descripcionReto", ra.getDescripcion());
            req.setAttribute("retoId", String.valueOf(ra.getIdReto()));
        }
        if (req.getAttribute("retoId") == null) req.setAttribute("retoId", "");

        // Isótopo objetivo (si no fue ya publicado)
        Isotopo  isoObj = (Isotopo)      sesion.getAttribute(SK_ISO_OBJ);
        ElementoBase ebReto = (ElementoBase) sesion.getAttribute(SK_EB_RETO);
        if (isoObj != null && req.getAttribute("isotopoObjetivo") == null) {
            req.setAttribute("isotopoObjetivo",    isoObj);
            req.setAttribute("ebReto",             ebReto);
            req.setAttribute("nomIsotopoObjetivo", isoObj.getNombreDisplay());
            req.setAttribute("neutronesObjetivo",  isoObj.getNumeroNeutrones());
        }
    }

    private void limpiarEvaluacion(HttpSession sesion) {
        sesion.removeAttribute(SK_RETO);
        sesion.removeAttribute(SK_ISO_OBJ);
        sesion.removeAttribute(SK_EB_RETO);
        sesion.removeAttribute(SK_Z_RETO);
    }

    private Escenario obtenerOCrearEscenario(HttpSession sesion) {
        Escenario esc = (Escenario) sesion.getAttribute(SK_ESC);
        if (esc == null)
            esc = new Escenario(EscenarioCuatroServicio.ID_ESCENARIO,
                                "Configura tu Isótopo", 3);
        return esc;
    }
}