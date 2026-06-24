# Databricks notebook source
# MAGIC %md
# MAGIC # 04 · Fato Gold — SOLUÇÃO (PySpark)

# COMMAND ----------

from pyspark.sql import functions as F

spark.sql("USE CATALOG workspace")
spark.sql("USE SCHEMA treino_financeiro")

silver           = spark.table("silver_lancamentos")
dim_centro_custo = spark.table("dim_centro_custo")
dim_categoria    = spark.table("dim_categoria")

# COMMAND ----------

fato = (silver
    .withColumn("sk_data", F.date_format("data_lancamento", "yyyyMMdd").cast("int"))
    .withColumn("valor_sinalizado",
                F.when(F.col("tipo") == "Receita", F.col("valor")).otherwise(-F.col("valor")))
    .join(dim_centro_custo, silver.centro_custo == dim_centro_custo.nome_centro_custo)
    .join(dim_categoria,    silver.categoria    == dim_categoria.nome_categoria)
    .select("id_lancamento", "sk_data", "sk_centro_custo", "sk_categoria",
            "tipo", "valor", "valor_sinalizado", "descricao"))

fato.write.mode("overwrite").saveAsTable("fato_lancamentos")

# COMMAND ----------

display(spark.sql("""
SELECT
  count(*)                                                AS linhas_fato,
  sum(CASE WHEN sk_centro_custo IS NULL THEN 1 ELSE 0 END) AS sk_centro_custo_faltando,
  sum(CASE WHEN sk_categoria   IS NULL THEN 1 ELSE 0 END)  AS sk_categoria_faltando,
  sum(CASE WHEN sk_data        IS NULL THEN 1 ELSE 0 END)  AS sk_data_faltando
FROM fato_lancamentos
"""))
