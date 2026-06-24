# Databricks notebook source
# MAGIC %md
# MAGIC # 03 · Gold — dimension tables  🧩
# MAGIC
# MAGIC **🇬🇧** Gold = a **star schema**: small descriptive *dimension* tables around
# MAGIC one central *fact* table. Each dimension holds unique attribute values plus a
# MAGIC surrogate key (`*_key`) the fact will point to.
# MAGIC
# MAGIC **🇧🇷** Gold = um **modelo estrela**: dimensões pequenas em volta de um fato
# MAGIC central. Cada dimensão guarda valores únicos + uma chave substituta (`*_key`).
# MAGIC
# MAGIC We build **cost center** (worked example), then **category** and **date**
# MAGIC (your challenges). The fact table is in notebook `04`.

# COMMAND ----------

from pyspark.sql import functions as F
from pyspark.sql.window import Window

CATALOG = "workspace"
SCHEMA  = "finance_training"
spark.sql(f"USE CATALOG {CATALOG}")
spark.sql(f"USE SCHEMA {SCHEMA}")

silver = spark.table("silver_ledger")

# COMMAND ----------

# MAGIC %md
# MAGIC ## ✅ Worked example — `dim_cost_center`
# MAGIC Distinct cost centers + a surrogate key via `row_number()`.

# COMMAND ----------

dim_cost_center = (silver.select("cost_center").distinct()
    .withColumn("cost_center_key", F.row_number().over(Window.orderBy("cost_center")))
    .select("cost_center_key", F.col("cost_center").alias("cost_center_name")))

dim_cost_center.write.mode("overwrite").saveAsTable("dim_cost_center")
display(spark.table("dim_cost_center").orderBy("cost_center_key"))

# COMMAND ----------

# MAGIC %md
# MAGIC ## 🧩 CHALLENGE 1 — `dim_category`
# MAGIC Same recipe as above, for `category`. Columns: `category_key`, `category_name`.
# MAGIC **Bonus:** add a `category_group` with a `F.when(...)` chain.

# COMMAND ----------

# TODO: build and save dim_category


# COMMAND ----------

# MAGIC %md
# MAGIC ## 🧩 CHALLENGE 2 — `dim_date`
# MAGIC One row per calendar day, with the parts broken out. Build from the distinct
# MAGIC `entry_date` values. Suggested columns + hints:
# MAGIC
# MAGIC | column | hint |
# MAGIC |--------|------|
# MAGIC | `date_key`   | `F.date_format("full_date","yyyyMMdd").cast("int")` |
# MAGIC | `full_date`  | the date itself |
# MAGIC | `year`       | `F.year("full_date")` |
# MAGIC | `month`      | `F.month("full_date")` |
# MAGIC | `month_name` | `F.date_format("full_date","MMMM")` |
# MAGIC | `quarter`    | `F.quarter("full_date")` |
# MAGIC | `day`        | `F.dayofmonth("full_date")` |
# MAGIC | `weekday`    | `F.date_format("full_date","EEEE")` |

# COMMAND ----------

# TODO: build and save dim_date
# Start from: silver.select(F.col("entry_date").alias("full_date")).distinct()


# COMMAND ----------

# DBTITLE 1,Validate your dimensions
for t in ["dim_cost_center", "dim_category", "dim_date"]:
    print(f"{t}: {spark.table(t).count()} rows")
