-- Databricks notebook source
-- MAGIC %md
-- MAGIC # 03 · Features — SOLUÇÃO
-- MAGIC **Não versionar no Git da turma.**

-- COMMAND ----------

USE CATALOG workspace;
USE SCHEMA treino_ml;

-- COMMAND ----------

-- DESAFIO 1 — features_treino (726 linhas)
CREATE OR REPLACE TABLE features_treino AS
SELECT
  cliente_id,
  score_bureau,
  atrasos_previos,
  round(valor_emprestimo / (renda_mensal * prazo_meses / 12), 4)
                                                  AS comprometimento,
  round(ln(renda_mensal), 4)                      AS renda_log,
  round(tempo_relacionamento_meses / 12, 2)       AS relacionamento_anos,
  CASE WHEN canal = 'App' THEN 1 ELSE 0 END       AS canal_app,
  CASE WHEN canal = 'Web' THEN 1 ELSE 0 END       AS canal_web,
  CASE WHEN atrasos_previos > 0 THEN 1 ELSE 0 END AS tem_atraso,
  inadimplente
FROM gold_treino;

-- COMMAND ----------

-- DESAFIO 2 — features_teste (185 linhas) — MESMA expressão, outra origem
CREATE OR REPLACE TABLE features_teste AS
SELECT
  cliente_id,
  score_bureau,
  atrasos_previos,
  round(valor_emprestimo / (renda_mensal * prazo_meses / 12), 4)
                                                  AS comprometimento,
  round(ln(renda_mensal), 4)                      AS renda_log,
  round(tempo_relacionamento_meses / 12, 2)       AS relacionamento_anos,
  CASE WHEN canal = 'App' THEN 1 ELSE 0 END       AS canal_app,
  CASE WHEN canal = 'Web' THEN 1 ELSE 0 END       AS canal_web,
  CASE WHEN atrasos_previos > 0 THEN 1 ELSE 0 END AS tem_atraso,
  inadimplente
FROM gold_teste;

-- COMMAND ----------

-- DESAFIO 3 — chave primária
ALTER TABLE features_treino ALTER COLUMN cliente_id SET NOT NULL;

-- COMMAND ----------

ALTER TABLE features_treino ADD CONSTRAINT pk_features_treino
  PRIMARY KEY (cliente_id);

-- COMMAND ----------

-- DESAFIO 4 — estatísticas
-- Esperado: 726 | comprometimento 3.005 | tem_atraso 0.539 | renda_log 8.239
SELECT
  count(*)                        AS linhas,
  round(avg(comprometimento), 3)  AS media_comprometimento,
  round(avg(tem_atraso), 3)       AS pct_tem_atraso,
  round(avg(renda_log), 3)        AS media_renda_log,
  sum(canal_app) + sum(canal_web) AS app_mais_web
FROM features_treino;

-- COMMAND ----------

-- MAGIC %md
-- MAGIC ## Notas para condução
-- MAGIC - **Por que Agencia não vira coluna?** Com App=0 e Web=0 o modelo já sabe
-- MAGIC   que é Agencia — a 3ª coluna seria redundante (dummy trap).
-- MAGIC - **Duplicação treino/teste:** proposital nesta aula, para doer. Na Aula 8
-- MAGIC   a mesma expressão vira a das features da carteira — gancho para "e se
-- MAGIC   isso fosse uma VIEW parametrizada?" (resposta de produção: view ou
-- MAGIC   função SQL no UC).
-- MAGIC - **PK no Delta é informacional** (não bloqueia duplicata na escrita) —
-- MAGIC   mas é ela que habilita o papel de feature table e a linhagem de lookup.
