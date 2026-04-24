package controlador;
 
import dao.*;
import modelo.*;
 
import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.*;
import java.io.IOException;
import java.util.*;
 
/**
 * EscenarioCincoControlador
 * Servlet del Escenario 5 "Configuración Electrónica".
 *
 * Solo trabaja con elementos de bloque s y p (Z ≤ 36 aproximadamente,
 * pero filtrando solo bloque s y p de la BD).
 *
 * Subniveles disponibles (bloque s y p, orden Aufbau):
 *   1s(2) → 2s(2) → 2p(6) → 3s(2) → 3p(6) →
 *   4s(2) → 3d(10) → 4p(6) → 5s(2) → 4d(10) → 5p(6) → ...
 * Para s y p solamente mostramos:
 *   1s, 2s, 2p, 3s, 3p, 4s, 4p, 5s, 5p, 6s, 6p, 7s, 7p
 *
 * Interacción de celdas:
 *   1er clic → ↑   2do clic → ↓   3er clic → vacía
 *
 * Comprobación:
 *   Se verifica que el número de electrones colocados en CADA subnivel
 *   coincida con la configuración correcta calculada por Aufbau.
 *   En evaluación, debe coincidir completamente para aprobar el reto.
 */
@WebServlet("/escenario5")
public class EscenarioCincoControlador extends HttpServlet {
 
    private static final int ID_ESCENARIO = 5;
 
    // Orden Aufbau completo para s y p (máx capacidad por subnivel)
    // formato: "nivel|tipo|capacidad"
    private static final String[] SUBNIVELES_ORDEN = {
        "1s", "2s", "2p", "3s", "3p", "4s", "4p",
        "5s", "5p", "6s", "6p", "7s", "7p"
    };
    private static final Map<String, Integer> CAPACIDAD = new LinkedHashMap<>();
    static {
        CAPACIDAD.put("1s", 2); CAPACIDAD.put("2s", 2); CAPACIDAD.put("2p", 6);
        CAPACIDAD.put("3s", 2); CAPACIDAD.put("3p", 6); CAPACIDAD.put("4s", 2);
        CAPACIDAD.put("4p", 6); CAPACIDAD.put("5s", 2); CAPACIDAD.put("5p", 6);
        CAPACIDAD.put("6s", 2); CAPACIDAD.put("6p", 6); CAPACIDAD.put("7s", 2);
        CAPACIDAD.put("7p", 6);
    }
 
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
            case "clickCelda":
                accionClickCelda(req, sesion);
                break;
            case "reiniciar":
                accionReiniciar(escenario, sesion);
                break;
            case "comprobar":
                accionComprobar(escenario, usuario, req, sesion);
                break;
            case "iniciarEval":
                accionIniciarEvaluacion(escenario, usuario, req, sesion);
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
 
        sesion.setAttribute("escenario5", escenario);
        publicarDatos(escenario, req, sesion);
        req.getRequestDispatcher("/escenario5/escenario5.jsp").forward(req, resp);
    }
 
    // ── CARGAR ───────────────────────────────────────────────────────────────
    private void accionCargar(Escenario escenario, Usuario usuario,
                               HttpServletRequest req, HttpSession sesion) {
        escenario.cargarEscenario();
        float pct = progresoDAO.obtenerPorcentaje(usuario.getIdUsuario(), ID_ESCENARIO);
        escenario.getProgreso().setPorcentajeAprendizaje(pct);
        req.setAttribute("mensajeMascota", escenario.guiaMascota());
        sesion.setAttribute("escenario5", escenario);
    }
 
    // ── SELECCIONAR ELEMENTO ─────────────────────────────────────────────────
    private void accionSeleccionarElemento(HttpServletRequest req,
                                            HttpSession sesion) {
        String zStr = req.getParameter("numeroAtomico");
        if (zStr == null) return;
        int z;
        try { z = Integer.parseInt(zStr); } catch (NumberFormatException e) { return; }
 
        ElementoBase eb = elementoDAO.obtenerPorNumeroAtomico(z);
        if (eb == null) return;
 
        // Solo permitir s y p
        String bloque = eb.getBloque();
        if (bloque == null || (!bloque.equalsIgnoreCase("s") && !bloque.equalsIgnoreCase("p"))) {
            req.setAttribute("mensajeMascota",
                "Este elemento es de bloque " + (bloque!=null?bloque:"desconocido") +
                ". En este escenario solo se trabaja con elementos de bloque s y p.");
            return;
        }
 
        sesion.setAttribute("elemSelec5", eb);
        // Limpiar configuración anterior
        sesion.removeAttribute("configUsuario5");
        sesion.removeAttribute("resultadoConfig5");
    }
 
    // ── CLICK EN CELDA ───────────────────────────────────────────────────────
    /**
     * Parámetros: subnivel (ej "2p"), celda (0-5 índice de la celda)
     * Estado de celda: 0=vacío, 1=↑, 2=↑↓
     * Ciclo: 0→1→2→0
     */
    @SuppressWarnings("unchecked")
    private void accionClickCelda(HttpServletRequest req, HttpSession sesion) {
        String subnivel = req.getParameter("subnivel");
        String celdaStr = req.getParameter("celda");
        if (subnivel == null || celdaStr == null) return;
 
        int celda;
        try { celda = Integer.parseInt(celdaStr); } catch (NumberFormatException e) { return; }
 
        // Recuperar o crear mapa de configuración
        Map<String, int[]> config = (Map<String,int[]>) sesion.getAttribute("configUsuario5");
        if (config == null) config = new LinkedHashMap<>();
 
        Integer cap = CAPACIDAD.get(subnivel);
        if (cap == null) return;
        int numCeldas = cap / 2; // cada celda = 2 electrones máximo
 
        int[] celdas = config.computeIfAbsent(subnivel, k -> new int[numCeldas]);
        if (celda < 0 || celda >= celdas.length) return;
 
        // Ciclo: 0 → 1 → 2 → 0
        celdas[celda] = (celdas[celda] + 1) % 3;
 
        // Validar: no se puede poner ↓ (estado 2) si la celda anterior está vacía
        // y verificar Principio de Hund básico: no emparejarse antes de llenar
        config.put(subnivel, celdas);
        sesion.setAttribute("configUsuario5", config);
        sesion.removeAttribute("resultadoConfig5");
    }
 
    // ── REINICIAR ────────────────────────────────────────────────────────────
    private void accionReiniciar(Escenario escenario, HttpSession sesion) {
        escenario.reiniciarEscenario();
        sesion.removeAttribute("elemSelec5");
        sesion.removeAttribute("configUsuario5");
        sesion.removeAttribute("resultadoConfig5");
        sesion.removeAttribute("retoActual5");
        sesion.removeAttribute("elemEval5");
    }
 
    // ── COMPROBAR (simulación y evaluación) ──────────────────────────────────
    @SuppressWarnings("unchecked")
    private void accionComprobar(Escenario escenario, Usuario usuario,
                                  HttpServletRequest req, HttpSession sesion) {
        boolean modoEval = escenario.isModoEvaluacion();
        ElementoBase eb  = modoEval
            ? (ElementoBase) sesion.getAttribute("elemEval5")
            : (ElementoBase) sesion.getAttribute("elemSelec5");
 
        if (eb == null) {
            req.setAttribute("mensajeMascota",
                modoEval ? "No hay reto activo. Presiona 'Iniciar Evaluación'."
                         : "Selecciona un elemento de la tabla periódica primero.");
            return;
        }
 
        Map<String, int[]> config = (Map<String,int[]>) sesion.getAttribute("configUsuario5");
        if (config == null) config = new LinkedHashMap<>();
 
        // Calcular configuración correcta
        Map<String, Integer> correcta = calcularConfiguracion(eb.getNumeroAtomico());
 
        // Contar electrones del usuario
        int electronesUsuario = contarElectrones(config);
        int electronesCorrectos = eb.getNumeroAtomico(); // = nº electrones del átomo neutro
 
        // Comparar subnivel por subnivel
        boolean configCorrecta = true;
        StringBuilder detalle = new StringBuilder();
        for (Map.Entry<String, Integer> entry : correcta.entrySet()) {
            String sub = entry.getKey();
            int   eCorr = entry.getValue();
            int   eUser = contarElectronesSubnivel(config.get(sub));
            if (eUser != eCorr) {
                configCorrecta = false;
                detalle.append("❌ ").append(sub).append(": tienes ").append(eUser)
                       .append(", correcto es ").append(eCorr).append("\n");
            } else {
                detalle.append("✅ ").append(sub).append(": ").append(eCorr).append("\n");
            }
        }
        // Verificar que no haya electrones en subniveles que no corresponden
        for (Map.Entry<String, int[]> entry : config.entrySet()) {
            String sub = entry.getKey();
            if (!correcta.containsKey(sub)) {
                int eUser = contarElectronesSubnivel(entry.getValue());
                if (eUser > 0) {
                    configCorrecta = false;
                    detalle.append("❌ ").append(sub).append(": no debe tener electrones (").append(eUser).append(")\n");
                }
            }
        }
 
        sesion.setAttribute("resultadoConfig5", configCorrecta ? "ok" : "err");
 
        if (modoEval) {
            Reto retoActual = (Reto) sesion.getAttribute("retoActual5");
            if (retoActual == null) return;
 
            retoActual.registrarIntento();
            int intento = retoActual.getIntentos();
            req.setAttribute("resultadoCorrecto", configCorrecta);
            req.setAttribute("intentosUsados",    intento);
 
            if (configCorrecta) {
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
                    "¡Excelente! La configuración de " + eb.getNombre()
                    + " es correcta. Intento " + intento + ".\n"
                    + "Configuración: " + construirNotacion(correcta));
 
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
                        "Intentos agotados. La configuración correcta era:\n"
                        + construirNotacion(correcta) + "\n\nDetalle:\n" + detalle
                        + "\nHe generado un nuevo reto.");
                    generarNuevoReto(escenario, usuario, req, sesion);
                } else {
                    int restantes = Reto.MAX_INTENTOS - intento;
                    req.setAttribute("mensajeMascota",
                        "Configuración incorrecta. Revisa:\n" + detalle
                        + "Te quedan " + restantes + " intento(s).");
                }
            }
            sesion.setAttribute("retoActual5", retoActual);
 
            Reto ra = (Reto) sesion.getAttribute("retoActual5");
            if (ra != null && req.getAttribute("retoActual") == null) {
                req.setAttribute("retoActual",    ra);
                req.setAttribute("temporizador",  ra.getTemporizador());
                req.setAttribute("intentosUsados", ra.getIntentos());
            }
        } else {
            // Modo simulación
            if (configCorrecta) {
                req.setAttribute("mensajeMascota",
                    "¡Configuración CORRECTA! ✅\n"
                    + eb.getNombre() + ": " + construirNotacion(correcta)
                    + "\nElectrones totales: " + electronesCorrectos);
            } else {
                req.setAttribute("mensajeMascota",
                    "Configuración INCORRECTA ❌\nDetalle:\n" + detalle.toString().trim()
                    + "\n\nConfiguración correcta: " + construirNotacion(correcta));
            }
        }
    }
 
    // ── INICIAR EVALUACIÓN ───────────────────────────────────────────────────
    private void accionIniciarEvaluacion(Escenario escenario, Usuario usuario,
                                          HttpServletRequest req, HttpSession sesion) {
        escenario.iniciarEvaluacion();
        generarNuevoReto(escenario, usuario, req, sesion);
    }
 
    // ── CONTINUAR ────────────────────────────────────────────────────────────
    private void accionContinuar(Escenario escenario, HttpSession sesion,
                                  HttpServletResponse resp) throws IOException {
        if (escenario.getProgreso().getPorcentajeAprendizaje() >= 80.0f) {
            escenario.superarEscenario();
            sesion.removeAttribute("escenario5");
            resp.sendRedirect("escenario6");
        }
    }
 
    // ── FINALIZAR ────────────────────────────────────────────────────────────
    private void accionFinalizar(Escenario escenario, HttpSession sesion,
                                  HttpServletRequest req) {
        escenario.setModoEvaluacion(false);
        sesion.removeAttribute("retoActual5");
        sesion.removeAttribute("elemEval5");
        sesion.removeAttribute("configUsuario5");
        sesion.removeAttribute("resultadoConfig5");
        float pct = escenario.getProgreso().getPorcentajeAprendizaje();
        req.setAttribute("mensajeMascota",
            "Evaluación finalizada. Tu porcentaje: " + Math.round(pct) + "%. "
            + (pct >= 80 ? "¡Superaste el escenario!" : "Sigue practicando para alcanzar el 80%."));
    }
 
    // ── VOLVER ───────────────────────────────────────────────────────────────
    private void accionVolver(Escenario escenario, HttpSession sesion,
                               HttpServletResponse resp) throws IOException {
        escenario.salirEscenario();
        sesion.removeAttribute("escenario5");
        resp.sendRedirect("login.jsp");
    }
 
    // ════════════════════════════════════════════════════════════════════════
    // HELPERS
    // ════════════════════════════════════════════════════════════════════════
 
    /** Genera reto con elemento aleatorio de bloque s o p */
    private void generarNuevoReto(Escenario escenario, Usuario usuario,
                                   HttpServletRequest req, HttpSession sesion) {
        ElementoBase eb = null;
        for (int i = 0; i < 30; i++) {
            ElementoBase candidato = elementoDAO.obtenerAleatorio();
            if (candidato != null) {
                String blq = candidato.getBloque();
                if (blq != null && (blq.equalsIgnoreCase("s") || blq.equalsIgnoreCase("p"))) {
                    eb = candidato;
                    break;
                }
            }
        }
        if (eb == null) return;
 
        Map<String, Integer> correcta = calcularConfiguracion(eb.getNumeroAtomico());
 
        Reto reto = new Reto();
        reto.setIdUsuario(usuario.getIdUsuario());
        reto.setIdEscenario(ID_ESCENARIO);
        reto.generarReto(eb, eb.getNumeroAtomico(), 0, eb.getNumeroAtomico());
        reto.setDescripcion(
            "Realiza la configuración electrónica de: "
            + eb.getNombre() + " (Z = " + eb.getNumeroAtomico() + ")\n"
            + "Configuración esperada: " + construirNotacion(correcta));
 
        int idReto = retoDAO.insertar(reto);
        reto.setIdReto(idReto);
 
        escenario.setRetoActual(reto);
        sesion.setAttribute("retoActual5",    reto);
        sesion.setAttribute("elemEval5",      eb);
        sesion.removeAttribute("configUsuario5");
        sesion.removeAttribute("resultadoConfig5");
 
        req.setAttribute("nuevoReto",       true);
        req.setAttribute("retoActual",      reto);
        req.setAttribute("descripcionReto", reto.getDescripcion());
        req.setAttribute("temporizador",    reto.getTemporizador());
        req.setAttribute("intentosUsados",  0);
    }
 
    /**
     * Calcula la configuración electrónica por la regla de Aufbau
     * SOLO para subniveles s y p.
     * Retorna mapa subnivel → número de electrones (solo los que tienen electrones).
     */
    public static Map<String, Integer> calcularConfiguracion(int z) {
        // Orden Aufbau completo (incluye d y f para contar bien)
        String[] ordenCompleto = {
            "1s","2s","2p","3s","3p","4s","3d","4p",
            "5s","4d","5p","6s","4f","5d","6p",
            "7s","5f","6d","7p"
        };
        Map<String, Integer> capCompleta = new LinkedHashMap<>();
        capCompleta.put("1s",2); capCompleta.put("2s",2); capCompleta.put("2p",6);
        capCompleta.put("3s",2); capCompleta.put("3p",6); capCompleta.put("4s",2);
        capCompleta.put("3d",10);capCompleta.put("4p",6); capCompleta.put("5s",2);
        capCompleta.put("4d",10);capCompleta.put("5p",6); capCompleta.put("6s",2);
        capCompleta.put("4f",14);capCompleta.put("5d",10);capCompleta.put("6p",6);
        capCompleta.put("7s",2); capCompleta.put("5f",14);capCompleta.put("6d",10);
        capCompleta.put("7p",6);
 
        Map<String, Integer> resultado = new LinkedHashMap<>();
        int restantes = z;
        for (String sub : ordenCompleto) {
            if (restantes <= 0) break;
            int cap = capCompleta.get(sub);
            int eEnSub = Math.min(restantes, cap);
            // Solo guardar subniveles s y p
            if (sub.endsWith("s") || sub.endsWith("p")) {
                resultado.put(sub, eEnSub);
            }
            restantes -= eEnSub;
        }
        return resultado;
    }
 
    /** Construye la notación estándar ej. "1s² 2s² 2p⁶" */
    private String construirNotacion(Map<String, Integer> config) {
        String[] sup = {"⁰","¹","²","³","⁴","⁵","⁶","⁷","⁸","⁹",
                        "¹⁰","¹¹","¹²","¹³","¹⁴"};
        StringBuilder sb = new StringBuilder();
        for (Map.Entry<String, Integer> e : config.entrySet()) {
            if (e.getValue() > 0) {
                int v = e.getValue();
                String superIndex = (v < sup.length) ? sup[v] : String.valueOf(v);
                sb.append(e.getKey()).append(superIndex).append(" ");
            }
        }
        return sb.toString().trim();
    }
 
    private int contarElectrones(Map<String, int[]> config) {
        int total = 0;
        for (int[] celdas : config.values()) total += contarElectronesSubnivel(celdas);
        return total;
    }
 
    private int contarElectronesSubnivel(int[] celdas) {
        if (celdas == null) return 0;
        int total = 0;
        for (int c : celdas) {
            if (c == 1) total += 1;
            else if (c == 2) total += 2;
        }
        return total;
    }
 
    @SuppressWarnings("unchecked")
    private void publicarDatos(Escenario escenario, HttpServletRequest req,
                                HttpSession sesion) {
        int pct = Math.round(escenario.getProgreso().getPorcentajeAprendizaje());
        req.setAttribute("porcentaje",    pct);
        req.setAttribute("modoEvaluacion", escenario.isModoEvaluacion());
        req.setAttribute("habilitarContinuar",
            escenario.getProgreso().getPorcentajeAprendizaje() >= 80.0f
            && escenario.isModoEvaluacion());
 
        // Elementos de la tabla periódica (solo s y p)
        List<ElementoBase> todos = elementoDAO.obtenerTodos();
        List<ElementoBase> spList = new ArrayList<>();
        for (ElementoBase e : todos) {
            String b = e.getBloque();
            if (b != null && (b.equalsIgnoreCase("s") || b.equalsIgnoreCase("p")))
                spList.add(e);
        }
        req.setAttribute("elementosPeriodica", spList);
 
        // Elemento seleccionado
        boolean modoEval = escenario.isModoEvaluacion();
        ElementoBase ebActual = modoEval
            ? (ElementoBase) sesion.getAttribute("elemEval5")
            : (ElementoBase) sesion.getAttribute("elemSelec5");
        req.setAttribute("elemActual", ebActual);
 
        // Z seleccionado para marcar tabla
        int zSelec = (ebActual != null) ? ebActual.getNumeroAtomico() : 0;
        req.setAttribute("zSeleccionado", zSelec);
 
        // Configuración del usuario
        Map<String, int[]> config = (Map<String,int[]>) sesion.getAttribute("configUsuario5");
        if (config == null) config = new LinkedHashMap<>();
        req.setAttribute("configUsuario", config);
 
        // Electrones colocados
        req.setAttribute("electronesColocados", contarElectrones(config));
 
        // Configuración correcta (si hay elemento)
        if (ebActual != null) {
            Map<String, Integer> correcta = calcularConfiguracion(ebActual.getNumeroAtomico());
            req.setAttribute("configCorrecta", correcta);
            req.setAttribute("notacionCorrecta", construirNotacion(correcta));
        }
 
        // Resultado
        req.setAttribute("resultadoConfig", sesion.getAttribute("resultadoConfig5"));
 
        // HUD reto
        Reto ra = (Reto) sesion.getAttribute("retoActual5");
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
        Escenario esc = (Escenario) sesion.getAttribute("escenario5");
        if (esc == null)
            esc = new Escenario(ID_ESCENARIO, "Configuración Electrónica", 3);
        return esc;
    }
}