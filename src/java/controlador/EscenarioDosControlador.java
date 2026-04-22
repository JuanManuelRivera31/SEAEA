package controlador;

import dao.*;
import modelo.*;

import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.*;
import java.io.IOException;

/**
 * EscenarioDosControlador
 * Servlet del Escenario 2 "Número y Núcleo Atómico".
 *
 * DIFERENCIAS con Escenario 1:
 *  - Solo se trabaja con PROTONES y NEUTRONES (sin electrones)
 *  - No hay barra de carga neta
 *  - El foco es el NÚCLEO y el NÚMERO ATÓMICO (Z)
 *
 * CORRECCIONES aplicadas (aprendidas del Escenario 1):
 *  1. Intentos por reto: el objeto Reto se crea NUEVO en cada generación → 0 intentos
 *  2. Porcentaje de sesión: se borra progreso al iniciar evaluación
 *  3. Timer: se limpia sessionStorage al generar nuevo reto
 *  4. mensajeMascota específico (nunca reutiliza guiaMascota())
 */
@WebServlet("/escenario2")
public class EscenarioDosControlador extends HttpServlet {

    private static final int ID_ESCENARIO = 2;

    private final ElementoBaseDAO      elementoDAO  = new ElementoBaseDAO();
    private final RetoDAO              retoDAO      = new RetoDAO();
    private final PuntajeRetoDAO       puntajeDAO   = new PuntajeRetoDAO();
    private final ProgresoEscenarioDAO progresoDAO  = new ProgresoEscenarioDAO();

    @Override
    protected void doGet(HttpServletRequest req, HttpServletResponse resp)
            throws ServletException, IOException { procesarAccion(req, resp); }

    @Override
    protected void doPost(HttpServletRequest req, HttpServletResponse resp)
            throws ServletException, IOException { procesarAccion(req, resp); }

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
            case "cargar":      accionCargar(escenario, usuario, req, sesion); break;
            case "incrementar": accionModificar(escenario, req.getParameter("particula"), true,  req); break;
            case "decrementar": accionModificar(escenario, req.getParameter("particula"), false, req); break;
            case "reiniciar":   accionReiniciar(escenario, sesion); break;
            case "iniciarEval": accionIniciarEvaluacion(escenario, usuario, req, sesion); break;
            case "comprobar":   accionComprobar(escenario, usuario, req, sesion); break;
            case "continuar":   accionContinuar(escenario, sesion, resp); return;
            case "finalizar":   accionFinalizar(escenario, sesion, req); break;
            case "volver":      accionVolver(escenario, sesion, resp); return;
            default:            accionCargar(escenario, usuario, req, sesion);
        }

        sesion.setAttribute("escenario2", escenario);
        publicarDatos(escenario, req, sesion);
        req.getRequestDispatcher("/escenario2/escenario2.jsp").forward(req, resp);
    }

    // ── CARGAR ──────────────────────────────────────────────────────────────
    private void accionCargar(Escenario escenario, Usuario usuario,
                               HttpServletRequest req, HttpSession sesion) {
        escenario.cargarEscenario();
        // CORRECCIÓN: Porcentaje inicia en 0 al cargar (sesión nueva)
        escenario.getProgreso().setPorcentajeAprendizaje(0.0f);
        req.setAttribute("mensajeMascota", escenario.guiaMascota());
        req.setAttribute("primeraCarga", true);
        sesion.setAttribute("escenario2", escenario);
    }

    // ── MODIFICAR (solo protones y neutrones) ────────────────────────────────
    private void accionModificar(Escenario escenario, String particula,
                                  boolean incrementar, HttpServletRequest req) {
        if (particula == null) return;
        Elemento el = escenario.getElemento();
        switch (particula) {
            case "protones":
                if (incrementar) el.incrementarProtones();
                else             el.decrementarProtones();
                // Actualizar elemento identificado por Z
                if (el.getProtones() > 0) {
                    ElementoBase eb = elementoDAO.obtenerPorNumeroAtomico(el.getProtones());
                    escenario.actualizarCartaPeriodicaElemento(eb);
                    req.setAttribute("elementoIdentificado", eb);
                } else {
                    escenario.actualizarCartaPeriodicaElemento(null);
                    req.setAttribute("elementoIdentificado", null);
                }
                break;
            case "neutrones":
                if (incrementar) el.incrementarNeutrones();
                else             el.decrementarNeutrones();
                // Al cambiar neutrones, el elemento NO cambia (RF-208)
                req.setAttribute("elementoIdentificado", escenario.getElementoIdentificado());
                break;
        }
    }

    // ── REINICIAR ────────────────────────────────────────────────────────────
    private void accionReiniciar(Escenario escenario, HttpSession sesion) {
        escenario.reiniciarEscenario();
        sesion.removeAttribute("reto2Actual");
        sesion.removeAttribute("reto2Objetivo");
        escenario.getProgreso().setPorcentajeAprendizaje(0.0f);
    }

    // ── INICIAR EVALUACIÓN ───────────────────────────────────────────────────
    /**
     * CORRECCIÓN: Al iniciar evaluación, se reinicia el porcentaje a 0
     * para que la barra sea de SESIÓN, no histórica.
     */
    private void accionIniciarEvaluacion(Escenario escenario, Usuario usuario,
                                          HttpServletRequest req, HttpSession sesion) {
        escenario.iniciarEvaluacion();
        // Reiniciar porcentaje de sesión
        escenario.getProgreso().setPorcentajeAprendizaje(0.0f);
        sesion.setAttribute("e2_retos_sesion", 0);
        sesion.setAttribute("e2_puntos_sesion", 0.0f);
        // Generar primer reto
        generarNuevoReto(escenario, usuario, req, sesion);
    }

    // ── COMPROBAR ────────────────────────────────────────────────────────────
    /**
     * CORRECCIONES APLICADAS:
     * 1. El reto se crea NUEVO en generarNuevoReto → intentos siempre empieza en 0
     * 2. Se verifica intento ANTES de registrar (evita sobre-conteo)
     * 3. Porcentaje calculado en memoria (no BD histórica) → sube correctamente
     */
    private void accionComprobar(Escenario escenario, Usuario usuario,
                                  HttpServletRequest req, HttpSession sesion) {

        Reto     retoActual   = (Reto)     sesion.getAttribute("reto2Actual");
        Elemento retoObjetivo = (Elemento) sesion.getAttribute("reto2Objetivo");

        if (retoActual == null || retoObjetivo == null) {
            req.setAttribute("mensajeMascota", "No hay reto activo. Presiona 'Iniciar Evaluación'.");
            return;
        }

        // CORRECCIÓN: verificar si ya se agotaron ANTES de registrar nuevo intento
        if (retoActual.agotadoIntentos()) {
            // No debería llegar aquí, pero por seguridad
            generarNuevoReto(escenario, usuario, req, sesion);
            return;
        }

        Elemento atomoEstudiante = escenario.getElemento();
        // En escenario 2: solo se valida protones y neutrones
        boolean correcto = (atomoEstudiante.getProtones()  == retoObjetivo.getProtones()
                         && atomoEstudiante.getNeutrones() == retoObjetivo.getNeutrones());

        // Registrar intento
        retoActual.registrarIntento();
        int intento = retoActual.getIntentos();

        req.setAttribute("resultadoCorrecto", correcto);
        req.setAttribute("intentosUsados",    intento);

        if (correcto) {
            // ── ÉXITO ──────────────────────────────────────────────────
            retoActual.setCompletado(true);

            // Persistir reto y puntaje
            retoDAO.actualizar(retoActual);
            double puntajeReto = intento == 1 ? 100.0 : intento == 2 ? 70.0 : 40.0;
            puntajeDAO.insertar(retoActual.getIdReto(), intento, (float)puntajeReto, true);

            // CORRECCIÓN: porcentaje calculado en SESIÓN (no histórico)
            float nuevoPct = calcularPorcentajeSesion(sesion, puntajeReto, true);
            escenario.getProgreso().setPorcentajeAprendizaje(nuevoPct);
            progresoDAO.guardar(usuario.getIdUsuario(), ID_ESCENARIO, nuevoPct);

            ElementoBase eb = retoActual.getElementoObjetivo();
            String nombreElem = (eb != null) ? eb.getNombre() : "el elemento";
            String simbolo    = (eb != null) ? " (" + eb.getSimbolo() + ")" : "";
            req.setAttribute("mensajeMascota",
                "¡Construiste correctamente el núcleo de " + nombreElem + simbolo
                + " en el intento " + intento + "! "
                + "Recuerda: Z = número de protones define el elemento. "
                + "El número másico A = protones + neutrones.");

            if (nuevoPct >= 80.0f) {
                req.setAttribute("habilitarContinuar", true);
            } else {
                generarNuevoReto(escenario, usuario, req, sesion);
            }

        } else {
            // ── FALLO ─────────────────────────────────────────────────
            puntajeDAO.insertar(retoActual.getIdReto(), intento, 0.0f, false);

            if (retoActual.agotadoIntentos()) {
                // ── INTENTOS AGOTADOS ──────────────────────────────────
                retoDAO.actualizar(retoActual);
                float nuevoPct = calcularPorcentajeSesion(sesion, 0.0, false);
                escenario.getProgreso().setPorcentajeAprendizaje(nuevoPct);
                progresoDAO.guardar(usuario.getIdUsuario(), ID_ESCENARIO, nuevoPct);

                req.setAttribute("mensajeMascota",
                    "Agotaste los 3 intentos para este reto. ¡No te rindas! "
                    + "He generado un nuevo reto para continuar aprendiendo.");
                generarNuevoReto(escenario, usuario, req, sesion);

            } else {
                int restantes = Reto.MAX_INTENTOS - intento;
                req.setAttribute("mensajeMascota",
                    "Esa configuración no es correcta. "
                    + "Recuerda: el reto pide un número específico de protones y neutrones. "
                    + "Te quedan " + restantes + " intento(s).");
            }
        }

        sesion.setAttribute("reto2Actual", retoActual);
    }

    // ── CONTINUAR ────────────────────────────────────────────────────────────
    private void accionContinuar(Escenario escenario, HttpSession sesion,
                                  HttpServletResponse resp) throws IOException {
        if (escenario.getProgreso().getPorcentajeAprendizaje() >= 80.0f) {
            escenario.superarEscenario();
            sesion.removeAttribute("escenario2");
            // TODO: redirigir a escenario3
            resp.sendRedirect("login.jsp");
        }
    }

    // ── FINALIZAR ────────────────────────────────────────────────────────────
    private void accionFinalizar(Escenario escenario, HttpSession sesion,
                                  HttpServletRequest req) {
        escenario.setModoEvaluacion(false);
        sesion.removeAttribute("reto2Actual");
        sesion.removeAttribute("reto2Objetivo");
        float pct = escenario.getProgreso().getPorcentajeAprendizaje();
        req.setAttribute("mensajeMascota",
            "Evaluación finalizada. Porcentaje de aprendizaje: " + Math.round(pct) + "%. "
            + (pct >= 80 ? "¡Has superado el escenario!" : "Sigue practicando para alcanzar el 80%."));
    }

    // ── VOLVER ───────────────────────────────────────────────────────────────
    private void accionVolver(Escenario escenario, HttpSession sesion,
                               HttpServletResponse resp) throws IOException {
        escenario.salirEscenario();
        sesion.removeAttribute("escenario2");
        resp.sendRedirect("login.jsp");
    }

    // ── HELPERS ──────────────────────────────────────────────────────────────

    /**
     * CORRECCIÓN CLAVE: porcentaje calculado en memoria de sesión.
     * Cada reto completado aporta puntaje/3 al total.
     * Con 3 retos perfectos (100 pts c/u): 100*3/3 = 100% → alcanza 80% fácilmente.
     */
    @SuppressWarnings("unchecked")
    private float calcularPorcentajeSesion(HttpSession sesion, double puntajeNuevo, boolean completado) {
        Integer retosCount = (Integer) sesion.getAttribute("e2_retos_sesion");
        Float   puntosAcc  = (Float)   sesion.getAttribute("e2_puntos_sesion");
        if (retosCount == null) retosCount = 0;
        if (puntosAcc  == null) puntosAcc  = 0.0f;

        retosCount++;
        puntosAcc += (float) puntajeNuevo;

        sesion.setAttribute("e2_retos_sesion", retosCount);
        sesion.setAttribute("e2_puntos_sesion", puntosAcc);

        // Porcentaje = suma de puntos / (retos * 100) * 100
        // Con 3 retos de 100pts: 300/300*100 = 100%
        // Con 1 reto de 100pts:  100/100*100 = 100% → subimos 100/3 = 33.3% por reto perfecto
        float pct = Math.min((puntosAcc / (retosCount * 100.0f)) * 100.0f, 100.0f);
        return Math.round(pct * 100.0f) / 100.0f;
    }

    /**
     * CORRECCIÓN: Genera reto con objeto NUEVO (intentos = 0 garantizado).
     * No reutiliza el objeto anterior.
     */
    private void generarNuevoReto(Escenario escenario, Usuario usuario,
                                   HttpServletRequest req, HttpSession sesion) {
        ElementoBase ebObjetivo = elementoDAO.obtenerAleatorio();
        if (ebObjetivo == null) return;

        // Objetivo: solo protones y neutrones (Z = N para átomo estable)
        Elemento atomoObjetivo = new Elemento(
            ebObjetivo.getNumeroAtomico(),  // protones = Z
            ebObjetivo.getNumeroAtomico(),  // neutrones = Z (núcleo estable)
            0                               // electrones no aplican en escenario 2
        );

        // CORRECCIÓN: objeto Reto SIEMPRE nuevo → intentos = 0
        Reto reto = new Reto();
        reto.setIdUsuario(usuario.getIdUsuario());
        reto.setIdEscenario(ID_ESCENARIO);
        reto.generarReto(ebObjetivo,
            atomoObjetivo.getProtones(),
            atomoObjetivo.getNeutrones(),
            0);
        // Sobrescribir descripción para escenario 2 (solo pide protones y neutrones)
        reto.setDescripcion("Construye el núcleo del elemento " + ebObjetivo.getNombre()
            + " (" + ebObjetivo.getSimbolo() + ") con "
            + atomoObjetivo.getProtones() + " protón(es) y "
            + atomoObjetivo.getNeutrones() + " neutrón(es).");

        int idReto = retoDAO.insertar(reto);
        reto.setIdReto(idReto);

        escenario.setRetoActual(reto);
        // CORRECCIÓN: guardar el nuevo objeto (no el anterior con intentos acumulados)
        sesion.setAttribute("reto2Actual",   reto);
        sesion.setAttribute("reto2Objetivo", atomoObjetivo);

        req.setAttribute("nuevoReto",       true);
        req.setAttribute("retoActual",      reto);
        req.setAttribute("descripcionReto", reto.getDescripcion());
        req.setAttribute("temporizador",    reto.getTemporizador());
        req.setAttribute("intentosUsados",  0);  // SIEMPRE 0 para nuevo reto
    }

    private void publicarDatos(Escenario escenario, HttpServletRequest req, HttpSession sesion) {
        Elemento el = escenario.getElemento();
        req.setAttribute("protones",    el.getProtones());
        req.setAttribute("neutrones",   el.getNeutrones());
        req.setAttribute("numeroMasico", el.getNumeroMasico());
        req.setAttribute("modoEvaluacion", escenario.isModoEvaluacion());
        req.setAttribute("habilitarContinuar",
            escenario.getProgreso().getPorcentajeAprendizaje() >= 80.0f
            && escenario.isModoEvaluacion());
        req.setAttribute("elementoIdentificado", escenario.getElementoIdentificado());
        int pct = Math.round(escenario.getProgreso().getPorcentajeAprendizaje());
        req.setAttribute("porcentaje", pct);

        // Datos del reto activo
        Reto ra = (Reto) sesion.getAttribute("reto2Actual");
        if (ra != null && req.getAttribute("retoActual") == null) {
            req.setAttribute("retoActual",    ra);
            req.setAttribute("temporizador",  ra.getTemporizador());
            req.setAttribute("intentosUsados", ra.getIntentos());
            if (req.getAttribute("descripcionReto") == null)
                req.setAttribute("descripcionReto", ra.getDescripcion());
        }
    }

    private Escenario obtenerOCrearEscenario(HttpSession sesion) {
        Escenario esc = (Escenario) sesion.getAttribute("escenario2");
        if (esc == null) esc = new Escenario(ID_ESCENARIO, "Número y Núcleo Atómico", 3);
        return esc;
    }
}

