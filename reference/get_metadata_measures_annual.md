# Get annual metadata for data measures

Combines the "Data measures (main)" and "Data measures (additional)"
sheets released alongside the annual NHS Talking Therapies reports.

## Usage

``` r
get_metadata_measures_annual(periods = NULL, use_cache = TRUE)
```

## Arguments

- periods:

  Character vector, specifying periods (e.g., "2023-24", "2024-25"). If
  NULL (default), returns all available annual periods

- use_cache:

  Logical, specifying whether to use cached data if available. Default
  TRUE.

## Value

Tibble containing metadata rows for each annual measure field

## Details

If network download fails (e.g., in GitHub Actions), falls back to
bundled metadata shipped with the package. This is a temporary
workaround for `digital.nhs.uk` blocking CI environments.

## Examples

``` r
if (FALSE) { # \dontrun{
measures_meta <- get_metadata_measures_annual()
} # }
```
