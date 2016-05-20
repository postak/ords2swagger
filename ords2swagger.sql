-- 
-- Author  : Luca Postacchini
-- Date    : May 2016
-- Version : 1.0
-- 
SET SERVEROUTPUT ON FORMAT WRAPPED
SET LINESIZE 10000
SET FEEDBACK OFF
SET VERIFY OFF


DECLARE
  
  -- START PARAMETERS (change it accordingly)
  
  c_basepath varchar(100)    := '/ords/scott';
  c_description varchar(100) := 'this is the description';
  c_title varchar(100)       := 'this is the title';
  c_hostname varchar(100)    := 'localhost';
  c_port number(4)           := 8080;
  
  -- END PARAMETERS 
  
  
  cur_method        user_ords_services.method%type;
  cur_base_path     user_ords_services.base_path%type;
  cur_pattern       user_ords_services.pattern%type;
  cur_source_type   user_ords_services.source_type%type;
  cur_source        user_ords_services.source%type;
  
  v_lastpath varchar(100);
  v_singleparam varchar(100);
  v_allparams varchar(100);
  v_prefix varchar(100);
  
  TYPE pattern IS TABLE OF varchar(100) INDEX BY PLS_INTEGER;

  v_pattern pattern;
  
   CURSOR cur_services is
      SELECT method, base_path, pattern,source_type,source 
          FROM user_ords_services where status = 'PUBLISHED';
BEGIN

   dbms_output.put_line('swagger: "2.0"');
   dbms_output.put_line('info:');
   dbms_output.put_line('  title: ' || c_title);
   dbms_output.put_line('  description: ' || c_description);
   dbms_output.put_line('  version: "1.0.0"');
   dbms_output.put_line('# the domain of the service');
   dbms_output.put_line('host: ' || c_hostname || ':' || c_port);
   dbms_output.put_line('basePath: ' || c_basepath);
   dbms_output.put_line('schemes:');
   dbms_output.put_line('  - http');
   dbms_output.put_line('  - https');
   dbms_output.put_line('consumes:');
   dbms_output.put_line('  - application/json');
   dbms_output.put_line('produces:');
   dbms_output.put_line('  - application/json');
   dbms_output.put_line('paths:');

   v_lastpath := '@';
  
   OPEN cur_services;
   LOOP
      FETCH cur_services INTO cur_method, cur_base_path, cur_pattern, cur_source_type, cur_source;
      EXIT WHEN cur_services%notfound;

      IF cur_pattern = '.' THEN
          -- no params
          IF (v_lastpath != cur_base_path) THEN
            v_lastpath := cur_base_path;
            dbms_output.put_line('  ' || cur_base_path || ':');
          END IF;
          dbms_output.put_line('    ' || LOWER( cur_method ) || ':');
          
          IF (LOWER ( cur_method  ) = 'post') THEN      
              dbms_output.put_line('      produces:');
              dbms_output.put_line('        - application/json');
              dbms_output.put_line('      parameters:');
              dbms_output.put_line('        - in: body');
              dbms_output.put_line('          name: body');
              dbms_output.put_line('          description: user data in JSON');
              dbms_output.put_line('          required: true');
              dbms_output.put_line('          schema:');
              dbms_output.put_line('            type: object');
          END IF;
          
          dbms_output.put_line('      responses:');
          dbms_output.put_line('        200:');
          CASE LOWER( cur_method )
            WHEN 'get' THEN dbms_output.put_line('          description: return data from table ' || cur_source);
            WHEN 'put' THEN dbms_output.put_line('          description: insert data to table ' || cur_source);
            WHEN 'post' THEN dbms_output.put_line('          description: insert data to  table ' || cur_source);
            WHEN 'delete' THEN dbms_output.put_line('          description: delete record in table ' || cur_source);
            ELSE dbms_output.put_line('          description: unkknown operation');
          END CASE;
      
      ELSIF INSTR( cur_pattern, ':' , 1 ) > 0 THEN
      
        -- param found
        
        v_prefix := SUBSTR (cur_pattern, 1, INSTR( cur_pattern, ':' , 1 ) - 1);
        v_allparams := SUBSTR (cur_pattern, INSTR( cur_pattern, ':' , 1 ));
        
        IF (v_lastpath != cur_base_path || cur_pattern ) THEN
            v_lastpath := cur_base_path || cur_pattern;
            dbms_output.put_line('  ' || cur_base_path || v_prefix || REPLACE (REPLACE (v_allparams, ':', '{'), '/', '}/') || '}:');
        END IF;
        
        dbms_output.put_line('    ' || LOWER( cur_method ) || ':');
        dbms_output.put_line('      parameters: ');
  
        FOR i IN 1 .. LENGTH (v_allparams)
        LOOP
            v_pattern (i) := REGEXP_SUBSTR (v_allparams, '[^/]+', 1, i);
            EXIT WHEN v_pattern (i) IS NULL;
                            
            v_singleparam := REPLACE (v_pattern (i), ':', '');
                
            dbms_output.put_line('        - name: ' || v_singleparam );
            dbms_output.put_line('          in: path');
            dbms_output.put_line('          type: string');
            dbms_output.put_line('          description: parameter ' || v_singleparam || ' for statement | ');
            dbms_output.put_line('            ' || replace( cur_source, CHR(10) , CHR(10) || '            '));
            dbms_output.put_line('          required: true');
        
        END LOOP;
                
        dbms_output.put_line('      responses:');
        dbms_output.put_line('        200:');
        
        CASE LOWER( cur_method )
            WHEN 'get' THEN dbms_output.put_line('          description: return data from | ');
            WHEN 'put' THEN dbms_output.put_line('          description: insert data to | ');
            WHEN 'post' THEN dbms_output.put_line('          description: insert data to || ');
            WHEN 'delete' THEN dbms_output.put_line('          description: delete record in | ');
            ELSE dbms_output.put_line('          description: unkknown operation |');
        END CASE;

        dbms_output.put_line('            ' || replace( cur_source, CHR(10) , CHR(10) || '            '));

      ELSE
          -- pattern
          dbms_output.put_line('  ' || REPLACE (cur_base_path || cur_pattern, '//', '/') || ':');
          dbms_output.put_line('    ' || LOWER( cur_method ) || ':');
          
          IF (LOWER ( cur_method  ) = 'post') THEN      
              dbms_output.put_line('      produces:');
              dbms_output.put_line('        - application/json');
              dbms_output.put_line('      parameters:');
              dbms_output.put_line('        - in: body');
              dbms_output.put_line('          name: body');
              dbms_output.put_line('          description: user data in JSON');
              dbms_output.put_line('          required: true');
              dbms_output.put_line('          schema:');
              dbms_output.put_line('            type: object');
          END IF;
          
          dbms_output.put_line('      responses:');
          dbms_output.put_line('        200:');
          CASE LOWER( cur_method )
            WHEN 'get' THEN dbms_output.put_line('          description: get data from the following statement => ' || cur_source);
            WHEN 'put' THEN dbms_output.put_line('          description: insert data using the following pl/sql => ' || cur_source);
            WHEN 'post' THEN dbms_output.put_line('          description: insert data using the following pl/sql => ' || cur_source);
            WHEN 'delete' THEN dbms_output.put_line('          description: delete record using the following pl/sql => => ' || cur_source);
            ELSE dbms_output.put_line('          description: unkknown operation');
          END CASE;
      END IF;
   END LOOP;
   CLOSE cur_services;
END;
/
EXIT;
