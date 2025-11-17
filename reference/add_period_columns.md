# Add period date columns

Detects period format (annual "2023-24" or monthly "2025-09") and adds
appropriate start_date and end_date columns

## Usage

``` r
add_period_columns(df)
```

## Arguments

- df:

  Tibble, specifying data with reporting_period column

## Value

Tibble with start_date and end_date columns
