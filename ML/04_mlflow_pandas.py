# Databricks notebook source
# MAGIC %md
# MAGIC # 04 · MLflow 3 — rastreando o primeiro modelo
# MAGIC
# MAGIC **Aqui entra o Python** — na medida certa. O SQL preparou tudo
# MAGIC (`features_treino` / `features_teste`); o Python só treina e o MLflow
# MAGIC anota tudo sozinho.
# MAGIC
# MAGIC ## Como este notebook funciona
# MAGIC O código vem quase pronto — os `TODO`s são pequenos e cirúrgicos.
# MAGIC Se você nunca escreveu Python, siga as dicas: é preencher lacunas.
# MAGIC
# MAGIC > Pré-requisito: notebook `03_features`.

# COMMAND ----------

import mlflow
import pandas as pd
from sklearn.linear_model import LogisticRegression
from sklearn.metrics import roc_auc_score

# COMMAND ----------

# MAGIC %md
# MAGIC ## Exemplo resolvido — do SQL para o Python
# MAGIC `spark.table()` lê a tabela do Unity Catalog; `.toPandas()` traz para a
# MAGIC memória. As features viram `X`; o alvo vira `y`.

# COMMAND ----------

FEATURES = ['score_bureau', 'atrasos_previos', 'comprometimento',
            'renda_log', 'relacionamento_anos', 'canal_app',
            'canal_web', 'tem_atraso']

treino = spark.table('workspace.treino_ml.features_treino').toPandas()
teste  = spark.table('workspace.treino_ml.features_teste').toPandas()

X_treino, y_treino = treino[FEATURES], treino['inadimplente']
X_teste,  y_teste  = teste[FEATURES],  teste['inadimplente']

print(X_treino.shape, X_teste.shape)   # (726, 8) (185, 8)

# COMMAND ----------

# MAGIC %md
# MAGIC ## DESAFIO 1 — ligue o autolog e treine
# MAGIC Duas lacunas: ativar o `mlflow.autolog()` e treinar com `.fit()`.
# MAGIC O autolog registra parâmetros, ambiente e o modelo — sem você pedir.

# COMMAND ----------

mlflow.___()          # TODO: autolog

with mlflow.start_run(run_name='logistica_baseline') as run:
    modelo = LogisticRegression(max_iter=1000)
    modelo.___(X_treino, y_treino)          # TODO: fit
    print('run_id:', run.info.run_id)

# COMMAND ----------

# MAGIC %md
# MAGIC ## DESAFIO 2 — meça no teste e logue a métrica
# MAGIC `predict_proba(...)[:, 1]` devolve a probabilidade de inadimplência.
# MAGIC O AUC compara essa ordenação com a realidade. Logue como `auc_teste`.

# COMMAND ----------

proba_teste = modelo.predict_proba(___)[:, 1]        # TODO: X_teste
auc = roc_auc_score(___, proba_teste)                # TODO: y_teste
print(f'AUC no teste: {auc:.3f}')

with mlflow.start_run(run_id=run.info.run_id):
    mlflow.log_metric('___', auc)                    # TODO: 'auc_teste'

# COMMAND ----------

# MAGIC %md
# MAGIC **Checkpoint:** AUC ≈ **0.78**. Interpretação: sorteando um bom e um mau
# MAGIC pagador, o modelo ordena certo ~78% das vezes (0.5 = moeda; 1.0 = oráculo).

# COMMAND ----------

# MAGIC %md
# MAGIC ## DESAFIO 3 — acurácia engana (prove em uma linha)
# MAGIC Calcule a acurácia do "modelo" que chuta 0 para todo mundo.
# MAGIC Dica: é simplesmente a proporção de bons pagadores no teste.

# COMMAND ----------

acuracia_chute = (y_teste == 0).___()    # TODO: mean
print(f'Chutar "ninguém dá calote" acerta {acuracia_chute:.1%}')

# COMMAND ----------

# MAGIC %md
# MAGIC ## DESAFIO 4 — explore a UI de experimentos
# MAGIC Sem código: no menu lateral, **Experiments** → abra o experimento deste
# MAGIC notebook e responda no chat da aula:
# MAGIC 1. Quais **parâmetros** o autolog registrou no seu run?
# MAGIC 2. Onde está a **signature** do modelo? (dica: aba *Artifacts* → `model/`)
# MAGIC 3. O AUC do colega do lado bateu com o seu? Por quê? (semente!)
# MAGIC
# MAGIC ## Como saber se acertou
# MAGIC - [ ] Run `logistica_baseline` visível na UI com parâmetros e modelo
# MAGIC - [ ] Métrica `auc_teste` ≈ 0.78 registrada no run
# MAGIC - [ ] Acurácia do chute ≈ **0.78** — quase igual ao AUC do modelo, e é
# MAGIC       exatamente por isso que acurácia NÃO é a métrica deste problema
# MAGIC - [ ] A turma inteira com o mesmo AUC (dado e seed idênticos)
