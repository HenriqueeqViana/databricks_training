-- Databricks notebook source
-- MAGIC %md
-- MAGIC # Delta Live Tables — Desafio
-- MAGIC
-- MAGIC Hoje o **DLT** se chama oficialmente **Lakeflow Declarative Pipelines**, mas a ideia é a mesma: você **declara** o resultado de cada tabela e o Databricks cuida da execução, das dependências e da qualidade dos dados.
-- MAGIC
-- MAGIC Neste desafio você vai montar um pipeline completo — **Bronze → Silver → Gold** — para os pedidos de uma cafeteria. Os dados já vêm prontos neste notebook.

-- COMMAND ----------

USE CATALOG workspace;
USE SCHEMA treino_dlt;

-- COMMAND ----------

-- MAGIC %md
-- MAGIC ## Passo 0 · Dados de exemplo (pronto)
-- MAGIC
-- MAGIC Pedidos de uma cafeteria fictícia: produto, categoria, quantidade, preço e data. Como pipelines só aceitam `MATERIALIZED VIEW`, `STREAMING TABLE` ou `VIEW` como statements, declaramos essa origem como uma `MATERIALIZED VIEW` — em um cenário real seria um arquivo chegando em um volume ou uma tabela de outro sistema.

-- COMMAND ----------

CREATE OR REFRESH MATERIALIZED VIEW pedidos_origem AS
SELECT * FROM (VALUES
  (1,  'Espresso',     'Bebida', 2,  8.50,  DATE'2026-06-01'),
  (2,  'Latte',        'Bebida', 1,  12.00, DATE'2026-06-01'),
  (3,  'Croissant',    'Comida', 3,  9.00,  DATE'2026-06-01'),
  (4,  'Cappuccino',   'Bebida', 0,  11.00, DATE'2026-06-02'),
  (5,  'Pão de Queijo','Comida', 4,  6.50,  DATE'2026-06-02'),
  (6,  'Espresso',     'Bebida', 3,  8.50,  DATE'2026-06-02'),
  (7,  'Suco Natural', 'Bebida', -1, 10.00, DATE'2026-06-02'),
  (8,  'Bolo de Cenoura','Comida', 2, 13.00, DATE'2026-06-03'),
  (9,  'Latte',        'Bebida', 2,  12.00, DATE'2026-06-03'),
  (10, 'Croissant',    'Comida', 1,  9.00,  DATE'2026-06-03'),
  (11, 'Cappuccino',   'Bebida', 2,  11.00, DATE'2026-06-03'),
  (12, 'Pão de Queijo','Comida', 5,  6.50,  DATE'2026-06-04')
) AS t(id_pedido, produto, categoria, quantidade, preco_unitario, data_pedido);

-- COMMAND ----------

-- MAGIC %md
-- MAGIC ## Passo 1 · Bronze — ingestão bruta
-- MAGIC
-- MAGIC A camada **bronze** não transforma nada — ela só declara a origem dos dados, lida de forma incremental com `STREAM`.
-- MAGIC
-- MAGIC **Atenção:** o código abaixo tem um erro de digitação proposital e vai falhar ao rodar. Rode o pipeline, abra o **grafo** e clique no nó vermelho — a mensagem de erro aponta exatamente onde está o problema. Conserte antes de seguir para os próximos passos.

-- COMMAND ----------

CREATE OR REFRESH STREAMING TABLE pedidos_bronze
COMMENT "Ingestão bruta dos pedidos, sem transformação."
AS SELECT * FROM STREAM(pedidos_origen);

-- COMMAND ----------

-- MAGIC %md
-- MAGIC **Checkpoint:** depois de corrigir o bug e rodar de novo, `pedidos_bronze` deve ter **12 linhas** (o mesmo total de `pedidos_origem` — a bronze não filtra nada). Se tiver menos, alguma coisa saiu errado antes desse passo.

-- COMMAND ----------

-- MAGIC %md
-- MAGIC ### Streaming Table vs Materialized View — qual a diferença?
-- MAGIC
-- MAGIC Repare: `pedidos_origem` (Passo 0) é uma **MATERIALIZED VIEW**, mas `pedidos_bronze` é uma **STREAMING TABLE**. Não é acaso:
-- MAGIC
-- MAGIC | | STREAMING TABLE | MATERIALIZED VIEW |
-- MAGIC |---|---|---|
-- MAGIC | Como processa | Incremental — só lê o que é **novo** desde a última execução, via `STREAM()` | Recalcula o **resultado inteiro** a cada refresh |
-- MAGIC | Quando usar | Ingestão contínua, append-only (arquivos chegando, eventos, logs) | Agregações, junções, ou qualquer transformação que olhe para o conjunto de dados como um todo |
-- MAGIC | Exemplo aqui | `pedidos_bronze`, `pedidos_silver` (só ingerem/filtram linha a linha) | `pedidos_origem`, `pedidos_gold` (agregação por produto) |
-- MAGIC
-- MAGIC Guarde essa tabela — ela volta lá no desafio bônus.

-- COMMAND ----------

-- MAGIC %md
-- MAGIC ## Passo 2 · Silver — qualidade de dados (DESAFIO)
-- MAGIC
-- MAGIC Repare nos dados de origem: tem pedido com `quantidade = 0`, outro com `quantidade` negativa, e outro com `preco_unitario = 0` — não fazem sentido de negócio. A `silver` é a camada que barra isso.
-- MAGIC
-- MAGIC **2 TODOs:**
-- MAGIC 1. Crie uma `CONSTRAINT` chamada `quantidade_valida`, que descarte pedidos com `quantidade <= 0`.
-- MAGIC 2. Crie uma `CONSTRAINT` chamada `preco_valido`, que descarte pedidos com `preco_unitario <= 0`.
-- MAGIC
-- MAGIC Dica — sintaxe de uma expectation:
-- MAGIC ```sql
-- MAGIC CONSTRAINT nome_da_regra EXPECT (condicao) ON VIOLATION DROP ROW
-- MAGIC ```
-- MAGIC
-- MAGIC ### Os 3 modos de `ON VIOLATION`
-- MAGIC - **`WARN`** *(padrão, se você omitir a cláusula)* — mantém a linha inválida na tabela, só registra a violação nas métricas do pipeline.
-- MAGIC - **`DROP ROW`** — descarta só a linha problemática, o pipeline continua normalmente. É o que vamos usar aqui.
-- MAGIC - **`FAIL UPDATE`** — para o pipeline inteiro se encontrar qualquer violação. Reservado para regras críticas, onde dado errado não pode nem ser processado.
-- MAGIC
-- MAGIC **Experimento opcional (não é obrigatório para concluir o desafio):** depois de terminar os TODOs, troque o `ON VIOLATION` da constraint `preco_valido` para `FAIL UPDATE`, rode o pipeline de novo e veja o nó `pedidos_silver` ficar vermelho no grafo. Depois volte para `DROP ROW` para conseguir seguir para o Passo 3.

-- COMMAND ----------

CREATE OR REFRESH STREAMING TABLE pedidos_silver (
  CONSTRAINT produto_valido EXPECT (produto IS NOT NULL) ON VIOLATION DROP ROW -- pronto, como modelo
  -- TODO 1: adicione aqui a CONSTRAINT "quantidade_valida" exigindo quantidade > 0
  -- TODO 2: adicione aqui a CONSTRAINT "preco_valido" exigindo preco_unitario > 0
)
COMMENT "Pedidos validados: produto preenchido, quantidade e preço positivos."
AS SELECT * FROM STREAM(pedidos_bronze);

-- COMMAND ----------

-- MAGIC %md
-- MAGIC **Checkpoint:** depois dos dois TODOs, `pedidos_silver` deve ter **10 linhas** (2 pedidos foram descartados pelas constraints — sabe dizer quais?).

-- COMMAND ----------

-- MAGIC %md
-- MAGIC ## Passo 3 · Gold — receita por produto (DESAFIO)
-- MAGIC
-- MAGIC A camada **gold** entrega uma tabela pronta para BI. Queremos saber a receita total por produto.
-- MAGIC
-- MAGIC Por isso ela é uma `MATERIALIZED VIEW`, e não uma `STREAMING TABLE`: `SUM(quantidade)` precisa recalcular o total considerando **todos** os pedidos do produto, não só os que chegaram agora.
-- MAGIC
-- MAGIC **1 TODO:** complete a coluna `receita_total`, multiplicando `quantidade` por `preco_unitario` e somando.

-- COMMAND ----------

CREATE OR REFRESH MATERIALIZED VIEW pedidos_gold
COMMENT "Receita total e quantidade vendida por produto."
AS SELECT
  produto,
  categoria,
  SUM(quantidade) AS qtd_total,
  NULL             AS receita_total   -- TODO: troque o NULL por SUM(quantidade * preco_unitario)
FROM pedidos_silver
GROUP BY produto, categoria;

-- COMMAND ----------

-- MAGIC %md
-- MAGIC **Checkpoint:** `pedidos_gold` deve ter **6 linhas** — um produto da origem não aparece nela. Qual foi, e por quê? (Dica: olhe de novo as constraints da silver.)
-- MAGIC
-- MAGIC Dica extra (opcional): depois de rodar, consulte `pedidos_gold` ordenando por `receita_total` — qual produto rendeu mais?

-- COMMAND ----------

-- MAGIC %md
-- MAGIC ## Bônus · Receita por dia (opcional)
-- MAGIC
-- MAGIC Crie uma 4ª camada `pedidos_por_dia_dlt`, agregando `pedidos_silver` por `data_pedido` com a receita total do dia.
-- MAGIC
-- MAGIC **Antes de escrever o código:** decida — essa camada deve ser uma `STREAMING TABLE` ou uma `MATERIALIZED VIEW`? Coloque sua resposta como comentário na primeira linha do bloco abaixo, e só depois implemente. (Dica: reveja a tabela comparativa lá no Passo 1.)

-- COMMAND ----------

-- TODO (bônus): crie aqui a MATERIALIZED VIEW pedidos_por_dia_dlt,
-- agrupando pedidos_silver por data_pedido e somando quantidade * preco_unitario

-- COMMAND ----------

-- MAGIC %md
-- MAGIC **Checkpoint:** `pedidos_por_dia_dlt` deve ter **4 linhas** (uma por dia de pedido).

-- COMMAND ----------

-- MAGIC %md
-- MAGIC ## Bônus avançado · Simulando correções com CDC (`AUTO CDC INTO`)
-- MAGIC
-- MAGIC **Pré-requisito:** este recurso só funciona em pipeline **Serverless** ou nas edições **Pro/Advanced** do SDP. Se o seu pipeline estiver na edição padrão, esse bloco vai dar erro — e não é bug seu, é limitação da plataforma. Confirme com o instrutor antes de tentar.
-- MAGIC
-- MAGIC Na vida real, pedidos chegam errados e alguém corrige depois — o sistema de origem manda um **feed de mudanças** (CDC: Change Data Capture). O Lakeflow Declarative Pipelines tem um jeito declarativo de aplicar essas mudanças automaticamente: o `AUTO CDC INTO` (substituto oficial do antigo `APPLY CHANGES INTO`, mesma sintaxe).
-- MAGIC
-- MAGIC Vamos simular duas correções: o pedido #4 (Cappuccino, que a silver descartou por ter `quantidade = 0`) foi corrigido pelo atendente para `quantidade = 2`; e o pedido #7 (Suco Natural, quantidade negativa) foi cancelado de vez.

-- COMMAND ----------

-- MAGIC %md
-- MAGIC **Passo A — feed de mudanças (pronto)**
-- MAGIC
-- MAGIC Cada linha representa um evento: `operacao` diz se é atualização ou exclusão, e `versao` serve para o pipeline saber a ordem correta dos eventos (`SEQUENCE BY`).

-- COMMAND ----------

CREATE OR REFRESH MATERIALIZED VIEW pedidos_correcoes AS
SELECT * FROM (VALUES
  (4, 'Cappuccino',    'Bebida', 2, 11.00, DATE'2026-06-02', 'UPDATE', 1),
  (7, 'Suco Natural',  'Bebida', 0, 10.00, DATE'2026-06-02', 'DELETE', 1)
) AS t(id_pedido, produto, categoria, quantidade, preco_unitario, data_pedido, operacao, versao);

-- COMMAND ----------

-- MAGIC %md
-- MAGIC **Passo B — TODO (bônus avançado):** declare a tabela de destino e o flow de CDC.
-- MAGIC
-- MAGIC Regras:
-- MAGIC - Toda `AUTO CDC INTO` precisa de uma `STREAMING TABLE` de destino já criada (sem SELECT — ela é preenchida pelo flow).
-- MAGIC - `KEYS` identifica o pedido único (`id_pedido`).
-- MAGIC - `SEQUENCE BY` diz qual coluna define a ordem dos eventos (`versao`).
-- MAGIC - `APPLY AS DELETE WHEN` trata o cancelamento do pedido #7 automaticamente.
-- MAGIC - `STORED AS SCD TYPE 1` guarda só o valor mais recente de cada pedido (sem histórico) — é o padrão mais simples de CDC.

-- COMMAND ----------

CREATE OR REFRESH STREAMING TABLE pedidos_atualizados;

CREATE FLOW pedidos_cdc_flow AS
AUTO CDC INTO pedidos_atualizados
FROM STREAM(pedidos_correcoes)
KEYS (id_pedido)
APPLY AS DELETE WHEN operacao = "DELETE"
SEQUENCE BY versao
STORED AS SCD TYPE 1;

-- COMMAND ----------

-- MAGIC %md
-- MAGIC **Pronto quando:** depois de rodar o pipeline, `pedidos_atualizados` mostra o pedido #4 com `quantidade = 2`, e o pedido #7 **não aparece** (foi removido pelo `APPLY AS DELETE WHEN`).
-- MAGIC
-- MAGIC **Checkpoint:** `pedidos_atualizados` deve ter **1 linha** só.
-- MAGIC
-- MAGIC > Esse bônus é independente do restante do pipeline — não precisa mexer aqui para concluir o desafio principal.

-- COMMAND ----------

-- MAGIC %md
-- MAGIC ## Deu erro? Troubleshooting rápido
-- MAGIC
-- MAGIC | Sintoma | Causa provável |
-- MAGIC |---|---|
-- MAGIC | Nó vermelho em `pedidos_bronze` na primeira execução | Esperado! É o bug proposital do Passo 1 — clique no nó, leia a mensagem de erro e corrija. |
-- MAGIC | Erro de permissão ao criar schema/tabela | Confirme com o instrutor se você tem permissão no catálogo `workspace`, ou troque para um catálogo/schema que você já tenha acesso. |
-- MAGIC | "Table or view not found" logo no início | Confira se rodou o comando `USE CATALOG` / `USE SCHEMA` do topo do notebook antes do resto. |
-- MAGIC | Nome de tabela já existe / conflito com outro aluno | Se a turma está usando o mesmo catálogo/schema, combine com o instrutor um sufixo único (ex: troque `treino_dlt` por `treino_dlt_seuiniciais`). |
-- MAGIC | Erro no bloco de CDC (`AUTO CDC INTO`) | Verifique o pré-requisito de edição do pipeline (Serverless / Pro / Advanced) lá no bônus avançado. |
-- MAGIC | Resultado diferente do esperado numa segunda tentativa | O pipeline guarda estado entre execuções. Rode com **Full Refresh** para recomeçar do zero. |

-- COMMAND ----------

-- MAGIC %md
-- MAGIC ## Como rodar
-- MAGIC 1. Crie um novo **Pipeline** em *Jobs & Pipelines → Create → ETL Pipeline*, modo **Lakeflow Declarative Pipelines**.
-- MAGIC 2. Defina o catálogo/schema padrão do pipeline como `workspace` / `treino_dlt` (o pipeline cria o schema automaticamente, se você tiver permissão).
-- MAGIC 3. Adicione este notebook como código-fonte e clique em **Run pipeline**.
-- MAGIC 4. Confira o **gráfico do pipeline**: nós verdes — `pedidos_bronze → pedidos_silver → pedidos_gold`.
-- MAGIC
-- MAGIC **Pronto quando:** o pipeline rodou sem nó vermelho, e `pedidos_gold` mostra `receita_total` preenchida com valores numéricos coerentes para cada produto.
