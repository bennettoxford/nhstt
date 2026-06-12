# Create a measures table from a tidy monthly dataset

**\[experimental\]**

Builds an analysis-ready measures table by pairing one or more numerator
measures with a denominator measure, following the structure used in
OpenSAFELY measures: one row per measure, organisation, and reporting
interval, with a `ratio` column giving numerator / denominator.

## Usage

``` r
create_measures(data, numerators, denominator, group_type = "Provider")
```

## Arguments

- data:

  Tibble, a tidy dataset as returned by
  [`get_activity_performance_monthly()`](https://bennettoxford.github.io/nhstt/reference/get_activity_performance_monthly.md)

- numerators:

  Character vector of measure IDs to use as numerators (e.g.,
  `c("M066", "M344")`)

- denominator:

  Character, single measure ID to use as the denominator (e.g.,
  `"M076"`)

- group_type:

  Character, organisation level to keep. Default "Provider"

## Value

Tibble with columns: measure_id, measure_name, interval_start,
interval_end, numerator, org_code2, org_name2, denominator,
denominator_measure_id, ratio

## Examples

``` r
if (FALSE) { # \dontrun{
df <- get_activity_performance_monthly()
df_measures <- create_measures(
  df,
  numerators = c("M066", "M344", "M341", "M070", "M069"),
  denominator = "M076"
)
} # }
```
