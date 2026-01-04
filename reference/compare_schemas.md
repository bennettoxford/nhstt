# Compare schemas across periods

Reads the schema file and creates a comparison table showing which
columns exist in which periods.

## Usage

``` r
compare_schemas(file_pattern, schema_file = NULL)
```

## Arguments

- file_pattern:

  Character, pattern to match CSV files (e.g., "effect-size", "main")

- schema_file:

  Character, path to schema CSV file. If NULL (default), uses the schema
  file from the installed package. Requires package to be installed with
  [`pak::local_install()`](https://pak.r-lib.org/reference/local_install.html)

## Value

Invisibly returns a data frame.
