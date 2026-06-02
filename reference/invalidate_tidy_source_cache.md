# Remove stale tidy source cache files

Deletes the parquet and sidecar JSON for a dataset so they are
re-downloaded on the next call.

## Usage

``` r
invalidate_tidy_source_cache(dataset)
```

## Arguments

- dataset:

  Character, dataset name

## Value

Invisible TRUE
