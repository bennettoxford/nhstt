# Get annual Patient Reported Outcome measures (PROMs)

Get annual Patient Reported Outcome Measures (PROMs) mean and SD broken
down by therapy type, problem descriptor, and providers.

## Usage

``` r
get_proms_annual(periods = NULL, use_cache = TRUE)
```

## Arguments

- periods:

  Character vector, specifying periods (e.g., "2023-24", "2024-25"). If
  NULL (default), returns all available annual periods

- use_cache:

  Logical, specifying whether to use cached data if available. Default
  TRUE.

## Value

Tibble with key measures data in long format

## References

NHS England. [NHS Talking Therapies for Anxiety and Depression Annual
Reports](https://digital.nhs.uk/data-and-information/publications/statistical/nhs-talking-therapies-for-anxiety-and-depression-annual-reports)

## Examples

``` r
if (FALSE) { # \dontrun{
# Get all annual periods
proms_df <- get_proms_annual()

# Get specific annual periods
proms_df <- get_proms_annual(periods = c("2023-24", "2024-25"))

# Re-download to get the latest data version
proms_df <- get_proms_annual(use_cache = FALSE)
} # }
```
