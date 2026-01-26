# Create raw fixture file for testing

Downloads raw data for a dataset/period and saves the first n rows as a
fixture CSV file for offline testing.

## Usage

``` r
create_raw_fixture(dataset, period, frequency, n_rows = 5, overwrite = FALSE)
```

## Arguments

- dataset:

  Character, dataset name (e.g., "therapy_position_annual")

- period:

  Character, period (e.g., "2021-22")

- frequency:

  Character, "annual" or "monthly"

- n_rows:

  Integer, number of rows to save (default 5)

- overwrite:

  Logical, whether to overwrite existing fixture (default FALSE)

## Value

Invisibly returns the fixture path

## Note

No unit tests - would require mocking download work.
