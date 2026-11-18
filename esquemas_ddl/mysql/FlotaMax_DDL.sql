-- creaer db para FlotaMax
CREATE DATABASE IF NOT EXISTS flotamax_db CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
USE flotamax_db;

-- 0. Catalogo de países
CREATE TABLE IF NOT EXISTS catalogo_pais (
    codigo_iso VARCHAR(2) PRIMARY KEY,
    nombre_pais VARCHAR(50) NOT NULL UNIQUE
) ;

-- 1. Clientes
CREATE TABLE IF NOT EXISTS clientes_flota (
    cliente_id INT PRIMARY KEY,
    nombre_cliente VARCHAR(150) NOT NULL,
    tipo_doc ENUM('Identidad', 'Pasaporte', 'RTN') NOT NULL,
    documento VARCHAR(25) NOT NULL,
    telefono_contacto VARCHAR(25),
    email VARCHAR(120),
    pais VARCHAR(50) NOT NULL,
    licencia_valida BOOLEAN NOT NULL,
    es_corporativo BOOLEAN NOT NULL DEFAULT FALSE,
    fecha_alta DATETIME NOT NULL,
    -- Columnas tecnicas 
    version_registro INT NOT NULL DEFAULT 1,
    fecha_ultima_mod_utc DATETIME(6) NOT NULL,
    eliminado BOOLEAN NOT NULL DEFAULT FALSE,
    CONSTRAINT uk_cliente_doc UNIQUE (tipo_doc, documento),
    CONSTRAINT fk_cliente_pais FOREIGN KEY (pais) REFERENCES catalogo_pais(nombre_pais)
) ;


-- 2. Sucursales (centros_operacion)
CREATE TABLE IF NOT EXISTS centros_operacion (
    centro_id INT PRIMARY KEY,
    nombre_centro VARCHAR(120) NOT NULL,
    municipio VARCHAR(100) NOT NULL,
    pais_operacion VARCHAR(50) NOT NULL,
    categoria ENUM('Aeropuerto', 'Urbana', 'Patio', 'Taller') NOT NULL,
    capacidad_maxima INT NOT NULL,
    -- Columnas tecnicas 
    version_registro INT NOT NULL DEFAULT 1,
    fecha_ultima_mod_utc DATETIME(6) NOT NULL,
    eliminado BOOLEAN NOT NULL DEFAULT FALSE,
    CONSTRAINT chk_capacidad_centro CHECK (capacidad_maxima > 0),
    CONSTRAINT fk_centro_pais FOREIGN KEY (pais_operacion) REFERENCES catalogo_pais(nombre_pais)
) ;


-- 3. Modelos de vehiculo (tipos_vehiculo)
CREATE TABLE IF NOT EXISTS tipos_vehiculo (
    tipo_id INT PRIMARY KEY,
    fabricante VARCHAR(50) NOT NULL,
    linea VARCHAR(50) NOT NULL,
    segmento ENUM('Económico', 'Sedán', 'SUV', 'Pickup', 'Van') NOT NULL,
    pasajeros TINYINT NOT NULL,
    tarifa_dia_usd DECIMAL(10,2) NOT NULL,
    -- Columnas técnicas
    version_registro INT NOT NULL DEFAULT 1,
    fecha_ultima_mod_utc DATETIME(6) NOT NULL,
    eliminado BOOLEAN NOT NULL DEFAULT FALSE,
    CONSTRAINT uk_fabricante_linea UNIQUE (fabricante, linea),
    CONSTRAINT chk_pasajeros CHECK (pasajeros > 0),
    CONSTRAINT chk_tarifa_usd CHECK (tarifa_dia_usd >= 0)
) ;


-- 4. Vehiculos (Unidades)
CREATE TABLE IF NOT EXISTS unidades (
    unidad_id INT PRIMARY KEY,
    placa VARCHAR(12) NOT NULL UNIQUE,
    vin CHAR(17) NOT NULL UNIQUE,
    tipo_id INT NOT NULL,
    anio_fabricacion YEAR NOT NULL,
    odometro_km INT NOT NULL,
    es_automatico BOOLEAN NOT NULL,
    estado ENUM('Disponible', 'Rentado', 'Mantenimiento', 'Retenido', 'Baja') NOT NULL,
    -- Columnas técnicas
    version_registro INT NOT NULL DEFAULT 1,
    fecha_ultima_mod_utc DATETIME(6) NOT NULL,
    eliminado BOOLEAN NOT NULL DEFAULT FALSE,
    CONSTRAINT chk_placa_formato CHECK (placa REGEXP '^[A-Z]{3}-[0-9]{4}$'),
    CONSTRAINT chk_anio_vehiculo CHECK (anio_fabricacion >= 2000),
    CONSTRAINT chk_odometro CHECK (odometro_km >= 0),
    CONSTRAINT fk_unidad_tipo FOREIGN KEY (tipo_id) REFERENCES tipos_vehiculo(tipo_id)
) ;


-- 5. Ubicacion actual de la flota (posicion_flota)
CREATE TABLE IF NOT EXISTS posicion_flota (
    posicion_id INT PRIMARY KEY,
    unidad_id INT NOT NULL UNIQUE,
    centro_id INT NOT NULL,
    combustible ENUM('Vacío','1/4', '1/2', '3/4', 'Lleno') NOT NULL,
    fecha_modificacion DATETIME NOT NULL,
    -- Columnas técnicas
    version_registro INT NOT NULL DEFAULT 1,
    fecha_ultima_mod_utc DATETIME(6) NOT NULL,
    eliminado BOOLEAN NOT NULL DEFAULT FALSE,
    CONSTRAINT fk_pos_unidad FOREIGN KEY (unidad_id) REFERENCES unidades(unidad_id),
    CONSTRAINT fk_pos_centro FOREIGN KEY (centro_id) REFERENCES centros_operacion(centro_id)
) ;


-- 6. Contratos de renta
CREATE TABLE IF NOT EXISTS contratos (
    contrato_id INT PRIMARY KEY,
    cliente_id INT NOT NULL,
    unidad_id INT NOT NULL,
    centro_salida INT NOT NULL,
    centro_retorno INT NOT NULL,
    fecha_salida DATETIME NOT NULL,
    fecha_retorno DATETIME NOT NULL,
    estatus ENUM('Reservado', 'En curso', 'Cerrado', 'Cancelado') NOT NULL,
    nivel_prioridad TINYINT NOT NULL,
    -- Columnas técnicas
    version_registro INT NOT NULL DEFAULT 1,
    fecha_ultima_mod_utc DATETIME(6) NOT NULL,
    eliminado BOOLEAN NOT NULL DEFAULT FALSE,
    CONSTRAINT chk_fechas_contrato CHECK (fecha_retorno > fecha_salida),
    CONSTRAINT chk_prioridad CHECK (nivel_prioridad BETWEEN 1 AND 5),
    CONSTRAINT fk_cont_cliente FOREIGN KEY (cliente_id) REFERENCES clientes_flota(cliente_id),
    CONSTRAINT fk_cont_unidad FOREIGN KEY (unidad_id) REFERENCES unidades(unidad_id),
    CONSTRAINT fk_cont_salida FOREIGN KEY (centro_salida) REFERENCES centros_operacion(centro_id),
    CONSTRAINT fk_cont_retorno FOREIGN KEY (centro_retorno) REFERENCES centros_operacion(centro_id)
) ;


-- 7. Facturas
CREATE TABLE IF NOT EXISTS facturas (
    factura_id INT PRIMARY KEY,
    contrato_id INT NOT NULL UNIQUE,
    fecha DATETIME NOT NULL,
    subtotal_usd DECIMAL(12,2) NOT NULL,
    impuesto_usd DECIMAL(12,2) NOT NULL,
    monto_total_usd DECIMAL(12,2) NOT NULL,
    comentarios TEXT,
    -- Columnas técnicas
    version_registro INT NOT NULL DEFAULT 1,
    fecha_ultima_mod_utc DATETIME(6) NOT NULL,
    eliminado BOOLEAN NOT NULL DEFAULT FALSE,
    CONSTRAINT chk_subtotal_usd CHECK (subtotal_usd >= 0),
    CONSTRAINT chk_impuesto_usd CHECK (impuesto_usd >= 0),
    CONSTRAINT chk_total_usd CHECK (monto_total_usd = subtotal_usd + impuesto_usd),
    CONSTRAINT fk_factura_contrato FOREIGN KEY (contrato_id) REFERENCES contratos(contrato_id)
) ;


-- 8. Servicios (extras)
CREATE TABLE IF NOT EXISTS extras (
    extra_id INT PRIMARY KEY,
    detalle VARCHAR(150) NOT NULL,
    costo_dia_usd DECIMAL(10,2) NOT NULL,
    autorizacion_previa BOOLEAN NOT NULL,
    categoria ENUM('Renta', 'Seguro', 'Equipo', 'Chofer', 'Entrega') NOT NULL,
    -- Columnas técnicas
    version_registro INT NOT NULL DEFAULT 1,
    fecha_ultima_mod_utc DATETIME(6) NOT NULL,
    eliminado BOOLEAN NOT NULL DEFAULT FALSE,
    CONSTRAINT chk_costo_extra CHECK (costo_dia_usd >= 0)
) ;


-- 9. Detalle de factura (factura_extras)
CREATE TABLE IF NOT EXISTS factura_extras (
    factura_id INT NOT NULL,
    extra_id INT NOT NULL,
    dias INT NOT NULL,
    subtotal_usd DECIMAL(12,2) NOT NULL,
    incluye_impuesto BOOLEAN NOT NULL,
    -- Columnas técnicas
    version_registro INT NOT NULL DEFAULT 1,
    fecha_ultima_mod_utc DATETIME(6) NOT NULL,
    eliminado BOOLEAN NOT NULL DEFAULT FALSE,
    PRIMARY KEY (factura_id, extra_id),
    CONSTRAINT chk_dias_detalle CHECK (dias > 0),
    CONSTRAINT chk_subtotal_detalle CHECK (subtotal_usd >= 0),
    CONSTRAINT fk_fe_factura FOREIGN KEY (factura_id) REFERENCES facturas(factura_id),
    CONSTRAINT fk_fe_extra FOREIGN KEY (extra_id) REFERENCES extras(extra_id)
) ;


-- 10. Traslados de vehiculos (movimientos_flota)
CREATE TABLE IF NOT EXISTS movimientos_flota (
    movimiento_id INT PRIMARY KEY,
    unidad_id INT NOT NULL,
    centro_origen INT NOT NULL,
    centro_destino INT NOT NULL,
    km_recorridos INT NOT NULL,
    motivo ENUM('Rebalanceo', 'Mantenimiento', 'Devolución') NOT NULL,
    fecha_movimiento DATETIME NOT NULL,
    -- Columnas técnicas
    version_registro INT NOT NULL DEFAULT 1,
    fecha_ultima_mod_utc DATETIME(6) NOT NULL,
    eliminado BOOLEAN NOT NULL DEFAULT FALSE,
    CONSTRAINT chk_destino_distinto CHECK (centro_destino <> centro_origen),
    CONSTRAINT chk_km_recorridos CHECK (km_recorridos > 0),
    CONSTRAINT fk_mov_unidad FOREIGN KEY (unidad_id) REFERENCES unidades(unidad_id),
    CONSTRAINT fk_mov_origen FOREIGN KEY (centro_origen) REFERENCES centros_operacion(centro_id),
    CONSTRAINT fk_mov_destino FOREIGN KEY (centro_destino) REFERENCES centros_operacion(centro_id)
) ;