# Apply column separation from configuration

Splits columns into multiple columns based on regex patterns (like
tidyr::separate)

## Usage

``` r
apply_separate(df, separate_config)
```

## Arguments

- df:

  Tibble, specifying data to transform

- separate_config:

  List, specifying column separation rules

## Value

Tibble with separated columns added
