package controlador;
 
import dao.*;
import modelo.*;
 
import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.*;
import java.io.IOException;
import java.util.List;
 
/**
 * EscenarioSeisControlador
 * Servlet del Escenario 6 "Propiedades Periódicas de los Elementos".
 *
 * Modo simulación:
 *   - El usuario hace clic en la tabla periódica:
 *       1er clic → elemento A
 *       2do clic → elemento B
 *       3er clic → resetea y pone nuevo A
 *   - Para cada propiedad (radio atómico, energía de ionización,
 *     electronegatividad) el usuario elige A o B.
 *   - Al comprobar, ve si acertó cada comparación (sin evaluación formal).
 *
 * Modo evaluación:
 *   - El sistema elige 2 elementos al azar (A y B).
 *   - El usuario debe acertar las 3 comparaciones (radio, ionización,
 *     electronegatividad) en un mismo reto.
 *   - Solo si acierta las 3 se aprueba el reto.
 *   - Módulo de evaluación idéntico al Escenario 1.
 */
@WebServlet("/escenario6")
public class EscenarioSeisControlador extends HttpServlet {
 
    private static final int ID_ESCENARIO = 6;
 
    private final ElementoBaseDAO      elementoDAO = new ElementoBaseDAO();
    private final RetoDAO              retoDAO     = new RetoDAO();
    private final PuntajeRetoDAO       puntajeDAO  = new PuntajeRetoDAO();
    private final ProgresoEscenarioDAO progresoDAO = new ProgresoEscenarioDAO();
 
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
            case "cargar":
                accionCargar(escenario, usuario, req, sesion);
                break;
            case "seleccionarElemento":
                accionSeleccionarElemento(req, sesion);
                break;
            case "reiniciar":
                accionReiniciar(escenario, sesion);
                break;
            case "comprobarSimulacion":
                accionComprobarSimulacion(req, sesion);
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
 
        sesion.setAttribute("escenario6", escenario);
        publicarDatos(escenario, req, sesion);
        req.getRequestDispatcher("/escenario6/escenario6.jsp").forward(req, resp);
    }
 
    // ── CARGAR ───────────────────────────────────────────────────────────────
    private void accionCargar(Escenario escenario, Usuario usuario,
                               HttpServletRequest req, HttpSession sesion) {
        escenario.cargarEscenario();
        float pct = progresoDAO.obtenerPorcentaje(usuario.getIdUsuario(), ID_ESCENARIO);
        escenario.getProgreso().setPorcentajeAprendizaje(pct);
        req.setAttribute("mensajeMascota", escenario.guiaMascota());
        sesion.setAttribute("escenario6", escenario);
    }
 
    // ── SELECCIONAR ELEMENTO (toggle A → B → reset) ──────────────────────────
    private void accionSeleccionarElemento(HttpServletRequest req, HttpSession sesion) {
        String zStr = req.getParameter("numeroAtomico");
        if (zStr == null) return;
        int z;
        try { z = Integer.parseInt(zStr); } catch (NumberFormatException e) { return; }
 
        ElementoBase eb = elementoDAO.obtenerPorNumeroAtomico(z);
        if (eb == null) return;
 
        ElementoBase ebA = (ElementoBase) sesion.getAttribute("elemA6");
        ElementoBase ebB = (ElementoBase) sesion.getAttribute("elemB6");
 
        // Si clicó el mismo elemento que ya es A o B, lo deselecciona
        if (ebA != null && ebA.getNumeroAtomico() == z) {
            sesion.removeAttribute("elemA6");
            // Si había B, lo promovemos a A
            if (ebB != null) {
                sesion.setAttribute("elemA6", ebB);
                sesion.removeAttribute("elemB6");
            }
            return;
        }
        if (ebB != null && ebB.getNumeroAtomico() == z) {
            sesion.removeAttribute("elemB6");
            return;
        }
 
        // Asignar A primero, luego B
        if (ebA == null) {
            sesion.setAttribute("elemA6", eb);
        } else if (ebB == null) {
            sesion.setAttribute("elemB6", eb);
        } else {
            // Ya hay A y B: resetear y poner como nuevo A
            sesion.setAttribute("elemA6", eb);
            sesion.removeAttribute("elemB6");
        }
 
        // Limpiar respuestas anteriores al cambiar selección
        sesion.removeAttribute("respRadio6");
        sesion.removeAttribute("respIoniz6");
        sesion.removeAttribute("respElectr6");
        sesion.removeAttribute("resultSimul6");
    }
 
    // ── REINICIAR ────────────────────────────────────────────────────────────
    private void accionReiniciar(Escenario escenario, HttpSession sesion) {
        escenario.reiniciarEscenario();
        sesion.removeAttribute("elemA6");
        sesion.removeAttribute("elemB6");
        sesion.removeAttribute("respRadio6");
        sesion.removeAttribute("respIoniz6");
        sesion.removeAttribute("respElectr6");
        sesion.removeAttribute("resultSimul6");
        sesion.removeAttribute("retoActual6");
        sesion.removeAttribute("elemAEval6");
        sesion.removeAttribute("elemBEval6");
    }
 
    // ── COMPROBAR SIMULACIÓN (modo libre) ────────────────────────────────────
    private void accionComprobarSimulacion(HttpServletRequest req, HttpSession sesion) {
        ElementoBase ebA = (ElementoBase) sesion.getAttribute("elemA6");
        ElementoBase ebB = (ElementoBase) sesion.getAttribute("elemB6");
        if (ebA == null || ebB == null) {
            req.setAttribute("mensajeMascota", "Selecciona dos elementos de la tabla periódica para comparar.");
            return;
        }
 
        String rRadio  = req.getParameter("respRadio");
        String rIoniz  = req.getParameter("respIoniz");
        String rElectr = req.getParameter("respElectr");
 
        sesion.setAttribute("respRadio6",  rRadio);
        sesion.setAttribute("respIoniz6",  rIoniz);
        sesion.setAttribute("respElectr6", rElectr);
 
        // Evaluar cada comparación
        boolean okRadio  = evaluarPropiedad(ebA, ebB, "radio",  rRadio);
        boolean okIoniz  = evaluarPropiedad(ebA, ebB, "ioniz",  rIoniz);
        boolean okElectr = evaluarPropiedad(ebA, ebB, "electr", rElectr);
 
        sesion.setAttribute("resultSimul6",
            (okRadio ? "1" : "0") + (okIoniz ? "1" : "0") + (okElectr ? "1" : "0"));
 
        // Mensaje pedagógico
        StringBuilder sb = new StringBuilder();
        sb.append(okRadio  ? "✅ Radio atómico: correcto.\n"    : "❌ Radio atómico: incorrecto.\n");
        sb.append(okIoniz  ? "✅ Energía de ionización: correcto.\n" : "❌ Energía de ionización: incorrecto.\n");
        sb.append(okElectr ? "✅ Electronegatividad: correcto." : "❌ Electronegatividad: incorrecto.");
 
        req.setAttribute("mensajeMascota", sb.toString());
        req.setAttribute("resultadoSimulacion", true);
    }
 
    // ── INICIAR EVALUACIÓN ───────────────────────────────────────────────────
    private void accionIniciarEvaluacion(Escenario escenario, Usuario usuario,
                                          HttpServletRequest req, HttpSession sesion) {
        escenario.iniciarEvaluacion();
        generarNuevoReto(escenario, usuario, req, sesion);
    }
 
    // ── COMPROBAR (evaluación) ───────────────────────────────────────────────
    private void accionComprobar(Escenario escenario, Usuario usuario,
                                  HttpServletRequest req, HttpSession sesion) {
 
        Reto         retoActual = (Reto)         sesion.getAttribute("retoActual6");
        ElementoBase ebA        = (ElementoBase) sesion.getAttribute("elemAEval6");
        ElementoBase ebB        = (ElementoBase) sesion.getAttribute("elemBEval6");
 
        if (retoActual == null || ebA == null || ebB == null) {
            req.setAttribute("mensajeMascota", "No hay un reto activo. Presiona 'Iniciar Evaluación'.");
            return;
        }
 
        String rRadio  = req.getParameter("respRadio");
        String rIoniz  = req.getParameter("respIoniz");
        String rElectr = req.getParameter("respElectr");
 
        sesion.setAttribute("respRadio6",  rRadio);
        sesion.setAttribute("respIoniz6",  rIoniz);
        sesion.setAttribute("respElectr6", rElectr);
 
        boolean okRadio  = evaluarPropiedad(ebA, ebB, "radio",  rRadio);
        boolean okIoniz  = evaluarPropiedad(ebA, ebB, "ioniz",  rIoniz);
        boolean okElectr = evaluarPropiedad(ebA, ebB, "electr", rElectr);
 
        // Solo correcto si acierta las 3
        boolean correcto = okRadio && okIoniz && okElectr;
 
        retoActual.registrarIntento();
        int intento = retoActual.getIntentos();
 
        req.setAttribute("resultadoCorrecto", correcto);
        req.setAttribute("intentosUsados",    intento);
        sesion.setAttribute("resultSimul6",
            (okRadio?"1":"0") + (okIoniz?"1":"0") + (okElectr?"1":"0"));
 
        if (correcto) {
            retoActual.setCompletado(true);
            PuntajeReto pr = new PuntajeReto(retoActual, intento, true);
            escenario.getProgreso().agregarResultado(pr);
 
            retoDAO.actualizar(retoActual);
            puntajeDAO.insertar(retoActual.getIdReto(), intento, pr.getPuntaje(), true);
            float nuevoPct = puntajeDAO.calcularPorcentajeAprendizaje(
                    usuario.getIdUsuario(), ID_ESCENARIO);
            progresoDAO.guardar(usuario.getIdUsuario(), ID_ESCENARIO, nuevoPct);
            escenario.getProgreso().setPorcentajeAprendizaje(nuevoPct);
 
            req.setAttribute("mensajeMascota",
                "¡Excelente! Acertaste las 3 comparaciones en el intento " + intento + ".\n"
                + construirExplicacion(ebA, ebB));
 
            if (nuevoPct >= 80.0f) {
                req.setAttribute("habilitarContinuar", true);
            } else {
                generarNuevoReto(escenario, usuario, req, sesion);
            }
 
        } else {
            puntajeDAO.insertar(retoActual.getIdReto(), intento, 0.0f, false);
 
            if (retoActual.agotadoIntentos()) {
                PuntajeReto prF = new PuntajeReto(retoActual, 3, false);
                escenario.getProgreso().agregarResultado(prF);
                float nuevoPct = puntajeDAO.calcularPorcentajeAprendizaje(
                        usuario.getIdUsuario(), ID_ESCENARIO);
                progresoDAO.guardar(usuario.getIdUsuario(), ID_ESCENARIO, nuevoPct);
                escenario.getProgreso().setPorcentajeAprendizaje(nuevoPct);
                retoDAO.actualizar(retoActual);
 
                req.setAttribute("mensajeMascota",
                    "Agotaste los 3 intentos. ¡No te rindas!\n"
                    + construirExplicacion(ebA, ebB)
                    + "\nHe generado un nuevo reto.");
                generarNuevoReto(escenario, usuario, req, sesion);
 
            } else {
                int restantes = Reto.MAX_INTENTOS - intento;
                StringBuilder sb = new StringBuilder("No acertaste todas las comparaciones.\n");
                sb.append(okRadio  ? "✅ Radio atómico: correcto.\n"    : "❌ Radio atómico: incorrecto.\n");
                sb.append(okIoniz  ? "✅ Energía de ionización: correcto.\n" : "❌ Energía de ionización: incorrecto.\n");
                sb.append(okElectr ? "✅ Electronegatividad: correcto."  : "❌ Electronegatividad: incorrecto.");
                sb.append("\nTe quedan ").append(restantes).append(" intento(s).");
                req.setAttribute("mensajeMascota", sb.toString());
            }
        }
 
        sesion.setAttribute("retoActual6", retoActual);
 
        Reto ra = (Reto) sesion.getAttribute("retoActual6");
        if (ra != null) {
            req.setAttribute("retoActual",    ra);
            req.setAttribute("temporizador",  ra.getTemporizador());
            req.setAttribute("intentosUsados", ra.getIntentos());
            if (req.getAttribute("descripcionReto") == null)
                req.setAttribute("descripcionReto", ra.mostrarReto());
        }
    }
 
    // ── CONTINUAR ────────────────────────────────────────────────────────────
    private void accionContinuar(Escenario escenario, HttpSession sesion,
                                  HttpServletResponse resp) throws IOException {
        if (escenario.getProgreso().getPorcentajeAprendizaje() >= 80.0f) {
            escenario.superarEscenario();
            sesion.removeAttribute("escenario6");
            resp.sendRedirect("login.jsp"); // ajusta si hay escenario7
        }
    }
 
    // ── FINALIZAR ────────────────────────────────────────────────────────────
    private void accionFinalizar(Escenario escenario, HttpSession sesion,
                                  HttpServletRequest req) {
        escenario.setModoEvaluacion(false);
        sesion.removeAttribute("retoActual6");
        sesion.removeAttribute("elemAEval6");
        sesion.removeAttribute("elemBEval6");
        sesion.removeAttribute("respRadio6");
        sesion.removeAttribute("respIoniz6");
        sesion.removeAttribute("respElectr6");
        sesion.removeAttribute("resultSimul6");
        float pct = escenario.getProgreso().getPorcentajeAprendizaje();
        req.setAttribute("mensajeMascota",
            "Evaluación finalizada. Tu porcentaje: " + Math.round(pct) + "%. "
            + (pct >= 80 ? "¡Superaste el escenario!" : "Sigue practicando para alcanzar el 80%."));
    }
 
    // ── VOLVER ───────────────────────────────────────────────────────────────
    private void accionVolver(Escenario escenario, HttpSession sesion,
                               HttpServletResponse resp) throws IOException {
        escenario.salirEscenario();
        sesion.removeAttribute("escenario6");
        resp.sendRedirect("login.jsp");
    }
 
    // ════════════════════════════════════════════════════════════════════════
    // HELPERS
    // ════════════════════════════════════════════════════════════════════════
 
    /**
     * Genera un reto: dos elementos aleatorios distintos como A y B.
     */
    private void generarNuevoReto(Escenario escenario, Usuario usuario,
                                   HttpServletRequest req, HttpSession sesion) {
        ElementoBase ebA = null, ebB = null;
        List<ElementoBase> todos = elementoDAO.obtenerTodos();
        if (todos.size() < 2) return;
 
        // Dos elementos aleatorios distintos
        java.util.Collections.shuffle(todos);
        ebA = todos.get(0);
        for (ElementoBase e : todos) {
            if (e.getNumeroAtomico() != ebA.getNumeroAtomico()) { ebB = e; break; }
        }
        if (ebB == null) return;
 
        Reto reto = new Reto();
        reto.setIdUsuario(usuario.getIdUsuario());
        reto.setIdEscenario(ID_ESCENARIO);
        reto.generarReto(ebA,
            ebA.getNumeroAtomico(), 0, ebA.getNumeroAtomico());
        reto.setDescripcion(
            "Compara las propiedades periódicas de:\n"
            + "A = " + ebA.getNombre() + " (Z=" + ebA.getNumeroAtomico() + ")\n"
            + "B = " + ebB.getNombre() + " (Z=" + ebB.getNumeroAtomico() + ")\n"
            + "Indica cuál tiene mayor: radio atómico, energía de ionización y electronegatividad.");
 
        int idReto = retoDAO.insertar(reto);
        reto.setIdReto(idReto);
 
        escenario.setRetoActual(reto);
        sesion.setAttribute("retoActual6",  reto);
        sesion.setAttribute("elemAEval6",   ebA);
        sesion.setAttribute("elemBEval6",   ebB);
        // Limpiar respuestas anteriores
        sesion.removeAttribute("respRadio6");
        sesion.removeAttribute("respIoniz6");
        sesion.removeAttribute("respElectr6");
        sesion.removeAttribute("resultSimul6");
 
        req.setAttribute("nuevoReto",       true);
        req.setAttribute("retoActual",      reto);
        req.setAttribute("descripcionReto", reto.getDescripcion());
        req.setAttribute("temporizador",    reto.getTemporizador());
        req.setAttribute("intentosUsados",  0);
    }
 
    /**
     * Evalúa si la respuesta del usuario es correcta para una propiedad.
     * resp: "A" o "B"
     * propiedad: "radio" | "ioniz" | "electr"
     */
    private boolean evaluarPropiedad(ElementoBase ebA, ElementoBase ebB,
                                      String propiedad, String resp) {
        if (resp == null || resp.isEmpty()) return false;
        double valA, valB;
        switch (propiedad) {
            case "radio":
                valA = ebA.getRadioAtomico();
                valB = ebB.getRadioAtomico();
                break;
            case "ioniz":
                valA = ebA.getEnergiaIonizacion();
                valB = ebB.getEnergiaIonizacion();
                break;
            case "electr":
                valA = ebA.getElectronegatividad();
                valB = ebB.getElectronegatividad();
                break;
            default: return false;
        }
        // Si son iguales, cualquier respuesta es válida (empate)
        if (valA == valB) return true;
        String mayor = valA > valB ? "A" : "B";
        return mayor.equals(resp);
    }
 
    /**
     * Construye explicación pedagógica con los valores reales.
     */
    private String construirExplicacion(ElementoBase ebA, ElementoBase ebB) {
        String mayorRadio  = ebA.getRadioAtomico()       >= ebB.getRadioAtomico()       ? ebA.getNombre() : ebB.getNombre();
        String mayorIoniz  = ebA.getEnergiaIonizacion()  >= ebB.getEnergiaIonizacion()  ? ebA.getNombre() : ebB.getNombre();
        String mayorElectr = ebA.getElectronegatividad() >= ebB.getElectronegatividad() ? ebA.getNombre() : ebB.getNombre();
 
        return "📏 Mayor radio atómico: " + mayorRadio
             + "\n⚡ Mayor energía de ionización: " + mayorIoniz
             + "\n🔗 Mayor electronegatividad: " + mayorElectr;
    }
 
    private void publicarDatos(Escenario escenario, HttpServletRequest req,
                                HttpSession sesion) {
        // Porcentaje
        int pct = Math.round(escenario.getProgreso().getPorcentajeAprendizaje());
        req.setAttribute("porcentaje",     pct);
        req.setAttribute("modoEvaluacion", escenario.isModoEvaluacion());
        req.setAttribute("habilitarContinuar",
            escenario.getProgreso().getPorcentajeAprendizaje() >= 80.0f
            && escenario.isModoEvaluacion());
 
        // Elementos de la tabla periódica
        req.setAttribute("elementosPeriodica", elementoDAO.obtenerTodos());
 
        // Elementos seleccionados (modo libre)
        req.setAttribute("elemA", sesion.getAttribute("elemA6"));
        req.setAttribute("elemB", sesion.getAttribute("elemB6"));
 
        // Respuestas del usuario
        req.setAttribute("respRadio",  sesion.getAttribute("respRadio6"));
        req.setAttribute("respIoniz",  sesion.getAttribute("respIoniz6"));
        req.setAttribute("respElectr", sesion.getAttribute("respElectr6"));
 
        // Resultado de simulación "okRadio okIoniz okElectr"
        req.setAttribute("resultSimul", sesion.getAttribute("resultSimul6"));
 
        // Elementos de evaluación
        boolean modoEval = escenario.isModoEvaluacion();
        if (modoEval) {
            ElementoBase ebAEval = (ElementoBase) sesion.getAttribute("elemAEval6");
            ElementoBase ebBEval = (ElementoBase) sesion.getAttribute("elemBEval6");
            req.setAttribute("elemA", ebAEval);
            req.setAttribute("elemB", ebBEval);
        }
 
        // HUD del reto
        Reto ra = (Reto) sesion.getAttribute("retoActual6");
        if (ra != null && req.getAttribute("retoActual") == null) {
            req.setAttribute("retoActual",    ra);
            req.setAttribute("temporizador",  ra.getTemporizador());
            req.setAttribute("intentosUsados", ra.getIntentos());
            if (req.getAttribute("descripcionReto") == null)
                req.setAttribute("descripcionReto", ra.getDescripcion());
        }
 
        String retoId = (ra != null) ? String.valueOf(ra.getIdReto()) : "";
        req.setAttribute("retoId", retoId);
    }
 
    private Escenario obtenerOCrearEscenario(HttpSession sesion) {
        Escenario esc = (Escenario) sesion.getAttribute("escenario6");
        if (esc == null)
            esc = new Escenario(ID_ESCENARIO, "Propiedades Periódicas de los Elementos", 3);
        return esc;
    }
}