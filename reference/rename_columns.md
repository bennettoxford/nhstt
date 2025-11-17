# Rename columns

Renames columns using a mapping (for year-specific inconsistencies)

## Usage

``` r
rename_columns(df, rename_mapping)
```

## Arguments

- df:

  Tibble, specifying data with columns to rename

- rename_mapping:

  Named character vector, specifying old_name = new_name mapping

## Value

Tibble with renamed columns
