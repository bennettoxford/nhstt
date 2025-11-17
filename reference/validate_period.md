# Validate period for a dataset and frequency

Validate period for a dataset and frequency

## Usage

``` r
validate_period(period, dataset, frequency)
```

## Arguments

- period:

  Character, specifying reporting period to validate (e.g., "2023-24"
  for annual, "2025-09" for monthly)

- dataset:

  Character, specifying dataset name (e.g., "key_measures",
  "activity_performance")

- frequency:

  Character, specifying report frequency ("annual" or "monthly")

## Value

Invisible TRUE if valid, aborts otherwise
