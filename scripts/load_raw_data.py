from pathlib import Path
import pandas as pd
from sqlalchemy import create_engine, text

# PostgreSQL settings
DB_USER = "postgres"
DB_PASSWORD = "IASTOBE7"
DB_HOST = "localhost"
DB_PORT = "5432"
DB_NAME = "novamart_raw"

# Project paths
PROJECT_ROOT = Path(__file__).resolve().parent.parent
RAW_FOLDER = PROJECT_ROOT / "data" / "raw"

# Create PostgreSQL connection
DATABASE_URL = (
    f"postgresql+psycopg2://{DB_USER}:{DB_PASSWORD}"
    f"@{DB_HOST}:{DB_PORT}/{DB_NAME}"
)

engine = create_engine(DATABASE_URL)

# Test connection
try:
    with engine.connect() as connection:
        db_name = connection.execute(
            text("SELECT current_database();")
        ).scalar()

        print(f"Connected to PostgreSQL database: {db_name}")

except Exception as e:
    print("Database connection failed.")
    print(e)
    raise

# Make sure raw schema exists
with engine.begin() as connection:
    connection.execute(
        text("CREATE SCHEMA IF NOT EXISTS raw;")
    )

# Find CSV files
csv_files = list(RAW_FOLDER.glob("*.csv"))

print(f"\nFound {len(csv_files)} CSV files.\n")

# Load each CSV
for csv_file in csv_files:

    table_name = csv_file.stem.lower()

    print("=" * 60)
    print(f"Loading: {csv_file.name}")
    print(f"Table: raw.{table_name}")

    df = pd.read_csv(csv_file)

    print(f"Rows: {len(df)}")
    print(f"Columns: {len(df.columns)}")

    df.to_sql(
        table_name,
        engine,
        schema="raw",
        if_exists="replace",
        index=False,
        chunksize=10000
    )

    print("SUCCESS")

print("\n" + "=" * 60)
print("ALL CSV FILES LOADED SUCCESSFULLY")
print("=" * 60)
