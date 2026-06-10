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

## References

NHS England. [NHS Talking Therapies for Anxiety and Depression Annual
Reports](https://digital.nhs.uk/data-and-information/publications/statistical/nhs-talking-therapies-for-anxiety-and-depression-annual-reports)

## Examples

``` r
if (FALSE) { # \dontrun{
measures_meta <- get_metadata_measures_annual()
} # }
```
