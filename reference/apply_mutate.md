# Apply column mutations from configuration

Creates new columns from existing data (like dplyr::mutate)

## Usage

``` r
apply_mutate(df, mutate_config)
```

## Arguments

- df:

  Tibble, specifying data to transform

- mutate_config:

  List, specifying column creation rules

## Value

Tibble with new columns added
