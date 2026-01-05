# Extract SNOMED CT codes from text

To extract SNOMED CT codes we use a regex pattern that matches 6 to 18
digit numbers that don't start with zero.

## Usage

``` r
str_extract_snomed(x)
```

## Arguments

- x:

  A character vector containing text

## Value

A list of character vectors
