# Generic tidy pipeline for all datasets

Applies configuration-driven transformations to convert raw data to tidy
format. Supports both wide-to-long pivoting (measures_annual) and
long-format data (measures_monthly).

## Usage

``` r
tidy_dataset(raw_data_list, dataset, frequency)
```

## Arguments

- raw_data_list:

  Named list, specifying raw tibbles (e.g., list("2023-24" = df))

- dataset:

  Character, specifying dataset name (e.g., "measures_annual")

- frequency:

  Character, specifying frequency ("annual", "quarterly" or "monthly")

## Value

Tibble in tidy long format
