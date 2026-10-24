/* Fresh installation. Use an empty SQL Server instance or choose another database name first. */
:ON ERROR EXIT
USE master;
GO
IF DB_ID(N'DataWarehouse') IS NOT NULL
BEGIN
    ;THROW 51000, 'DataWarehouse already exists. This installer is for a fresh database only.', 1;
END;
GO
CREATE DATABASE DataWarehouse;
GO
USE DataWarehouse;
GO
CREATE SCHEMA bronze;
GO
CREATE SCHEMA silver;
GO
CREATE SCHEMA gold;
GO
CREATE SCHEMA etl;
GO
:r 03_scripts/etl/ddl_etl.sql
:r 03_scripts/bronze/ddl_bronze.sql
:r 03_scripts/silver/ddl_silver.sql
:r 03_scripts/gold/ddl_gold.sql
:r 03_scripts/bronze/proc_load_bronze.sql
:r 03_scripts/silver/proc_load_silver.sql
:r 03_scripts/gold/proc_load_gold.sql
:r 03_scripts/etl/proc_build_reconciliation.sql
:r 03_scripts/etl/proc_run_quality_checks.sql
:r 03_scripts/etl/proc_record_preflight_failure.sql
:r 03_scripts/etl/proc_load_warehouse.sql
