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

import java.util.Collections;
import java.util.List;

/**
 * EscenarioSeisServicio
 * ─────────────────────────────────────────────────────────────────────────
 * Capa de LÓGICA de negocio para el Escenario 6
 * "Propiedades Periódicas de los Elementos".
 *
 * Responsabilidades:
 *  - Gestionar la selección del par de elementos A y B (toggle).
 *  - Evaluar si la respuesta del usuario es correcta para cada propiedad
 *    (radio atómico, energía de ionización, electronegatividad).
 *  - Generar retos con dos elementos aleatorios.
 *  - Comprobar las 3 comparaciones: todas deben acertarse para aprobar.
 *  - Construir mensajes de retroalimentación pedagógica.
 */
public class EscenarioSeisServicio {

    private static final int   ID_ESCENARIO       = 6;
    public  static final float MINIMO_APROBATORIO = 80.0f;

    private final ElementoBaseDAO      elementoDAO = new ElementoBaseDAO();
    private final RetoDAO              retoDAO     = new RetoDAO();
    private final PuntajeRetoDAO       puntajeDAO  = new PuntajeRetoDAO();
    private final ProgresoEscenarioDAO progresoDAO = new ProgresoEscenarioDAO();

    // ══════════════════════════════════════════════════════════════════════
    // COMPARACIONES
    // ══════════════════════════════════════════════════════════════════════

    /**
     * Evalúa si la respuesta del usuario es correcta para una propiedad.
     *
     * @param ebA      elemento A
     * @param ebB      elemento B
     * @param propiedad "radio" | "ioniz" | "electr"
     * @param resp      "A" o "B"
     * @return true si la respuesta es correcta
     */
    public boolean evaluarPropiedad(ElementoBase ebA, ElementoBase ebB,
                                     String propiedad, String resp) {
        if (resp == null || resp.isEmpty()) return false;
        double valA, valB;
        switch (propiedad) {
            case "radio":  valA = ebA.getRadioAtomico();       valB = ebB.getRadioAtomico();       break;
            case "ioniz":  valA = ebA.getEnergiaIonizacion();  valB = ebB.getEnergiaIonizacion();  break;
            case "electr": valA = ebA.getElectronegatividad(); valB = ebB.getElectronegatividad(); break;
            default: return false;
        }
        if (valA == valB) return true; // empate: cualquier respuesta válida
        return resp.equals(valA > valB ? "A" : "B");
    }

    /**
     * Comprueba las 3 propiedades en modo simulación (sin persistir).
     * Retorna un string de 3 bits: "111" = todo correcto, "010" = solo ionización.
     */
    public String comprobarSimulacion(ElementoBase ebA, ElementoBase ebB,
                                       String rRadio, String rIoniz, String rElectr) {
        boolean okR = evaluarPropiedad(ebA, ebB, "radio",  rRadio);
        boolean okI = evaluarPropiedad(ebA, ebB, "ioniz",  rIoniz);
        boolean okE = evaluarPropiedad(ebA, ebB, "electr", rElectr);
        return (okR?"1":"0") + (okI?"1":"0") + (okE?"1":"0");
    }

    /**
     * Construye el mensaje de retroalimentación para la simulación.
     */
    public String mensajeSimulacion(String bitResult) {
        StringBuilder sb = new StringBuilder();
        sb.append(bitResult.charAt(0)=='1' ? "✅ Radio atómico: correcto.\n"    : "❌ Radio atómico: incorrecto.\n");
        sb.append(bitResult.charAt(1)=='1' ? "✅ Energía de ionización: correcto.\n" : "❌ Energía de ionización: incorrecto.\n");
        sb.append(bitResult.charAt(2)=='1' ? "✅ Electronegatividad: correcto." : "❌ Electronegatividad: incorrecto.");
        return sb.toString();
    }

    /**
     * Construye la explicación pedagógica con los valores reales.
     */
    public String construirExplicacion(ElementoBase ebA, ElementoBase ebB) {
        String mayorR = ebA.getRadioAtomico()       >= ebB.getRadioAtomico()       ? ebA.getNombre() : ebB.getNombre();
        String mayorI = ebA.getEnergiaIonizacion()  >= ebB.getEnergiaIonizacion()  ? ebA.getNombre() : ebB.getNombre();
        String mayorE = ebA.getElectronegatividad() >= ebB.getElectronegatividad() ? ebA.getNombre() : ebB.getNombre();
        return "📏 Mayor radio atómico: " + mayorR
             + "\n⚡ Mayor energía de ionización: " + mayorI
             + "\n🔗 Mayor electronegatividad: " + mayorE;
    }

    // ══════════════════════════════════════════════════════════════════════
    // EVALUACIÓN
    // ══════════════════════════════════════════════════════════════════════

    /**
     * Genera un reto con dos elementos aleatorios distintos.
     */
    public ResultadoReto generarReto(Usuario usuario) {
        List<ElementoBase> todos = elementoDAO.obtenerTodos();
        if (todos.size() < 2) return null;

        Collections.shuffle(todos);
        ElementoBase ebA = todos.get(0);
        ElementoBase ebB = null;
        for (ElementoBase e : todos) {
            if (e.getNumeroAtomico() != ebA.getNumeroAtomico()) { ebB = e; break; }
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
     * Solo aprueba si las 3 son correctas.
     */
    public ResultadoComprobacion comprobar(Escenario escenario,
                                           Reto retoActual,
                                           ElementoBase ebA,
                                           ElementoBase ebB,
                                           String rRadio, String rIoniz, String rElectr,
                                           Usuario usuario) {
        boolean okR = evaluarPropiedad(ebA, ebB, "radio",  rRadio);
        boolean okI = evaluarPropiedad(ebA, ebB, "ioniz",  rIoniz);
        boolean okE = evaluarPropiedad(ebA, ebB, "electr", rElectr);
        boolean correcto = okR && okI && okE;

        String bitResult = (okR?"1":"0") + (okI?"1":"0") + (okE?"1":"0");

        retoActual.registrarIntento();
        int intento = retoActual.getIntentos();

        PuntajeReto pr = new PuntajeReto(retoActual, intento, correcto);
        puntajeDAO.insertar(retoActual.getIdReto(), intento, pr.getPuntaje(), correcto);

        if (correcto) retoActual.setCompletado(true);
        retoDAO.actualizar(retoActual);

        float porcentaje = puntajeDAO.calcularPorcentajeAprendizaje(
                usuario.getIdUsuario(), ID_ESCENARIO);
        progresoDAO.guardar(usuario.getIdUsuario(), ID_ESCENARIO, porcentaje);
        escenario.getProgreso().setPorcentajeAprendizaje(porcentaje);

        String mensaje;
        if (correcto) {
            mensaje = "¡Excelente! Acertaste las 3 comparaciones en el intento "
                + intento + ".\n" + construirExplicacion(ebA, ebB);
        } else if (retoActual.agotadoIntentos()) {
            mensaje = "Agotaste los 3 intentos.\n"
                + mensajeSimulacion(bitResult) + "\n\n"
                + construirExplicacion(ebA, ebB)
                + "\nHe generado un nuevo reto.";
        } else {
            int restantes = Reto.MAX_INTENTOS - intento;
            mensaje = "No acertaste todas las comparaciones.\n"
                + mensajeSimulacion(bitResult)
                + "\nTe quedan " + restantes + " intento(s).";
        }

        boolean habilitarContinuar = porcentaje >= MINIMO_APROBATORIO;
        boolean generarNuevoReto   = correcto || retoActual.agotadoIntentos();

        return new ResultadoComprobacion(
            correcto, porcentaje, bitResult, mensaje,
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

    public static class ResultadoComprobacion {
        public final boolean correcto;
        public final float   porcentaje;
        public final String  bitResultado;    // "111", "010", etc.
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