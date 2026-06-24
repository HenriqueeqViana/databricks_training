# Databricks notebook source
# MAGIC %md
# MAGIC # 00 · Setup — catalog, schema & volume
# MAGIC
# MAGIC **🇬🇧** Creates the catalog/schema and a **volume** to upload the CSV into.
# MAGIC Run this first, then upload the data file (see step 2 below).
# MAGIC
# MAGIC **🇧🇷** Cria o catálogo/schema e um **volume** para subir o CSV.
# MAGIC Rode este notebook primeiro e depois suba o arquivo (passo 2 abaixo).

# COMMAND ----------

# DBTITLE 1,Configuration (change here if needed)
# These three names are reused by every notebook in this track.
CATALOG = "workspace"          # default catalog in new Databricks workspaces
SCHEMA  = "finance_training"
VOLUME  = "landing"

CSV_PATH = f"/Volumes/{CATALOG}/{SCHEMA}/{VOLUME}/corporate_finance_ledger.csv"

# COMMAND ----------

spark.sql(f"USE CATALOG {CATALOG}")
spark.sql(f"CREATE SCHEMA IF NOT EXISTS {SCHEMA}")
spark.sql(f"USE SCHEMA {SCHEMA}")
spark.sql(f"CREATE VOLUME IF NOT EXISTS {VOLUME}")
print(f"Ready. Upload the CSV to: /Volumes/{CATALOG}/{SCHEMA}/{VOLUME}/")

# COMMAND ----------

# MAGIC %md
# MAGIC ## Step 2 — upload the CSV to the volume
# MAGIC
# MAGIC The notebooks expect the file at the `CSV_PATH` printed above.
# MAGIC
# MAGIC **UI:** Catalog → `workspace` → `finance_training` → `landing` →
# MAGIC **Upload to this volume** → pick `data/corporate_finance_ledger.csv`.
# MAGIC
# MAGIC **CLI:** `databricks fs cp data/corporate_finance_ledger.csv dbfs:/Volumes/workspace/finance_training/landing/`

# COMMAND ----------

# DBTITLE 1,Verify the upload
display(dbutils.fs.ls(f"/Volumes/{CATALOG}/{SCHEMA}/{VOLUME}/"))

# COMMAND ----------

# DBTITLE 1,Peek at the raw file
raw = (spark.read
       .format("csv")
       .option("header", True)
       .load(CSV_PATH))
display(raw.limit(10))
