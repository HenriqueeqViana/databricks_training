# Databricks notebook source
# MAGIC %md
# MAGIC # 03 · Gold — tabelas de dimensão  🧩
# MAGIC
# MAGIC Gold = um **star schema**: dimensões pequenas em volta de um fato central.
# MAGIC Cada dimensão guarda valores únicos de um atributo + uma chave substituta
# MAGIC (`sk_*`) que o fato vai referenciar.
# MAGIC
# MAGIC Montamos **centro de custo** (exemplo resolvido), depois **categoria** e
# MAGIC **data** (seus desafios). A tabela fato é o notebook `04`.

# COMMAND ----------

from pyspark.sql import functions as F
from pyspark.sql.window import Window

CATALOG = "workspace"
SCHEMA  = "treino_financeiro"
spark.sql(f"USE CATALOG {CATALOG}")
spark.sql(f"USE SCHEMA {SCHEMA}")

silver = spark.table("silver_lancamentos")

# COMMAND ----------

# MAGIC %md
# MAGIC ## ✅ Exemplo resolvido — `dim_centro_custo`
# MAGIC Centros de custo distintos + uma chave substituta via `row_number()`.

# COMMAND ----------

dim_centro_custo = (silver.select("centro_custo").distinct()
    .withColumn("sk_centro_custo", F.row_number().over(Window.orderBy("centro_custo")))
    .select("sk_centro_custo", F.col("centro_custo").alias("nome_centro_custo")))

dim_centro_custo.write.mode("overwrite").saveAsTable("dim_centro_custo")
display(spark.table("dim_centro_custo").orderBy("sk_centro_custo"))

# COMMAND ----------

# MAGIC %md
# MAGIC ## 🧩 DESAFIO 1 — `dim_categoria`
# MAGIC Mesma receita acima, para `categoria`. Colunas: `sk_categoria`, `nome_categoria`.
# MAGIC **Bônus:** adicione `grupo_categoria` com uma cadeia de `F.when(...)`.

# COMMAND ----------

# TODO: monte e grave dim_categoria


# COMMAND ----------

# MAGIC %md
# MAGIC ## 🧩 DESAFIO 2 — `dim_data`
# MAGIC Uma linha por dia, com as partes separadas. Monte a partir dos valores
# MAGIC distintos de `data_lancamento`. Colunas sugeridas + dicas:
# MAGIC
# MAGIC | coluna | dica |
# MAGIC |--------|------|
# MAGIC | `sk_data`       | `F.date_format("data_completa","yyyyMMdd").cast("int")` |
# MAGIC | `data_completa` | a própria data |
# MAGIC | `ano`           | `F.year("data_completa")` |
# MAGIC | `mes`           | `F.month("data_completa")` |
# MAGIC | `nome_mes`      | `F.date_format("data_completa","MMMM")` |
# MAGIC | `trimestre`     | `F.quarter("data_completa")` |
# MAGIC | `dia`           | `F.dayofmonth("data_completa")` |
# MAGIC | `dia_semana`    | `F.date_format("data_completa","EEEE")` |

# COMMAND ----------

# TODO: monte e grave dim_data
# Comece de: silver.select(F.col("data_lancamento").alias("data_completa")).distinct()


# COMMAND ----------

# DBTITLE 1,Valide suas dimensões
for t in ["dim_centro_custo", "dim_categoria", "dim_data"]:
    print(f"{t}: {spark.table(t).count()} linhas")
