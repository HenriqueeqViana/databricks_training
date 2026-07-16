-- Databricks notebook source
-- MAGIC %md
-- MAGIC # 09 · Monitoramento — o drift em SQL
-- MAGIC
-- MAGIC **Cenário:** na Aula 8 ficou a pulga atrás da orelha: 57% da carteira nova
-- MAGIC caiu em revisão, contra ~30% esperado. Hoje a gente **prova** que a
-- MAGIC população mudou — com estatística comparada e **PSI**, tudo em SQL.
-- MAGIC
-- MAGIC PSI (Population Stability Index), por faixa:
-- MAGIC `psi = soma( (p - q) * ln(p / q) )` — p = proporção no treino, q = na
-- MAGIC carteira. Régua: < 0.1 estável · 0.1–0.25 atenção · > 0.25 **drift, reaja**.
-- MAGIC
-- MAGIC > Pré-requisito: notebook `08_inferencia` (`carteira_novos` existe).

-- COMMAND ----------

USE CATALOG workspace;
USE SCHEMA treino_ml;

-- COMMAND ----------

-- MAGIC %md
-- MAGIC ## DESAFIO 1 — as duas populações lado a lado
-- MAGIC Compare média e mediana de `score_bureau` e `renda_mensal` entre
-- MAGIC `gold_treino` e `carteira_novos`, numa query só (UNION ALL).

-- COMMAND ----------

SELECT 'treino' AS populacao,
       round(avg(score_bureau), 1)   AS media_score,
       round(percentile_cont(0.5) WITHIN GROUP (ORDER BY score_bureau), 1)
                                     AS mediana_score,
       round(avg(renda_mensal), 2)   AS media_renda
FROM ___
UNION ALL
SELECT 'carteira',
       round(avg(score_bureau), 1),
       round(percentile_cont(0.5) WITHIN GROUP (ORDER BY score_bureau), 1),
       round(avg(renda_mensal), 2)
FROM ___;

-- COMMAND ----------

-- MAGIC %md
-- MAGIC **Checkpoint 1:** score médio caiu de ~**601** para ~**544**; renda média
-- MAGIC subiu de ~**4.2 mil** para ~**6.5 mil**. A carteira nova é OUTRA população.

-- COMMAND ----------

-- MAGIC %md
-- MAGIC ## DESAFIO 2 — proporções por faixa de score
-- MAGIC Para o PSI precisamos da fração de clientes em cada faixa, nas duas
-- MAGIC populações. As faixas são as mesmas da Aula 1. Complete os limites e a
-- MAGIC divisão pelo total (dica: `count(*) / sum(count(*)) OVER ()`).

-- COMMAND ----------

CREATE OR REPLACE TEMPORARY VIEW prop_treino AS
SELECT
  CASE
    WHEN score_bureau <= ___ THEN '300-500'
    WHEN score_bureau <= ___ THEN '501-650'
    WHEN score_bureau <= ___ THEN '651-800'
    ELSE '801-900'
  END AS faixa,
  count(*) / ___ AS pct
FROM gold_treino
GROUP BY faixa;

CREATE OR REPLACE TEMPORARY VIEW prop_carteira AS
SELECT
  CASE
    WHEN score_bureau <= 500 THEN '300-500'
    WHEN score_bureau <= 650 THEN '501-650'
    WHEN score_bureau <= 800 THEN '651-800'
    ELSE '801-900'
  END AS faixa,
  count(*) / sum(count(*)) OVER () AS pct
FROM carteira_novos
GROUP BY faixa;

SELECT t.faixa, round(t.pct, 3) AS pct_treino,
       round(coalesce(c.pct, 0), 3) AS pct_carteira
FROM prop_treino t
LEFT JOIN prop_carteira c USING (faixa)
ORDER BY t.faixa;

-- COMMAND ----------

-- MAGIC %md
-- MAGIC **Checkpoint 2:** a faixa **801-900** tem ~15% no treino e **0%** na
-- MAGIC carteira — os clientes de score alto sumiram. E um zero na proporção
-- MAGIC quebra o `ln(p/q)`… o próximo desafio resolve.

-- COMMAND ----------

-- MAGIC %md
-- MAGIC ## DESAFIO 3 — o PSI (com guarda de zero)
-- MAGIC `greatest(pct, 0.001)` impõe um piso e evita a divisão por zero.
-- MAGIC Complete a fórmula: `(p - q) * ln(p / q)` somada nas faixas.

-- COMMAND ----------

WITH pares AS (
  SELECT
    t.faixa,
    greatest(t.pct, 0.001)               AS p,
    greatest(coalesce(c.pct, 0), 0.001)  AS q
  FROM prop_treino t
  LEFT JOIN prop_carteira c USING (faixa)
)
SELECT round(sum( (___ - ___) * ln(___ / ___) ), 3) AS psi_score
FROM pares;

-- COMMAND ----------

-- MAGIC %md
-- MAGIC **Checkpoint 3:** PSI do score ≈ **0.88** — muito acima de 0.25.
-- MAGIC Drift gritante, e agora com número, não com intuição.

-- COMMAND ----------

-- MAGIC %md
-- MAGIC ## DESAFIO 4 — o monitor mínimo viável
-- MAGIC Transforme o número em **status acionável** com um CASE:
-- MAGIC `> 0.25` → ALERTA_RETREINAR · `> 0.10` → ATENCAO · senão → OK.

-- COMMAND ----------

WITH pares AS (
  SELECT greatest(t.pct, 0.001) AS p,
         greatest(coalesce(c.pct, 0), 0.001) AS q
  FROM prop_treino t
  LEFT JOIN prop_carteira c USING (faixa)
),
indice AS (
  SELECT round(sum((p - q) * ln(p / q)), 3) AS psi FROM pares
)
SELECT
  'score_bureau' AS feature,
  psi,
  CASE
    WHEN psi > ___ THEN '___'
    WHEN psi > ___ THEN '___'
    ELSE 'OK'
  END AS status
FROM indice;

-- COMMAND ----------

-- MAGIC %md
-- MAGIC ## DESAFIO BÔNUS — e a renda, também driftou?
-- MAGIC Repita o PSI para `renda_mensal`, agora com faixas pelos **quartis do
-- MAGIC treino** (no treino cada faixa terá ~25% por construção). As CTEs de
-- MAGIC corte e proporção já vêm prontas — falta só completar a fórmula do PSI,
-- MAGIC igual você fez no Desafio 3.

-- COMMAND ----------

WITH cortes AS (
  SELECT
    percentile_cont(0.25) WITHIN GROUP (ORDER BY renda_mensal) AS c1,
    percentile_cont(0.50) WITHIN GROUP (ORDER BY renda_mensal) AS c2,
    percentile_cont(0.75) WITHIN GROUP (ORDER BY renda_mensal) AS c3
  FROM gold_treino
),
pt AS (
  SELECT CASE WHEN renda_mensal <= c1 THEN 'q1'
              WHEN renda_mensal <= c2 THEN 'q2'
              WHEN renda_mensal <= c3 THEN 'q3'
              ELSE 'q4' END AS faixa,
         count(*) / sum(count(*)) OVER () AS pct
  FROM gold_treino CROSS JOIN cortes
  GROUP BY faixa
),
pc AS (
  SELECT CASE WHEN renda_mensal <= c1 THEN 'q1'
              WHEN renda_mensal <= c2 THEN 'q2'
              WHEN renda_mensal <= c3 THEN 'q3'
              ELSE 'q4' END AS faixa,
         count(*) / sum(count(*)) OVER () AS pct
  FROM carteira_novos CROSS JOIN cortes
  GROUP BY faixa
),
pares AS (
  SELECT
    pt.faixa,
    greatest(pt.pct, 0.001)              AS p,
    greatest(coalesce(pc.pct, 0), 0.001) AS q
  FROM pt LEFT JOIN pc USING (faixa)
)
SELECT round(sum( (___ - ___) * ln(___ / ___) ), 3) AS psi_renda
FROM pares;

-- COMMAND ----------

-- MAGIC %md
-- MAGIC ## Como saber se acertou
-- MAGIC - [ ] Checkpoint 1: score 601 → 544; renda 4.2 mil → 6.5 mil
-- MAGIC - [ ] Checkpoint 2: faixa 801-900 zerada na carteira
-- MAGIC - [ ] PSI do score ≈ **0.88** → status **ALERTA_RETREINAR**
-- MAGIC - [ ] Bônus: PSI da renda ≈ **0.44** — também em alerta
-- MAGIC - [ ] Você sabe dizer o próximo passo (retreinar com dado novo e
-- MAGIC       registrar como @challenger — ciclo da Aula 7 de novo)
-- MAGIC
-- MAGIC Travou? Levanta a mão. A resposta de referência fica com o instrutor.
