# Notes for developers

## System requirements

- [just](https://github.com/casey/just)
- R (version 4.0 or higher)
- [air](https://github.com/posit-dev/air/) for code formatting

## Local development environment

The `just` command provides a list of available recipes, most of them
are also available as shortcuts in Positron or RStudio:

``` bash
just list
```

## R package development

- [R Packages (2e) by Hadley Wickham and Jennifer
  Bryan](https://r-pkgs.org/)
- [Advanced R by Hadley Wickham](https://adv-r.hadley.nz/)
- [Creating R packages Kurt Hornik and the R Core
  Team](https://cran.r-project.org/doc/FAQ/R-exts.html#Creating-R-packages)

## Testing

Unit tests are implemented with *teststhat* in `tests/testthat` (run
`just test-unit`). To keep unit tests fast but still test the full
pipeline (download and tidy) integration tests are in
`tests/integration.R` (run `just test-integration`). There may be a way
to also add integration tests to testthat without running them every
time (possible using environment variables), but I haven’t explored that
yet. The just recipe `just test` runs both tests.

## Documentation

Documentation is built with [pkgdown](https://pkgdown.r-lib.org/).

## Development workflow

1.  Install package locally: `just build` (or
    [`pak::local_install()`](https://pak.r-lib.org/reference/local_install.html))
2.  Make changes to code
3.  Run `just fix` to format
4.  Run `just document` if you changed roxygen2 docs
5.  Run `just test` to verify tests pass
6.  For schema updates: `just update-schemas`
7.  Run `just check` before submitting a PR
8.  Update docs with `just docs` if needed

## Configuration files

Data sources and transformations are defined in `inst/config/` as YAML
files:

**Raw data sources** (archives, URLs, periods): -
`raw_annual_data_config.yml`: Annual datasets -
`raw_monthly_data_config.yml`: Monthly datasets -
`raw_metadata_config.yml`: Metadata

**Tidy transformations** (filters, derivations, output columns): -
`tidy_annual_data_config.yml` - `tidy_monthly_data_config.yml` -
`tidy_metadata_config.yml`

**Schemas** (auto-generated column tracking): - Run
`just update-schemas` after modifying `raw_annual_data_config.yml` -
Schemas saved to `inst/schemas/annual_main_schemas.csv`

## Dev utilities

Internal functions in `R/dev-utils.R` help explore archive contents
before exposing new data through the package: -
`list_available_archives()`: See all archives and periods -
`list_archive_files("annual_main", "2024-25")`: List CSV files in an
archive - `read_archive_file("annual_main", "2024-25", "main")`: Read
specific files - `compare_schemas("main")`: Compare column changes
across periods

Access via `devtools::load_all()` or `nhstt:::function_name()`.
