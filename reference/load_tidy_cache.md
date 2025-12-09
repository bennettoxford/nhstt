# Load tidy data from Parquet cache

Load tidy data from Parquet cache

## Usage

``` r
load_tidy_cache(dataset, period, frequency)
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

## Value

Tibble
