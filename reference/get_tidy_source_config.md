# Get tidy source configuration for a dataset

The download URL is derived from the dataset name and version using the
GitHub Release tag convention (`{dataset-with-dashes}-v{version}`),
which is what `just release` creates. An explicit `url` field in
tidy_data_sources.yml overrides the derived URL.

## Usage

``` r
get_tidy_source_config(dataset)
```

## Arguments

- dataset:

  Character, dataset name (e.g., "activity_performance_monthly")

## Value

List with fields: version, url
