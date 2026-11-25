
-- Insert a Flotamax.catalogo_pais a traves del dblink
DECLARE
  v_fecha_utc TIMESTAMP;
BEGIN
  -- sumar 6 horas a la fecha actual y asignarla a la variable
  v_fecha_utc := cast(systimestamp + interval '6' hour as timestamp);

  INSERT INTO "catalogo_pais"@FLOTAMAX (
      "codigo_pais",
      "nombre_pais",
      "fecha_ultima_mod_utc"
  ) VALUES (
      'SV', 
      'El Salvador', 
      v_fecha_utc
  );

  COMMIT;
END;
/

--Update a Flotamax.catalogo_pais a traves del dblink
--DBMS_HS_PASSTHROUGH.EXECUTE_IMMEDIATE utilizado, este ejecuta la sentencia
--en mysql 
DECLARE
    v_fecha_str VARCHAR2(30);
    v_version NUMBER;
    v_filas NUMBER;
    --v_sql variable para guardar la sentencia  
    v_sql VARCHAR2(2000); 
BEGIN
    -- consultar version actual  
    SELECT "version_registro"
    INTO v_version
    FROM "catalogo_pais"@FLOTAMAX
    WHERE "codigo_pais" = 'HN';

    -- incrementar version
    v_version := v_version + 1;

    -- convertir fecha actual a utc + 6 horas y castear a cadena
    v_fecha_str := TO_CHAR(
        SYSTIMESTAMP + INTERVAL '6' HOUR,
        'YYYY-MM-DD HH24:MI:SS'
    );

    -- construir sentencia sql que se enviara a mysql  
    v_sql :=
        'UPDATE catalogo_pais SET ' ||
        'nombre_pais = ''República Soberana de Honduras'', ' ||
        'version_registro = ' || TO_CHAR(v_version) || ', ' ||
        'fecha_ultima_mod_utc = ''' || v_fecha_str || ''' ' ||
        'WHERE codigo_pais = ''HN''';

    -- ejecutar la sentencia en mysql a traves del dblink
    v_filas := DBMS_HS_PASSTHROUGH.EXECUTE_IMMEDIATE@FLOTAMAX(v_sql);

    COMMIT;

END;
/

-- delete a Flotamax.catalogo_pais a traves del dblink
DECLARE
    v_filas NUMBER;
    v_sql VARCHAR2(1000);
BEGIN
    -- contruir sentencia
    v_sql := 'DELETE FROM catalogo_pais WHERE codigo_pais = ''SV''';

    -- ejecutar sentencia 
    v_filas := DBMS_HS_PASSTHROUGH.EXECUTE_IMMEDIATE@FLOTAMAX(v_sql);

    COMMIT;

END;
/

SELECT COUNT(*) AS total_oracle_remoto 
FROM "catalogo_pais"@FLOTAMAX;


/*
JOB
 Un job de DBMS_SCHEDULER que escriba en MySQL por el database link.
*/

CREATE OR REPLACE PROCEDURE prc_prueba_job_mysql IS
    v_filas NUMBER;
    v_sql   VARCHAR2(500);
BEGIN
    v_sql := 'UPDATE catalogo_pais SET nombre_pais = ''Honduras'' WHERE codigo_pais = ''HN''';
    v_filas := DBMS_HS_PASSTHROUGH.EXECUTE_IMMEDIATE@FLOTAMAX(v_sql);
    COMMIT;
END prc_prueba_job_mysql;
/

BEGIN
    DBMS_SCHEDULER.CREATE_JOB (
        job_name => 'JOB_PRUEBA_FLOTAMAX',
        job_type => 'STORED_PROCEDURE',
        job_action => 'prc_prueba_job_mysql',
        repeat_interval => 'FREQ=SECONDLY; INTERVAL=30',
        enabled => TRUE
    );
END;
/

--prueba de ejecucion 
SELECT job_name, status, actual_start_date, additional_info
FROM user_scheduler_job_run_details
WHERE job_name = 'JOB_PRUEBA_FLOTAMAX'
ORDER BY actual_start_date DESC;