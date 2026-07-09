# Databricks notebook source
# MAGIC %md
# MAGIC # 04 · MLflow — SOLUÇÃO
# MAGIC **Não versionar no Git da turma.**

# COMMAND ----------

import mlflow
import pandas as pd
from sklearn.linear_model import LogisticRegression
from sklearn.metrics import roc_auc_score

FEATURES = ['score_bureau', 'atrasos_previos', 'comprometimento',
            'renda_log', 'relacionamento_anos', 'canal_app',
            'canal_web', 'tem_atraso']

treino = spark.table('workspace.treino_ml.features_treino').toPandas()
teste  = spark.table('workspace.treino_ml.features_teste').toPandas()
X_treino, y_treino = treino[FEATURES], treino['inadimplente']
X_teste,  y_teste  = teste[FEATURES],  teste['inadimplente']

# COMMAND ----------

# DESAFIO 1
mlflow.autolog()

with mlflow.start_run(run_name='logistica_baseline') as run:
    modelo = LogisticRegression(max_iter=1000)
    modelo.fit(X_treino, y_treino)
    print('run_id:', run.info.run_id)

# COMMAND ----------

# DESAFIO 2 — esperado: AUC ~0.784 (pode variar centésimos com a versão do sklearn)
proba_teste = modelo.predict_proba(X_teste)[:, 1]
auc = roc_auc_score(y_teste, proba_teste)
print(f'AUC no teste: {auc:.3f}')

with mlflow.start_run(run_id=run.info.run_id):
    mlflow.log_metric('auc_teste', auc)

# COMMAND ----------

# DESAFIO 3 — esperado: 0.778 (1 - 0.222)
acuracia_chute = (y_teste == 0).mean()
print(f'Chutar "ninguém dá calote" acerta {acuracia_chute:.1%}')

# COMMAND ----------

# MAGIC %md
# MAGIC ## Notas para condução
# MAGIC - **Momento chave da aula:** acurácia do chute (0.778) ≈ AUC do modelo
# MAGIC   (0.784) parecem "iguais" mas medem coisas diferentes — acurácia olha o
# MAGIC   rótulo cortado em 0.5, AUC olha a ORDENAÇÃO. Volta na Aula 6.
# MAGIC - **Autolog:** mostre na UI o que ele registrou sem ninguém pedir:
# MAGIC   solver, max_iter, C, o conda.yaml e a signature inferida.
# MAGIC - **Se o AUC variar entre alunos:** versão do sklearn diferente no
# MAGIC   ambiente serverless — diferença de centésimos é esperada; use ~0.78.
# MAGIC - **Free Edition:** o experimento fica em Workspace > Experiments; o
# MAGIC   registro em UC entra só na Aula 7.
