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

	IF (countN != 0) THEN
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
BEGIN
	IF :NEW.dni != :OLD.dni THEN
		RAISE_APPLICATION_ERROR(-20006, 'No se puede cambiar el DNI.');
	END IF;

    -- Código para actualizar el cliente

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
BEGIN

    -- Código para insertar en la tabla de sesiones correspondiente

END;
/

CREATE OR REPLACE TRIGGER update_sesion
INSTEAD OF UPDATE ON sesion
FOR EACH ROW
BEGIN

    -- Código para actualizar la tabla de sesiones correspondiente

END;
/

CREATE OR REPLACE TRIGGER delete_sesion
INSTEAD OF DELETE ON sesion
FOR EACH ROW
BEGIN

    -- Código para eliminar de la tabla de sesiones correspondiente

END;
/
