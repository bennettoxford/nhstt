# Record version metadata

Record version metadata

## Usage

``` r
write_tidy_versions_json(
  dataset,
  period,
  frequency,
  raw_data_hash,
  raw_data_url
)
```

## Arguments

- dataset:

  Character, specifying dataset name (e.g., "key_measures",
  "activity_performance")

- period:

  Character, specifying reporting period (e.g., "2023-24" for annual,
  "2025-09" for monthly)

- frequency:

  Character, specifying report frequency ("annual" or "monthly")

- raw_data_hash:

  Character, specifying SHA256 hash

- raw_data_url:

  Character, specifying source URL
