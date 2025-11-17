# Pivot measures to long format

Pivot measures to long format

## Usage

``` r
pivot_longer_measures(data_list, pivot_config)
```

## Arguments

- data_list:

  Named list, specifying tibbles (e.g., list("2023-24" = df1, "2024-25"
  = df2))

- pivot_config:

  List, specifying pivot configuration with elements:

  - id_cols: Character vector, ID columns to preserve

  - measure_cols: Character vector, measure columns to pivot

  - sep: Character, regex pattern to separate measure names

  - into: Character vector, output column names for separated parts

## Value

Tibble in long format
