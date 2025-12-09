# Clean column values to snake_case

Applies clean_str to values in specified columns

## Usage

``` r
clean_column_values(df, column_names = NULL)
```

## Arguments

- df:

  Tibble, specifying data with columns to clean

- column_names:

  Character vector, specifying column names to clean (e.g., c("measure",
  "statistic"))

## Value

Tibble with cleaned column values
