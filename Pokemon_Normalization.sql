.mode csv
.headers on

DROP TABLE IF EXISTS pokemon_raw;
CREATE TABLE pokemon_raw (
    id          INTEGER,
    name        TEXT,
    type1       TEXT,
    type2       TEXT,
    hp          INTEGER,
    attack      INTEGER,
    defense     INTEGER,
    sp_atk      INTEGER,
    sp_def      INTEGER,
    speed       INTEGER,
    generation  INTEGER,
    legendary   INTEGER
);

.import --csv --skip 1 Pokemon.csv pokemon_raw
SELECT * FROM pokemon_raw LIMIT 8;

DROP TABLE IF EXISTS types;
CREATE TABLE types (
    id      INTEGER PRIMARY KEY AUTOINCREMENT,
    name    TEXT UNIQUE
);
INSERT INTO types (name)
    SELECT DISTINCT type1 FROM pokemon_raw WHERE type1 IS NOT NULL AND type1 != ''
    UNION
    SELECT DISTINCT type2 FROM pokemon_raw WHERE type2 IS NOT NULL AND type2 != '';
SELECT * FROM types ORDER BY name;

DROP TABLE IF EXISTS pokemon_types;
CREATE TABLE pokemon_types (
    pokemon_id      INTEGER,
    type_id         INTEGER,
    UNIQUE(pokemon_id, type_id)
);

INSERT INTO pokemon_types (pokemon_id, type_id)
    SELECT r.id, t.id
    FROM pokemon_raw r
    JOIN types t ON t.name = r.type1
    WHERE r.type1 IS NOT NULL AND r.type1 != '';

INSERT OR IGNORE INTO pokemon_types (pokemon_id, type_id)
    SELECT r.id, t.id
    FROM pokemon_raw r
    JOIN types t ON t.name = r.type2
    WHERE r.type2 IS NOT NULL AND r.type2 != '';

SELECT pr.name, t.name AS type
FROM pokemon_types pt
JOIN pokemon_raw pr ON pr.id = pt.pokemon_id
JOIN types t        ON t.id = pt.type_id
WHERE pr.name = 'Charizard';