# Databricks notebook source
# MAGIC %md
# MAGIC # 03 · Dimensões Gold — SOLUÇÃO (PySpark)

# COMMAND ----------

from pyspark.sql import functions as F
from pyspark.sql.window import Window

spark.sql("USE CATALOG workspace")
spark.sql("USE SCHEMA treino_financeiro")
silver = spark.table("silver_lancamentos")

# COMMAND ----------

# dim_centro_custo (exemplo resolvido)
dim_centro_custo = (silver.select("centro_custo").distinct()
    .withColumn("sk_centro_custo", F.row_number().over(Window.orderBy("centro_custo")))
    .select("sk_centro_custo", F.col("centro_custo").alias("nome_centro_custo")))
dim_centro_custo.write.mode("overwrite").saveAsTable("dim_centro_custo")

# COMMAND ----------

# dim_categoria (DESAFIO 1 + bônus grupo)
grupo = (F.when(F.col("categoria").isin("Vendas", "Receita de Serviços", "Juros", "Investimentos"), "Receita")
          .when(F.col("categoria").isin("Folha de Pagamento", "Viagens"), "Pessoas")
          .otherwise("Operacional"))

dim_categoria = (silver.select("categoria").distinct()
    .withColumn("sk_categoria", F.row_number().over(Window.orderBy("categoria")))
    .withColumn("grupo_categoria", grupo)
    .select("sk_categoria", F.col("categoria").alias("nome_categoria"), "grupo_categoria"))
dim_categoria.write.mode("overwrite").saveAsTable("dim_categoria")

# COMMAND ----------

# dim_data (DESAFIO 2)
dim_data = (silver.select(F.col("data_lancamento").alias("data_completa")).distinct()
    .withColumn("sk_data", F.date_format("data_completa", "yyyyMMdd").cast("int"))
    .withColumn("ano", F.year("data_completa"))
    .withColumn("mes", F.month("data_completa"))
    .withColumn("nome_mes", F.date_format("data_completa", "MMMM"))
    .withColumn("trimestre", F.quarter("data_completa"))
    .withColumn("dia", F.dayofmonth("data_completa"))
    .withColumn("dia_semana", F.date_format("data_completa", "EEEE"))
    .select("sk_data", "data_completa", "ano", "mes", "nome_mes", "trimestre", "dia", "dia_semana"))
dim_data.write.mode("overwrite").saveAsTable("dim_data")

# COMMAND ----------

for t in ["dim_centro_custo", "dim_categoria", "dim_data"]:
    print(f"{t}: {spark.table(t).count()} linhas")
