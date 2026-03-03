.mode csv
.import Pokemon.csv pokemon_raw_import

CREATE TABLE IF NOT EXISTS bronze_pokemon AS
SELECT * FROM pokemon_raw_import;

--SELECT * FROM bronze_pokemon LIMIT 5;

CREATE TABLE IF NOT EXISTS silver_pokemon AS
SELECT
    CAST([#]              AS INTEGER) AS pokedex_number,
    LOWER(name)                     AS name,
    LOWER(type1)                    AS type1,
    LOWER(type2)                    AS type2,
    CAST(hp             AS INTEGER) AS hp,
    CAST(attack         AS INTEGER) AS attack,
    CAST(defense        AS INTEGER) AS defense,
    CAST(sp_atk         AS INTEGER) AS sp_atk,
    CAST(sp_def         AS INTEGER) AS sp_def,
    CAST(speed          AS INTEGER) AS speed,
    CAST(legendary      AS INTEGER) AS is_legendary,
    CAST(hp AS INTEGER) 
    + CAST(attack AS INTEGER)
    + CAST(defense AS INTEGER)
    + CAST('Sp. Atk' AS INTEGER)
    + CAST('Sp. Def' AS INTEGER)
    + CAST(speed AS INTEGER)        AS base_stat_total
FROM bronze_pokemon WHERE type1 IS NOT NULL AND type1 != '';
-- SELECT * FROM silver_pokemon LIMIT 5;

CREATE TABLE IF NOT EXISTS gold_type_summary AS
SELECT
    type1,
    COUNT(*)                        AS pokemon_count,
    ROUND(AVG(base_stat_total), 1)  AS avg_bst,
    MAX(base_stat_total)            AS max_bst,
    MIN(base_stat_total)            AS min_bst,
    SUM(is_legendary)               AS legendary_count
FROM silver_pokemon
GROUP BY type1
ORDER BY avg_bst DESC;

CREATE TABLE IF NOT EXISTS gold_top_pokemon_by_type AS
SELECT * FROM (
    SELECT
        type1, name, base_stat_total, is_legendary,
        ROW_NUMBER() OVER (
            PARTITION BY type1
            ORDER BY base_stat_total DESC
        ) FROM silver_pokemon AS rank_in_type
)
WHERE rank_in_type <= 5;

SELECT type1, avg_bst, pokemon_count
FROM gold_type_summary
LIMIT 10;

SELECT name, base_stat_total, is_legendary
FROM gold_top_pokemon_by_type
WHERE type1='grass' AND rank_in_type <=3;
