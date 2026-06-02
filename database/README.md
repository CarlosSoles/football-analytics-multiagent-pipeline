# Módulo de Base de Datos: `futbol_analytics`

Este directorio contiene el diseño fundamental de la infraestructura de datos para el ecosistema analítico de fútbol de alto rendimiento. El modelo ha sido implementado bajo un **Enfoque Multidimensional en Estrella (Star Schema)**, optimizado específicamente para procesos de Business Intelligence (OLAP) e ingesta automatizada de datos (ETL) mediante sistemas multiagente.

---

## 1. Arquitectura del Modelo en Estrella

A diferencia de un diseño transaccional tradicional (altamente normalizado), este modelo organiza la información separando estrictamente el **contexto de negocio** de las **métricas cuantitativas**. Esto reduce la complejidad de las consultas analíticas y maximiza el rendimiento al conectar el servidor MySQL con Power BI.

### A. Tablas de Dimensiones (El Contexto)
Almacenan los atributos descriptivos que se utilizarán para filtrar, agrupar y segmentar los reportes de rendimiento, salud y carga.

* **`dim_equipos`**: Representa los clubes integrados en el ecosistema (tanto datos locales de la Liga 1 de Perú como datasets internacionales de StatsBomb Open Data).
    * `id` (`INT AUTO_INCREMENT`): Identificador numérico clave.
    * `nombre_club` (`VARCHAR(100)`): Almacenamiento optimizado para texto de longitud variable.
    * `liga` (`VARCHAR(50)`) / `pais` (`VARCHAR(50)`): Atributos cualitativos vitales para la segmentación de datos en los tableros de control.
* **`dim_jugadores`**: Mapea el universo de futbolistas bajo análisis.
    * `id` (`INT AUTO_INCREMENT`): Identificador único por atleta.
    * `nombre_completo` (`VARCHAR(150)`), `posicion_tactica` (`VARCHAR(50)`), `pie_dominante` (`VARCHAR(20)`): Características cualitativas de perfil deportivo.
    * `edad` (`INT`): Atributo numérico estático útil para análisis demográficos.
    * `equipo_id` (`INT`): Llave foránea (FK) que amarra físicamente al jugador con su club actual.

### B. Tablas de Hechos (Las Métricas)
Ubicadas en el centro de la estrella, registran los eventos cuantitativos y las series temporales operacionales que el departamento deportivo necesita evaluar.

* **`fact_rendimiento_equipos`**: Centraliza el historial competitivo de los clubes.
    * Métricas como `goles_anotados`, `goles_recibidos` y `puntos_obtenidos` utilizan `INT` al tratarse de unidades discretas e indivisibles.
    * `porcentaje_posesion` utiliza `DECIMAL(5,2)` para preservar la exactitud matemática exacta en promedios y agregaciones avanzadas.
* **`fact_carga_fisica_simulada`**: Captura diariamente el desgaste físico acumulado del jugador (simulando telemetría de dispositivos GPS).
    * `fecha_registro` (`DATE`): Eje cronológico indispensable para construir análisis temporales de fatiga.
    * `minutos_acumulados`, `sprints_alta_intensidad` (`INT`): Contadores operacionales directos.
    * `distancia_recorrida_km` (`DECIMAL(5,2)`): Mide con alta precisión el volumen de desplazamiento del atleta.
* **`fact_gestion_salud`**: Controla el historial médico y la disponibilidad de la plantilla.
    * `tipo_lesion` (`VARCHAR(100)`): Clasificación diagnóstica.
    * `dias_de_baja_estimados` (`INT`): Variable cuantitativa para calcular el promedio de inactividad.
    * `alta_medica` (`TINYINT(1)` / `BOOLEAN`): Indicador binario (0: No disponible, 1: Disponible), diseñado para agilizar la creación de matrices de disponibilidad en Power BI.

---

## 2. Relaciones e Integridad Referencial

El modelo se rige bajo relaciones puras de **Uno a Muchos (1:N)**, donde todas las dimensiones intersectan y nutren a las tablas de hechos centrales:
* `dim_equipos` (1) ➡️ `fact_rendimiento_equipos` (N)
* `dim_jugadores` (1) ➡️ `fact_carga_fisica_simulada` (N)
* `dim_jugadores` (1) ➡️ `fact_gestion_salud` (N)

---

## 3. Justificación de Decisiones de Diseño Técnico

### Por qué usar Claves Primarias (`PRIMARY KEY`) Autonuméricas (`INT AUTO_INCREMENT`)
1.  **Inmutabilidad e Identidad**: Aseguran un identificador único absoluto por registro. Evitan colisiones de datos si existen futbolistas homónimos en ligas diferentes.
2.  **Rendimiento del Motor (Indexación)**: MySQL indexa de forma óptima claves de tipo entero. Operaciones de búsqueda, ordenamiento y cruce (`JOIN`) son exponencialmente más rápidas utilizando enteros que comparando cadenas de texto pesadas (como nombres de clubes o ligas).

### Por qué usar Claves Foráneas (`FOREIGN KEY`) y Restricciones `CASCADE`
1.  **Gobernanza y Calidad de Datos**: Garantizan la **Integridad Referencial**. Impiden que un pipeline o un error de raspado manual intente inyectar métricas físicas o de salud asociadas a un ID de jugador inexistente, bloqueando datos huérfanos que corromperían las estadísticas.
2.  **Automatización de Mantenimiento (`ON DELETE CASCADE / ON UPDATE CASCADE`)**: Si el ID de un club o jugador se actualiza en la tabla de dimensiones por reestructuración conceptual, el cambio se replica instantáneamente en las millones de filas de hechos. Si un registro maestro se elimina por error de depuración, el sistema limpia automáticamente su historial en cascada, evitando basura residual en el disco.

### Optimización Nativa para Inteligencia de Negocios (Power BI)
Al conectar este servidor MySQL local mediante DirectQuery u ODBC, Power BI leerá automáticamente las relaciones físicas definidas mediante las llaves foráneas. Esto reduce el esfuerzo en el modelado dentro de Power BI Desktop, autodetectando el flujo de filtros unidireccional desde las dimensiones (`dim_`) hacia los hechos (`fact_`), permitiendo que cualquier arrastre de filtros cualitativos actualice los velocímetros y alertas del Índice de Alerta de Fatiga (IAF) en tiempo real.