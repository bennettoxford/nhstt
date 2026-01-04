# Extract schemas from archive files

Extracts column names from all CSV files in an archive across specified
periods. Returns a data frame useful for tracking schema changes over
time and spotting column name variations across periods.

## Usage

``` r
extract_archive_schemas(archive_name, periods = NULL)
```

## Arguments

- archive_name:

  Character, archive name (e.g., "annual_main")

- periods:

  Character vector, periods to extract schemas for (e.g., c("2024-25",
  "2023-24")). If NULL (default), extracts schemas for all available
  periods

## Value

Data frame with columns:

- period:

  Character, reporting period (e.g., "2024-25")

- archive_name:

  Character, archive name

- csv_file:

  Character, CSV filename

- column:

  Character, column name from the raw data

Sorted by period (descending), csv_file, and column name.
