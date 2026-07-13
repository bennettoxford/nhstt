
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
| `get_therapy_position_annual()` | annual | 2019-20 | 2024-25 | 6 | 0.1.0 |
| `get_measures_monthly()` | monthly | 2021-01 | 2026-05 | 65 | 0.5.0 |
| `get_metadata_measures_annual()` | annual | 2024-25 | 2024-25 | 1 | 0.1.0 |
| `get_metadata_variables_annual()` | annual | 2024-25 | 2024-25 | 1 | 0.1.0 |
| `get_metadata_monthly()` | monthly | 2026-07 | 2026-07 | 1 | 0.2.0 |
| `get_metadata_providers()` | live | current | current | 1 | 0.1.0 |

### Approximate build times

One period timed per dataset, multiplied by the number of periods. These
numbers are hardcoded (last measured 2026-07-13) — they are not
re-measured on render because timing a build of every dataset takes
ages. To update them, run the `build-times` chunk in `DEVELOPERS.Rmd`
interactively (it has `eval = FALSE`) and paste the table it prints over
the one below.

| Dataset | Timed period | Periods | Time for one (s) | Est. full build (min) |
|:---|:---|---:|---:|---:|
| `measures_annual` | 2024-25 | 8 | 62.0 | 8.3 |
| `proms_annual` | 2024-25 | 6 | 212.2 | 21.2 |
| `therapy_position_annual` | 2024-25 | 6 | 0.6 | 0.1 |
| `measures_monthly` | 2026-05 | 65 | 6.0 | 6.6 |

## Publishing new data

Each dataset is released independently — updating monthly data does not
affect annual dataset versions or caches.

1.  Update raw config (e.g. `raw_monthly_data_config.yml`) with new
    sources

2.  Add the new version (`version` + `url`) at the top of the dataset’s
    `versions` list in `inst/config/tidy_data_sources.yml` — the first
    entry is the default. Copy the `url` from the previous entry and
    update the version; `just release` creates the tag
    `{dataset-with-dashes}-v{version}`, so the URL is
    `https://github.com/bennettoxford/nhstt/releases/download/{tag}/{dataset}.parquet`

3.  `just build-data` — rebuilds all parquets and writes to `data-raw/`

4.  Create a GitHub Release using `just release` (run after merging to
    main):

    ``` bash
    just release measures_monthly 0.5.0 "Monthly activity and performance data YYYY-MM to YYYY-MM"
    ```

5.  Check the `url` in `tidy_data_sources.yml` matches the parquet asset
    URL on the release page (copy-paste it if not)

The monthly metadata file (`metadata_measures_monthly`) is replaced by
NHS Digital every month: they upload a newly dated xlsx and delete the
old one, so the URL in `raw_metadata_config.yml` breaks each time. When
the build fails downloading it, find the current link on the [NHS
Talking Therapies data set reports
page](https://digital.nhs.uk/data-and-information/data-collections-and-data-sets/data-sets/improving-access-to-psychological-therapies-data-set/improving-access-to-psychological-therapies-data-set-reports),
then update the period, URL, and cell range in
`raw_metadata_config.yml`, recreate the raw fixture with
`create_raw_fixture()`, and update the period in the tests and the
source link in the `get_metadata_monthly()` docs.

Provider metadata is published the same way, but its parquet is built
from the live ODS API snapshot:

``` bash
just build-data
just release metadata_providers 0.1.0 "Provider organisation metadata from ODS"
```

## Configuration files

All in `inst/config/`:

- `tidy_data_sources.yml` — version and GitHub Release URL per released
  dataset
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
