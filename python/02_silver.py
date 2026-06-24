# Databricks notebook source
# MAGIC %md
# MAGIC # 02 · Silver — clean & standardize  🧩
# MAGIC
# MAGIC **🇬🇧** Silver = clean, typed, trustworthy data. Parse numbers and dates,
# MAGIC standardize text, map Portuguese values to English, drop duplicates/bad rows.
# MAGIC
# MAGIC **🇧🇷** Silver = dado limpo, tipado e confiável. Número vira número, data vira
# MAGIC data, texto padronizado, valores PT→EN, duplicados/linhas ruins removidos.
# MAGIC
# MAGIC ## How this notebook works
# MAGIC The **`amount`** column is done for you as the worked example. Every other
# MAGIC column has a `🧩 CHALLENGE` with a `TODO`. Fill them in, then write the table.
# MAGIC Reference answer: [`solutions/`](../solutions/).

# COMMAND ----------

from pyspark.sql import functions as F

CATALOG = "workspace"
SCHEMA  = "finance_training"
spark.sql(f"USE CATALOG {CATALOG}")
spark.sql(f"USE SCHEMA {SCHEMA}")

bronze = spark.table("bronze_ledger")

# COMMAND ----------

# MAGIC %md
# MAGIC ## ✅ Worked example — cleaning `amount`
# MAGIC
# MAGIC Raw values look like `R$ 6,273.32`, `5622.22`, `  4,233.82 `, `R$13446.67`.
# MAGIC The only characters that matter are **digits and the decimal dot**, so we strip
# MAGIC everything else with a regex and cast to `decimal`.

# COMMAND ----------

amount_clean = F.regexp_replace(F.col("amount"), r"[^0-9.]", "").cast("decimal(12,2)")
display(bronze.select(
    F.col("amount").alias("amount_raw"),
    amount_clean.alias("amount_clean"),
).limit(15))

# COMMAND ----------

# MAGIC %md
# MAGIC ## 🧩 Build the full silver DataFrame
# MAGIC Replace each `TODO` expression. The `amount` column is your template.

# COMMAND ----------

silver = bronze.select(
    F.trim("entry_id").alias("entry_id"),

    # 🧩 CHALLENGE 1 — entry_date: parse BOTH 'yyyy-MM-dd' and 'dd/MM/yyyy' to date.
    # Hint: F.coalesce(F.to_date("entry_date","yyyy-MM-dd"),
    #                  F.to_date("entry_date","dd/MM/yyyy"))
    F.lit(None).cast("date").alias("entry_date"),                       # TODO

    # 🧩 CHALLENGE 2 — cost_center: trim + Title-Case.  Hint: F.initcap(F.trim(...))
    F.lit("TODO").alias("cost_center"),                                 # TODO

    # 🧩 CHALLENGE 3 — category: map PT variants -> ONE English label.
    # Hint: build cat = F.lower(F.trim("category")) then a chained
    #   F.when(cat.isin("software","licencas","licenças"), "Software")
    #    .when(cat.isin("impostos","tributos"), "Taxes")
    #    ... (see README for the full mapping) ...
    #    .when((cat == "") | cat.isNull(), "Uncategorized")
    F.lit("TODO").alias("category"),                                    # TODO

    # ✅ WORKED EXAMPLE — amount (done for you)
    F.regexp_replace(F.col("amount"), r"[^0-9.]", "").cast("decimal(12,2)").alias("amount"),

    # 🧩 CHALLENGE 4 — type: Receita->Income, Despesa->Expense (case-insensitive).
    # Hint: t = F.lower(F.trim("type"));  F.when(t=="receita","Income").when(t=="despesa","Expense")
    F.lit("TODO").alias("type"),                                        # TODO

    # 🧩 CHALLENGE 5 — description: collapse spaces + Title-Case.
    # Hint: F.initcap(F.trim(F.regexp_replace("description", r"\s+", " ")))
    F.lit("TODO").alias("description"),
)

# 🧩 CHALLENGE 6 — drop unusable rows (missing date or amount):
# silver = silver.filter(F.col("entry_date").isNotNull() & F.col("amount").isNotNull())

# 🧩 CHALLENGE 7 — remove exact duplicates:
# silver = silver.dropDuplicates()

silver.write.mode("overwrite").option("overwriteSchema", "true").saveAsTable("silver_ledger")

# COMMAND ----------

# DBTITLE 1,Validate your silver table
display(spark.sql("""
SELECT
  count(*)                                             AS rows,
  count(DISTINCT entry_id)                             AS distinct_ids,
  sum(CASE WHEN entry_date IS NULL THEN 1 ELSE 0 END)  AS null_dates,
  sum(CASE WHEN amount IS NULL THEN 1 ELSE 0 END)      AS null_amounts,
  count(DISTINCT type)                                 AS distinct_types
FROM silver_ledger
"""))

# COMMAND ----------

display(spark.sql("SELECT type, count(*) AS n FROM silver_ledger GROUP BY type"))
display(spark.sql("SELECT category, count(*) AS n FROM silver_ledger GROUP BY category ORDER BY n DESC"))
