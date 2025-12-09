# Get versioned tidy cache path

Get versioned tidy cache path

## Usage

``` r
get_tidy_cache_path(dataset, period, frequency, dataset_version = NULL)
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

- dataset_version:

  Character, specifying dataset version (e.g., "1.0.0"). Default NULL

## Value

Character path to cached Parquet file
