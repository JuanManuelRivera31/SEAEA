package controlador;

import dao.*;
import modelo.*;
import logica.EscenarioTresServicio;

import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.*;
import java.io.IOException;

/**
 * EscenarioTresControlador
 * Servlet controlador del Escenario 3 "Configura tu Átomo Objetivo".
 *
 * Diferencia respecto al Escenario 1:
 *  - El sistema genera un elemento aleatorio de la tabla periódica.
 *  - El usuario debe igualar SOLO el número atómico Z (protones)
 *    y el número másico A (protones + neutrones).
 *  - Los electrones NO se evalúan en la comprobación.
 */
@WebServlet("/escenario3")
public class EscenarioTresControlador extends HttpServlet {

    private static final int ID_ESCENARIO = 3;

    private final ElementoBaseDAO      elementoDAO  = new ElementoBaseDAO();
    private final RetoDAO              retoDAO      = new RetoDAO();
    private final PuntajeRetoDAO       puntajeDAO   = new PuntajeRetoDAO();
    private final ProgresoEscenarioDAO progresoDAO  = new ProgresoEscenarioDAO();

    @Override
    protected void doGet(HttpServletRequest req, HttpServletResponse resp)
            throws ServletException, IOException {
        procesarAccion(req, resp);
    }

    @Override
    protected void doPost(HttpServletRequest req, HttpServletResponse resp)
            throws ServletException, IOException {
        procesarAccion(req, resp);
    }

    private void procesarAccion(HttpServletRequest req, HttpServletResponse resp)
            throws ServletException, IOException {

        HttpSession sesion = req.getSession(false);
        if (sesion == null || sesion.getAttribute("usuario") == null) {
            resp.sendRedirect(req.getContextPath() + "escenario4");
            return;
        }

        Usuario   usuario   = (Usuario)   sesion.getAttribute("usuario");
        Escenario escenario = obtenerOCrearEscenario(sesion);
        String    accion    = req.getParameter("accion");
        if (accion == null) accion = "cargar";

        switch (accion) {
            case "cargar":
                accionCargar(escenario, usuario, req, sesion);
                break;
            case "incrementar":
                accionIncrementar(escenario, req.getParameter("particula"), req);
                break;
            case "decrementar":
                accionDecrementar(escenario, req.getParameter("particula"), req);
                break;
            case "reiniciar":
                accionReiniciar(escenario, sesion);
                break;
            case "iniciarEval":
                accionIniciarEvaluacion(escenario, usuario, req, sesion);
                break;
            case "comprobar":
                accionComprobar(escenario, usuario, req, sesion);
                break;
            case "continuar":
                accionContinuar(escenario, sesion, resp);
                return;
            case "finalizar":
                accionFinalizar(escenario, sesion, req);
                break;
            case "volver":
                accionVolver(escenario, sesion, resp);
                return;
            default:
                accionCargar(escenario, usuario, req, sesion);
        }

        sesion.setAttribute("escenario3", escenario);
        publicarDatosAtomo(escenario, req);
        req.getRequestDispatcher("/escenario3/escenario3.jsp").forward(req, resp);
    }

    // ── CARGAR ──────────────────────────────────────────────────────────────
    private void accionCargar(Escenario escenario, Usuario usuario,
                               HttpServletRequest req, HttpSession sesion) {
        escenario.cargarEscenario();
        float pct = progresoDAO.obtenerPorcentaje(usuario.getIdUsuario(), ID_ESCENARIO);
        escenario.getProgreso().setPorcentajeAprendizaje(pct);
        req.setAttribute("mensajeMascota", escenario.guiaMascota());
        sesion.setAttribute("escenario3", escenario);
    }

    // ── INCREMENTAR / DECREMENTAR ────────────────────────────────────────────
    private void accionIncrementar(Escenario escenario, String particula,
                                    HttpServletRequest req) {
        if (particula == null) return;
        Elemento el = escenario.getElemento();
        switch (particula) {
            case "protones":
                el.incrementarProtones();
                actualizarElementoPorProtones(escenario, el.getProtones(), req);
                break;
            case "neutrones":
                el.incrementarNeutrones();
                break;
            case "electrones":
                el.incrementarElectrones();
                break;
        }
    }

    private void accionDecrementar(Escenario escenario, String particula,
                                    HttpServletRequest req) {
        if (particula == null) return;
        Elemento el = escenario.getElemento();
        switch (particula) {
            case "protones":
                el.decrementarProtones();
                actualizarElementoPorProtones(escenario, el.getProtones(), req);
                break;
            case "neutrones":
                el.decrementarNeutrones();
                break;
            case "electrones":
                el.decrementarElectrones();
                break;
        }
    }

    // ── REINICIAR ────────────────────────────────────────────────────────────
    private void accionReiniciar(Escenario escenario, HttpSession sesion) {
        escenario.reiniciarEscenario();
        sesion.removeAttribute("retoActual3");
        sesion.removeAttribute("retoObjetivo3");
    }

    // ── INICIAR EVALUACIÓN ───────────────────────────────────────────────────
    private void accionIniciarEvaluacion(Escenario escenario, Usuario usuario,
                                          HttpServletRequest req, HttpSession sesion) {
        escenario.iniciarEvaluacion();
        generarNuevoReto(escenario, usuario, req, sesion);
    }

    // ── COMPROBAR ────────────────────────────────────────────────────────────
    /**
     * Lógica de comprobación del Escenario 3:
     * Se valida SOLO que:
     *   - protones del estudiante == Z del objetivo  (número atómico)
     *   - (protones + neutrones) del estudiante == A del objetivo (número másico)
     * Los electrones NO se evalúan.
     */
    private void accionComprobar(Escenario escenario, Usuario usuario,
                                  HttpServletRequest req, HttpSession sesion) {

        Reto     retoActual    = (Reto)     sesion.getAttribute("retoActual3");
        Elemento retoObjetivo  = (Elemento) sesion.getAttribute("retoObjetivo3");

        if (retoActual == null || retoObjetivo == null) {
            req.setAttribute("mensajeMascota", "No hay un reto activo. Presiona 'Iniciar Evaluación'.");
            return;
        }

        Elemento atomoEstudiante = escenario.getElemento();

        // ── Comprobación específica del Escenario 3 (Z y A) ──────────────────
        boolean correcto = (atomoEstudiante.getProtones()     == retoObjetivo.getProtones()) &&
                           (atomoEstudiante.getNumeroMasico() == retoObjetivo.getNumeroMasico());

        retoActual.registrarIntento();
        int intento = retoActual.getIntentos();

        req.setAttribute("resultadoCorrecto", correcto);
        req.setAttribute("intentosUsados",    intento);

        if (correcto) {
            // ── ÉXITO ──────────────────────────────────────────────────────
            retoActual.setCompletado(true);
            PuntajeReto pr = new PuntajeReto(retoActual, intento, true);
            escenario.getProgreso().agregarResultado(pr);

            retoDAO.actualizar(retoActual);
            puntajeDAO.insertar(retoActual.getIdReto(), intento, pr.getPuntaje(), true);
            float nuevoPorcentaje = puntajeDAO.calcularPorcentajeAprendizaje(
                    usuario.getIdUsuario(), ID_ESCENARIO);
            progresoDAO.guardar(usuario.getIdUsuario(), ID_ESCENARIO, nuevoPorcentaje);
            escenario.getProgreso().setPorcentajeAprendizaje(nuevoPorcentaje);

            ElementoBase eb = retoActual.getElementoObjetivo();
            String nombreElem = (eb != null) ? eb.getNombre()   : "el elemento";
            String simbolo    = (eb != null) ? " (" + eb.getSimbolo() + ")" : "";
            int    zA         = (eb != null) ? eb.getNumeroAtomico() : retoObjetivo.getProtones();
            int    masico     = retoObjetivo.getNumeroMasico();

            String msgExito =
                "¡Lo lograste! Configuraste correctamente el átomo de "
                + nombreElem + simbolo + " en el intento " + intento + ".\n"
                + "Z = " + zA + " (protones) · A = " + masico
                + " (número másico) · Neutrones = " + retoObjetivo.getNeutrones() + ".\n"
                + "Recuerda: A = Z + N  →  N = A − Z.";
            req.setAttribute("mensajeMascota", msgExito);

            if (nuevoPorcentaje >= 80.0f) {
                req.setAttribute("habilitarContinuar", true);
            } else {
                generarNuevoReto(escenario, usuario, req, sesion);
            }

        } else {
            // ── FALLO ─────────────────────────────────────────────────────
            puntajeDAO.insertar(retoActual.getIdReto(), intento, 0.0f, false);

            if (retoActual.agotadoIntentos()) {
                // ── INTENTOS AGOTADOS ──────────────────────────────────────
                PuntajeReto prFallo = new PuntajeReto(retoActual, 3, false);
                escenario.getProgreso().agregarResultado(prFallo);
                float nuevoPorcentaje = puntajeDAO.calcularPorcentajeAprendizaje(
                        usuario.getIdUsuario(), ID_ESCENARIO);
                progresoDAO.guardar(usuario.getIdUsuario(), ID_ESCENARIO, nuevoPorcentaje);
                escenario.getProgreso().setPorcentajeAprendizaje(nuevoPorcentaje);
                retoDAO.actualizar(retoActual);

                req.setAttribute("mensajeMascota",
                    "Agotaste los 3 intentos para este reto. ¡No te rindas!\n"
                    + "He generado un nuevo reto para que puedas seguir aprendiendo.");

                generarNuevoReto(escenario, usuario, req, sesion);

            } else {
                // ── FALLO PARCIAL ──────────────────────────────────────────
                int restantes = Reto.MAX_INTENTOS - intento;

                // Pistas específicas: indicar si Z o A están mal
                boolean zOk = atomoEstudiante.getProtones()     == retoObjetivo.getProtones();
                boolean aOk = atomoEstudiante.getNumeroMasico() == retoObjetivo.getNumeroMasico();

                String pista;
                if (!zOk && !aOk) {
                    pista = "Tanto el número atómico (Z) como el número másico (A) son incorrectos.";
                } else if (!zOk) {
                    pista = "El número atómico (Z = protones) no es correcto. Revisa los protones.";
                } else {
                    pista = "El número másico (A = protones + neutrones) no es correcto. Revisa los neutrones.";
                }

                req.setAttribute("mensajeMascota",
                    "Esa configuración no es correcta aún. " + pista
                    + "\nTe quedan " + restantes + " intento(s) para este reto.");
            }
        }

        sesion.setAttribute("retoActual3", retoActual);

        // Publicar datos del reto para el HUD
        Reto ra = (Reto) sesion.getAttribute("retoActual3");
        if (ra != null) {
            req.setAttribute("retoActual",    ra);
            req.setAttribute("temporizador",  ra.getTemporizador());
            req.setAttribute("intentosUsados", ra.getIntentos());
            if (req.getAttribute("descripcionReto") == null) {
                req.setAttribute("descripcionReto", ra.mostrarReto());
            }
        }

        // Publicar elemento objetivo para mostrarlo en pantalla
        publicarElementoObjetivo(retoObjetivo, retoActual, req);
    }

    // ── CONTINUAR ────────────────────────────────────────────────────────────
    private void accionContinuar(Escenario escenario, HttpSession sesion,
                                  HttpServletResponse resp) throws IOException {
        if (escenario.getProgreso().getPorcentajeAprendizaje() >= 80.0f) {
            escenario.superarEscenario();
            sesion.removeAttribute("escenario3");
            resp.sendRedirect("escenario4");
        }
    }

    // ── FINALIZAR ────────────────────────────────────────────────────────────
    private void accionFinalizar(Escenario escenario, HttpSession sesion,
                                  HttpServletRequest req) {
        escenario.setModoEvaluacion(false);
        sesion.removeAttribute("retoActual3");
        sesion.removeAttribute("retoObjetivo3");
        float pct = escenario.getProgreso().getPorcentajeAprendizaje();
        req.setAttribute("mensajeMascota",
            "Evaluación finalizada. Tu porcentaje de aprendizaje actual es "
            + Math.round(pct) + "%. "
            + (pct >= 80 ? "¡Has superado el escenario!" : "Sigue practicando para alcanzar el 80%."));
    }

    // ── VOLVER ───────────────────────────────────────────────────────────────
    private void accionVolver(Escenario escenario, HttpSession sesion,
                               HttpServletResponse resp) throws IOException {
        escenario.salirEscenario();
        sesion.removeAttribute("escenario3");
        resp.sendRedirect("login.jsp");
    }

    // ── HELPERS ──────────────────────────────────────────────────────────────

    /**
     * Genera un nuevo reto para el Escenario 3.
     * El átomo objetivo tiene: protones = Z, neutrones = A - Z (masa estándar), electrones = 0 (no se evalúan).
     */
    private void generarNuevoReto(Escenario escenario, Usuario usuario,
                                   HttpServletRequest req, HttpSession sesion) {
        ElementoBase ebObjetivo = elementoDAO.obtenerAleatorio();
        if (ebObjetivo == null) return;

        int z = ebObjetivo.getNumeroAtomico();
        // Número másico estándar: redondeamos la masa atómica
        int a = (int) Math.round(ebObjetivo.getMasaAtomica());
        int n = a - z;
        if (n < 0) n = z; // Fallback: si la masa no está bien cargada

        // Para el Escenario 3 el elemento objetivo representa Z y A; electrones no se evalúan
        Elemento atomoObjetivo = new Elemento(z, n, z); // electrones = z por convención (neutro)

        Reto reto = new Reto();
        reto.setIdUsuario(usuario.getIdUsuario());
        reto.setIdEscenario(ID_ESCENARIO);
        reto.generarReto(ebObjetivo, z, n, z);

        int idReto = retoDAO.insertar(reto);
        reto.setIdReto(idReto);

        escenario.setRetoActual(reto);
        sesion.setAttribute("retoActual3",   reto);
        sesion.setAttribute("retoObjetivo3", atomoObjetivo);

        req.setAttribute("nuevoReto",       true);
        req.setAttribute("retoActual",      reto);
        req.setAttribute("descripcionReto", reto.getDescripcion());
        req.setAttribute("temporizador",    reto.getTemporizador());
        req.setAttribute("intentosUsados",  0);

        // Publicar datos del elemento objetivo para mostrarlo en pantalla
        publicarElementoObjetivo(atomoObjetivo, reto, req);
    }

    /**
     * Publica en request los datos del elemento objetivo
     * para que el JSP pueda mostrar la "carta objetivo".
     */
    private void publicarElementoObjetivo(Elemento objetivo, Reto reto,
                                           HttpServletRequest req) {
        if (objetivo == null || reto == null) return;
        ElementoBase eb = reto.getElementoObjetivo();
        req.setAttribute("objProtones",  objetivo.getProtones());
        req.setAttribute("objNeutrones", objetivo.getNeutrones());
        req.setAttribute("objMasico",    objetivo.getNumeroMasico());
        req.setAttribute("objSimbolo",   eb != null ? eb.getSimbolo() : "?");
        req.setAttribute("objNombre",    eb != null ? eb.getNombre()  : "Desconocido");
    }

    private void actualizarElementoPorProtones(Escenario escenario,
                                                int protones,
                                                HttpServletRequest req) {
        if (protones > 0) {
            ElementoBase eb = elementoDAO.obtenerPorNumeroAtomico(protones);
            escenario.actualizarCartaPeriodicaElemento(eb);
            req.setAttribute("elementoIdentificado", eb);
        } else {
            escenario.actualizarCartaPeriodicaElemento(null);
            req.setAttribute("elementoIdentificado", null);
        }
    }

    private void publicarDatosAtomo(Escenario escenario, HttpServletRequest req) {
        Elemento el = escenario.getElemento();
        req.setAttribute("protones",      el.getProtones());
        req.setAttribute("neutrones",     el.getNeutrones());
        req.setAttribute("electrones",    el.getElectrones());
        req.setAttribute("numeroMasico",  el.getNumeroMasico());
        req.setAttribute("cargaNeta",     el.getCargaNeta());
        req.setAttribute("modoEvaluacion", escenario.isModoEvaluacion());
        req.setAttribute("habilitarContinuar",
            escenario.getProgreso().getPorcentajeAprendizaje() >= 80.0f
            && escenario.isModoEvaluacion());
        req.setAttribute("elementoIdentificado", escenario.getElementoIdentificado());

        int pct = Math.round(escenario.getProgreso().getPorcentajeAprendizaje());
        req.setAttribute("porcentaje", pct);

        HttpSession sesion = req.getSession(false);
        if (sesion != null) {
            Reto ra = (Reto) sesion.getAttribute("retoActual3");
            if (ra != null && req.getAttribute("retoActual") == null) {
                req.setAttribute("retoActual",    ra);
                req.setAttribute("temporizador",  ra.getTemporizador());
                req.setAttribute("intentosUsados", ra.getIntentos());
                if (req.getAttribute("descripcionReto") == null) {
                    req.setAttribute("descripcionReto", ra.getDescripcion());
                }
            }

            // Mantener datos del objetivo si ya hay reto activo
            Elemento obj = (Elemento) sesion.getAttribute("retoObjetivo3");
            if (obj != null && req.getAttribute("objProtones") == null) {
                publicarElementoObjetivo(obj, ra, req);
            }
        }
    }

    private Escenario obtenerOCrearEscenario(HttpSession sesion) {
        Escenario escenario = (Escenario) sesion.getAttribute("escenario3");
        if (escenario == null) {
            escenario = new Escenario(ID_ESCENARIO, "Configura tu Átomo Objetivo", 3);
        }
        return escenario;
    }
}

