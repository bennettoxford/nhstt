# Get provider organisation metadata

Organisation details for every provider in the annual reports, from the
NHS Organisation Data Service (ODS).

## Usage

``` r
get_metadata_providers(use_cache = TRUE, version = NULL)
```

## Arguments

- use_cache:

  Logical, specifying whether to use cached data if available. Default
  TRUE.

- version:

  Character, specifying a pinned data version (e.g., "0.1.0"). If NULL
  (default), the latest version is used. See
  [`available_versions()`](https://bennettoxford.github.io/nhstt/reference/available_versions.md).

## Value

Tibble with provider organisation metadata. Latitude and longitude come
from each provider's postcode, looked up on
[postcodes.io](https://postcodes.io/). `retrieved_date` is the day the
data was taken from ODS. `*_last_reported` is the last period each
provider appears in the annual, quarterly, and monthly data.
`*_latest_period` is the latest period in that data.

## Examples

``` r
if (FALSE) { # \dontrun{
# Get provider metadata
nhstt_providers <- get_metadata_providers()
} # }
```
