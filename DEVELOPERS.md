
<!-- DEVELOPERS.md is generated from DEVELOPERS.Rmd. Please edit that file -->

# Notes for developers

## Requirements

- R (\>= 4.0), [just](https://github.com/casey/just),
  [air](https://github.com/posit-dev/air/), [Quarto
  CLI](https://quarto.org/docs/get-started/),
  [gh](https://cli.github.com/)

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
| `get_measures_annual()` | annual | 2017-18 | 2024-25 | 8 | 0.2.0 |
| `get_proms_annual()` | annual | 2019-20 | 2024-25 | 6 | 0.2.0 |
| `get_therapy_annual()` | annual | 2019-20 | 2024-25 | 6 | 0.1.0 |
| `get_measures_monthly()` | monthly | 2021-01 | 2026-03 | 63 | 0.4.0 |
| `get_metadata_measures_annual()` | annual | 2024-25 | 2024-25 | 1 | 0.1.0 |
| `get_metadata_variables_annual()` | annual | 2024-25 | 2024-25 | 1 | 0.1.0 |
| `get_metadata_monthly()` | monthly | 2026-05 | 2026-05 | 1 | 0.1.0 |
| `get_metadata_providers()` | live | current | current | 1 | 0.1.0 |

### Approximate build times

One period timed per dataset; extrapolated to full build. Re-run with
`just render-developers`.

| Dataset | Timed period | Periods | Time for one (s) | Est. full build (min) |
|:---|:---|---:|---:|---:|
| `measures_annual` | 2024-25 | 8 | 66.2 | 8.8 |
| `proms_annual` | 2024-25 | 6 | 202.8 | 20.3 |
| `therapy_annual` | 2024-25 | 6 | 0.9 | 0.1 |
| `measures_monthly` | 2026-03 | 63 | 2.7 | 2.9 |

## Annual measures: two pipelines

The `measures_annual` dataset combines data from two separate pipelines
that share a common schema and are row-bound at build time.

“Legacy format” refers to the 2012-13 to 2016-17 reports, which were
published as XLSX workbooks (2012–15) and ZIP/CSV packs (2015–17) rather
than the uniform structured CSVs introduced in 2017-18. The readers in
`R/raw-annual-legacy-format.R` are just a translation layer: they bring
the the old formats into the same wide intermediate structure as the
post-2017-18 raw CSVs, then use the same `pivot_longer_measures()`
workflow. I use “legacy” to refer to the data format, not the data.

### Legacy format breakdown availability

Breakdowns are only included where available and may not have the same
subgroups as later years. Percentage measures are not included for
2012-13 because the denominator methodology differs from later years.
Numbers show unique subgroup counts (distinct `variable_a` times
`variable_b` combinations) for England-level rows.

| Breakdown                     | 2012-13 | 2013-14 | 2014-15 | 2015-16 | 2016-17 |
|:------------------------------|--------:|--------:|--------:|--------:|--------:|
| Age Group                     |       5 |       5 |       5 |       5 |       5 |
| Disability Type               |      NA |      NA |      15 |      15 |      15 |
| Ethnic Group                  |      17 |      22 |      16 |      16 |      16 |
| Gender                        |       2 |       2 |       2 |       2 |       2 |
| Indices of Deprivation Decile |      NA |      NA |      NA |      11 |      11 |
| Long Term Condition Status    |      NA |      NA |      NA |       2 |       3 |
| Religion                      |      NA |      NA |      15 |      15 |      15 |
| Sexual Orientation Type       |      NA |      NA |       6 |       6 |       6 |

**Modern format (2017-18 onwards)**

| Breakdown | 2017-18 | 2018-19 | 2019-20 | 2020-21 | 2021-22 | 2022-23 | 2023-24 | 2024-25 |
|:---|---:|---:|---:|---:|---:|---:|---:|---:|
| Age Group | 5 | 5 | 5 | 5 | 6 | 6 | 6 | 6 |
| BME Group | NA | NA | NA | 3 | 3 | 3 | 3 | 3 |
| Consultation Medium | 7 | 7 | 7 | 9 | 9 | 14 | 14 | 14 |
| Disability Type | NA | NA | NA | 15 | 15 | 15 | 15 | 15 |
| Ethnic Group | 22 | 22 | 22 | 22 | 22 | 22 | 22 | 22 |
| Gender | 3 | 3 | 3 | 4 | 4 | 4 | 4 | 4 |
| Indices of Deprivation Decile | 11 | 11 | 11 | 11 | 11 | 11 | 11 | 11 |
| Long Term Condition Status | 3 | 3 | 3 | 3 | 3 | 3 | 3 | 3 |
| Mental Health Care Cluster | 10 | 10 | 10 | 10 | 10 | 10 | 10 | 10 |
| Presenting Complaint | NA | NA | NA | 17 | 17 | 20 | 20 | 20 |
| Problem Descriptor | 16 | 16 | 16 | NA | NA | NA | NA | NA |
| Religion | 13 | 13 | 13 | 13 | 13 | 13 | 13 | 13 |
| Sexual Orientation Type | NA | NA | NA | 4 | 4 | 4 | 4 | 4 |
| Stepped Care Pathway | 4 | 4 | 4 | 4 | 4 | 4 | 4 | 8 |
| Waiting Time | 15 | 15 | 15 | 15 | 15 | 15 | 15 | 15 |

## Publishing new data

Each dataset is released independently — updating monthly data does not
affect annual dataset versions or caches.

1.  Update raw config (e.g. `raw_monthly_data_config.yml`) with new
    sources

2.  `just build-data` — rebuilds all parquets and writes to `data-raw/`

3.  Create a GitHub Release using `just release` (run after merging to
    main):

    ``` bash
    just release measures_monthly 0.4.0 "Monthly activity and performance data YYYY-MM to YYYY-MM"
    ```

4.  Update `version` for that dataset only in
    `inst/config/tidy_data_sources.yml`

Provider metadata is published the same way, but its parquet is built
from the live ODS API snapshot:

``` bash
just build-data
just release metadata_providers 0.1.0 "Provider organisation metadata from ODS"
```

## Configuration files

All in `inst/config/`:

- `tidy_data_sources.yml` — version per released dataset; GitHub Release
  URLs are derived from the dataset name and version
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
