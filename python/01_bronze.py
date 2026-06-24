# Databricks notebook source
# MAGIC %md
# MAGIC # 01 · Bronze — raw ingestion
# MAGIC
# MAGIC **🇬🇧** Bronze = the data **exactly as it arrived**. Read every column as text
# MAGIC (no cleaning, no casting) and only add load metadata. Never lose the raw truth.
# MAGIC
# MAGIC **🇧🇷** Bronze = o dado **como ele chegou**. Lemos tudo como texto e só
# MAGIC adicionamos metadados de carga (origem + data/hora). Nada de transformação aqui.

# COMMAND ----------

from pyspark.sql import functions as F

CATALOG = "workspace"
SCHEMA  = "finance_training"
VOLUME  = "landing"
CSV_PATH = f"/Volumes/{CATALOG}/{SCHEMA}/{VOLUME}/corporate_finance_ledger.csv"

spark.sql(f"USE CATALOG {CATALOG}")
spark.sql(f"USE SCHEMA {SCHEMA}")

# COMMAND ----------

# DBTITLE 1,Read the CSV as raw text + add lineage columns
# inferSchema=False keeps every column as STRING -> bronze never fails on a bad value.
bronze = (spark.read
          .format("csv")
          .option("header", True)
          .option("inferSchema", False)
          .load(CSV_PATH)
          .withColumn("_source_file", F.col("_metadata.file_path"))
          .withColumn("_ingested_at", F.current_timestamp()))

bronze.write.mode("overwrite").saveAsTable("bronze_ledger")

# COMMAND ----------

# DBTITLE 1,Sanity check
print("rows:", spark.table("bronze_ledger").count())
display(spark.table("bronze_ledger").limit(20))
