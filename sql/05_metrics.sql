-- Databricks notebook source
-- MAGIC %md
-- MAGIC # 05 · Metrics & Dashboard
-- MAGIC
-- MAGIC **🇬🇧** Now the payoff: query the star schema to answer business questions,
-- MAGIC then pin the results to a **Databricks SQL dashboard**.
-- MAGIC
-- MAGIC **🇧🇷** A recompensa: consultamos o modelo estrela para responder perguntas de
-- MAGIC negócio e depois fixamos os resultados em um **dashboard do Databricks SQL**.
-- MAGIC
-- MAGIC Notice how readable these queries are — that is the *point* of the star
-- MAGIC schema: join the fact to the dimensions and `GROUP BY` plain English columns.

-- COMMAND ----------

USE CATALOG workspace;
USE SCHEMA finance_training;

-- COMMAND ----------

-- DBTITLE 1,KPI — total income, expense & net result
SELECT
  sum(CASE WHEN type = 'Income'  THEN amount ELSE 0 END) AS total_income,
  sum(CASE WHEN type = 'Expense' THEN amount ELSE 0 END) AS total_expense,
  sum(signed_amount)                                     AS net_result
FROM fact_ledger;

-- COMMAND ----------

-- DBTITLE 1,Net result by month (trend line)
SELECT
  d.year,
  d.month,
  d.month_name,
  sum(f.signed_amount) AS net_result
FROM fact_ledger f
JOIN dim_date d ON f.date_key = d.date_key
GROUP BY d.year, d.month, d.month_name
ORDER BY d.year, d.month;

-- COMMAND ----------

-- DBTITLE 1,Expense by cost center (bar chart)
SELECT
  cc.cost_center_name,
  sum(f.amount) AS total_expense
FROM fact_ledger f
JOIN dim_cost_center cc ON f.cost_center_key = cc.cost_center_key
WHERE f.type = 'Expense'
GROUP BY cc.cost_center_name
ORDER BY total_expense DESC;

-- COMMAND ----------

-- DBTITLE 1,Top expense categories
SELECT
  cat.category_name,
  sum(f.amount) AS total_expense,
  count(*)      AS entries
FROM fact_ledger f
JOIN dim_category cat ON f.category_key = cat.category_key
WHERE f.type = 'Expense'
GROUP BY cat.category_name
ORDER BY total_expense DESC
LIMIT 10;

-- COMMAND ----------

-- DBTITLE 1,Income vs Expense by month (grouped chart)
SELECT
  d.year,
  d.month,
  f.type,
  sum(f.amount) AS total
FROM fact_ledger f
JOIN dim_date d ON f.date_key = d.date_key
GROUP BY d.year, d.month, f.type
ORDER BY d.year, d.month, f.type;

-- COMMAND ----------

-- MAGIC %md
-- MAGIC ## 📊 Turn these into a dashboard
-- MAGIC
-- MAGIC 1. Open **SQL → Dashboards → Create dashboard** (Databricks SQL).
-- MAGIC 2. Add a **dataset** for each query above (paste the SQL).
-- MAGIC 3. Add visualizations on the canvas:
-- MAGIC    - KPI counters for *total income / expense / net result*.
-- MAGIC    - **Line** chart for *net result by month*.
-- MAGIC    - **Bar** chart for *expense by cost center*.
-- MAGIC    - **Bar** chart for *top expense categories*.
-- MAGIC    - **Grouped bar** for *income vs expense by month*.
-- MAGIC 4. Add a **filter** widget on `year` / `cost_center_name` to make it interactive.
-- MAGIC
-- MAGIC 🧩 **CHALLENGE:** add two more metrics of your own — e.g. *average expense per
-- MAGIC entry*, *month-over-month growth*, or *top 3 cost centers by net result*.
