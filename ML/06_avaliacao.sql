-- Databricks notebook source
-- MAGIC %md
-- MAGIC # 06 · Avaliação — da probabilidade à decisão (em SQL)
-- MAGIC
-- MAGIC **Cenário:** a `predicoes_teste` (Aula 5) tem a probabilidade de cada
-- MAGIC cliente. Mas o negócio não decide com probabilidade — decide com um
-- MAGIC **threshold**: `proba >= t` → mandar para revisão de crédito.
-- MAGIC
-- MAGIC Os 4 resultados possíveis pra cada cliente:
-- MAGIC - **TP** (acertei o risco): previ calote, e ele realmente deu calote
-- MAGIC - **TN** (acertei o pagamento): não revisei, e ele realmente pagou
-- MAGIC - **FN** (aprovei quem deu calote): **R$ 10.000** por erro
-- MAGIC - **FP** (revisei quem pagaria): **R$ 1.000** por erro
-- MAGIC
-- MAGIC > Pré-requisito: notebook `05_modelos` (`predicoes_teste` existe).

-- COMMAND ----------

USE CATALOG workspace;
USE SCHEMA treino_ml;

-- COMMAND ----------

SELECT * FROM predicoes_teste ORDER BY proba DESC LIMIT 10;

-- COMMAND ----------

-- MAGIC %md
-- MAGIC ## DESAFIO 1 — matriz de confusão @ 0.5
-- MAGIC As 4 células com `sum(CASE WHEN ...)`. A do TP está pronta como modelo:
-- MAGIC predito 1 (`proba >= 0.5`) **e** real 1. Complete as outras três.
-- MAGIC
-- MAGIC **Antes de rodar — sua aposta:** qual erro vai ser maior no threshold de
-- MAGIC 0.5, FP (revisei quem pagaria) ou FN (aprovei quem não pagou)?
-- MAGIC *Dica: pense no que é mais comum, o modelo "deixar passar" um risco ou
-- MAGIC "desconfiar à toa".*

-- COMMAND ----------

-- Minha aposta: FP ou FN?
-- ___

-- COMMAND ----------

SELECT
  sum(CASE WHEN proba >= 0.5 AND real = 1 THEN 1 ELSE 0 END) AS tp,
  sum(CASE WHEN ___          AND ___      THEN 1 ELSE 0 END) AS fp,
  sum(CASE WHEN ___          AND ___      THEN 1 ELSE 0 END) AS fn,
  sum(CASE WHEN ___          AND ___      THEN 1 ELSE 0 END) AS tn
FROM predicoes_teste;

-- COMMAND ----------

-- MAGIC %md
-- MAGIC **Checkpoint 1:** aproximadamente TP=**14**, FP=**11**, FN=**27**,
-- MAGIC TN=**133** (soma = 185). Repare: 27 calotes passaram batido no 0.5.
-- MAGIC FN é maior que FP — bateu com sua aposta?

-- COMMAND ----------

-- MAGIC %md
-- MAGIC ## DESAFIO 2 — precisão e recall a partir das células
-- MAGIC - precisão = TP / (TP + FP) — dos que apontei, quantos eram mesmo?
-- MAGIC - recall   = TP / (TP + FN) — dos maus, quantos eu peguei?
-- MAGIC
-- MAGIC **Antes de rodar — sua aposta:** a precisão vai ser maior, menor ou igual
-- MAGIC ao recall?

-- COMMAND ----------

-- Minha aposta: precisão maior, menor ou igual ao recall?
-- ___

-- COMMAND ----------

WITH matriz AS (
  SELECT
    sum(CASE WHEN proba >= 0.5 AND real = 1 THEN 1 ELSE 0 END) AS tp,
    sum(CASE WHEN proba >= 0.5 AND real = 0 THEN 1 ELSE 0 END) AS fp,
    sum(CASE WHEN proba <  0.5 AND real = 1 THEN 1 ELSE 0 END) AS fn,
    sum(CASE WHEN proba <  0.5 AND real = 0 THEN 1 ELSE 0 END) AS tn
  FROM predicoes_teste
)
SELECT
  round(tp / (tp + ___), 3) AS precisao,   -- TODO
  round(tp / (tp + ___), 3) AS recall      -- TODO
FROM matriz;

-- COMMAND ----------

-- MAGIC %md
-- MAGIC **Checkpoint 2:** precisão ~**0.56**, recall ~**0.34** — o 0.5 pega só um
-- MAGIC terço dos calotes. Precisão maior que recall — bateu com sua aposta?
-- MAGIC Será que é o t certo? Vamos colocar preço nisso.

-- COMMAND ----------

-- MAGIC %md
-- MAGIC ## DESAFIO 3 — varra os thresholds de uma vez (CROSS JOIN)
-- MAGIC A tabela `VALUES` lista os candidatos a `t`; o `CROSS JOIN` avalia todos
-- MAGIC numa query só. Complete a condição de predição e a fórmula do custo.
-- MAGIC
-- MAGIC **Antes de rodar — sua aposta:** entre 0.2, 0.3, 0.4, 0.5, 0.6 e 0.7,
-- MAGIC qual threshold você acha que vai ter o MENOR custo total? (resposta no
-- MAGIC Desafio 4)
-- MAGIC *Dica: releia os custos lá no topo do notebook antes de apostar.*

-- COMMAND ----------

-- Minha aposta: qual t tem o menor custo total?
-- ___

-- COMMAND ----------

CREATE OR REPLACE TABLE matriz_por_threshold AS
WITH thresholds AS (
  SELECT t FROM VALUES (0.2), (0.3), (0.4), (0.5), (0.6), (0.7) AS x(t)
)
SELECT
  th.t,
  sum(CASE WHEN p.proba >= th.___ AND p.real = 1 THEN 1 ELSE 0 END) AS tp,
  sum(CASE WHEN p.proba >= th.___ AND p.real = 0 THEN 1 ELSE 0 END) AS fp,
  sum(CASE WHEN p.proba <  th.___ AND p.real = 1 THEN 1 ELSE 0 END) AS fn,
  sum(CASE WHEN p.proba <  th.___ AND p.real = 0 THEN 1 ELSE 0 END) AS tn
FROM predicoes_teste p
CROSS JOIN thresholds th
GROUP BY th.t;

SELECT * FROM matriz_por_threshold ORDER BY t;

-- COMMAND ----------

-- MAGIC %md
-- MAGIC ## DESAFIO 4 — a curva de custo
-- MAGIC custo = FN x 10.000 + FP x 1.000. Qual `t` minimiza?

-- COMMAND ----------

SELECT
  t,
  fn, fp,
  ___ * 10000 + ___ * 1000 AS custo_total       -- TODO
FROM matriz_por_threshold
ORDER BY custo_total;

-- COMMAND ----------

-- MAGIC %md
-- MAGIC **Checkpoint 4:** o mínimo é em **t = 0.2** (~R$ **140 mil**), menos da
-- MAGIC metade do custo do t = 0.5 (~R$ 281 mil). Com calote 10x mais caro que
-- MAGIC revisão, vale a pena revisar muito mais gente. Bateu com sua aposta do
-- MAGIC Desafio 3?

-- COMMAND ----------

-- MAGIC %md
-- MAGIC ## DESAFIO 5 — a frase para o comitê
-- MAGIC Sem código: escreva num comentário abaixo a recomendação em UMA frase de
-- MAGIC negócio (qual t, o que acontece na operação, quanto economiza vs 0.5).

-- COMMAND ----------

-- Minha recomendação:
-- TODO

-- COMMAND ----------

-- MAGIC %md
-- MAGIC ## Como saber se acertou
-- MAGIC - [ ] Matriz @0.5 fecha em 185 (TP+FP+FN+TN)
-- MAGIC - [ ] Precisão ~0.56 e recall ~0.34 no 0.5
-- MAGIC - [ ] `matriz_por_threshold` com 6 linhas
-- MAGIC - [ ] Custo mínimo em t = 0.2 (~R$ 140 mil)
-- MAGIC - [ ] Recomendação escrita com número e justificativa
-- MAGIC
-- MAGIC *Nota: os valores podem variar ±1-2 unidades conforme a versão do
-- MAGIC scikit-learn do ambiente — o formato e a conclusão não mudam.*
-- MAGIC
-- MAGIC Travou? Levanta a mão. A resposta de referência fica com o instrutor.
