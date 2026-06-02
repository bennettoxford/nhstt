
<!-- DEVELOPERS.md is generated from DEVELOPERS.Rmd. Please edit that file -->

# Notes for developers

## Requirements

- R (\>= 4.0), [just](https://github.com/casey/just),
  [air](https://github.com/posit-dev/air/), [Quarto
  CLI](https://quarto.org/docs/get-started/)

Run `just list` to see all available recipes.

## Data pipeline

Users call `get_*()`, which reads `tidy_data_sources.yml` for the
current version and URL, downloads the pre-built parquet if not already
cached, and caches it to `~/.cache/R/nhstt/tidy/{dataset}.parquet`.
Subsequent calls return the cached file instantly.

Developers run `build_tidy_data(dataset)` (`just build-data` for all),
which downloads raw source files, applies the tidy pipeline for every
period, and writes a combined parquet to `data-raw/`. Parquets are
published as GitHub Release assets and are directly usable from Python,
Julia, or any language that reads parquet.

### Available datasets

| Function | Frequency | First period | Last period | Periods | Version |
|:---|:---|:---|:---|---:|---:|
| `get_key_measures_annual()` | annual | 2017-18 | 2024-25 | 8 | 0.2.0 |
| `get_proms_annual()` | annual | 2019-20 | 2024-25 | 6 | 0.1.0 |
| `get_therapy_position_annual()` | annual | 2019-20 | 2024-25 | 6 | 0.1.0 |
| `get_activity_performance_monthly()` | monthly | 2023-05 | 2026-03 | 35 | 0.3.0 |
| `get_metadata_measures_annual()` | annual | 2024-25 | 2024-25 | 1 | 0.1.0 |
| `get_metadata_variables_annual()` | annual | 2024-25 | 2024-25 | 1 | 0.1.0 |
| `get_metadata_monthly()` | monthly | 2025-07 | 2025-07 | 1 | 0.1.0 |
| `get_metadata_providers()` | live | current | current | 1 | 0.1.0 |

### Approximate build times

One period timed per dataset; extrapolated to full build. Re-run with
`just render-developers`.

| Dataset | Timed period | Periods | Time for one (s) | Est. full build (min) |
|:---|:---|---:|---:|---:|
| `key_measures_annual` | 2024-25 | 8 | 58.6 | 7.8 |
| `proms_annual` | 2024-25 | 6 | 110.5 | 11.0 |
| `therapy_position_annual` | 2024-25 | 6 | 0.1 | 0.0 |
| `activity_performance_monthly` | 2026-03 | 35 | 0.5 | 0.3 |

## Publishing new data

Each dataset is released independently — updating monthly data does not
affect annual dataset versions or caches.

1.  Update raw config (e.g. `raw_monthly_data_config.yml`) with new
    sources

2.  `just build-data` — rebuilds all parquets and writes to `data-raw/`

3.  Create a GitHub Release with a dataset-specific tag and upload that
    parquet:

    ``` bash
    gh release create activity-performance-monthly-v0.4.0 \
      data-raw/activity_performance_monthly.parquet \
      --title "activity-performance-monthly v0.4.0"
    ```

4.  Update `version` and `url` for that dataset only in
    `inst/config/tidy_data_sources.yml`

## Configuration files

All in `inst/config/`:

- `tidy_data_sources.yml` — version + GitHub Release URL per dataset
  (user-facing)
- `raw_*_config.yml` — raw source archives, URLs, and periods
- `tidy_*_config.yml` — tidy transformations (filters, derivations,
  columns)

After changing raw config column structure, run `just update-schemas` to
update `inst/schemas/`.

## Dev utilities

Internal functions in `R/dev-utils.R` (load with
`devtools::load_all()`):

- `list_archives_periods()` — all archives and available periods
- `list_archive_files("annual_main", "2024-25")` — CSV files inside an
  archive
- `read_archive_file("annual_main", "2024-25", "main")` — read a
  specific file
- `compare_schemas("main")` — column changes across periods
- `build_tidy_data("dataset_name")` — build combined parquet for one
  dataset

## Resources

- [R Packages (2e)](https://r-pkgs.org/)
- [Advanced R](https://adv-r.hadley.nz/)
