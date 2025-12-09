# Get dataset version metadata file path

Returns the path to the JSON file that stores version metadata for a
dataset

## Usage

``` r
get_tidy_versions_json_path(dataset, frequency)
```

## Arguments

- dataset:

  Character, specifying dataset name (e.g., "key_measures_annual",
  "activity_performance_monthly")

- frequency:

  Character, specifying report frequency ("annual" or "monthly")

## Value

Character path to .versions.json file
