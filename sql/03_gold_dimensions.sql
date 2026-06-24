-- Databricks notebook source
-- MAGIC %md
-- MAGIC # 03 · Gold — dimension tables  🧩
-- MAGIC
-- MAGIC **🇬🇧** Gold = a **star schema**: small descriptive *dimension* tables around
-- MAGIC one central *fact* table. Each dimension holds the unique values of an
-- MAGIC attribute plus a surrogate key (`*_key`) the fact will point to.
-- MAGIC
-- MAGIC **🇧🇷** Gold = um **modelo estrela**: pequenas tabelas de *dimensão* em volta
-- MAGIC de uma tabela de *fato* central. Cada dimensão guarda os valores únicos de um
-- MAGIC atributo + uma chave substituta (`*_key`) que o fato vai referenciar.
-- MAGIC
-- MAGIC We build three dimensions: **cost center** (worked example), **category** and
-- MAGIC **date** (your challenges). The fact table comes in notebook `04`.

-- COMMAND ----------

USE CATALOG workspace;
USE SCHEMA finance_training;

-- COMMAND ----------

-- MAGIC %md
-- MAGIC ## ✅ Worked example — `dim_cost_center`
-- MAGIC
-- MAGIC Take the distinct cost centers from silver and give each a surrogate key.
-- MAGIC `row_number()` is a simple, deterministic way to generate that key.

-- COMMAND ----------

CREATE OR REPLACE TABLE dim_cost_center AS
SELECT
  row_number() OVER (ORDER BY cost_center) AS cost_center_key,
  cost_center                              AS cost_center_name
FROM (SELECT DISTINCT cost_center FROM silver_ledger);

-- COMMAND ----------

SELECT * FROM dim_cost_center ORDER BY cost_center_key;

-- COMMAND ----------

-- MAGIC %md
-- MAGIC ## 🧩 CHALLENGE 1 — `dim_category`
-- MAGIC Build the category dimension exactly like `dim_cost_center` above, but for
-- MAGIC the `category` column. Columns: `category_key`, `category_name`.
-- MAGIC
-- MAGIC **Bonus:** add a `category_group` column ('Operating', 'People', 'Revenue'…)
-- MAGIC using a `CASE` expression.

-- COMMAND ----------

-- TODO: CREATE OR REPLACE TABLE dim_category AS ...


-- COMMAND ----------

-- MAGIC %md
-- MAGIC ## 🧩 CHALLENGE 2 — `dim_date`
-- MAGIC A date dimension has **one row per calendar day** with useful parts broken
-- MAGIC out, so the dashboard can group by year / month / quarter without date math.
-- MAGIC
-- MAGIC Build it from the distinct `entry_date` values. Suggested columns:
-- MAGIC
-- MAGIC | column | hint |
-- MAGIC |--------|------|
-- MAGIC | `date_key`   | `CAST(date_format(entry_date,'yyyyMMdd') AS INT)` (e.g. 20250222) |
-- MAGIC | `full_date`  | the date itself |
-- MAGIC | `year`       | `year(full_date)` |
-- MAGIC | `month`      | `month(full_date)` |
-- MAGIC | `month_name` | `date_format(full_date,'MMMM')` |
-- MAGIC | `quarter`    | `quarter(full_date)` |
-- MAGIC | `day`        | `day(full_date)` |
-- MAGIC | `weekday`    | `date_format(full_date,'EEEE')` |
-- MAGIC
-- MAGIC Using `yyyyMMdd` as the key is a classic date-dimension trick: it is unique,
-- MAGIC sortable, and human-readable.

-- COMMAND ----------

-- TODO: CREATE OR REPLACE TABLE dim_date AS ...


-- COMMAND ----------

-- DBTITLE 1,Validate your dimensions
SELECT 'dim_cost_center' AS dim, count(*) AS rows FROM dim_cost_center
UNION ALL SELECT 'dim_category', count(*) FROM dim_category
UNION ALL SELECT 'dim_date',     count(*) FROM dim_date;
