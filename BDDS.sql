DROP TABLE IF EXISTS cliente_home;
DROP TABLE IF EXISTS cliente_muller;
DROP TABLE IF EXISTS cliente_outro;

DROP TABLE IF EXISTS sesion_home;
DROP TABLE IF EXISTS sesion_muller;
DROP TABLE IF EXISTS sesion_outro;

CREATE TABLE cliente_home (
    dni VARCHAR(10) PRIMARY KEY,
    nome VARCHAR(25) NOT NULL,
    sexo VARCHAR(1),
    telefono VARCHAR(10)
);

CREATE TABLE cliente_muller (
    dni VARCHAR(10) PRIMARY KEY,
    nome VARCHAR(25) NOT NULL,
    sexo VARCHAR(1),
    telefono VARCHAR(10)
);

CREATE TABLE cliente_outro (
    dni VARCHAR(10) PRIMARY KEY,
    nome VARCHAR(25) NOT NULL,
    sexo VARCHAR(1),
    telefono VARCHAR(10)
);

CREATE TABLE sesion_home (
    codsesion NUMERIC(6, 0) PRIMARY KEY,
    datahora DATE,
    cliente VARCHAR(10) NOT NULL,
    FOREIGN KEY (cliente) REFERENCES cliente_home(dni) ON DELETE CASCADE
);

CREATE TABLE sesion_muller (
    codsesion NUMERIC(6, 0) PRIMARY KEY,
    datahora DATE,
    cliente VARCHAR(10) NOT NULL,
    FOREIGN KEY (cliente) REFERENCES cliente_muller(dni) ON DELETE CASCADE
);

CREATE TABLE sesion_outro (
    codsesion NUMERIC(6, 0) PRIMARY KEY,
    datahora DATE,
    cliente VARCHAR(10) NOT NULL,
    FOREIGN KEY (cliente) REFERENCES cliente_outro(dni) ON DELETE CASCADE
);

CREATE OR REPLACE VIEW cliente AS
SELECT * FROM cliente_home
UNION
SELECT * FROM cliente_muller
UNION
SELECT * FROM cliente_outro;

CREATE OR REPLACE VIEW sesion AS
SELECT * FROM sesion_home
UNION
SELECT * FROM sesion_muller
UNION
SELECT * FROM sesion_outro;

CREATE OR REPLACE TRIGGER insert_cliente
INSTEAD OF INSERT ON cliente
FOR EACH ROW
DECLARE
    countN NUMBER;
BEGIN
    SELECT COUNT(*) INTO countN
    FROM cliente
    WHERE dni = :NEW.dni;

    IF countN != 0 THEN
        RAISE_APPLICATION_ERROR(-20001, 'Cliente ' || :NEW.dni || ' ya existe.');
    END IF;

    IF UPPER(:NEW.sexo) = 'HOME' THEN
        INSERT INTO cliente_home VALUES (:NEW.dni, :NEW.nome, :NEW.sexo, :NEW.telefono);
    ELSIF UPPER(:NEW.sexo) = 'MULLER' THEN
        INSERT INTO cliente_muller VALUES (:NEW.dni, :NEW.nome, :NEW.sexo, :NEW.telefono);
    ELSIF UPPER(:NEW.sexo) = 'OUTRO' THEN
        INSERT INTO cliente_outro VALUES (:NEW.dni, :NEW.nome, :NEW.sexo, :NEW.telefono);
    ELSE
        RAISE_APPLICATION_ERROR(-20002, 'Non hai clientes con sexo: ' || :NEW.sexo);
    END IF;
END;
/

CREATE OR REPLACE TRIGGER update_cliente
INSTEAD OF UPDATE ON cliente
FOR EACH ROW
DECLARE
    countN NUMBER;
BEGIN
    IF :NEW.dni != :OLD.dni THEN
        RAISE_APPLICATION_ERROR(-20006, 'No se puede cambiar el DNI.');
    END IF;

    IF :NEW.nome != :OLD.nome THEN
        IF UPPER(:OLD.sexo) = 'HOME' THEN
        ELSIF UPPER(:OLD.sexo) = 'MULLER' THEN
        ELSIF UPPER(:OLD.sexo) = 'OUTRO' THEN
        END IF;
    END IF;

    IF :NEW.telefono != :OLD.telefono THEN
        IF UPPER(:OLD.sexo) = 'HOME' THEN
        ELSIF UPPER(:OLD.sexo) = 'MULLER' THEN
        ELSIF UPPER(:OLD.sexo) = 'OUTRO' THEN
        END IF;
    END IF;

    IF :NEW.sexo != :OLD.sexo THEN
        IF UPPER(:OLD.sexo) = 'HOME' THEN
        ELSIF UPPER(:OLD.sexo) = 'MULLER' THEN
        ELSIF UPPER(:OLD.sexo) = 'OUTRO' THEN
        END IF;
    END IF;
END;
/

CREATE OR REPLACE TRIGGER delete_cliente
INSTEAD OF DELETE ON cliente
FOR EACH ROW
BEGIN
    IF UPPER(:OLD.sexo) = 'HOME' THEN
        DELETE FROM cliente_home WHERE dni = :OLD.dni;
        DELETE FROM sesion_home WHERE cliente = :OLD.dni;
    ELSIF UPPER(:OLD.sexo) = 'MULLER' THEN
        DELETE FROM cliente_muller WHERE dni = :OLD.dni;
        DELETE FROM sesion_muller WHERE cliente = :OLD.dni;
    ELSIF UPPER(:OLD.sexo) = 'OUTRO' THEN
        DELETE FROM cliente_outro WHERE dni = :OLD.dni;
        DELETE FROM sesion_outro WHERE cliente = :OLD.dni;
    END IF;
END;
/

CREATE OR REPLACE TRIGGER insert_sesion
INSTEAD OF INSERT ON sesion
FOR EACH ROW
DECLARE
    countN NUMBER;
    clienteAux cliente%ROWTYPE;
BEGIN
    SELECT COUNT(*) INTO countN
    FROM sesion
    WHERE codsesion = :NEW.codsesion;
    
    IF countN != 0 THEN
        RAISE_APPLICATION_ERROR(-20001, 'Sesión ' || :NEW.codsesion || ' ya existe.');
    END IF;
    
    SELECT COUNT(*) INTO countN
    FROM cliente
    WHERE dni = :NEW.cliente;
    
    IF countN = 0 THEN
        RAISE_APPLICATION_ERROR(-20002, 'Cliente ' || :NEW.cliente || ' no existe.');
    END IF;
    
    SELECT * INTO clienteAux
    FROM cliente
    WHERE dni = :NEW.cliente;
    
    IF UPPER(clienteAux.sexo) = 'HOME' THEN
        INSERT INTO sesion_home VALUES (:NEW.codsesion, :NEW.datahora, :NEW.cliente);
    ELSIF UPPER(clienteAux.sexo) = 'MULLER' THEN
        INSERT INTO sesion_muller VALUES (:NEW.codsesion, :NEW.datahora, :NEW.cliente);
    ELSIF UPPER(clienteAux.sexo) = 'OUTRO' THEN
        INSERT INTO sesion_outro VALUES (:NEW.codsesion, :NEW.datahora, :NEW.cliente);
    END IF;
END;
/

CREATE OR REPLACE TRIGGER update_sesion
INSTEAD OF UPDATE ON sesion
FOR EACH ROW
DECLARE
    countN NUMBER;
    clienteAux cliente%ROWTYPE;
    oldClienteAux cliente%ROWTYPE;
BEGIN
    IF :NEW.codsesion != :OLD.codsesion THEN
        RAISE_APPLICATION_ERROR();
    END IF;
END;
/

CREATE OR REPLACE TRIGGER delete_sesion
INSTEAD OF DELETE ON sesion
FOR EACH ROW
DECLARE
    countN NUMBER;
    clienteAux cliente%ROWTYPE;
BEGIN
    SELECT COUNT(*) INTO countN
    FROM cliente
    WHERE dni = :OLD.cliente;
    
    IF countN = 0 THEN
        RAISE_APPLICATION_ERROR(-20004, 'Cliente ' || :OLD.cliente || ' no existe.');
    END IF;
    
    SELECT * INTO clienteAux
    FROM cliente
    WHERE dni = :OLD.cliente;
    
    IF UPPER(clienteAux.sexo) = 'HOME' THEN
        DELETE FROM sesion_home WHERE codsesion = :OLD.codsesion;
    ELSIF UPPER(clienteAux.sexo) = 'MULLER' THEN
        DELETE FROM sesion_muller WHERE codsesion = :OLD.codsesion;
    ELSIF UPPER(clienteAux.sexo) = 'OUTRO' THEN
        DELETE FROM sesion_outro WHERE codsesion = :OLD.codsesion;
    END IF;
END;
/
