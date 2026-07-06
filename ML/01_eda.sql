-- Databricks notebook source
-- MAGIC %md
-- MAGIC # 01 · EDA em SQL — conheça o dado antes de modelar
-- MAGIC
-- MAGIC **Cenário:** você recebeu a base de clientes de crédito e a missão de
-- MAGIC construir um modelo que preveja `inadimplente`. Antes de qualquer modelo,
-- MAGIC o trabalho é **entender e limpar** o dado — e dá para fazer isso em SQL.
-- MAGIC
-- MAGIC ## Como este notebook funciona
-- MAGIC O primeiro passo vem como **exemplo resolvido**. Cada passo seguinte tem um
-- MAGIC `DESAFIO` com `___` para completar. Confira nos checkpoints.
-- MAGIC A resposta de referência fica com o instrutor.
-- MAGIC
-- MAGIC > Pré-requisito: rodar o `00_setup` antes (cria a `bronze_clientes`).

-- COMMAND ----------

USE CATALOG workspace;
USE SCHEMA treino_ml;

-- COMMAND ----------

-- MAGIC %md
-- MAGIC ## Exemplo resolvido — o primeiro olhar
-- MAGIC
-- MAGIC Três consultas que você roda em **qualquer** dataset novo, sempre:
-- MAGIC uma amostra (como o dado se parece), o `DESCRIBE` (tipos) e as
-- MAGIC estatísticas básicas — procure mínimos/máximos absurdos.

-- COMMAND ----------

SELECT * FROM bronze_clientes LIMIT 10;

-- COMMAND ----------

DESCRIBE bronze_clientes;

-- COMMAND ----------

-- DBTITLE 1,Estatísticas da renda — repare no MÁXIMO. Parece salário de gente normal?
SELECT
  count(renda_mensal)              AS qtd_preenchida,
  round(min(renda_mensal), 2)      AS minimo,
  round(avg(renda_mensal), 2)      AS media,
  round(max(renda_mensal), 2)      AS maximo
FROM bronze_clientes;

-- COMMAND ----------

-- MAGIC %md
-- MAGIC ## DESAFIO 1 — quantos nulos por coluna?
-- MAGIC Conte os nulos das duas colunas suspeitas.
-- MAGIC Dica: `sum(CASE WHEN coluna IS NULL THEN 1 ELSE 0 END)`.

-- COMMAND ----------

SELECT
  sum(CASE WHEN ___ IS NULL THEN 1 ELSE 0 END) AS nulos_renda,
  sum(CASE WHEN ___ IS NULL THEN 1 ELSE 0 END) AS nulos_score
FROM bronze_clientes;

-- COMMAND ----------

-- MAGIC %md
-- MAGIC **Checkpoint 1:** `renda_mensal` deve ter **40** nulos e `score_bureau`
-- MAGIC **15**.

-- COMMAND ----------

-- MAGIC %md
-- MAGIC ## DESAFIO 2 — duplicatas
-- MAGIC O dataset tem linhas repetidas (aconteceu na "extração"). Conte quantas
-- MAGIC linhas **sobram** além da primeira ocorrência.
-- MAGIC Dica: total de linhas − total de linhas **distintas**.
-- MAGIC `(SELECT count(*) FROM (SELECT DISTINCT * FROM ...))` resolve a 2ª parte.

-- COMMAND ----------

SELECT
  count(*)                                             AS total,
  ___                                                  AS distintas,
  count(*) - ___                                       AS duplicatas
FROM bronze_clientes;

-- COMMAND ----------

-- MAGIC %md
-- MAGIC **Checkpoint 2:** exatamente **25** duplicatas.

-- COMMAND ----------

-- MAGIC %md
-- MAGIC ## DESAFIO 3 — outliers de renda (regra do IQR)
-- MAGIC A regra clássica: outlier é o que fica fora de
-- MAGIC `[Q1 - 1.5*IQR, Q3 + 1.5*IQR]`, onde `IQR = Q3 - Q1`.
-- MAGIC
-- MAGIC No SQL, os quartis vêm de `percentile_cont(0.25) WITHIN GROUP (ORDER BY col)`
-- MAGIC (os nulos são ignorados automaticamente). Complete os `___`.

-- COMMAND ----------

WITH quartis AS (
  SELECT
    percentile_cont(___) WITHIN GROUP (ORDER BY renda_mensal) AS q1,
    percentile_cont(___) WITHIN GROUP (ORDER BY renda_mensal) AS q3
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

-- COMMAND ----------

-- DBTITLE 1,Espie os 12 maiores — o que eles têm em comum?
SELECT cliente_id, renda_mensal
FROM bronze_clientes
ORDER BY renda_mensal DESC NULLS LAST
LIMIT 12;

-- COMMAND ----------

-- MAGIC %md
-- MAGIC **Checkpoint 3:** **51** outliers. Os ~10 maiores têm renda na casa das
-- MAGIC **centenas de milhares** — são os valores multiplicados por 50 no setup
-- MAGIC (erro de unidade, clássico de integração). O resto é cauda natural da
-- MAGIC distribuição — nem todo outlier é erro!

-- COMMAND ----------

-- MAGIC %md
-- MAGIC ## DESAFIO 4 — padronize o `canal`
-- MAGIC Rode o `SELECT DISTINCT` abaixo — são 8 grafias para 3 canais reais.
-- MAGIC Escreva a expressão que padroniza: sem espaços nas bordas + Iniciais
-- MAGIC Maiúsculas. Dica: `initcap(trim(canal))` — a mesma dupla da silver do
-- MAGIC curso de engenharia.

-- COMMAND ----------

SELECT DISTINCT canal FROM bronze_clientes ORDER BY canal;

-- COMMAND ----------

SELECT
  ___                AS canal_padronizado,
  count(*)           AS qtd
FROM bronze_clientes
GROUP BY canal_padronizado
ORDER BY qtd DESC;

-- COMMAND ----------

-- MAGIC %md
-- MAGIC **Checkpoint 4:** sobram exatamente **3** canais: `App`, `Web`, `Agencia`.

-- COMMAND ----------

-- MAGIC %md
-- MAGIC ## DESAFIO 5 — o alvo se comporta como esperado?
-- MAGIC Em crédito, score baixo → mais inadimplência. Confirme: calcule a **taxa
-- MAGIC média de `inadimplente` por faixa de score**.
-- MAGIC
-- MAGIC Dica: `avg(inadimplente)` dá a taxa direto (o alvo é 0/1); as faixas vêm
-- MAGIC de um `CASE`. Complete os limites.

-- COMMAND ----------

SELECT
  CASE
    WHEN score_bureau <= ___ THEN '300-500'
    WHEN score_bureau <= ___ THEN '501-650'
    WHEN score_bureau <= ___ THEN '651-800'
    ELSE '801-900'
  END                              AS faixa_score,
  count(*)                         AS clientes,
  round(avg(inadimplente), 3)      AS taxa_inadimplencia
FROM bronze_clientes
WHERE score_bureau IS NOT NULL
GROUP BY faixa_score
ORDER BY faixa_score;

-- COMMAND ----------

-- MAGIC %md
-- MAGIC **Checkpoint 5:** a taxa **cai** conforme o score sobe — de ~**42%** na
-- MAGIC faixa 300-500 para menos de **10%** acima de 650. Se o seu modelo depois
-- MAGIC não usar o score, tem algo errado.

-- COMMAND ----------

-- MAGIC %md
-- MAGIC ## DESAFIO 6 — correlações com o alvo
-- MAGIC O SQL tem `corr(coluna_a, coluna_b)` nativo. Calcule a correlação de cada
-- MAGIC coluna numérica com `inadimplente` e descubra a mais negativa e a mais
-- MAGIC positiva. Complete as que faltam.

-- COMMAND ----------

SELECT
  round(corr(score_bureau,     inadimplente), 3) AS corr_score,
  round(corr(atrasos_previos,  inadimplente), 3) AS corr_atrasos,
  round(corr(___,              inadimplente), 3) AS corr_renda,
  round(corr(___,              inadimplente), 3) AS corr_valor,
  round(corr(___,              inadimplente), 3) AS corr_idade
FROM bronze_clientes;

-- COMMAND ----------

-- MAGIC %md
-- MAGIC **Checkpoint 6:** `score_bureau` tem a correlação mais **negativa** com o
-- MAGIC alvo; `atrasos_previos` a mais **positiva**. Guarde isso — são os
-- MAGIC candidatos a melhores features na aula de treinamento.

-- COMMAND ----------

-- MAGIC %md
-- MAGIC ## DESAFIO FINAL — monte a `silver_clientes`
-- MAGIC Aplique as decisões de limpeza, **nesta ordem** (a ordem muda o resultado!):
-- MAGIC 1. Remova as **duplicatas** (`SELECT DISTINCT`);
-- MAGIC 2. Remova linhas com `renda_mensal` **nula** (sem renda não dá pra avaliar crédito);
-- MAGIC 3. Sobre esse resultado, calcule a **mediana** do score e o **limite IQR** da renda;
-- MAGIC 4. Remova rendas **acima do limite superior**;
-- MAGIC 5. **Impute** os `score_bureau` nulos com a mediana (dica: `coalesce`);
-- MAGIC 6. Padronize o `canal` (Desafio 4).
-- MAGIC
-- MAGIC O esqueleto com CTEs está pronto — complete os `___`.

-- COMMAND ----------

CREATE OR REPLACE TABLE silver_clientes AS
WITH sem_duplicatas AS (
  SELECT DISTINCT * FROM bronze_clientes            -- passo 1
),
com_renda AS (
  SELECT * FROM sem_duplicatas
  WHERE ___ IS NOT NULL                             -- passo 2
),
estatisticas AS (
  SELECT
    percentile_cont(0.5)  WITHIN GROUP (ORDER BY score_bureau) AS mediana_score,
    percentile_cont(___)  WITHIN GROUP (ORDER BY renda_mensal) AS q1,
    percentile_cont(___)  WITHIN GROUP (ORDER BY renda_mensal) AS q3
  FROM com_renda                                    -- passo 3
)
SELECT
  c.cliente_id,
  c.idade,
  c.renda_mensal,
  c.valor_emprestimo,
  c.prazo_meses,
  coalesce(c.score_bureau, e.___)  AS score_bureau, -- passo 5
  c.atrasos_previos,
  c.tempo_relacionamento_meses,
  ___                              AS canal,        -- passo 6
  c.inadimplente
FROM com_renda c
CROSS JOIN estatisticas e
WHERE c.renda_mensal <= e.q3 + 1.5 * (e.q3 - e.q1); -- passo 4

-- COMMAND ----------

-- DBTITLE 1,Valide sua silver
SELECT
  count(*)                                            AS linhas,
  round(avg(inadimplente), 3)                         AS taxa_inadimplencia,
  sum(CASE WHEN score_bureau IS NULL THEN 1 END)      AS scores_nulos,
  count(DISTINCT canal)                               AS canais_distintos
FROM silver_clientes;

-- COMMAND ----------

-- MAGIC %md
-- MAGIC ## Como saber se acertou
-- MAGIC - [ ] Checkpoint 1: 40 nulos em `renda_mensal`, 15 em `score_bureau`
-- MAGIC - [ ] Checkpoint 2: 25 duplicatas
-- MAGIC - [ ] Checkpoint 3: 51 outliers de renda pelo IQR
-- MAGIC - [ ] Checkpoint 4: canais viram só `App`, `Web`, `Agencia`
-- MAGIC - [ ] Checkpoint 5: inadimplência cai de ~42% para <10% conforme o score sobe
-- MAGIC - [ ] Checkpoint 6: `score_bureau` é a correlação mais negativa com o alvo
-- MAGIC - [ ] Final: `silver_clientes` com **911 linhas**, taxa ~**0.22**,
-- MAGIC       **0** scores nulos e **3** canais
-- MAGIC
-- MAGIC Travou? Levanta a mão. A resposta de referência fica com o instrutor.
