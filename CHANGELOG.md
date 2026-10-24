# Project scope

This repository contains a SQL Server warehouse built around a full-snapshot ETL pipeline.

- Python checks six CRM and ERP CSV files before loading.
- Bronze preserves source rows and avoids duplicate batches when a file checksum is replayed.
- Silver cleans and deduplicates data and records rejected rows with reason codes.
- Gold contains the sales star schema and SCD Type 2 customer and product dimensions.
- Reconciliation and data quality checks record how the source snapshot maps to Gold.
- Six curated SQL queries explore sales, products, customers, and shipping.
- One GitHub Actions workflow checks the Python, SQL, and SQL Server integration paths.
