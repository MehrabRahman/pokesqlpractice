import pandas as pd
import sqlite3

DB_PATH = "pokemon_warehouse.db"
CSV_PATH = "Pokemon.csv"

bronze_df = pd.read_csv(CSV_PATH)
print("=== BRONZE: raw data ===")
print(bronze_df.head())
print(f"Shape: {bronze_df.shape}\n")

silver_df = bronze_df.copy()
silver_df.columns = silver_df.columns.str.lower().str.replace(" ", '_')
silver_df = silver_df.dropna(subset=["type1"])
silver_df = silver_df[silver_df["type1"].str.strip() != ""]
silver_df = silver_df.rename(columns={
    "#": "pokedex_number",
    "sp._atk": "sp_atk",
    "sp._def": "sp_def"})

stat_cols = ["hp", "attack", "defense", "sp_atk", "sp_def", "speed"]
silver_df[stat_cols] = silver_df[stat_cols].astype(int)

silver_df["base_stat_total"] = silver_df[stat_cols].sum(axis=1)
print("=== SILVER: cleaned data ===")
print(silver_df.head())
print(f"Shape: {silver_df.shape}\n")

con = sqlite3.connect(DB_PATH)

silver_df.to_sql("silver_pokemon", con, if_exists="replace", index=False)
print(f"Wrote {len(silver_df)} rows to silver_pokemon table in {DB_PATH}\n")

con.execute("DROP TABLE IF EXISTS gold_type_summary")
con.execute("""
    CREATE TABLE gold_type_summary AS
        SELECT 
            type1,
            COUNT(*) AS pokemon_count,
            ROUND(AVG(base_stat_total), 1)  AS avg_bst,
            MAX(base_stat_total)    AS max_bst,
            MIN(base_stat_total)    AS min_bst
        FROM silver_pokemon
        GROUP BY type1 ORDER BY avg_bst DESC
""")

con.commit()
print("Gold layer tables created!")

print("=== GOLD: type summary ===")
summary = pd.read_sql("SELECT * FROM gold_type_summary LIMIT 5", con)
print(summary.to_string(index=False))

con.close()
print(f"\nPipeline complete. Warehouse saved to {DB_PATH}\n")