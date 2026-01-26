# Get position of therapy types within the referral pathways

Get the number of courses of therapy by therapy type and position within
the referral pathway. A course of therapy is a set of 2 or more attended
treatment appointments where the same therapy type is recorded that
occur within a referral pathway. Counts are based on referrals finishing
a course of treatment in the year. Other low/high internsity and
low/high employment support therapy types have been excluded from theses
analyses.

## Usage

``` r
get_therapy_position_annual(periods = NULL, use_cache = TRUE)
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

## Details

Raw data is automatically stored in parquet format for efficient
compression.

## Examples

``` r
if (FALSE) { # \dontrun{
# Get all annual periods
therapy_position_df <- get_therapy_position_annual()

# Get specific annual periods
therapy_position_df <- get_therapy_position_annual(periods = c("2023-24", "2024-25"))

# Bypass cache to use latest tidying logic
therapy_position_df <- get_therapy_position_annual(periods = "2023-24", use_cache = FALSE)
} # }
```
