# Databricks notebook source
# MAGIC %md
# MAGIC # 05 · Modelos — SOLUÇÃO
# MAGIC **Não versionar no Git da turma.**

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

# DESAFIO 1 — esperado: logistica ~0.784 | floresta ~0.745
# Condução: fale a régua antes do código ("mesmas features, teste, métrica").
# Aponte só o `for` e o `run_name` — não leia o resto linha a linha.
# Aposta do aluno: MINHA_APOSTA_MODELO — qualquer valor funciona, é só
# comparado com `vencedor` depois. Sem gabarito fixo, é opinião do aluno.
MINHA_APOSTA_MODELO = 'floresta'  # exemplo — cada aluno escreve a própria

mlflow.autolog()

modelos = {
    'logistica': LogisticRegression(max_iter=1000),
    'floresta':  RandomForestClassifier(n_estimators=200, random_state=42),
}

resultados = {}
for nome, m in modelos.items():
    with mlflow.start_run(run_name=nome):
        m.fit(X_treino, y_treino)
        proba = m.predict_proba(X_teste)[:, 1]
        auc = roc_auc_score(y_teste, proba)
        mlflow.log_metric('auc_teste', auc)
        resultados[nome] = auc
        print(f'{nome}: AUC = {auc:.3f}')

vencedor = max(resultados, key=resultados.get)
print(f'Sua aposta: {MINHA_APOSTA_MODELO} | Vencedor real: {vencedor}')

# COMMAND ----------

# DESAFIO 2 — esperado top: score_bureau ~0.32 | comprometimento ~0.21 | renda_log ~0.19
# Condução: mostre o gráfico de barras, não a lista de números.
MINHA_APOSTA_FEATURE = 'renda_log'  # exemplo — cada aluno escreve a própria

floresta = modelos['floresta']
importancias = pd.DataFrame({
    'feature': FEATURES,
    'importancia': floresta.feature_importances_,
}).sort_values('importancia', ascending=False)

(spark.createDataFrame(importancias)
    .write.mode('overwrite')
    .saveAsTable('workspace.treino_ml.importancias_features'))
importancias

top_feature = importancias.iloc[0]['feature']
print(f'Sua aposta: {MINHA_APOSTA_FEATURE} | Feature real no topo: {top_feature}')

# COMMAND ----------

# DESAFIO 3 — score negativo (protege), atrasos positivo (piora)
# Condução: negativo = freio do risco; positivo = acelerador do risco.
MINHA_APOSTA_SINAL = 'positivo'  # exemplo — cada aluno escreve a própria

coefs = pd.DataFrame({
    'feature': FEATURES,
    'coeficiente': modelos['logistica'].coef_[0],
}).sort_values('coeficiente')
coefs

valor = coefs.loc[coefs['feature'] == 'score_bureau', 'coeficiente'].values[0]
sinal_real = 'negativo' if valor < 0 else 'positivo'
print(f'Sua aposta: {MINHA_APOSTA_SINAL} | Sinal real: {sinal_real}')

# COMMAND ----------

# DESAFIO 4 — predicoes_teste (185 linhas, risco médio ~0.222)
# Condução: reforce que é decisão pela métrica (AUC), não achismo.
# Fecha ligando com a Aula 6 (essa tabela alimenta a análise de negócio).
MINHA_APOSTA_LINHAS = 200  # exemplo — cada aluno escreve a própria

campeao = modelos['logistica']
proba_campeao = campeao.predict_proba(X_teste)[:, 1]
predicoes = pd.DataFrame({
    'cliente_id': teste['cliente_id'],
    'proba': np.round(proba_campeao, 4),
    'real': y_teste,
})
(spark.createDataFrame(predicoes)
    .write.mode('overwrite')
    .saveAsTable('workspace.treino_ml.predicoes_teste'))

print(f'Sua aposta: {MINHA_APOSTA_LINHAS} linhas | Total real: {len(predicoes)} linhas')

# COMMAND ----------

# MAGIC %md
# MAGIC ## Notas para condução
# MAGIC - **Apostas:** cada aluno preenche a própria `MINHA_APOSTA_*` antes de
# MAGIC   rodar a célula seguinte. Não precisa perguntar pra sala em voz alta —
# MAGIC   o "acertou/errou" já aparece no print de cada aluno.
# MAGIC - **Por que a floresta perdeu?** Dataset pequeno (726 linhas) e alvo quase
# MAGIC   linear nas features (foi gerado assim). Com interações reais e mais
# MAGIC   volume, a floresta costuma virar — provoque essa discussão.
# MAGIC - **Importância x coeficiente:** a floresta diz "quanto usei"; a
# MAGIC   logística diz "em que direção". As duas leituras se completam.
# MAGIC - **Guarde o objeto `campeao` na sessão** — a Aula 7 registra ele. Se a
# MAGIC   sessão reiniciar entre aulas, é só rodar este notebook de novo.
