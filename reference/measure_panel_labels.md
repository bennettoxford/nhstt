# Add a measure panel label column to a measures table

Builds a `measure_name_id` factor like "Completed (M066)" (or "A:
Completed (M066)" with panel tags), ordered by measure ID.

## Usage

``` r
measure_panel_labels(measures, panel_tags = FALSE, measure_order = NULL)
```

## Arguments

- measures:

  Tibble, as returned by
  [`create_measures()`](https://bennettoxford.github.io/nhstt/reference/create_measures.md)

- panel_tags:

  Logical, prefix panels with "A:", "B:", ... Default FALSE

- measure_order:

  Character vector of measure IDs giving the panel order. Default NULL
  (panels ordered by measure ID)

## Value

The measures tibble with a `measure_name_id` factor column
