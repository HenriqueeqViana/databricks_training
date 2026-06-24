-- Databricks notebook source
-- MAGIC %md
-- MAGIC # 02 · Silver — SOLUTION
-- MAGIC Completed reference for the silver cleaning challenges.

-- COMMAND ----------

USE CATALOG workspace;
USE SCHEMA finance_training;

-- COMMAND ----------

CREATE OR REPLACE TABLE silver_ledger AS
WITH cleaned AS (
  SELECT
    trim(entry_id) AS entry_id,

    -- CHALLENGE 1 — parse both date formats
    coalesce(
      try_to_date(entry_date, 'yyyy-MM-dd'),
      try_to_date(entry_date, 'dd/MM/yyyy')
    ) AS entry_date,

    -- CHALLENGE 2 — trim + title case
    initcap(trim(cost_center)) AS cost_center,

    -- CHALLENGE 3 — standardize categories to English
    CASE lower(trim(category))
      WHEN 'software' THEN 'Software'  WHEN 'licencas' THEN 'Software'  WHEN 'licenças' THEN 'Software'
      WHEN 'impostos' THEN 'Taxes'     WHEN 'tributos' THEN 'Taxes'
      WHEN 'salarios' THEN 'Payroll'   WHEN 'salários' THEN 'Payroll'
      WHEN 'folha' THEN 'Payroll'      WHEN 'folha de pagamento' THEN 'Payroll'
      WHEN 'aluguel' THEN 'Rent'       WHEN 'locacao' THEN 'Rent'
      WHEN 'marketing' THEN 'Marketing' WHEN 'publicidade' THEN 'Marketing' WHEN 'anuncios' THEN 'Marketing'
      WHEN 'viagens' THEN 'Travel'     WHEN 'viagem' THEN 'Travel'
      WHEN 'infraestrutura' THEN 'Infrastructure' WHEN 'infra' THEN 'Infrastructure' WHEN 'cloud' THEN 'Infrastructure'
      WHEN 'servicos' THEN 'Services'  WHEN 'serviços' THEN 'Services' WHEN 'consultoria' THEN 'Services'
      WHEN 'material' THEN 'Supplies'  WHEN 'materiais' THEN 'Supplies' WHEN 'suprimentos' THEN 'Supplies'
      WHEN 'vendas' THEN 'Sales'       WHEN 'venda mensal' THEN 'Sales'
      WHEN 'servicos prestados' THEN 'Services Revenue'
      WHEN 'serviços prestados' THEN 'Services Revenue'
      WHEN 'prestacao de servicos' THEN 'Services Revenue'
      WHEN 'juros' THEN 'Interest'     WHEN 'rendimentos' THEN 'Interest'
      WHEN 'investimentos' THEN 'Investments' WHEN 'aplicacoes' THEN 'Investments'
      ELSE 'Uncategorized'
    END AS category,

    -- WORKED EXAMPLE — amount
    CAST(regexp_replace(amount, '[^0-9.]', '') AS DECIMAL(12,2)) AS amount,

    -- CHALLENGE 4 — type to English
    CASE lower(trim(type))
      WHEN 'receita' THEN 'Income'
      WHEN 'despesa' THEN 'Expense'
    END AS type,

    -- CHALLENGE 5 — clean description
    initcap(trim(regexp_replace(description, '\\s+', ' '))) AS description
  FROM bronze_ledger
)
SELECT DISTINCT *                                   -- CHALLENGE 7 — dedupe
FROM cleaned
WHERE entry_date IS NOT NULL AND amount IS NOT NULL; -- CHALLENGE 6 — drop bad rows

-- COMMAND ----------

SELECT type, count(*) FROM silver_ledger GROUP BY type;
SELECT category, count(*) FROM silver_ledger GROUP BY category ORDER BY 2 DESC;
