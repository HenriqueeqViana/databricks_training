-- Databricks notebook source
-- MAGIC %md
-- MAGIC # 03 · Dimensões Gold — SOLUÇÃO

-- COMMAND ----------

USE CATALOG workspace;
USE SCHEMA treino_financeiro;

-- COMMAND ----------

-- EXEMPLO RESOLVIDO
CREATE OR REPLACE TABLE dim_centro_custo AS
SELECT
  row_number() OVER (ORDER BY centro_custo) AS sk_centro_custo,
  centro_custo                              AS nome_centro_custo
FROM (SELECT DISTINCT centro_custo FROM silver_lancamentos);

-- COMMAND ----------

-- DESAFIO 1 — dim_categoria (com bônus grupo_categoria)
CREATE OR REPLACE TABLE dim_categoria AS
SELECT
  row_number() OVER (ORDER BY categoria) AS sk_categoria,
  categoria                              AS nome_categoria,
  CASE
    WHEN categoria IN ('Vendas','Receita de Serviços','Juros','Investimentos') THEN 'Receita'
    WHEN categoria IN ('Folha de Pagamento','Viagens') THEN 'Pessoas'
    ELSE 'Operacional'
  END AS grupo_categoria
FROM (SELECT DISTINCT categoria FROM silver_lancamentos);

-- COMMAND ----------

-- DESAFIO 2 — dim_data
CREATE OR REPLACE TABLE dim_data AS
SELECT
  CAST(date_format(data_completa, 'yyyyMMdd') AS INT) AS sk_data,
  data_completa,
  year(data_completa)                  AS ano,
  month(data_completa)                 AS mes,
  date_format(data_completa, 'MMMM')   AS nome_mes,
  quarter(data_completa)               AS trimestre,
  day(data_completa)                   AS dia,
  date_format(data_completa, 'EEEE')   AS dia_semana
FROM (SELECT DISTINCT data_lancamento AS data_completa FROM silver_lancamentos);

-- COMMAND ----------

SELECT 'dim_centro_custo' AS dimensao, count(*) AS linhas FROM dim_centro_custo
UNION ALL SELECT 'dim_categoria', count(*) FROM dim_categoria
UNION ALL SELECT 'dim_data',      count(*) FROM dim_data;
