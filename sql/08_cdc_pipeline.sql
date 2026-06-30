-- Databricks notebook source
-- MAGIC %md
-- MAGIC # 08 · Desafio: Lakeflow Declarative Pipeline + CDC (AUTO CDC)
-- MAGIC
-- MAGIC **Cenário:** chega um *feed de mudanças* (insert/update/delete) e você precisa
-- MAGIC manter uma tabela sempre atualizada — sem reprocessar tudo, só aplicando o que
-- MAGIC mudou. Isso é **CDC** (Change Data Capture), e o Lakeflow faz com `AUTO CDC`.
-- MAGIC
-- MAGIC **Como rodar:** este arquivo é a fonte de um **Lakeflow Declarative Pipeline**
-- MAGIC (não rode célula a célula). No menu, crie um *Pipeline*, aponte para este
-- MAGIC notebook, defina o *target schema* = `treino_cdc` e clique em **Start**.
-- MAGIC Rode antes o notebook `07_cdc_setup` para criar o feed.
-- MAGIC
-- MAGIC > `AUTO CDC` é o nome novo do antigo `APPLY CHANGES INTO` — faz a mesma coisa.

-- COMMAND ----------

-- MAGIC %md
-- MAGIC ## 1) Fonte em streaming (pronto)
-- MAGIC Lemos o feed de mudanças como um **stream**. Em produção, no lugar desta
-- MAGIC tabela viria o conector do **Lakeflow Connect** capturando o Postgres.

-- COMMAND ----------

CREATE OR REFRESH STREAMING TABLE clientes_cdc_stream
COMMENT 'Feed de mudancas (CDC) lido como stream'
AS SELECT * FROM STREAM(treino_cdc.clientes_cdc);

-- COMMAND ----------

-- MAGIC %md
-- MAGIC ## 2) Sua vez — aplique o CDC (SCD tipo 1 = "estado atual")
-- MAGIC
-- MAGIC Complete os `___`. O `AUTO CDC` precisa saber:
-- MAGIC - **KEYS**: qual coluna identifica cada cliente (a chave).
-- MAGIC - **APPLY AS DELETE WHEN**: como reconhecer um evento de exclusão.
-- MAGIC - **SEQUENCE BY**: qual coluna diz a ordem dos eventos (pra não aplicar fora de ordem).
-- MAGIC - **SCD TYPE**: `1` mantém só o estado atual (sobrescreve).

-- COMMAND ----------

CREATE OR REFRESH STREAMING TABLE clientes_atual;

CREATE FLOW f_clientes_atual AS AUTO CDC INTO clientes_atual
FROM STREAM(clientes_cdc_stream)
KEYS (___)
APPLY AS DELETE WHEN ___
SEQUENCE BY ___
COLUMNS * EXCEPT (operacao, sequencia)
STORED AS SCD TYPE ___;

-- COMMAND ----------

-- MAGIC %md
-- MAGIC ## 3) Bônus — histórico (SCD tipo 2)
-- MAGIC SCD tipo 2 **guarda o histórico**: cada mudança vira uma nova versão da linha,
-- MAGIC com janelas de validade (`__START_AT` / `__END_AT`). Monte o mesmo `AUTO CDC`
-- MAGIC trocando `STORED AS SCD TYPE` para o tipo de histórico.

-- COMMAND ----------

CREATE OR REFRESH STREAMING TABLE clientes_historico;

CREATE FLOW f_clientes_historico AS AUTO CDC INTO clientes_historico
FROM STREAM(clientes_cdc_stream)
KEYS (___)
APPLY AS DELETE WHEN ___
SEQUENCE BY ___
COLUMNS * EXCEPT (operacao, sequencia)
STORED AS SCD TYPE ___;

-- COMMAND ----------

-- MAGIC %md
-- MAGIC ## Como saber se acertou
-- MAGIC
-- MAGIC Depois do pipeline rodar, consulte as tabelas (num notebook normal):
-- MAGIC
-- MAGIC `clientes_atual` deve ter **3 linhas** (estado final):
-- MAGIC - [ ] 101 Ana Souza — Araxá
-- MAGIC - [ ] 102 Bruno Lima — **Belo Horizonte** (update aplicado)
-- MAGIC - [ ] 104 Diego Ferreira — Curitiba
-- MAGIC - [ ] 103 Carla Mendes **não aparece** (delete aplicado)
-- MAGIC
-- MAGIC `clientes_historico` (SCD2) deve ter as **versões** do Bruno (Uberlândia e
-- MAGIC Belo Horizonte), a primeira já fechada (`__END_AT` preenchido).
-- MAGIC
-- MAGIC A resposta de referência fica com o instrutor.
