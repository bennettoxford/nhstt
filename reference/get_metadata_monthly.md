# Get monthly metadata for NHS Talking Therapies measures

Retrieves the definitions, derivations, and construction notes for each
reported measure.

## Usage

``` r
get_metadata_monthly(periods = NULL, use_cache = TRUE)
```

## Arguments

- periods:

  Character vector, specifying periods (e.g., "2025-09", "2025-08"). If
  NULL (default), returns all available monthly periods

- use_cache:

  Logical, specifying whether to use cached data if available. Default
  TRUE.

## Value

Tibble with metadata for each measure

## Details

Raw data is stored in parquet format for efficient compression.

If network download fails (e.g., in GitHub Actions), falls back to
bundled metadata shipped with the package. This is a temporary
workaround for `digital.nhs.uk` blocking CI environments.

## Examples

``` r
if (FALSE) { # \dontrun{
metadata <- get_metadata_monthly()
} # }
```
