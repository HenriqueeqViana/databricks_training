# Databricks notebook source
# MAGIC %md
# MAGIC # 05 · Metrics & Dashboard
# MAGIC
# MAGIC **🇬🇧** Query the star schema to answer business questions, then pin the
# MAGIC results to a **Databricks SQL dashboard**.
# MAGIC
# MAGIC **🇧🇷** Consultamos o modelo estrela para responder perguntas de negócio e
# MAGIC fixamos os resultados em um **dashboard do Databricks SQL**.

# COMMAND ----------

CATALOG = "workspace"
SCHEMA  = "finance_training"
spark.sql(f"USE CATALOG {CATALOG}")
spark.sql(f"USE SCHEMA {SCHEMA}")

# COMMAND ----------

# DBTITLE 1,KPI — total income, expense & net result
display(spark.sql("""
SELECT
  sum(CASE WHEN type = 'Income'  THEN amount ELSE 0 END) AS total_income,
  sum(CASE WHEN type = 'Expense' THEN amount ELSE 0 END) AS total_expense,
  sum(signed_amount)                                     AS net_result
FROM fact_ledger
"""))

# COMMAND ----------

# DBTITLE 1,Net result by month (trend line)
display(spark.sql("""
SELECT d.year, d.month, d.month_name, sum(f.signed_amount) AS net_result
FROM fact_ledger f
JOIN dim_date d ON f.date_key = d.date_key
GROUP BY d.year, d.month, d.month_name
ORDER BY d.year, d.month
"""))

# COMMAND ----------

# DBTITLE 1,Expense by cost center (bar chart)
display(spark.sql("""
SELECT cc.cost_center_name, sum(f.amount) AS total_expense
FROM fact_ledger f
JOIN dim_cost_center cc ON f.cost_center_key = cc.cost_center_key
WHERE f.type = 'Expense'
GROUP BY cc.cost_center_name
ORDER BY total_expense DESC
"""))

# COMMAND ----------

# DBTITLE 1,Top expense categories
display(spark.sql("""
SELECT cat.category_name, sum(f.amount) AS total_expense, count(*) AS entries
FROM fact_ledger f
JOIN dim_category cat ON f.category_key = cat.category_key
WHERE f.type = 'Expense'
GROUP BY cat.category_name
ORDER BY total_expense DESC
LIMIT 10
"""))

# COMMAND ----------

# DBTITLE 1,Income vs Expense by month (grouped chart)
display(spark.sql("""
SELECT d.year, d.month, f.type, sum(f.amount) AS total
FROM fact_ledger f
JOIN dim_date d ON f.date_key = d.date_key
GROUP BY d.year, d.month, f.type
ORDER BY d.year, d.month, f.type
"""))

# COMMAND ----------

# MAGIC %md
# MAGIC ## 📊 Turn these into a dashboard
# MAGIC
# MAGIC 1. **SQL → Dashboards → Create dashboard**.
# MAGIC 2. Add a **dataset** per query above (paste the SQL).
# MAGIC 3. Add visualizations: KPI counters, a **line** for net result by month,
# MAGIC    **bars** for expense by cost center and top categories, a **grouped bar**
# MAGIC    for income vs expense.
# MAGIC 4. Add a **filter** on `year` / `cost_center_name` for interactivity.
# MAGIC
# MAGIC 🧩 **CHALLENGE:** add two metrics of your own — e.g. *average expense per
# MAGIC entry*, *month-over-month growth*, or *top 3 cost centers by net result*.
