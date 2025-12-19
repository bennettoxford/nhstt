# Calculate percentiles for a numeric variable

Summarises a numeric variable by calculating specified percentiles,
optionally grouped by period and other grouping variables. Useful for
creating percentile distributions over time or across different
measures.

## Usage

``` r
summarise_percentiles(
  df,
  period_col,
  value_col,
  percentiles = seq(0.1, 0.9, 0.1),
  group_by = NULL
)
```

## Arguments

- df:

  Data frame or tibble containing the data to summarise

- period_col:

  Column name for the period variable, used for ordering results.
  Typically a date column e.g., `end_date`

- value_col:

  Column name for the numeric variable to calculate percentiles

- percentiles:

  Numeric vector of percentiles to calculate, specified as proportions
  between 0 and 1. Default is `seq(0.1, 0.9, 0.1)` (10th to 90th
  percentiles by 10s)

- group_by:

  Optional grouping variables. Can be a single column name or a vector
  of column names using [`c()`](https://rdrr.io/r/base/c.html). Default
  is `NULL`.

## Value

A tibble with columns for the period, percentile values, calculated
values, and any grouping variables.

## Examples

``` r
if (FALSE) { # \dontrun{
# Calculate percentiles by period
data |>
  summarise_percentiles(
    period_col = end_date,
    value_col = recovery_rate
  )

# Calculate quartiles grouped by measure
data |>
  summarise_percentiles(
    period_col = end_date,
    value_col = value,
    percentiles = c(0.25, 0.5, 0.75),
    group_by = measure_id
  )

# Multiple grouping variables
data |>
  summarise_percentiles(
    period_col = end_date,
    value_col = value,
    group_by = c(measure_id, region_name)
  )
} # }
```
