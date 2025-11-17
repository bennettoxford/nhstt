# Generic tidy pipeline for all datasets

Applies configuration-driven transformations to convert raw data to tidy
format. Supports both wide-to-long pivoting (key_measures) and
long-format data (activity_performance).

## Usage

``` r
tidy_dataset(raw_data_list, dataset, frequency)
```

## Arguments

- raw_data_list:

  Named list, specifying raw tibbles (e.g., list("2023-24" = df))

- dataset:

  Character, specifying dataset name (e.g., "key_measures")

- frequency:

  Character, specifying frequency ("annual" or "monthly")

## Value

Tibble in tidy long format
