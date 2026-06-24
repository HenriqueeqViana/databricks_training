# Soluções (referência do instrutor)

Versões completas dos três notebooks de desafio, nos dois tracks.

| Notebook de desafio | Solução SQL | Solução Python |
|---------------------|-------------|----------------|
| `02_silver`          | [`sql/02_silver_solution.sql`](sql/02_silver_solution.sql) | [`python/02_silver_solution.py`](python/02_silver_solution.py) |
| `03_gold_dimensions` | [`sql/03_gold_dimensions_solution.sql`](sql/03_gold_dimensions_solution.sql) | [`python/03_gold_dimensions_solution.py`](python/03_gold_dimensions_solution.py) |
| `04_gold_fact`       | [`sql/04_gold_fact_solution.sql`](sql/04_gold_fact_solution.sql) | [`python/04_gold_fact_solution.py`](python/04_gold_fact_solution.py) |

`00_setup`, `01_bronze` e `05_metrics` não têm lacunas, então não precisam de solução.

## Mapa de padronização de categoria (usado na silver)

| Rótulo canônico | Variantes brutas (após `lower(trim())`) |
|-----------------|-----------------------------------------|
| Software            | software, licencas, licenças |
| Impostos            | impostos, tributos |
| Folha de Pagamento  | salarios, salários, folha, folha de pagamento |
| Aluguel             | aluguel, locacao |
| Marketing           | marketing, publicidade, anuncios |
| Viagens             | viagens, viagem |
| Infraestrutura      | infraestrutura, infra, cloud |
| Serviços            | servicos, serviços, consultoria |
| Materiais           | material, materiais, suprimentos |
| Vendas              | vendas, venda mensal |
| Receita de Serviços | servicos prestados, serviços prestados, prestacao de servicos |
| Juros               | juros, rendimentos |
| Investimentos       | investimentos, aplicacoes |
| Sem Categoria       | em branco / nulo |

> Dica: não entregue isso de bandeja. Deixe a turma descobrir as variantes com
> `SELECT DISTINCT lower(trim(categoria)) FROM bronze_lancamentos ORDER BY 1;`

## Resultado esperado dos dados

95 linhas brutas → **93** (descarta 1 sem data + 1 sem valor) → **91** (remove 2
duplicatas exatas). A única categoria `Sem Categoria` é a linha de categoria em
branco injetada de propósito.
