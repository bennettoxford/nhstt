# Build tidy England totals for the legacy annual periods

Developer tool, called by
[`build_tidy_data()`](https://bennettoxford.github.io/nhstt/reference/build_tidy_data.md)
for datasets with a `legacy_archive` in the raw config. Downloads each
file in that archive, then reads and checks its England totals. Runs the
dataset's tidy config, so the rows have the same format as 2017-18
onwards.

## Usage

``` r
tidy_annual_legacy_totals(dataset)
```

## Arguments

- dataset:

  Character, specifying dataset name (e.g., `"measures_annual"`)

## Value

Tibble in the dataset's tidy schema
