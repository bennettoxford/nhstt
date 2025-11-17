# Determine if a reporting period represents a financial year

Accepts both legacy "FY2023-24" codes and new "2023-24" format. Values
ending in 13-31 are treated as financial years

## Usage

``` r
is_financial_year_period(period)
```

## Arguments

- period:

  Character, specifying period to check (e.g., "2023-24" or "FY2023-24")

## Value

Logical
