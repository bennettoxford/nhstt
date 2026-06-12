# Summarise a measures table by service

**\[experimental\]**

Gives one row per service with the number of reporting periods, the
median and minimum monthly denominator count, and the median ratio for
each measure. Useful for getting an overview of which services
contribute data and how they compare.

## Usage

``` r
summarise_measures(measures)
```

## Arguments

- measures:

  Tibble, as returned by
  [`create_measures()`](https://bennettoxford.github.io/nhstt/reference/create_measures.md)

## Value

Tibble with one row per service: org_code2, org_name2, n_periods,
median_denominator, min_denominator, and one `ratio_*` column per
measure (median ratio across periods, with ratios above 1 ignored)

## Examples

``` r
if (FALSE) { # \dontrun{
df_measures |> summarise_measures()
} # }
```
