# Databricks notebook source
# MAGIC %md
# MAGIC # 07 · Model Registry no Unity Catalog
# MAGIC
# MAGIC **Cenário:** o campeão da Aula 5 vai virar um **ativo governado**:
# MAGIC registrado no Unity Catalog com nome de 3 níveis, versão, signature e o
# MAGIC alias `@champion` — que é como todo mundo vai consumi-lo daqui pra frente.
# MAGIC
# MAGIC > Pré-requisito: notebook `03_features`. (Retreinamos o campeão aqui em
# MAGIC > 10 linhas para o notebook ser autossuficiente.)

# COMMAND ----------

import mlflow
from mlflow.models import infer_signature
from mlflow import MlflowClient
import pandas as pd
from sklearn.linear_model import LogisticRegression

mlflow.set_registry_uri('databricks-uc')   # registry = Unity Catalog (padrão no MLflow 3)

FEATURES = ['score_bureau', 'atrasos_previos', 'comprometimento',
            'renda_log', 'relacionamento_anos', 'canal_app',
            'canal_web', 'tem_atraso']
NOME_MODELO = 'workspace.treino_ml.modelo_inadimplencia'

# COMMAND ----------

# célula pronta — retreina o campeão da Aula 5 (mesmos dados, mesma seed)
treino = spark.table('workspace.treino_ml.features_treino').toPandas()
X_treino, y_treino = treino[FEATURES], treino['inadimplente']
campeao = LogisticRegression(max_iter=1000).fit(X_treino, y_treino)
print('campeão retreinado')

# COMMAND ----------

# MAGIC %md
# MAGIC ## DESAFIO 1 — logue com signature e registre no UC
# MAGIC A **signature** é o contrato de entrada/saída (obrigatória no UC).
# MAGIC `infer_signature` deduz dela dos exemplos. O `registered_model_name`
# MAGIC registra direto no catálogo — repare no nome de **3 níveis**.

# COMMAND ----------

assinatura = infer_signature(X_treino,
                             campeao.predict_proba(X_treino)[:, 1])

with mlflow.start_run(run_name='registro_champion'):
    mlflow.sklearn.log_model(
        campeao,
        name='modelo',
        signature=___,                       # TODO: assinatura
        input_example=X_treino.head(3),
        registered_model_name=___,           # TODO: NOME_MODELO
    )

# COMMAND ----------

# MAGIC %md
# MAGIC **Checkpoint 1:** abra **Catalog → workspace → treino_ml → Models**:
# MAGIC o `modelo_inadimplencia` está lá, **versão 1**, com signature na página.

# COMMAND ----------

# MAGIC %md
# MAGIC ## DESAFIO 2 — aponte o alias @champion
# MAGIC O alias desacopla "quem consome" de "qual versão": promover = mover o
# MAGIC apontador. Use o `MlflowClient`.

# COMMAND ----------

client = MlflowClient()
ultima = max(int(v.version) for v in client.search_model_versions(
    f"name = '{NOME_MODELO}'"))

client.set_registered_model_alias(
    name=___,          # TODO: NOME_MODELO
    alias='___',       # TODO: 'champion'
    version=ultima,
)
print(f'@champion -> versão {ultima}')

# COMMAND ----------

# MAGIC %md
# MAGIC ## DESAFIO 3 — carregue PELO ALIAS e pontue 5 clientes
# MAGIC Quem consome nunca escreve número de versão: usa a URI com `@champion`.

# COMMAND ----------

uri = f'models:/{NOME_MODELO}@___'          # TODO: champion
modelo_prod = mlflow.sklearn.load_model(uri)

teste = spark.table('workspace.treino_ml.features_teste').toPandas()
amostra = teste.head(5)
amostra['proba'] = modelo_prod.predict_proba(amostra[FEATURES])[:, 1].round(4)
amostra[['cliente_id', 'score_bureau', 'proba', 'inadimplente']]

# COMMAND ----------

# MAGIC %md
# MAGIC ## DESAFIO 4 — governança (sem código, no Catalog Explorer)
# MAGIC Na página do modelo no catálogo, encontre e responda no chat da aula:
# MAGIC 1. Aba **Lineage**: quais tabelas aparecem como origem do modelo?
# MAGIC 2. Aba **Permissions**: que privilégio um colega precisaria para
# MAGIC    carregar o modelo? (é o mesmo `GRANT` que vocês usam em tabela)
# MAGIC 3. Onde estão as **métricas** da versão 1? (MLflow 3 as mostra na
# MAGIC    própria página da versão)
# MAGIC
# MAGIC ## Como saber se acertou
# MAGIC - [ ] `modelo_inadimplencia` **v1** no Catalog Explorer, com signature
# MAGIC - [ ] Alias **@champion** apontando para a v1
# MAGIC - [ ] Os 5 clientes pontuados via URI `@champion` (sem número de versão)
# MAGIC - [ ] Você sabe dizer o que acontece com os consumidores quando o
# MAGIC       @champion mudar para a v2 (nada — esse é o ponto!)
# MAGIC
# MAGIC Travou? Levanta a mão. A resposta de referência fica com o instrutor.
