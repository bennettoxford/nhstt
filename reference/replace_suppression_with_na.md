# Replace NHS suppression markers with NA

Converts NHS suppression markers ("\*", "-", "NULL", etc.) to NA and
coerces to numeric

## Usage

``` r
replace_suppression_with_na(x)
```

## Arguments

- x:

  Character or numeric vector, specifying values to convert

## Value

Numeric vector with suppression markers as NA
