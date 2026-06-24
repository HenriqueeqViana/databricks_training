# Databricks notebook source
# MAGIC %md
# MAGIC # 00 · Setup — catálogo, schema & volume
# MAGIC
# MAGIC Cria o catálogo/schema e um **volume** para subir o CSV.
# MAGIC Rode este notebook primeiro e depois suba o arquivo (passo 2 abaixo).

# COMMAND ----------

# DBTITLE 1,Configuração (mude aqui se precisar)
# Estes três nomes são reusados por todos os notebooks deste track.
CATALOG = "workspace"          # catálogo padrão em workspaces novos do Databricks
SCHEMA  = "treino_financeiro"
VOLUME  = "entrada"

CSV_PATH = f"/Volumes/{CATALOG}/{SCHEMA}/{VOLUME}/lancamentos_financeiros.csv"

# COMMAND ----------

spark.sql(f"USE CATALOG {CATALOG}")
spark.sql(f"CREATE SCHEMA IF NOT EXISTS {SCHEMA}")
spark.sql(f"USE SCHEMA {SCHEMA}")
spark.sql(f"CREATE VOLUME IF NOT EXISTS {VOLUME}")
print(f"Pronto. Suba o CSV em: /Volumes/{CATALOG}/{SCHEMA}/{VOLUME}/")

# COMMAND ----------

# MAGIC %md
# MAGIC ## Passo 2 — suba o CSV no volume
# MAGIC
# MAGIC Os notebooks esperam o arquivo no `CSV_PATH` impresso acima.
# MAGIC
# MAGIC **UI:** Catalog → `workspace` → `treino_financeiro` → `entrada` →
# MAGIC **Upload to this volume** → escolha `data/lancamentos_financeiros.csv`.
# MAGIC
# MAGIC **CLI:** `databricks fs cp data/lancamentos_financeiros.csv dbfs:/Volumes/workspace/treino_financeiro/entrada/`

# COMMAND ----------

# DBTITLE 1,Verifique o upload
display(dbutils.fs.ls(f"/Volumes/{CATALOG}/{SCHEMA}/{VOLUME}/"))

# COMMAND ----------

# DBTITLE 1,Espie o arquivo bruto
bruto = (spark.read
         .format("csv")
         .option("header", True)
         .load(CSV_PATH))
display(bruto.limit(10))
