# Get annual metadata for variable derivations

Combines the "Variables (main)" and "Variables (additional)" sheets
released alongside the annual NHS Talking Therapies reports.

## Usage

``` r
get_metadata_variables_annual(periods = NULL, use_cache = TRUE)
```

## Arguments

- periods:

  Character vector, specifying periods (e.g., "2023-24", "2024-25"). If
  NULL (default), returns all available annual periods

- use_cache:

  Logical, specifying whether to use cached data if available. Default
  TRUE.

## Value

Tibble containing metadata rows for each annual variable definition

## Examples

``` r
if (FALSE) { # \dontrun{
variables_meta <- get_metadata_variables_annual()
} # }
```
