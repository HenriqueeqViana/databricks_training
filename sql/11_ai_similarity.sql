-- Databricks notebook source
-- MAGIC %md
-- MAGIC # 11 · Desafio: casar clientes (entity resolution) com `ai_similarity`
-- MAGIC
-- MAGIC **Cenário:** temos os clientes do sistema (Postgres, tabela `customers` — dados
-- MAGIC **sujos**) e uma lista **nova** de clientes (JSON). Alguns são a **mesma pessoa**
-- MAGIC (com variações: `Carla` vs `Karla`, `bruno_lima@` vs `bruno.lima@`, telefone em
-- MAGIC outro formato), outros **só parecem** (mesmo nome, e-mail diferente = pessoa
-- MAGIC diferente).
-- MAGIC
-- MAGIC **Objetivo:** usar a função de IA `ai_similarity(a, b)` (retorna ~0 a 1: quanto
-- MAGIC maior, mais parecido) em **nome, email, phone e address** para decidir se dois
-- MAGIC registros são o **mesmo cliente**.
-- MAGIC
-- MAGIC Fonte 1: `externo.public.customers` (Federation). Fonte 2: JSON `clientes_novos`.

-- COMMAND ----------

USE CATALOG workspace;
CREATE SCHEMA IF NOT EXISTS treino_match;
USE SCHEMA treino_match;

-- COMMAND ----------

-- MAGIC %md
-- MAGIC ## Fontes (pronto)
-- MAGIC Bronze do Postgres + o JSON novo. O JSON está semeado inline aqui para o
-- MAGIC exercício rodar sozinho; em produção você leria o arquivo, ex.:
-- MAGIC `SELECT * FROM read_files('/Volumes/.../clientes_novos.json', format => 'json')`.

-- COMMAND ----------

CREATE OR REPLACE TABLE bronze_customers AS SELECT * FROM externo.public.customers;

CREATE OR REPLACE TEMPORARY VIEW raw_novos AS
SELECT * FROM VALUES
  ('Ana Souza',      'ana.souza@gmail.com',    '34999112233',    'Rua das Flores, 100, Araxá - MG'),
  ('Bruno L.',       'bruno.lima@hotmail.com', '(34) 98822-3344','Avenida Brasil 200 - Uberlândia'),
  ('Karla Mendes',   'carla.mendes@yahoo.com', '62997771122',    'Rua 5, 33, Goiânia'),
  ('Ana Souza',      'ana.souza2@gmail.com',   '34988880000',    'Rua Nova, 5 - Belo Horizonte'),
  ('Diego Ferreira', 'diego@empresa.com',      '3499999-6655',   'Praça Central, 12 - Patos de Minas'),
  ('Fabio Rocha',    'fabio.rocha@gmail.com',  '34988887777',    'Rua B, 45, Uberaba - MG'),
  ('Helena Dias',    'helena.dias@outlook.com','11955554444',    'Rua Y, 9 - Campinas'),
  ('Gabriela N.',    'gabi.nunes@gmail.com',   '32995554433',    'Av. Goiás, 500 - Cataguases')
  AS t(nome, email, phone, address);

-- COMMAND ----------

-- MAGIC %md
-- MAGIC ## Desafio 1 — limpe as duas fontes (staging)
-- MAGIC Padronize para a comparação ficar justa. Complete os `___`.
-- MAGIC - `full_name` = nome + sobrenome, sem espaços sobrando, Iniciais Maiúsculas
-- MAGIC - `email` = minúsculo e **sem espaços** (o bronze tem `gmail. com`)
-- MAGIC - `phone` = **só dígitos**
-- MAGIC
-- MAGIC Dicas: `initcap(trim(...))`, `lower(replace(trim(email),' ',''))`,
-- MAGIC `regexp_replace(phone,'[^0-9]','')`.

-- COMMAND ----------

CREATE OR REPLACE TEMPORARY VIEW stg_customers AS
SELECT
  customer_id,
  initcap(trim(first_name)) || ' ' || initcap(trim(last_name)) AS full_name,
  ___                       AS email,
  ___                       AS phone,
  trim(address)             AS address
FROM bronze_customers;

CREATE OR REPLACE TEMPORARY VIEW stg_novos AS
SELECT
  initcap(trim(nome))       AS full_name,
  lower(replace(trim(email),' ','')) AS email,
  regexp_replace(phone,'[^0-9]','')  AS phone,
  trim(address)             AS address
FROM raw_novos;

SELECT * FROM stg_customers ORDER BY customer_id;

-- COMMAND ----------

-- MAGIC %md
-- MAGIC ## Desafio 2 — similaridade campo a campo (o coração do exercício)
-- MAGIC Para **cada par** (cliente do sistema × cliente novo), calcule a similaridade de
-- MAGIC `nome`, `email`, `phone` e `address` com `ai_similarity`. Complete os `___`.
-- MAGIC
-- MAGIC `ai_similarity(a, b)` compara dois textos e retorna um score (maior = mais parecido).

-- COMMAND ----------

CREATE OR REPLACE TEMPORARY VIEW pares_similaridade AS
SELECT
  c.customer_id,
  c.full_name AS nome_sistema,
  n.full_name AS nome_novo,
  n.email     AS email_novo,
  ai_similarity(c.full_name, ___) AS sim_nome,
  ai_similarity(c.email,     ___) AS sim_email,
  ai_similarity(c.phone,     ___) AS sim_phone,
  ai_similarity(c.address,   ___) AS sim_address
FROM stg_customers c
CROSS JOIN stg_novos n;

SELECT * FROM pares_similaridade
WHERE nome_sistema = 'Ana Souza'
ORDER BY sim_email DESC;
-- Observe: os dois "Ana Souza" têm sim_nome alto, mas o e-mail separa quem é quem.

-- COMMAND ----------

-- MAGIC %md
-- MAGIC ## Desafio 3 — decida "mesmo cliente" e pegue o melhor match
-- MAGIC 1. Combine os 4 scores num `score_total` (o e-mail costuma pesar mais).
-- MAGIC 2. Para cada cliente novo, fique só com o **melhor** candidato (maior score).
-- MAGIC 3. Marque `mesmo_cliente = score_total >= 0.7` (ajuste o limiar se quiser).
-- MAGIC
-- MAGIC Dica: `ROW_NUMBER() OVER (PARTITION BY nome_novo, email_novo ORDER BY score_total DESC)`.

-- COMMAND ----------

CREATE OR REPLACE TEMPORARY VIEW matches AS
WITH pontuado AS (
  SELECT *,
    (0.40*sim_email + 0.30*sim_nome + 0.15*sim_phone + 0.15*sim_address) AS score_total
  FROM pares_similaridade
),
ranqueado AS (
  SELECT *,
    ROW_NUMBER() OVER (PARTITION BY nome_novo, email_novo ORDER BY score_total DESC) AS rn
  FROM pontuado
)
SELECT
  nome_novo, email_novo,
  customer_id AS melhor_match_id, nome_sistema,
  ROUND(score_total, 3) AS score_total,
  (score_total >= ___)  AS mesmo_cliente
FROM ranqueado
WHERE rn = 1
ORDER BY score_total DESC;

SELECT * FROM matches;

-- COMMAND ----------

-- MAGIC %md
-- MAGIC ## Como saber se acertou (esperado)
-- MAGIC - [ ] Ana Souza (`ana.souza@gmail.com`) casa com o customer 1 → **mesmo_cliente**
-- MAGIC - [ ] Bruno L. (`bruno.lima@`) casa com o customer 2 (Bruno Lima) → **mesmo**
-- MAGIC - [ ] Karla Mendes casa com Carla Mendes (customer 3) → **mesmo** (nome/e-mail parecidos)
-- MAGIC - [ ] Ana Souza (`ana.souza2@gmail.com`) **NÃO** é o customer 1 — mesmo nome, e-mail
-- MAGIC       e endereço diferentes → `mesmo_cliente = false`
-- MAGIC - [ ] Helena Dias não casa com ninguém → **false**
-- MAGIC - [ ] Diego, Fábio e Gabriela casam pelos e-mails idênticos → **mesmo**
-- MAGIC
-- MAGIC A resposta de referência fica com o instrutor.
