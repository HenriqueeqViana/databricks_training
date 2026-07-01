-- Databricks notebook source
-- MAGIC %md
-- MAGIC # 04 · Fato Gold — SOLUÇÃO

-- COMMAND ----------

USE CATALOG workspace;
USE SCHEMA treino_financeiro;

-- COMMAND ----------

SELECT
  s.id_lancamento,
  CAST(date_format(s.data_lancamento, 'yyyyMMdd') AS INT)             AS sk_data,
  cc.sk_centro_custo,
  cat.sk_categoria,
  tp.sk_tipo,
  s.valor,
  CASE WHEN sk_tipo = 1 THEN s.valor ELSE -s.valor END         AS valor_sinalizado,
  s.descricao
FROM silver_lancamentos s
JOIN dim_centro_custo cc ON s.centro_custo = cc.nome_centro_custo
JOIN dim_categoria    cat ON s.categoria    = cat.nome_categoria
JOIN dim_tipo   tp ON s.tipo = tp.tipo

-- COMMAND ----------

CREATE OR REPLACE TABLE fato_lancamentos AS
SELECT
  s.id_lancamento,
  CAST(date_format(s.data_lancamento, 'yyyyMMdd') AS INT)             AS sk_data,
  cc.sk_centro_custo,
  cat.sk_categoria,
  tp.sk_tipo,
  s.valor,
  CASE WHEN sk_tipo = 1 THEN s.valor ELSE -s.valor END         AS valor_sinalizado,
  s.descricao
FROM silver_lancamentos s
JOIN dim_centro_custo cc ON s.centro_custo = cc.nome_centro_custo
JOIN dim_categoria    cat ON s.categoria    = cat.nome_categoria
JOIN dim_tipo   tp ON s.tipo = tp.tipo;

-- COMMAND ----------

SELECT
  count(*)                                                AS linhas_fato,
  sum(CASE WHEN sk_centro_custo IS NULL THEN 1 ELSE 0 END) AS sk_centro_custo_faltando,
  sum(CASE WHEN sk_categoria   IS NULL THEN 1 ELSE 0 END)  AS sk_categoria_faltando,
  sum(CASE WHEN sk_data        IS NULL THEN 1 ELSE 0 END)  AS sk_data_faltando,
  sum(CASE WHEN sk_tipo   IS NULL THEN 1 ELSE 0 END)  AS sk_tipo_faltando
FROM fato_lancamentos;
