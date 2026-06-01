# Get monthly activity and performance measures

Get monthly activity and performance indicators by organisation.

## Usage

``` r
get_activity_performance_monthly(periods = NULL, use_cache = TRUE)
```

## Arguments

- periods:

  Character vector, specifying periods (e.g., "2025-09", "2025-08"). If
  NULL (default), returns all available monthly periods

- use_cache:

  Logical, specifying whether to use cached data if available. Default
  TRUE.

## Value

Tibble with activity and performance data in long format

## Details

Raw data is automatically stored in parquet format for efficient
compression.

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
activity_df <- get_activity_performance_monthly()

# Get specific monthly periods
activity_df <- get_activity_performance_monthly(periods = c("2025-09", "2025-08"))

# Bypass cache to use latest tidying logic
activity_df <- get_activity_performance_monthly(periods = "2025-09", use_cache = FALSE)
} # }
```
