-- Databricks notebook source
-- MAGIC %md
-- MAGIC # 04 · Gold — fact table  🧩
-- MAGIC
-- MAGIC **🇬🇧** The **fact** table is the heart of the star schema: one row per
-- MAGIC business event (here, one ledger entry). It stores the **measures** (the
-- MAGIC numbers we add up) and **foreign keys** pointing to each dimension —
-- MAGIC *not* the descriptive text, which lives in the dimensions.
-- MAGIC
-- MAGIC **🇧🇷** A tabela **fato** é o coração do modelo estrela: uma linha por evento
-- MAGIC (aqui, um lançamento). Guarda as **métricas** (os números que somamos) e as
-- MAGIC **chaves estrangeiras** para cada dimensão — não o texto descritivo, que
-- MAGIC fica nas dimensões.

-- COMMAND ----------

USE CATALOG workspace;
USE SCHEMA finance_training;

-- COMMAND ----------

-- MAGIC %md
-- MAGIC ## ✅ Worked example — the signed measure
-- MAGIC
-- MAGIC `amount` in silver is always positive. For a P&L we want **income to add**
-- MAGIC and **expense to subtract**, so we derive a `signed_amount`:
-- MAGIC
-- MAGIC ```sql
-- MAGIC CASE WHEN type = 'Income' THEN amount ELSE -amount END
-- MAGIC ```
-- MAGIC Sum that column and you get the **net result** directly.

-- COMMAND ----------

-- MAGIC %md
-- MAGIC ## 🧩 CHALLENGE — build `fact_ledger`
-- MAGIC
-- MAGIC Join `silver_ledger` to each dimension to swap descriptive text for the
-- MAGIC surrogate keys. The skeleton is below — fill in the two `TODO` joins and the
-- MAGIC two `TODO` key columns. (The cost-center join is done as your template.)

-- COMMAND ----------

CREATE OR REPLACE TABLE fact_ledger AS
SELECT
  s.entry_id,

  -- date key: same yyyyMMdd formula you used to build dim_date
  CAST(date_format(s.entry_date, 'yyyyMMdd') AS INT) AS date_key,        -- ✅ done

  cc.cost_center_key,                                                    -- ✅ done (from join below)

  -- 🧩 TODO: bring in the category surrogate key
  NULL AS category_key,                                                  -- TODO -> cat.category_key

  -- measures
  s.type,
  s.amount,
  CASE WHEN s.type = 'Income' THEN s.amount ELSE -s.amount END AS signed_amount,  -- ✅ worked example
  s.description
FROM silver_ledger s
JOIN dim_cost_center cc ON s.cost_center = cc.cost_center_name           -- ✅ template join
-- 🧩 TODO: JOIN dim_category cat ON s.category = cat.category_name
;

-- COMMAND ----------

-- DBTITLE 1,Validate the fact table
-- Every fact row must match a dimension row (no orphan/NULL keys).
SELECT
  count(*)                                                  AS fact_rows,
  sum(CASE WHEN cost_center_key IS NULL THEN 1 ELSE 0 END)  AS missing_cost_center_key,
  sum(CASE WHEN category_key   IS NULL THEN 1 ELSE 0 END)   AS missing_category_key,
  sum(CASE WHEN date_key        IS NULL THEN 1 ELSE 0 END)  AS missing_date_key
FROM fact_ledger;

-- COMMAND ----------

-- DBTITLE 1,Quick smoke test — net result by type
SELECT type, count(*) AS entries, sum(amount) AS gross, sum(signed_amount) AS net
FROM fact_ledger
GROUP BY type;
