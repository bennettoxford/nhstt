# Resolve periods argument

Resolve periods argument

## Usage

``` r
resolve_periods(periods, dataset, frequency)
```

## Arguments

- periods:

  Character vector or NULL, specifying periods (e.g., c("2023-24",
  "2024-25") for annual, c("2025-08", "2025-09") for monthly). Default
  NULL returns all periods

- dataset:

  Character, specifying dataset name (e.g., "key_measures",
  "activity_performance")

- frequency:

  Character, specifying report frequency ("annual" or "monthly")

## Value

Character vector of validated periods
