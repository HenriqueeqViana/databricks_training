-- Databricks notebook source
-- MAGIC %md
-- MAGIC # 02 · Silver — SOLUÇÃO
-- MAGIC Referência completa dos desafios de limpeza da silver.

-- COMMAND ----------

USE CATALOG workspace;
USE SCHEMA treino_financeiro;

-- COMMAND ----------

CREATE OR REPLACE TABLE silver_lancamentos AS
WITH limpo AS (
  SELECT
    trim(id_lancamento) AS id_lancamento,

    -- DESAFIO 1 — converte os dois formatos de data
    coalesce(
      try_to_date(data_lancamento, 'yyyy-MM-dd'),
      try_to_date(data_lancamento, 'dd/MM/yyyy')
    ) AS data_lancamento,

    -- DESAFIO 2 — trim + iniciais maiúsculas
    initcap(trim(centro_custo)) AS centro_custo,

    -- DESAFIO 3 — padroniza categorias
    CASE lower(trim(categoria))
      WHEN 'software' THEN 'Software'  WHEN 'licencas' THEN 'Software'  WHEN 'licenças' THEN 'Software'
      WHEN 'impostos' THEN 'Impostos'  WHEN 'tributos' THEN 'Impostos'
      WHEN 'salarios' THEN 'Folha de Pagamento' WHEN 'salários' THEN 'Folha de Pagamento'
      WHEN 'folha' THEN 'Folha de Pagamento'    WHEN 'folha de pagamento' THEN 'Folha de Pagamento'
      WHEN 'aluguel' THEN 'Aluguel'    WHEN 'locacao' THEN 'Aluguel'
      WHEN 'marketing' THEN 'Marketing' WHEN 'publicidade' THEN 'Marketing' WHEN 'anuncios' THEN 'Marketing'
      WHEN 'viagens' THEN 'Viagens'    WHEN 'viagem' THEN 'Viagens'
      WHEN 'infraestrutura' THEN 'Infraestrutura' WHEN 'infra' THEN 'Infraestrutura' WHEN 'cloud' THEN 'Infraestrutura'
      WHEN 'servicos' THEN 'Serviços'  WHEN 'serviços' THEN 'Serviços' WHEN 'consultoria' THEN 'Serviços'
      WHEN 'material' THEN 'Materiais'  WHEN 'materiais' THEN 'Materiais' WHEN 'suprimentos' THEN 'Materiais'
      WHEN 'vendas' THEN 'Vendas'      WHEN 'venda mensal' THEN 'Vendas'
      WHEN 'servicos prestados' THEN 'Receita de Serviços'
      WHEN 'serviços prestados' THEN 'Receita de Serviços'
      WHEN 'prestacao de servicos' THEN 'Receita de Serviços'
      WHEN 'juros' THEN 'Juros'        WHEN 'rendimentos' THEN 'Juros'
      WHEN 'investimentos' THEN 'Investimentos' WHEN 'aplicacoes' THEN 'Investimentos'
      ELSE 'Sem Categoria'
    END AS categoria,

    -- EXEMPLO RESOLVIDO — valor
    CAST(regexp_replace(valor, '[^0-9.]', '') AS DECIMAL(12,2)) AS valor,

    -- DESAFIO 4 — normaliza o tipo
    CASE lower(trim(tipo))
      WHEN 'receita' THEN 'Receita'
      WHEN 'despesa' THEN 'Despesa'
    END AS tipo,

    -- DESAFIO 5 — limpa a descrição
    initcap(trim(regexp_replace(descricao, '\\s+', ' '))) AS descricao
  FROM bronze_lancamentos
)
SELECT DISTINCT *                                            -- DESAFIO 7 — dedupe
FROM limpo
WHERE data_lancamento IS NOT NULL AND valor IS NOT NULL;     -- DESAFIO 6 — descarta linhas ruins

-- COMMAND ----------

SELECT tipo, count(*) FROM silver_lancamentos GROUP BY tipo;
SELECT categoria, count(*) FROM silver_lancamentos GROUP BY categoria ORDER BY 2 DESC;
