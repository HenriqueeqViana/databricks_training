# Databricks notebook source
# MAGIC %md
# MAGIC # 04 · MLflow 3 — rastreando o primeiro modelo (Spark ML)
# MAGIC
# MAGIC **Aqui entra o Python** — na medida certa. O SQL preparou tudo
# MAGIC (`features_treino` / `features_teste`); o Python só treina e o MLflow
# MAGIC anota tudo sozinho.
# MAGIC
# MAGIC Usamos o **Spark ML**: o dado nunca sai do Spark — o mesmo código que
# MAGIC treina com 726 linhas treinaria com 726 milhões.
# MAGIC
# MAGIC ## Como este notebook funciona
# MAGIC O código vem quase pronto — os `TODO`s são pequenos e cirúrgicos.
# MAGIC Se você nunca escreveu Python, siga as dicas: é preencher lacunas.
# MAGIC
# MAGIC > Pré-requisito: notebook `03_features`.

# COMMAND ----------

import mlflow
from pyspark.ml.feature import VectorAssembler
from pyspark.ml.classification import LogisticRegression
from pyspark.ml.evaluation import BinaryClassificationEvaluator

# COMMAND ----------

# MAGIC %md
# MAGIC ## Exemplo resolvido — do SQL para o Spark ML
# MAGIC `spark.table()` lê a tabela do Unity Catalog — e ela **continua sendo um
# MAGIC DataFrame Spark** (nada de trazer para a memória).
# MAGIC
# MAGIC A única exigência do Spark ML: as features precisam estar **empacotadas
# MAGIC numa coluna única** do tipo vetor. Quem faz isso é o `VectorAssembler` —
# MAGIC pense nele como um `SELECT` que junta 8 colunas em 1.

# COMMAND ----------

FEATURES = ['score_bureau', 'atrasos_previos', 'comprometimento',
            'renda_log', 'relacionamento_anos', 'canal_app',
            'canal_web', 'tem_atraso']

treino = spark.table('workspace.treino_ml.features_treino')
teste  = spark.table('workspace.treino_ml.features_teste')

montador = VectorAssembler(inputCols=FEATURES, outputCol='features')
treino_ml = montador.transform(treino)
teste_ml  = montador.transform(teste)

print(treino_ml.count(), teste_ml.count())   # 726 185
display(treino_ml.select('cliente_id', 'features', 'inadimplente').limit(5))

# COMMAND ----------

# MAGIC %md
# MAGIC ## DESAFIO 1 — ligue o autolog e treine
# MAGIC Duas lacunas: ativar o `mlflow.pyspark.ml.autolog()` e treinar com
# MAGIC `.fit()`. O autolog registra parâmetros, ambiente e o modelo — sem pedir.

# COMMAND ----------

mlflow.pyspark.ml.___()          # TODO: autolog

with mlflow.start_run(run_name='logistica_baseline') as run:
    lr = LogisticRegression(featuresCol='features',
                            labelCol='inadimplente',
                            maxIter=100)
    modelo = lr.___(treino_ml)               # TODO: fit
    print('run_id:', run.info.run_id)

# COMMAND ----------

# MAGIC %md
# MAGIC ## DESAFIO 2 — meça no teste e logue a métrica
# MAGIC No Spark ML, `modelo.transform(teste_ml)` adiciona as colunas de
# MAGIC predição (`probability`, `prediction`) ao DataFrame. O
# MAGIC `BinaryClassificationEvaluator` calcula o AUC comparando a
# MAGIC probabilidade com a realidade. Logue como `auc_teste`.

# COMMAND ----------

predicoes = modelo.transform(___)                    # TODO: teste_ml

avaliador = BinaryClassificationEvaluator(
    labelCol='inadimplente',
    metricName='areaUnderROC')

auc = avaliador.evaluate(___)                        # TODO: predicoes
print(f'AUC no teste: {auc:.3f}')

with mlflow.start_run(run_id=run.info.run_id):
    mlflow.log_metric('___', auc)                    # TODO: 'auc_teste'

# COMMAND ----------

# MAGIC %md
# MAGIC **Checkpoint:** AUC ≈ **0.78**. Interpretação: sorteando um bom e um mau
# MAGIC pagador, o modelo ordena certo ~78% das vezes (0.5 = moeda; 1.0 = oráculo).

# COMMAND ----------

# MAGIC %md
# MAGIC ## DESAFIO 3 — acurácia engana (prove em uma query)
# MAGIC Calcule a acurácia do "modelo" que chuta 0 para todo mundo.
# MAGIC Dica: é simplesmente a proporção de bons pagadores no teste — e isso é
# MAGIC um `avg` que você já sabe fazer desde a Aula 1.

# COMMAND ----------

# MAGIC %sql
# MAGIC SELECT round(avg(CASE WHEN inadimplente = ___ THEN 1 ELSE 0 END), 3)
# MAGIC          AS acuracia_do_chute
# MAGIC FROM workspace.treino_ml.features_teste;

# COMMAND ----------

# MAGIC %md
# MAGIC ## DESAFIO 4 — explore a UI de experimentos
# MAGIC Sem código: no menu lateral, **Experiments** → abra o experimento deste
# MAGIC notebook e responda no chat da aula:
# MAGIC 1. Quais **parâmetros** o autolog registrou no seu run? (maxIter,
# MAGIC    regParam, elasticNetParam...)
# MAGIC 2. Onde está o **modelo** salvo? (aba *Artifacts* → `model/`)
# MAGIC 3. O AUC do colega do lado bateu com o seu? Por quê? (semente!)
# MAGIC
# MAGIC ## Como saber se acertou
# MAGIC - [ ] Run `logistica_baseline` visível na UI com parâmetros e modelo
# MAGIC - [ ] Métrica `auc_teste` ≈ 0.78 registrada no run
# MAGIC - [ ] Acurácia do chute = **0.778** — quase igual ao AUC do modelo, e é
# MAGIC       exatamente por isso que acurácia NÃO é a métrica deste problema
# MAGIC - [ ] A turma inteira com o mesmo AUC (dado e seed idênticos)