# Most recent service name for each org code

Service names can change across reporting periods (e.g. after the NHS TT
rebrand), so summaries and plot labels use the most recent name.

## Usage

``` r
latest_org_names(measures)
```

## Arguments

- measures:

  Tibble, as returned by
  [`create_measures()`](https://bennettoxford.github.io/nhstt/reference/create_measures.md)

## Value

Tibble with one row per org_code2 and its most recent org_name2
