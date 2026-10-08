# Get quarterly activity and performance measures

Get quarterly activity and performance measures by organisation, broken
down by demographic and clinical characteristics (e.g., age group,
ethnic group, problem descriptor). Organisations are England,
commissioning regions, ICBs, sub-ICBs, providers, and sub-ICB and
provider pairs.

## Usage

``` r
get_measures_quarterly(periods = NULL, use_cache = TRUE, version = NULL)
```

## Arguments

- periods:

  Character vector, specifying periods (e.g., "2026-27-q1",
  "2025-26-q4"). If NULL (default), returns all available quarterly
  periods

- use_cache:

  Logical, specifying whether to use cached data if available. Default
  TRUE.

- version:

  Character, specifying a pinned data version (e.g., "0.1.0"). If NULL
  (default), the latest version is used. See
  [`available_versions()`](https://bennettoxford.github.io/nhstt/reference/available_versions.md).

## Value

Tibble with quarterly measures data in long format

## References

NHS England. [NHS Talking Therapies Monthly Statistics Including
Employment
Advisors](https://digital.nhs.uk/data-and-information/publications/statistical/nhs-talking-therapies-monthly-statistics-including-employment-advisors)

NHS England. [NHS Talking Therapies Data Quality Note (monthly,
quarterly)](https://digital.nhs.uk/binaries/content/assets/website-assets/data-and-information/datasets/nhs-talking-therapies/nhs_talking_therapies_dq_note-260327.xlsx)

## Examples

``` r
if (FALSE) { # \dontrun{
# Get all quarterly periods
measures_df <- get_measures_quarterly()

# Get specific quarterly periods
measures_df <- get_measures_quarterly(periods = c("2026-27-q1", "2025-26-q4"))

# Re-download to get the latest data version
measures_df <- get_measures_quarterly(use_cache = FALSE)

# Pin to a specific data version for reproducibility
measures_df <- get_measures_quarterly(version = "0.1.0")
} # }
```
