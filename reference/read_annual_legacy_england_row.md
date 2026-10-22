# Read the England row of a legacy annual table

CSV tables mark England with `"England"` in the first column. XLSX
sheets mark it with `"England total"` in the first column.

## Usage

``` r
read_annual_legacy_england_row(path, table)
```

## Arguments

- path:

  Character, specifying path to the ZIP pack or XLSX workbook

- table:

  Character, specifying the CSV file pattern (ZIP) or sheet name (XLSX)

## Value

List of the England row's values. CSV values are named by column header.
XLSX values have no names, so pick them by column number.
