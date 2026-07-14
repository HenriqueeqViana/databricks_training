-- Databricks notebook source
-- MAGIC %md
-- MAGIC # 06 · Avaliação — SOLUÇÃO
-- MAGIC **Não versionar no Git da turma.**

-- COMMAND ----------

USE CATALOG workspace;
USE SCHEMA treino_ml;

-- COMMAND ----------

-- DESAFIO 1 — esperado: TP=14 FP=11 FN=27 TN=133 (±1-2 conforme sklearn)
SELECT
  sum(CASE WHEN proba >= 0.5 AND real = 1 THEN 1 ELSE 0 END) AS tp,
  sum(CASE WHEN proba >= 0.5 AND real = 0 THEN 1 ELSE 0 END) AS fp,
  sum(CASE WHEN proba <  0.5 AND real = 1 THEN 1 ELSE 0 END) AS fn,
  sum(CASE WHEN proba <  0.5 AND real = 0 THEN 1 ELSE 0 END) AS tn
FROM predicoes_teste;

-- COMMAND ----------

-- DESAFIO 2 — esperado: precisao ~0.56 | recall ~0.34
WITH matriz AS (
  SELECT
    sum(CASE WHEN proba >= 0.5 AND real = 1 THEN 1 ELSE 0 END) AS tp,
    sum(CASE WHEN proba >= 0.5 AND real = 0 THEN 1 ELSE 0 END) AS fp,
    sum(CASE WHEN proba <  0.5 AND real = 1 THEN 1 ELSE 0 END) AS fn,
    sum(CASE WHEN proba <  0.5 AND real = 0 THEN 1 ELSE 0 END) AS tn
  FROM predicoes_teste
)
SELECT
  round(tp / (tp + fp), 3) AS precisao,
  round(tp / (tp + fn), 3) AS recall
FROM matriz;

-- COMMAND ----------

-- DESAFIO 3 — varredura
CREATE OR REPLACE TABLE matriz_por_threshold AS
WITH thresholds AS (
  SELECT t FROM VALUES (0.2), (0.3), (0.4), (0.5), (0.6), (0.7) AS x(t)
)
SELECT
  th.t,
  sum(CASE WHEN p.proba >= th.t AND p.real = 1 THEN 1 ELSE 0 END) AS tp,
  sum(CASE WHEN p.proba >= th.t AND p.real = 0 THEN 1 ELSE 0 END) AS fp,
  sum(CASE WHEN p.proba <  th.t AND p.real = 1 THEN 1 ELSE 0 END) AS fn,
  sum(CASE WHEN p.proba <  th.t AND p.real = 0 THEN 1 ELSE 0 END) AS tn
FROM predicoes_teste p
CROSS JOIN thresholds th
GROUP BY th.t;

SELECT * FROM matriz_por_threshold ORDER BY t;

-- COMMAND ----------

-- DESAFIO 4 — curva de custo
-- Esperado (aprox.):
--   t=0.2  custo 140.000  <- MÍNIMO
--   t=0.3  custo 159.000
--   t=0.4  custo 197.000
--   t=0.5  custo 281.000
--   t=0.6  custo 313.000
--   t=0.7  custo 390.000
SELECT
  t, fn, fp,
  fn * 10000 + fp * 1000 AS custo_total
FROM matriz_por_threshold
ORDER BY custo_total;

-- COMMAND ----------

-- DESAFIO 5 — exemplo de recomendação
-- "Recomendo t = 0.2: revisamos ~93 dos 185 pedidos (metade da esteira),
--  capturamos 33 dos 41 calotes e reduzimos o custo esperado de perda de
--  R$ 281 mil para R$ 140 mil (-50%) em relação ao corte padrão de 0.5."

-- COMMAND ----------

-- MAGIC %md
-- MAGIC ## Notas para condução
-- MAGIC - **O clímax da aula é o Desafio 4:** o t "intuitivo" (0.5) custa o DOBRO
-- MAGIC   do ótimo. Threshold é decisão de negócio parametrizada pelo custo.
-- MAGIC - **Trade-off operacional:** t=0.2 manda ~50% da esteira para revisão —
-- MAGIC   pergunte: "a mesa de crédito dá conta?" Se não, o custo de operação
-- MAGIC   entra na função e o ótimo muda. Não existe resposta só estatística.
-- MAGIC - **AutoML (deck):** nas edições pagas o AutoML faz busca de modelo e
-- MAGIC   métrica automaticamente — mas a curva de custo continua sendo trabalho
-- MAGIC   de quem entende o negócio.
