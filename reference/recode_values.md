# Recode values

Replaces values in columns using a mapping (e.g., for a category that is
labelled differently in some periods)

## Usage

``` r
recode_values(df, recode_config)
```

## Arguments

- df:

  Tibble, specifying data with columns to recode

- recode_config:

  Named list, specifying for each column a mapping of
  `new_value: old_value` (e.g., list(variable_a = list(None = "null")))

## Value

Tibble with recoded values
