-- Databricks notebook source
-- MAGIC %md
-- MAGIC # 00 · Setup — catalog, schema & volume
-- MAGIC
-- MAGIC **🇬🇧** Creates the catalog/schema and a **volume** to upload the CSV into.
-- MAGIC Run this first, then upload the data file (see step 2 below).
-- MAGIC
-- MAGIC **🇧🇷** Cria o catálogo/schema e um **volume** para subir o CSV.
-- MAGIC Rode este notebook primeiro e depois suba o arquivo (passo 2 abaixo).
-- MAGIC
-- MAGIC > If your workspace does not have a `workspace` catalog, change `CATALOG`
-- MAGIC > below to one you can write to (e.g. `main` or your own catalog).

-- COMMAND ----------

-- DBTITLE 1,Configuration (change here if needed)
-- These three names are reused by every notebook in this track.
USE CATALOG workspace;
CREATE SCHEMA IF NOT EXISTS finance_training;
USE SCHEMA finance_training;

-- A volume is managed cloud storage you can upload files into.
CREATE VOLUME IF NOT EXISTS landing;

-- COMMAND ----------

-- MAGIC %md
-- MAGIC ## Step 2 — upload the CSV to the volume
-- MAGIC
-- MAGIC The notebooks expect the file here:
-- MAGIC
-- MAGIC ```
-- MAGIC /Volumes/workspace/finance_training/landing/corporate_finance_ledger.csv
-- MAGIC ```
-- MAGIC
-- MAGIC **UI:** Catalog → `workspace` → `finance_training` → `landing` →
-- MAGIC **Upload to this volume** → pick `data/corporate_finance_ledger.csv`.
-- MAGIC
-- MAGIC **CLI:** `databricks fs cp data/corporate_finance_ledger.csv dbfs:/Volumes/workspace/finance_training/landing/`

-- COMMAND ----------

-- DBTITLE 1,Verify the upload
-- After uploading you should see the file listed here.
LIST '/Volumes/workspace/finance_training/landing/';

-- COMMAND ----------

-- DBTITLE 1,Peek at the raw file
-- read_files() can read straight from the volume. Notice how messy it is!
SELECT *
FROM read_files(
  '/Volumes/workspace/finance_training/landing/corporate_finance_ledger.csv',
  format => 'csv',
  header => true
)
LIMIT 10;
