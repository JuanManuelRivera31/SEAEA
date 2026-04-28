package logica;

import dao.ElementoBaseDAO;
import dao.PuntajeRetoDAO;
import dao.ProgresoEscenarioDAO;
import dao.RetoDAO;
import modelo.ElementoBase;
import modelo.Escenario;
import modelo.PuntajeReto;
import modelo.Reto;
import modelo.Usuario;

import java.util.LinkedHashMap;
import java.util.Map;

/**
 * EscenarioCincoServicio
 * ─────────────────────────────────────────────────────────────────────────
 * Capa de LÓGICA de negocio para el Escenario 5 "Configuración Electrónica".
 *
 * Responsabilidades:
 *  - Calcular la configuración electrónica correcta por regla de Aufbau
 *    (solo subniveles s y p).
 *  - Validar que el elemento sea de bloque s o p.
 *  - Gestionar el ciclo de estado de celdas (0→1→2→0).
 *  - Generar retos y comprobar la configuración del estudiante.
 *  - Construir la notación estándar (ej. 1s² 2s² 2p⁶).
 */
public class EscenarioCincoServicio {

    private static final int   ID_ESCENARIO       = 5;
    public  static final float MINIMO_APROBATORIO = 80.0f;

    // Capacidades de cada subnivel s y p
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

    // ══════════════════════════════════════════════════════════════════════
    // SELECCIÓN DE ELEMENTO
    // ══════════════════════════════════════════════════════════════════════

    /**
     * Valida que el elemento sea de bloque s o p.
     * Retorna el ElementoBase si es válido, null si no.
     */
    public ElementoBase seleccionarElemento(int z) {
        ElementoBase eb = elementoDAO.obtenerPorNumeroAtomico(z);
        if (eb == null) return null;
        String bloque = eb.getBloque();
        if (bloque == null) return null;
        return (bloque.equalsIgnoreCase("s") || bloque.equalsIgnoreCase("p")) ? eb : null;
    }

    // ══════════════════════════════════════════════════════════════════════
    // GESTIÓN DE CELDAS
    // ══════════════════════════════════════════════════════════════════════

    /**
     * Cicla el estado de una celda: 0 (vacía) → 1 (↑) → 2 (↑↓) → 0.
     * Valida que el subnivel y el índice de celda sean válidos.
     *
     * @param config     mapa actual de configuración del usuario
     * @param subnivel   ej. "2p"
     * @param indiceCelda índice 0-based de la celda dentro del subnivel
     * @return mapa actualizado, o el mismo mapa sin cambios si hay error
     */
    public Map<String, int[]> ciclarCelda(Map<String, int[]> config,
                                           String subnivel, int indiceCelda) {
        if (config == null) config = new LinkedHashMap<>();
        Integer cap = CAPACIDAD.get(subnivel);
        if (cap == null) return config;

        int numCeldas = cap / 2;
        if (indiceCelda < 0 || indiceCelda >= numCeldas) return config;

        int[] celdas = config.computeIfAbsent(subnivel, k -> new int[numCeldas]);
        celdas[indiceCelda] = (celdas[indiceCelda] + 1) % 3;
        config.put(subnivel, celdas);
        return config;
    }

    // ══════════════════════════════════════════════════════════════════════
    // CÁLCULO DE CONFIGURACIÓN (AUFBAU)
    // ══════════════════════════════════════════════════════════════════════

    /**
     * Calcula la configuración electrónica correcta por la regla de Aufbau.
     * Solo devuelve subniveles s y p con electrones > 0.
     *
     * @param z número atómico del elemento
     * @return mapa ordenado subnivel → número de electrones
     */
    public static Map<String, Integer> calcularConfiguracion(int z) {
        String[] ordenCompleto = {
            "1s","2s","2p","3s","3p","4s","3d","4p",
            "5s","4d","5p","6s","4f","5d","6p",
            "7s","5f","6d","7p"
        };
        Map<String, Integer> capCompleta = new LinkedHashMap<>();
        capCompleta.put("1s",2);  capCompleta.put("2s",2);  capCompleta.put("2p",6);
        capCompleta.put("3s",2);  capCompleta.put("3p",6);  capCompleta.put("4s",2);
        capCompleta.put("3d",10); capCompleta.put("4p",6);  capCompleta.put("5s",2);
        capCompleta.put("4d",10); capCompleta.put("5p",6);  capCompleta.put("6s",2);
        capCompleta.put("4f",14); capCompleta.put("5d",10); capCompleta.put("6p",6);
        capCompleta.put("7s",2);  capCompleta.put("5f",14); capCompleta.put("6d",10);
        capCompleta.put("7p",6);

        Map<String, Integer> resultado = new LinkedHashMap<>();
        int restantes = z;
        for (String sub : ordenCompleto) {
            if (restantes <= 0) break;
            int cap = capCompleta.get(sub);
            int eEnSub = Math.min(restantes, cap);
            if (sub.endsWith("s") || sub.endsWith("p")) {
                resultado.put(sub, eEnSub);
            }
            restantes -= eEnSub;
        }
        return resultado;
    }

    /**
     * Construye la notación estándar: "1s² 2s² 2p⁶ ..."
     */
    public static String construirNotacion(Map<String, Integer> config) {
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

    // ══════════════════════════════════════════════════════════════════════
    // CONTEO DE ELECTRONES
    // ══════════════════════════════════════════════════════════════════════

    /** Total de electrones en toda la configuración del usuario. */
    public int contarElectrones(Map<String, int[]> config) {
        int total = 0;
        if (config == null) return 0;
        for (int[] celdas : config.values()) total += contarEnSubnivel(celdas);
        return total;
    }

    /** Electrones en un subnivel específico. */
    public int contarEnSubnivel(int[] celdas) {
        if (celdas == null) return 0;
        int total = 0;
        for (int c : celdas) { if (c == 1) total++; else if (c == 2) total += 2; }
        return total;
    }

    // ══════════════════════════════════════════════════════════════════════
    // EVALUACIÓN
    // ══════════════════════════════════════════════════════════════════════

    /**
     * Genera un reto con un elemento aleatorio de bloque s o p.
     */
    public ResultadoReto generarReto(Usuario usuario) {
        ElementoBase eb = null;
        for (int i = 0; i < 30; i++) {
            ElementoBase candidato = elementoDAO.obtenerAleatorio();
            if (candidato != null) {
                String blq = candidato.getBloque();
                if (blq != null && (blq.equalsIgnoreCase("s") || blq.equalsIgnoreCase("p"))) {
                    eb = candidato; break;
                }
            }
        }
        if (eb == null) return null;

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

        return new ResultadoReto(reto, eb, null, false);
    }

    /**
     * Comprueba la configuración del estudiante contra la correcta.
     * Solo aprueba si TODOS los subniveles coinciden.
     */
    public ResultadoComprobacion comprobar(Escenario escenario,
                                           Reto retoActual,
                                           ElementoBase eb,
                                           Map<String, int[]> configUsuario,
                                           Usuario usuario) {
        Map<String, Integer> correcta = calcularConfiguracion(eb.getNumeroAtomico());

        boolean configCorrecta = true;
        StringBuilder detalle = new StringBuilder();

        for (Map.Entry<String, Integer> entry : correcta.entrySet()) {
            String sub    = entry.getKey();
            int    eCorr  = entry.getValue();
            int    eUser  = contarEnSubnivel(
                configUsuario != null ? configUsuario.get(sub) : null);
            if (eUser != eCorr) {
                configCorrecta = false;
                detalle.append("❌ ").append(sub).append(": tienes ").append(eUser)
                       .append(", correcto es ").append(eCorr).append("\n");
            } else {
                detalle.append("✅ ").append(sub).append(": ").append(eCorr).append("\n");
            }
        }
        // Verificar que no haya electrones en subniveles incorrectos
        if (configUsuario != null) {
            for (Map.Entry<String, int[]> entry : configUsuario.entrySet()) {
                if (!correcta.containsKey(entry.getKey())) {
                    int eUser = contarEnSubnivel(entry.getValue());
                    if (eUser > 0) {
                        configCorrecta = false;
                        detalle.append("❌ ").append(entry.getKey())
                               .append(": no debe tener electrones (").append(eUser).append(")\n");
                    }
                }
            }
        }

        retoActual.registrarIntento();
        int intento = retoActual.getIntentos();

        PuntajeReto pr = new PuntajeReto(retoActual, intento, configCorrecta);
        puntajeDAO.insertar(retoActual.getIdReto(), intento, pr.getPuntaje(), configCorrecta);

        if (configCorrecta) retoActual.setCompletado(true);
        retoDAO.actualizar(retoActual);

        float porcentaje = puntajeDAO.calcularPorcentajeAprendizaje(
                usuario.getIdUsuario(), ID_ESCENARIO);
        progresoDAO.guardar(usuario.getIdUsuario(), ID_ESCENARIO, porcentaje);
        escenario.getProgreso().setPorcentajeAprendizaje(porcentaje);

        String mensaje;
        if (configCorrecta) {
            mensaje = "¡Excelente! La configuración de " + eb.getNombre()
                + " es correcta. Intento " + intento + ".\n"
                + "Configuración: " + construirNotacion(correcta);
        } else if (retoActual.agotadoIntentos()) {
            mensaje = "Intentos agotados. La configuración correcta era:\n"
                + construirNotacion(correcta) + "\n\nDetalle:\n"
                + detalle.toString().trim();
        } else {
            int restantes = Reto.MAX_INTENTOS - intento;
            mensaje = "Configuración incorrecta. Revisa:\n"
                + detalle.toString().trim()
                + "\nTe quedan " + restantes + " intento(s).";
        }

        boolean habilitarContinuar = porcentaje >= MINIMO_APROBATORIO;
        boolean generarNuevoReto   = configCorrecta || retoActual.agotadoIntentos();

        return new ResultadoComprobacion(
            configCorrecta, porcentaje, mensaje,
            habilitarContinuar, generarNuevoReto, intento);
    }

    /** Carga el porcentaje previo. */
    public float cargarProgreso(int idUsuario) {
        return progresoDAO.obtenerPorcentaje(idUsuario, ID_ESCENARIO);
    }

    // ══════════════════════════════════════════════════════════════════════
    // DTOs
    // ══════════════════════════════════════════════════════════════════════

    public static class ResultadoReto {
        public final Reto         reto;
        public final ElementoBase elementoBase;
        public final String       mensaje;
        public final boolean      error;

        public ResultadoReto(Reto reto, ElementoBase elementoBase,
                             String mensaje, boolean error) {
            this.reto         = reto;
            this.elementoBase = elementoBase;
            this.mensaje      = mensaje;
            this.error        = error;
        }
    }

    public static class ResultadoComprobacion {
        public final boolean correcto;
        public final float   porcentaje;
        public final String  mensajeMascota;
        public final boolean habilitarContinuar;
        public final boolean generarNuevoReto;
        public final int     intentoUsado;

        public ResultadoComprobacion(boolean correcto, float porcentaje,
                                     String mensajeMascota,
                                     boolean habilitarContinuar,
                                     boolean generarNuevoReto,
                                     int intentoUsado) {
            this.correcto           = correcto;
            this.porcentaje         = porcentaje;
            this.mensajeMascota     = mensajeMascota;
            this.habilitarContinuar = habilitarContinuar;
            this.generarNuevoReto   = generarNuevoReto;
            this.intentoUsado       = intentoUsado;
        }
    }
}