# Write tidy data to Parquet cache

Write tidy data to Parquet cache

## Usage

``` r
write_tidy_cache(data, dataset, period, frequency, raw_data_hash, raw_data_url)
```

## Arguments

- data:

  Tibble, containing cleaned data

- dataset:

  Character, specifying dataset name (e.g., "key_measures_annual",
  "activity_performance_monthly")

- period:

  Character, specifying reporting period (e.g., "2023-24" for annual,
  "2025-09" for monthly)

- frequency:

  Character, specifying report frequency ("annual" or "monthly")

- raw_data_hash:

  Character, specifying SHA256 hash of raw data

- raw_data_url:

  Character, specifying URL of source data
