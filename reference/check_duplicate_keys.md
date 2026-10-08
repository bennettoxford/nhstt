# Check that no rows share the same key in the tidied data

Developer tool, run as part of
[`build_tidy_data()`](https://bennettoxford.github.io/nhstt/reference/build_tidy_data.md).
The key is every column except `value`. Duplicate keys usually mean the
same rows came from more than one raw dataset (e.g. the England rows
repeated in each quarterly CSV) and a tidy filter is missing, so this
errors rather than publishing them.

## Usage

``` r
check_duplicate_keys(df, dataset)
```

## Arguments

- df:

  Tibble, tidied data combined across all periods and raw datasets

- dataset:

  Character, published dataset name

## Value

Invisibly returns `df`
