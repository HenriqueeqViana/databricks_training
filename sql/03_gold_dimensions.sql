-- Databricks notebook source
-- MAGIC %md
-- MAGIC # 03 · Gold — tabelas de dimensão
-- MAGIC
-- MAGIC Gold = um **star schema** (modelo estrela): pequenas tabelas de *dimensão*
-- MAGIC em volta de uma tabela de *fato* central. Cada dimensão guarda os valores
-- MAGIC únicos de um atributo + uma chave substituta (`sk_*`, *surrogate key*) que o
-- MAGIC fato vai referenciar.
-- MAGIC
-- MAGIC Montamos três dimensões: **centro de custo** (exemplo resolvido), **categoria**
-- MAGIC e **data** (seus desafios). A tabela fato vem no notebook `04`.

-- COMMAND ----------

USE CATALOG workspace;
USE SCHEMA treino_financeiro;

-- COMMAND ----------

-- MAGIC %md
-- MAGIC ## Exemplo resolvido — `dim_centro_custo`
-- MAGIC
-- MAGIC Pegue os centros de custo distintos da silver e dê a cada um uma chave
-- MAGIC substituta. `row_number()` é um jeito simples e determinístico de gerá-la.

-- COMMAND ----------

SELECT DISTINCT centro_custo FROM silver_lancamentos

-- COMMAND ----------

SELECT
  row_number() OVER (ORDER BY centro_custo) AS sk_centro_custo,
  centro_custo                              AS nome_centro_custo
FROM (SELECT DISTINCT centro_custo FROM silver_lancamentos);

-- COMMAND ----------

CREATE OR REPLACE TABLE dim_centro_custo AS
SELECT
  row_number() OVER (ORDER BY centro_custo) AS sk_centro_custo,
  centro_custo                              AS nome_centro_custo
FROM (SELECT DISTINCT centro_custo FROM silver_lancamentos);

-- COMMAND ----------

SELECT * FROM dim_centro_custo ORDER BY sk_centro_custo;

-- COMMAND ----------

-- MAGIC %md
-- MAGIC ## DESAFIO 1 — `dim_categoria`
-- MAGIC Monte a dimensão de categoria igual à `dim_centro_custo` acima, mas para a
-- MAGIC coluna `categoria`. Colunas: `sk_categoria`, `nome_categoria`.
-- MAGIC
-- MAGIC **Bônus:** adicione uma coluna `grupo_categoria` ('Receita', 'Pessoas',
-- MAGIC 'Operacional'…) usando uma expressão `CASE`.

-- COMMAND ----------

-- TODO: CREATE OR REPLACE TABLE dim_categoria AS ...


-- COMMAND ----------

-- MAGIC %md
-- MAGIC ## DESAFIO 2 — `dim_data`
-- MAGIC Uma dimensão de data tem **uma linha por dia do calendário** com as partes
-- MAGIC já separadas, para o dashboard agrupar por ano / mês / trimestre sem fazer
-- MAGIC conta de data.
-- MAGIC
-- MAGIC Monte a partir dos valores distintos de `data_lancamento`. Colunas sugeridas:
-- MAGIC
-- MAGIC | coluna | dica |
-- MAGIC |--------|------|
-- MAGIC | `sk_data`       | `CAST(date_format(data_completa,'yyyyMMdd') AS INT)` (ex.: 20250222) |
-- MAGIC | `data_completa` | a própria data |
-- MAGIC | `ano`           | `year(data_completa)` |
-- MAGIC | `mes`           | `month(data_completa)` |
-- MAGIC | `nome_mes`      | `date_format(data_completa,'MMMM')` |
-- MAGIC | `trimestre`     | `quarter(data_completa)` |
-- MAGIC | `dia`           | `day(data_completa)` |
-- MAGIC | `dia_semana`    | `date_format(data_completa,'EEEE')` |
-- MAGIC
-- MAGIC Usar `yyyyMMdd` como chave é um truque clássico de dimensão de data: é único,
-- MAGIC ordenável e legível por humanos.

-- COMMAND ----------

-- TODO: CREATE OR REPLACE TABLE dim_data AS ...


-- COMMAND ----------

-- DBTITLE 1,Valide suas dimensões
SELECT 'dim_centro_custo' AS dimensao, count(*) AS linhas FROM dim_centro_custo
UNION ALL SELECT 'dim_categoria', count(*) FROM dim_categoria
UNION ALL SELECT 'dim_data',      count(*) FROM dim_data;
