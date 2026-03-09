.mode csv
.headers on

DROP TABLE IF EXISTS pokemon_raw;
CREATE TABLE pokemon_raw (
    id          INTEGER,
    name        TEXT,
    type1       TEXT,
    type2       TEXT,
    total       INTEGER,
    hp          INTEGER,
    attack      INTEGER,
    defense     INTEGER,
    sp_atk      INTEGER,
    sp_def      INTEGER,
    speed       INTEGER,
    generation  INTEGER,
    legendary   INTEGER
);

.import --csv --skip 1 scratchdex.csv pokemon_raw
--SELECT * FROM pokemon_raw;

-- SELECT name, type1, hp + attack + defense + sp_atk + sp_def + speed
-- FROM pokemon_raw
-- ORDER BY 3 DESC
-- LIMIT 5;

-- SELECT 
--     name, 
--     type1 AS primary_type, 
--     hp + attack + defense + sp_atk + sp_def + speed AS base_stat_total
-- FROM pokemon_raw
-- ORDER BY base_stat_total DESC
-- LIMIT 10;

-- SELECT pr.name, pr.type1, pr.legendary
-- FROM pokemon_raw AS pr
-- WHERE pr.legendary = 'True';

DROP TABLE IF EXISTS typing;
CREATE TABLE typing(
    id  INTEGER PRIMARY KEY AUTOINCREMENT,
    type1   TEXT,
    type2   TEXT
);

INSERT INTO typing(type1, type2) 
SELECT DISTINCT type1, type2 FROM pokemon_raw ORDER BY type1;

-- SELECT * FROM typing;

-- SELECT 
--     type1,
--     COUNT(*) AS total_pokemon,
--     ROUND(AVG(hp), 2) AS avg_hp,
--     MAX(attack) AS strongest_attack
-- FROM pokemon_raw
-- GROUP BY type1
-- ORDER BY avg_hp DESC;

-- SELECT type1, COUNT(*) AS count
-- FROM pokemon_raw
-- GROUP BY type1
-- HAVING count > 2;

UPDATE pokemon_raw SET type1 = 'Fire' WHERE type1 = 'NULL';

DROP TABLE IF EXISTS types_lookup;
CREATE TABLE types_lookup(
    id  INTEGER PRIMARY KEY AUTOINCREMENT,
    type_name   TEXT UNIQUE
);
INSERT INTO types_lookup(type_name)
    SELECT DISTINCT type1 FROM pokemon_raw
    WHERE type1 IS NOT NULL AND type1 != ''
    UNION
    SELECT DISTINCT type2 FROM pokemon_raw
    WHERE type2 IS NOT NULL AND type2 != '';

-- SELECT pr.name, pr.type1, pr.type2, tl.id AS type_id
-- FROM pokemon_raw AS pr JOIN types_lookup AS tl
-- ON tl.type_name = pr.type1;

-- SELECT pr.name, pr.type2, tl.id AS secondary_type_id
-- FROM types_lookup AS tl
-- LEFT JOIN pokemon_raw as pr
-- ON tl.type_name = pr.type2;

DROP TABLE IF EXISTS generations;
CREATE TABLE generations (
    id      INTEGER PRIMARY KEY,
    game_title  TEXT
);
INSERT INTO generations VALUES
(1, 'Red / Blue'),
(2, 'Gold / Silver'),
(3, 'Ruby / Sapphire'),
(4, 'Diamond / Pearl');

-- SELECT pr.name, tl.type_name AS primary_type, g.game_title AS game_title
-- FROM pokemon_raw AS pr
-- JOIN types_lookup AS tl ON tl.type_name = pr.type1
-- JOIN generations AS g ON g.id = pr.generation
-- ORDER BY g.id, pr.name;

DROP TABLE IF EXISTS fire_pokemon;
CREATE TABLE fire_pokemon (
    id  INTEGER,
    name    TEXT,
    hp  INTEGER
);

INSERT INTO fire_pokemon (id, name, hp)
SELECT id, name, hp
FROM pokemon_raw
WHERE type1 = 'Fire';

-- SELECT * FROM fire_pokemon;

DROP TABLE IF EXISTS type_summary;
CREATE TABLE type_summary (type_name TEXT, count INTEGER, avg_hp INTEGER);

INSERT INTO type_summary
SELECT type1, COUNT(*), ROUND(AVG(hp), 1)
FROM pokemon_raw GROUP BY type1;

-- SELECT * FROM type_summary ORDER BY avg_hp DESC;

-- SELECT name, hp FROM pokemon_raw WHERE hp > (
--     SELECT AVG(hp) FROM pokemon_raw
-- ) ORDER BY hp DESC;

DROP TABLE IF EXISTS rankings;
CREATE TABLE rankings (name TEXT, type1 TEXT, bst INTEGER);

WITH bronze_tier AS (
    SELECT * FROM pokemon_raw WHERE generation = 1
),
valided_pokemon AS (
    SELECT * FROM bronze_tier
    WHERE id IS NOT NULL AND name IS NOT NULL AND type1 IS NOT NULL
),
enriched_pokemon AS (
    SELECT id, name, type1, type2, hp + attack + defense + sp_atk + sp_def + speed AS bst
    FROM valided_pokemon
),
final_tier AS (
    SELECT name, type1, bst, 
    ROW_NUMBER() OVER(PARTITION BY type1 ORDER BY bst DESC) AS type_rank
    FROM enriched_pokemon
) INSERT INTO rankings 
SELECT name, type1, bst FROM final_tier WHERE type_rank = 1 ORDER BY bst DESC;

select * from rankings;