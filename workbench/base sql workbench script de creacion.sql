use FlotaMax;

CREATE TABLE IF NOT EXISTS catalogo_pais (
    codigo_pais CHAR(2) PRIMARY KEY,
    nombre_pais VARCHAR(50) NOT NULL,
    version_registro INT NOT NULL DEFAULT 1,
    fecha_ultima_mod_utc DATETIME(6) NOT NULL,
    eliminado BOOLEAN NOT NULL DEFAULT FALSE
);

create table IF NOT EXISTS clientes_flota(

	cliente_id INT PRIMARY KEY,
	nombre_cliente VARCHAR(150) NOT NULL,
	tipo_doc ENUM('Identidad','Pasaporte','RTN') NOT NULL,
	documento VARCHAR(25) NOT NULL, UNIQUE(tipo_doc,documento),
	telefono_contacto VARCHAR(25),
    emial VARCHAR(120),
    codigo_pais VARCHAR(2) NOT NULL,
    FOREIGN KEY (codigo_pais) REFERENCES catalogo_pais(codigo_pais),
    licencia_valida BOOLEAN NOT NULL,
	version_registro INT NOT NULL DEFAULT 1,
	fecha_ultima_mod_utc DATETIME(6) NOT NULL,
	eliminado BOOLEAN NOT NULL DEFAULT FALSE
); 

create table IF NOT EXISTS centros_operacion(

	centro_id INT PRIMARY KEY,
    nombre_centro VARCHAR(120) NOT NULL,
    municipio VARCHAR(100) NOT NULL,
    pais_operacion VARCHAR(50) NOT NULL,
    FOREIGN KEY (pais_operacion) REFERENCES catalogo_pais(codigo_pais),
    categoria ENUM('Aeropuerto', 'Urbana', 'Patio','Taller') NOT NULL,
    capacidad_maxima INT NOT NULL CHECK(capacidad_maxima > 0),
	version_registro INT NOT NULL DEFAULT 1,
	fecha_ultima_mod_utc DATETIME(6) NOT NULL,
	eliminado BOOLEAN NOT NULL DEFAULT FALSE

);

create table IF NOT EXISTS tipos_vehiculo(

	tipo_id INT PRIMARY KEY,
    fabricante VARCHAR(50) NOT NULL,
    linea VARCHAR(50) NOT NULL, UNIQUE(fabricante, linea),
    segmento ENUM('Economico', 'Sedan','SUV', 'Pickup', 'Van'),
    pasajeros TINYINT NOT NULL CHECK(pasajeros > 0 ),
    tarifa_dia_usd DECIMAL(10,2) NOT NULL CHECK(tarifa_dia_usd >= 0),
	version_registro INT NOT NULL DEFAULT 1,
	fecha_ultima_mod_utc DATETIME(6) NOT NULL,
	eliminado BOOLEAN NOT NULL DEFAULT FALSE
);

create table IF NOT EXISTS unidades(

	unidad_id INT PRIMARY KEY,
	placa VARCHAR(12) NOT NULL UNIQUE CHECK (placa REGEXP '^[A-Z]{3}-[0-9]{4}$'),
    vin CHAR(17) NOT NULL UNIQUE,
    tipo_id INT NOT NULL,
    FOREIGN KEY (tipo_id) REFERENCES tipos_vehiculo(tipo_id),
    anio_fabricacion YEAR NOT NULL CHECK(anio_fabricacion >= 2000),
    odometro_km INT NOT NULL CHECK(odometro_km >= 0),
    es_automatico BOOLEAN NOT NULL,
    estado ENUM('Disponible','Rentado', 'Mantenimiento','Retenido', 'Baja') NOT NULL,
	version_registro INT NOT NULL DEFAULT 1,
	fecha_ultima_mod_utc DATETIME(6) NOT NULL,
	eliminado BOOLEAN NOT NULL DEFAULT FALSE
);

create table IF NOT EXISTS posicion_flota(

	posicion_id INT PRIMARY KEY,
    unidad_id INT NOT NULL UNIQUE,
    FOREIGN KEY (unidad_id) REFERENCES unidades(unidad_id),
    centro_id INT NOT NULL, 
    FOREIGN KEY (centro_id) REFERENCES centros_operacion(centro_id),
	combustible ENUM('Vacio', '1/4', '1/2', '3/4','Lleno') NOT NULL,
    fecha_modificacion DATETIME NOT NULL,
	version_registro INT NOT NULL DEFAULT 1,
	fecha_ultima_mod_utc DATETIME(6) NOT NULL,
	eliminado BOOLEAN NOT NULL DEFAULT FALSE
    
);

create table IF NOT EXISTS contratos(

	contrato_id INT PRIMARY KEY,
	cliente_id INT NOT NULL, 
    FOREIGN KEY (cliente_id) REFERENCES clientes_flota(cliente_id),
    unidad_id INT NOT NULL,
    FOREIGN KEY (unidad_id) REFERENCES unidades(unidad_id),
    centro_salida INT NOT NULL,
    FOREIGN KEY (centro_salida) REFERENCES centros_operacion(centro_id),
    centro_retorno INT NOT NULL,
	FOREIGN KEY (centro_retorno) REFERENCES centros_operacion(centro_id),	
    fecha_salida DATETIME NOT NULL,
    fecha_retorno DATETIME NOT NULL,
    CHECK(fecha_retorno > fecha_salida),
	version_registro INT NOT NULL DEFAULT 1,
	fecha_ultima_mod_utc DATETIME(6) NOT NULL,
	eliminado BOOLEAN NOT NULL DEFAULT FALSE
);

create table IF NOT EXISTS facturas(

	factura_id INT PRIMARY KEY,
    contrato_id INT NOT NULL UNIQUE,
    FOREIGN KEY (contrato_id) REFERENCES contratos(contrato_id),
    fecha DATETIME NOT NULL,
    subtotal_usd DECIMAL(12,2) NOT NULL CHECK(subtotal_usd >= 0),
    impuesto_usd DECIMAL(12,2) NOT NULL CHECK(impuesto_usd >= 0),
    monto_total_usd DECIMAL(12,2) NOT NULL,
    CHECK(monto_total_usd = subtotal_usd + impuesto_usd),
    comentarios TEXT,
	version_registro INT NOT NULL DEFAULT 1,
	fecha_ultima_mod_utc DATETIME(6) NOT NULL,
	eliminado BOOLEAN NOT NULL DEFAULT FALSE

);

create table IF NOT EXISTS extras(

	extra_id INT PRIMARY KEY,
    detalle VARCHAR(150) NOT NULL,
    costo_dia_usd DECIMAL(10,2) NOT NULL CHECK(costo_dia_usd >= 0),
    autorizacion_previa BOOLEAN NOT NULL,
    categoria ENUM('Renta', 'Seguro', 'Equipo', 'Chofer', 'Entrega') NOT NULL,
	version_registro INT NOT NULL DEFAULT 1,
	fecha_ultima_mod_utc DATETIME(6) NOT NULL,
	eliminado BOOLEAN NOT NULL DEFAULT FALSE
);

create table IF NOT EXISTS factura_extras(

	factura_id INT,
    extra_id INT,
    FOREIGN KEY (factura_id) REFERENCES facturas(factura_id),
    FOREIGN KEY (extra_id) REFERENCES extras(extra_id),
    PRIMARY KEY(factura_id,extra_id),
    dias INT NOT NULL CHECK(dias > 0 ),
    subtotal_usd DECIMAL(12,2) NOT NULL CHECK(subtotal_usd >= 0),
    incluye_impuesto BOOLEAN NOT NULL,
	version_registro INT NOT NULL DEFAULT 1,
	fecha_ultima_mod_utc DATETIME(6) NOT NULL,
	eliminado BOOLEAN NOT NULL DEFAULT FALSE
);

create table IF NOT EXISTS movimientos_flota(

	movimiento_id INT PRIMARY KEY,
	unidad_id INT NOT NULL,
	FOREIGN KEY (unidad_id) REFERENCES unidades(unidad_id),
	centro_origen INT NOT NULL,
    FOREIGN KEY (centro_origen) REFERENCES centros_operacion(centro_id),
    centro_destino INT NOT NULL,
    CHECK(centro_destino <> centro_origen ),
    FOREIGN KEY (centro_destino) REFERENCES centros_operacion(centro_id),
    km_recorridos INT NOT NULL CHECK(km_recorridos > 0 ),
    motivo ENUM ('Rebalanceo', 'Mantenimiejto', 'Devolucion') NOT NULL,
    fecha_movimiento DATETIME NOT NULL,
	version_registro INT NOT NULL DEFAULT 1,
	fecha_ultima_mod_utc DATETIME(6) NOT NULL,
	eliminado BOOLEAN NOT NULL DEFAULT FALSE
);
