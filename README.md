# Databricks Medallion Training — Corporate Finance Ledger

A hands-on, beginner-friendly training that takes a messy CSV and turns it into a
clean **star schema** with metrics and a dashboard — using the **Medallion
architecture** (Bronze → Silver → Gold) on Databricks.

There are **two parallel tracks** that do exactly the same thing:

| Track | Folder | Language |
|-------|--------|----------|
| SQL    | [`sql/`](sql/)       | Databricks SQL |
| Python | [`python/`](python/) | PySpark |

Pick whichever you prefer — the steps, table names and results are identical.

> The instructor walks through **one worked example** in each step. Everything
> marked `🧩 CHALLENGE` / `TODO` is for **you** to complete. Reference answers
> live in [`solutions/`](solutions/).

---

## 🇬🇧 What you will build

```
 corporate_finance_ledger.csv   (messy raw export)
            │
            ▼
   ┌──────────────────┐
   │  BRONZE           │  raw ingest, everything as text + load metadata
   │  bronze_ledger    │
   └──────────────────┘
            │  clean & standardize (the challenges)
            ▼
   ┌──────────────────┐
   │  SILVER           │  typed, deduplicated, English categories
   │  silver_ledger    │
   └──────────────────┘
            │  model into a star schema
            ▼
   ┌──────────────────────────────────────────────┐
   │  GOLD                                          │
   │  dim_date · dim_cost_center · dim_category     │
   │  fact_ledger                                   │
   └──────────────────────────────────────────────┘
            │
            ▼
     metrics + Databricks SQL dashboard
```

### Steps

| # | Notebook | What happens |
|---|----------|--------------|
| 00 | `00_setup` | Create the catalog/schema/volume. **Upload the CSV** to the volume. |
| 01 | `01_bronze` | Read the CSV from the volume → write `bronze_ledger` (raw, as-is). |
| 02 | `02_silver` | Clean & standardize the data. **1 example done, the rest are challenges.** |
| 03 | `03_gold_dimensions` | Build the dimension tables. **1 example done, the rest are challenges.** |
| 04 | `04_gold_fact` | Build the fact table by joining dimensions. **Challenge.** |
| 05 | `05_metrics` | Analytical queries + how to pin them to a dashboard. |

---

## 🇧🇷 O que você vai construir (Português)

Este treino pega um CSV **bagunçado** de lançamentos financeiros e o transforma em
um **modelo estrela** (star schema) com métricas e dashboard, usando a
**arquitetura Medallion** (Bronze → Silver → Gold) no Databricks.

- **Bronze** = dado cru, tudo como texto, sem tratamento (só guardamos a origem).
- **Silver** = dado **limpo e padronizado**: datas convertidas, valores virando
  número, categorias em inglês, duplicados removidos.
- **Gold** = modelo dimensional: tabelas de **dimensão** (`dim_*`) e de **fato**
  (`fact_ledger`) prontas para análise e dashboard.

O instrutor mostra **1 exemplo** em cada etapa. O que estiver marcado como
`🧩 CHALLENGE` / `TODO` é **você** quem completa. As respostas estão em
[`solutions/`](solutions/).

> Observação sobre os dados: os **cabeçalhos** do CSV estão em inglês (o projeto
> padroniza colunas em inglês), mas os **valores** são propositalmente "à
> brasileira" e sujos — centros de custo em PT (`TI`, `Comercial`...), tipo
> `Receita`/`Despesa`, valores em `R$`, datas em dois formatos. Padronizar isso é
> justamente o desafio. 🙂

---

## Getting started

### 1. Configuration (used by every notebook)

All notebooks read these three names from the top cell. Change them if your
workspace uses a different catalog:

```
catalog = workspace          -- default catalog in new Databricks workspaces
schema  = finance_training
volume  = landing
```

The CSV is expected at:

```
/Volumes/workspace/finance_training/landing/corporate_finance_ledger.csv
```

### 2. Upload the data

Run `00_setup` first (it creates the volume), then upload
[`data/corporate_finance_ledger.csv`](data/corporate_finance_ledger.csv) to the
volume. Two easy ways:

- **UI:** Catalog → `workspace` → `finance_training` → `landing` → **Upload to this volume**.
- **CLI:** `databricks fs cp data/corporate_finance_ledger.csv dbfs:/Volumes/workspace/finance_training/landing/`

### 3. Run the notebooks in order

Import the `sql/` *or* `python/` folder into your workspace and run `00` → `05`.

---

## The dataset

Raw columns in [`data/corporate_finance_ledger.csv`](data/corporate_finance_ledger.csv):

| Column | Example | Mess to clean |
|--------|---------|---------------|
| `entry_id`    | `L100`              | — |
| `entry_date`  | `2025-02-22`, `05/11/2025` | two date formats |
| `cost_center` | `TI`, `ti`, `Operações`, `comercial ` | casing + trailing spaces |
| `category`    | `SOFTWARE`, `software`, `Impostos` | casing + PT synonyms → English |
| `amount`      | `R$ 6,273.32`, `5622.22`, `  4,233.82 ` | currency symbol, spaces, thousands sep |
| `type`        | `Receita`, `despesa`, `DESPESA` | casing → `Income`/`Expense` |
| `description` | `  LICENCA DATABRICKS  ` | extra spaces, casing |

Plus a few injected data-quality issues: **duplicate rows**, **missing amount**,
**missing date**, **blank category**.

---

## Repo layout

```
databricks_training/
├── data/
│   └── corporate_finance_ledger.csv   # the messy sample data
├── sql/                               # SQL track (00 → 05)
├── python/                            # PySpark track (00 → 05)
├── solutions/                         # reference answers (instructor)
└── README.md
```
