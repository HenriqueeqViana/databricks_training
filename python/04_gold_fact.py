# Databricks notebook source
# MAGIC %md
# MAGIC # 04 · Gold — fact table  🧩
# MAGIC
# MAGIC **🇬🇧** The **fact** table is the heart of the star schema: one row per ledger
# MAGIC entry, storing the **measures** (numbers we sum) and **foreign keys** to each
# MAGIC dimension — not the descriptive text, which lives in the dimensions.
# MAGIC
# MAGIC **🇧🇷** A tabela **fato** é o coração do modelo estrela: uma linha por
# MAGIC lançamento, com as **métricas** e as **chaves estrangeiras** para cada
# MAGIC dimensão — não o texto descritivo, que fica nas dimensões.

# COMMAND ----------

from pyspark.sql import functions as F

CATALOG = "workspace"
SCHEMA  = "finance_training"
spark.sql(f"USE CATALOG {CATALOG}")
spark.sql(f"USE SCHEMA {SCHEMA}")

silver          = spark.table("silver_ledger")
dim_cost_center = spark.table("dim_cost_center")
# dim_category  = spark.table("dim_category")   # 🧩 uncomment once you built it in 03

# COMMAND ----------

# MAGIC %md
# MAGIC ## ✅ Worked example — the signed measure
# MAGIC `amount` is always positive. Income should add and expense should subtract, so
# MAGIC we derive `signed_amount = +amount for Income, -amount for Expense`. Summing it
# MAGIC gives the **net result** directly.

# COMMAND ----------

# MAGIC %md
# MAGIC ## 🧩 CHALLENGE — build `fact_ledger`
# MAGIC Join silver to each dimension to replace text with surrogate keys. The
# MAGIC cost-center join + the signed measure are done; fill in the category `TODO`s.

# COMMAND ----------

fact = (silver
    .withColumn("date_key", F.date_format("entry_date", "yyyyMMdd").cast("int"))   # ✅ done
    .withColumn("signed_amount",
                F.when(F.col("type") == "Income", F.col("amount"))
                 .otherwise(-F.col("amount")))                                     # ✅ worked example
    .join(dim_cost_center, silver.cost_center == dim_cost_center.cost_center_name) # ✅ template join
    # 🧩 TODO: .join(dim_category, silver.category == dim_category.category_name)
    .select(
        "entry_id",
        "date_key",
        "cost_center_key",
        # 🧩 TODO: "category_key",
        "type",
        "amount",
        "signed_amount",
        "description",
    ))

fact.write.mode("overwrite").saveAsTable("fact_ledger")

# COMMAND ----------

# DBTITLE 1,Validate the fact table
display(spark.sql("""
SELECT
  count(*)                                                 AS fact_rows,
  sum(CASE WHEN cost_center_key IS NULL THEN 1 ELSE 0 END) AS missing_cost_center_key,
  sum(CASE WHEN date_key IS NULL THEN 1 ELSE 0 END)        AS missing_date_key
FROM fact_ledger
"""))

# COMMAND ----------

# DBTITLE 1,Smoke test — net result by type
display(spark.sql("""
SELECT type, count(*) AS entries, sum(amount) AS gross, sum(signed_amount) AS net
FROM fact_ledger GROUP BY type
"""))
