# Record raw download metadata

Record raw download metadata

## Usage

``` r
write_raw_downloads_json(
  dataset,
  period,
  frequency,
  url,
  source_format,
  storage_format,
  raw_data_hash,
  file_size
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

- url:

  Character, specifying source URL

- source_format:

  Character, specifying original format ("zip", "rar", "csv")

- storage_format:

  Character, specifying how it's stored ("csv", "parquet")

- raw_data_hash:

  Character, specifying SHA256 hash of data

- file_size:

  Numeric, specifying size of stored file in bytes
