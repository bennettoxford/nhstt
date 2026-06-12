# Plot monthly trends for each measure across all services

**\[experimental\]**

Draws one line per service, facetted by measure, for either the raw
numerator counts or the ratio relative to the denominator.

## Usage

``` r
plot_measures(
  measures,
  y = c("ratio", "numerator"),
  ncol = 2,
  panel_tags = FALSE,
  measure_order = NULL
)
```

## Arguments

- measures:

  Tibble, as returned by
  [`create_measures()`](https://bennettoxford.github.io/nhstt/reference/create_measures.md),
  filtered to the measures to plot

- y:

  Character, plot the "ratio" (default) or the "numerator" counts

- ncol:

  Integer, number of facet columns. Default 2

- panel_tags:

  Logical, prefix panels with "A:", "B:", ... Default FALSE

- measure_order:

  Character vector of measure IDs giving the panel order. Default NULL
  (panels ordered by measure ID)

## Value

A ggplot object, so labels and theme can be adjusted with `+`

## Examples

``` r
if (FALSE) { # \dontrun{
df_clean |> plot_measures(y = "ratio")
df_clean |> plot_measures(y = "numerator") + ggplot2::labs(y = "Referrals")
} # }
```
