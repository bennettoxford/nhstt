# Prepare tidy data for any dataset (generic internal function)

Orchestrates the complete tidy pipeline: read raw → tidy → cache. This
replaces all dataset-specific fetch_and_tidy\_\* functions.

## Usage

``` r
prepare_tidy_data(dataset, period, frequency)
```

## Arguments

- dataset:

  Character, specifying dataset name (e.g., "key_measures",
  "activity_performance")

- period:

  Character, specifying reporting period (e.g., "2023-24" for annual,
  "2025-09" for monthly)

- frequency:

  Character, specifying frequency ("annual" or "monthly")

## Value

Tibble with tidy data
