# Extract England totals from one legacy annual source file

Extract England totals from one legacy annual source file

## Usage

``` r
extract_annual_legacy_totals(path, tables)
```

## Arguments

- path:

  Character, specifying path to the ZIP pack or XLSX workbook

- tables:

  Named list, specifying for each table a named list of
  `measure = column`, where column is a CSV header or an XLSX column
  number

## Value

One-row tibble in the wide format used by the `measures_annual` tidy
config, with one column per configured measure
