# List available archives and their periods

Returns all archives defined in the raw configuration files along with
their available periods.

## Usage

``` r
list_archives_periods()
```

## Value

Named list where names are archive names (e.g., "annual_main",
"annual_metadata") and values are character vectors of available periods
(e.g., c("2024-25", "2023-24")) sorted in descending order
