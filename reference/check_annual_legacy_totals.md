# Check legacy annual England totals for misread columns

Recalculates each published percentage from its count. Stops if the two
differ by more than 0.1, which catches a column read from the wrong
position. Also stops if a value is missing, a count is negative, a
percentage is outside 0 to 100, or reliable recovery is larger than
recovery.

## Usage

``` r
check_annual_legacy_totals(df, period)
```

## Arguments

- df:

  One-row tibble, as returned by
  [`extract_annual_legacy_totals()`](https://bennettoxford.github.io/nhstt/reference/extract_annual_legacy_totals.md)

- period:

  Character, specifying reporting period for error messages

## Value

Invisibly returns `df`

## Details

Improvement, no reliable change and deterioration are divided by
finished treatment. Recovery and reliable recovery are divided by
finished treatment minus those not at caseness. 2013-14 does not publish
the number not at caseness, so there we divide by the number at
caseness.
