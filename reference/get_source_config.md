# Get source configuration for a dataset period

Get source configuration for a dataset period

## Usage

``` r
get_source_config(dataset, period, frequency)
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

## Value

List with url, format, csv_pattern
