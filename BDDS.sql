DROP TABLE sesion_home CASCADE CONSTRAINTS;
DROP TABLE sesion_muller CASCADE CONSTRAINTS;
DROP TABLE cliente_home CASCADE CONSTRAINTS;
DROP TABLE cliente_muller CASCADE CONSTRAINTS;

CREATE TABLE cliente_home (
    dni VARCHAR2(10) PRIMARY KEY,
    nome VARCHAR2(25) NOT NULL,
    sexo CHAR(1),
    telefono VARCHAR2(10)
);

CREATE TABLE cliente_muller (
    dni VARCHAR2(10) PRIMARY KEY,
    nome VARCHAR2(25) NOT NULL,
    sexo CHAR(1),
    telefono VARCHAR2(10)
);

CREATE TABLE sesion_home (
    codsesion NUMBER(6) PRIMARY KEY,
    datahora DATE,
    cliente VARCHAR2(10) NOT NULL,
    FOREIGN KEY (cliente) REFERENCES cliente_home(dni) ON DELETE CASCADE
);

CREATE TABLE sesion_muller (
    codsesion NUMBER(6) PRIMARY KEY,
    datahora DATE,
    cliente VARCHAR2(10) NOT NULL,
    FOREIGN KEY (cliente) REFERENCES cliente_muller(dni) ON DELETE CASCADE
);

INSERT INTO cliente_home VALUES('91426928L', 'Manu', 'H', '1234567890');
INSERT INTO cliente_home VALUES('14533326V', 'Abel', 'H', '2345678901');
INSERT INTO cliente_home VALUES('74964665Y', 'Damián', 'H', '3456789012');

INSERT INTO cliente_muller VALUES('98286479G', 'Charo', 'M', '4567890123');
INSERT INTO cliente_muller VALUES('34933124B', 'Íngrid', 'M', '5678901234');
INSERT INTO cliente_muller VALUES('75749467W', 'Fabiola', 'M', '6789012345');

INSERT INTO sesion_home VALUES(1, TO_DATE('2023-06-10 09:00:00', 'YYYY-MM-DD HH24:MI:SS'), '91426928L');
INSERT INTO sesion_home VALUES(2, TO_DATE('2023-06-10 14:00:00', 'YYYY-MM-DD HH24:MI:SS'), '14533326V');
INSERT INTO sesion_home VALUES(3, TO_DATE('2023-06-11 10:30:00', 'YYYY-MM-DD HH24:MI:SS'), '74964665Y');

INSERT INTO sesion_muller VALUES(1, TO_DATE('2023-06-10 11:00:00', 'YYYY-MM-DD HH24:MI:SS'), '98286479G');
INSERT INTO sesion_muller VALUES(2, TO_DATE('2023-06-11 15:30:00', 'YYYY-MM-DD HH24:MI:SS'), '34933124B');
INSERT INTO sesion_muller VALUES(3, TO_DATE('2023-06-12 12:00:00', 'YYYY-MM-DD HH24:MI:SS'), '75749467W');

CREATE OR REPLACE VIEW cliente AS
SELECT * FROM cliente_home
UNION
SELECT * FROM cliente_muller;

CREATE OR REPLACE VIEW sesion AS
SELECT * FROM sesion_home
UNION
SELECT * FROM sesion_muller;

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
        RAISE_APPLICATION_ERROR(-20001, 'O cliente ' || :NEW.dni || ' xa existe.');
    END IF;

    IF UPPER(:NEW.sexo) = 'H' THEN
        INSERT INTO cliente_home VALUES (:NEW.dni, :NEW.nome, :NEW.sexo, :NEW.telefono);
    ELSIF UPPER(:NEW.sexo) = 'M' THEN
        INSERT INTO cliente_muller VALUES (:NEW.dni, :NEW.nome, :NEW.sexo, :NEW.telefono);
    ELSE
        RAISE_APPLICATION_ERROR(-20002, 'Non hai clientes co sexo: ' || :NEW.sexo);
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
        RAISE_APPLICATION_ERROR(-20001, 'A sesión ' || :NEW.codsesion || ' xa existe.');
    END IF;

    SELECT COUNT(*) INTO countN
    FROM cliente
    WHERE dni = :NEW.cliente;

    IF countN = 0 THEN
        RAISE_APPLICATION_ERROR(-20003, 'O cliente ' || :NEW.cliente || ' non existe.');
    END IF;

    SELECT * INTO clienteAux
    FROM cliente
    WHERE dni = :NEW.cliente;

    IF UPPER(clienteAux.sexo) = 'H' THEN
        INSERT INTO sesion_home VALUES (:NEW.codsesion, :NEW.datahora, :NEW.cliente);
    ELSIF UPPER(clienteAux.sexo) = 'M' THEN
        INSERT INTO sesion_muller VALUES (:NEW.codsesion, :NEW.datahora, :NEW.cliente);
    END IF;
END;
/

CREATE OR REPLACE TRIGGER delete_cliente
INSTEAD OF DELETE ON cliente
FOR EACH ROW
BEGIN
    IF UPPER(:OLD.sexo) = 'H' THEN
        DELETE FROM sesion_home WHERE cliente = :OLD.dni;
        DELETE FROM cliente_home WHERE dni = :OLD.dni;
    ELSIF UPPER(:OLD.sexo) = 'M' THEN
        DELETE FROM sesion_muller WHERE cliente = :OLD.dni;
        DELETE FROM cliente_muller WHERE dni = :OLD.dni;
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
        RAISE_APPLICATION_ERROR(-20003, 'O cliente ' || :OLD.cliente || ' non existe.');
    END IF;

    SELECT * INTO clienteAux
    FROM cliente
    WHERE dni = :OLD.cliente;

    IF UPPER(clienteAux.sexo) = 'H' THEN
        DELETE FROM sesion_home WHERE codsesion = :OLD.codsesion;
    ELSIF UPPER(clienteAux.sexo) = 'M' THEN
        DELETE FROM sesion_muller WHERE codsesion = :OLD.codsesion;
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
        RAISE_APPLICATION_ERROR(-20004, 'Non se pode cambiar o DNI.');
    END IF;

    IF :NEW.nome != :OLD.nome THEN
        IF UPPER(:OLD.sexo) = 'H' THEN
            UPDATE cliente_home SET nome = :NEW.nome WHERE dni = :OLD.dni;
        ELSIF UPPER(:OLD.sexo) = 'M' THEN
            UPDATE cliente_muller SET nome = :NEW.nome WHERE dni = :OLD.dni;
        END IF;
    END IF;

    IF :NEW.sexo != :OLD.sexo THEN
        IF UPPER(:NEW.sexo) = 'H' THEN
            INSERT INTO cliente_home SELECT dni, nome, :NEW.sexo, telefono FROM cliente_muller WHERE dni = :OLD.dni;
            INSERT INTO sesion_home SELECT * FROM sesion_muller WHERE cliente = :OLD.dni;
            DELETE FROM sesion_muller WHERE cliente = :OLD.dni;
            DELETE FROM cliente_muller WHERE dni = :OLD.dni;
        ELSIF UPPER(:NEW.sexo) = 'M' THEN
            INSERT INTO cliente_muller SELECT dni, nome, :NEW.sexo, telefono FROM cliente_home WHERE dni = :OLD.dni;
            INSERT INTO sesion_muller SELECT * FROM sesion_home WHERE cliente = :OLD.dni;
            DELETE FROM sesion_home WHERE cliente = :OLD.dni;
            DELETE FROM cliente_home WHERE dni = :OLD.dni;
        ELSE
            RAISE_APPLICATION_ERROR(-20005, 'Sexo non válido: ' || :NEW.sexo);
        END IF;
    END IF;

    IF :NEW.telefono != :OLD.telefono THEN
        IF UPPER(:OLD.sexo) = 'H' THEN
            UPDATE cliente_home SET telefono = :NEW.telefono WHERE dni = :OLD.dni;
        ELSIF UPPER(:OLD.sexo) = 'M' THEN
            UPDATE cliente_muller SET telefono = :NEW.telefono WHERE dni = :OLD.dni;
        END IF;
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
        RAISE_APPLICATION_ERROR(-20004, 'Non se pode cambiar o código de sesión.');
    END IF;

    SELECT COUNT(*) INTO countN
    FROM cliente
    WHERE dni = :NEW.cliente;

    IF countN = 0 THEN
        RAISE_APPLICATION_ERROR(-20003, 'O cliente ' || :NEW.cliente || ' non existe.');
    END IF;

    SELECT * INTO clienteAux
    FROM cliente
    WHERE dni = :NEW.cliente;

    IF :OLD.datahora != :NEW.datahora THEN
        IF UPPER(clienteAux.sexo) = 'H' THEN
            UPDATE sesion_home SET datahora = :NEW.datahora WHERE codsesion = :OLD.codsesion;
        ELSIF UPPER(clienteAux.sexo) = 'M' THEN
            UPDATE sesion_muller SET datahora = :NEW.datahora WHERE codsesion = :OLD.codsesion;
        END IF;
    END IF;

    IF :OLD.cliente != :NEW.cliente THEN
        SELECT * INTO oldClienteAux
        FROM cliente
        WHERE dni = :OLD.cliente;

        IF UPPER(clienteAux.sexo) = UPPER(oldClienteAux.sexo) THEN
            IF UPPER(clienteAux.sexo) = 'H' THEN
                UPDATE sesion_home SET cliente = :NEW.cliente WHERE codsesion = :OLD.codsesion;
            ELSIF UPPER(clienteAux.sexo) = 'M' THEN
                UPDATE sesion_muller SET cliente = :NEW.cliente WHERE codsesion = :OLD.codsesion;
            END IF;
        ELSE
            IF UPPER(clienteAux.sexo) = 'H' THEN
                INSERT INTO sesion_home SELECT codsesion, datahora, :NEW.cliente FROM sesion_muller WHERE codsesion = :OLD.codsesion;
                DELETE FROM sesion_muller WHERE codsesion = :OLD.codsesion;
            ELSIF UPPER(clienteAux.sexo) = 'M' THEN
                INSERT INTO sesion_muller SELECT codsesion, datahora, :NEW.cliente FROM sesion_home WHERE codsesion = :OLD.codsesion;
                DELETE FROM sesion_home WHERE codsesion = :OLD.codsesion;
            END IF;
        END IF;
    END IF;
END;
/
