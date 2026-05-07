package controlador;

import logica.EscenarioDosServicio;
import logica.EscenarioDosServicio.ResultadoComprobar;
import modelo.*;

import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.*;
import java.io.IOException;

/**
 * EscenarioDosControlador — Escenario 2 "Número y Núcleo Atómico"
 *
 * ARQUITECTURA MVC:
 *   JSP → Controlador → EscenarioDosServicio → DAOs → BD → Modelos
 *                                                         ↑
 *                                              (retorna hasta JSP)
 *
 * Responsabilidades de este controlador (SOLO):
 *   1. Leer parámetros del request / sesión.
 *   2. Llamar al servicio (EscenarioDosServicio).
 *   3. Publicar resultados en request/sesión.
 *   4. Hacer forward al JSP o redirect.
 *
 * NO contiene lógica de negocio. Todo está en EscenarioDosServicio.
 */
@WebServlet("/escenario2")
public class EscenarioDosControlador extends HttpServlet {

    // ── Capa lógica ──────────────────────────────────────────────────────────
    private final EscenarioDosServicio servicio = new EscenarioDosServicio();

    // ── Claves de sesión ────────────────────────────────────────────────────
    private static final String S_ESC      = "escenario2";
    private static final String S_RETO     = "reto2Actual";
    private static final String S_OBJ      = "reto2Objetivo";
    private static final String S_PCT      = "e2_porcentaje";
    private static final String S_RETOS_OK = "e2_retos_ok";

    @Override
    protected void doGet(HttpServletRequest req, HttpServletResponse resp)
            throws ServletException, IOException { procesar(req, resp); }

    @Override
    protected void doPost(HttpServletRequest req, HttpServletResponse resp)
            throws ServletException, IOException { procesar(req, resp); }

    // ════════════════════════════════════════════════════════════════════════
    private void procesar(HttpServletRequest req, HttpServletResponse resp)
            throws ServletException, IOException {

        HttpSession ses = req.getSession(false);
        if (ses == null || ses.getAttribute("usuario") == null) {
            resp.sendRedirect(req.getContextPath() + "/login.jsp");
            return;
        }

        Usuario   usuario   = (Usuario)   ses.getAttribute("usuario");
        Escenario escenario = obtenerOCrear(ses);
        String    accion    = req.getParameter("accion");
        if (accion == null) accion = "cargar";

        switch (accion) {
            case "cargar"      -> accionCargar(escenario, req, ses);
            case "incrementar" -> accionModificar(escenario, req.getParameter("particula"), true,  req, ses);
            case "decrementar" -> accionModificar(escenario, req.getParameter("particula"), false, req, ses);
            case "reiniciar"   -> accionReiniciar(escenario, ses);
            case "iniciarEval" -> accionIniciarEval(escenario, usuario, req, ses);
            case "comprobar"   -> accionComprobar(escenario, usuario, req, ses);
            case "continuar"   -> { accionContinuar(escenario, ses, resp); return; }
            case "finalizar"   -> accionFinalizar(escenario, ses, req);
            case "volver"      -> { accionVolver(escenario, ses, resp); return; }
            default            -> accionCargar(escenario, req, ses);
        }

        ses.setAttribute(S_ESC, escenario);
        publicarDatos(escenario, req, ses);
        req.getRequestDispatcher("/escenario2/escenario2.jsp").forward(req, resp);
    }

    // ════════════════════════════════════════════════════════════════════════
    //  ACCIONES — solo leen/escriben request y sesión, delegan al servicio
    // ════════════════════════════════════════════════════════════════════════

    private void accionCargar(Escenario escenario, HttpServletRequest req, HttpSession ses) {
        escenario.cargarEscenario();
        setPct(ses, 0f);
        setRetosOk(ses, 0);
        escenario.getProgreso().setPorcentajeAprendizaje(0f);
        req.setAttribute("primeraCarga",   true);
        req.setAttribute("mensajeMascota", escenario.guiaMascota());
    }

    private void accionModificar(Escenario escenario, String particula,
                                  boolean inc, HttpServletRequest req, HttpSession ses) {
        if (particula == null) return;
        Elemento el = escenario.getElemento();
        switch (particula) {
            case "protones" -> {
                if (inc) el.incrementarProtones(); else el.decrementarProtones();
                // Delegar al servicio la consulta del elemento identificado
                ElementoBase eb = servicio.obtenerElementoPorZ(el.getProtones());
                escenario.actualizarCartaPeriodicaElemento(eb);
                req.setAttribute("elementoIdentificado", eb);
            }
            case "neutrones" -> {
                if (inc) el.incrementarNeutrones(); else el.decrementarNeutrones();
                req.setAttribute("elementoIdentificado", escenario.getElementoIdentificado());
            }
        }
    }

    private void accionReiniciar(Escenario escenario, HttpSession ses) {
        escenario.reiniciarEscenario();
        ses.removeAttribute(S_RETO);
        ses.removeAttribute(S_OBJ);
        setPct(ses, 0f);
        setRetosOk(ses, 0);
        escenario.getProgreso().setPorcentajeAprendizaje(0f);
    }

    private void accionIniciarEval(Escenario escenario, Usuario usuario,
                                    HttpServletRequest req, HttpSession ses) {
        // Delegar inicio al servicio
        servicio.iniciarEvaluacion(escenario);
        setPct(ses, 0f);
        setRetosOk(ses, 0);
        escenario.getProgreso().setPorcentajeAprendizaje(0f);
        // Pedir al servicio el primer reto
        Reto reto = servicio.generarNuevoReto(usuario.getIdUsuario());
        if (reto == null) return;
        Elemento objetivo = servicio.crearElementoObjetivo(reto);
        ses.setAttribute(S_RETO, reto);
        ses.setAttribute(S_OBJ,  objetivo);
        publicarReto(reto, req);
    }

    private void accionComprobar(Escenario escenario, Usuario usuario,
                                  HttpServletRequest req, HttpSession ses) {

        Reto     retoActual = (Reto)     ses.getAttribute(S_RETO);
        Elemento objetivo   = (Elemento) ses.getAttribute(S_OBJ);

        if (retoActual == null || objetivo == null) {
            req.setAttribute("mensajeMascota", "No hay reto activo. Presiona 'Iniciar Evaluación'.");
            return;
        }

        // Delegar comprobación completa al servicio
        ResultadoComprobar res = servicio.comprobar(
            escenario, retoActual, objetivo,
            getPct(ses), getRetosOk(ses),
            usuario.getIdUsuario()
        );

        // Controlador solo actualiza sesión y request con los resultados
        setPct(ses, res.nuevoPct);
        escenario.getProgreso().setPorcentajeAprendizaje(res.nuevoPct);

        if (res.correcto) {
            setRetosOk(ses, getRetosOk(ses) + 1);
        }

        req.setAttribute("resultadoCorrecto", res.correcto);
        req.setAttribute("intentosUsados",    res.intento);
        req.setAttribute("mensajeMascota",    res.mensajeMascota);
        req.setAttribute("habilitarContinuar", res.puedeContar);

        if (res.nuevoRetoGenerado && res.nuevoReto != null) {
            ses.setAttribute(S_RETO, res.nuevoReto);
            ses.setAttribute(S_OBJ,  servicio.crearElementoObjetivo(res.nuevoReto));
            req.setAttribute("nuevoReto", true);
            publicarReto(res.nuevoReto, req);
        } else {
            // Mismo reto, actualizar intentos en sesión
            ses.setAttribute(S_RETO, retoActual);
        }
    }

    private void accionContinuar(Escenario escenario, HttpSession ses,
                                  HttpServletResponse resp) throws IOException {
        float pct     = getPct(ses);
        int   retosOk = getRetosOk(ses);
        if (pct >= EscenarioDosServicio.PCT_MINIMO_CONT
                && retosOk >= EscenarioDosServicio.RETOS_MIN) {
            escenario.superarEscenario();
            ses.removeAttribute(S_ESC);
            resp.sendRedirect("escenario3"); // siguiente escenario
        }
    }

    private void accionFinalizar(Escenario escenario, HttpSession ses,
                                  HttpServletRequest req) {
        escenario.setModoEvaluacion(false);
        ses.removeAttribute(S_RETO);
        ses.removeAttribute(S_OBJ);
        float pct     = getPct(ses);
        int   retosOk = getRetosOk(ses);
        req.setAttribute("mensajeMascota",
            "Evaluación finalizada.\n\n"
            + "📊 Porcentaje: " + (int) pct + "%\n"
            + "✅ Retos acertados: " + retosOk + " / " + EscenarioDosServicio.RETOS_MIN + " mínimo\n\n"
            + (pct >= EscenarioDosServicio.PCT_MINIMO_CONT && retosOk >= EscenarioDosServicio.RETOS_MIN
                ? "¡Has superado el escenario! Pulsa CONTINUAR."
                : "Necesitas ≥80% y ≥" + EscenarioDosServicio.RETOS_MIN + " retos. ¡Sigue practicando!"));
    }

    private void accionVolver(Escenario escenario, HttpSession ses,
                               HttpServletResponse resp) throws IOException {
        escenario.salirEscenario();
        ses.removeAttribute(S_ESC);
        resp.sendRedirect("login.jsp");
    }

    // ════════════════════════════════════════════════════════════════════════
    //  HELPERS — solo gestionan request/sesión, sin lógica de negocio
    // ════════════════════════════════════════════════════════════════════════

    /** Publica en request los atributos que el JSP necesita para renderizar. */
    private void publicarDatos(Escenario escenario, HttpServletRequest req, HttpSession ses) {
        Elemento el = escenario.getElemento();
        req.setAttribute("protones",       el.getProtones());
        req.setAttribute("neutrones",      el.getNeutrones());
        req.setAttribute("numeroMasico",   el.getNumeroMasico());
        req.setAttribute("modoEvaluacion", escenario.isModoEvaluacion());

        float pct     = getPct(ses);
        int   retosOk = getRetosOk(ses);
        escenario.getProgreso().setPorcentajeAprendizaje(pct);
        req.setAttribute("porcentaje", Math.round(pct));

        boolean puedeContar = escenario.isModoEvaluacion()
                && pct     >= EscenarioDosServicio.PCT_MINIMO_CONT
                && retosOk >= EscenarioDosServicio.RETOS_MIN;
        req.setAttribute("habilitarContinuar", puedeContar);
        req.setAttribute("elementoIdentificado", escenario.getElementoIdentificado());

        // Datos del reto activo (si no fueron ya publicados por la acción)
        Reto ra = (Reto) ses.getAttribute(S_RETO);
        if (ra != null && req.getAttribute("retoActual") == null) {
            req.setAttribute("retoActual",      ra);
            req.setAttribute("temporizador",    ra.getTemporizador());
            req.setAttribute("intentosUsados",  ra.getIntentos());
            if (req.getAttribute("descripcionReto") == null)
                req.setAttribute("descripcionReto", ra.getDescripcion());
        }
    }

    /** Publica en request los datos de un reto recién generado. */
    private void publicarReto(Reto reto, HttpServletRequest req) {
        req.setAttribute("retoActual",      reto);
        req.setAttribute("descripcionReto", reto.getDescripcion());
        req.setAttribute("temporizador",    reto.getTemporizador());
        req.setAttribute("intentosUsados",  0);
    }

    private Escenario obtenerOCrear(HttpSession ses) {
        Escenario e = (Escenario) ses.getAttribute(S_ESC);
        if (e == null) e = new Escenario(2, "Número y Núcleo Atómico", 3);
        return e;
    }

    // ── Accesores de sesión ──────────────────────────────────────────────────
    private float getPct(HttpSession ses) {
        Float v = (Float) ses.getAttribute(S_PCT);
        return v != null ? v : 0f;
    }
    private void setPct(HttpSession ses, float v)     { ses.setAttribute(S_PCT, v); }
    private int  getRetosOk(HttpSession ses) {
        Integer v = (Integer) ses.getAttribute(S_RETOS_OK);
        return v != null ? v : 0;
    }
    private void setRetosOk(HttpSession ses, int v)   { ses.setAttribute(S_RETOS_OK, v); }
}