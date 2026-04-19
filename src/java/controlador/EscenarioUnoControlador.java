package controlador;

import logica.EscenarioUnoServicio;
import logica.EscenarioUnoServicio.ResultadoComprobacion;
import logica.EscenarioUnoServicio.ResultadoReto;
import modelo.*;

import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.*;
import java.io.IOException;

/**
 * EscenarioUnoControlador
 * ─────────────────────────────────────────────────────────────
 * Servlet para el Escenario 1 "Arma tu átomo".
 * Solo coordina la sesión HTTP y delega toda la lógica al Servicio.
 *
 * Parámetro "accion" esperado:
 *   cargar | incrementar | decrementar | reiniciar |
 *   iniciarEval | comprobar | continuar | finalizar | volver
 *
 * Parámetro "particula" (cuando aplica):
 *   protones | neutrones | electrones
 */
@WebServlet("/escenario1")
public class EscenarioUnoControlador extends HttpServlet {

    private static final int ID_ESCENARIO = 1;
    private final EscenarioUnoServicio servicio = new EscenarioUnoServicio();

    // ─── HTTP ──────────────────────────────────────────────────
    @Override
    protected void doGet(HttpServletRequest req, HttpServletResponse resp)
            throws ServletException, IOException {
        dispatch(req, resp);
    }

    @Override
    protected void doPost(HttpServletRequest req, HttpServletResponse resp)
            throws ServletException, IOException {
        dispatch(req, resp);
    }

    // ─── Dispatcher ────────────────────────────────────────────
    private void dispatch(HttpServletRequest req, HttpServletResponse resp)
            throws ServletException, IOException {

        // Autenticación
        HttpSession sesion = req.getSession(false);
        if (sesion == null || sesion.getAttribute("usuario") == null) {
            resp.sendRedirect(req.getContextPath() + "/login.jsp");
            return;
        }

        Usuario   usuario   = (Usuario)   sesion.getAttribute("usuario");
        Escenario escenario = getEscenario(sesion);
        String    accion    = req.getParameter("accion");
        if (accion == null) accion = "cargar";

        switch (accion) {
            case "cargar":      acCargar(escenario, usuario, req);           break;
            case "incrementar": acParticula(escenario, req, true);           break;
            case "decrementar": acParticula(escenario, req, false);          break;
            case "reiniciar":   acReiniciar(escenario, sesion, req);         break;
            case "iniciarEval": acIniciarEval(escenario, usuario, req, sesion); break;
            case "comprobar":   acComprobar(escenario, usuario, req, sesion); break;
            case "continuar":   acContinuar(escenario, sesion, resp); return;
            case "finalizar":   acFinalizar(escenario, sesion, req);         break;
            case "volver":      acVolver(escenario, sesion, resp);   return;
        }

        // Publicar datos comunes para la vista
        publicarVista(escenario, req, sesion);
        sesion.setAttribute("escenario1", escenario);
        req.getRequestDispatcher("/escenario1/escenario1.jsp").forward(req, resp);
    }

    // ══════════════════════════════════════════════════════════
    // ACCIONES
    // ══════════════════════════════════════════════════════════

    /** Carga inicial del escenario. (CU-101) */
    private void acCargar(Escenario escenario, Usuario usuario,
                          HttpServletRequest req) {
        escenario.cargarEscenario();
        float progreso = servicio.cargarProgreso(usuario.getIdUsuario());
        escenario.getProgreso().setPorcentajeAprendizaje(progreso);
        req.setAttribute("mensajeMascota", escenario.guiaMascota());
        req.setAttribute("mostrarMascota", true);
    }

    /** Incrementa o decrementa una partícula. (RF-102) */
    private void acParticula(Escenario escenario, HttpServletRequest req,
                             boolean incrementar) {
        String particula = req.getParameter("particula");
        if (particula == null) return;
        ElementoBase eb = incrementar
            ? servicio.incrementar(escenario, particula)
            : servicio.decrementar(escenario, particula);
        req.setAttribute("elementoIdentificado", eb);
    }

    /** Reinicia el simulador. (RF-122 / CU-108) */
    private void acReiniciar(Escenario escenario, HttpSession sesion,
                             HttpServletRequest req) {
        escenario.reiniciarEscenario();
        sesion.removeAttribute("retoActual");
        sesion.removeAttribute("atomoObjetivo");
        req.setAttribute("mensajeMascota",
            "Simulador reiniciado. ¡Construye tu átomo desde cero!");
    }

    /** Inicia el módulo de evaluación. (RF-110 / CU-103) */
    private void acIniciarEval(Escenario escenario, Usuario usuario,
                               HttpServletRequest req, HttpSession sesion) {
        escenario.iniciarEvaluacion();
        generarYGuardarReto(escenario, usuario, req, sesion);
    }

    /** Comprueba el reto actual. (RF-115 / CU-105) */
    private void acComprobar(Escenario escenario, Usuario usuario,
                             HttpServletRequest req, HttpSession sesion) {
        Reto    retoActual   = (Reto)    sesion.getAttribute("retoActual");
        Elemento atomoObj    = (Elemento) sesion.getAttribute("atomoObjetivo");

        if (retoActual == null || atomoObj == null) {
            req.setAttribute("mensajeMascota",
                "⚠ No hay un reto activo. Presiona 'Iniciar Reto'.");
            return;
        }

        ResultadoComprobacion r = servicio.comprobar(
            escenario, retoActual, atomoObj, usuario);

        req.setAttribute("mensajeMascota",    r.mensajeMascota);
        req.setAttribute("resultadoCorrecto", r.correcto);
        req.setAttribute("intentoUsado",      r.intentoUsado);

        if (r.habilitarContinuar) {
            req.setAttribute("habilitarContinuar", true);
        }

        if (r.generarNuevoReto && !r.habilitarContinuar) {
            generarYGuardarReto(escenario, usuario, req, sesion);
        } else {
            sesion.setAttribute("retoActual", retoActual);
        }
    }

    /** Supera el escenario y avanza al siguiente. (RF-121 / CU-107) */
    private void acContinuar(Escenario escenario, HttpSession sesion,
                             HttpServletResponse resp) throws IOException {
        if (escenario.getProgreso().getPorcentajeAprendizaje() >= 80.0f) {
            escenario.superarEscenario();
            sesion.removeAttribute("escenario1");
            sesion.removeAttribute("retoActual");
            sesion.removeAttribute("atomoObjetivo");
            resp.sendRedirect("escenario2");
        }
    }

    /** Finaliza la evaluación sin salir del escenario. (RF-124 / CU-109) */
    private void acFinalizar(Escenario escenario, HttpSession sesion,
                             HttpServletRequest req) {
        escenario.setModoEvaluacion(false);
        sesion.removeAttribute("retoActual");
        sesion.removeAttribute("atomoObjetivo");
        req.setAttribute("mensajeMascota",
            "Evaluación finalizada. Porcentaje actual: "
            + escenario.getProgreso().mostrarPorcentajeAprendizaje());
    }

    /** Vuelve al menú principal. (RF-123 / CU-110) */
    private void acVolver(Escenario escenario, HttpSession sesion,
                          HttpServletResponse resp) throws IOException {
        escenario.salirEscenario();
        sesion.removeAttribute("escenario1");
        sesion.removeAttribute("retoActual");
        sesion.removeAttribute("atomoObjetivo");
        resp.sendRedirect("menu.jsp");
    }

    // ══════════════════════════════════════════════════════════
    // HELPERS
    // ══════════════════════════════════════════════════════════

    /** Genera un nuevo reto y lo registra en sesión. (RF-111 / CU-104) */
    private void generarYGuardarReto(Escenario escenario, Usuario usuario,
                                     HttpServletRequest req, HttpSession sesion) {
        ResultadoReto resultado = servicio.generarReto(usuario);
        if (resultado == null) {
            req.setAttribute("mensajeMascota",
                "⚠ Error generando el reto. Intenta de nuevo.");
            return;
        }
        escenario.setRetoActual(resultado.reto);
        sesion.setAttribute("retoActual",   resultado.reto);
        sesion.setAttribute("atomoObjetivo", resultado.atomoObjetivo);
        req.setAttribute("nuevoReto",        true);
        req.setAttribute("descripcionReto",  resultado.reto.mostrarReto());
        req.setAttribute("mensajeMascota",   escenario.guiaMascota());
    }

    /** Publica en request todos los datos que necesita el JSP. */
    private void publicarVista(Escenario escenario,
                               HttpServletRequest req, HttpSession sesion) {
        Elemento el = escenario.getElemento();
        req.setAttribute("protones",           el.getProtones());
        req.setAttribute("neutrones",          el.getNeutrones());
        req.setAttribute("electrones",         el.getElectrones());
        req.setAttribute("numeroMasico",       el.getNumeroMasico());
        req.setAttribute("cargaNeta",          el.getCargaNeta());
        req.setAttribute("estadoIonico",       el.getEstadoIonico());
        req.setAttribute("modoEvaluacion",     escenario.isModoEvaluacion());
        req.setAttribute("porcentaje",
            (int) escenario.getProgreso().getPorcentajeAprendizaje());
        req.setAttribute("elementoIdentificado",
            escenario.getElementoIdentificado());

        // Datos del reto activo para la vista
        Reto retoActual = (Reto) sesion.getAttribute("retoActual");
        if (retoActual != null) {
            req.setAttribute("retoActual",      retoActual);
            req.setAttribute("intentosUsados",  retoActual.getIntentos());
            req.setAttribute("intentosMax",     Reto.MAX_INTENTOS);
            req.setAttribute("temporizador",    retoActual.getTemporizador());
        }
    }

    /** Obtiene el Escenario de sesión o crea uno nuevo. */
    private Escenario getEscenario(HttpSession sesion) {
        Escenario e = (Escenario) sesion.getAttribute("escenario1");
        if (e == null) e = new Escenario(ID_ESCENARIO, "Arma tu átomo", 3);
        return e;
    }
}
