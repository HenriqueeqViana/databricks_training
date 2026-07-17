-- Databricks notebook source
-- MAGIC %md
-- MAGIC # 10 · AI Functions + Projeto Final
-- MAGIC
-- MAGIC **Parte A — GenAI em SQL:** os clientes deixam comentários no atendimento.
-- MAGIC Texto livre sempre foi terra de ninguém — com as **AI Functions**, vira
-- MAGIC coluna analisável dentro do SELECT.
-- MAGIC
-- MAGIC **Parte B — Projeto final:** provar, com uma consulta por etapa, que o
-- MAGIC pipeline inteiro do curso está de pé.
-- MAGIC
-- MAGIC > Pré-requisito: notebook `08desafio`.
-- MAGIC > As AI Functions chamam um LLM por linha: sempre teste com `LIMIT`.

-- COMMAND ----------

USE CATALOG workspace;
USE SCHEMA treino_ml;

-- COMMAND ----------

-- MAGIC %md
-- MAGIC ## Célula pronta — os comentários chegaram (não altere)

-- COMMAND ----------

CREATE OR REPLACE TABLE comentarios_clientes AS
SELECT * FROM (VALUES
  ('N0003', 'Atendimento excelente, resolvi tudo pelo app em minutos!'),
  ('N0007', 'Estou esperando resposta da minha proposta ha duas semanas. Absurdo.'),
  ('N0012', 'Como faco para antecipar parcelas do meu emprestimo?'),
  ('N0015', 'A taxa que me ofereceram esta muito acima do que vi anunciado. Me senti enganado.'),
  ('N0021', 'Parabens pela agilidade na liberacao do credito, superou minha expectativa.'),
  ('N0028', 'O aplicativo trava toda vez que tento enviar meus documentos.'),
  ('N0033', 'Qual o horario de atendimento da agencia de Botucatu?'),
  ('N0040', 'Cobraram uma tarifa que ninguem me explicou. Quero estorno.'),
  ('N0044', 'Gostei muito da consultora que me atendeu, muito atenciosa.'),
  ('N0051', 'Voces trabalham com credito consignado para servidor publico?')
) AS t(cliente_id, comentario);

SELECT * FROM comentarios_clientes;

-- COMMAND ----------

-- MAGIC %md
-- MAGIC ## DESAFIO 1 — classifique o sentimento com `ai_classify`
-- MAGIC Rotule cada comentário como `elogio`, `reclamacao` ou `duvida`.
-- MAGIC Sintaxe: `ai_classify(texto, array('rotulo1', 'rotulo2', ...))`.

-- COMMAND ----------

-- MAGIC %md
-- MAGIC **Antes de rodar — sua aposta:** olhando os 10 comentários acima, qual
-- MAGIC tipo você acha que vai ter MAIS ocorrências: elogio, reclamacao ou duvida?

-- COMMAND ----------

-- Minha aposta:

-- COMMAND ----------

CREATE OR REPLACE TABLE comentarios_classificados AS
SELECT
  cliente_id,
  comentario,
  ai_classify(___, array('___', '___', '___')) AS tipo
FROM comentarios_clientes;

SELECT tipo, count(*) FROM comentarios_classificados GROUP BY tipo;

-- COMMAND ----------

-- MAGIC %md
-- MAGIC **Checkpoint 1:** a divisão esperada é ~**4 elogios, 4 reclamações e
-- MAGIC 3 dúvidas** (leia os textos e confira se concorda com o LLM — pode haver
-- MAGIC 1 divergência de interpretação; isso também é aprendizado). Bateu com a
-- MAGIC sua aposta?

-- COMMAND ----------

-- MAGIC %md
-- MAGIC ## DESAFIO 2 — resumo executivo com `ai_query`
-- MAGIC Junte as reclamações num texto só e peça um resumo de 2 frases.
-- MAGIC Dica: `concat_ws(' | ', collect_list(comentario))` agrega os textos;
-- MAGIC o 1º argumento do `ai_query` é o endpoint do modelo (o instrutor passa o
-- MAGIC nome disponível no workspace — veja em Serving).

-- COMMAND ----------

-- MAGIC %md
-- MAGIC **Antes de rodar — sua aposta:** releia as reclamações lá em cima. Na sua
-- MAGIC opinião, o resumo gerado pela IA vai citar o app (Desafio "app trava")
-- MAGIC ou a demora/tarifa como problema principal?

-- COMMAND ----------

-- Minha aposta:

-- COMMAND ----------

SELECT ai_query(
  '___',   -- endpoint do modelo (ex.: databricks-meta-llama-3-3-70b-instruct)
  concat('Resuma em 2 frases, em portugues, as reclamacoes a seguir: ',
         (SELECT concat_ws(' | ', collect_list(comentario))
          FROM comentarios_classificados
          WHERE tipo = '___'))
) AS resumo_reclamacoes;

-- COMMAND ----------

-- MAGIC %md
-- MAGIC Bateu com a sua aposta? Leia o texto gerado e confira se ele cobre
-- MAGIC demora, taxa, app e tarifa — o texto exato muda a cada execução, mas o
-- MAGIC conteúdo coberto deve ser sempre parecido.

-- COMMAND ----------

-- MAGIC %md
-- MAGIC ## DESAFIO 3 — quem reclama é mais arriscado?
-- MAGIC Cruze os comentários classificados com `predicoes_carteira` e compare o
-- MAGIC risco médio por tipo de comentário.

-- COMMAND ----------

-- MAGIC %md
-- MAGIC **Antes de rodar — sua aposta:** qual tipo de comentário você acha que
-- MAGIC vai ter o MAIOR risco_medio: elogio, reclamacao ou duvida?

-- COMMAND ----------

-- Minha aposta:

-- COMMAND ----------

SELECT
  cc.tipo,
  count(*)                 AS clientes,
  round(avg(p.___), 3)     AS risco_medio
FROM comentarios_classificados cc
JOIN predicoes_carteira p ON cc.___ = p.___
GROUP BY cc.tipo
ORDER BY risco_medio DESC;

-- COMMAND ----------

-- MAGIC %md
-- MAGIC Bateu com a sua aposta? Lembre: amostra pequena (10 clientes) — o valor
-- MAGIC exato importa menos que entender a mecânica do cruzamento texto x score.

-- COMMAND ----------

-- MAGIC %md
-- MAGIC # Parte B — PROJETO FINAL: o pipeline de ponta a ponta
-- MAGIC
-- MAGIC Uma consulta por etapa. Todas devem rodar **sem erro** e bater com os
-- MAGIC checkpoints do curso. Complete os `___` e rode a bateria.

-- COMMAND ----------

-- Etapa 1-2 · Dados: bronze 1025 -> silver 911
SELECT 'bronze' AS etapa, count(*) AS linhas FROM ___
UNION ALL SELECT 'silver', count(*) FROM ___;

-- COMMAND ----------

-- Etapa 3 · Split: 726 / 185, taxas equilibradas
SELECT 'treino' AS conjunto, count(*), round(avg(inadimplente), 3) FROM ___
UNION ALL SELECT 'teste', count(*), round(avg(inadimplente), 3) FROM ___;

-- COMMAND ----------

-- Etapa 4 · Features: PK presente
DESCRIBE EXTENDED features_treino;

-- COMMAND ----------

-- Etapa 5 · Importâncias: score_bureau no topo
SELECT * FROM ___ ORDER BY importancia DESC LIMIT 3;

-- COMMAND ----------

-- Etapa 6 · Threshold: custo mínimo em t = 0.2
SELECT t, fn * 10000 + fp * 1000 AS custo FROM ___ ORDER BY custo LIMIT 1;

-- COMMAND ----------

-- Etapa 7-8 · Predições da carteira: 300 linhas, ~171 em revisão
SELECT count(*) AS predicoes,
       sum(CASE WHEN decisao = '___' THEN 1 ELSE 0 END) AS em_revisao,
       round(avg(proba), 3) AS risco_medio
FROM ___;

-- COMMAND ----------

-- MAGIC %md
-- MAGIC ## Apresentação final (5 min por dupla)
-- MAGIC 1. **O número que mais te surpreendeu** no curso — e por quê.
-- MAGIC 2. **O threshold que você defenderia** no comitê (com o custo).
-- MAGIC 3. **O status do monitor** e qual seria seu próximo passo como time de ML.
-- MAGIC
-- MAGIC ## Como saber se acertou
-- MAGIC - [ ] Sentimentos classificados (~4/4/3) e resumo gerado pelo `ai_query`
-- MAGIC - [ ] Cruzamento risco x tipo de comentário rodando
-- MAGIC - [ ] As 6 consultas do projeto rodam sem erro e batem com os checkpoints
-- MAGIC - [ ] Apresentação preparada com os 3 pontos
-- MAGIC
-- MAGIC **Parabéns — o pipeline é de vocês agora.**
