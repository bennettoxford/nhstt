# Get package data path

Returns path to tidy data shipped with the package. Used as fallback
when network downloads fail in GitHub Actions.

## Usage

``` r
get_package_data_path(dataset, period, frequency, dataset_version = NULL)
```

## Arguments

- dataset:

  Character, specifying dataset name (e.g., "metadata")

- period:

  Character, specifying reporting period (e.g., "2025-07")

- frequency:

  Character, specifying report frequency ("monthly" or "annual")

- dataset_version:

  Character, specifying dataset version (e.g., "0.1.0"). Default NULL

## Value

Character path to parquet file, or NULL if not available

## Details

This is a temporary workaround for metadata files hosted on
`digital.nhs.uk`, which are blocked in CI environments. This function
will likely be removed once data is archived on Zenodo, where we expect
no download issues.
