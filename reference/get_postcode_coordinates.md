# Look up postcode coordinates from postcodes.io

Developer tool, run as part of
[`build_metadata_providers()`](https://bennettoxford.github.io/nhstt/reference/build_metadata_providers.md).
Looks up current postcodes in batches. The bulk endpoint leaves out
postcodes that are no longer in use, so these are looked up one by one
from the terminated postcodes endpoint.

## Usage

``` r
get_postcode_coordinates(postcodes)
```

## Arguments

- postcodes:

  Character vector, postcodes to look up

## Value

Tibble with columns postcode, latitude, and longitude
