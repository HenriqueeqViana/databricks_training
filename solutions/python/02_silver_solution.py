# Databricks notebook source
# MAGIC %md
# MAGIC # 02 · Silver — SOLUTION (PySpark)

# COMMAND ----------

from pyspark.sql import functions as F

spark.sql("USE CATALOG workspace")
spark.sql("USE SCHEMA finance_training")
bronze = spark.table("bronze_ledger")

# COMMAND ----------

cat = F.lower(F.trim(F.col("category")))
ttype = F.lower(F.trim(F.col("type")))

category_std = (
    F.when(cat.isin("software", "licencas", "licenças"), "Software")
     .when(cat.isin("impostos", "tributos"), "Taxes")
     .when(cat.isin("salarios", "salários", "folha", "folha de pagamento"), "Payroll")
     .when(cat.isin("aluguel", "locacao"), "Rent")
     .when(cat.isin("marketing", "publicidade", "anuncios"), "Marketing")
     .when(cat.isin("viagens", "viagem"), "Travel")
     .when(cat.isin("infraestrutura", "infra", "cloud"), "Infrastructure")
     .when(cat.isin("servicos", "serviços", "consultoria"), "Services")
     .when(cat.isin("material", "materiais", "suprimentos"), "Supplies")
     .when(cat.isin("vendas", "venda mensal"), "Sales")
     .when(cat.isin("servicos prestados", "serviços prestados", "prestacao de servicos"), "Services Revenue")
     .when(cat.isin("juros", "rendimentos"), "Interest")
     .when(cat.isin("investimentos", "aplicacoes"), "Investments")
     .otherwise("Uncategorized")
)

silver = (bronze.select(
        F.trim("entry_id").alias("entry_id"),
        F.coalesce(
            F.to_date("entry_date", "yyyy-MM-dd"),
            F.to_date("entry_date", "dd/MM/yyyy"),
        ).alias("entry_date"),
        F.initcap(F.trim("cost_center")).alias("cost_center"),
        category_std.alias("category"),
        F.regexp_replace(F.col("amount"), r"[^0-9.]", "").cast("decimal(12,2)").alias("amount"),
        F.when(ttype == "receita", "Income").when(ttype == "despesa", "Expense").alias("type"),
        F.initcap(F.trim(F.regexp_replace("description", r"\s+", " "))).alias("description"),
    )
    .filter(F.col("entry_date").isNotNull() & F.col("amount").isNotNull())   # drop bad rows
    .dropDuplicates())                                                       # dedupe

silver.write.mode("overwrite").option("overwriteSchema", "true").saveAsTable("silver_ledger")

# COMMAND ----------

display(spark.sql("SELECT type, count(*) AS n FROM silver_ledger GROUP BY type"))
display(spark.sql("SELECT category, count(*) AS n FROM silver_ledger GROUP BY category ORDER BY n DESC"))
