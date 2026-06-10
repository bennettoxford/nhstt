# Extract schemas from direct source files

Extracts column names from a dataset's raw source files across specified
periods. Companion to
[`extract_archive_schemas()`](https://bennettoxford.github.io/nhstt/reference/extract_archive_schemas.md)
for datasets whose sources are standalone files (e.g. the monthly CSVs)
rather than archives. Returns a data frame useful for tracking schema
changes over time and spotting column name variations across periods.

## Usage

``` r
extract_source_schemas(dataset, periods = NULL)
```

## Arguments

- dataset:

  Character, dataset name (e.g., "activity_performance_monthly")

- periods:

  Character vector, periods to extract schemas for (e.g., c("2025-09",
  "2025-08")). If NULL (default), extracts schemas for all available
  periods

## Value

Data frame with columns:

- period:

  Character, reporting period (e.g., "2025-09")

- dataset:

  Character, dataset name

- column:

  Character, column name from the raw data

Sorted by period (descending) and column name.

## Details

Sources are read via
[`read_raw()`](https://bennettoxford.github.io/nhstt/reference/read_raw.md),
so all configured formats are supported and the raw cache is used when
available.
