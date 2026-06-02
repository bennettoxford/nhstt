# Check whether cached tidy source matches the expected version

Returns FALSE if the parquet or sidecar is missing, or if the cached
version does not match.

## Usage

``` r
tidy_source_cache_is_current(dataset, version)
```

## Arguments

- dataset:

  Character, dataset name

- version:

  Character, expected version from tidy_data_sources.yml

## Value

Logical
