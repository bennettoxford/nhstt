# List available NHS Talking Therapies reports

Returns a tibble with information about available datasets including
their time period coverage and frequency

## Usage

``` r
available_nhstt_reports()
```

## Value

Tibble with dataset and frequency information (one row per
dataset-frequency combination)

## Examples

``` r
available_nhstt_reports()
#> # A tibble: 2 × 8
#>   dataset        frequency title get_function first_period last_period n_periods
#>   <chr>          <chr>     <chr> <chr>        <chr>        <chr>           <int>
#> 1 activity_perf… monthly   Acti… get_activit… 2023-05      2025-09            29
#> 2 key_measures   annual    Key … get_key_mea… 2017-18      2024-25             8
#> # ℹ 1 more variable: version <chr>
```
