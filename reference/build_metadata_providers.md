# Build provider organisation metadata from ODS

Developer tool, run as part of
[`build_tidy_data()`](https://bennettoxford.github.io/nhstt/reference/build_tidy_data.md).
Looks up every provider in the published annual measures in ODS, adds
latitude and longitude for each postcode, and adds the last period each
provider reported in the annual, quarterly, and monthly data.

## Usage

``` r
build_metadata_providers()
```

## Value

Tibble with provider organisation metadata
