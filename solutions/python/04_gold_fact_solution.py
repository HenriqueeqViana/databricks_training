# Databricks notebook source
# MAGIC %md
# MAGIC # 04 · Gold fact — SOLUTION (PySpark)

# COMMAND ----------

from pyspark.sql import functions as F

spark.sql("USE CATALOG workspace")
spark.sql("USE SCHEMA finance_training")

silver          = spark.table("silver_ledger")
dim_cost_center = spark.table("dim_cost_center")
dim_category    = spark.table("dim_category")

# COMMAND ----------

fact = (silver
    .withColumn("date_key", F.date_format("entry_date", "yyyyMMdd").cast("int"))
    .withColumn("signed_amount",
                F.when(F.col("type") == "Income", F.col("amount")).otherwise(-F.col("amount")))
    .join(dim_cost_center, silver.cost_center == dim_cost_center.cost_center_name)
    .join(dim_category,    silver.category    == dim_category.category_name)
    .select("entry_id", "date_key", "cost_center_key", "category_key",
            "type", "amount", "signed_amount", "description"))

fact.write.mode("overwrite").saveAsTable("fact_ledger")

# COMMAND ----------

display(spark.sql("""
SELECT
  count(*)                                                  AS fact_rows,
  sum(CASE WHEN cost_center_key IS NULL THEN 1 ELSE 0 END)  AS missing_cost_center_key,
  sum(CASE WHEN category_key   IS NULL THEN 1 ELSE 0 END)   AS missing_category_key,
  sum(CASE WHEN date_key        IS NULL THEN 1 ELSE 0 END)  AS missing_date_key
FROM fact_ledger
"""))
