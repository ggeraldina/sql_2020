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











