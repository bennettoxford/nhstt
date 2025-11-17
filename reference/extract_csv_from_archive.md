# Extract CSV from archive using pattern matching

Extract CSV from archive using pattern matching

## Usage

``` r
extract_csv_from_archive(archive_path, csv_pattern)
```

## Arguments

- archive_path:

  Character, specifying path to zip/rar archive

- csv_pattern:

  Character, specifying regex pattern to match CSV filename

## Value

Tibble with raw data
