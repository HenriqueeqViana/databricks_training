# Databricks notebook source
# MAGIC %md
# MAGIC # 08 · Inferência batch — o modelo vai trabalhar
# MAGIC
# MAGIC **Cenário:** chegaram **300 clientes novos** (sem rótulo — ninguém sabe
# MAGIC ainda quem vai pagar). O pipeline: SQL monta as features com a MESMA
# MAGIC expressão da Aula 3 → o `@champion` pontua → as predições viram tabela →
# MAGIC o negócio consome em SQL.
# MAGIC
# MAGIC > Pré-requisito: notebook `07_registry` (@champion registrado).

# COMMAND ----------a

# MAGIC %md
# MAGIC ## Célula pronta — a carteira nova chegou (não altere)
# MAGIC Seed 99: a turma inteira gera a mesma carteira. Repare que ela é
# MAGIC *diferente* da base de treino — de propósito (a Aula 9 explica).

# COMMAND ----------

# MAGIC %python
# MAGIC import numpy as np
# MAGIC import pandas as pd
# MAGIC
# MAGIC r = np.random.default_rng(99)
# MAGIC m = 300
# MAGIC carteira = pd.DataFrame({
# MAGIC     'cliente_id': [f'N{i:04d}' for i in range(1, m + 1)],
# MAGIC     'idade': r.integers(18, 76, m),
# MAGIC     'renda_mensal': np.round(np.exp(r.normal(8.65, 0.5, m)), 2),
# MAGIC     'valor_emprestimo': 0.0,
# MAGIC     'prazo_meses': r.choice([12, 24, 36, 48, 60], m),
# MAGIC     'score_bureau': np.round(np.clip(r.normal(540, 110, m), 300, 900), 0),
# MAGIC     'atrasos_previos': r.poisson(1.2, m),
# MAGIC     'tempo_relacionamento_meses': r.integers(1, 240, m),
# MAGIC     'canal': r.choice(['App', 'Web', 'Agencia'], m),
# MAGIC })
# MAGIC carteira['valor_emprestimo'] = np.round(
# MAGIC     carteira['renda_mensal'] * r.uniform(2, 12, m), 2)
# MAGIC
# MAGIC (spark.createDataFrame(carteira)
# MAGIC     .write.mode('overwrite')
# MAGIC     .saveAsTable('workspace.treino_ml.carteira_novos'))
# MAGIC print(f'{m} clientes novos gravados em carteira_novos')

# COMMAND ----------

# MAGIC %md
# MAGIC ## DESAFIO 1 (SQL) — features da carteira
# MAGIC A MESMA expressão da Aula 3 (é o ponto: treino = produção). Complete os
# MAGIC `___` — pode consultar seu notebook 03.
# MAGIC
# MAGIC **Antes de rodar — sua aposta:** o comprometimento médio dessa carteira
# MAGIC nova vai ser MAIOR, MENOR ou IGUAL ao do treino (~3.0)?
# MAGIC *Dica: pense em como o valor_emprestimo dessa carteira nova foi gerado
# MAGIC lá na célula pronta.*

# COMMAND ----------

# MAGIC %sql
# MAGIC -- Minha aposta: maior, menor ou igual ao treino?
# MAGIC -- ___

# COMMAND ----------

# MAGIC %sql
# MAGIC USE CATALOG workspace;
# MAGIC USE SCHEMA treino_ml;
# MAGIC
# MAGIC CREATE OR REPLACE TABLE features_carteira AS
# MAGIC SELECT
# MAGIC   cliente_id,
# MAGIC   score_bureau,
# MAGIC   atrasos_previos,
# MAGIC   round(valor_emprestimo / (renda_mensal * prazo_meses / 12), 4)
# MAGIC                                               AS comprometimento,
# MAGIC   round(___, 4)                               AS renda_log,
# MAGIC   round(___, 2)                               AS relacionamento_anos,
# MAGIC   CASE WHEN canal = '___' THEN 1 ELSE 0 END   AS canal_app,
# MAGIC   CASE WHEN canal = '___' THEN 1 ELSE 0 END   AS canal_web,
# MAGIC   CASE WHEN ___ > 0 THEN 1 ELSE 0 END         AS tem_atraso
# MAGIC FROM carteira_novos;

# COMMAND ----------

# MAGIC %sql
# MAGIC -- Confira sua aposta: comprometimento médio da carteira nova
# MAGIC SELECT round(avg(comprometimento), 2) AS comprometimento_medio
# MAGIC FROM features_carteira;

# COMMAND ----------

# MAGIC %md
# MAGIC ## DESAFIO 2 (Python) — carregue o @champion e pontue
# MAGIC Threshold da Aula 6: **0.2** → `revisar`; abaixo → `aprovar`.
# MAGIC
# MAGIC **Antes de rodar — sua aposta:** que fração da carteira você acha que
# MAGIC vai cair em `revisar`? Escreva um número de 0 a 100.
# MAGIC *Dica: no treino, a taxa de calote girava perto de 22%.*

# COMMAND ----------

# MAGIC %python
# MAGIC MINHA_APOSTA_REVISAR = ___  # % da carteira em 'revisar' — número de 0 a 100, ex: 30

# COMMAND ----------

# MAGIC %python
# MAGIC import mlflow
# MAGIC import numpy as np
# MAGIC mlflow.set_registry_uri('databricks-uc')
# MAGIC
# MAGIC FEATURES = ['score_bureau', 'atrasos_previos', 'comprometimento',
# MAGIC             'renda_log', 'relacionamento_anos', 'canal_app',
# MAGIC             'canal_web', 'tem_atraso']
# MAGIC
# MAGIC uri = 'models:/workspace.treino_ml.modelo_inadimplencia@___'   # TODO
# MAGIC modelo = mlflow.sklearn.load_model(uri)
# MAGIC
# MAGIC fc = spark.table('workspace.treino_ml.features_carteira').toPandas()
# MAGIC proba = modelo.___(fc[FEATURES])[:, 1]                          # TODO: predict_proba
# MAGIC
# MAGIC fc['proba'] = np.round(proba, 4)
# MAGIC fc['decisao'] = np.where(proba >= ___, 'revisar', 'aprovar')    # TODO: 0.2
# MAGIC fc['versao_modelo'] = 'champion'
# MAGIC fc['data_score'] = pd.Timestamp.today().normalize()
# MAGIC
# MAGIC (spark.createDataFrame(fc[['cliente_id', 'proba', 'decisao',
# MAGIC                            'versao_modelo', 'data_score']])
# MAGIC     .write.mode('overwrite')
# MAGIC     .saveAsTable('workspace.treino_ml.predicoes_carteira'))
# MAGIC print('predições gravadas')

# COMMAND ----------

# MAGIC %python
# MAGIC pct_revisar = (fc['decisao'] == 'revisar').mean() * 100
# MAGIC print(f'Sua aposta: {MINHA_APOSTA_REVISAR}%')
# MAGIC print(f'Percentual real em revisar: {pct_revisar:.1f}%')
# MAGIC print('Boa aposta!' if abs(MINHA_APOSTA_REVISAR - pct_revisar) <= 10
# MAGIC       else 'Ficou longe — a carteira nova surpreende. Guarde essa.')

# COMMAND ----------

# MAGIC %md
# MAGIC ## DESAFIO 3 (SQL) — o relatório que o negócio vai ler
# MAGIC Três perguntas, três queries. Complete os `___`.

# COMMAND ----------

# MAGIC %sql
# MAGIC -- 3a. Quantos em cada decisão, e o risco médio de cada grupo?
# MAGIC SELECT ___, count(*) AS clientes, round(avg(proba), 3) AS risco_medio
# MAGIC FROM predicoes_carteira
# MAGIC GROUP BY ___;

# COMMAND ----------

# MAGIC %md
# MAGIC **Antes de rodar — sua aposta:** qual canal você acha que vai ter o
# MAGIC MAIOR risco médio: App, Web ou Agência?

# COMMAND ----------

# MAGIC %sql
# MAGIC -- Minha aposta: qual canal tem o maior risco médio?
# MAGIC -- ___

# COMMAND ----------

# MAGIC %sql
# MAGIC -- 3b. Risco médio por canal (junte com carteira_novos)
# MAGIC SELECT c.canal, round(avg(p.proba), 3) AS risco_medio
# MAGIC FROM predicoes_carteira p
# MAGIC JOIN carteira_novos c ON p.___ = c.___
# MAGIC GROUP BY c.canal
# MAGIC ORDER BY risco_medio DESC;

# COMMAND ----------

# MAGIC %sql
# MAGIC -- 3c. Top 10 maiores riscos (para a mesa revisar primeiro)
# MAGIC SELECT cliente_id, proba, decisao
# MAGIC FROM predicoes_carteira
# MAGIC ORDER BY ___ DESC
# MAGIC LIMIT 10;

# COMMAND ----------

# MAGIC %md
# MAGIC ## Como saber se acertou
# MAGIC - [ ] `features_carteira`: **300** linhas, 9 colunas (sem alvo!)
# MAGIC - [ ] `predicoes_carteira`: 300 linhas com proba, decisão, versão e data
# MAGIC - [ ] ~**171** clientes em `revisar` (~57% — bem mais que no treino…
# MAGIC       suspeito, não? Guarde essa pulga atrás da orelha para a Aula 9)
# MAGIC - [ ] Risco médio geral ≈ **0.28**; canal **Web** com o maior risco médio
# MAGIC - [ ] Nenhuma query do Desafio 3 usa Python — o consumidor não precisa
# MAGIC
# MAGIC Travou? Levanta a mão. A resposta de referência fica com o instrutor.
