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
 
import java.util.Collections;
import java.util.List;
 
/**
 * EscenarioSeisServicio
 * ─────────────────────────────────────────────────────────────────────────
 * Capa de LÓGICA de negocio para el Escenario 6
 * "Propiedades Periódicas de los Elementos".
 *
 * Flujo MVC:
 *   JSP → Controlador → EscenarioSeisServicio → DAOs / Modelo → BD
 *                     ←                       ←               ←
 *
 * El controlador SOLO orquesta: recibe la acción, llama a este servicio
 * y publica los DTOs de resultado como atributos de request/session.
 * Este servicio es el ÚNICO que toca DAOs y lógica de negocio.
 */
public class EscenarioSeisServicio {
 
    // ── Constantes ────────────────────────────────────────────────────────
    public static final int   ID_ESCENARIO       = 6;
    public static final float MINIMO_APROBATORIO = 80.0f;
 
    // ── DAOs (única capa que los instancia fuera del controlador) ─────────
    private final ElementoBaseDAO      elementoDAO = new ElementoBaseDAO();
    private final RetoDAO              retoDAO     = new RetoDAO();
    private final PuntajeRetoDAO       puntajeDAO  = new PuntajeRetoDAO();
    private final ProgresoEscenarioDAO progresoDAO = new ProgresoEscenarioDAO();
 
    // ══════════════════════════════════════════════════════════════════════
    // CARGA INICIAL
    // ══════════════════════════════════════════════════════════════════════
 
    /**
     * Carga el escenario: establece el porcentaje de progreso previo del usuario.
     *
     * @param escenario objeto Escenario recuperado/creado desde sesión
     * @param usuario   usuario autenticado
     * @return ResultadoCarga con el porcentaje actualizado y el mensaje de la mascota
     */
    public ResultadoCarga cargar(Escenario escenario, Usuario usuario) {
        escenario.cargarEscenario();
        float pct = progresoDAO.obtenerPorcentaje(usuario.getIdUsuario(), ID_ESCENARIO);
        escenario.getProgreso().setPorcentajeAprendizaje(pct);
        String mensaje = escenario.guiaMascota();
        return new ResultadoCarga(pct, mensaje);
    }
 
    /**
     * Obtiene todos los elementos de la tabla periódica para mostrar en el JSP.
     */
    public List<ElementoBase> obtenerElementos() {
        return elementoDAO.obtenerTodos();
    }
 
    /**
     * Obtiene un elemento por número atómico. Retorna null si no existe.
     */
    public ElementoBase obtenerElementoPorZ(int z) {
        return elementoDAO.obtenerPorNumeroAtomico(z);
    }
 
    // ══════════════════════════════════════════════════════════════════════
    // SELECCIÓN DE ELEMENTOS (toggle A → B → reset)
    // ══════════════════════════════════════════════════════════════════════
 
    /**
     * Aplica la lógica de toggle para selección de elementos A y B.
     * Reglas:
     *  - Clic en A existente → deselecciona A; si había B, lo promueve a A.
     *  - Clic en B existente → deselecciona B.
     *  - Sin A → asigna como A.
     *  - Hay A pero no B → asigna como B.
     *  - Hay A y B → reemplaza: nuevo A, B vacío.
     *
     * @param z    número atómico del elemento clicado
     * @param ebA  elemento A actual (puede ser null)
     * @param ebB  elemento B actual (puede ser null)
     * @return ResultadoSeleccion con los nuevos A, B y si se deben limpiar respuestas
     */
    public ResultadoSeleccion seleccionarElemento(int z,
                                                   ElementoBase ebA,
                                                   ElementoBase ebB) {
        ElementoBase elem = elementoDAO.obtenerPorNumeroAtomico(z);
        if (elem == null) {
            // Z no encontrado en BD: no cambiar nada
            return new ResultadoSeleccion(ebA, ebB, false);
        }
 
        // Clic en A ya seleccionado
        if (ebA != null && ebA.getNumeroAtomico() == z) {
            ElementoBase nuevoA = ebB; // promover B a A si existe
            return new ResultadoSeleccion(nuevoA, null, true);
        }
 
        // Clic en B ya seleccionado
        if (ebB != null && ebB.getNumeroAtomico() == z) {
            return new ResultadoSeleccion(ebA, null, true);
        }
 
        // Sin A → asignar A
        if (ebA == null) {
            return new ResultadoSeleccion(elem, ebB, false);
        }
 
        // Hay A, sin B → asignar B
        if (ebB == null) {
            return new ResultadoSeleccion(ebA, elem, false);
        }
 
        // Hay A y B → reset: nuevo A, sin B
        return new ResultadoSeleccion(elem, null, true);
    }
 
    // ══════════════════════════════════════════════════════════════════════
    // REINICIO
    // ══════════════════════════════════════════════════════════════════════
 
    /**
     * Reinicia el escenario: limpia el estado del objeto Escenario.
     * El controlador debe además limpiar los atributos de sesión correspondientes.
     */
    public void reiniciar(Escenario escenario) {
        escenario.reiniciarEscenario();
    }
 
    // ══════════════════════════════════════════════════════════════════════
    // MODO SIMULACIÓN (libre, sin persistencia de puntaje)
    // ══════════════════════════════════════════════════════════════════════
 
    /**
     * Comprueba las 3 comparaciones en modo simulación libre.
     * No persiste puntaje ni progreso.
     *
     * @return ResultadoSimulacion con bits de resultado y mensaje pedagógico
     */
    public ResultadoSimulacion comprobarSimulacion(ElementoBase ebA,
                                                    ElementoBase ebB,
                                                    String rRadio,
                                                    String rIoniz,
                                                    String rElectr) {
        if (ebA == null || ebB == null) {
            return new ResultadoSimulacion("000",
                "Selecciona dos elementos de la tabla periódica para comparar.");
        }
 
        boolean okR = evaluarPropiedad(ebA, ebB, "radio",  rRadio);
        boolean okI = evaluarPropiedad(ebA, ebB, "ioniz",  rIoniz);
        boolean okE = evaluarPropiedad(ebA, ebB, "electr", rElectr);
 
        String bits    = (okR?"1":"0") + (okI?"1":"0") + (okE?"1":"0");
        String mensaje = construirMensajeBits(bits);
 
        return new ResultadoSimulacion(bits, mensaje);
    }
 
    // ══════════════════════════════════════════════════════════════════════
    // MODO EVALUACIÓN
    // ══════════════════════════════════════════════════════════════════════
 
    /**
     * Inicia la evaluación: activa el modo evaluación en el escenario
     * y genera el primer reto.
     */
    public void iniciarEvaluacion(Escenario escenario) {
        escenario.iniciarEvaluacion();
    }
 
    /**
     * Genera un nuevo reto con dos elementos aleatorios distintos.
     * Persiste el reto en BD.
     *
     * @param usuario usuario autenticado
     * @return ResultadoReto con el Reto creado, elemA, elemB; o null si no hay suficientes elementos
     */
    public ResultadoReto generarReto(Usuario usuario) {
        List<ElementoBase> todos = elementoDAO.obtenerTodos();
        if (todos == null || todos.size() < 2) return null;
 
        Collections.shuffle(todos);
        ElementoBase ebA = todos.get(0);
        ElementoBase ebB = null;
        for (ElementoBase e : todos) {
            if (e.getNumeroAtomico() != ebA.getNumeroAtomico()) {
                ebB = e;
                break;
            }
        }
        if (ebB == null) return null;
 
        Reto reto = new Reto();
        reto.setIdUsuario(usuario.getIdUsuario());
        reto.setIdEscenario(ID_ESCENARIO);
        reto.generarReto(ebA, ebA.getNumeroAtomico(), 0, ebA.getNumeroAtomico());
        reto.setDescripcion(
            "Compara las propiedades periódicas de:\n"
            + "A = " + ebA.getNombre() + " (Z=" + ebA.getNumeroAtomico() + ")\n"
            + "B = " + ebB.getNombre() + " (Z=" + ebB.getNumeroAtomico() + ")\n"
            + "Indica cuál tiene mayor: radio atómico, energía de ionización y electronegatividad.");
 
        int idReto = retoDAO.insertar(reto);
        reto.setIdReto(idReto);
 
        return new ResultadoReto(reto, ebA, ebB, null, false);
    }
 
    /**
     * Comprueba las 3 comparaciones en modo evaluación.
     * Solo aprueba si las 3 son correctas. Persiste puntaje y progreso.
     *
     * @return ResultadoComprobacion con todo el estado resultante
     */
    public ResultadoComprobacion comprobar(Escenario escenario,
                                            Reto retoActual,
                                            ElementoBase ebA,
                                            ElementoBase ebB,
                                            String rRadio,
                                            String rIoniz,
                                            String rElectr,
                                            Usuario usuario) {
        if (retoActual == null || ebA == null || ebB == null) {
            return new ResultadoComprobacion(
                false, escenario.getProgreso().getPorcentajeAprendizaje(),
                "000", "No hay un reto activo. Presiona 'Iniciar Evaluación'.",
                false, false, 0);
        }
 
        boolean okR = evaluarPropiedad(ebA, ebB, "radio",  rRadio);
        boolean okI = evaluarPropiedad(ebA, ebB, "ioniz",  rIoniz);
        boolean okE = evaluarPropiedad(ebA, ebB, "electr", rElectr);
        boolean correcto = okR && okI && okE;
 
        String bits = (okR?"1":"0") + (okI?"1":"0") + (okE?"1":"0");
 
        retoActual.registrarIntento();
        int intento = retoActual.getIntentos();
 
        // Persistir intento
        PuntajeReto pr = new PuntajeReto(retoActual, intento, correcto);
        puntajeDAO.insertar(retoActual.getIdReto(), intento, pr.getPuntaje(), correcto);
 
        if (correcto) retoActual.setCompletado(true);
        retoDAO.actualizar(retoActual);
 
        // Recalcular progreso
        float porcentaje = puntajeDAO.calcularPorcentajeAprendizaje(
                usuario.getIdUsuario(), ID_ESCENARIO);
        progresoDAO.guardar(usuario.getIdUsuario(), ID_ESCENARIO, porcentaje);
        escenario.getProgreso().setPorcentajeAprendizaje(porcentaje);
 
        // Construir mensaje
        String mensaje;
        if (correcto) {
            mensaje = "¡Excelente! Acertaste las 3 comparaciones en el intento "
                    + intento + ".\n" + construirExplicacion(ebA, ebB);
        } else if (retoActual.agotadoIntentos()) {
            mensaje = "Agotaste los 3 intentos.\n"
                    + construirMensajeBits(bits) + "\n\n"
                    + construirExplicacion(ebA, ebB)
                    + "\nHe generado un nuevo reto.";
        } else {
            int restantes = Reto.MAX_INTENTOS - intento;
            mensaje = "No acertaste todas las comparaciones.\n"
                    + construirMensajeBits(bits)
                    + "\nTe quedan " + restantes + " intento(s).";
        }
 
        boolean habilitarContinuar = porcentaje >= MINIMO_APROBATORIO;
        boolean generarNuevoReto   = correcto || retoActual.agotadoIntentos();
 
        return new ResultadoComprobacion(
            correcto, porcentaje, bits, mensaje,
            habilitarContinuar, generarNuevoReto, intento);
    }
 
    /**
     * Finaliza la evaluación: desactiva modo evaluación en el escenario.
     *
     * @return Mensaje informativo del porcentaje alcanzado.
     */
    public String finalizar(Escenario escenario) {
        escenario.setModoEvaluacion(false);
        float pct = escenario.getProgreso().getPorcentajeAprendizaje();
        return "Evaluación finalizada. Tu porcentaje: " + Math.round(pct) + "%. "
             + (pct >= MINIMO_APROBATORIO
                ? "¡Superaste el escenario!"
                : "Sigue practicando para alcanzar el 80%.");
    }
 
    /**
     * Verifica si el porcentaje actual es suficiente para continuar.
     */
    public boolean puedeSuperar(Escenario escenario) {
        return escenario.getProgreso().getPorcentajeAprendizaje() >= MINIMO_APROBATORIO;
    }
 
    /**
     * Marca el escenario como superado.
     */
    public void superar(Escenario escenario) {
        escenario.superarEscenario();
    }
 
    /**
     * Prepara la salida del escenario (sin evaluación).
     */
    public void salir(Escenario escenario) {
        escenario.salirEscenario();
    }
 
    // ══════════════════════════════════════════════════════════════════════
    // LÓGICA INTERNA DE EVALUACIÓN
    // ══════════════════════════════════════════════════════════════════════
 
    /**
     * Evalúa si la respuesta del usuario es correcta para una propiedad.
     *
     * @param propiedad "radio" | "ioniz" | "electr"
     * @param resp      "A" o "B"
     */
    private boolean evaluarPropiedad(ElementoBase ebA, ElementoBase ebB,
                                      String propiedad, String resp) {
        if (resp == null || resp.isEmpty()) return false;
        double valA, valB;
        switch (propiedad) {
            case "radio":  valA = ebA.getRadioAtomico();       valB = ebB.getRadioAtomico();       break;
            case "ioniz":  valA = ebA.getEnergiaIonizacion();  valB = ebB.getEnergiaIonizacion();  break;
            case "electr": valA = ebA.getElectronegatividad(); valB = ebB.getElectronegatividad(); break;
            default: return false;
        }
        // Empate: cualquier respuesta es válida
        if (valA == valB) return true;
        return resp.equals(valA > valB ? "A" : "B");
    }
 
    /**
     * Construye mensaje pedagógico a partir de los bits de resultado.
     */
    private String construirMensajeBits(String bits) {
        StringBuilder sb = new StringBuilder();
        sb.append(bits.charAt(0)=='1' ? "✅ Radio atómico: correcto.\n"         : "❌ Radio atómico: incorrecto.\n");
        sb.append(bits.charAt(1)=='1' ? "✅ Energía de ionización: correcto.\n" : "❌ Energía de ionización: incorrecto.\n");
        sb.append(bits.charAt(2)=='1' ? "✅ Electronegatividad: correcto."      : "❌ Electronegatividad: incorrecto.");
        return sb.toString();
    }
 
    /**
     * Construye la explicación pedagógica con los valores reales de cada propiedad.
     */
    private String construirExplicacion(ElementoBase ebA, ElementoBase ebB) {
        String mayorR = ebA.getRadioAtomico()       >= ebB.getRadioAtomico()       ? ebA.getNombre() : ebB.getNombre();
        String mayorI = ebA.getEnergiaIonizacion()  >= ebB.getEnergiaIonizacion()  ? ebA.getNombre() : ebB.getNombre();
        String mayorE = ebA.getElectronegatividad() >= ebB.getElectronegatividad() ? ebA.getNombre() : ebB.getNombre();
        return "📏 Mayor radio atómico: "           + mayorR
             + "\n⚡ Mayor energía de ionización: " + mayorI
             + "\n🔗 Mayor electronegatividad: "    + mayorE;
    }
 
    // ══════════════════════════════════════════════════════════════════════
    // DTOs DE RETORNO
    // Clases internas que el controlador usa para publicar datos al JSP.
    // Así el controlador nunca accede directamente a DAOs ni a lógica.
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
 
    /** Resultado de la selección toggle de un elemento. */
    public static class ResultadoSeleccion {
        public final ElementoBase nuevoA;
        public final ElementoBase nuevoB;
        /** true si se deben limpiar las respuestas previas */
        public final boolean limpiarRespuestas;
        public ResultadoSeleccion(ElementoBase nuevoA, ElementoBase nuevoB, boolean limpiarRespuestas) {
            this.nuevoA           = nuevoA;
            this.nuevoB           = nuevoB;
            this.limpiarRespuestas = limpiarRespuestas;
        }
    }
 
    /** Resultado de comprobar en modo simulación libre. */
    public static class ResultadoSimulacion {
        /** String de 3 bits: '1'=correcto, '0'=incorrecto. Ej: "101" */
        public final String bits;
        public final String mensajeMascota;
        public ResultadoSimulacion(String bits, String mensajeMascota) {
            this.bits           = bits;
            this.mensajeMascota = mensajeMascota;
        }
    }
 
    /** Resultado de generar un nuevo reto de evaluación. */
    public static class ResultadoReto {
        public final Reto         reto;
        public final ElementoBase ebA;
        public final ElementoBase ebB;
        public final String       mensaje;
        public final boolean      error;
        public ResultadoReto(Reto reto, ElementoBase ebA, ElementoBase ebB,
                             String mensaje, boolean error) {
            this.reto    = reto;
            this.ebA     = ebA;
            this.ebB     = ebB;
            this.mensaje = mensaje;
            this.error   = error;
        }
    }
 
    /** Resultado de comprobar en modo evaluación. */
    public static class ResultadoComprobacion {
        public final boolean correcto;
        public final float   porcentaje;
        /** String de 3 bits: "111", "010", etc. */
        public final String  bitResultado;
        public final String  mensajeMascota;
        public final boolean habilitarContinuar;
        public final boolean generarNuevoReto;
        public final int     intentoUsado;
        public ResultadoComprobacion(boolean correcto, float porcentaje,
                                      String bitResultado, String mensajeMascota,
                                      boolean habilitarContinuar,
                                      boolean generarNuevoReto, int intentoUsado) {
            this.correcto           = correcto;
            this.porcentaje         = porcentaje;
            this.bitResultado       = bitResultado;
            this.mensajeMascota     = mensajeMascota;
            this.habilitarContinuar = habilitarContinuar;
            this.generarNuevoReto   = generarNuevoReto;
            this.intentoUsado       = intentoUsado;
        }
    }
}