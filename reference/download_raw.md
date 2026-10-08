# Download and cache raw data

Download and cache raw data

## Usage

``` r
download_raw(dataset, period, frequency, use_cache = TRUE)
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

Character path to cached file
