package controlador;

import logica.EscenarioTresServicio;
import logica.EscenarioTresServicio.ResultadoComprobacion;
import logica.EscenarioTresServicio.ResultadoReto;
import modelo.ElementoBase;
import modelo.Elemento;
import modelo.Escenario;
import modelo.Reto;
import modelo.Usuario;

import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.*;
import java.io.IOException;

/**
 * EscenarioTresControlador – Escenario 3 "Configura tu Átomo Objetivo"
 *
 * ARQUITECTURA MVC ESTRICTA:
 *
 *   JSP (Vista)
 *     ↓ acción HTTP (POST/GET)
 *   EscenarioTresControlador   ← orquesta, NO conoce DAOs
 *     ↓ delega toda lógica
 *   EscenarioTresServicio      ← lógica de negocio + acceso a datos
 *     ↓
 *   ElementoBaseDAO / RetoDAO / PuntajeRetoDAO / ProgresoEscenarioDAO
 *     ↓
 *   ConexionDB → Base de datos
 *     ↑ entidades
 *   modelo.* (Elemento, ElementoBase, Reto, Escenario…)
 *     ↑ DTOs
 *   ResultadoReto / ResultadoComprobacion
 *     ↑ atributos request
 *   JSP (Vista)
 *
 * REGLA: El controlador NO importa ningún DAO.
 *        Toda lógica de negocio y persistencia vive en EscenarioTresServicio.
 */
@WebServlet("/escenario3")
public class EscenarioTresControlador extends HttpServlet {

    // Única dependencia del controlador: la capa lógica
    private final EscenarioTresServicio servicio = new EscenarioTresServicio();

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
            case "cargar":      accionCargar    (escenario, usuario, req, sesion); break;
            case "incrementar": accionMoverPart (escenario, req, true);            break;
            case "decrementar": accionMoverPart (escenario, req, false);           break;
            case "reiniciar":   accionReiniciar (escenario, sesion);               break;
            case "iniciarEval": accionIniciarEval(escenario, usuario, req, sesion);break;
            case "comprobar":   accionComprobar (escenario, usuario, req, sesion); break;
            case "continuar":   accionContinuar (escenario, sesion, resp); return;
            case "finalizar":   accionFinalizar (escenario, sesion, req);          break;
            case "volver":      accionVolver    (escenario, sesion, resp); return;
            default:            accionCargar    (escenario, usuario, req, sesion);
        }

        sesion.setAttribute("escenario3", escenario);
        publicarVista(escenario, req, sesion);
        req.getRequestDispatcher("/escenario3/escenario3.jsp").forward(req, resp);
    }

    // ════════════════════════════════════════════════════════════════════════
    // ACCIONES — solo orquestan, toda lógica en EscenarioTresServicio
    // ════════════════════════════════════════════════════════════════════════

    /** Carga inicial: recupera progreso de BD vía servicio y muestra bienvenida. */
    private void accionCargar(Escenario escenario, Usuario usuario,
                               HttpServletRequest req, HttpSession sesion) {
        escenario.cargarEscenario();
        // Delega al servicio → ProgresoEscenarioDAO → BD
        float pct = servicio.cargarProgreso(usuario.getIdUsuario());
        escenario.getProgreso().setPorcentajeAprendizaje(pct);
        req.setAttribute("mensajeMascota", escenario.guiaMascota());
    }

    /**
     * Mueve una partícula (+1 o -1).
     * Delega al servicio → Elemento + ElementoBaseDAO → BD (si cambian protones).
     */
    private void accionMoverPart(Escenario escenario, HttpServletRequest req,
                                  boolean incrementar) {
        String particula = req.getParameter("particula");
        if (particula == null) return;
        ElementoBase eb = incrementar
            ? servicio.incrementar(escenario, particula)
            : servicio.decrementar(escenario, particula);
        if (eb != null) req.setAttribute("elementoIdentificado", eb);
    }

    /** Reinicia el átomo y elimina el reto de la sesión. */
    private void accionReiniciar(Escenario escenario, HttpSession sesion) {
        escenario.reiniciarEscenario();
        sesion.removeAttribute("retoActual3");
        sesion.removeAttribute("retoObjetivo3");
    }

    /**
     * Activa modo evaluación y genera el primer reto.
     * Delega al servicio → ElementoBaseDAO + RetoDAO → BD.
     */
    private void accionIniciarEval(Escenario escenario, Usuario usuario,
                                   HttpServletRequest req, HttpSession sesion) {
        escenario.iniciarEvaluacion();
        generarYPublicarReto(usuario, req, sesion, escenario);
    }

    /**
     * Comprueba la configuración del estudiante.
     * Delega al servicio toda la lógica de validación y persistencia.
     * El controlador solo publica el resultado en el request.
     */
    private void accionComprobar(Escenario escenario, Usuario usuario,
                                  HttpServletRequest req, HttpSession sesion) {

        Reto     retoActual   = (Reto)     sesion.getAttribute("retoActual3");
        Elemento retoObjetivo = (Elemento) sesion.getAttribute("retoObjetivo3");

        if (retoActual == null || retoObjetivo == null) {
            req.setAttribute("mensajeMascota",
                "No hay un reto activo. Presiona 'Iniciar Evaluación'.");
            return;
        }

        // Delega al servicio: valida Z y A, registra intento, persiste en BD
        ResultadoComprobacion res =
            servicio.comprobar(escenario, retoActual, retoObjetivo, usuario);

        // El controlador solo publica resultados en request
        req.setAttribute("resultadoCorrecto", res.correcto);
        req.setAttribute("intentosUsados",    res.intentoUsado);
        req.setAttribute("mensajeMascota",    res.mensajeMascota);

        sesion.setAttribute("retoActual3", retoActual); // estado actualizado

        if (res.habilitarContinuar) {
            req.setAttribute("habilitarContinuar", true);
        }

        if (res.generarNuevoReto && !res.habilitarContinuar) {
            // Reto terminado (acierto o agotó intentos) → generar siguiente
            generarYPublicarReto(usuario, req, sesion, escenario);
        } else {
            // Reto sigue activo → mantener objetivo visible
            publicarObjetivo(retoObjetivo, retoActual, req);
        }
    }

    /** Avanza al escenario 4 si el porcentaje mínimo fue alcanzado. */
    private void accionContinuar(Escenario escenario, HttpSession sesion,
                                  HttpServletResponse resp) throws IOException {
        if (escenario.getProgreso().getPorcentajeAprendizaje() >= 80.0f) {
            escenario.superarEscenario();
            sesion.removeAttribute("escenario3");
            resp.sendRedirect("escenario4");
        }
    }

    /** Sale del modo evaluación sin avanzar de escenario. */
    private void accionFinalizar(Escenario escenario, HttpSession sesion,
                                  HttpServletRequest req) {
        escenario.setModoEvaluacion(false);
        sesion.removeAttribute("retoActual3");
        sesion.removeAttribute("retoObjetivo3");
        float pct = escenario.getProgreso().getPorcentajeAprendizaje();
        req.setAttribute("mensajeMascota",
            "Evaluación finalizada. Porcentaje: " + Math.round(pct) + "%. "
            + (pct >= 80 ? "¡Has superado el escenario!" :
                           "Sigue practicando para alcanzar el 80%."));
    }

    /** Regresa al menú principal. */
    private void accionVolver(Escenario escenario, HttpSession sesion,
                               HttpServletResponse resp) throws IOException {
        escenario.salirEscenario();
        sesion.removeAttribute("escenario3");
        resp.sendRedirect("login.jsp");
    }

    // ════════════════════════════════════════════════════════════════════════
    // HELPERS — solo gestionan datos entre servicio, sesión y request
    // ════════════════════════════════════════════════════════════════════════

    /**
     * Solicita al servicio un nuevo reto y distribuye los resultados
     * entre sesión (estado) y request (para el JSP).
     */
    private void generarYPublicarReto(Usuario usuario, HttpServletRequest req,
                                       HttpSession sesion, Escenario escenario) {
        // Delega al servicio → ElementoBaseDAO + RetoDAO → BD
        ResultadoReto res = servicio.generarReto(usuario);
        if (res == null) return;

        // Estado en sesión
        sesion.setAttribute("retoActual3",   res.reto);
        sesion.setAttribute("retoObjetivo3", res.atomoObjetivo);
        escenario.setRetoActual(res.reto);

        // Datos para el JSP
        req.setAttribute("nuevoReto",       true);
        req.setAttribute("retoActual",      res.reto);
        req.setAttribute("descripcionReto", res.reto.getDescripcion());
        req.setAttribute("temporizador",    res.reto.getTemporizador());
        req.setAttribute("intentosUsados",  0);
        publicarObjetivo(res.atomoObjetivo, res.reto, req);
    }

    /**
     * Publica los datos del átomo objetivo en el request
     * para que el JSP dibuje la carta central.
     */
    private void publicarObjetivo(Elemento objetivo, Reto reto,
                                   HttpServletRequest req) {
        if (objetivo == null || reto == null) return;
        ElementoBase eb = reto.getElementoObjetivo();
        req.setAttribute("objProtones",  objetivo.getProtones());
        req.setAttribute("objNeutrones", objetivo.getNeutrones());
        req.setAttribute("objMasico",    objetivo.getNumeroMasico());
        req.setAttribute("objSimbolo",   eb != null ? eb.getSimbolo() : "?");
        req.setAttribute("objNombre",    eb != null ? eb.getNombre()  : "Desconocido");
    }

    /**
     * Publica todos los atributos de presentación en el request.
     * El controlador NO calcula nada; solo transfiere estado al JSP.
     */
    private void publicarVista(Escenario escenario, HttpServletRequest req,
                                HttpSession sesion) {
        Elemento el = escenario.getElemento();
        req.setAttribute("protones",     el.getProtones());
        req.setAttribute("neutrones",    el.getNeutrones());
        req.setAttribute("electrones",   el.getElectrones());
        req.setAttribute("numeroMasico", el.getNumeroMasico());
        req.setAttribute("cargaNeta",    el.getCargaNeta());

        boolean enEval = escenario.isModoEvaluacion();
        req.setAttribute("modoEvaluacion", enEval);
        req.setAttribute("habilitarContinuar",
            escenario.getProgreso().getPorcentajeAprendizaje() >= 80.0f && enEval);
        req.setAttribute("elementoIdentificado", escenario.getElementoIdentificado());
        req.setAttribute("porcentaje",
            Math.round(escenario.getProgreso().getPorcentajeAprendizaje()));

        // HUD del reto — solo si no fue publicado en esta petición
        Reto ra = (Reto) sesion.getAttribute("retoActual3");
        if (ra != null && req.getAttribute("retoActual") == null) {
            req.setAttribute("retoActual",    ra);
            req.setAttribute("temporizador",  ra.getTemporizador());
            if (req.getAttribute("intentosUsados") == null)
                req.setAttribute("intentosUsados", ra.getIntentos());
            if (req.getAttribute("descripcionReto") == null)
                req.setAttribute("descripcionReto", ra.getDescripcion());
        }

        // Objetivo — solo si no fue publicado en esta petición
        Elemento obj = (Elemento) sesion.getAttribute("retoObjetivo3");
        if (obj != null && req.getAttribute("objProtones") == null)
            publicarObjetivo(obj, ra, req);
    }

    private Escenario obtenerOCrearEscenario(HttpSession sesion) {
        Escenario esc = (Escenario) sesion.getAttribute("escenario3");
        if (esc == null) esc = new Escenario(3, "Configura tu Átomo Objetivo", 3);
        return esc;
    }
}