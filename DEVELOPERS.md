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

Currently only (fast) unit tests.
The full data pipleline including downloads is not included in the test at the moment.

## Documentation

Documentation is built with [pkgdown](https://pkgdown.r-lib.org/).

## Development workflow

1. Make changes to code
2. Run `just fix` to format
3. Run `just document` if you changed roxygen2 docs
4. Run `just test` to verify tests pass
5. Run `just check` before submitting a PR
6. Update docs with `just docs` if needed
