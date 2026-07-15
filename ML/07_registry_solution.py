# Databricks notebook source
# MAGIC %md
# MAGIC # 07 · Registry — SOLUÇÃO
# MAGIC **Não versionar no Git da turma.**

# COMMAND ----------

import mlflow
from mlflow.models import infer_signature
from mlflow import MlflowClient
import pandas as pd
from sklearn.linear_model import LogisticRegression

mlflow.set_registry_uri('databricks-uc')

FEATURES = ['score_bureau', 'atrasos_previos', 'comprometimento',
            'renda_log', 'relacionamento_anos', 'canal_app',
            'canal_web', 'tem_atraso']
NOME_MODELO = 'workspace.treino_ml.modelo_inadimplencia'

treino = spark.table('workspace.treino_ml.features_treino').toPandas()
X_treino, y_treino = treino[FEATURES], treino['inadimplente']
campeao = LogisticRegression(max_iter=1000).fit(X_treino, y_treino)

# COMMAND ----------

# DESAFIO 1 — log + registro com signature
assinatura = infer_signature(X_treino,
                             campeao.predict_proba(X_treino)[:, 1])

with mlflow.start_run(run_name='registro_champion'):
    mlflow.sklearn.log_model(
        campeao,
        name='modelo',
        signature=assinatura,
        input_example=X_treino.head(3),
        registered_model_name=NOME_MODELO,
    )

# COMMAND ----------

# DESAFIO 2 — alias @champion na última versão
client = MlflowClient()
ultima = max(int(v.version) for v in client.search_model_versions(
    f"name = '{NOME_MODELO}'"))
client.set_registered_model_alias(NOME_MODELO, 'champion', ultima)
print(f'@champion -> versão {ultima}')

# COMMAND ----------

# DESAFIO 3 — consumo pelo alias
uri = f'models:/{NOME_MODELO}@champion'
modelo_prod = mlflow.sklearn.load_model(uri)

teste = spark.table('workspace.treino_ml.features_teste').toPandas()
amostra = teste.head(5)
amostra['proba'] = modelo_prod.predict_proba(amostra[FEATURES])[:, 1].round(4)
amostra[['cliente_id', 'score_bureau', 'proba', 'inadimplente']]

# COMMAND ----------

# DESAFIO 4 — respostas esperadas:
# 1. Lineage: features_treino (e, por transitividade, gold_treino/silver).
# 2. Permissão: EXECUTE no modelo (+ USE SCHEMA / USE CATALOG no caminho).
#    Ex.: GRANT EXECUTE ON MODEL workspace.treino_ml.modelo_inadimplencia TO `grupo`;
# 3. Métricas na página da versão do modelo no Catalog Explorer (MLflow 3
#    grava params/metrics no Logged Model, visíveis no UC).

# COMMAND ----------

# MAGIC %md
# MAGIC ## Notas para condução
# MAGIC - **Se der erro de permissão no registro:** o aluno precisa de
# MAGIC   CREATE MODEL no schema — no Free Edition, no schema próprio funciona;
# MAGIC   se a turma compartilha o `treino_ml`, combine sufixo no nome do modelo
# MAGIC   (ex.: `modelo_inadimplencia_iniciais`).
# MAGIC - **Rodar 2x o Desafio 1 cria v2** — ótimo! Use para mostrar o alias
# MAGIC   migrando de versão sem quebrar consumidor.
# MAGIC - **Ponto conceitual:** alias substitui os antigos stages
# MAGIC   (Staging/Production) do registry legado.
