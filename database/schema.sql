-- ==============================================================================
-- SCRIPT DE DEFINICIÓN DE DATOS (DDL) - ECOSISTEMA ANALÍTICO "FUTBOL_ANALYTICS"
-- Modelo Multidimensional en Estrella (Star Schema) para Power BI
-- ==============================================================================

-- Creación e inicialización de la base de datos de manera idempotente
CREATE DATABASE IF NOT EXISTS futbol_analytics
CHARACTER SET utf8mb4 -- Soporta tildes, eñes y emojis de nombres de jugadores sin corromper los textos.
COLLATE utf8mb4_unicode_ci; -- Permite búsquedas insensibles a mayúsculas/minúsculas y ordena alfabéticamente siguiendo el estándar global de Unicode.

USE futbol_analytics;

-- ==============================================================================
-- 1. ELIMINACIÓN DE TABLAS EXISTENTES (Orden correcto por integridad referencial)
-- ==============================================================================

DROP TABLE IF EXISTS fact_gestion_salud;
DROP TABLE IF EXISTS fact_carga_fisica_simulada;
DROP TABLE IF EXISTS fact_rendimiento_equipos;
DROP TABLE IF EXISTS dim_jugadores;
DROP TABLE IF EXISTS dim_equipos;

-- ==============================================================================
-- 2. CREACIÓN DE TABLAS DE DIMENSIONES (Estructura jerárquica y descriptiva)
-- ==============================================================================

-- dim_equipos: Almacena información contextual de los clubes, ligas y países de procedencia.
-- Esencial para filtrar y agrupar métricas agregadas por club y competición.
CREATE TABLE dim_equipos (
    equipo_id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    nombre VARCHAR(100) NOT NULL COMMENT 'Nombre oficial del club de fútbol',
    liga VARCHAR(100) NOT NULL COMMENT 'Liga o competición en la que participa el club',
    pais VARCHAR(100) NOT NULL COMMENT 'País de origen del club',
    INDEX idx_equipos_liga (liga)
) ENGINE=InnoDB -- Activa el soporte real de llaves foráneas (FK) y bloqueo a nivel de fila para permitir cargas simultáneas de los agentes de IA.
DEFAULT CHARSET=utf8mb4 
COLLATE=utf8mb4_unicode_ci COMMENT='Dimensión que almacena la información descriptiva de los equipos de fútbol';

-- dim_jugadores: Contiene los datos demográficos, tácticos y físicos estables del jugador.
-- Se vincula a un equipo y sirve como eje analítico para la carga física y la salud.
CREATE TABLE dim_jugadores (
    jugador_id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    nombre_completo VARCHAR(150) NOT NULL COMMENT 'Nombre y apellidos del jugador',
    edad TINYINT UNSIGNED NOT NULL COMMENT 'Edad actual del jugador en años',
    posicion_tactica_principal VARCHAR(50) NOT NULL COMMENT 'Posición táctica principal en el campo de juego',
    pie_dominante VARCHAR(20) NOT NULL COMMENT 'Pie preferido del jugador (Derecho, Izquierdo, Ambidiestro)',
    equipo_id INT UNSIGNED NOT NULL COMMENT 'Relación con el equipo al que pertenece actualmente',
    CONSTRAINT fk_jugadores_equipos FOREIGN KEY (equipo_id)
        REFERENCES dim_equipos (equipo_id)
        ON DELETE CASCADE ON UPDATE CASCADE,
    INDEX idx_jugadores_equipo (equipo_id)
) ENGINE=InnoDB 
DEFAULT CHARSET=utf8mb4 
COLLATE=utf8mb4_unicode_ci COMMENT='Dimensión que contiene el perfil detallado de cada jugador y su equipo actual';

-- ==============================================================================
-- 3. CREACIÓN DE TABLAS DE HECHOS (Métricas cuantitativas y granulares)
-- ==============================================================================

-- fact_rendimiento_equipos: Registra los resultados de rendimiento colectivo e indicadores de juego por partido.
-- Alimenta el área clave de "Análisis por Equipo" y métricas tácticas/competitivas en tableros de Power BI.
CREATE TABLE fact_rendimiento_equipos (
    rendimiento_equipo_id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    partido_id INT UNSIGNED NOT NULL COMMENT 'Identificador único del partido analizado',
    equipo_id INT UNSIGNED NOT NULL COMMENT 'Relación con el equipo evaluado en el partido',
    goles_anotados TINYINT UNSIGNED NOT NULL COMMENT 'Cantidad de goles marcados por el equipo en el partido',
    goles_recibidos TINYINT UNSIGNED NOT NULL COMMENT 'Cantidad de goles encajados por el equipo en el partido',
    puntos_obtenidos TINYINT UNSIGNED NOT NULL COMMENT 'Puntos obtenidos en el partido (ej. 3 por victoria, 1 por empate, 0 por derrota)',
    porcentaje_posesion DECIMAL(5, 2) NOT NULL COMMENT 'Porcentaje de posesión del balón durante el partido',
    CONSTRAINT fk_rendimiento_equipos FOREIGN KEY (equipo_id)
        REFERENCES dim_equipos (equipo_id)
        ON DELETE CASCADE ON UPDATE CASCADE,
    INDEX idx_rendimiento_equipo (equipo_id),
    INDEX idx_rendimiento_partido (partido_id)
) ENGINE=InnoDB 
DEFAULT CHARSET=utf8mb4 
COLLATE=utf8mb4_unicode_ci COMMENT='Hechos de rendimiento táctico y deportivo colectivo por cada partido jugado';

-- fact_carga_fisica_simulada: Registra métricas de volumen e intensidad física acumuladas por sesión/fecha.
-- Alimenta el área clave de "Preparación Física" para monitorear cargas de trabajo y prevenir sobreentrenamiento.
CREATE TABLE fact_carga_fisica_simulada (
    carga_fisica_id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    jugador_id INT UNSIGNED NOT NULL COMMENT 'Relación con el jugador evaluado',
    fecha_registro DATE NOT NULL COMMENT 'Fecha de registro de la sesión de entrenamiento o partido',
    minutos_acumulados INT UNSIGNED NOT NULL COMMENT 'Minutos totales de actividad física registrados',
    distancia_recorrida_km DECIMAL(5, 2) NOT NULL COMMENT 'Distancia total recorrida en kilómetros',
    sprints_alta_intensidad INT UNSIGNED NOT NULL COMMENT 'Cantidad de aceleraciones a alta intensidad realizadas',
    CONSTRAINT fk_carga_fisica_jugadores FOREIGN KEY (jugador_id)
        REFERENCES dim_jugadores (jugador_id)
        ON DELETE CASCADE ON UPDATE CASCADE,
    INDEX idx_carga_jugador (jugador_id),
    INDEX idx_carga_fecha (fecha_registro)
) ENGINE=InnoDB
DEFAULT CHARSET=utf8mb4 
COLLATE=utf8mb4_unicode_ci COMMENT='Hechos de volumen y carga física e intensidad de los jugadores por fecha';

-- fact_gestion_salud: Monitorea las lesiones, periodos de inactividad médica y estados de disponibilidad.
-- Alimenta el área clave de "Gestión de Salud" para el análisis de disponibilidad de plantilla e historial clínico.
CREATE TABLE fact_gestion_salud (
    gestion_salud_id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    jugador_id INT UNSIGNED NOT NULL COMMENT 'Relación con el jugador bajo seguimiento médico',
    fecha_inicio_baja DATE NOT NULL COMMENT 'Fecha en la que el jugador es retirado de la actividad por lesión/enfermedad',
    tipo_lesion VARCHAR(100) NOT NULL COMMENT 'Diagnóstico o zona corporal afectada por la lesión',
    dias_de_baja_estimados INT UNSIGNED NOT NULL COMMENT 'Duración estimada de la recuperación en días',
    alta_medica TINYINT(1) NOT NULL DEFAULT 0 COMMENT 'Indicador de estado: 0 = En recuperación, 1 = Alta médica otorgada',
    CONSTRAINT fk_gestion_salud_jugadores FOREIGN KEY (jugador_id)
        REFERENCES dim_jugadores (jugador_id)
        ON DELETE CASCADE ON UPDATE CASCADE,
    INDEX idx_salud_jugador (jugador_id),
    INDEX idx_salud_fecha_baja (fecha_inicio_baja)
) ENGINE=InnoDB 
DEFAULT CHARSET=utf8mb4 
COLLATE=utf8mb4_unicode_ci COMMENT='Hechos de eventos médicos, lesiones y periodos de incapacidad de los jugadores';
