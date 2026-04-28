package controlador;

import dao.*;
import modelo.*;

import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.*;
import java.io.IOException;

/**
 * EscenarioDosControlador — Escenario 2 "Número y Núcleo Atómico"
 *
 * SISTEMA DE PONDERACIÓN CORREGIDO:
 *  - Reto acertado en intento 1 → +20%
 *  - Reto acertado en intento 2 → +13%
 *  - Reto acertado en intento 3 → +7%
 *  - Intento fallido (sin agotar) → -5%
 *  - Reto agotado (3 fallos)     → -10%
 *  - Mínimo 3 retos acertados para habilitar CONTINUAR
 *  - Porcentaje nunca baja de 0% ni sube de 100%
 */
@WebServlet("/escenario2")
public class EscenarioDosControlador extends HttpServlet {

    private static final int ID_ESCENARIO = 2;

    private final ElementoBaseDAO      elementoDAO = new ElementoBaseDAO();
    private final RetoDAO              retoDAO     = new RetoDAO();
    private final PuntajeRetoDAO       puntajeDAO  = new PuntajeRetoDAO();
    private final ProgresoEscenarioDAO progresoDAO = new ProgresoEscenarioDAO();

    // ── Constantes del sistema de ponderación ───────────────────────────────
    private static final float PCT_ACIERTO_1   =  20f;
    private static final float PCT_ACIERTO_2   =  13f;
    private static final float PCT_ACIERTO_3   =   7f;
    private static final float PCT_FALLO       =  -5f;
    private static final float PCT_AGOTADO     = -10f;
    private static final int   RETOS_MIN       =   3;   // mínimo para habilitar CONTINUAR
    private static final float PCT_MINIMO_CONT =  80f;

    // ── Claves de sesión ────────────────────────────────────────────────────
    private static final String SESION_ESC        = "escenario2";
    private static final String SESION_RETO       = "reto2Actual";
    private static final String SESION_OBJETIVO   = "reto2Objetivo";
    private static final String SESION_PCT        = "e2_porcentaje";
    private static final String SESION_RETOS_OK   = "e2_retos_ok";

    @Override
    protected void doGet(HttpServletRequest req, HttpServletResponse resp)
            throws ServletException, IOException { procesarAccion(req, resp); }

    @Override
    protected void doPost(HttpServletRequest req, HttpServletResponse resp)
            throws ServletException, IOException { procesarAccion(req, resp); }

    // ════════════════════════════════════════════════════════════════════════
    private void procesarAccion(HttpServletRequest req, HttpServletResponse resp)
            throws ServletException, IOException {

        HttpSession sesion = req.getSession(false);
        if (sesion == null || sesion.getAttribute("usuario") == null) {
            resp.sendRedirect(req.getContextPath() + "/login.jsp");
            return;
        }

        Usuario   usuario   = (Usuario)   sesion.getAttribute("usuario");
        Escenario escenario = obtenerOCrearEscenario(sesion);
        String    accion    = req.getParameter("accion");
        if (accion == null) accion = "cargar";

        switch (accion) {
            case "cargar"      -> accionCargar(escenario, req, sesion);
            case "incrementar" -> accionModificar(escenario, req.getParameter("particula"), true,  req);
            case "decrementar" -> accionModificar(escenario, req.getParameter("particula"), false, req);
            case "reiniciar"   -> accionReiniciar(escenario, sesion);
            case "iniciarEval" -> accionIniciarEvaluacion(escenario, usuario, req, sesion);
            case "comprobar"   -> accionComprobar(escenario, usuario, req, sesion);
            case "continuar"   -> { accionContinuar(escenario, sesion, resp); return; }
            case "finalizar"   -> accionFinalizar(escenario, sesion, req);
            case "volver"      -> { accionVolver(escenario, sesion, resp); return; }
            default            -> accionCargar(escenario, req, sesion);
        }

        sesion.setAttribute(SESION_ESC, escenario);
        publicarDatos(escenario, req, sesion);
        req.getRequestDispatcher("/escenario2/escenario2.jsp").forward(req, resp);
    }

    // ════════════════════════════════════════════════════════════════════════
    //  ACCIONES
    // ════════════════════════════════════════════════════════════════════════

    private void accionCargar(Escenario escenario, HttpServletRequest req,
                               HttpSession sesion) {
        escenario.cargarEscenario();
        sesion.setAttribute(SESION_PCT,      0f);
        sesion.setAttribute(SESION_RETOS_OK, 0);
        escenario.getProgreso().setPorcentajeAprendizaje(0f);
        req.setAttribute("primeraCarga", true);
        req.setAttribute("mensajeMascota", escenario.guiaMascota());
        sesion.setAttribute(SESION_ESC, escenario);
    }

    // ── Modificar protones / neutrones ──────────────────────────────────────
    private void accionModificar(Escenario escenario, String particula,
                                  boolean inc, HttpServletRequest req) {
        if (particula == null) return;
        Elemento el = escenario.getElemento();
        switch (particula) {
            case "protones" -> {
                if (inc) el.incrementarProtones(); else el.decrementarProtones();
                ElementoBase eb = el.getProtones() > 0
                        ? elementoDAO.obtenerPorNumeroAtomico(el.getProtones()) : null;
                escenario.actualizarCartaPeriodicaElemento(eb);
                req.setAttribute("elementoIdentificado", eb);
            }
            case "neutrones" -> {
                if (inc) el.incrementarNeutrones(); else el.decrementarNeutrones();
                // Neutrones no cambian el elemento (RF-208)
                req.setAttribute("elementoIdentificado", escenario.getElementoIdentificado());
            }
        }
    }

    // ── Reiniciar ────────────────────────────────────────────────────────────
    private void accionReiniciar(Escenario escenario, HttpSession sesion) {
        escenario.reiniciarEscenario();
        sesion.removeAttribute(SESION_RETO);
        sesion.removeAttribute(SESION_OBJETIVO);
        sesion.setAttribute(SESION_PCT,      0f);
        sesion.setAttribute(SESION_RETOS_OK, 0);
        escenario.getProgreso().setPorcentajeAprendizaje(0f);
    }

    // ── Iniciar evaluación ───────────────────────────────────────────────────
    private void accionIniciarEvaluacion(Escenario escenario, Usuario usuario,
                                          HttpServletRequest req, HttpSession sesion) {
        escenario.iniciarEvaluacion();
        // Reiniciar contadores de sesión
        sesion.setAttribute(SESION_PCT,      0f);
        sesion.setAttribute(SESION_RETOS_OK, 0);
        escenario.getProgreso().setPorcentajeAprendizaje(0f);
        // Generar primer reto
        generarNuevoReto(escenario, usuario, req, sesion);
    }

    // ── Comprobar ────────────────────────────────────────────────────────────
    private void accionComprobar(Escenario escenario, Usuario usuario,
                                  HttpServletRequest req, HttpSession sesion) {

        Reto     retoActual   = (Reto)     sesion.getAttribute(SESION_RETO);
        Elemento retoObjetivo = (Elemento) sesion.getAttribute(SESION_OBJETIVO);

        if (retoActual == null || retoObjetivo == null) {
            req.setAttribute("mensajeMascota",
                    "No hay reto activo. Presiona 'Iniciar Evaluación'.");
            return;
        }

        // Seguridad: no permitir más comprobaciones si ya agotó intentos
        if (retoActual.agotadoIntentos()) {
            generarNuevoReto(escenario, usuario, req, sesion);
            return;
        }

        Elemento atomoEstudiante = escenario.getElemento();
        boolean correcto = atomoEstudiante.getProtones()  == retoObjetivo.getProtones()
                        && atomoEstudiante.getNeutrones() == retoObjetivo.getNeutrones();

        // Registrar intento
        retoActual.registrarIntento();
        int intento = retoActual.getIntentos();

        req.setAttribute("resultadoCorrecto", correcto);
        req.setAttribute("intentosUsados",    intento);

        if (correcto) {
            retoActual.setCompletado(true);
            retoDAO.actualizar(retoActual);

            // Puntaje BD según intento
            double puntajeBD = intento == 1 ? 100.0 : intento == 2 ? 70.0 : 40.0;
            puntajeDAO.insertar(retoActual.getIdReto(), intento, (float) puntajeBD, true);

            // Actualizar porcentaje en sesión
            float delta = intento == 1 ? PCT_ACIERTO_1 : intento == 2 ? PCT_ACIERTO_2 : PCT_ACIERTO_3;
            float nuevoPct = clamp(getPct(sesion) + delta);
            setPct(sesion, nuevoPct);
            escenario.getProgreso().setPorcentajeAprendizaje(nuevoPct);
            progresoDAO.guardar(usuario.getIdUsuario(), ID_ESCENARIO, nuevoPct);

            // Contador de retos acertados
            int retosOk = getRetosOk(sesion) + 1;
            sesion.setAttribute(SESION_RETOS_OK, retosOk);

            // Mensaje mascota
            String nombreElem = retoActual.getElementoObjetivo() != null
                    ? retoActual.getElementoObjetivo().getNombre() : "el elemento";
            String simb = retoActual.getElementoObjetivo() != null
                    ? " (" + retoActual.getElementoObjetivo().getSimbolo() + ")" : "";

            req.setAttribute("mensajeMascota",
                "¡Correcto! Construiste el núcleo de " + nombreElem + simb
                + " en el intento " + intento + ".\n\n"
                + "📈 +" + (int) delta + "% de aprendizaje. Porcentaje actual: " + (int) nuevoPct + "%\n\n"
                + "Recuerda: Z = protones define el elemento. A = protones + neutrones.");

            // ¿Puede continuar? Necesita ≥ RETOS_MIN acertados Y ≥ PCT_MINIMO_CONT
            boolean puedeContar = retosOk >= RETOS_MIN && nuevoPct >= PCT_MINIMO_CONT;
            req.setAttribute("habilitarContinuar", puedeContar);

            if (!puedeContar) {
                generarNuevoReto(escenario, usuario, req, sesion);
            }

        } else {
            // ── FALLO ──────────────────────────────────────────────────────
            puntajeDAO.insertar(retoActual.getIdReto(), intento, 0f, false);

            if (retoActual.agotadoIntentos()) {
                // Intentos agotados
                retoDAO.actualizar(retoActual);
                float nuevoPct = clamp(getPct(sesion) + PCT_AGOTADO);
                setPct(sesion, nuevoPct);
                escenario.getProgreso().setPorcentajeAprendizaje(nuevoPct);
                progresoDAO.guardar(usuario.getIdUsuario(), ID_ESCENARIO, nuevoPct);

                req.setAttribute("mensajeMascota",
                    "Se agotaron los 3 intentos para este reto.\n\n"
                    + "📉 " + (int) PCT_AGOTADO + "% de aprendizaje. Porcentaje actual: "
                    + (int) nuevoPct + "%\n\n"
                    + "El reto pedía: "
                    + retoObjetivo.getProtones() + " protón(es) y "
                    + retoObjetivo.getNeutrones() + " neutrón(es).\n"
                    + "¡Sigue practicando!");
                generarNuevoReto(escenario, usuario, req, sesion);

            } else {
                // Intento fallido pero quedan más
                float nuevoPct = clamp(getPct(sesion) + PCT_FALLO);
                setPct(sesion, nuevoPct);
                escenario.getProgreso().setPorcentajeAprendizaje(nuevoPct);

                int restantes = Reto.MAX_INTENTOS - intento;
                req.setAttribute("mensajeMascota",
                    "Esa configuración no es correcta.\n\n"
                    + "📉 " + (int) PCT_FALLO + "% de aprendizaje. Porcentaje actual: "
                    + (int) nuevoPct + "%\n\n"
                    + "Recuerda: el reto pide un número específico de protones y neutrones.\n"
                    + "Te quedan " + restantes + " intento(s).");
            }
        }

        sesion.setAttribute(SESION_RETO, retoActual);
    }

    // ── Continuar ────────────────────────────────────────────────────────────
    private void accionContinuar(Escenario escenario, HttpSession sesion,
                                  HttpServletResponse resp) throws IOException {
        if (escenario.getProgreso().getPorcentajeAprendizaje() >= PCT_MINIMO_CONT
                && getRetosOk(sesion) >= RETOS_MIN) {
            escenario.superarEscenario();
            sesion.removeAttribute(SESION_ESC);
            // TODO: redirigir al siguiente escenario
            resp.sendRedirect("login.jsp");
        }
    }

    // ── Finalizar ────────────────────────────────────────────────────────────
    private void accionFinalizar(Escenario escenario, HttpSession sesion,
                                  HttpServletRequest req) {
        escenario.setModoEvaluacion(false);
        sesion.removeAttribute(SESION_RETO);
        sesion.removeAttribute(SESION_OBJETIVO);
        float pct     = getPct(sesion);
        int   retosOk = getRetosOk(sesion);
        req.setAttribute("mensajeMascota",
            "Evaluación finalizada.\n\n"
            + "📊 Porcentaje de aprendizaje: " + (int) pct + "%\n"
            + "✅ Retos acertados: " + retosOk + " / " + RETOS_MIN + " mínimo\n\n"
            + (pct >= PCT_MINIMO_CONT && retosOk >= RETOS_MIN
                ? "¡Has superado el escenario! Pulsa CONTINUAR."
                : "Necesitas ≥80% y acertar al menos " + RETOS_MIN + " retos. ¡Sigue practicando!"));
    }

    // ── Volver ───────────────────────────────────────────────────────────────
    private void accionVolver(Escenario escenario, HttpSession sesion,
                               HttpServletResponse resp) throws IOException {
        escenario.salirEscenario();
        sesion.removeAttribute(SESION_ESC);
        resp.sendRedirect("login.jsp");
    }

    // ════════════════════════════════════════════════════════════════════════
    //  HELPERS
    // ════════════════════════════════════════════════════════════════════════

    /** Genera un reto nuevo con objeto Reto completamente fresco (intentos = 0). */
    private void generarNuevoReto(Escenario escenario, Usuario usuario,
                                   HttpServletRequest req, HttpSession sesion) {
        ElementoBase ebObjetivo = elementoDAO.obtenerAleatorio();
        if (ebObjetivo == null) return;

        // Para escenario 2: neutrones = Z (isótopo estable por defecto)
        int protonObjetivo   = ebObjetivo.getNumeroAtomico();
        int neutronObjetivo  = ebObjetivo.getNumeroAtomico();

        Elemento atomoObjetivo = new Elemento(protonObjetivo, neutronObjetivo, 0);

        // Objeto Reto siempre nuevo → intentos empieza en 0
        Reto reto = new Reto();
        reto.setIdUsuario(usuario.getIdUsuario());
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

        escenario.setRetoActual(reto);
        sesion.setAttribute(SESION_RETO,     reto);
        sesion.setAttribute(SESION_OBJETIVO, atomoObjetivo);

        req.setAttribute("nuevoReto",       true);
        req.setAttribute("retoActual",      reto);
        req.setAttribute("descripcionReto", reto.getDescripcion());
        req.setAttribute("temporizador",    reto.getTemporizador());
        req.setAttribute("intentosUsados",  0);
    }

    /** Publica todos los atributos necesarios para el JSP. */
    private void publicarDatos(Escenario escenario, HttpServletRequest req,
                                HttpSession sesion) {
        Elemento el = escenario.getElemento();
        req.setAttribute("protones",    el.getProtones());
        req.setAttribute("neutrones",   el.getNeutrones());
        req.setAttribute("numeroMasico", el.getNumeroMasico());
        req.setAttribute("modoEvaluacion", escenario.isModoEvaluacion());

        // Porcentaje de la sesión (no el histórico de BD)
        float pct     = getPct(sesion);
        int   retosOk = getRetosOk(sesion);
        escenario.getProgreso().setPorcentajeAprendizaje(pct);
        req.setAttribute("porcentaje", Math.round(pct));

        // Habilitar continuar solo si cumple ambas condiciones
        boolean puedeContar = escenario.isModoEvaluacion()
                && pct >= PCT_MINIMO_CONT
                && retosOk >= RETOS_MIN;
        req.setAttribute("habilitarContinuar", puedeContar);

        req.setAttribute("elementoIdentificado", escenario.getElementoIdentificado());

        // Datos del reto activo (si no fueron sobreescritos por la acción)
        Reto ra = (Reto) sesion.getAttribute(SESION_RETO);
        if (ra != null && req.getAttribute("retoActual") == null) {
            req.setAttribute("retoActual",      ra);
            req.setAttribute("temporizador",    ra.getTemporizador());
            req.setAttribute("intentosUsados",  ra.getIntentos());
            if (req.getAttribute("descripcionReto") == null)
                req.setAttribute("descripcionReto", ra.getDescripcion());
        }
    }

    /** Obtiene o crea el objeto Escenario de la sesión. */
    private Escenario obtenerOCrearEscenario(HttpSession sesion) {
        Escenario esc = (Escenario) sesion.getAttribute(SESION_ESC);
        if (esc == null) esc = new Escenario(ID_ESCENARIO, "Número y Núcleo Atómico", 3);
        return esc;
    }

    // ── Accesores al porcentaje y retos de sesión ───────────────────────────
    private float getPct(HttpSession ses) {
        Float v = (Float) ses.getAttribute(SESION_PCT);
        return v != null ? v : 0f;
    }
    private void setPct(HttpSession ses, float v) {
        ses.setAttribute(SESION_PCT, v);
    }
    private int getRetosOk(HttpSession ses) {
        Integer v = (Integer) ses.getAttribute(SESION_RETOS_OK);
        return v != null ? v : 0;
    }

    /** Limita el porcentaje entre 0 y 100. */
    private float clamp(float v) {
        return Math.max(0f, Math.min(100f, v));
    }
}
