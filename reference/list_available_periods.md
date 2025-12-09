# List available periods for a dataset and frequency

List available periods for a dataset and frequency

## Usage

``` r
list_available_periods(dataset, frequency, include_development = FALSE)
```

## Arguments

- dataset:

  Character, specifying dataset name

- frequency:

  Character, specifying report frequency ("annual" or "monthly")

- include_development:

  Logical, specifying whether to include periods marked with development
  = true. Default FALSE

## Value

Character vector of available periods
