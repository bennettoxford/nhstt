# Replace values with NA

Converts placeholder values (e.g., "null", "All_ICB") to NA in all
character columns

## Usage

``` r
replace_values_with_na(df, values)
```

## Arguments

- df:

  Tibble, specifying data to clean

- values:

  Character vector, specifying values to replace with NA

## Value

Tibble with placeholder values as NA
