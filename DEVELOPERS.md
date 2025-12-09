# Notes for developers

## System requirements

- [just](https://github.com/casey/just)
- R (version 4.0 or higher)
- [air](https://github.com/r-lib/air) for code formatting

## Local development environment

The `just` command provides a list of available recipes, most of them are also available as shortcuts in Positron or RStudio:

```bash
just list
```

## R package development

- [R Packages (2e) by Hadley Wickham and Jennifer Bryan](https://r-pkgs.org/)
- [Advanced R by Hadley Wickham](https://adv-r.hadley.nz/)
- [Creating R packages Kurt Hornik and the R Core Team](https://cran.r-project.org/doc/FAQ/R-exts.html#Creating-R-packages)

## Testing

Unit tests are implemented with _teststhat_ in `tests/testthat` (run `just test-unit`).
To keep unit tests fast but still test the full pipeline (download and tidy) integration tests are in `tests/integration.R` (run `just test-integration`).
There may be a way to also add integration tests to testthat without running them every time (possible using environment variables), but I haven't explored that yet.
The just recipe `just test` runs both tests.

## Documentation

Documentation is built with [pkgdown](https://pkgdown.r-lib.org/).

## Configuration

Data source and transformation configs live in `inst/config/` as YAML files (`raw_config.yml` for raw download sources, `tidy_config.yml` for data cleaning).

## OJS Reports

Interactive reports in `vignettes/report-*.qmd` use [Observable JavaScript (OJS)](https://quarto.org/docs/interactive/ojs/) in Quarto with shared code in `_shared-code.qmd`. Reports support URL parameters (`?orgs=code1,code2`) for organization selection and use [Observable Plot](https://observablehq.com/@observablehq/plot-gallery) (or [D3](https://observablehq.com/@d3/gallery)) for visualizations.

We could drop OJS, but then we'd loose some interactivity between URL parameters and UI components (e.g., plots and tables). Alternatively we could do some of that using R-based approaches with ([plotly](https://plotly.com/r/), or [Highcharts](https://jkunst.com/highcharter/)). For similar interactivity we would need Shiny.

## Development workflow

1. Make changes to code
2. Run `just fix` to format
3. Run `just document` if you changed roxygen2 docs
4. Run `just test` to verify tests pass
5. Run `just check` before submitting a PR
6. Update docs with `just docs` if needed
