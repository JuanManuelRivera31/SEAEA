package controlador;

import dao.*;
import modelo.*;

import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.*;
import java.io.IOException;
import java.util.List;

/**
 * EscenarioCuatroControlador
 * Servlet del Escenario 4 "Configura tu Isótopo".
 *
 * CORRECCIÓN: ElementoBase no tiene id_elemento ni obtenerPorId().
 * Se usa getNumeroAtomico() como identificador único del elemento.
 * ElementoBaseDAO no tiene obtenerPorId() → se usa obtenerPorNumeroAtomico().
 *
 * Flujo libre:
 *   1. Usuario selecciona elemento de la tabla periódica (primeros 18).
 *   2. Protones y electrones se fijan al valor Z del elemento.
 *   3. Usuario solo manipula NEUTRONES para explorar isótopos.
 *   4. Muestra isótopo actual (nombre, estabilidad, abundancia, masa).
 *
 * Flujo evaluación:
 *   1. Sistema elige elemento aleatorio (Z ≤ 18) e isótopo aleatorio.
 *   2. Reto: usuario debe seleccionar ese elemento y ajustar neutrones exactos.
 *   3. Módulo de evaluación idéntico al Escenario 1.
 */
@WebServlet("/escenario4")
public class EscenarioCuatroControlador extends HttpServlet {

    private static final int ID_ESCENARIO = 4;
    private static final int MAX_Z        = 18; // primeros 3 períodos

    private final ElementoBaseDAO      elementoDAO = new ElementoBaseDAO();
    private final IsotopoDAO           isotopoDAO  = new IsotopoDAO();
    private final RetoDAO              retoDAO     = new RetoDAO();
    private final PuntajeRetoDAO       puntajeDAO  = new PuntajeRetoDAO();
    private final ProgresoEscenarioDAO progresoDAO = new ProgresoEscenarioDAO();

    // ════════════════════════════════════════════════════════════════════════

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
            case "cargar":
                accionCargar(escenario, usuario, req, sesion);
                break;
            case "seleccionarElemento":
                accionSeleccionarElemento(escenario, req, sesion);
                break;
            case "incrementarNeutrones":
                accionModificarNeutrones(escenario, req, sesion, +1);
                break;
            case "decrementarNeutrones":
                accionModificarNeutrones(escenario, req, sesion, -1);
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

        sesion.setAttribute("escenario4", escenario);
        publicarDatos(escenario, req, sesion);
        req.getRequestDispatcher("/escenario4/escenario4.jsp").forward(req, resp);
    }

    // ── CARGAR ───────────────────────────────────────────────────────────────
    private void accionCargar(Escenario escenario, Usuario usuario,
                               HttpServletRequest req, HttpSession sesion) {
        escenario.cargarEscenario();
        float pct = progresoDAO.obtenerPorcentaje(usuario.getIdUsuario(), ID_ESCENARIO);
        escenario.getProgreso().setPorcentajeAprendizaje(pct);
        req.setAttribute("mensajeMascota", escenario.guiaMascota());
        cargarElementosPeriodica(req);
        sesion.setAttribute("escenario4", escenario);
    }

    // ── SELECCIONAR ELEMENTO ─────────────────────────────────────────────────
    private void accionSeleccionarElemento(Escenario escenario,
                                            HttpServletRequest req,
                                            HttpSession sesion) {
        String zStr = req.getParameter("numeroAtomico"); // ← recibe Z, no id
        if (zStr == null) { cargarElementosPeriodica(req); return; }

        int z;
        try { z = Integer.parseInt(zStr); } catch (NumberFormatException e) {
            cargarElementosPeriodica(req); return;
        }
        if (z < 1 || z > MAX_Z) { cargarElementosPeriodica(req); return; }

        // Buscar elemento por número atómico (única clave disponible)
        ElementoBase eb = elementoDAO.obtenerPorNumeroAtomico(z);
        if (eb == null) { cargarElementosPeriodica(req); return; }

        // Fijar partículas: protones=Z, electrones=Z, neutrones=0
        escenario.getElemento().setProtones(z);
        escenario.getElemento().setElectrones(z);
        escenario.getElemento().setNeutrones(0);
        escenario.actualizarCartaPeriodicaElemento(eb);

        sesion.setAttribute("elementoSeleccionado4", eb);
        sesion.setAttribute("neutrones4",            0);
        sesion.setAttribute("zSeleccionado4",        z); // guardar Z como clave

        cargarElementosPeriodica(req);
        actualizarIsotopoActual(eb, 0, req, sesion);
    }

    // ── MODIFICAR NEUTRONES ──────────────────────────────────────────────────
    private void accionModificarNeutrones(Escenario escenario,
                                           HttpServletRequest req,
                                           HttpSession sesion, int delta) {
        ElementoBase eb = (ElementoBase) sesion.getAttribute("elementoSeleccionado4");
        if (eb == null) {
            req.setAttribute("mensajeMascota", "Primero selecciona un elemento de la tabla periódica.");
            cargarElementosPeriodica(req);
            return;
        }

        Integer nActual = (Integer) sesion.getAttribute("neutrones4");
        if (nActual == null) nActual = 0;
        int nuevo = Math.max(0, Math.min(30, nActual + delta));

        escenario.getElemento().setNeutrones(nuevo);
        sesion.setAttribute("neutrones4", nuevo);

        cargarElementosPeriodica(req);
        actualizarIsotopoActual(eb, nuevo, req, sesion);
    }

    // ── REINICIAR ────────────────────────────────────────────────────────────
    private void accionReiniciar(Escenario escenario, HttpSession sesion) {
        escenario.reiniciarEscenario();
        sesion.removeAttribute("elementoSeleccionado4");
        sesion.removeAttribute("neutrones4");
        sesion.removeAttribute("zSeleccionado4");
        sesion.removeAttribute("retoActual4");
        sesion.removeAttribute("isotopoObjetivo4");
        sesion.removeAttribute("elementoReto4");
        sesion.removeAttribute("zReto4");
    }

    // ── INICIAR EVALUACIÓN ───────────────────────────────────────────────────
    private void accionIniciarEvaluacion(Escenario escenario, Usuario usuario,
                                          HttpServletRequest req, HttpSession sesion) {
        escenario.iniciarEvaluacion();
        generarNuevoReto(escenario, usuario, req, sesion);
        cargarElementosPeriodica(req);
    }

    // ── COMPROBAR ────────────────────────────────────────────────────────────
    private void accionComprobar(Escenario escenario, Usuario usuario,
                                  HttpServletRequest req, HttpSession sesion) {

        Reto         retoActual = (Reto)         sesion.getAttribute("retoActual4");
        Isotopo      isotopoObj = (Isotopo)      sesion.getAttribute("isotopoObjetivo4");
        ElementoBase ebActual   = (ElementoBase) sesion.getAttribute("elementoSeleccionado4");
        Integer      zReto      = (Integer)      sesion.getAttribute("zReto4");

        if (retoActual == null || isotopoObj == null) {
            req.setAttribute("mensajeMascota", "No hay un reto activo. Presiona 'Iniciar Evaluación'.");
            cargarElementosPeriodica(req);
            return;
        }

        Integer nActual = (Integer) sesion.getAttribute("neutrones4");
        if (nActual == null) nActual = 0;

        // Comprobación: mismo elemento (por Z) Y neutrones correctos
        int zActual = (ebActual != null) ? ebActual.getNumeroAtomico() : -1;
        boolean elementoCorrecto   = (zReto != null) && (zActual == zReto);
        boolean neutronesCorrectos = (nActual == isotopoObj.getNumeroNeutrones());
        boolean correcto           = elementoCorrecto && neutronesCorrectos;

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
            float nuevoPct = puntajeDAO.calcularPorcentajeAprendizaje(
                    usuario.getIdUsuario(), ID_ESCENARIO);
            progresoDAO.guardar(usuario.getIdUsuario(), ID_ESCENARIO, nuevoPct);
            escenario.getProgreso().setPorcentajeAprendizaje(nuevoPct);

            String nomIso = isotopoObj.getNombreDisplay();
            String abund  = isotopoObj.getAbundancia() > 0
                            ? String.format("%.4f%%", isotopoObj.getAbundancia()) : "trazas";
            req.setAttribute("mensajeMascota",
                "¡Excelente! Configuraste correctamente el isótopo "
                + nomIso + " en el intento " + intento + ".\n"
                + "Neutrones: " + isotopoObj.getNumeroNeutrones()
                + " · Número másico: " + isotopoObj.getNumeroMasico()
                + "\nAbundancia natural: " + abund
                + "\nRecuerda: A = Z + N");

            if (nuevoPct >= 80.0f) {
                req.setAttribute("habilitarContinuar", true);
            } else {
                generarNuevoReto(escenario, usuario, req, sesion);
            }

        } else {
            // ── FALLO ─────────────────────────────────────────────────────
            puntajeDAO.insertar(retoActual.getIdReto(), intento, 0.0f, false);

            if (retoActual.agotadoIntentos()) {
                // ── AGOTADO ────────────────────────────────────────────────
                PuntajeReto prF = new PuntajeReto(retoActual, 3, false);
                escenario.getProgreso().agregarResultado(prF);
                float nuevoPct = puntajeDAO.calcularPorcentajeAprendizaje(
                        usuario.getIdUsuario(), ID_ESCENARIO);
                progresoDAO.guardar(usuario.getIdUsuario(), ID_ESCENARIO, nuevoPct);
                escenario.getProgreso().setPorcentajeAprendizaje(nuevoPct);
                retoDAO.actualizar(retoActual);

                req.setAttribute("mensajeMascota",
                    "Agotaste los 3 intentos. ¡No te rindas!\n"
                    + "He generado un nuevo reto para continuar aprendiendo.");
                generarNuevoReto(escenario, usuario, req, sesion);

            } else {
                // ── PARCIAL ────────────────────────────────────────────────
                int restantes = Reto.MAX_INTENTOS - intento;
                String pista;
                if (!elementoCorrecto) {
                    ElementoBase ebReto = (ElementoBase) sesion.getAttribute("elementoReto4");
                    String nomEsperado  = (ebReto != null) ? ebReto.getNombre() : "el elemento del reto";
                    pista = "El elemento seleccionado no es correcto. Selecciona: " + nomEsperado + ".";
                } else {
                    int diff = nActual - isotopoObj.getNumeroNeutrones();
                    pista = diff > 0
                          ? "Tienes demasiados neutrones. Quita " + diff + "."
                          : "Faltan " + Math.abs(diff) + " neutrones. Agrega más.";
                }
                req.setAttribute("mensajeMascota",
                    "No es correcto aún. " + pista
                    + "\nTe quedan " + restantes + " intento(s).");
            }
        }

        sesion.setAttribute("retoActual4", retoActual);

        // HUD del reto
        Reto ra = (Reto) sesion.getAttribute("retoActual4");
        if (ra != null) {
            req.setAttribute("retoActual",    ra);
            req.setAttribute("temporizador",  ra.getTemporizador());
            req.setAttribute("intentosUsados", ra.getIntentos());
            if (req.getAttribute("descripcionReto") == null)
                req.setAttribute("descripcionReto", ra.mostrarReto());
        }

        if (ebActual != null) {
            actualizarIsotopoActual(ebActual, nActual, req, sesion);
        }
        cargarElementosPeriodica(req);
    }

    // ── CONTINUAR ────────────────────────────────────────────────────────────
    private void accionContinuar(Escenario escenario, HttpSession sesion,
                                  HttpServletResponse resp) throws IOException {
        if (escenario.getProgreso().getPorcentajeAprendizaje() >= 80.0f) {
            escenario.superarEscenario();
            sesion.removeAttribute("escenario4");
            resp.sendRedirect("escenario5");
        }
    }

    // ── FINALIZAR ────────────────────────────────────────────────────────────
    private void accionFinalizar(Escenario escenario, HttpSession sesion,
                                  HttpServletRequest req) {
        escenario.setModoEvaluacion(false);
        sesion.removeAttribute("retoActual4");
        sesion.removeAttribute("isotopoObjetivo4");
        sesion.removeAttribute("elementoReto4");
        sesion.removeAttribute("zReto4");
        float pct = escenario.getProgreso().getPorcentajeAprendizaje();
        req.setAttribute("mensajeMascota",
            "Evaluación finalizada. Tu porcentaje: " + Math.round(pct) + "%. "
            + (pct >= 80 ? "¡Superaste el escenario!" : "Sigue practicando para alcanzar el 80%."));
        cargarElementosPeriodica(req);
    }

    // ── VOLVER ───────────────────────────────────────────────────────────────
    private void accionVolver(Escenario escenario, HttpSession sesion,
                               HttpServletResponse resp) throws IOException {
        escenario.salirEscenario();
        sesion.removeAttribute("escenario4");
        resp.sendRedirect("login.jsp");
    }

    // ════════════════════════════════════════════════════════════════════════
    // HELPERS
    // ════════════════════════════════════════════════════════════════════════

    /**
     * Genera un reto: elemento aleatorio (Z ≤ 18) → isótopo aleatorio.
     * Usa obtenerAleatorio() del DAO filtrado por Z ≤ 18.
     */
    private void generarNuevoReto(Escenario escenario, Usuario usuario,
                                   HttpServletRequest req, HttpSession sesion) {
        // Obtener elemento aleatorio con Z ≤ MAX_Z
        ElementoBase eb = null;
        for (int intentos = 0; intentos < 20; intentos++) {
            ElementoBase candidato = elementoDAO.obtenerAleatorio();
            if (candidato != null && candidato.getNumeroAtomico() <= MAX_Z) {
                eb = candidato;
                break;
            }
        }
        if (eb == null) return;

        int zEb = eb.getNumeroAtomico();

        // Isótopo aleatorio usando Z
        Isotopo isoObj = isotopoDAO.obtenerAleatorio(zEb);
        if (isoObj == null) return;

        Elemento atomoObj = new Elemento(
            zEb,
            isoObj.getNumeroNeutrones(),
            zEb
        );

        Reto reto = new Reto();
        reto.setIdUsuario(usuario.getIdUsuario());
        reto.setIdEscenario(ID_ESCENARIO);
        reto.generarReto(eb, atomoObj.getProtones(), atomoObj.getNeutrones(), atomoObj.getElectrones());
        reto.setDescripcion("Configura el isótopo " + isoObj.getNombreDisplay()
            + ". Selecciona " + eb.getNombre()
            + " (Z=" + zEb + ") y ajusta los neutrones a " + isoObj.getNumeroNeutrones() + ".");

        int idReto = retoDAO.insertar(reto);
        reto.setIdReto(idReto);

        escenario.setRetoActual(reto);
        sesion.setAttribute("retoActual4",      reto);
        sesion.setAttribute("isotopoObjetivo4", isoObj);
        sesion.setAttribute("elementoReto4",    eb);
        sesion.setAttribute("zReto4",           zEb); // ← guardamos Z como referencia

        req.setAttribute("nuevoReto",       true);
        req.setAttribute("retoActual",      reto);
        req.setAttribute("descripcionReto", reto.getDescripcion());
        req.setAttribute("temporizador",    reto.getTemporizador());
        req.setAttribute("intentosUsados",  0);

        publicarIsotopoObjetivo(isoObj, eb, req);
    }

    /** Consulta el isótopo que corresponde a (Z del elemento, neutrones actuales). */
    private void actualizarIsotopoActual(ElementoBase eb, int neutrones,
                                          HttpServletRequest req, HttpSession sesion) {
        int z = eb.getNumeroAtomico();
        Isotopo iso = isotopoDAO.obtenerPorNeutrones(z, neutrones);

        int    a          = z + neutrones;
        String nombreIso  = eb.getNombre() + "-" + a;
        String estab      = (iso != null) ? (iso.isEstable() ? "ESTABLE" : "INESTABLE") : "INESTABLE";
        double abundancia = (iso != null) ? iso.getAbundancia() : 0.0;
        double masaIso    = (iso != null) ? iso.getMasaIsotopica() : (double) eb.getMasaAtomica();

        req.setAttribute("isotopoActual",       iso);
        req.setAttribute("nombreIsotopoActual", nombreIso);
        req.setAttribute("estabilidadActual",   estab);
        req.setAttribute("abundanciaActual",    abundancia);
        req.setAttribute("masaIsotopicaActual", masaIso);
        req.setAttribute("numeroMasicoActual",  a);
        req.setAttribute("neutronesActuales",   neutrones);
        sesion.setAttribute("neutrones4", neutrones);
    }

    private void publicarIsotopoObjetivo(Isotopo iso, ElementoBase eb,
                                          HttpServletRequest req) {
        req.setAttribute("isotopoObjetivo",      iso);
        req.setAttribute("ebReto",               eb);
        req.setAttribute("nomIsotopoObjetivo",   iso.getNombreDisplay());
        req.setAttribute("neutronesObjetivo",    iso.getNumeroNeutrones());
        req.setAttribute("numeroMasicoObjetivo", iso.getNumeroMasico());
    }

    /** Carga los primeros MAX_Z elementos para la tabla periódica. */
    private void cargarElementosPeriodica(HttpServletRequest req) {
        List<ElementoBase> todos    = elementoDAO.obtenerTodos();
        List<ElementoBase> primeros = new java.util.ArrayList<>();
        for (ElementoBase e : todos) {
            if (e.getNumeroAtomico() <= MAX_Z) primeros.add(e);
        }
        req.setAttribute("elementosPeriodica", primeros);
    }

    private void publicarDatos(Escenario escenario, HttpServletRequest req,
                                HttpSession sesion) {
        Elemento el = escenario.getElemento();
        req.setAttribute("protones",       el.getProtones());
        req.setAttribute("neutrones",      el.getNeutrones());
        req.setAttribute("electrones",     el.getElectrones());
        req.setAttribute("numeroMasico",   el.getNumeroMasico());
        req.setAttribute("cargaNeta",      el.getCargaNeta());
        req.setAttribute("modoEvaluacion", escenario.isModoEvaluacion());
        req.setAttribute("habilitarContinuar",
            escenario.getProgreso().getPorcentajeAprendizaje() >= 80.0f
            && escenario.isModoEvaluacion());
        req.setAttribute("elementoIdentificado", escenario.getElementoIdentificado());

        int pct = Math.round(escenario.getProgreso().getPorcentajeAprendizaje());
        req.setAttribute("porcentaje", pct);

        // Elemento seleccionado
        ElementoBase ebSel = (ElementoBase) sesion.getAttribute("elementoSeleccionado4");
        req.setAttribute("elementoSeleccionado", ebSel);

        // Z seleccionado (para marcar celda activa en tabla)
        Integer zSel = (Integer) sesion.getAttribute("zSeleccionado4");
        req.setAttribute("zSeleccionado", zSel != null ? zSel : 0);

        // Neutrones actuales
        Integer nAct = (Integer) sesion.getAttribute("neutrones4");
        if (nAct == null) nAct = 0;
        req.setAttribute("neutronesActuales", nAct);

        // Info isótopo actual
        if (ebSel != null && req.getAttribute("nombreIsotopoActual") == null) {
            actualizarIsotopoActual(ebSel, nAct, req, sesion);
        }

        // HUD del reto activo
        Reto ra = (Reto) sesion.getAttribute("retoActual4");
        if (ra != null && req.getAttribute("retoActual") == null) {
            req.setAttribute("retoActual",    ra);
            req.setAttribute("temporizador",  ra.getTemporizador());
            req.setAttribute("intentosUsados", ra.getIntentos());
            if (req.getAttribute("descripcionReto") == null)
                req.setAttribute("descripcionReto", ra.getDescripcion());
        }

        // Isótopo objetivo
        Isotopo  isoObj = (Isotopo)      sesion.getAttribute("isotopoObjetivo4");
        ElementoBase ebReto = (ElementoBase) sesion.getAttribute("elementoReto4");
        if (isoObj != null && req.getAttribute("isotopoObjetivo") == null) {
            publicarIsotopoObjetivo(isoObj, ebReto, req);
        }

        String retoId = (ra != null) ? String.valueOf(ra.getIdReto()) : "";
        req.setAttribute("retoId", retoId);
    }

    private Escenario obtenerOCrearEscenario(HttpSession sesion) {
        Escenario esc = (Escenario) sesion.getAttribute("escenario4");
        if (esc == null) esc = new Escenario(ID_ESCENARIO, "Configura tu Isótopo", 3);
        return esc;
    }
}
