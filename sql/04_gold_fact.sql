-- Databricks notebook source
-- MAGIC %md
-- MAGIC # 04 · Gold — tabela fato  🧩
-- MAGIC
-- MAGIC A tabela **fato** é o coração do modelo estrela: uma linha por evento de
-- MAGIC negócio (aqui, um lançamento). Ela guarda as **métricas** (os números que
-- MAGIC somamos) e as **chaves estrangeiras** apontando para cada dimensão — *não* o
-- MAGIC texto descritivo, que mora nas dimensões.

-- COMMAND ----------

USE CATALOG workspace;
USE SCHEMA treino_financeiro;

-- COMMAND ----------

-- MAGIC %md
-- MAGIC ## ✅ Exemplo resolvido — a métrica com sinal
-- MAGIC
-- MAGIC O `valor` na silver é sempre positivo. Para um resultado (P&L) queremos
-- MAGIC **receita somando** e **despesa subtraindo**, então derivamos um
-- MAGIC `valor_sinalizado`:
-- MAGIC
-- MAGIC ```sql
-- MAGIC CASE WHEN tipo = 'Receita' THEN valor ELSE -valor END
-- MAGIC ```
-- MAGIC Some essa coluna e você tem o **resultado líquido** direto.

-- COMMAND ----------

-- MAGIC %md
-- MAGIC ## 🧩 DESAFIO — monte `fato_lancamentos`
-- MAGIC
-- MAGIC Junte `silver_lancamentos` a cada dimensão para trocar o texto descritivo
-- MAGIC pelas chaves substitutas. O esqueleto está abaixo — preencha os dois `TODO`
-- MAGIC (o join e a chave de categoria). O join de centro de custo já está pronto
-- MAGIC como modelo.

-- COMMAND ----------

CREATE OR REPLACE TABLE fato_lancamentos AS
SELECT
  s.id_lancamento,

  -- chave de data: a mesma fórmula yyyyMMdd usada para montar a dim_data
  CAST(date_format(s.data_lancamento, 'yyyyMMdd') AS INT) AS sk_data,            -- ✅ pronto

  cc.sk_centro_custo,                                                            -- ✅ pronto (do join abaixo)

  -- 🧩 TODO: traga a chave substituta de categoria
  NULL AS sk_categoria,                                                          -- TODO -> cat.sk_categoria

  -- métricas
  s.tipo,
  s.valor,
  CASE WHEN s.tipo = 'Receita' THEN s.valor ELSE -s.valor END AS valor_sinalizado, -- ✅ exemplo resolvido
  s.descricao
FROM silver_lancamentos s
JOIN dim_centro_custo cc ON s.centro_custo = cc.nome_centro_custo                -- ✅ join modelo
-- 🧩 TODO: JOIN dim_categoria cat ON s.categoria = cat.nome_categoria
;

-- COMMAND ----------

-- DBTITLE 1,Valide a tabela fato
-- Toda linha do fato precisa casar com uma linha de dimensão (sem chave NULL/órfã).
SELECT
  count(*)                                                AS linhas_fato,
  sum(CASE WHEN sk_centro_custo IS NULL THEN 1 ELSE 0 END) AS sk_centro_custo_faltando,
  sum(CASE WHEN sk_categoria   IS NULL THEN 1 ELSE 0 END)  AS sk_categoria_faltando,
  sum(CASE WHEN sk_data        IS NULL THEN 1 ELSE 0 END)  AS sk_data_faltando
FROM fato_lancamentos;

-- COMMAND ----------

-- DBTITLE 1,Teste rápido — resultado por tipo
SELECT tipo, count(*) AS lancamentos, sum(valor) AS bruto, sum(valor_sinalizado) AS liquido
FROM fato_lancamentos
GROUP BY tipo;
