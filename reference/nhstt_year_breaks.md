# Yearly x-axis breaks anchored to a fixed date within each year

Yearly x-axis breaks anchored to a fixed date within each year

## Usage

``` r
nhstt_year_breaks(dates, break_start = "%Y-01-01")
```

## Arguments

- dates:

  Date vector

- break_start:

  Character, format string giving the anchor date within the first year.
  Default "%Y-01-01" (1 January)

## Value

Date vector with one break per year in the range of `dates`. When no
yearly break falls inside the range (e.g. data spanning only a few
months that do not include the anchor date), falls back to
[`pretty()`](https://rdrr.io/r/base/pretty.html) breaks so the axis is
never left unlabelled
