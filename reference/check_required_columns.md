# Check that a data frame has the required columns

Check that a data frame has the required columns

## Usage

``` r
check_required_columns(
  data,
  required_cols,
  arg,
  hint = NULL,
  call = caller_env()
)
```

## Arguments

- data:

  Data frame to check

- required_cols:

  Character vector of column names that must be present

- arg:

  Character, name of the user-facing argument for the error message

- hint:

  Optional named character vector appended to the error message

- call:

  Environment reported as the source of the error

## Value

Invisible TRUE, aborts if any required column is missing
