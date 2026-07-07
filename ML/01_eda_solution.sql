-- Databricks notebook source
-- MAGIC %md
-- MAGIC # 01 · EDA em SQL — SOLUÇÃO
-- MAGIC Referência completa dos desafios de EDA. **Não versionar no Git da turma.**

-- COMMAND ----------

USE CATALOG workspace;
USE SCHEMA treino_ml;

-- COMMAND ----------

-- DESAFIO 1 — nulos por coluna
-- Esperado: nulos_renda = 40 | nulos_score = 15
SELECT
  sum(CASE WHEN renda_mensal IS NULL THEN 1 ELSE 0 END) AS nulos_renda,
  sum(CASE WHEN score_bureau IS NULL THEN 1 ELSE 0 END) AS nulos_score
FROM bronze_clientes;

-- COMMAND ----------

-- DESAFIO 2 — duplicatas
-- Esperado: total = 1025 | distintas = 1000 | duplicatas = 25
SELECT
  count(*)                                                    AS total,
  (SELECT count(*) FROM (SELECT DISTINCT * FROM bronze_clientes)) AS distintas,
  count(*) -
  (SELECT count(*) FROM (SELECT DISTINCT * FROM bronze_clientes)) AS duplicatas
FROM bronze_clientes;

-- COMMAND ----------

-- DESAFIO 3 — outliers pelo IQR
-- Esperado: qtd_outliers = 51
WITH quartis AS (
  SELECT
    percentile_cont(0.25) WITHIN GROUP (ORDER BY renda_mensal) AS q1,
    percentile_cont(0.75) WITHIN GROUP (ORDER BY renda_mensal) AS q3
  FROM bronze_clientes
)
SELECT
  count(*)                    AS qtd_outliers,
  round(q3 + 1.5*(q3-q1), 2)  AS limite_superior
FROM bronze_clientes b
JOIN quartis q
  ON b.renda_mensal > q.q3 + 1.5 * (q.q3 - q.q1)
  OR b.renda_mensal < q.q1 - 1.5 * (q.q3 - q.q1)
GROUP BY q.q1, q.q3;

-- Ponto de discussão em aula: os ~10 maiores são ERRO (renda x50 no setup);
-- o resto é cauda legítima da lognormal. Outlier != erro sempre.
-- Em produção: investigar a origem antes de remover.

-- COMMAND ----------

-- DESAFIO 4 — padroniza canal
-- Esperado: 3 canais — App / Web / Agencia
SELECT
  initcap(trim(canal)) AS canal_padronizado,
  count(*)             AS qtd
FROM bronze_clientes
GROUP BY canal_padronizado
ORDER BY qtd DESC;

-- COMMAND ----------

-- DESAFIO 5 — taxa de inadimplência por faixa de score
-- Esperado (aprox.): 300-500 = 0.42 | 501-650 = 0.18 | 651-800 = 0.07 | 801-900 = 0.09
-- Nas duas faixas altas empata no ruído — bom gancho: amostra pequena por faixa.
SELECT
  CASE
    WHEN score_bureau <= 500 THEN '300-500'
    WHEN score_bureau <= 650 THEN '501-650'
    WHEN score_bureau <= 800 THEN '651-800'
    ELSE '801-900'
  END                              AS faixa_score,
  count(*)                         AS clientes,
  round(avg(inadimplente), 3)      AS taxa_inadimplencia
FROM bronze_clientes
WHERE score_bureau IS NOT NULL
GROUP BY faixa_score
ORDER BY faixa_score;

-- COMMAND ----------

-- DESAFIO 6 — correlações com o alvo
-- Esperado: corr_score é a mais NEGATIVA | corr_atrasos a mais POSITIVA
SELECT
  round(corr(score_bureau,     inadimplente), 3) AS corr_score,
  round(corr(atrasos_previos,  inadimplente), 3) AS corr_atrasos,
  round(corr(renda_mensal,     inadimplente), 3) AS corr_renda,
  round(corr(valor_emprestimo, inadimplente), 3) AS corr_valor,
  round(corr(idade,            inadimplente), 3) AS corr_idade
FROM bronze_clientes;

-- COMMAND ----------

-- DESAFIO FINAL — silver_clientes
-- Esperado: 911 linhas | taxa ~0.221 | 0 scores nulos | 3 canais
-- Mediana usada na imputação: 596.0
CREATE OR REPLACE TABLE silver_clientes AS
WITH sem_duplicatas AS (
  SELECT DISTINCT * FROM bronze_clientes            -- passo 1
),
com_renda AS (
  SELECT * FROM sem_duplicatas
  WHERE renda_mensal IS NOT NULL                    -- passo 2
),
estatisticas AS (
  SELECT
    percentile_cont(0.5)  WITHIN GROUP (ORDER BY score_bureau) AS mediana_score,
    percentile_cont(0.25) WITHIN GROUP (ORDER BY renda_mensal) AS q1,
    percentile_cont(0.75) WITHIN GROUP (ORDER BY renda_mensal) AS q3
  FROM com_renda                                    -- passo 3
)
SELECT
  c.cliente_id,
  c.idade,
  c.renda_mensal,
  c.valor_emprestimo,
  c.prazo_meses,
  coalesce(c.score_bureau, e.mediana_score) AS score_bureau,  -- passo 5
  c.atrasos_previos,
  c.tempo_relacionamento_meses,
  initcap(trim(c.canal))                    AS canal,          -- passo 6
  c.inadimplente
FROM com_renda c
CROSS JOIN estatisticas e
WHERE c.renda_mensal <= e.q3 + 1.5 * (e.q3 - e.q1);            -- passo 4

-- COMMAND ----------

SELECT
  count(*)                                            AS linhas,
  round(avg(inadimplente), 3)                         AS taxa_inadimplencia,
  sum(CASE WHEN score_bureau IS NULL THEN 1 END)      AS scores_nulos,
  count(DISTINCT canal)                               AS canais_distintos
FROM silver_clientes;

-- COMMAND ----------

-- MAGIC %md
-- MAGIC ## Notas para condução da aula
-- MAGIC - **Desafio 3:** provoque a turma — "todo outlier deve ser removido?" Não:
-- MAGIC   aqui removemos porque sabemos que é erro de unidade; em produção,
-- MAGIC   investigaríamos a origem antes.
-- MAGIC - **Ordem do desafio final importa:** se remover outliers *antes* de tirar
-- MAGIC   os nulos (ou calcular a mediana depois do filtro), os quantis mudam e o
-- MAGIC   resultado não bate com o checkpoint de 911 linhas.
-- MAGIC - **Gancho para a Aula 2:** aqui o SQL resolve tudo; e quando a pergunta
-- MAGIC   for "treine um modelo"? → é onde entra o Python, na medida certa.
-- MAGIC - **Gancho para a Aula 5:** score e atrasos são os candidatos a melhores
-- MAGIC   features — o modelo vai confirmar isso via importância de variáveis.
