# Databricks notebook source
# MAGIC %md
# MAGIC # 06 · Desafio: Federation + Lakeflow
# MAGIC
# MAGIC **Cenário:** uma empresa tem duas "estruturas" que não se comunicam entre si:
# MAGIC - Lojas -> sabe quem comprou o quê
# MAGIC - Financeira -> sabe quem pegou crédito
# MAGIC
# MAGIC No mundo real essas fontes são bancos separados. Aqui elas vivem num
# MAGIC **PostgreSQL** real, e o Databricks lê via **Lakehouse Federation**.
# MAGIC
# MAGIC **Objetivo:** unir as duas fontes e descobrir, por cidade, qual foi a
# MAGIC receita de vendas e o total de crédito contratado.
# MAGIC
# MAGIC > Pré-requisitos: workspace com **Unity Catalog**. O host/porta/usuário do
# MAGIC > Postgres são preenchidos nos widgets abaixo pelo instrutor, e a senha vem
# MAGIC > de um **secret scope** — nada de credencial escrita no notebook.

# COMMAND ----------

# DBTITLE 1,Parâmetros de conexão (sem credenciais no código)
# O instrutor preenche estes widgets em aula. Nada fica versionado.
dbutils.widgets.text("pg_host", "", "Host do Postgres (tunel)")
dbutils.widgets.text("pg_port", "", "Porta")
dbutils.widgets.text("pg_user", "teste", "Usuario")
dbutils.widgets.text("pg_database", "teste", "Database")

# Secret scope/key configurados previamente:
#   databricks secrets create-scope treino
#   databricks secrets put-secret treino pg_password
SECRET_SCOPE = "treino"
SECRET_KEY   = "pg_password"

host = dbutils.widgets.get("pg_host")
port = dbutils.widgets.get("pg_port")
user = dbutils.widgets.get("pg_user")
database = dbutils.widgets.get("pg_database")
password = dbutils.secrets.get(scope=SECRET_SCOPE, key=SECRET_KEY)

assert host and port, "Preencha os widgets pg_host e pg_port antes de rodar."

# COMMAND ----------

# DBTITLE 1,Cria a Connection e o Foreign Catalog (Federation)
# A senha vem do secret; o valor nunca aparece no código nem no histórico.
spark.sql(f"""
CREATE CONNECTION IF NOT EXISTS conn_postgres TYPE postgresql
OPTIONS (
  host '{host}',
  port '{port}',
  user '{user}',
  password secret('{SECRET_SCOPE}', '{SECRET_KEY}')
)
""")

spark.sql(f"""
CREATE FOREIGN CATALOG IF NOT EXISTS externo
USING CONNECTION conn_postgres
OPTIONS (database '{database}')
""")

# Confere que as duas fontes apareceram via Federation
display(spark.sql("SHOW TABLES IN externo.public"))

# COMMAND ----------

# MAGIC %md
# MAGIC ## Espie as fontes (já vêm do Postgres real)

# COMMAND ----------

# MAGIC %sql
# MAGIC SELECT * FROM externo.public.vendas_lojas;
# MAGIC -- SELECT * FROM externo.public.contratos_credito;

# COMMAND ----------

# MAGIC %md
# MAGIC ## Sua vez
# MAGIC
# MAGIC Complete o SQL abaixo (troque os `___`) para responder:
# MAGIC **"Por cidade, qual a receita total de vendas e o total de crédito contratado?"**
# MAGIC
# MAGIC Dicas:
# MAGIC - As duas tabelas se conectam pelo `cliente_id` (é a "ponte" — o papel que a
# MAGIC   Federation faria entre dois bancos reais).
# MAGIC - Você precisa de um `JOIN` pra unir e um `GROUP BY` pra resumir por cidade.
# MAGIC - `SUM()` soma uma coluna.

# COMMAND ----------

# MAGIC %sql
# MAGIC SELECT
# MAGIC   v.___,
# MAGIC   SUM(v.___) AS receita_total,
# MAGIC   SUM(c.___) AS credito_total
# MAGIC FROM externo.public.vendas_lojas v
# MAGIC JOIN externo.public.contratos_credito c ON v.___ = c.___
# MAGIC GROUP BY v.___

# COMMAND ----------

# MAGIC %md
# MAGIC ## Como saber se acertou
# MAGIC
# MAGIC Seu resultado deve ter:
# MAGIC - [ ] 3 linhas (uma por cidade: Araxá, Uberlândia, Goiânia)
# MAGIC - [ ] Coluna `receita_total` com os valores 3200, 1500 e 2200
# MAGIC - [ ] Coluna `credito_total` com os valores 2000, 5000 e 8000
# MAGIC
# MAGIC Travou? Levanta a mão. A resposta de referência fica com o instrutor.

# COMMAND ----------

# MAGIC %md
# MAGIC ## O que fizemos
# MAGIC
# MAGIC - Lemos duas fontes separadas direto do Postgres via **Federation** (o que
# MAGIC   a Federation faria entre Postgres e Snowflake de verdade).
# MAGIC - Construímos a resposta de negócio com `JOIN` + `GROUP BY` (a lógica por
# MAGIC   trás de um pipeline Lakeflow).
# MAGIC
# MAGIC No mundo real, esse mesmo SQL roda automaticamente todo dia, com os dados
# MAGIC vindo direto dos sistemas de origem.
