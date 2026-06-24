-- Databricks notebook source
-- MAGIC %md
-- MAGIC # 03 · Gold dimensions — SOLUTION

-- COMMAND ----------

USE CATALOG workspace;
USE SCHEMA finance_training;

-- COMMAND ----------

-- WORKED EXAMPLE
CREATE OR REPLACE TABLE dim_cost_center AS
SELECT
  row_number() OVER (ORDER BY cost_center) AS cost_center_key,
  cost_center                              AS cost_center_name
FROM (SELECT DISTINCT cost_center FROM silver_ledger);

-- COMMAND ----------

-- CHALLENGE 1 — dim_category (with bonus category_group)
CREATE OR REPLACE TABLE dim_category AS
SELECT
  row_number() OVER (ORDER BY category) AS category_key,
  category                              AS category_name,
  CASE
    WHEN category IN ('Sales','Services Revenue','Interest','Investments') THEN 'Revenue'
    WHEN category IN ('Payroll','Travel') THEN 'People'
    ELSE 'Operating'
  END AS category_group
FROM (SELECT DISTINCT category FROM silver_ledger);

-- COMMAND ----------

-- CHALLENGE 2 — dim_date
CREATE OR REPLACE TABLE dim_date AS
SELECT
  CAST(date_format(full_date, 'yyyyMMdd') AS INT) AS date_key,
  full_date,
  year(full_date)                  AS year,
  month(full_date)                 AS month,
  date_format(full_date, 'MMMM')   AS month_name,
  quarter(full_date)               AS quarter,
  day(full_date)                   AS day,
  date_format(full_date, 'EEEE')   AS weekday
FROM (SELECT DISTINCT entry_date AS full_date FROM silver_ledger);

-- COMMAND ----------

SELECT 'dim_cost_center' AS dim, count(*) AS rows FROM dim_cost_center
UNION ALL SELECT 'dim_category', count(*) FROM dim_category
UNION ALL SELECT 'dim_date',     count(*) FROM dim_date;
