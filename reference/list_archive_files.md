# List files in archives

Downloads archives and lists all CSV files for specified periods.

## Usage

``` r
list_archive_files(archive_name, periods = NULL)
```

## Arguments

- archive_name:

  Character, archive name (e.g., "annual_main"). Use
  [`list_archives_periods()`](https://bennettoxford.github.io/nhstt/reference/list_archives_periods.md)
  to see available archives

- periods:

  Character vector, periods to list files for (e.g., c("2024-25",
  "2023-24")). If NULL (default), returns files for all available
  periods

## Value

Named list where names are periods and values are character vectors of
CSV filenames, sorted alphabetically
