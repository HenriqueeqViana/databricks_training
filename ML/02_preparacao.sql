-- Databricks notebook source
-- MAGIC %md
-- MAGIC # 02 · Preparação — amostragem, janelas e split
-- MAGIC
-- MAGIC **Cenário:** a `silver_clientes` está limpa (Aula 1). Antes de treinar,
-- MAGIC precisamos separar **treino** e **teste** de forma reproduzível — e sem
-- MAGIC vazamento. Tudo em SQL.
-- MAGIC
-- MAGIC > Pré-requisito: notebooks `00_setup` e `01_eda` (a `silver_clientes` existe).

-- COMMAND ----------

USE CATALOG workspace;
USE SCHEMA treino_ml;

-- COMMAND ----------

-- MAGIC %md
-- MAGIC ## Exemplo resolvido — amostragem com TABLESAMPLE
-- MAGIC Com 911 linhas nem precisamos, mas com 911 milhões sim: `TABLESAMPLE`
-- MAGIC lê só uma fração. Compare a taxa do alvo na amostra vs na tabela cheia —
-- MAGIC a amostra varia a cada execução (e é por isso que ela NÃO serve de split).

-- COMMAND ----------

SELECT count(*) AS linhas, round(avg(inadimplente), 3) AS taxa
FROM silver_clientes TABLESAMPLE (20 PERCENT);

-- COMMAND ----------

SELECT count(*) AS linhas, round(avg(inadimplente), 3) AS taxa
FROM silver_clientes;

-- COMMAND ----------

-- MAGIC %md
-- MAGIC ## DESAFIO 1 — cada cliente vs o grupo dele (window function)
-- MAGIC Sem perder nenhuma linha, mostre a renda de cada cliente **e** a média de
-- MAGIC renda do canal dele, com a diferença percentual.
-- MAGIC Dica: `avg(renda_mensal) OVER (PARTITION BY canal)`.

-- COMMAND ----------

SELECT
  cliente_id,
  canal,
  renda_mensal,
  round(avg(renda_mensal) OVER (PARTITION BY ___), 2)  AS media_canal,
  round(renda_mensal /
        avg(renda_mensal) OVER (PARTITION BY ___) * 100 - 100, 1)
                                                        AS pct_vs_canal
FROM silver_clientes
ORDER BY pct_vs_canal DESC
LIMIT 10;

-- COMMAND ----------

-- MAGIC %md
-- MAGIC **Checkpoint 1:** as médias por canal ficam todas na casa dos **R$ 4.1–4.3
-- MAGIC mil** — canais parecidos entre si. O top da lista tem renda ~3x a média.

-- COMMAND ----------

-- MAGIC %md
-- MAGIC ## DESAFIO 2 — o número estável por cliente
-- MAGIC `rand()` muda a cada execução; o split precisa ser **determinístico**.
-- MAGIC O truque: extrair o número do `cliente_id` (ex.: `C0042` → 42) e usar o
-- MAGIC resto da divisão por 5.
-- MAGIC Dica: `CAST(substr(cliente_id, 2) AS INT) % 5`.

-- COMMAND ----------

SELECT
  ___ AS resto,
  count(*)                     AS clientes,
  round(avg(inadimplente), 3)  AS taxa
FROM silver_clientes
GROUP BY resto
ORDER BY resto;

-- COMMAND ----------

-- MAGIC %md
-- MAGIC **Checkpoint 2:** 5 grupos de ~180 clientes cada. Rode duas vezes —
-- MAGIC o resultado é **idêntico** (é isso que `rand()` não te dá).

-- COMMAND ----------

-- MAGIC %md
-- MAGIC ## DESAFIO 3 — crie `gold_treino` e `gold_teste`
-- MAGIC Regra da turma: **resto = 2 → teste** (~20%); o restante → treino.
-- MAGIC Complete os `___` (atenção ao operador: `=` num, `<>` no outro).

-- COMMAND ----------

CREATE OR REPLACE TABLE gold_treino AS
SELECT * FROM silver_clientes
WHERE CAST(substr(cliente_id, 2) AS INT) % 5 ___ 2;

-- COMMAND ----------

CREATE OR REPLACE TABLE gold_teste AS
SELECT * FROM silver_clientes
WHERE CAST(substr(cliente_id, 2) AS INT) % 5 ___ 2;

-- COMMAND ----------

-- MAGIC %md
-- MAGIC ## DESAFIO 4 — valide o equilíbrio
-- MAGIC Uma query só, com os dois conjuntos lado a lado: linhas e taxa do alvo.
-- MAGIC Dica: `UNION ALL` de dois SELECTs com uma coluna literal `'treino'`/`'teste'`.

-- COMMAND ----------

SELECT 'treino' AS conjunto, count(*) AS linhas,
       round(avg(inadimplente), 3) AS taxa
FROM ___
UNION ALL
SELECT 'teste', count(*), round(avg(inadimplente), 3)
FROM ___;

-- COMMAND ----------

-- MAGIC %md
-- MAGIC ## DESAFIO 5 — prova de que não há vazamento
-- MAGIC Nenhum `cliente_id` pode estar nos dois conjuntos. Escreva a query que
-- MAGIC conta a interseção — o resultado deve ser **0**.
-- MAGIC Dica: `JOIN` entre as duas tabelas pelo `cliente_id`.

-- COMMAND ----------

SELECT count(*) AS clientes_nos_dois
FROM gold_treino tr
JOIN gold_teste te ON tr.___ = te.___;

-- COMMAND ----------

-- MAGIC %md
-- MAGIC ## Como saber se acertou
-- MAGIC - [ ] Checkpoint 1: médias por canal em ~R$ 4.1–4.3 mil
-- MAGIC - [ ] Checkpoint 2: 5 grupos estáveis entre execuções
-- MAGIC - [ ] `gold_treino` = **726** linhas, taxa **0.220**
-- MAGIC - [ ] `gold_teste` = **185** linhas, taxa **0.222**
-- MAGIC - [ ] Interseção de clientes = **0**
-- MAGIC - [ ] Você sabe explicar por que `rand()` não serve para split
-- MAGIC
-- MAGIC Travou? Levanta a mão. A resposta de referência fica com o instrutor.
