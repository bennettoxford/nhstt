# Validate format-specific source fields

Validate format-specific source fields

## Usage

``` r
validate_source_format_fields(
  source,
  source_format,
  dataset_name,
  source_index
)
```

## Arguments

- source:

  List, source configuration

- source_format:

  Character, format type

- dataset_name:

  Character, dataset name for error messages

- source_index:

  Integer, source index for error messages

## Value

Invisible TRUE if valid, aborts otherwise
