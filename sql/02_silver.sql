-- Databricks notebook source
-- MAGIC %md
-- MAGIC # 02 · Silver — limpar & padronizar  🧩
-- MAGIC
-- MAGIC Silver = dado limpo, tipado e confiável. Corrigimos a bagunça do bronze:
-- MAGIC número vira número, data vira data, texto padronizado, categorias unificadas
-- MAGIC e duplicados/linhas ruins removidos.
-- MAGIC
-- MAGIC ## Como este notebook funciona
-- MAGIC A coluna **`valor`** já está pronta como exemplo resolvido. Cada outra coluna
-- MAGIC tem um `🧩 DESAFIO` com um `TODO`. Substitua os TODOs e rode o `CREATE TABLE`
-- MAGIC final. A resposta de referência fica com o instrutor.

-- COMMAND ----------

USE CATALOG workspace;
USE SCHEMA treino_financeiro;

-- COMMAND ----------

-- MAGIC %md
-- MAGIC ## ✅ Exemplo resolvido — limpando `valor`
-- MAGIC
-- MAGIC Os valores brutos vêm como `R$ 6,273.32`, `5622.22`, `  4,233.82 `, `R$13446.67`.
-- MAGIC Todos têm algo em comum: os únicos caracteres que importam são **dígitos e o
-- MAGIC ponto decimal**. Então removemos o resto e fazemos cast para `DECIMAL`.
-- MAGIC
-- MAGIC `regexp_replace(valor, '[^0-9.]', '')` remove `R$`, espaços e separador de
-- MAGIC milhar de uma vez, deixando, por exemplo, `6273.32`.

-- COMMAND ----------

SELECT
  valor                                              AS valor_bruto,
  regexp_replace(valor, '[^0-9.]', '')               AS valor_digitos,
  CAST(regexp_replace(valor, '[^0-9.]', '') AS DECIMAL(12,2)) AS valor_limpo
FROM bronze_lancamentos
LIMIT 15;

-- COMMAND ----------

-- MAGIC %md
-- MAGIC ## 🧩 Agora monte a tabela silver completa
-- MAGIC
-- MAGIC Preencha cada `TODO` abaixo. As dicas estão nos comentários. A linha do
-- MAGIC `valor` já está pronta — use como modelo de estilo.

-- COMMAND ----------

CREATE OR REPLACE TABLE silver_lancamentos AS
WITH limpo AS (
  SELECT
    -- id: só remove espaços
    trim(id_lancamento) AS id_lancamento,

    -- 🧩 DESAFIO 1 — data_lancamento: converta OS DOIS formatos para DATE de verdade.
    -- A coluna bruta mistura 'yyyy-MM-dd' e 'dd/MM/yyyy'.
    -- Dica: coalesce(try_to_date(data_lancamento,'yyyy-MM-dd'),
    --                try_to_date(data_lancamento,'dd/MM/yyyy'))
    CAST(NULL AS DATE) AS data_lancamento,                 -- TODO

    -- 🧩 DESAFIO 2 — centro_custo: tire espaços e deixe com Iniciais Maiúsculas.
    -- Dica: initcap(trim(centro_custo))  (ex.: 'comercial ' -> 'Comercial')
    'TODO' AS centro_custo,                                 -- TODO

    -- 🧩 DESAFIO 3 — categoria: padronize as variantes em UM rótulo único.
    -- Dica: normalize com lower(trim(categoria)) e use um CASE/WHEN mapeando:
    --   'software'/'licencas'/'licenças'                  -> 'Software'
    --   'impostos'/'tributos'                              -> 'Impostos'
    --   'salarios'/'salários'/'folha'/'folha de pagamento' -> 'Folha de Pagamento'
    --   'vendas'/'venda mensal'                            -> 'Vendas'
    --   ... descubra as variantes com:
    --       SELECT DISTINCT lower(trim(categoria)) FROM bronze_lancamentos ORDER BY 1; ...
    --   em branco/nulo                                     -> 'Sem Categoria'
    'TODO' AS categoria,                                    -- TODO

    -- ✅ EXEMPLO RESOLVIDO — valor (pronto para você)
    CAST(regexp_replace(valor, '[^0-9.]', '') AS DECIMAL(12,2)) AS valor,

    -- 🧩 DESAFIO 4 — tipo: normalize a caixa para 'Receita'/'Despesa'.
    -- Dica: CASE WHEN lower(trim(tipo)) = 'receita' THEN 'Receita'
    --            WHEN lower(trim(tipo)) = 'despesa' THEN 'Despesa' END
    'TODO' AS tipo,                                         -- TODO

    -- 🧩 DESAFIO 5 — descricao: junte espaços repetidos e deixe Iniciais Maiúsculas.
    -- Dica: initcap(trim(regexp_replace(descricao, '\\s+', ' ')))
    'TODO' AS descricao
  FROM bronze_lancamentos
)
SELECT *
FROM limpo
-- 🧩 DESAFIO 6 — descarte linhas que não dá para usar (sem data ou sem valor).
-- Dica: WHERE data_lancamento IS NOT NULL AND valor IS NOT NULL
;

-- COMMAND ----------

-- MAGIC %md
-- MAGIC ## 🧩 DESAFIO 7 — remova linhas duplicadas
-- MAGIC O arquivo bruto tem algumas duplicatas exatas. Depois que a tabela acima
-- MAGIC funcionar, remova as duplicatas. Um jeito limpo:
-- MAGIC
-- MAGIC ```sql
-- MAGIC CREATE OR REPLACE TABLE silver_lancamentos AS
-- MAGIC SELECT DISTINCT * FROM silver_lancamentos;
-- MAGIC ```
-- MAGIC (Ou use `ROW_NUMBER() OVER (PARTITION BY id_lancamento ORDER BY ...)` e fique com `= 1`.)

-- COMMAND ----------

-- DBTITLE 1,Valide sua tabela silver
-- Esperado: nenhuma data/valor NULL, tipo só Receita/Despesa, nenhum 'TODO' sobrando.
SELECT
  count(*)                                                  AS linhas,
  count(DISTINCT id_lancamento)                             AS ids_distintos,
  sum(CASE WHEN data_lancamento IS NULL THEN 1 ELSE 0 END)  AS datas_nulas,
  sum(CASE WHEN valor IS NULL THEN 1 ELSE 0 END)            AS valores_nulos,
  count(DISTINCT tipo)                                      AS tipos_distintos
FROM silver_lancamentos;

-- COMMAND ----------

SELECT tipo, count(*) FROM silver_lancamentos GROUP BY tipo;        -- deve ser Receita / Despesa
SELECT categoria, count(*) FROM silver_lancamentos GROUP BY categoria ORDER BY 2 DESC;
