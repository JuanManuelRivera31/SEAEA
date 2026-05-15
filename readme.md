
# SEAEA — Sistema Educativo de Aprendizaje de Estructura Atómica

Proyecto educativo desarrollado en **Java con NetBeans 24**, servidor **Apache Tomcat** y base de datos **MySQL**. Sin Maven (gestión manual de librerías).

---

## Descripción

SEAEA es una aplicación web educativa que enseña estructura atómica a través de 6 escenarios interactivos progresivos. Cada escenario permite al estudiante manipular partículas subatómicas, recibir retroalimentación inmediata y ser evaluado con un sistema de ponderación de porcentaje de aprendizaje.

---

## Tecnologías

| Componente       | Tecnología                        |
|-----------------|-----------------------------------|
| Lenguaje        | Java 17+                          |
| IDE             | NetBeans 24                       |
| Servidor        | Apache Tomcat 10+                 |
| Base de datos   | MySQL 8                           |
| Vista           | JSP + HTML5 + CSS3 + JavaScript   |
| Fuentes         | Google Fonts (Baloo 2, Nunito)    |
| Build           | Sin Maven (Ant / manual)          |

---

## Arquitectura MVC

El proyecto implementa arquitectura **MVC estricta por capas**:

```
[Vista JSP]
    ↓  acción del usuario (form POST/GET)
[Controlador]          → controlador/EscenarioXControlador.java
    ↓  delega lógica
[Lógica / Servicio]    → logica/EscenarioXServicio.java
    ↓  consulta datos
[DAO]                  → dao/ElementoBaseDAO.java, RetoDAO.java, etc.
    ↓  ejecuta SQL
[Conexión]             → conexion/DBConexion.java
    ↓  retorna ResultSet
[Modelo]               → modelo/Elemento.java, Reto.java, etc.
    ↑  sube hasta JSP
```

### Responsabilidades por capa

| Capa          | Responsabilidad                                                        |
|--------------|------------------------------------------------------------------------|
| **Vista**    | Renderizar UI, capturar inputs del usuario, mostrar resultados         |
| **Controlador** | Leer parámetros, llamar al servicio, publicar en request/sesión, forward al JSP |
| **Lógica**   | Reglas de negocio: ponderación, validación, generación de retos       |
| **DAO**      | Queries SQL (SELECT, INSERT, UPDATE). Sin lógica de negocio           |
| **Conexión** | Pool/gestión de conexión a MySQL                                       |
| **Modelo**   | Entidades del dominio (Elemento, Reto, Escenario, Usuario, etc.)      |

---

## Estructura del proyecto

```
SEAEA/
├── Web Pages/
│   ├── WEB-INF/
│   │   └── web.xml
│   ├── escenario1/
│   │   └── escenario1.jsp
│   ├── escenario2/
│   │   └── escenario2.jsp
│   ├── escenario3/
│   │   └── escenario3.jsp
│   ├── escenario4/
│   │   └── escenario4.jsp
│   ├── escenario5/
│   │   └── escenario5.jsp
│   ├── escenario6/
│   │   └── escenario6.jsp
│   ├── index.html
│   ├── login.jsp
│   └── menu.jsp
│
└── Source Packages/
    ├── conexion/
    │   └── DBConexion.java
    ├── controlador/
    │   ├── EscenarioUnoControlador.java
    │   ├── EscenarioDosControlador.java
    │   ├── EscenarioTresControlador.java
    │   ├── EscenarioCuatroControlador.java
    │   ├── EscenarioCincoControlador.java
    │   ├── EscenarioSeisControlador.java
    │   ├── LoginControlador.java
    │   └── MenuControlador.java
    ├── dao/
    │   ├── ElementoBaseDAO.java
    │   ├── IsotopoDAO.java
    │   ├── ProgresoEscenarioDAO.java
    │   ├── PuntajeRetoDAO.java
    │   ├── RetoDAO.java
    │   └── UsuarioDAO.java
    ├── logica/
    │   ├── EscenarioUnoServicio.java
    │   ├── EscenarioDosServicio.java
    │   ├── EscenarioTresServicio.java
    │   ├── EscenarioCuatroServicio.java
    │   ├── EscenarioCincoServicio.java
    │   └── EscenarioSeisServicio.java
    └── modelo/
        ├── Elemento.java
        ├── ElementoBase.java
        ├── Escenario.java
        ├── Isotopo.java
        ├── ProgresoEscenario.java
        ├── PuntajeReto.java
        ├── Reto.java
        └── Usuario.java
```

---

## Escenarios educativos

| # | Nombre                        | Concepto principal                              |
|---|-------------------------------|-------------------------------------------------|
| 1 | Estructura Atómica Básica     | Partículas subatómicas (p, n, e)               |
| 2 | Número y Núcleo Atómico       | Número atómico Z, número másico A              |
| 3 | Configura tu Átomo Objetivo   | Identificar elemento por Z y A                 |
| 4 | Configura tu Isótopo          | Isótopos, neutrones variables, abundancia      |
| 5 | Configuración Electrónica     | Orbitales, subniveles, regla de Aufbau         |
| 6 | Propiedades Periódicas        | Radio atómico, electronegatividad, E. ionización|

---

## Sistema de evaluación

Cada escenario implementa el mismo sistema de ponderación por sesión:

| Evento                        | Efecto en porcentaje |
|-------------------------------|---------------------|
| Reto acertado en intento 1    | +20%                |
| Reto acertado en intento 2    | +13%                |
| Reto acertado en intento 3    | +7%                 |
| Intento fallido (sin agotar)  | -5%                 |
| Reto agotado (3 fallos)       | -10%                |

**Condiciones para superar un escenario:**
- Porcentaje de aprendizaje ≥ 80%
- Mínimo 3 retos acertados
- Timer por reto: 90 segundos
- Máximo 3 intentos por reto

---

## Base de datos MySQL

Tablas principales:

```sql
usuario           -- Datos del estudiante
elemento_base     -- Tabla periódica (Z, símbolo, nombre, masa, etc.)
isotopo           -- Isótopos por elemento (neutrones, abundancia, masa)
escenario         -- Definición de los 6 escenarios
reto              -- Retos generados por sesión
puntaje_reto      -- Resultado de cada intento
progreso_escenario -- Porcentaje acumulado por usuario/escenario
```

---

## Configuración

### 1. Base de datos

```sql
CREATE DATABASE seaea;
-- Ejecutar script SQL de creación de tablas e inserción de datos
```

### 2. Conexión (`DBConexion.java`)

```java
private static final String URL  = "jdbc:mysql://localhost:3306/seaea";
private static final String USER = "root";
private static final String PASS = "tu_password";
```

### 3. Tomcat

- Desplegar el proyecto como aplicación web en Tomcat 10+
- Agregar `mysql-connector-j-x.x.x.jar` en `WEB-INF/lib/`
- Acceder en: `http://localhost:8090/SEAEA/`

---

## Pruebas

El proyecto está diseñado para soportar:

- **Pruebas de caja blanca** por capa (Controlador, Servicio, DAO, Conexión)
- **Pruebas de tiempos** de respuesta por capa
- **Pruebas de integración** del flujo completo   

---

## Autor

Proyecto académico — Universidad / Ingeniería de Sistemas  
Desarrollado con NetBeans 24 + Apache Tomcat + MySQL
