# Add the last period each provider reported

For each of the annual, quarterly, and monthly datasets, adds the last
period a provider appears in (`*_last_reported`, NA if never) and the
latest period in the whole dataset (`*_latest_period`).

## Usage

``` r
add_provider_reporting(
  providers,
  measures_annual,
  measures_quarterly,
  measures_monthly
)
```

## Arguments

- providers:

  Tibble, providers with an `org_code` column

- measures_annual:

  Tibble, as returned by
  [`get_measures_annual()`](https://bennettoxford.github.io/nhstt/reference/get_measures_annual.md)

- measures_quarterly:

  Tibble, as returned by
  [`get_measures_quarterly()`](https://bennettoxford.github.io/nhstt/reference/get_measures_quarterly.md)

- measures_monthly:

  Tibble, as returned by
  [`get_measures_monthly()`](https://bennettoxford.github.io/nhstt/reference/get_measures_monthly.md)

## Value

`providers` with six added columns

## Details

Developer tool, run as part of
[`build_metadata_providers()`](https://bennettoxford.github.io/nhstt/reference/build_metadata_providers.md).
