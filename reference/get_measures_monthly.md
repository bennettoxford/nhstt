# Get monthly activity and performance measures

Get monthly activity and performance indicators by organisation.

## Usage

``` r
get_measures_monthly(periods = NULL, use_cache = TRUE, version = NULL)
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

Tibble with activity and performance data in long format

## References

NHS England. [NHS Talking Therapies Monthly Statistics Including
Employment
Advisors](https://digital.nhs.uk/data-and-information/publications/statistical/nhs-talking-therapies-monthly-statistics-including-employment-advisors)

NHS England. [NHS Talking Therapies Data Quality Note (monthly,
quarterly)](https://digital.nhs.uk/binaries/content/assets/website-assets/data-and-information/datasets/nhs-talking-therapies/nhs_talking_therapies_dq_note-260327.xlsx)

## Examples

``` r
if (FALSE) { # \dontrun{
# Get all monthly periods
measures_df <- get_measures_monthly()

# Get specific monthly periods
measures_df <- get_measures_monthly(periods = c("2025-09", "2025-08"))

# Re-download to get the latest data version
measures_df <- get_measures_monthly(use_cache = FALSE)

# Pin to a specific data version for reproducibility
measures_df <- get_measures_monthly(version = "0.3.0")
} # }
```
