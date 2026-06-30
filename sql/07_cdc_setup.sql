-- Databricks notebook source
-- MAGIC %md
-- MAGIC # 07 · CDC — preparar o change-feed (setup)
-- MAGIC
-- MAGIC Rode este notebook **uma vez** antes do pipeline `08`. Ele cria uma tabela
-- MAGIC Delta com um **feed de mudanças** (CDC): cada linha é um evento de
-- MAGIC `I`(insert), `U`(update) ou `D`(delete), com uma `sequencia` que diz a ordem.
-- MAGIC
-- MAGIC > Em produção esse feed **não é digitado à mão**: o **Lakeflow Connect** lê o
-- MAGIC > log de transações (WAL) do Postgres e gera esses eventos automaticamente.
-- MAGIC > Aqui semeamos com `VALUES` só para o exercício rodar sozinho.

-- COMMAND ----------

CREATE SCHEMA IF NOT EXISTS treino_cdc;

-- COMMAND ----------

-- Feed de mudanças (o que um conector CDC entregaria)
CREATE OR REPLACE TABLE treino_cdc.clientes_cdc (
  cliente_id INT,
  nome       STRING,
  cidade     STRING,
  operacao   STRING,   -- 'I' insert | 'U' update | 'D' delete
  sequencia  INT       -- ordem dos eventos
);

INSERT INTO treino_cdc.clientes_cdc VALUES
  (101, 'Ana Souza',      'Araxá',          'I', 1),
  (102, 'Bruno Lima',     'Uberlândia',     'I', 2),
  (103, 'Carla Mendes',   'Goiânia',        'I', 3),
  (102, 'Bruno Lima',     'Belo Horizonte', 'U', 4),   -- Bruno mudou de cidade
  (103,  NULL,             NULL,            'D', 5),    -- Carla foi removida
  (104, 'Diego Ferreira', 'Curitiba',       'I', 6);   -- novo cliente

-- COMMAND ----------

SELECT * FROM treino_cdc.clientes_cdc ORDER BY sequencia;
