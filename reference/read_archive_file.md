# Read a file from an archive

Downloads an archive and reads a specific CSV file from it.

## Usage

``` r
read_archive_file(archive_name, period, file_pattern)
```

## Arguments

- archive_name:

  Character, archive name (e.g., "annual_main")

- period:

  Character, archive period (e.g., "2024-25")

- file_pattern:

  Character, CSV filename or pattern to match (e.g., "main",
  "therapy-type")

## Value

Tibble with raw data from the CSV file
