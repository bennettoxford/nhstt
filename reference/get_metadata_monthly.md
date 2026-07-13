# Get monthly metadata for NHS Talking Therapies measures

Gets the definitions, derivations, and construction notes for each
reported measure.

## Usage

``` r
get_metadata_monthly(periods = NULL, use_cache = TRUE, version = NULL)
```

## Arguments

- periods:

  Character vector, specifying periods (e.g., "2025-09", "2025-08"). If
  NULL (default), returns all available monthly periods

- use_cache:

  Logical, specifying whether to use cached data if available. Default
  TRUE.

- version:

  Character, specifying a pinned data version (e.g., "0.3.0"). If NULL
  (default), the latest version is used. See
  [`available_versions()`](https://bennettoxford.github.io/nhstt/reference/available_versions.md).

## Value

Tibble with metadata for each measure

## References

NHS England. [NHS Talking Therapies Monthly Statistics Including
Employment
Advisors](https://digital.nhs.uk/data-and-information/publications/statistical/nhs-talking-therapies-monthly-statistics-including-employment-advisors)

NHS England. [NHS Talking Therapies Monthly Statistics Including
Employment Advisors: Metadata
(monthly)](https://digital.nhs.uk/binaries/content/assets/website-assets/data-and-information/datasets/nhs-talking-therapies/reports/nhstalkingtherapies-monthly-metadata-20260709.xlsx)

NHS England. [NHS Talking Therapies Data Quality
Note](https://digital.nhs.uk/binaries/content/assets/website-assets/data-and-information/datasets/nhs-talking-therapies/nhs_talking_therapies_dq_note-260327.xlsx)

## Examples

``` r
if (FALSE) { # \dontrun{
metadata <- get_metadata_monthly()
} # }
```
