# Databricks notebook source
# MAGIC %md
# MAGIC # 04 · Gold — tabela fato  🧩
# MAGIC
# MAGIC A tabela **fato** é o coração do modelo estrela: uma linha por lançamento,
# MAGIC guardando as **métricas** (números que somamos) e as **chaves estrangeiras**
# MAGIC para cada dimensão — não o texto descritivo, que mora nas dimensões.

# COMMAND ----------

from pyspark.sql import functions as F

CATALOG = "workspace"
SCHEMA  = "treino_financeiro"
spark.sql(f"USE CATALOG {CATALOG}")
spark.sql(f"USE SCHEMA {SCHEMA}")

silver           = spark.table("silver_lancamentos")
dim_centro_custo = spark.table("dim_centro_custo")
# dim_categoria  = spark.table("dim_categoria")   # 🧩 descomente depois de criar no 03

# COMMAND ----------

# MAGIC %md
# MAGIC ## ✅ Exemplo resolvido — a métrica com sinal
# MAGIC `valor` é sempre positivo. Receita deve somar e despesa subtrair, então
# MAGIC derivamos `valor_sinalizado = +valor para Receita, -valor para Despesa`.
# MAGIC Somar essa coluna dá o **resultado líquido** direto.

# COMMAND ----------

# MAGIC %md
# MAGIC ## 🧩 DESAFIO — monte `fato_lancamentos`
# MAGIC Junte a silver a cada dimensão para trocar texto por chaves substitutas. O
# MAGIC join de centro de custo + a métrica com sinal estão prontos; preencha os
# MAGIC `TODO` de categoria.

# COMMAND ----------

fato = (silver
    .withColumn("sk_data", F.date_format("data_lancamento", "yyyyMMdd").cast("int"))   # ✅ pronto
    .withColumn("valor_sinalizado",
                F.when(F.col("tipo") == "Receita", F.col("valor"))
                 .otherwise(-F.col("valor")))                                           # ✅ exemplo resolvido
    .join(dim_centro_custo, silver.centro_custo == dim_centro_custo.nome_centro_custo)  # ✅ join modelo
    # 🧩 TODO: .join(dim_categoria, silver.categoria == dim_categoria.nome_categoria)
    .select(
        "id_lancamento",
        "sk_data",
        "sk_centro_custo",
        # 🧩 TODO: "sk_categoria",
        "tipo",
        "valor",
        "valor_sinalizado",
        "descricao",
    ))

fato.write.mode("overwrite").saveAsTable("fato_lancamentos")

# COMMAND ----------

# DBTITLE 1,Valide a tabela fato
display(spark.sql("""
SELECT
  count(*)                                                 AS linhas_fato,
  sum(CASE WHEN sk_centro_custo IS NULL THEN 1 ELSE 0 END) AS sk_centro_custo_faltando,
  sum(CASE WHEN sk_data IS NULL THEN 1 ELSE 0 END)         AS sk_data_faltando
FROM fato_lancamentos
"""))

# COMMAND ----------

# DBTITLE 1,Teste rápido — resultado por tipo
display(spark.sql("""
SELECT tipo, count(*) AS lancamentos, sum(valor) AS bruto, sum(valor_sinalizado) AS liquido
FROM fato_lancamentos GROUP BY tipo
"""))
