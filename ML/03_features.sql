-- Databricks notebook source
-- MAGIC %md
-- MAGIC # 03 · Feature Engineering em SQL
-- MAGIC
-- MAGIC **Cenário:** transformar as colunas do split (Aula 2) nos **sinais** que o
-- MAGIC modelo vai consumir. Cada feature é uma expressão SQL — e a tabela final,
-- MAGIC com chave primária, vira uma **feature table** governada no Unity Catalog.
-- MAGIC
-- MAGIC As 8 features do curso:
-- MAGIC | feature | expressão | por quê |
-- MAGIC |---|---|---|
-- MAGIC | `score_bureau` | direto | melhor preditor (Aula 1) |
-- MAGIC | `atrasos_previos` | direto | comportamento passado |
-- MAGIC | `comprometimento` | valor / (renda x prazo / 12) | peso da dívida |
-- MAGIC | `renda_log` | ln(renda) | comprime a cauda longa |
-- MAGIC | `relacionamento_anos` | meses / 12 | unidade melhor |
-- MAGIC | `canal_app`, `canal_web` | one-hot | categoria vira número |
-- MAGIC | `tem_atraso` | flag 0/1 | atrasou alguma vez? |
-- MAGIC
-- MAGIC > Pré-requisito: notebook `02_preparacao` (`gold_treino` / `gold_teste`).

-- COMMAND ----------

USE CATALOG workspace;
USE SCHEMA treino_ml;

-- COMMAND ----------

-- MAGIC %md
-- MAGIC ## Exemplo resolvido — a razão de comprometimento
-- MAGIC A pergunta certa não é "quanto ele deve", é "quanto ele deve **em relação
-- MAGIC ao que ganha**". Parcela mensal aproximada = valor / prazo; renda anualizada
-- MAGIC no denominador dá a razão:

-- COMMAND ----------

SELECT
  cliente_id,
  valor_emprestimo,
  renda_mensal,
  prazo_meses,
  round(valor_emprestimo / (renda_mensal * prazo_meses / 12), 4)
    AS comprometimento
FROM gold_treino
ORDER BY comprometimento DESC
LIMIT 10;

-- COMMAND ----------

-- MAGIC %md
-- MAGIC ## DESAFIO 1 — monte a `features_treino`
-- MAGIC Complete os `___` com as expressões da tabela lá de cima.
-- MAGIC Dicas: `ln()`, `CASE WHEN canal = 'App' THEN 1 ELSE 0 END`.

-- COMMAND ----------

CREATE OR REPLACE TABLE features_treino AS
SELECT
  cliente_id,
  score_bureau,
  atrasos_previos,
  round(valor_emprestimo / (renda_mensal * prazo_meses / 12), 4)
                                              AS comprometimento,
  round(___, 4)                               AS renda_log,           -- ln(renda_mensal)
  round(___, 2)                               AS relacionamento_anos, -- meses / 12
  CASE WHEN canal = '___' THEN 1 ELSE 0 END   AS canal_app,
  CASE WHEN canal = '___' THEN 1 ELSE 0 END   AS canal_web,
  CASE WHEN ___ > 0 THEN 1 ELSE 0 END         AS tem_atraso,
  inadimplente
FROM gold_treino;

-- COMMAND ----------

-- MAGIC %md
-- MAGIC ## DESAFIO 2 — agora a `features_teste`
-- MAGIC **A MESMA expressão**, trocando só a tabela de origem. É assim que treino e
-- MAGIC produção não divergem. (Copie, cole, troque o FROM.)

-- COMMAND ----------

CREATE OR REPLACE TABLE features_teste AS
SELECT
  -- TODO: cole aqui o mesmo SELECT do desafio 1
  *
FROM ___;

-- COMMAND ----------

-- MAGIC %md
-- MAGIC ## DESAFIO 3 — promova a feature table (chave primária)
-- MAGIC Uma feature table de verdade tem PK. No Delta/UC são dois passos:
-- MAGIC a coluna vira `NOT NULL`, depois entra a `PRIMARY KEY`.

-- COMMAND ----------

ALTER TABLE features_treino ALTER COLUMN ___ SET NOT NULL;

-- COMMAND ----------

ALTER TABLE features_treino ADD CONSTRAINT pk_features_treino
  PRIMARY KEY (___);

-- COMMAND ----------

-- MAGIC %md
-- MAGIC ## DESAFIO 4 — confira as estatísticas das features

-- COMMAND ----------

SELECT
  count(*)                              AS linhas,
  round(avg(comprometimento), 3)        AS media_comprometimento,
  round(avg(tem_atraso), 3)             AS pct_tem_atraso,
  round(avg(renda_log), 3)              AS media_renda_log,
  sum(canal_app) + sum(canal_web)       AS app_mais_web
FROM features_treino;

-- COMMAND ----------

-- MAGIC %md
-- MAGIC ## Como saber se acertou
-- MAGIC - [ ] `features_treino`: **726** linhas, 10 colunas
-- MAGIC - [ ] `features_teste`: **185** linhas, mesmas colunas
-- MAGIC - [ ] Comprometimento médio ≈ **3.0** (a dívida típica pesa ~3x a renda anualizada)
-- MAGIC - [ ] `pct_tem_atraso` ≈ **0.54**
-- MAGIC - [ ] `media_renda_log` ≈ **8.24**
-- MAGIC - [ ] O `DESCRIBE EXTENDED features_treino` mostra a constraint de PK
-- MAGIC - [ ] No Catalog Explorer, a aba *Lineage* liga a feature table à `gold_treino`
-- MAGIC
-- MAGIC Travou? Levanta a mão. A resposta de referência fica com o instrutor.
