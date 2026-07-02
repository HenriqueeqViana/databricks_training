-- Databricks notebook source
-- MAGIC %md
-- MAGIC # 11 · Desafio: deduplicação de clientes (medallion + `ai_similarity`)
-- MAGIC
-- MAGIC **Cenário:** dois cadastros do mesmo cliente em bases diferentes — o sistema
-- MAGIC (Postgres, sujo) e uma lista nova (JSON). Precisamos descobrir **quem é a mesma
-- MAGIC pessoa**, apesar de variações (`Carla`/`Karla`, `bruno_lima@`/`bruno.lima@`).
-- MAGIC
-- MAGIC **Arquitetura (medallion):**
-- MAGIC 1. `bronze_customer_postgresql` e `bronze_customer_json` — cru
-- MAGIC 2. `silver_customer_xref` — colunas tratadas + as duas bases unidas
-- MAGIC 3. `silver_customer_dedup` — aplica as **regras de match em cascata**
-- MAGIC
-- MAGIC **Regras (por prioridade — a 1ª que bater decide, sem sobra de borda):**
-- MAGIC | Prioridade | Regra | "é o mesmo cliente se…" |
-- MAGIC |---|---|---|
-- MAGIC | 1 | nome + email | nome bate **e** email bate |
-- MAGIC | 2 | nome + telefone | nome bate **e** telefone igual |
-- MAGIC | 3 | nome + endereço | nome bate **e** endereço bate |
-- MAGIC
-- MAGIC "Bate" = `ai_similarity(a, b) >= 0.6` (para `full_name`, `email` e `endereço`).
-- MAGIC O telefone é comparado por igualdade exata (só dígitos).

-- COMMAND ----------

USE CATALOG workspace;
CREATE SCHEMA IF NOT EXISTS treino_match;
USE SCHEMA treino_match;

CREATE WIDGET TEXT json_path DEFAULT '/Volumes/workspace/treino_match/dados/clientes_novos.json';

-- COMMAND ----------

-- MAGIC %md
-- MAGIC ## Bronze — cru das duas fontes (pronto)
-- MAGIC Postgres via Federation; JSON via `read_files` do Volume.

-- COMMAND ----------

CREATE OR REPLACE TABLE bronze_customer_postgresql AS
SELECT * FROM externo.public.customers;

CREATE OR REPLACE TABLE bronze_customer_json AS
SELECT nome, email, phone, address
FROM read_files('${json_path}', format => 'json', multiLine => true);

-- COMMAND ----------

-- MAGIC %md
-- MAGIC ## Desafio 1 — `silver_customer_xref` (tratar colunas + unir as bases)
-- MAGIC Padronize as colunas nas DUAS fontes e junte com `UNION ALL`, marcando a
-- MAGIC coluna `source_name` (de onde o registro veio).
-- MAGIC - `full_name` = nome completo, Iniciais Maiúsculas, sem espaços sobrando
-- MAGIC - `email` = minúsculo e **sem espaços** (o Postgres tem `gmail. com`)
-- MAGIC - `phone` = **só dígitos**
-- MAGIC - `endereco` = minúsculo, sem espaços nas bordas
-- MAGIC
-- MAGIC Complete os `___`. (No Postgres o nome vem em `first_name`+`last_name`; no JSON
-- MAGIC já vem completo em `nome`.)

-- COMMAND ----------

CREATE OR REPLACE TABLE silver_customer_xref AS
SELECT
  'bronze_customer_postgresql'                     AS source_name,
  concat('PG-', customer_id)                       AS registro_id,
  initcap(trim(first_name))||' '||initcap(trim(last_name)) AS full_name,
  lower(replace(trim(email),' ',''))               AS email,
  regexp_replace(phone,'[^0-9]','')                AS phone,
  lower(trim(address))                             AS endereco
FROM bronze_customer_postgresql

UNION ALL

SELECT
  'bronze_customer_json'                           AS source_name,
  concat('JS-', row_number() OVER (ORDER BY nome, email)) AS registro_id,
  initcap(trim(nome))                              AS full_name,
  ___                                              AS email,
  ___                                              AS phone,
  ___                                              AS endereco
FROM bronze_customer_json;

SELECT source_name, count(*) FROM silver_customer_xref GROUP BY source_name;

-- COMMAND ----------

-- MAGIC %md
-- MAGIC ## Desafio 2 — sinais de similaridade entre as bases
-- MAGIC Cruze cada registro do Postgres com cada registro do JSON e calcule os sinais.
-- MAGIC Use `ai_similarity` em `full_name`, `email` e `endereco`; telefone é igualdade.
-- MAGIC Complete os `___` (o 2º argumento de cada `ai_similarity`).

-- COMMAND ----------

CREATE OR REPLACE TEMPORARY VIEW pares_clientes AS
SELECT
  pg.source_name AS source_pg, js.source_name AS source_js,
  pg.registro_id AS id_pg,  js.registro_id AS id_js,
  pg.full_name   AS nome_pg, js.full_name  AS nome_js,
  pg.email       AS email_pg, js.email     AS email_js,
  ai_similarity(pg.full_name, ___) AS sim_nome,
  ai_similarity(pg.email,     ___) AS sim_email,
  ai_similarity(pg.endereco,  ___) AS sim_endereco,
  (pg.phone = js.phone)            AS telefone_igual
FROM silver_customer_xref pg
JOIN silver_customer_xref js
  ON pg.source_name = 'bronze_customer_postgresql' AND js.source_name = 'bronze_customer_json';

-- COMMAND ----------

-- MAGIC %md
-- MAGIC ## Desafio 3 — `silver_customer_dedup` (regras em cascata)
-- MAGIC Aplique as 3 regras **em ordem de prioridade** com um `CASE` (cascata — a
-- MAGIC primeira que bater decide, então não sobra borda). Limiar `ai_similarity`: `0.6`.
-- MAGIC
-- MAGIC Preencha os `___`: os limiares e a ordem das regras.

-- COMMAND ----------

CREATE OR REPLACE TABLE silver_customer_dedup AS
WITH sinais AS (
  SELECT *,
    (sim_nome     >= ___) AS nome_ok,
    (sim_email    >= ___) AS email_ok,
    (sim_endereco >= ___) AS endereco_ok
  FROM pares_clientes
)
SELECT
  source_pg, id_pg, nome_pg, source_js, id_js, nome_js, email_pg, email_js,
  ROUND(sim_nome,3) AS sim_nome, ROUND(sim_email,3) AS sim_email, ROUND(sim_endereco,3) AS sim_endereco,
  telefone_igual,
  CASE
    WHEN nome_ok AND ___            THEN 1   -- prioridade 1: nome + email
    WHEN nome_ok AND ___            THEN 2   -- prioridade 2: nome + telefone
    WHEN nome_ok AND ___            THEN 3   -- prioridade 3: nome + endereço
    ELSE NULL
  END AS regra_match
FROM sinais;

-- só os pares considerados o mesmo cliente, com a regra que decidiu
SELECT id_pg, nome_pg, id_js, nome_js, regra_match
FROM silver_customer_dedup
WHERE regra_match IS NOT NULL
ORDER BY regra_match, id_pg;

-- COMMAND ----------

-- MAGIC %md
-- MAGIC ## Desafio 4 — 1 match por registro novo (sem duplicar)
-- MAGIC Um registro do JSON pode bater com mais de um do Postgres. Fique com o de
-- MAGIC **maior prioridade** (menor `regra_match`). Dica: `ROW_NUMBER() OVER
-- MAGIC (PARTITION BY id_js ORDER BY regra_match)`.

-- COMMAND ----------

CREATE OR REPLACE TEMPORARY VIEW clientes_reconciliados AS
SELECT * FROM (
  SELECT *,
    ROW_NUMBER() OVER (PARTITION BY id_js ORDER BY regra_match) AS rn
  FROM silver_customer_dedup
  WHERE regra_match IS NOT NULL
)
WHERE rn = 1;

SELECT id_js, nome_js, id_pg, nome_pg, regra_match FROM clientes_reconciliados ORDER BY id_js;

-- COMMAND ----------

-- MAGIC %md
-- MAGIC ## Como saber se acertou
-- MAGIC - [ ] `silver_customer_xref`: 16 linhas (8 do Postgres + 8 do JSON)
-- MAGIC - [ ] Ana Souza (`ana.souza@gmail.com`) casa por **regra 1** (nome + email)
-- MAGIC - [ ] O 2º "Ana Souza" (`ana.souza2@`) **não** casa com o customer 1
-- MAGIC       (nome bate, mas email/telefone/endereço não) → `regra_match = NULL`
-- MAGIC - [ ] Karla ↔ Carla Mendes casa (nome e email parecidos ≥ 0.6)
-- MAGIC - [ ] Helena Dias não casa com ninguém
-- MAGIC - [ ] Cada `id_js` aparece **uma vez** em `clientes_reconciliados`
-- MAGIC
-- MAGIC A resposta de referência fica com o instrutor.
