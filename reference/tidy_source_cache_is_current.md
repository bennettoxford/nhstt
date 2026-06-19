# Check whether a versioned tidy source is cached

Returns TRUE if the parquet for this exact dataset+version exists on
disk. Because the version is part of the filename, no sidecar comparison
is needed.

## Usage

``` r
tidy_source_cache_is_current(dataset, version)
```

## Arguments

- dataset:

  Character, dataset name

- version:

  Character, expected version

## Value

Logical
