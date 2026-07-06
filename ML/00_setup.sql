-- Databricks notebook source
-- MAGIC %md
-- MAGIC # 00 · Setup — schema & dataset do curso de ML
-- MAGIC
-- MAGIC Cria o schema `treino_ml` e gera o dataset que usaremos em **todo o curso**:
-- MAGIC clientes de crédito sintéticos, com o alvo `inadimplente` (1 = deu calote).
-- MAGIC
-- MAGIC O dado vem **propositalmente sujo** — nulos, outliers, duplicatas e texto
-- MAGIC bagunçado — porque a Aula 1 é exatamente sobre encontrar essas coisas.
-- MAGIC
-- MAGIC > Rode este notebook **uma vez**, anexado ao compute **Serverless**
-- MAGIC > (Free Edition). A única célula Python é a de geração dos dados —
-- MAGIC > está pronta, não precisa alterar nada nela.

-- COMMAND ----------

USE CATALOG workspace;
CREATE SCHEMA IF NOT EXISTS treino_ml;
USE SCHEMA treino_ml;

-- COMMAND ----------

-- MAGIC %md
-- MAGIC ## Gera o dataset sintético (célula Python — pronta, não altere)
-- MAGIC
-- MAGIC A semente (`seed=42`) é fixa: **todo mundo na turma gera exatamente os
-- MAGIC mesmos números**, e os checkpoints dos desafios batem para todos.

-- COMMAND ----------

-- MAGIC %python
-- MAGIC import numpy as np
-- MAGIC import pandas as pd
-- MAGIC
-- MAGIC rng = np.random.default_rng(42)
-- MAGIC n = 1000
-- MAGIC
-- MAGIC idade     = rng.integers(18, 76, n)
-- MAGIC renda     = np.round(rng.lognormal(8.3, 0.5, n), 2)
-- MAGIC score     = rng.integers(300, 901, n)
-- MAGIC atrasos   = rng.poisson(0.8, n)
-- MAGIC tempo_rel = rng.integers(1, 240, n)
-- MAGIC prazo     = rng.choice([12, 24, 36, 48, 60], n)
-- MAGIC valor     = np.round(renda * rng.uniform(2, 12, n), 2)
-- MAGIC canal     = rng.choice(['App', 'app', 'APP', 'Web', 'web',
-- MAGIC                         'Agencia', 'agencia', ' Agencia '], n)
-- MAGIC
-- MAGIC # probabilidade de inadimplência: piora com score baixo, atrasos e
-- MAGIC # parcela pesada em relação à renda (é assim que dado real se comporta)
-- MAGIC logit = -2.4 - 0.007 * (score - 600) + 0.5 * atrasos \
-- MAGIC         + 0.15 * (valor / (renda * prazo / 12 + 1e-9))
-- MAGIC prob = 1 / (1 + np.exp(-logit))
-- MAGIC inadimplente = (rng.uniform(0, 1, n) < prob).astype(int)
-- MAGIC
-- MAGIC df = pd.DataFrame({
-- MAGIC     'cliente_id': [f'C{i:04d}' for i in range(1, n + 1)],
-- MAGIC     'idade': idade,
-- MAGIC     'renda_mensal': renda,
-- MAGIC     'valor_emprestimo': valor,
-- MAGIC     'prazo_meses': prazo,
-- MAGIC     'score_bureau': score.astype(float),
-- MAGIC     'atrasos_previos': atrasos,
-- MAGIC     'tempo_relacionamento_meses': tempo_rel,
-- MAGIC     'canal': canal,
-- MAGIC     'inadimplente': inadimplente,
-- MAGIC })
-- MAGIC
-- MAGIC # ---- sujeira proposital ----
-- MAGIC idx_null_renda = rng.choice(n, 40, replace=False)          # 40 rendas nulas
-- MAGIC df.loc[idx_null_renda, 'renda_mensal'] = np.nan
-- MAGIC
-- MAGIC idx_null_score = rng.choice(n, 15, replace=False)          # 15 scores nulos
-- MAGIC df.loc[idx_null_score, 'score_bureau'] = np.nan
-- MAGIC
-- MAGIC idx_out = rng.choice(np.setdiff1d(np.arange(n), idx_null_renda),
-- MAGIC                      10, replace=False)                     # 10 rendas x50
-- MAGIC df.loc[idx_out, 'renda_mensal'] *= 50
-- MAGIC
-- MAGIC dups = df.sample(25, random_state=7)                        # 25 duplicatas
-- MAGIC df = pd.concat([df, dups], ignore_index=True) \
-- MAGIC        .sample(frac=1, random_state=7).reset_index(drop=True)
-- MAGIC
-- MAGIC (spark.createDataFrame(df)
-- MAGIC     .write.mode('overwrite')
-- MAGIC     .saveAsTable('workspace.treino_ml.bronze_clientes'))
-- MAGIC
-- MAGIC print(f'{len(df)} linhas gravadas em bronze_clientes')

-- COMMAND ----------

-- Conferência: deve retornar 1025 linhas
SELECT count(*) AS qtd_linhas FROM bronze_clientes;

-- COMMAND ----------

SELECT * FROM bronze_clientes LIMIT 20;

-- COMMAND ----------

-- MAGIC %md
-- MAGIC **Pronto quando:** a tabela `workspace.treino_ml.bronze_clientes` existe com
-- MAGIC **1025 linhas**. Siga para o notebook `01_eda`.
