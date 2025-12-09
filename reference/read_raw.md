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

  Character, specifying dataset name (e.g., "key_measures_annual",
  "activity_performance_monthly")

- period:

  Character, specifying reporting period (e.g., "2023-24" for annual,
  "2025-09" for monthly)

- frequency:

  Character, specifying report frequency ("annual" or "monthly")

- use_cache:

  Logical, specifying whether to use cached data if available. Default
  TRUE

## Value

Tibble with raw data
