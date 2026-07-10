# Databricks notebook source
# MAGIC %md
# MAGIC # 05 · Modelos — logística vs floresta
# MAGIC
# MAGIC **Cenário:** treinar dois modelos com a MESMA régua (mesmas features,
# MAGIC mesmo teste, mesma métrica), comparar na UI do MLflow, interpretar o que
# MAGIC cada um aprendeu — e salvar as predições do campeão para a Aula 6.
# MAGIC
# MAGIC > Pré-requisito: notebook `03_features` (o 04 ajuda, mas não é obrigatório).

# COMMAND ----------

import mlflow
import pandas as pd
import numpy as np
from sklearn.linear_model import LogisticRegression
from sklearn.ensemble import RandomForestClassifier
from sklearn.metrics import roc_auc_score

FEATURES = ['score_bureau', 'atrasos_previos', 'comprometimento',
            'renda_log', 'relacionamento_anos', 'canal_app',
            'canal_web', 'tem_atraso']

treino = spark.table('workspace.treino_ml.features_treino').toPandas()
teste  = spark.table('workspace.treino_ml.features_teste').toPandas()
X_treino, y_treino = treino[FEATURES], treino['inadimplente']
X_teste,  y_teste  = teste[FEATURES],  teste['inadimplente']

# COMMAND ----------

# MAGIC %md
# MAGIC ## DESAFIO 1 — um run para cada modelo
# MAGIC O dicionário define os concorrentes; o loop treina cada um num run
# MAGIC nomeado e loga o AUC do teste. Complete os 3 TODOs.
# MAGIC
# MAGIC **Antes de rodar — sua aposta:** qual modelo você acha que vence no AUC?

# COMMAND ----------

MINHA_APOSTA_MODELO = "___"  # escreva 'logistica' ou 'floresta'

# COMMAND ----------

mlflow.autolog()

modelos = {
    'logistica': LogisticRegression(max_iter=1000),
    'floresta':  RandomForestClassifier(n_estimators=200, random_state=42),
}

resultados = {}
for nome, m in modelos.items():
    with mlflow.start_run(run_name=___):                 # TODO: nome
        m.fit(___, ___)                                  # TODO: X_treino, y_treino
        proba = m.predict_proba(X_teste)[:, 1]
        auc = roc_auc_score(y_teste, proba)
        mlflow.log_metric('auc_teste', ___)              # TODO: auc
        resultados[nome] = auc
        print(f'{nome}: AUC = {auc:.3f}')

# COMMAND ----------

vencedor = max(resultados, key=resultados.get)
print(f'Sua aposta: {MINHA_APOSTA_MODELO}')
print(f'Vencedor real: {vencedor} (AUC = {resultados[vencedor]:.3f})')
print('Acertou!' if MINHA_APOSTA_MODELO == vencedor else 'Errou essa — bora ver o porquê.')

# COMMAND ----------

# MAGIC %md
# MAGIC **Checkpoint 1:** logística ≈ **0.78**, floresta ≈ **0.75**. O modelo
# MAGIC simples vence — acontece mais do que se imagina, e é por isso que
# MAGIC baseline simples é obrigatório.

# COMMAND ----------

# MAGIC %md
# MAGIC ## DESAFIO 2 — o que a floresta acha importante
# MAGIC `feature_importances_` diz quanto cada feature pesou. Monte o DataFrame,
# MAGIC ordene do maior para o menor e grave como tabela para consultar em SQL.
# MAGIC
# MAGIC **Antes de rodar — sua aposta:** qual das 8 features fica no topo?
# MAGIC (score_bureau, atrasos_previos, comprometimento, renda_log,
# MAGIC relacionamento_anos, canal_app, canal_web, tem_atraso)

# COMMAND ----------

MINHA_APOSTA_FEATURE = "___"  # escreva o nome exato de uma das 8 features

# COMMAND ----------

floresta = modelos['floresta']
importancias = pd.DataFrame({
    'feature': FEATURES,
    'importancia': floresta.___,                          # TODO: feature_importances_
}).sort_values('importancia', ascending=___)              # TODO: False

(spark.createDataFrame(importancias)
    .write.mode('overwrite')
    .saveAsTable('workspace.treino_ml.importancias_features'))

importancias

# COMMAND ----------

top_feature = importancias.iloc[0]['feature']
print(f'Sua aposta: {MINHA_APOSTA_FEATURE}')
print(f'Feature real no topo: {top_feature}')
print('Acertou!' if MINHA_APOSTA_FEATURE == top_feature else 'Errou essa — bora ver o porquê.')

# COMMAND ----------

# MAGIC %md
# MAGIC **Checkpoint 2:** `score_bureau` (~0.32) e `comprometimento` (~0.21) no
# MAGIC topo — exatamente o que a correlação da Aula 1 sugeria.

# COMMAND ----------

# MAGIC %md
# MAGIC ## DESAFIO 3 — e a logística, o que ela "pensa"?
# MAGIC Na logística a história está nos **coeficientes**: sinal negativo = reduz
# MAGIC o risco; positivo = aumenta. Monte a tabela.
# MAGIC
# MAGIC **Antes de rodar — sua aposta:** o coeficiente de `score_bureau` é
# MAGIC positivo ou negativo?

# COMMAND ----------

MINHA_APOSTA_SINAL = "___"  # escreva 'positivo' ou 'negativo'

# COMMAND ----------

coefs = pd.DataFrame({
    'feature': FEATURES,
    'coeficiente': modelos['logistica'].___[0],           # TODO: coef_
}).sort_values('coeficiente')
coefs

# COMMAND ----------

valor = coefs.loc[coefs['feature'] == 'score_bureau', 'coeficiente'].values[0]
sinal_real = 'negativo' if valor < 0 else 'positivo'
print(f'Sua aposta: {MINHA_APOSTA_SINAL}')
print(f'Sinal real de score_bureau: {sinal_real} ({valor:.3f})')
print('Acertou!' if MINHA_APOSTA_SINAL == sinal_real else 'Errou essa — bora ver o porquê.')

# COMMAND ----------

# MAGIC %md
# MAGIC **Checkpoint 3:** `score_bureau` com coeficiente **negativo** (score alto
# MAGIC protege) e `atrasos_previos` **positivo** (atraso passado aumenta o risco).

# COMMAND ----------

# MAGIC %md
# MAGIC ## DESAFIO 4 — salve as predições do campeão
# MAGIC A logística venceu. Grave `cliente_id`, a probabilidade e o valor real em
# MAGIC `predicoes_teste` — a Aula 6 faz a análise de negócio em SQL sobre ela.
# MAGIC
# MAGIC **Antes de rodar — sua aposta:** quantas linhas essa tabela final vai ter?

# COMMAND ----------

MINHA_APOSTA_LINHAS = "___"  # escreva um número inteiro

# COMMAND ----------

campeao = modelos['___']                                  # TODO: 'logistica'
proba_campeao = campeao.predict_proba(X_teste)[:, 1]

predicoes = pd.DataFrame({
    'cliente_id': teste['cliente_id'],
    'proba': np.round(proba_campeao, 4),
    'real': y_teste,
})

(spark.createDataFrame(predicoes)
    .write.mode('overwrite')
    .saveAsTable('workspace.treino_ml.___'))              # TODO: 'predicoes_teste'

# COMMAND ----------

print(f'Sua aposta: {MINHA_APOSTA_LINHAS} linhas')
print(f'Total real: {len(predicoes)} linhas')
print('Acertou!' if MINHA_APOSTA_LINHAS == len(predicoes) else 'Errou essa — bora ver o porquê.')

# COMMAND ----------

# MAGIC %sql
# MAGIC SELECT count(*)              AS linhas,
# MAGIC        round(avg(proba), 3)  AS risco_medio,
# MAGIC        round(avg(real), 3)   AS taxa_real
# MAGIC FROM workspace.treino_ml.predicoes_teste;

# COMMAND ----------

# MAGIC %md
# MAGIC ## Como saber se acertou
# MAGIC - [ ] Dois runs na UI: `logistica` e `floresta`, com `auc_teste` em cada
# MAGIC - [ ] AUC ≈ 0.78 vs ≈ 0.75 — logística campeã
# MAGIC - [ ] `importancias_features`: score_bureau no topo (~0.32)
# MAGIC - [ ] Coeficiente do score negativo; o de atrasos positivo
# MAGIC - [ ] `predicoes_teste`: **185** linhas, risco médio ≈ **0.22**
# MAGIC
# MAGIC Travou? Levanta a mão. A resposta de referência fica com o instrutor.
