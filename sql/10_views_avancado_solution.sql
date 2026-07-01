-- Databricks notebook source
-- MAGIC %md
-- MAGIC # 10 · Temp/Global/Materialized View — SOLUÇÃO
-- MAGIC
-- MAGIC Gabarito completo. Fontes via Federation (catálogo `externo`).
-- MAGIC Lembrete-chave: **MV só lê tabelas persistentes** (bronze), nunca temp views.

-- COMMAND ----------

USE CATALOG workspace;
CREATE SCHEMA IF NOT EXISTS treino_avancado;
USE SCHEMA treino_avancado;

-- COMMAND ----------

-- MAGIC %md
-- MAGIC ## Bronze (persistente) — base de tudo

-- COMMAND ----------

CREATE OR REPLACE TABLE bronze_transacoes AS SELECT * FROM externo.public.transacoes;
CREATE OR REPLACE TABLE bronze_agencias   AS SELECT * FROM externo.public.agencias;
CREATE OR REPLACE TABLE bronze_clientes   AS SELECT * FROM externo.public.clientes;

-- COMMAND ----------

-- MAGIC %md
-- MAGIC ## Desafio 1 — TEMPORARY VIEW (staging da sessão)

-- COMMAND ----------

CREATE OR REPLACE TEMPORARY VIEW stg_transacoes AS
SELECT
  transacao_id,
  cliente_id,
  agencia_id,
  data_transacao,
  trunc(data_transacao, 'MM') AS mes,
  valor,
  initcap(lower(canal))       AS canal,
  status
FROM bronze_transacoes
WHERE status = 'concluida';

SELECT canal, count(*) AS n, sum(valor) AS total FROM stg_transacoes GROUP BY canal ORDER BY total DESC;
-- Esperado: Agencia 3/2509.90, Web 4/1570.50, App 5/1105.25 (12 linhas no total)

-- COMMAND ----------

-- MAGIC %md
-- MAGIC ## Desafio 2 — GLOBAL TEMPORARY VIEW (lê do bronze, compartilhável)

-- COMMAND ----------

CREATE OR REPLACE GLOBAL TEMPORARY VIEW transacoes_enriquecidas AS
SELECT
  t.transacao_id,
  trunc(t.data_transacao, 'MM') AS mes,
  initcap(lower(t.canal))       AS canal,
  t.valor,
  cl.nome                       AS cliente,
  ag.cidade                     AS cidade
FROM bronze_transacoes t
JOIN bronze_clientes cl ON t.cliente_id = cl.cliente_id
JOIN bronze_agencias ag ON t.agencia_id = ag.agencia_id
WHERE t.status = 'concluida';

SELECT * FROM global_temp.transacoes_enriquecidas ORDER BY valor DESC LIMIT 10;
-- Esperado no topo: 1003 Carla Mendes/Goiânia/999.90; 1012 Diego Ferreira/Araxá/890

-- COMMAND ----------

-- MAGIC %md
-- MAGIC ## Desafio 3 — MATERIALIZED VIEW (lê do bronze)

-- COMMAND ----------

CREATE MATERIALIZED VIEW mv_receita_mensal_cidade AS
SELECT
  ag.cidade,
  trunc(t.data_transacao, 'MM') AS mes,
  SUM(t.valor)                  AS receita_mes,
  COUNT(*)                      AS qtd
FROM bronze_transacoes t
JOIN bronze_agencias ag ON t.agencia_id = ag.agencia_id
WHERE t.status = 'concluida'
GROUP BY ag.cidade, trunc(t.data_transacao, 'MM');

SELECT * FROM mv_receita_mensal_cidade ORDER BY cidade, mes;

-- COMMAND ----------

-- MAGIC %md
-- MAGIC ## Desafio 4 — VIEW com window sobre a MV (acumulado)

-- COMMAND ----------

CREATE OR REPLACE VIEW vw_receita_acumulada AS
SELECT
  cidade,
  mes,
  receita_mes,
  SUM(receita_mes) OVER (PARTITION BY cidade ORDER BY mes
                         ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS receita_acumulada
FROM mv_receita_mensal_cidade;

SELECT * FROM vw_receita_acumulada ORDER BY cidade, mes;
-- Esperado (acumulado):
--   Araxá:      320.00 -> 875.25 -> 2025.25
--   Goiânia:    999.90 -> 1119.90 -> 1549.90
--   Uberaba:    620.00 -> 1130.00
--   Uberlândia: 150.50 -> 480.50

-- COMMAND ----------

-- MAGIC %md
-- MAGIC ## Por que cada tipo
-- MAGIC - **stg_transacoes (temp)**: limpeza intermediária, só desta execução — some ao fechar.
-- MAGIC - **transacoes_enriquecidas (global temp)**: outro notebook do mesmo cluster lê via
-- MAGIC   `global_temp.` sem precisar de tabela; por isso lê do bronze, não da temp view.
-- MAGIC - **mv_receita_mensal_cidade (materialized)**: agregação cara, pré-calculada e
-- MAGIC   atualizável via `REFRESH MATERIALIZED VIEW` — serve dashboards. Só lê persistente.
-- MAGIC - **vw_receita_acumulada (view)**: cálculo leve (window) ao vivo sobre a MV.
