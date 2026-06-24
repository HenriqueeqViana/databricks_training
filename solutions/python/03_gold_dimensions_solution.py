# Databricks notebook source
# MAGIC %md
# MAGIC # 03 · Gold dimensions — SOLUTION (PySpark)

# COMMAND ----------

from pyspark.sql import functions as F
from pyspark.sql.window import Window

spark.sql("USE CATALOG workspace")
spark.sql("USE SCHEMA finance_training")
silver = spark.table("silver_ledger")

# COMMAND ----------

# dim_cost_center (worked example)
dim_cost_center = (silver.select("cost_center").distinct()
    .withColumn("cost_center_key", F.row_number().over(Window.orderBy("cost_center")))
    .select("cost_center_key", F.col("cost_center").alias("cost_center_name")))
dim_cost_center.write.mode("overwrite").saveAsTable("dim_cost_center")

# COMMAND ----------

# dim_category (CHALLENGE 1 + bonus group)
group = (F.when(F.col("category").isin("Sales", "Services Revenue", "Interest", "Investments"), "Revenue")
          .when(F.col("category").isin("Payroll", "Travel"), "People")
          .otherwise("Operating"))

dim_category = (silver.select("category").distinct()
    .withColumn("category_key", F.row_number().over(Window.orderBy("category")))
    .withColumn("category_group", group)
    .select("category_key", F.col("category").alias("category_name"), "category_group"))
dim_category.write.mode("overwrite").saveAsTable("dim_category")

# COMMAND ----------

# dim_date (CHALLENGE 2)
dim_date = (silver.select(F.col("entry_date").alias("full_date")).distinct()
    .withColumn("date_key", F.date_format("full_date", "yyyyMMdd").cast("int"))
    .withColumn("year", F.year("full_date"))
    .withColumn("month", F.month("full_date"))
    .withColumn("month_name", F.date_format("full_date", "MMMM"))
    .withColumn("quarter", F.quarter("full_date"))
    .withColumn("day", F.dayofmonth("full_date"))
    .withColumn("weekday", F.date_format("full_date", "EEEE"))
    .select("date_key", "full_date", "year", "month", "month_name", "quarter", "day", "weekday"))
dim_date.write.mode("overwrite").saveAsTable("dim_date")

# COMMAND ----------

for t in ["dim_cost_center", "dim_category", "dim_date"]:
    print(f"{t}: {spark.table(t).count()} rows")
