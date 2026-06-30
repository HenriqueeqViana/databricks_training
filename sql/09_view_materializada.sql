-- Databricks notebook source
-- MAGIC %md
-- MAGIC # 09 · Desafio: View vs Materialized View
-- MAGIC
-- MAGIC Duas formas de "salvar uma consulta" — com um trade-off importante:
-- MAGIC
-- MAGIC | | VIEW | MATERIALIZED VIEW |
-- MAGIC |---|---|---|
-- MAGIC | O que guarda | só a **consulta** (SQL) | o **resultado** já calculado |
-- MAGIC | Quando calcula | **toda vez** que você lê | no **refresh** (agendado/manual) |
-- MAGIC | Leitura | mais lenta (recalcula) | rápida (lê pronto) |
-- MAGIC | Atualização | sempre ao vivo | pode ficar "atrasada" até o refresh |
-- MAGIC
-- MAGIC Vamos usar as fontes do Postgres via **Federation** (catálogo `externo`).
-- MAGIC Se o seu catálogo tem outro nome, troque `externo` abaixo.
-- MAGIC
-- MAGIC > Pré-requisito: o foreign catalog já criado, ex.:
-- MAGIC > `CREATE FOREIGN CATALOG externo USING CONNECTION conn_postgresql OPTIONS (database 'teste');`

-- COMMAND ----------

-- Escolha onde criar as views (catálogo/schema do seu workspace)
USE CATALOG workspace;
CREATE SCHEMA IF NOT EXISTS treino_views;
USE SCHEMA treino_views;

-- COMMAND ----------

-- MAGIC %md
-- MAGIC ## Exemplo resolvido — a VIEW (sempre ao vivo)
-- MAGIC A view abaixo é só a consulta salva. Cada `SELECT` nela recalcula lendo o
-- MAGIC Postgres na hora — então reflete qualquer mudança na fonte imediatamente.

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
-- MAGIC ## Sua vez 1 — a MATERIALIZED VIEW (resultado pré-calculado)
-- MAGIC Crie uma materialized view com a **mesma lógica** da view acima. Complete os `___`.
-- MAGIC Dica: a única diferença em relação à view é `CREATE MATERIALIZED VIEW` no começo —
-- MAGIC o `SELECT` é igualzinho.

-- COMMAND ----------

CREATE MATERIALIZED VIEW mv_resumo_cidade AS
SELECT
  v.___,
  SUM(v.___) AS receita_total,
  SUM(c.___) AS credito_total
FROM externo.public.vendas_lojas v
JOIN externo.public.contratos_credito c ON v.___ = c.___
GROUP BY v.___;

SELECT * FROM mv_resumo_cidade ORDER BY cidade;

-- COMMAND ----------

-- MAGIC %md
-- MAGIC ## Sua vez 2 — uma MV com outra agregação
-- MAGIC Crie `mv_credito_por_status`: total de crédito contratado **por status**
-- MAGIC (`aprovado`, `recusado`). Use `externo.public.contratos_credito`.
-- MAGIC Dica: `GROUP BY status`, `SUM(valor_contratado)`, `COUNT(*)`.

-- COMMAND ----------

CREATE MATERIALIZED VIEW mv_credito_por_status AS
SELECT
  ___                       AS status,
  COUNT(*)                  AS qtd_contratos,
  SUM(___)                  AS credito_total
FROM externo.public.contratos_credito
GROUP BY ___;

SELECT * FROM mv_credito_por_status ORDER BY credito_total DESC;

-- COMMAND ----------

-- MAGIC %md
-- MAGIC ## Veja a diferença na prática (view ao vivo x MV congelada)
-- MAGIC
-- MAGIC 1. O instrutor altera um valor no Postgres (ex.: muda a venda de uma cidade).
-- MAGIC 2. Rode os dois `SELECT` abaixo:
-- MAGIC    - a **VIEW** já mostra o valor novo (recalcula ao vivo)
-- MAGIC    - a **MATERIALIZED VIEW** ainda mostra o valor antigo (está congelada)
-- MAGIC 3. Atualize a MV e veja ela igualar:
-- MAGIC    ```sql
-- MAGIC    REFRESH MATERIALIZED VIEW mv_resumo_cidade;
-- MAGIC    ```

-- COMMAND ----------

SELECT 'view (ao vivo)' AS origem, * FROM vw_resumo_cidade WHERE cidade = 'Araxá';
-- depois do REFRESH, compare:
SELECT 'materialized (refresh)' AS origem, * FROM mv_resumo_cidade WHERE cidade = 'Araxá';

-- COMMAND ----------

-- MAGIC %md
-- MAGIC ## Como saber se acertou
-- MAGIC - [ ] `mv_resumo_cidade` retorna as mesmas linhas/valores da `vw_resumo_cidade`
-- MAGIC - [ ] `mv_credito_por_status` tem uma linha por status com `qtd_contratos` e `credito_total`
-- MAGIC - [ ] Depois de mudar a fonte: a VIEW muda na hora; a MV só muda após `REFRESH`
-- MAGIC
-- MAGIC A resposta de referência fica com o instrutor.
