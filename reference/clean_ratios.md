# Set ratios above `max_ratio` to NA

Single place for the rule that ratios above `max_ratio` cannot be
interpreted and are treated as missing, used by
[`summarise_measures()`](https://bennettoxford.github.io/nhstt/reference/summarise_measures.md)
and
[`explore_services()`](https://bennettoxford.github.io/nhstt/reference/explore_services.md).

## Usage

``` r
clean_ratios(ratio, max_ratio = 1)
```

## Arguments

- ratio:

  Numeric vector of ratios

- max_ratio:

  Numeric, ratios above this are set to NA. Default 1

## Value

Numeric vector with ratios above `max_ratio` set to NA
