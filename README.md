# Treinamento Databricks — Arquitetura Medallion (Razão Financeiro)

Treinamento prático e didático que pega um **CSV bagunçado** de lançamentos
financeiros e o transforma em um **modelo estrela** (star schema) com métricas e
dashboard — usando a **arquitetura Medallion** (Bronze → Silver → Gold) no
Databricks.

> 🌎 Esta é a versão em **português** (para o treino interno). Uma versão pública
> em inglês será derivada depois.

Há **dois tracks paralelos** que fazem exatamente a mesma coisa:

| Track | Pasta | Linguagem |
|-------|-------|-----------|
| SQL    | [`sql/`](sql/)       | Databricks SQL |
| Python | [`python/`](python/) | PySpark |

Escolha o que preferir — os passos, nomes de tabela e resultados são idênticos.

> O instrutor mostra **um exemplo resolvido** em cada etapa. Tudo marcado como
> `🧩 DESAFIO` / `TODO` é para **você** completar. As respostas de referência
> ficam com o **instrutor** (fora deste repositório, de propósito).

---

## O que você vai construir

```
 lancamentos_financeiros.csv   (export bruto e bagunçado)
            │
            ▼
   ┌────────────────────────┐
   │  BRONZE                 │  ingestão crua, tudo como texto + metadados
   │  bronze_lancamentos     │
   └────────────────────────┘
            │  limpar & padronizar (os desafios)
            ▼
   ┌────────────────────────┐
   │  SILVER                 │  tipado, sem duplicatas, categorias padronizadas
   │  silver_lancamentos     │
   └────────────────────────┘
            │  modelar em star schema
            ▼
   ┌──────────────────────────────────────────────────┐
   │  GOLD                                              │
   │  dim_data · dim_centro_custo · dim_categoria       │
   │  fato_lancamentos                                  │
   └──────────────────────────────────────────────────┘
            │
            ▼
     métricas + dashboard no Databricks SQL
```

### O que é cada camada

- **Bronze** = dado **cru**, tudo como texto, sem tratamento (só guardamos a
  origem do arquivo e a hora da carga). Nunca perdemos a verdade original.
- **Silver** = dado **limpo e padronizado**: datas convertidas, valor virando
  número, categorias padronizadas, tipos normalizados, duplicados removidos.
- **Gold** = modelo dimensional: tabelas de **dimensão** (`dim_*`) e de **fato**
  (`fato_lancamentos`) prontas para análise e dashboard.

### Etapas

| # | Notebook | O que acontece |
|---|----------|----------------|
| 00 | `00_setup` | Cria o catálogo/schema/volume. **Suba o CSV** no volume. |
| 01 | `01_bronze` | Lê o CSV do volume → grava `bronze_lancamentos` (cru). |
| 02 | `02_silver` | Limpa & padroniza. **1 exemplo pronto, o resto são desafios.** |
| 03 | `03_gold_dimensions` | Monta as dimensões. **1 exemplo pronto, o resto são desafios.** |
| 04 | `04_gold_fact` | Monta a tabela fato juntando as dimensões. **Desafio.** |
| 05 | `05_metrics` | Consultas analíticas + como fixar num dashboard. |

---

## Como começar

### 1. Configuração (usada por todos os notebooks)

Todos os notebooks leem estes três nomes na primeira célula. Mude se o seu
workspace usar outro catálogo:

```
catalog = workspace            -- catálogo padrão em workspaces novos do Databricks
schema  = treino_financeiro
volume  = entrada
```

O CSV é esperado em:

```
/Volumes/workspace/treino_financeiro/entrada/lancamentos_financeiros.csv
```

### 2. Suba os dados

Rode o `00_setup` primeiro (ele cria o volume), depois suba o arquivo
[`data/lancamentos_financeiros.csv`](data/lancamentos_financeiros.csv) no volume.
Dois jeitos fáceis:

- **UI:** Catalog → `workspace` → `treino_financeiro` → `entrada` → **Upload to this volume**.
- **CLI:** `databricks fs cp data/lancamentos_financeiros.csv dbfs:/Volumes/workspace/treino_financeiro/entrada/`

### 3. Rode os notebooks em ordem

Importe a pasta `sql/` *ou* `python/` no seu workspace e rode do `00` ao `05`.

---

## Os dados

Colunas brutas em [`data/lancamentos_financeiros.csv`](data/lancamentos_financeiros.csv):

| Coluna | Exemplo | Bagunça para limpar |
|--------|---------|---------------------|
| `id_lancamento`   | `L100`              | — |
| `data_lancamento` | `2025-02-22`, `05/11/2025` | dois formatos de data |
| `centro_custo`    | `TI`, `ti`, `Operações`, `comercial ` | caixa + espaços sobrando |
| `categoria`       | `SOFTWARE`, `software`, `Impostos` | caixa + sinônimos a padronizar |
| `valor`           | `R$ 6,273.32`, `5622.22`, `  4,233.82 ` | símbolo, espaços, separador de milhar |
| `tipo`            | `Receita`, `despesa`, `DESPESA` | caixa → `Receita`/`Despesa` |
| `descricao`       | `  LICENCA DATABRICKS  ` | espaços sobrando, caixa |

Além disso, alguns problemas de qualidade injetados de propósito: **linhas
duplicadas**, **valor faltando**, **data faltando**, **categoria em branco**.

---

## Estrutura do repositório

```
databricks_training/
├── data/
│   └── lancamentos_financeiros.csv    # os dados de exemplo (bagunçados)
├── sql/                               # track SQL (00 → 05)
├── python/                            # track PySpark (00 → 05)
└── README.md
```
