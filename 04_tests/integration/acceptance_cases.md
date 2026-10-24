# SQL Server acceptance cases

The GitHub Actions workflow runs SQL Server acceptance checks against a disposable SQL Server 2022 database. The Python preflight tests can also run locally:

~~~powershell
python -m unittest discover -s 04_tests/unit -v
~~~

## Acceptance coverage

1. **Checksum replay:** run the same complete snapshot twice. Bronze source history should reuse the existing batches, and the second run should add no duplicate Bronze rows.
2. **Preflight checks:** test a missing file, empty file, changed header, invalid encoding, and incorrect row width. The pipeline should fail before publishing to Gold and record the failure when SQL Server is reachable.
3. **Reject ledger:** test malformed dates, invalid amounts, and duplicate business grain. Rejected rows should have reason codes, and valid rows should continue through the pipeline.
4. **Unmatched dimensions:** provide a sales line with an unknown customer or product. Gold should omit it, record the reason, and report its count and amount in reconciliation.
5. **SCD Type 2:** change a customer attribute and reload. The previous version should expire, one current version should remain, and existing dimension keys should stay stable.
6. **Failure isolation:** point SQL Server to an unavailable source path. The run should fail and the previously published Gold facts should remain unchanged.
7. **Analytics:** execute each of the six scripts in 05_analytics/ against the loaded Gold schema.
