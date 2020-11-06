-- DROP ALL

DROP TABLE GRUSHEVSKAYA_ALBUM;
DROP TYPE GRUSHEVSKAYA_RECORD_ARR;
DROP TABLE GRUSHEVSKAYA_RECORD;
DROP TYPE GRUSHEVSKAYA_SINGER_TAB;
DROP TABLE GRUSHEVSKAYA_DICT_STYLE;
DROP TABLE GRUSHEVSKAYA_SINGER;
DROP TABLE GRUSHEVSKAYA_DICT_COUNTRY;
/

--����� � ������������

CREATE OR REPLACE 
PACKAGE GRUSHEVSKAYA_EXCEPTIONS AS
    INVALIDE_TYPE_FIELDS EXCEPTION;
    ERROR_RECORD EXCEPTION;
    ERROR_SINGER_DEL EXCEPTION;
    ERROR_ALBUM EXCEPTION;
    ERROR_RECORD_DEL EXCEPTION;
    LONG_VARCHAR2 EXCEPTION;
END;
/

-- COUNTRY - ��������������� �������, ���������� ������� �����. 
-- ��������� ��������, ����� ���-�� ������ "��", � ���-�� "������".

CREATE TABLE GRUSHEVSKAYA_DICT_COUNTRY(
    NAME VARCHAR2(100 BYTE)
        PRIMARY KEY
        NOT NULL
);

-- SINGER - �����������

CREATE TABLE GRUSHEVSKAYA_SINGER(
    NAME VARCHAR2(100 BYTE),
    NICKNAME VARCHAR2(100 BYTE),
    COUNTRY VARCHAR2(100 BYTE)
);

ALTER TABLE GRUSHEVSKAYA_SINGER 
    ADD CONSTRAINT GRUSHEVSKAYA_SINGER_PK 
    PRIMARY KEY(NAME) ENABLE;
ALTER TABLE GRUSHEVSKAYA_SINGER 
    MODIFY (NAME NOT NULL ENABLE);

ALTER TABLE GRUSHEVSKAYA_SINGER 
    ADD CONSTRAINT GRUSHEVSKAYA_SINGER_UK 
    UNIQUE (NAME, NICKNAME) ENABLE;

ALTER TABLE GRUSHEVSKAYA_SINGER 
    MODIFY (COUNTRY NOT NULL ENABLE);
    
ALTER TABLE GRUSHEVSKAYA_SINGER 
    ADD CONSTRAINT GRUSHEVSKAYA_SINGER_FK 
    FOREIGN KEY (COUNTRY)
    REFERENCES GRUSHEVSKAYA_DICT_COUNTRY (NAME) 
    ON DELETE SET NULL ENABLE;

-- STYLE - ��������������� �������, ���������� ������� ������

CREATE TABLE GRUSHEVSKAYA_DICT_STYLE(
    NAME VARCHAR2(100 BYTE)
        PRIMARY KEY
        NOT NULL
);

-- RECORD - ������ 
CREATE OR REPLACE 
TYPE GRUSHEVSKAYA_TIME AS OBJECT(
    HOURS NUMBER(2,0),
    MINUTES NUMBER(2,0),
    SECONDS NUMBER(2,0),
    CONSTRUCTOR FUNCTION GRUSHEVSKAYA_TIME(
        HOURS IN NUMBER DEFAULT 0,
        MINUTES IN NUMBER DEFAULT 0,
        SECONDS IN NUMBER DEFAULT 0
    ) RETURN SELF AS RESULT,
    MEMBER FUNCTION ACCUMULATE(
        TIME GRUSHEVSKAYA_TIME
    ) RETURN GRUSHEVSKAYA_TIME,
    MEMBER FUNCTION PRINT RETURN VARCHAR2
);
/
CREATE OR REPLACE 
TYPE BODY GRUSHEVSKAYA_TIME AS 
    CONSTRUCTOR FUNCTION GRUSHEVSKAYA_TIME(
        HOURS IN NUMBER DEFAULT 0,
        MINUTES IN NUMBER DEFAULT 0,
        SECONDS IN NUMBER DEFAULT 0
        ) RETURN SELF AS RESULT AS
    BEGIN
        IF HOURS IS NULL OR MINUTES IS NULL OR SECONDS IS NULL THEN 
            RAISE GRUSHEVSKAYA_EXCEPTIONS.INVALIDE_TYPE_FIELDS;
        END IF;
        IF HOURS > 23 OR MINUTES > 60 OR SECONDS > 60 THEN 
            RAISE GRUSHEVSKAYA_EXCEPTIONS.INVALIDE_TYPE_FIELDS;
        END IF;
        SELF.HOURS := HOURS;
        SELF.MINUTES := MINUTES;
        SELF.SECONDS := SECONDS;
        RETURN;
    END GRUSHEVSKAYA_TIME;    
    
    MEMBER FUNCTION ACCUMULATE(
        TIME GRUSHEVSKAYA_TIME
    ) RETURN GRUSHEVSKAYA_TIME
    IS
        RESULT_SECONDS NUMBER := 0;
        RESULT_MINUTES NUMBER := 0;
        RESULT_HOURS NUMBER := 0;
        RESULT_TIME GRUSHEVSKAYA_TIME;
    BEGIN
        RESULT_SECONDS := MOD(SELF.SECONDS + TIME.SECONDS, 60);
        RESULT_MINUTES := (
                SELF.MINUTES 
                + TIME.MINUTES 
                + FLOOR((SELF.SECONDS + TIME.SECONDS) / 60)
            ) MOD 60;
        RESULT_HOURS := MOD(
                SELF.HOURS 
                + TIME.HOURS 
                + FLOOR(
                    (
                        SELF.MINUTES 
                        + TIME.MINUTES 
                        + FLOOR((SELF.SECONDS + TIME.SECONDS) / 60)
                     ) / 60), 
            24);
        RESULT_TIME := GRUSHEVSKAYA_TIME(
            RESULT_HOURS,
            RESULT_MINUTES,
            RESULT_SECONDS
        );
        RETURN RESULT_TIME;
    END ACCUMULATE;
    
    MEMBER FUNCTION PRINT RETURN VARCHAR2
    IS
    BEGIN
        RETURN LPAD(SELF.HOURS, 2, '0') || ':' || LPAD(SELF.MINUTES, 2, '0') || ':' ||  LPAD(SELF.SECONDS, 2, '0');
    END PRINT;
END;
/
CREATE TYPE GRUSHEVSKAYA_SINGER_TAB AS TABLE OF VARCHAR2(100 BYTE);
/
CREATE TABLE GRUSHEVSKAYA_RECORD(
    ID NUMBER(10,0),
    NAME VARCHAR2(100 BYTE),
    TIME GRUSHEVSKAYA_TIME,
    STYLE VARCHAR2(100 BYTE),
    SINGER_LIST GRUSHEVSKAYA_SINGER_TAB
)NESTED TABLE SINGER_LIST
    STORE AS GRUSHEVSKAYA_SINGER_LIST;

ALTER TABLE GRUSHEVSKAYA_RECORD 
    ADD CONSTRAINT GRUSHEVSKAYA_RECORD_PK 
    PRIMARY KEY(ID) ENABLE;
ALTER TABLE GRUSHEVSKAYA_RECORD 
    MODIFY (ID NOT NULL ENABLE);

ALTER TABLE GRUSHEVSKAYA_RECORD 
    MODIFY (NAME NOT NULL ENABLE);

ALTER TABLE GRUSHEVSKAYA_RECORD 
    MODIFY (TIME NOT NULL ENABLE);

ALTER TABLE GRUSHEVSKAYA_RECORD 
    ADD CONSTRAINT GRUSHEVSKAYA_RECORD_FK 
    FOREIGN KEY (STYLE)
    REFERENCES GRUSHEVSKAYA_DICT_STYLE (NAME) 
    ON DELETE SET NULL ENABLE;
    
-- ALBUM - �������

CREATE TYPE GRUSHEVSKAYA_RECORD_ARR AS VARRAY(30) OF NUMBER(10,0);
/
CREATE TABLE GRUSHEVSKAYA_ALBUM(
    ID NUMBER(10, 0),
    NAME VARCHAR2(100 BYTE),
    PRICE NUMBER(6,2),
    QUANTITY_IN_STOCK NUMBER(5, 0),
    QUANTITY_OF_SOLD NUMBER(5, 0),
    RECORD_ARRAY GRUSHEVSKAYA_RECORD_ARR
);

ALTER TABLE GRUSHEVSKAYA_ALBUM 
    ADD CONSTRAINT GRUSHEVSKAYA_ALBUM_PK 
    PRIMARY KEY(ID) ENABLE;
ALTER TABLE GRUSHEVSKAYA_ALBUM 
    MODIFY (ID NOT NULL ENABLE);

ALTER TABLE GRUSHEVSKAYA_ALBUM 
    MODIFY (NAME NOT NULL ENABLE);

ALTER TABLE GRUSHEVSKAYA_ALBUM 
    MODIFY (PRICE NOT NULL ENABLE);
ALTER TABLE GRUSHEVSKAYA_ALBUM 
    ADD CONSTRAINT GRUSHEVSKAYA_ALBUM_CHK1 
    CHECK (PRICE >= 0) ENABLE;

ALTER TABLE GRUSHEVSKAYA_ALBUM 
    MODIFY (QUANTITY_IN_STOCK NOT NULL ENABLE);
ALTER TABLE GRUSHEVSKAYA_ALBUM 
    ADD CONSTRAINT GRUSHEVSKAYA_ALBUM_CHK2 
    CHECK (QUANTITY_IN_STOCK >= 0) ENABLE;

ALTER TABLE GRUSHEVSKAYA_ALBUM 
    MODIFY (QUANTITY_OF_SOLD NOT NULL ENABLE);
ALTER TABLE GRUSHEVSKAYA_ALBUM 
    ADD CONSTRAINT GRUSHEVSKAYA_ALBUM_CHK3 
    CHECK (QUANTITY_OF_SOLD >= 0) ENABLE;

ALTER TABLE GRUSHEVSKAYA_ALBUM 
    MODIFY (RECORD_ARRAY NOT NULL ENABLE);
/
--����� �������-��-������ SINGER-RECORD

--����� �������� ��� ����������� ������
--������� NULL-�������� ������������ � ��������� ������ ������������.
--���� ������������ ������������ �� ������������� ������� ������������,
--�� �������� ������� ��� �������� ����������
CREATE OR REPLACE 
TRIGGER GRUSHEVSKAYA_TR_ON_RECORDS
BEFORE INSERT OR UPDATE ON GRUSHEVSKAYA_RECORD
FOR EACH ROW
DECLARE
    LIST_NAME GRUSHEVSKAYA_SINGER_TAB;
    FLAG_RECORD_USES BOOLEAN := FALSE;
    ID_ARR GRUSHEVSKAYA_RECORD_ARR;
BEGIN
    -- �������� ������ �� ��.���.
    FOR i IN 1..:NEW.SINGER_LIST.COUNT
    LOOP
        IF :NEW.SINGER_LIST(i) IS NULL THEN 
            :NEW.SINGER_LIST.DELETE(i);
        END IF;
    END LOOP;
    :NEW.SINGER_LIST := SET(:NEW.SINGER_LIST);
    -- ������ ��� ���������� � ����� �� �������� => ��������� ���. ������
    FOR ALBUM_ROW IN (SELECT * FROM GRUSHEVSKAYA_ALBUM)
    LOOP
        ID_ARR := ALBUM_ROW.RECORD_ARRAY;
        FOR i IN 1..ID_ARR.COUNT
        LOOP
            IF ID_ARR(i) = :OLD.ID THEN
                FLAG_RECORD_USES := TRUE;
            END IF;
        END LOOP;
    END LOOP;
    IF UPDATING('SINGER_LIST')
        AND NOT FLAG_RECORD_USES
        AND NOT (SET(:NEW.SINGER_LIST) = SET(:OLD.SINGER_LIST)) THEN
            :NEW.ID := :OLD.ID;
            :NEW.NAME := :OLD.NAME;
            :NEW.TIME := :OLD.TIME;
            :NEW.STYLE := :OLD.STYLE;
            :NEW.SINGER_LIST := :OLD.SINGER_LIST;
            DBMS_OUTPUT.PUT_LINE('������ � ��������������� ' 
                || :OLD.ID 
                || ' �� ���� ���������. ������ ������������ ��������� ������,' 
                || ' ��� ��� ������ ��� ���������� � ����� �� ��������');        
    END IF;
    -- �������� ����.��.
    SELECT NAME BULK COLLECT INTO LIST_NAME FROM GRUSHEVSKAYA_SINGER;
    IF :NEW.SINGER_LIST NOT SUBMULTISET OF LIST_NAME THEN
        IF INSERTING THEN
            DBMS_OUTPUT.PUT_LINE('������������ ������ ������������.');
            RAISE GRUSHEVSKAYA_EXCEPTIONS.ERROR_RECORD;
        ELSE
            :NEW.ID := :OLD.ID;
            :NEW.NAME := :OLD.NAME;
            :NEW.TIME := :OLD.TIME;
            :NEW.STYLE := :OLD.STYLE;
            :NEW.SINGER_LIST := :OLD.SINGER_LIST;
            DBMS_OUTPUT.PUT_LINE('������ � ��������������� ' 
                || :OLD.ID 
                || ' �� ���� ��������� ��-�� ��������� �������� ����� (�����������).');
        END IF;
    END IF;
END;
/
--����� ��������� �����������
--����� ��������� ��� �� ��� ������ (�������).
--���� ����, �� ������� ������.
CREATE OR REPLACE 
TRIGGER GRUSHEVSKAYA_TR_ON_SINGERS_DEL
BEFORE DELETE ON GRUSHEVSKAYA_SINGER
FOR EACH ROW
BEGIN
    FOR RECORD_ROW IN (SELECT * FROM GRUSHEVSKAYA_RECORD)
    LOOP
        FOR i IN 1..RECORD_ROW.SINGER_LIST.COUNT
        LOOP
            IF RECORD_ROW.SINGER_LIST(i) = :OLD.NAME THEN
                DBMS_OUTPUT.PUT_LINE('����������� � ��������������� ' 
                    || :OLD.NAME 
                    || ' ������� ������ - � ���� ���� �����.');
                RAISE GRUSHEVSKAYA_EXCEPTIONS.ERROR_SINGER_DEL;
            END IF;
        END LOOP;
    END LOOP;
END;
/
--����� ���������� �����������
--����� �������� ��� ��� ��� ���� �������
--� �������� ���� ������
CREATE OR REPLACE 
TRIGGER GRUSHEVSKAYA_TR_ON_SINGERS_UDP
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
/
--����� �������-��-������ RECORD-ALBUM

--����� �������� ��� ����������� �������
--���������, ��� ��� ������ ����������.
--���� ���, �� ���� �������� ������, 
--���� �������� ����������
CREATE OR REPLACE 
TRIGGER GRUSHEVSKAYA_TR_ON_ALBUM
BEFORE INSERT OR UPDATE ON GRUSHEVSKAYA_ALBUM
FOR EACH ROW
DECLARE
    TYPE GRUSHEVSKAYA_RECORD_TAB IS TABLE OF NUMBER(10, 0);
    LIST_ID GRUSHEVSKAYA_RECORD_TAB;
BEGIN
    -- ���� ������ ������, �� ��������� ����� ������.
    IF UPDATING('RECORD_ARRAY') AND :OLD.QUANTITY_OF_SOLD > 0 THEN
        FOR j IN 1..:OLD.RECORD_ARRAY.COUNT
        LOOP
            IF :NEW.RECORD_ARRAY(j) IS NULL AND :OLD.RECORD_ARRAY(j) IS NULL THEN
                CONTINUE;
            END IF;
            IF :NEW.RECORD_ARRAY(j) IS NULL OR :OLD.RECORD_ARRAY(j) IS NULL THEN
                :NEW.ID := :OLD.ID;
                :NEW.NAME := :OLD.NAME;
                :NEW.PRICE := :OLD.PRICE;
                :NEW.QUANTITY_IN_STOCK := :OLD.QUANTITY_IN_STOCK;
                :NEW.QUANTITY_OF_SOLD := :OLD.QUANTITY_OF_SOLD;
                :NEW.RECORD_ARRAY := :OLD.RECORD_ARRAY;
                DBMS_OUTPUT.PUT_LINE('������ � ��������������� ' 
                    || :OLD.ID 
                    || ' �� ��� ��������. ������ ��������� �����, ���� ������ ������');
                RETURN;
            END IF;
            IF :NEW.RECORD_ARRAY(j) <> :OLD.RECORD_ARRAY(j) THEN
                :NEW.ID := :OLD.ID;
                :NEW.NAME := :OLD.NAME;
                :NEW.PRICE := :OLD.PRICE;
                :NEW.QUANTITY_IN_STOCK := :OLD.QUANTITY_IN_STOCK;
                :NEW.QUANTITY_OF_SOLD := :OLD.QUANTITY_OF_SOLD;
                :NEW.RECORD_ARRAY := :OLD.RECORD_ARRAY;
                DBMS_OUTPUT.PUT_LINE('������ � ��������������� ' 
                    || :OLD.ID 
                    || ' �� ��� ��������. ������ ��������� �����, ���� ������ ������');
                RETURN;          
            END IF;
        END LOOP;
    END IF;
    -- �������� ����.��.
    SELECT ID BULK COLLECT INTO LIST_ID FROM GRUSHEVSKAYA_RECORD;
    FOR i IN 1..:NEW.RECORD_ARRAY.COUNT
    LOOP
       IF NOT :NEW.RECORD_ARRAY(i) IS NULL
          AND NOT LIST_ID.EXISTS(:NEW.RECORD_ARRAY(i)) THEN
            IF INSERTING THEN
                DBMS_OUTPUT.PUT_LINE('������������ ������ �������.');
                RAISE GRUSHEVSKAYA_EXCEPTIONS.ERROR_ALBUM;
            ELSE
                :NEW.ID := :OLD.ID;
                :NEW.NAME := :OLD.NAME;
                :NEW.PRICE := :OLD.PRICE;
                :NEW.QUANTITY_IN_STOCK := :OLD.QUANTITY_IN_STOCK;
                :NEW.QUANTITY_OF_SOLD := :OLD.QUANTITY_OF_SOLD;
                :NEW.RECORD_ARRAY := :OLD.RECORD_ARRAY;
                DBMS_OUTPUT.PUT_LINE('������ � ��������������� ' 
                    || :OLD.ID 
                    || ' �� ��� �������� ��-�� ��������� �������� ����� (������).');
                RETURN;
            END IF;
        END IF;
    END LOOP;    
END;
/
--����� ��������� ������ ��������� ��� �� �� � ��������.
--���� ����, �� ������� ������.
CREATE OR REPLACE 
TRIGGER GRUSHEVSKAYA_TR_ON_RECORD_DEL
BEFORE DELETE ON GRUSHEVSKAYA_RECORD
FOR EACH ROW
BEGIN
    FOR ALBUM_ROW IN (SELECT * FROM GRUSHEVSKAYA_ALBUM)
    LOOP
        FOR i IN 1..ALBUM_ROW.RECORD_ARRAY.COUNT
        LOOP
            IF ALBUM_ROW.RECORD_ARRAY(i) = :OLD.ID THEN
                DBMS_OUTPUT.PUT_LINE('����� � ��������������� ' 
                    || :OLD.ID 
                    || ' ������� ������ - ��� ���� � �������.');
                RAISE GRUSHEVSKAYA_EXCEPTIONS.ERROR_RECORD_DEL;
            END IF;
        END LOOP;
    END LOOP;
END;
/
--����� ���������� ������ 
--����� �������� ��� �� id �� ���� ��������
--� �������� ���� �������
CREATE OR REPLACE 
TRIGGER GRUSHEVSKAYA_TR_ON_RECORD_UDP
FOR UPDATE OF ID ON GRUSHEVSKAYA_RECORD
COMPOUND TRIGGER
    TYPE CHANGES_ARR IS TABLE OF NUMBER(10,0) INDEX BY PLS_INTEGER;
    RECORD_CHANGES CHANGES_ARR;
    AFTER EACH ROW IS
    BEGIN
        RECORD_CHANGES(:OLD.ID) := :NEW.ID;
    END AFTER EACH ROW;
    AFTER STATEMENT IS
        ID_ARR GRUSHEVSKAYA_RECORD_ARR;
        FLAG BOOLEAN := FALSE;
    BEGIN
        FOR ALBUM_ROW IN (SELECT * FROM GRUSHEVSKAYA_ALBUM)
        LOOP
            FLAG := FALSE;
            ID_ARR := ALBUM_ROW.RECORD_ARRAY;
            FOR i IN 1..ID_ARR.COUNT 
            LOOP
                IF RECORD_CHANGES.EXISTS(ID_ARR(i)) THEN
                    ID_ARR(i) := RECORD_CHANGES(ID_ARR(i));
                    FLAG := TRUE;
                END IF;
            END LOOP;
            IF FLAG = TRUE THEN
                UPDATE GRUSHEVSKAYA_ALBUM
                    SET RECORD_ARRAY = ID_ARR
                    WHERE ID = ALBUM_ROW.ID;
            END IF;
        END LOOP;
    END AFTER STATEMENT;
END;
/
--

CREATE OR REPLACE 
PACKAGE GRUSHEVSKAYA_PACKAGE AS
    PROCEDURE ADD_IN_DICT_COUNTRY (
        NAME VARCHAR2
    );
    PROCEDURE ADD_IN_DICT_STYLE (
        NAME VARCHAR2
    );
    PROCEDURE ADD_RECORD (
        ID NUMBER, 
        NAME VARCHAR2, 
        HOURS NUMBER,
        MINUTES NUMBER,
        SECONDS NUMBER,
        STYLE VARCHAR2,
        SINGER VARCHAR2
    );
    PROCEDURE ADD_SINGER_IN_RECORD (
        RECORD_ID NUMBER,
        SINGER_NAME VARCHAR2
    );
    PROCEDURE ADD_SINGER (
        NAME VARCHAR2, 
        NICKNAME VARCHAR2, 
        COUNTRY VARCHAR2
    );
    PROCEDURE ADD_ALBUM (
        ID NUMBER,
        NAME VARCHAR2,
        PRICE NUMBER,
        QUANTITY_IN_STOCK NUMBER,
        QUANTITY_OF_SOLD NUMBER, 
        RECORD_ID NUMBER,
        RECORD_SERIAL_NUMBER NUMBER
    );
    PROCEDURE ADD_ALBUM (
        ID NUMBER,
        NAME VARCHAR2,
        PRICE NUMBER,
        QUANTITY_IN_STOCK NUMBER,
        QUANTITY_OF_SOLD NUMBER
    );
    PROCEDURE ADD_RECORD_IN_ALBUM (
        ALBUM_ID NUMBER, 
        RECORD_ID NUMBER,
        RECORD_SERIAL_NUMBER NUMBER
    );
    PROCEDURE PRINT_ALBUMS_IN_STOCK;
    PROCEDURE PRINT_SINGERS;
    PROCEDURE ADD_ALBUMS_IN_STOCK (
        ALBUM_ID NUMBER,
        QUANTITY NUMBER
    );
    PROCEDURE SELL_ALBUMS(
        ALBUM_ID NUMBER,
        QUANTITY NUMBER
    );
    PROCEDURE DELETE_SINGERS_WITHOUT_RECORDS;
    PROCEDURE PRINT_ALBUM_RECORDS(ALBUM_ID NUMBER);
END;
/
CREATE OR REPLACE
PACKAGE BODY GRUSHEVSKAYA_PACKAGE AS
    PROCEDURE PRINT_MSG_EX(SQLCODE NUMBER) IS
    BEGIN
        DBMS_OUTPUT.PUT_LINE('����������� ����������');
        DBMS_OUTPUT.PUT_LINE('���: ' || SQLCODE);
        DBMS_OUTPUT.PUT_LINE('���������: ' || SQLERRM(SQLCODE));        
    END PRINT_MSG_EX;
    
    PROCEDURE ADD_IN_DICT_COUNTRY (
        NAME VARCHAR2
    )IS
    BEGIN
        INSERT INTO GRUSHEVSKAYA_DICT_COUNTRY (NAME) VALUES (NAME);
        COMMIT;
    EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('EXCEPTION IN ADD_IN_DICT_COUNTRY');
        IF SQLCODE = -12899 THEN
            DBMS_OUTPUT.PUT_LINE('�������� ��� ������ �� �������� ������� ������');
        ELSIF SQLCODE = -1 THEN
            DBMS_OUTPUT.PUT_LINE('�������� ����������� ������������ ������ �� �����');
        ELSE
            PRINT_MSG_EX(SQLCODE);
        END IF;
    END ADD_IN_DICT_COUNTRY;
    
    PROCEDURE ADD_IN_DICT_STYLE (
        NAME VARCHAR2
    )IS
    BEGIN
        INSERT INTO GRUSHEVSKAYA_DICT_STYLE (NAME) VALUES (NAME);
        COMMIT;
    EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('EXCEPTION IN ADD_IN_DICT_STYLE');
        IF SQLCODE = -12899 THEN
            DBMS_OUTPUT.PUT_LINE('�������� ��� ������ �� �������� ������� ������');
        ELSIF SQLCODE = -1 THEN
            DBMS_OUTPUT.PUT_LINE('�������� ����������� ������������ ������ �� �����');
        ELSE
            PRINT_MSG_EX(SQLCODE);
        END IF;
    END ADD_IN_DICT_STYLE;
    
    PROCEDURE ADD_RECORD(
        ID NUMBER, 
        NAME VARCHAR2,
        HOURS NUMBER,
        MINUTES NUMBER,
        SECONDS NUMBER,
        STYLE VARCHAR2,
        SINGER VARCHAR2
    ) IS
        TIME GRUSHEVSKAYA_TIME;
    BEGIN
        TIME := NEW GRUSHEVSKAYA_TIME(HOURS, MINUTES, SECONDS);
        INSERT INTO GRUSHEVSKAYA_RECORD (ID, NAME, TIME, STYLE, SINGER_LIST)
            VALUES (ID, NAME, TIME, STYLE, GRUSHEVSKAYA_SINGER_TAB(SINGER));
        COMMIT;
    EXCEPTION
    WHEN GRUSHEVSKAYA_EXCEPTIONS.ERROR_RECORD THEN
        RETURN;
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('EXCEPTION IN ADD_RECORD');
        IF SQLCODE = -02291 THEN
            DBMS_OUTPUT.PUT_LINE('��� ������ ����� � �������');
        ELSIF SQLCODE = -12899 THEN
            DBMS_OUTPUT.PUT_LINE('�������� ��� ������ �� �������� ������� ������');
        ELSIF SQLCODE = -1 THEN
            DBMS_OUTPUT.PUT_LINE('�������� ����������� ������������ ������ �� �����');
        ELSE
            PRINT_MSG_EX(SQLCODE);
        END IF;
    END ADD_RECORD;
    
    
    PROCEDURE ADD_SINGER_IN_RECORD (
        RECORD_ID NUMBER,
        SINGER_NAME VARCHAR2
    ) IS
        TMP_SINGER_LIST GRUSHEVSKAYA_SINGER_TAB;
    BEGIN
        SELECT SINGER_LIST INTO TMP_SINGER_LIST 
            FROM GRUSHEVSKAYA_RECORD
            WHERE ID = RECORD_ID;
        TMP_SINGER_LIST.EXTEND;
        TMP_SINGER_LIST(TMP_SINGER_LIST.LAST) := SINGER_NAME;
        UPDATE GRUSHEVSKAYA_RECORD
            SET SINGER_LIST = TMP_SINGER_LIST
            WHERE ID = RECORD_ID;
        COMMIT;
    EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('EXCEPTION IN ADD_SINGER_IN_RECORD');
        IF SQLCODE = -12899 THEN
            DBMS_OUTPUT.PUT_LINE('�������� ��� ������ �� �������� ������� ������');
        ELSE
            PRINT_MSG_EX(SQLCODE);
        END IF;
    END ADD_SINGER_IN_RECORD;
    
    PROCEDURE ADD_SINGER (
        NAME VARCHAR2, 
        NICKNAME VARCHAR2, 
        COUNTRY VARCHAR2
    ) IS
    BEGIN
        INSERT INTO GRUSHEVSKAYA_SINGER (NAME, NICKNAME, COUNTRY)
            VALUES (NAME, NICKNAME, COUNTRY);
        COMMIT;
    EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('EXCEPTION IN ADD_SINGER');
        IF SQLCODE = -02291 THEN
            DBMS_OUTPUT.PUT_LINE('��� ����� ������ � �������');
        ELSIF SQLCODE = -12899 THEN
            DBMS_OUTPUT.PUT_LINE('�������� ��� ������ �� �������� ������� ������');
        ELSIF SQLCODE = -1 THEN
            DBMS_OUTPUT.PUT_LINE('�������� ����������� ������������ ������ �� �����');
        ELSE
            PRINT_MSG_EX(SQLCODE);
        END IF;
    END ADD_SINGER;
        
    PROCEDURE ADD_ALBUM (
        ID NUMBER,
        NAME VARCHAR2,
        PRICE NUMBER,
        QUANTITY_IN_STOCK NUMBER,
        QUANTITY_OF_SOLD NUMBER, 
        RECORD_ID NUMBER,
        RECORD_SERIAL_NUMBER NUMBER
    ) IS
        RECORD_ARR GRUSHEVSKAYA_RECORD_ARR := GRUSHEVSKAYA_RECORD_ARR();
    BEGIN
        RECORD_ARR.EXTEND(30);
        RECORD_ARR(RECORD_SERIAL_NUMBER) := RECORD_ID;
        INSERT INTO GRUSHEVSKAYA_ALBUM (
            ID, 
            NAME, 
            PRICE, 
            QUANTITY_IN_STOCK,
            QUANTITY_OF_SOLD,
            RECORD_ARRAY
        ) VALUES (
            ID, 
            NAME, 
            PRICE, 
            QUANTITY_IN_STOCK,
            QUANTITY_OF_SOLD,
            RECORD_ARR
        );
        COMMIT;
    EXCEPTION
    WHEN GRUSHEVSKAYA_EXCEPTIONS.ERROR_ALBUM THEN
        RETURN;
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('EXCEPTION IN ADD_ALBUM');
        IF SQLCODE = -12899 THEN
            DBMS_OUTPUT.PUT_LINE('�������� ��� ������ �� �������� ������� ������');
        ELSIF SQLCODE = -6532 THEN
            DBMS_OUTPUT.PUT_LINE('������ ��������� �������');
        ELSIF SQLCODE = -1 THEN
            DBMS_OUTPUT.PUT_LINE('�������� ����������� ������������ ������ �� �����');
        ELSE
            PRINT_MSG_EX(SQLCODE);
        END IF;
    END ADD_ALBUM;
        
    PROCEDURE ADD_ALBUM (
        ID NUMBER,
        NAME VARCHAR2,
        PRICE NUMBER,
        QUANTITY_IN_STOCK NUMBER,
        QUANTITY_OF_SOLD NUMBER
    ) IS
        RECORD_ARR GRUSHEVSKAYA_RECORD_ARR := GRUSHEVSKAYA_RECORD_ARR();
    BEGIN
        RECORD_ARR.EXTEND(30);
        INSERT INTO GRUSHEVSKAYA_ALBUM (
            ID, 
            NAME, 
            PRICE, 
            QUANTITY_IN_STOCK,
            QUANTITY_OF_SOLD,
            RECORD_ARRAY
        ) VALUES (
            ID, 
            NAME, 
            PRICE, 
            QUANTITY_IN_STOCK,
            QUANTITY_OF_SOLD,
            RECORD_ARR
        );
        COMMIT;
    EXCEPTION
    WHEN GRUSHEVSKAYA_EXCEPTIONS.ERROR_ALBUM THEN
        RETURN;
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('EXCEPTION IN ADD_ALBUM');
        IF SQLCODE = -12899 THEN
            DBMS_OUTPUT.PUT_LINE('�������� ��� ������ �� �������� ������� ������');
        ELSIF SQLCODE = -6532 THEN
            DBMS_OUTPUT.PUT_LINE('������ ��������� �������');
        ELSIF SQLCODE = -1 THEN
            DBMS_OUTPUT.PUT_LINE('�������� ����������� ������������ ������ �� �����');
        ELSE
            PRINT_MSG_EX(SQLCODE);
        END IF;
    END ADD_ALBUM;    
    
    PROCEDURE ADD_RECORD_IN_ALBUM (
        ALBUM_ID NUMBER, 
        RECORD_ID NUMBER,
        RECORD_SERIAL_NUMBER NUMBER
    )IS
        TMP_RECORD_ARR GRUSHEVSKAYA_RECORD_ARR;
    BEGIN
        SELECT RECORD_ARRAY INTO TMP_RECORD_ARR
            FROM GRUSHEVSKAYA_ALBUM
            WHERE ID = ALBUM_ID;
        TMP_RECORD_ARR(RECORD_SERIAL_NUMBER) := RECORD_ID;
        UPDATE GRUSHEVSKAYA_ALBUM
            SET RECORD_ARRAY = TMP_RECORD_ARR
            WHERE ID = ALBUM_ID;            
        COMMIT;
    EXCEPTION
    WHEN GRUSHEVSKAYA_EXCEPTIONS.ERROR_ALBUM THEN
        RETURN;
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('EXCEPTION IN ADD_RECORD_IN_ALBUM');
        IF SQLCODE = -12899 THEN
            DBMS_OUTPUT.PUT_LINE('�������� ��� ������ �� �������� ������� ������');
        ELSIF SQLCODE = -6532 THEN
            DBMS_OUTPUT.PUT_LINE('������ ��������� �������');
        ELSE
            PRINT_MSG_EX(SQLCODE);
        END IF;
    END ADD_RECORD_IN_ALBUM;
    
    PROCEDURE PRINT_ALBUMS_IN_STOCK 
    IS
        QUANTITY NUMBER := 0;
    BEGIN
        DBMS_OUTPUT.PUT_LINE('������� � �������:');
        FOR ALBUM IN (SELECT * FROM GRUSHEVSKAYA_ALBUM WHERE QUANTITY_IN_STOCK > 0)
        LOOP
            DBMS_OUTPUT.PUT_LINE(ALBUM.NAME);
            QUANTITY := QUANTITY + 1;
        END LOOP;
        DBMS_OUTPUT.PUT_LINE('����� �������� � �������: ' || QUANTITY);
    END PRINT_ALBUMS_IN_STOCK;
    
    PROCEDURE PRINT_SINGERS
    IS
    BEGIN
        DBMS_OUTPUT.PUT_LINE('�����������:');
        FOR SINGER IN (SELECT * FROM GRUSHEVSKAYA_SINGER)
        LOOP
            DBMS_OUTPUT.PUT_LINE(SINGER.NAME);
        END LOOP;
    END PRINT_SINGERS;
    
    PROCEDURE ADD_ALBUMS_IN_STOCK (
        ALBUM_ID NUMBER,
        QUANTITY NUMBER
    ) IS
    BEGIN
        UPDATE GRUSHEVSKAYA_ALBUM
            SET QUANTITY_IN_STOCK = QUANTITY_IN_STOCK + QUANTITY
            WHERE ID = ALBUM_ID;
        COMMIT;
    EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('EXCEPTION IN ADD_ALBUMS_IN_STOCK');
        IF SQLCODE = -12899 THEN
            DBMS_OUTPUT.PUT_LINE('�������� ��� ������ �� �������� ������� ������');
        ELSE
            PRINT_MSG_EX(SQLCODE);
        END IF;        
    END ADD_ALBUMS_IN_STOCK;
    
    
    PROCEDURE SELL_ALBUMS(
        ALBUM_ID NUMBER,
        QUANTITY NUMBER
    ) IS
        RECORD_ARR GRUSHEVSKAYA_RECORD_ARR;
        FLAG_ONE_RECORD BOOLEAN := FALSE;
        MAX_QUANTITY NUMBER;
    BEGIN
        SELECT RECORD_ARRAY INTO RECORD_ARR 
            FROM GRUSHEVSKAYA_ALBUM
            WHERE ID = ALBUM_ID;
        FOR i IN 1..RECORD_ARR.COUNT
        LOOP
            IF NOT RECORD_ARR(i) IS NULL THEN
                FLAG_ONE_RECORD := TRUE;
            END IF;
        END LOOP;
        IF NOT FLAG_ONE_RECORD THEN
            DBMS_OUTPUT.PUT_LINE('������� ������ ������. � ������� ��� ������');
            RETURN;
        END IF;
        SELECT QUANTITY_IN_STOCK INTO MAX_QUANTITY 
            FROM GRUSHEVSKAYA_ALBUM
            WHERE ID = ALBUM_ID;
        MAX_QUANTITY := LEAST(MAX_QUANTITY, QUANTITY);
        IF MAX_QUANTITY <= 0 THEN
            DBMS_OUTPUT.PUT_LINE('������� ������ ������. �������� ��� �� ������');
            RETURN;
        END IF;
        UPDATE GRUSHEVSKAYA_ALBUM
            SET 
                QUANTITY_IN_STOCK = QUANTITY_IN_STOCK - MAX_QUANTITY,
                QUANTITY_OF_SOLD = QUANTITY_OF_SOLD + MAX_QUANTITY
            WHERE ID = ALBUM_ID;
        COMMIT;
        DBMS_OUTPUT.PUT_LINE('������� ' || MAX_QUANTITY || ' ��������.');
    EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('EXCEPTION IN SELL_ALBUMS');
        IF SQLCODE = -12899 THEN
            DBMS_OUTPUT.PUT_LINE('�������� ��� ������ �� �������� ������� ������');
        ELSE
            PRINT_MSG_EX(SQLCODE);
        END IF;       
    END SELL_ALBUMS;
    
    PROCEDURE DELETE_SINGERS_WITHOUT_RECORDS
    IS
        DEL_SINGERS_LIST GRUSHEVSKAYA_SINGER_TAB;
    BEGIN
        SELECT NAME BULK COLLECT INTO DEL_SINGERS_LIST FROM GRUSHEVSKAYA_SINGER;
        FOR RECORD IN (SELECT * FROM GRUSHEVSKAYA_RECORD)
        LOOP
           FOR i IN 1..RECORD.SINGER_LIST.COUNT
            LOOP
                FOR k IN 1..DEL_SINGERS_LIST.COUNT
                LOOP                   
                    IF NOT DEL_SINGERS_LIST(k) IS NULL
                       AND NOT RECORD.SINGER_LIST(i) IS NULL
                       AND DEL_SINGERS_LIST(k) = RECORD.SINGER_LIST(i) THEN
                        DEL_SINGERS_LIST(k) := NULL;
                    END IF;                
                END LOOP;
            END LOOP;
        END LOOP;
        FOR j IN 1..DEL_SINGERS_LIST.COUNT
        LOOP
            IF NOT DEL_SINGERS_LIST(j) IS NULL THEN
                DELETE FROM GRUSHEVSKAYA_SINGER
                WHERE NAME = DEL_SINGERS_LIST(j);
                DBMS_OUTPUT.PUT_LINE('������ ����������� ' || DEL_SINGERS_LIST(j));
            END IF;
        END LOOP;
        COMMIT;
    EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('EXCEPTION IN DELETE_SINGERS_WITHOUT_RECORDS');
        PRINT_MSG_EX(SQLCODE);
    END DELETE_SINGERS_WITHOUT_RECORDS;    
    
    PROCEDURE PRINT_ALBUM_RECORDS(
        ALBUM_ID NUMBER
    ) IS
        RECORD_ARR GRUSHEVSKAYA_RECORD_ARR;
        RECORD GRUSHEVSKAYA_RECORD%ROWTYPE;
        TIME GRUSHEVSKAYA_TIME := GRUSHEVSKAYA_TIME(0, 0, 0);
        SINGERS VARCHAR2(300) := '';
    BEGIN
        DBMS_OUTPUT.PUT_LINE('������ �' || ALBUM_ID);
        SELECT RECORD_ARRAY INTO RECORD_ARR
            FROM GRUSHEVSKAYA_ALBUM
            WHERE ID = ALBUM_ID;
        FOR i IN 1..RECORD_ARR.COUNT
        LOOP
            IF NOT RECORD_ARR(i) IS NULL THEN
                SELECT * INTO RECORD FROM GRUSHEVSKAYA_RECORD 
                    WHERE ID = RECORD_ARR(i);
                SINGERS := '-';
                FOR j IN 1..RECORD.SINGER_LIST.COUNT
                LOOP
                    SINGERS := SINGERS || ' ' || RECORD.SINGER_LIST(j);
                END LOOP;
                DBMS_OUTPUT.PUT_LINE(
                    '�' 
                    || LPAD(i, 2, '0')
                    || ' ' 
                    || RECORD.STYLE
                    || ', ' 
                    || RECORD.TIME.PRINT
                    || ' ' 
                    || RECORD.NAME
                    || ' ' 
                    || SINGERS
                );
                TIME := RECORD.TIME.ACCUMULATE(TIME);
            END IF;
        END LOOP;
        DBMS_OUTPUT.PUT_LINE('����� ����� ��������: ' || TIME.PRINT);
    END PRINT_ALBUM_RECORDS;
END;
/
DECLARE 
BEGIN
    GRUSHEVSKAYA_PACKAGE.ADD_IN_DICT_COUNTRY('country_1');
    GRUSHEVSKAYA_PACKAGE.ADD_SINGER('singer_1', 'nick_1', 'country_1');
    GRUSHEVSKAYA_PACKAGE.ADD_IN_DICT_STYLE('style_1');
    GRUSHEVSKAYA_PACKAGE.ADD_RECORD(1, 'song_1', 0, 1, 10, 'style_1', 'singer_1');
    GRUSHEVSKAYA_PACKAGE.ADD_SINGER('singer_2', 'nick_2', 'country_1');
    GRUSHEVSKAYA_PACKAGE.ADD_SINGER_IN_RECORD(1, 'singer_2');
    GRUSHEVSKAYA_PACKAGE.ADD_ALBUM(
        ID => 1, 
        NAME => 'album_1', 
        PRICE => 100.50, 
        QUANTITY_IN_STOCK => 10, 
        QUANTITY_OF_SOLD => 0, 
        RECORD_ID => 1, 
        RECORD_SERIAL_NUMBER => 10
    );
    GRUSHEVSKAYA_PACKAGE.ADD_RECORD(2, 'song_2', 0, 2, 50, 'style_1', 'singer_2');
    GRUSHEVSKAYA_PACKAGE.ADD_RECORD_IN_ALBUM(
        ALBUM_ID => 1,
        RECORD_ID => 2, 
        RECORD_SERIAL_NUMBER => 3
    );
    GRUSHEVSKAYA_PACKAGE.ADD_ALBUM(
        ID => 2, 
        NAME => 'album_2', 
        PRICE => 123.50, 
        QUANTITY_IN_STOCK => 5, 
        QUANTITY_OF_SOLD => 0
    );
    GRUSHEVSKAYA_PACKAGE.ADD_RECORD(3, 'song_3', 0, 1, 37, 'style_1', 'singer_1');
    GRUSHEVSKAYA_PACKAGE.ADD_RECORD(4, 'song_4', 0, 2, 12, 'style_1', 'singer_1');
    GRUSHEVSKAYA_PACKAGE.ADD_RECORD(5, 'song_5', 0, 1, 42, 'style_1', 'singer_2');    
    GRUSHEVSKAYA_PACKAGE.ADD_RECORD_IN_ALBUM(
        ALBUM_ID => 2,
        RECORD_ID => 3, 
        RECORD_SERIAL_NUMBER => 1
    );
    GRUSHEVSKAYA_PACKAGE.ADD_RECORD_IN_ALBUM(
        ALBUM_ID => 2,
        RECORD_ID => 4, 
        RECORD_SERIAL_NUMBER => 8
    );
    GRUSHEVSKAYA_PACKAGE.ADD_RECORD_IN_ALBUM(
        ALBUM_ID => 2,
        RECORD_ID => 5, 
        RECORD_SERIAL_NUMBER => 4
    );
    GRUSHEVSKAYA_PACKAGE.ADD_ALBUM(
        ID => 3, 
        NAME => 'album_3', 
        PRICE => 555.50, 
        QUANTITY_IN_STOCK => 0, 
        QUANTITY_OF_SOLD => 10
    );
    GRUSHEVSKAYA_PACKAGE.PRINT_ALBUMS_IN_STOCK;
    GRUSHEVSKAYA_PACKAGE.PRINT_SINGERS;
    GRUSHEVSKAYA_PACKAGE.ADD_ALBUMS_IN_STOCK(ALBUM_ID => 1, QUANTITY => 8);
    GRUSHEVSKAYA_PACKAGE.SELL_ALBUMS(ALBUM_ID => 2, QUANTITY => 8);
    GRUSHEVSKAYA_PACKAGE.SELL_ALBUMS(ALBUM_ID => 2, QUANTITY => 8);
    GRUSHEVSKAYA_PACKAGE.SELL_ALBUMS(ALBUM_ID => 3, QUANTITY => 8);    
    GRUSHEVSKAYA_PACKAGE.ADD_SINGER('singer_3', 'nick_3', 'country_1');
    GRUSHEVSKAYA_PACKAGE.DELETE_SINGERS_WITHOUT_RECORDS;   
    GRUSHEVSKAYA_PACKAGE.ADD_SINGER('singer_4', 'nick_4', 'country_1');
    GRUSHEVSKAYA_PACKAGE.PRINT_ALBUM_RECORDS(ALBUM_ID => 2);
END;













