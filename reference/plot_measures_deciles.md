# Plot decile charts for each measure, optionally highlighting services

**\[experimental\]**

Shows the distribution of ratios across all services as decile bands
(10th to 90th percentile, darker closer to the median), facetted by
measure. Selected services can be highlighted as coloured lines,
labelled with their service name by default or with generic "Service A",
"Service B", ... labels when service names should not be shown (e.g. in
a blog post).

## Usage

``` r
plot_measures_deciles(
  measures,
  highlight_services = NULL,
  hide_service_names = FALSE,
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

- highlight_services:

  Character vector of org codes to highlight (e.g.,
  `c("RNUDT", "RTQ")`). Default NULL (no services highlighted)

- hide_service_names:

  Logical, label highlighted services "Service A", "Service B", ...
  instead of their service name. Default FALSE

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
# highlighted services labelled with their names
df_clean |> plot_measures_deciles(highlight_services = c("RNUDT", "RTQ"))

# generic labels when service names should not be shown
df_clean |> plot_measures_deciles(highlight_services = c("RNUDT", "RTQ"), hide_service_names = TRUE)
} # }
```
