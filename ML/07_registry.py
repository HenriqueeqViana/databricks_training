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

# MAGIC %md
# MAGIC **Aposta:** antes de rodar, quantas colunas de **entrada** você acha
# MAGIC que essa assinatura vai ter? (dica: dá pra contar sem rodar nada)

# COMMAND ----------

aposta_colunas = ___   # TODO: seu palpite (um número)

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
# MAGIC **Confira sozinho:** rode a célula abaixo — se aparecer OK, o registro
# MAGIC deu certo (e você já sabe se acertou a aposta).

# COMMAND ----------

client = MlflowClient()
versoes = client.search_model_versions(f"name = '{NOME_MODELO}'")
assert len(versoes) >= 1, 'Nenhuma versão encontrada — confira o registered_model_name'
print(f'OK — {len(versoes)} versão(ões) registrada(s) em {NOME_MODELO}')
print(f'Assinatura tem {len(FEATURES)} colunas de entrada — sua aposta foi {aposta_colunas}?')

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
# MAGIC **Confira sozinho:**

# COMMAND ----------

mv = client.get_model_version_by_alias(NOME_MODELO, 'champion')
assert int(mv.version) == ultima, 'Alias não está apontando pra última versão'
print(f'OK — @champion aponta pra versão {mv.version}')

# COMMAND ----------

# MAGIC %md
# MAGIC ## DESAFIO 3 — carregue PELO ALIAS e pontue 5 clientes
# MAGIC Quem consome nunca escreve número de versão: usa a URI com `@champion`.
# MAGIC
# MAGIC **Aposta:** a probabilidade média desses 5 clientes vai ser **maior**,
# MAGIC **menor** ou **igual** a 22% (a taxa geral de inadimplência que vimos
# MAGIC lá na Aula 2)?

# COMMAND ----------

aposta_proba = '___'   # TODO: 'maior', 'menor' ou 'igual'

uri = f'models:/{NOME_MODELO}@___'          # TODO: champion
modelo_prod = mlflow.sklearn.load_model(uri)

teste = spark.table('workspace.treino_ml.features_teste').toPandas()
amostra = teste.head(5)
amostra['proba'] = modelo_prod.predict_proba(amostra[FEATURES])[:, 1].round(4)
print(f'Probabilidade média da amostra: {amostra["proba"].mean():.2%} '
      f'— sua aposta foi "{aposta_proba}"?')
amostra[['cliente_id', 'score_bureau', 'proba', 'inadimplente']]

# COMMAND ----------

# MAGIC %md
# MAGIC ## DESAFIO 4 — governança (sem código, no Catalog Explorer)
# MAGIC **Aposta antes de abrir:** a aba Lineage vai mostrar só a
# MAGIC `features_treino`, ou a cadeia inteira até a `bronze_clientes`?
# MAGIC
# MAGIC Na página do modelo no catálogo, encontre e responda:
# MAGIC 1. Aba **Lineage**: quais tabelas aparecem como origem do modelo?
# MAGIC 2. Aba **Permissions**: que privilégio um colega precisaria para
# MAGIC    carregar o modelo? (é o mesmo `GRANT` que vocês usam em tabela)
# MAGIC 3. Onde estão as **métricas** da versão 1? (MLflow 3 as mostra na
# MAGIC    própria página da versão)

# COMMAND ----------

dbutils.widgets.text('resposta_lineage', '', '1) Tabelas no Lineage')
dbutils.widgets.text('resposta_permissao', '', '2) Privilégio necessário')
dbutils.widgets.text('resposta_metricas', '', '3) Onde ficam as métricas')

# COMMAND ----------

# MAGIC %md
# MAGIC ## Como saber se acertou
# MAGIC - [ ] `modelo_inadimplencia` **v1** no Catalog Explorer, com signature
# MAGIC - [ ] Alias **@champion** apontando para a v1
# MAGIC - [ ] Os 5 clientes pontuados via URI `@champion` (sem número de versão)
# MAGIC - [ ] Você sabe dizer o que acontece com os consumidores quando o
# MAGIC       @champion mudar para a v2 (nada — esse é o ponto!)
# MAGIC
# MAGIC Travou? Levanta a mão. A resposta de referência fica com o instrutor.
