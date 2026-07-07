-- Databricks notebook source
-- MAGIC %md
-- MAGIC # 02 · Preparação — SOLUÇÃO
-- MAGIC **Não versionar no Git da turma.**

-- COMMAND ----------

USE CATALOG workspace;
USE SCHEMA treino_ml;

-- COMMAND ----------

-- DESAFIO 1 — window function
-- Esperado: médias por canal ~ Agencia 4283 | App 4201 | Web 4161
SELECT
  cliente_id, canal, renda_mensal,
  round(avg(renda_mensal) OVER (PARTITION BY canal), 2)  AS media_canal,
  round(renda_mensal /
        avg(renda_mensal) OVER (PARTITION BY canal) * 100 - 100, 1)
                                                          AS pct_vs_canal
FROM silver_clientes
ORDER BY pct_vs_canal DESC
LIMIT 10;

-- COMMAND ----------

-- DESAFIO 2 — resto estável
SELECT
  CAST(substr(cliente_id, 2) AS INT) % 5 AS resto,
  count(*) AS clientes,
  round(avg(inadimplente), 3) AS taxa
FROM silver_clientes
GROUP BY resto ORDER BY resto;
-- resto=2 é o mais equilibrado com o todo — por isso a regra da turma.

-- COMMAND ----------

-- DESAFIO 3 — split
CREATE OR REPLACE TABLE gold_treino AS
SELECT * FROM silver_clientes
WHERE CAST(substr(cliente_id, 2) AS INT) % 5 <> 2;   -- 726 linhas

-- COMMAND ----------

CREATE OR REPLACE TABLE gold_teste AS
SELECT * FROM silver_clientes
WHERE CAST(substr(cliente_id, 2) AS INT) % 5 = 2;    -- 185 linhas

-- COMMAND ----------

-- DESAFIO 4 — validação
-- Esperado: treino 726 | 0.220  ·  teste 185 | 0.222
SELECT 'treino' AS conjunto, count(*) AS linhas,
       round(avg(inadimplente), 3) AS taxa
FROM gold_treino
UNION ALL
SELECT 'teste', count(*), round(avg(inadimplente), 3)
FROM gold_teste;

-- COMMAND ----------

-- DESAFIO 5 — interseção = 0
SELECT count(*) AS clientes_nos_dois
FROM gold_treino tr
JOIN gold_teste te ON tr.cliente_id = te.cliente_id;

-- COMMAND ----------

-- MAGIC %md
-- MAGIC ## Notas para condução
-- MAGIC - **TABLESAMPLE:** rode 2x na frente da turma — a taxa muda. Gancho perfeito
-- MAGIC   para "por que não usar amostra aleatória como split".
-- MAGIC - **Módulo do id:** com chaves não numéricas o equivalente é
-- MAGIC   `abs(hash(chave)) % 5` — mesmo raciocínio.
-- MAGIC - **Desafio 5:** aqui dá 0 por construção (partição exata); no mundo real,
-- MAGIC   duplicatas na origem quebram isso — por isso a dedupe veio ANTES (Aula 1).
