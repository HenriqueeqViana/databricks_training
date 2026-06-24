-- Databricks notebook source
-- MAGIC %md
-- MAGIC # 01 · Bronze — raw ingestion
-- MAGIC
-- MAGIC **🇬🇧** Bronze = the data **exactly as it arrived**. We read every column as
-- MAGIC text (no cleaning, no casting) and only add load metadata so we always know
-- MAGIC *where* and *when* a row came from. Never lose the raw truth.
-- MAGIC
-- MAGIC **🇧🇷** Bronze = o dado **como ele chegou**. Lemos tudo como texto (sem
-- MAGIC tratamento) e só adicionamos metadados de carga (origem + data/hora).
-- MAGIC Nada de transformação aqui — a verdade crua fica preservada.

-- COMMAND ----------

USE CATALOG workspace;
USE SCHEMA finance_training;

-- COMMAND ----------

-- DBTITLE 1,Create the bronze table from the CSV
-- We force every column to STRING on purpose: bronze keeps data raw and
-- never fails on a badly formatted value. Two helper columns record lineage.
CREATE OR REPLACE TABLE bronze_ledger AS
SELECT
  CAST(entry_id    AS STRING) AS entry_id,
  CAST(entry_date  AS STRING) AS entry_date,
  CAST(cost_center AS STRING) AS cost_center,
  CAST(category    AS STRING) AS category,
  CAST(amount      AS STRING) AS amount,
  CAST(type        AS STRING) AS type,
  CAST(description AS STRING) AS description,
  _metadata.file_path        AS _source_file,
  current_timestamp()        AS _ingested_at
FROM read_files(
  '/Volumes/workspace/finance_training/landing/corporate_finance_ledger.csv',
  format            => 'csv',
  header            => true,
  inferSchema       => false,   -- everything stays as text in bronze
  rescuedDataColumn => '_rescued'
);

-- COMMAND ----------

-- DBTITLE 1,Sanity check
SELECT count(*) AS row_count FROM bronze_ledger;

-- COMMAND ----------

SELECT * FROM bronze_ledger LIMIT 20;
