# Get a pre-built tidy dataset

Shared core for all user-facing `get_*()` functions. Looks up the
dataset in `tidy_data_sources.yml`, downloads the pre-built parquet from
the GitHub Release if the cache is missing or stale, and filters to the
requested periods.

## Usage

``` r
get_tidy_dataset(dataset, periods = NULL, use_cache = TRUE)
```

## Arguments

- dataset:

  Character, dataset name as listed in tidy_data_sources.yml

- periods:

  Character vector of periods, or NULL for all periods

- use_cache:

  Logical, whether to use cached data if available

## Value

Tibble, ordered most-recent period first

## Details

Requested periods are validated against the periods actually present in
the downloaded data, so a period that exists in the developer config but
not yet in the published parquet raises an error instead of silently
returning zero rows.
