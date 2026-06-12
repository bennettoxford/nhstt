# Explore services that cross chosen thresholds

**\[experimental\]**

Shows which services cross the thresholds you choose: a median monthly
denominator count below `median_threshold`, or any single ratio at or
above `ratio_threshold` in at least one reporting period (ratios above 1
are ignored). Returns these services with their summary statistics so
you can look at them more closely and make an informed decision about
what to do with them — for example keep them, investigate them further,
or exclude them with a
[`dplyr::filter()`](https://dplyr.tidyverse.org/reference/filter.html)
call in your own code (see Examples).

## Usage

``` r
explore_services(measures, median_threshold = 20, ratio_threshold = 0.99)
```

## Arguments

- measures:

  Tibble, as returned by
  [`create_measures()`](https://bennettoxford.github.io/nhstt/reference/create_measures.md)

- median_threshold:

  Numeric, services with a median monthly denominator below this are
  grouped as "low_denominator". Default 20

- ratio_threshold:

  Numeric, services with any ratio at or above this in at least one
  period are grouped as "high_ratio". Default 0.99

## Value

Tibble of services crossing a threshold: group ("low_denominator",
"high_ratio", or "both"), followed by the columns from
[`summarise_measures()`](https://bennettoxford.github.io/nhstt/reference/summarise_measures.md)

## Examples

``` r
if (FALSE) { # \dontrun{
df_explored <- df_measures |>
  explore_services(median_threshold = 20, ratio_threshold = 0.99)

# after reviewing df_explored, exclude these services and treat
# ratios above 1 as missing
df_clean <- df_measures |>
  dplyr::filter(!org_code2 %in% df_explored$org_code2) |>
  dplyr::mutate(ratio = dplyr::if_else(ratio > 1, NA_real_, ratio))
} # }
```
