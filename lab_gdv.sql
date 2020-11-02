-- DROP ALL

DROP TABLE "GRUSHEVSKAYA_ALBUM";
DROP TYPE GRUSHEVSKAYA_RECORD_ARR;
DROP TABLE "GRUSHEVSKAYA_RECORD";
DROP TYPE GRUSHEVSKAYA_SINGER_TAB;
DROP TABLE "GRUSHEVSKAYA_DICTIONARY_STYLE";
DROP TABLE "GRUSHEVSKAYA_SINGER";

-- SINGER

CREATE TABLE "GRUSHEVSKAYA_SINGER"(
    "NAME" VARCHAR2(100 BYTE),
    "NICKNAME" VARCHAR2(100 BYTE),
    "COUNTRY" VARCHAR2(100 BYTE)
);

ALTER TABLE "GRUSHEVSKAYA_SINGER" ADD CONSTRAINT "GRUSHEVSKAYA_SINGER_PK" PRIMARY KEY("NAME") ENABLE;
ALTER TABLE "GRUSHEVSKAYA_SINGER" MODIFY ("NAME" NOT NULL ENABLE);

ALTER TABLE "GRUSHEVSKAYA_SINGER" ADD CONSTRAINT "GRUSHEVSKAYA_SINGER_UK" UNIQUE ("NAME", "NICKNAME") ENABLE;

ALTER TABLE "GRUSHEVSKAYA_SINGER" MODIFY ("COUNTRY" NOT NULL ENABLE);

-- STYLE

CREATE TABLE "GRUSHEVSKAYA_DICTIONARY_STYLE"(
    "NAME" VARCHAR2(100 BYTE)
        PRIMARY KEY
        NOT NULL
);

-- RECORD

CREATE TYPE GRUSHEVSKAYA_SINGER_TAB AS TABLE OF VARCHAR2(1);
/

CREATE TABLE "GRUSHEVSKAYA_RECORD"(
    "ID" NUMBER(10,0),
    "NAME" VARCHAR2(100 BYTE),
    "TIME" TIMESTAMP,
    "STYLE" VARCHAR2(100 BYTE),
    "SINGER_LIST" GRUSHEVSKAYA_SINGER_TAB
)NESTED TABLE "SINGER_LIST"
    STORE AS GRUSHEVSKAYA_SINGER_LIST;

ALTER TABLE "GRUSHEVSKAYA_RECORD" ADD CONSTRAINT "GRUSHEVSKAYA_RECORD_PK" PRIMARY KEY("ID") ENABLE;
ALTER TABLE "GRUSHEVSKAYA_RECORD" MODIFY ("ID" NOT NULL ENABLE);

ALTER TABLE "GRUSHEVSKAYA_RECORD" MODIFY ("NAME" NOT NULL ENABLE);

ALTER TABLE "GRUSHEVSKAYA_RECORD" MODIFY ("TIME" NOT NULL ENABLE);

ALTER TABLE "GRUSHEVSKAYA_RECORD" ADD CONSTRAINT "GRUSHEVSKAYA_RECORD_FK" FOREIGN KEY ("STYLE")
    REFERENCES "GRUSHEVSKAYA_DICTIONARY_STYLE" ("NAME") ON DELETE SET NULL ENABLE;
    
-- ALBUM

CREATE TYPE GRUSHEVSKAYA_RECORD_ARR AS VARRAY(30) OF NUMBER(10,0);
/

CREATE TABLE "GRUSHEVSKAYA_ALBUM"(
    "ID" NUMBER(10, 0),
    "NAME" VARCHAR2(100 BYTE),
    "PRICE" NUMBER(6,2),
    "QUANTITY_IN_STOCK" NUMBER(5, 0),
    "QUANTITY_OF_SOLD" NUMBER(5, 0),
    "RECORD_ARRAY" GRUSHEVSKAYA_RECORD_ARR
);

ALTER TABLE "GRUSHEVSKAYA_ALBUM" ADD CONSTRAINT "GRUSHEVSKAYA_ALBUM_PK" PRIMARY KEY("ID") ENABLE;
ALTER TABLE "GRUSHEVSKAYA_ALBUM" MODIFY ("ID" NOT NULL ENABLE);

ALTER TABLE "GRUSHEVSKAYA_ALBUM" MODIFY ("NAME" NOT NULL ENABLE);

ALTER TABLE "GRUSHEVSKAYA_ALBUM" MODIFY ("PRICE" NOT NULL ENABLE);
ALTER TABLE "GRUSHEVSKAYA_ALBUM" ADD CONSTRAINT "GRUSHEVSKAYA_ALBUM_CHK1" CHECK ("PRICE" >= 0) ENABLE;

ALTER TABLE "GRUSHEVSKAYA_ALBUM" MODIFY ("QUANTITY_IN_STOCK" NOT NULL ENABLE);
ALTER TABLE "GRUSHEVSKAYA_ALBUM" ADD CONSTRAINT "GRUSHEVSKAYA_ALBUM_CHK2" CHECK ("QUANTITY_IN_STOCK" >= 0) ENABLE;

ALTER TABLE "GRUSHEVSKAYA_ALBUM" MODIFY ("QUANTITY_OF_SOLD" NOT NULL ENABLE);
ALTER TABLE "GRUSHEVSKAYA_ALBUM" ADD CONSTRAINT "GRUSHEVSKAYA_ALBUM_CHK3" CHECK ("QUANTITY_OF_SOLD" >= 0) ENABLE;

ALTER TABLE "GRUSHEVSKAYA_ALBUM" MODIFY ("RECORD_ARRAY" NOT NULL ENABLE);

-------------------- ����� �������-��-������

CREATE OR REPLACE TRIGGER GRUSHEVSKAYA_TR_ON_RECORDS
BEFORE INSERT OR UPDATE ON GRUSHEVSKAYA_RECORD
FOR EACH ROW
DECLARE
    LIST_NAME GRUSHEVSKAYA_SINGER_TAB;
    ERROR_RECORD EXCEPTION;
BEGIN
    FOR i IN 1..:NEW.SINGER_LIST.COUNT
    LOOP
        IF :NEW.SINGER_LIST(i) IS NULL THEN 
            :NEW.SINGER_LIST.DELETE(i);
        END IF;
    END LOOP;
    :NEW.SINGER_LIST := SET(:NEW.SINGER_LIST);
    SELECT NAME BULK COLLECT INTO LIST_NAME FROM GRUSHEVSKAYA_SINGER;
    IF :NEW.SINGER_LIST NOT SUBMULTISET OF LIST_NAME THEN
        IF INSERTING THEN
            DBMS_OUTPUT.PUT_LINE('������������ ������ ������������.');
            RAISE ERROR_RECORD;
        ELSE
            :NEW.ID := :OLD.ID;
            :NEW.NAME := :OLD.NAME;
            :NEW.TIME := :OLD.TIME;
            :NEW.STYLE := :OLD.STYLE;
            :NEW.SINGER_LIST := :OLD.SINGER_LIST;
            DBMS_OUTPUT.PUT_LINE('������ � ��������������� ' || :OLD.ID || ' �� ���� ��������� ��-�� ��������� �������� �����.');
        END IF;
    END IF;
END;
/
CREATE OR REPLACE TRIGGER GRUSHEVSKAYA_TR_ON_SINGERS_DEL
BEFORE DELETE ON GRUSHEVSKAYA_SINGER
FOR EACH ROW
DECLARE    
    ERROR_SINGER_DEL EXCEPTION;
BEGIN
    FOR RECORD_ROW IN (SELECT * FROM GRUSHEVSKAYA_RECORD)
    LOOP
        FOR i IN 1..RECORD_ROW.SINGER_LIST.COUNT
        LOOP
            IF RECORD_ROW.SINGER_LIST(i) = :OLD.NAME THEN
                DBMS_OUTPUT.PUT_LINE('����������� � ��������������� ' || :OLD.NAME || ' ������� ������ - � ���� ���� �����.');
                RAISE ERROR_SINGER_DEL;
            END IF;
        END LOOP;
    END LOOP;
END;
/
CREATE OR REPLACE TRIGGER GRUSHEVSKAYA_TR_ON_SINGERS_UDP
FOR UPDATE OF NAME ON GRUSHEVSKAYA_SINGER
COMPOUND TRIGGER
    TYPE CHANGES_ARR IS TABLE OF VARCHAR2(100 BYTE) INDEX BY PLS_INTEGER;
    SINGERS_CHANGES CHANGES_ARR;
    AFTER EACH ROW IS
    BEGIN
        SINGERS_CHANGES(:OLD.NAME) := :NEW.NAME;
    END AFTER EACH ROW;
    AFTER STATEMENT IS
        LIST_NAME GRUSHEVSKAYA_SINGER_TAB;
        FLAG BOOLEAN := FALSE;
    BEGIN
        FOR RECORD_ROW IN (SELECT * FROM GRUSHEVSKAYA_RECORD)
        LOOP
            FLAG := FALSE;
            LIST_NAME := RECORD_ROW.SINGER_LIST;
            FOR i IN 1..LIST_NAME.COUNT 
            LOOP
                IF SINGERS_CHANGES.EXISTS(LIST_NAME(i)) THEN
                    LIST_NAME(i) := SINGERS_CHANGES(LIST_NAME(i));
                    FLAG := TRUE;
                END IF;
            END LOOP;
            IF FLAG = TRUE THEN
                UPDATE GRUSHEVSKAYA_RECORD
                    SET SINGER_LIST = SET(LIST_NAME)
                    WHERE ID = RECORD_ROW.ID;
            END IF;
        END LOOP;
    END AFTER STATEMENT;
END;











