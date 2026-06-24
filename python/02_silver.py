# Databricks notebook source
# MAGIC %md
# MAGIC # 02 · Silver — limpar & padronizar
# MAGIC
# MAGIC Silver = dado limpo, tipado e confiável. Número vira número, data vira data,
# MAGIC texto padronizado, categorias unificadas, duplicados/linhas ruins removidos.
# MAGIC
# MAGIC ## Como este notebook funciona
# MAGIC A coluna **`valor`** já está pronta como exemplo resolvido. Cada outra coluna
# MAGIC tem um `DESAFIO` com um `TODO`. Preencha e grave a tabela.
# MAGIC A resposta de referência fica com o instrutor.

# COMMAND ----------

from pyspark.sql import functions as F

CATALOG = "workspace"
SCHEMA  = "treino_financeiro"
spark.sql(f"USE CATALOG {CATALOG}")
spark.sql(f"USE SCHEMA {SCHEMA}")

bronze = spark.table("bronze_lancamentos")

# COMMAND ----------

# MAGIC %md
# MAGIC ## Exemplo resolvido — limpando `valor`
# MAGIC
# MAGIC Valores brutos vêm como `R$ 6,273.32`, `5622.22`, `  4,233.82 `, `R$13446.67`.
# MAGIC Os únicos caracteres que importam são **dígitos e o ponto decimal**, então
# MAGIC removemos o resto com um regex e fazemos cast para `decimal`.

# COMMAND ----------

valor_limpo = F.regexp_replace(F.col("valor"), r"[^0-9.]", "").cast("decimal(12,2)")
display(bronze.select(
    F.col("valor").alias("valor_bruto"),
    valor_limpo.alias("valor_limpo"),
).limit(15))

# COMMAND ----------

# MAGIC %md
# MAGIC ## Monte o DataFrame silver completo
# MAGIC Substitua cada expressão `TODO`. A coluna `valor` é o seu modelo.

# COMMAND ----------

silver = bronze.select(
    F.trim("id_lancamento").alias("id_lancamento"),

    # DESAFIO 1 — data_lancamento: converta 'yyyy-MM-dd' E 'dd/MM/yyyy' para date.
    # Dica: F.coalesce(F.to_date("data_lancamento","yyyy-MM-dd"),
    #                  F.to_date("data_lancamento","dd/MM/yyyy"))
    F.lit(None).cast("date").alias("data_lancamento"),                 # TODO

    # DESAFIO 2 — centro_custo: trim + Iniciais Maiúsculas. Dica: F.initcap(F.trim(...))
    F.lit("TODO").alias("centro_custo"),                               # TODO

    # DESAFIO 3 — categoria: mapeie as variantes -> UM rótulo padronizado.
    # Dica: monte cat = F.lower(F.trim("categoria")) e encadeie
    #   F.when(cat.isin("software","licencas","licenças"), "Software")
    #    .when(cat.isin("impostos","tributos"), "Impostos")
    #    ... descubra as variantes com:
    #        spark.sql("SELECT DISTINCT lower(trim(categoria)) FROM bronze_lancamentos ORDER BY 1").show(50) ...
    #    .when((cat == "") | cat.isNull(), "Sem Categoria")
    F.lit("TODO").alias("categoria"),                                  # TODO

    # EXEMPLO RESOLVIDO — valor (pronto para você)
    F.regexp_replace(F.col("valor"), r"[^0-9.]", "").cast("decimal(12,2)").alias("valor"),

    # DESAFIO 4 — tipo: normalize a caixa para Receita/Despesa.
    # Dica: t = F.lower(F.trim("tipo"));  F.when(t=="receita","Receita").when(t=="despesa","Despesa")
    F.lit("TODO").alias("tipo"),                                       # TODO

    # DESAFIO 5 — descricao: junte espaços + Iniciais Maiúsculas.
    # Dica: F.initcap(F.trim(F.regexp_replace("descricao", r"\s+", " ")))
    F.lit("TODO").alias("descricao"),
)

# DESAFIO 6 — descarte linhas inutilizáveis (sem data ou sem valor):
# silver = silver.filter(F.col("data_lancamento").isNotNull() & F.col("valor").isNotNull())

# DESAFIO 7 — remova duplicatas exatas:
# silver = silver.dropDuplicates()

silver.write.mode("overwrite").option("overwriteSchema", "true").saveAsTable("silver_lancamentos")

# COMMAND ----------

# DBTITLE 1,Valide sua tabela silver
display(spark.sql("""
SELECT
  count(*)                                                  AS linhas,
  count(DISTINCT id_lancamento)                             AS ids_distintos,
  sum(CASE WHEN data_lancamento IS NULL THEN 1 ELSE 0 END)  AS datas_nulas,
  sum(CASE WHEN valor IS NULL THEN 1 ELSE 0 END)            AS valores_nulos,
  count(DISTINCT tipo)                                      AS tipos_distintos
FROM silver_lancamentos
"""))

# COMMAND ----------

display(spark.sql("SELECT tipo, count(*) AS n FROM silver_lancamentos GROUP BY tipo"))
display(spark.sql("SELECT categoria, count(*) AS n FROM silver_lancamentos GROUP BY categoria ORDER BY n DESC"))
