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

# Create a GitHub Release for a dataset — run after merging to main
# Usage: just release <dataset> <version> [notes]
# Example: just release activity_performance_monthly 0.4.0 "Monthly activity and performance data YYYY-MM to YYYY-MM"
release dataset version notes='':
    #!/usr/bin/env bash
    tag=$(echo "{{dataset}}" | tr '_' '-')-v{{version}}
    gh release create "$tag" data-raw/{{dataset}}.parquet --notes "{{notes}}"

# Build all pre-built tidy parquets and write to data-raw/ (slow — downloads raw data)
build-data:
    Rscript --quiet --vanilla -e '\
        devtools::load_all(); \
        build_tidy_data("activity_performance_monthly"); \
        build_tidy_data("key_measures_annual"); \
        build_tidy_data("proms_annual"); \
        build_tidy_data("therapy_position_annual"); \
        build_tidy_data("metadata_measures_monthly"); \
        build_tidy_data("metadata_providers"); \
        build_tidy_data("metadata_measures_annual", raw_datasets = c("metadata_measures_main_annual", "metadata_measures_additional_annual")); \
        build_tidy_data("metadata_variables_annual", raw_datasets = c("metadata_variables_main_annual", "metadata_variables_additional_annual"))'

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

# Render README.Rmd to README.md
render-readme:
    Rscript --quiet --vanilla -e 'devtools::load_all(quiet = TRUE); rmarkdown::render("README.Rmd")'

# Render DEVELOPERS.Rmd to DEVELOPERS.md
render-developers:
    Rscript --quiet --vanilla -e 'devtools::load_all(quiet = TRUE); rmarkdown::render("DEVELOPERS.Rmd")'

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
        schemas_main <- extract_archive_schemas("annual_main"); \
        write.csv(schemas_main, "inst/schemas/annual_main_schemas.csv", row.names = FALSE); \
        message("Updated inst/schemas/annual_main_schemas.csv"); \
        schemas_tbo <- extract_archive_schemas("annual_tbo"); \
        write.csv(schemas_tbo, "inst/schemas/annual_tbo_schemas.csv", row.names = FALSE); \
        message("Updated inst/schemas/annual_tbo_schemas.csv")'
