# Get annual key performance measures

Get annual key performance measures including referrals, assessments,
treatment completions, recovery rates, and waiting times by organisation

## Usage

``` r
get_measures_annual(periods = NULL, use_cache = TRUE, version = NULL)
```

## Arguments

- periods:

  Character vector, specifying periods (e.g., "2023-24", "2024-25"). If
  NULL (default), returns all available annual periods

- use_cache:

  Logical, specifying whether to use cached data if available. Default
  TRUE.

- version:

  Character, specifying a pinned data version (e.g., "0.1.0"). If NULL
  (default), the latest version is used. See
  [`available_versions()`](https://bennettoxford.github.io/nhstt/reference/available_versions.md).

## Value

Tibble with key measures data in long format

## References

NHS England. [NHS Talking Therapies for Anxiety and Depression Annual
Reports](https://digital.nhs.uk/data-and-information/publications/statistical/nhs-talking-therapies-for-anxiety-and-depression-annual-reports)

## Examples

``` r
if (FALSE) { # \dontrun{
# Get all annual periods
measures_df <- get_measures_annual()

# Get specific annual periods
measures_df <- get_measures_annual(periods = c("2023-24", "2024-25"))

# Re-download to get the latest data version
measures_df <- get_measures_annual(use_cache = FALSE)

# Pin to a specific data version for reproducibility
measures_df <- get_measures_annual(version = "0.1.0")
} # }
```
