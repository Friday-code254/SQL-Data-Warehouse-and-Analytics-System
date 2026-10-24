# Pipeline dependencies and failure boundaries

## Dependency graph

~~~mermaid
flowchart TD
  A[Six complete CSV inputs] --> B[Python validates files and builds manifest]
  B --> C[SQL Server verifies checksums and stages rows]
  C -->|All six pass| D[Bronze batches and source manifest]
  C -->|Any source fails| X[Record failed run; Gold stays unchanged]
  D --> E[Silver full snapshot cleaning and rejects]
  E -->|Failure| Y[Roll back Silver transaction]
  E -->|Success| F[Gold SCD Type 2 dimensions and fact snapshot]
  F --> G[Source-to-Gold reconciliation]
  G --> H[Data quality checks]
  H -->|Critical failure| I[Roll back Gold publication]
  H -->|Pass| J[Commit Gold and mark run successful]
  J --> K[Six curated analytics queries]
~~~

## Stage contracts

| Stage | Reads | Writes | Publication rule |
| --- | --- | --- | --- |
| Python preflight | etl.source_config and six CSV files | Validated manifest in memory | No warehouse rows change. |
| Bronze | Manifest and original CSV files | Append-only Bronze batches, checksum history, source-file run details, table logs | SQL Server verifies checksums and row counts for all six files before saving any new batch. Replayed checksums reuse their original batch. |
| Silver | Bronze batches registered for the current run | Cleansed CRM/ERP snapshot and reason-coded rejects | All current Silver tables are rebuilt in one transaction from the complete snapshot. |
| Gold | Accepted Silver snapshot | SCD Type 2 customer/product dimensions, date dimension, sales fact snapshot | Gold, reconciliation, and quality checks run in one transaction. Critical failures roll back publication. |
| Analytics | Committed Gold tables | Query result sets | Six documented SQL scripts. |

Run-level status is in etl.pipeline_runs. Per-stage and per-table outcomes are in etl.table_load_logs. Quality outcomes, rejected rows, and reconciliation values are recorded in etl.data_quality_results, etl.rejected_records, and etl.reconciliation_results.
