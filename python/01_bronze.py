# Databricks notebook source
# MAGIC %md
# MAGIC # 01 · Bronze — ingestão crua
# MAGIC
# MAGIC Bronze = o dado **exatamente como ele chegou**. Lemos toda coluna como texto
# MAGIC (sem limpeza, sem cast) e só adicionamos metadados de carga. Nunca perca a
# MAGIC verdade crua.

# COMMAND ----------

from pyspark.sql import functions as F

CATALOG = "workspace"
SCHEMA  = "treino_financeiro"
VOLUME  = "entrada"
CSV_PATH = f"/Volumes/{CATALOG}/{SCHEMA}/{VOLUME}/lancamentos_financeiros.csv"

spark.sql(f"USE CATALOG {CATALOG}")
spark.sql(f"USE SCHEMA {SCHEMA}")

# COMMAND ----------

# DBTITLE 1,Lê o CSV como texto cru + adiciona colunas de origem
# inferSchema=False mantém toda coluna como STRING -> bronze nunca quebra com valor ruim.
bronze = (spark.read
          .format("csv")
          .option("header", True)
          .option("inferSchema", False)
          .load(CSV_PATH)
          .withColumn("_arquivo_origem", F.col("_metadata.file_path"))
          .withColumn("_carregado_em", F.current_timestamp()))

bronze.write.mode("overwrite").saveAsTable("bronze_lancamentos")

# COMMAND ----------

# DBTITLE 1,Conferência rápida
print("linhas:", spark.table("bronze_lancamentos").count())
display(spark.table("bronze_lancamentos").limit(20))
