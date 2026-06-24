# Databricks notebook source
# MAGIC %md
# MAGIC # 05 · Métricas & Dashboard
# MAGIC
# MAGIC Consultamos o modelo estrela para responder perguntas de negócio e fixamos
# MAGIC os resultados em um **dashboard do Databricks SQL**.

# COMMAND ----------

CATALOG = "workspace"
SCHEMA  = "treino_financeiro"
spark.sql(f"USE CATALOG {CATALOG}")
spark.sql(f"USE SCHEMA {SCHEMA}")

# COMMAND ----------

# DBTITLE 1,KPI — total de receita, despesa & resultado líquido
display(spark.sql("""
SELECT
  sum(CASE WHEN tipo = 'Receita' THEN valor ELSE 0 END) AS total_receita,
  sum(CASE WHEN tipo = 'Despesa' THEN valor ELSE 0 END) AS total_despesa,
  sum(valor_sinalizado)                                 AS resultado_liquido
FROM fato_lancamentos
"""))

# COMMAND ----------

# DBTITLE 1,Resultado líquido por mês (linha de tendência)
display(spark.sql("""
SELECT d.ano, d.mes, d.nome_mes, sum(f.valor_sinalizado) AS resultado_liquido
FROM fato_lancamentos f
JOIN dim_data d ON f.sk_data = d.sk_data
GROUP BY d.ano, d.mes, d.nome_mes
ORDER BY d.ano, d.mes
"""))

# COMMAND ----------

# DBTITLE 1,Despesa por centro de custo (gráfico de barras)
display(spark.sql("""
SELECT cc.nome_centro_custo, sum(f.valor) AS total_despesa
FROM fato_lancamentos f
JOIN dim_centro_custo cc ON f.sk_centro_custo = cc.sk_centro_custo
WHERE f.tipo = 'Despesa'
GROUP BY cc.nome_centro_custo
ORDER BY total_despesa DESC
"""))

# COMMAND ----------

# DBTITLE 1,Maiores categorias de despesa
display(spark.sql("""
SELECT cat.nome_categoria, sum(f.valor) AS total_despesa, count(*) AS lancamentos
FROM fato_lancamentos f
JOIN dim_categoria cat ON f.sk_categoria = cat.sk_categoria
WHERE f.tipo = 'Despesa'
GROUP BY cat.nome_categoria
ORDER BY total_despesa DESC
LIMIT 10
"""))

# COMMAND ----------

# DBTITLE 1,Receita vs Despesa por mês (gráfico agrupado)
display(spark.sql("""
SELECT d.ano, d.mes, f.tipo, sum(f.valor) AS total
FROM fato_lancamentos f
JOIN dim_data d ON f.sk_data = d.sk_data
GROUP BY d.ano, d.mes, f.tipo
ORDER BY d.ano, d.mes, f.tipo
"""))

# COMMAND ----------

# MAGIC %md
# MAGIC ## 📊 Transforme isso num dashboard
# MAGIC
# MAGIC 1. **SQL → Dashboards → Create dashboard**.
# MAGIC 2. Crie um **dataset** por consulta acima (cole o SQL).
# MAGIC 3. Adicione visualizações: contadores KPI, uma **linha** para resultado por
# MAGIC    mês, **barras** para despesa por centro de custo e maiores categorias, uma
# MAGIC    **barra agrupada** para receita vs despesa.
# MAGIC 4. Adicione um **filtro** em `ano` / `nome_centro_custo` para interatividade.
# MAGIC
# MAGIC 🧩 **DESAFIO:** crie duas métricas suas — ex.: *despesa média por lançamento*,
# MAGIC *crescimento mês a mês*, ou *top 3 centros de custo por resultado*.
