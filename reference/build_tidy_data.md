# Build combined tidy parquet for a dataset

Developer tool. Runs the full raw-to-tidy pipeline for all available
periods, combines them into a single parquet file, and writes it to
`data-raw/`.

## Usage

``` r
build_tidy_data(dataset, raw_datasets = dataset)
```

## Arguments

- dataset:

  Character, name of the published dataset as listed in
  tidy_data_sources.yml (e.g., "activity_performance_monthly")

- raw_datasets:

  Character vector, raw config dataset(s) to combine into the published
  parquet. Defaults to `dataset`; pass several names to combine multiple
  raw datasets (e.g. the main and additional metadata sheets).

## Value

Invisibly returns the path to the written parquet file

## Details

After running this function, upload the resulting parquet to a GitHub
Release and update `inst/config/tidy_data_sources.yml` with the new
version.
