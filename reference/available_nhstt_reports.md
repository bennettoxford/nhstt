# List available NHS Talking Therapies reports

Returns a tibble with information about available datasets including
their time period coverage and frequency

## Usage

``` r
available_nhstt_reports()
```

## Value

Tibble with dataset and frequency information (one row per dataset)

## Examples

``` r
available_nhstt_reports()
#> # A tibble: 10 × 8
#>    dataset       frequency title get_function first_period last_period n_periods
#>    <chr>         <chr>     <chr> <chr>        <chr>        <chr>           <int>
#>  1 key_measures… annual    Key … get_key_mea… 2017-18      2024-25             8
#>  2 proms_annual  annual    Pati… get_proms_a… 2021-22      2024-25             4
#>  3 therapy_posi… annual    Ther… get_therapy… 2021-22      2024-25             4
#>  4 activity_per… monthly   Acti… get_activit… 2023-05      2025-09            29
#>  5 metadata_mea… annual    Annu… get_metadat… 2024-25      2024-25             1
#>  6 metadata_mea… annual    Annu… get_metadat… 2024-25      2024-25             1
#>  7 metadata_var… annual    Annu… get_metadat… 2024-25      2024-25             1
#>  8 metadata_var… annual    Annu… get_metadat… 2024-25      2024-25             1
#>  9 metadata_mea… monthly   Mont… get_metadat… 2025-07      2025-07             1
#> 10 metadata_pro… live      Prov… get_metadat… current      current             1
#> # ℹ 1 more variable: version <chr>
```
