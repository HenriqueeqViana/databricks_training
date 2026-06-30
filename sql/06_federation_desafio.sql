-- Databricks notebook source
-- MAGIC %md
-- MAGIC # 06 · Desafio: Federation + Lakeflow
-- MAGIC
-- MAGIC **Cenário:** uma empresa tem duas "estruturas" que não se comunicam entre si:
-- MAGIC - Lojas -> sabe quem comprou o quê
-- MAGIC - Financeira -> sabe quem pegou crédito
-- MAGIC
-- MAGIC No mundo real essas fontes são bancos separados. Aqui elas vivem num
-- MAGIC **PostgreSQL** real, e o Databricks lê via **Lakehouse Federation**.
-- MAGIC
-- MAGIC **Objetivo:** unir as duas fontes e descobrir, por cidade, qual foi a
-- MAGIC receita de vendas e o total de crédito contratado.
-- MAGIC
-- MAGIC > Pré-requisitos: workspace com **Unity Catalog**. O host/porta/usuário do
-- MAGIC > Postgres entram pelos widgets abaixo (preenchidos pelo instrutor) e a senha
-- MAGIC > vem de um **secret scope** — nada de credencial escrita no notebook.

-- COMMAND ----------

-- MAGIC %md
-- MAGIC ## Setup do instrutor — conexão (rode uma vez)
-- MAGIC Tudo por widget, direto no notebook — sem CLI. Os widgets aparecem no topo;
-- MAGIC o instrutor preenche host/porta/usuário/senha em aula. Como os valores são
-- MAGIC digitados em runtime, **nada de credencial fica no arquivo versionado**.
-- MAGIC
-- MAGIC > Observação: o Databricks não cria *secret scope* por SQL (só via CLI/API).
-- MAGIC > Para treino, o widget de senha resolve. Em produção, troque por
-- MAGIC > `secret('escopo','chave')` com um secret scope de verdade.

-- COMMAND ----------

CREATE WIDGET TEXT pg_host DEFAULT '';
CREATE WIDGET TEXT pg_port DEFAULT '';
CREATE WIDGET TEXT pg_user DEFAULT 'teste';
CREATE WIDGET TEXT pg_database DEFAULT 'teste';
CREATE WIDGET TEXT pg_password DEFAULT '';

-- COMMAND ----------

-- Senha vem do widget (digitada em runtime); não fica escrita no notebook.
CREATE CONNECTION IF NOT EXISTS conn_postgres TYPE postgresql
OPTIONS (
  host '${pg_host}',
  port '${pg_port}',
  user '${pg_user}',
  password '${pg_password}'
);

-- COMMAND ----------

CREATE FOREIGN CATALOG IF NOT EXISTS externo
USING CONNECTION conn_postgres
OPTIONS (database '${pg_database}');

-- Confere que as duas fontes apareceram via Federation
SHOW TABLES IN externo.public;

-- COMMAND ----------

-- MAGIC %md
-- MAGIC ## Espie as fontes (já vêm do Postgres real)

-- COMMAND ----------

SELECT * FROM externo.public.vendas_lojas;
-- SELECT * FROM externo.public.contratos_credito;

-- COMMAND ----------

-- MAGIC %md
-- MAGIC ## Sua vez
-- MAGIC
-- MAGIC Complete o SQL abaixo (troque os `___`) para responder:
-- MAGIC **"Por cidade, qual a receita total de vendas e o total de crédito contratado?"**
-- MAGIC
-- MAGIC Dicas:
-- MAGIC - As duas tabelas se conectam pelo `cliente_id` (é a "ponte" — o papel que a
-- MAGIC   Federation faria entre dois bancos reais).
-- MAGIC - Você precisa de um `JOIN` pra unir e um `GROUP BY` pra resumir por cidade.
-- MAGIC - `SUM()` soma uma coluna.

-- COMMAND ----------

SELECT
  v.___,
  SUM(v.___) AS receita_total,
  SUM(c.___) AS credito_total
FROM externo.public.vendas_lojas v
JOIN externo.public.contratos_credito c ON v.___ = c.___
GROUP BY v.___;

-- COMMAND ----------

-- MAGIC %md
-- MAGIC ## Como saber se acertou
-- MAGIC
-- MAGIC Seu resultado deve ter:
-- MAGIC - [ ] 3 linhas (uma por cidade: Araxá, Uberlândia, Goiânia)
-- MAGIC - [ ] Coluna `receita_total` com os valores 3200, 1500 e 2200
-- MAGIC - [ ] Coluna `credito_total` com os valores 2000, 5000 e 8000
-- MAGIC
-- MAGIC Travou? Levanta a mão. A resposta de referência fica com o instrutor.

-- COMMAND ----------

-- MAGIC %md
-- MAGIC ## O que fizemos
-- MAGIC
-- MAGIC - Lemos duas fontes separadas direto do Postgres via **Federation** (o que
-- MAGIC   a Federation faria entre Postgres e Snowflake de verdade).
-- MAGIC - Construímos a resposta de negócio com `JOIN` + `GROUP BY` (a lógica por
-- MAGIC   trás de um pipeline Lakeflow).
-- MAGIC
-- MAGIC No mundo real, esse mesmo SQL roda automaticamente todo dia, com os dados
-- MAGIC vindo direto dos sistemas de origem.
