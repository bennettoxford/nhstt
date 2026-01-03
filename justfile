set positional-arguments := true

alias help := list

# List available commands
list:
    @just --list --unsorted

# Format R code using air, see air.toml
fix:
    air format .

# Document package using roxygen
document:
    Rscript --quiet --vanilla -e 'devtools::document()'

# Build and install package
build:
    Rscript --quiet --vanilla -e 'pak::local_install()'

# Run all tests
test-unit:
    Rscript --quiet --vanilla -e 'devtools::test()'

# Run integration tests (downloads real data)
test-integration:
    Rscript tests/integration.R

test: test-unit test-integration

# Run R CMD check
check:
    Rscript --quiet --vanilla -e 'devtools::check()'

# Build pkgdown site
docs-build:
    Rscript --quiet --vanilla -e 'pkgdown::build_site()'

# Preview pkgdown site with HTTP server
docs-serve:
    Rscript --quiet --vanilla -e 'servr::httw("docs", initpath = "index.html", browser = TRUE)'

# Build and preview pkgdown site
docs: docs-build docs-serve

# Update archive schemas (extracts column names from raw data)
update-schemas:
    Rscript --quiet --vanilla -e '\
        devtools::load_all(); \
        dir.create("inst/schemas", recursive = TRUE, showWarnings = FALSE); \
        schemas <- extract_archive_schemas("annual_main"); \
        write.csv(schemas, "inst/schemas/annual_main_schemas.csv", row.names = FALSE); \
        message("✓ Updated inst/schemas/annual_main_schemas.csv")'
