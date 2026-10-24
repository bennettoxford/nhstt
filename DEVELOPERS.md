
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
| `get_measures_annual()` | annual | 2012-13 | 2025-26 | 14 | 0.5.0 |
| `get_proms_annual()` | annual | 2019-20 | 2025-26 | 7 | 0.3.0 |
| `get_therapy_position_annual()` | annual | 2019-20 | 2025-26 | 7 | 0.2.0 |
| `get_measures_monthly()` | monthly | 2021-01 | 2026-07 | 67 | 0.6.0 |
| `get_measures_quarterly()` | quarterly | 2022-23-q2 | 2026-27-q1 | 16 | 0.2.0 |
| `get_metadata_measures_annual()` | annual | 2024-25 | 2025-26 | 2 | 0.2.0 |
| `get_metadata_variables_annual()` | annual | 2024-25 | 2025-26 | 2 | 0.2.0 |
| `get_metadata_monthly()` | monthly | 2026-07 | 2026-07 | 1 | 0.2.0 |
| `get_metadata_providers()` | live | current | current | 1 | 0.2.0 |

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

## Annual measures before 2017-18

The annual reports from 2012-13 to 2016-17 use a different format from
later years. Up to 2014-15 they are XLSX workbooks. 2015-16 and 2016-17
are ZIP packs of CSVs. The layout changes every year. For these years
`measures_annual` has England totals only. It has no breakdowns and no
organisations below England.

The `measures_annual` entry in `raw_annual_data_config.yml` has
`legacy_archive: "annual_legacy"`. This tells `build_tidy_data()` to add
these rows with `tidy_annual_legacy_totals()` in
`R/raw-annual-legacy.R`. It also adds these years to
`available_nhstt_reports()`. The `annual_legacy` archive says where each
measure is in each year’s file. The rows then go through the same tidy
config as later years.

The build stops if a published percentage does not match its count. This
catches a column read from the wrong position. Measures without a
percentage have no such check, and neither does any of 2012-13. We
checked their column positions by hand against the source headers.

Some measures are missing in early years.

- 2013-14 and 2012-13 do not publish the number not at caseness.
- 2012-13 was the first year of the dataset, so only referrals received
  in that year count. Its outcomes are grouped differently. We include
  only the recovery and reliable recovery counts, with no percentages.

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

4.  Push the branch, then create a GitHub Release with `just release`.
    It tags the current branch, so you can run it from a pull request
    branch before merging:

    ``` bash
    just release measures_monthly 0.5.0 "Monthly activity and performance data YYYY-MM to YYYY-MM"
    ```

5.  Check the `url` in `tidy_data_sources.yml` matches the parquet asset
    URL on the release page (copy-paste it if not)

6.  Run `just docs` to check the vignettes with the released data. The
    pkgdown check on the pull request downloads the same release

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

Provider metadata is published the same way, see [Provider
metadata](#provider-metadata).

## Provider metadata

`get_metadata_providers()` downloads a published parquet like every
other getter. `build_tidy_data("metadata_providers")` builds that
parquet with `build_metadata_providers()` in four steps.

1.  Take the provider codes from the published annual measures
2.  Look up each provider in the live NHS Organisation Data Service
    (ODS) API with `get_ods_data()`
3.  Add latitude and longitude for each postcode from
    [postcodes.io](https://postcodes.io/) with
    `get_postcode_coordinates()`
4.  Add the last period each provider reported, and the latest period,
    in the published annual, quarterly, and monthly data with
    `add_provider_reporting()`

Steps 1 and 4 read the published datasets. Rebuild provider metadata
after releasing new annual, quarterly, or monthly data, so the reporting
columns include the new period. ODS changes over time, so the
`retrieved_date` column records the day of the build.

``` bash
just build-data-metadata
just release metadata_providers 0.2.0 "Provider organisation metadata from ODS"
```

### Providers vignette

`vignettes/metadata-providers.qmd` draws the providers map and table.
Three files sit next to it.

- `metadata-providers.js` has the map interactions, passed to
  `htmlwidgets::onRender()`
- `metadata-providers.css` has the page styles
- `nhs-england-regions.geojson` has the NHS England region boundaries

The vignette reads the JavaScript and CSS into the page when it renders,
so the pkgdown site needs no extra files.

The region boundaries come from the [Office for National Statistics
(ONS) Open Geography Portal](https://geoportal.statistics.gov.uk/).
`update_region_boundaries()` downloads them and renames the fields to
`region_code` and `region_name`, so the vignette does not depend on the
boundary year. To update them, change the default `url` and the year in
`attribution`, then run `just update-region-boundaries`. The region
names must match the `region_name` values from ODS. If they do not,
clicking a region on the map hides every provider.

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
- `update_region_boundaries()` — download the region boundaries for the
  providers map

## Resources

- [R Packages (2e)](https://r-pkgs.org/)
- [Advanced R](https://adv-r.hadley.nz/)
