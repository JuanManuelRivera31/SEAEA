package logica;
 
import dao.ElementoBaseDAO;
import dao.ProgresoEscenarioDAO;
import dao.PuntajeRetoDAO;
import dao.RetoDAO;
import modelo.ElementoBase;
import modelo.Escenario;
import modelo.PuntajeReto;
import modelo.Reto;
import modelo.Usuario;
 
import java.util.ArrayList;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
 
/**
 * EscenarioCincoServicio
 * ─────────────────────────────────────────────────────────────────────────
 * Capa de LÓGICA de negocio para el Escenario 5 "Configuración Electrónica".
 *
 * Flujo MVC:
 *   JSP → Controlador → EscenarioCincoServicio → DAOs / Modelo → BD
 *                     ←                        ←               ←
 *
 * Este servicio es el ÚNICO que toca DAOs y ejecuta lógica de negocio.
 * El controlador solo lo llama y publica los DTOs de resultado al JSP.
 */
public class EscenarioCincoServicio {
 
    // ── Constantes ────────────────────────────────────────────────────────
    public static final int   ID_ESCENARIO       = 5;
    public static final float MINIMO_APROBATORIO = 80.0f;
 
    /** Capacidad máxima de cada subnivel s y p (en electrones). */
    public static final Map<String, Integer> CAPACIDAD = new LinkedHashMap<>();
    static {
        CAPACIDAD.put("1s", 2); CAPACIDAD.put("2s", 2); CAPACIDAD.put("2p", 6);
        CAPACIDAD.put("3s", 2); CAPACIDAD.put("3p", 6); CAPACIDAD.put("4s", 2);
        CAPACIDAD.put("4p", 6); CAPACIDAD.put("5s", 2); CAPACIDAD.put("5p", 6);
        CAPACIDAD.put("6s", 2); CAPACIDAD.put("6p", 6); CAPACIDAD.put("7s", 2);
        CAPACIDAD.put("7p", 6);
    }
 
    // ── DAOs ─────────────────────────────────────────────────────────────
    private final ElementoBaseDAO      elementoDAO = new ElementoBaseDAO();
    private final RetoDAO              retoDAO     = new RetoDAO();
    private final PuntajeRetoDAO       puntajeDAO  = new PuntajeRetoDAO();
    private final ProgresoEscenarioDAO progresoDAO = new ProgresoEscenarioDAO();
 
    // ══════════════════════════════════════════════════════════════════════
    // CARGA INICIAL
    // ══════════════════════════════════════════════════════════════════════
 
    /**
     * Carga el escenario: establece el porcentaje previo y genera el mensaje
     * de bienvenida de la mascota.
     */
    public ResultadoCarga cargar(Escenario escenario, Usuario usuario) {
        escenario.cargarEscenario();
        float pct = progresoDAO.obtenerPorcentaje(usuario.getIdUsuario(), ID_ESCENARIO);
        escenario.getProgreso().setPorcentajeAprendizaje(pct);
        String mensaje = escenario.guiaMascota();
        return new ResultadoCarga(pct, mensaje);
    }
 
    /**
     * Obtiene la lista de elementos filtrada a solo bloque s y p,
     * para mostrar en la tabla periódica del JSP.
     */
    public List<ElementoBase> obtenerElementosSP() {
        List<ElementoBase> todos = elementoDAO.obtenerTodos();
        List<ElementoBase> spList = new ArrayList<>();
        for (ElementoBase e : todos) {
            String b = e.getBloque();
            if (b != null && (b.equalsIgnoreCase("s") || b.equalsIgnoreCase("p")))
                spList.add(e);
        }
        return spList;
    }
 
    // ══════════════════════════════════════════════════════════════════════
    // SELECCIÓN DE ELEMENTO
    // ══════════════════════════════════════════════════════════════════════
 
    /**
     * Busca el elemento por Z y valida que sea de bloque s o p.
     *
     * @return el ElementoBase si es válido para el escenario; null si no existe
     *         o si es de bloque d/f. El controlador usa null para mostrar mensaje de error.
     */
    public ElementoBase seleccionarElemento(int z) {
        ElementoBase eb = elementoDAO.obtenerPorNumeroAtomico(z);
        if (eb == null) return null;
        String bloque = eb.getBloque();
        if (bloque == null) return null;
        return (bloque.equalsIgnoreCase("s") || bloque.equalsIgnoreCase("p")) ? eb : null;
    }
 
    /**
     * Retorna el bloque del elemento para el mensaje de error cuando es inválido.
     */
    public String obtenerBloqueElemento(int z) {
        ElementoBase eb = elementoDAO.obtenerPorNumeroAtomico(z);
        if (eb == null || eb.getBloque() == null) return "desconocido";
        return eb.getBloque();
    }
 
    // ══════════════════════════════════════════════════════════════════════
    // GESTIÓN DE CELDAS
    // ══════════════════════════════════════════════════════════════════════
 
    /**
     * Cicla el estado de una celda del diagrama orbital:
     *   0 (vacía) → 1 (↑ un electrón) → 2 (↑↓ par) → 0 (vacía)
     *
     * @param config      mapa actual de configuración del usuario (puede ser null)
     * @param subnivel    ej. "2p"
     * @param indiceCelda índice 0-based de la celda dentro del subnivel
     * @return mapa de configuración actualizado
     */
    public Map<String, int[]> ciclarCelda(Map<String, int[]> config,
                                           String subnivel, int indiceCelda) {
        if (config == null) config = new LinkedHashMap<>();
        Integer cap = CAPACIDAD.get(subnivel);
        if (cap == null) return config;
 
        int numCeldas = cap / 2; // cada celda = 1 orbital = máx 2e⁻
        if (indiceCelda < 0 || indiceCelda >= numCeldas) return config;
 
        int[] celdas = config.computeIfAbsent(subnivel, k -> new int[numCeldas]);
        celdas[indiceCelda] = (celdas[indiceCelda] + 1) % 3;
        config.put(subnivel, celdas);
        return config;
    }
 
    // ══════════════════════════════════════════════════════════════════════
    // MODO SIMULACIÓN (sin persistencia de puntaje)
    // ══════════════════════════════════════════════════════════════════════
 
    /**
     * Comprueba la configuración del usuario en modo simulación libre.
     * No persiste puntaje ni progreso.
     *
     * @return ResultadoSimulacion con el resultado y mensaje pedagógico
     */
    public ResultadoSimulacion comprobarSimulacion(ElementoBase eb,
                                                    Map<String, int[]> configUsuario) {
        if (eb == null) {
            return new ResultadoSimulacion(false,
                "Selecciona un elemento de la tabla periódica primero.", "");
        }
        if (configUsuario == null) configUsuario = new LinkedHashMap<>();
 
        Map<String, Integer> correcta = calcularConfiguracion(eb.getNumeroAtomico());
        ResultadoValidacion val = validarConfiguracion(correcta, configUsuario);
 
        String notacion = construirNotacion(correcta);
        String mensaje;
        if (val.correcta) {
            mensaje = "¡Configuración CORRECTA! ✅\n"
                + eb.getNombre() + ": " + notacion
                + "\nElectrones totales: " + eb.getNumeroAtomico();
        } else {
            mensaje = "Configuración INCORRECTA ❌\nDetalle:\n"
                + val.detalle.toString().trim()
                + "\n\nConfiguración correcta: " + notacion;
        }
        return new ResultadoSimulacion(val.correcta, mensaje, val.correcta ? "ok" : "err");
    }
 
    // ══════════════════════════════════════════════════════════════════════
    // MODO EVALUACIÓN
    // ══════════════════════════════════════════════════════════════════════
 
    /**
     * Activa el modo evaluación en el escenario.
     */
    public void iniciarEvaluacion(Escenario escenario) {
        escenario.iniciarEvaluacion();
    }
 
    /**
     * Genera un reto con un elemento aleatorio de bloque s o p.
     * Persiste el reto en BD.
     *
     * @return ResultadoReto con el Reto y el ElementoBase; null si no hay elementos válidos.
     */
    public ResultadoReto generarReto(Usuario usuario) {
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
     * Comprueba la configuración del estudiante en modo evaluación.
     * Solo aprueba si TODOS los subniveles son correctos.
     * Persiste puntaje y progreso.
     */
    public ResultadoComprobacion comprobar(Escenario escenario,
                                            Reto retoActual,
                                            ElementoBase eb,
                                            Map<String, int[]> configUsuario,
                                            Usuario usuario) {
        if (retoActual == null || eb == null) {
            return new ResultadoComprobacion(
                false, escenario.getProgreso().getPorcentajeAprendizaje(),
                "No hay reto activo. Presiona 'Iniciar Evaluación'.",
                false, false, 0);
        }
        if (configUsuario == null) configUsuario = new LinkedHashMap<>();
 
        Map<String, Integer> correcta = calcularConfiguracion(eb.getNumeroAtomico());
        ResultadoValidacion val = validarConfiguracion(correcta, configUsuario);
 
        retoActual.registrarIntento();
        int intento = retoActual.getIntentos();
 
        // Persistir intento
        PuntajeReto pr = new PuntajeReto(retoActual, intento, val.correcta);
        puntajeDAO.insertar(retoActual.getIdReto(), intento, pr.getPuntaje(), val.correcta);
 
        if (val.correcta) retoActual.setCompletado(true);
        retoDAO.actualizar(retoActual);
 
        // Recalcular progreso
        float porcentaje = puntajeDAO.calcularPorcentajeAprendizaje(
                usuario.getIdUsuario(), ID_ESCENARIO);
        progresoDAO.guardar(usuario.getIdUsuario(), ID_ESCENARIO, porcentaje);
        escenario.getProgreso().setPorcentajeAprendizaje(porcentaje);
 
        // Construir mensaje
        String notacion = construirNotacion(correcta);
        String mensaje;
        if (val.correcta) {
            mensaje = "¡Excelente! La configuración de " + eb.getNombre()
                + " es correcta. Intento " + intento + ".\n"
                + "Configuración: " + notacion;
        } else if (retoActual.agotadoIntentos()) {
            mensaje = "Intentos agotados. La configuración correcta era:\n"
                + notacion + "\n\nDetalle:\n" + val.detalle.toString().trim();
        } else {
            int restantes = Reto.MAX_INTENTOS - intento;
            mensaje = "Configuración incorrecta. Revisa:\n"
                + val.detalle.toString().trim()
                + "\nTe quedan " + restantes + " intento(s).";
        }
 
        boolean habilitarContinuar = porcentaje >= MINIMO_APROBATORIO;
        boolean generarNuevoReto   = val.correcta || retoActual.agotadoIntentos();
 
        return new ResultadoComprobacion(
            val.correcta, porcentaje, mensaje,
            habilitarContinuar, generarNuevoReto, intento);
    }
 
    /**
     * Finaliza la evaluación y retorna el mensaje de cierre.
     */
    public String finalizar(Escenario escenario) {
        escenario.setModoEvaluacion(false);
        float pct = escenario.getProgreso().getPorcentajeAprendizaje();
        return "Evaluación finalizada. Tu porcentaje: " + Math.round(pct) + "%. "
             + (pct >= MINIMO_APROBATORIO
                ? "¡Superaste el escenario!"
                : "Sigue practicando para alcanzar el 80%.");
    }
 
    /** Verifica si el porcentaje alcanza el mínimo para continuar. */
    public boolean puedeSuperar(Escenario escenario) {
        return escenario.getProgreso().getPorcentajeAprendizaje() >= MINIMO_APROBATORIO;
    }
 
    /** Marca el escenario como superado. */
    public void superar(Escenario escenario) {
        escenario.superarEscenario();
    }
 
    /** Prepara la salida del escenario. */
    public void salir(Escenario escenario) {
        escenario.salirEscenario();
    }
 
    /** Reinicia el estado del escenario. */
    public void reiniciar(Escenario escenario) {
        escenario.reiniciarEscenario();
    }
 
    // ══════════════════════════════════════════════════════════════════════
    // LÓGICA INTERNA DE CONFIGURACIÓN ELECTRÓNICA
    // ══════════════════════════════════════════════════════════════════════
 
    /**
     * Calcula la configuración electrónica correcta por la regla de Aufbau.
     * Recorre el orden completo (incluyendo d y f para contar bien),
     * pero solo devuelve subniveles s y p con electrones > 0.
     *
     * Método público y estático porque el JSP necesita recibirlo como atributo
     * del request; el controlador lo llama via servicio y lo publica.
     *
     * @param z número atómico
     * @return mapa ordenado subnivel → número de electrones (solo s y p)
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
     * Método público y estático para que el controlador pueda publicarla al JSP.
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
 
    // ── Conteo de electrones ──────────────────────────────────────────────
 
    /** Total de electrones en toda la configuración del usuario. */
    public int contarElectrones(Map<String, int[]> config) {
        if (config == null) return 0;
        int total = 0;
        for (int[] celdas : config.values()) total += contarEnSubnivel(celdas);
        return total;
    }
 
    /** Electrones en un subnivel específico (null → 0). */
    public int contarEnSubnivel(int[] celdas) {
        if (celdas == null) return 0;
        int total = 0;
        for (int c : celdas) { if (c == 1) total++; else if (c == 2) total += 2; }
        return total;
    }
 
    // ── Validación ────────────────────────────────────────────────────────
 
    /**
     * Compara la configuración del usuario con la correcta subnivel a subnivel.
     * También verifica que no haya electrones en subniveles incorrectos.
     */
    private ResultadoValidacion validarConfiguracion(Map<String, Integer> correcta,
                                                      Map<String, int[]> configUsuario) {
        boolean correcto = true;
        StringBuilder detalle = new StringBuilder();
 
        // Verificar cada subnivel esperado
        for (Map.Entry<String, Integer> entry : correcta.entrySet()) {
            String sub   = entry.getKey();
            int    eCorr = entry.getValue();
            int    eUser = contarEnSubnivel(
                configUsuario != null ? configUsuario.get(sub) : null);
            if (eUser != eCorr) {
                correcto = false;
                detalle.append("❌ ").append(sub).append(": tienes ").append(eUser)
                       .append(", correcto es ").append(eCorr).append("\n");
            } else {
                detalle.append("✅ ").append(sub).append(": ").append(eCorr).append("\n");
            }
        }
 
        // Verificar que no haya electrones en subniveles que no corresponden
        if (configUsuario != null) {
            for (Map.Entry<String, int[]> entry : configUsuario.entrySet()) {
                if (!correcta.containsKey(entry.getKey())) {
                    int eUser = contarEnSubnivel(entry.getValue());
                    if (eUser > 0) {
                        correcto = false;
                        detalle.append("❌ ").append(entry.getKey())
                               .append(": no debe tener electrones (").append(eUser).append(")\n");
                    }
                }
            }
        }
 
        return new ResultadoValidacion(correcto, detalle);
    }
 
    // ══════════════════════════════════════════════════════════════════════
    // DTOs DE RETORNO
    // ══════════════════════════════════════════════════════════════════════
 
    /** Resultado de la carga inicial del escenario. */
    public static class ResultadoCarga {
        public final float  porcentaje;
        public final String mensajeMascota;
        public ResultadoCarga(float porcentaje, String mensajeMascota) {
            this.porcentaje     = porcentaje;
            this.mensajeMascota = mensajeMascota;
        }
    }
 
    /** Resultado de comprobar en modo simulación libre. */
    public static class ResultadoSimulacion {
        public final boolean correcto;
        public final String  mensajeMascota;
        /** "ok" o "err" — para que el controlador lo guarde en sesión */
        public final String  estadoConfig;
        public ResultadoSimulacion(boolean correcto, String mensajeMascota, String estadoConfig) {
            this.correcto       = correcto;
            this.mensajeMascota = mensajeMascota;
            this.estadoConfig   = estadoConfig;
        }
    }
 
    /** Resultado de generar un reto de evaluación. */
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
 
    /** Resultado de comprobar en modo evaluación. */
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
                                      boolean generarNuevoReto, int intentoUsado) {
            this.correcto           = correcto;
            this.porcentaje         = porcentaje;
            this.mensajeMascota     = mensajeMascota;
            this.habilitarContinuar = habilitarContinuar;
            this.generarNuevoReto   = generarNuevoReto;
            this.intentoUsado       = intentoUsado;
        }
    }
 
    /** DTO interno para resultado de validación de configuración. */
    private static class ResultadoValidacion {
        public final boolean       correcta;
        public final StringBuilder detalle;
        public ResultadoValidacion(boolean correcta, StringBuilder detalle) {
            this.correcta = correcta;
            this.detalle  = detalle;
        }
    }
}