drop table prueba_melvin;
commit;

/*
columnas tecnicas
aniadir a cada table
    version_registro        number(10) default 1 not null,
    fecha_ultima_mod_utc    timestamp default current_timestamp not null,
    eliminado               char(1) default 'N' not null constraint chk_cli_elim check (eliminado in ('S','N')),
*/

create table catalogo_pais(
    codigo_pais CHAR(2) PRIMARY KEY,
    nombre_pais VARCHAR(50) NOT NULL,
    version_registro        number(10) default 1 not null,
    fecha_ultima_mod_utc    timestamp default current_timestamp not null,
    eliminado               char(1) default 'N' not null constraint chk_cat_pais_elim check (eliminado in ('S','N'))
);

create table cliente_renta(
id_cliente number(8) primary key,
nombre_completo varchar2(120) not null,
tipo_documento varchar2(3) not null, constraint chk_cli_ren_tipo_doc check (tipo_documento in ('DNI', 'PAS', 'RTN')),
num_documento varchar2(20) not null,
telefono varchar2(20),
correo varchar2(100),
pais_origen char(2) not null,
licencia_vigente char(1) not null constraint check_cli_ren_lic_vig check (licencia_vigente in ('S', 'N')),
fecha_registro date not null,
    version_registro        number(10) default 1 not null,
    fecha_ultima_mod_utc    timestamp default current_timestamp not null,
    eliminado               char(1) default 'N' not null constraint chk_cli_ren_elim check (eliminado in ('S','N')),
constraint uk_cliente_documento unique (tipo_documento, num_documento),
constraint fk_cliente_pais foreign key (pais_origen) references catalogo_pais(codigo_iso)
);

create table sucursal(
    id_sucursal number(4) primary key,
    nombre_sucursal varchar2(100) not null,
    ciudad varchar2(80) not null,
    pais char(2) not null,
    tipo_sucursal varchar2(20) not null constraint chk_sucursal_tipo check (tipo_sucursal in ('AEROPUERTO', 'CIUDAD', 'PATIO', 'TALLER')),
    capacidad_vehiculos number(4) not null, constraint chk_sucursal_capacidad check (capacidad_vehiculos > 0),
    version_registro        number(10) default 1 not null,
    fecha_ultima_mod_utc    timestamp default current_timestamp not null,
    eliminado               char(1) default 'N' not null constraint chk_sucursal_elim check (eliminado in ('S','N')),
    constraint fk_sucursal_pais foreign key (pais) references catalogo_pais(codigo_iso)
);

create table modelo_vehiculo(
    id_modelo number(5) primary key,
    marca varchar2(40) not null, 
    modelo varchar (40) not null,
    categoria varchar2(20) not null constraint chk_mod_veh_categoria check (categoria in ('ECONOMICO','SEDAN','SUV','PICKUP','VAN')),
    capacidad_pasajeros number(2) not null constraint chk_mod_veh_capacidad check (capacidad_pasajeros > 0),
    tarifa_diario number(10,2) not null constraint chk_mod_veh_tarifa check (tarifa_diario > 0),
    version_registro        number(10) default 1 not null,
    fecha_ultima_mod_utc    timestamp default current_timestamp not null,
    eliminado               char(1) default 'N' not null constraint chk_mod_veh_elim check (eliminado in ('S','N')),
    constraint uk_modelo_marca_modelo unique (marca, modelo)
);

create table vehiculo(
    id_vehiculo number(6) primary key,
    placa varchar2(10) not null unique,
    vin varchar2(17) not null unique,
    id_modelo number(5) not null,
    anio number(4) not null constraint chk_veh_anio check (anio >= 2000),
    kilometraje number(8) not null constraint chk_veh_km check (kilometraje >= 0),
    transmision_automatica char(1) not null constraint chk_veh_trans check (transmision_automatica in ('S','N')),
    estado_operacion varchar2(20) not null constraint chk_veh_estado check (estado_operacion in ('DISPONIBLE', 'RENTADO', 'MANTENIMIENTO', 'RETENIDO', 'BAJA')),

    version_registro number(10) default 1 not null,
    fecha_ultima_mod_utc timestamp default current_timestamp not null,
    eliminado char(1) default 'N' not null constraint chk_veh_elim check (eliminado in ('S','N')),

    constraint chk_veh_placa_formato check (regexp_like(placa, '^[A-Z]{3}[0-9]{4}$')),
    constraint chk_veh_vin_longitud check (length(vin) = 17),
    constraint fk_vehiculo_modelo foreign key (id_modelo) references modelo_vehiculo(id_modelo)
);

create table ubicacion_vehiculo (
    id_ubicacion number(8) primary key,
    id_vehiculo number(6) not null unique,
    id_sucursal number(4) not null,
    nivel_combustible number(3) not null constraint chk_ubi_veh_combust check (nivel_combustible between 0 and 100),
    fecha_actualizacion date not null,
    version_registro number(10) default 1 not null,
    fecha_ultima_mod_utc timestamp default current_timestamp not null,
    eliminado char(1) default 'N' not null constraint chk_ubi_veh_elim check (eliminado in ('S','N')),
    constraint fk_ubi_vehiculo foreign key (id_vehiculo) references vehiculo(id_vehiculo),
    constraint fk_ubi_veh_sucursal foreign key (id_sucursal) references sucursal(id_sucursal)
);

create table contrato_renta (
    id_contrato number(8) primary key,
    id_cliente number(8) not null,
    id_vehiculo number(6) not null,
    sucursal_retiro number(4) not null,
    sucursal_devolucion number(4) not null,
    fecha_inicio date not null,
    fecha_fin date not null,
    estado_contrato varchar2(20) not null constraint chk_cont_estado check (estado_contrato in ('RESERVADO', 'ACTIVO', 'FINALIZADO', 'CANCELADO')),
    prioridad number(1) not null constraint chk_cont_prioridad check (prioridad between 1 and 3),

    version_registro number(10) default 1 not null,
    fecha_ultima_mod_utc timestamp default current_timestamp not null,
    eliminado char(1) default 'N' not null constraint chk_cont_elim check (eliminado in ('S','N')),

    constraint chk_cont_fechas check (fecha_fin > fecha_inicio),
    constraint fk_cont_cliente foreign key (id_cliente) references cliente_renta(id_cliente),
    constraint fk_cont_vehiculo foreign key (id_vehiculo) references vehiculo(id_vehiculo),
    constraint fk_cont_retiro foreign key (sucursal_retiro) references sucursal(id_sucursal),
    constraint fk_cont_devolucion foreign key (sucursal_devolucion) references sucursal(id_sucursal)
);

create table factura (
    id_factura number(8) primary key,
    id_contrato number(8) not null unique,
    fecha_emision date not null,
    subtotal number(12,2) not null constraint chk_fac_subtotal check (subtotal >= 0),
    isv number(12,2) not null constraint chk_fac_isv check (isv >= 0),
    total number(12,2) not null,
    observaciones varchar2(150),

    version_registro number(10) default 1 not null,
    fecha_ultima_mod_utc timestamp default current_timestamp not null,
    eliminado char(1) default 'N' not null constraint chk_fac_elim check (eliminado in ('S','N')),

    constraint chk_fac_total_suma check (total = subtotal + isv),
    constraint fk_factura_contrato foreign key (id_contrato) references contrato_renta(id_contrato)
);

create table servicio_renta (
    id_servicio number(5) primary key,
    descripcion varchar2(120) not null,
    costo_diario number(10,2) not null constraint chk_serv_costo check (costo_diario >= 0),
    requiere_autorizacion char(1) not null constraint chk_serv_aut check (requiere_autorizacion in ('S','N')),
    tipo_servicio varchar2(20) not null constraint chk_serv_tipo check (tipo_servicio in ('RENTA', 'SEGURO', 'EQUIPO', 'CONDUCTOR', 'ENTREGA')),
    version_registro number(10) default 1 not null,
    fecha_ultima_mod_utc timestamp default current_timestamp not null,
    eliminado char(1) default 'N' not null constraint chk_serv_elim check (eliminado in ('S','N'))
);

create table detalle_factura (
    id_factura number(8) not null,
    id_servicio number(5) not null,
    dias number(3) not null constraint chk_det_dias check (dias > 0),
    subtotal number(12,2) not null constraint chk_det_subtotal check (subtotal >= 0),
    aplica_isv char(1) not null constraint chk_det_isv check (aplica_isv in ('S','N')),

    version_registro number(10) default 1 not null,
    fecha_ultima_mod_utc timestamp default current_timestamp not null,
    eliminado char(1) default 'N' not null constraint chk_det_elim check (eliminado in ('S','N')),

    constraint pk_detalle_factura primary key (id_factura, id_servicio),
    constraint fk_detfac_factura foreign key (id_factura) references factura(id_factura),
    constraint fk_detfac_servicio foreign key (id_servicio) references servicio_renta(id_servicio)
);

create table traslado_vehiculo (
    id_traslado number(8) primary key,
    id_vehiculo number(6) not null,
    sucursal_origen number(4) not null,
    sucursal_destino number(4) not null,
    km_recorridos number(6) not null constraint chk_tras_km check (km_recorridos > 0),
    motivo varchar2(25) not null constraint chk_tras_motivo check (motivo in ('REBALANCEO', 'MANTENIMIENTO', 'DEVOLUCION')),
    fecha_traslado date not null,
    version_registro number(10) default 1 not null,
    fecha_ultima_mod_utc timestamp default current_timestamp not null,
    eliminado char(1) default 'N' not null constraint chk_tras_elim check (eliminado in ('S','N')),
    constraint chk_tras_dest_distinto check (sucursal_destino <> sucursal_origen),
    constraint fk_tras_vehiculo foreign key (id_vehiculo) references vehiculo(id_vehiculo),
    constraint fk_tras_origen foreign key (sucursal_origen) references sucursal(id_sucursal),
    constraint fk_tras_destino foreign key (sucursal_destino) references sucursal(id_sucursal)
);