# Check that configured filter values match rows in the tidied data

Developer tool, run as part of
[`build_tidy_data()`](https://bennettoxford.github.io/nhstt/reference/build_tidy_data.md).
Filtering happens per period, and a filter value can legitimately be
absent from individual periods (e.g. SubICB only appears in monthly data
from mid-2022). But a value that matches no rows across all periods
combined is almost certainly misspelled in the tidy config, so this
errors rather than silently publishing a parquet with those rows
missing.

## Usage

``` r
check_filter_values(df, dataset, frequency)
```

## Arguments

- df:

  Tibble, tidied data combined across all periods

- dataset:

  Character, raw dataset name

- frequency:

  Character, "annual" or "monthly"

## Value

Invisibly returns `df`
