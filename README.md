# SQL Data Warehouse and Analytics System

This project brings together customer, product, and sales data from CRM and ERP CSV files. It uses Python to check the files and SQL Server to load, clean, validate, and prepare the data for analysis.

The warehouse follows a simple **Bronze → Silver → Gold** flow. Each run loads a complete source snapshot. Bronze uses file checksums to recognize a replay, while Silver and the Gold sales fact are rebuilt from the current snapshot. Customer and product history is kept in Gold with SCD Type 2.

## What it does

- Checks the six CSV files before loading: encoding, headers, columns, line endings, row counts, and checksums.
- Loads raw records into Bronze and records file and run details.
- Cleans and deduplicates data in Silver. Rows that fail a rule are saved in a reject ledger with a reason.
- Builds a Gold star schema with customer, product, date, and sales tables.
- Tracks customer and product changes with SCD Type 2.
- Reconciles source and Gold row counts and sales amounts.
- Runs data-quality checks; a critical failure stops Gold from being published and the last good Gold state stays in place.
- Includes six SQL queries and automated checks through GitHub Actions.

The supplied sample data includes rows that fail the project’s validation rules. The amount difference is explained in the reconciliation results, but the business decision to accept or exclude those rows still belongs to a data owner. See the [sample data quality profile](06_reports/sample_data_quality_profile.md).

## Data flow

~~~mermaid
flowchart LR
    A[CRM and ERP CSV snapshots] --> B[Python preflight]
    B --> C[Bronze raw data]
    C --> D[Silver cleaned snapshot]
    D --> E[Gold dimensions and sales facts]
    E --> F[Six analytics queries]
    C -.-> G[Run logs and checks]
    D -.-> G
    E -.-> G
~~~

## Repository layout

| Path | Contents |
| --- | --- |
| 00_setup/ | Fresh database installer |
| 01_datasets/ | CRM and ERP sample CSV files |
| 02_docs/ | Architecture, data model, lineage, and design notes |
| 03_scripts/ | SQL schemas, loaders, and Python preflight runner |
| 04_tests/ | Python preflight tests and SQL Server acceptance checks |
| 05_analytics/ | Six curated Gold-layer queries |
| 06_reports/ | Sample data quality profile |

## Requirements

- SQL Server 2022
- Python 3.10 or later
- Microsoft ODBC Driver 18 for SQL Server
- sqlcmd

Keep the six CSV files in `01_datasets`; the Python runner checks that folder by default. Set `SQLSERVER_DATASET_ROOT` in `.env` to the path where SQL Server can read those files. The pipeline command below uses the default local folder and does not need a path argument.

## Set up

Run these commands from the repository root in PowerShell:

~~~powershell
python -m venv .venv
.\.venv\Scripts\Activate.ps1
python -m pip install -r requirements.txt
Copy-Item .env.example .env
~~~

Set `SQLSERVER_DATASET_ROOT` in `.env` to the SQL Server-visible dataset folder, and adjust the connection values if needed. Then install the schema into a new SQL Server database:

~~~powershell
sqlcmd -S localhost -E -i 00_setup/install.sql
~~~

The installer creates a fresh DataWarehouse database and stops if a database with that name already exists. It does not migrate or replace an existing database. To start over, manually drop `DataWarehouse` in SQL Server; this deletes its data. Then run the installer again.

Run the complete snapshot pipeline:

~~~powershell
python 03_scripts/etl/run_pipeline.py
~~~

To run one analytics query:

~~~powershell
sqlcmd -S localhost -E -d DataWarehouse -i 05_analytics/monthly_sales_mom.sql
~~~

## Checks

Run the Python preflight unit tests:

~~~powershell
python -m unittest discover -s 04_tests/unit -v
~~~

The GitHub Actions workflow validates the project structure, lints the six analytics queries, runs the Python checks, installs a disposable SQL Server, runs a full load, and checks replay, failure handling, SCD Type 2 behavior, and the analytics queries.

## Sample run results

The sample data was loaded in a local SQL Server run on 2026-10-24. Sales reconciliation reported:

| Measure | Rows |
| --- | ---: |
| Source sales lines | 60,398 |
| Accepted in Silver and Gold | 60,360 |
| Rejected sales lines | 38 |

The 38 sales rejects have recorded reason codes. Their source amounts account for the $7,705 source-to-Gold difference in the reconciliation bridge; this accounting result does not decide whether the rejected rows should be accepted by the business.

## Limitations

- Each run loads a complete snapshot; there is no change data capture or partial-file loading.
- SCD Type 2 effective dates record when the warehouse saw a change, not when it happened in the source.

## Project background

The project is based on the SQL Data Warehouse tutorial structure and sample dataset by Baraa Khatib Salkini. This repository adds a documented full-snapshot pipeline, data quality checks, SCD Type 2 dimensions, reconciliation, and a small set of curated analytics queries.
