# Solutions (instructor reference)

Completed versions of the three challenge notebooks, for both tracks.

| Challenge notebook | SQL solution | Python solution |
|--------------------|--------------|-----------------|
| `02_silver`          | [`sql/02_silver_solution.sql`](sql/02_silver_solution.sql) | [`python/02_silver_solution.py`](python/02_silver_solution.py) |
| `03_gold_dimensions` | [`sql/03_gold_dimensions_solution.sql`](sql/03_gold_dimensions_solution.sql) | [`python/03_gold_dimensions_solution.py`](python/03_gold_dimensions_solution.py) |
| `04_gold_fact`       | [`sql/04_gold_fact_solution.sql`](sql/04_gold_fact_solution.sql) | [`python/04_gold_fact_solution.py`](python/04_gold_fact_solution.py) |

`00_setup`, `01_bronze` and `05_metrics` have no blanks, so they need no solution.

## Category standardization map (used in silver)

| English label (canonical) | Raw PT variants (after `lower(trim())`) |
|---------------------------|-----------------------------------------|
| Software        | software, licencas, licenças |
| Taxes           | impostos, tributos |
| Payroll         | salarios, salários, folha, folha de pagamento |
| Rent            | aluguel, locacao |
| Marketing       | marketing, publicidade, anuncios |
| Travel          | viagens, viagem |
| Infrastructure  | infraestrutura, infra, cloud |
| Services        | servicos, serviços, consultoria |
| Supplies        | material, materiais, suprimentos |
| Sales           | vendas, venda mensal |
| Services Revenue| servicos prestados, serviços prestados, prestacao de servicos |
| Interest        | juros, rendimentos |
| Investments     | investimentos, aplicacoes |
| Uncategorized   | blank / null |

> Tip: don't hand these to students. Let them discover the variants with
> `SELECT DISTINCT lower(trim(category)) FROM bronze_ledger ORDER BY 1;`
