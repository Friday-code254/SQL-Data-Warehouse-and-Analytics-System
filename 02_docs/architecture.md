# Warehouse architecture

~~~mermaid
flowchart LR
  A[Complete CRM and ERP CSV snapshot] --> B[Python preflight]
  B --> C[SQL Server verifies files and stages rows]
  C --> D[Bronze append-only source batches]
  D --> E[Silver full snapshot cleansing]
  E --> F[Gold SCD Type 2 dimensions]
  E --> G[Gold sales fact snapshot]
  F --> G
  G --> H[Reconciliation and quality checks]
  H --> I{Critical checks pass?}
  I -->|Yes| J[Commit Gold and mark the run successful]
  I -->|No| K[Roll back Gold and record the failed run]
  J --> L[Six analytics queries]
~~~

Python reads the six configured CSV files and checks their encoding, headers, row shapes, line endings, row counts, and checksums. SQL Server then verifies the files again and bulk-loads them into temporary tables. The SQL Server service account must be able to read the same files. Only after all six files pass does Bronze store new source batches. A file with a checksum already in the source history reuses its original batch.

Each pipeline run rebuilds the current Silver tables from the complete snapshot inside a transaction. Invalid and duplicate records are recorded with a reason code. The Gold sales fact is rebuilt from accepted Silver rows. Gold customer and product dimensions keep prior versions with SCD Type 2; the date dimension grows to cover dates in the current snapshot.

Gold publication, source-to-Gold reconciliation, and critical quality checks share a transaction. A critical check failure rolls back Gold publication and leaves the last successful Gold snapshot available. Run and table logs, data quality results, rejected records, and reconciliation results remain available for review.

Each run processes all six files as a complete snapshot. Replaying an unchanged file is idempotent in Bronze because the file checksum maps to its existing source batch.

For stage inputs, outputs, and failure boundaries, see the [pipeline dependencies](pipeline_dependencies.md). For field transformations, see [column lineage](column_lineage.md).
