-- Databricks notebook source
-- MAGIC %md
-- MAGIC # 02 · Silver — clean & standardize  🧩
-- MAGIC
-- MAGIC **🇬🇧** Silver = clean, typed, trustworthy data. We fix the mess from bronze:
-- MAGIC parse numbers and dates, standardize text, map Portuguese values to English,
-- MAGIC and remove duplicates / bad rows.
-- MAGIC
-- MAGIC **🇧🇷** Silver = dado limpo, tipado e confiável. Corrigimos a bagunça do
-- MAGIC bronze: número vira número, data vira data, texto padronizado, valores em
-- MAGIC português mapeados para inglês, e duplicados/linhas ruins removidos.
-- MAGIC
-- MAGIC ## How this notebook works
-- MAGIC The **`amount`** column is done for you as the worked example. Every other
-- MAGIC column has a `🧩 CHALLENGE` with a `TODO`. Replace the TODOs, then run the
-- MAGIC final `CREATE TABLE`. Reference answer: [`solutions/`](../solutions/).

-- COMMAND ----------

USE CATALOG workspace;
USE SCHEMA finance_training;

-- COMMAND ----------

-- MAGIC %md
-- MAGIC ## ✅ Worked example — cleaning `amount`
-- MAGIC
-- MAGIC The raw values look like `R$ 6,273.32`, `5622.22`, `  4,233.82 `, `R$13446.67`.
-- MAGIC They all share one thing: the only characters we care about are **digits and
-- MAGIC the decimal dot**. So we strip everything else and cast to `DECIMAL`.
-- MAGIC
-- MAGIC `regexp_replace(amount, '[^0-9.]', '')` removes `R$`, spaces and thousands
-- MAGIC separators in one shot, leaving e.g. `6273.32`.

-- COMMAND ----------

SELECT
  amount                                              AS amount_raw,
  regexp_replace(amount, '[^0-9.]', '')               AS amount_digits,
  CAST(regexp_replace(amount, '[^0-9.]', '') AS DECIMAL(12,2)) AS amount_clean
FROM bronze_ledger
LIMIT 15;

-- COMMAND ----------

-- MAGIC %md
-- MAGIC ## 🧩 Now build the full silver table
-- MAGIC
-- MAGIC Fill in each `TODO` below. Hints are inline. The `amount` line is already
-- MAGIC done — use it as your template for style.

-- COMMAND ----------

CREATE OR REPLACE TABLE silver_ledger AS
WITH cleaned AS (
  SELECT
    -- id: just trim whitespace
    trim(entry_id) AS entry_id,

    -- 🧩 CHALLENGE 1 — entry_date: parse BOTH formats into a real DATE.
    -- The raw column mixes 'yyyy-MM-dd' and 'dd/MM/yyyy'.
    -- Hint: coalesce(try_to_date(entry_date,'yyyy-MM-dd'),
    --                try_to_date(entry_date,'dd/MM/yyyy'))
    CAST(NULL AS DATE) AS entry_date,                       -- TODO

    -- 🧩 CHALLENGE 2 — cost_center: trim spaces and Title-Case it.
    -- Hint: initcap(trim(cost_center)). (e.g. 'comercial ' -> 'Comercial')
    'TODO' AS cost_center,                                  -- TODO

    -- 🧩 CHALLENGE 3 — category: standardize PT variants into ONE English label.
    -- Hint: first normalize with lower(trim(category)), then a CASE/WHEN that maps
    --   'software'/'licencas'/'licenças'        -> 'Software'
    --   'impostos'/'tributos'                    -> 'Taxes'
    --   'salarios'/'salários'/'folha'/'folha de pagamento' -> 'Payroll'
    --   'vendas'/'venda mensal'                  -> 'Sales'
    --   ... (see the README table for the full list) ...
    --   blank/null                               -> 'Uncategorized'
    'TODO' AS category,                                     -- TODO

    -- ✅ WORKED EXAMPLE — amount (done for you)
    CAST(regexp_replace(amount, '[^0-9.]', '') AS DECIMAL(12,2)) AS amount,

    -- 🧩 CHALLENGE 4 — type: map Receita/Despesa to English (case-insensitive).
    -- Hint: CASE WHEN lower(trim(type)) = 'receita' THEN 'Income'
    --            WHEN lower(trim(type)) = 'despesa' THEN 'Expense' END
    'TODO' AS type,                                         -- TODO

    -- 🧩 CHALLENGE 5 — description: collapse extra spaces and Title-Case it.
    -- Hint: initcap(trim(regexp_replace(description, '\\s+', ' ')))
    'TODO' AS description
  FROM bronze_ledger
)
SELECT *
FROM cleaned
-- 🧩 CHALLENGE 6 — drop rows we cannot use (missing date or amount).
-- Hint: WHERE entry_date IS NOT NULL AND amount IS NOT NULL
;

-- COMMAND ----------

-- MAGIC %md
-- MAGIC ## 🧩 CHALLENGE 7 — remove duplicate rows
-- MAGIC The raw file contains a couple of exact duplicates. After the table above
-- MAGIC works, dedup it. One clean way:
-- MAGIC
-- MAGIC ```sql
-- MAGIC CREATE OR REPLACE TABLE silver_ledger AS
-- MAGIC SELECT DISTINCT * FROM silver_ledger;
-- MAGIC ```
-- MAGIC (Or use `ROW_NUMBER() OVER (PARTITION BY entry_id ORDER BY ...)` and keep `= 1`.)

-- COMMAND ----------

-- DBTITLE 1,Validate your silver table
-- Expect: no NULL dates/amounts, type only Income/Expense, no 'TODO' left.
SELECT
  count(*)                                              AS rows,
  count(DISTINCT entry_id)                              AS distinct_ids,
  sum(CASE WHEN entry_date IS NULL THEN 1 ELSE 0 END)   AS null_dates,
  sum(CASE WHEN amount IS NULL THEN 1 ELSE 0 END)       AS null_amounts,
  count(DISTINCT type)                                  AS distinct_types
FROM silver_ledger;

-- COMMAND ----------

SELECT type, count(*) FROM silver_ledger GROUP BY type;        -- should be Income / Expense
SELECT category, count(*) FROM silver_ledger GROUP BY category ORDER BY 2 DESC;
