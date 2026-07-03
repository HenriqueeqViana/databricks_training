-- Databricks notebook source
-- MAGIC %md
-- MAGIC # 01 · Bronze — ingestão crua
-- MAGIC
-- MAGIC Bronze = o dado **exatamente como ele chegou**. Lemos toda coluna como texto
-- MAGIC (sem limpeza, sem cast) e só adicionamos metadados de carga para sempre saber
-- MAGIC *de onde* e *quando* uma linha veio. Nunca perca a verdade crua.

-- COMMAND ----------

USE CATALOG workspace;
USE SCHEMA treino_financeiro;

-- COMMAND ----------

-- DBTITLE 1,Cria a tabela bronze a partir do CSV
-- Forçamos toda coluna para STRING de propósito: bronze mantém o dado cru e nunca
-- quebra com um valor mal formatado. Duas colunas auxiliares registram a origem.
CREATE OR REPLACE TABLE bronze_lancamentos AS
SELECT
  CAST(id_lancamento   AS STRING) AS id_lancamento,
  CAST(data_lancamento AS STRING) AS data_lancamento,
  CAST(centro_custo    AS STRING) AS centro_custo,
  CAST(categoria       AS STRING) AS categoria,
  CAST(valor           AS STRING) AS valor,
  CAST(tipo            AS STRING) AS tipo,
  CAST(descricao       AS STRING) AS descricao,
  _metadata.file_path             AS _arquivo_origem,
  current_timestamp()             AS _carregado_em
FROM read_files(
  '/Volumes/workspace/treino_financeiro/entrada/lancamentos_financeiros.csv',
  format            => 'csv',
  header            => true,
  inferSchema       => false,   -- tudo continua como texto no bronze
  rescuedDataColumn => '_rescued'
);

-- COMMAND ----------

-- DBTITLE 1,Conferência rápida
SELECT count(*) AS qtd_linhas FROM bronze_lancamentos;

-- COMMAND ----------

SELECT * FROM bronze_lancamentos LIMIT 20;

-- COMMAND ----------

describe  bronze_lancamentos

-- COMMAND ----------

SELECT COUNT(*), id_lancamento  FROM bronze_lancamentos group by id_lancamento having count(*)> 1

-- COMMAND ----------

SELECT *  FROM bronze_lancamentos where id_lancamento = 'L107'
