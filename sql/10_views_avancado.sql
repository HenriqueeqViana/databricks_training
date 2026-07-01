-- Databricks notebook source
-- MAGIC %md
-- MAGIC # 10 · Desafio avançado: Temp View × Global Temp View × Materialized View
-- MAGIC
-- MAGIC Quatro formas de "salvar uma consulta", cada uma pra uma necessidade diferente.
-- MAGIC Saber **qual usar quando** é o objetivo deste desafio.
-- MAGIC
-- MAGIC | Tipo | Escopo / vida | Recalcula? | Use quando… |
-- MAGIC |---|---|---|---|
-- MAGIC | **TEMPORARY VIEW** | só a **sessão/notebook** atual | a cada leitura | rascunho intermediário de 1 execução |
-- MAGIC | **GLOBAL TEMPORARY VIEW** | o **cluster** (schema `global_temp`), some no restart | a cada leitura | compartilhar entre notebooks sem criar tabela |
-- MAGIC | **MATERIALIZED VIEW** | **persistente** (Unity Catalog) | no `REFRESH` | agregação cara servida a dashboards |
-- MAGIC | **VIEW** | persistente | a cada leitura | cálculo leve/ao vivo sobre tabelas ou MVs |
-- MAGIC
-- MAGIC **Regra que pega todo mundo:** uma **Materialized View só pode ler tabelas
-- MAGIC persistentes** (ex.: bronze). Ela **não** pode ler uma temp view nem uma global
-- MAGIC temp view. Por isso a MV vai ler o **bronze** direto.
-- MAGIC
-- MAGIC Fonte: as tabelas do Postgres via Federation (catálogo `externo`), incluindo as
-- MAGIC novas `transacoes` e `agencias`.

-- COMMAND ----------

USE CATALOG workspace;
CREATE SCHEMA IF NOT EXISTS treino_avancado;
USE SCHEMA treino_avancado;

-- COMMAND ----------

-- MAGIC %md
-- MAGIC ## Bronze — traga as fontes pra tabelas persistentes (pronto)
-- MAGIC Simula a ingestão: copiamos as fontes federadas para tabelas Delta (bronze).
-- MAGIC É sobre estas tabelas que a Materialized View vai poder ser construída.

-- COMMAND ----------

CREATE OR REPLACE TABLE bronze_transacoes AS SELECT * FROM externo.public.transacoes;
CREATE OR REPLACE TABLE bronze_agencias   AS SELECT * FROM externo.public.agencias;
CREATE OR REPLACE TABLE bronze_clientes   AS SELECT * FROM externo.public.clientes;

SELECT status, count(*) AS n FROM bronze_transacoes GROUP BY status;
-- bronze é "cru": tem canceladas/pendentes e canal com caixa bagunçada (App/app/WEB)

-- COMMAND ----------

-- MAGIC %md
-- MAGIC ## Desafio 1 — TEMPORARY VIEW (staging desta sessão)
-- MAGIC Crie a temp view `stg_transacoes`: limpe o bronze para uso **neste notebook**.
-- MAGIC - Mantenha só o status **`concluida`**
-- MAGIC - Padronize `canal` para Iniciais Maiúsculas (ex.: `App`, `Web`, `Agencia`)
-- MAGIC - Derive `mes` = primeiro dia do mês da `data_transacao`
-- MAGIC
-- MAGIC Dicas: `initcap(lower(canal))`, `trunc(data_transacao, 'MM')`.
-- MAGIC Por que temp: é rascunho de limpeza, não precisa persistir.

-- COMMAND ----------

CREATE OR REPLACE TEMPORARY VIEW stg_transacoes AS
SELECT
  transacao_id,
  cliente_id,
  agencia_id,
  data_transacao,
  ___                 AS mes,      -- primeiro dia do mês
  valor,
  ___                 AS canal,    -- Iniciais Maiúsculas
  status
FROM bronze_transacoes
WHERE status = '___';

SELECT canal, count(*) AS n, sum(valor) AS total FROM stg_transacoes GROUP BY canal ORDER BY total DESC;

-- COMMAND ----------

-- MAGIC %md
-- MAGIC ## Desafio 2 — GLOBAL TEMPORARY VIEW (compartilhar entre notebooks)
-- MAGIC Crie `transacoes_enriquecidas` como **global temp view**, juntando transações
-- MAGIC concluídas com `bronze_clientes` e `bronze_agencias` para trazer `cliente` e
-- MAGIC `cidade`.
-- MAGIC
-- MAGIC ⚠️ **Leia do bronze (persistente), não da `stg_transacoes`** — uma global temp
-- MAGIC view precisa valer em **outra sessão**, e a temp view da sessão 1 não existe lá.
-- MAGIC
-- MAGIC Lembre: global temp view mora no schema `global_temp` e é lida como
-- MAGIC `global_temp.transacoes_enriquecidas`.

-- COMMAND ----------

CREATE OR REPLACE GLOBAL TEMPORARY VIEW transacoes_enriquecidas AS
SELECT
  t.transacao_id,
  trunc(t.data_transacao, 'MM') AS mes,
  initcap(lower(t.canal))       AS canal,
  t.valor,
  cl.nome                       AS cliente,
  ag.cidade                     AS cidade
FROM bronze_transacoes t
JOIN bronze_clientes cl ON t.___ = cl.___
JOIN bronze_agencias ag ON t.___ = ag.___
WHERE t.status = 'concluida';

SELECT * FROM ___.transacoes_enriquecidas ORDER BY valor DESC LIMIT 10;

-- COMMAND ----------

-- MAGIC %md
-- MAGIC ## Desafio 3 — MATERIALIZED VIEW (agregação servida)
-- MAGIC Crie `mv_receita_mensal_cidade`: receita por **cidade** e **mês**, só concluídas.
-- MAGIC Leia do **bronze** (a MV não pode ler as views acima). Precisa juntar
-- MAGIC `bronze_transacoes` com `bronze_agencias` pra ter a cidade.
-- MAGIC
-- MAGIC Colunas: `cidade`, `mes`, `receita_mes` (=`SUM(valor)`), `qtd` (=`COUNT(*)`).

-- COMMAND ----------

CREATE MATERIALIZED VIEW mv_receita_mensal_cidade AS
SELECT
  ag.cidade,
  trunc(t.data_transacao, 'MM') AS mes,
  SUM(t.___)                    AS receita_mes,
  COUNT(*)                      AS qtd
FROM bronze_transacoes t
JOIN bronze_agencias ag ON t.agencia_id = ag.agencia_id
WHERE t.status = '___'
GROUP BY ag.cidade, trunc(t.data_transacao, 'MM');

SELECT * FROM mv_receita_mensal_cidade ORDER BY cidade, mes;

-- COMMAND ----------

-- MAGIC %md
-- MAGIC ## Desafio 4 — VIEW com window sobre a MV (receita acumulada)
-- MAGIC Crie a VIEW `vw_receita_acumulada`: para cada cidade, o **total acumulado** de
-- MAGIC receita mês a mês. Construa **em cima da `mv_receita_mensal_cidade`** (cálculo
-- MAGIC leve sobre a agregação já pronta).
-- MAGIC
-- MAGIC Dica (window function):
-- MAGIC `SUM(receita_mes) OVER (PARTITION BY cidade ORDER BY mes ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW)`

-- COMMAND ----------

CREATE OR REPLACE VIEW vw_receita_acumulada AS
SELECT
  cidade,
  mes,
  receita_mes,
  SUM(receita_mes) OVER (PARTITION BY ___ ORDER BY ___
                         ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS receita_acumulada
FROM mv_receita_mensal_cidade;

SELECT * FROM vw_receita_acumulada ORDER BY cidade, mes;

-- COMMAND ----------

-- MAGIC %md
-- MAGIC ## Como saber se acertou
-- MAGIC - [ ] `stg_transacoes`: 12 linhas (só concluídas), canal como `App`/`Web`/`Agencia`
-- MAGIC - [ ] `global_temp.transacoes_enriquecidas`: traz `cliente` e `cidade`; funciona
-- MAGIC       porque lê do bronze (persistente)
-- MAGIC - [ ] `mv_receita_mensal_cidade`: 10 linhas (cidade × mês). Ex.: Araxá/2026-03 = 1150
-- MAGIC - [ ] `vw_receita_acumulada`: Araxá acumula 320 → 875.25 → 2025.25 de jan a mar
-- MAGIC - [ ] Você sabe explicar por que a MV não pode ler a temp view
-- MAGIC
-- MAGIC A resposta de referência fica com o instrutor.
