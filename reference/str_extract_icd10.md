# Extract ICD-10 codes from text

To extract ICD-10 codes we use a regex pattern that matches the standard
ICD-10 format: a letter (A-Z) followed by two digits, optionally
followed by a decimal point and 1-2 more digits.

## Usage

``` r
str_extract_icd10(x)
```

## Arguments

- x:

  A character vector containing text

## Value

A character vector with extracted standardised ICD-10 codes
(comma-separated with no decimal point) or NA
