-- Databricks notebook source
-- MAGIC %md
-- MAGIC # 09 · View vs Materialized View — SOLUÇÃO
-- MAGIC
-- MAGIC Gabarito completo dos desafios. Fontes vêm do Postgres via Federation
-- MAGIC (catálogo `externo`). Ajuste o nome do catálogo se o seu for diferente.

-- COMMAND ----------

USE CATALOG workspace;
CREATE SCHEMA IF NOT EXISTS treino_views;
USE SCHEMA treino_views;

-- COMMAND ----------

-- MAGIC %md
-- MAGIC ## VIEW — sempre ao vivo

-- COMMAND ----------

CREATE OR REPLACE VIEW vw_resumo_cidade AS
SELECT
  v.cidade,
  SUM(v.valor_venda)      AS receita_total,
  SUM(c.valor_contratado) AS credito_total
FROM externo.public.vendas_lojas v
JOIN externo.public.contratos_credito c ON v.cliente_id = c.cliente_id
GROUP BY v.cidade;

SELECT * FROM vw_resumo_cidade ORDER BY cidade;

-- COMMAND ----------

-- MAGIC %md
-- MAGIC ## Desafio 1 — MATERIALIZED VIEW equivalente

-- COMMAND ----------

CREATE MATERIALIZED VIEW mv_resumo_cidade AS
SELECT
  v.cidade,
  SUM(v.valor_venda)      AS receita_total,
  SUM(c.valor_contratado) AS credito_total
FROM externo.public.vendas_lojas v
JOIN externo.public.contratos_credito c ON v.cliente_id = c.cliente_id
GROUP BY v.cidade;

SELECT * FROM mv_resumo_cidade ORDER BY cidade;

-- COMMAND ----------

-- MAGIC %md
-- MAGIC ## Desafio 2 — crédito por status

-- COMMAND ----------

CREATE MATERIALIZED VIEW mv_credito_por_status AS
SELECT
  status,
  COUNT(*)                AS qtd_contratos,
  SUM(valor_contratado)   AS credito_total
FROM externo.public.contratos_credito
GROUP BY status;

SELECT * FROM mv_credito_por_status ORDER BY credito_total DESC;

-- COMMAND ----------

-- MAGIC %md
-- MAGIC ## Desafio 3 — ticket médio por cidade

-- COMMAND ----------

CREATE MATERIALIZED VIEW mv_ticket_medio_cidade AS
SELECT
  cidade,
  ROUND(AVG(valor_venda), 2) AS ticket_medio,
  COUNT(*)                    AS qtd_vendas
FROM externo.public.vendas_lojas
GROUP BY cidade;

SELECT * FROM mv_ticket_medio_cidade ORDER BY ticket_medio DESC;
-- Esperado: Goiânia 9999, Uberaba 5000, Cataguases 4300, Araxá 1950 (2 vendas),
-- Patos de Minas 1800, Uberlândia 1500

-- COMMAND ----------

-- MAGIC %md
-- MAGIC ## Desafio 4 — crédito por produto (JOIN no catálogo)

-- COMMAND ----------

CREATE MATERIALIZED VIEW mv_credito_por_produto AS
SELECT
  p.nome_produto,
  p.taxa_juros_mensal,
  SUM(c.valor_contratado) AS total_contratado,
  COUNT(*)                AS qtd_contratos
FROM externo.public.contratos_credito c
JOIN externo.public.produtos_credito p ON c.tipo_produto = p.tipo_produto
GROUP BY p.nome_produto, p.taxa_juros_mensal;

SELECT * FROM mv_credito_por_produto ORDER BY total_contratado DESC;
-- Esperado: Crédito Consignado 17000/2, Cartão de Crédito 9700/3, Empréstimo Pessoal 3250/2

-- COMMAND ----------

-- MAGIC %md
-- MAGIC ## Desafio 5 — nome do cliente na venda (JOIN clientes)

-- COMMAND ----------

CREATE MATERIALIZED VIEW mv_cliente_venda AS
SELECT
  cl.nome,
  v.cidade,
  v.valor_venda
FROM externo.public.vendas_lojas v
JOIN externo.public.clientes cl ON v.cliente_id = cl.cliente_id;

SELECT * FROM mv_cliente_venda ORDER BY valor_venda DESC;
-- Esperado: 7 linhas (Carla/Goiânia/9999 no topo ... Elaine/Araxá/700 no fim)

-- COMMAND ----------

-- MAGIC %md
-- MAGIC ## Desafio 6 — receita vs meta (VIEW sobre VIEW)

-- COMMAND ----------

CREATE OR REPLACE VIEW vw_receita_vs_meta AS
SELECT
  meta.cidade,
  meta.meta_receita,
  vw.receita_total,
  ROUND(vw.receita_total / meta.meta_receita * 100, 1) AS pct_meta
FROM vw_resumo_cidade vw
JOIN externo.public.metas_cidade meta ON vw.cidade = meta.cidade;

SELECT * FROM vw_receita_vs_meta ORDER BY pct_meta DESC;
-- Esperado: Goiânia 200%, Araxá 130%, Uberaba 125%, Cataguases 122.9%,
-- Uberlândia 75%, Patos de Minas 72%

-- COMMAND ----------

-- MAGIC %md
-- MAGIC ## Demonstração view x MV (congelada até o refresh)

-- COMMAND ----------

-- No Postgres (psql local), o instrutor altera um valor, ex.:
--   UPDATE vendas_lojas SET valor_venda = 1234 WHERE cidade='Araxá' AND cliente_id=101;
-- A VIEW muda na hora; a MV só após:
REFRESH MATERIALIZED VIEW mv_resumo_cidade;

SELECT 'view (ao vivo)'         AS origem, * FROM vw_resumo_cidade WHERE cidade = 'Araxá';
SELECT 'materialized (refresh)' AS origem, * FROM mv_resumo_cidade WHERE cidade = 'Araxá';
