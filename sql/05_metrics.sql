-- Databricks notebook source
-- MAGIC %md
-- MAGIC # 05 · Métricas & Dashboard
-- MAGIC
-- MAGIC Agora a recompensa: consultamos o modelo estrela para responder perguntas de
-- MAGIC negócio e depois fixamos os resultados em um **dashboard do Databricks SQL**.
-- MAGIC
-- MAGIC Repare como essas consultas ficam legíveis — esse é o *propósito* do modelo
-- MAGIC estrela: junte o fato às dimensões e faça `GROUP BY` em colunas em português.

-- COMMAND ----------

USE CATALOG workspace;
USE SCHEMA treino_financeiro;

-- COMMAND ----------

-- DBTITLE 1,KPI — total de receita, despesa & resultado líquido
SELECT
  sum(CASE WHEN tipo = 'Receita' THEN valor ELSE 0 END) AS total_receita,
  sum(CASE WHEN tipo = 'Despesa' THEN valor ELSE 0 END) AS total_despesa,
  sum(valor_sinalizado)                                 AS resultado_liquido
FROM fato_lancamentos;

-- COMMAND ----------

-- DBTITLE 1,Resultado líquido por mês (linha de tendência)
SELECT
  d.ano,
  d.mes,
  d.nome_mes,
  sum(f.valor_sinalizado) AS resultado_liquido
FROM fato_lancamentos f
JOIN dim_data d ON f.sk_data = d.sk_data
GROUP BY d.ano, d.mes, d.nome_mes
ORDER BY d.ano, d.mes;

-- COMMAND ----------

-- DBTITLE 1,Despesa por centro de custo (gráfico de barras)
SELECT
  cc.nome_centro_custo,
  sum(f.valor) AS total_despesa
FROM fato_lancamentos f
JOIN dim_centro_custo cc ON f.sk_centro_custo = cc.sk_centro_custo
WHERE f.tipo = 'Despesa'
GROUP BY cc.nome_centro_custo
ORDER BY total_despesa DESC;

-- COMMAND ----------

-- DBTITLE 1,Maiores categorias de despesa
SELECT
  cat.nome_categoria,
  sum(f.valor) AS total_despesa,
  count(*)     AS lancamentos
FROM fato_lancamentos f
JOIN dim_categoria cat ON f.sk_categoria = cat.sk_categoria
WHERE f.tipo = 'Despesa'
GROUP BY cat.nome_categoria
ORDER BY total_despesa DESC
LIMIT 10;

-- COMMAND ----------

-- DBTITLE 1,Receita vs Despesa por mês (gráfico agrupado)
SELECT
  d.ano,
  d.mes,
  f.tipo,
  sum(f.valor) AS total
FROM fato_lancamentos f
JOIN dim_data d ON f.sk_data = d.sk_data
GROUP BY d.ano, d.mes, f.tipo
ORDER BY d.ano, d.mes, f.tipo;

-- COMMAND ----------

-- MAGIC %md
-- MAGIC ## Transforme isso num dashboard
-- MAGIC
-- MAGIC 1. Abra **SQL → Dashboards → Create dashboard** (Databricks SQL).
-- MAGIC 2. Crie um **dataset** para cada consulta acima (cole o SQL).
-- MAGIC 3. Adicione as visualizações na tela:
-- MAGIC    - Contadores **KPI** para *total receita / despesa / resultado líquido*.
-- MAGIC    - Gráfico de **linha** para *resultado líquido por mês*.
-- MAGIC    - Gráfico de **barras** para *despesa por centro de custo*.
-- MAGIC    - Gráfico de **barras** para *maiores categorias de despesa*.
-- MAGIC    - **Barra agrupada** para *receita vs despesa por mês*.
-- MAGIC 4. Adicione um **filtro** em `ano` / `nome_centro_custo` para deixar interativo.
-- MAGIC
-- MAGIC **DESAFIO:** crie mais duas métricas suas — ex.: *despesa média por
-- MAGIC lançamento*, *crescimento mês a mês*, ou *top 3 centros de custo por resultado*.
