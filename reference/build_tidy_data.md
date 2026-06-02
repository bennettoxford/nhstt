# Build combined tidy parquet for a dataset

Developer tool. Runs the full raw-to-tidy pipeline for all available
periods, combines them into a single parquet file, and writes it to
`data-raw/`.

## Usage

``` r
build_tidy_data(dataset, frequency = NULL)
```

## Arguments

- dataset:

  Character, dataset name (e.g., "activity_performance_monthly")

- frequency:

  Character, "annual" or "monthly". Inferred from dataset name if NULL.

## Value

Invisibly returns the path to the written parquet file

## Details

After running this function, upload the resulting parquet to a GitHub
Release and update `inst/config/tidy_data_sources.yml` with the new
version and URL.
