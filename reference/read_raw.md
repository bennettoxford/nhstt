# Read raw dataset from cache

Downloads (if needed) and reads a single raw dataset file into memory.
All data is stored as parquet files (archives are extracted during
download).

## Usage

``` r
read_raw(dataset, period, frequency, use_cache = TRUE)
```

## Arguments

- dataset:

  Character, specifying dataset name (e.g., "measures_annual",
  "measures_monthly")

- period:

  Character, specifying reporting period (e.g., "2023-24" for annual,
  "2026-27-q1" for quarterly, "2025-09" for monthly)

- frequency:

  Character, specifying report frequency ("annual", "quarterly" or
  "monthly")

- use_cache:

  Logical, specifying whether to use cached data if available. Default
  TRUE

## Value

Tibble with raw data
