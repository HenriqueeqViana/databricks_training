# Databricks notebook source
# MAGIC %md
# MAGIC # 02 · Silver — SOLUÇÃO (PySpark)

# COMMAND ----------

from pyspark.sql import functions as F

spark.sql("USE CATALOG workspace")
spark.sql("USE SCHEMA treino_financeiro")
bronze = spark.table("bronze_lancamentos")

# COMMAND ----------

cat = F.lower(F.trim(F.col("categoria")))
tipo = F.lower(F.trim(F.col("tipo")))

categoria_std = (
    F.when(cat.isin("software", "licencas", "licenças"), "Software")
     .when(cat.isin("impostos", "tributos"), "Impostos")
     .when(cat.isin("salarios", "salários", "folha", "folha de pagamento"), "Folha de Pagamento")
     .when(cat.isin("aluguel", "locacao"), "Aluguel")
     .when(cat.isin("marketing", "publicidade", "anuncios"), "Marketing")
     .when(cat.isin("viagens", "viagem"), "Viagens")
     .when(cat.isin("infraestrutura", "infra", "cloud"), "Infraestrutura")
     .when(cat.isin("servicos", "serviços", "consultoria"), "Serviços")
     .when(cat.isin("material", "materiais", "suprimentos"), "Materiais")
     .when(cat.isin("vendas", "venda mensal"), "Vendas")
     .when(cat.isin("servicos prestados", "serviços prestados", "prestacao de servicos"), "Receita de Serviços")
     .when(cat.isin("juros", "rendimentos"), "Juros")
     .when(cat.isin("investimentos", "aplicacoes"), "Investimentos")
     .otherwise("Sem Categoria")
)

silver = (bronze.select(
        F.trim("id_lancamento").alias("id_lancamento"),
        F.coalesce(
            F.to_date("data_lancamento", "yyyy-MM-dd"),
            F.to_date("data_lancamento", "dd/MM/yyyy"),
        ).alias("data_lancamento"),
        F.initcap(F.trim("centro_custo")).alias("centro_custo"),
        categoria_std.alias("categoria"),
        F.regexp_replace(F.col("valor"), r"[^0-9.]", "").cast("decimal(12,2)").alias("valor"),
        F.when(tipo == "receita", "Receita").when(tipo == "despesa", "Despesa").alias("tipo"),
        F.initcap(F.trim(F.regexp_replace("descricao", r"\s+", " "))).alias("descricao"),
    )
    .filter(F.col("data_lancamento").isNotNull() & F.col("valor").isNotNull())   # descarta linhas ruins
    .dropDuplicates())                                                           # dedupe

silver.write.mode("overwrite").option("overwriteSchema", "true").saveAsTable("silver_lancamentos")

# COMMAND ----------

display(spark.sql("SELECT tipo, count(*) AS n FROM silver_lancamentos GROUP BY tipo"))
display(spark.sql("SELECT categoria, count(*) AS n FROM silver_lancamentos GROUP BY categoria ORDER BY n DESC"))
