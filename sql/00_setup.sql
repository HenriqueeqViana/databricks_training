-- Databricks notebook source
-- MAGIC %md
-- MAGIC # 00 · Setup — catálogo, schema & volume
-- MAGIC
-- MAGIC Cria o catálogo/schema e um **volume** para subir o CSV.
-- MAGIC Rode este notebook primeiro e depois suba o arquivo (passo 2 abaixo).
-- MAGIC
-- MAGIC > Se o seu workspace não tiver o catálogo `workspace`, troque o `CATALOG`
-- MAGIC > abaixo por um onde você consiga escrever (ex.: `main` ou um catálogo seu).

-- COMMAND ----------

-- DBTITLE 1,Configuração (mude aqui se precisar)
-- Estes três nomes são reusados por todos os notebooks deste track.
USE CATALOG workspace;
CREATE SCHEMA IF NOT EXISTS treino_financeiro;
USE SCHEMA treino_financeiro;

-- Um volume é um armazenamento gerenciado onde você sobe arquivos.
CREATE VOLUME IF NOT EXISTS entrada;

-- COMMAND ----------

-- MAGIC %md
-- MAGIC ## Passo 2 — suba o CSV no volume
-- MAGIC
-- MAGIC Os notebooks esperam o arquivo aqui:
-- MAGIC
-- MAGIC ```
-- MAGIC /Volumes/workspace/treino_financeiro/entrada/lancamentos_financeiros.csv
-- MAGIC ```
-- MAGIC
-- MAGIC **UI:** Catalog → `workspace` → `treino_financeiro` → `entrada` →
-- MAGIC **Upload to this volume** → escolha `data/lancamentos_financeiros.csv`.
-- MAGIC
-- MAGIC **CLI:** `databricks fs cp data/lancamentos_financeiros.csv dbfs:/Volumes/workspace/treino_financeiro/entrada/`

-- COMMAND ----------

-- DBTITLE 1,Verifique o upload
-- Depois de subir, o arquivo deve aparecer listado aqui.
LIST '/Volumes/workspace/treino_financeiro/entrada/';

-- COMMAND ----------

-- DBTITLE 1,Espie o arquivo bruto
-- read_files() lê direto do volume. Repare como está bagunçado!
SELECT *
FROM read_files(
  '/Volumes/workspace/treino_financeiro/entrada/lancamentos_financeiros.csv',
  format => 'csv',
  header => true
)
LIMIT 10;
