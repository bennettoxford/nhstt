# Extract a start/end time qualifier from measure names

Splits a leading "start"/"end" qualifier off `measure_name` into a new
`measure_time` column (e.g., `"start_phq"` becomes
`measure_name = "phq"`, `measure_time = "start"`). Measure names without
this qualifier are left unchanged and get `NA` for `measure_time`.

## Usage

``` r
extract_measure_time(df, regex)
```

## Arguments

- df:

  Tibble, specifying data with a `measure_name` column

- regex:

  Character, specifying a regex with two capture groups: the time
  qualifier and the remaining measure name

## Value

Tibble with `measure_time` column added
