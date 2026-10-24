# Design decisions

1. **Full snapshots:** the six supplied CSVs are complete snapshots, not change-data feeds. Every run rebuilds the current Silver snapshot and Gold sales facts. Bronze keeps one copy per source file checksum so replay does not duplicate raw batches.
2. **Safe ingestion:** Python validates UTF-8 encoding, exact headers, column counts, line endings, row counts, and checksums. SQL Server rechecks file checksums and row counts before saving Bronze data. The SQL Server service account needs access to the source files.
3. **Amount rules:** Silver and Gold use DECIMAL(19,4). Quantity must be positive. When one of sales or price is missing and the other amount plus quantity are valid, the missing value is derived and tagged. Invalid, negative, missing-both, or inconsistent values are rejected.
4. **Product dates:** product versions are ordered by product business key and start date. An end date that conflicts with the next version is repaired to the day before the next start date; an invalid end date on the latest version is cleared. Silver stores a correction code.
5. **Sales grain:** one row represents an order line for an order, product business key, customer, and order date. Silver and Gold constraints enforce this grain.
6. **Dimension history:** Gold customer and product dimensions use SCD Type 2. Since the sources do not contain reliable change-effective timestamps, the warehouse observation time starts each version. Current-snapshot facts resolve to the current dimension versions.
7. **Unmatched facts:** a sales line without a current customer or product dimension is excluded from Gold and recorded in the reject ledger. Reconciliation reports its row and amount impact.

## Table grain

- gold.fact_sales: one accepted line per order, product, customer, and order date.
- gold.dim_customers: one row per customer version, with at most one current version.
- gold.dim_products: one row per product business-key version, with at most one current version.
- gold.dim_date: one row per calendar date, plus key 0 for an unknown date.
