-- Databricks notebook source
-- MAGIC %md
-- MAGIC # 04 · Gold fact — SOLUTION

-- COMMAND ----------

USE CATALOG workspace;
USE SCHEMA finance_training;

-- COMMAND ----------

CREATE OR REPLACE TABLE fact_ledger AS
SELECT
  s.entry_id,
  CAST(date_format(s.entry_date, 'yyyyMMdd') AS INT)          AS date_key,
  cc.cost_center_key,
  cat.category_key,
  s.type,
  s.amount,
  CASE WHEN s.type = 'Income' THEN s.amount ELSE -s.amount END AS signed_amount,
  s.description
FROM silver_ledger s
JOIN dim_cost_center cc ON s.cost_center = cc.cost_center_name
JOIN dim_category    cat ON s.category    = cat.category_name;

-- COMMAND ----------

SELECT
  count(*)                                                  AS fact_rows,
  sum(CASE WHEN cost_center_key IS NULL THEN 1 ELSE 0 END)  AS missing_cost_center_key,
  sum(CASE WHEN category_key   IS NULL THEN 1 ELSE 0 END)   AS missing_category_key,
  sum(CASE WHEN date_key        IS NULL THEN 1 ELSE 0 END)  AS missing_date_key
FROM fact_ledger;
